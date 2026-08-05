import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/shell_route_utils.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/notification_sheet.dart';
import '../../models/app_notification.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import 'teacher_attendance_tab.dart';
import 'teacher_dashboard_tab.dart';
import 'teacher_exercises_tab.dart';
import 'teacher_grades_tab.dart';
import 'teacher_profile_tab.dart';
import 'teacher_students_tab.dart';

class TeacherShell extends StatefulWidget {
  const TeacherShell({super.key, required this.child});

  final Widget child;

  @override
  State<TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends State<TeacherShell> {
  int _index = 0;

  static const _destinations = [
    AppShellDestination(
      label: 'Dashboard',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    AppShellDestination(
      label: 'Students',
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
    ),
    AppShellDestination(
      label: 'Exercises',
      icon: Icons.fitness_center_outlined,
      selectedIcon: Icons.fitness_center,
    ),
    AppShellDestination(
      label: 'Classes',
      icon: Icons.event_outlined,
      selectedIcon: Icons.event,
    ),
    AppShellDestination(
      label: 'Grades',
      icon: Icons.grading_outlined,
      selectedIcon: Icons.grading,
    ),
    AppShellDestination(
      label: 'Profile',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
  ];

  void _switchTab(int index) {
    final path = GoRouterState.of(context).uri.path;
    if (!ShellRouteUtils.isTeacherRoot(path)) {
      context.go('/teacher');
    }
    setState(() => _index = index);
  }

  Widget? _topBarAction(BuildContext context) {
    if (!ShellRouteUtils.isTeacherRoot(GoRouterState.of(context).uri.path)) {
      return null;
    }

    return switch (_index) {
      3 => FilledButton.icon(
          onPressed: () => context.push('/teacher/session/new'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.navy,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('New class'),
        ),
      _ => null,
    };
  }

  void _openNotifications(List<AppNotification> notifications) {
    showNotificationsSheet(
      context: context,
      notifications: notifications,
      role: AppConstants.roleTeacher,
      onSelectTab: _switchTab,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.appUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final path = GoRouterState.of(context).uri.path;
    final nested = ShellRouteUtils.isTeacherNested(path);
    final tabFromRoute = ShellRouteUtils.teacherTabIndexForLocation(path);
    if (tabFromRoute != null && tabFromRoute != _index) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _index = tabFromRoute);
      });
    }

    final firestore = context.read<FirestoreService>();

    final tabs = [
      const TeacherDashboardTab(),
      const TeacherStudentsTab(),
      const TeacherExercisesTab(),
      const TeacherAttendanceTab(),
      const TeacherGradesTab(),
      TeacherProfileTab(user: user),
    ];

    final title = nested
        ? ShellRouteUtils.teacherTitleForLocation(path)
        : _destinations[_index].label;

    return StreamBuilder<List<AppNotification>>(
      stream: firestore.watchNotificationsForUser(user),
      builder: (context, notifSnap) {
        final notifications = notifSnap.data ?? [];
        final unread = notifications.where((n) => !n.read).length;

        return AppShellScaffold(
          title: title,
          selectedIndex: _index,
          onSelectedIndexChanged: _switchTab,
          destinations: _destinations,
          userName: user.name,
          roleLabel: 'Guru',
          topBarAction: _topBarAction(context),
          onBack: nested ? () => context.pop() : null,
          showNotificationBell: true,
          notificationCount: unread,
          onNotificationTap: () => _openNotifications(notifications),
          fabLabel: nested
              ? null
              : switch (_index) {
                  3 => 'New class',
                  _ => null,
                },
          onFabPressed: nested
              ? null
              : switch (_index) {
                  3 => () => context.push('/teacher/session/new'),
                  _ => null,
                },
          onSignOut: () => context.read<AuthService>().signOut(),
          body: Stack(
            fit: StackFit.expand,
            children: [
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
