import 'package:chinese_tracker/models/app_user.dart';
import 'package:chinese_tracker/models/cohort_report_models.dart';
import 'package:flutter_test/flutter_test.dart';

// Build 2B, Must 8: staff see `中文名 (Latin name)`, and student searches
// match both names (PLAN.md §3 "Names").
void main() {
  const student = AppUser(
    uid: 's1',
    email: 'angeline@example.com',
    name: 'Angeline Santoso',
    role: 'student',
    nameIndonesian: 'Angeline Santoso',
    nameChinese: '陈美琳',
  );

  test('the staff label puts the Chinese name first', () {
    expect(student.staffLabel, '陈美琳 (Angeline Santoso)');
    expect(student.peerLabel, '陈美琳');
  });

  test('search matches the Chinese name, the Latin name and the email', () {
    expect(student.matchesSearch(''), isTrue);
    expect(student.matchesSearch('美琳'), isTrue);
    expect(student.matchesSearch('santoso'), isTrue);
    expect(student.matchesSearch('  ANGELINE '), isTrue);
    expect(student.matchesSearch('example.com'), isTrue);
    expect(student.matchesSearch('example.com', includeEmail: false), isFalse);
    expect(student.matchesSearch('Bryan'), isFalse);
  });

  test('search for names stored outside a profile', () {
    expect(AppUser.nameMatches('陈', chinese: '陈美琳', latin: 'Angeline'),
        isTrue);
    expect(AppUser.nameMatches('ange', chinese: null, latin: 'Angeline'),
        isTrue);
    expect(AppUser.nameMatches('H3DEMO', latin: 'Bryan', others: ['h3demo1']),
        isTrue);
    expect(AppUser.nameMatches('zhang', chinese: '陈美琳', latin: 'Angeline'),
        isFalse);
  });

  test('roster rows keep the Latin name for exports and show the label', () {
    const row = StudentRosterSummary(
      studentId: 's1',
      name: 'Angeline Santoso',
      staffLabel: '陈美琳 (Angeline Santoso)',
      levelLabel: 'HSK 3',
      lessonsCompleted: 0,
      lessonsTotal: 0,
      termProgressLabel: '',
      homeworkCompleted: 0,
      homeworkAssigned: 0,
      homeworkOverdue: 0,
      sessionsRemaining: 0,
    );
    expect(row.name, 'Angeline Santoso');
    expect(row.staffLabel, '陈美琳 (Angeline Santoso)');

    const noLabel = StudentRosterSummary(
      studentId: 's2',
      name: 'Bryan',
      levelLabel: '',
      lessonsCompleted: 0,
      lessonsTotal: 0,
      termProgressLabel: '',
      homeworkCompleted: 0,
      homeworkAssigned: 0,
      homeworkOverdue: 0,
      sessionsRemaining: 0,
    );
    expect(noLabel.staffLabel, 'Bryan');
  });
}
