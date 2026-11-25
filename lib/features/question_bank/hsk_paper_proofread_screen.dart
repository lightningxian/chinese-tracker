import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/build_flags.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/pinyin_tones.dart';
import '../../core/widgets/app_card.dart';
import '../../l10n/l10n.dart';
import '../../models/app_user.dart';
import '../../models/hsk_paper_draft.dart';
import '../../models/paper_proof_record.dart';
import '../../models/question_bank_item.dart';
import '../../services/auth_service.dart';
import '../../services/hsk_paper/hsk_paper_import.dart';
import '../../services/hsk_paper/hsk_paper_reader.dart';
import '../../services/hsk_paper/paper_draft_service.dart';
import '../../services/hsk_paper/paper_image_ops.dart';
import '../../services/hsk_paper/paper_truth.dart';
import '../../core/widgets/discard_guard.dart';

/// ViewModel of the proofreading screen: the pages the reader saw, the
/// draft being corrected, the page on show and the save.
class HskPaperProofreadViewModel extends ChangeNotifier {
  HskPaperProofreadViewModel({
    required this.pages,
    required this.draft,
    required this.pdfBytes,
    required this.fileName,
    this.readSeconds = 0,
    this.engine = '',
  })  : startedAt = DateTime.now(),
        flaggedAtStart = draft.flagged.length {
    // Open on the first page that has something to check.
    final first = draft.flagged.where((s) => s.page >= 1).firstOrNull;
    if (first != null) selectedPage = first.page;
  }

  final List<PaperPage> pages;
  final HskPaperDraft draft;
  final Uint8List pdfBytes;
  final String fileName;

  /// When proofreading started (the report states how long it took).
  final DateTime startedAt;

  /// Build 1C (Must 6): what the proofreading record keeps.
  final int flaggedAtStart;
  final int readSeconds;
  final String engine;

  PaperProofRecord record() => PaperProofRecord(
        slots: draft.slots.length,
        flagged: flaggedAtStart,
        changed: edited.length,
        proofSeconds: DateTime.now().difference(startedAt).inSeconds,
        readSeconds: readSeconds,
        engine: engine,
        savedAt: DateTime.now(),
      );

  int selectedPage = 1;
  bool onlyFlagged = false;

  /// Owner 2026-11-24: the draft this scan is kept in (null until saved).
  String? draftId;
  bool savingDraft = false;

  Future<void> saveDraft(String byName) async {
    savingDraft = true;
    notifyListeners();
    try {
      draftId = await PaperDraftService().save(
        id: draftId,
        draft: draft,
        pages: pages,
        pdfBytes: pdfBytes,
        fileName: fileName,
        edited: edited,
        drawnBoxes: drawnBoxes,
        readSeconds: readSeconds,
        engine: engine,
        byName: byName,
      );
    } finally {
      savingDraft = false;
      notifyListeners();
    }
  }
  bool saving = false;
  String savingDetail = '';

  /// Slots the admin edited (the report counts the untouched ones).
  final Set<int> edited = {};

  /// Standard Course: the lesson text as the admin corrected it.
  void setContext(String text) {
    draft.context = text;
  }

  PaperPage get page => pages[(selectedPage - 1).clamp(0, pages.length - 1)];

  /// The slots on show, by number: every flagged one (and every one the
  /// admin already edited, so a slot does not vanish while it is being
  /// typed in) when [onlyFlagged], else the page's own.
  List<HskSlot> get visible => [
        for (final s in draft.slots)
          if (onlyFlagged
              ? s.flagged || edited.contains(s.number)
              : s.page == selectedPage ||
                  (s.form == HskForm.picture && s.picturePage == selectedPage))
            s,
      ];

  /// Slots with no page (the reader found no line and no block).
  List<HskSlot> get unplaced => [
        for (final s in draft.slots)
          if (s.page < 1 && s.form != HskForm.picture) s,
      ];

  List<int> get unsavable => HskPaperImport.unsavable(draft, pages);

  void showPage(int number) {
    selectedPage = number;
    onlyFlagged = false;
    notifyListeners();
  }

  void setOnlyFlagged(bool v) {
    onlyFlagged = v;
    notifyListeners();
  }

  /// Any change to a slot: it counts as corrected, and its reader flags
  /// (missing, unsure) are cleared because the admin has looked at it.
  void changed(HskSlot slot) {
    edited.add(slot.number);
    slot.missing = false;
    slot.unsure = false;
    notifyListeners();
  }

  /// Owner 2026-11-24: the boxes the admin drew, by page; the page preview
  /// shows these instead of the reader's first guess.
  final Map<int, List<PixelBox>> drawnBoxes = {};

  /// The picture boxes to draw on [page].
  List<PixelBox> boxesFor(PaperPage page) => drawnBoxes[page.number] ?? page.pictureBoxes;

  void nextPage(int step) {
    final n = (selectedPage + step).clamp(1, pages.length);
    if (n != selectedPage || onlyFlagged) showPage(n);
  }

  /// Owner 2026-11-24: a block of matching (or word-bank) questions shares
  /// one lettered list, shown once like on the paper.
  List<String> sharedOptions(HskSlot slot) {
    for (final s in draft.slots) {
      if (s.section == slot.section && s.form == slot.form && s.options.isNotEmpty) {
        return s.options;
      }
    }
    return slot.options;
  }

