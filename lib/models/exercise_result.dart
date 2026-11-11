import 'package:cloud_firestore/cloud_firestore.dart';

import 'exercise_category.dart';

/// One submitted attempt at an exercise. Attempts since 2026-11-11 also carry
/// the counts, the time taken, the exercise title and its type of exercise
/// (written by the `finishExercise` function, or by the app for the old
/// exercises that still keep their questions in the document); older results
/// have only the score.
class ExerciseResult {
  const ExerciseResult({
    required this.id,
    required this.studentId,
    required this.exerciseId,
    required this.score,
    this.submittedAt,
    this.correct,
    this.total,
    this.durationSeconds,
    this.exerciseTitle,
    this.category,
  });

  final String id;
  final String studentId;
  final String exerciseId;

  /// 0 to 100.
  final int score;
  final DateTime? submittedAt;
  final int? correct;
  final int? total;

  /// Seconds between opening the questions and submitting.
  final int? durationSeconds;

  /// Title at the time of the attempt, so history survives a rename or
  /// a deleted exercise.
  final String? exerciseTitle;

  /// Type of exercise of the package's first worksheet.
  final ExerciseCategory? category;

  bool get hasCounts => correct != null && total != null && total! > 0;

  factory ExerciseResult.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final category = data['category'];
    return ExerciseResult(
      id: doc.id,
      studentId: data['studentId'] as String? ?? '',
      exerciseId: data['exerciseId'] as String? ?? '',
      score: (data['score'] as num?)?.toInt() ?? 0,
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate(),
      correct: (data['correct'] as num?)?.toInt(),
      total: (data['total'] as num?)?.toInt(),
      durationSeconds: (data['durationSeconds'] as num?)?.toInt(),
      exerciseTitle: data['exerciseTitle'] as String?,
      category:
          category is String ? ExerciseCategory.fromValue(category) : null,
    );
  }
}
