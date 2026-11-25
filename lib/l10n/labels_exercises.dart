import '../models/exercise_category.dart';
import '../models/exercise_skill_category.dart';
import '../models/exercise_type.dart';
import '../models/question_bank_item.dart';
import 'generated/app_localizations.dart';

/// Translated names for the exercise enums. The models keep their English
/// `label` (search matching, logs); screens show `localized(context.l10n)`.

extension ExerciseTypeL10n on ExerciseType {
  String localized(AppLocalizations l) => switch (this) {
        ExerciseType.multipleChoice => l.exerciseTypeMultipleChoice,
        ExerciseType.composeSentences => l.exerciseTypeComposeSentences,
        ExerciseType.matching => l.exerciseTypeMatching,
        ExerciseType.listening => l.exerciseTypeListening,
        ExerciseType.readingCloze => l.exerciseTypeReadingCloze,
        ExerciseType.pictureSentence => l.exerciseTypePictureSentence,
        ExerciseType.typeHanzi => l.exerciseTypeTypeHanzi,
        ExerciseType.typePinyin => l.exerciseTypeTypePinyin,
        ExerciseType.essay => l.exerciseTypeEssay,
        ExerciseType.fillBlanks => l.exerciseTypeFillBlanks,
      };
}

extension ExerciseCategoryL10n on ExerciseCategory {
  String localized(AppLocalizations l) => switch (this) {
        ExerciseCategory.exercise => l.exerciseCategoryExercise,
        ExerciseCategory.quiz => l.exerciseCategoryQuiz,
        ExerciseCategory.exam => l.exerciseCategoryExam,
        ExerciseCategory.hskSimulation => l.exerciseCategoryHskSimulation,
        ExerciseCategory.standardCourse => l.exerciseCategoryStandardCourse,
      };
}

extension ExerciseSkillCategoryL10n on ExerciseSkillCategory {
  String localized(AppLocalizations l) => switch (this) {
        ExerciseSkillCategory.reading => l.skillCategoryReading,
        ExerciseSkillCategory.listening => l.skillCategoryListening,
        ExerciseSkillCategory.typing => l.skillCategoryTyping,
        ExerciseSkillCategory.speaking => l.skillCategorySpeaking,
        ExerciseSkillCategory.mixed => l.skillCategoryMixed,
      };
}

/// Owner 2026-11-24: HSK and Standard Course papers show the paper kind in
/// the "Question type" column ([QuestionBankSheet.typeLabel]).
extension QuestionBankSheetTypeL10n on QuestionBankSheet {
  String typeLocalized(AppLocalizations l) => switch (category) {
        ExerciseCategory.hskSimulation => l.bankTypeHsk,
        ExerciseCategory.standardCourse => l.exerciseCategoryStandardCourse,
        _ => type.localized(l),
      };
}
