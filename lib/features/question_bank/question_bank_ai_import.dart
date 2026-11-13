import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/worksheet_import_platform.dart';
import '../../l10n/l10n.dart';
import '../../models/question_bank_item.dart';
import '../../models/worksheet_import_stage.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/question_bank_media_service.dart';
import '../../services/worksheet_ai_import_service.dart';
import '../../services/worksheet_import_service.dart';
import '../../services/worksheet_page_images.dart';
import '../teacher/widgets/worksheet_import_progress_dialog.dart';
import 'question_bank_ai_import_utils.dart';
import 'question_bank_bulk_import.dart';

/// Scan a paper with the AI reader: pick a PDF or image, let Gemini read
/// every question (typed, in parts, keyed where it can), cut out the
/// pictures it found and upload them, then the usual review screen before
/// the worksheet enters the bank. Admin, web only. Returns the sheet codes
/// added, or null when cancelled or failed.
Future<List<String>?> runQuestionBankAiImport(
  BuildContext context, {
  required String ownerId,
}) async {
  final l = context.l10n;
  final user = context.read<AuthService>().appUser;
  if (!WorksheetImportPlatform.isSupportedFor(user)) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.worksheetUploadUnsupported)),
    );
    return null;
  }

  final picked = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
    withData: true,
  );
  if (picked == null || picked.files.isEmpty || !context.mounted) return null;
  final file = picked.files.first;
  final bytes = file.bytes;
  if (bytes == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.worksheetCouldNotReadFile)),
    );
    return null;
  }

  final progress = ValueNotifier(
    WorksheetImportStage.reading(0.05, detail: l.aiImportSending),
  );
  unawaited(showWorksheetImportProgress(
    context: context,
    fileName: file.name,
    progress: progress,
  ));

  List<QuestionBankItem> items;
  AiImportSummary summary;
  try {
    final service = context.read<WorksheetAiImportService>();
    final media = context.read<QuestionBankMediaService>();
    progress.value =
        WorksheetImportStage.reading(0.15, detail: l.aiImportReading);
    final worksheet = await service.read(bytes: bytes, fileName: file.name);

    // Pictures: cut each distinct box out of the page once, upload it.
    final boxes = worksheet.boxes;
    final urls = <String, String>{};
    if (boxes.isNotEmpty) {
      final isPdf = file.name.toLowerCase().endsWith('.pdf');
      final pages = await WorksheetPageImages.open(bytes, isPdf: isPdf);
      try {
        var n = 0;
        final code = QuestionBankAiImportUtils.sheetCodeFor(worksheet, file.name);
        for (final entry in boxes.entries) {
          n++;
          progress.value = WorksheetImportStage(
            label: '',
            progress: 0.6 + (n / boxes.length) * 0.3,
            stepIndex: 2,
            detail: l.aiImportCropping(n, boxes.length),
          );
          try {
            final png = await pages.crop(entry.value);
            urls[entry.key] = await media.uploadBytes(
              ownerId,
              png,
              fileName: '${code}_${entry.key}.png',
              contentType: 'image/png',
            );
          } catch (e) {
            debugPrint('AI import: picture ${entry.key} skipped: $e');
          }
        }
      } finally {
        await pages.dispose();
      }
    }

    items = QuestionBankAiImportUtils.toBankItems(
      worksheet,
      ownerId: ownerId,
      imageUrls: urls,
      fileName: file.name,
    );
    summary = QuestionBankAiImportUtils.summarize(worksheet,
        pictures: urls.length);
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).popUntil(
        (route) => route is! PopupRoute || route.isFirst,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.aiImportFailed(formatUserFacingError(e)))),
      );
    }
    return null;
  }
  if (!context.mounted) return null;
  Navigator.of(context, rootNavigator: true).pop();

  if (items.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.aiImportNothingFound)),
    );
    return null;
  }
  final existing =
      await context.read<FirestoreService>().watchQuestionBank(ownerId).first;
  if (!context.mounted) return null;
  final added = await confirmAndInsertQuestionBankItems(
    context,
    ownerId: ownerId,
    items: items,
    summary: l.aiImportSummary(
      summary.level ?? '—',
      summary.questions,
      summary.sections,
      summary.pictures,
      summary.missingKeys,
    ),
    existingBank: existing,
  );
  if (added == null) return null;
  return {
    for (final sheet in QuestionBankSheet.group(added))
      if (sheet.isSheet) sheet.key!,
  }.toList();
}
