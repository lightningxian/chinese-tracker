import '../core/utils/teacher_attention_utils.dart';
import '../models/class_session.dart';
import '../models/grade.dart';
import '../models/teacher_dashboard_stat_kind.dart';
import 'l10n.dart';

/// Localized labels for the class / grade / dashboard enums.
///
/// The models keep their English `label` (used for sorting and storage);
/// screens call these extensions for what the user sees.
extension SessionModeLabels on SessionMode {
  String localized(AppLocalizations l) => switch (this) {
        SessionMode.offline => l.teacherSessionModeOffline,
        SessionMode.online => l.teacherSessionModeOnline,
        SessionMode.hybrid => l.teacherSessionModeHybrid,
      };
}

extension RegistrationStateLabels on RegistrationState {
  String localized(AppLocalizations l) => switch (this) {
        RegistrationState.draft => l.teacherSessionRegDraft,
        RegistrationState.open => l.teacherSessionRegOpen,
        RegistrationState.active => l.teacherSessionRegActive,
        RegistrationState.closed => l.teacherSessionRegClosed,
      };
}

extension GradeCategoryLabels on GradeCategory {
  String localized(AppLocalizations l) => switch (this) {
        GradeCategory.quiz => l.teacherGradesCategoryQuiz,
        GradeCategory.exercise => l.teacherGradesCategoryExercise,
        GradeCategory.speaking => l.teacherGradesCategorySpeaking,
        GradeCategory.writing => l.teacherGradesCategoryWriting,
        GradeCategory.exam => l.teacherGradesCategoryExam,
        GradeCategory.other => l.teacherGradesCategoryOther,
      };
}

extension GradeStatusLabels on GradeStatus {
  String localized(AppLocalizations l) => switch (this) {
        GradeStatus.pending => l.teacherGradesStatusPending,
        GradeStatus.graded => l.teacherGradesStatusGraded,
      };
}

extension TeacherDashboardStatKindLabels on TeacherDashboardStatKind {
  String localizedTitle(AppLocalizations l) => switch (this) {
        TeacherDashboardStatKind.students => l.teacherDashStatStudentsTitle,
        TeacherDashboardStatKind.activeThisWeek => l.teacherDashActiveThisWeek,
        TeacherDashboardStatKind.homeworkDone =>
          l.teacherDashStatHomeworkDoneTitle,
        TeacherDashboardStatKind.overdue => l.teacherDashStatOverdueTitle,
        TeacherDashboardStatKind.avgQuiz => l.teacherDashStatAvgQuizTitle,
        TeacherDashboardStatKind.avgPractice =>
          l.teacherDashStatAvgPracticeTitle,
        TeacherDashboardStatKind.sessionsLeft =>
          l.teacherDashStatSessionsLeftTitle,
        TeacherDashboardStatKind.classesThisWeek =>
          l.teacherDashStatClassesThisWeekTitle,
        TeacherDashboardStatKind.needAttention =>
          l.teacherDashStatNeedAttentionTitle,
        TeacherDashboardStatKind.weeklyActivity =>
          l.teacherDashStatWeeklyActivityTitle,
        TeacherDashboardStatKind.homeworkOverview =>
          l.teacherDashStatHomeworkOverviewTitle,
      };

  String localizedDescription(AppLocalizations l) => switch (this) {
        TeacherDashboardStatKind.students =>
          l.teacherDashStatStudentsDescription,
        TeacherDashboardStatKind.activeThisWeek =>
          l.teacherDashStatActiveThisWeekDescription,
        TeacherDashboardStatKind.homeworkDone =>
          l.teacherDashStatHomeworkDoneDescription,
        TeacherDashboardStatKind.overdue => l.teacherDashStatOverdueDescription,
        TeacherDashboardStatKind.avgQuiz => l.teacherDashStatAvgQuizDescription,
        TeacherDashboardStatKind.avgPractice =>
          l.teacherDashStatAvgPracticeDescription,
        TeacherDashboardStatKind.sessionsLeft =>
          l.teacherDashStatSessionsLeftDescription,
        TeacherDashboardStatKind.classesThisWeek =>
          l.teacherDashStatClassesThisWeekDescription,
        TeacherDashboardStatKind.needAttention =>
          l.teacherDashStatNeedAttentionDescription,
        TeacherDashboardStatKind.weeklyActivity =>
          l.teacherDashStatWeeklyActivityDescription,
        TeacherDashboardStatKind.homeworkOverview =>
          l.teacherDashStatHomeworkOverviewDescription,
      };
}

extension AttentionItemLabels on AttentionItem {
  /// Localized version of [AttentionItem.message].
  String localizedMessage(AppLocalizations l) {
    final name = student.name;
    return switch (reason) {
      AttentionReason.overdueExercise => l.attentionOverdue(name),
      AttentionReason.staleAssignment => l.attentionStale(name, count ?? 0),
      AttentionReason.inactiveStudent => l.attentionInactive(name, count ?? 0),
      AttentionReason.lowSessions => (count ?? 0) == 0
          ? l.attentionNoSessions(name)
          : l.attentionSessionsLeft(name, count ?? 0),
    };
  }
}
