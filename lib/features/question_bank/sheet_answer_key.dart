import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/answer_key_parser.dart';
import '../../l10n/l10n.dart';
import '../../models/exercise_type.dart';
import '../../models/question_bank_item.dart';
import '../../services/firestore_service.dart';

/// The worksheet's **Answer key** dialog: the admin types or pastes the
/// printed key; numbers follow the sheet order. Choice questions take a
/// letter (`1 D`, `11 √`, `41-45 ECBAD`); since Build 1B the writing
/// questions take their answer too: `71 书被妹妹拿走了` puts that
/// question's words in the order of the sentence, `76 长` sets the
/// accepted character. Returns how many questions changed (null when
/// cancelled).
Future<int?> showSheetAnswerKeyDialog(
  BuildContext context,
  QuestionBankSheet sheet,
) async {
  final l = context.l10n;
  final controller = TextEditingController();
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
