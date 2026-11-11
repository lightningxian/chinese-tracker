import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/exercise_utils.dart';
import '../../core/utils/progress_utils.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/exercise_widgets.dart';
import '../../core/widgets/responsive_card_grid.dart';
import '../../l10n/l10n.dart';
import '../../models/app_user.dart';
import '../../models/exercise.dart';
import '../../models/exercise_result.dart';
import '../../models/lesson.dart';
import '../../models/student_class_term.dart';
import '../../models/student_progress.dart';
import '../../services/firestore_service.dart';
import 'student_join_session_section.dart';

/// Student home, kept to about one screen: a header strip with three
/// tiles (sessions left, exercises done with the streak, average score),
/// one row of quick links, the open class sessions, then "Continue
/// learning" with at most three pending exercises and the next lesson.
/// Finished exercises live in Progress › Exercises.
class StudentHomeTab extends StatelessWidget {
  const StudentHomeTab({
    super.key,
    required this.student,
    required this.contentOwnerId,
    this.onOpenTab,
  });

  final AppUser student;
  final String contentOwnerId;

  /// Switches the shell to another tab (1 history, 2 lessons, 3 progress).
  final void Function(int index)? onOpenTab;

  static const _maxPendingShown = 3;

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final l = context.l10n;

    return StreamBuilder<List<ExerciseResult>>(
      stream: firestore.watchStudentExerciseResults(student.uid),
      builder: (context, resultsSnap) {
        final results = resultsSnap.data ?? const <ExerciseResult>[];
        final bestScores = ExerciseUtils.bestScores(results);

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _HeroHeader(
              student: student,
              results: results,
              bestScores: bestScores,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _QuickLink(
                  icon: Icons.calendar_month_outlined,
                  label: l.studentHomeQuickCalendar,
                  onTap: () => context.push('/student/calendar'),
                ),
                _QuickLink(
                  icon: Icons.workspace_premium_outlined,
                  label: l.studentHomeQuickGrades,
                  onTap: () => context.push('/student/grades'),
                ),
                _QuickLink(
                  icon: Icons.folder_open_outlined,
                  label: l.studentHomeQuickMaterials,
                  onTap: () => context.push('/student/materials'),
                ),
                if (onOpenTab != null)
                  _QuickLink(
                    icon: Icons.history_outlined,
                    label: l.studentHomeQuickHistory,
                    onTap: () => onOpenTab!(1),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            StudentJoinSessionSection(student: student),
            const SizedBox(height: 20),
            SectionHeader(title: l.studentHomeContinueLearning),
            _ContinueLearning(
              student: student,
              contentOwnerId: contentOwnerId,
              bestScores: bestScores,
              onOpenTab: onOpenTab,
            ),
          ],
        );
      },
    );
  }
}

/// Greeting on the left, the three tiles on the right (below it on a phone).
class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.student,
    required this.results,
    required this.bestScores,
  });

  final AppUser student;
  final List<ExerciseResult> results;
  final Map<String, int> bestScores;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final firestore = context.read<FirestoreService>();
    final greeting = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l.studentHomeGreeting(student.name.split(' ').first),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          ProgressUtils.formatStudentLevel(student),
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );

    final tiles = StreamBuilder<List<StudentClassTerm>>(
      stream: firestore.watchStudentClassTerms(student.uid),
      builder: (context, termsSnap) {
        final terms = termsSnap.data ?? const <StudentClassTerm>[];
        final remaining = firestore.totalRemainingClassSessions(terms);
        final active = terms.where((t) => t.isActive && t.isWithinTermDates);
        final primary = active.isEmpty
            ? null
            : active.reduce(
                (a, b) => a.deadlineDate.compareTo(b.deadlineDate) <= 0 ? a : b,
              );
        final deadline = DateTime.tryParse(primary?.deadlineDate ?? '');
        final stats = ExerciseUtils.resultStats(results);
        final streak = ExerciseUtils.streakDays(results);
        final sessionsSubtitle = terms.isEmpty
            ? l.studentHomeNoVoucher
            : deadline == null
                ? null
                : l.studentHomeUntil(
                    DateFormat('d MMM', l.localeName).format(deadline),
                  );

        return Row(
          children: [
            Expanded(
              child: _HeroTile(
                icon: Icons.confirmation_number_outlined,
                color: remaining <= 0
                    ? AppColors.error
                    : remaining <= 2
                        ? AppColors.brandYellow
                        : AppColors.teal,
                value: '$remaining',
                label: l.studentHomeSessionsLeft,
                subtitle: sessionsSubtitle,
                progress: primary == null || primary.packageSize == 0
                    ? null
                    : primary.sessionsRemaining / primary.packageSize,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _HeroTile(
                icon: streak > 0
                    ? Icons.local_fire_department
                    : Icons.fitness_center_outlined,
                color: streak > 0 ? AppColors.brandYellow : AppColors.navy,
                value: '${bestScores.length}',
                label: l.studentHomeExercisesDone,
                subtitle: streak > 0 ? l.studentHomeStreak(streak) : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _HeroTile(
                icon: Icons.star_outline,
                color: AppColors.success,
                value: stats.average == null ? '—' : '${stats.average}%',
                label: l.studentHomeAvgScore,
                subtitle:
                    stats.best == null ? null : l.studentHomeBest(stats.best!),
              ),
            ),
          ],
        );
      },
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 760) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: greeting),
              const SizedBox(width: 16),
              SizedBox(width: 440, child: tiles),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [greeting, const SizedBox(height: 14), tiles],
        );
      },
    );
  }
}

class _HeroTile extends StatelessWidget {
  const _HeroTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    this.subtitle,
    this.progress,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final String? subtitle;

