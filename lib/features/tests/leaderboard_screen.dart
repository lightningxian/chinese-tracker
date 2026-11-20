import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/shell_nested_page.dart';
import '../../l10n/l10n.dart';
import '../../models/leaderboard.dart';
import '../../models/test_track.dart';
import '../../services/auth_service.dart';
import '../../services/promotion_service.dart';
import 'test_labels.dart';

/// What the leaderboard screen shows: the ranked board of one code and,
/// for staff, the staff label of each student (Build 2B, LB-01).
class LeaderboardViewModel extends ChangeNotifier {
  LeaderboardViewModel({
    required this.codeId,
    required this.staff,
    PromotionService? service,
  }) : _service = service ?? PromotionService() {
    _sub = _service.watchLeaderboard(codeId).listen(_onEntries, onError: (Object e) {
      error = e;
      loading = false;
      notifyListeners();
    });
  }

  final String codeId;
  final bool staff;
  final PromotionService _service;
  StreamSubscription<List<LeaderboardEntry>>? _sub;

  List<LeaderboardEntry> entries = const [];
  Map<String, String> staffLabels = const {};
  bool loading = true;
  Object? error;

  Future<void> _onEntries(List<LeaderboardEntry> list) async {
    entries = list;
    loading = false;
    notifyListeners();
    if (!staff) return;
    final missing = list.map((e) => e.studentId).where((id) => !staffLabels.containsKey(id));
    if (missing.isEmpty) return;
    try {
      staffLabels = {...staffLabels, ...await _service.staffLabels(missing)};
      notifyListeners();
    } catch (e) {
      debugPrint('leaderboard: staff labels: $e');
    }
  }

  String nameOf(LeaderboardEntry e) => staff ? (staffLabels[e.studentId] ?? e.name) : e.name;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// **Leaderboard** of a test code. Students see other students by the
/// Chinese name and their own row highlighted; staff see `中文名 (Latin)`.
/// Pending, invalid and placement results are never on it.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({
    super.key,
    required this.codeId,
    this.staff = false,
    this.embedded = false,
  });

  final String codeId;
  final bool staff;
  final bool embedded;

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late final _vm = LeaderboardViewModel(codeId: widget.codeId, staff: widget.staff);

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final me = context.read<AuthService>().appUser?.uid;
    return ShellNestedPage(
      embedded: widget.embedded,
      title: l.leaderboardTitle(widget.codeId),
      child: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          if (_vm.error != null) {
            return EmptyState(
              icon: Icons.lock_outline,
              title: l.leaderboardLockedTitle,
              subtitle: l.leaderboardLockedSubtitle,
            );
          }
          if (_vm.loading) return const Center(child: CircularProgressIndicator());
          if (_vm.entries.isEmpty) {
            return EmptyState(
              icon: Icons.emoji_events_outlined,
              title: l.leaderboardEmptyTitle,
              subtitle: l.leaderboardEmptySubtitle,
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                widget.staff ? l.leaderboardIntroStaff : l.leaderboardIntroStudent,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              for (final e in _vm.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _EntryRow(entry: e, name: _vm.nameOf(e), mine: e.studentId == me),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry, required this.name, required this.mine});

  final LeaderboardEntry entry;
  final String name;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final e = entry;
    final medal = switch (e.rank) {
      1 => const Color(0xFFD4A017),
      2 => const Color(0xFF9EA7B0),
      3 => const Color(0xFFB07142),
      _ => null,
    };
    return Container(
      decoration: mine
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.teal, width: 2),
            )
          : null,
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: CircleAvatar(
                radius: 17,
                backgroundColor: medal ?? AppColors.surface,
                child: Text(
                  '${e.rank}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: medal == null ? AppColors.navy : Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mine ? l.leaderboardYou(name) : name,
                    style: AppTextStyles.question.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 10,
                    children: [
                      for (final p in e.parts)
                        Text(
                          '${_skillName(l, p.skill)} ${p.mark}',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      if (e.seconds != null)
                        Text(
                          clockText(e.seconds!),
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${e.total} / ${e.max}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                Text(
                  e.passed ? '合格' : '不合格',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: e.passed ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _skillName(AppLocalizations l, String value) {
    for (final s in TestSkill.values) {
      if (s.value == value) return s.localized(l);
    }
    return value;
  }
}
