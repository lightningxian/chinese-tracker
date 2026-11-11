import 'package:chinese_tracker/core/utils/exercise_utils.dart';
import 'package:chinese_tracker/models/exercise_result.dart';
import 'package:flutter_test/flutter_test.dart';

ExerciseResult _result(String id, int score, DateTime? at) => ExerciseResult(
      id: id,
      studentId: 's1',
      exerciseId: 'ex',
      score: score,
      submittedAt: at,
    );

void main() {
  group('ExerciseUtils.formatClock', () {
    test('minutes and seconds, hours when needed, dash for null', () {
      expect(ExerciseUtils.formatClock(0), '00:00');
      expect(ExerciseUtils.formatClock(65), '01:05');
      expect(ExerciseUtils.formatClock(3725), '1:02:05');
      expect(ExerciseUtils.formatClock(null), '—');
      expect(ExerciseUtils.formatClock(-3), '—');
    });
  });

  group('ExerciseUtils history', () {
    final results = [
      _result('old', 40, DateTime(2026, 11, 1)),
      _result('undated', 90, null),
      _result('new', 80, DateTime(2026, 11, 10)),
    ];

    test('newest first, undated last', () {
      expect(
        ExerciseUtils.newestFirst(results).map((r) => r.id).toList(),
        ['new', 'old', 'undated'],
      );
    });

    test('stats: attempts, rounded average, best', () {
      final stats = ExerciseUtils.resultStats(results);
      expect(stats.attempts, 3);
      expect(stats.average, 70);
      expect(stats.best, 90);
      final none = ExerciseUtils.resultStats(const []);
      expect(none.attempts, 0);
      expect(none.average, isNull);
      expect(none.best, isNull);
    });
  });
}