  void setSharedOptions(HskSlot slot, List<String> options) {
    for (final s in draft.slots) {
      if (s.section == slot.section && s.form == slot.form) {
        s.options = [...options];
        s.optionsIncomplete = false;
        edited.add(s.number);
      }
    }
    notifyListeners();
  }

  void setAnswer(HskSlot slot, int? index) {
    slot.correctIndex = index;
    changed(slot);
  }

  /// New picture boxes for every picture question of [pageNumber].
  void setPictures(int pageNumber, List<PixelBox> boxes) {
    drawnBoxes[pageNumber] = [...boxes];
    for (final s in draft.slots) {
      if (s.form == HskForm.picture && s.picturePage == pageNumber) {
        s.pictures = [...boxes];
        edited.add(s.number);
        s.missing = false;
        s.unsure = false;
      }
    }
    notifyListeners();
  }

  Future<List<QuestionBankItem>> buildItems({
    required AppUser? user,
    required String ownerId,
    required Future<String> Function(Uint8List png, String name) upload,
    required String Function(int done, int total) pictureLabel,
  }) async {
    saving = true;
    notifyListeners();
    try {
      return await HskPaperImport.toBankItems(
        draft,
        pages,
        user: user,
        pdfBytes: pdfBytes,
        ownerId: ownerId,
        fileName: fileName,
        upload: upload,
        onPicture: (done, total) {
          savingDetail = pictureLabel(done, total);
          notifyListeners();
        },
      );
    } finally {
      saving = false;
      savingDetail = '';
      notifyListeners();
    }
  }
}

/// Result of the proofreading screen: the items to add, and how the
/// proofreading went (for the report).
class HskProofreadResult {
  const HskProofreadResult({
    required this.items,
    required this.untouched,
    required this.total,
    required this.duration,
  });

  final List<QuestionBankItem> items;

  /// Questions the admin did not change.
  final int untouched;
  final int total;
  final Duration duration;
}

/// Proofreading: page by page, the page picture on one side and the
/// questions read from it on the other; flagged slots first; the counts
/// against the format on top. Nothing the reader returned is hidden.
class HskPaperProofreadScreen extends StatelessWidget {
  const HskPaperProofreadScreen({
    super.key,
    required this.viewModel,
    required this.ownerId,
    required this.upload,
  });

  final HskPaperProofreadViewModel viewModel;
  final String ownerId;
  final Future<String> Function(Uint8List png, String name) upload;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: _ProofreadView(ownerId: ownerId, upload: upload),
    );
  }
}

class _ProofreadView extends StatelessWidget {
  const _ProofreadView({required this.ownerId, required this.upload});

  final String ownerId;
  final Future<String> Function(Uint8List png, String name) upload;

