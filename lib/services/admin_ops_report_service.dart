import 'package:intl/intl.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/level_utils.dart';
import '../models/app_user.dart';
import '../models/attendance_record.dart';
import '../models/class_session.dart';
import '../models/exercise.dart';
import '../models/exercise_assignment.dart';
import '../models/exercise_result.dart';
import '../models/invoice.dart';
import '../models/student_class_term.dart';

/// One calendar month, used as a bucket key and label in every monthly report.
class ReportMonth implements Comparable<ReportMonth> {
  const ReportMonth(this.year, this.month);

  factory ReportMonth.of(DateTime d) => ReportMonth(d.year, d.month);

  final int year;
  final int month;

  /// "Nov 2026" in the app language (Intl.defaultLocale); screens use it.
  String get label => DateFormat('MMM yyyy').format(DateTime(year, month));

  /// Always English, for the PDF reports.
  String get labelEn =>
      DateFormat('MMM yyyy', 'en_US').format(DateTime(year, month));

  /// The [count] months ending with the month of [now], oldest first.
  static List<ReportMonth> last(int count, DateTime now) => [
        for (var i = count - 1; i >= 0; i--)
          ReportMonth.of(DateTime(now.year, now.month - i, 1)),
      ];

  bool contains(DateTime? d) => d != null && d.year == year && d.month == month;

  @override
  int compareTo(ReportMonth other) =>
      year != other.year ? year - other.year : month - other.month;

  @override
  bool operator ==(Object other) =>
      other is ReportMonth && other.year == year && other.month == month;

  @override
  int get hashCode => year * 12 + month;
}

// ─── 1. Attendance per student per month ────────────────────────────────────

class AttendanceStudentRow {
  const AttendanceStudentRow({
    required this.studentId,
    required this.name,
    required this.level,
    required this.hadir,
    required this.izin,
    required this.alpa,
  });

  final String studentId;
  final String name;
  final String level;
  final int hadir;
  final int izin;
  final int alpa;

  int get total => hadir + izin + alpa;
  int get presentPercent => total == 0 ? 0 : (hadir * 100 / total).round();
}

class AttendanceMonth {
  const AttendanceMonth({required this.month, required this.rows});

  final ReportMonth month;
  final List<AttendanceStudentRow> rows;

  int get hadir => rows.fold(0, (s, r) => s + r.hadir);
  int get izin => rows.fold(0, (s, r) => s + r.izin);
  int get alpa => rows.fold(0, (s, r) => s + r.alpa);
  int get total => hadir + izin + alpa;
  int get presentPercent => total == 0 ? 0 : (hadir * 100 / total).round();
}

// ─── 2. Term balance alerts ─────────────────────────────────────────────────

enum TermAlertKind { lowBalance, expiringSoon, expiredWithBalance }

class TermAlertRow {
  const TermAlertRow({
    required this.studentId,
    required this.name,
    required this.level,
    required this.voucherCode,
    required this.sessionsRemaining,
    required this.packageSize,
    required this.deadline,
    required this.daysLeft,
    required this.kinds,
  });

  final String studentId;
  final String name;
  final String level;
  final String voucherCode;
  final int sessionsRemaining;
  final int packageSize;
  final DateTime? deadline;

  /// Negative when the deadline has passed. Null without a deadline.
  final int? daysLeft;
  final Set<TermAlertKind> kinds;

  String get reason => [
        if (kinds.contains(TermAlertKind.lowBalance))
          '$sessionsRemaining session${sessionsRemaining == 1 ? '' : 's'} left',
        if (kinds.contains(TermAlertKind.expiringSoon))
          'expires in ${daysLeft ?? 0} day${daysLeft == 1 ? '' : 's'}',
        if (kinds.contains(TermAlertKind.expiredWithBalance))
          'expired ${-(daysLeft ?? 0)} day${daysLeft == -1 ? '' : 's'} ago '
              'with $sessionsRemaining left',
      ].join(' · ');
}

class TermAlertsReport {
  const TermAlertsReport({required this.rows, required this.activeTerms});

  final List<TermAlertRow> rows;
  final int activeTerms;

  int count(TermAlertKind kind) =>
      rows.where((r) => r.kinds.contains(kind)).length;
}

