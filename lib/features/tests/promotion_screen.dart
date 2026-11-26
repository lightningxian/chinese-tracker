import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';

import '../../core/paging/date_range.dart';
import '../../core/paging/paged_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/paging_bars.dart';
import '../../core/widgets/shell_nested_page.dart';
import '../../l10n/l10n.dart';
import '../../models/app_user.dart';
import '../../models/leaderboard.dart';
import '../../services/firestore_service.dart';
import '../../services/promotion_service.dart';
import 'level_paths.dart';
import 'test_labels.dart';
import 'test_player_screen.dart' show PlacementChip;

/// Which recommendation is being decided (the list itself is a live
/// stream).
class PromotionViewModel extends ChangeNotifier {
  PromotionViewModel({PromotionService? service}) : service = service ?? PromotionService();

  final PromotionService service;
  String? busyId;

  Future<void> run(String id, Future<void> Function() action) async {
    busyId = id;
    notifyListeners();
    try {
      await action();
    } finally {
      busyId = null;
      notifyListeners();
    }
  }
}

String levelGroupName(AppLocalizations l, String level) => switch (levelGroupOf(level)) {
      LevelGroup.beginner => l.levelGroupBeginner,
      LevelGroup.intermediate => l.levelGroupIntermediate,
      LevelGroup.advance => l.levelGroupAdvance,
      null => '',
    };

/// **Promotion** (admin, Build 2B): students who passed enough different
/// codes at their level. Approve moves the level up one (and writes the
/// history, tells the student and a linked parent); Decline keeps it and
/// stores the reason.
class PromotionScreen extends StatefulWidget {
  const PromotionScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<PromotionScreen> createState() => _PromotionScreenState();
}

class _PromotionScreenState extends State<PromotionScreen> {
  final _vm = PromotionViewModel();
  late final _waiting = _vm.service.watchWaiting();
  late final _minCodes = _vm.service.watchMinCodes();
  /// Build 9 Then list: declined recommendations, 25 a page, all dates.
  late final PagedController<LevelPromotion> _declined =
      PagedController<LevelPromotion>(
    build: (range) => _vm.service.declinedSource(range),
    range: const DateRangeSel.all(),
  );
  bool _showDeclined = false;

