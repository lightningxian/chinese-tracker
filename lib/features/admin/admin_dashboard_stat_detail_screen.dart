import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/invoice_utils.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/responsive_card_grid.dart';
import '../../core/widgets/shell_nested_page.dart';
import '../../core/widgets/status_pill.dart';
import '../../models/admin_dashboard_stat_kind.dart';
import '../../models/app_user.dart';
import '../../models/dashboard_stat_routes.dart';
import '../../models/exercise.dart';
import '../../models/invoice.dart';
import '../../models/student_class_term.dart';
import '../../services/admin_report_service.dart';
import '../../services/firestore_service.dart';
import 'admin_dashboard_widgets.dart';

class AdminDashboardStatDetailScreen extends StatelessWidget {
  const AdminDashboardStatDetailScreen({
    super.key,
    required this.kind,
    this.embedded = false,
    this.routes = DashboardStatRoutes.admin,
  });

  final AdminDashboardStatKind kind;
  final bool embedded;
  final DashboardStatRoutes routes;

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();

    return ShellNestedPage(
      embedded: embedded,
      title: kind.title,
      child: StreamBuilder<List<AppUser>>(
        stream: firestore.watchAllUsers(),
        builder: (context, usersSnap) {
          if (usersSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (usersSnap.hasError) {
            return Center(
              child: Text(
                usersSnap.error.toString(),
                style: TextStyle(color: AppColors.error),
              ),
            );
          }

          final users = usersSnap.data ?? [];

          return StreamBuilder<List<Exercise>>(
            stream: firestore.watchAllExercises(),
            builder: (context, exercisesSnap) {
              return StreamBuilder<List<StudentClassTerm>>(
                stream: firestore.watchAllClassTerms(),
                builder: (context, termsSnap) {
                  final exercises = exercisesSnap.data ?? [];
                  final classTerms = termsSnap.data ?? [];
                  final report = AdminReportService.build(
                    users: users,
                    exercises: exercises,
                    classTerms: classTerms,
                  );
                  final voucherAlerts = AdminAttentionUtils.buildVoucherAlerts(
                    students: users.where((u) => u.isStudent).toList(),
                    classTerms: classTerms,
                  );

                  return _AdminStatDetailBody(
                    kind: kind,
                    routes: routes,
                    users: users,
                    exercises: exercises,
                    report: report,
                    voucherAlerts: voucherAlerts,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _AdminStatDetailBody extends StatelessWidget {
  const _AdminStatDetailBody({
    required this.kind,
    required this.routes,
    required this.users,
    required this.exercises,
    required this.report,
    required this.voucherAlerts,
  });

  final AdminDashboardStatKind kind;
  final DashboardStatRoutes routes;
  final List<AppUser> users;
  final List<Exercise> exercises;
  final AdminReportData report;
  final List<AdminVoucherAlert> voucherAlerts;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AppCard(
          child: Text(
            kind.description,
            style: TextStyle(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ..._buildContent(context),
      ],
    );
  }

  List<Widget> _buildContent(BuildContext context) {
    return switch (kind) {
      AdminDashboardStatKind.totalUsers => [
          _roleSummary(),
          const SizedBox(height: 12),
          _userList(context, users),
        ],
      AdminDashboardStatKind.activeMurid => [
          _userList(
            context,
            users.where((u) => u.isStudent && u.active).toList(),
            emptyTitle: 'No active murid',
            emptySubtitle: 'Active student accounts will appear here.',
          ),
        ],
      AdminDashboardStatKind.exercises => [
          _exerciseList(context),
        ],
      AdminDashboardStatKind.incomeMonthly => [
          _IncomeByMonth(firestore: context.read<FirestoreService>()),
        ],
      AdminDashboardStatKind.newStudentsMonthly => [
          MonthlyStudentsChart(months: report.newStudentsByMonth),
          const SizedBox(height: 16),
          _signupList(context),
        ],
      AdminDashboardStatKind.voucherAlerts => [
          _voucherAlertList(context),
        ],
    };
  }

  Widget _roleSummary() {
    return AppCard(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          StatusPill(
            label: '${report.totalMurid} murid',
            color: AppColors.teal,
          ),
          StatusPill(
            label: '${report.totalTeachers} guru',
            color: AppColors.navy,
          ),
          StatusPill(
            label: '${report.totalAdmins} admin',
            color: adminPurple,
          ),
          if (report.inactiveUsers > 0)
            StatusPill(
              label: '${report.inactiveUsers} inactive',
              color: AppColors.textSecondary,
            ),
        ],
      ),
    );
  }

  Widget _userList(
    BuildContext context,
    List<AppUser> items, {
    String emptyTitle = 'No users',
    String emptySubtitle = 'Users will appear here after registration.',
  }) {
    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    final sorted = [...items]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Column(
      children: [
        for (final user in sorted)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              onTap: routes.userEdit == null
                  ? null
                  : () => context.push(routes.userEdit!(user.uid)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: _roleColor(user).withValues(alpha: 0.12),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: _roleColor(user),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          user.email,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusPill(
                    label: user.roleDisplayLabel,
                    color: _roleColor(user),
                  ),
                  if (!user.active) ...[
                    const SizedBox(width: 6),
                    StatusPill(
                      label: 'Inactive',
                      color: AppColors.textSecondary,
                    ),
                  ],
                  if (routes.userEdit != null) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _exerciseList(BuildContext context) {
    final published = exercises.where((e) => e.isPublished).toList()
      ..sort((a, b) => a.title.compareTo(b.title));

    if (published.isEmpty) {
      return const EmptyState(
        icon: Icons.menu_book_outlined,
        title: 'No published exercises',
        subtitle: 'Publish exercises from the Exercises tab.',
      );
    }

    return Column(
      children: [
        for (final exercise in published)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              onTap: routes.exerciseEdit == null
                  ? null
                  : () => context.push(
                        routes.exerciseEdit!(exercise.id),
                        extra: exercise,
                      ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          [
                            if (exercise.level != null) exercise.level!,
                            exercise.skillCategory.label,
                            '${exercise.questions.length} questions',
                          ].join(' · '),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusPill(
                    label: 'Published',
                    color: AppColors.success,
                  ),
                  if (routes.exerciseEdit != null) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _signupList(BuildContext context) {
    final students = users.where((u) => u.isStudent).toList()
      ..sort((a, b) {
        final aAt = a.createdAt;
        final bAt = b.createdAt;
        if (aAt == null && bAt == null) return 0;
        if (aAt == null) return 1;
        if (bAt == null) return -1;
        return bAt.compareTo(aAt);
      });

    if (students.isEmpty) {
      return const EmptyState(
        icon: Icons.person_add_alt_1_outlined,
        title: 'No student signups yet',
        subtitle: 'New murid registrations will appear here.',
      );
    }

    return Column(
      children: [
        for (final student in students)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              onTap: routes.userEdit == null
                  ? null
                  : () => context.push(routes.userEdit!(student.uid)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          student.level ?? 'Murid',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    student.createdAt == null
                        ? '—'
                        : DateFormat('d MMM yyyy').format(student.createdAt!),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  if (routes.userEdit != null) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _voucherAlertList(BuildContext context) {
    if (voucherAlerts.isEmpty) {
      return const EmptyState(
        icon: Icons.check_circle_outline,
        title: 'All caught up',
        subtitle: 'No voucher alerts right now.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return ResponsiveCardGrid(
          width: constraints.maxWidth,
          minCardWidth: 280,
          children: [
            for (final alert in voucherAlerts)
              AdminAttentionCard(
                alert: alert,
                onTap: () {
                  if (routes.voucherEdit != null) {
                    context.push(routes.voucherEdit!(alert.termId));
                  } else if (routes.userEdit != null) {
                    context.push(routes.userEdit!(alert.student.uid));
                  }
                },
              ),
          ],
        );
      },
    );
  }

  Color _roleColor(AppUser user) {
    if (user.isAdmin) return adminPurple;
    if (user.isTeacher) return AppColors.navy;
    return AppColors.teal;
  }
}

/// Twelve rows, newest month first: payments received and their total.
class _IncomeByMonth extends StatelessWidget {
  const _IncomeByMonth({required this.firestore});
  final FirestoreService firestore;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return StreamBuilder<List<Invoice>>(
      stream: firestore.watchAllInvoices(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final months = InvoiceUtils.paidByMonth(snap.data ?? const []);
        final yearTotal = months.fold(0, (sum, m) => sum + m.total);
        if (yearTotal == 0) {
          return const EmptyState(
            icon: Icons.payments_outlined,
            title: 'No payments in the last twelve months',
            subtitle:
                'Payments show here once an invoice is marked paid in Payments.',
          );
        }
        return AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (i, m) in months.indexed)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: i == months.length - 1
                        ? null
                        : Border(
                            bottom: BorderSide(color: AppColors.tableLine),
                          ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          DateFormat('MMMM yyyy').format(m.month),
                          style: TextStyle(
                            fontWeight:
                                i == 0 ? FontWeight.w700 : FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        m.count == 0
                            ? '—'
                            : '${m.count} payment${m.count == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 130,
                        child: Text(
                          currency.format(m.total),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: m.total > 0
                                ? AppColors.success
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
