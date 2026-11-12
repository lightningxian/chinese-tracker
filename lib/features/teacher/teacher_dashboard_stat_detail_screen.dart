import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/exercise_utils.dart';
import '../../core/utils/teacher_activity_utils.dart';
import '../../core/utils/teacher_attention_utils.dart';
import '../../core/utils/teacher_stats_utils.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/cohort_stats_widgets.dart';
import '../../core/widgets/responsive_card_grid.dart';
import '../../core/widgets/shell_nested_page.dart';
import '../../core/widgets/status_pill.dart';
import '../../core/widgets/teacher_activity_widgets.dart';
import '../../l10n/l10n.dart';
import '../../l10n/labels_classes.dart';
import '../../models/app_user.dart';
import '../../models/attendance_record.dart';
import '../../models/class_session.dart';
import '../../models/cohort_report_models.dart';
import '../../models/exercise.dart';
import '../../models/exercise_assignment.dart';
import '../../models/exercise_result.dart';
import '../../models/lesson.dart';
import '../../models/student_class_term.dart';
import '../../models/student_progress.dart';
import '../../models/teacher_activity_event.dart';
import '../../models/dashboard_stat_routes.dart';
import '../../models/teacher_dashboard_stat_kind.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class TeacherDashboardStatDetailScreen extends StatelessWidget {
  const TeacherDashboardStatDetailScreen({
    super.key,
    required this.kind,
    this.embedded = false,
    this.routes = DashboardStatRoutes.teacher,
  });

  final TeacherDashboardStatKind kind;
  final bool embedded;
  final DashboardStatRoutes routes;

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final user = context.watch<AuthService>().appUser;
    // Admin centre views keep the full centre; teacher views are scoped.
    final sessionsStream = user != null && user.isTeacher
        ? firestore.watchTeacherSessions(AppConstants.contentOwnerFor(user))
        : firestore.watchAllClassSessions();
    // Per-teacher model: teachers use contentOwnerFor; admins aggregate below.
    final teacherOwnerId = user != null && user.isTeacher
        ? AppConstants.contentOwnerFor(user)
        : '';

    return ShellNestedPage(
      embedded: embedded,
      title: kind.localizedTitle(context.l10n),
      child: StreamBuilder<List<AppUser>>(
        stream: firestore.watchAllStudents(),
        builder: (context, studentsSnap) {
          if (studentsSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (studentsSnap.hasError) {
            return Center(
              child: Text(
                studentsSnap.error.toString(),
                style: TextStyle(color: AppColors.error),
              ),
            );
          }

          final students = studentsSnap.data ?? [];
          final ownerIds = teacherOwnerId.isNotEmpty
              ? <String>{teacherOwnerId}
              : {
                  for (final s in students) AppConstants.contentOwnerFor(s),
                }.where((id) => id.isNotEmpty).toSet();

          return StreamBuilder<List<StudentProgress>>(
            stream: firestore.watchAllStudentProgress(),
            builder: (context, progressSnap) {
              return StreamBuilder<List<ExerciseAssignment>>(
                stream: firestore.watchAllExerciseAssignments(),
                builder: (context, assignmentsSnap) {
                  return StreamBuilder<List<ExerciseResult>>(
                    stream: firestore.watchAllExerciseResults(),
                    builder: (context, resultsSnap) {
                      return StreamBuilder<List<StudentClassTerm>>(
                        stream: firestore.watchAllClassTerms(),
                        builder: (context, termsSnap) {
                          return StreamBuilder<List<Exercise>>(
                            stream: firestore.watchAllExercises(),
                            builder: (context, exercisesSnap) {
                              return StreamBuilder<Map<String, List<Lesson>>>(
                                stream: firestore.watchLessonsByOwnerIds(
                                  ownerIds,
                                ),
                                builder: (context, lessonsSnap) {
                                  return StreamBuilder<List<ClassSession>>(
                                    stream: sessionsStream,
                                    builder: (context, sessionsSnap) {
                                      return StreamBuilder<
                                          List<AttendanceRecord>>(
                                        stream: firestore.watchAllAttendance(),
                                        builder: (context, attendanceSnap) {
                                          final progress =
                                              progressSnap.data ?? [];
                                          final assignments =
                                              assignmentsSnap.data ?? [];
                                          final results =
                                              resultsSnap.data ?? [];
                                          final classTerms =
                                              termsSnap.data ?? [];
                                          final exercises =
                                              exercisesSnap.data ?? [];
                                          final lessonsByOwnerId = lessonsSnap
                                                  .data ??
                                              const <String, List<Lesson>>{};
                                          final lessons = lessonsByOwnerId
                                              .values
                                              .expand((e) => e)
                                              .toList();
                                          final sessions =
                                              sessionsSnap.data ?? [];
                                          final attendance =
                                              attendanceSnap.data ?? [];

                                          final exercisesById = {
                                            for (final e in exercises) e.id: e,
                                          };

                                          final homeworkOverview =
                                              TeacherActivityUtils
                                                  .buildHomeworkOverview(
                                            students: students,
                                            assignments: assignments,
                                            results: results,
                                            exercisesById: exercisesById,
                                          );
                                          final attentionItems =
                                              TeacherAttentionUtils.buildItems(
                                            students: students,
                                            progress: progress,
                                            assignments: assignments,
                                            exerciseResults: results,
                                            classTerms: classTerms,
                                          );
                                          final rosters = TeacherStatsUtils
                                              .buildStudentRosters(
                                            students: students,
                                            progress: progress,
                                            assignments: assignments,
                                            results: results,
                                            classTerms: classTerms,
                                            attendance: attendance,
                                            lessonsByOwnerId: lessonsByOwnerId,
                                          );
                                          final weeklyActivity =
                                              TeacherActivityUtils
                                                  .buildWeeklyActivity(
                                            progress: progress,
                                            results: results,
                                          );
                                          final activityFeed =
                                              TeacherActivityUtils.buildFeed(
                                            l: context.l10n,
                                            students: students,
                                            progress: progress,
                                            assignments: assignments,
                                            exerciseResults: results,
                                            attendance: attendance,
                                            sessions: sessions,
                                            classTerms: classTerms,
                                            exercisesById: exercisesById,
                                            lessonsById: {
                                              for (final l in lessons) l.id: l,
                                            },
                                            limit: 100,
                                          );

                                          return _StatDetailBody(
                                            kind: kind,
                                            routes: routes,
                                            students: students,
                                            rosters: rosters,
                                            homeworkOverview: homeworkOverview,
                                            attentionItems: attentionItems,
                                            weeklyActivity: weeklyActivity,
                                            activityFeed: activityFeed,
                                            sessions: sessions,
                                            assignments: assignments,
                                            results: results,
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
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _StatDetailBody extends StatelessWidget {
  const _StatDetailBody({
    required this.kind,
    required this.routes,
    required this.students,
    required this.rosters,
    required this.homeworkOverview,
    required this.attentionItems,
    required this.weeklyActivity,
    required this.activityFeed,
    required this.sessions,
    required this.assignments,
    required this.results,
  });

  final TeacherDashboardStatKind kind;
  final DashboardStatRoutes routes;
  final List<AppUser> students;
  final List<StudentRosterSummary> rosters;
  final HomeworkOverview homeworkOverview;
  final List<AttentionItem> attentionItems;
  final List<WeeklyActivityDay> weeklyActivity;
  final List<TeacherActivityEvent> activityFeed;
  final List<ClassSession> sessions;
  final List<ExerciseAssignment> assignments;
  final List<ExerciseResult> results;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AppCard(
          child: Text(
            kind.localizedDescription(l),
            style: TextStyle(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ..._buildContent(context),
      ],
    );
  }

  List<Widget> _buildContent(BuildContext context) {
    final l = context.l10n;
    return switch (kind) {
      TeacherDashboardStatKind.students => [_rosterList(context, rosters)],
      TeacherDashboardStatKind.activeThisWeek => [
          _rosterList(context, _activeRosters()),
        ],
      TeacherDashboardStatKind.homeworkDone => [
          _homeworkRows(
            context,
            homeworkOverview.rows.where((row) => row.isDone).toList(),
            emptyTitle: l.teacherDashNoCompletedHomeworkTitle,
            emptySubtitle: l.teacherDashNoCompletedHomeworkSubtitle,
          ),
        ],
      TeacherDashboardStatKind.overdue => [
          _homeworkRows(
            context,
            homeworkOverview.rows.where((row) => row.isOverdue).toList(),
            emptyTitle: l.teacherDashNoOverdueTitle,
            emptySubtitle: l.teacherDashNoOverdueSubtitle,
          ),
        ],
      TeacherDashboardStatKind.avgQuiz => [
          _scoreList(
            context,
            rosters
                .where((student) => student.avgQuizScore != null)
                .map(
                  (student) => _ScoreRow(
                    studentId: student.studentId,
                    name: student.name,
                    subtitle: student.levelLabel,
                    score: student.avgQuizScore!,
                  ),
                )
                .toList()
              ..sort((a, b) => b.score.compareTo(a.score)),
            emptyTitle: l.teacherDashNoQuizScoresTitle,
            emptySubtitle: l.teacherDashNoQuizScoresSubtitle,
          ),
        ],
      TeacherDashboardStatKind.avgPractice => [
          _scoreList(
            context,
            _practiceAverages(l),
            emptyTitle: l.teacherDashNoPracticeScoresTitle,
            emptySubtitle: l.teacherDashNoPracticeScoresSubtitle,
          ),
        ],
      TeacherDashboardStatKind.sessionsLeft => [
          _sessionBalanceList(context),
        ],
      TeacherDashboardStatKind.classesThisWeek => [
          _classesThisWeekList(context),
        ],
      TeacherDashboardStatKind.needAttention => [
          _attentionList(context),
        ],
      TeacherDashboardStatKind.weeklyActivity => [
          WeeklyActivityChart(days: weeklyActivity),
          const SizedBox(height: 16),
          _weeklyEventList(context),
        ],
      TeacherDashboardStatKind.homeworkOverview => [
          _homeworkSummary(context),
          const SizedBox(height: 12),
          _homeworkRows(
            context,
            homeworkOverview.rows,
            emptyTitle: l.teacherDashNoHomeworkTitle,
            emptySubtitle: l.teacherDashNoHomeworkSubtitle,
          ),
        ],
    };
  }

  List<StudentRosterSummary> _activeRosters() {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return rosters
        .where(
          (student) =>
              student.lastActivityAt != null &&
              student.lastActivityAt!.isAfter(cutoff),
        )
        .toList();
  }

  List<_ScoreRow> _practiceAverages(AppLocalizations l) {
    final bestByAssignment = ExerciseUtils.bestScoresByStudentExercise(results);
    final totals = <String, _PracticeAccumulator>{};

    for (final assignment in assignments) {
      final key = '${assignment.studentId}_${assignment.exerciseId}';
      final score = bestByAssignment[key];
      if (score == null) continue;
      totals
          .putIfAbsent(assignment.studentId, _PracticeAccumulator.new)
          .add(score);
    }

    final rows = <_ScoreRow>[];
    for (final roster in rosters) {
      final total = totals[roster.studentId];
      if (total == null || total.count == 0) continue;
      rows.add(
        _ScoreRow(
          studentId: roster.studentId,
          name: roster.name,
          subtitle:
              l.teacherDashExerciseCountLevel(total.count, roster.levelLabel),
          score: (total.sum / total.count).round(),
        ),
      );
    }
    rows.sort((a, b) => b.score.compareTo(a.score));
    return rows;
  }

  Widget _rosterList(BuildContext context, List<StudentRosterSummary> items) {
    if (items.isEmpty) {
      final l = context.l10n;
      return EmptyState(
        icon: Icons.people_outline,
        title: l.teacherDashNoStudentsToShowTitle,
        subtitle: l.teacherDashNoStudentsToShowSubtitle,
      );
    }
    return StudentRosterList(students: items, padding: EdgeInsets.zero);
  }

  Widget _homeworkSummary(BuildContext context) {
    final l = context.l10n;
    return AppCard(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          StatusPill(
            label: l.teacherDashHomeworkDone(homeworkOverview.completed),
            color: AppColors.success,
          ),
          StatusPill(
            label: l.teacherDashHomeworkToDo(homeworkOverview.pending),
            color: AppColors.teal,
          ),
          if (homeworkOverview.overdue > 0)
            StatusPill(
              label: l.teacherDashHomeworkOverdue(homeworkOverview.overdue),
              color: AppColors.error,
            ),
        ],
      ),
    );
  }

  Widget _homeworkRows(
    BuildContext context,
    List<HomeworkOverviewRow> rows, {
    required String emptyTitle,
    required String emptySubtitle,
  }) {
    if (rows.isEmpty) {
      return EmptyState(
        icon: Icons.assignment_outlined,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }
    final l = context.l10n;

    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              onTap: () => context.push(routes.studentDetail(row.studentId)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.studentName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          row.exerciseTitle,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        if (row.dueDate != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            ExerciseUtils.dueDateLabel(
                              row.dueDate,
                              isOverdue: row.isOverdue,
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: row.isOverdue
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (row.bestScore != null)
                    Text(
                      '${row.bestScore}%',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    )
                  else
                    StatusPill(
                      label: row.isOverdue
                          ? l.teacherDashOverdue
                          : l.teacherDashPending,
                      color: row.isOverdue
                          ? AppColors.error
                          : AppColors.textSecondary,
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _scoreList(
    BuildContext context,
    List<_ScoreRow> rows, {
    required String emptyTitle,
    required String emptySubtitle,
  }) {
    if (rows.isEmpty) {
      return EmptyState(
        icon: Icons.leaderboard_outlined,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              onTap: () => context.push(routes.studentDetail(row.studentId)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          row.subtitle,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${row.score}%',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _sessionBalanceList(BuildContext context) {
    final l = context.l10n;
    final items = rosters.toList()
      ..sort((a, b) => a.sessionsRemaining.compareTo(b.sessionsRemaining));

    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.event_busy_outlined,
        title: l.teacherDashNoSessionPackagesTitle,
        subtitle: l.teacherDashNoSessionPackagesSubtitle,
      );
    }

    return Column(
      children: [
        for (final student in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              onTap: () =>
                  context.push(routes.studentDetail(student.studentId)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          student.levelLabel,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusPill(
                    label: l.teacherDashSessionsLeft(student.sessionsRemaining),
                    color: student.sessionsRemaining > 0
                        ? AppColors.teal
                        : AppColors.error,
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _classesThisWeekList(BuildContext context) {
    final l = context.l10n;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    final thisWeek = sessions.where((session) {
      final parsed = DateTime.tryParse(session.sessionDate);
      if (parsed == null) return false;
      final day = DateTime(parsed.year, parsed.month, parsed.day);
      return !day.isBefore(weekStart) && day.isBefore(weekEnd);
    }).toList()
      ..sort((a, b) => a.sessionDate.compareTo(b.sessionDate));

    if (thisWeek.isEmpty) {
      return EmptyState(
        icon: Icons.event_outlined,
        title: l.teacherDashNoClassesThisWeekTitle,
        subtitle: l.teacherDashNoClassesThisWeekSubtitle,
      );
    }

    return Column(
      children: [
        for (final session in thisWeek)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              onTap: routes.sessionDetail == null
                  ? null
                  : () => context.push(routes.sessionDetail!(session.id)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.sessionTitle,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            _formatSessionDate(session.sessionDate),
                            session.timeRangeLabel,
                            if (session.isConcluded) l.teacherDashConcluded,
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
            ),
          ),
      ],
    );
  }

  Widget _attentionList(BuildContext context) {
    if (attentionItems.isEmpty) {
      final l = context.l10n;
      return EmptyState(
        icon: Icons.check_circle_outline,
        title: l.teacherDashAllCaughtUp,
        subtitle: l.teacherDashNoFollowUp,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return ResponsiveCardGrid(
          width: constraints.maxWidth,
          minCardWidth: 280,
          children: [
            for (final item in attentionItems)
              AppCard(
                onTap: () =>
                    context.push(routes.studentDetail(item.student.uid)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      _iconForReason(item.reason),
                      color: _colorForReason(item.reason),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.message,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _weeklyEventList(BuildContext context) {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final events = activityFeed
        .where((event) => event.occurredAt.isAfter(cutoff))
        .toList();

    if (events.isEmpty) {
      final l = context.l10n;
      return EmptyState(
        icon: Icons.insights_outlined,
        title: l.teacherDashNoActivityTitle,
        subtitle: l.teacherDashNoActivitySubtitle,
      );
    }

    return Column(
      children: [
        for (final event in events)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              onTap: event.studentId != null
                  ? () => context.push(routes.studentDetail(event.studentId!))
                  : event.studentRoute != null
                      ? () => context.push(event.studentRoute!)
                      : null,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (event.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            event.subtitle!,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEE d MMM · HH:mm')
                              .format(event.occurredAt),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (event.studentRoute != null)
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  static String _formatSessionDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('EEE, d MMM yyyy').format(parsed);
  }

  static IconData _iconForReason(AttentionReason reason) {
    return switch (reason) {
      AttentionReason.overdueExercise => Icons.warning_amber_rounded,
      AttentionReason.staleAssignment => Icons.assignment_late_outlined,
      AttentionReason.inactiveStudent => Icons.schedule_outlined,
      AttentionReason.lowSessions => Icons.event_busy_outlined,
    };
  }

  static Color _colorForReason(AttentionReason reason) {
    return switch (reason) {
      AttentionReason.overdueExercise => AppColors.error,
      AttentionReason.staleAssignment => AppColors.error,
      AttentionReason.inactiveStudent => AppColors.textSecondary,
      AttentionReason.lowSessions => AppColors.teal,
    };
  }
}

class _ScoreRow {
  const _ScoreRow({
    required this.studentId,
    required this.name,
    required this.subtitle,
    required this.score,
  });

  final String studentId;
  final String name;
  final String subtitle;
  final int score;
}

class _PracticeAccumulator {
  int sum = 0;
  int count = 0;

  void add(int score) {
    sum += score;
    count++;
  }
}
