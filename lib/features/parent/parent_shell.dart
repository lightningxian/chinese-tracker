import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/notification_sheet.dart';
import '../../models/app_notification.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import 'parent_overview_tab.dart';
import 'parent_payments_tab.dart';
import 'parent_profile_tab.dart';
import '../calendar/class_calendar_screen.dart';

class ParentShell extends StatefulWidget {
  const ParentShell({super.key});

  @override
  State<ParentShell> createState() => _ParentShellState();
}

class _ParentShellState extends State<ParentShell> {
  int _index = 0;
  String? _selectedChildId;

  static const _destinations = [
    AppShellDestination(
      label: 'Overview',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    AppShellDestination(
      label: 'Calendar',
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
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
      role: AppConstants.roleParent,
      onSelectTab: (i) => setState(() => _index = i),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final parent = auth.appUser;
    if (parent == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final firestore = context.read<FirestoreService>();

    return StreamBuilder<List<AppUser>>(
      stream: firestore.watchUsersByIds(parent.studentIds),
      builder: (context, childSnap) {
        final children = childSnap.data ?? [];
        final selectedChild = _resolveSelectedChild(children);

        return StreamBuilder<List<AppNotification>>(
          stream: firestore.watchNotificationsForUser(parent),
          builder: (context, notifSnap) {
            final notifications = notifSnap.data ?? [];
            final unread = notifications.where((n) => !n.read).length;

            final body = _buildBody(parent, children, selectedChild);

            return AppShellScaffold(
              title: _destinations[_index].label,
              selectedIndex: _index,
              onSelectedIndexChanged: (i) => setState(() => _index = i),
              destinations: _destinations,
              userName: parent.name,
              roleLabel: 'Orang Tua',
              showNotificationBell: true,
              notificationCount: unread,
              onNotificationTap: () => _openNotifications(notifications),
              onSignOut: () => context.read<AuthService>().signOut(),
              body: body,
            );
          },
        );
      },
    );
  }

  AppUser? _resolveSelectedChild(List<AppUser> children) {
    if (children.isEmpty) return null;
    final match = children.where((c) => c.uid == _selectedChildId).toList();
    return match.isNotEmpty ? match.first : children.first;
  }

  Widget _buildBody(
    AppUser parent,
    List<AppUser> children,
    AppUser? child,
  ) {
    if (_index == 3) {
      return ParentProfileTab(parent: parent);
    }

    if (child == null) {
      return const EmptyState(
        icon: Icons.family_restroom_outlined,
        title: 'No children linked',
        subtitle:
            'Ask your centre admin to link your account to your child, or '
            'register again with your child access code.',
      );
    }

    final content = switch (_index) {
      0 => ParentOverviewTab(child: child),
      1 => ClassCalendarScreen(
          title: 'Calendar',
          showAppBar: false,
          sessions: context
              .read<FirestoreService>()
              .watchTeacherSessions(AppConstants.contentOwnerFor(child)),
        ),
      2 => ParentPaymentsTab(child: child),
      _ => ParentOverviewTab(child: child),
    };

    if (children.length <= 1) return content;

    // Multiple children — show a switcher above the tab content.
    return Column(
      children: [
        _ChildSwitcher(
          children: children,
          selectedId: child.uid,
          onChanged: (id) => setState(() => _selectedChildId = id),
        ),
        Expanded(child: content),
      ],
    );
  }
}

class _ChildSwitcher extends StatelessWidget {
  const _ChildSwitcher({
    required this.children,
    required this.selectedId,
    required this.onChanged,
  });

  final List<AppUser> children;
  final String selectedId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      color: AppColors.surface,
      child: DropdownButtonFormField<String>(
        initialValue: selectedId,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Child',
          prefixIcon: Icon(Icons.person_outline),
          isDense: true,
        ),
        items: [
          for (final c in children)
            DropdownMenuItem(
              value: c.uid,
              child: Text(c.displayNameIndonesian),
            ),
        ],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}
