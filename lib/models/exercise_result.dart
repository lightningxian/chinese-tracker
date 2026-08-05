import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseResult {
  const ExerciseResult({
    required this.id,
    required this.studentId,
    required this.exerciseId,
    required this.score,
    this.submittedAt,
  });

  final String id;
  final String studentId;
  final String exerciseId;
  final int score;
  final DateTime? submittedAt;

  factory ExerciseResult.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return ExerciseResult(
      id: doc.id,
      studentId: data['studentId'] as String? ?? '',
      exerciseId: data['exerciseId'] as String? ?? '',
      score: data['score'] as int? ?? 0,
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate(),
    );
  }
}
