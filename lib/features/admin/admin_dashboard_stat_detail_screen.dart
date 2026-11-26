import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/paging/date_range.dart';
import '../../core/paging/paged_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/invoice_utils.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/paging_bars.dart';
import '../../core/widgets/shell_nested_page.dart';
import '../../core/widgets/status_pill.dart';
import '../../l10n/l10n.dart';
import '../../l10n/labels_admin.dart';
import '../../l10n/labels_exercises.dart';
import '../../l10n/labels_reports.dart';
import '../../models/admin_dashboard_stat_kind.dart';
import '../../models/app_user.dart';
import '../../models/dashboard_stat_routes.dart';
import '../../models/exercise.dart';
import '../../models/student_class_term.dart';
import '../../services/admin_report_service.dart';
import '../../services/firestore_service.dart';
import '../../services/list_pages_service.dart';
import 'admin_dashboard_widgets.dart';

/// Students show the staff label (PLAN.md §3); other roles keep their name.
String _listName(AppUser u) => u.isStudent ? u.staffLabel : u.name;

/// An admin-dashboard figure opened as a list. Build 9 part 2: each list is
/// read a page at a time (accounts by name, packages, sign-ups in a date
/// range, vouchers running out); the totals are count and sum
/// aggregations, not the whole users, exercises, vouchers and invoices
/// collections streamed into the browser.
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
    return ShellNestedPage(
      embedded: embedded,
      title: kind.localizedTitle(context.l10n),
      child: _AdminStatDetailBody(key: ValueKey(kind), kind: kind, routes: routes),
    );
  }
}

class _AdminStatDetailBody extends StatefulWidget {
  const _AdminStatDetailBody({super.key, required this.kind, required this.routes});

  final AdminDashboardStatKind kind;
  final DashboardStatRoutes routes;

  @override
  State<_AdminStatDetailBody> createState() => _AdminStatDetailBodyState();
}

class _AdminStatDetailBodyState extends State<_AdminStatDetailBody> {
  late final FirestoreService _fs = context.read<FirestoreService>();
  late final ListPagesService _lists = ListPagesService(_fs);
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  PagedController<Object?>? _pages;
  Future<({int students, int teachers, int admins, int inactive})>? _roles;
  Future<List<MonthlyCount>>? _signups;

  AdminDashboardStatKind get kind => widget.kind;

  @override
  void initState() {
    super.initState();
    switch (kind) {
      case AdminDashboardStatKind.totalUsers:
        _roles = _roleCounts();
        _pages = PagedController<Object?>(
            build: (_) => _fs.userSource(_fs.userListQuery()));
      case AdminDashboardStatKind.activeMurid:
        _pages = PagedController<Object?>(
            build: (_) => _fs.userSource(_fs.userListQuery(
                role: AppConstants.roleStudent, active: true)));
      case AdminDashboardStatKind.exercises:
        _pages = PagedController<Object?>(
          range: const DateRangeSel.all(),
          build: (range) => FirestorePageSource<Object?>(
            ListPagesService.newestFirst(
                _db
                    .collection(AppConstants.exercisesCollection)
                    .where('listPublished', isEqualTo: true),
                'listAt',
                range),
            Exercise.fromFirestore,
          ),
        );
      case AdminDashboardStatKind.newStudentsMonthly:
        _signups = _signupsByMonth();
        _pages = PagedController<Object?>(
          build: (range) => FirestorePageSource<Object?>(
            ListPagesService.newestFirst(
                _db
                    .collection(AppConstants.usersCollection)
                    .where('role', isEqualTo: AppConstants.roleStudent),
                'createdAt',
                range),
            AppUser.fromFirestore,
          ),
        );
      case AdminDashboardStatKind.voucherAlerts:
        _pages = PagedController<Object?>(build: (_) => _voucherAlerts());
      case AdminDashboardStatKind.incomeMonthly:
        break;
    }
  }

  @override
  void dispose() {
    _pages?.dispose();
    super.dispose();
  }

  Future<int> _count(Query<Map<String, dynamic>> q) async =>
      (await q.count().get()).count ?? 0;

  Future<({int students, int teachers, int admins, int inactive})>
      _roleCounts() async {
    final users = _db.collection(AppConstants.usersCollection);
    final r = await Future.wait([
      _count(users.where('role', isEqualTo: AppConstants.roleStudent)),
      _count(users.where('role', isEqualTo: AppConstants.roleTeacher)),
      _count(users.where('role', isEqualTo: AppConstants.roleAdmin)),
      _count(users.where('active', isEqualTo: false)),
    ]);
    return (students: r[0], teachers: r[1], admins: r[2], inactive: r[3]);
  }