  Future<void> _compare(BuildContext context) async {
    final l = context.l10n;
    final vm = context.read<HskPaperProofreadViewModel>();
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    final bytes = picked?.files.firstOrNull?.bytes;
    if (bytes == null || !context.mounted) return;
    PaperMeasure measure;
    try {
      measure = PaperMeasure.compare(
        vm.draft,
        PaperTruth.parse(utf8.decode(bytes)),
        seconds: vm.readSeconds.toDouble(),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.paperCompareFailed('$e'))));
      return;
    }
    debugPrint('paper reader measure: ${measure.summary()}');
    final wrong = [
      for (final c in measure.checks)
        if (!c.right) '${c.flagged ? '' : '!'}${c.number} (${c.wrong.join(', ')})',
    ];
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.paperCompareTruth),
        content: SingleChildScrollView(
          child: Text([
            l.paperCompareSummary(measure.right, measure.total, measure.flagged,
                measure.wrongNotFlagged, vm.readSeconds),
            if (wrong.isNotEmpty) l.paperCompareWrong(wrong.join(' · ')),
          ].join('\n\n')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.commonOk)),
        ],
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    final l = context.l10n;
    final vm = context.read<HskPaperProofreadViewModel>();
    final unsavable = vm.unsavable;
    if (unsavable.isNotEmpty) {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.paperUnsavableTitle),
          content: Text(l.paperUnsavableBody(unsavable.join(', '))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.paperKeepChecking),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.paperSaveAnyway),
            ),
          ],
        ),
      );
      if (go != true || !context.mounted) return;
    }
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final items = await vm.buildItems(
        user: context.read<AuthService>().appUser,
        ownerId: ownerId,
        upload: upload,
        pictureLabel: l.paperUploadingPicture,
      );
      final record = vm.record();
      navigator.pop(HskProofreadResult(
        items: [for (final i in items) i.copyWith(paperRecord: record)],
        untouched: vm.draft.slots.length - vm.edited.length,
        total: vm.draft.slots.length,
        duration: DateTime.now().difference(vm.startedAt),
      ));
    } catch (e) {
      // Owner 2026-11-24: show the whole error (to copy) and keep the work.
      messenger.hideCurrentSnackBar();
      if (!context.mounted) return;
      final draft = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.paperSaveFailedTitle),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l.paperSaveFailedBody),
                const SizedBox(height: 10),
                SelectableText('$e',
                    style: TextStyle(color: AppColors.error, fontFamily: 'monospace', fontSize: 12)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.discardKeepEditing)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.paperSaveDraft)),
          ],
        ),
      );
      if (draft == true && context.mounted) await _saveDraft(context);
    }
  }

  @override
  Widget build(BuildContext context) =>
      // Owner 2026-11-24: a scan is unsaved work as soon as it is read;
      // leaving asks: keep editing, save as a draft, or discard.
      PopScope<Object?>(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final vm = context.read<HskPaperProofreadViewModel>();
          if (vm.saving) return;
          final navigator = Navigator.of(context);
          final choice = await _askLeave(context);
          if (choice == 'discard') {
            navigator.pop();
          } else if (choice == 'draft' && context.mounted) {
            if (await _saveDraft(context)) navigator.pop();
          }
        },
        child: _buildEditor(context),
      );

  Future<String?> _askLeave(BuildContext context) {
    final l = context.l10n;
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.paperLeaveTitle),
        content: Text(l.paperLeaveBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.discardKeepEditing)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'discard'),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l.discardConfirm),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'draft'),
            child: Text(l.paperSaveDraft),
          ),
        ],
      ),
    );
  }

  Future<bool> _saveDraft(BuildContext context) async {
    final l = context.l10n;
    final vm = context.read<HskPaperProofreadViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await vm.saveDraft(context.read<AuthService>().appUser?.name ?? '');
      messenger.showSnackBar(SnackBar(content: Text(l.paperDraftSaved)));
      return true;
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.paperDraftFailed('$e'))));
      return false;
    }
  }

  Widget _buildEditor(BuildContext context) {
    final l = context.l10n;
    final vm = context.watch<HskPaperProofreadViewModel>();
    final draft = vm.draft;
    final wide = MediaQuery.sizeOf(context).width >= 980;
    final slots = vm.visible;
    final list = ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (draft.standardCourse) ...[
          _ContextCard(draft: draft),
          const SizedBox(height: 10),
        ],
        if (!vm.onlyFlagged && vm.unplaced.isNotEmpty) ...[
          Text(
            l.paperUnplaced(vm.unplaced.map((s) => s.number).join(', ')),
            style: TextStyle(color: AppColors.chipAmberFg),
          ),
          const SizedBox(height: 8),
        ],
        if (slots.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l.paperNothingOnPage,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        for (final (i, s) in slots.indexed) ...[
          if ((s.form == HskForm.matching || s.form == HskForm.wordBank) &&
              (i == 0 ||
                  slots[i - 1].section != s.section ||
                  slots[i - 1].form != s.form))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SharedChoicesCard(
                key: ValueKey('shared-${s.section}-${s.form}'),
                slot: s,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SlotEditor(
              key: ValueKey('slot-${s.number}'),
              slot: s,
              page: vm.pages.length >= s.picturePage && s.picturePage >= 1
                  ? vm.pages[s.picturePage - 1]
                  : null,
            ),
          ),
        ],
      ],
    );
    final pageView = _PageView(page: vm.page, wide: wide);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.navy,
        title: Text(l.paperProofreadTitle(
            draft.code.isEmpty ? '—' : draft.code)),
        actions: [
          // Emulator builds only (Build 1C, Must 1): the reader measured
          // against a truth file (the practice paper's, or a proofread
          // worksheet saved with Download text).
          if (BuildFlags.useEmulators)
            IconButton(
              onPressed: () => _compare(context),
              icon: const Icon(Icons.rule_outlined),
              tooltip: l.paperCompareTruth,
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: OutlinedButton.icon(
              onPressed: vm.saving || vm.savingDraft ? null : () => _saveDraft(context),
              icon: vm.savingDraft
                  ? const SizedBox(
                      width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.bookmark_add_outlined, size: 18),
              label: Text(l.paperSaveDraft),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: vm.saving ? null : () => _save(context),
              icon: vm.saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined, size: 18),
              label: Text(vm.saving && vm.savingDetail.isNotEmpty
                  ? vm.savingDetail
                  : l.paperSaveWorksheet),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CountsBar(draft: draft),
          Expanded(
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 5, child: pageView),
                      VerticalDivider(width: 1, color: AppColors.border),
                      Expanded(flex: 6, child: list),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 280, child: pageView),
                      Divider(height: 1, color: AppColors.border),
                      Expanded(child: list),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Standard Course (owner 2026-11-25): the textbook dialogues and new words
/// the reader found, shown to the students while they answer. Folded until
/// opened; the admin corrects it here before saving.
class _ContextCard extends StatefulWidget {
  const _ContextCard({required this.draft});

  final HskPaperDraft draft;

  @override
  State<_ContextCard> createState() => _ContextCardState();
}

class _ContextCardState extends State<_ContextCard> {
  late final _text = TextEditingController(text: widget.draft.context);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final empty = widget.draft.context.trim().isEmpty;
    return AppCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        leading: Icon(Icons.menu_book_outlined, color: AppColors.navy),
        title: Text(
          l.paperContextTitle,
          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy),
        ),
        subtitle: Text(
          empty ? l.paperContextEmpty : l.paperContextLines(
              widget.draft.context.trim().split('\n').length),
          style: TextStyle(
            fontSize: 12,
            color: empty ? AppColors.chipAmberFg : AppColors.textSecondary,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          TextField(
            controller: _text,
            minLines: 8,
            maxLines: 24,
            decoration: InputDecoration(
              helperText: l.paperContextHint,
              helperMaxLines: 3,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) {
              context.read<HskPaperProofreadViewModel>().setContext(v);
              if (v.trim().isEmpty != empty) setState(() {});
            },
          ),
        ],
      ),
    );
  }
}

