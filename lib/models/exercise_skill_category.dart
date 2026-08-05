import 'exercise_type.dart';

enum ExerciseSkillCategory {
  reading('reading', 'Reading'),
  listening('listening', 'Listening'),
  typing('typing', 'Typing (Writing)'),
  speaking('speaking', 'Speaking');

  const ExerciseSkillCategory(this.value, this.label);

  final String value;
  final String label;

  static ExerciseSkillCategory fromValue(String? value) {
    return ExerciseSkillCategory.values.firstWhere(
      (category) => category.value == value,
      orElse: () => ExerciseSkillCategory.reading,
    );
  }

  /// Default skill section when creating from an exercise type.
  static ExerciseSkillCategory forExerciseType(ExerciseType type) {
    return switch (type) {
      ExerciseType.listening => ExerciseSkillCategory.listening,
      ExerciseType.readingCloze => ExerciseSkillCategory.reading,
      ExerciseType.composeSentences => ExerciseSkillCategory.typing,
      ExerciseType.pictureSentence => ExerciseSkillCategory.typing,
      ExerciseType.matching => ExerciseSkillCategory.reading,
      ExerciseType.multipleChoice => ExerciseSkillCategory.reading,
    };
  }
}
