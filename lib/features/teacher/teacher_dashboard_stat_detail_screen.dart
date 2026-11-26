import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/paging/paged_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/exercise_utils.dart';
import '../../core/utils/teacher_attention_utils.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/cohort_stats_widgets.dart';
import '../../core/widgets/paging_bars.dart';
import '../../core/widgets/shell_nested_page.dart';
import '../../core/widgets/status_pill.dart';
import '../../core/widgets/teacher_activity_widgets.dart';
import '../../l10n/l10n.dart';
import '../../l10n/labels_classes.dart';
import '../../models/class_session.dart';
import '../../models/cohort_report_models.dart';
import '../../models/dashboard_stat_routes.dart';
import '../../models/lesson.dart';
import '../../models/roster_row.dart';
import '../../models/teacher_activity_event.dart';
import '../../models/teacher_dashboard_stat_kind.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/list_pages_service.dart';

/// A teacher-dashboard figure opened as a list. Build 9 part 2: every list
/// is read a page at a time — the student lists from `progress_summary`
/// (its roster block, written by the functions), the homework lists from
/// the assignments with their `done` stamp, the week from bounded queries —
/// instead of eight whole collections streamed into the browser.
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
    return ShellNestedPage(
      embedded: embedded,
      title: kind.localizedTitle(context.l10n),
      child: _StatDetailBody(key: ValueKey(kind), kind: kind, routes: routes),
    );
  }
}

class _StatDetailBody extends StatefulWidget {
  const _StatDetailBody({super.key, required this.kind, required this.routes});

  final TeacherDashboardStatKind kind;
  final DashboardStatRoutes routes;

  @override
  State<_StatDetailBody> createState() => _StatDetailBodyState();
}

class _StatDetailBodyState extends State<_StatDetailBody> {
  late final ListPagesService _lists =
      ListPagesService(context.read<FirestoreService>());
  final Map<String, List<Lesson>> _lessons = {};
  PagedController<StudentRosterSummary>? _roster;
  PagedController<Object?>? _pages;
  Future<({int total, int done, int overdue})>? _homeworkCounts;
  Future<List<WeeklyActivityDay>>? _week;

  TeacherDashboardStatKind get kind => widget.kind;

  /// Teachers see their own classes; admins the whole centre.
  String? get _teacherUid {
    final user = context.read<AuthService>().appUser;
    return user != null && user.isTeacher ? user.uid : null;
  }

  @override
  void initState() {
    super.initState();
    final l = context.l10n;
    switch (kind) {
      case TeacherDashboardStatKind.students:
      case TeacherDashboardStatKind.activeThisWeek:
        final active = kind == TeacherDashboardStatKind.activeThisWeek;
        _roster = PagedController<StudentRosterSummary>(
          build: (_) => MappedPageSource<RosterRow, StudentRosterSummary>(
            _lists.summarySource(
              orderBy: active ? 'roster.lastActiveMs' : 'nameLower',
              descending: active,
              minMs: active
                  ? DateTime.now()
                      .subtract(const Duration(days: 7))
                      .millisecondsSinceEpoch
                  : null,
            ),
            (page) async {
              await _lists.lessonsFor(page.map((r) => r.student), _lessons);
              return [
                for (final r in page)
                  r.toSummary(l: l, lessonsByOwnerId: _lessons),
              ];
            },
          ),
        );
      case TeacherDashboardStatKind.avgQuiz:
        _pages = PagedController<Object?>(
            build: (_) => _lists.summarySource(
                orderBy: 'roster.lessonAvg', descending: true, notNull: true));
      case TeacherDashboardStatKind.avgPractice:
        _pages = PagedController<Object?>(
            build: (_) => _lists.summarySource(
                orderBy: 'roster.practiceAvg', descending: true, notNull: true));
      case TeacherDashboardStatKind.sessionsLeft:
        _pages = PagedController<Object?>(
            build: (_) =>
                _lists.summarySource(orderBy: 'roster.sessionsRemaining'));
      case TeacherDashboardStatKind.needAttention:
        _pages = PagedController<Object?>(
            build: (_) => _lists.summarySource(attentionOnly: true));
      case TeacherDashboardStatKind.homeworkDone:
        _pages = PagedController<Object?>(
            build: (_) => _lists.homeworkSource(HomeworkView.done));
      case TeacherDashboardStatKind.overdue:
        _pages = PagedController<Object?>(
            build: (_) => _lists.homeworkSource(HomeworkView.overdue));
      case TeacherDashboardStatKind.homeworkOverview:
        _homeworkCounts = _lists.homeworkCounts();
        _pages = PagedController<Object?>(
            build: (_) => _lists.homeworkSource(HomeworkView.all));
      case TeacherDashboardStatKind.weeklyActivity:
        _week = _lists.weeklyActivity();
        _pages = PagedController<Object?>(
            build: (_) =>
                _lists.weeklyFeedSource(l, teacherUid: _teacherUid));
      case TeacherDashboardStatKind.classesThisWeek:
        _pages = PagedController<Object?>(
            build: (_) =>
                _lists.classesThisWeekSource(teacherUid: _teacherUid));
    }
  }

