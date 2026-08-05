import 'package:cloud_firestore/cloud_firestore.dart';

/// A recorded quiz attempt (`quiz_results`). Used read-only in the transcript
/// alongside first-class grades and exercise results.
class QuizResult {
  const QuizResult({
    required this.id,
    required this.studentId,
    required this.lessonId,
    required this.score,
    this.quizId,
    this.submittedAt,
  });

  final String id;
  final String studentId;
  final String lessonId;
  final int score;
  final String? quizId;
  final DateTime? submittedAt;

  factory QuizResult.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return QuizResult(
      id: doc.id,
      studentId: data['studentId'] as String? ?? '',
      lessonId: data['lessonId'] as String? ?? '',
      score: (data['score'] as num?)?.toInt() ?? 0,
      quizId: data['quizId'] as String?,
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate(),
    );
  }
}
