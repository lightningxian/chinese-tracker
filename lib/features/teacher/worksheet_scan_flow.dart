import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/worksheet_import_platform.dart';
import '../../models/worksheet_import_stage.dart';
import '../../services/auth_service.dart';
import '../../services/worksheet_import_service.dart';
import 'widgets/worksheet_import_progress_dialog.dart';
import 'worksheet_import_review_screen.dart';

/// Pick a worksheet (PDF, Word, image), read it on the device, let the admin
/// review what the scanner detected, and return the confirmed result.
/// Returns null when the admin cancels or nothing could be read. Shared by
/// the question bank, the quiz editor and the exercise form.
Future<WorksheetImportReviewResult?> scanWorksheet(BuildContext context) async {
  final user = context.read<AuthService>().appUser;
  if (!WorksheetImportPlatform.isSupportedFor(user)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(WorksheetImportPlatform.unsupportedMessage)),
    );
    return null;
  }

  final picked = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: WorksheetImportService.allowedExtensions.toList(),
    withData: true,
  );
  if (picked == null || picked.files.isEmpty || !context.mounted) return null;

  final file = picked.files.first;
  final bytes = file.bytes;
  if (bytes == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not read the selected file.')),
    );
    return null;
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
    final text =
        await context.read<WorksheetImportService>().extractTextFromWorksheet(
              bytes: bytes,
              fileName: file.name,
              onProgress: (s) => progress.value = s,
            );
    progress.value = WorksheetImportStage.analyze();
    if (!context.mounted) return null;
    Navigator.of(context).pop();

    final result =
        await Navigator.of(context).push<WorksheetImportReviewResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => WorksheetImportReviewScreen(
          extractedText: text,
          fileName: file.name,
        ),
      ),
    );
    if (result == null ||
        result.action != WorksheetImportReviewAction.importQuestions ||
        result.parseResult == null) {
      return null;
    }
    return result;
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).popUntil(
        (route) => route is! PopupRoute || route.isFirst,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    }
    return null;
  }
}
