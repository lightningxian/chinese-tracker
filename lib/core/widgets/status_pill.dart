import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../theme/app_theme.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.backgroundColor,
  });

  final String label;
  final Color color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// A [StatusPill] whose label is looked up from the UI language at build
/// time, so the [StatusPills] helpers can stay context-free.
class _LocalizedStatusPill extends StatusPill {
  const _LocalizedStatusPill({required this.resolve, required super.color})
      : super(label: '');

  final String Function(AppLocalizations l) resolve;

  @override
  Widget build(BuildContext context) {
    return StatusPill(
      label: resolve(context.l10n),
      color: color,
      backgroundColor: backgroundColor,
    );
  }
}

class StatusPills {
  static StatusPill open() => _LocalizedStatusPill(
        resolve: (l) => l.statusPillOpen,
        color: AppColors.success,
      );

  static StatusPill closed() => _LocalizedStatusPill(
        resolve: (l) => l.statusPillClosed,
        color: AppColors.textSecondary,
      );

  static StatusPill full() => _LocalizedStatusPill(
        resolve: (l) => l.commonFull,
        color: AppColors.error,
      );

  static StatusPill concluded() => _LocalizedStatusPill(
        resolve: (l) => l.statusPillConcluded,
        color: AppColors.navy,
      );
}
