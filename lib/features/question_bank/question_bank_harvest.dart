import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../models/exercise.dart';
import '../../models/question_bank_item.dart';
import '../../services/firestore_service.dart';
import 'question_bank_import_utils.dart';

/// Harvest questions from existing exercises into the bank (with dedupe).
Future<void> showQuestionBankHarvestFromExercises(
  BuildContext context, {
  required String ownerId,
  required List<QuestionBankItem> existingBank,
}) async {
  final firestore = context.read<FirestoreService>();
  final l = context.l10n;

  if (!context.mounted) return;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  List<Exercise> exercises;
  try {
    exercises = await firestore.watchAllExercises().first;
  } catch (e) {
    if (context.mounted) Navigator.pop(context);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.bankHarvestCouldNotLoad('$e'))),
      );
    }
    return;
  }

  if (context.mounted) Navigator.pop(context);

  final candidates = <QuestionBankItem>[];
  for (final ex in exercises) {
    candidates.addAll(
      QuestionBankImportUtils.fromExerciseQuestions(
        ownerId: ownerId,
        exerciseId: ex.id,
        type: ex.type,
        questions: ex.questions,
        skillCategory: ex.skillCategory,
        level: ex.level,
      ),
    );
  }

  final deduped = QuestionBankImportUtils.dedupeAgainstBank(
    candidates,
    existingBank,
  );

  if (!context.mounted) return;

  if (deduped.novel.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.bankHarvestNoNew(deduped.skipped))),
    );
    return;
  }

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.bankHarvestTitle),
      content: Text(l.bankHarvestFound(deduped.novel.length, deduped.skipped)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l.bankHarvestImportCount(deduped.novel.length)),
        ),
      ],
    ),
  );

  if (ok != true || !context.mounted) return;

  try {
    await firestore.addQuestionBankItems(deduped.novel);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.bankHarvestImported(deduped.novel.length))),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.worksheetImportFailed('$e'))),
    );
  }
}
