import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import '../utils/progress_utils.dart';
import 'app_card.dart';

class TermProgressCard extends StatelessWidget {
  const TermProgressCard({
    super.key,
    required this.term,
    this.subtitle,
  });

  final TermProgress term;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      term.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                '${term.completedCount}/${term.termSize}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: term.progress,
              minHeight: 8,
              backgroundColor: AppColors.border,
              color: AppColors.teal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${term.totalInTerm} lessons published in this term',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class ProgressHistoryTile extends StatelessWidget {
  const ProgressHistoryTile({super.key, required this.item});

  final EnrichedProgress item;

  @override
  Widget build(BuildContext context) {
    final date = item.completedAt;
    final dateLabel =
        date != null ? DateFormat('d MMM yyyy').format(date) : null;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            item.completed ? Icons.check_circle : Icons.radio_button_unchecked,
            color: item.completed ? AppColors.success : AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.lessonTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    item.termLabel,
                    if (item.lesson?.order != null)
                      'Lesson ${item.lesson!.order}',
                    if (dateLabel != null) dateLabel,
                  ].join(' · '),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (item.score != null)
            Text(
              '${item.score}%',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
        ],
      ),
    );
  }
}

class ProgressSummaryRow extends StatelessWidget {
  const ProgressSummaryRow({
    super.key,
    required this.completed,
    required this.avgScore,
    this.thirdLabel,
    this.thirdValue,
  });

  final int completed;
  final int? avgScore;
  final String? thirdLabel;
  final String? thirdValue;

  @override
  Widget build(BuildContext context) {
    final cards = [
      SummaryTile(label: 'Completed', value: '$completed'),
      SummaryTile(
        label: 'Avg. score',
        value: avgScore != null ? '$avgScore%' : '—',
      ),
      if (thirdLabel != null && thirdValue != null)
        SummaryTile(label: thirdLabel!, value: thirdValue!),
    ];

    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: cards[i]),
        ],
      ],
    );
  }
}

/// Big number over a label, for summary rows.
class SummaryTile extends StatelessWidget {
  const SummaryTile({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
          ),
          Text(label, style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
