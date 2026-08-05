import 'package:intl/intl.dart';

class ReportExerciseLine {
  const ReportExerciseLine({
    required this.title,
    required this.status,
    this.bestScore,
    this.attempts,
    this.dueDate,
  });

  final String title;
  final String status;
  final int? bestScore;
  final int? attempts;
  final DateTime? dueDate;
}

class ReportTermLine {
  const ReportTermLine({
    required this.label,
    required this.completed,
    required this.total,
  });

  final String label;
  final int completed;
  final int total;
}

class StudentProgressReportData {
  const StudentProgressReportData({
    required this.studentName,
    required this.email,
    required this.levelLabel,
    required this.generatedAt,
    required this.lessonsCompleted,
    required this.lessonsTotal,
    required this.averageQuizScore,
    required this.exercisesAssigned,
    required this.exercisesCompleted,
    required this.exercisesOverdue,
    required this.classSessionsRemaining,
    required this.classSessionsUsed,
    required this.lastActivityAt,
    required this.terms,
    required this.exercises,
  });

  final String studentName;
  final String email;
  final String levelLabel;
  final DateTime generatedAt;
  final int lessonsCompleted;
  final int lessonsTotal;
  final int? averageQuizScore;
  final int exercisesAssigned;
  final int exercisesCompleted;
  final int exercisesOverdue;
  final int classSessionsRemaining;
  final int classSessionsUsed;
  final DateTime? lastActivityAt;
  final List<ReportTermLine> terms;
  final List<ReportExerciseLine> exercises;

  String get generatedAtLabel =>
      DateFormat('d MMM yyyy, HH:mm').format(generatedAt);

  String get lastActivityLabel {
    if (lastActivityAt == null) return 'No activity recorded';
    return DateFormat('d MMM yyyy').format(lastActivityAt!);
  }
}
