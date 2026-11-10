import '../../core/constants/app_constants.dart';
import '../../models/app_user.dart';
import '../../models/attendance_record.dart';
import '../../models/class_session.dart';
import '../../models/cohort_report_models.dart';
import '../../models/exercise_assignment.dart';
import '../../models/exercise_result.dart';
import '../../models/lesson.dart';
import '../../models/student_class_term.dart';
import '../../models/student_progress.dart';
import '../../models/teacher_activity_event.dart';
import 'exercise_utils.dart';
import 'progress_utils.dart';
import 'teacher_activity_utils.dart';
import 'teacher_attention_utils.dart';

abstract final class TeacherStatsUtils {
  static CohortStats buildCohortStats({
    required List<AppUser> students,
    required List<StudentProgress> progress,
    required List<ExerciseAssignment> assignments,
    required List<ExerciseResult> results,
    required List<StudentClassTerm> classTerms,
    required List<ClassSession> sessions,
    required HomeworkOverview homeworkOverview,
    required List<AttentionItem> attentionItems,
  }) {
    final activeThisWeek = TeacherActivityUtils.countActiveThisWeek(
      students: students,
      progress: progress,
      results: results,
    );

    final homeworkCompletionPercent = homeworkOverview.totalAssigned == 0
        ? 0
        : ((homeworkOverview.completed / homeworkOverview.totalAssigned) * 100)
            .round();

    final attentionStudents = attentionItems.map((i) => i.student.uid).toSet();

    return CohortStats(
      totalStudents: students.length,
      activeThisWeek: activeThisWeek,
      homeworkCompletionPercent: homeworkCompletionPercent,
      overdueAssignments: homeworkOverview.overdue,
      avgQuizScore: _cohortAvgQuizScore(progress),
      avgPracticeScore: _cohortAvgPracticeScore(assignments, results),
      totalSessionsRemaining: _totalSessionsRemaining(classTerms),
      classesThisWeek: _classesThisWeek(sessions),
      studentsNeedingAttention: attentionStudents.length,
    );
  }

