import 'dart:convert';
import 'dart:io';

import 'package:chinese_tracker/core/utils/question_import_utils.dart';
import 'package:chinese_tracker/features/question_bank/question_bank_import_utils.dart';
import 'package:chinese_tracker/models/exercise.dart';
import 'package:chinese_tracker/models/exercise_skill_category.dart';
import 'package:chinese_tracker/models/exercise_type.dart';
import 'package:chinese_tracker/models/question_bank_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  WorksheetParseResult parse(String name) =>
      QuestionImportUtils.parseWorksheet(
        File('test/fixtures/worksheets/$name.txt').readAsStringSync(),
      );

  test('compose items carry their sheet, order and tag, and stay distinct', () {
    final items = QuestionBankImportUtils.fromParseResult(
      result: parse('hsk3_compose'),
      ownerId: 'admin',
    );
    expect(items, hasLength(10));
    expect(items.first.tags, contains('300001-KLM'));
    expect(items.first.sheetCode, '300001-KLM');
    expect(items.first.sheetTitle, isNotEmpty);
    expect(items.map((i) => i.sheetIndex).toList(), List.generate(10, (i) => i));
    expect(items.first.skillCategory, ExerciseSkillCategory.typing);
    // No prompt on a compose item: the list shows the sentence instead.
    expect(items.first.displayText, '南方的 / 夏天 / 热极了');
    expect(items.map((i) => i.dedupeKey).toSet(), hasLength(10));

    // Importing the same sheet again adds nothing.
    final again = QuestionBankImportUtils.dedupeAgainstBank(items, items);
    expect(again.novel, isEmpty);
    expect(again.skipped, 10);
  });

  test('reading items keep the sheet code as a tag', () {
    final items = QuestionBankImportUtils.fromParseResult(
      result: parse('hsk3_reading_inline_options'),
      ownerId: 'admin',
    );
    expect(items, hasLength(7));
    expect(items.every((i) => i.tags.contains('310001-RDG')), isTrue);
    expect(items.every((i) => i.sheetCode == '310001-RDG'), isTrue);
    expect(items.first.skillCategory, ExerciseSkillCategory.reading);
  });

  test('the bundled sample set yields ten titled sheets in sheet order', () {
    final set = jsonDecode(
      File('assets/question_sets/contoh_latihan_soal.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final items = QuestionBankImportUtils.fromQuestionSet(set, ownerId: 'admin');
    final sheets = QuestionBankSheet.group(items);
    expect(sheets, hasLength(10));
    expect(sheets.every((s) => s.isSheet), isTrue);
    expect(sheets.every((s) => s.title != s.code), isTrue, reason: 'titled');
    final reading = sheets.singleWhere((s) => s.key == '310001-RDG');
    expect(reading.count, 7);
    expect(reading.items.map((i) => i.sheetIndex).toList(), [0, 1, 2, 3, 4, 5, 6]);
  });

  test('a bank groups into sheets and stand-alone questions', () {
    QuestionBankItem item(String id, {String? code, int? index, List<String> tags = const []}) =>
        QuestionBankItem(
          id: id,
          ownerId: 'admin',
          type: ExerciseType.multipleChoice,
          question: ExerciseQuestion(prompt: 'q$id', options: const ['a', 'b']),
          sheetCode: code,
          sheetIndex: index,
          tags: tags,
        );

    // Newest first, as the bank stream delivers them; the second question of
    // the sheet arrives before the first.
    final sheets = QuestionBankSheet.group([
      item('3', code: '310001-RDG', index: 1),
      item('4'),
      item('2', code: '310001-RDG', index: 0),
      // Imported before sheetCode existed: the code is only a tag.
      item('1', tags: ['300001-KLM', 'latihan']),
    ]);

    expect(sheets.map((s) => s.key).toList(), ['310001-RDG', null, '300001-KLM']);
    expect(sheets.first.items.map((i) => i.id).toList(), ['2', '3']);
    expect(sheets.first.title, '310001-RDG');
    expect(sheets[1].isSheet, isFalse);
    expect(sheets[1].title, 'q4');
    expect(sheets.last.tags, ['latihan']);
  });
}
