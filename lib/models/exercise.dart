import 'package:cloud_firestore/cloud_firestore.dart';

import 'exercise_skill_category.dart';
import 'exercise_type.dart';

class ExerciseQuestion {
  const ExerciseQuestion({
    required this.prompt,
    this.options = const [],
    this.correctIndex = 0,
    this.segments = const [],
    this.keyword = '',
    this.imageUrl = '',
    this.audioUrl = '',
    this.blankNumber,
  });

  final String prompt;
  final List<String> options;
  final int correctIndex;
  /// Ordered parts of the sentence (compose sentences type).
  final List<String> segments;
  /// Required word for picture sentence exercises.
  final String keyword;
  final String imageUrl;
  /// Optional per-question audio (listening items in bank/quiz).
  final String audioUrl;
  /// Blank index inside a reading cloze passage.
  final int? blankNumber;

  factory ExerciseQuestion.fromMap(
    Map<String, dynamic> map, {
    required ExerciseType exerciseType,
  }) {
    switch (exerciseType) {
      case ExerciseType.composeSentences:
        return ExerciseQuestion(
          prompt: map['prompt'] as String? ?? '',
          segments: List<String>.from(map['segments'] as List? ?? []),
          imageUrl: map['imageUrl'] as String? ?? '',
          audioUrl: map['audioUrl'] as String? ?? '',
        );
      case ExerciseType.matching:
        return ExerciseQuestion(
          prompt: map['prompt'] as String? ?? '',
          correctIndex: map['correctIndex'] as int? ?? 0,
          imageUrl: map['imageUrl'] as String? ?? '',
          audioUrl: map['audioUrl'] as String? ?? '',
        );
      case ExerciseType.pictureSentence:
        return ExerciseQuestion(
          prompt: map['prompt'] as String? ?? '',
          keyword: map['keyword'] as String? ?? map['prompt'] as String? ?? '',
          imageUrl: map['imageUrl'] as String? ?? '',
          audioUrl: map['audioUrl'] as String? ?? '',
        );
      case ExerciseType.readingCloze:
        return ExerciseQuestion(
          prompt: map['prompt'] as String? ?? '',
          options: List<String>.from(map['options'] as List? ?? []),
          correctIndex: map['correctIndex'] as int? ?? 0,
          blankNumber: map['blankNumber'] as int?,
          imageUrl: map['imageUrl'] as String? ?? '',
          audioUrl: map['audioUrl'] as String? ?? '',
        );
      case ExerciseType.multipleChoice:
      case ExerciseType.listening:
        return ExerciseQuestion(
          prompt: map['prompt'] as String? ?? map['question'] as String? ?? '',
          options: List<String>.from(map['options'] as List? ?? []),
          correctIndex: map['correctIndex'] as int? ?? 0,
          imageUrl: map['imageUrl'] as String? ?? '',
          audioUrl: map['audioUrl'] as String? ?? '',
        );
    }
  }

  Map<String, dynamic> toMap(ExerciseType exerciseType) {
    Map<String, dynamic> mediaFields() => {
          if (imageUrl.isNotEmpty) 'imageUrl': imageUrl,
          if (audioUrl.isNotEmpty) 'audioUrl': audioUrl,
        };

    switch (exerciseType) {
      case ExerciseType.composeSentences:
        return {
          'prompt': prompt,
          'segments': segments,
          ...mediaFields(),
        };
      case ExerciseType.matching:
        return {
          'prompt': prompt,
          'correctIndex': correctIndex,
          ...mediaFields(),
        };
      case ExerciseType.pictureSentence:
        return {
          'prompt': prompt,
          'keyword': keyword,
          ...mediaFields(),
        };
      case ExerciseType.readingCloze:
        return {
          'prompt': prompt,
          'options': options,
          'correctIndex': correctIndex,
          if (blankNumber != null) 'blankNumber': blankNumber,
          ...mediaFields(),
        };
      case ExerciseType.multipleChoice:
      case ExerciseType.listening:
        return {
          'prompt': prompt,
          'options': options,
          'correctIndex': correctIndex,
          ...mediaFields(),
        };
    }
  }

  bool isCorrectComposeOrder(List<String> order) {
    if (order.length != segments.length) return false;
    for (var i = 0; i < segments.length; i++) {
      if (order[i] != segments[i]) return false;
    }
    return true;
  }
}

class Exercise {
  const Exercise({
    required this.id,
    required this.title,
    required this.instructions,
    required this.teacherId,
    required this.questions,
    required this.order,
    this.type = ExerciseType.multipleChoice,
    this.matchingOptions = const [],
    this.passage = '',
    this.level,
    this.skillCategory = ExerciseSkillCategory.reading,
    this.termNumber,
    this.isPublished = true,
    this.createdAt,
    this.audioUrl,
  });

  final String id;
  final String title;
  final String instructions;
  final String teacherId;
  final List<ExerciseQuestion> questions;
  final int order;
  final ExerciseType type;
  /// Shared answer bank for matching exercises (A, B, C…).
  final List<String> matchingOptions;
  /// Reading passage for cloze exercises.
  final String passage;
  final String? level;
  final ExerciseSkillCategory skillCategory;
  final int? termNumber;
  final bool isPublished;
  final DateTime? createdAt;
  /// Audio file URL for listening exercises.
  final String? audioUrl;

  String get termLabel =>
      termNumber != null ? 'Term $termNumber' : 'General';

  factory Exercise.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final exerciseType =
        ExerciseType.fromValue(data['type'] as String?);
    final rawQuestions = data['questions'] as List? ?? [];
    return Exercise(
      id: doc.id,
      title: data['title'] as String? ?? '',
      instructions: data['instructions'] as String? ?? '',
      teacherId: data['teacherId'] as String? ?? '',
      order: data['order'] as int? ?? 0,
      type: exerciseType,
      matchingOptions:
          List<String>.from(data['matchingOptions'] as List? ?? []),
      passage: data['passage'] as String? ?? '',
      level: data['level'] as String?,
      skillCategory: ExerciseSkillCategory.fromValue(
        data['skillCategory'] as String?,
      ),
      termNumber: data['termNumber'] as int?,
      isPublished: data['isPublished'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      audioUrl: data['audioUrl'] as String?,
      questions: rawQuestions
          .map(
            (q) => ExerciseQuestion.fromMap(
              Map<String, dynamic>.from(q as Map),
              exerciseType: exerciseType,
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'instructions': instructions,
        'teacherId': teacherId,
        'order': order,
        'type': type.value,
        if (matchingOptions.isNotEmpty) 'matchingOptions': matchingOptions,
        if (passage.isNotEmpty) 'passage': passage,
        if (level != null && level!.isNotEmpty) 'level': level,
        'skillCategory': skillCategory.value,
        if (termNumber != null) 'termNumber': termNumber,
        'isPublished': isPublished,
        if (audioUrl != null && audioUrl!.isNotEmpty) 'audioUrl': audioUrl,
        'questions': questions.map((q) => q.toMap(type)).toList(),
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };
}
