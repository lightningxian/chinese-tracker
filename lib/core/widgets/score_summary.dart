import 'package:flutter/material.dart';

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
  });

  final int scorePercent;
  final int correctCount;
  final int totalCount;
  final String primaryLabel;
  final VoidCallback? onPrimaryPressed;
  final bool loading;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final passed = scorePercent >= 70;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
                        passed ? Icons.emoji_events_outlined : Icons.school_outlined,
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
                      '$correctCount of $totalCount correct',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      passed ? 'Great work!' : 'Keep practicing — you\'re improving.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: passed ? AppColors.success : AppColors.navy,
                      ),
                    ),
                  ],
                ),
              ),
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
