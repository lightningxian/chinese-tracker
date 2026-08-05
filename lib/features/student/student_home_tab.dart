import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/exercise_utils.dart';
import '../../core/utils/progress_utils.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/class_term_widgets.dart';
import '../../core/widgets/exercise_widgets.dart';
import '../../core/widgets/responsive_card_grid.dart';
import '../../models/app_user.dart';
import '../../models/exercise.dart';
import '../../models/exercise_result.dart';
import '../../models/lesson.dart';
import '../../models/student_progress.dart';
import '../../services/firestore_service.dart';
import 'student_join_session_section.dart';

class StudentHomeTab extends StatelessWidget {
  const StudentHomeTab({
    super.key,
    required this.student,
    required this.contentOwnerId,
  });

  final AppUser student;
  final String contentOwnerId;

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Hello, ${student.name.split(' ').first}',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          ProgressUtils.formatStudentLevel(student),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        StudentHomeTermBalance(studentId: student.uid),
        const SizedBox(height: 24),
        StudentJoinSessionSection(student: student),
        const SizedBox(height: 12),
        AppCard(
          onTap: () => context.push('/student/calendar'),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.calendar_month_outlined,
                    color: AppColors.teal),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'View class calendar',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          onTap: () => context.push('/student/grades'),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.navy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.grading_outlined,
                    color: AppColors.navy),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'View grades & transcript',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          onTap: () => context.push('/student/materials'),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.brandYellow.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.folder_open_outlined,
                    color: AppColors.brandYellow),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Learning materials',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Continue learning'),
        StreamBuilder<List<Exercise>>(
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
                      style: const TextStyle(color: AppColors.error),
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
                    return StreamBuilder<List<ExerciseResult>>(
                      stream: firestore.watchStudentExerciseResults(student.uid),
                      builder: (context, resultsSnap) {
                        final progressByLesson =
                            ProgressUtils.progressByLessonId(
                          progressSnap.data ?? [],
                        );
                        final bestScores = ExerciseUtils.bestScores(
                          resultsSnap.data ?? [],
                        );

                        Lesson? nextLesson;
                        for (final lesson in lessons) {
                          final record = progressByLesson[lesson.id];
                          if (record == null || !record.completed) {
                            nextLesson = lesson;
                            break;
                          }
                        }

                        final pendingExercises = availableExercises
                            .where(
                              (exercise) => bestScores[exercise.id] == null,
                            )
                            .toList()
                          ..sort(
                            (a, b) => ExerciseUtils.compareExercises(
                              a,
                              b,
                              bestScores: bestScores,
                            ),
                          );
                        final completedExercises = availableExercises
                            .where(
                              (exercise) => bestScores[exercise.id] != null,
                            )
                            .toList()
                          ..sort(
                            (a, b) => ExerciseUtils.compareExercises(
                              a,
                              b,
                              bestScores: bestScores,
                            ),
                          );

                        final counts = ExerciseUtils.practiceCounts(
                          availableExercises,
                          bestScores: bestScores,
                        );

                        if (availableExercises.isEmpty && nextLesson == null) {
                          return const EmptyState(
                            icon: Icons.fitness_center_outlined,
                            title: 'No practice yet',
                            subtitle:
                                'Set your HSK level in Profile to unlock exercises, '
                                'or wait for new practice to be published.',
                          );
                        }

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = ResponsiveCardGrid.columnCount(
                              constraints.maxWidth,
                              minCardWidth: 300,
                            );
                            final compact = columns > 1;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (availableExercises.isNotEmpty) ...[
                                  HomeworkSummaryBar(
                                    pending: counts.pending,
                                    overdue: counts.overdue,
                                    done: counts.done,
                                  ),
                                ],
                                if (pendingExercises.isNotEmpty) ...[
                                  Text(
                                    '${student.level ?? 'Your level'} practice',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.navy,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  ResponsiveCardGrid(
                                    width: constraints.maxWidth,
                                    children: [
                                      for (final exercise in pendingExercises)
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
                                  Text(
                                    'Next lesson',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.navy,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  AppCard(
                                    onTap: () => context.push(
                                      '/student/lesson/${nextLesson!.id}',
                                    ),
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: AppColors.navy
                                                .withValues(alpha: 0.08),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '${nextLesson.order}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.navy,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${nextLesson.termLabel} · Lesson ${nextLesson.order}',
                                                style: const TextStyle(
                                                  color: AppColors.teal,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                nextLesson.title,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.chevron_right,
                                          color: AppColors.textSecondary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else if (lessons.isNotEmpty) ...[
                                  const EmptyState(
                                    icon: Icons.celebration_outlined,
                                    title: 'All lessons done',
                                    subtitle: 'Great work — you completed every available lesson.',
                                  ),
                                ],
                                if (completedExercises.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    'Completed practice',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.navy,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  ResponsiveCardGrid(
                                    width: constraints.maxWidth,
                                    children: [
                                      for (final exercise in completedExercises)
                                        AssignedExerciseCard(
                                          exercise: exercise,
                                          bestScore: bestScores[exercise.id],
                                          compact: true,
                                          onTap: () => context.push(
                                            '/student/exercise/${exercise.id}',
                                          ),
                                        ),
                                    ],
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
          },
        ),
      ],
    );
  }
}
