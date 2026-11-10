import 'package:flutter/material.dart';

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

class StatusPills {
  static StatusPill open() => StatusPill(
        label: 'Open',
        color: AppColors.success,
      );

  static StatusPill closed() => StatusPill(
        label: 'Closed',
        color: AppColors.textSecondary,
      );

  static StatusPill full() => StatusPill(
        label: 'Full',
        color: AppColors.error,
      );

  static StatusPill concluded() => StatusPill(
        label: 'Concluded',
        color: AppColors.navy,
      );
}
