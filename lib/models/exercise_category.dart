/// What a worksheet in the question bank is for. Set per worksheet (every
/// question of the sheet carries the same value) and shown as the "Type of
/// exercise" column in the bank.
enum ExerciseCategory {
  exercise('exercise', 'Exercise'),
  quiz('quiz', 'Quiz'),
  exam('exam', 'Exam'),
  hskSimulation('hsk_simulation', 'HSK Simulation'),

  /// Owner 2026-11-24: the HSK Standard Course books (标准教程) and their
  /// workbooks, with the book's audio. Practice: played any number of
  /// times, like an exercise.
  standardCourse('hsk_standard_course', 'HSK Standard Course');

  const ExerciseCategory(this.value, this.label);

  final String value;
  final String label;

  /// Unknown or missing values read as [exercise], the default for every
  /// sheet imported before the field existed.
  static ExerciseCategory fromValue(String? value) =>
      ExerciseCategory.values.firstWhere(
        (c) => c.value == value,
        orElse: () => ExerciseCategory.exercise,
      );
}
