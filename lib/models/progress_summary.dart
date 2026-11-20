import 'package:cloud_firestore/cloud_firestore.dart';

/// Build 4 (docs/PLAN.md §4): `progress_summary/{studentId}`, written only
/// by functions (functions/progress.js). Times are milliseconds.

int? _int(Object? v) => v is num ? v.round() : null;
double? _double(Object? v) => v is num ? v.toDouble() : null;
DateTime? _ms(Object? v) =>
    v is num ? DateTime.fromMillisecondsSinceEpoch(v.toInt()) : null;
Map<String, dynamic> _map(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : const <String, dynamic>{};
List<Map<String, dynamic>> _list(Object? v) => v is List
    ? [for (final x in v) if (x is Map) Map<String, dynamic>.from(x)]
    : const [];

/// The status label: 0 warnings = good, 1 = attention, 2+ = follow_up.
enum ProgressStatus {
  good('good'),
  attention('attention'),
  followUp('follow_up');

  const ProgressStatus(this.value);
  final String value;

  static ProgressStatus fromValue(String? v) =>
      values.firstWhere((s) => s.value == v, orElse: () => ProgressStatus.good);
}

class PracticeWeek {
  const PracticeWeek({
    required this.week,
    required this.monday,
    required this.average,
    required this.attempts,
  });

  final String week;
  final String monday;
  final double? average;
  final int attempts;
}

class ProgressWarning {
  const ProgressWarning({required this.id, required this.since, required this.detail});

  /// 1 attendance, 2 score drop, 3 inactive, 4 voucher, 5 two failed tests.
  final int id;
  final DateTime? since;
  final String detail;
}

class SkillAverage {
  const SkillAverage({required this.skill, required this.percent, required this.total});

  final String skill;
  final int percent;
  final int total;
}

class ProgressTestRow {
  const ProgressTestRow({
    required this.resultId,
    required this.codeId,
    required this.code,
    required this.level,
    required this.finishedAt,
    required this.parts,
    required this.total,
    required this.max,
    required this.passed,
    required this.valid,
    required this.status,
    required this.placement,
    required this.rank,
    required this.boardSize,
  });

  final String resultId;
  final String codeId;
  final String code;
  final String level;
  final DateTime? finishedAt;
  final List<({String skill, int mark, int maxScore})> parts;
  final int total;
  final int max;
  final bool passed;
  final bool valid;
  final String status;
  final bool placement;
  final int? rank;
  final int? boardSize;

  bool get pendingMarking => status == 'pending_marking';
}

class ProgressSummary {
  const ProgressSummary({
    required this.studentId,
    required this.studentName,
    required this.studentNameChinese,
    required this.teacherId,
    required this.level,
    required this.group,
    required this.codesCount,
    required this.minCodes,
    required this.nextLevel,
    required this.weeks,
    required this.average14,
    required this.attempts14,
    required this.averagePrev14,
    required this.attemptsPrev14,
    required this.lastPractice,
    required this.attempts90,
    required this.skills,
    required this.tests,
    required this.passedAtLevel,
    required this.attendancePercent,
    required this.hadir,
    required this.izin,
    required this.alpa,
    required this.attendanceLast,
    required this.sessionsRemaining,
    required this.deadlineDate,
    required this.daysLeft,
    required this.hasVoucher,
    required this.latestNote,
    required this.levelHistory,
    required this.warnings,
    required this.status,
    required this.updatedAt,
  });

  final String studentId;
  final String studentName;
  final String studentNameChinese;
  final String teacherId;
  final String level;
  final String group;
  final int codesCount;
  final int minCodes;
  final String nextLevel;
  final List<PracticeWeek> weeks;
  final double? average14;
  final int attempts14;
  final double? averagePrev14;
  final int attemptsPrev14;
  final DateTime? lastPractice;
  final int attempts90;
  final List<SkillAverage> skills;
  final List<ProgressTestRow> tests;
  final int passedAtLevel;
  final int? attendancePercent;
  final int hadir;
  final int izin;
  final int alpa;
  final List<({String sessionDate, String status, String title})> attendanceLast;
  final int sessionsRemaining;
  final String deadlineDate;
  final int? daysLeft;
  final bool hasVoucher;
  final ({String text, String teacherName, DateTime? createdAt})? latestNote;
  final List<({String from, String to, String kind, DateTime? date})> levelHistory;
  final List<ProgressWarning> warnings;
  final ProgressStatus status;
  final DateTime? updatedAt;

  /// Change of the 14-day practice average against the 14 days before.
  double? get practiceChange => average14 != null && averagePrev14 != null
      ? average14! - averagePrev14!
      : null;

  factory ProgressSummary.fromMap(String id, Map<String, dynamic> m) {
    final codes = _map(m['codes']);
    final practice = _map(m['practice']);
    final tests = _map(m['tests']);
    final att = _map(m['attendance']);
    final voucher = m['voucher'] is Map ? _map(m['voucher']) : null;
    final note = m['latestNote'] is Map ? _map(m['latestNote']) : null;
    const skillOrder = ['listening', 'reading', 'typing', 'writing', 'speaking'];
    final skillMap = _map(m['skills']);
    final skills = [
      for (final e in skillMap.entries)
        SkillAverage(
          skill: e.key,
          percent: _int(_map(e.value)['percent']) ?? 0,
          total: _int(_map(e.value)['total']) ?? 0,
        ),
    ]..sort((a, b) {
        final ia = skillOrder.indexOf(a.skill);
        final ib = skillOrder.indexOf(b.skill);
        return (ia < 0 ? 99 : ia).compareTo(ib < 0 ? 99 : ib);
      });
    return ProgressSummary(
      studentId: id,
      studentName: m['studentName'] as String? ?? '',
      studentNameChinese: m['studentNameChinese'] as String? ?? '',
      teacherId: m['teacherId'] as String? ?? '',
      level: m['level'] as String? ?? '',
      group: m['group'] as String? ?? '',
      codesCount: _int(codes['count']) ?? 0,
      minCodes: _int(codes['minCodes']) ?? 3,
      nextLevel: codes['next'] as String? ?? '',
      weeks: [
        for (final w in _list(practice['weeks']))
          PracticeWeek(
            week: w['week'] as String? ?? '',
            monday: w['monday'] as String? ?? '',
            average: _double(w['average']),
            attempts: _int(w['attempts']) ?? 0,
          ),
      ],
      average14: _double(practice['average14']),
      attempts14: _int(practice['attempts14']) ?? 0,
      averagePrev14: _double(practice['averagePrev14']),
      attemptsPrev14: _int(practice['attemptsPrev14']) ?? 0,
      lastPractice: _ms(practice['lastPracticeMs']),
      attempts90: _int(practice['attempts90']) ?? 0,
      skills: skills,
      tests: [
        for (final t in _list(tests['history']))
          ProgressTestRow(
            resultId: t['resultId'] as String? ?? '',
            codeId: t['codeId'] as String? ?? '',
            code: t['code'] as String? ?? '',
            level: t['level'] as String? ?? '',
            finishedAt: _ms(t['finishedAtMs']),
            parts: [
              for (final p in _list(t['parts']))
                (
                  skill: p['skill'] as String? ?? '',
                  mark: _int(p['mark']) ?? 0,
                  maxScore: _int(p['maxScore']) ?? 0,
                ),
            ],
            total: _int(t['total']) ?? 0,
            max: _int(t['max']) ?? 0,
            passed: t['passed'] == true,
            valid: t['valid'] != false,
            status: t['status'] as String? ?? 'final',
            placement: t['placement'] == true,
            rank: _int(t['rank']),
            boardSize: _int(t['boardSize']),
          ),
      ],
      passedAtLevel: _int(tests['passedAtLevel']) ?? 0,
      attendancePercent: _int(att['percent']),
      hadir: _int(att['hadir']) ?? 0,
      izin: _int(att['izin']) ?? 0,
      alpa: _int(att['alpa']) ?? 0,
      attendanceLast: [
        for (final r in _list(att['last']))
          (
            sessionDate: r['sessionDate'] as String? ?? '',
            status: r['status'] as String? ?? '',
            title: r['title'] as String? ?? '',
          ),
      ],
      hasVoucher: voucher != null,
      sessionsRemaining: _int(voucher?['sessionsRemaining']) ?? 0,
      deadlineDate: voucher?['deadlineDate'] as String? ?? '',
      daysLeft: _int(voucher?['daysLeft']),
      latestNote: note == null || (note['text'] as String? ?? '').isEmpty
          ? null
          : (
              text: note['text'] as String? ?? '',
              teacherName: note['teacherName'] as String? ?? '',
              createdAt: _ms(note['createdAtMs']),
            ),
      levelHistory: [
        for (final h in _list(m['levelHistory']))
          (
            from: h['from'] as String? ?? '',
            to: h['to'] as String? ?? '',
            kind: h['kind'] as String? ?? 'promotion',
            date: _ms(h['dateMs']),
          ),
      ],
      warnings: [
        for (final w in _list(m['warnings']))
          ProgressWarning(
            id: _int(w['id']) ?? 0,
            since: _ms(w['since']),
            detail: w['detail'] as String? ?? '',
          ),
      ],
      status: ProgressStatus.fromValue(m['status'] as String?),
      updatedAt: (m['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory ProgressSummary.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) =>
      ProgressSummary.fromMap(d.id, d.data() ?? const {});
}

/// The chart's points: one per week that has practice (x = week index
/// 0..11, oldest first; y = the average score). Weeks without practice
/// leave a gap, so the line does not drop to zero.
List<({double x, double y})> practiceChartPoints(List<PracticeWeek> weeks) => [
      for (var i = 0; i < weeks.length; i++)
        if (weeks[i].average != null)
          (x: i.toDouble(), y: weeks[i].average!.clamp(0, 100).toDouble()),
    ];

/// A teacher's follow-up note (`progress_notes/{id}`).
class ProgressNote {
  const ProgressNote({
    required this.id,
    required this.studentId,
    required this.teacherId,
    required this.teacherName,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String studentId;
  final String teacherId;
  final String teacherName;
  final String text;
  final DateTime? createdAt;

  factory ProgressNote.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const <String, dynamic>{};
    return ProgressNote(
      id: d.id,
      studentId: m['studentId'] as String? ?? '',
      teacherId: m['teacherId'] as String? ?? '',
      teacherName: m['teacherName'] as String? ?? '',
      text: m['text'] as String? ?? '',
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
