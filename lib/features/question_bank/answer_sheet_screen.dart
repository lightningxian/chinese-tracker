import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/answer_sheet_parser.dart';
import '../../core/utils/file_download.dart' as file_download;
import '../../core/widgets/app_card.dart';
import '../../core/widgets/discard_guard.dart';
import '../../l10n/l10n.dart';
import '../../l10n/labels_exercises.dart';
import '../../models/exercise_type.dart';
import '../../models/question_bank_item.dart';
import '../../services/answer_sheet_service.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import 'answer_sheet_check.dart';

/// The worksheet's **Answer sheet** card (owner 2026-11-26): upload the
/// answer PDF, open it again later, read it again, replace or remove it.
/// Admin on web only (the caller shows it when `canManageBank`).
class AnswerSheetCard extends StatelessWidget {
  const AnswerSheetCard({super.key, required this.sheet});

  final QuestionBankSheet sheet;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final file = sheet.answerSheet;
    final when = file?.uploadedAt;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Row(
        children: [
          Icon(Icons.fact_check_outlined, color: AppColors.navy),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.answerSheetTitle,
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy)),
                const SizedBox(height: 2),
                Text(
                  file == null
                      ? l.answerSheetNone
                      : l.answerSheetUploaded(
                          file.name, when == null ? '…' : DateFormat.yMMMd().format(when)),
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (file == null)
            FilledButton.icon(
              onPressed: () => checkAnswerSheet(context, sheet),
              icon: const Icon(Icons.upload_file_outlined, size: 18),
              label: Text(l.answerSheetUpload),
              style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
            )
          else ...[
            OutlinedButton.icon(
              onPressed: () => _open(context, file),
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: Text(l.answerSheetOpen),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => checkAnswerSheet(context, sheet, stored: file),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l.answerSheetReadAgain),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => checkAnswerSheet(context, sheet),
              icon: const Icon(Icons.upload_file_outlined, size: 18),
              label: Text(l.answerSheetReplace),
            ),
            IconButton(
              tooltip: l.answerSheetRemove,
              onPressed: () => _remove(context, file),
              icon: Icon(Icons.close, color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _open(BuildContext context, AnswerSheetFile file) async {
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    try {
      final bytes = await context.read<AnswerSheetService>().download(file.path);
      file_download.openBytesInNewTab(bytes, 'application/pdf');
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.answerSheetReadFailed('$e'))));
    }
  }

  Future<void> _remove(BuildContext context, AnswerSheetFile file) async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.answerSheetRemoveTitle),
        content: Text(l.answerSheetRemoveBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.commonCancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.answerSheetRemove),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    await context
        .read<FirestoreService>()
        .setQuestionBankAnswerSheet(sheet.items.map((i) => i.id), null);
    if (!context.mounted) return;
    await context.read<AnswerSheetService>().delete(file.path);
    messenger.showSnackBar(SnackBar(content: Text(l.answerSheetRemoved)));
  }
}

/// Picks a PDF (or loads the [stored] one), reads it on this computer and
/// opens the check screen.
Future<void> checkAnswerSheet(
  BuildContext context,
  QuestionBankSheet sheet, {
  AnswerSheetFile? stored,
}) async {
  final l = context.l10n;
  final service = context.read<AnswerSheetService>();
  final user = context.read<AuthService>().appUser;
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context, rootNavigator: true);
  final page = ValueNotifier<(int, int)>((0, 0));
  var dialogOpen = false;
  try {
    PickedAnswerSheet? picked;
    Uint8List bytes;
    if (stored == null) {
      picked = await service.pick(user);
      if (picked == null || !context.mounted) return;
      bytes = picked.bytes;
    } else {
      bytes = Uint8List(0);
    }
    dialogOpen = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(l.answerSheetReading),
        content: ValueListenableBuilder<(int, int)>(
          valueListenable: page,
          builder: (_, p, __) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(value: p.$2 == 0 ? null : p.$1 / p.$2),
              const SizedBox(height: 8),
              if (p.$2 > 0) Text(l.answerSheetReadingPage(p.$1, p.$2)),
            ],
          ),
        ),
      ),
    );
    if (stored != null) bytes = await service.download(stored.path);
    final read = await service.readText(user, bytes,
        onPage: (p, n) => page.value = (p, n));
    final parsed = AnswerSheetParser.parse(read.text);
    final rows = AnswerSheetCheck.match(sheet, parsed);
    if (dialogOpen) navigator.pop();
    dialogOpen = false;
    if (!context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => AnswerSheetCheckScreen(
        sheet: sheet,
        rows: rows,
        text: read.text,
        parsed: parsed,
        usedReader: read.usedReader,
        upload: picked,
        stored: stored,
      ),
    ));
  } catch (e) {
    if (dialogOpen) navigator.pop();
    messenger.showSnackBar(SnackBar(content: Text(l.answerSheetReadFailed('$e'))));
  } finally {
    page.dispose();
  }
}