/// "Listening 40 of 40 · … · to check: n · not read: 12, 27".
class _CountsBar extends StatelessWidget {
  const _CountsBar({required this.draft});

  final HskPaperDraft draft;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final vm = context.watch<HskPaperProofreadViewModel>();
    String skillName(String s) => switch (s) {
          'listening' => l.testsSkillListening,
          'writing' => l.testsSkillWriting,
          _ => l.testsSkillReading,
        };
    final skills = draft.expected.isEmpty
        ? {for (final s in draft.slots) s.skill: 0}.keys.toList()
        : draft.expected.keys.toList();
    final flagged = draft.flagged.length;
    final missing = draft.missingNumbers;
    return Material(
      color: AppColors.card,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              [
                if (draft.standardCourse)
                  '${l.exerciseCategoryStandardCourse}${draft.level == null ? '' : ' ${draft.level}'}'
                else if (draft.level != null)
                  'HSK ${draft.level}',
                if (draft.code.isNotEmpty) draft.code,
              ].join(' · '),
              style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy),
            ),
            for (final skill in skills)
              _CountChip(
                label: l.paperCountOf(
                  skillName(skill),
                  draft.countFor(skill),
                  draft.expected[skill] ?? draft.countFor(skill),
                ),
                ok: draft.expected[skill] == null ||
                    draft.expected[skill] == draft.countFor(skill),
              ),
            FilterChip(
              selected: vm.onlyFlagged,
              onSelected: vm.setOnlyFlagged,
              label: Text(l.paperToCheck(flagged)),
            ),
            if (missing.isNotEmpty)
              Text(
                l.paperNotRead(missing.join(', ')),
                style: TextStyle(color: AppColors.chipAmberFg, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.ok});

  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ok ? AppColors.chipGreenBg : AppColors.chipAmberBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: ok ? AppColors.chipGreenFg : AppColors.chipAmberFg,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// The page picture with a page picker; picture boxes drawn on it. Owner
/// 2026-11-24: on a wide screen the pages are a column of thumbnails beside
/// the picture (like a PDF viewer), with previous / next buttons.
class _PageView extends StatelessWidget {
  const _PageView({required this.page, required this.wide});

  final PaperPage page;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final vm = context.watch<HskPaperProofreadViewModel>();
    bool flagged(int n) => vm.draft.flagged.any((s) => s.page == n);
    final picture = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: l.paperPrevPage,
                onPressed: vm.selectedPage > 1 ? () => vm.nextPage(-1) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text(l.paperPageOf(vm.selectedPage, vm.pages.length),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              IconButton(
                tooltip: l.paperNextPage,
                onPressed: vm.selectedPage < vm.pages.length ? () => vm.nextPage(1) : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        Expanded(
          child: InteractiveViewer(
            maxScale: 5,
            child: Center(child: _BoxedPage(page: page, boxes: vm.boxesFor(page))),
          ),
        ),
      ],
    );
    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 104,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              itemCount: vm.pages.length,
              itemBuilder: (context, i) {
                final p = vm.pages[i];
                final selected = !vm.onlyFlagged && p.number == vm.selectedPage;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () => vm.showPage(p.number),
                    borderRadius: BorderRadius.circular(6),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: selected ? AppColors.teal : AppColors.border,
                              width: selected ? 3 : 1,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: AspectRatio(
                            aspectRatio: p.width / p.height,
                            child: Image.memory(p.png,
                                fit: BoxFit.fill, gaplessPlayback: true, cacheWidth: 160),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (flagged(p.number))
                              Padding(
                                padding: const EdgeInsets.only(right: 3),
                                child: Icon(Icons.error_outline,
                                    size: 13, color: AppColors.chipAmberFg),
                              ),
                            Text('${p.number}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                                  color: selected ? AppColors.teal : AppColors.textSecondary,
                                )),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          VerticalDivider(width: 1, color: AppColors.border),
          Expanded(child: picture),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            children: [
              for (final p in vm.pages)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(l.paperPageShort(p.number)),
                    selected: !vm.onlyFlagged && p.number == vm.selectedPage,
                    avatar: flagged(p.number)
                        ? Icon(Icons.error_outline,
                            size: 16, color: AppColors.chipAmberFg)
                        : null,
                    onSelected: (_) => vm.showPage(p.number),
                  ),
                ),
            ],
          ),
        ),
        Expanded(child: picture),
      ],
    );
  }
}

/// A page image with numbered rectangles over it.
class _BoxedPage extends StatelessWidget {
  const _BoxedPage({required this.page, required this.boxes, this.selected});

