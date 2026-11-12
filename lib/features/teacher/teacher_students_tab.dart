import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/teacher_stats_utils.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/cohort_stats_widgets.dart';
import '../../l10n/l10n.dart';
import '../../models/app_user.dart';
import '../../models/attendance_record.dart';
import '../../models/exercise_assignment.dart';
import '../../models/exercise_result.dart';
import '../../models/lesson.dart';
import '../../models/student_class_term.dart';
import '../../models/student_progress.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class TeacherStudentsTab extends StatelessWidget {
  const TeacherStudentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final firestore = context.read<FirestoreService>();
    final user = context.watch<AuthService>().appUser;
    // Per-teacher content model: teachers read their own library.
    final contentOwnerId =
        user == null ? '' : AppConstants.contentOwnerFor(user);

    return StreamBuilder<List<AppUser>>(
      stream: firestore.watchAllStudents(),
      builder: (context, studentsSnap) {
        if (studentsSnap.connectionState == ConnectionState.waiting &&
            !studentsSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (studentsSnap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l.teacherStudentsLoadFailed('${studentsSnap.error}'),
                style: TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final students = studentsSnap.data ?? [];
        if (students.isEmpty) {
          return EmptyState(
            icon: Icons.people_outline,
            title: l.teacherDashNoStudentsTitle,
            subtitle: l.studentLessonsNoDemoData,
          );
        }

        // Roster stats are best-effort: if a supporting stream fails, still
        // show the student list with empty metrics instead of a blank page.
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
                        return StreamBuilder<List<AttendanceRecord>>(
                          stream: firestore.watchAllAttendance(),
                          builder: (context, attendanceSnap) {
                            return StreamBuilder<List<Lesson>>(
                              stream: contentOwnerId.isEmpty
                                  ? Stream.value(const <Lesson>[])
                                  : firestore.watchLessons(contentOwnerId),
                              builder: (context, lessonsSnap) {
                                final lessons = lessonsSnap.data ?? [];
                                final lessonsByOwnerId = contentOwnerId.isEmpty
                                    ? <String, List<Lesson>>{}
                                    : {contentOwnerId: lessons};

                                final rosters =
                                    TeacherStatsUtils.buildStudentRosters(
                                  l: context.l10n,
                                  students: students,
                                  progress: progressSnap.data ?? const [],
                                  assignments: assignmentsSnap.data ?? const [],
                                  results: resultsSnap.data ?? const [],
                                  classTerms: termsSnap.data ?? const [],
                                  attendance: attendanceSnap.data ?? const [],
                                  lessonsByOwnerId: lessonsByOwnerId,
                                );

                                return StudentRosterList(students: rosters);
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
