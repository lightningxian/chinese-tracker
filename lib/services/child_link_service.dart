import 'package:cloud_functions/cloud_functions.dart';

class ChildLinkException implements Exception {
  const ChildLinkException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Result of resolving a child access code to a student.
class ResolvedChild {
  const ResolvedChild({
    required this.studentId,
    this.teacherId,
    this.studentName,
  });

  final String studentId;
  final String? teacherId;
  final String? studentName;
}

/// Resolves a student's parent-access code to that student via the
/// `resolveChildCode` Cloud Function. Server-side so it works during parent
/// registration (before the parent has an auth account) and keeps the users
/// collection closed to code enumeration.
abstract final class ChildLinkService {
  static String normalizeCode(String raw) => raw.trim().toUpperCase();

  static Future<ResolvedChild> resolveChild({
    required String rawCode,
    FirebaseFunctions? functions,
  }) async {
    final code = normalizeCode(rawCode);
    if (code.length < 4) {
      throw const ChildLinkException(
        "Enter the child access code from your child's profile.",
      );
    }
    try {
      final callable = (functions ?? FirebaseFunctions.instance)
          .httpsCallable('resolveChildCode');
      final result = await callable.call({'code': code});
      final data = (result.data as Map).cast<String, dynamic>();
      final studentId = data['studentId'] as String?;
      if (studentId == null || studentId.isEmpty) {
        throw const ChildLinkException('Invalid child access code.');
      }
      return ResolvedChild(
        studentId: studentId,
        teacherId: data['teacherId'] as String?,
        studentName: data['studentName'] as String?,
      );
    } on FirebaseFunctionsException catch (e) {
      // 'internal' / 'unavailable' mean the server could not run the check
      // (for example Cloud Functions switched off), not a bad code.
      if (e.code == 'internal' ||
          e.code == 'unavailable' ||
          e.code == 'deadline-exceeded') {
        throw ChildLinkException(
          "We couldn't check the child access code right now. Please try "
          'again in a few minutes, or contact the centre on WhatsApp.',
        );
      }
      throw ChildLinkException(
        e.message ?? 'Invalid child access code. Check your child\'s profile.',
      );
    }
  }

  /// Authoritatively links the signed-in parent to a child via the child's
  /// access code, using the `linkChild` Cloud Function (admin SDK). This is the
  /// only way `studentIds` gets written — the client cannot set it directly.
  static Future<ResolvedChild> linkChild({
    required String rawCode,
    FirebaseFunctions? functions,
  }) async {
    final code = normalizeCode(rawCode);
    if (code.length < 4) {
      throw const ChildLinkException(
        "Enter the child access code from your child's profile.",
      );
    }
    try {
      final callable = (functions ?? FirebaseFunctions.instance)
          .httpsCallable('linkChild');
      final result = await callable.call({'code': code});
      final data = (result.data as Map).cast<String, dynamic>();
      final studentId = data['studentId'] as String?;
      if (studentId == null || studentId.isEmpty) {
        throw const ChildLinkException('Invalid child access code.');
      }
      return ResolvedChild(
        studentId: studentId,
        studentName: data['studentName'] as String?,
      );
    } on FirebaseFunctionsException catch (e) {
      // 'internal' / 'unavailable' mean the server could not run the check
      // (for example Cloud Functions switched off), not a bad code.
      if (e.code == 'internal' ||
          e.code == 'unavailable' ||
          e.code == 'deadline-exceeded') {
        throw ChildLinkException(
          "We couldn't check the child access code right now. Please try "
          'again in a few minutes, or contact the centre on WhatsApp.',
        );
      }
      throw ChildLinkException(
        e.message ?? 'Invalid child access code. Check your child\'s profile.',
      );
    }
  }
}
