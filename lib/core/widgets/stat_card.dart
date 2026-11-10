import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_card.dart';

/// Pastel tints for the stat-tile icon chip (from the LinguaHub reference).
enum StatChipTint {
  green,
  blue,
  purple,
  amber;

  // Read from the palette that is on, so the tints follow light / dark.
  Color get background => switch (this) {
        StatChipTint.green => AppColors.chipGreenBg,
        StatChipTint.blue => AppColors.chipBlueBg,
        StatChipTint.purple => AppColors.chipPurpleBg,
        StatChipTint.amber => AppColors.chipAmberBg,
      };

  Color get foreground => switch (this) {
        StatChipTint.green => AppColors.chipGreenFg,
        StatChipTint.blue => AppColors.chipBlueFg,
        StatChipTint.purple => AppColors.chipPurpleFg,
        StatChipTint.amber => AppColors.chipAmberFg,
      };

  /// Maps the accent colors used by the old ad-hoc stat cards to a tint so
  /// call sites can keep passing a [Color].
  static StatChipTint fromColor(Color color) {
    if (color == AppColors.teal ||
        color == AppColors.success ||
        color == AppColors.brandGreen) {
      return StatChipTint.green;
    }
    if (color == AppColors.navy || color == AppColors.navyLight) {
      return StatChipTint.blue;
    }
    if (color == AppColors.brandYellow || color == AppColors.error) {
      return StatChipTint.amber;
    }
    return StatChipTint.purple;
  }
}

/// The shared stat tile: muted label, large bold value, optional subtitle,
/// and a soft-tinted rounded-square icon chip in the top-right.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.tint = StatChipTint.blue,
    this.subtitle,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final StatChipTint tint;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tint.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: tint.foreground),
          ),
        ],
      ),
    );
  }
}
