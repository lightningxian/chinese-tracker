enum TeacherActivityType {
  exerciseSubmitted,
  lessonCompleted,
  homeworkAssigned,
  sessionJoined,
  sessionAdded,
  classConcluded,
  termCreated,
}

enum TeacherActivityFilter { all, practice, lessons, classes }

class TeacherActivityEvent {
  const TeacherActivityEvent({
    required this.type,
    required this.occurredAt,
    required this.title,
    this.studentId,
    this.studentName,
    this.subtitle,
  });

  final TeacherActivityType type;
  final DateTime occurredAt;
  final String title;
  final String? studentId;
  final String? studentName;
  final String? subtitle;

  String? get studentRoute =>
      studentId != null ? '/teacher/student/$studentId' : null;
}

class HomeworkOverviewRow {
  const HomeworkOverviewRow({
    required this.studentId,
    required this.studentName,
    required this.exerciseId,
    required this.exerciseTitle,
    required this.isOverdue,
    this.bestScore,
    this.dueDate,
  });

  final String studentId;
  final String studentName;
  final String exerciseId;
  final String exerciseTitle;
  final int? bestScore;
  final bool isOverdue;
  final DateTime? dueDate;

  bool get isDone => bestScore != null;
}

class HomeworkOverview {
  const HomeworkOverview({
    required this.totalAssigned,
    required this.completed,
    required this.overdue,
    required this.pending,
    required this.rows,
  });

  final int totalAssigned;
  final int completed;
  final int overdue;
  final int pending;
  final List<HomeworkOverviewRow> rows;
}

class WeeklyActivityDay {
  const WeeklyActivityDay({
    required this.day,
    required this.count,
  });

  final DateTime day;
  final int count;
}
