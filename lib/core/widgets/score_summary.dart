import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

/// Figma-aligned quiz / exercise completion summary.
class ScoreSummary extends StatelessWidget {
  const ScoreSummary({
    super.key,
    required this.scorePercent,
    required this.correctCount,
    required this.totalCount,
    required this.primaryLabel,
    this.onPrimaryPressed,
    this.loading = false,
    this.subtitle,
    this.timeLabel,
    this.details = const [],
  });

  final int scorePercent;
  final int correctCount;
  final int totalCount;
  final String primaryLabel;
  final VoidCallback? onPrimaryPressed;
  final bool loading;
  final String? subtitle;

  /// Time taken, e.g. "04:32"; shown under the correct count.
  final String? timeLabel;

  /// Widgets shown between the score card and the button (the review).
  final List<Widget> details;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final passed = scorePercent >= 70;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: details.isEmpty ? 420 : 640),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: (passed ? AppColors.success : AppColors.teal)
                            .withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        passed
                            ? Icons.emoji_events_outlined
                            : Icons.school_outlined,
                        color: passed ? AppColors.success : AppColors.teal,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '$scorePercent%',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.scoreSummaryCorrectOf(correctCount, totalCount),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                    if (timeLabel != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer_outlined,
                              size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            timeLabel!,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (subtitle != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      passed
                          ? l.scoreSummaryPassed
                          : l.scoreSummaryKeepPracticing,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: passed ? AppColors.success : AppColors.navy,
                      ),
                    ),
                  ],
                ),
              ),
              for (final detail in details) ...[
                const SizedBox(height: 12),
                detail,
              ],
              const SizedBox(height: 24),
              if (loading)
                const CircularProgressIndicator()
              else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onPrimaryPressed,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(primaryLabel),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