  /// Fraction left on the voucher, drawn as a ring around the icon.
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 30,
                height: 30,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (progress != null)
                      CircularProgressIndicator(
                        value: progress!.clamp(0.0, 1.0),
                        strokeWidth: 3,
                        backgroundColor: color.withValues(alpha: 0.15),
                        color: color,
                      ),
                    Icon(icon, size: 16, color: color),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Shrinks instead of truncating on a narrow phone tile.
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (subtitle != null)
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                subtitle!,
                maxLines: 1,
                style: TextStyle(fontSize: 11, color: color),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  const _QuickLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.navy,
        backgroundColor: AppColors.card,
        side: BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      icon: Icon(icon, size: 18, color: AppColors.teal),
      label: Text(label),
    );
  }
}

/// Pending exercises (three at most), the next lesson, and a link to the
/// scores of everything already done.
class _ContinueLearning extends StatelessWidget {
  const _ContinueLearning({
    required this.student,
    required this.contentOwnerId,
    required this.bestScores,
    required this.onOpenTab,
  });

  final AppUser student;
  final String contentOwnerId;
  final Map<String, int> bestScores;
  final void Function(int index)? onOpenTab;

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final l = context.l10n;

    return StreamBuilder<List<Exercise>>(
      stream: firestore.watchAvailableExercisesForStudent(student),
      builder: (context, exercisesSnap) {
        return StreamBuilder<List<Lesson>>(
          stream: firestore.watchLessons(contentOwnerId),
          builder: (context, lessonsSnap) {
            if (exercisesSnap.connectionState == ConnectionState.waiting ||
                lessonsSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (exercisesSnap.hasError) {
              return AppCard(
                child: Text(
                  exercisesSnap.error.toString(),
                  style: TextStyle(color: AppColors.error),
                ),
              );
            }

            final availableExercises = exercisesSnap.data ?? [];
            final lessons = ProgressUtils.lessonsForStudent(
              lessonsSnap.data ?? [],
              student,
            );

            return StreamBuilder<List<StudentProgress>>(
              stream: firestore.watchStudentProgress(student.uid),
              builder: (context, progressSnap) {
                final progressByLesson = ProgressUtils.progressByLessonId(
                  progressSnap.data ?? [],
                );

                Lesson? nextLesson;
                for (final lesson in lessons) {
                  final record = progressByLesson[lesson.id];
                  if (record == null || !record.completed) {
                    nextLesson = lesson;
                    break;
                  }
                }

                final pending = availableExercises
                    .where((exercise) => bestScores[exercise.id] == null)
                    .toList()
                  ..sort(
                    (a, b) => ExerciseUtils.compareExercises(
                      a,
                      b,
                      bestScores: bestScores,
                    ),
                  );
                final doneCount = availableExercises
                    .where((exercise) => bestScores[exercise.id] != null)
                    .length;
                final counts = ExerciseUtils.practiceCounts(
                  availableExercises,
                  bestScores: bestScores,
                );

                if (availableExercises.isEmpty && nextLesson == null) {
                  return EmptyState(
                    icon: Icons.fitness_center_outlined,
                    title: l.studentHomeNoPracticeTitle,
                    subtitle: l.studentHomeNoPracticeSubtitle,
                  );
                }

                final titleStyle =
                    Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        );

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = ResponsiveCardGrid.columnCount(
                      constraints.maxWidth,
                      minCardWidth: 300,
                    );
                    final compact = columns > 1;
                    final shown =
                        pending.take(StudentHomeTab._maxPendingShown).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (availableExercises.isNotEmpty)
                          HomeworkSummaryBar(
                            pending: counts.pending,
                            overdue: counts.overdue,
                            done: counts.done,
                          ),
                        if (shown.isNotEmpty) ...[
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l.studentHomeLevelPractice(
                                    student.level ?? l.commonYourLevel,
                                  ),
                                  style: titleStyle,
                                ),
                              ),
                              if (pending.length > shown.length &&
                                  onOpenTab != null)
                                TextButton(
                                  onPressed: () => onOpenTab!(2),
                                  child: Text(
                                    l.studentHomeSeeAll(pending.length),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ResponsiveCardGrid(
                            width: constraints.maxWidth,
                            children: [
                              for (final exercise in shown)
                                AssignedExerciseCard(
                                  exercise: exercise,
                                  bestScore: null,
                                  compact: compact,
                                  onTap: () => context.push(
                                    '/student/exercise/${exercise.id}',
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (nextLesson != null) ...[
                          Text(l.studentHomeNextLesson, style: titleStyle),
                          const SizedBox(height: 8),
                          _NextLessonCard(lesson: nextLesson),
                        ] else if (lessons.isNotEmpty && pending.isEmpty) ...[
                          EmptyState(
                            icon: Icons.celebration_outlined,
                            title: l.studentHomeAllDoneTitle,
                            subtitle: l.studentHomeAllDoneSubtitle,
                          ),
                        ],
                        if (doneCount > 0 && onOpenTab != null) ...[
                          const SizedBox(height: 10),
                          AppCard(
                            onTap: () => onOpenTab!(3),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.emoji_events_outlined,
                                    color: AppColors.success),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    l.studentHomeSeeScores(doneCount),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Icon(Icons.chevron_right,
                                    color: AppColors.textSecondary),
                              ],
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _NextLessonCard extends StatelessWidget {
  const _NextLessonCard({required this.lesson});

  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppCard(
      onTap: () => context.push('/student/lesson/${lesson.id}'),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.navy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${lesson.order}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.studentHomeLessonMeta(lesson.termLabel, lesson.order),
                  style: TextStyle(
                    color: AppColors.teal,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  lesson.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
