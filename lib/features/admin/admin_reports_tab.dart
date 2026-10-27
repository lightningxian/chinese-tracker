import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/money_format.dart';
import '../../core/widgets/export_report_card.dart';
import '../../core/widgets/responsive_card_grid.dart';
import '../../models/app_user.dart';
import '../../models/attendance_record.dart';
import '../../models/class_session.dart';
import '../../models/exercise.dart';
import '../../models/exercise_assignment.dart';
import '../../models/exercise_result.dart';
import '../../models/invoice.dart';
import '../../models/student_class_term.dart';
import '../../services/admin_ops_report_service.dart';
import '../../services/admin_report_export_service.dart';
import '../../services/admin_report_service.dart';
import '../../services/firestore_service.dart';

/// Admin → Reports. Eight operational reports (attendance, balances, revenue,
/// retention, fill rate, teacher recap, progress, overdue homework) followed
/// by the four older platform exports. Every card previews live numbers and
/// exports a PDF.
class AdminReportsTab extends StatefulWidget {
  const AdminReportsTab({super.key});

  @override
  State<AdminReportsTab> createState() => _AdminReportsTabState();
}

class _AdminReportsTabState extends State<AdminReportsTab> {
  final _subs = <StreamSubscription<dynamic>>[];
  List<AppUser>? _users;
  List<Exercise>? _exercises;
  List<StudentClassTerm>? _terms;
  List<AttendanceRecord>? _attendance;
  List<ClassSession>? _sessions;
  List<Invoice>? _invoices;
  List<ExerciseAssignment>? _assignments;
  List<ExerciseResult>? _results;
  Object? _error;

  bool get _ready =>
      _users != null &&
      _exercises != null &&
      _terms != null &&
      _attendance != null &&
      _sessions != null &&
      _invoices != null &&
      _assignments != null &&
      _results != null;

  @override
  void initState() {
    super.initState();
    final f = context.read<FirestoreService>();
    _listen(f.watchAllUsers(), (v) => _users = v);
    _listen(f.watchAllExercises(), (v) => _exercises = v);
    _listen(f.watchAllClassTerms(), (v) => _terms = v);
    _listen(f.watchAllAttendance(), (v) => _attendance = v);
    _listen(f.watchAllClassSessions(), (v) => _sessions = v);
    _listen(f.watchAllInvoices(), (v) => _invoices = v);
    _listen(f.watchAllExerciseAssignments(), (v) => _assignments = v);
    _listen(f.watchAllExerciseResults(), (v) => _results = v);
  }

  void _listen<T>(Stream<List<T>> stream, void Function(List<T>) set) {
    _subs.add(
      stream.listen(
        (v) => setState(() => set(v)),
        onError: (Object e) => setState(() => _error = e),
      ),
    );
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Could not load report data: $_error',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      );
    }
    if (!_ready) {
      return const Center(child: CircularProgressIndicator());
    }

