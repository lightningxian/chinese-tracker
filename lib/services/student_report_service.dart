import 'package:printing/printing.dart';

import '../core/constants/app_constants.dart';
import '../core/reports/student_progress_report_pdf.dart';
import '../core/utils/exercise_utils.dart';
import '../core/utils/progress_utils.dart';
import '../models/app_user.dart';
import '../models/exercise_result.dart';
import '../models/student_progress.dart';
import '../models/student_progress_report_data.dart';
import 'firestore_service.dart';

class StudentReportService {
  StudentReportService({required FirestoreService firestore})
      : _firestore = firestore;

  final FirestoreService _firestore;

  String _lessonsOwnerIdForStudent(AppUser student) {
    return AppConstants.contentOwnerFor(student);
  }

  Future<StudentProgressReportData> buildReportData(String studentId) async {
    final student = await _firestore.getUser(studentId);
    if (student == null) {
      throw StateError('Student not found.');
    }

    final contentOwnerId = _lessonsOwnerIdForStudent(student);
    final lessons = ProgressUtils.lessonsForStudent(
      contentOwnerId.isEmpty
          ? []
          : await _firestore.watchLessons(contentOwnerId).first,
      student,
    );

    final progress = await _firestore.watchStudentProgress(studentId).first;
    final terms = ProgressUtils.buildTermProgress(
      lessons: lessons,
      progress: progress,
      termSize: student.lessonsPerTerm,
    );

    final assignments =
        await _firestore.watchAssignmentsForStudent(studentId).first;
    final availableExercises =
        await _firestore.watchAvailableExercisesForStudent(student).first;
    final results =
        await _firestore.watchStudentExerciseResults(studentId).first;
    final classTerms = await _firestore.watchStudentClassTerms(studentId).first;

    final bestScores = ExerciseUtils.bestScores(results);
    final attemptCounts = ExerciseUtils.attemptCounts(results);
    final assignmentsByExerciseId = {
      for (final assignment in assignments) assignment.exerciseId: assignment,
    };

    final exerciseLines = <ReportExerciseLine>[];
    for (final exercise in availableExercises) {
      final assignment = assignmentsByExerciseId[exercise.id];
      final best = bestScores[exercise.id];
      final overdue = assignment?.isOverdue == true && best == null;
      exerciseLines.add(
        ReportExerciseLine(
          title: exercise.title,
          status: best != null
              ? 'Completed'
              : overdue
                  ? 'Overdue'
                  : 'Not started',
          bestScore: best,
          attempts: attemptCounts[exercise.id],
          dueDate: assignment?.dueDate,
        ),
      );
    }

    for (final assignment in assignments) {
      if (availableExercises.any((e) => e.id == assignment.exerciseId)) {
        continue;
      }
      final exercise = await _firestore.getExercise(assignment.exerciseId);
      if (exercise == null || !exercise.isPublished) continue;

      final best = bestScores[exercise.id];
      final overdue = assignment.isOverdue && best == null;
      exerciseLines.add(
        ReportExerciseLine(
          title: exercise.title,
          status: best != null
              ? 'Completed'
              : overdue
                  ? 'Overdue'
                  : 'Not started',
          bestScore: best,
          attempts: attemptCounts[exercise.id],
          dueDate: assignment.dueDate,
        ),
      );
    }

    exerciseLines.sort((a, b) {
      if (a.status == 'Overdue' && b.status != 'Overdue') return -1;
      if (b.status == 'Overdue' && a.status != 'Overdue') return 1;
      if (a.bestScore == null && b.bestScore != null) return -1;
      if (a.bestScore != null && b.bestScore == null) return 1;
      return a.title.compareTo(b.title);
    });

    final practiceCounts = ExerciseUtils.practiceCounts(
      availableExercises,
      bestScores: bestScores,
    );
    final exercisesOverdue = assignments
        .where(
          (assignment) =>
              assignment.isOverdue &&
              !bestScores.containsKey(assignment.exerciseId),
        )
        .length;

    final completedLessons = progress.where((item) => item.completed).length;

    final sessionsRemaining =
        _firestore.totalRemainingClassSessions(classTerms);
    final sessionsUsed =
        classTerms.fold<int>(0, (sum, term) => sum + term.sessionsUsed);

    return StudentProgressReportData(
      studentName: student.name,
      email: student.email,
      levelLabel: ProgressUtils.formatStudentLevel(student),
      generatedAt: DateTime.now(),
      lessonsCompleted: completedLessons,
      lessonsTotal: lessons.length,
      averageQuizScore: ProgressUtils.averageScore(progress),
      exercisesAssigned: availableExercises.isNotEmpty
          ? availableExercises.length
          : assignments.length,
      exercisesCompleted: practiceCounts.done,
      exercisesOverdue: exercisesOverdue,
      classSessionsRemaining: sessionsRemaining,
      classSessionsUsed: sessionsUsed,
      lastActivityAt: _lastActivity(progress, results),
      terms: terms
          .map(
            (term) => ReportTermLine(
              label: term.label,
              completed: term.completedCount,
              total: term.totalInTerm,
            ),
          )
          .toList(),
      exercises: exerciseLines,
    );
  }

  Future<void> previewReport(String studentId) async {
    try {
      final data = await buildReportData(studentId);
      final doc = await StudentProgressReportPdf.build(data);
      await Printing.layoutPdf(
        onLayout: (_) async => doc.save(),
        name: _fileName(data.studentName),
      );
    } on StateError {
      rethrow;
    } catch (e) {
      throw StateError('Could not export progress report: $e');
    }
  }

  DateTime? _lastActivity(
    List<StudentProgress> progress,
    List<ExerciseResult> results,
  ) {
    DateTime? latest;
    for (final item in progress) {
      final at = item.completedAt;
      if (at != null && (latest == null || at.isAfter(latest))) {
        latest = at;
      }
    }
    for (final result in results) {
      final at = result.submittedAt;
      if (at != null && (latest == null || at.isAfter(latest))) {
        latest = at;
      }
    }
    return latest;
  }

  String _fileName(String studentName) {
    final safe = studentName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return 'progress_report_${safe.isEmpty ? 'student' : safe}.pdf';
  }
}
