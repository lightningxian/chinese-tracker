import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/paging/date_range.dart';
import '../../core/paging/paged_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/paging_bars.dart';
import '../../core/widgets/shell_nested_page.dart';
import '../../l10n/l10n.dart';
import '../../models/app_user.dart';
import '../../models/marking_item.dart';
import '../../services/marking_service.dart';
import 'test_labels.dart';

/// What the marking screen is doing: which item is being saved, and the
/// last error. The queue itself is a live stream from [MarkingService].
class MarkingViewModel extends ChangeNotifier {
  MarkingViewModel({MarkingService? service})
      : service = service ?? MarkingService();

  final MarkingService service;
  String? savingId;
  String? openId;

  void toggle(String id) {
    openId = openId == id ? null : id;
    notifyListeners();
  }

  Future<void> run(String id, Future<void> Function() action) async {
    savingId = id;
    notifyListeners();
    try {
      await action();
      if (openId == id) openId = null;
    } finally {
      savingId = null;
      notifyListeners();
    }
  }
}

/// **Marking** (Build 2A): the answers a teacher must look at, from tests
/// and from practice packages. Typed answers the matcher gave half credit:
/// keep the half, give full or zero. Free writing: the rubric (grammar 40,
/// vocabulary 30, content 30). Teachers see their own queue, admins all.
class MarkingScreen extends StatefulWidget {
  const MarkingScreen({super.key, required this.user, this.embedded = false});

  final AppUser user;
  final bool embedded;

  @override
  State<MarkingScreen> createState() => _MarkingScreenState();
}

class _MarkingScreenState extends State<MarkingScreen> {
  final _vm = MarkingViewModel();

  /// Build 9A session 2: 25 answers a page. The queue opens on all dates
  /// (an old answer must not hide behind "this month"); the range bar
  /// narrows it.
  late final PagedController<MarkingItem> _pages = PagedController<MarkingItem>(
    build: (range) => _vm.service.openSource(widget.user, range),
    range: const DateRangeSel.all(),
  );

  @override
  void initState() {
    super.initState();
    // A marked answer leaves the queue: read the page again.
    _vm.addListener(_afterMark);
  }

  String? _wasSaving;

  void _afterMark() {
    if (_wasSaving != null && _vm.savingId == null) _pages.refresh();
    _wasSaving = _vm.savingId;
  }

  @override
  void dispose() {
    _vm.removeListener(_afterMark);
    _vm.dispose();
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ShellNestedPage(
      embedded: widget.embedded,
      title: l.markingTitle,
      child: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) => PagedListBody<MarkingItem>(
          controller: _pages,
          padding: const EdgeInsets.all(16),
          maxWidth: 960,
          emptyIcon: Icons.task_alt,
          emptyTitle: l.markingEmptyTitle,
          emptySubtitle: l.markingEmptySubtitle,
          header: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.markingIntro, style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              ListenableBuilder(
                listenable: _pages,
                builder: (context, _) =>
                    DateRangeBar(value: _pages.range, onChanged: _pages.setRange),
              ),
            ],
          ),
          itemBuilder: (context, item) => _MarkingTile(item: item, vm: _vm),
        ),
      ),
    );
  }
}

class _MarkingTile extends StatelessWidget {
  const _MarkingTile({required this.item, required this.vm});

  final MarkingItem item;
  final MarkingViewModel vm;

  String _reason(AppLocalizations l) => switch (item.reason) {
        MarkingReason.oneCharacter => l.markingReasonOneCharacter,
        MarkingReason.tone => l.markingReasonTone,
        MarkingReason.freeWriting => l.markingReasonFreeWriting,
      };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final open = vm.openId == item.id;
    final when = item.createdAt == null
        ? ''
        : DateFormat.yMMMd().add_Hm().format(item.createdAt!);
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => vm.toggle(item.id),
            child: Row(
              children: [
                Icon(
                  item.isFreeWriting ? Icons.edit_note : Icons.star_half,
                  color: AppColors.chipAmberFg,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.studentName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                      Text(
                        [item.title, _reason(l), if (when.isNotEmpty) when]
                            .join(' · '),
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(open ? Icons.expand_less : Icons.expand_more),
              ],
            ),
          ),
          if (open) ...[
            const Divider(height: 20),
            _MarkingDetail(item: item, vm: vm),
          ],
        ],
      ),
    );
  }
}