  @override
  void dispose() {
    _roster?.dispose();
    _pages?.dispose();
    super.dispose();
  }

  Widget _description(BuildContext context) => AppCard(
        child: Text(
          kind.localizedDescription(context.l10n),
          style: TextStyle(color: AppColors.textSecondary, height: 1.45),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final roster = _roster;
    if (roster != null) {
      return StudentRosterList(controller: roster, header: _description(context));
    }
    final pages = _pages!;
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _description(context),
        if (_homeworkCounts != null) ...[
          const SizedBox(height: 12),
          _HomeworkCounts(counts: _homeworkCounts!),
        ],
        if (_week != null) ...[
          const SizedBox(height: 12),
          FutureBuilder<List<WeeklyActivityDay>>(
            future: _week,
            builder: (context, snap) => snap.hasData
                ? WeeklyActivityChart(days: snap.data!)
                : const LinearProgressIndicator(minHeight: 2),
          ),
        ],
      ],
    );
    final (empty, emptyTitle, emptySubtitle) = switch (kind) {
      TeacherDashboardStatKind.homeworkDone => (
          Icons.assignment_outlined,
          l.teacherDashNoCompletedHomeworkTitle,
          l.teacherDashNoCompletedHomeworkSubtitle
        ),
      TeacherDashboardStatKind.overdue => (
          Icons.assignment_outlined,
          l.teacherDashNoOverdueTitle,
          l.teacherDashNoOverdueSubtitle
        ),
      TeacherDashboardStatKind.homeworkOverview => (
          Icons.assignment_outlined,
          l.teacherDashNoHomeworkTitle,
          l.teacherDashNoHomeworkSubtitle
        ),
      TeacherDashboardStatKind.avgQuiz => (
          Icons.leaderboard_outlined,
          l.teacherDashNoQuizScoresTitle,
          l.teacherDashNoQuizScoresSubtitle
        ),
      TeacherDashboardStatKind.avgPractice => (
          Icons.leaderboard_outlined,
          l.teacherDashNoPracticeScoresTitle,
          l.teacherDashNoPracticeScoresSubtitle
        ),
      TeacherDashboardStatKind.sessionsLeft => (
          Icons.event_busy_outlined,
          l.teacherDashNoSessionPackagesTitle,
          l.teacherDashNoSessionPackagesSubtitle
        ),
      TeacherDashboardStatKind.classesThisWeek => (
          Icons.event_outlined,
          l.teacherDashNoClassesThisWeekTitle,
          l.teacherDashNoClassesThisWeekSubtitle
        ),
      TeacherDashboardStatKind.needAttention => (
          Icons.check_circle_outline,
          l.teacherDashAllCaughtUp,
          l.teacherDashNoFollowUp
        ),
      TeacherDashboardStatKind.weeklyActivity => (
          Icons.insights_outlined,
          l.teacherDashNoActivityTitle,
          l.teacherDashNoActivitySubtitle
        ),
      _ => (Icons.inbox_outlined, null, null),
    };
    return ListenableBuilder(
      listenable: pages,
      builder: (context, _) => PagedListBody<Object?>(
        controller: pages,
        header: header,
        separator: 8,
        emptyIcon: empty,
        emptyTitle: emptyTitle,
        emptySubtitle: emptySubtitle,
        itemBuilder: (context, item) => _item(context, item),
      ),
    );
  }

  Widget _item(BuildContext context, Object? item) {
    final l = context.l10n;
    final routes = widget.routes;
    if (item is HomeworkOverviewRow) return _HomeworkCard(row: item, routes: routes);
    if (item is TeacherActivityEvent) return _EventCard(event: item, routes: routes);
    if (item is ClassSession) return _SessionCard(session: item, routes: routes);
    if (item is RosterRow) {
      final s = item.toSummary(l: l);
      switch (kind) {
        case TeacherDashboardStatKind.avgQuiz:
          return _ScoreCard(
            studentId: s.studentId,
            name: s.staffLabel,
            subtitle: s.levelLabel,
            score: item.lessonAvg ?? 0,
            routes: routes,
          );
        case TeacherDashboardStatKind.avgPractice:
          return _ScoreCard(
            studentId: s.studentId,
            name: s.staffLabel,
            subtitle:
                l.teacherDashExerciseCountLevel(item.practiceCount, s.levelLabel),
            score: item.practiceAvg ?? 0,
            routes: routes,
          );
        case TeacherDashboardStatKind.sessionsLeft:
          return _BalanceCard(summary: s, routes: routes);
        case TeacherDashboardStatKind.needAttention:
          return Column(
            children: [
              for (final (i, a) in item.attention.indexed) ...[
                if (i > 0) const SizedBox(height: 8),
                _AttentionCard(item: a, routes: routes),
              ],
            ],
          );
        default:
          return const SizedBox.shrink();
      }
    }
    return const SizedBox.shrink();
  }
}

