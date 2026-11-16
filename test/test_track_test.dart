import 'package:chinese_tracker/models/app_user.dart';
import 'package:chinese_tracker/models/exercise.dart';
import 'package:chinese_tracker/models/exercise_skill_category.dart';
import 'package:chinese_tracker/models/exercise_type.dart';
import 'package:chinese_tracker/models/question_bank_item.dart';
import 'package:chinese_tracker/models/test_track.dart';
import 'package:chinese_tracker/services/test_service.dart';
import 'package:flutter_test/flutter_test.dart';

QuestionBankItem _q(String id, ExerciseSkillCategory? skill) => QuestionBankItem(
      id: id,
      ownerId: 'admin',
      type: ExerciseType.multipleChoice,
      question: ExerciseQuestion(prompt: id, options: const ['a', 'b']),
      skillCategory: skill,
      sheetCode: '310901-KK',
    );

void main() {
  group('names (PLAN.md §3)', () {
    test('staff label: Chinese name (Latin name), or Latin alone', () {
      expect(AppUser.staffLabelOf('陈美琳', 'Angeline Santoso'),
          '陈美琳 (Angeline Santoso)');
      expect(AppUser.staffLabelOf(null, 'Angeline Santoso'), 'Angeline Santoso');
      expect(AppUser.staffLabelOf('  ', 'Bryan'), 'Bryan');
    });
    test('peer label: Chinese name, or the first word of the Latin name', () {
      expect(AppUser.peerLabelOf('陈美琳', 'Angeline Santoso'), '陈美琳');
      expect(AppUser.peerLabelOf(null, 'Angeline Santoso'), 'Angeline');
    });
  });

  group('standard formats (PLAN.md §3)', () {
    final formats = {for (final f in standardTestFormats()) f.id: f};

    test('HSK 1-6 as in the table', () {
      final hsk3 = formats['hsk-3']!;
      expect(hsk3.parts.map((p) => (p.skill, p.questions, p.minutes)), [
        (TestSkill.listening, 40, 40),
        (TestSkill.reading, 30, 30),
        (TestSkill.writing, 10, 15),
      ]);
      expect(hsk3.maxTotal, 300);
      expect(hsk3.passMark, 180);
      expect(hsk3.provisional, isFalse);
      expect(formats['hsk-1']!.maxTotal, 200);
      expect(formats['hsk-1']!.passMark, 120);
      expect(formats['hsk-6']!.parts.last.questions, 1);
    });

    test('HSKK basic and HSK 3.0 from the owner papers, all drafts', () {
      final hskk = formats['hskk-basic']!;
      expect(hskk.parts.map((p) => (p.questions, p.minutes)),
          [(15, 6), (10, 4), (2, 3)]);
      expect(hskk.maxTotal, 100);
      expect(hskk.passMark, 60);
      expect(hskk.isSpeaking, isTrue);
      final h30 = formats['hsk3-4']!;
      expect(h30.parts.map((p) => (p.questions, p.minutes)),
          [(32, 25), (32, 30), (6, 25)]);
      expect(h30.passMark, 180);
      expect(h30.provisional, isTrue);
      expect(formats['hsk3-7-9']!.parts, isEmpty);
    });

    test('ids are unique and in order', () {
      final list = standardTestFormats();
      expect(list.map((f) => f.id).toSet().length, list.length);
      expect(list.map((f) => f.order), List.generate(list.length, (i) => i + 1));
    });
  });

  test('考试类型 on the result card', () {
    expect(chineseExamType(TestFamily.hsk, '3'), 'HSK 三级');
    expect(chineseExamType(TestFamily.hsk3, '7-9'), 'HSK 3.0 七至九级');
    expect(chineseExamType(TestFamily.hskk, 'basic'), 'HSKK 初级');
  });

  test('codes are upper case without spaces', () {
    expect(TestCode.normalize(' h31 005 '), 'H31005');
  });

  test('expected vs found questions per part (same split as the server)', () {
    final items = [
      _q('l1', ExerciseSkillCategory.listening),
      _q('l2', ExerciseSkillCategory.listening),
      _q('r1', ExerciseSkillCategory.reading),
      _q('r2', null), // missing skill = reading
      _q('w1', ExerciseSkillCategory.typing), // writing
      _q('s1', ExerciseSkillCategory.speaking), // no speaking part
    ];
    const parts = [
      TestPart(skill: TestSkill.listening, questions: 2, minutes: 1, maxScore: 100),
      TestPart(skill: TestSkill.reading, questions: 3, minutes: 1, maxScore: 100),
      TestPart(skill: TestSkill.writing, questions: 1, minutes: 1, maxScore: 100),
    ];
    final counts = TestService.partCounts(items, parts);
    expect(counts.map((c) => (c.expected, c.found)), [(2, 2), (3, 2), (1, 1)]);
  });
}
