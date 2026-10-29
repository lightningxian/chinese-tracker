import 'dart:io';

import 'package:chinese_tracker/core/utils/question_import_utils.dart';
import 'package:chinese_tracker/models/exercise_type.dart';
import 'package:flutter_test/flutter_test.dart';

/// The centre's own worksheets (text as the app's PDF reader extracts it).
WorksheetParseResult parse(String name) => QuestionImportUtils.parseWorksheet(
      File('test/fixtures/worksheets/$name.txt').readAsStringSync(),
    );

void main() {
  test('HSK 2 fill in the blank, lettered bank with pinyin above hanzi', () {
    final r = parse('hsk2_cloze_lettered_bank_pinyin');
    expect(r.suggestedType, ExerciseType.multipleChoice);
    expect(r.suggestedLevel, 'HSK 2');
    expect(r.mcQuestions, hasLength(10));
    expect(r.mcQuestions[0].prompt, '汉语很难，不过很有（ ）。');
    expect(r.mcQuestions[0].options, ['想', '意思', '同屋', '都', '贵', '一共']);
    expect(r.mcQuestions[5].options.first, '新');
    expect(r.mcQuestions[4].prompt, contains('汉英词典'));
    expect(r.detectionSummary, contains('2 word lists'));
  });

  test('HSK 2 true/false with ★ statements', () {
    final r = parse('hsk2_true_false_star_pinyin');
    expect(r.suggestedType, ExerciseType.multipleChoice);
    expect(r.mcQuestions, hasLength(10));
    expect(r.mcQuestions[1].prompt, contains('★ 我爸爸是大夫'));
    expect(r.mcQuestions[1].prompt, contains('医院工作'));
    expect(r.mcQuestions[1].options, QuestionImportUtils.trueFalseOptions);
    expect(r.detectionSummary, contains('★'));
  });

  test('HSK 3 compose sentences', () {
    final r = parse('hsk3_compose');
    expect(r.suggestedType, ExerciseType.composeSentences);
    expect(r.composeQuestions, hasLength(10));
  });

  test('HSK 3 reading with a text per question and inline A B C options', () {
    final r = parse('hsk3_reading_inline_options');
    expect(r.suggestedType, ExerciseType.multipleChoice);
    expect(r.mcQuestions, hasLength(7));
    expect(r.mcQuestions[0].options, ['不是南方人', '会说南方话', '今天搬到南方']);
    expect(r.mcQuestions[0].prompt, contains('妈妈是个北方人'));
    expect(r.mcQuestions[0].prompt, contains('妈妈'));
    expect(r.mcQuestions[6].options, hasLength(3));
  });

  test('HSK 3 type the hanzi for the pinyin', () {
    final r = parse('hsk3_type_hanzi_from_pinyin');
    expect(r.suggestedType, ExerciseType.typeHanzi);
    expect(r.mcQuestions, hasLength(15));
    expect(r.mcQuestions[0].keyword, 'gāng');
    expect(r.mcQuestions[0].prompt, '我（ ）才一直在玩儿电脑游戏，可能没听见。');
    expect(r.mcQuestions[3].prompt, contains('去那儿走 走。'));
    expect(r.suggestedLevel, 'HSK 3');
  });

  test('HSK 3 fill in the blank from boxed word lists', () {
    final r = parse('hsk3_cloze_boxed_banks');
    expect(r.suggestedType, ExerciseType.multipleChoice);
    expect(r.mcQuestions, hasLength(20));
    expect(r.mcQuestions[0].options, ['周末', '带', '游戏', '跟', '作业']);
    expect(r.mcQuestions[5].options.first, '楼');
    expect(r.mcQuestions[19].options.last, '认真');
    expect(r.mcQuestions[0].prompt, '你写完（ ）了吗？');
  });

  test('HSK 4 picture + keyword sentences', () {
    final r = parse('hsk4_picture_keyword');
    expect(r.suggestedType, ExerciseType.pictureSentence);
    expect(r.mcQuestions, hasLength(8));
    expect(r.mcQuestions[0].keyword, '页');
    expect(r.mcQuestions[7].keyword, '钥匙');
  });

  test('HSK 5 exam page: passage with numbered gaps, A–D per gap', () {
    final r = parse('hsk5_exam_cloze_numbered');
    expect(r.suggestedType, ExerciseType.multipleChoice);
    expect(r.suggestedLevel, 'HSK 5');
    expect(r.mcQuestions, hasLength(7));
    expect(r.mcQuestions[0].options, ['繁荣', '单调', '强烈', '深刻']);
    expect(r.mcQuestions[0].prompt, contains('心理学家'));
    expect(r.mcQuestions[0].prompt, contains('（46）'));
    expect(r.mcQuestions[6].options, hasLength(4));
    expect(r.mcQuestions[6].prompt, contains('（52）'));
  });

  test('HSK 5 vocabulary matching sheet: the sentences become blanks', () {
    final r = parse('hsk5_match_vocab_sentences');
    expect(r.suggestedType, ExerciseType.readingCloze);
    expect(r.matchingQuestions, hasLength(5));
    expect(r.detectionSummary, contains('No word bank'));
  });

  test('HSK 5 reading: paragraph then four statements', () {
    final r = parse('hsk5_reading_statements');
    expect(r.suggestedType, ExerciseType.multipleChoice);
    expect(r.suggestedLevel, 'HSK 5');
    expect(r.mcQuestions, hasLength(4));
    expect(r.mcQuestions[0].options.first, '要宽厚待人');
    expect(r.mcQuestions[0].options, hasLength(4));
    expect(r.mcQuestions[0].prompt, contains('人们常说'));
  });
}
