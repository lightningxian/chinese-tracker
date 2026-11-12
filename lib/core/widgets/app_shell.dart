import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';
import 'theme_toggle.dart';
import 'app_logo.dart';

/// Breakpoint for Figma Make desktop layout (sidebar + white top bar).
const kAppShellDesktopBreakpoint = 900.0;

class AppShellDestination {
  const AppShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class AppShellScaffold extends StatelessWidget {
  const AppShellScaffold({
    super.key,
    required this.title,
    required this.selectedIndex,
    required this.onSelectedIndexChanged,
    required this.destinations,
    required this.body,
    required this.userName,
    required this.roleLabel,
    this.hskLevel,
    this.topBarAction,
    this.fabLabel,
    this.onFabPressed,
    this.showNotificationBell = false,
    this.notificationCount = 0,
    this.onNotificationTap,
    this.figmaMobileAppBar = false,
    this.onSignOut,
    this.onBack,
  });

  final String title;
  final int selectedIndex;
  final ValueChanged<int> onSelectedIndexChanged;
  final List<AppShellDestination> destinations;
  final Widget body;
  final String userName;
  final String roleLabel;
  final String? hskLevel;
  final Widget? topBarAction;
  final String? fabLabel;
  final VoidCallback? onFabPressed;
  final bool showNotificationBell;
  final int notificationCount;
  final VoidCallback? onNotificationTap;
  final bool figmaMobileAppBar;
  final VoidCallback? onSignOut;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        MediaQuery.sizeOf(context).width >= kAppShellDesktopBreakpoint;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.pageBg,
        body: Row(
          children: [
            _AppSidebar(
              selectedIndex: selectedIndex,
              onSelectedIndexChanged: onSelectedIndexChanged,
              destinations: destinations,
              userName: userName,
              roleLabel: roleLabel,
              hskLevel: hskLevel,
              onSignOut: onSignOut,
            ),
            Expanded(
              child: Column(
                children: [
                  _AppTopBar(
                    title: title,
                    userName: userName,
                    roleLabel: roleLabel,
                    action: topBarAction,
                    onBack: onBack,
                    showNotificationBell: showNotificationBell,
                    notificationCount: notificationCount,
                    onNotificationTap: onNotificationTap,
                  ),
                  Expanded(child: body),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: figmaMobileAppBar
          ? _FigmaMobileAppBar(
              title: title,
              notificationCount: notificationCount,
              onNotificationTap: onNotificationTap,
              onBack: onBack,
            )
          : AppBar(
              automaticallyImplyLeading: false,
              title: Row(
                children: [
                  const AppLogo(variant: AppLogoVariant.mascot, height: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              actions: [
                AppearanceMenuButton(iconColor: AppColors.navy),
                if (showNotificationBell)
                  _NotificationBellButton(
                    count: notificationCount,
                    onPressed: onNotificationTap,
                    iconColor: AppColors.navy,
                  ),
              ],
            ),
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelectedIndexChanged,
        destinations: [
          for (final destination in destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: destination.label,
            ),
        ],
      ),
      floatingActionButton: fabLabel != null && onFabPressed != null
          ? FloatingActionButton.extended(
              onPressed: onFabPressed,
              backgroundColor: AppColors.navy,
              icon: const Icon(Icons.add),
              label: Text(fabLabel!),
            )
          : null,
    );
  }
}

class _AppSidebar extends StatelessWidget {
  const _AppSidebar({
    required this.selectedIndex,
    required this.onSelectedIndexChanged,
    required this.destinations,
    required this.userName,
    required this.roleLabel,
    this.hskLevel,
    this.onSignOut,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelectedIndexChanged;
  final List<AppShellDestination> destinations;
  final String userName;
  final String roleLabel;
  final String? hskLevel;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: AppColors.sidebarBg,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Full brand lockup (calligraphy + EASY STUDY badge + pencil).
                const Align(
                  alignment: Alignment.centerLeft,
                  child: AppLogo(variant: AppLogoVariant.primary, height: 46),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    AppUserAvatar(
                      initials: userInitials(userName),
                      size: 32,
                      backgroundColor: roleLabel == 'Guru'
                          ? AppColors.navyLight
                          : roleLabel == 'Admin'
                              ? const Color(0xFF7A4FBF)
                              : AppColors.teal,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _SidebarRoleChip(label: roleLabel),
                              if (hskLevel != null) HskBadge(label: hskLevel!),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.border),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              children: [
                for (var i = 0; i < destinations.length; i++)
                  _SidebarNavItem(
                    label: destinations[i].label,
                    icon: destinations[i].icon,
                    selected: selectedIndex == i,
                    onTap: () => onSelectedIndexChanged(i),
                  ),
              ],
            ),
          ),
          if (onSignOut != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: TextButton.icon(
                onPressed: onSignOut,
                icon: Icon(Icons.logout, size: 16, color: AppColors.error),
                label: Text(
                  context.l10n.commonSignOut,
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  const _SidebarNavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        // Active item is a solid near-black navy pill with white text.
        color: selected ? AppColors.sidebarActive : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarRoleChip extends StatelessWidget {
  const _SidebarRoleChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.pageBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AppTopBar extends StatelessWidget {
  const _AppTopBar({
    required this.title,
    required this.userName,
    required this.roleLabel,
    this.action,
    this.onBack,
    this.showNotificationBell = false,
    this.notificationCount = 0,
    this.onNotificationTap,
  });

  final String title;
  final String userName;
  final String roleLabel;
  final Widget? action;
  final VoidCallback? onBack;
  final bool showNotificationBell;
  final int notificationCount;
  final VoidCallback? onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back, size: 20),
              color: AppColors.navy,
              tooltip: context.l10n.appShellBack,
              onPressed: onBack,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 12),
          // Light-gray role chip, per the reference top bar.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.pageBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              roleLabel,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          if (action != null) ...[
            action!,
            const SizedBox(width: 12),
          ],
          const AppearanceMenuButton(),
          const SizedBox(width: 4),
          if (showNotificationBell) ...[
            _NotificationBellButton(
              count: notificationCount,
              onPressed: onNotificationTap,
            ),
            const SizedBox(width: 8),
          ],
          AppUserAvatar(initials: userInitials(userName), size: 32),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              Text(
                roleLabel,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AppUserAvatar extends StatelessWidget {
  AppUserAvatar({
    super.key,
    required this.initials,
    this.size = 36,
    Color? backgroundColor,
    this.photoUrl,
  }) : backgroundColor = backgroundColor ?? AppColors.navy;

  final String initials;
  final double size;
  final Color backgroundColor;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initialsBubble(),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return SizedBox(
              width: size,
              height: size,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: backgroundColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }
    return _initialsBubble();
  }

  Widget _initialsBubble() {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: size * 0.35,
        ),
      ),
    );
  }
}

class HskBadge extends StatelessWidget {
  const HskBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.teal,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

String userInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return '${parts.first.substring(0, 1)}${parts[1].substring(0, 1)}'
      .toUpperCase();
}

class _FigmaMobileAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _FigmaMobileAppBar({
    required this.title,
    required this.notificationCount,
    this.onNotificationTap,
    this.onBack,
  });

  final String title;
  final int notificationCount;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 64,
      backgroundColor: AppColors.card,
      shape: Border(bottom: BorderSide(color: AppColors.border)),
      titleSpacing: 16,
      title: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: onBack != null
                  ? IconButton(
                      icon: Icon(Icons.arrow_back, color: AppColors.navy),
                      tooltip: context.l10n.appShellBack,
                      onPressed: onBack,
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppLogo(
                            variant: AppLogoVariant.mascot, height: 30),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppConstants.brandName,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                height: 1.1,
                              ),
                            ),
                            Text(
                              AppConstants.brandNameChinese,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
            Text(
              title,
              style: TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppearanceMenuButton(iconColor: AppColors.navy),
                  _NotificationBellButton(
                    count: notificationCount,
                    onPressed: onNotificationTap,
                    iconColor: AppColors.navy,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationBellButton extends StatelessWidget {
  const _NotificationBellButton({
    required this.count,
    this.onPressed,
    this.iconColor,
  });

  final int count;
  final VoidCallback? onPressed;

  /// Defaults to the secondary text colour.
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(Icons.notifications_none,
              color: iconColor ?? AppColors.textSecondary),
        ),
        if (count > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                count > 9 ? '9+' : '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
