import 'package:cloud_firestore/cloud_firestore.dart';

class StudentProgress {
  const StudentProgress({
    required this.id,
    required this.studentId,
    required this.lessonId,
    required this.completed,
    this.score,
    this.completedAt,
  });

  final String id;
  final String studentId;
  final String lessonId;
  final bool completed;
  final int? score;
  final DateTime? completedAt;

  factory StudentProgress.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return StudentProgress(
      id: doc.id,
      studentId: data['studentId'] as String? ?? '',
      lessonId: data['lessonId'] as String? ?? '',
      completed: data['completed'] as bool? ?? false,
      score: data['score'] as int?,
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'studentId': studentId,
        'lessonId': lessonId,
        'completed': completed,
        if (score != null) 'score': score,
        'completedAt': FieldValue.serverTimestamp(),
      };
}