  /// New students in each of the last six months (count per month).
  Future<List<MonthlyCount>> _signupsByMonth() async {
    final now = DateTime.now();
    final users = _db
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: AppConstants.roleStudent);
    return Future.wait([
      for (var i = 5; i >= 0; i--)
        () async {
          final from = DateTime(now.year, now.month - i, 1);
          final to = DateTime(from.year, from.month + 1, 1);
          final n = await _count(users
              .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
              .where('createdAt', isLessThan: Timestamp.fromDate(to)));
          return MonthlyCount(
              label: DateFormat('MMM', 'en_US').format(from), count: n);
        }(),
    ]);
  }

  /// Vouchers still running (deadline today or later) with 2 sessions or
  /// fewer, of active students; read a page at a time.
  PageSource<Object?> _voucherAlerts() {
    final today = DateRangeSel.isoDay(DateTime.now());
    final terms = FilteredPageSource<StudentClassTerm>(
      FirestorePageSource(
        _db
            .collection(AppConstants.studentClassTermsCollection)
            .where('deadlineDate', isGreaterThanOrEqualTo: today)
            .orderBy('deadlineDate'),
        StudentClassTerm.fromFirestore,
      ),
      (t) => t.isWithinTermDates && t.sessionsRemaining <= 2,
    );
    final alerts = MappedPageSource<StudentClassTerm, AdminVoucherAlert?>(
      terms,
      (page) async {
        final users = await _lists.usersById(page.map((t) => t.studentId));
        return [
          for (final t in page)
            users[t.studentId] == null || !users[t.studentId]!.active
                ? null
                : AdminVoucherAlert(
                    student: users[t.studentId]!,
                    sessionsRemaining: t.sessionsRemaining,
                    termId: t.id,
                  ),
        ];
      },
    );
    return FilteredPageSource<AdminVoucherAlert?>(alerts, (a) => a != null);
  }

  Widget _description(BuildContext context) => AppCard(
        child: Text(
          kind.localizedDescription(context.l10n),
          style: TextStyle(color: AppColors.textSecondary, height: 1.45),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (kind == AdminDashboardStatKind.incomeMonthly) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _description(context),
          const SizedBox(height: 16),
          _IncomeByMonth(lists: _lists),
        ],
      );
    }
    final pages = _pages!;
    final dated = kind == AdminDashboardStatKind.exercises ||
        kind == AdminDashboardStatKind.newStudentsMonthly;
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _description(context),
        if (_roles != null) ...[
          const SizedBox(height: 12),
          _RoleSummary(counts: _roles!),
        ],
        if (_signups != null) ...[
          const SizedBox(height: 12),
          FutureBuilder<List<MonthlyCount>>(
            future: _signups,
            builder: (context, snap) => snap.hasData
                ? MonthlyStudentsChart(months: snap.data!)
                : const LinearProgressIndicator(minHeight: 2),
          ),
        ],
        if (dated) ...[
          const SizedBox(height: 12),
          DateRangeBar(value: pages.range, onChanged: pages.setRange),
        ],
      ],
    );
    final (emptyIcon, emptyTitle, emptySubtitle) = switch (kind) {
      AdminDashboardStatKind.activeMurid => (
          Icons.people_outline,
          l.adminDashNoActiveMurid,
          l.adminDashActiveAccountsAppear
        ),
      AdminDashboardStatKind.exercises => (
          Icons.menu_book_outlined,
          l.adminDashNoPublishedExercises,
          l.adminDashPublishFromTab
        ),
      AdminDashboardStatKind.newStudentsMonthly => (
          Icons.person_add_alt_1_outlined,
          l.adminDashNoSignups,
          l.adminDashSignupsAppear
        ),
      AdminDashboardStatKind.voucherAlerts => (
          Icons.check_circle_outline,
          l.adminDashAllCaughtUp,
          l.adminDashNoVoucherAlerts
        ),
      _ => (Icons.people_outline, l.adminDashNoUsers, l.adminDashUsersAppear),
    };
    return ListenableBuilder(
      listenable: pages,
      builder: (context, _) => PagedListBody<Object?>(
        controller: pages,
        header: header,
        separator: 8,
        emptyIcon: emptyIcon,
        emptyTitle: emptyTitle,
        emptySubtitle: emptySubtitle,
        itemBuilder: (context, item) => switch (item) {
          AppUser u when kind == AdminDashboardStatKind.newStudentsMonthly =>
            _SignupCard(student: u, routes: widget.routes),
          AppUser u => _UserCard(user: u, routes: widget.routes),
          Exercise e => _ExerciseCard(exercise: e, routes: widget.routes),
          AdminVoucherAlert a => AdminAttentionCard(
              alert: a,
              onTap: () {
                final routes = widget.routes;
                if (routes.voucherEdit != null) {
                  context.push(routes.voucherEdit!(a.termId));
                } else if (routes.userEdit != null) {
                  context.push(routes.userEdit!(a.student.uid));
                }
              },
            ),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }
}

class _RoleSummary extends StatelessWidget {
  const _RoleSummary({required this.counts});

  final Future<({int students, int teachers, int admins, int inactive})> counts;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return FutureBuilder(
      future: counts,
      builder: (context, snap) {
        final c = snap.data;
        if (c == null) return const LinearProgressIndicator(minHeight: 2);
        return AppCard(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusPill(label: l.adminDashMuridCount(c.students), color: AppColors.teal),
              StatusPill(label: l.adminDashGuruCount(c.teachers), color: AppColors.navy),
              StatusPill(label: l.adminDashAdminCount(c.admins), color: adminPurple),
              if (c.inactive > 0)
                StatusPill(
                    label: l.adminDashInactiveCount(c.inactive),
                    color: AppColors.textSecondary),
            ],
          ),
        );
      },
    );
  }
}

