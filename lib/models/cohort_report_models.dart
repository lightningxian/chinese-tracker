import 'package:intl/intl.dart';

class CohortStats {
  const CohortStats({
    required this.totalStudents,
    required this.activeThisWeek,
    required this.homeworkCompletionPercent,
    required this.overdueAssignments,
    required this.totalSessionsRemaining,
    required this.classesThisWeek,
    required this.studentsNeedingAttention,
    this.avgQuizScore,
    this.avgPracticeScore,
  });

  final int totalStudents;
  final int activeThisWeek;
  final int homeworkCompletionPercent;
  final int overdueAssignments;
  final int? avgQuizScore;
  final int? avgPracticeScore;
  final int totalSessionsRemaining;
  final int classesThisWeek;
  final int studentsNeedingAttention;
}

class StudentRosterSummary {
  const StudentRosterSummary({
    required this.studentId,
    required this.name,
    required this.levelLabel,
    required this.lessonsCompleted,
    required this.lessonsTotal,
    required this.termProgressLabel,
    required this.homeworkCompleted,
    required this.homeworkAssigned,
    required this.homeworkOverdue,
    required this.sessionsRemaining,
    this.avgQuizScore,
    this.lastActivityAt,
  });

  final String studentId;
  final String name;
  final String levelLabel;
  final int lessonsCompleted;
  final int lessonsTotal;
  final String termProgressLabel;
  final int homeworkCompleted;
  final int homeworkAssigned;
  final int homeworkOverdue;
  final int sessionsRemaining;
  final int? avgQuizScore;
  final DateTime? lastActivityAt;

  String get lastActivityLabel {
    if (lastActivityAt == null) return 'No activity';
    final now = DateTime.now();
    final diff = now.difference(lastActivityAt!);
    if (diff.inDays < 1) return 'Today';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM').format(lastActivityAt!);
  }

  String get homeworkLabel {
    if (homeworkAssigned == 0) return 'No homework';
    if (homeworkOverdue > 0) {
      return '$homeworkCompleted/$homeworkAssigned · $homeworkOverdue overdue';
    }
    return '$homeworkCompleted/$homeworkAssigned done';
  }
}

class CohortSummaryReportData {
  const CohortSummaryReportData({
    required this.generatedAt,
    required this.stats,
    required this.students,
  });

  final DateTime generatedAt;
  final CohortStats stats;
  final List<StudentRosterSummary> students;

  String get generatedAtLabel =>
      DateFormat('d MMM yyyy, HH:mm').format(generatedAt);
}
