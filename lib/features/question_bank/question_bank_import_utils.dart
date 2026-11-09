import '../../core/constants/app_constants.dart';
import '../../core/utils/question_import_utils.dart';
import '../../models/exercise.dart';
import '../../models/exercise_skill_category.dart';
import '../../models/exercise_type.dart';
import '../../models/question_bank_item.dart';

/// Converts parsed worksheet / paste text into bank items.
abstract final class QuestionBankImportUtils {
  static List<QuestionBankItem> fromParseResult({
    required WorksheetParseResult result,
    required String ownerId,
    ExerciseType? typeOverride,
    String? levelOverride,
    List<String> tags = const [],
  }) {
    final type = typeOverride ?? result.suggestedType;
    final level = levelOverride ?? result.suggestedLevel;
    final skill =
        result.suggestedSkill ?? ExerciseSkillCategory.forExerciseType(type);
    // The sheet code (310001-RDG) as a tag, so the bank can be searched and
    // filtered by worksheet.
    final sheetCode = result.sheetCode;
    final itemTags = sheetCode == null || tags.contains(sheetCode)
        ? tags
        : [sheetCode, ...tags];
    final sheetTitle = result.suggestedTitle?.trim();

    QuestionBankItem item(int index, ExerciseQuestion question) =>
        QuestionBankItem(
          id: '',
          ownerId: ownerId,
          type: type,
          question: question,
          skillCategory: skill,
          level: level,
          tags: itemTags,
          sheetCode: sheetCode,
          sheetTitle: sheetCode == null ? null : sheetTitle,
          sheetIndex: sheetCode == null ? null : index,
        );

    return switch (type) {
      ExerciseType.composeSentences => [
          for (final (i, q) in result.composeQuestions.indexed)
            item(i, ExerciseQuestion(prompt: q.prompt, segments: q.segments)),
        ],
      // Matching and fill in the blank share one answer bank; each bank
      // item keeps a copy of it so the question stays usable on its own.
      ExerciseType.matching || ExerciseType.readingCloze => [
          for (final (i, q) in result.matchingQuestions.indexed)
            item(
              i,
              ExerciseQuestion(
                prompt: q.prompt,
                options: result.matchingOptions,
                correctIndex: q.correctIndex,
              ),
            ),
        ],
      // Multiple choice, listening, type-the-hanzi (options = accepted
      // answers, keyword = pinyin) and picture sentences (keyword).
      _ => [
          for (final (i, q) in result.mcQuestions.indexed)
            item(
              i,
              ExerciseQuestion(
                prompt: q.prompt,
                options: q.options,
                correctIndex: q.correctIndex,
                keyword: q.keyword,
              ),
            ),
        ],
    };
  }

  static List<QuestionBankItem> fromPasteText({
    required String text,
    required String ownerId,
    ExerciseType type = ExerciseType.multipleChoice,
    String? level,
    List<String> tags = const [],
  }) {
    final result = QuestionImportUtils.parseWorksheet(text);
    return fromParseResult(
      result: result,
      ownerId: ownerId,
      typeOverride: type,
      levelOverride:
          level ?? result.suggestedLevel ?? AppConstants.hskLevels.first,
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

  /// A bundled question set (`assets/question_sets/*.json`): the centre's
  /// own sheets, already scanned and keyed. Each item carries its sheet code
  /// (`set`), type, level, skill, tags and an [ExerciseQuestion] map; the
  /// position inside its sheet becomes [QuestionBankItem.sheetIndex].
  static List<QuestionBankItem> fromQuestionSet(
    Map<String, dynamic> set, {
    required String ownerId,
  }) {
    final items = (set['items'] as List? ?? const [])
        .whereType<Map>()
        .map((raw) => Map<String, dynamic>.from(raw));
    final indexInSheet = <String, int>{};
    return [
      for (final it in items)
        () {
          final type = ExerciseType.fromValue(it['type'] as String?);
          final code = (it['set'] as String?)?.trim();
          final index = code == null
              ? null
              : indexInSheet.update(code, (n) => n + 1, ifAbsent: () => 0);
          return QuestionBankItem(
            id: '',
            ownerId: ownerId,
            type: type,
            question: ExerciseQuestion.fromMap(
              Map<String, dynamic>.from(it['question'] as Map? ?? const {}),
              exerciseType: type,
            ),
            skillCategory:
                ExerciseSkillCategory.fromValue(it['skill'] as String?),
            level: it['level'] as String?,
            tags: List<String>.from(it['tags'] as List? ?? const []),
            sheetCode: code,
            sheetTitle: (it['title'] as String?)?.trim(),
            sheetIndex: index,
          );
        }(),
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
