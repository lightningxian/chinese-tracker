import '../../models/exercise_type.dart';
import '../../models/question_bank_item.dart';

/// One-line wording shared by the bank screens.
abstract final class QuestionBankText {
  /// What the student will have to get right, as stored in the bank.
  static String answerLine(QuestionBankItem item) {
    final q = item.question;
    switch (item.type) {
      case ExerciseType.composeSentences:
        return 'Order: ${q.segments.join(' / ')}';
      case ExerciseType.matching:
      case ExerciseType.readingCloze:
        final letter = String.fromCharCode(65 + q.correctIndex);
        final word = q.correctIndex < q.options.length
            ? ' ${q.options[q.correctIndex]}'
            : '';
        return 'Answer: $letter$word';
      case ExerciseType.typeHanzi:
        return 'Pinyin ${q.keyword} → '
            '${q.options.isEmpty ? 'type the hanzi in the editor' : q.options.join(' / ')}';
      case ExerciseType.pictureSentence:
        return 'Keyword: ${q.keyword}';
      case ExerciseType.multipleChoice:
      case ExerciseType.listening:
        if (q.options.isEmpty) return 'No answer options read yet';
        return [
          for (var i = 0; i < q.options.length; i++)
            '${i == q.correctIndex ? '✓ ' : ''}${String.fromCharCode(65 + i)}. ${q.options[i]}',
        ].join('   ');
    }
  }

  /// "7 questions", "1 question".
  static String questionCount(int n) => '$n question${n == 1 ? '' : 's'}';
}
