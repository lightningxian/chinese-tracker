import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/grade_utils.dart';
import '../../core/widgets/app_card.dart';
import '../../l10n/l10n.dart';
import '../../l10n/labels_classes.dart';
import '../../models/evaluation.dart';
import '../../models/exercise_result.dart';
import '../../models/grade.dart';
import '../../models/quiz_result.dart';
import '../../services/firestore_service.dart';

/// Read-only transcript for one student, merging first-class [Grade]s with the
/// existing quiz and exercise scores. Newest first, with letter grades.
///
/// Shared by the student's own view and the parent's read-only child view.
class TranscriptView extends StatelessWidget {
  const TranscriptView({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final firestore = context.read<FirestoreService>();

    return StreamBuilder<List<Grade>>(
      stream: firestore.watchStudentGrades(studentId),
      builder: (context, gradeSnap) {
        return StreamBuilder<List<ExerciseResult>>(
          stream: firestore.watchStudentExerciseResults(studentId),
          builder: (context, exSnap) {
            return StreamBuilder<List<QuizResult>>(
              stream: firestore.watchStudentQuizResults(studentId),
              builder: (context, quizSnap) {
                final waiting =
                    gradeSnap.connectionState == ConnectionState.waiting &&
                        !gradeSnap.hasData;
                if (waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final grades = gradeSnap.data ?? const <Grade>[];
                final entries = <_TranscriptEntry>[
                  for (final g in grades) _TranscriptEntry.fromGrade(g, l),
                  for (final r in (exSnap.data ?? const <ExerciseResult>[]))
                    _TranscriptEntry.fromExercise(r, l),
                  for (final q in (quizSnap.data ?? const <QuizResult>[]))
                    _TranscriptEntry.fromQuiz(q, l),
                ]..sort((a, b) => b.date.compareTo(a.date));

                final pending = grades.where((g) => g.isPending).toList();

                return StreamBuilder<List<Evaluation>>(
                  stream: firestore.watchStudentEvaluations(
                    studentId,
                    publishedOnly: true,
                  ),
                  builder: (context, evalSnap) {
                    final evaluations = evalSnap.data ?? const <Evaluation>[];

                    if (entries.isEmpty && evaluations.isEmpty) {
                      return EmptyState(
                        icon: Icons.grading_outlined,
                        title: l.teacherGradesEmptyTitle,
                        subtitle: l.transcriptEmptySubtitle,
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        if (pending.isNotEmpty) ...[
                          SectionHeader(title: l.transcriptPendingHeader),
                          for (final g in pending) ...[
                            _PendingCard(grade: g),
                            const SizedBox(height: 10),
                          ],
                          const SizedBox(height: 12),
                        ],
                        if (evaluations.isNotEmpty) ...[
                          SectionHeader(title: l.transcriptTeacherEvaluations),
                          for (final e in evaluations) ...[
                            _EvaluationCard(evaluation: e),
                            const SizedBox(height: 10),
                          ],
                          const SizedBox(height: 12),
                        ],
                        SectionHeader(title: l.transcriptTitle),
                        for (final e in entries.where((e) => !e.isPending)) ...[
                          _EntryCard(entry: e),
                          const SizedBox(height: 10),
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

class _TranscriptEntry {
  const _TranscriptEntry({
    required this.title,
    required this.category,
    required this.date,
    this.score,
    this.isPending = false,
  });

  final String title;
  final String category;
  final DateTime date;
  final num? score;
  final bool isPending;

  String? get letter =>
      score == null ? null : GradeUtils.letterGradeFor(score!);

  factory _TranscriptEntry.fromGrade(Grade g, AppLocalizations l) =>
      _TranscriptEntry(
        title: g.title.isEmpty ? g.category.localized(l) : g.title,
        category: g.category.localized(l),
        date: g.gradedAt ?? g.createdAt ?? DateTime(1970),
        score: g.score,
        isPending: g.isPending,
      );

  factory _TranscriptEntry.fromExercise(
    ExerciseResult r,
    AppLocalizations l,
  ) =>
      _TranscriptEntry(
        title: l.transcriptPracticeExercise,
        category: GradeCategory.exercise.localized(l),
        date: r.submittedAt ?? DateTime(1970),
        score: r.score,
      );

  factory _TranscriptEntry.fromQuiz(QuizResult q, AppLocalizations l) =>
      _TranscriptEntry(
        title: l.transcriptLessonQuiz,
        category: GradeCategory.quiz.localized(l),
        date: q.submittedAt ?? DateTime(1970),
        score: q.score,
      );
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry});

  final _TranscriptEntry entry;

  @override
  Widget build(BuildContext context) {
    final score = entry.score;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.date.year > 1970
                      ? '${entry.category} · ${DateFormat('d MMM yyyy').format(entry.date)}'
                      : entry.category,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (score != null) _ScoreBadge(score: score),
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});

  final num score;

  @override
  Widget build(BuildContext context) {
    final letter = GradeUtils.letterGradeFor(score);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${score.round()}',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.navy,
          ),
        ),
        Text(
          letter,
          style: TextStyle(
            color: AppColors.teal,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _EvaluationCard extends StatelessWidget {
  const _EvaluationCard({required this.evaluation});

  final Evaluation evaluation;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final e = evaluation;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  e.term.isEmpty ? l.evaluationsFallbackTitle : e.term,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.navy,
                  ),
                ),
              ),
              if (e.rating != null)
                Row(
                  children: [
                    Icon(Icons.star, size: 16, color: AppColors.teal),
                    const SizedBox(width: 2),
                    Text(
                      '${e.rating}/5',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.teal,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (e.strengths.isNotEmpty)
            _EvalLine(label: l.evaluationsStrengths, text: e.strengths),
          if (e.improvements.isNotEmpty)
            _EvalLine(label: l.transcriptToImprove, text: e.improvements),
          if (e.comment.isNotEmpty)
            _EvalLine(label: l.evaluationsComment, text: e.comment),
        ],
      ),
    );
  }
}

class _EvalLine extends StatelessWidget {
  const _EvalLine({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(text, style: const TextStyle(fontSize: 13, height: 1.35)),
        ],
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({required this.grade});

  final Grade grade;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.brandYellow.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.schedule, color: AppColors.brandYellow, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  grade.title.isEmpty ? grade.category.localized(l) : grade.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  l.transcriptAwaitingScore(grade.category.localized(l)),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
