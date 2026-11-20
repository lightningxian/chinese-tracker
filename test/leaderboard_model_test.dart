import 'package:chinese_tracker/models/leaderboard.dart';
import 'package:flutter_test/flutter_test.dart';

// Build 2B: the app ranks a board the same way functions/promotion.js does
// (LB-01), and names the level groups of the spec.
LeaderboardEntry _e(String id, int total, int? seconds, int minute) => LeaderboardEntry(
      studentId: id,
      name: id,
      parts: const [],
      total: total,
      max: 300,
      passed: total >= 180,
      seconds: seconds,
      finishedAt: DateTime.utc(2026, 11, 20, 9, minute),
    );

void main() {
  test('total first, then fewer seconds, then the earlier finish; ties share a rank', () {
    final ranked = LeaderboardEntry.ranked([
      _e('a', 250, 3400, 5),
      _e('b', 280, 3600, 1),
      _e('c', 250, 3100, 9),
      _e('d', 250, 3100, 4),
      _e('e', 300, 3700, 8),
      _e('f', 0, null, 10),
    ]);
    expect(ranked.map((x) => '${x.rank}${x.studentId}').toList(),
        ['1e', '2b', '3d', '3c', '5a', '6f']);
  });

  test('level groups: Beginner 1-2, Intermediate 3-4, Advance 5-6', () {
    expect(levelGroupOf('HSK 2'), LevelGroup.beginner);
    expect(levelGroupOf('HSK 3'), LevelGroup.intermediate);
    expect(levelGroupOf('HSK 4'), LevelGroup.intermediate);
    expect(levelGroupOf('HSK 6'), LevelGroup.advance);
    expect(levelGroupOf('YCT'), isNull);
  });
}
