import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../l10n/l10n.dart';
import '../../models/app_user.dart';
import '../../models/leaderboard.dart';
import '../../models/test_track.dart';
import '../../services/promotion_service.dart';
import '../../services/test_service.dart';
import 'level_paths.dart';
import 'promotion_screen.dart' show levelGroupName;

/// The student's **Tests** place: type the token from the teacher, continue
/// a test after a reload, and the list of the student's own results.
class StudentTestsTab extends StatefulWidget {
  const StudentTestsTab({super.key, required this.student});

  final AppUser student;

  @override
  State<StudentTestsTab> createState() => _StudentTestsTabState();
}

class _StudentTestsTabState extends State<StudentTestsTab> {
  final _token = TextEditingController();
  final _service = TestService();
  late final _progress = PromotionService().watchProgress(widget.student.uid);
  late final _placement = PromotionService().watchPlacement(widget.student.uid);

  @override
  void dispose() {
    _token.dispose();
    super.dispose();
  }

  void _enter() {
    final t = _token.text.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    if (t.length != 6) return;
    _token.clear();
    context.push('/student/test?token=${Uri.encodeComponent(t)}');
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.testsEnterToken,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l.testsEnterTokenHint,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _token,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 6,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[A-Za-z0-9]')),
                      ],
                      style: const TextStyle(
                        fontSize: 24,
                        letterSpacing: 6,
                        fontWeight: FontWeight.w800,
                      ),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        counterText: '',
                        hintText: 'ABC234',
                      ),
                      onSubmitted: (_) => _enter(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _enter,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 18),
                    ),
                    child: Text(l.testsGo),
                  ),
                ],
              ),
            ],
          ),
        ),
        StreamBuilder<List<TestAttempt>>(
          stream: _service.watchMyOpenAttempts(widget.student.uid),
          builder: (context, snap) {
            final open = snap.data ?? const <TestAttempt>[];
            if (open.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                children: [
                  for (final a in open)
                    AppCard(
                      onTap: () => context.push(
                          '/student/test?code=${Uri.encodeComponent(a.codeId)}'),
                      child: Row(
                        children: [
                          Icon(Icons.play_circle_fill, color: AppColors.teal),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l.testsContinueTest(a.codeId),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        // Build 3: a placement test's recommendation.
        StreamBuilder<LevelPromotion?>(
          stream: _placement,
          builder: (context, snap) => snap.data == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _PlacementCard(promotion: snap.data!),
                ),
        ),
        // Build 2B: codes passed toward the next level (LV-03).
        const SizedBox(height: 12),
        StreamBuilder<PromotionProgress?>(
          stream: _progress,
          builder: (context, snap) => _ProgressCard(
            progress: snap.data,
            fallbackLevel: widget.student.level ?? '',
          ),
        ),
        const SizedBox(height: 20),
        Text(
          l.testsMyResults,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<TestResult>>(
          stream: _service.watchMyResults(widget.student.uid),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final results = snap.data!;
            if (results.isEmpty) {
              return EmptyState(
                icon: Icons.emoji_events_outlined,
                title: l.testsMyResultsEmptyTitle,
                subtitle: l.testsMyResultsEmptySubtitle,
              );
            }
            return Column(
              children: [
                for (final r in results)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      onTap: () => context.push('/student/test-result/${r.id}'),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${r.examTypeChinese} · ${r.code}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.navy,
                                  ),
                                ),
                                if (r.valid && !r.isPendingMarking)
                                  _RankText(codeId: r.codeId, uid: widget.student.uid),
                                if (r.finishedAt != null)
                                  Text(
                                    DateFormat.yMMMd().format(r.finishedAt!),
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            '${r.total} / ${r.max}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            !r.valid
                                ? l.testsInvalid
                                : r.isPendingMarking
                                    ? l.testsPendingMarking
                                    : r.passed
                                        ? '合格'
                                        : '不合格',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: r.isPendingMarking
                                  ? AppColors.chipAmberFg
                                  : r.valid && r.passed
                                      ? AppColors.success
                                      : AppColors.error,
                            ),
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
    );
  }
}

/// "2 of 3 codes passed" at the student's level (from promotion_progress).
/// "Placement test: waiting for the admin", then the result.
class _PlacementCard extends StatelessWidget {
  const _PlacementCard({required this.promotion});

  final LevelPromotion promotion;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = promotion;
    final text = switch (p.status) {
      'waiting' => l.placementStudentWaiting(p.toLevel),
      'approved' => l.placementStudentApproved(p.toLevel),
      'declined' => l.placementStudentDeclined,
      _ => '',
    };
    if (text.isEmpty) return const SizedBox.shrink();
    return AppCard(
      child: Row(
        children: [
          Icon(
            p.status == 'waiting' ? Icons.hourglass_top : Icons.explore_outlined,
            color: AppColors.teal,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.placementTestLabel,
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: AppColors.navy)),
                const SizedBox(height: 2),
                Text(text),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.progress, required this.fallbackLevel});

  final PromotionProgress? progress;
  final String fallbackLevel;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = progress;
    final level = p?.level.isNotEmpty == true ? p!.level : fallbackLevel;
    if (level.isEmpty) return const SizedBox.shrink();
    final count = p?.count ?? 0;
    final min = p?.minCodes ?? 3;
    final next = p?.next ?? '';
    final group = levelGroupName(l, level);
    // Owner 2026-11-24: the level's checklist replaces the code count.
    if (p != null && p.usesPath && next.isNotEmpty) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LevelPathProgress(progress: p),
            const SizedBox(height: 6),
            Text(
              p.declined
                  ? l.promotionNotYetStudent(next)
                  : p.done >= p.total
                      ? l.promotionWaitingForAdmin(next)
                      : l.promotionTowards(next),
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: AppColors.teal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  group.isEmpty ? level : '$level · $group',
                  style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l.promotionProgress(count > min ? min : count, min),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: min == 0 ? 0 : (count / min).clamp(0, 1).toDouble(),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            next.isEmpty
                ? l.promotionTopLevel
                : p?.declined == true
                    ? l.promotionNotYetStudent(next)
                    : count >= min
                    ? l.promotionWaitingForAdmin(next)
                    : l.promotionTowards(next),
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          if (p != null && p.codes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final c in p.codes)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text('${c.code} · ${c.total}'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// "Rank 2 of 15" on a code's board (the student may read boards of codes
/// they sat).
class _RankText extends StatelessWidget {
  const _RankText({required this.codeId, required this.uid});

  final String codeId;
  final String uid;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return StreamBuilder<List<LeaderboardEntry>>(
      stream: PromotionService().watchLeaderboard(codeId),
      builder: (context, snap) {
        final list = snap.data;
        if (list == null) return const SizedBox.shrink();
        final mine = list.where((e) => e.studentId == uid).firstOrNull;
        if (mine == null) return const SizedBox.shrink();
        return Text(
          l.leaderboardRankOf(mine.rank, list.length),
          style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.w700, fontSize: 12),
        );
      },
    );
  }
}