class _MarkingDetail extends StatefulWidget {
  const _MarkingDetail({required this.item, required this.vm});

  final MarkingItem item;
  final MarkingViewModel vm;

  @override
  State<_MarkingDetail> createState() => _MarkingDetailState();
}

class _MarkingDetailState extends State<_MarkingDetail> {
  double _grammar = 0;
  double _vocabulary = 0;
  double _content = 0;

  MarkingItem get item => widget.item;

  int get _rubricTotal =>
      _grammar.round() + _vocabulary.round() + _content.round();

  String _points(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  Future<void> _save(BuildContext context, Future<void> Function() action) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.vm.run(item.id, action);
      messenger.showSnackBar(SnackBar(content: Text(l.markingSaved)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(testErrorMessage(l, e))));
    }
  }

  Widget _slider(String label, double value, int max, ValueChanged<double> on) {
    return Row(
      children: [
        SizedBox(width: 110, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            max: max.toDouble(),
            divisions: max,
            label: '${value.round()}',
            onChanged: (v) => setState(() => on(v)),
          ),
        ),
        SizedBox(
          width: 72,
          child: Text('${value.round()} / $max',
              textAlign: TextAlign.end, maxLines: 1, softWrap: false),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final saving = widget.vm.savingId == item.id;
    final service = widget.vm.service;
    final check = item.keywordCheck;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.markingQuestion, style: TextStyle(color: AppColors.textSecondary)),
        Text(item.prompt, style: AppTextStyles.question.copyWith(fontSize: 18)),
        if (item.imageUrl.isNotEmpty) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(item.imageUrl,
                height: 160,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          ),
        ],
        const SizedBox(height: 12),
        Text(l.markingAnswer, style: TextStyle(color: AppColors.textSecondary)),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.chipAmberFg.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: SelectableText(
            item.answerText.isEmpty ? '—' : item.answerText,
            style: AppTextStyles.question.copyWith(fontSize: 20, height: 1.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(l.playEssayCount(item.characterCount),
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        if (item.accepted.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(l.markingKeys(item.accepted.join(' / ')),
              style: TextStyle(
                  color: AppColors.success, fontWeight: FontWeight.w600)),
        ],
        if (item.keywords.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final k in check.found)
                Chip(
                  avatar: Icon(Icons.check, size: 16, color: AppColors.success),
                  label: Text(k, style: AppTextStyles.question),
                ),
              for (final k in check.missing)
                Chip(
                  avatar: Icon(Icons.close, size: 16, color: AppColors.error),
                  label: Text(k, style: AppTextStyles.question),
                ),
            ],
          ),
          Text(
            l.markingKeywordsFound(check.found.length, item.keywords.length),
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
        const SizedBox(height: 14),
        if (!item.isFreeWriting) ...[
          Text(
            l.markingMachineGave(_points(item.machinePoints), _points(item.maxPoints)),
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: saving
                    ? null
                    : () => _save(context, () => service.markTyped(item.id, 'full')),
                child: Text(l.markingFull),
              ),
              OutlinedButton(
                onPressed: saving
                    ? null
                    : () => _save(context, () => service.markTyped(item.id, 'keep')),
                child: Text(l.markingKeepHalf),
              ),
              OutlinedButton(
                onPressed: saving
                    ? null
                    : () => _save(context, () => service.markTyped(item.id, 'zero')),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                child: Text(l.markingZero),
              ),
            ],
          ),
        ] else ...[
          _slider(l.markingGrammar, _grammar, MarkingRubric.grammar,
              (v) => _grammar = v),
          _slider(l.markingVocabulary, _vocabulary, MarkingRubric.vocabulary,
              (v) => _vocabulary = v),
          _slider(l.markingContent, _content, MarkingRubric.content,
              (v) => _content = v),
          const SizedBox(height: 4),
          Text(
            l.markingRubricTotal(_rubricTotal,
                _points(_rubricTotal / 100 * item.maxPoints), _points(item.maxPoints)),
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: saving
                  ? null
                  : () => _save(
                        context,
                        () => service.markRubric(
                          item.id,
                          grammar: _grammar.round(),
                          vocabulary: _vocabulary.round(),
                          content: _content.round(),
                        ),
                      ),
              icon: const Icon(Icons.save_outlined),
              label: Text(l.markingSave),
            ),
          ),
        ],
        if (saving) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(),
        ],
      ],
    );
  }
}
