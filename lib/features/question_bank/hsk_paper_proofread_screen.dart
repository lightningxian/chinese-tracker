import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../l10n/l10n.dart';
import '../../models/hsk_paper_draft.dart';
import '../../models/question_bank_item.dart';
import '../../services/hsk_paper/hsk_paper_import.dart';
import '../../services/hsk_paper/hsk_paper_reader.dart';
import '../../services/hsk_paper/paper_image_ops.dart';

/// ViewModel of the proofreading screen: the pages the reader saw, the
/// draft being corrected, the page on show and the save.
class HskPaperProofreadViewModel extends ChangeNotifier {
  HskPaperProofreadViewModel({
    required this.pages,
    required this.draft,
    required this.pdfBytes,
    required this.fileName,
  }) : startedAt = DateTime.now() {
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

  int selectedPage = 1;
  bool onlyFlagged = false;
  bool saving = false;
  String savingDetail = '';

  /// Slots the admin edited (the report counts the untouched ones).
  final Set<int> edited = {};

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

  /// New picture boxes for every picture question of [pageNumber].
  void setPictures(int pageNumber, List<PixelBox> boxes) {
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
        ownerId: ownerId,
        upload: upload,
        pictureLabel: l.paperUploadingPicture,
      );
      navigator.pop(HskProofreadResult(
        items: items,
        untouched: vm.draft.slots.length - vm.edited.length,
        total: vm.draft.slots.length,
        duration: DateTime.now().difference(vm.startedAt),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final vm = context.watch<HskPaperProofreadViewModel>();
    final draft = vm.draft;
    final wide = MediaQuery.sizeOf(context).width >= 980;
    final slots = vm.visible;
    final list = ListView(
      padding: const EdgeInsets.all(12),
      children: [
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
        for (final s in slots)
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
    );
    final pageView = _PageView(page: vm.page);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.navy,
        title: Text(l.paperProofreadTitle(
            draft.code.isEmpty ? '—' : draft.code)),
        actions: [
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
                if (draft.level != null) 'HSK ${draft.level}',
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

/// The page picture with a page picker; picture boxes drawn on it.
class _PageView extends StatelessWidget {
  const _PageView({required this.page});

  final PaperPage page;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final vm = context.watch<HskPaperProofreadViewModel>();
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
                    avatar: vm.draft.flagged.any((s) => s.page == p.number)
                        ? Icon(Icons.error_outline,
                            size: 16, color: AppColors.chipAmberFg)
                        : null,
                    onSelected: (_) => vm.showPage(p.number),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: InteractiveViewer(
            maxScale: 5,
            child: Center(child: _BoxedPage(page: page, boxes: page.pictureBoxes)),
          ),
        ),
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

  @override
  void dispose() {
    _prompt.dispose();
    _options.dispose();
    _segments.dispose();
    _keyword.dispose();
    super.dispose();
  }

  void _changed() =>
      context.read<HskPaperProofreadViewModel>().changed(widget.slot);

  String _doubtName(AppLocalizations l, String doubt) => switch (doubt) {
        HskSlot.doubtTones => l.paperFlagTones,
        HskSlot.doubtSplit => l.paperFlagSplit,
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
        _ => l.paperFormChoice,
      };

  Future<void> _editBoxes() async {
    final page = widget.page;
    if (page == null) return;
    final vm = context.read<HskPaperProofreadViewModel>();
    final boxes = await showDialog<List<PixelBox>>(
      context: context,
      builder: (_) => _BoxEditorDialog(page: page, initial: widget.slot.pictures),
    );
    if (boxes != null) vm.setPictures(page.number, boxes);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = widget.slot;
    final usesOptions = s.form == HskForm.choice ||
        s.form == HskForm.matching ||
        s.form == HskForm.wordBank;
    final doubt = s.checked ? null : s.doubt;
    InputDecoration deco(String label, {String? helper}) => InputDecoration(
          labelText: label,
          helperText: helper,
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
                  setState(() => s.form = f);
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
            if (usesOptions) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _options,
                minLines: 2,
                maxLines: 8,
                decoration: deco(l.paperOptions, helper: l.paperOptionsHint),
                onChanged: (v) {
                  s.options = v.split('\n').map((o) => o.trim()).toList();
                  while (s.options.isNotEmpty && s.options.last.isEmpty) {
                    s.options.removeLast();
                  }
                  s.optionsIncomplete = false;
                  _changed();
                },
              ),
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
                  s.keyword = v;
                  _changed();
                },
              ),
            ],
          ],
        ],
      ),
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
  Widget build(BuildContext context) {
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
          onPressed: () => Navigator.pop(context),
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
