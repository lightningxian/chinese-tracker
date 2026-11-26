import 'package:chinese_tracker/core/utils/answer_sheet_parser.dart';
import 'package:chinese_tracker/features/question_bank/answer_sheet_check.dart';
import 'package:chinese_tracker/models/exercise.dart';
import 'package:chinese_tracker/models/exercise_type.dart';
import 'package:chinese_tracker/models/question_bank_item.dart';
import 'package:flutter_test/flutter_test.dart';

// Every key below is made up for the test (never an official key).

Map<int, String> numbered(AnswerSheetText t) => {for (final e in t.entries) e.number: e.value};

QuestionBankItem item(
  String id,
  ExerciseType type,
  ExerciseQuestion q,
  int i, {
  String? section,
}) =>
    QuestionBankItem(
      id: id,
      ownerId: 'a',
      type: type,
      question: q,
      sheetCode: 'K',
      sheetIndex: i,
      section: section,
    );

const abcd = ExerciseQuestion(prompt: 'q', options: ['甲', '乙', '丙', '丁']);
const tf = ExerciseQuestion(prompt: 'q', options: ['对 (True)', '错 (False)']);

void main() {
  group('AnswerSheetParser: reading the text', () {
    test('HSK style: parts, stops, marks, written answers', () {
      final t = AnswerSheetParser.parse('''
HSK（三级）答案
一、听 力
第一部分
1. √  2. ×  3. √
第二部分
4．B  5、C  6) A
三、书写
7. 我们一起去吧。
8. 长
''');
      expect(numbered(t), {
        1: '√', 2: '×', 3: '√', 4: 'B', 5: 'C', 6: 'A',
        7: '我们一起去吧。', 8: '长',
      });
      expect(t.blockCount, 1);
      expect(t.script, isNull);
    });

    test('full-width digits, glued entries, ranges and tables', () {
      expect(numbered(AnswerSheetParser.parse('１．Ａ ２．Ｃ')), {1: 'A', 2: 'C'});
      expect(numbered(AnswerSheetParser.parse('1.A2.C3.B')), {1: 'A', 2: 'C', 3: 'B'});
      expect(numbered(AnswerSheetParser.parse('41-45 ECBAD')),
          {41: 'E', 42: 'C', 43: 'B', 44: 'A', 45: 'D'});
      expect(numbered(AnswerSheetParser.parse('1 2 3 4 5\n√ × A B C')),
          {1: '√', 2: '×', 3: 'A', 4: 'B', 5: 'C'});
      expect(numbered(AnswerSheetParser.parse('(1) A (2) B')), {1: 'A', 2: 'B'});
      expect(numbered(AnswerSheetParser.parse('1 A 2 C')), {1: 'A', 2: 'C'});
    });

    test('two-column keys read out of order still count', () {
      expect(numbered(AnswerSheetParser.parse('1. A  6. E\n2. B  7. F')),
          {1: 'A', 6: 'E', 2: 'B', 7: 'F'});
    });

    test('numbers inside an answer stay in the answer', () {
      expect(numbered(AnswerSheetParser.parse('1. 两点 2. 3点')), {1: '两点', 2: '3点'});
      expect(numbered(AnswerSheetParser.parse('5. 两点；3点')), {5: '两点；3点'});
      expect(numbered(AnswerSheetParser.parse('3. 3.5')), {3: '3.5'});
    });

    test('titles and codes are not answers', () {
      expect(AnswerSheetParser.parse('H31999 HSK 3 答案\n第1课\n2026年').entries, isEmpty);
    });

    test('the listening script is cut out (after or before the key)', () {
      final after = AnswerSheetParser.parse('''
答案
1. √ 2. ×
听力材料
1. 男：你好！
2. 女：谢谢。
''');
      expect(numbered(after), {1: '√', 2: '×'});
      expect(after.script, contains('男：你好'));

      final before = AnswerSheetParser.parse('''
听力文本
1. 男：你好！
2. 女：谢谢。
1. √ 2. × 3. A
''');
      expect(numbered(before), {1: '√', 2: '×', 3: 'A'});
      expect(before.script, contains('女：谢谢'));
    });

    test('a paper printed with its key: only the key is read', () {
      final t = AnswerSheetParser.parse('''
一、听力
1. 他想去哪儿？ A 北京 B 上海
请把答案写在答题卡上。
参考答案
1. B
''');
      expect(numbered(t), {1: 'B'});
    });

    test('Standard Course style: numbering starts again per block', () {
      final t = AnswerSheetParser.parse('''
第1课
一、1. × 2. √
二、1. B 2. A
三、1. 你好 2. 再见
''');
      expect(t.blockCount, 3);
      expect([for (final e in t.entries) '${e.block}:${e.number}'],
          ['0:1', '0:2', '1:1', '1:2', '2:1', '2:2']);
      expect(t.entries.first.heading, '一、');
    });
  });

  group('AnswerSheetCheck: matching and checking', () {
    test('one numbering: every type gets its key, free writing has none', () {
      final sheet = QuestionBankSheet(key: 'K', items: [
        item('c', ExerciseType.multipleChoice, abcd, 0),
        item('t', ExerciseType.listening, tf, 1),
        item('w', ExerciseType.composeSentences,
            const ExerciseQuestion(prompt: '', segments: ['去吧', '我们', '一起']), 2),
        item('h', ExerciseType.typeHanzi,
            const ExerciseQuestion(prompt: '（ ）', keyword: 'cháng'), 3),
        item('p', ExerciseType.typePinyin, const ExerciseQuestion(prompt: '长'), 4),
        item('f', ExerciseType.fillBlanks,
            const ExerciseQuestion(prompt: '他____去，她____买。'), 5),
        item('e', ExerciseType.essay, const ExerciseQuestion(prompt: '写'), 6),
        item('m', ExerciseType.matching,
            const ExerciseQuestion(prompt: 'q', options: ['A', 'B', 'C', 'D', 'E', 'F']), 7),
      ]);
      final rows = AnswerSheetCheck.match(
        sheet,
        AnswerSheetParser.parse('1. C 2. × 3. 我们一起去吧。\n4. 长 / 常\n5. cháng\n'
            '6. 想；要\n7. 我喜欢学习汉语。\n8. F'),
      );
      expect([for (final r in rows) r.verdict.status], [
        AnswerSheetStatus.changed, // C, was A
        AnswerSheetStatus.changed, // × = 1, was 0
        AnswerSheetStatus.changed,
        AnswerSheetStatus.changed,
        AnswerSheetStatus.changed,
        AnswerSheetStatus.changed,
        AnswerSheetStatus.free,
        AnswerSheetStatus.changed,
      ]);
      expect(rows[5].read, '想 | 要');
      final plan = AnswerSheetCheck.plan(sheet, rows);
      expect(plan.indexes, {'c': 2, 't': 1, 'm': 5});
      expect(plan.fields['w'], {'question.segments': ['我们', '一起', '去吧']});
      expect(plan.fields['h'], {'question.options': ['长', '常']});
      expect(plan.fields['p'], {'question.options': ['cháng']});
      expect(plan.fields['f'], {'question.options': ['想', '要']});
      expect(plan.fields.containsKey('e'), isFalse);
    });

    test('flags: past the last choice, wrong words, blank count, missing', () {
      final sheet = QuestionBankSheet(key: 'K', items: [
        item('c', ExerciseType.multipleChoice, abcd, 0),
        item('w', ExerciseType.composeSentences,
            const ExerciseQuestion(prompt: '', segments: ['去', '我们']), 1),
        item('f', ExerciseType.fillBlanks,
            const ExerciseQuestion(prompt: '他____去，她____买。'), 2),
        item('h', ExerciseType.typeHanzi, const ExerciseQuestion(prompt: '（ ）'), 3),
        item('x', ExerciseType.multipleChoice, abcd, 4),
      ]);
      final rows = AnswerSheetCheck.match(
          sheet, AnswerSheetParser.parse('1. F 2. 他们来 3. 想 4. ma'));
      expect([for (final r in rows) r.verdict.issue], [
        AnswerSheetIssue.pastLastChoice,
        AnswerSheetIssue.wordsDoNotMatch,
        AnswerSheetIssue.blankCount,
        AnswerSheetIssue.wrongScript,
        AnswerSheetIssue.none,
      ]);
      expect(rows.last.verdict.status, AnswerSheetStatus.missing);
      // Fixed on the check screen: the row is good again.
      rows[0].value = 'B';
      expect(rows[0].verdict.status, AnswerSheetStatus.changed);
      expect(AnswerSheetCheck.plan(sheet, rows).indexes, {'c': 1});
    });

    test('the key already on the sheet reads as the same; Save changes nothing', () {
      final sheet = QuestionBankSheet(key: 'K', items: [
        item('c', ExerciseType.multipleChoice,
            const ExerciseQuestion(prompt: 'q', options: ['甲', '乙', '丙'], correctIndex: 1), 0),
      ]);
      final rows = AnswerSheetCheck.match(sheet, AnswerSheetParser.parse('1. B'));
      expect(rows.single.verdict.status, AnswerSheetStatus.same);
      final plan = AnswerSheetCheck.plan(sheet, rows);
      expect(plan.indexes, isEmpty);
      expect(plan.fields, isEmpty);
    });

    test('a choice may be named by its text', () {
      final sheet = QuestionBankSheet(key: 'K', items: [
        item('c', ExerciseType.readingCloze,
            const ExerciseQuestion(prompt: '他____去。', options: ['想', '要', '会']), 0),
      ]);
      final rows = AnswerSheetCheck.match(sheet, AnswerSheetParser.parse('1. 会'));
      expect(rows.single.read, 'C');
      expect(rows.single.verdict.choice, 2);
    });

    test('read twice with two answers: the admin picks', () {
      final sheet = QuestionBankSheet(key: 'K', items: [
        item('a', ExerciseType.multipleChoice, abcd, 0),
        item('c', ExerciseType.multipleChoice, abcd, 1),
      ]);
      final rows = AnswerSheetCheck.match(sheet, AnswerSheetParser.parse('1. A 2. B\n2. C'));
      expect(rows.last.verdict.issue, AnswerSheetIssue.readTwice);
      expect(AnswerSheetCheck.plan(sheet, rows).indexes, isEmpty);
      rows.last.value = 'C ';
      expect(rows.last.verdict.status, AnswerSheetStatus.changed);
    });

    test('a key that starts later is shifted to the first question', () {
      final sheet = QuestionBankSheet(key: 'K', items: [
        item('a', ExerciseType.multipleChoice, abcd, 0),
        item('b', ExerciseType.multipleChoice, abcd, 1),
      ]);
      final rows = AnswerSheetCheck.match(sheet, AnswerSheetParser.parse('41. C 42. D'));
      expect([for (final r in rows) r.read], ['C', 'D']);
    });

    test('blocks go to the worksheet parts; free-writing parts may be left out', () {
      final sheet = QuestionBankSheet(key: 'K', items: [
        item('a1', ExerciseType.listening, tf, 0, section: '一'),
        item('a2', ExerciseType.listening, tf, 1, section: '一'),
        item('e1', ExerciseType.essay, const ExerciseQuestion(prompt: '组词'), 2, section: '二'),
        item('b1', ExerciseType.multipleChoice, abcd, 3, section: '三'),
        item('b2', ExerciseType.multipleChoice, abcd, 4, section: '三'),
      ]);
      final rows = AnswerSheetCheck.match(
          sheet, AnswerSheetParser.parse('一、1. × 2. √\n三、1. D 2. C'));
      expect([for (final r in rows) r.read], ['×', '√', '', 'D', 'C']);
      expect(rows[2].verdict.status, AnswerSheetStatus.free);
      expect(rows.every((r) => r.readIssue == AnswerSheetIssue.none), isTrue);
    });

    test('blocks that do not line up are given out in order, with a hint', () {
      final sheet = QuestionBankSheet(key: 'K', items: [
        item('a', ExerciseType.multipleChoice, abcd, 0),
        item('b', ExerciseType.multipleChoice, abcd, 1),
        item('c', ExerciseType.multipleChoice, abcd, 2),
      ]);
      final rows = AnswerSheetCheck.match(
          sheet, AnswerSheetParser.parse('1. B\n1. C\n2. D'));
      expect([for (final r in rows) r.read], ['B', 'C', 'D']);
      expect(rows.every((r) => r.readIssue == AnswerSheetIssue.matchedInOrder), isTrue);
      // A hint, not a stop: Save still writes them.
      expect(AnswerSheetCheck.plan(sheet, rows).indexes, {'a': 1, 'b': 2, 'c': 3});
    });
  });
}
