enum ExerciseType {
  multipleChoice('multiple_choice', 'Multiple choice'),
  composeSentences('compose_sentences', 'Compose sentences (组词成句)'),
  matching('matching', 'Matching (对话配对)'),
  listening('listening', 'Listening (听力)'),
  readingCloze('reading_cloze', 'Fill in the blank (选词填空)'),
  pictureSentence('picture_sentence', 'Picture + keyword sentence'),
  typeHanzi('type_hanzi', 'Type the hanzi (写汉字)'),
  // Build 2A: T1 type the pinyin (keys checked on the server, half credit
  // for tones) and T5 free writing (always marked by a teacher).
  typePinyin('type_pinyin', 'Type the pinyin (写拼音)'),
  essay('essay', 'Free writing (写作)');

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
      case ExerciseType.typePinyin:
      case ExerciseType.essay:
        return true;
    }
  }

  /// Answered by typing (a text field in the player).
  bool get isTyped =>
      this == ExerciseType.typeHanzi ||
      this == ExerciseType.typePinyin ||
      this == ExerciseType.pictureSentence ||
      this == ExerciseType.essay;

  /// Marked by a teacher, never by the machine (T5).
  bool get isTeacherMarked =>
      this == ExerciseType.pictureSentence || this == ExerciseType.essay;
}
