import 'package:chinese_tracker/models/progress_summary.dart';
import 'package:flutter_test/flutter_test.dart';

// Build 4: the summary model, the chart's data mapping and empty states.
void main() {
  test('chart points: one per week with practice, gaps left open, clamped', () {
    final weeks = [
      for (var i = 0; i < 12; i++)
        PracticeWeek(
          week: 'W$i',
          monday: '2026-09-0${i % 9 + 1}',
          average: i == 3 || i == 4 ? null : (i == 11 ? 104.0 : 50.0 + i),
          attempts: i == 3 || i == 4 ? 0 : 2,
        ),
    ];
    final points = practiceChartPoints(weeks);
    expect(points.length, 10);
    expect(points.map((p) => p.x), isNot(contains(3.0)));
    expect(points.first, (x: 0.0, y: 50.0));
    expect(points.last.y, 100, reason: 'clamped to 100');
    expect(practiceChartPoints(const []), isEmpty);
  });

  test('a brand-new summary reads with empty blocks and status good', () {
    final s = ProgressSummary.fromMap('u1', const {});
    expect(s.status, ProgressStatus.good);
    expect(s.weeks, isEmpty);
    expect(s.skills, isEmpty);
    expect(s.tests, isEmpty);
    expect(s.attendancePercent, isNull);
    expect(s.hasVoucher, isFalse);
    expect(s.latestNote, isNull);
    expect(s.practiceChange, isNull);
    expect(s.minCodes, 3);
  });

  test('the function document maps field by field', () {
    final s = ProgressSummary.fromMap('u2', {
      'studentName': 'Hana Lin',
      'studentNameChinese': '林小华',
      'level': 'HSK 3',
      'group': 'intermediate',
      'codes': {'count': 2, 'minCodes': 3, 'next': 'HSK 4'},
      'practice': {
        'weeks': [
          {'week': '2026-W47', 'monday': '2026-11-16', 'average': 75.5, 'attempts': 2},
        ],
        'average14': 75.5,
        'attempts14': 2,
        'averagePrev14': 80,
        'attemptsPrev14': 3,
        'lastPracticeMs': 1795000000000,
      },
      'skills': {
        'typing': {'percent': 40, 'total': 5},
        'listening': {'percent': 80, 'total': 10},
      },
      'tests': {
        'history': [
          {'codeId': 'A', 'code': 'A', 'total': 200, 'max': 300, 'passed': true,
            'rank': 2, 'boardSize': 15, 'placement': false, 'status': 'final'},
        ],
        'passedAtLevel': 1,
      },
      'attendance': {'percent': 75, 'hadir': 3, 'izin': 1, 'alpa': 1, 'last': []},
      'voucher': {'sessionsRemaining': 2, 'deadlineDate': '2026-12-01', 'daysLeft': 12},
      'latestNote': {'text': 'Good', 'teacherName': 'Andrea', 'createdAtMs': 1795000000000},
      'warnings': [
        {'id': 4, 'since': 1795000000000, 'detail': '2 sessions left'},
      ],
      'status': 'attention',
    });
    expect(s.status, ProgressStatus.attention);
    expect(s.codesCount, 2);
    expect(s.nextLevel, 'HSK 4');
    expect(s.practiceChange, closeTo(-4.5, 0.001));
    expect(s.skills.map((k) => k.skill), ['listening', 'typing'], reason: 'skill order');
    expect(s.tests.single.rank, 2);
    expect(s.tests.single.boardSize, 15);
    expect(s.hasVoucher, isTrue);
    expect(s.daysLeft, 12);
    expect(s.latestNote!.teacherName, 'Andrea');
    expect(s.warnings.single.id, 4);
  });

  test('status values', () {
    expect(ProgressStatus.fromValue('follow_up'), ProgressStatus.followUp);
    expect(ProgressStatus.fromValue('x'), ProgressStatus.good);
  });
}
