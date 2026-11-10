import 'package:intl/intl.dart';

import '../../models/exercise.dart';
import '../../models/exercise_result.dart';
import '../../models/student_assigned_exercise.dart';

abstract final class ExerciseUtils {
  static Map<String, int> bestScores(List<ExerciseResult> results) {
    final best = <String, int>{};
    for (final result in results) {
      final current = best[result.exerciseId];
      if (current == null || result.score > current) {
        best[result.exerciseId] = result.score;
      }
    }
    return best;
  }

  static Map<String, int> attemptCounts(List<ExerciseResult> results) {
    final counts = <String, int>{};
    for (final result in results) {
      counts[result.exerciseId] = (counts[result.exerciseId] ?? 0) + 1;
    }
    return counts;
  }

  static Map<String, ExerciseResult> latestResults(
      List<ExerciseResult> results) {
    final latest = <String, ExerciseResult>{};
    for (final result in results) {
      final existing = latest[result.exerciseId];
      final submittedAt = result.submittedAt;
      if (existing == null) {
        latest[result.exerciseId] = result;
        continue;
      }
      final existingAt = existing.submittedAt;
      if (submittedAt != null &&
          (existingAt == null || submittedAt.isAfter(existingAt))) {
        latest[result.exerciseId] = result;
      }
    }
    return latest;
  }

  static String formatDueDate(DateTime? dueDate) {
    if (dueDate == null) return '';
    return DateFormat('d MMM yyyy').format(dueDate);
  }

  static String dueDateLabel(DateTime? dueDate, {required bool isOverdue}) {
    if (dueDate == null) return '';
    if (isOverdue) return 'Overdue · ${formatDueDate(dueDate)}';
    return 'Due ${formatDueDate(dueDate)}';
  }

  static Map<String, int> bestScoresForExercise(
    String exerciseId,
    List<ExerciseResult> results,
  ) {
    final filtered = results.where((r) => r.exerciseId == exerciseId).toList();
    return bestScores(filtered);
  }

  static int compareExercises(
    Exercise a,
    Exercise b, {
    required Map<String, int> bestScores,
  }) {
    final aDone = bestScores.containsKey(a.id);
    final bDone = bestScores.containsKey(b.id);
    if (!aDone && bDone) return -1;
    if (aDone && !bDone) return 1;
    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  }

  static ({int pending, int overdue, int done}) practiceCounts(
    List<Exercise> exercises, {
    required Map<String, int> bestScores,
  }) {
    var pending = 0;
    var done = 0;
    for (final exercise in exercises) {
      if (bestScores.containsKey(exercise.id)) {
        done++;
      } else {
        pending++;
      }
    }
    return (pending: pending, overdue: 0, done: done);
  }

  static Map<String, int> bestScoresByStudentForExercise(
    String exerciseId,
    List<ExerciseResult> results,
  ) {
    final best = <String, int>{};
    for (final result in results) {
      if (result.exerciseId != exerciseId) continue;
      final current = best[result.studentId];
      if (current == null || result.score > current) {
        best[result.studentId] = result.score;
      }
    }
    return best;
  }

  static ({int pending, int overdue, int done}) homeworkCounts(
    List<StudentAssignedExercise> items, {
    required Map<String, int> bestScores,
  }) {
    var pending = 0;
    var overdue = 0;
    var done = 0;
    for (final item in items) {
      final best = bestScores[item.exercise.id];
      if (best != null) {
        done++;
      } else if (item.assignment.isOverdue) {
        overdue++;
      } else {
        pending++;
      }
    }
    return (pending: pending, overdue: overdue, done: done);
  }

  static Map<String, int> bestScoresByStudentExercise(
    List<ExerciseResult> results,
  ) {
    final best = <String, int>{};
    for (final result in results) {
      final key = '${result.studentId}_${result.exerciseId}';
      final current = best[key];
      if (current == null || result.score > current) {
        best[key] = result.score;
      }
    }
    return best;
  }

  static int compareAssigned(
    StudentAssignedExercise a,
    StudentAssignedExercise b, {
    required Map<String, int> bestScores,
  }) {
    final aDone = bestScores.containsKey(a.exercise.id);
    final bDone = bestScores.containsKey(b.exercise.id);
    if (!aDone && bDone) return -1;
    if (aDone && !bDone) return 1;

    if (!aDone && !bDone) {
      final aOverdue = a.assignment.isOverdue;
      final bOverdue = b.assignment.isOverdue;
      if (aOverdue != bOverdue) return aOverdue ? -1 : 1;

      final aDue = a.assignment.dueDate;
      final bDue = b.assignment.dueDate;
      if (aDue != null && bDue != null) {
        return aDue.compareTo(bDue);
      }
      if (aDue != null) return -1;
      if (bDue != null) return 1;
    }

    return a.exercise.title
        .toLowerCase()
        .compareTo(b.exercise.title.toLowerCase());
  }
}
