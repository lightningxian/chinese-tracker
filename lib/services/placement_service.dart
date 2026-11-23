import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../core/utils/session_store.dart';
import '../models/app_user.dart';
import '../models/placement.dart';
import '../models/test_track.dart';
import 'exercise_play_service.dart';
import 'test_service.dart';

/// Build 3 (docs/PLAN.md §4): registration approval and placement tests.
/// Every write goes through Cloud Functions (`decideRegistration`,
/// `startPlacement`, `submitPlacementPart`, ...); the public ones work
/// without a sign-in.
class PlacementService {
  PlacementService({FirebaseFirestore? firestore, FirebaseFunctions? functions})
      : _db = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  // ------------------------------------------------------------ public

  /// The register form: the paper's level, the mark and the recommended
  /// level of a result code (no name, no number).
  Future<PlacementSummary> resolveResultCode(String code) async {
    final r = await _functions
        .httpsCallable('resolvePlacementResult')
        .call({'resultCode': code});
    return PlacementSummary.fromMap(Map<String, dynamic>.from(r.data as Map));
  }

  /// The landing page's list of placement tests.
  Future<List<PlacementMenuEntry>> menu() async {
    final r = await _functions.httpsCallable('placementMenu').call({});
    return [
      for (final c in ((r.data as Map)['codes'] as List? ?? const []))
        PlacementMenuEntry.fromMap(Map<String, dynamic>.from(c as Map)),
    ];
  }

  // ------------------------------------------------------------ admin

  /// Pending and rejected self-registrations, newest first.
  Stream<List<AppUser>> watchRegistrations() => _db
      .collection('users')
      .where('status', whereIn: [AppUser.statusPending, AppUser.statusRejected])
      .snapshots()
      .map((s) => s.docs.map(AppUser.fromFirestore).toList()
        ..sort((a, b) => (b.createdAt ?? DateTime(2000))
            .compareTo(a.createdAt ?? DateTime(2000))));

  /// The placement result behind a pending student's result code.
  Future<PlacementSummary?> registrationPlacement(String code) async {
    if (code.trim().isEmpty) return null;
    final r = await _functions
        .httpsCallable('registrationPlacement')
        .call({'resultCode': code});
    final m = Map<String, dynamic>.from(r.data as Map);
    if (m['found'] != true) return null;
    return PlacementSummary.fromMap(m);
  }

  Future<void> approve(String studentId,
          {required String level, required String teacherId}) =>
      _functions.httpsCallable('decideRegistration').call({
        'studentId': studentId,
        'approve': true,
        'level': level,
        'teacherId': teacherId,
      });

  Future<void> reject(String studentId, String reason) =>
      _functions.httpsCallable('decideRegistration').call({
        'studentId': studentId,
        'approve': false,
        'reason': reason,
      });

  /// Staff: a visitor's result (the supervision screen links to it).
  Stream<Map<String, dynamic>?> watchVisitorResult(String attemptId) => _db
      .collection('placement_results')
      .doc(attemptId)
      .snapshots()
      .map((d) => d.data());
}

/// A visitor's placement attempt (no account): the attempt id and the key
/// `startPlacement` returned once, kept in the tab's sessionStorage so a
/// reload resumes the same part.
class VisitorTestBackend implements TestPlayBackend {
  VisitorTestBackend({
    this.name = '',
    this.whatsapp = '',
    FirebaseFunctions? functions,
  }) : _functions = functions ?? FirebaseFunctions.instance;

  final String name;
  final String whatsapp;
  final FirebaseFunctions _functions;

  static const _storeKey = 'placement_visitor_attempt';
  static const _deviceKey = 'placement_visitor_device';

  /// A random id for this browser tab: wrong tokens are counted per tab
  /// first, so one classroom Wi-Fi does not block every visitor.
  static String deviceId() {
    final have = SessionStore.read(_deviceKey);
    if (have != null && have.isNotEmpty) return have;
    final r = Random.secure();
    const abc = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final id = List.generate(20, (_) => abc[r.nextInt(abc.length)]).join();
    SessionStore.write(_deviceKey, id);
    return id;
  }
  static const _resultKey = 'placement_visitor_result';

  /// `{attemptId, key}` of the attempt in this tab, if any.
  static ({String attemptId, String key})? stored() {
    final raw = SessionStore.read(_storeKey);
    if (raw == null) return null;
    try {
      final m = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final id = m['attemptId'] as String? ?? '';
      final key = m['key'] as String? ?? '';
      if (id.isEmpty || key.isEmpty) return null;
      return (attemptId: id, key: key);
    } catch (_) {
      return null;
    }
  }

  static void _store(String attemptId, String key) => SessionStore.write(
      _storeKey, jsonEncode({'attemptId': attemptId, 'key': key}));

  static void forget() => SessionStore.remove(_storeKey);

  /// The last result shown in this tab (the result page survives a reload).
  static VisitorResult? lastResult() {
    final raw = SessionStore.read(_resultKey);
    if (raw == null) return null;
    try {
      return VisitorResult.fromMap(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return null;
    }
  }

  static void keepResult(VisitorResult r) =>
      SessionStore.write(_resultKey, jsonEncode(r.toMap()));

  @override
  bool get isVisitor => true;

  Map<String, dynamic> _auth() {
    final s = stored();
    return s == null ? const {} : {'attemptId': s.attemptId, 'key': s.key};
  }

  TestStep _step(Object? data) {
    final m = Map<String, dynamic>.from(data as Map);
    final step = TestStep.fromServer(m);
    final key = step.visitorKey;
    if (key != null && step.attemptId != null) _store(step.attemptId!, key);
    final result = step.visitorResult;
    if (result != null) {
      keepResult(result);
      forget();
    }
    return step;
  }

  @override
  Future<TestFacts> peek(String token) async {
    final r = await _functions
        .httpsCallable('startPlacement')
        .call({'token': token, 'peek': true, 'deviceId': deviceId()});
    return TestFacts.fromServer(Map<String, dynamic>.from(r.data as Map));
  }

  /// With a token: joins (name and WhatsApp go with it). Without: resumes
  /// the attempt kept in this tab.
  @override
  Future<TestStep> start({String? token, String? codeId}) async {
    final call = _functions.httpsCallable('startPlacement');
    if (token != null && stored() == null) {
      return _step((await call.call({
        'token': token,
        'name': name,
        'whatsapp': whatsapp,
        'deviceId': deviceId(),
      }))
          .data);
    }
    return _step((await call.call(_auth())).data);
  }

  @override
  Future<TestStep> submitPart(
      String codeId, int partIndex, Map<String, PlayAnswer> answers) async {
    final r = await _functions.httpsCallable('submitPlacementPart').call({
      ..._auth(),
      'partIndex': partIndex,
      'answers': answers.map((k, v) => MapEntry(k, v.toJson())),
    });
    return _step(r.data);
  }

  @override
  Future<void> reportEvent(String codeId, {required bool left}) async {
    try {
      await _functions.httpsCallable('reportPlacementEvent').call({
        ..._auth(),
        'type': left ? 'left' : 'back',
      });
    } catch (_) {}
  }

  /// A visitor cannot read the attempt (staff only); the clock and the
  /// next submit tell the player when the teacher ended the session.
  @override
  Stream<TestAttempt?> watchAttempt(String id) => const Stream.empty();
}
