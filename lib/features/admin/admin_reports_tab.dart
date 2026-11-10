import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/utils/money_format.dart';
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
            style: TextStyle(color: AppColors.error),
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
    final month = ops.attendance.last.month.label;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        final horizontalPadding = isWide ? 32.0 : 20.0;
        final gridWidth = constraints.maxWidth - horizontalPadding * 2;

        Widget section(String title, List<_ReportTile> tiles) => Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionHeader(title: title),
                  ResponsiveCardGrid(
                    width: gridWidth,
                    minCardWidth: 360,
                    maxColumns: 2,
                    children: tiles,
                  ),
                ],
              ),
            );

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
            const SizedBox(height: 6),
            Text(
              'Live numbers for $month. Each PDF covers the last 6 months.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            section('Students', _studentTiles(ops, export)),
            section('Classes & teachers', _classTiles(ops, export)),
            section('Money', _moneyTiles(ops, export)),
            section('Platform exports', _platformTiles(report, export)),
          ],
        );
      },
    );
  }

  List<_ReportTile> _studentTiles(
    AdminOpsReportData ops,
    AdminReportExportService export,
  ) {
    final attendance = ops.attendance.last;
    final retention = ops.retention;
    final levels = ops.progressByLevel;
    final students = levels.fold(0, (s, l) => s + l.studentCount);
    final assigned = levels.fold(0, (s, l) => s + l.assigned);
    final completed = levels.fold(0, (s, l) => s + l.completed);
    final overdue = ops.overdueHomework;
    return [
      _ReportTile(
        number: 1,
        title: 'Attendance per student',
        description: 'Hadir / Izin / Alpa for every student, month by month.',
        stats: [
          ('Students', '${attendance.rows.length}'),
          ('Present', '${attendance.presentPercent}%'),
          ('Alpa', '${attendance.alpa}'),
        ],
        onExport: () => export.exportPdf(AdminExportReport.attendanceMonthly),
      ),
      _ReportTile(
        number: 4,
        title: 'New students & retention',
        description: 'Sign-ups per month and how many are still active today.',
        stats: [
          ('New this month', '${retention.newThisMonth}'),
          (
            'Active',
            '${retention.activeStudents} / ${retention.totalStudents}'
          ),
          ('Retention', '${retention.retentionPercent}%'),
        ],
        onExport: () => export.exportPdf(AdminExportReport.studentRetention),
      ),
      _ReportTile(
        number: 7,
        title: 'Progress per HSK level',
        description:
            'Exercises assigned and done, average best score, no activity.',
        stats: [
          ('Students', '$students'),
          (
            'Done',
            assigned == 0 ? '—' : '${(completed * 100 / assigned).round()}%'
          ),
          ('No activity', '${levels.fold(0, (s, l) => s + l.inactive)}'),
        ],
        onExport: () => export.exportPdf(AdminExportReport.progressByLevel),
      ),
      _ReportTile(
        number: 8,
        title: 'Overdue homework',
        description: 'Past-due assignments without a submission, per teacher.',
        stats: [
          ('Overdue', '${overdue.total}'),
          ('Open', '${overdue.open}'),
          ('Teachers', '${overdue.groups.length}'),
        ],
        onExport: () => export.exportPdf(AdminExportReport.overdueHomework),
      ),
    ];
  }

  List<_ReportTile> _classTiles(
    AdminOpsReportData ops,
    AdminReportExportService export,
  ) {
    final fill = ops.fillRate.last;
    final recap = ops.teacherRecap.last;
    final held = recap.rows.fold(0, (s, r) => s + r.concluded);
    final hours = recap.rows.fold(0.0, (s, r) => s + r.teachingHours);
    return [
      _ReportTile(
        number: 5,
        title: 'Class fill rate',
        description: 'Seats taken against capacity, per month and per class.',
        stats: [
          ('Classes', '${fill.classes}'),
          ('Full', '${fill.fillPercent}%'),
          ('Empty', '${fill.empty}'),
        ],
        onExport: () => export.exportPdf(AdminExportReport.classFillRate),
      ),
      _ReportTile(
        number: 6,
        title: 'Teacher recap',
        description:
            'Classes, teaching hours, students taught and attendance per teacher.',
        stats: [
          ('Teachers', '${recap.rows.length}'),
          ('Classes held', '$held'),
          ('Hours', hours.toStringAsFixed(1)),
        ],
        onExport: () => export.exportPdf(AdminExportReport.teacherRecap),
      ),
    ];
  }

  List<_ReportTile> _moneyTiles(
    AdminOpsReportData ops,
    AdminReportExportService export,
  ) {
    final alerts = ops.termAlerts;
    final revenue = ops.revenue;
    return [
      _ReportTile(
        number: 2,
        title: 'Term balance alerts',
        description:
            'Who to call: 2 or fewer sessions left, expiring within 7 days, expired.',
        stats: [
          ('Low balance', '${alerts.count(TermAlertKind.lowBalance)}'),
          ('Expiring', '${alerts.count(TermAlertKind.expiringSoon)}'),
          ('Expired', '${alerts.count(TermAlertKind.expiredWithBalance)}'),
        ],
        onExport: () => export.exportPdf(AdminExportReport.termBalanceAlerts),
      ),
      _ReportTile(
        number: 3,
        title: 'Revenue per month',
        description:
            'Paid invoices by item, plus every unpaid invoice and how overdue it is.',
        stats: [
          ('This month', formatRupiah(revenue.thisMonth.total)),
          ('Unpaid', formatRupiah(revenue.outstandingAmount)),
          ('Overdue', '${revenue.overdue.length}'),
        ],
        onExport: () => export.exportPdf(AdminExportReport.revenueMonthly),
      ),
    ];
  }

  List<_ReportTile> _platformTiles(
    AdminReportData report,
    AdminReportExportService export,
  ) {
    final thisMonthVouchers = report.vouchersIssuedByMonth.isEmpty
        ? 0
        : report.vouchersIssuedByMonth.last.count;
    final thisMonthStudents = report.newStudentsByMonth.isEmpty
        ? 0
        : report.newStudentsByMonth.last.count;
    final sixMonths = report.newStudentsByMonth.fold(0, (s, m) => s + m.count);
    return [
      _ReportTile(
        number: 9,
        title: 'User roster',
        description: 'Every account with role, join date and status.',
        stats: [
          ('Users', '${report.totalUsers}'),
          ('Active murid', '${report.activeStudents}'),
          ('Inactive', '${report.inactiveUsers}'),
        ],
        onExport: () => export.exportPdf(AdminExportReport.userRoster),
      ),
      _ReportTile(
        number: 10,
        title: 'Registration & growth',
        description: 'New murid per month and current HSK level bands.',
        stats: [
          ('This month', '$thisMonthStudents'),
          ('Last 6 months', '$sixMonths'),
        ],
        onExport: () => export.exportPdf(AdminExportReport.registrationGrowth),
      ),
      _ReportTile(
        number: 11,
        title: 'Vouchers & packages',
        description: 'All session packages with codes and balance.',
        stats: [
          ('Packages', '${_terms!.length}'),
          ('Low balance', '${report.lowVouchers}'),
          ('Issued this month', '$thisMonthVouchers'),
        ],
        onExport: () => export.exportPdf(AdminExportReport.voucherSessions),
      ),
      _ReportTile(
        number: 12,
        title: 'Worksheet inventory',
        description: 'Practice worksheets by HSK level and skill section.',
        stats: [
          ('Worksheets', '${report.totalWorksheets}'),
          ('Published', '${report.totalExercises}'),
          ('Draft', '${report.totalWorksheets - report.totalExercises}'),
        ],
        onExport: () => export.exportPdf(AdminExportReport.worksheetInventory),
      ),
    ];
  }
}

/// One report: number badge, title, one-line description, up to three
/// figures in a fixed row, and the PDF button. Same shape for every report so
/// the page reads as a list, not a wall of bullet points.
class _ReportTile extends StatelessWidget {
  const _ReportTile({
    required this.number,
    required this.title,
    required this.description,
    required this.stats,
    required this.onExport,
  });

  final int number;
  final String title;
  final String description;
  final List<(String label, String value)> stats;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$number',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.navy,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: onExport,
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                label: const Text('PDF'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                for (var i = 0; i < stats.length; i++) ...[
                  if (i > 0)
                    Container(
                      width: 1,
                      height: 30,
                      color: AppColors.border,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stats[i].$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppColors.navy,
                          ),
                        ),
                        Text(
                          stats[i].$1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
