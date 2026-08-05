/// Difficulty tag for question-bank items.
enum QuestionDifficulty {
  easy('easy', 'Easy'),
  medium('medium', 'Medium'),
  hard('hard', 'Hard');

  const QuestionDifficulty(this.value, this.label);

  final String value;
  final String label;

  static QuestionDifficulty fromValue(String? raw) {
    return QuestionDifficulty.values.firstWhere(
      (d) => d.value == raw,
      orElse: () => QuestionDifficulty.medium,
    );
  }
}