class _HomeworkCounts extends StatelessWidget {
  const _HomeworkCounts({required this.counts});

  final Future<({int total, int done, int overdue})> counts;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return FutureBuilder<({int total, int done, int overdue})>(
      future: counts,
      builder: (context, snap) {
        final c = snap.data;
        if (c == null) return const LinearProgressIndicator(minHeight: 2);
        final pending = c.total - c.done - c.overdue;
        return AppCard(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusPill(
                  label: l.teacherDashHomeworkDone(c.done),
                  color: AppColors.success),
              StatusPill(
                  label: l.teacherDashHomeworkToDo(pending),
                  color: AppColors.teal),
              if (c.overdue > 0)
                StatusPill(
                    label: l.teacherDashHomeworkOverdue(c.overdue),
                    color: AppColors.error),
            ],
          ),
        );
      },
    );
  }
}

class _HomeworkCard extends StatelessWidget {
  const _HomeworkCard({required this.row, required this.routes});

  final HomeworkOverviewRow row;
  final DashboardStatRoutes routes;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppCard(
      onTap: () => context.push(routes.studentDetail(row.studentId)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.studentName,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(row.exerciseTitle,
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                if (row.dueDate != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    ExerciseUtils.dueDateLabel(row.dueDate,
                        isOverdue: row.isOverdue),
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
            Text('${row.bestScore}%',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.success))
          else
            StatusPill(
              label: row.isOverdue ? l.teacherDashOverdue : l.teacherDashPending,
              color: row.isOverdue ? AppColors.error : AppColors.textSecondary,
            ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
    required this.studentId,
    required this.name,
    required this.subtitle,
    required this.score,
    required this.routes,
  });

  final String studentId;
  final String name;
  final String subtitle;
  final int score;
  final DashboardStatRoutes routes;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.push(routes.studentDetail(studentId)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          Text('$score%',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.navy)),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.summary, required this.routes});

  final StudentRosterSummary summary;
  final DashboardStatRoutes routes;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppCard(
      onTap: () => context.push(routes.studentDetail(summary.studentId)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(summary.staffLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(summary.levelLabel,
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          StatusPill(
            label: l.teacherDashSessionsLeft(summary.sessionsRemaining),
            color: summary.sessionsRemaining > 0
                ? AppColors.teal
                : AppColors.error,
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.routes});

  final ClassSession session;
  final DashboardStatRoutes routes;

  static String _date(String raw) {
    final parsed = DateTime.tryParse(raw);
    return parsed == null ? raw : DateFormat('EEE, d MMM yyyy').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppCard(
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
                Text(session.sessionTitle,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  [
                    _date(session.sessionDate),
                    session.timeRangeLabel,
                    if (session.isConcluded) l.teacherDashConcluded,
                  ].join(' · '),
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
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

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({required this.item, required this.routes});

  final AttentionItem item;
  final DashboardStatRoutes routes;

  static IconData _icon(AttentionReason reason) => switch (reason) {
        AttentionReason.overdueExercise => Icons.warning_amber_rounded,
        AttentionReason.staleAssignment => Icons.assignment_late_outlined,
        AttentionReason.inactiveStudent => Icons.schedule_outlined,
        AttentionReason.lowSessions => Icons.event_busy_outlined,
      };

  static Color _color(AttentionReason reason) => switch (reason) {
        AttentionReason.overdueExercise => AppColors.error,
        AttentionReason.staleAssignment => AppColors.error,
        AttentionReason.inactiveStudent => AppColors.textSecondary,
        AttentionReason.lowSessions => AppColors.teal,
      };

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.push(routes.studentDetail(item.student.uid)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(_icon(item.reason), color: _color(item.reason), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(item.localizedMessage(context.l10n),
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.routes});

  final TeacherActivityEvent event;
  final DashboardStatRoutes routes;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: event.studentId != null
          ? () => context.push(routes.studentDetail(event.studentId!))
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                if (event.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(event.subtitle!,
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                ],
                const SizedBox(height: 4),
                Text(DateFormat('EEE d MMM · HH:mm').format(event.occurredAt),
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          if (event.studentRoute != null)
            Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
