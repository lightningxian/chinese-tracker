enum ExerciseType {
  multipleChoice('multiple_choice', 'Multiple choice'),
  composeSentences('compose_sentences', 'Compose sentences (组词成句)'),
  matching('matching', 'Matching (对话配对)'),
  listening('listening', 'Listening (听力)'),
  readingCloze('reading_cloze', 'Fill in the blank (选词填空)'),
  pictureSentence('picture_sentence', 'Picture + keyword sentence'),
  typeHanzi('type_hanzi', 'Type the hanzi (写汉字)');

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
      // Typed answers: hanzi for a pinyin hint, or a sentence with a keyword.
      case ExerciseType.typeHanzi:
      case ExerciseType.pictureSentence:
        return true;
    }
  }
}
