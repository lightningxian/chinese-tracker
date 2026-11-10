import 'dart:async';
import 'dart:math' as math;
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/exercise_authoring_platform.dart';
import '../core/errors/class_term_errors.dart';
import '../core/utils/grade_utils.dart';
import '../core/utils/level_utils.dart';
import '../core/errors/conclude_errors.dart';
import '../core/errors/session_errors.dart';
import '../models/app_user.dart';
import '../models/attendance_record.dart';
import '../models/class_session.dart';
import '../models/student_class_term.dart';
import '../models/exercise.dart';
import '../models/exercise_skill_category.dart';
import '../models/exercise_type.dart';
import '../models/exercise_assignment.dart';
import '../models/exercise_level.dart';
import '../models/exercise_result.dart';
import '../models/grade.dart';
import '../models/question_bank_item.dart';
import '../models/student_assigned_exercise.dart';
import '../models/app_notification.dart';
import '../models/audit_log.dart';
import '../models/evaluation.dart';
import '../models/invoice.dart';
import '../models/material_item.dart';
import '../models/org_settings.dart';
import '../models/pricing_settings.dart';
import '../models/lesson.dart';
import '../models/quiz.dart';
import '../models/quiz_result.dart';
import '../models/student_progress.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<AppUser?> getUser(String uid) async {
    final doc =
        await _db.collection(AppConstants.usersCollection).doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }

  Future<bool> _currentUserIsAdmin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final doc =
        await _db.collection(AppConstants.usersCollection).doc(uid).get();
    return doc.data()?['role'] == AppConstants.roleAdmin;
  }

  Stream<List<AppUser>> watchAllStudents() {
    return _usersByRole(AppConstants.roleStudent, activeOnly: true);
  }

  /// All platform users — merges per-role queries so admin sees the same
  /// student base as the teacher view (unfiltered collection reads are
  /// blocked by Firestore rules for non-matching documents).
  Stream<List<AppUser>> watchAllUsers() {
    return _mergeUserRoleStreams([
      AppConstants.roleStudent,
      AppConstants.roleTeacher,
      AppConstants.roleAdmin,
      AppConstants.roleParent,
    ]);
  }

  Stream<List<AppUser>> _usersByRole(
    String role, {
    bool activeOnly = false,
  }) {
    return _db
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: role)
        .snapshots()
        .map((snap) {
      var users = snap.docs.map(AppUser.fromFirestore).toList();
      if (activeOnly) {
        users = users.where((u) => u.active).toList();
      }
      users.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return users;
    });
  }

  Stream<List<AppUser>> _mergeUserRoleStreams(List<String> roles) {
    final streams = roles.map(_usersByRole).toList();
    return Stream.multi((controller) {
      final latest = List<List<AppUser>?>.filled(streams.length, null);
      final subs = <StreamSubscription<List<AppUser>>>[];

      void publish() {
        if (latest.any((list) => list == null)) return;
        final byId = <String, AppUser>{};
        for (final list in latest) {
          for (final user in list!) {
            byId[user.uid] = user;
          }
        }
        final merged = byId.values.toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
        controller.add(merged);
      }

      for (var i = 0; i < streams.length; i++) {
        final index = i;
        subs.add(
          streams[i].listen(
            (users) {
              latest[index] = users;
              publish();
            },
            onError: controller.addError,
          ),
        );
      }

      controller.onCancel = () async {
        for (final sub in subs) {
          await sub.cancel();
        }
      };
    });
  }

  Stream<List<AppUser>> watchAllTeachers() {
    return _usersByRole(AppConstants.roleTeacher);
  }

  Future<void> setUserActive({
    required String userId,
    required bool active,
  }) async {
    await _db.collection(AppConstants.usersCollection).doc(userId).update({
      'active': active,
    });
  }

  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? nameIndonesian,
    String? nameChinese,
    String? whatsapp,
    String? photoUrl,
    String? parentName,
    String? parentPhone,
    String? level,
    int? termSize,
    String? phone,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name.trim();
    if (nameIndonesian != null) {
      final trimmed = nameIndonesian.trim();
      updates['nameIndonesian'] =
          trimmed.isEmpty ? FieldValue.delete() : trimmed;
      if (trimmed.isNotEmpty && name == null) {
        updates['name'] = trimmed;
      }
    }
    if (nameChinese != null) {
      final trimmed = nameChinese.trim();
      updates['nameChinese'] = trimmed.isEmpty ? FieldValue.delete() : trimmed;
    }
    if (whatsapp != null) {
      final trimmed = whatsapp.trim();
      updates['whatsapp'] = trimmed.isEmpty ? FieldValue.delete() : trimmed;
    }
    if (photoUrl != null) {
      final trimmed = photoUrl.trim();
      updates['photoUrl'] = trimmed.isEmpty ? FieldValue.delete() : trimmed;
    }
    if (parentName != null) {
      final trimmed = parentName.trim();
      updates['parentName'] = trimmed.isEmpty ? FieldValue.delete() : trimmed;
    }
    if (parentPhone != null) {
      final trimmed = parentPhone.trim();
      updates['parentPhone'] = trimmed.isEmpty ? FieldValue.delete() : trimmed;
    }
    if (level != null) {
      updates['level'] = LevelUtils.normalizeHskLevel(level) ?? level;
    }
    if (termSize != null) updates['termSize'] = termSize;
    if (phone != null) {
      final trimmed = phone.trim();
      updates['phone'] = trimmed.isEmpty ? FieldValue.delete() : trimmed;
    }
    if (updates.isEmpty) return;
    await _db
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update(updates);
  }

  Stream<List<StudentProgress>> watchAllStudentProgress() {
    return _db
        .collection(AppConstants.progressCollection)
        .snapshots()
        .map((snap) => snap.docs.map(StudentProgress.fromFirestore).toList());
  }

  Stream<List<Lesson>> watchLessons(String contentOwnerId) {
    final query = contentOwnerId.isEmpty
        ? _db.collection(AppConstants.lessonsCollection).orderBy('order')
        : _db
            .collection(AppConstants.lessonsCollection)
            .where('teacherId', isEqualTo: contentOwnerId)
            .orderBy('order');
    return query.snapshots().map(
          (snap) => snap.docs.map(Lesson.fromFirestore).toList(),
        );
  }

  /// Live map of ownerId → lessons for centre-wide admin views (per-teacher model).
  Stream<Map<String, List<Lesson>>> watchLessonsByOwnerIds(
    Iterable<String> ownerIds,
  ) {
    final ids = ownerIds.where((id) => id.isNotEmpty).toSet().toList()..sort();
    if (ids.isEmpty) {
      return Stream.value(const {});
    }

    late StreamController<Map<String, List<Lesson>>> controller;
    final cache = <String, List<Lesson>>{};
    final subs = <StreamSubscription<List<Lesson>>>[];

    void emit() {
      if (!controller.isClosed) {
        controller.add(Map<String, List<Lesson>>.from(cache));
      }
    }

    controller = StreamController<Map<String, List<Lesson>>>(
      onListen: () {
        for (final id in ids) {
          cache[id] = const [];
          subs.add(
            watchLessons(id).listen(
              (lessons) {
                cache[id] = lessons;
                emit();
              },
              onError: controller.addError,
            ),
          );
        }
        emit();
      },
      onCancel: () async {
        for (final sub in subs) {
          await sub.cancel();
        }
      },
    );

    return controller.stream;
  }

  Future<Lesson?> getLesson(String lessonId) async {
    final doc = await _db
        .collection(AppConstants.lessonsCollection)
        .doc(lessonId)
        .get();
    if (!doc.exists) return null;
    return Lesson.fromFirestore(doc);
  }

  Stream<List<Exercise>> watchAllExercises() {
    return _db
        .collection(AppConstants.exercisesCollection)
        .snapshots()
        .map((snap) {
      final exercises = snap.docs.map(Exercise.fromFirestore).toList();
      exercises.sort(_compareExercisesByTitle);
      return exercises;
    });
  }

  Stream<List<Exercise>> watchExercises(String contentOwnerId) {
    if (contentOwnerId.isEmpty) {
      return watchAllExercises();
    }
    return _db
        .collection(AppConstants.exercisesCollection)
        .where('teacherId', isEqualTo: contentOwnerId)
        .snapshots()
        .map((snap) {
      final exercises = snap.docs.map(Exercise.fromFirestore).toList();
      exercises.sort(_compareExercisesByTitle);
      return exercises;
    });
  }

  static int _compareExercisesByTitle(Exercise a, Exercise b) {
    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  }

  Future<Exercise?> getExercise(String exerciseId) async {
    final doc = await _db
        .collection(AppConstants.exercisesCollection)
        .doc(exerciseId)
        .get();
    if (!doc.exists) return null;
    return Exercise.fromFirestore(doc);
  }

  Future<String> createExercise({
    required String teacherId,
    required String title,
    required String instructions,
    required List<ExerciseQuestion> questions,
    ExerciseType type = ExerciseType.multipleChoice,
    List<String> matchingOptions = const [],
    String passage = '',
    required String level,
    ExerciseSkillCategory skillCategory = ExerciseSkillCategory.reading,
    bool isPublished = true,
  }) async {
    ExerciseAuthoringPlatform.ensureWeb();
    if (!await _currentUserIsAdmin()) {
      throw ExerciseAuthoringPlatformException(
        ExerciseAuthoringPlatform.adminOnlyMessage,
      );
    }

    final doc = await _db.collection(AppConstants.exercisesCollection).add({
      'title': title.trim(),
      'instructions': instructions.trim(),
      'teacherId': teacherId,
      'type': type.value,
      if (matchingOptions.isNotEmpty) 'matchingOptions': matchingOptions,
      if (passage.trim().isNotEmpty) 'passage': passage.trim(),
      'level': level.trim(),
      'skillCategory': skillCategory.value,
      'isPublished': isPublished,
      'questions': questions.map((q) => q.toMap(type)).toList(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Creates or updates a package: an exercise whose questions are bank
  /// worksheets and single bank questions. Returns the exercise id.
  Future<String> saveExercisePackage({
    String? exerciseId,
    required String teacherId,
    required String title,
    required String instructions,
    required String level,
    required List<String> bankSheets,
    required List<String> bankQuestionIds,
    required bool isPublished,
    ExerciseSkillCategory skillCategory = ExerciseSkillCategory.reading,
  }) async {
    ExerciseAuthoringPlatform.ensureWeb();
    if (!await _currentUserIsAdmin()) {
      throw ExerciseAuthoringPlatformException(
        ExerciseAuthoringPlatform.adminOnlyMessage,
      );
    }
    final data = <String, dynamic>{
      'title': title.trim(),
      'instructions': instructions.trim(),
      'level': level.trim(),
      'skillCategory': skillCategory.value,
      'isPublished': isPublished,
      'bankSheets': bankSheets,
      'bankQuestionIds': bankQuestionIds,
      // A package keeps no questions of its own.
      'questions': const [],
      'type': ExerciseType.multipleChoice.value,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final col = _db.collection(AppConstants.exercisesCollection);
    if (exerciseId == null) {
      final doc = await col.add({
        ...data,
        'teacherId': teacherId,
        'order': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return doc.id;
    }
    await col.doc(exerciseId).update(data);
    return exerciseId;
  }

  /// Changes a worksheet as a whole: every question of the sheet gets the
  /// fields that are passed (printed title, level, skill, type, or the word
  /// bank shared by matching / fill-in-the-blank questions).
  Future<void> updateQuestionBankSheet(
    Iterable<String> questionIds, {
    String? title,
    String? level,
    ExerciseSkillCategory? skillCategory,
    ExerciseType? type,
    List<String>? wordBank,
  }) async {
    final data = <String, dynamic>{
      if (title != null) 'sheetTitle': title.trim(),
      if (level != null) 'level': level,
      if (skillCategory != null) 'skillCategory': skillCategory.value,
      if (type != null) 'type': type.value,
      if (wordBank != null) 'question.options': wordBank,
    };
    if (data.isEmpty) return;
    data['updatedAt'] = FieldValue.serverTimestamp();
    final ids = questionIds.toList();
    const chunkSize = 400;
    for (var i = 0; i < ids.length; i += chunkSize) {
      final batch = _db.batch();
      for (final id in ids.skip(i).take(chunkSize)) {
        batch.update(
          _db.collection(AppConstants.questionBankCollection).doc(id),
          data,
        );
      }
      await batch.commit();
    }
  }

  /// New order of a worksheet's questions: `sheetIndex` = position in [ids].
  Future<void> reorderQuestionBankSheet(List<String> ids) async {
    final batch = _db.batch();
    for (final (i, id) in ids.indexed) {
      batch.update(
        _db.collection(AppConstants.questionBankCollection).doc(id),
        {'sheetIndex': i, 'updatedAt': FieldValue.serverTimestamp()},
      );
    }
    await batch.commit();
  }

  Future<void> updateExercise({
    required String exerciseId,
    required String title,
    required String instructions,
    required List<ExerciseQuestion> questions,
    ExerciseType type = ExerciseType.multipleChoice,
    List<String> matchingOptions = const [],
    String passage = '',
    required String level,
    ExerciseSkillCategory skillCategory = ExerciseSkillCategory.reading,
    required bool isPublished,
  }) async {
    ExerciseAuthoringPlatform.ensureWeb();
    if (!await _currentUserIsAdmin()) {
      throw ExerciseAuthoringPlatformException(
        ExerciseAuthoringPlatform.adminOnlyMessage,
      );
    }

    final data = <String, dynamic>{
      'title': title.trim(),
      'instructions': instructions.trim(),
      'type': type.value,
      'isPublished': isPublished,
      'questions': questions.map((q) => q.toMap(type)).toList(),
      if (matchingOptions.isNotEmpty) 'matchingOptions': matchingOptions,
      'passage': passage.trim(),
      'level': level.trim(),
      'skillCategory': skillCategory.value,
      'termNumber': FieldValue.delete(),
    };
    await _db
        .collection(AppConstants.exercisesCollection)
        .doc(exerciseId)
        .update(data);
  }

  Future<void> deleteExercise(String exerciseId) async {
    ExerciseAuthoringPlatform.ensureWeb();
    if (!await _currentUserIsAdmin()) {
      throw ExerciseAuthoringPlatformException(
        ExerciseAuthoringPlatform.adminOnlyMessage,
      );
    }

    final assignments = await _db
        .collection(AppConstants.exerciseAssignmentsCollection)
        .where('exerciseId', isEqualTo: exerciseId)
        .get();
    final batch = _db.batch();
    for (final doc in assignments.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(
      _db.collection(AppConstants.exercisesCollection).doc(exerciseId),
    );
    await batch.commit();
  }

  Stream<List<ExerciseAssignment>> watchAssignmentsForExercise(
    String exerciseId,
  ) {
    return _db
        .collection(AppConstants.exerciseAssignmentsCollection)
        .where('exerciseId', isEqualTo: exerciseId)
        .snapshots()
        .map(
          (snap) => snap.docs.map(ExerciseAssignment.fromFirestore).toList(),
        );
  }

  Stream<List<ExerciseAssignment>> watchAssignmentsForStudent(
    String studentId,
  ) {
    return _db
        .collection(AppConstants.exerciseAssignmentsCollection)
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map(
          (snap) => snap.docs.map(ExerciseAssignment.fromFirestore).toList(),
        );
  }

  /// The exercises a student may open: only the published ones assigned to
  /// them (directly or through a level), sorted by title. Since 2026-11-09
  /// nothing is open to a whole HSK level any more.
  Stream<List<Exercise>> watchAvailableExercisesForStudent(AppUser student) {
    return watchAssignedExercisesForStudent(student.uid).map((assigned) {
      final available = assigned.map((a) => a.exercise).toList();
      available.sort(_compareExercisesByTitle);
      return available;
    });
  }

  Future<bool> canStudentAccessExercise({
    required String exerciseId,
    required AppUser student,
  }) async {
    final exercise = await getExercise(exerciseId);
    if (exercise == null || !exercise.isPublished) return false;
    // Query the student's own assignments (allowed by the rules) instead of
    // reading one assignment doc: a missing doc would be a denied read.
    final mine = await watchAssignmentsForStudent(student.uid).first;
    return mine.any((a) => a.exerciseId == exerciseId);
  }

  Stream<List<StudentAssignedExercise>> watchAssignedExercisesForStudent(
    String studentId,
  ) {
    return watchAssignmentsForStudent(studentId).asyncMap(
      (assignments) async {
        final assigned = <StudentAssignedExercise>[];
        for (final assignment in assignments) {
          final exercise = await getExercise(assignment.exerciseId);
          if (exercise != null && exercise.isPublished) {
            assigned.add(
              StudentAssignedExercise(
                exercise: exercise,
                assignment: assignment,
              ),
            );
          }
        }
        return assigned;
      },
    );
  }

  Stream<List<ExerciseAssignment>> watchAllExerciseAssignments() {
    return _db
        .collection(AppConstants.exerciseAssignmentsCollection)
        .snapshots()
        .map(
          (snap) => snap.docs.map(ExerciseAssignment.fromFirestore).toList(),
        );
  }

  Stream<List<ExerciseResult>> watchAllExerciseResults() {
    return _db
        .collection(AppConstants.exerciseResultsCollection)
        .snapshots()
        .map(
          (snap) => snap.docs.map(ExerciseResult.fromFirestore).toList(),
        );
  }

  Stream<List<StudentClassTerm>> watchAllClassTerms() {
    return _db
        .collection(AppConstants.studentClassTermsCollection)
        .snapshots()
        .map((snap) {
      final terms = snap.docs.map(StudentClassTerm.fromFirestore).toList();
      terms.sort((a, b) {
        final aTime = a.createdAt ?? a.purchasedAt ?? DateTime(1970);
        final bTime = b.createdAt ?? b.purchasedAt ?? DateTime(1970);
        return bTime.compareTo(aTime);
      });
      return terms;
    });
  }

  Future<bool> isExerciseAssignedToStudent({
    required String exerciseId,
    required String studentId,
  }) async {
    final doc = await _db
        .collection(AppConstants.exerciseAssignmentsCollection)
        .doc(ExerciseAssignment.docId(exerciseId, studentId))
        .get();
    return doc.exists;
  }

  /// Assigns one exercise to several students in one batch; existing
  /// assignments are kept (and keep their level tag).
  Future<void> assignExerciseToStudents({
    required String exerciseId,
    required Iterable<String> studentIds,
    required String teacherId,
    DateTime? dueDate,
  }) async {
    final batch = _db.batch();
    for (final studentId in studentIds.toSet()) {
      batch.set(
        _db
            .collection(AppConstants.exerciseAssignmentsCollection)
            .doc(ExerciseAssignment.docId(exerciseId, studentId)),
        {
          'exerciseId': exerciseId,
          'studentId': studentId,
          'teacherId': teacherId,
          'assignedAt': FieldValue.serverTimestamp(),
          'dueDate': dueDate == null
              ? FieldValue.delete()
              : Timestamp.fromDate(
                  DateTime(
                      dueDate.year, dueDate.month, dueDate.day, 23, 59, 59),
                ),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Future<void> assignExerciseToStudent({
    required String exerciseId,
    required String studentId,
    required String teacherId,
    DateTime? dueDate,
  }) async {
    final exercise = await getExercise(exerciseId);
    if (exercise == null) throw StateError('Exercise not found.');
    if (!exercise.isPublished) {
      throw StateError('Publish the exercise before assigning it.');
    }

    final data = <String, dynamic>{
      'exerciseId': exerciseId,
      'studentId': studentId,
      'teacherId': teacherId,
      'assignedAt': FieldValue.serverTimestamp(),
    };
    if (dueDate != null) {
      data['dueDate'] = Timestamp.fromDate(
        DateTime(dueDate.year, dueDate.month, dueDate.day, 23, 59, 59),
      );
    } else {
      data['dueDate'] = FieldValue.delete();
    }

    await _db
        .collection(AppConstants.exerciseAssignmentsCollection)
        .doc(ExerciseAssignment.docId(exerciseId, studentId))
        .set(data, SetOptions(merge: true));
  }

  // ---------------------------------------------------------------- Levels

  Stream<List<ExerciseLevel>> watchExerciseLevels() => _db
      .collection(AppConstants.exerciseLevelsCollection)
      .orderBy('name')
      .snapshots()
      .map((snap) => snap.docs.map(ExerciseLevel.fromFirestore).toList());

  Future<ExerciseLevel?> getExerciseLevel(String id) async {
    final doc = await _db
        .collection(AppConstants.exerciseLevelsCollection)
        .doc(id)
        .get();
    return doc.exists ? ExerciseLevel.fromFirestore(doc) : null;
  }

  /// Creates or updates a level, then makes the assignments match it: one
  /// `exercise_assignments` doc per (exercise, student) tagged `levelId`.
  /// Returns the level id.
  Future<String> saveExerciseLevel(
    ExerciseLevel level, {
    required String teacherId,
  }) async {
    final col = _db.collection(AppConstants.exerciseLevelsCollection);
    final ref = level.id.isEmpty ? col.doc() : col.doc(level.id);
    await ref.set({
      ...level.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (level.id.isEmpty) 'createdAt': FieldValue.serverTimestamp(),
      if (level.id.isEmpty) 'createdBy': teacherId,
    }, SetOptions(merge: true));
    await _syncLevelAssignments(
      levelId: ref.id,
      exerciseIds: level.exerciseIds,
      studentIds: level.studentIds,
      teacherId: teacherId,
    );
    return ref.id;
  }

  /// Deletes the level and every assignment it created.
  Future<void> deleteExerciseLevel(String levelId) async {
    await _syncLevelAssignments(
      levelId: levelId,
      exerciseIds: const [],
      studentIds: const [],
      teacherId: '',
    );
    await _db
        .collection(AppConstants.exerciseLevelsCollection)
        .doc(levelId)
        .delete();
  }

  Future<void> _syncLevelAssignments({
    required String levelId,
    required List<String> exerciseIds,
    required List<String> studentIds,
    required String teacherId,
  }) async {
    final assignments =
        _db.collection(AppConstants.exerciseAssignmentsCollection);
    final existing =
        await assignments.where('levelId', isEqualTo: levelId).get();
    final existingIds = {for (final d in existing.docs) d.id};
    final desired = <String, Map<String, dynamic>>{
      for (final e in exerciseIds)
        for (final st in studentIds)
          ExerciseAssignment.docId(e, st): {
            'exerciseId': e,
            'studentId': st,
            'teacherId': teacherId,
            'levelId': levelId,
          },
    };

    final ops = <void Function(WriteBatch)>[];
    for (final entry in desired.entries) {
      if (existingIds.contains(entry.key)) continue;
      ops.add((b) => b.set(
            assignments.doc(entry.key),
            {...entry.value, 'assignedAt': FieldValue.serverTimestamp()},
            SetOptions(merge: true),
          ));
    }
    for (final id in existingIds) {
      if (desired.containsKey(id)) continue;
      ops.add((b) => b.delete(assignments.doc(id)));
    }
    // Firestore batches cap at 500 writes.
    for (var i = 0; i < ops.length; i += 400) {
      final batch = _db.batch();
      for (final op in ops.sublist(i, math.min(i + 400, ops.length))) {
        op(batch);
      }
      await batch.commit();
    }
  }

  Future<void> unassignExerciseFromStudent({
    required String exerciseId,
    required String studentId,
  }) async {
    await _db
        .collection(AppConstants.exerciseAssignmentsCollection)
        .doc(ExerciseAssignment.docId(exerciseId, studentId))
        .delete();
  }

  Future<void> saveExerciseResult({
    required String studentId,
    required String exerciseId,
    required int score,
  }) async {
    await _db.collection(AppConstants.exerciseResultsCollection).add({
      'studentId': studentId,
      'exerciseId': exerciseId,
      'score': score,
      'submittedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Quiz attempts for one student (transcript). Sorted client-side so no
  /// composite index is needed.
  Stream<List<QuizResult>> watchStudentQuizResults(String studentId) {
    if (studentId.isEmpty) return Stream.value(const []);
    return _db
        .collection(AppConstants.quizResultsCollection)
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snap) {
      final results = snap.docs.map(QuizResult.fromFirestore).toList();
      results.sort((a, b) {
        final aAt = a.submittedAt ?? DateTime(1970);
        final bAt = b.submittedAt ?? DateTime(1970);
        return bAt.compareTo(aAt);
      });
      return results;
    });
  }

  Stream<List<ExerciseResult>> watchStudentExerciseResults(String studentId) {
    return _db
        .collection(AppConstants.exerciseResultsCollection)
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map(
          (snap) => snap.docs.map(ExerciseResult.fromFirestore).toList(),
        );
  }

  Stream<List<StudentProgress>> watchStudentProgress(String studentId) {
    return _db
        .collection(AppConstants.progressCollection)
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snap) => snap.docs.map(StudentProgress.fromFirestore).toList());
  }

  Future<void> markLessonComplete({
    required String studentId,
    required String lessonId,
    int? score,
  }) async {
    final existing = await _db
        .collection(AppConstants.progressCollection)
        .where('studentId', isEqualTo: studentId)
        .where('lessonId', isEqualTo: lessonId)
        .limit(1)
        .get();

    final data = StudentProgress(
      id: existing.docs.isNotEmpty ? existing.docs.first.id : '',
      studentId: studentId,
      lessonId: lessonId,
      completed: true,
      score: score,
      completedAt: DateTime.now(),
    ).toMap();

    if (existing.docs.isNotEmpty) {
      await existing.docs.first.reference.update(data);
    } else {
      await _db.collection(AppConstants.progressCollection).add(data);
    }
  }

  Future<Quiz?> getQuizForLesson(String lessonId) async {
    final snap = await _db
        .collection(AppConstants.quizzesCollection)
        .where('lessonId', isEqualTo: lessonId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return Quiz.fromFirestore(snap.docs.first);
  }

  Future<void> saveQuizResult({
    required String studentId,
    required String quizId,
    required String lessonId,
    required int score,
  }) async {
    await _db.collection(AppConstants.quizResultsCollection).add({
      'studentId': studentId,
      'quizId': quizId,
      'lessonId': lessonId,
      'score': score,
      'submittedAt': FieldValue.serverTimestamp(),
    });
    await markLessonComplete(
      studentId: studentId,
      lessonId: lessonId,
      score: score,
    );
  }

  static String sessionDateKey([DateTime? date]) =>
      DateFormat('yyyy-MM-dd').format(date ?? DateTime.now());

  Stream<List<ClassSession>> watchAllClassSessions() {
    return _db
        .collection(AppConstants.classSessionsCollection)
        .snapshots()
        .map((snap) {
      final sessions = snap.docs.map(ClassSession.fromFirestore).toList();
      sessions.sort((a, b) {
        final byDate = b.sessionDate.compareTo(a.sessionDate);
        if (byDate != 0) return byDate;
        return a.startMinutes.compareTo(b.startMinutes);
      });
      return sessions;
    });
  }

  /// Sessions for one teacher — uses the composite index on
  /// (teacherId, sessionDate DESC, startMinutes ASC).
  Stream<List<ClassSession>> watchTeacherSessions(String teacherId) {
    if (teacherId.isEmpty) {
      return Stream.value(const []);
    }
    return _db
        .collection(AppConstants.classSessionsCollection)
        .where('teacherId', isEqualTo: teacherId)
        .orderBy('sessionDate', descending: true)
        .orderBy('startMinutes')
        .snapshots()
        .map((snap) => snap.docs.map(ClassSession.fromFirestore).toList());
  }

  /// Sessions across several teachers (parent calendar spanning children).
  Stream<List<ClassSession>> watchSessionsByTeacherIds(
    Iterable<String> teacherIds,
  ) {
    final ids = teacherIds.where((id) => id.isNotEmpty).toSet().toList()
      ..sort();
    if (ids.isEmpty) return Stream.value(const []);
    if (ids.length == 1) return watchTeacherSessions(ids.first);

    late StreamController<List<ClassSession>> controller;
    final cache = <String, List<ClassSession>>{
      for (final id in ids) id: const []
    };
    final subs = <StreamSubscription<List<ClassSession>>>[];

    void emit() {
      if (controller.isClosed) return;
      final merged = <String, ClassSession>{};
      for (final list in cache.values) {
        for (final s in list) {
          merged[s.id] = s;
        }
      }
      final sessions = merged.values.toList()
        ..sort((a, b) {
          final byDate = b.sessionDate.compareTo(a.sessionDate);
          if (byDate != 0) return byDate;
          return a.startMinutes.compareTo(b.startMinutes);
        });
      controller.add(sessions);
    }

    controller = StreamController<List<ClassSession>>(
      onListen: () {
        for (final id in ids) {
          subs.add(
            watchTeacherSessions(id).listen(
              (sessions) {
                cache[id] = sessions;
                emit();
              },
              onError: controller.addError,
            ),
          );
        }
      },
      onCancel: () async {
        for (final sub in subs) {
          await sub.cancel();
        }
      },
    );

    return controller.stream;
  }

  Stream<List<ClassSession>> watchOpenSessions({String? teacherId}) {
    final stream = (teacherId == null || teacherId.isEmpty)
        ? watchAllClassSessions()
        : watchTeacherSessions(teacherId);
    return stream.map(
      (sessions) => sessions.where((s) => s.isOpen && !s.isConcluded).toList(),
    );
  }

  Future<ClassSession?> getClassSession(String sessionId) async {
    final doc = await _db
        .collection(AppConstants.classSessionsCollection)
        .doc(sessionId)
        .get();
    if (!doc.exists) return null;
    return ClassSession.fromFirestore(doc);
  }

  Future<String> createClassSession({
    required String teacherId,
    required DateTime date,
    required String sessionTitle,
    required int startMinutes,
    required int endMinutes,
    required int capacity,
    bool isOpen = true,
    SessionMode? mode,
    String? room,
    RegistrationState? registrationState,
  }) async {
    final title = sessionTitle.trim().isEmpty
        ? formatTimeRangeMinutes(startMinutes, endMinutes)
        : sessionTitle.trim();

    final doc = await _db.collection(AppConstants.classSessionsCollection).add({
      'teacherId': teacherId,
      'sessionDate': sessionDateKey(date),
      'sessionTitle': title,
      'startMinutes': startMinutes,
      'endMinutes': endMinutes,
      'capacity': capacity,
      'isOpen': isOpen,
      'isConcluded': false,
      if (mode != null) 'mode': mode.value,
      if (room != null && room.trim().isNotEmpty) 'room': room.trim(),
      if (registrationState != null)
        'registrationState': registrationState.value,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateClassSession({
    required String sessionId,
    required DateTime date,
    required String sessionTitle,
    required int startMinutes,
    required int endMinutes,
    required int capacity,
    required bool isOpen,
    SessionMode? mode,
    String? room,
    RegistrationState? registrationState,
  }) async {
    final title = sessionTitle.trim().isEmpty
        ? formatTimeRangeMinutes(startMinutes, endMinutes)
        : sessionTitle.trim();

    await _db
        .collection(AppConstants.classSessionsCollection)
        .doc(sessionId)
        .update({
      'sessionDate': sessionDateKey(date),
      'sessionTitle': title,
      'startMinutes': startMinutes,
      'endMinutes': endMinutes,
      'capacity': capacity,
      'isOpen': isOpen,
      'mode': mode?.value ?? FieldValue.delete(),
      'room': (room != null && room.trim().isNotEmpty)
          ? room.trim()
          : FieldValue.delete(),
      'registrationState': registrationState?.value ?? FieldValue.delete(),
    });
  }

  Future<void> deleteClassSession(String sessionId) async {
    final batch = _db.batch();
    final attendance = await _db
        .collection(AppConstants.attendanceCollection)
        .where('sessionId', isEqualTo: sessionId)
        .get();
    for (final doc in attendance.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(
      _db.collection(AppConstants.classSessionsCollection).doc(sessionId),
    );
    await batch.commit();
  }

  Stream<List<AttendanceRecord>> watchSessionAttendance(String sessionId) {
    return _db
        .collection(AppConstants.attendanceCollection)
        .where('sessionId', isEqualTo: sessionId)
        .snapshots()
        .map((snap) => snap.docs.map(AttendanceRecord.fromFirestore).toList());
  }

  Stream<List<AttendanceRecord>> watchAllAttendance() {
    return _db.collection(AppConstants.attendanceCollection).snapshots().map(
      (snap) {
        final records = snap.docs.map(AttendanceRecord.fromFirestore).toList();
        records.sort((a, b) {
          final aAt = a.joinedAt;
          final bAt = b.joinedAt;
          if (aAt != null && bAt != null) return bAt.compareTo(aAt);
          if (aAt != null) return -1;
          if (bAt != null) return 1;
          return b.sessionDate.compareTo(a.sessionDate);
        });
        return records;
      },
    );
  }

  Future<int> getSessionJoinedCount(String sessionId) async {
    final snap = await _db
        .collection(AppConstants.attendanceCollection)
        .where('sessionId', isEqualTo: sessionId)
        .get();
    return snap.docs
        .where((doc) => doc.data()['attended'] as bool? ?? false)
        .length;
  }

  bool isSessionFull(ClassSession session, int joinedCount) {
    return joinedCount >= session.capacity;
  }

  static int minutesOfDay(TimeOfDay time) => time.hour * 60 + time.minute;

  static String formatTimeRangeMinutes(int startMinutes, int endMinutes) {
    String fmt(int minutes) {
      final h = (minutes ~/ 60).toString().padLeft(2, '0');
      final m = (minutes % 60).toString().padLeft(2, '0');
      return '$h:$m';
    }

    return '${fmt(startMinutes)}–${fmt(endMinutes)}';
  }

  Stream<List<AttendanceRecord>> watchStudentAttendance(String studentId) {
    return watchStudentJoinedSessions(studentId);
  }

  /// Joined / attended records for a student (direct query — no full session scan).
  Stream<List<AttendanceRecord>> watchStudentJoinedSessions(String studentId) {
    if (studentId.isEmpty) {
      return Stream.value(const []);
    }

    return _db
        .collection(AppConstants.attendanceCollection)
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snap) {
      final records = snap.docs
          .map(AttendanceRecord.fromFirestore)
          .where((r) => r.attended || r.joinedByStudent)
          .toList();
      records.sort((a, b) => b.sessionDate.compareTo(a.sessionDate));
      return records;
    });
  }

  Stream<List<StudentClassTerm>> watchStudentClassTerms(String studentId) {
    return _db
        .collection(AppConstants.studentClassTermsCollection)
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snap) {
      final terms = snap.docs.map(StudentClassTerm.fromFirestore).toList();
      terms.sort((a, b) {
        final aTime = a.createdAt ?? a.purchasedAt ?? DateTime(1970);
        final bTime = b.createdAt ?? b.purchasedAt ?? DateTime(1970);
        return bTime.compareTo(aTime);
      });
      return terms;
    });
  }

  int totalRemainingClassSessions(List<StudentClassTerm> terms) {
    return terms
        .where((t) => t.isActive && t.isWithinTermDates)
        .fold<int>(0, (total, t) => total + t.sessionsRemaining);
  }

  Stream<List<AttendanceRecord>> watchCreditedClassHistory(String studentId) {
    return _db
        .collection(AppConstants.attendanceCollection)
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snap) {
      final records = snap.docs
          .map(AttendanceRecord.fromFirestore)
          .where((r) => r.sessionCredited)
          .toList();
      records.sort((a, b) {
        final byDate = b.sessionDate.compareTo(a.sessionDate);
        if (byDate != 0) return byDate;
        return b.startMinutes.compareTo(a.startMinutes);
      });
      return records;
    });
  }

  /// Groups concluded visits by the term package they were charged to.
  Map<String, List<AttendanceRecord>> visitsByTermId(
    List<AttendanceRecord> creditedVisits,
  ) {
    final grouped = <String, List<AttendanceRecord>>{};
    for (final record in creditedVisits) {
      final termId = record.classTermId;
      if (termId == null || termId.isEmpty) continue;
      grouped.putIfAbsent(termId, () => []).add(record);
    }
    for (final visits in grouped.values) {
      visits.sort((a, b) {
        final byDate = b.sessionDate.compareTo(a.sessionDate);
        if (byDate != 0) return byDate;
        return b.startMinutes.compareTo(a.startMinutes);
      });
    }
    return grouped;
  }

  Future<String> createClassTermPackage({
    required String studentId,
    required int packageSize,
    required String createdByTeacherId,
    required DateTime startDate,
    required DateTime deadlineDate,
    String? notes,
    String? sourceInvoiceId,
  }) async {
    if (packageSize <= 0) {
      throw ArgumentError('packageSize must be at least 1');
    }
    if (deadlineDate.isBefore(startDate)) {
      throw ArgumentError('Deadline must be on or after the start date.');
    }

    final voucherCode = await _generateVoucherCode();

    final doc =
        await _db.collection(AppConstants.studentClassTermsCollection).add({
      'studentId': studentId,
      'packageSize': packageSize,
      'sessionsRemaining': packageSize,
      'sessionsUsed': 0,
      'status': StudentClassTerm.statusActive,
      'startDate': sessionDateKey(startDate),
      'deadlineDate': sessionDateKey(deadlineDate),
      'createdBy': createdByTeacherId,
      'voucherCode': voucherCode,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      if (sourceInvoiceId != null && sourceInvoiceId.isNotEmpty)
        'sourceInvoiceId': sourceInvoiceId,
      'purchasedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Links an existing term to the invoice that pays for it.
  Future<void> linkClassTermToInvoice({
    required String termId,
    required String invoiceId,
  }) =>
      _db
          .collection(AppConstants.studentClassTermsCollection)
          .doc(termId)
          .update({'sourceInvoiceId': invoiceId});

  /// Pending invoice recorded by staff for a payment made at the centre
  /// (cash or bank transfer). An admin settles it with
  /// `PaymentService.markInvoicePaid`, which credits the sessions
  /// server-side. [classTermId] links it to a term that already exists.
  Future<String> createManualInvoice({
    required AppUser student,
    required PriceItem item,
    required String createdBy,
    required DateTime dueDate,
    String? classTermId,
  }) async {
    final now = DateTime.now();
    final number =
        'ES-INV-${now.millisecondsSinceEpoch}-M${now.microsecond % 1000}';
    final doc = await _db.collection(AppConstants.invoicesCollection).add({
      'invoiceNumber': number,
      'studentId': student.uid,
      'studentName': student.displayNameIndonesian,
      'teacherId': student.teacherId ?? createdBy,
      'item': item.kind == PriceKind.book ? AppConstants.bookItem : 'package',
      'description': item.name,
      'packageSize': item.sessions,
      'priceItemId': item.id,
      'kind': item.kind.value,
      'sessions': item.sessions,
      'amount': item.price,
      'currency': 'IDR',
      'status': InvoiceStatus.pending.value,
      'paymentMethod': 'manual',
      'dueDate': sessionDateKey(dueDate),
      if (classTermId != null && classTermId.isNotEmpty)
        'classTermId': classTermId,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Admin removes a pending invoice recorded by mistake (rules refuse
  /// anything that is not pending).
  Future<void> deleteInvoice(String invoiceId) =>
      _db.collection(AppConstants.invoicesCollection).doc(invoiceId).delete();

  Future<String> _generateVoucherCode() async {
    final now = DateTime.now();
    final prefix = '${now.year}_${now.month.toString().padLeft(2, '0')}_';
    final snap =
        await _db.collection(AppConstants.studentClassTermsCollection).get();

    var maxSeq = 0;
    for (final doc in snap.docs) {
      final code = doc.data()['voucherCode'] as String? ?? '';
      if (!code.startsWith(prefix)) continue;
      final seq = int.tryParse(code.substring(prefix.length)) ?? 0;
      if (seq > maxSeq) maxSeq = seq;
    }

    return '$prefix${(maxSeq + 1).toString().padLeft(3, '0')}';
  }

  Future<StudentClassTerm?> getClassTerm(String termId) async {
    final doc = await _db
        .collection(AppConstants.studentClassTermsCollection)
        .doc(termId)
        .get();
    if (!doc.exists) return null;
    return StudentClassTerm.fromFirestore(doc);
  }

  Future<void> updateClassTerm({
    required String termId,
    required DateTime startDate,
    required DateTime deadlineDate,
    required int sessionsRemaining,
    String? notes,
  }) async {
    if (deadlineDate.isBefore(startDate)) {
      throw ArgumentError('Deadline must be on or after the start date.');
    }

    final ref =
        _db.collection(AppConstants.studentClassTermsCollection).doc(termId);
    final snap = await ref.get();
    if (!snap.exists) throw StateError('Term not found.');

    final packageSize = snap.data()?['packageSize'] as int? ?? 8;
    final remaining = sessionsRemaining.clamp(0, packageSize);
    final used = packageSize - remaining;

    await ref.update({
      'startDate': sessionDateKey(startDate),
      'deadlineDate': sessionDateKey(deadlineDate),
      'sessionsRemaining': remaining,
      'sessionsUsed': used,
      'status': remaining <= 0
          ? StudentClassTerm.statusDepleted
          : StudentClassTerm.statusActive,
      if (notes != null)
        'notes': notes.trim().isEmpty ? FieldValue.delete() : notes.trim(),
    });
  }

  Future<void> deleteClassTerm(String termId) async {
    await _db
        .collection(AppConstants.studentClassTermsCollection)
        .doc(termId)
        .delete();
  }

  /// Concludes a class. [statuses] maps studentId → `hadir` | `izin` | `alpa`
  /// (see [AttendanceRecord]); students not in the map keep their stored
  /// status, defaulting to hadir. Hadir and alpa charge one session; izin
  /// (excused before class) is recorded but not charged.
  Future<ConcludeClassResult> concludeClassSession(
    String sessionId, {
    Map<String, String> statuses = const {},
  }) async {
    final session = await getClassSession(sessionId);
    if (session == null) {
      throw const ClassConcludeException('Class not found.');
    }
    if (session.isConcluded) {
      throw const ClassConcludeException('This class is already concluded.');
    }

    final attendanceSnap = await _db
        .collection(AppConstants.attendanceCollection)
        .where('sessionId', isEqualTo: sessionId)
        .get();

    var creditedCount = 0;
    var excusedCount = 0;
    final failedStudents = <String>[];

    for (final doc in attendanceSnap.docs) {
      final record = AttendanceRecord.fromFirestore(doc);
      if (!record.attended || record.sessionCredited) continue;

      final status = statuses[record.studentId] ??
          record.normalizedStatus ??
          AttendanceRecord.hadir;
      if (status == AttendanceRecord.izin) {
        await doc.reference.update({'attendanceStatus': status});
        excusedCount++;
        continue;
      }

      final name = record.studentName?.isNotEmpty == true
          ? record.studentName!
          : 'Student';

      try {
        final classTermId = await _deductClassSession(record.studentId);
        await doc.reference.update({
          'classTermId': classTermId,
          'sessionCredited': true,
          'attendanceStatus': status,
        });
        creditedCount++;
      } on NoClassCreditsException {
        await doc.reference.update({'attendanceStatus': status});
        failedStudents.add(name);
      }
    }

    await _db
        .collection(AppConstants.classSessionsCollection)
        .doc(sessionId)
        .update({
      'isConcluded': true,
      'isOpen': false,
      'concludedAt': FieldValue.serverTimestamp(),
    });

    return ConcludeClassResult(
      creditedCount: creditedCount,
      failedStudents: failedStudents,
      excusedCount: excusedCount,
    );
  }

  Future<StudentClassTerm?> _getOldestActiveTerm(String studentId) async {
    final snap = await _db
        .collection(AppConstants.studentClassTermsCollection)
        .where('studentId', isEqualTo: studentId)
        .where('status', isEqualTo: StudentClassTerm.statusActive)
        .get();

    final terms = snap.docs.map(StudentClassTerm.fromFirestore).toList()
      ..removeWhere(
        (t) => t.sessionsRemaining <= 0 || !t.isWithinTermDates,
      );

    if (terms.isEmpty) return null;

    terms.sort((a, b) {
      final aTime = a.purchasedAt ?? a.createdAt ?? DateTime(1970);
      final bTime = b.purchasedAt ?? b.createdAt ?? DateTime(1970);
      return aTime.compareTo(bTime);
    });
    return terms.first;
  }

  /// Deducts one session from the student's oldest active term package.
  Future<String> _deductClassSession(String studentId) async {
    final term = await _getOldestActiveTerm(studentId);
    if (term == null || term.sessionsRemaining <= 0) {
      throw const NoClassCreditsException();
    }

    final ref =
        _db.collection(AppConstants.studentClassTermsCollection).doc(term.id);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw const NoClassCreditsException();
      final data = snap.data()!;
      final remaining = data['sessionsRemaining'] as int? ?? 0;
      if (remaining <= 0) throw const NoClassCreditsException();
      final used = data['sessionsUsed'] as int? ?? 0;
      final newRemaining = remaining - 1;
      tx.update(ref, {
        'sessionsRemaining': newRemaining,
        'sessionsUsed': used + 1,
        'status': newRemaining <= 0
            ? StudentClassTerm.statusDepleted
            : StudentClassTerm.statusActive,
      });
    });
    return term.id;
  }

  Future<void> _refundClassSession(String classTermId) async {
    final ref = _db
        .collection(AppConstants.studentClassTermsCollection)
        .doc(classTermId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data()!;
      final remaining = data['sessionsRemaining'] as int? ?? 0;
      final used = data['sessionsUsed'] as int? ?? 0;
      final packageSize = data['packageSize'] as int? ?? remaining + used;
      tx.update(ref, {
        'sessionsRemaining': (remaining + 1).clamp(0, packageSize),
        'sessionsUsed': (used - 1).clamp(0, packageSize),
        'status': StudentClassTerm.statusActive,
      });
    });
  }

  Future<void> _assertCanJoinClass(String studentId) async {
    final snap = await _db
        .collection(AppConstants.studentClassTermsCollection)
        .where('studentId', isEqualTo: studentId)
        .where('status', isEqualTo: StudentClassTerm.statusActive)
        .get();

    final terms = snap.docs.map(StudentClassTerm.fromFirestore).toList();
    final usable = terms
        .where((t) => t.sessionsRemaining > 0 && t.isWithinTermDates)
        .toList();

    if (usable.isEmpty) {
      final hasCreditsOutsideDates = terms.any((t) => t.sessionsRemaining > 0);
      throw NoClassCreditsException(
        reason: hasCreditsOutsideDates
            ? 'Your term is outside its start/deadline dates. Ask your teacher to update the dates.'
            : null,
      );
    }
  }

  Future<void> _enrollInSession({
    required ClassSession session,
    required String studentId,
    required String studentName,
    required String joinedBy,
  }) async {
    if (session.isConcluded) {
      throw const ClassConcludeException('This class has already concluded.');
    }

    final docId = '${session.id}_$studentId';
    final docRef = _db.collection(AppConstants.attendanceCollection).doc(docId);
    final existing = await docRef.get();
    if (existing.exists) {
      final data = existing.data();
      if (data?['attended'] as bool? ?? false) return;
    }

    await _assertCanJoinClass(studentId);

    final joinedCount = await getSessionJoinedCount(session.id);
    if (joinedCount >= session.capacity) {
      throw SessionFullException(capacity: session.capacity);
    }

    final record = AttendanceRecord(
      id: docId,
      sessionId: session.id,
      studentId: studentId,
      teacherId: session.teacherId,
      sessionDate: session.sessionDate,
      sessionTitle: session.sessionTitle,
      startMinutes: session.startMinutes,
      endMinutes: session.endMinutes,
      attended: true,
      joinedBy: joinedBy,
      studentName: studentName.trim(),
      sessionCredited: false,
    );

    await docRef.set(record.toMap());
  }

  Future<void> removeStudentFromSession({
    required String sessionId,
    required String studentId,
  }) async {
    await leaveSession(sessionId: sessionId, studentId: studentId);
  }

  Future<void> addStudentToSession({
    required ClassSession session,
    required String studentId,
    required String studentName,
  }) async {
    await _enrollInSession(
      session: session,
      studentId: studentId,
      studentName: studentName,
      joinedBy: 'teacher',
    );
  }

  Future<void> leaveSession({
    required String sessionId,
    required String studentId,
  }) async {
    final session = await getClassSession(sessionId);
    if (session?.isConcluded == true) {
      throw const ClassConcludeException(
        'This class is concluded — you cannot leave it.',
      );
    }

    final docId = '${sessionId}_$studentId';
    final docRef = _db.collection(AppConstants.attendanceCollection).doc(docId);
    final existing = await docRef.get();
    if (existing.exists) {
      final record = AttendanceRecord.fromFirestore(existing);
      if (record.sessionCredited &&
          record.classTermId != null &&
          record.classTermId!.isNotEmpty) {
        await _refundClassSession(record.classTermId!);
      }
    }
    await docRef.delete();
  }

  Future<void> joinSession({
    required ClassSession session,
    required String studentId,
    required String studentName,
  }) async {
    if (session.isConcluded) {
      throw const ClassConcludeException('This class has already concluded.');
    }
    if (!session.isOpen) {
      throw StateError('This session is closed.');
    }

    final docRef = _db
        .collection(AppConstants.attendanceCollection)
        .doc('${session.id}_$studentId');
    final existing = await docRef.get();
    if (existing.exists) return;

    await _enrollInSession(
      session: session,
      studentId: studentId,
      studentName: studentName,
      joinedBy: 'student',
    );
  }

  /// Notifications addressed to this user plus broadcasts for their role.
  ///
  /// Firestore rules cannot filter a broad query, so this asks only for what
  /// the rules allow: `userId == uid`, and `userId == '' && forRole in (...)`.
  /// Broadcasts are stored with `userId: ''` (see AppNotification.toMap and
  /// functions/index.js); older broadcasts without the field are not shown.
  Stream<List<AppNotification>> watchNotificationsForUser(AppUser user) {
    final col = _db.collection(AppConstants.notificationsCollection);
    final audiences = <String>[
      if (user.isAdmin) AppConstants.roleAdmin,
      if (user.isTeacher) AppConstants.roleTeacher,
      if (user.isStudent) AppConstants.roleStudent,
      'all',
    ];
    final mine = col.where('userId', isEqualTo: user.uid).snapshots();
    final broadcast = col
        .where('userId', isEqualTo: '')
        .where('forRole', whereIn: audiences)
        .snapshots();

    final controller = StreamController<List<AppNotification>>();
    var ownItems = const <AppNotification>[];
    var broadcastItems = const <AppNotification>[];
    var gotOwn = false;
    var gotBroadcast = false;
    StreamSubscription? ownSub;
    StreamSubscription? broadcastSub;

    void emit() {
      if (!gotOwn || !gotBroadcast) return;
      final items = [...ownItems, ...broadcastItems];
      items.sort((a, b) {
        final aAt = a.createdAt;
        final bAt = b.createdAt;
        if (aAt == null && bAt == null) return 0;
        if (aAt == null) return 1;
        if (bAt == null) return -1;
        return bAt.compareTo(aAt);
      });
      controller.add(items);
    }

    controller.onListen = () {
      ownSub = mine.listen((snap) {
        ownItems = snap.docs.map(AppNotification.fromFirestore).toList();
        gotOwn = true;
        emit();
      }, onError: controller.addError);
      broadcastSub = broadcast.listen((snap) {
        broadcastItems = snap.docs.map(AppNotification.fromFirestore).toList();
        gotBroadcast = true;
        emit();
      }, onError: controller.addError);
    };
    controller.onCancel = () async {
      await ownSub?.cancel();
      await broadcastSub?.cancel();
    };
    return controller.stream;
  }

  Future<void> createNotification(AppNotification notification) async {
    await _db.collection(AppConstants.notificationsCollection).add(
          notification.toMap(),
        );
  }

  Future<void> markNotificationRead(String notificationId) async {
    await _db
        .collection(AppConstants.notificationsCollection)
        .doc(notificationId)
        .update({'read': true});
  }

  Future<void> setAttendanceStatus({
    required String sessionId,
    required String studentId,
    required String status,
  }) async {
    await _db
        .collection(AppConstants.attendanceCollection)
        .doc('${sessionId}_$studentId')
        .update({'attendanceStatus': status});
  }

  // ---------------------------------------------------------------------------
  // Invoices (Phase 1 — payments)
  // ---------------------------------------------------------------------------

  Stream<List<Invoice>> _mapInvoices(Query<Map<String, dynamic>> query) {
    return query.snapshots().map((snap) {
      final invoices = snap.docs.map(Invoice.fromFirestore).toList();
      invoices.sort((a, b) {
        final aAt = a.createdAt ?? DateTime(1970);
        final bAt = b.createdAt ?? DateTime(1970);
        return bAt.compareTo(aAt);
      });
      return invoices;
    });
  }

  /// All invoices — admin view. Filtered client-side sort (rules gate access).
  Stream<List<Invoice>> watchAllInvoices() {
    return _mapInvoices(_db.collection(AppConstants.invoicesCollection));
  }

  /// Invoices for one student (student self-view or parent/staff scoped view).
  Stream<List<Invoice>> watchStudentInvoices(String studentId) {
    if (studentId.isEmpty) return Stream.value(const []);
    return _mapInvoices(
      _db
          .collection(AppConstants.invoicesCollection)
          .where('studentId', isEqualTo: studentId),
    );
  }

  /// Invoices owned by a teacher (their students).
  Stream<List<Invoice>> watchTeacherInvoices(String teacherId) {
    if (teacherId.isEmpty) return Stream.value(const []);
    return _mapInvoices(
      _db
          .collection(AppConstants.invoicesCollection)
          .where('teacherId', isEqualTo: teacherId),
    );
  }

  // ---------------------------------------------------------------------------
  // Parent access (Phase 2)
  // ---------------------------------------------------------------------------

  Stream<List<AppUser>> watchAllParents() {
    return _usersByRole(AppConstants.roleParent);
  }

  /// Live list of the specific students linked to a parent. Firestore has no
  /// `documentId in [...]` stream helper, so we merge per-doc snapshots.
  Stream<List<AppUser>> watchUsersByIds(Iterable<String> ids) {
    final list = ids.where((id) => id.isNotEmpty).toSet().toList()..sort();
    if (list.isEmpty) return Stream.value(const []);

    late StreamController<List<AppUser>> controller;
    final cache = <String, AppUser?>{for (final id in list) id: null};
    final subs = <StreamSubscription>[];

    void emit() {
      if (controller.isClosed) return;
      final users = cache.values.whereType<AppUser>().toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      controller.add(users);
    }

    controller = StreamController<List<AppUser>>(
      onListen: () {
        for (final id in list) {
          subs.add(
            _db
                .collection(AppConstants.usersCollection)
                .doc(id)
                .snapshots()
                .listen(
              (doc) {
                cache[id] = doc.exists ? AppUser.fromFirestore(doc) : null;
                emit();
              },
              onError: controller.addError,
            ),
          );
        }
      },
      onCancel: () async {
        for (final sub in subs) {
          await sub.cancel();
        }
      },
    );

    return controller.stream;
  }

  /// Sets the children a parent account can see, plus the derived set of
  /// teacher ids (so parents can read their children's class sessions). Admin
  /// -only in practice (rules gate the write).
  Future<void> setParentChildren({
    required String parentId,
    required List<String> studentIds,
    List<String>? teacherIds,
  }) async {
    final resolvedTeacherIds =
        teacherIds ?? await _teacherIdsForStudents(studentIds);
    await _db.collection(AppConstants.usersCollection).doc(parentId).update({
      'studentIds': studentIds,
      'teacherIds': resolvedTeacherIds,
    });
  }

  Future<List<String>> _teacherIdsForStudents(List<String> studentIds) async {
    final teacherIds = <String>{};
    for (final id in studentIds) {
      if (id.isEmpty) continue;
      final doc =
          await _db.collection(AppConstants.usersCollection).doc(id).get();
      final tid = doc.data()?['teacherId'] as String?;
      if (tid != null && tid.isNotEmpty) teacherIds.add(tid);
    }
    return teacherIds.toList();
  }

  /// Ensures the student has a stable [parentCode] that a parent can enter to
  /// link to this child, returning it. Safe to call repeatedly.
  Future<String> ensureParentCode(String studentId) async {
    final ref = _db.collection(AppConstants.usersCollection).doc(studentId);
    final snap = await ref.get();
    final existing = snap.data()?['parentCode'] as String?;
    if (existing != null && existing.isNotEmpty) return existing;

    final code = _generateParentCode();
    await ref.update({'parentCode': code});
    return code;
  }

  String _generateParentCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(6, (_) => alphabet[rand.nextInt(alphabet.length)])
        .join();
  }

  // ---------------------------------------------------------------------------
  // Gradebook (Tier 2 · Phase 1)
  // ---------------------------------------------------------------------------

  /// All grades a teacher owns, newest first — uses the composite index on
  /// (teacherId, createdAt DESC). Powers the teacher gradebook and the
  /// "grades pending" dashboard count (filter client-side by status).
  Stream<List<Grade>> watchTeacherGrades(String teacherId) {
    if (teacherId.isEmpty) return Stream.value(const []);
    return _db
        .collection(AppConstants.gradesCollection)
        .where('teacherId', isEqualTo: teacherId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Grade.fromFirestore).toList());
  }

  /// A teacher's pending grades (assessments awaiting a score).
  Stream<List<Grade>> watchTeacherPendingGrades(String teacherId) {
    return watchTeacherGrades(teacherId).map(
      (grades) => grades.where((g) => g.isPending).toList(),
    );
  }

  /// Grades for one student — student self-view or parent/staff scoped view.
  /// Uses the composite index on (studentId, createdAt DESC).
  Stream<List<Grade>> watchStudentGrades(String studentId) {
    if (studentId.isEmpty) return Stream.value(const []);
    return _db
        .collection(AppConstants.gradesCollection)
        .where('studentId', isEqualTo: studentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Grade.fromFirestore).toList());
  }

  /// Creates a gradebook entry. A [score] of null records a *pending*
  /// assessment; a non-null score records it as *graded* with a derived
  /// letter grade.
  Future<String> createGrade({
    required String studentId,
    required String teacherId,
    required String title,
    required GradeCategory category,
    num? score,
    String? classSessionId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? teacherId;
    final graded = score != null;
    final data = <String, dynamic>{
      'studentId': studentId,
      'teacherId': teacherId,
      'title': title.trim(),
      'category': category.value,
      'status': graded ? GradeStatus.graded.value : GradeStatus.pending.value,
      'gradedBy': uid,
      'createdAt': FieldValue.serverTimestamp(),
      if (classSessionId != null && classSessionId.isNotEmpty)
        'classSessionId': classSessionId,
      if (graded) ...{
        'score': score,
        'letterGrade': GradeUtils.letterGradeFor(score),
        'gradedAt': FieldValue.serverTimestamp(),
      },
    };
    final doc = await _db.collection(AppConstants.gradesCollection).add(data);
    return doc.id;
  }

  /// Fills (or updates) a grade's score, flipping it to *graded* and deriving
  /// the letter grade.
  Future<void> setGradeScore({
    required String gradeId,
    required num score,
  }) async {
    await _db.collection(AppConstants.gradesCollection).doc(gradeId).update({
      'score': score,
      'letterGrade': GradeUtils.letterGradeFor(score),
      'status': GradeStatus.graded.value,
      'gradedBy': FirebaseAuth.instance.currentUser?.uid,
      'gradedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Updates the editable metadata of a grade (title/category).
  Future<void> updateGradeMeta({
    required String gradeId,
    required String title,
    required GradeCategory category,
  }) async {
    await _db.collection(AppConstants.gradesCollection).doc(gradeId).update({
      'title': title.trim(),
      'category': category.value,
    });
  }

  Future<void> deleteGrade(String gradeId) async {
    await _db.collection(AppConstants.gradesCollection).doc(gradeId).delete();
  }

  // ---------------------------------------------------------------------------
  // Question bank (Tier 2 · Phase 2)
  // ---------------------------------------------------------------------------

  /// Bank questions owned by [ownerId] (a content-owner teacher/admin id),
  /// newest first. Uses the composite index on (ownerId, createdAt DESC).
  Stream<List<QuestionBankItem>> watchQuestionBank(String ownerId) {
    if (ownerId.isEmpty) return Stream.value(const []);
    return _db
        .collection(AppConstants.questionBankCollection)
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(QuestionBankItem.fromFirestore).toList());
  }

  Future<String> createQuestionBankItem(QuestionBankItem item) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final data = item.toMap()
      ..['createdBy'] = uid
      ..['createdAt'] = FieldValue.serverTimestamp();
    final doc =
        await _db.collection(AppConstants.questionBankCollection).add(data);
    return doc.id;
  }

  Future<void> updateQuestionBankItem(QuestionBankItem item) async {
    await _db
        .collection(AppConstants.questionBankCollection)
        .doc(item.id)
        .update({
      ...item.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteQuestionBankItem(String id) async {
    await _db.collection(AppConstants.questionBankCollection).doc(id).delete();
  }

  /// Delete a whole worksheet (or any set of bank questions) in batches.
  Future<void> deleteQuestionBankItems(Iterable<String> ids) async {
    final list = ids.where((id) => id.isNotEmpty).toSet().toList();
    const chunkSize = 400;
    for (var i = 0; i < list.length; i += chunkSize) {
      final batch = _db.batch();
      for (final id in list.skip(i).take(chunkSize)) {
        batch.delete(
            _db.collection(AppConstants.questionBankCollection).doc(id));
      }
      await batch.commit();
    }
  }

  /// Batch-insert bank questions (max 500 per Firestore batch).
  Future<void> addQuestionBankItems(List<QuestionBankItem> items) async {
    if (items.isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    const chunkSize = 400;
    for (var i = 0; i < items.length; i += chunkSize) {
      final batch = _db.batch();
      final slice = items.skip(i).take(chunkSize);
      for (final item in slice) {
        final ref = _db.collection(AppConstants.questionBankCollection).doc();
        batch.set(ref, {
          ...item.toMap(),
          'createdBy': uid,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }

  /// Bump usage stats when questions are pulled into an exercise or quiz.
  Future<void> incrementQuestionBankUsage(Iterable<String> questionIds) async {
    final ids = questionIds.where((id) => id.isNotEmpty).toSet().toList();
    if (ids.isEmpty) return;
    const chunkSize = 400;
    for (var i = 0; i < ids.length; i += chunkSize) {
      final batch = _db.batch();
      for (final id in ids.skip(i).take(chunkSize)) {
        final ref = _db.collection(AppConstants.questionBankCollection).doc(id);
        batch.update(ref, {
          'usageCount': FieldValue.increment(1),
          'lastUsedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }

  // ---------------------------------------------------------------------------
  // Quizzes (authoring)
  // ---------------------------------------------------------------------------

  Stream<List<Quiz>> watchQuizzesForTeacher(String teacherId) {
    if (teacherId.isEmpty) return Stream.value(const []);
    return _db
        .collection(AppConstants.quizzesCollection)
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map((snap) => snap.docs.map(Quiz.fromFirestore).toList());
  }

  Future<String> createQuiz(Quiz quiz) async {
    final doc = await _db.collection(AppConstants.quizzesCollection).add({
      'lessonId': quiz.lessonId,
      'title': quiz.title,
      'teacherId': quiz.teacherId,
      'questions': quiz.questions
          .map(
            (q) => {
              'question': q.question,
              'options': q.options,
              'correctIndex': q.correctIndex,
              if (q.imageUrl != null && q.imageUrl!.isNotEmpty)
                'imageUrl': q.imageUrl,
              if (q.audioUrl != null && q.audioUrl!.isNotEmpty)
                'audioUrl': q.audioUrl,
            },
          )
          .toList(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateQuiz(Quiz quiz) async {
    await _db.collection(AppConstants.quizzesCollection).doc(quiz.id).update({
      'lessonId': quiz.lessonId,
      'title': quiz.title,
      'teacherId': quiz.teacherId,
      'questions': quiz.questions
          .map(
            (q) => {
              'question': q.question,
              'options': q.options,
              'correctIndex': q.correctIndex,
              if (q.imageUrl != null && q.imageUrl!.isNotEmpty)
                'imageUrl': q.imageUrl,
              if (q.audioUrl != null && q.audioUrl!.isNotEmpty)
                'audioUrl': q.audioUrl,
            },
          )
          .toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteQuiz(String quizId) async {
    await _db.collection(AppConstants.quizzesCollection).doc(quizId).delete();
  }

  // ---------------------------------------------------------------------------
  // Org settings (Tier 3 · Phase 1)
  // ---------------------------------------------------------------------------

  DocumentReference<Map<String, dynamic>> get _orgSettingsRef => _db
      .collection(AppConstants.settingsCollection)
      .doc(AppConstants.orgSettingsDoc);

  /// Centre-wide settings. Emits defaults until the doc exists.
  DocumentReference<Map<String, dynamic>> get _pricingRef => _db
      .collection(AppConstants.settingsCollection)
      .doc(AppConstants.pricingSettingsDoc);

  Stream<PricingSettings> watchPricing() => _pricingRef.snapshots().map(
        (doc) => doc.exists
            ? PricingSettings.fromSnapshot(doc)
            : PricingSettings.defaults,
      );

  Future<void> updatePricing(PricingSettings pricing) async {
    await _pricingRef.set({
      ...pricing.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': FirebaseAuth.instance.currentUser?.uid,
    }, SetOptions(merge: true));
  }

  Stream<OrgSettings> watchOrgSettings() {
    return _orgSettingsRef.snapshots().map(
          (doc) =>
              doc.exists ? OrgSettings.fromSnapshot(doc) : OrgSettings.defaults,
        );
  }

  Future<OrgSettings> getOrgSettings() async {
    final doc = await _orgSettingsRef.get();
    return doc.exists ? OrgSettings.fromSnapshot(doc) : OrgSettings.defaults;
  }

  Future<void> updateOrgSettings(OrgSettings settings) async {
    await _orgSettingsRef.set({
      ...settings.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': FirebaseAuth.instance.currentUser?.uid,
    }, SetOptions(merge: true));
  }

  // ---------------------------------------------------------------------------
  // Audit log (Tier 3 · Phase 2) — read-only for admins; writes via Functions.
  // ---------------------------------------------------------------------------

  Stream<List<AuditLog>> watchAuditLogs({int limit = 200}) {
    return _db
        .collection(AppConstants.auditLogsCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(AuditLog.fromFirestore).toList());
  }

  // ---------------------------------------------------------------------------
  // Materials repository (Tier 3 · Phase 3)
  // ---------------------------------------------------------------------------

  /// All materials owned by [ownerId] (staff view). Sorted newest-first.
  Stream<List<MaterialItem>> watchMaterials(String ownerId) {
    if (ownerId.isEmpty) return Stream.value(const []);
    return _db
        .collection(AppConstants.materialsCollection)
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(MaterialItem.fromFirestore).toList());
  }

  /// Published materials for [ownerId] (student/parent view). Uses the
  /// composite index on (ownerId, status, createdAt DESC).
  Stream<List<MaterialItem>> watchPublishedMaterials(String ownerId) {
    if (ownerId.isEmpty) return Stream.value(const []);
    return _db
        .collection(AppConstants.materialsCollection)
        .where('ownerId', isEqualTo: ownerId)
        .where('status', isEqualTo: 'published')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(MaterialItem.fromFirestore).toList());
  }

  Future<String> createMaterial(MaterialItem material) async {
    final doc = await _db.collection(AppConstants.materialsCollection).add({
      ...material.toMap(),
      'createdBy': FirebaseAuth.instance.currentUser?.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateMaterial(MaterialItem material) async {
    await _db
        .collection(AppConstants.materialsCollection)
        .doc(material.id)
        .update(material.toMap());
  }

  Future<void> deleteMaterial(String id) async {
    await _db.collection(AppConstants.materialsCollection).doc(id).delete();
  }

  // ---------------------------------------------------------------------------
  // Semester evaluations (Tier 3 · Phase 4)
  // ---------------------------------------------------------------------------

  /// Evaluations a teacher owns (management view).
  Stream<List<Evaluation>> watchTeacherEvaluations(String teacherId) {
    if (teacherId.isEmpty) return Stream.value(const []);
    return _db
        .collection(AppConstants.evaluationsCollection)
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map((snap) => _sortedEvaluations(snap));
  }

  /// A student's evaluations. For self/parent views pass [publishedOnly] true
  /// (rules also enforce this); staff can see drafts.
  Stream<List<Evaluation>> watchStudentEvaluations(
    String studentId, {
    bool publishedOnly = false,
  }) {
    if (studentId.isEmpty) return Stream.value(const []);
    var query = _db
        .collection(AppConstants.evaluationsCollection)
        .where('studentId', isEqualTo: studentId);
    if (publishedOnly) {
      query = query.where('status', isEqualTo: 'published');
    }
    return query.snapshots().map(_sortedEvaluations);
  }

  List<Evaluation> _sortedEvaluations(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) {
    final list = snap.docs.map(Evaluation.fromFirestore).toList();
    list.sort((a, b) {
      final aAt = a.updatedAt ?? a.createdAt ?? DateTime(1970);
      final bAt = b.updatedAt ?? b.createdAt ?? DateTime(1970);
      return bAt.compareTo(aAt);
    });
    return list;
  }

  Future<String> createEvaluation(Evaluation evaluation) async {
    final doc = await _db.collection(AppConstants.evaluationsCollection).add({
      ...evaluation.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateEvaluation(Evaluation evaluation) async {
    await _db
        .collection(AppConstants.evaluationsCollection)
        .doc(evaluation.id)
        .update({
      ...evaluation.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteEvaluation(String id) async {
    await _db.collection(AppConstants.evaluationsCollection).doc(id).delete();
  }
}
