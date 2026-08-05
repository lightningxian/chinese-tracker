import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/notification_sheet.dart';
import '../../models/app_notification.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import 'student_home_tab.dart';
import 'student_lessons_tab.dart';
import 'student_my_classes_tab.dart';
import 'student_payments_tab.dart';
import 'student_progress_tab.dart';
import 'student_profile_tab.dart';

class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _index = 0;

  static const _destinations = [
    AppShellDestination(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    AppShellDestination(
      label: 'My Classes',
      icon: Icons.event_available_outlined,
      selectedIcon: Icons.event_available,
    ),
    AppShellDestination(
      label: 'Lessons',
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book,
    ),
    AppShellDestination(
      label: 'Progress',
      icon: Icons.trending_up_outlined,
      selectedIcon: Icons.trending_up,
    ),
    AppShellDestination(
      label: 'Payments',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
    ),
    AppShellDestination(
      label: 'Profile',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthService>().refreshProfile();
    });
  }

  void _openNotifications(List<AppNotification> notifications) {
    showNotificationsSheet(
      context: context,
      notifications: notifications,
      role: AppConstants.roleStudent,
      onSelectTab: (i) => setState(() => _index = i),
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
    final contentOwnerId = AppConstants.contentOwnerFor(user);
    final firestore = context.read<FirestoreService>();

    final tabs = [
      StudentHomeTab(student: user, contentOwnerId: contentOwnerId),
      StudentMyClassesTab(student: user),
      StudentLessonsTab(contentOwnerId: contentOwnerId, student: user),
      StudentProgressTab(studentId: user.uid),
      StudentPaymentsTab(student: user),
      StudentProfileTab(user: user),
    ];

    return StreamBuilder<List<AppNotification>>(
      stream: firestore.watchNotificationsForUser(user),
      builder: (context, notifSnap) {
        final notifications = notifSnap.data ?? [];
        final unread = notifications.where((n) => !n.read).length;

        return AppShellScaffold(
          title: _destinations[_index].label,
          selectedIndex: _index,
          onSelectedIndexChanged: (i) => setState(() => _index = i),
          destinations: _destinations,
          userName: user.name,
          roleLabel: 'Murid',
          hskLevel: user.level,
          showNotificationBell: true,
          notificationCount: unread,
          onNotificationTap: () => _openNotifications(notifications),
          onSignOut: () => context.read<AuthService>().signOut(),
          body: IndexedStack(index: _index, children: tabs),
        );
      },
    );
  }
}
