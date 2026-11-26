import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/paging/date_range.dart';
import '../../core/paging/paged_controller.dart';
import '../../core/utils/progress_utils.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/paging_bars.dart';
import '../../core/widgets/exercise_results_list.dart';
import '../../core/widgets/progress_widgets.dart';
import '../../l10n/l10n.dart';
import '../../models/exercise.dart';
import '../../models/exercise_result.dart';
import '../../models/lesson.dart';
import '../../models/student_progress.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../progress/student_progress_report_screen.dart';

enum _ProgressView { report, lessons, exercises }

/// Progress tab: the progress report (Build 4), every exercise attempt with
/// its score, correct count and time, or lessons by term.
class StudentProgressTab extends StatefulWidget {
  const StudentProgressTab({super.key, required this.studentId});

  final String studentId;

  @override
  State<StudentProgressTab> createState() => _StudentProgressTabState();
}

class _StudentProgressTabState extends State<StudentProgressTab> {
  _ProgressView _view = _ProgressView.report;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    // Three segments fit a phone only without their icons.
    final narrow = MediaQuery.sizeOf(context).width < 480;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: SegmentedButton<_ProgressView>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: _ProgressView.report,
                icon: narrow ? null : const Icon(Icons.insights_outlined, size: 18),
                label: Text(l.progressReportTab),
              ),
              ButtonSegment(
                value: _ProgressView.exercises,
                icon: narrow ? null : const Icon(Icons.fitness_center_outlined, size: 18),
                label: Text(l.studentProgressExercises),
              ),
              ButtonSegment(
                value: _ProgressView.lessons,
                icon: narrow ? null : const Icon(Icons.menu_book_outlined, size: 18),
                label: Text(l.studentProgressLessons),
              ),
            ],
            selected: {_view},
            onSelectionChanged: (s) => setState(() => _view = s.first),
          ),
        ),
        Expanded(
          child: switch (_view) {
            _ProgressView.report =>
              StudentProgressReport(studentId: widget.studentId),
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

/// Build 9 Then list: the exercise results 25 a page in a date range
/// (default this year); attempts and average for the range, best ever.
class _ExerciseHistory extends StatefulWidget {
  const _ExerciseHistory({required this.studentId});

  final String studentId;

  @override
  State<_ExerciseHistory> createState() => _ExerciseHistoryState();
}

class _ExerciseHistoryState extends State<_ExerciseHistory> {
  late final FirestoreService _firestore = context.read<FirestoreService>();
  late final PagedController<ExerciseResult> _pages = PagedController<ExerciseResult>(
    build: (range) => FirestorePageSource(
        _firestore.studentResultsQuery(widget.studentId, range),
        ExerciseResult.fromFirestore),
    range: DateRangeSel.preset(RangePreset.thisYear),
  );
  late Future<({int attempts, int? average, int? best})> _stats =
      _firestore.studentResultStats(widget.studentId, _pages.range);
  late final Stream<List<Exercise>> _exercises = _firestore
      .watchAvailableExercisesForStudent(context.read<AuthService>().appUser!);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _setRange(DateRangeSel r) {
    _pages.setRange(r);
    setState(() => _stats = _firestore.studentResultStats(widget.studentId, r));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    // Titles for attempts recorded before the title was stored with them.
    return StreamBuilder<List<Exercise>>(
      stream: _exercises,
      builder: (context, exercisesSnap) {
        final titles = {
          for (final e in exercisesSnap.data ?? const <Exercise>[]) e.id: e.title,
        };
        return ListenableBuilder(
          listenable: _pages,
          builder: (context, _) => PagedListBody<ExerciseResult>(
            controller: _pages,
            separator: 8,
            emptyIcon: Icons.fitness_center_outlined,
            emptyTitle: l.studentProgressNoExercisesTitle,
            emptySubtitle: l.studentProgressNoExercisesSubtitle,
            header: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FutureBuilder<({int attempts, int? average, int? best})>(
                  future: _stats,
                  builder: (context, snap) {
                    final st = snap.data;
                    return Row(
                      children: [
                        Expanded(
                          child: SummaryTile(
                            label: l.studentProgressAttempts,
                            value: st == null ? '…' : '${st.attempts}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SummaryTile(
                            label: l.studentProgressAvgScore,
                            value: st?.average != null ? '${st!.average}%' : '—',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SummaryTile(
                            label: l.studentProgressBestScore,
                            value: st?.best != null ? '${st!.best}%' : '—',
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                DateRangeBar(value: _pages.range, onChanged: _setRange),
              ],
            ),
            itemBuilder: (context, result) => ExerciseResultTile(
              result: result,
              fallbackTitle: titles[result.exerciseId],
            ),
          ),
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
