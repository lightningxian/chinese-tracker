import '../../core/constants/app_constants.dart';
import '../../core/utils/question_import_utils.dart';
import '../../models/ai_worksheet.dart';
import '../../models/exercise.dart';
import '../../models/exercise_category.dart';
import '../../models/exercise_skill_category.dart';
import '../../models/exercise_type.dart';
import '../../models/question_bank_item.dart';

/// Counts the review screen reports after an AI reading.
class AiImportSummary {
  const AiImportSummary({
    required this.questions,
    required this.sections,
    required this.missingKeys,
    required this.pictures,
    this.level,
  });

  final int questions;
  final int sections;

  /// Questions the reader could not key (listening without a transcript):
  /// they default to the first choice until the admin sets the key.
  final int missingKeys;
  final int pictures;
  final String? level;
}

/// Turns the AI reader's result into bank items: one worksheet (the paper's
/// code), questions in printed order, each with its part heading and skill.
abstract final class QuestionBankAiImportUtils {
  /// [imageUrls] maps [AiBox.key] to the uploaded picture; boxes without an
  /// upload are skipped (the choice stays text-only).
  static List<QuestionBankItem> toBankItems(
    AiWorksheet worksheet, {
    required String ownerId,
    required Map<String, String> imageUrls,
    required String fileName,
  }) {
    final code = sheetCodeFor(worksheet, fileName);
    final level = worksheet.hskLevel == null
        ? null
        : AppConstants.hskLevels
            .where((l) => l.endsWith(' ${worksheet.hskLevel}'))
            .firstOrNull;
    final title = worksheet.title.isNotEmpty
        ? worksheet.title
        : level != null
            ? '$level · $code'
            : code;
    final category = ExerciseCategory.fromValue(worksheet.category);
    final out = <QuestionBankItem>[];
    for (final section in worksheet.sections) {
      final skill = skillFor(section.skill);
      for (final q in section.questions) {
        final built = _build(q, skill: skill, imageUrls: imageUrls);
        if (built == null) continue;
        out.add(QuestionBankItem(
          id: '',
          ownerId: ownerId,
          type: built.$1,
          question: built.$2,
          skillCategory: skill,
          level: level,
          category: category,
          tags: [code],
          sheetCode: code,
          sheetTitle: title,
          sheetIndex: out.length,
          section: section.title.isEmpty ? null : section.title,
        ));
      }
    }
    return out;
  }

  static AiImportSummary summarize(
    AiWorksheet worksheet, {
    required int pictures,
  }) {
    final questions = worksheet.questions;
    return AiImportSummary(
      questions: questions.length,
      sections: worksheet.sections.length,
      missingKeys: questions
          .where((q) => q.correctIndex == null && _isChoice(q.type))
          .length,
      pictures: pictures,
      level: worksheet.hskLevel == null ? null : 'HSK ${worksheet.hskLevel}',
    );
  }

  /// The paper's printed code; else the file name; else a timestamp.
  static String sheetCodeFor(AiWorksheet worksheet, String fileName) {
    final printed = worksheet.code.replaceAll(RegExp(r'[^A-Za-z0-9-]'), '');
    if (printed.isNotEmpty) return printed.toUpperCase();
    final base = fileName.split('/').last.split('.').first;
    final cleaned = base.replaceAll(RegExp(r'[^A-Za-z0-9-]'), '');
    if (cleaned.isNotEmpty) return cleaned.toUpperCase();
    return 'SHEET-${DateTime.now().millisecondsSinceEpoch}';
  }

  static ExerciseSkillCategory skillFor(String skill) => switch (skill) {
        'listening' => ExerciseSkillCategory.listening,
        'writing' => ExerciseSkillCategory.typing,
        _ => ExerciseSkillCategory.reading,
      };

  static bool _isChoice(String type) => const {
        'picture_choice',
        'true_false',
        'choice',
        'matching',
        'cloze',
      }.contains(type);

  static (ExerciseType, ExerciseQuestion)? _build(
    AiQuestion q, {
    required ExerciseSkillCategory skill,
    required Map<String, String> imageUrls,
  }) {
    final isListening = skill == ExerciseSkillCategory.listening;
    final numberPrompt = '第${q.number}题';
    final prompt = q.prompt.isNotEmpty ? q.prompt : numberPrompt;
    final imageUrl = q.imageBox == null ? '' : imageUrls[q.imageBox!.key] ?? '';
    final key = q.correctIndex ?? 0;
    switch (q.type) {
      case 'picture_choice':
        final urls = [
          for (final box in q.optionImageBoxes) imageUrls[box.key] ?? '',
        ];
        final count = urls.isNotEmpty ? urls.length : q.options.length;
        if (count < 2) return null;
        final letters = [
          for (var i = 0; i < count; i++) String.fromCharCode(65 + i),
        ];
        return (
          isListening ? ExerciseType.listening : ExerciseType.multipleChoice,
          ExerciseQuestion(
            prompt: prompt,
            options: letters,
            optionImageUrls: urls.every((u) => u.isEmpty) ? const [] : urls,
            correctIndex: key.clamp(0, count - 1),
            imageUrl: imageUrl,
          ),
        );
      case 'true_false':
        return (
          ExerciseType.multipleChoice,
          ExerciseQuestion(
            prompt: prompt,
            options: QuestionImportUtils.trueFalseOptions,
            correctIndex: key.clamp(0, 1),
            imageUrl: imageUrl,
          ),
        );
      case 'matching':
      case 'cloze':
        if (q.options.length < 2) return null;
        return (
          q.type == 'cloze' ? ExerciseType.readingCloze : ExerciseType.matching,
          ExerciseQuestion(
            prompt: prompt,
            options: q.options,
            correctIndex: key.clamp(0, q.options.length - 1),
            imageUrl: imageUrl,
          ),
        );
      case 'reorder':
        if (q.segments.length < 2) return null;
        return (
          ExerciseType.composeSentences,
          ExerciseQuestion(prompt: q.prompt, segments: q.segments),
        );
      case 'write_hanzi':
        if (q.keyword.isEmpty) return null;
        return (
          ExerciseType.typeHanzi,
          ExerciseQuestion(
            prompt: prompt,
            keyword: q.keyword,
            options: q.accepted,
          ),
        );
      case 'sentence_with_word':
        if (q.keyword.isEmpty) return null;
        return (
          ExerciseType.pictureSentence,
          ExerciseQuestion(
            prompt: q.prompt,
            keyword: q.keyword,
            imageUrl: imageUrl,
          ),
        );
      default:
        if (q.options.length < 2) return null;
        return (
          isListening ? ExerciseType.listening : ExerciseType.multipleChoice,
          ExerciseQuestion(
            prompt: prompt,
            options: q.options,
            correctIndex: key.clamp(0, q.options.length - 1),
            imageUrl: imageUrl,
          ),
        );
    }
  }
}
