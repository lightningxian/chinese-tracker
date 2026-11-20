import 'package:chinese_tracker/core/utils/notification_routes.dart';
import 'package:chinese_tracker/models/app_notification.dart';
import 'package:flutter_test/flutter_test.dart';

// Build 2B: promotion notices and test notices open the right place.
AppNotification _n(String kind, String role, [String? route]) => AppNotification(
      id: 'n',
      kind: NotificationKind.fromValue(kind),
      title: 't',
      body: 'b',
      forRole: role,
      targetRoute: route,
    );

void main() {
  test('admins open the Promotion screen, not the Classes tab', () {
    final n = _n('promotion', 'admin', '/admin/tests/promotion');
    expect(n.kind, NotificationKind.promotion);
    expect(NotificationRoutes.tabFor(n, role: 'admin'), isNull);
    expect(NotificationRoutes.pathFor(n, role: 'admin'), '/admin/tests/promotion');
  });

  test('students open the Tests tab for a level up and for a marked test', () {
    expect(NotificationRoutes.tabFor(_n('promotion', 'student', '/student/tests'), role: 'student'),
        NotificationRoutes.studentTestsTab);
    expect(NotificationRoutes.tabFor(_n('grading', 'student', '/student/tests'), role: 'student'),
        NotificationRoutes.studentTestsTab);
    // A marked exercise still opens Progress.
    expect(NotificationRoutes.tabFor(_n('grading', 'student', '/student'), role: 'student'), 3);
  });

  test('a parent opens the parent home', () {
    final n = _n('promotion', 'parent', '/parent');
    expect(NotificationRoutes.tabFor(n, role: 'parent'), isNull);
    expect(NotificationRoutes.pathFor(n, role: 'parent'), '/parent');
  });
}
