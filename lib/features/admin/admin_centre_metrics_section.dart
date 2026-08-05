import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/utils/teacher_activity_utils.dart';
import '../../core/utils/teacher_attention_utils.dart';
import '../../core/utils/teacher_stats_utils.dart';
import '../../core/widgets/cohort_stats_widgets.dart';
import '../../core/widgets/teacher_activity_widgets.dart';
import '../../models/app_user.dart';
import '../../models/class_session.dart';
import '../../models/exercise.dart';
import '../../models/exercise_assignment.dart';
import '../../models/exercise_result.dart';
import '../../models/student_class_term.dart';
import '../../models/student_progress.dart';
import '../../models/teacher_dashboard_stat_kind.dart';
import '../../models/admin_dashboard_stat_kind.dart';
import '../../services/firestore_service.dart';

class AdminCentreMetricsSection extends StatelessWidget {
  const AdminCentreMetricsSection({
    super.key,
    required this.onCentreStatTap,
  });

  final ValueChanged<TeacherDashboardStatKind> onCentreStatTap;

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    // Per-teacher content model: centre metrics do not depend on
    // CONTENT_OWNER_ID. Lesson/progress detail screens aggregate via
    // AppConstants.contentOwnerFor(student).

    return StreamBuilder<List<AppUser>>(
      stream: firestore.watchAllStudents(),
      builder: (context, studentsSnap) {
        final students = studentsSnap.data ?? [];

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
                            return StreamBuilder<List<ClassSession>>(
                              stream: firestore.watchAllClassSessions(),
                              builder: (context, sessionsSnap) {
                                final progress = progressSnap.data ?? [];
                                final assignments =
                                    assignmentsSnap.data ?? [];
                                final results = resultsSnap.data ?? [];
                                final classTerms = termsSnap.data ?? [];
                                final exercises = exercisesSnap.data ?? [];
                                final sessions = sessionsSnap.data ?? [];

                                final exercisesById = {
                                  for (final e in exercises) e.id: e,
                                };

                                final homeworkOverview = TeacherActivityUtils
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

                                final cohortStats =
                                    TeacherStatsUtils.buildCohortStats(
                                  students: students,
                                  progress: progress,
                                  assignments: assignments,
                                  results: results,
                                  classTerms: classTerms,
                                  sessions: sessions,
                                  homeworkOverview: homeworkOverview,
                                  attentionItems: attentionItems,
                                );

                                final weeklyActivity =
                                    TeacherActivityUtils.buildWeeklyActivity(
                                  progress: progress,
                                  results: results,
                                );

                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    WeeklyActivityChart(
                                      days: weeklyActivity,
                                      onTap: () => onCentreStatTap(
                                        TeacherDashboardStatKind
                                            .weeklyActivity,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    CohortStatsGrid(
                                      stats: cohortStats,
                                      onStatTap: onCentreStatTap,
                                    ),
                                    const SizedBox(height: 20),
                                    HomeworkOverviewCard(
                                      overview: homeworkOverview,
                                      onTap: () => onCentreStatTap(
                                        TeacherDashboardStatKind
                                            .homeworkOverview,
                                      ),
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
              },
            );
          },
        );
      },
    );
  }
}

void openAdminCentreStatDetail(
  BuildContext context,
  TeacherDashboardStatKind kind,
) {
  context.push('/admin/dashboard/stat/${kind.routeSlug}');
}

void openAdminPlatformStatDetail(
  BuildContext context,
  AdminDashboardStatKind kind,
) {
  context.push('/admin/dashboard/stat/${kind.routeSlug}');
}
