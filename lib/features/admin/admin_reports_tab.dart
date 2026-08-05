import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/export_report_card.dart';
import '../../core/widgets/responsive_card_grid.dart';
import '../../services/admin_report_export_service.dart';
import '../../services/admin_report_service.dart';
import '../../services/firestore_service.dart';

class AdminReportsTab extends StatelessWidget {
  const AdminReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final export = context.read<AdminReportExportService>();

    return StreamBuilder(
      stream: firestore.watchAllUsers(),
      builder: (context, usersSnap) {
        return StreamBuilder(
          stream: firestore.watchAllClassTerms(),
          builder: (context, termsSnap) {
            return StreamBuilder(
              stream: firestore.watchAllExercises(),
              builder: (context, exercisesSnap) {
                if (usersSnap.connectionState == ConnectionState.waiting ||
                    termsSnap.connectionState == ConnectionState.waiting ||
                    exercisesSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final report = AdminReportService.build(
                  users: usersSnap.data ?? [],
                  exercises: exercisesSnap.data ?? [],
                  classTerms: termsSnap.data ?? [],
                );
                final thisMonthVouchers = report.vouchersIssuedByMonth.isEmpty
                    ? 0
                    : report.vouchersIssuedByMonth.last.count;
                final thisMonthStudents = report.newStudentsByMonth.isEmpty
                    ? 0
                    : report.newStudentsByMonth.last.count;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 720;
                    final horizontalPadding = isWide ? 32.0 : 20.0;
                    final gridWidth =
                        constraints.maxWidth - horizontalPadding * 2;

                    return ListView(
                      padding: EdgeInsets.all(horizontalPadding),
                      children: [
                        Text(
                          'Reports',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.navy,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${report.totalUsers} users in Firestore '
                          '(${report.totalMurid} murid · '
                          '${report.totalTeachers} guru · '
                          '${report.totalAdmins} admin)',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ResponsiveCardGrid(
                          width: gridWidth,
                          children: [
                            ExportReportCard(
                              title: '1. User roster',
                              description:
                                  'Full account list — Admin, Guru, and Murid with '
                                  'role, join date, and active status. Snapshot export.',
                              preview: [
                                'Total: ${report.totalUsers}',
                                'Active murid: ${report.activeStudents}',
                                'Inactive: ${report.inactiveUsers}',
                              ],
                              onExport: () => export.exportPdf(
                                AdminExportReport.userRoster,
                              ),
                            ),
                            ExportReportCard(
                              title: '2. Monthly registration & growth',
                              description:
                                  'New murid sign-ups per month (last 6 months) and '
                                  'current HSK level bands for centre planning.',
                              preview: [
                                'This month: $thisMonthStudents new murid',
                                ...report.newStudentsByMonth
                                    .map((m) => '${m.label}: ${m.count} new')
                                    .take(3),
                              ],
                              onExport: () => export.exportPdf(
                                AdminExportReport.registrationGrowth,
                              ),
                            ),
                            ExportReportCard(
                              title: '3. Vouchers & monthly packages',
                              description:
                                  'All session packages with codes, balance, and '
                                  'vouchers issued per month (last 6 months).',
                              preview: [
                                'Active packages: ${(termsSnap.data ?? []).length}',
                                'Low balance alerts: ${report.lowVouchers}',
                                'This month: $thisMonthVouchers vouchers issued',
                                ...report.vouchersIssuedByMonth
                                    .reversed
                                    .take(2)
                                    .map((m) => '${m.label}: ${m.count} issued'),
                              ],
                              onExport: () => export.exportPdf(
                                AdminExportReport.voucherSessions,
                              ),
                            ),
                            ExportReportCard(
                              title: '4. Worksheet inventory',
                              description:
                                  'All practice worksheets produced, grouped by HSK '
                                  'level and skill section (Reading, Listening, etc.).',
                              preview: [
                                'Total worksheets: ${report.totalWorksheets}',
                                ...report.worksheetInventory
                                    .take(4)
                                    .map(
                                      (row) => row.skillSummary.isEmpty
                                          ? '${row.hskLevel}: ${row.total}'
                                          : '${row.hskLevel}: ${row.total} '
                                              '(${row.skillSummary})',
                                    ),
                              ],
                              onExport: () => export.exportPdf(
                                AdminExportReport.worksheetInventory,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
