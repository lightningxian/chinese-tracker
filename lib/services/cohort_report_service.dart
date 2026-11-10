import 'package:printing/printing.dart';

import '../core/constants/app_constants.dart';
import '../core/reports/cohort_summary_report_pdf.dart';
import '../core/utils/teacher_activity_utils.dart';
import '../core/utils/teacher_attention_utils.dart';
import '../core/utils/teacher_stats_utils.dart';
import '../models/app_user.dart';
import '../models/cohort_report_models.dart';
import '../models/lesson.dart';
import 'firestore_service.dart';

class CohortReportService {
  CohortReportService({required FirestoreService firestore})
      : _firestore = firestore;

  final FirestoreService _firestore;

  Future<CohortSummaryReportData> buildCohortSummary() async {
    final students = await _firestore.watchAllStudents().first;
    final progress = await _firestore.watchAllStudentProgress().first;
    final assignments = await _firestore.watchAllExerciseAssignments().first;
    final results = await _firestore.watchAllExerciseResults().first;
    final classTerms = await _firestore.watchAllClassTerms().first;
    final sessions = await _firestore.watchAllClassSessions().first;
    final attendance = await _firestore.watchAllAttendance().first;
    final exercises = await _firestore.watchAllExercises().first;

    final lessonsByOwnerId = await _loadLessonsByOwner(students);
    final exercisesById = {for (final e in exercises) e.id: e};

    final homeworkOverview = TeacherActivityUtils.buildHomeworkOverview(
      students: students,
      assignments: assignments,
      results: results,
      exercisesById: exercisesById,
    );

    final attentionItems = TeacherAttentionUtils.buildItems(
      students: students,
      progress: progress,
      assignments: assignments,
      exerciseResults: results,
      classTerms: classTerms,
    );

    final stats = TeacherStatsUtils.buildCohortStats(
      students: students,
      progress: progress,
      assignments: assignments,
      results: results,
      classTerms: classTerms,
      sessions: sessions,
      homeworkOverview: homeworkOverview,
      attentionItems: attentionItems,
    );

    final rosters = TeacherStatsUtils.buildStudentRosters(
      students: students,
      progress: progress,
      assignments: assignments,
      results: results,
      classTerms: classTerms,
      attendance: attendance,
      lessonsByOwnerId: lessonsByOwnerId,
    );

    return CohortSummaryReportData(
      generatedAt: DateTime.now(),
      stats: stats,
      students: rosters,
    );
  }

  Future<void> previewCohortSummary() async {
    final data = await buildCohortSummary();
    final doc = await CohortSummaryReportPdf.build(data);
    await Printing.layoutPdf(
      onLayout: (_) async => doc.save(),
      name: _fileName(),
    );
  }

  String buildCohortCsv(CohortSummaryReportData data) {
    final lines = <String>[
      [
        'Name',
        'Level',
        'Term progress',
        'Lessons completed',
        'Lessons total',
        'Homework completed',
        'Homework assigned',
        'Overdue',
        'Avg quiz score',
        'Sessions remaining',
        'Last active',
      ].map(_csvCell).join(','),
    ];

    for (final student in data.students) {
      lines.add(
        [
          student.name,
          student.levelLabel,
          student.termProgressLabel,
          '${student.lessonsCompleted}',
          '${student.lessonsTotal}',
          '${student.homeworkCompleted}',
          '${student.homeworkAssigned}',
          '${student.homeworkOverdue}',
          student.avgQuizScore?.toString() ?? '',
          '${student.sessionsRemaining}',
          student.lastActivityLabel,
        ].map(_csvCell).join(','),
      );
    }

    return '${lines.join('\n')}\n';
  }

  Future<Map<String, List<Lesson>>> _loadLessonsByOwner(
    List<AppUser> students,
  ) async {
    final ownerIds = <String>{};
    for (final student in students) {
      final ownerId = AppConstants.contentOwnerFor(student);
      if (ownerId.isNotEmpty) ownerIds.add(ownerId);
    }
    // No CONTENT_OWNER_ID fallback — per-teacher model only.

    final lessonsByOwnerId = <String, List<Lesson>>{};
    for (final ownerId in ownerIds) {
      lessonsByOwnerId[ownerId] = await _firestore.watchLessons(ownerId).first;
    }
    return lessonsByOwnerId;
  }

  String _csvCell(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  String _fileName() {
    final date = DateTime.now().toIso8601String().substring(0, 10);
    return 'centre_summary_$date.pdf';
  }
}
