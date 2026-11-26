import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/paging/date_range.dart';
import '../../core/paging/paged_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/grade_utils.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/paging_bars.dart';
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
/// Build 9 part 2: the transcript is one page at a time in a date range,
/// merged from the three sources (each reads at most a page); the grades
/// waiting for a score and the published evaluations stay above it.
class TranscriptView extends StatefulWidget {
  const TranscriptView({super.key, required this.studentId});

  final String studentId;

  @override
  State<TranscriptView> createState() => _TranscriptViewState();
}

class _TranscriptViewState extends State<TranscriptView> {
  late final FirestoreService _fs = context.read<FirestoreService>();
  late final Stream<List<Grade>> _pending = FirebaseFirestore.instance
      .collection(AppConstants.gradesCollection)
      .where('studentId', isEqualTo: widget.studentId)
      .where('status', isEqualTo: GradeStatus.pending.value)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs.map(Grade.fromFirestore).toList());
  late final Stream<List<Evaluation>> _evaluations =
      _fs.watchStudentEvaluations(widget.studentId, publishedOnly: true);
  late final PagedController<Object> _pages = PagedController<Object>(
    range: DateRangeSel.preset(RangePreset.thisYear),
    build: _source,
  );

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  static DateTime _dateOf(Object e) => switch (e) {
        Grade g => g.gradedAt ?? g.createdAt ?? DateTime(1970),
        ExerciseResult r => r.submittedAt ?? DateTime(1970),
        QuizResult q => q.submittedAt ?? DateTime(1970),
        _ => DateTime(1970),
      };

  PageSource<Object> _source(DateRangeSel range) {
    final db = FirebaseFirestore.instance;
    final id = widget.studentId;
    Query<Map<String, dynamic>> byStudent(String col, String field) =>
        applyDateRange(
            db
                .collection(col)
                .where('studentId', isEqualTo: id)
                .orderBy(field, descending: true),
            field,
            range);
    return MergedPageSource<Object>([
      FirestorePageSource<Object>(
          applyDateRange(
              db
                  .collection(AppConstants.gradesCollection)
                  .where('studentId', isEqualTo: id)
                  .where('status', isEqualTo: GradeStatus.graded.value)
                  .orderBy('createdAt', descending: true),
              'createdAt',
              range),
          Grade.fromFirestore),
      FirestorePageSource<Object>(
          byStudent(AppConstants.exerciseResultsCollection, 'submittedAt'),
          ExerciseResult.fromFirestore),
      FirestorePageSource<Object>(
          byStudent(AppConstants.quizResultsCollection, 'submittedAt'),
          QuizResult.fromFirestore),
    ], newer: (a, b) => _dateOf(a).isAfter(_dateOf(b)));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return StreamBuilder<List<Grade>>(
      stream: _pending,
      builder: (context, pendingSnap) => StreamBuilder<List<Evaluation>>(
        stream: _evaluations,
        builder: (context, evalSnap) {
          final pending = pendingSnap.data ?? const <Grade>[];
          final evaluations = evalSnap.data ?? const <Evaluation>[];
          return ListenableBuilder(
            listenable: _pages,
            builder: (context, _) => ListView(
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
                PagedListBody<Object>(
                  controller: _pages,
                  inline: true,
                  padding: const EdgeInsets.only(top: 8),
                  header: DateRangeBar(
                      value: _pages.range, onChanged: _pages.setRange),
                  emptyIcon: Icons.grading_outlined,
                  emptyTitle: l.teacherGradesEmptyTitle,
                  emptySubtitle: l.transcriptEmptySubtitle,
                  itemBuilder: (context, e) => _EntryCard(
                    entry: switch (e) {
                      Grade g => _TranscriptEntry.fromGrade(g, l),
                      ExerciseResult r => _TranscriptEntry.fromExercise(r, l),
                      _ => _TranscriptEntry.fromQuiz(e as QuizResult, l),
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
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