  /// Owner 2026-11-24 (Q12): promote straight away, optionally for one
  /// student and level already chosen (a declined recommendation).
  Future<void> _promote({String? studentId, String? toLevel}) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final students = await context.read<FirestoreService>().watchAllStudents().first;
    if (!mounted) return;
    final pick = await showDialog<_PromotePick>(
      context: context,
      builder: (_) => _PromoteDialog(
        students: students.where((u) => u.isStudent && !u.isPending).toList()
          ..sort((a, b) => a.staffLabel.compareTo(b.staffLabel)),
        studentId: studentId,
        toLevel: toLevel,
      ),
    );
    if (pick == null) return;
    try {
      await _vm.run('manual', () =>
          _vm.service.promote(pick.studentId, toLevel: pick.toLevel, reason: pick.reason));
      messenger.showSnackBar(SnackBar(content: Text(l.promotionApproved(pick.toLevel))));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(testErrorMessage(l, e))));
    }
  }

  @override
  void dispose() {
    _vm.dispose();
    _declined.dispose();
    super.dispose();
  }

  Future<void> _approve(LevelPromotion p) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _vm.run(p.id, () => _vm.service.decide(p.id, approve: true));
      messenger.showSnackBar(SnackBar(content: Text(l.promotionApproved(p.toLevel))));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(testErrorMessage(l, e))));
    }
  }

  Future<void> _decline(LevelPromotion p) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.promotionDeclineTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: l.promotionDeclineReason,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.commonCancel)),
          FilledButton(
            onPressed: () {
              final t = controller.text.trim();
              if (t.isNotEmpty) Navigator.pop(ctx, t);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l.promotionDecline),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null) return;
    try {
      await _vm.run(p.id, () => _vm.service.decide(p.id, approve: false, reason: reason));
      messenger.showSnackBar(SnackBar(content: Text(l.promotionDeclined)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(testErrorMessage(l, e))));
    }
  }

  Future<void> _editMinCodes(int current) async {
    final l = context.l10n;
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.promotionMinCodesTitle),
        children: [
          for (var n = 1; n <= 6; n++)
            ListTile(
              leading: Icon(n == current ? Icons.check_circle : Icons.circle_outlined,
                  color: n == current ? AppColors.teal : AppColors.textSecondary),
              title: Text(l.promotionMinCodesValue(n)),
              onTap: () => Navigator.pop(ctx, n),
            ),
        ],
      ),
    );
    if (picked == null || picked == current) return;
    await _vm.service.setMinCodes(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ShellNestedPage(
      embedded: widget.embedded,
      title: l.promotionTitle,
      child: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            StreamBuilder<int>(
              stream: _minCodes,
              builder: (context, snap) {
                final n = snap.data ?? 3;
                return AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.tune, color: AppColors.navy),
                      const SizedBox(width: 10),
                      Expanded(child: Text(l.promotionRule(n))),
                      TextButton(
                        onPressed: () => _editMinCodes(n),
                        child: Text(l.promotionChange),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            // Owner 2026-11-24: one checklist per level.
            const LevelPathsCard(),
            const SizedBox(height: 10),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.rocket_launch_outlined, color: AppColors.teal),
                  const SizedBox(width: 10),
                  Expanded(child: Text(l.promoteManualHint)),
                  FilledButton.icon(
                    onPressed: _vm.busyId == 'manual' ? null : () => _promote(),
                    icon: const Icon(Icons.trending_up, size: 18),
                    label: Text(l.promoteManualButton),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<LevelPromotion>>(
              stream: _waiting,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Text(testErrorMessage(l, snap.error!));
                }
                if (!snap.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final list = snap.data!;
                if (list.isEmpty) {
                  return EmptyState(
                    icon: Icons.trending_up,
                    title: l.promotionEmptyTitle,
                    subtitle: l.promotionEmptySubtitle,
                  );
                }
                return Column(
                  children: [
                    for (final p in list)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _PromotionCard(
                          promotion: p,
                          busy: _vm.busyId == p.id,
                          onApprove: () => _approve(p),
                          onDecline: () => _decline(p),
                        ),
                      ),
                  ],
                );
              },
            ),
            ListenableBuilder(
              listenable: _declined,
              builder: (context, _) {
                final total = _declined.total ?? _declined.items.length;
                if (total == 0 && !_declined.loading) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => setState(() => _showDeclined = !_showDeclined),
                        icon: Icon(_showDeclined ? Icons.expand_less : Icons.expand_more),
                        label: Text(l.promotionDeclinedList(total)),
                      ),
                    ),
                    if (_showDeclined)
                      PagedListBody<LevelPromotion>(
                        controller: _declined,
                        inline: true,
                        padding: EdgeInsets.zero,
                        separator: 8,
                        itemBuilder: (context, p) => AppCard(
                          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(AppUser.staffLabelOf(p.studentNameChinese, p.studentName),
                                        style: const TextStyle(fontWeight: FontWeight.w700)),
                                    Text('${p.fromLevel} → ${p.toLevel} · ${p.declineReason}',
                                        style: TextStyle(
                                            color: AppColors.textSecondary, fontSize: 12)),
                                  ],
                                ),
                              ),
                              OutlinedButton(
                                onPressed: _vm.busyId == 'manual'
                                    ? null
                                    : () => _promote(studentId: p.studentId, toLevel: p.toLevel),
                                child: Text(l.promoteAnyway),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PromotePick {
  const _PromotePick(this.studentId, this.toLevel, this.reason);
  final String studentId;
  final String toLevel;
  final String reason;
}

/// Pick a student, a higher level and a reason.
class _PromoteDialog extends StatefulWidget {
  const _PromoteDialog({required this.students, this.studentId, this.toLevel});

  final List<AppUser> students;
  final String? studentId;
  final String? toLevel;

  @override
  State<_PromoteDialog> createState() => _PromoteDialogState();
}

class _PromoteDialogState extends State<_PromoteDialog> {
  final _reason = TextEditingController();
  AppUser? _student;
  String? _level;

  @override
  void initState() {
    super.initState();
    for (final u in widget.students) {
      if (u.uid == widget.studentId) _student = u;
    }
    if (_student != null && _higher(_student!).contains(widget.toLevel)) {
      _level = widget.toLevel;
    }
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  static int _rank(String? level) => AppConstants.hskLevels.indexOf(level ?? '');

  List<String> _higher(AppUser u) =>
      AppConstants.hskLevels.where((lv) => _rank(lv) > _rank(u.level)).toList();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final levels = _student == null ? const <String>[] : _higher(_student!);
    final ok = _student != null && _level != null && _reason.text.trim().isNotEmpty;
    return AlertDialog(
      title: Text(l.promoteManualButton),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.promoteManualHelp,
                style: TextStyle(color: AppColors.textSecondary, height: 1.4)),
            const SizedBox(height: 14),
            Autocomplete<AppUser>(
              initialValue: TextEditingValue(text: _student?.staffLabel ?? ''),
              optionsBuilder: (v) {
                final q = v.text.trim().toLowerCase();
                return widget.students
                    .where((u) => q.isEmpty || u.staffLabel.toLowerCase().contains(q))
                    .take(30);
              },
              displayStringForOption: (u) => '${u.staffLabel} · ${u.level ?? '—'}',
              onSelected: (u) => setState(() {
                _student = u;
                _level = null;
              }),
              fieldViewBuilder: (context, controller, focus, onSubmit) => TextField(
                controller: controller,
                focusNode: focus,
                decoration: InputDecoration(
                  labelText: l.promoteStudentLabel,
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_student != null && levels.isEmpty)
              Text(l.promoteTopLevel, style: TextStyle(color: AppColors.error))
            else
              DropdownButtonFormField<String>(
                initialValue: _level,
                items: [
                  for (final lv in levels) DropdownMenuItem(value: lv, child: Text(lv)),
                ],
                onChanged: _student == null ? null : (v) => setState(() => _level = v),
                decoration: InputDecoration(
                  labelText: _student == null
                      ? l.promoteLevelLabel
                      : l.promoteLevelFrom(_student!.level ?? '—'),
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _reason,
              maxLines: 2,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(labelText: l.promoteReasonLabel),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.commonCancel)),
        FilledButton(
          onPressed: ok
              ? () => Navigator.pop(
                  context, _PromotePick(_student!.uid, _level!, _reason.text.trim()))
              : null,
          child: Text(_level == null ? l.promoteManualButton : l.promoteConfirm(_level!)),
        ),
      ],
    );
  }
}

class _PromotionCard extends StatelessWidget {
  const _PromotionCard({
    required this.promotion,
    required this.busy,
    required this.onApprove,
    required this.onDecline,
  });

  final LevelPromotion promotion;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = promotion;
    final from = levelGroupName(l, p.fromLevel);
    final to = levelGroupName(l, p.toLevel);
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (p.isPlacement)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: PlacementChip(label: l.placementTestLabel),
              ),
            ),
          Text(
            AppUser.staffLabelOf(p.studentNameChinese, p.studentName),
            style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy, fontSize: 16),
          ),
          const SizedBox(height: 2),
          Text(
            '${p.fromLevel} ($from) → ${p.toLevel} ($to)',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.teal),
          ),
          if (p.createdAt != null)
            Text(
              DateFormat.yMMMd().add_Hm().format(p.createdAt!),
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          const SizedBox(height: 8),
          Text(
              p.isPlacement
                  ? (p.passed ? l.placementPaperPassed : l.placementPaperFailed)
                  : l.promotionCodesPassed(p.codes.length),
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final c in p.codes)
                Chip(label: Text('${c.code} · ${c.total} / ${c.max}')),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: busy ? null : onApprove,
                icon: const Icon(Icons.check),
                label: Text(l.promotionApprove(p.toLevel)),
              ),
              OutlinedButton.icon(
                onPressed: busy ? null : onDecline,
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                icon: const Icon(Icons.close),
                label: Text(l.promotionDecline),
              ),
            ],
          ),
          if (busy) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }
}
