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

  group('ExerciseUtils.streakDays and scoreStars', () {
    test('counts days in a row ending today or yesterday', () {
      final now = DateTime(2026, 11, 11, 15);
      final chain = [
        _result('a', 80, DateTime(2026, 11, 11, 9)),
        _result('b', 80, DateTime(2026, 11, 10, 20)),
        _result('c', 80, DateTime(2026, 11, 9, 8)),
        _result('d', 80, DateTime(2026, 11, 7)),
      ];
      expect(ExerciseUtils.streakDays(chain, now: now), 3);
      // Nothing today yet: yesterday still counts.
      expect(ExerciseUtils.streakDays(chain.skip(1), now: now), 2);
      // Last attempt two days ago: chain broken.
      expect(ExerciseUtils.streakDays(chain.skip(2), now: now), 0);
      expect(ExerciseUtils.streakDays(const [], now: now), 0);
    });

    test('stars by score', () {
      expect(ExerciseUtils.scoreStars(100), 3);
      expect(ExerciseUtils.scoreStars(90), 3);
      expect(ExerciseUtils.scoreStars(75), 2);
      expect(ExerciseUtils.scoreStars(10), 1);
      expect(ExerciseUtils.scoreStars(0), 0);
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
