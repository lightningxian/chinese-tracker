import '../../core/constants/app_constants.dart';
import '../../core/utils/question_import_utils.dart';
import '../../models/exercise.dart';
import '../../models/exercise_skill_category.dart';
import '../../models/exercise_type.dart';
import '../../models/question_bank_item.dart';
import '../../models/question_difficulty.dart';

/// Converts parsed worksheet / paste text into bank items.
abstract final class QuestionBankImportUtils {
  static List<QuestionBankItem> fromParseResult({
    required WorksheetParseResult result,
    required String ownerId,
    ExerciseType? typeOverride,
    String? levelOverride,
    QuestionDifficulty difficulty = QuestionDifficulty.medium,
    List<String> tags = const [],
  }) {
    final type = typeOverride ?? result.suggestedType;
    final level = levelOverride ?? result.suggestedLevel;
    final skill = ExerciseSkillCategory.forExerciseType(type);

    return switch (type) {
      ExerciseType.composeSentences => [
          for (final q in result.composeQuestions)
            QuestionBankItem(
              id: '',
              ownerId: ownerId,
              type: type,
              question: ExerciseQuestion(
                prompt: q.prompt,
                segments: q.segments,
              ),
              skillCategory: skill,
              level: level,
              tags: tags,
              difficulty: difficulty,
            ),
        ],
      // Matching and fill in the blank share one answer bank; each bank
      // item keeps a copy of it so the question stays usable on its own.
      ExerciseType.matching || ExerciseType.readingCloze => [
          for (final q in result.matchingQuestions)
            QuestionBankItem(
              id: '',
              ownerId: ownerId,
              type: type,
              question: ExerciseQuestion(
                prompt: q.prompt,
                options: result.matchingOptions,
                correctIndex: q.correctIndex,
              ),
              skillCategory: skill,
              level: level,
              tags: tags,
              difficulty: difficulty,
            ),
        ],
      // Multiple choice, listening, type-the-hanzi (options = accepted
      // answers, keyword = pinyin) and picture sentences (keyword).
      _ => [
          for (final q in result.mcQuestions)
            QuestionBankItem(
              id: '',
              ownerId: ownerId,
              type: type,
              question: ExerciseQuestion(
                prompt: q.prompt,
                options: q.options,
                correctIndex: q.correctIndex,
                keyword: q.keyword,
              ),
              skillCategory: skill,
              level: level,
              tags: tags,
              difficulty: difficulty,
            ),
        ],
    };
  }

  static List<QuestionBankItem> fromPasteText({
    required String text,
    required String ownerId,
    ExerciseType type = ExerciseType.multipleChoice,
    String? level,
    QuestionDifficulty difficulty = QuestionDifficulty.medium,
    List<String> tags = const [],
  }) {
    final result = QuestionImportUtils.parseWorksheet(text);
    return fromParseResult(
      result: result,
      ownerId: ownerId,
      typeOverride: type,
      levelOverride: level ?? result.suggestedLevel ?? AppConstants.hskLevels.first,
      difficulty: difficulty,
      tags: tags,
    );
  }

  static List<QuestionBankItem> fromExerciseQuestions({
    required String ownerId,
    required String exerciseId,
    required ExerciseType type,
    required List<ExerciseQuestion> questions,
    ExerciseSkillCategory? skillCategory,
    String? level,
  }) {
    final skill = skillCategory ?? ExerciseSkillCategory.forExerciseType(type);
    return [
      for (final q in questions)
        if (q.prompt.trim().isNotEmpty)
          QuestionBankItem(
            id: '',
            ownerId: ownerId,
            type: type,
            question: q,
            skillCategory: skill,
            level: level,
            sourceExerciseId: exerciseId,
          ),
    ];
  }

  /// Returns only candidates whose prompt+type are not already in [existing].
  static ({List<QuestionBankItem> novel, int skipped}) dedupeAgainstBank(
    List<QuestionBankItem> candidates,
    List<QuestionBankItem> existing,
  ) {
    final keys = existing.map((e) => e.dedupeKey).toSet();
    final novel = <QuestionBankItem>[];
    var skipped = 0;
    for (final c in candidates) {
      if (keys.contains(c.dedupeKey)) {
        skipped++;
      } else {
        keys.add(c.dedupeKey);
        novel.add(c);
      }
    }
    return (novel: novel, skipped: skipped);
  }
}