Color _roleColor(AppUser user) {
  if (user.isAdmin) return adminPurple;
  if (user.isTeacher) return AppColors.navy;
  return AppColors.teal;
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.routes});

  final AppUser user;
  final DashboardStatRoutes routes;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppCard(
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
              style: TextStyle(color: _roleColor(user), fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_listName(user), style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(user.email,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          StatusPill(label: user.roleLocalized(l), color: _roleColor(user)),
          if (!user.active) ...[
            const SizedBox(width: 6),
            StatusPill(label: l.adminDashInactive, color: AppColors.textSecondary),
          ],
          if (routes.userEdit != null) ...[
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.exercise, required this.routes});

  final Exercise exercise;
  final DashboardStatRoutes routes;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppCard(
      onTap: routes.exerciseEdit == null
          ? null
          : () => context.push(routes.exerciseEdit!(exercise.id), extra: exercise),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  [
                    if (exercise.level != null) exercise.level!,
                    exercise.skillCategory.localized(l),
                    l.adminDashQuestionCount(exercise.questions.length),
                  ].join(' · '),
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          StatusPill(label: l.adminDashPublished, color: AppColors.success),
          if (routes.exerciseEdit != null) ...[
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ],
      ),
    );
  }
}

class _SignupCard extends StatelessWidget {
  const _SignupCard({required this.student, required this.routes});

  final AppUser student;
  final DashboardStatRoutes routes;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppCard(
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
                Text(student.staffLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(student.level ?? l.commonStudent,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          Text(
            student.createdAt == null
                ? '—'
                : DateFormat('d MMM yyyy').format(student.createdAt!),
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          if (routes.userEdit != null) ...[
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ],
      ),
    );
  }
}

/// Twelve rows, newest month first: payments received and their total.
/// Build 9 part 2: one count and one sum aggregation per month on the paid
/// invoices (index status + paidAt), not every invoice downloaded.
class _IncomeByMonth extends StatefulWidget {
  const _IncomeByMonth({required this.lists});
  final ListPagesService lists;

  @override
  State<_IncomeByMonth> createState() => _IncomeByMonthState();
}

class _IncomeByMonthState extends State<_IncomeByMonth> {
  late final Future<List<MonthlyIncome>> _months = _load();

  Future<List<MonthlyIncome>> _load() {
    final now = DateTime.now();
    final paid = FirebaseFirestore.instance
        .collection(AppConstants.invoicesCollection)
        .where('status', isEqualTo: 'paid');
    return Future.wait([
      for (var i = 0; i < 12; i++)
        () async {
          final month = DateTime(now.year, now.month - i, 1);
          final next = DateTime(month.year, month.month + 1, 1);
          final r = await paid
              .where('paidAt', isGreaterThanOrEqualTo: Timestamp.fromDate(month))
              .where('paidAt', isLessThan: Timestamp.fromDate(next))
              .aggregate(count(), sum('amount'))
              .get();
          return MonthlyIncome(
            month: month,
            total: (r.getSum('amount') ?? 0).round(),
            count: r.count ?? 0,
          );
        }(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return FutureBuilder<List<MonthlyIncome>>(
      future: _months,
      builder: (context, snap) {
        if (!snap.hasData) {
          return snap.hasError
              ? Text('${snap.error}', style: TextStyle(color: AppColors.error))
              : const Center(child: CircularProgressIndicator());
        }
        final months = snap.data!;
        final yearTotal = months.fold(0, (acc, m) => acc + m.total);
        if (yearTotal == 0) {
          return EmptyState(
            icon: Icons.payments_outlined,
            title: l.adminDashNoPaymentsTwelveMonths,
            subtitle: l.adminDashPaymentsShowHint,
          );
        }
        return AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (i, m) in months.indexed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    border: i == months.length - 1
                        ? null
                        : Border(bottom: BorderSide(color: AppColors.tableLine)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          DateFormat('MMMM yyyy').format(m.month),
                          style: TextStyle(
                            fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        m.count == 0 ? '—' : l.adminDashPaymentCount(m.count),
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 130,
                        child: Text(
                          currency.format(m.total),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: m.total > 0 ? AppColors.success : AppColors.textSecondary,
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