    final export = context.read<AdminReportExportService>();
    final report = AdminReportService.build(
      users: _users!,
      exercises: _exercises!,
      classTerms: _terms!,
    );
    final ops = AdminOpsReportService.build(
      users: _users!,
      exercises: _exercises!,
      classTerms: _terms!,
      attendance: _attendance!,
      sessions: _sessions!,
      invoices: _invoices!,
      assignments: _assignments!,
      results: _results!,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        final horizontalPadding = isWide ? 32.0 : 20.0;
        final gridWidth = constraints.maxWidth - horizontalPadding * 2;

        return ListView(
          padding: EdgeInsets.all(horizontalPadding),
          children: [
            Text(
              'Reports',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '${report.totalUsers} users '
              '(${report.totalMurid} murid · ${report.totalTeachers} guru · '
              '${report.totalAdmins} admin). Numbers below are live; '
              'each PDF covers the last 6 months.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            ResponsiveCardGrid(
              width: gridWidth,
              children: _opsCards(ops, export),
            ),
            const SizedBox(height: 28),
            const Text(
              'Platform exports',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 12),
            ResponsiveCardGrid(
              width: gridWidth,
              children: _platformCards(report, export),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _opsCards(
    AdminOpsReportData ops,
    AdminReportExportService export,
  ) {
    final attendance = ops.attendance.last;
    final alerts = ops.termAlerts;
    final revenue = ops.revenue;
    final retention = ops.retention;
    final fill = ops.fillRate.last;
    final recap = ops.teacherRecap.last;
    final overdue = ops.overdueHomework;

    return [
      ExportReportCard(
        title: '1. Attendance per student',
        description:
            'Hadir / Izin / Alpa for every student, month by month, with a '
            'present percentage. Open classes are not counted yet.',
        preview: [
          '${attendance.month.label}: ${attendance.rows.length} students · '
              '${attendance.presentPercent}% present',
          'Hadir ${attendance.hadir} · Izin ${attendance.izin} · '
              'Alpa ${attendance.alpa}',
        ],
        onExport: () => export.exportPdf(AdminExportReport.attendanceMonthly),
      ),
      ExportReportCard(
        title: '2. Term balance alerts',
        description:
            'Who to call this week: 2 or fewer sessions left, term expiring '
            'within 7 days, or expired with sessions unused.',
        preview: [
          '${alerts.count(TermAlertKind.lowBalance)} low balance',
          '${alerts.count(TermAlertKind.expiringSoon)} expiring within 7 days',
          '${alerts.count(TermAlertKind.expiredWithBalance)} expired with sessions left',
          '${alerts.activeTerms} active terms in total',
        ],
        onExport: () => export.exportPdf(AdminExportReport.termBalanceAlerts),
      ),
      ExportReportCard(
        title: '3. Revenue per month',
        description:
            'Paid invoices by month and item (8 sessions, 16 sessions, book), '
            'plus every unpaid invoice and how overdue it is.',
        preview: [
          '${revenue.thisMonth.month.label}: '
              '${formatRupiah(revenue.thisMonth.total)} '
              '(${revenue.thisMonth.invoices} paid)',
          'Unpaid: ${formatRupiah(revenue.outstandingAmount)} '
              '(${revenue.outstanding.length})',
          'Overdue: ${revenue.overdue.length} · '
              '${formatRupiah(revenue.overdueAmount)}',
        ],
        onExport: () => export.exportPdf(AdminExportReport.revenueMonthly),
      ),
      ExportReportCard(
        title: '4. New students & retention',
        description:
            'Sign-ups per month and how many of each group are still active '
            '(a term with sessions left, or a class in the last 30 days).',
        preview: [
          'New this month: ${retention.newThisMonth}',
          'Active now: ${retention.activeStudents} of '
              '${retention.totalStudents}',
          'Retention: ${retention.retentionPercent}% '
              '(${retention.retained} of ${retention.eligible} who joined '
              '60+ days ago)',
        ],
        onExport: () => export.exportPdf(AdminExportReport.studentRetention),
      ),
      ExportReportCard(
        title: '5. Class fill rate',
        description:
            'Seats taken against capacity per month, and every class this '
            'month with its teacher and how full it was.',
        preview: [
          '${fill.month.label}: ${fill.classes} classes · '
              '${fill.fillPercent}% full',
          '${fill.joined} of ${fill.capacity} seats taken',
          '${fill.empty} empty · ${fill.full} full',
        ],
        onExport: () => export.exportPdf(AdminExportReport.classFillRate),
      ),
      ExportReportCard(
        title: '6. Teacher recap per month',
        description:
            'Per teacher: classes scheduled and concluded, teaching hours, '
            'students taught and their attendance rate. Last 3 months.',
        preview: [
          if (recap.rows.isEmpty)
            '${recap.month.label}: no classes yet'
          else
            for (final r in recap.rows.take(3))
              '${r.name}: ${r.concluded} of ${r.scheduled} classes · '
                  '${r.teachingHours.toStringAsFixed(1)} h · '
                  '${r.studentsTaught} students',
        ],
        onExport: () => export.exportPdf(AdminExportReport.teacherRecap),
      ),
      ExportReportCard(
        title: '7. Student progress per HSK level',
        description:
            'For each HSK level: students, exercises assigned and done, '
            'average best score and who has no activity at all.',
        preview: [
          if (ops.progressByLevel.isEmpty)
            'No active students yet'
          else
            for (final l in ops.progressByLevel.take(4))
              '${l.level}: ${l.studentCount} students · '
                  '${l.completionPercent}% done · '
                  'avg ${l.averageScore ?? '—'}',
        ],
        onExport: () => export.exportPdf(AdminExportReport.progressByLevel),
      ),
      ExportReportCard(
        title: '8. Overdue homework per teacher',
        description:
            'Assignments past their due date with no submission, grouped by '
            'the student\'s teacher so follow-up is clear.',
        preview: [
          '${overdue.total} overdue of ${overdue.open} open assignments',
          for (final g in overdue.groups.take(3))
            '${g.teacherName}: ${g.count} overdue · ${g.students} students',
        ],
        onExport: () => export.exportPdf(AdminExportReport.overdueHomework),
      ),
    ];
  }

  List<Widget> _platformCards(
    AdminReportData report,
    AdminReportExportService export,
  ) {
    final thisMonthVouchers = report.vouchersIssuedByMonth.isEmpty
        ? 0
        : report.vouchersIssuedByMonth.last.count;
    final thisMonthStudents = report.newStudentsByMonth.isEmpty
        ? 0
        : report.newStudentsByMonth.last.count;
    return [
      ExportReportCard(
        title: '9. User roster',
        description:
            'Full account list — Admin, Guru, and Murid with role, join date, '
            'and active status.',
        preview: [
          'Total: ${report.totalUsers}',
          'Active murid: ${report.activeStudents}',
          'Inactive: ${report.inactiveUsers}',
        ],
        onExport: () => export.exportPdf(AdminExportReport.userRoster),
      ),
      ExportReportCard(
        title: '10. Monthly registration & growth',
        description:
            'New murid sign-ups per month (last 6 months) and current HSK '
            'level bands.',
        preview: [
          'This month: $thisMonthStudents new murid',
          ...report.newStudentsByMonth
              .map((m) => '${m.label}: ${m.count} new')
              .take(3),
        ],
        onExport: () => export.exportPdf(AdminExportReport.registrationGrowth),
      ),
      ExportReportCard(
        title: '11. Vouchers & packages',
        description:
            'All session packages with codes and balance, and vouchers issued '
            'per month.',
        preview: [
          'Packages: ${_terms!.length}',
          'Low balance: ${report.lowVouchers}',
          'This month: $thisMonthVouchers issued',
        ],
        onExport: () => export.exportPdf(AdminExportReport.voucherSessions),
      ),
      ExportReportCard(
        title: '12. Worksheet inventory',
        description:
            'All practice worksheets, grouped by HSK level and skill section.',
        preview: [
          'Total worksheets: ${report.totalWorksheets}',
          ...report.worksheetInventory.take(4).map(
                (row) => row.skillSummary.isEmpty
                    ? '${row.hskLevel}: ${row.total}'
                    : '${row.hskLevel}: ${row.total} (${row.skillSummary})',
              ),
        ],
        onExport: () => export.exportPdf(AdminExportReport.worksheetInventory),
      ),
    ];
  }
}
