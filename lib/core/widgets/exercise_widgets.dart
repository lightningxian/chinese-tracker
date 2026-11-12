import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import '../utils/exercise_utils.dart';
import '../../l10n/l10n.dart';
import '../../l10n/labels_exercises.dart';
import '../../models/app_user.dart';
import '../../models/exercise.dart';
import '../../models/exercise_assignment.dart';
import '../../models/exercise_result.dart';
import '../../models/student_assigned_exercise.dart';
import '../../services/firestore_service.dart';
import 'app_card.dart';
import 'responsive_card_grid.dart';
import 'status_pill.dart';

enum HomeworkStatus { pending, overdue, done }

HomeworkStatus homeworkStatus({
  required int? bestScore,
  required bool isOverdue,
}) {
  if (bestScore != null) return HomeworkStatus.done;
  if (isOverdue) return HomeworkStatus.overdue;
  return HomeworkStatus.pending;
}

/// "2 worksheets · 1 question" for a package, "7 questions" otherwise:
/// [Exercise.contentsLabel] in the UI language.
String exerciseContentsLabel(AppLocalizations l, Exercise exercise) {
  if (exercise.isPackage) {
    return [
      if (exercise.bankSheets.isNotEmpty)
        l.exerciseCardWorksheets(exercise.bankSheets.length),
      if (exercise.bankQuestionIds.isNotEmpty)
        l.bankTextQuestionCount(exercise.bankQuestionIds.length),
    ].join(' · ');
  }
  return l.bankTextQuestionCount(exercise.questions.length);
}

/// "Due 12 Nov 2026" / "Overdue · 12 Nov 2026": [ExerciseUtils.dueDateLabel]
/// in the UI language.
String exerciseDueDateLabel(
  AppLocalizations l,
  DateTime? dueDate, {
  required bool isOverdue,
}) {
  if (dueDate == null) return '';
  final date = ExerciseUtils.formatDueDate(dueDate);
  return isOverdue ? l.exerciseCardOverdueOn(date) : l.exerciseCardDue(date);
}

class HomeworkSummaryBar extends StatelessWidget {
  const HomeworkSummaryBar({
    super.key,
    required this.pending,
    required this.overdue,
    required this.done,
  });

  final int pending;
  final int overdue;
  final int done;

  @override
  Widget build(BuildContext context) {
    if (pending == 0 && overdue == 0 && done == 0) {
      return const SizedBox.shrink();
    }
    final l = context.l10n;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (pending > 0)
            StatusPill(
              label: l.exerciseCardToDoCount(pending),
              color: AppColors.teal,
            ),
          if (overdue > 0)
            StatusPill(
              label: l.exerciseCardOverdueCount(overdue),
              color: AppColors.error,
            ),
          if (done > 0)
            StatusPill(
              label: l.exerciseCardDoneCount(done),
              color: AppColors.success,
            ),
        ],
      ),
    );
  }
}

/// One to three small stars for a score (see [ExerciseUtils.scoreStars]).
class ScoreStars extends StatelessWidget {
  const ScoreStars({super.key, required this.score, this.size = 14});

  final int score;
  final double size;

  @override
  Widget build(BuildContext context) {
    final stars = ExerciseUtils.scoreStars(score);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Icon(
            i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: i < stars ? AppColors.brandYellow : AppColors.border,
          ),
      ],
    );
  }
}

class AssignedExerciseCard extends StatelessWidget {
  const AssignedExerciseCard({
    super.key,
    required this.exercise,
    this.assignment,
    required this.bestScore,
    this.attempts,
    this.latestResult,
    this.onTap,
    this.compact = false,
  });

  final Exercise exercise;
  final ExerciseAssignment? assignment;
  final int? bestScore;
  final int? attempts;
  final ExerciseResult? latestResult;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final overdue = assignment?.isOverdue == true && bestScore == null;
    final status = homeworkStatus(
      bestScore: bestScore,
      isOverdue: assignment?.isOverdue ?? false,
    );
    final statusColor = switch (status) {
      HomeworkStatus.overdue => AppColors.error,
      HomeworkStatus.done => AppColors.success,
      HomeworkStatus.pending => AppColors.teal,
    };
    final statusIcon = switch (status) {
      HomeworkStatus.overdue => Icons.warning_amber_rounded,
      HomeworkStatus.done => Icons.check_circle_outline,
      HomeworkStatus.pending => Icons.fitness_center_outlined,
    };
    final trailingIcon =
        bestScore == null ? Icons.play_arrow_rounded : Icons.chevron_right;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 16,
        vertical: compact ? 12 : 14,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(statusIcon, color: statusColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        exercise.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: compact ? 15 : 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (bestScore != null) ...[
                      ScoreStars(score: bestScore!),
                      const SizedBox(width: 6),
                    ],
                    _HomeworkStatusPill(status: status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _categorySubtitle(l, overdue: overdue),
                  style: TextStyle(
                    color: overdue ? AppColors.error : AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                if (assignment?.dueDate != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    exerciseDueDateLabel(
                      l,
                      assignment!.dueDate,
                      isOverdue: overdue,
                    ),
                    style: TextStyle(
                      color: overdue ? AppColors.error : AppColors.teal,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            Icon(
              trailingIcon,
              color:
                  bestScore == null ? AppColors.navy : AppColors.textSecondary,
            ),
          ],
        ],
      ),
    );
  }

