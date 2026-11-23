import 'package:chinese_tracker/core/utils/notification_routes.dart';
import 'package:chinese_tracker/models/app_notification.dart';
import 'package:flutter_test/flutter_test.dart';

AppNotification _n(String role) => AppNotification(
      id: 'ann_x_$role',
      kind: NotificationKind.fromValue('announcement'),
      title: 'Parent meeting',
      body: '',
      forRole: role,
      userId: '',
      targetRoute: '/$role',
    );

void main() {
  group('Owner 2026-11-24 (third round)', () {
    test('a News notice is an announcement, not a class session', () {
      expect(NotificationKind.fromValue('announcement'), NotificationKind.announcement);
    });

    test('a News notice opens the home tab of every role', () {
      for (final role in ['student', 'teacher', 'parent', 'admin']) {
        expect(NotificationRoutes.tabFor(_n(role), role: role), 0, reason: role);
      }
    });
  });
}
