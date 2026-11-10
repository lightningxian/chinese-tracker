import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
import '../../models/student_progress.dart';
import '../../services/firestore_service.dart';

class StudentLessonsTab extends StatelessWidget {
  const StudentLessonsTab({
    super.key,
    required this.contentOwnerId,
    required this.student,
  });

  final String contentOwnerId;
  final AppUser student;

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final l = context.l10n;
    final levelLabel = student.level ?? l.commonYourLevel;

    return StreamBuilder<List<Exercise>>(
      stream: firestore.watchAvailableExercisesForStudent(student),
      builder: (context, exercisesSnap) {
        final availableExercises = exercisesSnap.data ?? [];

        return StreamBuilder(
          stream: firestore.watchLessons(contentOwnerId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                exercisesSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final allLessons = snapshot.data ?? [];
            final lessons =
                ProgressUtils.lessonsForStudent(allLessons, student);

            if (lessons.isEmpty && availableExercises.isEmpty) {
              return EmptyState(
                icon: Icons.menu_book_outlined,
                title: l.studentLessonsNoContentTitle,
                subtitle: contentOwnerId.isEmpty
                    ? l.studentLessonsNoDemoData
                    : student.level == null
                        ? l.studentLessonsSetLevel
                        : l.studentLessonsWillAppear(student.level!),
              );
            }

            final byTerm = ProgressUtils.groupLessonsByTerm(lessons);

            return StreamBuilder(
              stream: firestore.watchStudentProgress(student.uid),
              builder: (context, progressSnap) {
                return StreamBuilder<List<ExerciseResult>>(
                  stream: firestore.watchStudentExerciseResults(student.uid),
                  builder: (context, resultsSnap) {
                    final progressByLesson = ProgressUtils.progressByLessonId(
                        progressSnap.data ?? []);
                    final bestScores =
                        ExerciseUtils.bestScores(resultsSnap.data ?? []);
                    final sortedExercises = [...availableExercises]..sort(
                        (a, b) => ExerciseUtils.compareExercises(
                          a,
                          b,
                          bestScores: bestScores,
                        ),
                      );

                    final counts = ExerciseUtils.practiceCounts(
                      sortedExercises,
                      bestScores: bestScores,
                    );

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = ResponsiveCardGrid.columnCount(
                          constraints.maxWidth,
                          minCardWidth: 300,
                        );
                        final compact = columns > 1;

                        return ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            if (sortedExercises.isNotEmpty) ...[
                              SectionHeader(
                                title: l.studentLessonsExercisesHeader(
                                  levelLabel,
                                  sortedExercises.length,
                                ),
                              ),
                              HomeworkSummaryBar(
                                pending: counts.pending,
                                overdue: counts.overdue,
                                done: counts.done,
                              ),
                              ResponsiveCardGrid(
                                width: constraints.maxWidth,
                                children: [
                                  for (final exercise in sortedExercises)
                                    AssignedExerciseCard(
                                      exercise: exercise,
                                      bestScore: bestScores[exercise.id],
                                      compact: compact,
                                      onTap: () => context.push(
                                        '/student/exercise/${exercise.id}',
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ] else ...[
                              EmptyState(
                                icon: Icons.fitness_center_outlined,
                                title: l.studentLessonsNoExercisesTitle,
                                subtitle: student.level == null
                                    ? l.studentLessonsNoExercisesSetLevel
                                    : l.studentLessonsNoPublishedExercises(
                                        student.level!,
                                      ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (lessons.isNotEmpty) ...[
                              AppCard(
                                child: Text(
                                  l.studentLessonsLevelTermInfo(
                                    levelLabel,
                                    student.lessonsPerTerm,
                                  ),
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              for (final entry in byTerm.entries) ...[
                                SectionHeader(
                                  title: l.studentLessonsTermHeader(
                                    '${entry.key}',
                                    entry.value.length,
                                  ),
                                ),
                                ResponsiveCardGrid(
                                  width: constraints.maxWidth,
                                  children: [
                                    for (final lesson in entry.value)
                                      _LessonCard(
                                        lesson: lesson,
                                        record: progressByLesson[lesson.id],
                                        compact: compact,
                                        onTap: () => context.push(
                                          '/student/lesson/${lesson.id}',
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
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
      },
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.lesson,
    required this.record,
    required this.compact,
    required this.onTap,
  });

  final Lesson lesson;
  final StudentProgress? record;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = record?.completed ?? false;
    final score = record?.score;
    final l = context.l10n;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 16,
        vertical: compact ? 12 : 14,
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 36 : 40,
            height: compact ? 36 : 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: done
                  ? AppColors.success.withValues(alpha: 0.12)
                  : AppColors.navy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: done
                ? Icon(
                    Icons.check,
                    color: AppColors.success,
                    size: compact ? 20 : 22,
                  )
                : Text(
                    '${lesson.order}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: compact ? 14 : 16,
                  ),
                ),
                if ([
                  if (lesson.level != null) lesson.level!,
                  if (score != null) l.studentLessonsQuizScore('$score'),
                  if (done && score == null) l.commonCompleted,
                ].isNotEmpty)
                  Text(
                    [
                      if (lesson.level != null) lesson.level!,
                      if (score != null) l.studentLessonsQuizScore('$score'),
                      if (done && score == null) l.commonCompleted,
                    ].join(' · '),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