// ─── 3. Revenue per month ───────────────────────────────────────────────────

class RevenueMonth {
  const RevenueMonth({
    required this.month,
    required this.package8,
    required this.package16,
    required this.book,
    required this.other,
    required this.invoices,
  });

  final ReportMonth month;
  final int package8;
  final int package16;
  final int book;
  final int other;
  final int invoices;

  int get total => package8 + package16 + book + other;
}

class OutstandingInvoiceRow {
  const OutstandingInvoiceRow({
    required this.invoiceNumber,
    required this.studentName,
    required this.itemLabel,
    required this.amount,
    required this.dueDate,
    required this.daysOverdue,
  });

  final String invoiceNumber;
  final String studentName;
  final String itemLabel;
  final int amount;
  final DateTime? dueDate;

  /// 0 while not yet due.
  final int daysOverdue;

  bool get isOverdue => daysOverdue > 0;
}

class RevenueReport {
  const RevenueReport({required this.months, required this.outstanding});

  final List<RevenueMonth> months;

  /// Pending invoices, most overdue first.
  final List<OutstandingInvoiceRow> outstanding;

  RevenueMonth get thisMonth => months.last;
  int get outstandingAmount => outstanding.fold(0, (s, r) => s + r.amount);
  List<OutstandingInvoiceRow> get overdue =>
      outstanding.where((r) => r.isOverdue).toList();
  int get overdueAmount => overdue.fold(0, (s, r) => s + r.amount);
}

// ─── 4. New students & retention ────────────────────────────────────────────

class CohortRow {
  const CohortRow({
    required this.month,
    required this.joined,
    required this.stillActive,
  });

  final ReportMonth month;
  final int joined;
  final int stillActive;

  int get retentionPercent =>
      joined == 0 ? 0 : (stillActive * 100 / joined).round();
}

class RetentionReport {
  const RetentionReport({
    required this.cohorts,
    required this.totalStudents,
    required this.activeStudents,
    required this.eligible,
    required this.retained,
  });

  /// New students per join month (last 6 months) and how many are still active.
  final List<CohortRow> cohorts;
  final int totalStudents;

  /// Students counted as active today: account active and (a class term with
  /// sessions left, or a class attended in the last 30 days).
  final int activeStudents;

  /// Students who joined more than 60 days ago (old enough to measure).
  final int eligible;

  /// Of [eligible], how many are still active.
  final int retained;

  int get retentionPercent =>
      eligible == 0 ? 0 : (retained * 100 / eligible).round();
  int get newThisMonth => cohorts.last.joined;
}

// ─── 5. Class fill rate ─────────────────────────────────────────────────────

class SessionFillRow {
  const SessionFillRow({
    required this.date,
    required this.title,
    required this.teacherName,
    required this.joined,
    required this.capacity,
    required this.concluded,
  });

  final String date;
  final String title;
  final String teacherName;
  final int joined;
  final int capacity;
  final bool concluded;

  int get fillPercent => capacity == 0 ? 0 : (joined * 100 / capacity).round();
}

class FillRateMonth {
  const FillRateMonth({required this.month, required this.sessions});

  final ReportMonth month;
  final List<SessionFillRow> sessions;

  int get classes => sessions.length;
  int get capacity => sessions.fold(0, (s, r) => s + r.capacity);
  int get joined => sessions.fold(0, (s, r) => s + r.joined);
  int get fillPercent => capacity == 0 ? 0 : (joined * 100 / capacity).round();
  int get empty => sessions.where((s) => s.joined == 0).length;
  int get full => sessions.where((s) => s.joined >= s.capacity).length;
}

// ─── 6. Teacher recap per month ─────────────────────────────────────────────

class TeacherMonthRow {
  const TeacherMonthRow({
    required this.teacherId,
    required this.name,
    required this.scheduled,
    required this.concluded,
    required this.teachingMinutes,
    required this.studentsTaught,
    required this.hadir,
    required this.marked,
  });

  final String teacherId;
  final String name;
  final int scheduled;
  final int concluded;
  final int teachingMinutes;
  final int studentsTaught;

  /// Present marks and all marks (hadir + izin + alpa) in concluded classes.
  final int hadir;
  final int marked;

