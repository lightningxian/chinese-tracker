import 'package:chinese_tracker/core/utils/question_import_utils.dart';
import 'package:chinese_tracker/models/exercise_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QuestionImportUtils.parseWorksheet', () {
    test('parses numbered multiple choice with letter options', () {
      const text = '''
Instructions: Choose the best answer.

1. What does 你好 mean?
A. Thank you
B. Hello *
C. Goodbye
D. Please

2. How do you say thank you?
A. 再见
B. 你好
C. 谢谢
D. 请
''';

      final result = QuestionImportUtils.parseWorksheet(text);

      expect(result.suggestedType, ExerciseType.multipleChoice);
      expect(result.instructions, contains('Choose the best answer'));
      expect(result.mcQuestions, hasLength(2));
      expect(result.mcQuestions.first.prompt, 'What does 你好 mean?');
      expect(result.mcQuestions.first.options, hasLength(4));
      expect(result.mcQuestions.first.options[1], 'Hello');
      expect(result.mcQuestions.first.correctIndex, 1);
    });

    test('parses slash-separated compose sentences', () {
      const text = '''
Arrange the words to form a sentence.

1. 我 / 是 / 学生
2. 今天 / 天气 / 很好
''';

      final result = QuestionImportUtils.parseWorksheet(text);

      expect(result.suggestedType, ExerciseType.composeSentences);
      expect(result.composeQuestions, hasLength(2));
      expect(result.composeQuestions.first.segments, ['我', '是', '学生']);
      expect(result.composeQuestions[1].segments, ['今天', '天气', '很好']);
    });

    test('parses bracket-separated compose segments', () {
      const text = '''
1. [我] [喜欢] [学习] [中文]
''';

      final result = QuestionImportUtils.parseWorksheet(text);

      expect(result.suggestedType, ExerciseType.composeSentences);
      expect(result.composeQuestions, hasLength(1));
      expect(
        result.composeQuestions.first.segments,
        ['我', '喜欢', '学习', '中文'],
      );
    });

    test('parses HSK 3 组词成句 worksheet with spaced segments', () {
      const text = '''
HSK 3 组词成句 Menyusun kalimat (A1)
300001-KLM

1. 南方的  夏天  热极了
2. 经理的  二楼  办公室在
3. 我  买笔记本  忘了
4. 大家  马上  离开那儿  她要求
5. 他  把办法  了  告诉我
6. 事情  他解决  了  已经被
7. 这儿  一双  有  筷子
8. 这个地方  很大  变化  的
9. 一直  阴天  最近  都是
10. 健康  没有什么比  更重要

11 October 2025
1
''';

      final result = QuestionImportUtils.parseWorksheet(text);

      expect(result.suggestedType, ExerciseType.composeSentences);
      expect(result.suggestedLevel, 'HSK 3');
      expect(result.composeQuestions, hasLength(10));
      expect(result.composeQuestions.first.segments, ['南方的', '夏天', '热极了']);
      expect(result.composeQuestions[4].segments, ['他', '把办法', '了', '告诉我']);
      expect(result.composeQuestions.last.segments, ['健康', '没有什么比', '更重要']);
    });

    test('parses matching worksheet with answer bank and prompts', () {
      const text = '''
LATIHAN SOAL HSK 3 (A)
Part 1

A. 他刚离开学校，没走太远。
B. 我的手表和裤子呢？
C. 你刚下飞机，休息一下吧。
D. 你不是要出去吗？怎么还在这儿？
E. 当然。我们先坐公共汽车，然后换地铁。
F. 喂，你听得见我说话吗？

1. 不行，刚才公司来电话，让我过去一下。 ( )
2. 小方呢？不在校园里吗？ ( )
3. 你说什么？我一个字也听不见。 ( )
''';

      final result = QuestionImportUtils.parseWorksheet(text);

      expect(result.suggestedType, ExerciseType.matching);
      expect(result.suggestedLevel, 'HSK 3');
      expect(result.matchingOptions, hasLength(6));
      expect(result.matchingQuestions, hasLength(3));
      expect(result.matchingQuestions.first.prompt, contains('公司来电话'));
    });
  });
}
