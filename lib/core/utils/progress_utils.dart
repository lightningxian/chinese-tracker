import '../../l10n/generated/app_localizations.dart';
import '../../models/app_user.dart';
import '../../models/exercise.dart';
import '../../models/lesson.dart';
import '../../models/student_progress.dart';

class EnrichedProgress {
  const EnrichedProgress({
    required this.progress,
    this.lesson,
  });

  final StudentProgress progress;
  final Lesson? lesson;

  String get lessonTitle => lesson?.title ?? 'Unknown lesson';
  int get termNumber => lesson?.termNumber ?? 1;
  String get termLabel => 'Term $termNumber';
  int? get score => progress.score;
  bool get completed => progress.completed;
  DateTime? get completedAt => progress.completedAt;
}

class TermProgress {
  const TermProgress({
    required this.termNumber,
    required this.completedCount,
    required this.totalInTerm,
    required this.termSize,
    required this.items,
  });

  final int termNumber;
  final int completedCount;
  final int totalInTerm;
  final int termSize;
  final List<EnrichedProgress> items;

  String get label => 'Term $termNumber';
  double get progress =>
      termSize == 0 ? 0 : (completedCount / termSize).clamp(0, 1);
  bool get isFull => completedCount >= termSize;
}

abstract final class ProgressUtils {
  static List<Exercise> exercisesForStudent(
    List<Exercise> all,
    AppUser student,
  ) {
    final filtered = all
        .where((exercise) => exercise.isPublished)
        .where(
          (exercise) =>
              exercise.level == null ||
              exercise.level!.isEmpty ||
              exercise.level == student.level,
        )
        .toList();
    filtered.sort(_compareExercises);
    return filtered;
  }

  static int _compareExercises(Exercise a, Exercise b) {
    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  }

  static List<Lesson> lessonsForStudent(List<Lesson> all, AppUser student) {
    final filtered = all
        .where(
          (lesson) =>
              lesson.level == null ||
              lesson.level!.isEmpty ||
              lesson.level == student.level,
        )
        .toList();
    filtered.sort(_compareLessons);
    return filtered;
  }

  static int compareLessons(Lesson a, Lesson b) => _compareLessons(a, b);

  static int _compareLessons(Lesson a, Lesson b) {
    final termCompare = a.termNumber.compareTo(b.termNumber);
    if (termCompare != 0) return termCompare;
    return a.order.compareTo(b.order);
  }

  static Map<String, StudentProgress> progressByLessonId(
    List<StudentProgress> progress,
  ) {
    return {for (final item in progress) item.lessonId: item};
  }

  static List<EnrichedProgress> enrichProgress({
    required List<StudentProgress> progress,
    required List<Lesson> lessons,
  }) {
    final lessonById = {for (final lesson in lessons) lesson.id: lesson};
    final enriched = progress
        .map(
          (item) => EnrichedProgress(
            progress: item,
            lesson: lessonById[item.lessonId],
          ),
        )
        .toList();
    enriched.sort((a, b) {
      if (a.completed != b.completed) {
        return a.completed ? -1 : 1;
      }
      final termCompare = a.termNumber.compareTo(b.termNumber);
      if (termCompare != 0) return termCompare;
      final orderA = a.lesson?.order ?? 0;
      final orderB = b.lesson?.order ?? 0;
      return orderA.compareTo(orderB);
    });
    return enriched;
  }

  static Map<int, List<Lesson>> groupLessonsByTerm(List<Lesson> lessons) {
    final grouped = <int, List<Lesson>>{};
    for (final lesson in lessons) {
      grouped.putIfAbsent(lesson.termNumber, () => []).add(lesson);
    }
    for (final entry in grouped.entries) {
      entry.value.sort((a, b) => a.order.compareTo(b.order));
    }
    return grouped;
  }

  static List<TermProgress> buildTermProgress({
    required List<Lesson> lessons,
    required List<StudentProgress> progress,
    required int termSize,
  }) {
    final progressByLesson = progressByLessonId(progress);
    final grouped = groupLessonsByTerm(lessons);

    return grouped.entries.map((entry) {
      final termLessons = entry.value;
      final items = termLessons.map((lesson) {
        final record = progressByLesson[lesson.id];
        return EnrichedProgress(
          progress: record ??
              StudentProgress(
                id: '',
                studentId: '',
                lessonId: lesson.id,
                completed: false,
              ),
          lesson: lesson,
        );
      }).toList();

      final completedCount = items.where((item) => item.completed).length;

      return TermProgress(
        termNumber: entry.key,
        completedCount: completedCount,
        totalInTerm: termLessons.length,
        termSize: termSize,
        items: items,
      );
    }).toList()
      ..sort((a, b) => a.termNumber.compareTo(b.termNumber));
  }

  static TermProgress? currentTerm({
    required List<Lesson> lessons,
    required List<StudentProgress> progress,
    required int termSize,
  }) {
    final terms = buildTermProgress(
      lessons: lessons,
      progress: progress,
      termSize: termSize,
    );
    if (terms.isEmpty) return null;

    for (final term in terms) {
      if (!term.isFull) return term;
    }
    return terms.last;
  }

  static int totalCompleted(List<StudentProgress> progress) =>
      progress.where((item) => item.completed).length;

  static int? averageScore(List<StudentProgress> progress) {
    final scores = progress
        .where((item) => item.score != null)
        .map((item) => item.score!)
        .toList();
    if (scores.isEmpty) return null;
    return (scores.reduce((a, b) => a + b) / scores.length).round();
  }

  /// English, for reports and CSV. Screens use [formatStudentLevelLocalized].
  static String formatStudentLevel(AppUser student) {
    final level = student.level ?? 'No HSK level';
    return '$level · ${student.lessonsPerTerm} lessons/term';
  }

  /// "HSK 1 · 8 pelajaran/periode" in the app language.
  static String formatStudentLevelLocalized(
      AppLocalizations l, AppUser student) {
    final level = student.level ?? l.commonNoHskLevel;
    return '$level · ${l.studentDetailLessonsPerTerm(student.lessonsPerTerm)}';
  }
}
