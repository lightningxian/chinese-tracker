import 'package:flutter/foundation.dart' show kIsWeb;

import '../../models/app_user.dart';
import '../../models/exercise.dart';

/// Who may author what, and only on web.
///
/// - **Packages** (exercises built from the question bank): admins and
///   teachers. A teacher manages only the packages they created
///   (`teacherId` = their uid); an admin manages every exercise.
/// - **Question bank** (scanning worksheets, typing or pasting questions,
///   editing or deleting bank questions, loading the sample sheets) and the
///   **old-format exercise editor** (questions inside the document): admins.
abstract final class ExerciseAuthoringPlatform {
  static bool get isWeb => kIsWeb;

  /// Admin signed in on web: the gate for the question bank and the
  /// old-format editor.
  static bool isAdminOnWeb(AppUser? user) => kIsWeb && (user?.isAdmin ?? false);

  /// Staff (admin or teacher) on web may build packages from the bank.
  static bool canManageExercises(AppUser? user) =>
      kIsWeb && user != null && (user.isAdmin || user.isTeacher);

  /// Question bank authoring (scan, paste, type, edit, delete, samples).
  static bool canManageBank(AppUser? user) => isAdminOnWeb(user);

  /// The old-format editor (questions inside the exercise document).
  static bool canManageLegacyExercises(AppUser? user) => isAdminOnWeb(user);

  /// Whether [user] may edit or delete this particular exercise: admins
  /// always; teachers only their own packages, never old-format exercises.
  static bool canEditExercise(AppUser? user, Exercise exercise) {
    if (!canManageExercises(user)) return false;
    if (user!.isAdmin) return true;
    return exercise.isPackage && exercise.teacherId == user.uid;
  }

  static const String unsupportedMessage =
      'Creating and editing exercises is only available on web. '
      'Open Easy Study in a browser on desktop to manage exercises.';

  static const String adminOnlyMessage =
      'This is only available to admins on web.';

  static const String staffOnlyMessage =
      'Creating and editing exercises is only available to admins and '
      'teachers on web.';

  static const String ownPackagesOnlyMessage =
      'Teachers can only edit or delete the packages they created.';

  static const String teacherReadOnlyMessage =
      'View only — browse published practice and assign it to murid. '
      'Creating and editing exercises is done on web.';

  static void ensureWeb() {
    if (!isWeb) {
      throw ExerciseAuthoringPlatformException(unsupportedMessage);
    }
  }

  static void ensureCanManage(AppUser user) {
    ensureWeb();
    if (!user.isAdmin && !user.isTeacher) {
      throw ExerciseAuthoringPlatformException(staffOnlyMessage);
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
