import '../core/constants/app_constants.dart';
import '../core/utils/progress_utils.dart';
import '../core/utils/teacher_attention_utils.dart';
import '../l10n/generated/app_localizations.dart';
import 'app_user.dart';
import 'cohort_report_models.dart';
import 'lesson.dart';
import 'student_progress.dart';

int? _int(Object? v) => v is num ? v.round() : null;
DateTime? _ms(Object? v) =>
    v is num ? DateTime.fromMillisecondsSinceEpoch(v.toInt()) : null;

/// Build 9 part 2: one row of the teacher's Students list and of the
/// dashboard drill-downs, read from the `roster` block of
/// `progress_summary/{uid}` (functions/progress.js `rosterOf`) instead of
/// six whole collections. [hasRoster] is false until the summary has been
/// rebuilt once after the deploy (Org settings → Rebuild progress
/// summaries); the row then shows dashes.
class RosterRow {
  const RosterRow({
    required this.student,
    required this.hasRoster,
    this.homeworkAssigned = 0,
    this.homeworkCompleted = 0,
    this.homeworkOverdue = 0,
    this.practiceAvg,
    this.practiceCount = 0,
    this.sessionsRemaining = 0,
    this.lessonsCompleted = 0,
    this.lessonAvg,
    this.lessons = const [],
    this.lastActiveAt,
    this.attention = const [],
  });

  final AppUser student;
  final bool hasRoster;
  final int homeworkAssigned;
  final int homeworkCompleted;
  final int homeworkOverdue;
  final int? practiceAvg;
  final int practiceCount;
  final int sessionsRemaining;
  final int lessonsCompleted;
  final int? lessonAvg;
  final List<StudentProgress> lessons;
  final DateTime? lastActiveAt;
  final List<AttentionItem> attention;

  String get studentId => student.uid;

  /// [student] is the account when the page was read from `users`; null
  /// rebuilds a minimal one from the summary's copy of the profile.
  factory RosterRow.fromSummary(String uid, Map<String, dynamic>? m,
      {AppUser? student}) {
    final data = m ?? const <String, dynamic>{};
    final r = data['roster'] is Map
        ? Map<String, dynamic>.from(data['roster'] as Map)
        : null;
    final user = student ??
        AppUser(
          uid: uid,
          email: '',
          name: data['studentName'] as String? ?? '',
          role: AppConstants.roleStudent,
          nameChinese: data['studentNameChinese'] as String?,
          teacherId: data['teacherId'] as String?,
          level: r?['rawLevel'] as String?,
          termSize: _int(r?['lessonsPerTerm']),
        );
    if (r == null) return RosterRow(student: user, hasRoster: false);
    return RosterRow(
      student: user,
      hasRoster: true,
      homeworkAssigned: _int(r['homeworkAssigned']) ?? 0,
      homeworkCompleted: _int(r['homeworkCompleted']) ?? 0,
      homeworkOverdue: _int(r['homeworkOverdue']) ?? 0,
      practiceAvg: _int(r['practiceAvg']),
      practiceCount: _int(r['practiceCount']) ?? 0,
      sessionsRemaining: _int(r['sessionsRemaining']) ?? 0,
      lessonsCompleted: _int(r['lessonsCompleted']) ?? 0,
      lessonAvg: _int(r['lessonAvg']),
      lessons: [
        for (final x in (r['lessons'] as List? ?? const []))
          if (x is Map)
            StudentProgress(
              id: '${uid}_${x['lessonId']}',
              studentId: uid,
              lessonId: '${x['lessonId'] ?? ''}',
              completed: x['completed'] == true,
              score: _int(x['score']),
              completedAt: _ms(x['completedAtMs']),
            ),
      ],
      lastActiveAt: _ms(r['lastActiveMs']),
      attention: [
        for (final x in (r['attention'] as List? ?? const []))
          if (x is Map)
            AttentionItem(
              student: user,
              reason: AttentionReason.values.firstWhere(
                  (a) => a.name == x['reason'],
                  orElse: () => AttentionReason.lowSessions),
              count: _int(x['count']),
              message: '',
            ),
      ],
    );
  }

  /// The Students table row. [lessonsByOwnerId] is the viewer's lesson
  /// library (small), used for the "This term" column as before.
  StudentRosterSummary toSummary({
    AppLocalizations? l,
    Map<String, List<Lesson>> lessonsByOwnerId = const {},
  }) {
    final ownerLessons =
        lessonsByOwnerId[AppConstants.contentOwnerFor(student)] ?? const [];
    final lessonList = ProgressUtils.lessonsForStudent(ownerLessons, student);
    final term = ProgressUtils.currentTerm(
      lessons: lessonList,
      progress: lessons,
      termSize: student.lessonsPerTerm,
    );
    return StudentRosterSummary(
      studentId: student.uid,
      name: student.name,
      staffLabel: student.staffLabel,
      levelLabel: l == null
          ? ProgressUtils.formatStudentLevel(student)
          : ProgressUtils.formatStudentLevelLocalized(l, student),
      lessonsCompleted: lessonsCompleted,
      lessonsTotal: lessonList.length,
      termProgressLabel: term == null
          ? '$lessonsCompleted/${lessonList.length} lessons'
          : '${term.completedCount}/${term.termSize} this term',
      homeworkCompleted: homeworkCompleted,
      homeworkAssigned: homeworkAssigned,
      homeworkOverdue: homeworkOverdue,
      sessionsRemaining: sessionsRemaining,
      avgQuizScore: lessonAvg,
      lastActivityAt: lastActiveAt,
    );
  }
}
