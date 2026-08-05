/// Helpers for turning a 0–100 [score] into a display letter grade.
///
/// Shared across the teacher gradebook and the student/parent transcript so a
/// grade always renders the same letter everywhere.
abstract final class GradeUtils {
  /// Maps a numeric [score] (0..100) to a letter grade.
  static String letterGradeFor(num score) {
    final s = score.clamp(0, 100);
    if (s >= 90) return 'A';
    if (s >= 85) return 'B+';
    if (s >= 80) return 'B';
    if (s >= 75) return 'C+';
    if (s >= 70) return 'C';
    if (s >= 60) return 'D';
    return 'E';
  }
}