  String _categorySubtitle(AppLocalizations l, {required bool overdue}) {
    final categoryParts = <String>[
      if (exercise.level != null) exercise.level!,
      exercise.skillCategory.localized(l),
    ];
    final progress = _subtitle(l, overdue: overdue);
    if (categoryParts.isEmpty) return progress;
    return '${categoryParts.join(' · ')} · $progress';
  }

  String _subtitle(AppLocalizations l, {required bool overdue}) {
    if (bestScore == null) {
      return [
        exerciseContentsLabel(l, exercise),
        l.exerciseCardNotStarted,
        if (overdue) l.exerciseCardOverdueLower,
      ].join(' · ');
    }

    final parts = <String>[l.exerciseCardBest(bestScore!)];
    if (attempts != null) {
      parts.insert(0, l.exerciseCardAttempts(attempts!));
    } else {
      parts.add(l.exerciseCardTapToRetry);
    }

    final submittedAt = latestResult?.submittedAt;
    if (submittedAt != null) {
      parts.add(l.exerciseCardLast(DateFormat('d MMM').format(submittedAt)));
    }

    return parts.join(' · ');
  }
}

class _HomeworkStatusPill extends StatelessWidget {
  const _HomeworkStatusPill({required this.status});

  final HomeworkStatus status;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final (label, color) = switch (status) {
      HomeworkStatus.pending => (l.exerciseCardStatusToDo, AppColors.teal),
      HomeworkStatus.overdue => (l.exerciseCardStatusOverdue, AppColors.error),
      HomeworkStatus.done => (l.exerciseCardStatusDone, AppColors.success),
    };
    return StatusPill(label: label, color: color);
  }
}

Future<void> showExerciseHomeworkProgressDialog({
  required BuildContext context,
  required Exercise exercise,
  List<ExerciseAssignment> assignments = const [],
  required List<ExerciseResult> results,
  required List<AppUser> students,
}) {
  final l = context.l10n;
  final scoresByStudent =
      ExerciseUtils.bestScoresByStudentForExercise(exercise.id, results);

  final rows = <_ProgressRow>[];
  if (assignments.isNotEmpty) {
    final studentsById = {for (final s in students) s.uid: s};
    for (final assignment in assignments) {
      final student = studentsById[assignment.studentId];
      final best = scoresByStudent[assignment.studentId];
      final overdue = assignment.isOverdue && best == null;
      rows.add(
        _ProgressRow(
          name: student?.name ?? l.exerciseCardUnknownStudent,
          level: student?.level,
          dueDate: assignment.dueDate,
          bestScore: best,
          overdue: overdue,
        ),
      );
    }
  } else {
    final level = exercise.level;
    final eligible = students.where(
      (student) =>
          student.isStudent &&
          student.active &&
          level != null &&
          student.level == level,
    );
    for (final student in eligible) {
      rows.add(
        _ProgressRow(
          name: student.name,
          level: student.level,
          bestScore: scoresByStudent[student.uid],
          overdue: false,
        ),
      );
    }
  }

  rows.sort((a, b) {
    if (a.bestScore == null && b.bestScore != null) return -1;
    if (a.bestScore != null && b.bestScore == null) return 1;
    if (a.overdue != b.overdue) return a.overdue ? -1 : 1;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });

  final completed = rows.where((r) => r.bestScore != null).length;
  final levelLabel = exercise.level ?? l.exerciseCardThisLevel;

  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.exerciseCardStudentProgress),
          const SizedBox(height: 4),
          Text(
            exercise.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: rows.isEmpty
            ? Text(l.exerciseCardNoStudentsRegistered(levelLabel))
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.exerciseCardCompletedOpenTo(
                      completed,
                      rows.length,
                      levelLabel,
                    ),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.teal,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final row = rows[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            row.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            [
                              if (row.level != null) row.level!,
                              if (row.dueDate != null)
                                exerciseDueDateLabel(
                                  l,
                                  row.dueDate,
                                  isOverdue: row.overdue,
                                ),
                            ].join(' · '),
                            style: TextStyle(
                              fontSize: 12,
                              color: row.overdue
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                            ),
                          ),
                          trailing: row.bestScore != null
                              ? Text(
                                  '${row.bestScore}%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.success,
                                  ),
                                )
                              : StatusPill(
                                  label: row.overdue
                                      ? l.exerciseCardStatusOverdue
                                      : l.exerciseCardPending,
                                  color: row.overdue
                                      ? AppColors.error
                                      : AppColors.textSecondary,
                                ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l.exerciseCardClose),
        ),
      ],
    ),
  );
}

