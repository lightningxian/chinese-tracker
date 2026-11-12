import '../../models/app_user.dart';
import '../../models/exercise_assignment.dart';
import '../../models/exercise_result.dart';
import '../../models/student_class_term.dart';
import '../../models/student_progress.dart';
import 'exercise_utils.dart';

enum AttentionReason {
  overdueExercise,
  staleAssignment,
  inactiveStudent,
  lowSessions,
}

class AttentionItem {
  const AttentionItem({
    required this.student,
    required this.message,
    required this.reason,
    this.count,
  });

  final AppUser student;

  /// English wording; screens show [localizedMessage] from
  /// `lib/l10n/labels_classes.dart` instead.
  final String message;
  final AttentionReason reason;

  /// Days (stale, inactive) or sessions left (low sessions); null otherwise.
  final int? count;
}

abstract final class TeacherAttentionUtils {
  static const _staleAssignmentDays = 3;
  static const _inactiveDays = 7;
  static const _lowSessionThreshold = 2;

  static List<AttentionItem> buildItems({
    required List<AppUser> students,
    required List<StudentProgress> progress,
    required List<ExerciseAssignment> assignments,
    required List<ExerciseResult> exerciseResults,
    required List<StudentClassTerm> classTerms,
  }) {
    final items = <AttentionItem>[];
    final now = DateTime.now();

    for (final student in students) {
      final studentAssignments = assignments
          .where((assignment) => assignment.studentId == student.uid)
          .toList();
      final studentProgress = progress
          .where(
              (record) => record.studentId == student.uid && record.completed)
          .toList();
      final studentResults = exerciseResults
          .where((result) => result.studentId == student.uid)
          .toList();
      final studentBest = ExerciseUtils.bestScores(studentResults);
      final studentTerms =
          classTerms.where((term) => term.studentId == student.uid).toList();

      for (final assignment in studentAssignments) {
        if (studentBest.containsKey(assignment.exerciseId)) continue;

        if (assignment.isOverdue) {
          items.add(
            AttentionItem(
              student: student,
              reason: AttentionReason.overdueExercise,
              message: '${student.name} has overdue practice',
            ),
          );
          continue;
        }

        final assignedAt = assignment.assignedAt;
        if (assignedAt != null &&
            now.difference(assignedAt).inDays >= _staleAssignmentDays) {
          items.add(
            AttentionItem(
              student: student,
              reason: AttentionReason.staleAssignment,
              count: now.difference(assignedAt).inDays,
              message:
                  '${student.name} has assigned practice not started (${now.difference(assignedAt).inDays}d)',
            ),
          );
        }
      }

      final lastLesson = studentProgress
          .map((record) => record.completedAt)
          .whereType<DateTime>()
          .fold<DateTime?>(
            null,
            (latest, at) => latest == null || at.isAfter(latest) ? at : latest,
          );
      final lastExercise = studentResults
          .map((result) => result.submittedAt)
          .whereType<DateTime>()
          .fold<DateTime?>(
            null,
            (latest, at) => latest == null || at.isAfter(latest) ? at : latest,
          );
      final lastActive = _latest(lastLesson, lastExercise);
      final inactiveSince = now.subtract(const Duration(days: _inactiveDays));

      final hasHistory =
          studentProgress.isNotEmpty || studentResults.isNotEmpty;
      if (hasHistory &&
          (lastActive == null || lastActive.isBefore(inactiveSince))) {
        items.add(
          AttentionItem(
            student: student,
            reason: AttentionReason.inactiveStudent,
            count: _inactiveDays,
            message: '${student.name} inactive for $_inactiveDays+ days',
          ),
        );
      }

      final remaining = _remainingSessions(studentTerms);
      if (remaining >= 0 && remaining <= _lowSessionThreshold) {
        items.add(
          AttentionItem(
            student: student,
            reason: AttentionReason.lowSessions,
            count: remaining,
            message: remaining == 0
                ? '${student.name} has no class sessions left'
                : '${student.name} has $remaining class session${remaining == 1 ? '' : 's'} left',
          ),
        );
      }
    }

    items.sort((a, b) {
      final byReason = a.reason.index.compareTo(b.reason.index);
      if (byReason != 0) return byReason;
      return a.student.name
          .toLowerCase()
          .compareTo(b.student.name.toLowerCase());
    });

    return items;
  }

  static DateTime? _latest(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }

  static int _remainingSessions(List<StudentClassTerm> terms) {
    return terms
        .where((term) => term.isActive && term.isWithinTermDates)
        .fold<int>(0, (total, term) => total + term.sessionsRemaining);
  }
}
