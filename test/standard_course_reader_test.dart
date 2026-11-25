// Owner 2026-11-25: Scan paper reads an HSK Standard Course lesson
// (textbook pages + workbook pages). The page texts below are made up in
// the layout the reader returns for such a lesson (a tab marks a wide gap
// between two columns, `＿＿` a blank line); no book text is copied here.
import 'package:chinese_tracker/core/utils/question_import_utils.dart';
import 'package:chinese_tracker/features/question_bank/question_bank_ai_import_utils.dart';
import 'package:chinese_tracker/models/exercise.dart';
import 'package:chinese_tracker/models/exercise_category.dart';
import 'package:chinese_tracker/models/exercise_type.dart';
import 'package:chinese_tracker/models/hsk_paper_draft.dart';
import 'package:chinese_tracker/services/exercise_play_service.dart';
import 'package:flutter_test/flutter_test.dart';

const _textbook1 = '''
热身 Warm-up
1 给下面的词语选择对应的图片
A B C
2 HSK 标准教程 2
1 买水果 Buying fruit 02-1
大明： 今天下午你去哪儿？\t生词 New Words
小红：我想去商店，买一些\t1.水果 shuǐguǒ
苹果和西瓜。\tn. fruit
小红：我想去商店，买一些苹果
大明： 我跟你一起去吧。\t2.一起 yìqǐ
在学校\t02-2
老师： 你的书带来了吗？\t3.带 dài
学生： 带来了。\tv. to bring
专有名词 Proper Nouns
1.大明 Dàmíng\t2.小红 Xiǎohóng
''';

const _textbook2 = '''
小红： 西瓜 太 贵 了。
拼音课文 Texts in pinyin
Dàmíng: Jīntiān xiàwǔ nǐ qù nǎr?
''';

const _workbook1 = '''
Mǎi shuǐguǒ
买水果
Buying fruit
一、听力 Listening 02
第一部分 Part I
第1-2题：听句子，判断对错
Questions 1-2: Decide whether the statements are true or false.
例如: 他每天跑步。
★ 他很喜欢运动。 （ ）
1. ★ 他想买苹果。 （ ）
2. ★ 西瓜很便宜。 （ ）
第二部分 Part II
第3-4题：听短对话，选择正确答案
3. A 商店 B 学校 C 医院
4. A 一个 B 两个 C 三个
''';

const _workbook2 = '''
标准教程2 练习册
Standard Course 2 Workbook
二、阅读 Reading
第5-6题：选择合适的词语填空
A 一起 B 水果 C 带
例如: 你喜欢吃什么（ ）？
5. 我们（ ）去吧。
6. 你的书（ ）来了吗？
三、书写 Writing
第7-8题：连词成句
7. 去 我 商店 想
8. 西瓜 贵 太 了
第9-10题：看拼音，写汉字
yì
9. 我们（ ）起去。
dài
10. 你（ ）书了吗？
第11-12题：辨认汉字，选择正确的汉字填空
11. 我 ＿＿ 你一起 ＿＿ 商店。（去、跟）
12. 今天 ＿＿ 午我很忙。（下、上）
第13-16题：用下边的汉字组词
13. 水 ＿＿， ＿＿\t15. 学 ＿＿， ＿＿
14. 商 ＿＿， ＿＿\t16. 书 ＿＿， ＿＿
四、复习 Review
第1-1题：根据课文内容填空
1. 大明 ＿＿ 去商店，小红 ＿＿ 买苹果。
''';

