import '../../models/app_user.dart';
import '../../models/attendance_record.dart';
import '../../models/class_session.dart';
import '../../models/exercise.dart';
import '../../models/exercise_assignment.dart';
import '../../models/exercise_result.dart';
import '../../models/lesson.dart';
import '../../models/student_class_term.dart';
import '../../models/student_progress.dart';
import '../../models/teacher_activity_event.dart';
import 'exercise_utils.dart';

abstract final class TeacherActivityUtils {
  static const _feedLimit = 25;

  static List<TeacherActivityEvent> buildFeed({
    required List<AppUser> students,
    required List<StudentProgress> progress,
    required List<ExerciseAssignment> assignments,
    required List<ExerciseResult> exerciseResults,
    required List<AttendanceRecord> attendance,
    required List<ClassSession> sessions,
    required List<StudentClassTerm> classTerms,
    required Map<String, Exercise> exercisesById,
    required Map<String, Lesson> lessonsById,
    TeacherActivityFilter filter = TeacherActivityFilter.all,
    int limit = _feedLimit,
  }) {
    final studentsById = {for (final s in students) s.uid: s};
    final events = <TeacherActivityEvent>[];

    for (final result in exerciseResults) {
      final at = result.submittedAt;
      if (at == null) continue;
      final student = studentsById[result.studentId];
      final exercise = exercisesById[result.exerciseId];
      events.add(
        TeacherActivityEvent(
          type: TeacherActivityType.exerciseSubmitted,
          occurredAt: at,
          studentId: result.studentId,
          studentName: student?.name,
          title: student != null
              ? '${student.name} scored ${result.score}%'
              : 'Practice submitted · ${result.score}%',
          subtitle: exercise?.title ?? 'Exercise',
        ),
      );
    }

    for (final record in progress) {
      if (!record.completed) continue;
      final at = record.completedAt;
      if (at == null) continue;
      final student = studentsById[record.studentId];
      final lesson = lessonsById[record.lessonId];
      events.add(
        TeacherActivityEvent(
          type: TeacherActivityType.lessonCompleted,
          occurredAt: at,
          studentId: record.studentId,
          studentName: student?.name,
          title: student != null
              ? '${student.name} completed a lesson'
              : 'Lesson completed',
          subtitle: lesson != null
              ? '${lesson.termLabel} · ${lesson.title}'
              : 'Lesson ${record.lessonId}',
        ),
      );
    }

    for (final assignment in assignments) {
      final at = assignment.assignedAt;
      if (at == null) continue;
      final student = studentsById[assignment.studentId];
      final exercise = exercisesById[assignment.exerciseId];
      events.add(
        TeacherActivityEvent(
          type: TeacherActivityType.homeworkAssigned,
          occurredAt: at,
          studentId: assignment.studentId,
          studentName: student?.name,
          title: student != null
              ? 'Assigned practice to ${student.name}'
              : 'Practice assigned',
          subtitle: exercise?.title ?? 'Exercise',
        ),
      );
    }

    for (final record in attendance) {
      final at = record.joinedAt;
      if (at == null || !record.attended) continue;
      final student = studentsById[record.studentId];
      final name = student?.name ?? record.studentName ?? 'Student';
      events.add(
        TeacherActivityEvent(
          type: record.joinedByStudent
              ? TeacherActivityType.sessionJoined
              : TeacherActivityType.sessionAdded,
          occurredAt: at,
          studentId: record.studentId,
          studentName: name,
          title: record.joinedByStudent
              ? '$name joined a class'
              : 'You added $name to a class',
          subtitle: record.sessionTitle.isNotEmpty
              ? '${record.sessionDate} · ${record.sessionTitle}'
              : record.sessionDate,
        ),
      );
    }

    for (final session in sessions) {
      if (!session.isConcluded) continue;
      final at = session.concludedAt;
      if (at == null) continue;
      events.add(
        TeacherActivityEvent(
          type: TeacherActivityType.classConcluded,
          occurredAt: at,
          title: 'Class concluded',
          subtitle: session.sessionTitle.isNotEmpty
              ? '${session.sessionDate} · ${session.sessionTitle}'
              : session.sessionDate,
        ),
      );
    }

    for (final term in classTerms) {
      final at = term.createdAt ?? term.purchasedAt;
      if (at == null) continue;
      final student = studentsById[term.studentId];
      events.add(
        TeacherActivityEvent(
          type: TeacherActivityType.termCreated,
          occurredAt: at,
          studentId: term.studentId,
          studentName: student?.name,
          title: student != null
              ? 'Term package added for ${student.name}'
              : 'Term package added',
          subtitle:
              '${term.packageSize} sessions · ${term.startDate} → ${term.deadlineDate}',
        ),
      );
    }

    events.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    final filtered = events.where((event) {
      return switch (filter) {
        TeacherActivityFilter.all => true,
        TeacherActivityFilter.practice =>
          event.type == TeacherActivityType.exerciseSubmitted ||
              event.type == TeacherActivityType.homeworkAssigned,
        TeacherActivityFilter.lessons =>
          event.type == TeacherActivityType.lessonCompleted,
        TeacherActivityFilter.classes =>
          event.type == TeacherActivityType.sessionJoined ||
              event.type == TeacherActivityType.sessionAdded ||
              event.type == TeacherActivityType.classConcluded ||
              event.type == TeacherActivityType.termCreated,
      };
    }).toList();

    return filtered.take(limit).toList();
  }