  double get teachingHours => teachingMinutes / 60;
  int get attendancePercent => marked == 0 ? 0 : (hadir * 100 / marked).round();
}

class TeacherRecapMonth {
  const TeacherRecapMonth({required this.month, required this.rows});

  final ReportMonth month;
  final List<TeacherMonthRow> rows;
}

// ─── 7. Student progress per HSK level ──────────────────────────────────────

class StudentProgressRow {
  const StudentProgressRow({
    required this.studentId,
    required this.name,
    required this.level,
    required this.assigned,
    required this.completed,
    required this.averageScore,
    required this.lastActivity,
  });

  final String studentId;
  final String name;
  final String level;
  final int assigned;
  final int completed;
  final int? averageScore;
  final DateTime? lastActivity;

  int get completionPercent =>
      assigned == 0 ? 0 : (completed * 100 / assigned).round();
}

class LevelProgressRow {
  const LevelProgressRow({required this.level, required this.students});

  final String level;
  final List<StudentProgressRow> students;

  int get studentCount => students.length;
  int get assigned => students.fold(0, (s, r) => s + r.assigned);
  int get completed => students.fold(0, (s, r) => s + r.completed);
  int get completionPercent =>
      assigned == 0 ? 0 : (completed * 100 / assigned).round();
  int get inactive => students.where((s) => s.lastActivity == null).length;

  int? get averageScore {
    final scores =
        students.map((s) => s.averageScore).whereType<int>().toList();
    if (scores.isEmpty) return null;
    return (scores.reduce((a, b) => a + b) / scores.length).round();
  }
}

// ─── 8. Overdue homework per teacher ────────────────────────────────────────

class OverdueHomeworkRow {
  const OverdueHomeworkRow({
    required this.studentId,
    required this.studentName,
    required this.exerciseTitle,
    required this.dueDate,
    required this.daysOverdue,
  });

  final String studentId;
  final String studentName;
  final String exerciseTitle;
  final DateTime dueDate;
  final int daysOverdue;
}

class TeacherOverdueGroup {
  const TeacherOverdueGroup({
    required this.teacherId,
    required this.teacherName,
    required this.rows,
  });

  final String teacherId;
  final String teacherName;

  /// Most overdue first.
  final List<OverdueHomeworkRow> rows;

  int get count => rows.length;
  int get students => rows.map((r) => r.studentId).toSet().length;
}

class OverdueHomeworkReport {
  const OverdueHomeworkReport({required this.groups, required this.open});

  /// Teachers with the most overdue homework first.
  final List<TeacherOverdueGroup> groups;

  /// Assignments without a result yet (overdue or not).
  final int open;

  int get total => groups.fold(0, (s, g) => s + g.count);
}

// ─── Aggregate ──────────────────────────────────────────────────────────────

class AdminOpsReportData {
  const AdminOpsReportData({
    required this.generatedAt,
    required this.attendance,
    required this.termAlerts,
    required this.revenue,
    required this.retention,
    required this.fillRate,
    required this.teacherRecap,
    required this.progressByLevel,
    required this.overdueHomework,
  });

  final DateTime generatedAt;
  final List<AttendanceMonth> attendance;
  final TermAlertsReport termAlerts;
  final RevenueReport revenue;
  final RetentionReport retention;
  final List<FillRateMonth> fillRate;
  final List<TeacherRecapMonth> teacherRecap;
  final List<LevelProgressRow> progressByLevel;
  final OverdueHomeworkReport overdueHomework;
}

/// Pure calculations for the eight operational reports on the admin Reports
/// tab. Everything is computed from the full collections the admin already
/// streams, so there is nothing to keep in sync server-side.
abstract final class AdminOpsReportService {
  static const monthsShown = 6;

