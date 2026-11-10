import '../../models/app_notification.dart';
import '../constants/app_constants.dart';

/// Resolves where a notification should take the user.
abstract final class NotificationRoutes {
  /// Prefer [AppNotification.targetRoute]; otherwise kind + role defaults.
  static String? pathFor(AppNotification notification, {required String role}) {
    final explicit = notification.targetRoute?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;

    return switch (notification.kind) {
      NotificationKind.registration =>
        role == AppConstants.roleAdmin ? '/admin' : '/teacher',
      NotificationKind.grading => role == AppConstants.roleStudent
          ? '/student'
          : role == AppConstants.roleAdmin
              ? '/admin'
              : '/teacher',
      NotificationKind.session => role == AppConstants.roleStudent
          ? '/student'
          : role == AppConstants.roleAdmin
              ? '/admin'
              : '/teacher',
    };
  }

  /// Tab index inside the role shell (null = leave current tab).
  static int? tabFor(AppNotification notification, {required String role}) {
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