void main() {
  final pages = [_textbook1, _textbook2, _workbook1, _workbook2];
  HskPaperDraft read() =>
      QuestionImportUtils.parseHskPaper(pages, fileName: 'Bab 4.pdf');

  test('a Standard Course lesson is recognised with its level, code and title',
      () {
    final d = read();
    expect(d.standardCourse, isTrue);
    expect(d.level, 2);
    expect(d.code, 'SC2-04');
    expect(d.title, 'Standard Course 2 · 买水果');
    expect(d.slots.map((s) => s.number), [for (var n = 1; n <= 17; n++) n]);
    expect(d.slots.where((s) => s.missing), isEmpty);
    expect(d.expected, {'listening': 4, 'reading': 2, 'writing': 11});
  });

  test('each block takes the form its instruction names', () {
    final d = read();
    String form(int n) => d.slots[n - 1].form;
    expect([form(1), form(2)], everyElement(HskForm.trueFalse));
    expect(d.slots[0].prompt, '★ 他想买苹果。（ ）');
    expect([form(3), form(4)], everyElement(HskForm.choice));
    expect(d.slots[2].options, ['商店', '学校', '医院']);
    expect([form(5), form(6)], everyElement(HskForm.wordBank));
    expect(d.slots[4].options, ['一起', '水果', '带']);
    expect([form(7), form(8)], everyElement(HskForm.reorder));
    expect(d.slots[6].segments, ['去', '我', '商店', '想']);
    expect([form(9), form(10)], everyElement(HskForm.pinyinChar));
    expect(d.slots[8].keyword, 'yì');
    for (var n = 13; n <= 16; n++) {
      expect(form(n), HskForm.open, reason: '$n');
    }
    // The review has its answers (owner 2026-11-25): one per blank.
    expect(form(17), HskForm.fillBlanks);
  });

  test('a review question is answered once every blank has its answer', () {
    final review = read().slots[16];
    expect(review.blankCount, 2);
    expect(review.answered, isFalse);
    review.accepted = ['想'];
    expect(review.answered, isFalse);
    review.accepted = ['想', '要/想'];
    expect(review.answered, isTrue);
    expect(review.flagged, isFalse);
  });

  test('two blanks and two characters become a choice of the two orders', () {
    final d = read();
    final s11 = d.slots[10];
    expect(s11.form, HskForm.choice);
    expect(s11.prompt, '我____你一起____商店。');
    expect(s11.options, ['去 … 跟', '跟 … 去']);
    expect(s11.unsure, isFalse);
    // One blank read: the admin looks at it.
    expect(d.slots[11].unsure, isTrue);
  });

  test('two questions on one line, and the review numbered on after them', () {
    final d = read();
    expect(d.slots[12].prompt, '水____，____');
    expect(d.slots[14].prompt, '学____，____');
    expect(d.slots[13].prompt, '商____，____');
    expect(d.slots[15].prompt, '书____，____');
    final review = d.slots[16];
    expect(review.number, 17);
    expect(review.section, '四、复习 · 第1-1题');
    expect(review.skill, 'writing');
    expect(review.prompt, '大明____去商店，小红____买苹果。');
  });

  test('the textbook pages become the context text', () {
    final d = read();
    expect(
      d.context,
      '1. 买水果\n'
      '大明：今天下午你去哪儿？\n'
      '小红：我想去商店，买一些苹果和西瓜。\n'
      '大明：我跟你一起去吧。\n'
      '\n'
      '2. 在学校\n'
      '老师：你的书带来了吗？\n'
      '学生：带来了。\n'
      '小红：西瓜太贵了。\n'
      '\n'
      '生词 New Words\n'
      '1. 水果 shuǐguǒ — n. fruit\n'
      '2. 一起 yìqǐ\n'
      '3. 带 dài — v. to bring\n'
      '\n'
      '专有名词 Proper Nouns\n'
      '大明 Dàmíng\n'
      '小红 Xiǎohóng',
    );
  });

  test('saved as a Standard Course worksheet with the context on each question',
      () {
    final d = read();
    for (final s in d.slots) {
      s.correctIndex ??= 0;
    }
    d.slots[16].accepted = ['想', '要/想'];
    final ws = d.toAiWorksheet({for (var p = 1; p <= 4; p++) p: (1000, 1400)});
    expect(ws.category, 'hsk_standard_course');
    final items = QuestionBankAiImportUtils.toBankItems(
      ws,
      ownerId: 'o',
      imageUrls: const {},
      fileName: 'Bab 4.pdf',
    );
    expect(items.first.sheetCode, 'SC2-04');
    expect(items.every((i) => i.category == ExerciseCategory.standardCourse), isTrue);
    expect(items.every((i) => i.context == d.context), isTrue);
    final open = items.where((i) => i.type == ExerciseType.essay).toList();
    expect(open.length, 4);
    final review = items.last;
    expect(review.type, ExerciseType.fillBlanks);
    expect(review.question.prompt, '大明____去商店，小红____买苹果。');
    expect(review.question.options, ['想', '要/想']);
    // Stored and read back the same way.
    expect(
      ExerciseQuestion.fromMap(review.question.toMap(ExerciseType.fillBlanks),
              exerciseType: ExerciseType.fillBlanks)
          .options,
      ['想', '要/想'],
    );
    expect(items[10].question.options, ['去 … 跟', '跟 … 去']);
  });

  test('the player carries the context the server sends once', () {
    final list = PlayQuestion.listFromServer([
      {'id': 'a', 'type': 'multiple_choice', 'prompt': '1', 'context': 'TEXT'},
      {'id': 'b', 'type': 'multiple_choice', 'prompt': '2', 'context': '', 'contextSame': true},
      {'id': 'c', 'type': 'multiple_choice', 'prompt': '3', 'context': ''},
      {'id': 'd', 'type': 'multiple_choice', 'prompt': '4'},
    ]);
    expect(list.map((q) => q.context), ['TEXT', 'TEXT', '', '']);
  });

  test('a review in two blocks numbers on after the workbook, once', () {
    final d = QuestionImportUtils.parseHskPaper([
      '标准教程2 练习册\n三、书写\n第1-2题：连词成句\n1. 去 我 想\n2. 贵 太 了',
      '四、复习\n第1-1题：根据课文内容填空\n1. 大明 ＿＿ 去商店。\n'
          '第2-2题：根据课文内容填空\n2. 小红 ＿＿ 买苹果，＿＿ 回家。',
    ]);
    expect(d.slots.map((s) => s.number), [1, 2, 3, 4]);
    expect(d.slots.where((s) => s.missing), isEmpty);
    expect(d.slots[2].prompt, '大明____去商店。');
    expect(d.slots[3].section, '四、复习 · 第2-2题');
    expect(d.slots[3].blankCount, 2);
  });

  test('blanks are counted the way the player draws them', () {
    final slot = HskSlot(number: 1, skill: 'writing', form: HskForm.fillBlanks,
        prompt: '他（ ）去过____。');
    expect(slot.blankCount, 2);
    expect(ExerciseType.blankMark.allMatches(slot.prompt).length, 2);
  });

  test('an HSK paper reads a tab as a space and has no context', () {
    final d = QuestionImportUtils.parseHskPaper([
      '一、听力\n第1-2题\n1. ★ 他想\t买苹果。 （ ）\n2. ★ 西瓜很便宜。 （ ）',
    ]);
    expect(d.standardCourse, isFalse);
    expect(d.context, '');
    expect(d.slots.first.prompt, '★ 他想买苹果。（ ）');
  });
}