  final PaperPage page;
  final List<PixelBox> boxes;
  final int? selected;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: page.width / page.height,
      child: LayoutBuilder(
        builder: (context, c) {
          final k = c.maxWidth / page.width;
          return Stack(
            children: [
              Positioned.fill(
                child: Image.memory(page.png, fit: BoxFit.fill, gaplessPlayback: true),
              ),
              for (var i = 0; i < boxes.length; i++)
                Positioned(
                  left: boxes[i].x0 * k,
                  top: boxes[i].y0 * k,
                  width: boxes[i].width * k,
                  height: boxes[i].height * k,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: i == selected ? AppColors.error : AppColors.teal,
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.topLeft,
                      child: Container(
                        color: i == selected ? AppColors.error : AppColors.teal,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          String.fromCharCode(65 + i),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// One question slot, every field editable in place.
class _SlotEditor extends StatefulWidget {
  const _SlotEditor({super.key, required this.slot, required this.page});

  final HskSlot slot;
  final PaperPage? page;

  @override
  State<_SlotEditor> createState() => _SlotEditorState();
}

class _SlotEditorState extends State<_SlotEditor> {
  late final _prompt = TextEditingController(text: widget.slot.prompt);
  late final _options =
      TextEditingController(text: widget.slot.options.join('\n'));
  late final _segments =
      TextEditingController(text: widget.slot.segments.join(' / '));
  late final _keyword = TextEditingController(text: widget.slot.keyword);
  late final _accepted = TextEditingController(text: widget.slot.accepted.join(' / '));

  @override
  void dispose() {
    _prompt.dispose();
    _options.dispose();
    _segments.dispose();
    _keyword.dispose();
    _accepted.dispose();
    super.dispose();
  }

  void _changed() =>
      context.read<HskPaperProofreadViewModel>().changed(widget.slot);

  String _doubtName(AppLocalizations l, String doubt) => switch (doubt) {
        HskSlot.doubtTones => l.paperFlagTones,
        HskSlot.doubtSplit => l.paperFlagSplit,
        HskSlot.doubtGap => l.paperFlagGap,
        HskSlot.doubtForm => l.paperFlagForm,
        HskSlot.doubtMarks => l.paperFlagMarks,
        HskSlot.doubtLevel => l.paperFlagLevel(
            widget.slot.paperLevel ?? 0, widget.slot.unknownCharacters.join(' ')),
        _ => l.paperFlagGarbled,
      };

  String _formName(AppLocalizations l, String form) => switch (form) {
        HskForm.picture => l.paperFormPicture,
        HskForm.trueFalse => l.paperFormTrueFalse,
        HskForm.matching => l.paperFormMatching,
        HskForm.wordBank => l.paperFormWordBank,
        HskForm.reorder => l.paperFormReorder,
        HskForm.pinyinChar => l.paperFormPinyinChar,
        HskForm.sentenceWithWord => l.paperFormSentenceWithWord,
        HskForm.open => l.paperFormOpen,
        _ => l.paperFormChoice,
      };

  Future<void> _editBoxes() async {
    final page = widget.page;
    if (page == null) return;
    final vm = context.read<HskPaperProofreadViewModel>();
    final boxes = await showDialog<List<PixelBox>>(
      context: context,
      builder: (_) => _BoxEditorDialog(
          page: page,
          initial: widget.slot.pictures.isNotEmpty ? widget.slot.pictures : vm.boxesFor(page)),
    );
    if (boxes != null) vm.setPictures(page.number, boxes);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = widget.slot;
    final doubt = s.checked ? null : s.doubt;
    InputDecoration deco(String label, {String? helper}) => InputDecoration(
          labelText: label,
          helperText: helper,
          helperMaxLines: 3,
          border: const OutlineInputBorder(),
          isDense: true,
        );
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${s.number}.',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                  fontSize: 16,
                ),
              ),
              DropdownButton<String>(
                value: s.form,
                isDense: true,
                items: [
                  for (final f in HskForm.all)
                    DropdownMenuItem(value: f, child: Text(_formName(l, f))),
                ],
                onChanged: (f) {
                  if (f == null) return;
                  setState(() {
                    s.form = f;
                    s.oddForm = false;
                  });
                  _changed();
                },
              ),
              if (s.missing) _Flag(text: l.paperFlagMissing),
              if (s.unsure) _Flag(text: l.paperFlagUnsure),
              if (s.optionsIncomplete) _Flag(text: l.paperFlagOptions),
              if (doubt != null) _Flag(text: _doubtName(l, doubt)),
              if (!s.missing &&
                  !s.unsure &&
                  !s.optionsIncomplete &&
                  doubt == null &&
                  s.flagged)
                _Flag(text: l.paperFlagIncomplete),
              if (s.page >= 1)
                Text(
                  l.paperPageShort(s.page),
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              if (s.form != HskForm.sentenceWithWord && s.form != HskForm.open)
                _AnswerChip(slot: s),
              if (s.missing || s.unsure || doubt != null)
                TextButton(
                  onPressed: () {
                    s.checked = true;
                    _changed();
                  },
                  child: Text(l.paperLooksRight),
                ),
            ],
          ),
          if (s.section.isNotEmpty)
            Text(s.section,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          if (s.form == HskForm.picture) ...[
            Row(
              children: [
                Expanded(
                  child: Text(l.paperPictures(s.pictures.length,
                      s.picturePage < 1 ? 0 : s.picturePage)),
                ),
                OutlinedButton.icon(
                  onPressed: widget.page == null ? null : _editBoxes,
                  icon: const Icon(Icons.crop_free, size: 18),
                  label: Text(l.paperEditBoxes),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _LetterAnswer(slot: s, count: s.pictures.length),
          ] else ...[
            if (s.form != HskForm.reorder)
              TextField(
                controller: _prompt,
                minLines: 1,
                maxLines: 6,
                decoration: deco(l.paperPrompt),
                onChanged: (v) {
                  s.prompt = v;
                  _changed();
                },
              ),
            if (s.form == HskForm.choice) ...[
              const SizedBox(height: 8),
              _ChoiceRows(key: ValueKey('choices-${s.number}'), slot: s),
            ],
            if (s.form == HskForm.matching || s.form == HskForm.wordBank) ...[
              const SizedBox(height: 8),
              _LetterAnswer(
                slot: s,
                count: context.watch<HskPaperProofreadViewModel>().sharedOptions(s).length,
              ),
            ],
            if (s.form == HskForm.trueFalse) ...[
              const SizedBox(height: 8),
              _TrueFalseAnswer(slot: s),
            ],
            if (s.form == HskForm.reorder) ...[
              TextField(
                controller: _segments,
                decoration: deco(l.paperSegments, helper: l.paperSegmentsHint),
                onChanged: (v) {
                  s.segments = v
                      .split('/')
                      .map((w) => w.trim())
                      .where((w) => w.isNotEmpty)
                      .toList();
                  s.orderSet = false;
                  _changed();
                },
              ),
            ],
            if (s.form == HskForm.reorder) ...[
              const SizedBox(height: 8),
              _OrderAnswer(
                key: ValueKey('order-${s.number}-${s.segments.join('|')}'),
                slot: s,
                onOrdered: (words) {
                  _segments.text = words.join(' / ');
                  setState(() {
                    s.segments = words;
                    s.orderSet = true;
                  });
                  _changed();
                },
              ),
            ],
            if (s.form == HskForm.pinyinChar ||
                s.form == HskForm.sentenceWithWord) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _keyword,
                decoration: deco(
                  s.form == HskForm.pinyinChar ? l.paperPinyin : l.paperKeyword,
                  helper: s.form == HskForm.pinyinChar ? l.paperPinyinHint : null,
                ),
                onChanged: (v) {
                  // `guan1` → `guān` (Build 1C, Must 5).
                  if (s.form == HskForm.pinyinChar &&
                      RegExp(r'[a-zA-Zü:][0-5]').hasMatch(v)) {
                    final marked = PinyinTones.fromNumbers(v);
                    _keyword.value = TextEditingValue(
                      text: marked,
                      selection: TextSelection.collapsed(offset: marked.length),
                    );
                    v = marked;
                  }
                  setState(() => s.keyword = v);
                  _changed();
                },
              ),
              if (s.form == HskForm.pinyinChar &&
                  PinyinTones.syllables(s.keyword).isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    for (final (i, syl) in PinyinTones.syllables(s.keyword).indexed)
                      _ToneButtons(
                        syllable: syl,
                        onTone: (tone) {
                          final next = PinyinTones.setTone(s.keyword, i, tone);
                          _keyword.text = next;
                          setState(() => s.keyword = next);
                          _changed();
                        },
                      ),
                  ],
                ),
              ],
              if (s.form == HskForm.pinyinChar) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _accepted,
                  decoration: deco(l.paperCharAnswer, helper: l.paperCharAnswerHint),
                  onChanged: (v) {
                    setState(() => s.accepted = v
                        .split(RegExp(r'[/,，、]'))
                        .map((a) => a.trim())
                        .where((a) => a.isNotEmpty)
                        .toList());
                    _changed();
                  },
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }
}

/// The four tones of one syllable as buttons (`ā á ǎ à`); the one in use is
/// filled.
class _ToneButtons extends StatelessWidget {
  const _ToneButtons({required this.syllable, required this.onTone});

  final String syllable;
  final ValueChanged<int> onTone;

  @override
  Widget build(BuildContext context) {
    final (base, current) = PinyinTones.split(syllable);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var t = 1; t <= 4; t++)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: t == current
                ? FilledButton(
                    onPressed: () => onTone(t),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(44, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Text(PinyinTones.mark(base, t)),
                  )
                : OutlinedButton(
                    onPressed: () => onTone(t),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(44, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Text(PinyinTones.mark(base, t)),
                  ),
          ),
      ],
    );
  }
}

class _Flag extends StatelessWidget {
  const _Flag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.chipAmberBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.chipAmberFg,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

/// Redraw the picture boxes of a page: drag on the page to draw a box,
/// tap a box's letter to select it, delete the selected one.
class _BoxEditorDialog extends StatefulWidget {
  const _BoxEditorDialog({required this.page, required this.initial});

  final PaperPage page;
  final List<PixelBox> initial;

  @override
  State<_BoxEditorDialog> createState() => _BoxEditorDialogState();
}

class _BoxEditorDialogState extends State<_BoxEditorDialog> {
  static String _boxSig(List<PixelBox> b) =>
      b.map((x) => '${x.x0},${x.y0},${x.width},${x.height}').join(';');

  late List<PixelBox> _boxes = [...widget.initial];
  int? _selected;
  Offset? _start;
  Offset? _end;

  PixelBox? _drawn(double k) {
    final a = _start, b = _end;
    if (a == null || b == null) return null;
    final box = PixelBox(
      (a.dx < b.dx ? a.dx : b.dx) ~/ k,
      (a.dy < b.dy ? a.dy : b.dy) ~/ k,
      (a.dx > b.dx ? a.dx : b.dx) ~/ k,
      (a.dy > b.dy ? a.dy : b.dy) ~/ k,
    );
    return box.width > 10 && box.height > 10 ? box : null;
  }

  @override
  Widget build(BuildContext context) =>
      DiscardGuard(isDirty: () => _boxSig(_boxes) != _boxSig(widget.initial), child: _buildEditor(context));

  Widget _buildEditor(BuildContext context) {
    final l = context.l10n;
    final page = widget.page;
    final size = MediaQuery.sizeOf(context);
    final width = (size.width * 0.8).clamp(280.0, 820.0);
    return AlertDialog(
      title: Text(l.paperEditBoxesTitle(page.number)),
      content: SizedBox(
        width: width,
        height: (size.height * 0.75).clamp(300.0, 1000.0),
        child: Column(
          children: [
            Text(l.paperEditBoxesHint,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: LayoutBuilder(
                  builder: (context, c) {
                    final k = c.maxWidth / page.width;
                    final drawn = _drawn(k);
                    return GestureDetector(
                      onPanStart: (d) => setState(() {
                        _start = d.localPosition;
                        _end = d.localPosition;
                      }),
                      onPanUpdate: (d) => setState(() => _end = d.localPosition),
                      onPanEnd: (_) => setState(() {
                        final box = _drawn(k);
                        if (box != null) {
                          if (_selected != null) {
                            _boxes[_selected!] = box;
                          } else {
                            _boxes.add(box);
                          }
                          _boxes = PaperImageOps.readingOrder(_boxes);
                          _selected = null;
                        }
                        _start = null;
                        _end = null;
                      }),
                      onTapUp: (d) {
                        final p = d.localPosition;
                        final hit = _boxes.indexWhere((b) =>
                            p.dx >= b.x0 * k &&
                            p.dx <= b.x1 * k &&
                            p.dy >= b.y0 * k &&
                            p.dy <= b.y1 * k);
                        setState(() => _selected = hit < 0 ? null : hit);
                      },
                      child: _BoxedPage(
                        page: page,
                        boxes: [..._boxes, if (drawn != null) drawn],
                        selected: _selected,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: _selected == null
              ? null
              : () => setState(() {
                    _boxes.removeAt(_selected!);
                    _selected = null;
                  }),
          icon: const Icon(Icons.delete_outline),
          label: Text(l.paperDeleteBox),
        ),
        TextButton(
          onPressed: () => Navigator.maybePop(context),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _boxes),
          child: Text(l.paperUseBoxes(_boxes.length)),
        ),
      ],
    );
  }
}


String _letter(int i) => String.fromCharCode(65 + i);

/// "Answer: B" (green) or "No answer yet" (amber) beside the number.
class _AnswerChip extends StatelessWidget {
  const _AnswerChip({required this.slot});
  final HskSlot slot;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final i = slot.correctIndex;
    final String? answer = switch (slot.form) {
      HskForm.reorder => slot.orderSet ? slot.segments.join() : null,
      HskForm.pinyinChar => slot.accepted.where((a) => a.trim().isNotEmpty).firstOrNull,
      HskForm.trueFalse => i == null ? null : (i == 0 ? '✓' : '✗'),
      _ => i == null ? null : _letter(i),
    };
    final text = answer == null ? l.paperNoAnswer : l.paperAnswerIs(answer);
    final color = answer == null ? AppColors.chipAmberFg : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11.5)),
    );
  }
}

/// Owner 2026-11-24: the choices of a question as rows, the right one
/// ticked, like a multiple-choice question.
class _ChoiceRows extends StatefulWidget {
  const _ChoiceRows({super.key, required this.slot});
  final HskSlot slot;

  @override
  State<_ChoiceRows> createState() => _ChoiceRowsState();
}

class _ChoiceRowsState extends State<_ChoiceRows> {
  late final List<TextEditingController> _rows = [
    for (final o in widget.slot.options) TextEditingController(text: o),
  ];

  @override
  void dispose() {
    for (final c in _rows) {
      c.dispose();
    }
    super.dispose();
  }

  void _push() {
    final vm = context.read<HskPaperProofreadViewModel>();
    widget.slot.options = [for (final c in _rows) c.text.trim()];
    widget.slot.optionsIncomplete = false;
    vm.changed(widget.slot);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final vm = context.read<HskPaperProofreadViewModel>();
    final s = widget.slot;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.paperChoicesTick, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        for (var i = 0; i < _rows.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Checkbox(
                  value: s.correctIndex == i,
                  onChanged: (v) => setState(() => vm.setAnswer(s, v == true ? i : null)),
                ),
                SizedBox(
                  width: 22,
                  child: Text(_letter(i), style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
                Expanded(
                  child: TextField(
                    controller: _rows[i],
                    decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                    onChanged: (_) => _push(),
                  ),
                ),
                IconButton(
                  tooltip: l.paperRemoveChoice,
                  onPressed: () => setState(() {
                    _rows.removeAt(i).dispose();
                    if (s.correctIndex == i) {
                      s.correctIndex = null;
                    } else if ((s.correctIndex ?? -1) > i) {
                      s.correctIndex = s.correctIndex! - 1;
                    }
                    _push();
                  }),
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() {
              _rows.add(TextEditingController());
              _push();
            }),
            icon: const Icon(Icons.add, size: 18),
            label: Text(l.paperAddChoice),
          ),
        ),
      ],
    );
  }
}

/// Owner 2026-11-24: the shared lettered list of a matching (or word-bank)
/// block, once, like on the paper; each question then picks its letter.
class _SharedChoicesCard extends StatefulWidget {
  const _SharedChoicesCard({super.key, required this.slot});
  final HskSlot slot;

  @override
  State<_SharedChoicesCard> createState() => _SharedChoicesCardState();
}

class _SharedChoicesCardState extends State<_SharedChoicesCard> {
  late final List<TextEditingController> _rows = [
    for (final o in context.read<HskPaperProofreadViewModel>().sharedOptions(widget.slot))
      TextEditingController(text: o),
  ];

  @override
  void dispose() {
    for (final c in _rows) {
      c.dispose();
    }
    super.dispose();
  }

  void _push() => context
      .read<HskPaperProofreadViewModel>()
      .setSharedOptions(widget.slot, [for (final c in _rows) c.text.trim()]);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = widget.slot;
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.paperSharedChoices, style: const TextStyle(fontWeight: FontWeight.w800)),
          if (s.section.isNotEmpty)
            Text(s.section, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          for (var i = 0; i < _rows.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 26,
                    child: Text(_letter(i),
                        style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.teal)),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _rows[i],
                      decoration:
                          const InputDecoration(isDense: true, border: OutlineInputBorder()),
                      onChanged: (_) => _push(),
                    ),
                  ),
                  IconButton(
                    tooltip: l.paperRemoveChoice,
                    onPressed: () => setState(() {
                      _rows.removeAt(i).dispose();
                      _push();
                    }),
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() {
                _rows.add(TextEditingController());
                _push();
              }),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l.paperAddChoice),
            ),
          ),
        ],
      ),
    );
  }
}

