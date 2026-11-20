import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/shell_nested_page.dart';
import '../../l10n/l10n.dart';
import '../../models/app_user.dart';
import '../../models/leaderboard.dart';
import '../../services/promotion_service.dart';
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

  @override
  void dispose() {
    _vm.dispose();
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
          ],
        ),
      ),
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
