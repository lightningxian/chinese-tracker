import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/board_check.dart';

/// Build 7 (docs/PLAN.md §4): the teaching day. Everything that changes a
/// session's life or a voucher goes through a function: check-in, the close
/// (one transaction with the voucher ledger), substitutes, cancellations,
/// confirmations and change requests.
class TeachingDayException implements Exception {
  const TeachingDayException(this.reason, this.message);
  final String reason;
  final String message;

  @override
  String toString() => message;
}

/// The answer of `closeSession`.
class CloseResult {
  const CloseResult({
    required this.credited,
    required this.excused,
    required this.failed,
    required this.already,
  });

  final int credited;
  final int excused;
  final List<String> failed;
  final bool already;

  factory CloseResult.fromMap(Map<String, dynamic> m) => CloseResult(
        credited: (m['credited'] as num?)?.toInt() ?? 0,
        excused: (m['excused'] as num?)?.toInt() ?? 0,
        failed: [for (final f in (m['failed'] as List? ?? const [])) '$f'],
        already: m['already'] == true,
      );
}

class ChangeRequest {
  const ChangeRequest({
    required this.id,
    required this.scheduleId,
    required this.teacherId,
    required this.teacherName,
    required this.className,
    required this.reason,
    required this.wanted,
    required this.status,
    required this.note,
    this.createdAt,
  });

  final String id;
  final String scheduleId;
  final String teacherId;
  final String teacherName;
  final String className;
  final String reason;
  final String wanted;
  final String status;
  final String note;
  final DateTime? createdAt;

  bool get isOpen => status == 'open';

  factory ChangeRequest.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const <String, dynamic>{};
    String s(String k) => m[k] as String? ?? '';
    return ChangeRequest(
      id: d.id,
      scheduleId: s('scheduleId'),
      teacherId: s('teacherId'),
      teacherName: s('teacherName'),
      className: s('className'),
      reason: s('reason'),
      wanted: s('wanted'),
      status: s('status'),
      note: s('note'),
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class RecapRow {
  const RecapRow({
    required this.teacherId,
    required this.teacherName,
    required this.scheduled,
    required this.held,
    required this.cancelled,
    required this.lateCheckIns,
    required this.hours,
  });

  final String teacherId;
  final String teacherName;
  final int scheduled;
  final int held;
  final int cancelled;
  final int lateCheckIns;
  final double hours;

  factory RecapRow.fromMap(Map<String, dynamic> m) {
    int i(String k) => (m[k] as num?)?.toInt() ?? 0;
    return RecapRow(
      teacherId: m['teacherId'] as String? ?? '',
      teacherName: m['teacherName'] as String? ?? '',
      scheduled: i('scheduled'),
      held: i('held'),
      cancelled: i('cancelled'),
      lateCheckIns: i('lateCheckIns'),
      hours: (m['hours'] as num?)?.toDouble() ?? 0,
    );
  }
}

class Mismatch {
  const Mismatch(this.termId, this.studentId, this.problems);
  final String termId;
  final String studentId;
  final List<String> problems;
}

class TeachingDayService {
  TeachingDayService({FirebaseFirestore? firestore, FirebaseFunctions? functions})
      : _db = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  Future<Map<String, dynamic>> _call(String name, Map<String, dynamic> data) async {
    try {
      final r = await _functions.httpsCallable(name).call(data);
      final d = r.data;
      return d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{};
    } on FirebaseFunctionsException catch (e) {
      final d = e.details;
      throw TeachingDayException(
          d is Map ? '${d['reason'] ?? ''}' : e.code, e.message ?? e.code);
    }
  }

  Future<int> checkIn(String sessionId) async {
    final m = await _call('checkInSession', {'sessionId': sessionId});
    return (m['lateMinutes'] as num?)?.toInt() ?? 0;
  }

  /// [statuses]: studentId → `hadir` / `izin` / `alpa`.
  Future<CloseResult> close(String sessionId, Map<String, String> statuses,
      {BoardCheck? board}) async {
    var mismatches = 0;
    if (board != null) {
      final d = BoardCheck.differences(
          statusById: statuses, board: board.board, nameById: const {}, extras: board.extras);
      mismatches = d.presentNotSigned.length + d.signedNotPresent.length + d.notBooked.length;
    }
    return CloseResult.fromMap(await _call('closeSession', {
      'sessionId': sessionId,
      'statuses': statuses,
      if (board != null) ...{
        'board': board.board,
        'boardExtras': board.extras,
        'boardMismatches': mismatches,
      },
    }));
  }

  Future<void> cancel(String sessionId) => _call('cancelSession', {'sessionId': sessionId});

  Future<List<({String uid, String name})>> substituteCandidates(String sessionId) async {
    final m = await _call('substituteCandidates', {'sessionId': sessionId});
    return [
      for (final c in (m['candidates'] as List? ?? const []))
        if (c is Map) (uid: '${c['uid']}', name: '${c['name']}'),
    ];
  }

  Future<void> assignSubstitute(String sessionId, String teacherId) =>
      _call('assignSubstitute', {'sessionId': sessionId, 'teacherId': teacherId});

  Future<void> confirmSchedule(String scheduleId) =>
      _call('confirmSchedule', {'scheduleId': scheduleId});

  Future<void> requestChange(String scheduleId, String reason, String wanted) =>
      _call('requestScheduleChange',
          {'scheduleId': scheduleId, 'reason': reason, 'wanted': wanted});

  Future<void> resolveChange(String requestId, {required bool accept, String note = ''}) =>
      _call('resolveScheduleChange', {'requestId': requestId, 'accept': accept, 'note': note});

  /// The teacher's own requests, or every request for an admin (null).
  Stream<List<ChangeRequest>> watchChangeRequests({String? teacherId}) {
    Query<Map<String, dynamic>> q = _db.collection('schedule_change_requests');
    if (teacherId != null) q = q.where('teacherId', isEqualTo: teacherId);
    return q.snapshots().map((s) => s.docs.map(ChangeRequest.fromDoc).toList()
      ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0))));
  }

  Future<List<RecapRow>> recap(String month) async {
    final m = await _call('teacherRecap', {'month': month});
    return [
      for (final r in (m['rows'] as List? ?? const []))
        if (r is Map) RecapRow.fromMap(Map<String, dynamic>.from(r)),
    ];
  }

  Future<({int checked, List<Mismatch> mismatches})> reconcile() async {
    final m = await _call('reconcileVouchers', {});
    return (
      checked: (m['checked'] as num?)?.toInt() ?? 0,
      mismatches: [
        for (final x in (m['mismatches'] as List? ?? const []))
          if (x is Map)
            Mismatch('${x['termId']}', '${x['studentId']}',
                [for (final p in (x['problems'] as List? ?? const [])) '$p']),
      ],
    );
  }
}
