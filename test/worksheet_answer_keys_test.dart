import 'dart:convert';
import 'dart:io';

import 'package:chinese_tracker/core/utils/question_import_utils.dart';
import 'package:chinese_tracker/core/utils/worksheet_answer_keys.dart';
import 'package:chinese_tracker/models/exercise_type.dart';
import 'package:flutter_test/flutter_test.dart';

/// The bundled sample set keys the centre's own sheets after a scan.
void main() {
  final keys = WorksheetAnswerKeys(
    jsonDecode(
      File(WorksheetAnswerKeys.assetPath).readAsStringSync(),
    ) as Map<String, dynamic>,
  );

  WorksheetParseResult parse(String name) => QuestionImportUtils.parseWorksheet(
        File('test/fixtures/worksheets/$name.txt').readAsStringSync(),
      );

  test('reading sheet 310001-RDG gets its 7 answers', () {
    final parsed = parse('hsk3_reading_inline_options');
    expect(parsed.sheetCode, '310001-RDG');
    expect(keys.hasKeyFor(parsed.sheetCode), isTrue);

    final keyed = keys.apply(parsed);
    expect(keyed.applied, 7);
    expect(keyed.total, 7);
    expect(
      keyed.result.mcQuestions.map((q) => q.correctIndex).toList(),
      [0, 1, 0, 2, 1, 1, 2],
    );
    // Symbol-font bullets (Wingdings arrows) are dropped, not shown as boxes.
    expect(keyed.result.mcQuestions[0].prompt, isNot(contains('')));
  });

  test('compose sheet 300001-KLM gets the correct word order', () {
    final keyed = keys.apply(parse('hsk3_compose'));
    expect(keyed.applied, 10);
    expect(keyed.result.composeQuestions[1].segments, ['经理的', '办公室在', '二楼']);
    expect(keyed.result.composeQuestions[2].segments, ['我', '忘了', '买笔记本']);
  });

  test('type-the-hanzi sheet 320001-WRT gets the accepted hanzi', () {
    final keyed = keys.apply(parse('hsk3_type_hanzi_from_pinyin'));
    expect(keyed.result.suggestedType, ExerciseType.typeHanzi);
    expect(keyed.applied, 15);
    expect(keyed.result.mcQuestions[0].options, ['刚']);
    expect(keyed.result.mcQuestions[0].keyword, 'gāng');
  });

  test('boxed word lists 320002-WRT: answers resolved by word, not position',
      () {
    final keyed = keys.apply(parse('hsk3_cloze_boxed_banks'));
    expect(keyed.applied, 20);
    final first = keyed.result.mcQuestions[0];
    expect(first.options[first.correctIndex], '作业');
  });

  test('connect-the-words 520002-KK takes the bank from the key', () {
    final parsed = parse('hsk5_match_vocab_sentences');
    expect(parsed.suggestedType, ExerciseType.readingCloze);
    expect(parsed.matchingOptions, isEmpty);

    final keyed = keys.apply(parsed);
    expect(keyed.applied, 5);
    expect(keyed.result.matchingOptions, hasLength(5));
    expect(
      keyed.result.matchingQuestions.map((q) => q.correctIndex).toList(),
      [0, 1, 2, 3, 4],
    );
  });

  test('a sheet without a code is left as scanned', () {
    final parsed = QuestionImportUtils.parseWorksheet('''
Choose the right answers.
1. 我（ ）喜欢喝茶。
A 很 B 是 C 的
2. 他（ ）去学校。
A 吃 B 天天 C 书
''');
    expect(parsed.sheetCode, isNull);
    final keyed = keys.apply(parsed);
    expect(keyed.applied, 0);
    expect(identical(keyed.result, parsed), isTrue);
  });
}
