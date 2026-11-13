import 'package:chinese_tracker/core/utils/question_import_utils.dart';
import 'package:chinese_tracker/features/question_bank/question_bank_ai_import_utils.dart';
import 'package:chinese_tracker/models/ai_worksheet.dart';
import 'package:chinese_tracker/models/exercise_category.dart';
import 'package:chinese_tracker/models/exercise_skill_category.dart';
import 'package:chinese_tracker/models/exercise_type.dart';
import 'package:flutter_test/flutter_test.dart';

/// A slice of an HSK 3 paper the way the AI reader returns it.
const _paper = {
  'title': 'HSK（三级）H326202Z',
  'code': 'H326202Z',
  'hskLevel': 3,
  'category': 'hsk_simulation',
  'sections': [
    {
      'title': '一、听力 · 第一部分 · 第1-5题',
      'skill': 'listening',
      'questions': [
        {
          'number': 1,
          'type': 'picture_choice',
          'page': 2,
          'correctIndex': -1,
          'optionImageBoxes': [
            [230, 290, 420, 430],
            [230, 700, 420, 780],
            [460, 300, 600, 420],
            [460, 650, 600, 820],
            [640, 280, 780, 450],
            [640, 650, 780, 820],
          ],
        },
        {
          'number': 2,
          'type': 'picture_choice',
          'page': 2,
          'correctIndex': -1,
          'optionImageBoxes': [
            [230, 290, 420, 430],
            [230, 700, 420, 780],
            [460, 300, 600, 420],
            [460, 650, 600, 820],
            [640, 280, 780, 450],
            [640, 650, 780, 820],
          ],
        },
      ],
    },
    {
      'title': '一、听力 · 第二部分 · 第11-20题',
      'skill': 'listening',
      'questions': [
        {
          'number': 11,
          'type': 'true_false',
          'page': 4,
          'prompt': '★ 说话人一般坐电梯上楼。',
          'correctIndex': -1,
        },
      ],
    },
    {
      'title': '二、阅读 · 第一部分 · 第46-50题',
      'skill': 'reading',
      'questions': [
        {
          'number': 46,
          'type': 'matching',
          'page': 8,
          'prompt': '你做什么了？怎么身上都是水？',
          'options': [
            '我刚才给小狗洗澡了。',
            '对，上面有我用铅笔写的名字。',
            '差一刻钟三点，会议马上要开始了。',
            '为了这次篮球比赛，我们努力练习了两个多月。',
            '我终于明白这个题怎么做了，谢谢你。',
          ],
          'correctIndex': 0,
        },
      ],
    },
    {
      'title': '二、阅读 · 第三部分 · 第61-70题',
      'skill': 'reading',
      'questions': [
        {
          'number': 61,
          'type': 'choice',
          'page': 11,
          'prompt': '这双皮鞋很便宜，颜色也漂亮，但穿着走了没几分钟，我的脚就开始疼了。\n★ 那双皮鞋：',
          'options': ['是蓝色的', '让他不满意', '是妻子买的'],
          'correctIndex': 1,
        },
      ],
    },
    {
      'title': '三、书写 · 第一部分 · 第71-75题',
      'skill': 'writing',
      'questions': [
        {
          'number': 71,
          'type': 'reorder',
          'page': 15,
          'segments': ['我', '把', '作业', '写完了'],
          'correctIndex': -1,
        },
        {
          'number': 76,
          'type': 'write_hanzi',
          'page': 16,
          'prompt': '他每天都（ ）跑步。',
          'keyword': 'qù',
          'accepted': ['去'],
        },
        {'number': 77, 'type': 'write_hanzi', 'page': 16, 'prompt': 'no pinyin'},
      ],
    },
  ],
};

void main() {
  final worksheet = AiWorksheet.fromJson(Map<String, dynamic>.from(_paper));

  test('boxes are shared between the questions of a group', () {
    expect(worksheet.questions.length, 8);
    expect(worksheet.boxes.length, 6);
    expect(worksheet.boxes.values.every((b) => b.page == 2), isTrue);
  });

  test('bank items keep the paper code, parts, skills and keys', () {
    final urls = {
      for (final box in worksheet.boxes.values) box.key: 'https://img/${box.key}',
    };
    final items = QuestionBankAiImportUtils.toBankItems(
      worksheet,
      ownerId: 'owner',
      imageUrls: urls,
      fileName: 'H326202Z.pdf',
    );
    // The hanzi question without pinyin is dropped.
    expect(items.length, 7);
    expect(items.every((i) => i.sheetCode == 'H326202Z'), isTrue);
    expect(items.every((i) => i.level == 'HSK 3'), isTrue);
    expect(items.every((i) => i.category == ExerciseCategory.hskSimulation),
        isTrue);
    expect(items.map((i) => i.sheetIndex), [0, 1, 2, 3, 4, 5, 6]);

    final q1 = items[0];
    expect(q1.type, ExerciseType.listening);
    expect(q1.skillCategory, ExerciseSkillCategory.listening);
    expect(q1.section, '一、听力 · 第一部分 · 第1-5题');
    expect(q1.question.prompt, '第1题');
    expect(q1.question.options, ['A', 'B', 'C', 'D', 'E', 'F']);
    expect(q1.question.optionImageUrls.length, 6);
    expect(q1.question.optionImageUrls.first, startsWith('https://img/p2-'));
    expect(q1.question.correctIndex, 0, reason: 'unknown key defaults to A');

    final tf = items[2];
    expect(tf.type, ExerciseType.multipleChoice);
    expect(tf.question.options, QuestionImportUtils.trueFalseOptions);

    final matching = items[3];
    expect(matching.type, ExerciseType.matching);
    expect(matching.skillCategory, ExerciseSkillCategory.reading);
    expect(matching.question.options.length, 5);
    expect(matching.question.correctIndex, 0);

    final reading = items[4];
    expect(reading.type, ExerciseType.multipleChoice);
    expect(reading.question.correctIndex, 1);

    final reorder = items[5];
    expect(reorder.type, ExerciseType.composeSentences);
    expect(reorder.skillCategory, ExerciseSkillCategory.typing);
    expect(reorder.question.segments, ['我', '把', '作业', '写完了']);

    final hanzi = items[6];
    expect(hanzi.type, ExerciseType.typeHanzi);
    expect(hanzi.question.keyword, 'qù');
    expect(hanzi.question.acceptedAnswers, ['去']);
  });

  test('summary counts the missing keys of choice questions only', () {
    final summary =
        QuestionBankAiImportUtils.summarize(worksheet, pictures: 6);
    expect(summary.questions, 8);
    expect(summary.sections, 5);
    expect(summary.missingKeys, 3, reason: 'Q1, Q2 and Q11');
    expect(summary.level, 'HSK 3');
  });

  test('sheet code falls back to the file name', () {
    final noCode = AiWorksheet.fromJson({'title': 'x', 'sections': []});
    expect(QuestionBankAiImportUtils.sheetCodeFor(noCode, 'latihan hsk3.pdf'),
        'LATIHANHSK3');
  });

  test('option images stay off when no picture uploaded', () {
    final items = QuestionBankAiImportUtils.toBankItems(
      worksheet,
      ownerId: 'owner',
      imageUrls: const {},
      fileName: 'H326202Z.pdf',
    );
    expect(items.first.question.optionImageUrls, isEmpty);
    expect(items.first.question.options.length, 6);
  });
}
