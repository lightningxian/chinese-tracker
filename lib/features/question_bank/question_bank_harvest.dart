import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
        SnackBar(content: Text('Could not load exercises: $e')),
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
      SnackBar(
        content: Text(
          'No new questions — ${deduped.skipped} already in the bank.',
        ),
      ),
    );
    return;
  }

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Import from exercises'),
      content: Text(
        'Found ${deduped.novel.length} new question(s).\n'
        '${deduped.skipped} already in the bank (skipped).',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text('Import ${deduped.novel.length}'),
        ),
      ],
    ),
  );

  if (ok != true || !context.mounted) return;

  try {
    await firestore.addQuestionBankItems(deduped.novel);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Imported ${deduped.novel.length} question(s) from exercises.'),
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Import failed: $e')),
    );
  }
}
