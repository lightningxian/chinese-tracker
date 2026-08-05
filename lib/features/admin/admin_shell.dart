import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/exercise_authoring_platform.dart';
import '../../core/utils/shell_route_utils.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/notification_sheet.dart';
import '../../models/app_notification.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../teacher/teacher_attendance_tab.dart';
import '../teacher/teacher_exercises_tab.dart';
import 'admin_profile_tab.dart';
import 'admin_dashboard_tab.dart';
import 'admin_invoices_tab.dart';
import 'admin_reports_tab.dart';
import 'admin_users_tab.dart';
import 'admin_vouchers_tab.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  static const _destinations = [
    AppShellDestination(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    AppShellDestination(
      label: 'Users',
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
    ),
    AppShellDestination(
      label: 'Exercises',
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book,
    ),
    AppShellDestination(
      label: 'Classes',
      icon: Icons.event_outlined,
      selectedIcon: Icons.event,
    ),
    AppShellDestination(
      label: 'Vouchers',
      icon: Icons.confirmation_number_outlined,
      selectedIcon: Icons.confirmation_number,
    ),
    AppShellDestination(
      label: 'Payments',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
    ),
    AppShellDestination(
      label: 'Reports',
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart,
    ),
    AppShellDestination(
      label: 'Account',
      icon: Icons.manage_accounts_outlined,
      selectedIcon: Icons.manage_accounts,
    ),
  ];

  void _switchTab(int index) {
    final path = GoRouterState.of(context).uri.path;
    if (!ShellRouteUtils.isAdminRoot(path)) {
      context.go('/admin');
    }
    setState(() => _index = index);
  }

  Widget? _topBarAction(BuildContext context) {
    if (!ShellRouteUtils.isAdminRoot(GoRouterState.of(context).uri.path)) {
      return null;
    }

    final canManageExercises = ExerciseAuthoringPlatform.canManageExercises(
      context.read<AuthService>().appUser,
    );

    return switch (_index) {
      2 when canManageExercises => FilledButton.icon(
          onPressed: () => context.push('/admin/exercise/new'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.navy,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('New exercise'),
        ),
      3 => FilledButton.icon(
          onPressed: () => context.push('/admin/session/new'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.navy,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('New class'),
        ),
      4 => FilledButton.icon(
          onPressed: () => context.push('/admin/vouchers/new'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.navy,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('New voucher'),
        ),
      _ => null,
    };
  }

  void _openNotifications(List<AppNotification> notifications) {
    showNotificationsSheet(
      context: context,
      notifications: notifications,
      role: AppConstants.roleAdmin,
      onSelectTab: _switchTab,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.appUser;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final path = GoRouterState.of(context).uri.path;
    final nested = ShellRouteUtils.isAdminNested(path);
    final tabFromRoute = ShellRouteUtils.adminTabIndexForLocation(path);
    if (tabFromRoute != null && tabFromRoute != _index) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _index = tabFromRoute);
      });
    }

    final firestore = context.read<FirestoreService>();

    return StreamBuilder<List<AppNotification>>(
      stream: firestore.watchNotificationsForUser(user),
      builder: (context, notifSnap) {
        final notifications = notifSnap.data ?? [];
        final unread = notifications.where((n) => !n.read).length;

        final tabs = [
          AdminDashboardTab(onSwitchTab: _switchTab),
          const AdminUsersTab(),
          const TeacherExercisesTab(),
          const TeacherAttendanceTab(),
          const AdminVouchersTab(),
          const AdminInvoicesTab(),
          const AdminReportsTab(),
          AdminProfileTab(user: user),
        ];

        final title = nested
            ? ShellRouteUtils.adminTitleForLocation(path)
            : _destinations[_index].label;

        final canManageExercises = ExerciseAuthoringPlatform.canManageExercises(
          user,
        );

        return AppShellScaffold(
          title: title,
          selectedIndex: _index,
          onSelectedIndexChanged: _switchTab,
          destinations: _destinations,
          userName: user.name,
          roleLabel: 'Admin',
          topBarAction: _topBarAction(context),
          onBack: nested ? () => context.pop() : null,
          figmaMobileAppBar: true,
          showNotificationBell: true,
          notificationCount: unread,
          onNotificationTap: () => _openNotifications(notifications),
          fabLabel: nested
              ? null
              : switch (_index) {
                  2 when canManageExercises => 'New exercise',
                  3 => 'New class',
                  _ => null,
                },
          onFabPressed: nested
              ? null
              : switch (_index) {
                  2 when canManageExercises =>
                    () => context.push('/admin/exercise/new'),
                  3 => () => context.push('/admin/session/new'),
                  _ => null,
                },
          onSignOut: () => context.read<AuthService>().signOut(),
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Shell navigator must stay mounted so push() to sub-routes works.
              Positioned.fill(child: widget.child),
              if (!nested)
                Positioned.fill(
                  child: IndexedStack(index: _index, children: tabs),
                ),
            ],
          ),
        );
      },
    );
  }
}
