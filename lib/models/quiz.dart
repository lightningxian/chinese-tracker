import 'package:cloud_firestore/cloud_firestore.dart';

class QuizQuestion {
  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    this.imageUrl,
    this.audioUrl,
  });

  final String question;
  final List<String> options;
  final int correctIndex;
  final String? imageUrl;
  final String? audioUrl;

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      question: map['question'] as String? ?? '',
      options: List<String>.from(map['options'] as List? ?? []),
      correctIndex: map['correctIndex'] as int? ?? 0,
      imageUrl: map['imageUrl'] as String?,
      audioUrl: map['audioUrl'] as String?,
    );
  }
}

class Quiz {
  const Quiz({
    required this.id,
    required this.lessonId,
    required this.title,
    required this.questions,
    required this.teacherId,
  });

  final String id;
  final String lessonId;
  final String title;
  final List<QuizQuestion> questions;
  final String teacherId;

  factory Quiz.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawQuestions = data['questions'] as List? ?? [];
    return Quiz(
      id: doc.id,
      lessonId: data['lessonId'] as String? ?? '',
      title: data['title'] as String? ?? 'Quiz',
      teacherId: data['teacherId'] as String? ?? '',
      questions: rawQuestions
          .map((q) => QuizQuestion.fromMap(Map<String, dynamic>.from(q as Map)))
          .toList(),
    );
  }
}
