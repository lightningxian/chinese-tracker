enum ExerciseType {
  multipleChoice('multiple_choice', 'Multiple choice'),
  composeSentences('compose_sentences', 'Compose sentences (组词成句)'),
  matching('matching', 'Matching (对话配对)'),
  listening('listening', 'Listening (听力)'),
  readingCloze('reading_cloze', 'Fill in the blank (选词填空)'),
  pictureSentence('picture_sentence', 'Picture + keyword sentence');

  const ExerciseType(this.value, this.label);

  final String value;
  final String label;

  static ExerciseType fromValue(String? value) {
    return ExerciseType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ExerciseType.multipleChoice,
    );
  }

  bool get isImplemented {
    switch (this) {
      case ExerciseType.multipleChoice:
      case ExerciseType.composeSentences:
      case ExerciseType.matching:
      case ExerciseType.listening:
      // Fill in the blank reuses the matching data: a shared word bank and one
      // sentence per blank with the index of the right word.
      case ExerciseType.readingCloze:
        return true;
      case ExerciseType.pictureSentence:
        return false;
    }
  }
}
