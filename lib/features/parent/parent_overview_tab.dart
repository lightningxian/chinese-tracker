import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/progress_utils.dart';
import '../../core/utils/exercise_utils.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/exercise_results_list.dart';
import '../../core/widgets/stat_card.dart';
import '../../l10n/l10n.dart';
import '../../models/app_user.dart';
import '../../models/attendance_record.dart';
import '../../models/exercise_result.dart';
import '../../models/lesson.dart';
import '../../models/student_class_term.dart';
import '../../models/student_progress.dart';
import '../../services/firestore_service.dart';

/// Read-only summary of one child's progress, grades and attendance.
class ParentOverviewTab extends StatelessWidget {
  const ParentOverviewTab({super.key, required this.child});

  final AppUser child;

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final ownerId = AppConstants.contentOwnerFor(child);
    final l = context.l10n;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          child.displayNameIndonesian,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          ProgressUtils.formatStudentLevel(child),
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        StreamBuilder<List<StudentClassTerm>>(
          stream: firestore.watchStudentClassTerms(child.uid),
          builder: (context, termSnap) {
            final remaining =
                firestore.totalRemainingClassSessions(termSnap.data ?? []);
            return _StatCard(
              icon: Icons.confirmation_number_outlined,
              label: l.parentOverviewSessionsRemaining,
              value: '$remaining',
            );
          },
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<StudentProgress>>(
          stream: firestore.watchStudentProgress(child.uid),
          builder: (context, progressSnap) {
            final progress = progressSnap.data ?? [];
            final completed = progress.where((p) => p.completed).length;
            final avg = ProgressUtils.averageScore(progress);
            return StreamBuilder<List<Lesson>>(
              stream: firestore.watchLessons(ownerId),
              builder: (context, lessonsSnap) {
                final lessons = ProgressUtils.lessonsForStudent(
                  lessonsSnap.data ?? [],
                  child,
                );
                return Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.menu_book_outlined,
                        label: l.parentOverviewLessonsDone,
                        value: '$completed/${lessons.length}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.grade_outlined,
                        label: l.parentOverviewAvgScore,
                        value: avg == null ? '—' : '${avg.round()}%',
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
        const SizedBox(height: 20),
        AppCard(
          onTap: () => context.push('/parent/calendar/${child.uid}'),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    Icon(Icons.calendar_month_outlined, color: AppColors.teal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(l.commonViewClassCalendar,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
              ),
              Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          onTap: () => context.push('/parent/grades/${child.uid}'),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.navy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.grading_outlined, color: AppColors.navy),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(l.commonViewGrades,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
              ),
              Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          onTap: () => context.push('/parent/materials/${child.uid}'),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.brandYellow.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.folder_open_outlined,
                    color: AppColors.brandYellow),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(l.commonLearningMaterials,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
              ),
              Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SectionHeader(title: l.parentOverviewRecentGrades),
        StreamBuilder<List<ExerciseResult>>(
          stream: firestore.watchStudentExerciseResults(child.uid),
          builder: (context, snap) {
            final results = ExerciseUtils.newestFirst(snap.data ?? const []);
            if (results.isEmpty) {
              return _EmptyLine(text: l.parentOverviewNoGrades);
            }
            return Column(
              children: [
                for (final r in results.take(5))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ExerciseResultTile(result: r),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        SectionHeader(title: l.parentOverviewRecentClasses),
        StreamBuilder<List<AttendanceRecord>>(
          stream: firestore.watchStudentJoinedSessions(child.uid),
          builder: (context, snap) {
            final records = snap.data ?? [];
            if (records.isEmpty) {
              return _EmptyLine(text: l.parentOverviewNoClasses);
            }
            return Column(
              children: [
                for (final record in records.take(5))
                  AppCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.event_available_outlined,
                            color: AppColors.teal, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            record.sessionTitle.isNotEmpty
                                ? record.sessionTitle
                                : l.commonClassSession,
                          ),
                        ),
                        Text(
                          record.sessionDate,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return StatCard(
      label: label,
      value: value,
      icon: icon,
      tint: StatChipTint.blue,
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(text, style: TextStyle(color: AppColors.textSecondary)),
    );
  }
}
