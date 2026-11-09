import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../models/exercise_type.dart';
import '../../models/question_bank_item.dart';
import '../../services/firestore_service.dart';
import '../teacher/worksheet_scan_flow.dart';
import 'question_bank_import_review.dart';
import 'question_bank_import_utils.dart';

/// Paste-text bulk import into the question bank.
Future<void> showQuestionBankPasteImport(
  BuildContext context, {
  required String ownerId,
}) async {
  final controller = TextEditingController();
  ExerciseType type = ExerciseType.multipleChoice;
  String level = AppConstants.hskLevels.first;

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

/// The centre's ten sample sheets (CONTOH LATIHAN SOAL), scanned and keyed,
/// bundled with the app. Loads them into the bank, skipping questions that
/// are already there.
Future<void> runQuestionBankSampleSetImport(
  BuildContext context, {
  required String ownerId,
  required List<QuestionBankItem> existingBank,
}) async {
  final raw = await rootBundle
      .loadString('assets/question_sets/contoh_latihan_soal.json');
  if (!context.mounted) return;
  final set = Map<String, dynamic>.from(jsonDecode(raw) as Map);
  final all = QuestionBankImportUtils.fromQuestionSet(set, ownerId: ownerId);
  final deduped = QuestionBankImportUtils.dedupeAgainstBank(all, existingBank);
  if (deduped.novel.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All sample questions are already in the bank.'),
      ),
    );
    return;
  }
  await _confirmAndInsert(
    context,
    ownerId: ownerId,
    items: deduped.novel,
    summary: '${set['name']}: ${all.length} questions from 10 sheets with '
        'answer keys${deduped.skipped > 0 ? ', ${deduped.skipped} already in the bank' : ''}. '
        'Pictures for the 看图写句子 keywords are added in the editor.',
  );
}

/// Worksheet file bulk import into the question bank: scan, review what was
/// detected (type + answer per question), then add. Returns the sheet codes
/// that went into the bank (one for a coded sheet), or null when nothing was
/// added.
Future<List<String>?> runQuestionBankWorksheetImport(
  BuildContext context, {
  required String ownerId,
}) async {
  final result = await scanWorksheet(context);
  if (result == null || !context.mounted) return null;

  final items = QuestionBankImportUtils.fromParseResult(
    result: result.parseResult!,
    ownerId: ownerId,
    typeOverride: result.selectedType,
  );
  if (items.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No questions to import.')),
    );
    return null;
  }
  // The same sheet may already be in the bank (scanned before, or loaded
  // from the sample set): the review offers to replace it.
  final existing =
      await context.read<FirestoreService>().watchQuestionBank(ownerId).first;
  if (!context.mounted) return null;
  final added = await _confirmAndInsert(
    context,
    ownerId: ownerId,
    items: items,
    summary: result.parseResult!.detectionSummary,
    existingBank: existing,
  );
  if (added == null) return null;
  return {
    for (final sheet in QuestionBankSheet.group(added))
      if (sheet.isSheet) sheet.key!,
  }.toList();
}

/// Returns the questions that were written, or null when cancelled/failed.
Future<List<QuestionBankItem>?> _confirmAndInsert(
  BuildContext context, {
  required String ownerId,
  required List<QuestionBankItem> items,
  String? summary,
  List<QuestionBankItem> existingBank = const [],
}) async {
  final decision = await Navigator.of(context).push<QuestionBankImportDecision>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => QuestionBankImportReviewScreen(
        items: items,
        summary: summary ??
            '${items.length} question${items.length == 1 ? '' : 's'} parsed '
                'from the pasted text.',
        existingBank: existingBank,
      ),
    ),
  );
  if (decision == null || decision.items.isEmpty || !context.mounted) {
    return null;
  }
  final confirmed = decision.items;

  try {
    final firestore = context.read<FirestoreService>();
    if (decision.replaceIds.isNotEmpty) {
      await firestore.deleteQuestionBankItems(decision.replaceIds);
    }
    await firestore.addQuestionBankItems(confirmed);
    if (!context.mounted) return confirmed;
    final sheets = QuestionBankSheet.group(confirmed);
    final n = confirmed.length;
    final verb = decision.replaceIds.isNotEmpty ? 'Replaced' : 'Added';
    final what = sheets.length == 1 && sheets.first.isSheet
        ? 'worksheet ${sheets.first.code} ($n question${n == 1 ? '' : 's'})'
        : '$n question${n == 1 ? '' : 's'}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$verb $what in the bank.')),
    );
    return confirmed;
  } catch (e) {
    if (!context.mounted) return null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not import: $e')),
    );
    return null;
  }
}
