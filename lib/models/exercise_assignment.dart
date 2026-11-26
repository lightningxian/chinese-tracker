import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseAssignment {
  const ExerciseAssignment({
    required this.id,
    required this.exerciseId,
    required this.studentId,
    required this.teacherId,
    this.assignedAt,
    this.dueDate,
    this.done,
    this.bestScore,
  });

  final String id;
  final String exerciseId;
  final String studentId;
  final String teacherId;
  final DateTime? assignedAt;
  final DateTime? dueDate;

  /// Build 9 part 2: stamped by the progress-summary refresh (functions):
  /// whether the student has a result for the exercise, and the best
  /// score. Null on an assignment not stamped yet.
  final bool? done;
  final int? bestScore;

  bool get isOverdue {
    if (dueDate == null) return false;
    final today = DateTime.now();
    final due = dueDate!;
    final dueDay = DateTime(due.year, due.month, due.day);
    final todayDay = DateTime(today.year, today.month, today.day);
    return dueDay.isBefore(todayDay);
  }

  factory ExerciseAssignment.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return ExerciseAssignment(
      id: doc.id,
      exerciseId: data['exerciseId'] as String? ?? '',
      studentId: data['studentId'] as String? ?? '',
      teacherId: data['teacherId'] as String? ?? '',
      assignedAt: (data['assignedAt'] as Timestamp?)?.toDate(),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      done: data['done'] as bool?,
      bestScore: (data['bestScore'] as num?)?.round(),
    );
  }

  static String docId(String exerciseId, String studentId) =>
      '${exerciseId}_$studentId';
}