enum _Filter { all, check, changed }

/// Side by side: each question with the key read from the PDF, whether it
/// is right, changes the key or needs a look; the PDF's text next to it.
/// The admin fixes the odd one and saves.
class AnswerSheetCheckScreen extends StatefulWidget {
  const AnswerSheetCheckScreen({
    super.key,
    required this.sheet,
    required this.rows,
    required this.text,
    required this.parsed,
    required this.usedReader,
    this.upload,
    this.stored,
  });

  final QuestionBankSheet sheet;
  final List<AnswerSheetRow> rows;
  final String text;
  final AnswerSheetText parsed;
  final bool usedReader;

  /// A newly picked PDF, stored on Save.
  final PickedAnswerSheet? upload;

  /// The PDF already kept, read again.
  final AnswerSheetFile? stored;

  @override
  State<AnswerSheetCheckScreen> createState() => _AnswerSheetCheckScreenState();
}

class _AnswerSheetCheckScreenState extends State<AnswerSheetCheckScreen> {
  var _filter = _Filter.all;
  var _saving = false;
  var _saved = false;
  late bool _saveScript =
      widget.parsed.script != null && (widget.sheet.transcript?.trim().isEmpty ?? true);

  bool get _inOrder =>
      widget.rows.any((r) => r.readIssue == AnswerSheetIssue.matchedInOrder);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final counts = AnswerSheetCheck.counts(widget.rows);
    final visible = [
      for (final r in widget.rows)
        if (switch (_filter) {
          _Filter.all => true,
          _Filter.check => r.verdict.status == AnswerSheetStatus.check,
          _Filter.changed => r.verdict.status == AnswerSheetStatus.changed,
        })
          r,
    ];
    final wide = MediaQuery.sizeOf(context).width >= 1100;
    final list = ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        _summary(l, counts),
        const SizedBox(height: 12),
        if (!wide) ...[
          AppCard(
            padding: EdgeInsets.zero,
            child: ExpansionTile(
              title: Text(l.answerSheetTextPanel),
              children: [_textPanel()],
            ),
          ),
          const SizedBox(height: 12),
        ],
        for (final r in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _RowCard(
              key: ValueKey(r.item.id),
              row: r,
              onChanged: (v) => setState(() => r.value = v),
            ),
          ),
      ],
    );
    return DiscardGuard(
      isDirty: () => !_saved,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.card,
          foregroundColor: AppColors.navy,
          elevation: 0,
          title: Text('${l.answerSheetCheckTitle} · ${widget.sheet.title}'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined, size: 18),
                label: Text(_saving ? l.answerSheetSaving : l.answerSheetSave),
                style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
              ),
            ),
          ],
        ),
        body: wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: list),
                  SizedBox(
                    width: 380,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 16, 20, 20),
                      child: AppCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.answerSheetTextPanel,
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, color: AppColors.navy)),
                            const SizedBox(height: 8),
                            Expanded(child: SingleChildScrollView(child: _textPanel())),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : list,
      ),
    );
  }

  Widget _textPanel() => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
        child: SelectableText(
          widget.text.trim().isEmpty ? '—' : widget.text.trim(),
          style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textPrimary),
        ),
      );

  Widget _summary(AppLocalizations l, Map<AnswerSheetStatus, int> counts) {
    Widget banner(IconData icon, String text, Color color) => Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(text, style: TextStyle(color: color, fontSize: 13, height: 1.4))),
            ],
          ),
        );
    final name = widget.upload?.name ?? widget.stored?.name ?? '';
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.picture_as_pdf_outlined, color: AppColors.navy),
              const SizedBox(width: 8),
              Expanded(
                child: Text(name,
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CountChip(l.answerSheetCountChanged(counts[AnswerSheetStatus.changed]!),
                  AnswerSheetStatus.changed),
              _CountChip(l.answerSheetCountSame(counts[AnswerSheetStatus.same]!),
                  AnswerSheetStatus.same),
              _CountChip(l.answerSheetCountCheck(counts[AnswerSheetStatus.check]!),
                  AnswerSheetStatus.check),
              _CountChip(l.answerSheetCountMissing(counts[AnswerSheetStatus.missing]!),
                  AnswerSheetStatus.missing),
              if (counts[AnswerSheetStatus.free]! > 0)
                _CountChip(l.answerSheetCountFree(counts[AnswerSheetStatus.free]!),
                    AnswerSheetStatus.free),
            ],
          ),
          if (widget.parsed.entries.isEmpty)
            banner(Icons.error_outline, l.answerSheetNothingBanner, AppColors.error),
          if (_inOrder) banner(Icons.warning_amber_rounded, l.answerSheetInOrderBanner, AppColors.chipAmberFg),
          if (widget.usedReader)
            banner(Icons.image_search_outlined, l.answerSheetReaderBanner, AppColors.chipAmberFg),
          if (widget.parsed.script != null)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              value: _saveScript,
              onChanged: (v) => setState(() => _saveScript = v ?? false),
              title: Text(l.answerSheetSaveScript, style: const TextStyle(fontSize: 13)),
            ),
          const SizedBox(height: 10),
          SegmentedButton<_Filter>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: _Filter.all, label: Text(l.answerSheetFilterAll)),
              ButtonSegment(value: _Filter.check, label: Text(l.answerSheetFilterCheck)),
              ButtonSegment(value: _Filter.changed, label: Text(l.answerSheetFilterChanged)),
            ],
            selected: {_filter},
            onSelectionChanged: (s) => setState(() => _filter = s.first),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final firestore = context.read<FirestoreService>();
    final service = context.read<AnswerSheetService>();
    final user = context.read<AuthService>().appUser;
    setState(() => _saving = true);
    try {
      final plan = AnswerSheetCheck.plan(widget.sheet, widget.rows);
      final ids = widget.sheet.items.map((i) => i.id).toList();
      final upload = widget.upload;
      // The PDF first: when the upload fails nothing is written and the
      // admin simply saves again.
      final path = upload == null
          ? null
          : await service.upload(user, upload.name, upload.bytes);
      await firestore.updateQuestionBankAnswers(plan.indexes);
      await firestore.updateQuestionBankWrittenKeys(plan.fields);
      if (upload != null && path != null) {
        final old = widget.sheet.answerSheet;
        await firestore.setQuestionBankAnswerSheet(
          ids,
          AnswerSheetFile(
            path: path,
            name: upload.name,
            size: upload.bytes.length,
            uploadedBy: user?.uid,
          ),
        );
        if (old != null && old.path != path) await service.delete(old.path);
      }
      final script = widget.parsed.script;
      if (_saveScript && script != null) {
        await firestore.setQuestionBankTranscript(ids, script);
      }
      _saved = true;
      messenger.showSnackBar(SnackBar(
          content: Text(l.answerSheetSaved(plan.indexes.length + plan.fields.length))));
      navigator.pop();
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(l.answerSheetSaveFailed('$e'))));
    }
  }
}

