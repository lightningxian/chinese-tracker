import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/worksheet_import_platform.dart';
import '../../models/exercise_type.dart';
import '../../models/question_bank_item.dart';
import '../../models/question_difficulty.dart';
import '../../models/worksheet_import_stage.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/worksheet_import_service.dart';
import '../teacher/worksheet_import_review_screen.dart';
import '../teacher/widgets/worksheet_import_progress_dialog.dart';
import 'question_bank_import_utils.dart';

/// Paste-text bulk import into the question bank.
Future<void> showQuestionBankPasteImport(
  BuildContext context, {
  required String ownerId,
}) async {
  final controller = TextEditingController();
  ExerciseType type = ExerciseType.multipleChoice;
  String level = AppConstants.hskLevels.first;
  QuestionDifficulty difficulty = QuestionDifficulty.medium;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        title: const Text('Paste questions'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Paste worksheet text (numbered questions + A/B/C/D options).',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  minLines: 8,
                  maxLines: 14,
                  decoration: const InputDecoration(
                    hintText: '1. 你好 means…\nA. hello\nB. goodbye',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ExerciseType>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: [
                    for (final t in ExerciseType.values)
                      if (t.isImplemented)
                        DropdownMenuItem(value: t, child: Text(t.label)),
                  ],
                  onChanged: (v) => setLocal(() => type = v ?? type),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: level,
                  decoration: const InputDecoration(labelText: 'Level'),
                  items: [
                    for (final l in AppConstants.hskLevels)
                      DropdownMenuItem(value: l, child: Text(l)),
                  ],
                  onChanged: (v) => setLocal(
                    () => level = v ?? AppConstants.hskLevels.first,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<QuestionDifficulty>(
                  initialValue: difficulty,
                  decoration: const InputDecoration(labelText: 'Difficulty'),
                  items: [
                    for (final d in QuestionDifficulty.values)
                      DropdownMenuItem(value: d, child: Text(d.label)),
                  ],
                  onChanged: (v) => setLocal(
                    () => difficulty = v ?? QuestionDifficulty.medium,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Import'),
          ),
        ],
      ),
    ),
  );

  if (confirmed != true || !context.mounted) {
    controller.dispose();
    return;
  }

  final items = QuestionBankImportUtils.fromPasteText(
    text: controller.text,
    ownerId: ownerId,
    type: type,
    level: level,
    difficulty: difficulty,
  );
  controller.dispose();

  if (items.isEmpty) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No questions could be parsed.')),
    );
    return;
  }

  await _confirmAndInsert(context, ownerId: ownerId, items: items);
}

/// Worksheet file bulk import into the question bank.
Future<void> runQuestionBankWorksheetImport(
  BuildContext context, {
  required String ownerId,
}) async {
  final user = context.read<AuthService>().appUser;
  if (!WorksheetImportPlatform.isSupportedFor(user)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(WorksheetImportPlatform.unsupportedMessage)),
    );
    return;
  }

  final picked = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: WorksheetImportService.allowedExtensions.toList(),
    withData: true,
  );
  if (picked == null || picked.files.isEmpty || !context.mounted) return;

  final file = picked.files.first;
  final bytes = file.bytes;
  if (bytes == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not read the selected file.')),
    );
    return;
  }

  final progress = ValueNotifier(WorksheetImportStage.prepare());
  unawaited(
    showWorksheetImportProgress(
      context: context,
      fileName: file.name,
      progress: progress,
    ),
  );

  try {
    final text = await context.read<WorksheetImportService>().extractTextFromWorksheet(
          bytes: bytes,
          fileName: file.name,
          onProgress: (s) => progress.value = s,
        );
    progress.value = WorksheetImportStage.analyze();
    if (!context.mounted) return;
    Navigator.of(context).pop();

    final result = await Navigator.of(context).push<WorksheetImportReviewResult>(
      MaterialPageRoute(
        builder: (_) => WorksheetImportReviewScreen(
          extractedText: text,
          fileName: file.name,
        ),
      ),
    );
    if (result == null ||
        result.action != WorksheetImportReviewAction.importQuestions ||
        result.parseResult == null ||
        !context.mounted) {
      return;
    }

    final items = QuestionBankImportUtils.fromParseResult(
      result: result.parseResult!,
      ownerId: ownerId,
      typeOverride: result.selectedType,
    );
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No questions to import.')),
      );
      return;
    }
    await _confirmAndInsert(context, ownerId: ownerId, items: items);
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).popUntil(
        (route) => route is! PopupRoute || route.isFirst,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    }
  }
}

Future<void> _confirmAndInsert(
  BuildContext context, {
  required String ownerId,
  required List<QuestionBankItem> items,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Add to bank?'),
      content: Text('Import ${items.length} question(s) into the bank?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Import'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;

  try {
    await context.read<FirestoreService>().addQuestionBankItems(items);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added ${items.length} question(s) to the bank.')),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not import: $e')),
    );
  }
}
