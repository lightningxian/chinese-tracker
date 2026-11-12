import '../../l10n/l10n.dart';
import '../../models/exercise_type.dart';
import '../../models/question_bank_item.dart';

/// One-line wording shared by the bank screens.
abstract final class QuestionBankText {
  /// What the student will have to get right, as stored in the bank.
  static String answerLine(AppLocalizations l, QuestionBankItem item) {
    final q = item.question;
    switch (item.type) {
      case ExerciseType.composeSentences:
        return l.bankTextOrder(q.segments.join(' / '));
      case ExerciseType.matching:
      case ExerciseType.readingCloze:
        final letter = String.fromCharCode(65 + q.correctIndex);
        final word = q.correctIndex < q.options.length
            ? ' ${q.options[q.correctIndex]}'
            : '';
        return l.bankTextAnswer('$letter$word');
      case ExerciseType.typeHanzi:
        return l.bankTextPinyin(
          q.keyword,
          q.options.isEmpty
              ? l.bankTextTypeHanziInEditor
              : q.options.join(' / '),
        );
      case ExerciseType.pictureSentence:
        return l.bankTextKeyword(q.keyword);
      case ExerciseType.multipleChoice:
      case ExerciseType.listening:
        if (q.options.isEmpty) return l.bankTextNoOptionsYet;
        return [
          for (var i = 0; i < q.options.length; i++)
            '${i == q.correctIndex ? '✓ ' : ''}${String.fromCharCode(65 + i)}. ${q.options[i]}',
        ].join('   ');
    }
  }

  /// "7 questions", "1 question".
  static String questionCount(AppLocalizations l, int n) =>
      l.bankTextQuestionCount(n);
}
