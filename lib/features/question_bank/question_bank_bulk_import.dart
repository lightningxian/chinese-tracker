import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../l10n/l10n.dart';
import '../../l10n/labels_exercises.dart';
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
  final l = context.l10n;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        title: Text(l.bankImportPasteTitle),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l.bankImportPasteHint),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  minLines: 8,
                  maxLines: 14,
                  decoration: InputDecoration(
                    hintText: l.bankImportPasteExample,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ExerciseType>(
                  initialValue: type,
                  decoration: InputDecoration(labelText: l.bankImportType),
                  items: [
                    for (final t in ExerciseType.values)
                      if (t.isImplemented)
                        DropdownMenuItem(value: t, child: Text(t.localized(l))),
                  ],
                  onChanged: (v) => setLocal(() => type = v ?? type),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: level,
                  decoration: InputDecoration(labelText: l.bankFiltersLevel),
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
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.bankImportImport),
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
      SnackBar(content: Text(l.bankImportNoneParsed)),
    );
    return;
  }

  await confirmAndInsertQuestionBankItems(context, ownerId: ownerId, items: items);
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
  final l = context.l10n;
  final set = Map<String, dynamic>.from(jsonDecode(raw) as Map);
  final all = QuestionBankImportUtils.fromQuestionSet(set, ownerId: ownerId);
  final deduped = QuestionBankImportUtils.dedupeAgainstBank(all, existingBank);
  if (deduped.novel.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.bankImportAllSamplesPresent)),
    );
    return;
  }
  await confirmAndInsertQuestionBankItems(
    context,
    ownerId: ownerId,
    items: deduped.novel,
    summary: l.bankImportSampleSummary(
      '${set['name']}',
      all.length,
      deduped.skipped > 0 ? l.bankImportSampleSkipped(deduped.skipped) : '',
    ),
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
      SnackBar(content: Text(context.l10n.bankImportNothingToImport)),
    );
    return null;
  }
  // The same sheet may already be in the bank (scanned before, or loaded
  // from the sample set): the review offers to replace it.
  final existing =
      await context.read<FirestoreService>().watchQuestionBank(ownerId).first;
  if (!context.mounted) return null;
  final added = await confirmAndInsertQuestionBankItems(
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
Future<List<QuestionBankItem>?> confirmAndInsertQuestionBankItems(
  BuildContext context, {
  required String ownerId,
  required List<QuestionBankItem> items,
  String? summary,
  List<QuestionBankItem> existingBank = const [],
}) async {
  final l = context.l10n;
  final decision = await Navigator.of(context).push<QuestionBankImportDecision>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => QuestionBankImportReviewScreen(
        items: items,
        summary: summary ?? l.bankImportParsedFromPaste(items.length),
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
    final questions = l.bankTextQuestionCount(confirmed.length);
    final replaced = decision.replaceIds.isNotEmpty;
    final message = sheets.length == 1 && sheets.first.isSheet
        ? (replaced
            ? l.bankImportReplacedSheet(sheets.first.code, questions)
            : l.bankImportAddedSheet(sheets.first.code, questions))
        : (replaced
            ? l.bankImportReplacedQuestions(questions)
            : l.bankImportAddedQuestions(questions));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    return confirmed;
  } catch (e) {
    if (!context.mounted) return null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.bankImportCouldNotImport('$e'))),
    );
    return null;
  }
}
