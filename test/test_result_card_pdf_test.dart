import 'dart:io';

import 'package:chinese_tracker/features/tests/test_result_card.dart';
import 'package:chinese_tracker/l10n/generated/app_localizations.dart';
import 'package:chinese_tracker/models/test_track.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('result card PDF builds with the Chinese font (saved for a look)',
      () async {
    final l = lookupAppLocalizations(const Locale('id'));
    final result = TestResult(
      id: 'H3DEMO1_uid',
      codeId: 'H3DEMO1',
      code: 'H3DEMO1',
      family: TestFamily.hsk,
      level: 'HSK 3',
      levelKey: '3',
      studentId: 'uid',
      studentName: 'Angeline Santoso',
      studentNameChinese: '陈美琳',
      sessionId: 's1',
      openedBy: 't1',
      supervisorName: 'Test Teacher',
      parts: const [
        TestResultPart(
            skill: TestSkill.listening, mark: 75, maxScore: 100, correct: 3, total: 4),
        TestResultPart(
            skill: TestSkill.reading, mark: 50, maxScore: 100, correct: 2, total: 4),
        TestResultPart(
            skill: TestSkill.writing, mark: 67, maxScore: 100, correct: 2, total: 3),
      ],
      total: 192,
      max: 300,
      passMark: 180,
      passed: true,
      valid: true,
      invalidReason: '',
      status: 'final',
      resultNumber: 'ES-20261116-JK7PWY',
      releaseYear: 2021,
      finishedAt: DateTime(2026, 11, 16),
    );
    final bytes = await buildTestResultCardPdf(result, l);
    expect(bytes.length, greaterThan(10000), reason: 'font embedded');
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    final out = File('build/test_result_card.pdf');
    out.parent.createSync(recursive: true);
    out.writeAsBytesSync(bytes);
  });
}
