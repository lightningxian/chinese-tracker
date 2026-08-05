enum TeacherDashboardStatKind {
  students('students'),
  activeThisWeek('active-this-week'),
  homeworkDone('homework-done'),
  overdue('overdue'),
  avgQuiz('avg-quiz'),
  avgPractice('avg-practice'),
  sessionsLeft('sessions-left'),
  classesThisWeek('classes-this-week'),
  needAttention('need-attention'),
  weeklyActivity('weekly-activity'),
  homeworkOverview('homework-overview');

  const TeacherDashboardStatKind(this.routeSlug);

  final String routeSlug;

  static TeacherDashboardStatKind? fromRouteSlug(String slug) {
    for (final kind in values) {
      if (kind.routeSlug == slug) return kind;
    }
    return null;
  }

  String get title => switch (this) {
        students => 'All students',
        activeThisWeek => 'Active this week',
        homeworkDone => 'Homework completed',
        overdue => 'Overdue practice',
        avgQuiz => 'Quiz averages',
        avgPractice => 'Practice averages',
        sessionsLeft => 'Class sessions remaining',
        classesThisWeek => 'Classes this week',
        needAttention => 'Students needing attention',
        weeklyActivity => 'Weekly activity',
        homeworkOverview => 'Homework overview',
      };

  String get description => switch (this) {
        students => 'Every registered murid with progress, homework, and session balance.',
        activeThisWeek =>
          'Murid who completed a lesson or submitted practice in the last 7 days.',
        homeworkDone => 'Assigned practice that murid have finished.',
        overdue => 'Assigned practice past the due date and not yet completed.',
        avgQuiz => 'Average quiz score per murid across completed lessons.',
        avgPractice => 'Best practice score per murid across assigned exercises.',
        sessionsLeft =>
          'Remaining live-class sessions on active voucher packages.',
        classesThisWeek => 'Scheduled class sessions in the current calendar week.',
        needAttention =>
          'Overdue homework, stale assignments, inactive murid, and low session balance.',
        weeklyActivity =>
          'Lesson completions and practice submissions day by day.',
        homeworkOverview =>
          'Every assigned exercise with status, due date, and best score.',
      };
}
