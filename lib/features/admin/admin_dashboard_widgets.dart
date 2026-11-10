import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/stat_card.dart';
import '../../models/app_user.dart';
import '../../models/student_class_term.dart';
import '../../services/admin_report_service.dart';

const adminPurple = Color(0xFF7A4FBF);

/// Thin wrapper kept for existing call sites; delegates to the shared
/// [StatCard] so every dashboard tile shares the LinguaHub look.
class AdminStatCard extends StatelessWidget {
  const AdminStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return StatCard(
      label: label,
      value: value,
      icon: icon,
      tint: StatChipTint.fromColor(color),
      subtitle: subtitle,
      onTap: onTap,
    );
  }
}

class MonthlyStudentsChart extends StatelessWidget {
  const MonthlyStudentsChart({
    super.key,
    required this.months,
    this.onTap,
  });

  final List<MonthlyCount> months;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (months.isEmpty) return const SizedBox.shrink();

    final maxCount = months.fold<int>(
      1,
      (max, month) => month.count > max ? month.count : max,
    );

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'New students / month',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 128,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: months.map((month) {
                final heightFactor = month.count / maxCount;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor:
                                  month.count == 0 ? 0.06 : heightFactor,
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: month.count == 0
                                      ? AppColors.border
                                      : AppColors.teal.withValues(alpha: 0.9),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          month.label,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminQuickActionsCard extends StatelessWidget {
  const AdminQuickActionsCard({
    super.key,
    required this.onNewExercise,
    required this.onNewClass,
    this.showNewExercise = true,
  });

  final VoidCallback onNewExercise;
  final VoidCallback onNewClass;
  final bool showNewExercise;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Quick actions',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
          ),
          const SizedBox(height: 12),
          if (showNewExercise) ...[
            FilledButton.icon(
              onPressed: onNewExercise,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.navy,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New exercise'),
            ),
            const SizedBox(height: 8),
          ],
          FilledButton.icon(
            onPressed: onNewClass,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.navy,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.calendar_today_outlined, size: 18),
            label: const Text('New class'),
          ),
        ],
      ),
    );
  }
}

class AdminVoucherAlert {
  const AdminVoucherAlert({
    required this.student,
    required this.sessionsRemaining,
    required this.termId,
  });

  final AppUser student;
  final int sessionsRemaining;
  final String termId;

  bool get depleted => sessionsRemaining == 0;

  String get title => depleted
      ? '${student.name} — voucher depleted'
      : '${student.name} — low balance';

  String get subtitle =>
      '$sessionsRemaining session${sessionsRemaining == 1 ? '' : 's'} remaining';

  Color get accentColor => depleted ? AppColors.error : AppColors.teal;
}

abstract final class AdminAttentionUtils {
  static List<AdminVoucherAlert> buildVoucherAlerts({
    required List<AppUser> students,
    required List<StudentClassTerm> classTerms,
  }) {
    final byId = {for (final s in students) s.uid: s};
    final alerts = <AdminVoucherAlert>[];

    for (final term in classTerms) {
      if (!term.isWithinTermDates) continue;
      if (term.sessionsRemaining > 2) continue;

      final student = byId[term.studentId];
      if (student == null || !student.active) continue;

      alerts.add(
        AdminVoucherAlert(
          student: student,
          sessionsRemaining: term.sessionsRemaining,
          termId: term.id,
        ),
      );
    }

    alerts.sort((a, b) {
      if (a.depleted != b.depleted) return a.depleted ? -1 : 1;
      return a.sessionsRemaining.compareTo(b.sessionsRemaining);
    });

    return alerts;
  }
}

class AdminAttentionCard extends StatelessWidget {
  const AdminAttentionCard({
    super.key,
    required this.alert,
    this.onTap,
  });

  final AdminVoucherAlert alert;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: alert.accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.confirmation_number_outlined,
              color: alert.accentColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    alert.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class AdminSectionHeader extends StatelessWidget {
  const AdminSectionHeader({
    super.key,
    required this.title,
    this.badgeCount,
    this.onTap,
  });

  final String title;
  final int? badgeCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final titleRow = Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
        ),
        if (badgeCount != null && badgeCount! > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$badgeCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        if (onTap != null) ...[
          const Spacer(),
          Icon(
            Icons.chevron_right,
            color: AppColors.textSecondary,
          ),
        ],
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: onTap == null
          ? titleRow
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: titleRow,
              ),
            ),
    );
  }
}