/// The right letter of a picture or shared-list question.
class _LetterAnswer extends StatelessWidget {
  const _LetterAnswer({required this.slot, required this.count});
  final HskSlot slot;
  final int count;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final vm = context.read<HskPaperProofreadViewModel>();
    return Row(
      children: [
        Text(l.paperRightAnswer, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(width: 10),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < count; i++)
                ChoiceChip(
                  label: Text(_letter(i)),
                  selected: slot.correctIndex == i,
                  onSelected: (v) => vm.setAnswer(slot, v ? i : null),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrueFalseAnswer extends StatelessWidget {
  const _TrueFalseAnswer({required this.slot});
  final HskSlot slot;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final vm = context.read<HskPaperProofreadViewModel>();
    return Row(
      children: [
        Text(l.paperRightAnswer, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(width: 10),
        ChoiceChip(
          label: const Text('✓'),
          selected: slot.correctIndex == 0,
          onSelected: (v) => vm.setAnswer(slot, v ? 0 : null),
        ),
        const SizedBox(width: 6),
        ChoiceChip(
          label: const Text('✗'),
          selected: slot.correctIndex == 1,
          onSelected: (v) => vm.setAnswer(slot, v ? 1 : null),
        ),
      ],
    );
  }
}


/// Owner 2026-11-24: word order: tap the words in the right order; the
/// order becomes the answer (the player shuffles them for students).
class _OrderAnswer extends StatefulWidget {
  const _OrderAnswer({super.key, required this.slot, required this.onOrdered});
  final HskSlot slot;
  final ValueChanged<List<String>> onOrdered;

  @override
  State<_OrderAnswer> createState() => _OrderAnswerState();
}

class _OrderAnswerState extends State<_OrderAnswer> {
  final List<int> _picked = [];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final words = widget.slot.segments;
    if (words.length < 2) return const SizedBox.shrink();
    final done = widget.slot.orderSet && _picked.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(l.paperRightOrder, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                done ? l.paperOrderDone : l.paperOrderHint,
                style: TextStyle(
                    fontSize: 12, color: done ? AppColors.success : AppColors.textSecondary),
              ),
            ),
            if (_picked.isNotEmpty)
              TextButton(
                onPressed: () => setState(_picked.clear),
                child: Text(l.paperOrderReset),
              ),
          ],
        ),
        if (_picked.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              [for (final i in _picked) words[i]].join(),
              style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.teal, fontSize: 16),
            ),
          ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var i = 0; i < words.length; i++)
              ActionChip(
                label: Text(words[i]),
                onPressed: _picked.contains(i)
                    ? null
                    : () {
                        setState(() => _picked.add(i));
                        if (_picked.length == words.length) {
                          final ordered = [for (final k in _picked) words[k]];
                          _picked.clear();
                          widget.onOrdered(ordered);
                        }
                      },
              ),
          ],
        ),
      ],
    );
  }
}