  static List<StudentRosterSummary> buildStudentRosters({
    required List<AppUser> students,
    required List<StudentProgress> progress,
    required List<ExerciseAssignment> assignments,
    required List<ExerciseResult> results,
    required List<StudentClassTerm> classTerms,
    required List<AttendanceRecord> attendance,
    required Map<String, List<Lesson>> lessonsByOwnerId,
  }) {
    final progressByStudent = <String, List<StudentProgress>>{};
    for (final record in progress) {
      progressByStudent.putIfAbsent(record.studentId, () => []).add(record);
    }

    final assignmentsByStudent = <String, List<ExerciseAssignment>>{};
    for (final assignment in assignments) {
      assignmentsByStudent
          .putIfAbsent(assignment.studentId, () => [])
          .add(assignment);
    }

    final resultsByStudent = <String, List<ExerciseResult>>{};
    for (final result in results) {
      resultsByStudent.putIfAbsent(result.studentId, () => []).add(result);
    }

    final termsByStudent = <String, List<StudentClassTerm>>{};
    for (final term in classTerms) {
      termsByStudent.putIfAbsent(term.studentId, () => []).add(term);
    }

    final attendanceByStudent = <String, List<AttendanceRecord>>{};
    for (final record in attendance) {
      if (!record.attended) continue;
      attendanceByStudent.putIfAbsent(record.studentId, () => []).add(record);
    }

    final bestByAssignment = ExerciseUtils.bestScoresByStudentExercise(results);

    final rosters = students.map((student) {
      final studentProgress = progressByStudent[student.uid] ?? [];
      final ownerId = _lessonsOwnerId(student);
      final lessons = ProgressUtils.lessonsForStudent(
        lessonsByOwnerId[ownerId] ?? const [],
        student,
      );
      final studentAssignments = assignmentsByStudent[student.uid] ?? [];
      final studentResults = resultsByStudent[student.uid] ?? [];
      final studentTerms = termsByStudent[student.uid] ?? [];
      final studentAttendance = attendanceByStudent[student.uid] ?? [];

      final currentTerm = ProgressUtils.currentTerm(
        lessons: lessons,
        progress: studentProgress,
        termSize: student.lessonsPerTerm,
      );
      final termProgressLabel = currentTerm == null
          ? '${ProgressUtils.totalCompleted(studentProgress)}/${lessons.length} lessons'
          : '${currentTerm.completedCount}/${currentTerm.termSize} this term';

      var homeworkCompleted = 0;
      var homeworkOverdue = 0;
      for (final assignment in studentAssignments) {
        final key = '${assignment.studentId}_${assignment.exerciseId}';
        final best = bestByAssignment[key];
        if (best != null) {
          homeworkCompleted++;
        } else if (assignment.isOverdue) {
          homeworkOverdue++;
        }
      }

      final lastActive = _lastActive(
        progress: studentProgress,
        results: studentResults,
        attendance: studentAttendance,
      );

      return StudentRosterSummary(
        studentId: student.uid,
        name: student.name,
        levelLabel: ProgressUtils.formatStudentLevel(student),
        lessonsCompleted: ProgressUtils.totalCompleted(studentProgress),
        lessonsTotal: lessons.length,
        termProgressLabel: termProgressLabel,
        homeworkCompleted: homeworkCompleted,
        homeworkAssigned: studentAssignments.length,
        homeworkOverdue: homeworkOverdue,
        sessionsRemaining: _remainingSessions(studentTerms),
        avgQuizScore: ProgressUtils.averageScore(studentProgress),
        lastActivityAt: lastActive,
      );
    }).toList();

    rosters.sort((a, b) {
      final aAt = a.lastActivityAt;
      final bAt = b.lastActivityAt;
      if (aAt == null && bAt == null) {
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      if (aAt == null) return 1;
      if (bAt == null) return -1;
      return bAt.compareTo(aAt);
    });

    return rosters;
  }

  static String _lessonsOwnerId(AppUser student) {
    return AppConstants.contentOwnerFor(student);
  }

  static int? _cohortAvgQuizScore(List<StudentProgress> progress) {
    final scores = progress
        .where((item) => item.completed && item.score != null)
        .map((item) => item.score!)
        .toList();
    if (scores.isEmpty) return null;
    return (scores.reduce((a, b) => a + b) / scores.length).round();
  }

  static int? _cohortAvgPracticeScore(
    List<ExerciseAssignment> assignments,
    List<ExerciseResult> results,
  ) {
    final bestByAssignment = ExerciseUtils.bestScoresByStudentExercise(results);
    var total = 0;
    var count = 0;
    for (final assignment in assignments) {
      final key = '${assignment.studentId}_${assignment.exerciseId}';
      final score = bestByAssignment[key];
      if (score != null) {
        total += score;
        count++;
      }
    }
    if (count == 0) return null;
    return (total / count).round();
  }

  static int _totalSessionsRemaining(List<StudentClassTerm> terms) {
    return terms
        .where((term) => term.isActive && term.isWithinTermDates)
        .fold<int>(0, (total, term) => total + term.sessionsRemaining);
  }

  static int _remainingSessions(List<StudentClassTerm> terms) {
    return terms
        .where((term) => term.isActive && term.isWithinTermDates)
        .fold<int>(0, (total, term) => total + term.sessionsRemaining);
  }

  static int _classesThisWeek(List<ClassSession> sessions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    return sessions.where((session) {
      final parsed = DateTime.tryParse(session.sessionDate);
      if (parsed == null) return false;
      final day = DateTime(parsed.year, parsed.month, parsed.day);
      return !day.isBefore(weekStart) && day.isBefore(weekEnd);
    }).length;
  }

  static DateTime? _lastActive({
    required List<StudentProgress> progress,
    required List<ExerciseResult> results,
    required List<AttendanceRecord> attendance,
  }) {
    DateTime? latest;

    void bump(DateTime? at) {
      if (at == null) return;
      if (latest == null || at.isAfter(latest!)) latest = at;
    }

    for (final record in progress) {
      if (record.completed) bump(record.completedAt);
    }
    for (final result in results) {
      bump(result.submittedAt);
    }
    for (final record in attendance) {
      bump(record.joinedAt);
    }

    return latest;
  }
}
