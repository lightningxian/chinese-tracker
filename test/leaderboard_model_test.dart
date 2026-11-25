import 'package:chinese_tracker/features/tests/leaderboard_export.dart';
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

  // Build 9C: the paged board's order key and the export rows.
  test('the rank prefix is the same string the functions write', () {
    expect(LeaderboardEntry.rankPrefixOf(300, null), '099700-99999999');
    expect(LeaderboardEntry.rankPrefixOf(0, 59), '100000-00000059');
    final a = _e('a', 250, 3100, 1), b = _e('b', 250, 3400, 1), c = _e('c', 280, 3600, 1);
    final byPrefix = [a, b, c]..sort((x, y) => x.rankPrefix.compareTo(y.rankPrefix));
    expect(byPrefix.map((x) => x.studentId), ['c', 'a', 'b']);
  });

  test('the finish time is shown in Jakarta time, and the export has one row per student', () {
    final e = _e('a', 250, 3100, 5); // 09:05 UTC
    expect(LeaderboardExport.finishedText(e), '20 Nov 2026, 16:05 WIB');
    final board = LeaderboardEntry.ranked([
      e,
      const LeaderboardEntry(
        studentId: 'b', name: '王', total: 280, max: 300, passed: true, seconds: 3000,
        parts: [LeaderboardPart(skill: 'listening', mark: 90, maxScore: 100)],
      ),
    ]);
    final sk = LeaderboardExport.skills(board);
    expect(sk, ['listening']);
    expect(LeaderboardExport.header(sk, (s) => s),
        ['Rank', 'Name', 'listening', 'Total', 'Max', 'Passed', 'Finished at']);
    final rows = LeaderboardExport.rows(board, sk, (x) => 'staff:${x.name}');
    expect(rows.first.take(6).toList(), [1, 'staff:王', 90, 280, 300, 'yes']);
    expect(rows.last[2], '');
  });
}
