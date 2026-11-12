import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/utils/money_format.dart';
import '../../core/widgets/responsive_card_grid.dart';
import '../../l10n/l10n.dart';
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
    final l = context.l10n;
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l.adminReportsLoadFailed('$_error'),
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
              l.adminReportsTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              l.adminReportsSubtitle(month),
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            section(l.cohortStudents, _studentTiles(l, ops, export)),
            section(l.adminReportsSectionClasses, _classTiles(l, ops, export)),
            section(l.adminReportsSectionMoney, _moneyTiles(l, ops, export)),
            section(
              l.adminReportsSectionPlatform,
              _platformTiles(l, report, export),
            ),
          ],
        );
      },
    );
  }

  List<_ReportTile> _studentTiles(
    AppLocalizations l,
    AdminOpsReportData ops,
    AdminReportExportService export,
  ) {
    final attendance = ops.attendance.last;
    final retention = ops.retention;
    final levels = ops.progressByLevel;
    final students = levels.fold(0, (s, lv) => s + lv.studentCount);
    final assigned = levels.fold(0, (s, lv) => s + lv.assigned);
    final completed = levels.fold(0, (s, lv) => s + lv.completed);
    final overdue = ops.overdueHomework;
    return [
      _ReportTile(
        number: 1,
        title: l.adminReportsAttendanceTitle,
        description: l.adminReportsAttendanceDesc,
        stats: [
          (l.cohortStudents, '${attendance.rows.length}'),
          (l.attendancePresent, '${attendance.presentPercent}%'),
          (l.adminReportsAlpa, '${attendance.alpa}'),
        ],
        onExport: () => export.exportPdf(AdminExportReport.attendanceMonthly),
      ),
      _ReportTile(
        number: 4,
        title: l.adminReportsRetentionTitle,
        description: l.adminReportsRetentionDesc,
        stats: [
          (l.adminReportsNewThisMonth, '${retention.newThisMonth}'),
          (
            l.historyStatusActive,
            '${retention.activeStudents} / ${retention.totalStudents}'
          ),
          (l.adminReportsRetention, '${retention.retentionPercent}%'),
        ],
        onExport: () => export.exportPdf(AdminExportReport.studentRetention),
      ),
      _ReportTile(
        number: 7,
        title: l.adminReportsProgressTitle,
        description: l.adminReportsProgressDesc,
        stats: [
          (l.cohortStudents, '$students'),
          (
            l.adminReportsDone,
            assigned == 0 ? '—' : '${(completed * 100 / assigned).round()}%'
          ),
          (
            l.adminReportsNoActivity,
            '${levels.fold(0, (s, lv) => s + lv.inactive)}'
          ),
        ],
        onExport: () => export.exportPdf(AdminExportReport.progressByLevel),
      ),
      _ReportTile(
        number: 8,
        title: l.adminReportsOverdueHomeworkTitle,
        description: l.adminReportsOverdueHomeworkDesc,
        stats: [
          (l.cohortOverdue, '${overdue.total}'),
          (l.adminReportsOpen, '${overdue.open}'),
          (l.adminReportsTeachers, '${overdue.groups.length}'),
        ],
        onExport: () => export.exportPdf(AdminExportReport.overdueHomework),
      ),
    ];
  }

  List<_ReportTile> _classTiles(
    AppLocalizations l,
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
        title: l.adminReportsFillRateTitle,
        description: l.adminReportsFillRateDesc,
        stats: [
          (l.adminReportsClasses, '${fill.classes}'),
          (l.commonFull, '${fill.fillPercent}%'),
          (l.adminReportsEmpty, '${fill.empty}'),
        ],
        onExport: () => export.exportPdf(AdminExportReport.classFillRate),
      ),
      _ReportTile(
        number: 6,
        title: l.adminReportsTeacherRecapTitle,
        description: l.adminReportsTeacherRecapDesc,
        stats: [
          (l.adminReportsTeachers, '${recap.rows.length}'),
          (l.adminReportsClassesHeld, '$held'),
          (l.adminReportsHours, hours.toStringAsFixed(1)),
        ],
        onExport: () => export.exportPdf(AdminExportReport.teacherRecap),
      ),
    ];
  }

  List<_ReportTile> _moneyTiles(
    AppLocalizations l,
    AdminOpsReportData ops,
    AdminReportExportService export,
  ) {
    final alerts = ops.termAlerts;
    final revenue = ops.revenue;
    return [
      _ReportTile(
        number: 2,
        title: l.adminReportsTermAlertsTitle,
        description: l.adminReportsTermAlertsDesc,
        stats: [
          (
            l.adminReportsLowBalance,
            '${alerts.count(TermAlertKind.lowBalance)}'
          ),
          (
            l.adminReportsExpiring,
            '${alerts.count(TermAlertKind.expiringSoon)}'
          ),
          (
            l.historyStatusExpired,
            '${alerts.count(TermAlertKind.expiredWithBalance)}'
          ),
        ],
        onExport: () => export.exportPdf(AdminExportReport.termBalanceAlerts),
      ),
      _ReportTile(
        number: 3,
        title: l.adminReportsRevenueTitle,
        description: l.adminReportsRevenueDesc,
        stats: [
          (l.adminReportsThisMonth, formatRupiah(revenue.thisMonth.total)),
          (l.adminReportsUnpaid, formatRupiah(revenue.outstandingAmount)),
          (l.cohortOverdue, '${revenue.overdue.length}'),
        ],
        onExport: () => export.exportPdf(AdminExportReport.revenueMonthly),
      ),
    ];
  }

  List<_ReportTile> _platformTiles(
    AppLocalizations l,
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
        title: l.adminReportsUserRosterTitle,
        description: l.adminReportsUserRosterDesc,
        stats: [
          (l.adminReportsUsers, '${report.totalUsers}'),
          (l.adminDashActiveMurid, '${report.activeStudents}'),
          (l.adminDashInactive, '${report.inactiveUsers}'),
        ],
        onExport: () => export.exportPdf(AdminExportReport.userRoster),
      ),
      _ReportTile(
        number: 10,
        title: l.adminReportsGrowthTitle,
        description: l.adminReportsGrowthDesc,
        stats: [
          (l.adminReportsThisMonth, '$thisMonthStudents'),
          (l.adminReportsLastSixMonths, '$sixMonths'),
        ],
        onExport: () => export.exportPdf(AdminExportReport.registrationGrowth),
      ),
      _ReportTile(
        number: 11,
        title: l.adminReportsVouchersTitle,
        description: l.adminReportsVouchersDesc,
        stats: [
          (l.adminReportsPackages, '${_terms!.length}'),
          (l.adminReportsLowBalance, '${report.lowVouchers}'),
          (l.adminReportsIssuedThisMonth, '$thisMonthVouchers'),
        ],
        onExport: () => export.exportPdf(AdminExportReport.voucherSessions),
      ),
      _ReportTile(
        number: 12,
        title: l.adminReportsWorksheetInventoryTitle,
        description: l.adminReportsWorksheetInventoryDesc,
        stats: [
          (l.adminReportsWorksheets, '${report.totalWorksheets}'),
          (l.adminDashPublished, '${report.totalExercises}'),
          (
            l.adminReportsDraft,
            '${report.totalWorksheets - report.totalExercises}'
          ),
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
    final l = context.l10n;
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
                label: Text(l.adminReportsPdf),
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
