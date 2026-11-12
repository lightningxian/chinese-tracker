import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/teacher_activity_utils.dart';
import '../../core/utils/teacher_attention_utils.dart';
import '../../core/utils/teacher_stats_utils.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/cohort_stats_widgets.dart';
import '../../core/widgets/responsive_card_grid.dart';
import '../../core/widgets/teacher_activity_widgets.dart';
import '../admin/admin_dashboard_widgets.dart';
import '../../l10n/l10n.dart';
import '../../l10n/labels_classes.dart';
import '../../models/app_user.dart';
import '../../models/attendance_record.dart';
import '../../models/class_session.dart';
import '../../models/exercise.dart';
import '../../models/exercise_assignment.dart';
import '../../models/exercise_result.dart';
import '../../models/grade.dart';
import '../../models/lesson.dart';
import '../../models/student_class_term.dart';
import '../../models/student_progress.dart';
import '../../models/teacher_dashboard_stat_kind.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class TeacherDashboardTab extends StatelessWidget {
  const TeacherDashboardTab({super.key});

  void _openStatDetail(
    BuildContext context,
    TeacherDashboardStatKind kind,
  ) {
    context.push('/teacher/dashboard/stat/${kind.routeSlug}');
  }

  IconData _iconForReason(AttentionReason reason) {
    return switch (reason) {
      AttentionReason.overdueExercise => Icons.warning_amber_rounded,
      AttentionReason.staleAssignment => Icons.assignment_late_outlined,
      AttentionReason.inactiveStudent => Icons.schedule_outlined,
      AttentionReason.lowSessions => Icons.event_busy_outlined,
    };
  }

  Color _colorForReason(AttentionReason reason) {
    return switch (reason) {
      AttentionReason.overdueExercise => AppColors.error,
      AttentionReason.staleAssignment => AppColors.error,
      AttentionReason.inactiveStudent => AppColors.textSecondary,
      AttentionReason.lowSessions => AppColors.teal,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final firestore = context.read<FirestoreService>();
    final teacher = context.watch<AuthService>().appUser;
    // Per-teacher content model via contentOwnerFor (same key students use).
    final contentOwnerId =
        teacher == null ? '' : AppConstants.contentOwnerFor(teacher);
    final teacherId = contentOwnerId;

    return StreamBuilder<List<AppUser>>(
      stream: firestore.watchAllStudents(),
      builder: (context, studentsSnap) {
        if (studentsSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final students = studentsSnap.data ?? [];
        if (students.isEmpty) {
          return EmptyState(
            icon: Icons.school_outlined,
            title: l.teacherDashNoDemoTitle,
            subtitle: l.teacherDashNoDemoSubtitle,
          );
        }

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
                            return StreamBuilder<List<Lesson>>(
                              stream: contentOwnerId.isEmpty
                                  ? Stream.value(const <Lesson>[])
                                  : firestore.watchLessons(contentOwnerId),
                              builder: (context, lessonsSnap) {
                                return StreamBuilder<List<ClassSession>>(
                                  stream: firestore.watchTeacherSessions(
                                    teacherId,
                                  ),
                                  builder: (context, sessionsSnap) {
                                    return StreamBuilder<
                                        List<AttendanceRecord>>(
                                      stream: firestore.watchAllAttendance(),
                                      builder: (context, attendanceSnap) {
                                        final allProgress =
                                            progressSnap.data ?? [];
                                        final assignments =
                                            assignmentsSnap.data ?? [];
                                        final results = resultsSnap.data ?? [];
                                        final classTerms = termsSnap.data ?? [];
                                        final exercises =
                                            exercisesSnap.data ?? [];
                                        final lessons = lessonsSnap.data ?? [];
                                        final sessions =
                                            sessionsSnap.data ?? [];
                                        final attendance =
                                            attendanceSnap.data ?? [];

                                        final exercisesById = {
                                          for (final e in exercises) e.id: e,
                                        };
                                        final lessonsById = {
                                          for (final l in lessons) l.id: l,
                                        };

                                        final activeThisWeek =
                                            TeacherActivityUtils
                                                .countActiveThisWeek(
                                          students: students,
                                          progress: allProgress,
                                          results: results,
                                        );

                                        final attentionItems =
                                            TeacherAttentionUtils.buildItems(
                                          students: students,
                                          progress: allProgress,
                                          assignments: assignments,
                                          exerciseResults: results,
                                          classTerms: classTerms,
                                        );

                                        final homeworkOverview =
                                            TeacherActivityUtils
                                                .buildHomeworkOverview(
                                          students: students,
                                          assignments: assignments,
                                          results: results,
                                          exercisesById: exercisesById,
                                        );

                                        final cohortStats =
                                            TeacherStatsUtils.buildCohortStats(
                                          students: students,
                                          progress: allProgress,
                                          assignments: assignments,
                                          results: results,
                                          classTerms: classTerms,
                                          sessions: sessions,
                                          homeworkOverview: homeworkOverview,
                                          attentionItems: attentionItems,
                                        );

                                        final activityFeed =
                                            TeacherActivityUtils.buildFeed(
                                          l: l,
                                          students: students,
                                          progress: allProgress,
                                          assignments: assignments,
                                          exerciseResults: results,
                                          attendance: attendance,
                                          sessions: sessions,
                                          classTerms: classTerms,
                                          exercisesById: exercisesById,
                                          lessonsById: lessonsById,
                                        );

                                        final weeklyActivity =
                                            TeacherActivityUtils
                                                .buildWeeklyActivity(
                                          progress: allProgress,
                                          results: results,
                                        );

                                        final recentStudents =
                                            TeacherActivityUtils
                                                .sortStudentsByLastActivity(
                                          students: students,
                                          progress: allProgress,
                                          results: results,
                                          attendance: attendance,
                                        );

                                        return ListView(
                                          padding: const EdgeInsets.all(20),
                                          children: [
                                            Text(
                                              l.teacherShellNavDashboard,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headlineSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.navy,
                                                  ),
                                            ),
                                            const SizedBox(height: 16),
                                            AppCard(
                                              onTap: () => context
                                                  .push('/teacher/calendar'),
                                              padding: const EdgeInsets.all(14),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            10),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.teal
                                                          .withValues(
                                                              alpha: 0.12),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: Icon(
                                                      Icons
                                                          .calendar_month_outlined,
                                                      color: AppColors.teal,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      l.commonViewClassCalendar,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                  ),
                                                  Icon(
                                                    Icons.chevron_right,
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            StreamBuilder<List<Grade>>(
                                              stream: firestore
                                                  .watchTeacherPendingGrades(
                                                      teacherId),
                                              builder: (context, gradeSnap) {
                                                final pending =
                                                    gradeSnap.data?.length ?? 0;
                                                return AppCard(
                                                  onTap: () => context
                                                      .push('/teacher/grades'),
                                                  padding:
                                                      const EdgeInsets.all(14),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(10),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: AppColors
                                                              .brandYellow
                                                              .withValues(
                                                                  alpha: 0.16),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                        child: Icon(
                                                          Icons
                                                              .grading_outlined,
                                                          color: AppColors
                                                              .brandYellow,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Text(
                                                          l.teacherDashGradebook,
                                                          style:
                                                              const TextStyle(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 15,
                                                          ),
                                                        ),
                                                      ),
                                                      if (pending > 0) ...[
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            horizontal: 10,
                                                            vertical: 4,
                                                          ),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: AppColors
                                                                .brandYellow
                                                                .withValues(
                                                                    alpha: 0.2),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20),
                                                          ),
                                                          child: Text(
                                                            l.teacherDashPendingCount(
                                                                pending),
                                                            style: TextStyle(
                                                              color: AppColors
                                                                  .navy,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                      ],
                                                      Icon(
                                                        Icons.chevron_right,
                                                        color: AppColors
                                                            .textSecondary,
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                            const SizedBox(height: 12),
                                            AppCard(
                                              onTap: () => context
                                                  .push('/teacher/materials'),
                                              padding: const EdgeInsets.all(14),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            10),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.navy
                                                          .withValues(
                                                              alpha: 0.08),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: Icon(
                                                      Icons
                                                          .folder_open_outlined,
                                                      color: AppColors.navy,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      l.studentHomeQuickMaterials,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                  ),
                                                  Icon(
                                                    Icons.chevron_right,
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            LayoutBuilder(
                                              builder: (context, constraints) {
                                                return ResponsiveCardGrid(
                                                  width: constraints.maxWidth,
                                                  minCardWidth: 220,
                                                  maxColumns: 2,
                                                  children: [
                                                    AdminStatCard(
                                                      label: l
                                                          .teacherShellNavStudents,
                                                      value:
                                                          '${students.length}',
                                                      icon:
                                                          Icons.people_outline,
                                                      color: AppColors.navy,
                                                      onTap: () =>
                                                          _openStatDetail(
                                                        context,
                                                        TeacherDashboardStatKind
                                                            .students,
                                                      ),
                                                    ),
                                                    AdminStatCard(
                                                      label: l
                                                          .teacherDashActiveThisWeek,
                                                      value: '$activeThisWeek',
                                                      icon: Icons.trending_up,
                                                      color: AppColors.teal,
                                                      onTap: () =>
                                                          _openStatDetail(
                                                        context,
                                                        TeacherDashboardStatKind
                                                            .activeThisWeek,
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                            const SizedBox(height: 20),
                                            WeeklyActivityChart(
                                              days: weeklyActivity,
                                              onTap: () => _openStatDetail(
                                                context,
                                                TeacherDashboardStatKind
                                                    .weeklyActivity,
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            CohortStatsGrid(
                                              stats: cohortStats,
                                              onStatTap: (kind) =>
                                                  _openStatDetail(
                                                      context, kind),
                                            ),
                                            const SizedBox(height: 20),
                                            HomeworkOverviewCard(
                                              overview: homeworkOverview,
                                              onTap: () => _openStatDetail(
                                                context,
                                                TeacherDashboardStatKind
                                                    .homeworkOverview,
                                              ),
                                            ),
                                            const SizedBox(height: 24),
                                            SectionHeader(
                                              title:
                                                  l.teacherDashNeedsAttention,
                                            ),
                                            if (attentionItems.isEmpty)
                                              EmptyState(
                                                icon:
                                                    Icons.check_circle_outline,
                                                title: l.teacherDashAllCaughtUp,
                                                subtitle:
                                                    l.teacherDashNoFollowUp,
                                              )
                                            else
                                              LayoutBuilder(
                                                builder: (
                                                  context,
                                                  constraints,
                                                ) {
                                                  return ResponsiveCardGrid(
                                                    width: constraints.maxWidth,
                                                    minCardWidth: 280,
                                                    children: [
                                                      for (final item
                                                          in attentionItems
                                                              .take(12))
                                                        AppCard(
                                                          onTap: () =>
                                                              context.push(
                                                            '/teacher/student/${item.student.uid}',
                                                          ),
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            horizontal: 14,
                                                            vertical: 12,
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                _iconForReason(
                                                                  item.reason,
                                                                ),
                                                                color:
                                                                    _colorForReason(
                                                                  item.reason,
                                                                ),
                                                                size: 22,
                                                              ),
                                                              const SizedBox(
                                                                width: 12,
                                                              ),
                                                              Expanded(
                                                                child: Text(
                                                                  item.localizedMessage(
                                                                      l),
                                                                  style:
                                                                      const TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                  ),
                                                                ),
                                                              ),
                                                              Icon(
                                                                Icons
                                                                    .chevron_right,
                                                                color: AppColors
                                                                    .textSecondary,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                    ],
                                                  );
                                                },
                                              ),
                                            const SizedBox(height: 24),
                                            TeacherActivityFeed(
                                              events: activityFeed,
                                            ),
                                            const SizedBox(height: 24),
                                            SectionHeader(
                                              title:
                                                  l.teacherDashRecentStudents,
                                            ),
                                            if (recentStudents.isEmpty)
                                              EmptyState(
                                                icon: Icons.people_outline,
                                                title: l
                                                    .teacherDashNoStudentsTitle,
                                                subtitle: l
                                                    .teacherDashNoStudentsSubtitle,
                                              )
                                            else
                                              LayoutBuilder(
                                                builder: (
                                                  context,
                                                  constraints,
                                                ) {
                                                  return ResponsiveCardGrid(
                                                    width: constraints.maxWidth,
                                                    minCardWidth: 260,
                                                    children: [
                                                      for (final student
                                                          in recentStudents
                                                              .take(8))
                                                        AppCard(
                                                          onTap: () =>
                                                              context.push(
                                                            '/teacher/student/${student.uid}',
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              CircleAvatar(
                                                                backgroundColor:
                                                                    AppColors
                                                                        .navy
                                                                        .withValues(
                                                                  alpha: 0.1,
                                                                ),
                                                                child: Text(
                                                                  student.name
                                                                          .isNotEmpty
                                                                      ? student
                                                                          .name[
                                                                              0]
                                                                          .toUpperCase()
                                                                      : '?',
                                                                  style:
                                                                      TextStyle(
                                                                    color:
                                                                        AppColors
                                                                            .navy,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 12,
                                                              ),
                                                              Expanded(
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Text(
                                                                      student
                                                                          .name,
                                                                      style:
                                                                          const TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.w600,
                                                                      ),
                                                                    ),
                                                                    Text(
                                                                      student.level ??
                                                                          l.commonStudent,
                                                                      style:
                                                                          TextStyle(
                                                                        color: AppColors
                                                                            .textSecondary,
                                                                        fontSize:
                                                                            13,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              const Icon(
                                                                Icons
                                                                    .chevron_right,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                    ],
                                                  );
                                                },
                                              ),
                                            if (students.isEmpty) ...[
                                              const SizedBox(height: 16),
                                              AppCard(
                                                child: Text(
                                                  l.studentLessonsNoDemoData,
                                                  style: TextStyle(
                                                    color:
                                                        AppColors.textSecondary,
                                                    fontSize: 13,
                                                  ),
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
