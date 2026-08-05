import 'dart:io';

import 'package:chinese_tracker/core/utils/question_import_utils.dart';
import 'package:chinese_tracker/models/exercise_type.dart';
import 'package:chinese_tracker/services/worksheet_text/pdf_text_reader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('extracts compose sentences from MENYUSUN KALIMAT HSK3 PDF', () async {
    final file = File('test/fixtures/menyusun_kalimat_hsk3.pdf');
    if (!file.existsSync()) return;

    final text = await PdfTextReader.extract(await file.readAsBytes());
    expect(text.trim(), isNotEmpty);
    expect(text, contains('Menyusun kalimat'));

    final parsed = QuestionImportUtils.parseWorksheet(text);
    expect(parsed.suggestedType, ExerciseType.composeSentences);
    expect(parsed.suggestedLevel, 'HSK 3');
    expect(parsed.composeQuestions.length, greaterThanOrEqualTo(10));
  });
}
