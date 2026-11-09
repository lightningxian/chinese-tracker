import 'package:cloud_firestore/cloud_firestore.dart';

import 'exercise.dart';
import 'exercise_skill_category.dart';
import 'exercise_type.dart';
import 'question_difficulty.dart';

/// A reusable question in the shared question bank. Wraps an
/// [ExerciseQuestion] (using the same serialization) so a bank question drops
/// straight into an exercise/quiz. Ownership mirrors lessons/exercises via
/// [ownerId] (`AppConstants.contentTeacherId`).
class QuestionBankItem {
  const QuestionBankItem({
    required this.id,
    required this.ownerId,
    required this.type,
    required this.question,
    this.skillCategory,
    this.level,
    this.tags = const [],
    this.difficulty = QuestionDifficulty.medium,
    this.usageCount = 0,
    this.lastUsedAt,
    this.updatedAt,
    this.sourceExerciseId,
    this.createdBy,
    this.createdAt,
  });

  final String id;
  final String ownerId;
  final ExerciseType type;
  final ExerciseQuestion question;
  final ExerciseSkillCategory? skillCategory;
  final String? level;
  final List<String> tags;
  final QuestionDifficulty difficulty;
  final int usageCount;
  final DateTime? lastUsedAt;
  final DateTime? updatedAt;
  final String? sourceExerciseId;
  final String? createdBy;
  final DateTime? createdAt;

  String get prompt => question.prompt;

  /// What identifies the question when shown in a list: the prompt, or for a
  /// compose item its sentence, or the keyword of a picture / hanzi item.
  String get displayText {
    if (prompt.trim().isNotEmpty) return prompt;
    if (question.segments.isNotEmpty) return question.segments.join(' / ');
    if (question.keyword.isNotEmpty) return question.keyword;
    return '';
  }

  /// Dedupe key: same content + type = already in bank. Built from
  /// [displayText], so compose items (which have no prompt) stay distinct.
  String get dedupeKey => '${type.value}::${displayText.trim().toLowerCase()}';

  factory QuestionBankItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final type = ExerciseType.fromValue(data['type'] as String?);
    return QuestionBankItem(
      id: doc.id,
      ownerId: data['ownerId'] as String? ?? '',
      type: type,
      question: ExerciseQuestion.fromMap(
        Map<String, dynamic>.from(data['question'] as Map? ?? data),
        exerciseType: type,
      ),
      skillCategory: data['skillCategory'] == null
          ? null
          : ExerciseSkillCategory.fromValue(data['skillCategory'] as String?),
      level: data['level'] as String?,
      tags: List<String>.from(data['tags'] as List? ?? const []),
      difficulty: QuestionDifficulty.fromValue(data['difficulty'] as String?),
      usageCount: data['usageCount'] as int? ?? 0,
      lastUsedAt: (data['lastUsedAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      sourceExerciseId: data['sourceExerciseId'] as String?,
      createdBy: data['createdBy'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'ownerId': ownerId,
        'type': type.value,
        'prompt': question.prompt,
        'question': question.toMap(type),
        if (skillCategory != null) 'skillCategory': skillCategory!.value,
        if (level != null && level!.isNotEmpty) 'level': level,
        'tags': tags,
        'difficulty': difficulty.value,
        'usageCount': usageCount,
        if (sourceExerciseId != null && sourceExerciseId!.isNotEmpty)
          'sourceExerciseId': sourceExerciseId,
      };

  QuestionBankItem copyWith({
    String? id,
    String? ownerId,
    ExerciseType? type,
    ExerciseQuestion? question,
    ExerciseSkillCategory? skillCategory,
    String? level,
    List<String>? tags,
    QuestionDifficulty? difficulty,
    int? usageCount,
    DateTime? lastUsedAt,
    DateTime? updatedAt,
    String? sourceExerciseId,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return QuestionBankItem(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      type: type ?? this.type,
      question: question ?? this.question,
      skillCategory: skillCategory ?? this.skillCategory,
      level: level ?? this.level,
      tags: tags ?? this.tags,
      difficulty: difficulty ?? this.difficulty,
      usageCount: usageCount ?? this.usageCount,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sourceExerciseId: sourceExerciseId ?? this.sourceExerciseId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
