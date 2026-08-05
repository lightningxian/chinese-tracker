import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/grade_utils.dart';

/// Category of an assessment recorded in the gradebook.
enum GradeCategory {
  quiz('quiz', 'Quiz'),
  exercise('exercise', 'Exercise'),
  speaking('speaking', 'Speaking'),
  writing('writing', 'Writing'),
  exam('exam', 'Exam'),
  other('other', 'Other');

  const GradeCategory(this.value, this.label);

  final String value;
  final String label;

  static GradeCategory fromValue(String? value) {
    return GradeCategory.values.firstWhere(
      (c) => c.value == value,
      orElse: () => GradeCategory.other,
    );
  }
}

/// Lifecycle of a grade entry: an assessment can be scheduled ([pending]) and
/// scored later ([graded]).
enum GradeStatus {
  pending('pending', 'Pending'),
  graded('graded', 'Graded');

  const GradeStatus(this.value, this.label);

  final String value;
  final String label;

  static GradeStatus fromValue(String? value) {
    return GradeStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => GradeStatus.pending,
    );
  }
}

/// A first-class gradebook entry. Teachers own writes (see `firestore.rules`);
/// students and their linked parents get read-only access for the transcript.
class Grade {
  const Grade({
    required this.id,
    required this.studentId,
    required this.teacherId,
    required this.title,
    required this.category,
    required this.status,
    this.classSessionId,
    this.score,
    this.letterGrade,
    this.gradedBy,
    this.createdAt,
    this.gradedAt,
  });

  final String id;
  final String studentId;
  final String teacherId;
  final String title;
  final GradeCategory category;
  final GradeStatus status;
  final String? classSessionId;

  /// 0..100 once graded; null while pending.
  final num? score;
  final String? letterGrade;
  final String? gradedBy;
  final DateTime? createdAt;
  final DateTime? gradedAt;

  bool get isGraded => status == GradeStatus.graded;
  bool get isPending => status == GradeStatus.pending;

  /// Letter grade for display — falls back to deriving from [score].
  String? get displayLetter {
    if (letterGrade != null && letterGrade!.isNotEmpty) return letterGrade;
    if (score != null) return GradeUtils.letterGradeFor(score!);
    return null;
  }

  factory Grade.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Grade(
      id: doc.id,
      studentId: data['studentId'] as String? ?? '',
      teacherId: data['teacherId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      category: GradeCategory.fromValue(data['category'] as String?),
      status: GradeStatus.fromValue(data['status'] as String?),
      classSessionId: data['classSessionId'] as String?,
      score: data['score'] as num?,
      letterGrade: data['letterGrade'] as String?,
      gradedBy: data['gradedBy'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      gradedAt: (data['gradedAt'] as Timestamp?)?.toDate(),
    );
  }
}
