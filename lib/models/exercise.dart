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

  /// Required word for picture sentence exercises; the pinyin hint for
  /// "type the hanzi" questions.
  final String keyword;

  /// Typed-answer questions: every accepted answer (trimmed, exact match).
  List<String> get acceptedAnswers => options;
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
        // Inside an exercise the word bank lives in `matchingOptions`; a bank
        // question keeps its own copy in `options` so it plays on its own.
        return ExerciseQuestion(
          prompt: map['prompt'] as String? ?? '',
          options: List<String>.from(map['options'] as List? ?? []),
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
      case ExerciseType.typeHanzi:
        return ExerciseQuestion(
          prompt: map['prompt'] as String? ?? '',
          keyword: map['keyword'] as String? ?? '',
          options: List<String>.from(map['options'] as List? ?? []),
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
          if (options.isNotEmpty) 'options': options,
          'correctIndex': correctIndex,
          ...mediaFields(),
        };
      case ExerciseType.pictureSentence:
        return {
          'prompt': prompt,
          'keyword': keyword,
          ...mediaFields(),
        };
      case ExerciseType.typeHanzi:
        return {
          'prompt': prompt,
          'keyword': keyword,
          'options': options,
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

  /// Typed answer check: exact match after trimming and removing spaces and
  /// full-width punctuation (type the hanzi); for picture sentences the
  /// sentence must contain the keyword and be more than the keyword alone.
  bool isCorrectTypedAnswer(ExerciseType type, String typed) {
    String clean(String s) =>
        s.replaceAll(RegExp(r'[\s。．.，,！!？?、：:；;「」『』“”"()（）]'), '').trim();
    final answer = clean(typed);
    if (answer.isEmpty) return false;
    if (type == ExerciseType.pictureSentence) {
      final k = clean(keyword);
      return k.isEmpty
          ? answer.length >= 2
          : answer.contains(k) && answer.length > k.length;
    }
    return acceptedAnswers.any((a) => clean(a) == answer);
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
    this.bankSheets = const [],
    this.bankQuestionIds = const [],
    this.timeLimitMinutes,
  });

  final String id;
  final String title;
  final String instructions;
  final String teacherId;

  /// Questions stored inside the exercise (legacy exercises built before
  /// 2026-11-09). A package ([isPackage]) has none here: its questions live
  /// in the question bank and are served by the `startExercise` function
  /// without their answer keys.
  final List<ExerciseQuestion> questions;

  /// Worksheet codes from the question bank (`310001-RDG`) that make up a
  /// package, in play order.
  final List<String> bankSheets;

  /// Single bank questions added to a package, played after the sheets.
  final List<String> bankQuestionIds;

  bool get isPackage => bankSheets.isNotEmpty || bankQuestionIds.isNotEmpty;

  /// "2 worksheets" for a package (the question count is only known once
  /// the bank is read), "7 questions" otherwise.
  String get contentsLabel {
    if (isPackage) {
      final n = bankSheets.length;
      final q = bankQuestionIds.length;
      return [
        if (n > 0) '$n worksheet${n == 1 ? '' : 's'}',
        if (q > 0) '$q question${q == 1 ? '' : 's'}',
      ].join(' · ');
    }
    return '${questions.length} question${questions.length == 1 ? '' : 's'}';
  }

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

  /// Minutes the student has to submit; the player counts down and submits
  /// by itself when it reaches zero. Null: no limit, the clock only counts up.
  final int? timeLimitMinutes;

  String get termLabel => termNumber != null ? 'Term $termNumber' : 'General';

  factory Exercise.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final exerciseType = ExerciseType.fromValue(data['type'] as String?);
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
      bankSheets: List<String>.from(data['bankSheets'] as List? ?? const []),
      bankQuestionIds:
          List<String>.from(data['bankQuestionIds'] as List? ?? const []),
      timeLimitMinutes: (data['timeLimitMinutes'] as num?)?.toInt(),
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
        'bankSheets': bankSheets,
        'bankQuestionIds': bankQuestionIds,
        if (timeLimitMinutes != null) 'timeLimitMinutes': timeLimitMinutes,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };
}
