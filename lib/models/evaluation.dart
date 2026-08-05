import 'package:cloud_firestore/cloud_firestore.dart';

/// A per-term student evaluation (`evaluations`). Staff write; students see
/// their own *published* ones; parents see their linked child's published ones.
class Evaluation {
  const Evaluation({
    required this.id,
    required this.studentId,
    required this.teacherId,
    required this.term,
    required this.status,
    this.rating,
    this.strengths = '',
    this.improvements = '',
    this.comment = '',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String studentId;
  final String teacherId;
  final String term;

  /// "draft" | "published"
  final String status;

  /// 1..5, optional.
  final num? rating;
  final String strengths;
  final String improvements;
  final String comment;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isPublished => status == 'published';

  factory Evaluation.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return Evaluation(
      id: doc.id,
      studentId: data['studentId'] as String? ?? '',
      teacherId: data['teacherId'] as String? ?? '',
      term: data['term'] as String? ?? '',
      status: data['status'] as String? ?? 'draft',
      rating: data['rating'] as num?,
      strengths: data['strengths'] as String? ?? '',
      improvements: data['improvements'] as String? ?? '',
      comment: data['comment'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'studentId': studentId,
        'teacherId': teacherId,
        'term': term.trim(),
        'status': status,
        if (rating != null) 'rating': rating,
        'strengths': strengths.trim(),
        'improvements': improvements.trim(),
        'comment': comment.trim(),
      };
}
