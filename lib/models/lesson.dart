import 'package:cloud_firestore/cloud_firestore.dart';

class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.unit,
    required this.order,
    required this.content,
    required this.teacherId,
    this.audioUrl,
    this.level,
    this.termNumber = 1,
  });

  final String id;
  final String title;
  final String unit;
  final int order;
  final String content;
  final String teacherId;
  final String? audioUrl;
  final String? level;
  final int termNumber;

  String get termLabel => 'Term $termNumber';

  factory Lesson.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Lesson(
      id: doc.id,
      title: data['title'] as String? ?? '',
      unit: data['unit'] as String? ?? 'General',
      order: data['order'] as int? ?? 0,
      content: data['content'] as String? ?? '',
      teacherId: data['teacherId'] as String? ?? '',
      audioUrl: data['audioUrl'] as String?,
      level: data['level'] as String?,
      termNumber: data['termNumber'] as int? ?? 1,
    );
  }
}
