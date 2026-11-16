import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/exercise_skill_category.dart';
import '../models/question_bank_item.dart';
import '../models/test_track.dart';
import 'exercise_play_service.dart';

/// Supervised test track (docs/PLAN.md §3, Build 1).
///
/// Admins write `test_formats` and `test_codes` here; everything a session,
/// attempt or result does goes through the Cloud Functions
/// (`openTestSession`, `startTest`, `submitTestPart`, `reportTestEvent`,
/// `closeTestSession`, `setTestResultValidity`, `getTestReview`), so answer
/// keys never reach the app.
class TestService {
  TestService({FirebaseFirestore? firestore, FirebaseFunctions? functions})
      : _db = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  static const formatsCollection = 'test_formats';
  static const codesCollection = 'test_codes';
  static const sessionsCollection = 'test_sessions';
  static const attemptsCollection = 'test_attempts';
  static const resultsCollection = 'test_results';

  // ---------------------------------------------------------------- formats

  Stream<List<TestFormat>> watchFormats() => _db
      .collection(formatsCollection)
      .snapshots()
      .map((s) => s.docs.map(TestFormat.fromDoc).toList()
        ..sort((a, b) => a.order.compareTo(b.order)));

  /// Adds the standard formats that are missing; never overwrites one that
  /// exists (an edited format keeps its edit). Returns how many were added.
  Future<int> loadStandardFormats() async {
    final existing = await _db.collection(formatsCollection).get();
    final ids = existing.docs.map((d) => d.id).toSet();
    final missing =
        standardTestFormats().where((f) => !ids.contains(f.id)).toList();
    if (missing.isEmpty) return 0;
    final batch = _db.batch();
    for (final f in missing) {
      batch.set(_db.collection(formatsCollection).doc(f.id), {
        ...f.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    return missing.length;
  }

  Future<void> saveFormat(TestFormat format) =>
      _db.collection(formatsCollection).doc(format.id).set({
        ...format.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  // ------------------------------------------------------------------ codes

  Stream<List<TestCode>> watchCodes() => _db
      .collection(codesCollection)
      .snapshots()
      .map((s) => s.docs.map(TestCode.fromDoc).toList()
        ..sort((a, b) => a.code.compareTo(b.code)));

  /// Creates a code; refuses a code that already exists.
  Future<void> createCode(TestCode code, {required String createdBy}) async {
    final id = TestCode.normalize(code.code);
    final ref = _db.collection(codesCollection).doc(id);
    // Return a flag rather than throwing inside the transaction: on the web
    // an exception thrown there comes back wrapped and cannot be caught by
    // type.
    final created = await _db.runTransaction<bool>((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists) return false;
      tx.set(ref, {
        ...code.toMap(),
        'code': id,
        'createdBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    });
    if (!created) throw const DuplicateTestCodeException();
  }

  /// Saves the editable parts of a code (timing, marks, year, flags). The
  /// worksheet of a code never changes.
  Future<void> updateCode(TestCode code) =>
      _db.collection(codesCollection).doc(code.id).update({
        'format': code.toMap()['format'],
        'releaseYear': code.releaseYear,
        'active': code.active,
        'countsForPromotion': code.countsForPromotion,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> setCodeActive(String codeId, bool active) =>
      _db.collection(codesCollection).doc(codeId).update({
        'active': active,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  /// Per part: how many questions the format expects and how many the
  /// worksheet has (mirrors `splitIntoParts` in functions/supervised_test.js).
  static List<({TestSkill skill, int expected, int found})> partCounts(
    List<QuestionBankItem> sheetItems,
    List<TestPart> parts,
  ) {
    final found = List<int>.filled(parts.length, 0);
    for (final item in sheetItems) {
      final skill = switch (item.skillCategory) {
        ExerciseSkillCategory.listening => TestSkill.listening,
        ExerciseSkillCategory.typing => TestSkill.writing,
        ExerciseSkillCategory.speaking => TestSkill.speaking,
        _ => TestSkill.reading,
      };
      final candidates = [
        for (var i = 0; i < parts.length; i++)
          if (parts[i].skill == skill) i,
      ];
      if (candidates.isEmpty) continue;
      final open = candidates.where(
          (i) => parts[i].questions > 0 && found[i] < parts[i].questions);
      found[open.isNotEmpty ? open.first : candidates.last] += 1;
    }
    return [
      for (var i = 0; i < parts.length; i++)
        (skill: parts[i].skill, expected: parts[i].questions, found: found[i]),
    ];
  }

  // --------------------------------------------------------------- sessions

  /// Staff: every session (admin) or the ones the teacher opened, newest
  /// first.
  Stream<List<TestSession>> watchSessions({String? openedBy}) {
    Query<Map<String, dynamic>> q = _db.collection(sessionsCollection);
    if (openedBy != null) q = q.where('openedBy', isEqualTo: openedBy);
    return q.snapshots().map((s) => s.docs.map(TestSession.fromDoc).toList()
      ..sort((a, b) => (b.createdAt ?? DateTime(2100))
          .compareTo(a.createdAt ?? DateTime(2100))));
  }

  Stream<TestSession?> watchSession(String id) => _db
      .collection(sessionsCollection)
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? TestSession.fromDoc(d) : null);

  Stream<List<TestAttempt>> watchSessionAttempts(String sessionId) => _db
      .collection(attemptsCollection)
      .where('sessionId', isEqualTo: sessionId)
      .snapshots()
      .map((s) => s.docs.map(TestAttempt.fromDoc).toList()
        ..sort((a, b) => a.studentName.compareTo(b.studentName)));

  Future<OpenedSession> openSession(String codeId,
      {bool partClocks = true}) async {
    final r = await _functions
        .httpsCallable('openTestSession')
        .call({'codeId': codeId, 'partClocks': partClocks});
    return OpenedSession.fromServer(Map<String, dynamic>.from(r.data as Map));
  }

  /// A new token for an open session; extends its join window.
  Future<OpenedSession> newToken(String sessionId) async {
    final r = await _functions
        .httpsCallable('openTestSession')
        .call({'sessionId': sessionId});
    return OpenedSession.fromServer(Map<String, dynamic>.from(r.data as Map));
  }

  Future<int> closeSession(String sessionId) async {
    final r = await _functions
        .httpsCallable('closeTestSession')
        .call({'sessionId': sessionId});
    return ((r.data as Map)['finished'] as num?)?.toInt() ?? 0;
  }

  // --------------------------------------------------------------- results

  Stream<List<TestResult>> watchResults({String? codeId, String? openedBy}) {
    Query<Map<String, dynamic>> q = _db.collection(resultsCollection);
    if (codeId != null) q = q.where('codeId', isEqualTo: codeId);
    if (openedBy != null) q = q.where('openedBy', isEqualTo: openedBy);
    return q.snapshots().map((s) => s.docs.map(TestResult.fromDoc).toList()
      ..sort((a, b) => (b.finishedAt ?? DateTime(2000))
          .compareTo(a.finishedAt ?? DateTime(2000))));
  }

  Stream<List<TestResult>> watchMyResults(String uid) => _db
      .collection(resultsCollection)
      .where('studentId', isEqualTo: uid)
      .snapshots()
      .map((s) => s.docs.map(TestResult.fromDoc).toList()
        ..sort((a, b) => (b.finishedAt ?? DateTime(2000))
            .compareTo(a.finishedAt ?? DateTime(2000))));

  Stream<TestResult?> watchResult(String id) => _db
      .collection(resultsCollection)
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? TestResult.fromDoc(d) : null);

  /// The student's unfinished attempts (to resume after a reload).
  Stream<List<TestAttempt>> watchMyOpenAttempts(String uid) => _db
      .collection(attemptsCollection)
      .where('studentId', isEqualTo: uid)
      .snapshots()
      .map((s) => s.docs
          .map(TestAttempt.fromDoc)
          .where((a) => !a.finished)
          .toList());

  Stream<TestAttempt?> watchAttempt(String id) => _db
      .collection(attemptsCollection)
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? TestAttempt.fromDoc(d) : null);

  Future<void> setValidity(String resultId,
          {required bool valid, String reason = ''}) =>
      _functions.httpsCallable('setTestResultValidity').call({
        'resultId': resultId,
        'valid': valid,
        'reason': reason,
      });

  // ---------------------------------------------------------------- student

  /// Start-screen facts for a token (no clock starts).
  Future<TestFacts> peek(String token) async {
    final r = await _functions
        .httpsCallable('startTest')
        .call({'token': token, 'peek': true});
    return TestFacts.fromServer(Map<String, dynamic>.from(r.data as Map));
  }

  /// Joins with a token (or resumes with [codeId]) and returns the open part.
  Future<TestStep> start({String? token, String? codeId}) async {
    final r = await _functions.httpsCallable('startTest').call({
      if (token != null) 'token': token,
      if (codeId != null) 'codeId': codeId,
    });
    return TestStep.fromServer(Map<String, dynamic>.from(r.data as Map));
  }

  /// Submits the open part; returns the next part or the finish.
  Future<TestStep> submitPart(
    String codeId,
    int partIndex,
    Map<String, PlayAnswer> answers,
  ) async {
    final r = await _functions.httpsCallable('submitTestPart').call({
      'codeId': codeId,
      'partIndex': partIndex,
      'answers': answers.map((k, v) => MapEntry(k, v.toJson())),
    });
    return TestStep.fromServer(Map<String, dynamic>.from(r.data as Map));
  }

  Future<void> reportEvent(String codeId, {required bool left}) async {
    try {
      await _functions.httpsCallable('reportTestEvent').call({
        'codeId': codeId,
        'type': left ? 'left' : 'back',
      });
    } catch (_) {
      // Best effort: a lost event must never break the test.
    }
  }

  /// The review of a finished test, once its session is closed.
  Future<TestReview> review(String codeId) async {
    final r = await _functions
        .httpsCallable('getTestReview')
        .call({'codeId': codeId});
    return TestReview.fromServer(Map<String, dynamic>.from(r.data as Map));
  }

  // ------------------------------------------- answers kept on the device

  static String _answersKey(String codeId, int partIndex) =>
      'test_answers_${codeId}_$partIndex';

  /// Answers of the open part survive a reload: kept on this device until
  /// the part is submitted.
  static Future<void> keepAnswers(
      String codeId, int partIndex, Map<String, PlayAnswer> answers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _answersKey(codeId, partIndex),
        jsonEncode(answers.map((k, v) => MapEntry(k, v.toJson()))),
      );
    } catch (_) {}
  }

  static Future<Map<String, PlayAnswer>> keptAnswers(
      String codeId, int partIndex) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_answersKey(codeId, partIndex));
      if (raw == null) return {};
      final m = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final out = <String, PlayAnswer>{};
      for (final e in m.entries) {
        final a = playAnswerFromJson(Map<String, dynamic>.from(e.value as Map));
        if (a != null) out[e.key] = a;
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  /// Plays of each question's own clip in this test (at most two).
  static Future<void> keepClipPlays(
      String codeId, Map<String, int> plays) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('test_clips_$codeId', jsonEncode(plays));
    } catch (_) {}
  }

  static Future<Map<String, int>> keptClipPlays(String codeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('test_clips_$codeId');
      if (raw == null) return {};
      return Map<String, dynamic>.from(jsonDecode(raw) as Map)
          .map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  static Future<void> forgetAnswers(String codeId, int partIndex) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_answersKey(codeId, partIndex));
    } catch (_) {}
  }
}

PlayAnswer? playAnswerFromJson(Map<String, dynamic> m) {
  final index = (m['index'] as num?)?.toInt();
  if (index != null) return PlayAnswer.index(index);
  final order = m['order'];
  if (order is List) return PlayAnswer.order(order.map((e) => '$e').toList());
  final text = m['text'];
  if (text is String) return PlayAnswer.text(text);
  return null;
}

class DuplicateTestCodeException implements Exception {
  const DuplicateTestCodeException();
}

/// What `openTestSession` returns.
class OpenedSession {
  const OpenedSession({
    required this.sessionId,
    required this.token,
    required this.joinUntil,
  });

  final String sessionId;
  final String token;
  final DateTime joinUntil;

  factory OpenedSession.fromServer(Map<String, dynamic> m) => OpenedSession(
        sessionId: m['sessionId'] as String? ?? '',
        token: m['token'] as String? ?? '',
        joinUntil: DateTime.fromMillisecondsSinceEpoch(
            (m['joinUntilMillis'] as num?)?.toInt() ?? 0),
      );
}

/// The start screen: code, level, parts with minutes.
class TestFacts {
  const TestFacts({
    required this.codeId,
    required this.code,
    required this.family,
    required this.level,
    required this.levelKey,
    required this.parts,
    required this.passMark,
    required this.partClocks,
    this.releaseYear,
    this.started = false,
  });

  final String codeId;
  final String code;
  final TestFamily family;
  final String level;
  final String levelKey;
  final List<TestPart> parts;
  final int passMark;
  final bool partClocks;
  final int? releaseYear;
  final bool started;

  int get maxTotal => parts.fold<int>(0, (n, p) => n + p.maxScore);
  int get totalMinutes => parts.fold<int>(0, (n, p) => n + p.minutes);

  factory TestFacts.fromServer(Map<String, dynamic> m) => TestFacts(
        codeId: m['codeId'] as String? ?? '',
        code: m['code'] as String? ?? '',
        family: TestFamily.fromValue(m['family'] as String?),
        level: m['level'] as String? ?? '',
        levelKey: m['levelKey'] as String? ?? '',
        parts: (m['parts'] as List? ?? const [])
            .map((p) => TestPart.fromMap(Map<String, dynamic>.from(p as Map)))
            .toList(),
        passMark: (m['passMark'] as num?)?.toInt() ?? 0,
        partClocks: m['partClocks'] != false,
        releaseYear: (m['releaseYear'] as num?)?.toInt(),
        started: m['started'] == true,
      );
}

/// One step of a test: the open part (or the whole paper when the session
/// runs one clock), or the finish.
class TestStep {
  const TestStep({
    required this.facts,
    required this.finished,
    this.resultId,
    this.attemptId,
    this.partIndex = 0,
    this.partCount = 0,
    this.skill = TestSkill.reading,
    this.questions = const [],
    this.secondsLeft = 0,
    this.partSeconds = 0,
    this.elapsedSeconds = 0,
    this.recordingUrl = '',
  });

  final TestFacts facts;
  final bool finished;
  final String? resultId;

  /// `{codeId}_{uid}`: also the id of the result.
  final String? attemptId;
  final int partIndex;
  final int partCount;
  final TestSkill skill;
  final List<PlayQuestion> questions;
  final int secondsLeft;
  final int partSeconds;

  /// Seconds since the part started: where the recording continues.
  final int elapsedSeconds;
  final String recordingUrl;

  bool get isLastPart => partIndex + 1 >= partCount;

  factory TestStep.fromServer(Map<String, dynamic> m) => TestStep(
        facts: TestFacts.fromServer(m),
        finished: m['finished'] == true,
        resultId: m['resultId'] as String?,
        attemptId: m['attemptId'] as String?,
        partIndex: (m['partIndex'] as num?)?.toInt() ?? 0,
        partCount: (m['partCount'] as num?)?.toInt() ?? 0,
        skill: TestSkill.fromValue(m['skill'] as String?),
        questions: (m['questions'] as List? ?? const [])
            .map((q) =>
                PlayQuestion.fromServer(Map<String, dynamic>.from(q as Map)))
            .toList(),
        secondsLeft: (m['secondsLeft'] as num?)?.toInt() ?? 0,
        partSeconds: (m['partSeconds'] as num?)?.toInt() ?? 0,
        elapsedSeconds: (m['elapsedSeconds'] as num?)?.toInt() ?? 0,
        recordingUrl: m['recordingUrl'] as String? ?? '',
      );
}

/// One question of the review: the question, the student's answer and the
/// key with the explanation.
class TestReviewItem {
  const TestReviewItem({
    required this.question,
    required this.partIndex,
    required this.answer,
    required this.check,
  });

  final PlayQuestion question;
  final int partIndex;
  final PlayAnswer? answer;
  final AnswerCheck check;
}

class TestReview {
  const TestReview({required this.items, required this.recordings});

  final List<TestReviewItem> items;

  /// Recording per part index (listening parts only).
  final Map<int, String> recordings;

  factory TestReview.fromServer(Map<String, dynamic> m) => TestReview(
        items: (m['items'] as List? ?? const []).map((raw) {
          final it = Map<String, dynamic>.from(raw as Map);
          final ans = it['answer'];
          return TestReviewItem(
            question: PlayQuestion.fromServer(
                Map<String, dynamic>.from(it['question'] as Map)),
            partIndex: (it['partIndex'] as num?)?.toInt() ?? 0,
            answer: ans is Map
                ? playAnswerFromJson(Map<String, dynamic>.from(ans))
                : null,
            check: AnswerCheck.fromServer(
                Map<String, dynamic>.from(it['review'] as Map)),
          );
        }).toList(),
        recordings: {
          for (final e in Map<String, dynamic>.from(
                  m['recordings'] as Map? ?? const {})
              .entries)
            int.tryParse(e.key) ?? 0: '${e.value}',
        },
      );
}
