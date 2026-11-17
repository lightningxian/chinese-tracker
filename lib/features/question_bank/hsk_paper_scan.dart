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
import '../../services/hsk_paper/hsk_paper_import.dart';
import '../../services/hsk_paper/hsk_paper_reader.dart';
import '../../services/question_bank_media_service.dart';
import '../teacher/widgets/worksheet_import_progress_dialog.dart';
import 'hsk_paper_proofread_screen.dart';
import 'sheet_answer_key.dart';

/// **Scan paper** (Build 1B): the built-in reader. The admin picks the
/// paper's PDF; every page is read in the browser (nothing leaves the
/// computer); the proofreading screen shows what was read against the
/// format; saving makes one worksheet in the bank; the answer key is
/// offered right after. Admin, web only. Returns the sheet code, or null.
Future<String?> runHskPaperScan(
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
    allowedExtensions: const ['pdf'],
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
    WorksheetImportStage.reading(0, detail: l.paperOpening),
  );
  unawaited(showWorksheetImportProgress(
    context: context,
    fileName: file.name,
    progress: progress,
  ));
  final started = DateTime.now();
  List<PaperPage> pages;
  try {
    pages = await HskPaperReader().readPdf(
      bytes,
      onProgress: (fraction, page, count) {
        progress.value = WorksheetImportStage.reading(
          fraction,
          detail: l.paperReadingPage(page, count),
        );
      },
    );
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.paperReadFailed('$e'))),
      );
    }
    return null;
  }
  final readSeconds = DateTime.now().difference(started).inSeconds;
  debugPrint('HSK paper reader: ${pages.length} pages in $readSeconds s');
  if (!context.mounted) return null;
  Navigator.of(context, rootNavigator: true).pop();

  final draft = HskPaperImport.draftFrom(pages);
  if (draft.slots.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.paperNothingFound)),
    );
    return null;
  }
  final media = context.read<QuestionBankMediaService>();
  final vm = HskPaperProofreadViewModel(
    pages: pages,
    draft: draft,
    pdfBytes: bytes,
    fileName: file.name,
  );
  final result = await Navigator.of(context).push<HskProofreadResult>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => HskPaperProofreadScreen(
        viewModel: vm,
        ownerId: ownerId,
        upload: (png, name) => media.uploadBytes(
          ownerId,
          png,
          fileName: name,
          contentType: 'image/png',
        ),
      ),
    ),
  );
  vm.dispose();
  if (result == null || !context.mounted) return null;

  final firestore = context.read<FirestoreService>();
  await firestore.addQuestionBankItems(result.items);
  final code = result.items.isEmpty ? null : result.items.first.sheetCode;
  debugPrint('HSK paper reader: saved ${result.items.length} questions; '
      '${result.untouched} of ${result.total} needed no correction; '
      'proofreading ${result.duration.inMinutes} min ${result.duration.inSeconds % 60} s');
  if (!context.mounted) return code;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    duration: const Duration(seconds: 8),
    content: Text(l.paperSaved(
      result.items.length,
      result.untouched,
      result.total,
      result.duration.inMinutes,
      readSeconds,
    )),
  ));

  // The answer key right away (the paper prints none).
  final now = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.paperKeyNowTitle),
      content: Text(l.paperKeyNowBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l.paperLater),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l.bankSheetAnswerKey),
        ),
      ],
    ),
  );
  if (now != true || code == null || !context.mounted) return code;
  final bank = await firestore.watchQuestionBank(ownerId).first;
  final sheet = QuestionBankSheet.group(bank)
      .where((s) => s.key == code)
      .firstOrNull;
  if (sheet != null && context.mounted) {
    await showSheetAnswerKeyDialog(context, sheet);
  }
  return code;
}
