import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';
import '../../models/exercise_result.dart';
import '../theme/app_theme.dart';
import '../utils/exercise_utils.dart';
import 'app_card.dart';
import 'exercise_category_chip.dart';

/// One attempt in a student's exercise history: title, type of exercise,
/// date, correct count and time, with the score on the right. Used by the
/// student's Progress tab and the parent's overview.
class ExerciseResultTile extends StatelessWidget {
  const ExerciseResultTile({
    super.key,
    required this.result,
    this.fallbackTitle,
  });

  final ExerciseResult result;

  /// Title for results from before titles were stored with the attempt.
  final String? fallbackTitle;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final stored = result.exerciseTitle ?? '';
    final title = stored.isNotEmpty
        ? stored
        : (fallbackTitle ?? '').isNotEmpty
            ? fallbackTitle!
            : l.commonExerciseFallback;
    final submittedAt = result.submittedAt;
    final meta = [
      if (submittedAt != null)
        DateFormat('d MMM yyyy, HH:mm', l.localeName).format(submittedAt),
      if (result.hasCounts) l.resultCorrectOf(result.correct!, result.total!),
      if (result.durationSeconds != null)
        ExerciseUtils.formatClock(result.durationSeconds),
      if (result.late) l.resultLate,
    ].join(' · ');

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (result.category != null)
                      ExerciseCategoryChip(category: result.category!),
                    Text(
                      meta,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ScoreBadge(score: result.score),
        ],
      ),
    );
  }
}

/// "85%" in a tinted pill: green from 70, amber from 40, red below.
class ScoreBadge extends StatelessWidget {
  const ScoreBadge({super.key, required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final color = score >= 70
        ? AppColors.success
        : score >= 40
            ? AppColors.chipAmberFg
            : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$score%',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      ),
    );
  }
}
