import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../core/constants/app_constants.dart';
import '../models/teacher_link_code.dart';

abstract final class TeacherLinkCodeService {
  static const _codeLength = 6;
  static const _rotation = Duration(minutes: 15);
  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static String _generateCode(Random random) {
    return List.generate(
      _codeLength,
      (_) => _alphabet[random.nextInt(_alphabet.length)],
    ).join();
  }

  static String normalizeCode(String raw) => raw.trim().toUpperCase();

  static Future<TeacherLinkCode> ensureLinkCode({
    required FirebaseFirestore firestore,
    required String teacherId,
  }) async {
    final stateRef = firestore
        .collection(AppConstants.teacherLinkStateCollection)
        .doc(teacherId);
    final stateSnap = await stateRef.get();
    final now = DateTime.now();

    if (stateSnap.exists) {
      final data = stateSnap.data() ?? {};
      final code = data['code'] as String?;
      final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
      if (code != null &&
          expiresAt != null &&
          now.isBefore(expiresAt.subtract(const Duration(seconds: 2)))) {
        return TeacherLinkCode(code: code, expiresAt: expiresAt);
      }
      if (code != null) {
        await firestore
            .collection(AppConstants.teacherLinkCodesCollection)
            .doc(code)
            .delete()
            .catchError((_) {});
      }
    }

    final random = Random.secure();
    var code = _generateCode(random);
    for (var attempt = 0; attempt < 8; attempt++) {
      var taken = false;
      try {
        final existing = await firestore
            .collection(AppConstants.teacherLinkCodesCollection)
            .doc(code)
            .get();
        taken = existing.exists;
      } on FirebaseException catch (_) {
        // Rules deny reading a code owned by another teacher, so a
        // permission error means the code is already in use — regenerate.
        taken = true;
      }
      if (!taken) break;
      code = _generateCode(random);
    }

    final expiresAt = now.add(_rotation);
    final batch = firestore.batch();
    final codeRef =
        firestore.collection(AppConstants.teacherLinkCodesCollection).doc(code);
    batch.set(codeRef, {
      'teacherId': teacherId,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(stateRef, {
      'code': code,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();

    return TeacherLinkCode(code: code, expiresAt: expiresAt);
  }

  /// Resolves a link code to its teacher via the `resolveLinkCode` Cloud
  /// Function. Resolution is server-side so `teacher_link_codes` stays closed
  /// to anonymous reads, and so it works during email/password registration
  /// (before the student has an auth account).
  ///
  /// [firestore] is retained for call-site compatibility and is unused here.
  static Future<String> resolveTeacherId({
    required FirebaseFirestore firestore,
    required String rawCode,
    FirebaseFunctions? functions,
  }) async {
    final code = normalizeCode(rawCode);
    if (code.length < 4) {
      throw TeacherLinkCodeException('Enter the link code from your teacher.');
    }

    try {
      final callable = (functions ?? FirebaseFunctions.instance)
          .httpsCallable('resolveLinkCode');
      final result = await callable.call({'code': code});
      final data = (result.data as Map).cast<String, dynamic>();
      final teacherId = data['teacherId'] as String?;
      if (teacherId == null || teacherId.isEmpty) {
        throw TeacherLinkCodeException('This link code is no longer valid.');
      }
      return teacherId;
    } on FirebaseFunctionsException catch (e) {
      // 'internal' / 'unavailable' mean the server could not run the check
      // (for example Cloud Functions switched off), not a bad code.
      if (e.code == 'internal' ||
          e.code == 'unavailable' ||
          e.code == 'deadline-exceeded') {
        throw TeacherLinkCodeException(
          "We couldn't check the link code right now. Please try again in a "
          'few minutes, or contact the centre on WhatsApp.',
        );
      }
      throw TeacherLinkCodeException(
        e.message ??
            'Invalid link code. Ask your teacher for the current code.',
      );
    }
  }
}
