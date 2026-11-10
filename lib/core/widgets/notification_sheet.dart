import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/app_notification.dart';
import '../../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/notification_routes.dart';

Future<void> showNotificationsSheet({
  required BuildContext context,
  required List<AppNotification> notifications,
  required String role,
  void Function(int tabIndex)? onSelectTab,
}) {
  final firestore = context.read<FirestoreService>();

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Notifications',
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
            ),
            const SizedBox(height: 12),
            if (notifications.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No notifications yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: notifications.take(12).length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final n = notifications[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        n.title,
                        style: TextStyle(
                          fontWeight:
                              n.read ? FontWeight.w500 : FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(n.body),
                      trailing: n.read
                          ? const Icon(Icons.chevron_right, size: 20)
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right, size: 20),
                              ],
                            ),
                      onTap: () async {
                        if (!n.read) {
                          await firestore.markNotificationRead(n.id);
                        }
                        if (!ctx.mounted) return;
                        Navigator.of(ctx).pop();

                        final tab = NotificationRoutes.tabFor(n, role: role);
                        if (tab != null && onSelectTab != null) {
                          onSelectTab(tab);
                          return;
                        }

                        final path = NotificationRoutes.pathFor(n, role: role);
                        if (path != null && context.mounted) {
                          context.go(path);
                        }
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