  static AdminOpsReportData build({
    required List<AppUser> users,
    required List<Exercise> exercises,
    required List<StudentClassTerm> classTerms,
    required List<AttendanceRecord> attendance,
    required List<ClassSession> sessions,
    required List<Invoice> invoices,
    required List<ExerciseAssignment> assignments,
    required List<ExerciseResult> results,
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();
    final usersById = {for (final u in users) u.uid: u};
    final students = users.where((u) => u.isStudent).toList();
    return AdminOpsReportData(
      generatedAt: at,
      attendance: attendanceByMonth(
        attendance: attendance,
        sessions: sessions,
        usersById: usersById,
        now: at,
      ),
      termAlerts: termAlerts(
        classTerms: classTerms,
        usersById: usersById,
        now: at,
      ),
      revenue: revenue(invoices: invoices, now: at),
      retention: retention(
        students: students,
        classTerms: classTerms,
        attendance: attendance,
        now: at,
      ),
      fillRate: fillRate(
        sessions: sessions,
        attendance: attendance,
        usersById: usersById,
        now: at,
      ),
      teacherRecap: teacherRecap(
        sessions: sessions,
        attendance: attendance,
        users: users,
        now: at,
      ),
      progressByLevel: progressByLevel(
        students: students,
        assignments: assignments,
        results: results,
      ),
      overdueHomework: overdueHomework(
        assignments: assignments,
        results: results,
        exercises: exercises,
        usersById: usersById,
        now: at,
      ),
    );
  }

  // ── helpers ──

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  static int _daysBetween(DateTime from, DateTime to) =>
      _day(to).difference(_day(from)).inDays;

  static String _name(Map<String, AppUser> usersById, String id,
          {String? fallback}) =>
      usersById[id]?.displayNameIndonesian ?? fallback ?? 'Unknown ($id)';

  static String _level(AppUser? u) =>
      LevelUtils.normalizeHskLevel(u?.level) ?? u?.level ?? '—';

  /// Which bucket a record counts in, or null while the class is still open.
  static String? _attendanceBucket(
    AttendanceRecord r,
    Set<String> concludedSessionIds,
    Set<String> knownSessionIds,
  ) {
    final status = r.normalizedStatus;
    if (status != null) return status;
    if (r.attended || r.sessionCredited) return AttendanceRecord.hadir;
    // No status and not credited: absent in a concluded class (before the
    // Hadir/Izin/Alpa marks existed), or just joined an open class.
    if (concludedSessionIds.contains(r.sessionId)) return AttendanceRecord.alpa;
    return null;
  }

  // ── 1 ──

  static List<AttendanceMonth> attendanceByMonth({
    required List<AttendanceRecord> attendance,
    required List<ClassSession> sessions,
    required Map<String, AppUser> usersById,
    required DateTime now,
  }) {
    final concluded =
        sessions.where((s) => s.isConcluded).map((s) => s.id).toSet();
    final known = sessions.map((s) => s.id).toSet();
    final months = ReportMonth.last(monthsShown, now);
    final out = <AttendanceMonth>[];
    for (final month in months) {
      final counts = <String, List<int>>{}; // studentId -> [hadir, izin, alpa]
      for (final r in attendance) {
        final date = DateTime.tryParse(r.sessionDate);
        if (!month.contains(date)) continue;
        final bucket = _attendanceBucket(r, concluded, known);
        if (bucket == null) continue;
        final c = counts.putIfAbsent(r.studentId, () => [0, 0, 0]);
        switch (bucket) {
          case AttendanceRecord.hadir:
            c[0]++;
          case AttendanceRecord.izin:
            c[1]++;
          default:
            c[2]++;
        }
      }
      final rows = counts.entries
          .map(
            (e) => AttendanceStudentRow(
              studentId: e.key,
              name: _name(usersById, e.key,
                  fallback: _recordName(attendance, e.key)),
              level: _level(usersById[e.key]),
              hadir: e.value[0],
              izin: e.value[1],
              alpa: e.value[2],
            ),
          )
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      out.add(AttendanceMonth(month: month, rows: rows));
    }
    return out;
  }

  static String? _recordName(List<AttendanceRecord> records, String studentId) {
    for (final r in records) {
      if (r.studentId == studentId && (r.studentName ?? '').isNotEmpty) {
        return r.studentName;
      }
    }
    return null;
  }

  // ── 2 ──

  static TermAlertsReport termAlerts({
    required List<StudentClassTerm> classTerms,
    required Map<String, AppUser> usersById,
    required DateTime now,
    int lowBalanceAt = 2,
    int expiringWithinDays = 7,
  }) {
    final rows = <TermAlertRow>[];
    var active = 0;
    for (final t in classTerms) {
      if (t.status != StudentClassTerm.statusActive ||
          t.sessionsRemaining <= 0) {
        continue;
      }
      active++;
      final deadline = DateTime.tryParse(t.deadlineDate);
      final daysLeft = deadline == null ? null : _daysBetween(now, deadline);
      final kinds = <TermAlertKind>{
        if (t.sessionsRemaining <= lowBalanceAt) TermAlertKind.lowBalance,
        if (daysLeft != null && daysLeft >= 0 && daysLeft <= expiringWithinDays)
          TermAlertKind.expiringSoon,
        if (daysLeft != null && daysLeft < 0) TermAlertKind.expiredWithBalance,
      };
      if (kinds.isEmpty) continue;
      final user = usersById[t.studentId];
      rows.add(
        TermAlertRow(
          studentId: t.studentId,
          name: _name(usersById, t.studentId),
          level: _level(user),
          voucherCode: t.voucherCode ?? '—',
          sessionsRemaining: t.sessionsRemaining,
          packageSize: t.packageSize,
          deadline: deadline,
          daysLeft: daysLeft,
          kinds: kinds,
        ),
      );
    }
    // Most urgent first: expired, then soonest deadline, then fewest sessions.
    rows.sort((a, b) {
      final ad = a.daysLeft ?? 1 << 20;
      final bd = b.daysLeft ?? 1 << 20;
      if (ad != bd) return ad.compareTo(bd);
      return a.sessionsRemaining.compareTo(b.sessionsRemaining);
    });
    return TermAlertsReport(rows: rows, activeTerms: active);
  }

  // ── 3 ──

  static RevenueReport revenue({
    required List<Invoice> invoices,
    required DateTime now,
  }) {
    final months = <RevenueMonth>[];
    for (final month in ReportMonth.last(monthsShown, now)) {
      var p8 = 0, p16 = 0, book = 0, other = 0, count = 0;
      for (final inv in invoices) {
        if (!inv.isPaid) continue;
        if (!month.contains(inv.paidAt ?? inv.createdAt)) continue;
        count++;
        if (inv.isBook) {
          book += inv.amount;
        } else if (inv.packageSize == 8) {
          p8 += inv.amount;
        } else if (inv.packageSize == 16) {
          p16 += inv.amount;
        } else {
          other += inv.amount;
        }
      }
      months.add(
        RevenueMonth(
          month: month,
          package8: p8,
          package16: p16,
          book: book,
          other: other,
          invoices: count,
        ),
      );
    }
    final outstanding = invoices.where((i) => i.isPending).map((inv) {
      final due = DateTime.tryParse(inv.dueDate);
      final overdueDays = due == null ? 0 : _daysBetween(due, now);
      return OutstandingInvoiceRow(
        invoiceNumber: inv.invoiceNumber,
        studentName: inv.studentName ?? inv.studentId,
        itemLabel: inv.itemLabel,
        amount: inv.amount,
        dueDate: due,
        daysOverdue: overdueDays > 0 ? overdueDays : 0,
      );
    }).toList()
      ..sort((a, b) => b.daysOverdue.compareTo(a.daysOverdue));
    return RevenueReport(months: months, outstanding: outstanding);
  }

  // ── 4 ──

  static RetentionReport retention({
    required List<AppUser> students,
    required List<StudentClassTerm> classTerms,
    required List<AttendanceRecord> attendance,
    required DateTime now,
    int activeWindowDays = 30,
    int eligibleAfterDays = 60,
  }) {
    final withTerm = classTerms
        .where((t) => t.isActive && t.isValidOnDateWithin(now))
        .map((t) => t.studentId)
        .toSet();
    final recentlyAttended = <String>{};
    for (final r in attendance) {
      final date = DateTime.tryParse(r.sessionDate);
      if (date == null) continue;
      final age = _daysBetween(date, now);
      if (age < 0 || age > activeWindowDays) continue;
      if (r.normalizedStatus == AttendanceRecord.hadir ||
          r.attended ||
          r.sessionCredited) {
        recentlyAttended.add(r.studentId);
      }
    }
    bool isActive(AppUser s) =>
        s.active &&
        (withTerm.contains(s.uid) || recentlyAttended.contains(s.uid));

    final cohorts = <CohortRow>[];
    for (final month in ReportMonth.last(monthsShown, now)) {
      final joined =
          students.where((s) => month.contains(s.createdAt)).toList();
      cohorts.add(
        CohortRow(
          month: month,
          joined: joined.length,
          stillActive: joined.where(isActive).length,
        ),
      );
    }
    final eligible = students
        .where((s) =>
            s.createdAt != null &&
            _daysBetween(s.createdAt!, now) > eligibleAfterDays)
        .toList();
    return RetentionReport(
      cohorts: cohorts,
      totalStudents: students.length,
      activeStudents: students.where(isActive).length,
      eligible: eligible.length,
      retained: eligible.where(isActive).length,
    );
  }

  // ── 5 ──

  static List<FillRateMonth> fillRate({
    required List<ClassSession> sessions,
    required List<AttendanceRecord> attendance,
    required Map<String, AppUser> usersById,
    required DateTime now,
  }) {
    final joinedBySession = <String, int>{};
    for (final r in attendance) {
      joinedBySession[r.sessionId] = (joinedBySession[r.sessionId] ?? 0) + 1;
    }
    final out = <FillRateMonth>[];
    for (final month in ReportMonth.last(monthsShown, now)) {
      final rows = sessions
          .where((s) => month.contains(DateTime.tryParse(s.sessionDate)))
          .map(
            (s) => SessionFillRow(
              date: s.sessionDate,
              title: s.sessionTitle,
              teacherName: _name(usersById, s.teacherId),
              joined: joinedBySession[s.id] ?? 0,
              capacity: s.capacity,
              concluded: s.isConcluded,
            ),
          )
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      out.add(FillRateMonth(month: month, sessions: rows));
    }
    return out;
  }

  // ── 6 ──

  static List<TeacherRecapMonth> teacherRecap({
    required List<ClassSession> sessions,
    required List<AttendanceRecord> attendance,
    required List<AppUser> users,
    required DateTime now,
    int months = 3,
  }) {
    final usersById = {for (final u in users) u.uid: u};
    final concludedIds =
        sessions.where((s) => s.isConcluded).map((s) => s.id).toSet();
    final knownIds = sessions.map((s) => s.id).toSet();
    final recordsBySession = <String, List<AttendanceRecord>>{};
    for (final r in attendance) {
      recordsBySession.putIfAbsent(r.sessionId, () => []).add(r);
    }
    final out = <TeacherRecapMonth>[];
    for (final month in ReportMonth.last(months, now)) {
      final byTeacher = <String, _TeacherAcc>{};
      for (final s in sessions) {
        if (!month.contains(DateTime.tryParse(s.sessionDate))) continue;
        final acc = byTeacher.putIfAbsent(s.teacherId, _TeacherAcc.new);
        acc.scheduled++;
        if (!s.isConcluded) continue;
        acc.concluded++;
        acc.minutes += (s.endMinutes - s.startMinutes).clamp(0, 24 * 60);
        for (final r in recordsBySession[s.id] ?? const <AttendanceRecord>[]) {
          final bucket = _attendanceBucket(r, concludedIds, knownIds);
          if (bucket == null) continue;
          acc.marked++;
          if (bucket == AttendanceRecord.hadir) {
            acc.hadir++;
            acc.students.add(r.studentId);
          }
        }
      }
      final rows = byTeacher.entries
          .map(
            (e) => TeacherMonthRow(
              teacherId: e.key,
              name: _name(usersById, e.key),
              scheduled: e.value.scheduled,
              concluded: e.value.concluded,
              teachingMinutes: e.value.minutes,
              studentsTaught: e.value.students.length,
              hadir: e.value.hadir,
              marked: e.value.marked,
            ),
          )
          .toList()
        ..sort((a, b) => b.concluded.compareTo(a.concluded));
      out.add(TeacherRecapMonth(month: month, rows: rows));
    }
    return out;
  }

  // ── 7 ──

  static List<LevelProgressRow> progressByLevel({
    required List<AppUser> students,
    required List<ExerciseAssignment> assignments,
    required List<ExerciseResult> results,
  }) {
    final assignedByStudent = <String, Set<String>>{};
    for (final a in assignments) {
      assignedByStudent.putIfAbsent(a.studentId, () => {}).add(a.exerciseId);
    }
    // Best score per (student, exercise) and last activity per student.
    final bestByStudent = <String, Map<String, int>>{};
    final lastByStudent = <String, DateTime>{};
    for (final r in results) {
      final best = bestByStudent.putIfAbsent(r.studentId, () => {});
      final prev = best[r.exerciseId];
      if (prev == null || r.score > prev) best[r.exerciseId] = r.score;
      final at = r.submittedAt;
      if (at != null) {
        final prevAt = lastByStudent[r.studentId];
        if (prevAt == null || at.isAfter(prevAt))
          lastByStudent[r.studentId] = at;
      }
    }

    final buckets = <String, List<StudentProgressRow>>{
      for (final l in AppConstants.hskLevels) l: [],
      'Unassigned': [],
    };
    for (final s in students.where((s) => s.active)) {
      final assigned = assignedByStudent[s.uid] ?? const <String>{};
      final best = bestByStudent[s.uid] ?? const <String, int>{};
      final completed = assigned.where(best.containsKey).length;
      final scores = [
        for (final id in assigned)
          if (best[id] != null) best[id]!
      ];
      final level = LevelUtils.normalizeHskLevel(s.level);
      final key =
          level != null && buckets.containsKey(level) ? level : 'Unassigned';
      buckets[key]!.add(
        StudentProgressRow(
          studentId: s.uid,
          name: s.displayNameIndonesian,
          level: key,
          assigned: assigned.length,
          completed: completed,
          averageScore: scores.isEmpty
              ? null
              : (scores.reduce((a, b) => a + b) / scores.length).round(),
          lastActivity: lastByStudent[s.uid],
        ),
      );
    }
    return [
      for (final e in buckets.entries)
        if (e.value.isNotEmpty)
          LevelProgressRow(
            level: e.key,
            students: e.value
              ..sort((a, b) =>
                  a.name.toLowerCase().compareTo(b.name.toLowerCase())),
          ),
    ];
  }

  // ── 8 ──

  static OverdueHomeworkReport overdueHomework({
    required List<ExerciseAssignment> assignments,
    required List<ExerciseResult> results,
    required List<Exercise> exercises,
    required Map<String, AppUser> usersById,
    required DateTime now,
  }) {
    final done = {for (final r in results) '${r.studentId}|${r.exerciseId}'};
    final titles = {for (final e in exercises) e.id: e.title};
    final today = _day(now);
    final byTeacher = <String, List<OverdueHomeworkRow>>{};
    var open = 0;
    for (final a in assignments) {
      if (done.contains('${a.studentId}|${a.exerciseId}')) continue;
      open++;
      final due = a.dueDate;
      if (due == null || !_day(due).isBefore(today)) continue;
      final student = usersById[a.studentId];
      final teacherId = (student?.teacherId?.isNotEmpty ?? false)
          ? student!.teacherId!
          : a.teacherId;
      byTeacher.putIfAbsent(teacherId, () => []).add(
            OverdueHomeworkRow(
              studentId: a.studentId,
              studentName: _name(usersById, a.studentId),
              exerciseTitle: titles[a.exerciseId] ?? a.exerciseId,
              dueDate: due,
              daysOverdue: _daysBetween(due, now),
            ),
          );
    }
    final groups = byTeacher.entries
        .map(
          (e) => TeacherOverdueGroup(
            teacherId: e.key,
            teacherName: _name(usersById, e.key, fallback: 'Centre (admin)'),
            rows: e.value
              ..sort((a, b) => b.daysOverdue.compareTo(a.daysOverdue)),
          ),
        )
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    return OverdueHomeworkReport(groups: groups, open: open);
  }
}

class _TeacherAcc {
  int scheduled = 0;
  int concluded = 0;
  int minutes = 0;
  int hadir = 0;
  int marked = 0;
  final Set<String> students = {};
}

extension on StudentClassTerm {
  bool isValidOnDateWithin(DateTime now) => StudentClassTerm.isValidOnDate(
        startDate: startDate,
        deadlineDate: deadlineDate,
        on: now,
      );
}