  static HomeworkOverview buildHomeworkOverview({
    required List<AppUser> students,
    required List<ExerciseAssignment> assignments,
    required List<ExerciseResult> results,
    required Map<String, Exercise> exercisesById,
  }) {
    final studentsById = {for (final s in students) s.uid: s};
    final bestScores = ExerciseUtils.bestScoresByStudentExercise(results);
    final rows = <HomeworkOverviewRow>[];

    for (final assignment in assignments) {
      final exercise = exercisesById[assignment.exerciseId];
      if (exercise == null || !exercise.isPublished) continue;
      final student = studentsById[assignment.studentId];
      final key = '${assignment.studentId}_${assignment.exerciseId}';
      final best = bestScores[key];
      final overdue = assignment.isOverdue && best == null;
      rows.add(
        HomeworkOverviewRow(
          studentId: assignment.studentId,
          studentName: student?.name ?? 'Unknown student',
          exerciseId: assignment.exerciseId,
          exerciseTitle: exercise.title,
          bestScore: best,
          isOverdue: overdue,
          dueDate: assignment.dueDate,
        ),
      );
    }

    rows.sort((a, b) {
      if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
      if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
      final aDue = a.dueDate;
      final bDue = b.dueDate;
      if (aDue != null && bDue != null) return aDue.compareTo(bDue);
      if (aDue != null) return -1;
      if (bDue != null) return 1;
      return a.studentName
          .toLowerCase()
          .compareTo(b.studentName.toLowerCase());
    });

    final completed = rows.where((r) => r.isDone).length;
    final overdue = rows.where((r) => r.isOverdue).length;
    final pending = rows.length - completed - overdue;

    return HomeworkOverview(
      totalAssigned: rows.length,
      completed: completed,
      overdue: overdue,
      pending: pending,
      rows: rows,
    );
  }

  static List<WeeklyActivityDay> buildWeeklyActivity({
    required List<StudentProgress> progress,
    required List<ExerciseResult> results,
    int days = 7,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final counts = <DateTime, int>{};

    for (var i = days - 1; i >= 0; i--) {
      counts[today.subtract(Duration(days: i))] = 0;
    }

    void bump(DateTime? at) {
      if (at == null) return;
      final day = DateTime(at.year, at.month, at.day);
      if (counts.containsKey(day)) {
        counts[day] = counts[day]! + 1;
      }
    }

    for (final record in progress) {
      if (record.completed) bump(record.completedAt);
    }
    for (final result in results) {
      bump(result.submittedAt);
    }

    return counts.entries
        .map((e) => WeeklyActivityDay(day: e.key, count: e.value))
        .toList();
  }

  static int countActiveThisWeek({
    required List<AppUser> students,
    required List<StudentProgress> progress,
    required List<ExerciseResult> results,
  }) {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final activeIds = <String>{};

    for (final record in progress) {
      if (!record.completed) continue;
      final at = record.completedAt;
      if (at != null && at.isAfter(cutoff)) {
        activeIds.add(record.studentId);
      }
    }
    for (final result in results) {
      final at = result.submittedAt;
      if (at != null && at.isAfter(cutoff)) {
        activeIds.add(result.studentId);
      }
    }

    return students.where((s) => activeIds.contains(s.uid)).length;
  }

  static List<AppUser> sortStudentsByLastActivity({
    required List<AppUser> students,
    required List<StudentProgress> progress,
    required List<ExerciseResult> results,
    required List<AttendanceRecord> attendance,
  }) {
    final lastByStudent = <String, DateTime>{};

    void bump(String studentId, DateTime? at) {
      if (at == null) return;
      final current = lastByStudent[studentId];
      if (current == null || at.isAfter(current)) {
        lastByStudent[studentId] = at;
      }
    }

    for (final record in progress) {
      if (record.completed) bump(record.studentId, record.completedAt);
    }
    for (final result in results) {
      bump(result.studentId, result.submittedAt);
    }
    for (final record in attendance) {
      if (record.attended) bump(record.studentId, record.joinedAt);
    }

    final sorted = [...students];
    sorted.sort((a, b) {
      final aAt = lastByStudent[a.uid];
      final bAt = lastByStudent[b.uid];
      if (aAt == null && bAt == null) {
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      if (aAt == null) return 1;
      if (bAt == null) return -1;
      return bAt.compareTo(aAt);
    });
    return sorted;
  }
}