class _ProgressRow {
  const _ProgressRow({
    required this.name,
    this.level,
    this.dueDate,
    this.bestScore,
    required this.overdue,
  });

  final String name;
  final String? level;
  final DateTime? dueDate;
  final int? bestScore;
  final bool overdue;
}

class StudentPracticeResultsSection extends StatelessWidget {
  const StudentPracticeResultsSection({
    super.key,
    required this.studentId,
    required this.firestore,
  });

  final String studentId;
  final FirestoreService firestore;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ExerciseAssignment>>(
      stream: firestore.watchAssignmentsForStudent(studentId),
      builder: (context, assignmentsSnap) {
        return StreamBuilder<List<ExerciseResult>>(
          stream: firestore.watchStudentExerciseResults(studentId),
          builder: (context, resultsSnap) {
            if (assignmentsSnap.connectionState == ConnectionState.waiting ||
                resultsSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final assignments = assignmentsSnap.data ?? [];
            if (assignments.isEmpty) {
              return EmptyState(
                icon: Icons.fitness_center_outlined,
                title: context.l10n.exerciseCardNoPracticeTitle,
                subtitle: context.l10n.exerciseCardNoPracticeSubtitle,
              );
            }

            final results = resultsSnap.data ?? [];
            final bestScores = ExerciseUtils.bestScores(results);
            final attemptCounts = ExerciseUtils.attemptCounts(results);
            final latestResults = ExerciseUtils.latestResults(results);

            return FutureBuilder<List<StudentAssignedExercise>>(
              future: _loadAssignedExercises(assignments),
              builder: (context, assignedSnap) {
                if (assignedSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final assigned = assignedSnap.data ?? [];
                assigned.sort(
                  (a, b) => ExerciseUtils.compareAssigned(
                    a,
                    b,
                    bestScores: bestScores,
                  ),
                );

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = ResponsiveCardGrid.columnCount(
                      constraints.maxWidth,
                      minCardWidth: 300,
                    );
                    final compact = columns > 1;

                    return ResponsiveCardGrid(
                      width: constraints.maxWidth,
                      children: [
                        for (final item in assigned)
                          AssignedExerciseCard(
                            exercise: item.exercise,
                            assignment: item.assignment,
                            bestScore: bestScores[item.exercise.id],
                            attempts: attemptCounts[item.exercise.id] ?? 0,
                            latestResult: latestResults[item.exercise.id],
                            compact: compact,
                          ),
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

  Future<List<StudentAssignedExercise>> _loadAssignedExercises(
    List<ExerciseAssignment> assignments,
  ) async {
    final assigned = <StudentAssignedExercise>[];
    for (final assignment in assignments) {
      final exercise = await firestore.getExercise(assignment.exerciseId);
      if (exercise != null && exercise.isPublished) {
        assigned.add(
          StudentAssignedExercise(
            exercise: exercise,
            assignment: assignment,
          ),
        );
      }
    }
    return assigned;
  }
}

String assignedExerciseSubtitle(
  AppLocalizations l, {
  required Exercise exercise,
  required ExerciseAssignment assignment,
  required int? bestScore,
}) {
  final parts = <String>[];
  if (bestScore == null) {
    parts.add(
        '${exerciseContentsLabel(l, exercise)} · ${l.exerciseCardNotStarted}');
  } else {
    parts.add(l.exerciseCardBestScoreRetry(bestScore));
  }
  if (assignment.dueDate != null) {
    parts.add(
      exerciseDueDateLabel(
        l,
        assignment.dueDate,
        isOverdue: assignment.isOverdue && bestScore == null,
      ),
    );
  }
  return parts.join(' · ');
}
