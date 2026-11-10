import 'package:chinese_tracker/core/utils/question_import_utils.dart';
import 'package:chinese_tracker/models/exercise_type.dart';
import 'package:flutter_test/flutter_test.dart';

/// The scanner must name the worksheet form and extract its questions.
void main() {
  test('R1 fill in the blank: word bank + blanks → reading cloze', () {
    const text = '''
HSK 2 选词填空
A. 的  B. 了  C. 过  D. 在
1. 我吃（B）饭了。
2. 这是我（ ）书。
3. 他去（C）北京。
''';
    final r = QuestionImportUtils.parseWorksheet(text);
    expect(r.suggestedType, ExerciseType.readingCloze);
    expect(r.suggestedLevel, 'HSK 2');
    expect(r.matchingOptions, ['的', '了', '过', '在']);
    expect(r.matchingQuestions, hasLength(3));
    expect(r.matchingQuestions[0].prompt, '我吃（ ）饭了。');
    expect(r.matchingQuestions[0].correctIndex, 1);
    expect(r.matchingQuestions[1].correctIndex, 0);
    expect(r.matchingQuestions[2].correctIndex, 2);
    expect(r.detectionSummary, contains('R1'));
    expect(r.detectionSummary, contains('1 blank without'));
    expect(r.canImport, isTrue);
  });

  test('R1 with an underline blank and a plain word bank', () {
    const text = '''
Isilah dengan kata yang tepat.
（ 喜欢  因为  所以  已经 ）
1. 我____学习汉语。
2. ____下雨，____我们不出去。
''';
    final r = QuestionImportUtils.parseWorksheet(text);
    expect(r.suggestedType, ExerciseType.readingCloze);
    expect(r.matchingOptions, ['喜欢', '因为', '所以', '已经']);
    expect(r.matchingQuestions.first.prompt, '我（ ）学习汉语。');
  });

  test('R4 order the sentences: lettered sentences + answer key', () {
    const text = '''
HSK 4 句子排序
1.
A 所以我们决定明天再去
B 今天天气不好
C 而且商店也关门了
答案：BCA
2.
A 他每天都很忙
B 但是周末会休息
''';
    final r = QuestionImportUtils.parseWorksheet(text);
    expect(r.suggestedType, ExerciseType.composeSentences);
    expect(r.composeQuestions, hasLength(2));
    expect(
        r.composeQuestions[0].segments, ['今天天气不好', '而且商店也关门了', '所以我们决定明天再去']);
    expect(r.composeQuestions[1].prompt, contains('order not detected'));
    expect(r.detectionSummary, contains('R4'));
  });

  test('true/false statements with √ and × marks', () {
    const text = '''
判断对错 HSK 1
1. 我是老师。（√）
2. 他不喜欢喝茶。（×）
3. 今天是星期一。
''';
    final r = QuestionImportUtils.parseWorksheet(text);
    expect(r.suggestedType, ExerciseType.multipleChoice);
    expect(r.mcQuestions, hasLength(3));
    expect(r.mcQuestions[0].prompt, '我是老师。');
    expect(r.mcQuestions[0].options, QuestionImportUtils.trueFalseOptions);
    expect(r.mcQuestions[0].correctIndex, 0);
    expect(r.mcQuestions[1].correctIndex, 1);
    expect(r.detectionSummary, contains('true/false'));
    expect(r.detectionSummary, contains('1 statement without'));
  });

  test('R3 reading comprehension: passage kept apart from the questions', () {
    const text = '''
阅读理解
小明每天早上七点起床，吃完早饭以后坐公共汽车去学校。他最喜欢的课是汉语课，因为老师很有意思。下午四点他回家做作业。
1. 小明几点起床？
A. 六点
B. 七点 *
C. 八点
2. 小明最喜欢什么课？
A. 英语课
B. 数学课
C. 汉语课 *
''';
    final r = QuestionImportUtils.parseWorksheet(text);
    expect(r.suggestedType, ExerciseType.multipleChoice);
    expect(r.passage, startsWith('小明每天早上七点起床'));
    expect(r.instructions, '阅读理解');
    expect(r.mcQuestions, hasLength(2));
    expect(r.mcQuestions[0].prompt, '小明几点起床？');
    expect(r.mcQuestions[0].correctIndex, 1);
    expect(r.mcQuestions[1].correctIndex, 2);
    expect(r.detectionSummary, contains('R3'));
  });

  test('L3 listening: questions imported under the listening type', () {
    const text = '''
听力 HSK 1
听录音，选择正确的答案。
1. 他是谁？
A. 老师 *
B. 学生
C. 医生
''';
    final r = QuestionImportUtils.parseWorksheet(text);
    expect(r.suggestedType, ExerciseType.listening);
    expect(r.mcQuestions, hasLength(1));
    expect(r.questionCount, 1);
    expect(r.detectionSummary, contains('audio'));
  });

  test('plain multiple choice is not mistaken for ordering', () {
    const text = '''
1. 他今天为什么没有来上课？
A. 因为他生病了，在家休息
B. 因为他去北京出差了
C. 因为他忘记了今天有课
2. 她周末一般做什么？
A. 她喜欢在家看书和听音乐
B. 她常常和朋友去公园散步
C. 她每个周末都去图书馆学习
''';
    final r = QuestionImportUtils.parseWorksheet(text);
    expect(r.suggestedType, ExerciseType.multipleChoice);
    expect(r.mcQuestions, hasLength(2));
    expect(r.mcQuestions[0].options, hasLength(3));
  });
}
