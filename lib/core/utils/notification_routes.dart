import '../../models/app_notification.dart';
import '../constants/app_constants.dart';

/// Resolves where a notification should take the user.
abstract final class NotificationRoutes {
  /// Position of **Tests** in the student shell.
  static const studentTestsTab = 4;

  /// Prefer [AppNotification.targetRoute]; otherwise kind + role defaults.
  static String? pathFor(AppNotification notification, {required String role}) {
    final explicit = notification.targetRoute?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;

    return switch (notification.kind) {
      // Build 3: the admin opens the Approval list; the student the app.
      NotificationKind.registration => switch (role) {
          AppConstants.roleAdmin => '/admin/users/approval',
          AppConstants.roleStudent => '/student',
          _ => '/teacher',
        },
      NotificationKind.grading => role == AppConstants.roleStudent
          ? '/student'
          : role == AppConstants.roleAdmin
              ? '/admin'
              : '/teacher',
      NotificationKind.promotion => switch (role) {
          AppConstants.roleAdmin => '/admin/tests/promotion',
          AppConstants.roleStudent => '/student',
          AppConstants.roleParent => '/parent',
          _ => '/teacher',
        },
      NotificationKind.session ||
      NotificationKind.reminder =>
        role == AppConstants.roleStudent
            ? '/student'
            : role == AppConstants.roleAdmin
                ? '/admin'
                : '/teacher',
    };
  }

  /// Tab index inside the role shell (null = leave current tab).
  static int? tabFor(AppNotification notification, {required String role}) {
    // Test results, marking and promotions open the student's Tests tab
    // (the functions write `/student/tests`, which is a tab, not a route).
    if (role == AppConstants.roleStudent &&
        (notification.kind == NotificationKind.promotion ||
            notification.targetRoute?.trim() == '/student/tests')) {
      return studentTestsTab;
    }
    // Build 3: a registration waiting for approval opens its own page.
    if (notification.kind == NotificationKind.registration &&
        (role == AppConstants.roleStudent ||
            notification.targetRoute?.trim() == '/admin/users/approval')) {
      return null;
    }
    return switch ((role, notification.kind)) {
      (AppConstants.roleAdmin, NotificationKind.registration) => 1, // Users
      (AppConstants.roleAdmin, NotificationKind.grading) => 2, // Exercises
      (AppConstants.roleAdmin, NotificationKind.session) => 4, // Classes
      (AppConstants.roleTeacher, NotificationKind.registration) =>
        1, // Students
      (AppConstants.roleTeacher, NotificationKind.grading) => 2, // Exercises
      (AppConstants.roleTeacher, NotificationKind.session) => 3, // Classes
      (AppConstants.roleStudent, NotificationKind.grading) => 3, // Progress
      (AppConstants.roleStudent, NotificationKind.session) => 1, // My Classes
      _ => null,
    };
  }
}
