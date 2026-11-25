import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/answer_key_parser.dart';
import '../../core/utils/question_import_utils.dart';
import '../../l10n/l10n.dart';
import '../../models/exercise_type.dart';
import '../../models/question_bank_item.dart';
import '../../services/firestore_service.dart';

/// The worksheet's **Answer key** dialog: the admin types or pastes the
/// printed key; numbers follow the sheet order. Choice questions take a
/// letter (`1 D`, `11 √`, `41-45 ECBAD`); since Build 1B the writing
/// questions take their answer too: `71 书被妹妹拿走了` puts that
/// question's words in the order of the sentence, `76 长` sets the
/// accepted character. Owner 2026-11-24: the box opens filled with the
/// answers the worksheet already has ([SheetAnswerKeyPlan.keyText]), so the
/// admin only corrects what is wrong. Returns how many questions changed
/// (null when cancelled).
Future<int?> showSheetAnswerKeyDialog(
  BuildContext context,
  QuestionBankSheet sheet,
) async {
  final l = context.l10n;
  final controller = TextEditingController(text: SheetAnswerKeyPlan.keyText(sheet));
  final text = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.bankSheetAnswerKey),
      content: SizedBox(
        width: 460,
        child: TextField(
          controller: controller,
          autofocus: true,
          minLines: 4,
          maxLines: 12,
          decoration: InputDecoration(
            hintText: '1 D 2 A 3 C\n11 √ 12 ×\n41-45 ECBAD\n71 我们一起去吧\n76 长',
            helperText: '${l.bankSheetAnswerKeyHint} ${l.paperAnswerKeyWrittenHint}',
            helperMaxLines: 4,
            border: const OutlineInputBorder(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text),
          child: Text(l.bankSheetAnswerKeyApply),
        ),
      ],
    ),
  );
  controller.dispose();
  if (text == null || !context.mounted) return null;

  final choices = AnswerKeyParser.parse(text);
  final written = AnswerKeyParser.parseWritten(text);
  final messenger = ScaffoldMessenger.of(context);
  if (choices.isEmpty && written.isEmpty) {
    messenger.showSnackBar(SnackBar(content: Text(l.bankSheetAnswerKeyNone)));
    return 0;
  }
  final plan = SheetAnswerKeyPlan.of(sheet, choices: choices, written: written);
  final firestore = context.read<FirestoreService>();
  await firestore.updateQuestionBankAnswers(plan.indexes);
  await firestore.updateQuestionBankWrittenKeys(plan.fields);
  final changed = plan.indexes.length + plan.fields.length;
  messenger.showSnackBar(SnackBar(
    content: Text(plan.notMatched.isEmpty
        ? l.bankSheetAnswerKeyApplied(changed)
        : '${l.bankSheetAnswerKeyApplied(changed)} '
            '${l.paperAnswerKeyNotMatched(plan.notMatched.join(', '))}'),
  ));
  return changed;
}

/// What an answer key changes on a sheet (pure, unit tested).
class SheetAnswerKeyPlan {
  const SheetAnswerKeyPlan({
    required this.indexes,
    required this.fields,
    required this.notMatched,
  });

  /// Question id → index of the right choice.
  final Map<String, int> indexes;

  /// Question id → fields of a written answer.
  final Map<String, Map<String, Object>> fields;

  /// Numbers whose sentence does not use exactly that question's words.
  final List<int> notMatched;

  /// The key as the worksheet holds it now, in the format the dialog reads
  /// back: choice letters five per line (`1 D  2 A  3 C …`), true/false as
  /// √ / ×, then one line per writing answer (`71 我们一起去吧`, `76 长`).
  /// Free writing has no key and is left out. Applying this text unchanged
  /// changes nothing.
  static String keyText(QuestionBankSheet sheet) {
    final choices = <String>[];
    final written = <String>[];
    for (var i = 0; i < sheet.items.length; i++) {
      final item = sheet.items[i];
      final q = item.question;
      final n = i + 1;
      switch (item.type) {
        case ExerciseType.multipleChoice ||
              ExerciseType.listening ||
              ExerciseType.matching ||
              ExerciseType.readingCloze:
          if (q.correctIndex < 0 || q.correctIndex >= q.options.length) continue;
          final trueFalse = q.options.length == 2 &&
              q.options.join() == QuestionImportUtils.trueFalseOptions.join();
          final mark = trueFalse
              ? (q.correctIndex == 0 ? '√' : '×')
              : String.fromCharCode(65 + q.correctIndex);
          choices.add('$n $mark');
        case ExerciseType.composeSentences:
          if (q.segments.length > 1) written.add('$n ${q.segments.join()}');
        case ExerciseType.typeHanzi:
          final first = q.options.where((o) => o.trim().isNotEmpty).firstOrNull;
          if (first != null) written.add('$n ${first.trim()}');
        case ExerciseType.fillBlanks:
          // One answer per blank, `|` between blanks.
          if (q.options.isNotEmpty) written.add('$n ${q.options.join(' | ')}');
        default:
          break;
      }
    }
    final lines = <String>[
      for (var i = 0; i < choices.length; i += 5)
        choices.sublist(i, (i + 5).clamp(0, choices.length)).join('  '),
      ...written,
    ];
    return lines.join('\n');
  }

  static SheetAnswerKeyPlan of(
    QuestionBankSheet sheet, {
    required Map<int, int> choices,
    required Map<int, String> written,
  }) {
    final indexes = <String, int>{};
    for (final entry in choices.entries) {
      final index = entry.key - 1;
      if (index < 0 || index >= sheet.items.length) continue;
      final item = sheet.items[index];
      final usesIndex = switch (item.type) {
        ExerciseType.multipleChoice ||
        ExerciseType.listening ||
        ExerciseType.matching ||
        ExerciseType.readingCloze =>
          true,
        _ => false,
      };
      if (!usesIndex || entry.value >= item.question.options.length) continue;
      if (item.question.correctIndex != entry.value) {
        indexes[item.id] = entry.value;
      }
    }
    final fields = <String, Map<String, Object>>{};
    final notMatched = <int>[];
    for (final entry in written.entries) {
      final index = entry.key - 1;
      if (index < 0 || index >= sheet.items.length) continue;
      final item = sheet.items[index];
      switch (item.type) {
        case ExerciseType.composeSentences:
          final ordered = AnswerKeyParser.orderSegments(
              item.question.segments, entry.value);
          if (ordered == null) {
            notMatched.add(entry.key);
          } else {
            fields[item.id] = {'question.segments': ordered};
          }
        case ExerciseType.typeHanzi:
          fields[item.id] = {'question.options': [entry.value.trim()]};
        case ExerciseType.fillBlanks:
          final answers = [
            for (final a in entry.value.split(RegExp(r'\s*[|｜]\s*')))
              if (a.trim().isNotEmpty) a.trim(),
          ];
          // One answer per blank, as the player draws them; else it is
          // listed as not matched and nothing is changed.
          final blanks =
              ExerciseType.blankMark.allMatches(item.question.prompt).length;
          if (answers.length != blanks) {
            notMatched.add(entry.key);
          } else {
            fields[item.id] = {'question.options': answers};
          }
        default:
          break;
      }
    }
    return SheetAnswerKeyPlan(
      indexes: indexes,
      fields: fields,
      notMatched: notMatched,
    );
  }
}