Color _statusColor(AnswerSheetStatus s) => switch (s) {
      AnswerSheetStatus.same => AppColors.success,
      AnswerSheetStatus.changed => AppColors.navy,
      AnswerSheetStatus.check => AppColors.chipAmberFg,
      AnswerSheetStatus.missing => AppColors.textSecondary,
      AnswerSheetStatus.free => AppColors.textSecondary,
    };

class _CountChip extends StatelessWidget {
  const _CountChip(this.label, this.status);
  final String label;
  final AnswerSheetStatus status;

  @override
  Widget build(BuildContext context) {
    final c = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

class _RowCard extends StatefulWidget {
  const _RowCard({super.key, required this.row, required this.onChanged});
  final AnswerSheetRow row;
  final ValueChanged<String> onChanged;

  @override
  State<_RowCard> createState() => _RowCardState();
}

class _RowCardState extends State<_RowCard> {
  late final _controller = TextEditingController(text: widget.row.value);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = widget.row;
    final q = r.item.question;
    final verdict = r.verdict;
    final color = _statusColor(verdict.status);
    final free = verdict.status == AnswerSheetStatus.free;
    final choices = AnswerSheetCheck.isChoice(r.item.type) && q.options.isNotEmpty
        ? [
            for (final (i, o) in q.options.indexed)
              '${String.fromCharCode(65 + i)}. ${o.isEmpty ? '🖼' : o}',
          ].join('   ')
        : r.item.type == ExerciseType.composeSentences
            ? q.segments.join(' / ')
            : '';
    final question = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          [l.answerSheetNumber(r.number), r.item.type.localized(l), if (r.heading.isNotEmpty) r.heading]
              .join(' · '),
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        if (q.prompt.trim().isNotEmpty)
          Text(q.prompt.trim(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.textPrimary, height: 1.4)),
        if (choices.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(choices,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
        const SizedBox(height: 4),
        Text(l.answerSheetNow(r.current.isEmpty ? l.answerSheetNoKeyYet : r.current),
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
    final key = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!free)
          TextField(
            controller: _controller,
            onChanged: widget.onChanged,
            decoration: InputDecoration(
              isDense: true,
              labelText: l.answerSheetKeyLabel,
              helperText: l.answerSheetHint,
              helperMaxLines: 2,
              border: const OutlineInputBorder(),
            ),
          ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              switch (verdict.status) {
                AnswerSheetStatus.same => Icons.check_circle_outline,
                AnswerSheetStatus.changed => Icons.edit_note,
                AnswerSheetStatus.check => Icons.warning_amber_rounded,
                AnswerSheetStatus.missing => Icons.help_outline,
                AnswerSheetStatus.free => Icons.rate_review_outlined,
              },
              size: 16,
              color: color,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _label(l, r, verdict),
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    );
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        padding: const EdgeInsets.only(left: 12),
        child: LayoutBuilder(
          builder: (context, c) => c.maxWidth >= 560
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: question),
                    const SizedBox(width: 16),
                    SizedBox(width: 260, child: key),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [question, const SizedBox(height: 10), key],
                ),
        ),
      ),
    );
  }

  static String _label(AppLocalizations l, AnswerSheetRow r, AnswerSheetVerdict v) {
    final base = switch (v.status) {
      AnswerSheetStatus.same => l.answerSheetStatusSame,
      AnswerSheetStatus.changed => l.answerSheetStatusChanged,
      AnswerSheetStatus.check => l.answerSheetStatusCheck,
      AnswerSheetStatus.missing => l.answerSheetStatusMissing,
      AnswerSheetStatus.free => l.answerSheetStatusFree,
    };
    final issue = switch (v.issue) {
      AnswerSheetIssue.none => '',
      AnswerSheetIssue.notAChoice => l.answerSheetIssueNotAChoice,
      AnswerSheetIssue.pastLastChoice => l.answerSheetIssuePastLast,
      AnswerSheetIssue.wordsDoNotMatch => l.answerSheetIssueWords,
      AnswerSheetIssue.blankCount => l.answerSheetIssueBlanks,
      AnswerSheetIssue.readTwice => l.answerSheetIssueTwice,
      AnswerSheetIssue.matchedInOrder => l.answerSheetIssueInOrder,
      AnswerSheetIssue.wrongScript => r.item.type == ExerciseType.typePinyin
          ? l.answerSheetIssuePinyin
          : l.answerSheetIssueHanzi,
    };
    final hint = r.readIssue == AnswerSheetIssue.matchedInOrder && v.issue == AnswerSheetIssue.none
        ? ' · ${l.answerSheetIssueInOrder}'
        : '';
    return issue.isEmpty ? '$base$hint' : '$base: $issue';
  }
}
