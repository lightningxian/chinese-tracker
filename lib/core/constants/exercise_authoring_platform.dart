import 'package:flutter/foundation.dart' show kIsWeb;

import '../../models/app_user.dart';

/// Creating and editing exercises is admin-only on web.
abstract final class ExerciseAuthoringPlatform {
  static bool get isWeb => kIsWeb;

  static bool canManageExercises(AppUser? user) =>
      kIsWeb && (user?.isAdmin ?? false);

  static const String unsupportedMessage =
      'Creating and editing exercises is only available on web. '
      'Open Easy Study in a browser on desktop to manage exercises.';

  static const String adminOnlyMessage =
      'Creating and editing exercises is only available to admins on web.';

  static const String teacherReadOnlyMessage =
      'View only — browse published practice and assign it to murid. '
      'Creating and editing exercises is done by admins on web.';

  static void ensureWeb() {
    if (!isWeb) {
      throw ExerciseAuthoringPlatformException(unsupportedMessage);
    }
  }

  static void ensureCanManage(AppUser user) {
    ensureWeb();
    if (!user.isAdmin) {
      throw ExerciseAuthoringPlatformException(adminOnlyMessage);
    }
  }

  static bool isAuthoringRoute(String location) {
    return location.endsWith('/exercise/new') ||
        (location.contains('/exercise/') && location.endsWith('/edit'));
  }

  static String? redirectFromAuthoringRoute(
    String location,
    AppUser user,
  ) {
    if (!isAuthoringRoute(location)) return null;
    if (canManageExercises(user)) return null;
    if (location.startsWith('/admin')) return '/admin';
    if (location.startsWith('/teacher')) return '/teacher';
    return null;
  }
}

class ExerciseAuthoringPlatformException implements Exception {
  ExerciseAuthoringPlatformException(this.message);

  final String message;

  @override
  String toString() => message;
}
