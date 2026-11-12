import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/constants/exercise_authoring_platform.dart';
import '../../core/utils/invoice_utils.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/responsive_card_grid.dart';
import '../../l10n/l10n.dart';
import '../../l10n/labels_admin.dart';
import '../../models/admin_dashboard_stat_kind.dart';
import '../../models/app_user.dart';
import '../../models/invoice.dart';
import '../../models/student_class_term.dart';
import '../../models/teacher_dashboard_stat_kind.dart';
import '../../services/admin_report_service.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import 'admin_centre_metrics_section.dart';
import 'admin_dashboard_widgets.dart';

class AdminDashboardTab extends StatelessWidget {
  const AdminDashboardTab({
    super.key,
    required this.onSwitchTab,
  });

  final ValueChanged<int> onSwitchTab;

  void _openPlatformStat(BuildContext context, AdminDashboardStatKind kind) {
    openAdminPlatformStatDetail(context, kind);
  }

  void _openCentreStat(BuildContext context, TeacherDashboardStatKind kind) {
    openAdminCentreStatDetail(context, kind);
  }

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final canManageExercises = ExerciseAuthoringPlatform.canManageExercises(
      context.read<AuthService>().appUser,
    );

    return StreamBuilder<List<AppUser>>(
      stream: firestore.watchAllUsers(),
      builder: (context, usersSnap) {
        return StreamBuilder(
          stream: firestore.watchAllExercises(),
          builder: (context, exercisesSnap) {
            return StreamBuilder(
              stream: firestore.watchAllClassTerms(),
              builder: (context, termsSnap) {
                return StreamBuilder<List<Invoice>>(
                  stream: firestore.watchAllInvoices(),
                  builder: (context, invoicesSnap) {
                    final users = usersSnap.data ?? [];
                    final allMurid = users.where((u) => u.isStudent).toList();
                    final invoices = invoicesSnap.data ?? const <Invoice>[];

                    final report = AdminReportService.build(
                      users: users,
                      exercises: exercisesSnap.data ?? [],
                      classTerms: termsSnap.data ?? [],
                    );

                    final voucherAlerts =
                        AdminAttentionUtils.buildVoucherAlerts(
                      students: allMurid,
                      classTerms: termsSnap.data ?? [],
                    );

                    return ListView(
                      padding: EdgeInsets.all(isWide ? 32 : 20),
                      children: [
                        _statsRow(context, report, invoices),
                        const SizedBox(height: 20),
                        if (isWide)
                          _wideChartAndActions(
                            context,
                            report: report,
                            voucherAlerts: voucherAlerts,
                            canManageExercises: canManageExercises,
                          )
                        else ...[
                          MonthlyStudentsChart(
                            months: report.newStudentsByMonth,
                            onTap: () => _openPlatformStat(
                              context,
                              AdminDashboardStatKind.newStudentsMonthly,
                            ),
                          ),
                          const SizedBox(height: 16),
                          AdminQuickActionsCard(
                            onNewExercise: () => onSwitchTab(2),
                            onNewClass: () => onSwitchTab(4),
                            showNewExercise: canManageExercises,
                          ),
                          const SizedBox(height: 20),
                          _needsAttention(context, voucherAlerts),
                        ],
                        const SizedBox(height: 24),
                        _FinancialSummarySection(
                          invoices: invoices,
                          terms: termsSnap.data ?? const [],
                          onOpenPayments: () => onSwitchTab(6),
                          onOpenVouchers: () => onSwitchTab(5),
                        ),
                        const SizedBox(height: 24),
                        AdminCentreMetricsSection(
                          onCentreStatTap: (kind) =>
                              _openCentreStat(context, kind),
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

  Widget _statsRow(
    BuildContext context,
    AdminReportData report,
    List<Invoice> invoices,
  ) {
    final l = context.l10n;
    final now = DateTime.now();
    final income = InvoiceUtils.paidTotalInMonth(invoices, now);
    final paidCount = invoices
        .where((i) =>
            i.isPaid &&
            i.paidAt != null &&
            i.paidAt!.year == now.year &&
            i.paidAt!.month == now.month)
        .length;
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return ResponsiveCardGrid(
      minCardWidth: 220,
      maxColumns: 4,
      children: [
        AdminStatCard(
          label: l.adminDashTotalUsers,
          value: '${report.totalUsers}',
          icon: Icons.people_outline,
          color: adminPurple,
          subtitle: l.adminDashUsersBreakdown(
            report.totalMurid,
            report.totalTeachers,
          ),
          onTap: () =>
              _openPlatformStat(context, AdminDashboardStatKind.totalUsers),
        ),
        AdminStatCard(
          label: l.adminDashActiveMurid,
          value: '${report.activeStudents}',
          icon: Icons.person_outline,
          color: AppColors.teal,
          onTap: () =>
              _openPlatformStat(context, AdminDashboardStatKind.activeMurid),
        ),
        AdminStatCard(
          label: l.studentProgressExercises,
          value: '${report.totalExercises}',
          icon: Icons.menu_book_outlined,
          color: AppColors.navy,
          onTap: () =>
              _openPlatformStat(context, AdminDashboardStatKind.exercises),
        ),
        AdminStatCard(
          label: l.adminDashIncomePerMonth,
          value: currency.format(income),
          icon: Icons.attach_money,
          color: AppColors.success,
          subtitle: paidCount == 0
              ? l.adminDashNoPaymentsInMonth(DateFormat('MMMM').format(now))
              : l.adminDashPaymentsInMonth(
                  paidCount,
                  DateFormat('MMMM').format(now),
                ),
          onTap: () =>
              _openPlatformStat(context, AdminDashboardStatKind.incomeMonthly),
        ),
      ],
    );
  }

  Widget _wideChartAndActions(
    BuildContext context, {
    required AdminReportData report,
    required List<AdminVoucherAlert> voucherAlerts,
    required bool canManageExercises,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MonthlyStudentsChart(
                months: report.newStudentsByMonth,
                onTap: () => _openPlatformStat(
                  context,
                  AdminDashboardStatKind.newStudentsMonthly,
                ),
              ),
              const SizedBox(height: 20),
              _needsAttention(context, voucherAlerts),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: AdminQuickActionsCard(
            onNewExercise: () => onSwitchTab(2),
            onNewClass: () => onSwitchTab(4),
            showNewExercise: canManageExercises,
          ),
        ),
      ],
    );
  }

  Widget _needsAttention(
    BuildContext context,
    List<AdminVoucherAlert> alerts,
  ) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminSectionHeader(
          title: l.adminDashNeedsAttention,
          badgeCount: alerts.isEmpty ? null : alerts.length,
          onTap: alerts.isEmpty
              ? null
              : () => _openPlatformStat(
                    context,
                    AdminDashboardStatKind.voucherAlerts,
                  ),
        ),
        if (alerts.isEmpty)
          AppCard(
            child: Text(
              l.adminDashAllCaughtUpNoAlerts,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          ResponsiveCardGrid(
            minCardWidth: 280,
            children: [
              for (final alert in alerts.take(8))
                AdminAttentionCard(
                  alert: alert,
                  onTap: () => _openPlatformStat(
                    context,
                    AdminDashboardStatKind.voucherAlerts,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// Financial overview from `invoices`: revenue this month, pending payments
/// (count + amount, incl. the oldest ones to chase), vouchers that have no
/// payment record, and the most recent payments.
class _FinancialSummarySection extends StatelessWidget {
  const _FinancialSummarySection({
    required this.invoices,
    required this.terms,
    required this.onOpenPayments,
    required this.onOpenVouchers,
  });

  final List<Invoice> invoices;
  final List<StudentClassTerm> terms;
  final VoidCallback onOpenPayments;
  final VoidCallback onOpenVouchers;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final now = DateTime.now();
    final revenueThisMonth = InvoiceUtils.paidTotalInMonth(invoices, now);

    var outstanding = 0;
    final pending = <Invoice>[];
    for (final inv in invoices) {
      if (inv.isPending) {
        outstanding += inv.amount;
        pending.add(inv);
      }
    }
    pending.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final invoiceIds = {for (final i in invoices) i.id};
    final vouchersWithoutPayment = terms
        .where((t) =>
            t.isActive &&
            (!t.hasPayment || !invoiceIds.contains(t.sourceInvoiceId)))
        .length;

    final recentPaid = invoices.where((i) => i.isPaid).toList()
      ..sort((a, b) {
        final aAt = a.paidAt ?? a.createdAt ?? DateTime(1970);
        final bAt = b.paidAt ?? b.createdAt ?? DateTime(1970);
        return bAt.compareTo(aAt);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminSectionHeader(title: l.adminDashFinancialSummary),
        ResponsiveCardGrid(
          minCardWidth: 220,
          maxColumns: 3,
          children: [
            AdminStatCard(
              label: l.adminDashRevenueThisMonth,
              value: currency.format(revenueThisMonth),
              icon: Icons.trending_up,
              color: AppColors.success,
              onTap: onOpenPayments,
            ),
            AdminStatCard(
              label: l.adminDashPendingPayments,
              value: '${pending.length}',
              subtitle: currency.format(outstanding),
              icon: Icons.pending_actions_outlined,
              color: AppColors.brandYellow,
              onTap: onOpenPayments,
            ),
            AdminStatCard(
              label: l.adminDashVouchersWithoutPayment,
              value: '$vouchersWithoutPayment',
              subtitle: l.adminDashActiveVouchersNoInvoice,
              icon: Icons.confirmation_number_outlined,
              color: AppColors.error,
              onTap: onOpenVouchers,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (pending.isNotEmpty) ...[
          AppCard(
            onTap: onOpenPayments,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.adminDashPendingToChase,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 8),
                for (final inv in pending.take(5))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${inv.studentName?.isNotEmpty == true ? inv.studentName! : inv.invoiceNumber} · ${inv.itemLocalized(l)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          inv.isOverdue
                              ? '${l.adminDashOverdue} · '
                              : '${l.adminDashDue(inv.dueDate)} · ',
                          style: TextStyle(
                            fontSize: 12,
                            color: inv.isOverdue
                                ? AppColors.error
                                : AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          currency.format(inv.amount),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (recentPaid.isEmpty)
          AppCard(
            child: Text(
              l.adminDashNoPaymentsYet,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.adminDashRecentPayments,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 8),
                for (final inv in recentPaid.take(5))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            inv.studentName?.isNotEmpty == true
                                ? inv.studentName!
                                : inv.invoiceNumber,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          currency.format(inv.amount),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
