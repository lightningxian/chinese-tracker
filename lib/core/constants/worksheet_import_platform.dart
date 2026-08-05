import 'package:flutter/foundation.dart' show kIsWeb;

import '../../models/app_user.dart';
import 'exercise_authoring_platform.dart';

/// Worksheet upload / OCR import is admin-only on web.
abstract final class WorksheetImportPlatform {
  static bool isSupportedFor(AppUser? user) =>
      ExerciseAuthoringPlatform.canManageExercises(user);

  static const String unsupportedMessage =
      'Worksheet upload is only available to admins on web. '
      'Open Easy Study in a browser on desktop to import worksheets.';

  static void ensureSupportedFor(AppUser? user) {
    if (!isSupportedFor(user)) {
      throw WorksheetImportPlatformException(unsupportedMessage);
    }
  }
}

class WorksheetImportPlatformException implements Exception {
  WorksheetImportPlatformException(this.message);

  final String message;

  @override
  String toString() => message;
}
