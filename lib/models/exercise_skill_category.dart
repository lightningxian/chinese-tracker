import 'exercise_type.dart';

enum ExerciseSkillCategory {
  reading('reading', 'Reading'),
  listening('listening', 'Listening'),
  typing('typing', 'Typing (Writing)'),
  speaking('speaking', 'Speaking'),

  /// Owner 2026-11-24: an exercise that mixes skills. Exercises only; a
  /// question in the bank keeps one skill.
  mixed('mixed', 'Mixed');

  const ExerciseSkillCategory(this.value, this.label);

  final String value;
  final String label;

  static ExerciseSkillCategory fromValue(String? value) {
    return ExerciseSkillCategory.values.firstWhere(
      (category) => category.value == value,
      orElse: () => ExerciseSkillCategory.reading,
    );
  }

  /// The skills a single question can have (no Mixed).
  static List<ExerciseSkillCategory> get forQuestions =>
      values.where((c) => c != mixed).toList();

  /// Default skill section when creating from an exercise type.
  static ExerciseSkillCategory forExerciseType(ExerciseType type) {
    return switch (type) {
      ExerciseType.listening => ExerciseSkillCategory.listening,
      ExerciseType.readingCloze => ExerciseSkillCategory.reading,
      ExerciseType.composeSentences => ExerciseSkillCategory.typing,
      ExerciseType.pictureSentence => ExerciseSkillCategory.typing,
      ExerciseType.typeHanzi => ExerciseSkillCategory.typing,
      ExerciseType.typePinyin => ExerciseSkillCategory.typing,
      ExerciseType.essay => ExerciseSkillCategory.typing,
      ExerciseType.fillBlanks => ExerciseSkillCategory.typing,
      ExerciseType.matching => ExerciseSkillCategory.reading,
      ExerciseType.multipleChoice => ExerciseSkillCategory.reading,
    };
  }
}
