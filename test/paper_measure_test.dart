import 'dart:convert';
import 'dart:io';

import 'package:chinese_tracker/core/utils/question_import_utils.dart';
import 'package:chinese_tracker/models/hsk_paper_draft.dart';
import 'package:chinese_tracker/services/hsk_paper/paper_truth.dart';
import 'package:flutter_test/flutter_test.dart';

// Build 1C (docs/PLAN.md §4): the reader measured against a truth file.
//
// Unit checks run always. With PAPER_TEXTS (page texts written by
// tool/paper_measure/run.mjs) and PAPER_TRUTH set, the last test runs the
// structure builder on those texts and prints the numbers, e.g.
//   PAPER_TEXTS=out.json PAPER_TRUTH=test/fixtures/practice_paper/H399001P.truth.json \
//     flutter test test/paper_measure_test.dart
const _fixture = 'test/fixtures/practice_paper/H399001P.truth.json';

HskPaperDraft _draftOf(PaperTruth truth) => HskPaperDraft(
      code: truth.code,
      level: truth.level,
      slots: [
        for (final q in truth.questions)
          HskSlot(
            number: q.number,
            skill: q.skill,
            form: q.form,
            prompt: q.prompt,
            options: [...q.options],
            segments: [...q.segments],
            keyword: q.keyword,
          ),
      ],
    );

void main() {
  final truth = PaperTruth.parse(File(_fixture).readAsStringSync());

  test('the practice paper has 80 questions in the HSK 3 parts', () {
    expect(truth.code, 'H399001P');
    expect(truth.questions.length, 80);
    expect(truth.questions.where((q) => q.skill == 'listening').length, 40);
    expect(truth.questions.where((q) => q.skill == 'reading').length, 30);
    expect(truth.questions.where((q) => q.skill == 'writing').length, 10);
    expect(truth.questions[75].keyword, 'guān');
  });

  test('a perfect draft is 80 of 80 right; each kind of difference counts', () {
    final draft = _draftOf(truth);
    expect(PaperMeasure.compare(draft, truth, checkPictures: false).right, 80);

    draft.slots[12].prompt = draft.slots[12].prompt.replaceFirst('画', '昼');
    draft.slots[22].options[1] = '';
    draft.slots[70].segments = ['桌', '子', '小猫', '下面', '在'];
    draft.slots[76].keyword = 'cha';
    final m = PaperMeasure.compare(draft, truth, checkPictures: false);
    expect(m.right, 76);
    final wrong = {for (final c in m.checks) if (!c.right) c.number: c.wrong};
    expect(wrong[13], ['prompt']);
    expect(wrong[23], ['options']);
    expect(wrong[71], ['segments']);
    expect(wrong[77], ['keyword']);
  });

  test('spaces, Western punctuation and an empty answer bracket do not count', () {
    expect(PaperMeasure.norm('★ 他 今天 没去上班。 ( )'), PaperMeasure.norm('★ 他今天没去上班。'));
    expect(PaperMeasure.norm('你好,再见?'), '你好，再见？');
    expect(PaperMeasure.norm('这道题很（ ），我'), '这道题很（），我');
  });

  test('a truth file round-trips', () {
    final again = PaperTruth.parse(truth.encode());
    expect(again.questions.length, 80);
    expect(again.questions[60].prompt, truth.questions[60].prompt);
  });

  final textsPath = Platform.environment['PAPER_TEXTS'];
  final truthPath = Platform.environment['PAPER_TRUTH'];

  // A paper with no truth file yet (the real one until the owner has
  // proofread it): what the reader found and how much it flags.
  test('flag counts of saved page texts', () {
    final data = jsonDecode(File(textsPath!).readAsStringSync()) as Map;
    final pages = [for (final p in data['pages'] as List) (p as Map)['text'] as String];
    final draft = QuestionImportUtils.parseHskPaper(pages);
    final pictureSlots = draft.slots.where((s) => s.form == HskForm.picture).length;
    final flaggedText = draft.flagged.where((s) => s.form != HskForm.picture).length;
    final line = '${(data['meta'] as Map?)?['engine'] ?? '?'}: ${draft.code} · '
        '${draft.slots.length} slots (${draft.countFor('listening')}/'
        '${draft.countFor('reading')}/${draft.countFor('writing')}) · '
        '${draft.missingNumbers.length} missing ${draft.missingNumbers} · ${draft.flagged.length} flagged '
        '($flaggedText not counting $pictureSlots picture questions, whose '
        'pictures come from the page images) · '
        '${(((data['meta'] as Map?)?['totalMs'] as num? ?? 0) / 1000).toStringAsFixed(1)} s';
    final report = Platform.environment['PAPER_OUT'];
    if (report != null) {
      File(report).writeAsStringSync([
        line,
        for (final s in draft.slots)
          '${s.flagged ? 'F' : ' '} ${s.number} ${s.form} | ${s.prompt.replaceAll('\n', '/')} | '
              '${s.options.join(' · ')} | ${s.segments.join(' · ')} | ${s.keyword}',
      ].join('\n'));
    }
    // ignore: avoid_print
    print(line);
  }, skip: textsPath == null || truthPath != null
      ? 'set PAPER_TEXTS without PAPER_TRUTH for flag counts'
      : false);
  test('measure the reader on saved page texts', () {
    final data = jsonDecode(File(textsPath!).readAsStringSync()) as Map;
    final pages = [for (final p in data['pages'] as List) (p as Map)['text'] as String];
    final paperTruth = PaperTruth.parse(File(truthPath!).readAsStringSync());
    final draft = QuestionImportUtils.parseHskPaper(pages);
    final measure = PaperMeasure.compare(draft, paperTruth,
        checkPictures: false,
        seconds: ((data['meta'] as Map?)?['totalMs'] as num?)?.toDouble() == null
            ? null
            : ((data['meta'] as Map)['totalMs'] as num) / 1000);
    final out = StringBuffer()
      ..writeln('${(data['meta'] as Map?)?['engine'] ?? '?'}: ${measure.summary()}')
      ..writeln('wrong & flagged ${measure.wrongFlagged} · right but flagged '
          '${measure.rightButFlagged}');
    final slotOf = {for (final s in draft.slots) s.number: s};
    for (final c in measure.checks.where((c) => !c.right)) {
      final s = slotOf[c.number];
      final t = paperTruth.questions.firstWhere((q) => q.number == c.number);
      out.writeln('${c.flagged ? 'F' : '!'} ${c.number} ${c.wrong.join(',')} | '
          'read: ${s?.form} ${s?.prompt.replaceAll('\n', '/')} ${s?.options} '
          '${s?.segments} ${s?.keyword} | truth: ${t.form} '
          '${t.prompt.replaceAll('\n', '/')} ${t.options} ${t.segments} ${t.keyword}');
    }
    final report = Platform.environment['PAPER_OUT'];
    if (report != null) File(report).writeAsStringSync(out.toString());
    // ignore: avoid_print
    print(out.toString().split('\n').take(2).join('\n'));
  }, skip: textsPath == null || truthPath == null
      ? 'set PAPER_TEXTS and PAPER_TRUTH to measure'
      : false);
}
