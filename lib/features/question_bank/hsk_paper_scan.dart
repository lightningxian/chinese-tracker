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
import '../../services/hsk_paper/paper_draft_service.dart';
import '../../services/question_bank_media_service.dart';
import '../teacher/widgets/worksheet_import_progress_dialog.dart';
import '../teacher/worksheet_scan_flow.dart';
import 'hsk_paper_proofread_screen.dart';
import 'question_bank_bulk_import.dart';
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
  final reader = HskPaperReader();
  try {
    pages = await reader.readPdf(
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
  debugPrint('HSK paper reader: ${pages.length} pages in $readSeconds s '
      '(${reader.engineUsed})');
  if (!context.mounted) return null;
  Navigator.of(context, rootNavigator: true).pop();

  final draft = HskPaperImport.draftFrom(pages);
  if (draft.slots.isEmpty) {
    // Not an HSK paper (no `第 a-b 题` blocks): one of the centre's own
    // worksheets (fill in, true/false, word order…). The worksheet reader
    // knows those forms (docs/WORKSHEET_FORMS.md), so the same file goes
    // there instead of stopping here.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.paperReadAsWorksheet)),
    );
    final result =
        await reviewWorksheetFile(context, bytes: bytes, fileName: file.name);
    if (result == null || !context.mounted) return null;
    final codes = await addReviewedWorksheetToBank(
      context,
      ownerId: ownerId,
      result: result,
    );
    return codes == null || codes.isEmpty ? null : codes.first;
  }
  final vm = HskPaperProofreadViewModel(
    pages: pages,
    draft: draft,
    pdfBytes: bytes,
    fileName: file.name,
    readSeconds: readSeconds,
    engine: reader.engineUsed,
  );
  return _proofreadAndSave(context, vm, ownerId: ownerId, readSeconds: readSeconds);
}

/// Owner 2026-11-24: opens an unfinished scan again (no reading: the pages
/// are drawn from its PDF) on the proofreading screen.
Future<String?> resumePaperDraft(
  BuildContext context, {
  required String ownerId,
  required String draftId,
}) async {
  final l = context.l10n;
  final progress = ValueNotifier(WorksheetImportStage.reading(0, detail: l.paperOpening));
  unawaited(showWorksheetImportProgress(
    context: context,
    fileName: l.paperDraftsTitle,
    progress: progress,
  ));
  LoadedPaperDraft loaded;
  try {
    loaded = await PaperDraftService().load(draftId, onPage: (page, count) {
      progress.value = WorksheetImportStage.reading(
        (page - 1) / count,
        detail: l.paperReadingPage(page, count),
      );
    });
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.paperReadFailed('$e'))));
    }
    return null;
  }
  if (!context.mounted) return null;
  Navigator.of(context, rootNavigator: true).pop();
  final vm = HskPaperProofreadViewModel(
    pages: loaded.pages,
    draft: loaded.draft,
    pdfBytes: loaded.pdfBytes,
    fileName: loaded.fileName,
    readSeconds: loaded.readSeconds,
    engine: loaded.engine,
  )
    ..draftId = loaded.id
    ..edited.addAll(loaded.edited)
    ..drawnBoxes.addAll(loaded.drawnBoxes);
  return _proofreadAndSave(context, vm, ownerId: ownerId, readSeconds: loaded.readSeconds);
}

Future<String?> _proofreadAndSave(
  BuildContext context,
  HskPaperProofreadViewModel vm, {
  required String ownerId,
  required int readSeconds,
}) async {
  final l = context.l10n;
  final media = context.read<QuestionBankMediaService>();
  // Owner 2026-11-24: over the whole window (inside the admin frame its
  // right side, with Save, fell off the screen).
  final result = await Navigator.of(context, rootNavigator: true).push<HskProofreadResult>(
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
  if (result == null || !context.mounted) {
    vm.dispose();
    return null;
  }

  final firestore = context.read<FirestoreService>();
  try {
    await firestore.addQuestionBankItems(result.items);
  } catch (e) {
    // Owner 2026-11-24: keep the work when the bank refuses the save.
    final draftId = vm.draftId;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        duration: const Duration(seconds: 12),
        content: Text(l.paperBankSaveFailed('$e')),
      ));
    }
    debugPrint('HSK paper reader: bank save failed: $e (draft $draftId)');
    return null;
  }
  final draftId = vm.draftId;
  if (draftId != null) {
    try {
      await PaperDraftService().delete(draftId);
    } catch (_) {
      // The draft stays in the list; it can be deleted there.
    }
  }
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


/// Owner 2026-11-24: **Unfinished scans**: open a draft again or delete it.
Future<void> showPaperDrafts(BuildContext context, {required String ownerId}) async {
  final l = context.l10n;
  final service = PaperDraftService();
  final picked = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.paperDraftsTitle),
      content: SizedBox(
        width: 560,
        child: StreamBuilder<List<PaperDraftInfo>>(
          stream: service.watchDrafts(),
          builder: (ctx, snap) {
            final list = snap.data ?? const <PaperDraftInfo>[];
            if (!snap.hasData) return const LinearProgressIndicator();
            if (list.isEmpty) return Text(l.paperDraftsNone);
            return ListView(
              shrinkWrap: true,
              children: [
                for (final d in list)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.description_outlined),
                    title: Text(d.code.isEmpty ? d.fileName : '${d.code} · ${d.fileName}'),
                    subtitle: Text(l.paperDraftLine(
                      d.questions,
                      d.toCheck,
                      d.answered,
                      d.savedAt == null ? '' : MaterialLocalizations.of(ctx).formatShortDate(d.savedAt!),
                    )),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          tooltip: l.timetableDelete,
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: ctx,
                              builder: (c2) => AlertDialog(
                                title: Text(l.paperDraftDeleteTitle),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(c2, false),
                                      child: Text(l.commonCancel)),
                                  FilledButton(
                                      onPressed: () => Navigator.pop(c2, true),
                                      child: Text(l.timetableDelete)),
                                ],
                              ),
                            );
                            if (ok == true) await service.delete(d.id);
                          },
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, d.id),
                          child: Text(l.paperDraftOpen),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.teacherAttClose)),
      ],
    ),
  );
  if (picked == null || !context.mounted) return;
  await resumePaperDraft(context, ownerId: ownerId, draftId: picked);
}
