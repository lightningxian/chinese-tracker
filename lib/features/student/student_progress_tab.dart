import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/exercise_utils.dart';
import '../../core/utils/progress_utils.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/exercise_results_list.dart';
import '../../core/widgets/progress_widgets.dart';
import '../../l10n/l10n.dart';
import '../../models/exercise.dart';
import '../../models/exercise_result.dart';
import '../../models/lesson.dart';
import '../../models/student_progress.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

enum _ProgressView { lessons, exercises }

/// Progress tab: lessons by term (as before) or every exercise attempt with
/// its score, correct count and time, newest first.
class StudentProgressTab extends StatefulWidget {
  const StudentProgressTab({super.key, required this.studentId});

  final String studentId;

  @override
  State<StudentProgressTab> createState() => _StudentProgressTabState();
}

class _StudentProgressTabState extends State<StudentProgressTab> {
  _ProgressView _view = _ProgressView.exercises;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: SegmentedButton<_ProgressView>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: _ProgressView.exercises,
                icon: const Icon(Icons.fitness_center_outlined, size: 18),
                label: Text(l.studentProgressExercises),
              ),
              ButtonSegment(
                value: _ProgressView.lessons,
                icon: const Icon(Icons.menu_book_outlined, size: 18),
                label: Text(l.studentProgressLessons),
              ),
            ],
            selected: {_view},
            onSelectionChanged: (s) => setState(() => _view = s.first),
          ),
        ),
        Expanded(
          child: switch (_view) {
            _ProgressView.exercises =>
              _ExerciseHistory(studentId: widget.studentId),
            _ProgressView.lessons =>
              _LessonProgress(studentId: widget.studentId),
          },
        ),
      ],
    );
  }
}

class _ExerciseHistory extends StatelessWidget {
  const _ExerciseHistory({required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final student = context.watch<AuthService>().appUser!;
    final l = context.l10n;

    return StreamBuilder<List<ExerciseResult>>(
      stream: firestore.watchStudentExerciseResults(studentId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final results = ExerciseUtils.newestFirst(snap.data ?? const []);
        if (results.isEmpty) {
          return EmptyState(
            icon: Icons.fitness_center_outlined,
            title: l.studentProgressNoExercisesTitle,
            subtitle: l.studentProgressNoExercisesSubtitle,
          );
        }
        final stats = ExerciseUtils.resultStats(results);

        // Titles for attempts recorded before the title was stored with them.
        return StreamBuilder<List<Exercise>>(
          stream: firestore.watchAvailableExercisesForStudent(student),
          builder: (context, exercisesSnap) {
            final titles = {
              for (final e in exercisesSnap.data ?? const <Exercise>[])
                e.id: e.title,
            };
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SummaryTile(
                        label: l.studentProgressAttempts,
                        value: '${stats.attempts}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SummaryTile(
                        label: l.studentProgressAvgScore,
                        value:
                            stats.average != null ? '${stats.average}%' : '—',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SummaryTile(
                        label: l.studentProgressBestScore,
                        value: stats.best != null ? '${stats.best}%' : '—',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                for (final result in results)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ExerciseResultTile(
                      result: result,
                      fallbackTitle: titles[result.exerciseId],
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _LessonProgress extends StatelessWidget {
  const _LessonProgress({required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final student = context.watch<AuthService>().appUser!;
    final contentOwnerId = AppConstants.contentOwnerFor(student);
    final l = context.l10n;

    return StreamBuilder<List<StudentProgress>>(
      stream: firestore.watchStudentProgress(studentId),
      builder: (context, progressSnap) {
        if (progressSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final progress = progressSnap.data ?? [];
        final completed = progress.where((item) => item.completed).toList();

        if (contentOwnerId.isEmpty) {
          return EmptyState(
            icon: Icons.trending_up,
            title: l.studentProgressNoProgressTitle,
            subtitle: l.studentProgressNoProgressSubtitle,
          );
        }

        return StreamBuilder<List<Lesson>>(
          stream: firestore.watchLessons(contentOwnerId),
          builder: (context, lessonsSnap) {
            final allLessons = lessonsSnap.data ?? [];
            final lessons =
                ProgressUtils.lessonsForStudent(allLessons, student);
            final terms = ProgressUtils.buildTermProgress(
              lessons: lessons,
              progress: progress,
              termSize: student.lessonsPerTerm,
            );
            final avgScore = ProgressUtils.averageScore(progress);
            final currentTerm = ProgressUtils.currentTerm(
              lessons: lessons,
              progress: progress,
              termSize: student.lessonsPerTerm,
            );

            if (lessons.isEmpty) {
              return EmptyState(
                icon: Icons.trending_up,
                title: l.studentProgressNoLessonsTitle,
                subtitle: l.studentProgressNoLessonsSubtitle(
                  student.level ?? l.studentProgressYourHskLevel,
                ),
              );
            }

            if (completed.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  ProgressSummaryRow(
                    completed: 0,
                    avgScore: null,
                    thirdLabel: l.studentProgressTermSize,
                    thirdValue: '${student.lessonsPerTerm}',
                  ),
                  const SizedBox(height: 20),
                  if (currentTerm != null) ...[
                    TermProgressCard(
                      term: currentTerm,
                      subtitle: l.studentProgressStartFirst,
                    ),
                    const SizedBox(height: 20),
                  ],
                  SectionHeader(title: l.studentProgressTermPlan),
                  for (final term in terms) ...[
                    TermProgressCard(term: term),
                    const SizedBox(height: 12),
                  ],
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                ProgressSummaryRow(
                  completed: completed.length,
                  avgScore: avgScore,
                  thirdLabel: l.studentProgressCurrentTerm,
                  thirdValue: currentTerm != null
                      ? '${currentTerm.completedCount}/${currentTerm.termSize}'
                      : '—',
                ),
                const SizedBox(height: 20),
                for (final term in terms) ...[
                  SectionHeader(
                    title:
                        '${term.label} (${term.completedCount}/${term.termSize})',
                  ),
                  ...term.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ProgressHistoryTile(item: item),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
        );
      },
    );
  }
}
