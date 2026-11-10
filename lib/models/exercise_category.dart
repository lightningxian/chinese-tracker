/// What a worksheet in the question bank is for. Set per worksheet (every
/// question of the sheet carries the same value) and shown as the "Type of
/// exercise" column in the bank.
enum ExerciseCategory {
  exercise('exercise', 'Exercise'),
  quiz('quiz', 'Quiz'),
  exam('exam', 'Exam'),
  hskSimulation('hsk_simulation', 'HSK Simulation');

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
