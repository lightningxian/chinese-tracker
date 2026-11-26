// Build 9 part 2: a Students-list row read from progress_summary.roster.
import 'package:chinese_tracker/core/utils/teacher_attention_utils.dart';
import 'package:chinese_tracker/models/roster_row.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a summary with a roster block gives the Students row', () {
    final at = DateTime(2026, 11, 20, 9);
    final row = RosterRow.fromSummary('s1', {
      'studentName': 'Angeline',
      'studentNameChinese': '安琪',
      'teacherId': 't1',
      'roster': {
        'homeworkAssigned': 5,
        'homeworkCompleted': 2,
        'homeworkOverdue': 1,
        'practiceAvg': 85,
        'practiceCount': 2,
        'sessionsRemaining': 2,
        'lessonsCompleted': 1,
        'lessonAvg': 80,
        'lessons': [
          {'lessonId': 'l1', 'completed': true, 'score': 70, 'completedAtMs': 1},
        ],
        'lessonsPerTerm': 12,
        'rawLevel': 'HSK 3',
        'lastActiveMs': at.millisecondsSinceEpoch,
        'attention': [
          {'reason': 'overdueExercise', 'count': null},
          {'reason': 'lowSessions', 'count': 2},
        ],
      },
    });
    expect(row.hasRoster, isTrue);
    expect(row.student.staffLabel, '安琪 (Angeline)');
    expect(row.student.lessonsPerTerm, 12);
    expect(row.attention.map((a) => a.reason),
        [AttentionReason.overdueExercise, AttentionReason.lowSessions]);
    final s = row.toSummary();
    expect(s.homeworkAssigned, 5);
    expect(s.homeworkCompleted, 2);
    expect(s.homeworkOverdue, 1);
    expect(s.sessionsRemaining, 2);
    expect(s.avgQuizScore, 80);
    expect(s.lastActivityAt, at);
    expect(s.levelLabel.startsWith('HSK 3'), isTrue);
    expect(s.termProgressLabel, '1/0 lessons', reason: 'no lesson library');
  });

  test('a summary not rebuilt yet shows an empty row, not an error', () {
    final row = RosterRow.fromSummary('s2', {'studentName': 'Budi'});
    expect(row.hasRoster, isFalse);
    expect(row.toSummary().homeworkAssigned, 0);
    expect(RosterRow.fromSummary('s3', null).student.uid, 's3');
  });
}
