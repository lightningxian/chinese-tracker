import 'dart:io';

import 'package:chinese_tracker/core/utils/question_import_utils.dart';
import 'package:chinese_tracker/features/question_bank/question_bank_import_utils.dart';
import 'package:chinese_tracker/models/exercise_skill_category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  WorksheetParseResult parse(String name) =>
      QuestionImportUtils.parseWorksheet(
        File('test/fixtures/worksheets/$name.txt').readAsStringSync(),
      );

  test('compose items are tagged with the sheet code and stay distinct', () {
    final items = QuestionBankImportUtils.fromParseResult(
      result: parse('hsk3_compose'),
      ownerId: 'admin',
    );
    expect(items, hasLength(10));
    expect(items.first.tags, contains('300001-KLM'));
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
    expect(items.first.skillCategory, ExerciseSkillCategory.reading);
  });
}
