import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../../l10n/l10n.dart';
import '../../l10n/labels_exercises.dart';
import '../../models/exercise_category.dart';

/// Tinted label for the type of exercise (exercise / quiz / exam / HSK),
/// used in the question bank and the exercises table.
class ExerciseCategoryChip extends StatelessWidget {
  const ExerciseCategoryChip({super.key, required this.category});
  final ExerciseCategory category;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final (bg, fg) = switch (category) {
      ExerciseCategory.exercise => (AppColors.chipBlueBg, AppColors.chipBlueFg),
      ExerciseCategory.quiz => (AppColors.chipGreenBg, AppColors.chipGreenFg),
      ExerciseCategory.exam => (AppColors.chipAmberBg, AppColors.chipAmberFg),
      ExerciseCategory.hskSimulation => (
          AppColors.chipPurpleBg,
          AppColors.chipPurpleFg
        ),
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          category.localized(l),
          style: TextStyle(
            color: fg,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
