// Build 1B: the built-in HSK paper reader. Texts below are written for the
// test (not copied from a real paper).
import 'dart:typed_data';

import 'package:chinese_tracker/core/utils/answer_key_parser.dart';
import 'package:chinese_tracker/core/utils/question_import_utils.dart';
import 'package:chinese_tracker/features/question_bank/sheet_answer_key.dart';
import 'package:chinese_tracker/models/exercise.dart';
import 'package:chinese_tracker/models/exercise_type.dart';
import 'package:chinese_tracker/models/hsk_paper_draft.dart';
import 'package:chinese_tracker/models/question_bank_item.dart';
import 'package:chinese_tracker/services/hsk_paper/hsk_paper_import.dart';
import 'package:chinese_tracker/services/hsk_paper/hsk_paper_reader.dart';
import 'package:chinese_tracker/services/hsk_paper/paper_image_ops.dart';
import 'package:chinese_tracker/services/hsk_paper/paper_ocr.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeEngine implements PaperOcrEngine {
  final modes = <int>[];
  @override
  Future<String> read(Uint8List png,
      {required int pageMode, void Function(double)? onProgress}) async {
    modes.add(pageMode);
    return 'text';
  }
}

Uint8List _rgba(List<List<int>> pixels) => Uint8List.fromList([
      for (final p in pixels) ...[...p, 255],
    ]);

/// A white page with filled rectangles (pictures) and small dots (text).
Uint8List _page(int w, int h, List<PixelBox> rects, {List<PixelBox> dots = const []}) {
  final gray = Uint8List(w * h)..fillRange(0, w * h, 255);
  for (final r in [...rects, ...dots]) {
    for (var y = r.y0; y < r.y1; y++) {
      for (var x = r.x0; x < r.x1; x++) {
        gray[y * w + x] = 40;
      }
    }
  }
  return gray;
}

void main() {
  group('watermark removal (PLAN rule)', () {
    test('saturated light pixels go white, dark ink keeps its grey', () {
      final out = PaperImageOps.cleanToGray(_rgba([
        [230, 120, 120], // pink watermark: max−min 110 > 28, max 230 > 150
        [20, 20, 20], // black ink
        [120, 120, 120], // grey ink stays grey
        [215, 215, 215], // light grey: luminance > 205 → white
        [100, 40, 40], // dark red ink: saturated but max ≤ 150 → kept
      ]));
      expect(out[0], 255);
      expect(out[1], 20);
      expect(out[2], 120);
      expect(out[3], 255);
      expect(out[4], lessThan(100));
    });
  });

  test('every page is read with page mode 6', () async {
    final engine = _FakeEngine();
    final reader = HskPaperReader(engine: engine);
    final white = Uint8List(40 * 40 * 4)..fillRange(0, 40 * 40 * 4, 255);
    await reader.readPage(RgbaPage(40, 40, white), number: 1);
    await reader.readPage(RgbaPage(40, 40, white), number: 2);
    expect(engine.modes, [6, 6]);
    expect(HskPaperReader.maxPages, 30);
  });

  group('picture boxes', () {
    test('large shapes in reading order; text-sized marks ignored', () {
      const w = 1000, h = 1200;
      final rects = [
        const PixelBox(600, 100, 800, 300), // B (right, first row)
        const PixelBox(100, 110, 300, 290), // A
        const PixelBox(100, 500, 320, 640), // C
        const PixelBox(600, 520, 780, 700), // D
      ];
      final dots = [
        for (var i = 0; i < 20; i++) PixelBox(100 + i * 30, 900, 120 + i * 30, 920),
      ];
      final boxes =
          PaperImageOps.findPictureBoxes(_page(w, h, rects, dots: dots), w, h);
      expect(boxes.length, 4);
      expect(boxes.map((b) => b.x0 < 500 ? 'L' : 'R').join(), 'LRLR');
      expect(boxes.first.y0, lessThan(boxes[2].y0));
    });

    test('a picture drawn in pieces becomes one box', () {
      const w = 800, h = 800;
      final rects = [
        const PixelBox(100, 100, 260, 200),
        const PixelBox(110, 215, 250, 330), // 15 px below: same picture
      ];
      final boxes = PaperImageOps.findPictureBoxes(_page(w, h, rects), w, h);
      expect(boxes.length, 1);
      expect(boxes.single.y1, greaterThanOrEqualTo(328));
    });

    test('closely set lines of text are not a picture (Build 1C)', () {
      const w = 1500, h = 800;
      // Three lines of 12 character-sized marks, 28 px apart: they merge
      // into one box, but no shape in it is taller than a character.
      final rects = [
        for (var row = 0; row < 3; row++)
          for (var c = 0; c < 12; c++)
            PixelBox(100 + c * 48, 100 + row * 68, 140 + c * 48, 140 + row * 68),
      ];
      final boxes = PaperImageOps.findPictureBoxes(_page(w, h, rects), w, h);
      expect(boxes, isEmpty);
    });

    test('a long thin strip (a line of text) is not a picture', () {
      const w = 1500, h = 600;
      final boxes = PaperImageOps.findPictureBoxes(
          _page(w, h, [const PixelBox(100, 100, 1400, 190)]), w, h);
      expect(boxes, isEmpty);
    });
  });

  group('structure builder', () {
    // An HSK 1-style paper, written for the test, with the engine's habits:
    // spaces between characters, a misread number (S for 5), a lost line.
    final pages = [
      '汉 语 水 平 考 试\nH 1 2 3 4 5 6 X\nHSK ( 一 级 )',
      '一 、 听 力\n第 一 部 分\n第 1-5 题\n例如 : 示 例\n1. []\n2. []\n3.\n4.\n5.\nH123456X - 1',
      '第 二 部 分\n第 6-10 题\n6. ★ 他 今 天 很 忙 。 ( )\n7. ★ 我 们 明 天 去 。 ( )\n'
          '8. ★ 她 喜 欢 喝 茶 。 ( )\n9. ★ 他 是 医 生 。 ( )\n10. ★ 天 气 很 好 。 ( )',
      '第 三 部 分\n第 11-20 题\n11. A 苹 果 B 米 饭 C 面 条\n12. A 书 店 B 学 校 C 医 院\n'
          '13. A 一 点 B 两 点 C 三 点\n14. A 星 期 一 B 星 期 二 C 星 期 三\n'
          'S5. A 老 师 B 学 生 C 医 生\n16. A 红 色 B 白 色 C 黑 色\n'
          '18. A 猫 B 狗 C 鱼\n19. A 冷 B 热 C 好\n20. A 去 B 来 C 走',
      '二 、 阅 读\n第 一 部 分\n第 21-25 题\nA 喝 B 看 C 买 D 去 E 吃\n例如 : 我 ( ) 书 。\n'
          '21. 我 想 ( ) 水 。\n22. 他 在 ( ) 电 影 。\n23. 我 们 ( ) 学 校 。\n'
          '24. 她 想 ( ) 东 西 。\n25. 我 喜 欢 ( ) 米 饭 。',
      '下 面 是 书 写 部 分\n请 在 书 写 考 试 开 始 后 作 答',
    ];

    test('code and level from the paper; every format number gets a slot', () {
      final d = QuestionImportUtils.parseHskPaper(pages);
      expect(d.code, 'H123456X');
      expect(d.level, 1);
      // HSK 1 format: listening 20, reading 20.
      expect(d.slots.length, 40);
      expect(d.countFor('listening'), 20);
      expect(d.countFor('reading'), 20);
    });

    test('forms by block: pictures, ★ statements, choices, word bank', () {
      final d = QuestionImportUtils.parseHskPaper(pages);
      HskSlot n(int i) => d.slots[i - 1];
      expect(n(1).form, HskForm.picture);
      expect(n(1).picturePage, 2);
      expect(n(6).form, HskForm.trueFalse);
      expect(n(6).prompt, startsWith('★ 他今天很忙。'));
      expect(n(11).form, HskForm.choice);
      expect(n(11).options, ['苹果', '米饭', '面条']);
      expect(n(21).form, HskForm.wordBank);
      expect(n(21).options, ['喝', '看', '买', '去', '吃']);
      expect(n(21).prompt, '我想（ ）水。');
      expect(n(21).section, '二、阅读 · 第一部分 · 第21-25题');
    });

    test('a misread number takes its place by order; a lost line is a flagged slot', () {
      final d = QuestionImportUtils.parseHskPaper(pages);
      expect(d.slots[14].options, ['老师', '学生', '医生']); // S5. → 15
      final seventeen = d.slots[16];
      expect(seventeen.missing, isTrue);
      expect(seventeen.flagged, isTrue);
      expect(seventeen.form, HskForm.choice, reason: 'form of its block');
      expect(d.missingNumbers, contains(17));
      expect(d.slots[17].options, ['猫', '狗', '鱼']); // 18 still in place
    });

    test('a one-line word bank survives misread letters', () {
      final d = QuestionImportUtils.parseHskPaper([
        'H 1 2 3 4 5 6 X\nHSK ( 一 级 )',
        '二 、 阅 读\n第 一 部 分\n第 21-25 题\nA 喝 B 看 CC 买 D 去 王 吃\n'
            '21. 我 想 ( ) 水 。\n22. 他 在 ( ) 电 影 。',
      ]);
      expect(d.slots[20].options, ['喝', '看', '买', '去', '吃']);
      expect(d.slots[20].optionsIncomplete, isFalse);
    });

    test('reader marks are cleaned; doubtful reading is flagged', () {
      final d = QuestionImportUtils.parseHskPaper([
        'H 3 0 0 0 0 0 Z\nHSK ( 三 级 )',
        '二 、 阅 读\n第 三 部 分\n第 61-63 题\n'
            '61. 他 很 忙 。\n★ 他 :\nA 很 忙 B 不 忙 C 很 累\n'
            '62. 她 去 了 。\n★ 她 :\nA 去 了 B 没 去 ”C 不 知 道\n'
            '63. 天 很 冷 。\n★ 天 气 :\nA 很 冷 B H#EX\n'
            '第 一 部 分\n第 41-42 题\nA 好 的 。 B 是 啊 。\n41. 你 好 吗 ？ CC\n42. 冷 吗 ？ (0',
        '三 、 书 写\n第 一 部 分\n第 71-71 题\n71. 我 们 明 天 去 公 园 玩\n'
            '第 二 部 分\n第 76-76 题\nchang\n76. 这 条 路 很 ( ) 。',
      ]);
      HskSlot n(int i) => d.slots.firstWhere((s) => s.number == i);
      expect(n(62).options, ['去了', '没去', '不知道'], reason: '”C is the letter C');
      expect(n(63).optionsIncomplete, isTrue, reason: 'two of three choices');
      expect(n(63).doubt, HskSlot.doubtOptions, reason: 'H#EX has no character');
      expect(n(41).prompt, '你好吗？');
      expect(n(42).prompt, '冷吗？');
      expect(n(71).doubt, HskSlot.doubtSplit);
      expect(n(76).doubt, HskSlot.doubtTones);
      n(76).keyword = 'cháng';
      expect(n(76).doubt, isNull);
      n(71).checked = true;
      expect(n(71).flagged, isFalse, reason: 'the admin said it looks right');
    });

    test('examples and "下面是…部分" pages are skipped', () {
      final d = QuestionImportUtils.parseHskPaper(pages);
      expect(d.slots.any((s) => s.prompt.contains('示例')), isFalse);
      expect(d.slots.any((s) => s.prompt.contains('书写部分')), isFalse);
      expect(d.slots.any((s) => s.prompt.contains('我（ ）书')), isFalse);
    });

    test('writing: word order and the character for a pinyin', () {
      final d = QuestionImportUtils.parseHskPaper([
        'H 3 0 0 0 0 0 Z',
        '三 、 书 写\n第 一 部 分\n第 71-72 题\n71. 我 们 一 起 去 吧\n72. 小 狗 被 他 带 走 了\n'
            '第 二 部 分\n第 76-77 题\nchang\n76. 这 条 路 很 ( ) 。\nhao\n77. 你 ( ) 吗 ?',
      ]);
      HskSlot n(int i) => d.slots.firstWhere((s) => s.number == i);
      expect(n(71).form, HskForm.reorder);
      expect(n(71).segments, ['我', '们', '一', '起', '去', '吧']);
      expect(n(76).form, HskForm.pinyinChar);
      expect(n(76).keyword, 'chang');
      expect(n(76).prompt, '这条路很（ ）。');
      expect(n(77).keyword, 'hao');
    });

    test('pictures of the page become the choices; the slot needs no text', () {
      final d = QuestionImportUtils.parseHskPaper(pages);
      final pagesRead = [
        for (var i = 0; i < pages.length; i++)
          PaperPage(
            number: i + 1,
            width: 1000,
            height: 1400,
            text: pages[i],
            png: Uint8List(0),
            pictureBoxes: i == 1
                ? const [
                    PixelBox(100, 100, 300, 300),
                    PixelBox(500, 100, 700, 300),
                    PixelBox(100, 400, 300, 600),
                  ]
                : const [],
          ),
      ];
      HskPaperImport.assignPictures(d, pagesRead);
      expect(d.slots[2].pictures.length, 3);
      expect(d.slots[2].missing, isFalse);
      expect(d.slots[2].flagged, isFalse);
      final ws = d.toAiWorksheet(HskPaperImport.pageSizes(pagesRead));
      expect(ws.questions.first.optionImageBoxes.first.xmin, 100);
      expect(ws.questions.first.optionImageBoxes.first.ymax, 214); // 300/1400
      expect(ws.code, 'H123456X');
      expect(ws.category, 'hsk_simulation');
      // The lost line 17 has no choices: it is listed, never dropped silently.
      expect(HskPaperImport.unsavable(d, pagesRead), contains(17));
    });
  });

  group('answer key: writing lines', () {
    test('parseWritten reads sentences and characters, not 对 / 错', () {
      final w = AnswerKeyParser.parseWritten('1 A 11 对\n71 我们一起去吧\n76 长');
      expect(w, {71: '我们一起去吧', 76: '长'});
      expect(AnswerKeyParser.parse('1 A 11 对'), {1: 0, 11: 0});
    });

    test('orderSegments puts the words in the order of the sentence', () {
      expect(
        AnswerKeyParser.orderSegments(['被', '书', '妹妹', '拿走了'], '书被妹妹拿走了。'),
        ['书', '被', '妹妹', '拿走了'],
      );
      expect(AnswerKeyParser.orderSegments(['一', '一条', '河'], '一条河一'),
          ['一条', '河', '一'],
          reason: 'the longer word is tried first; every word is used');
    });

    test('a sentence that does not use the words is reported', () {
      expect(AnswerKeyParser.orderSegments(['我', '去'], '他来'), isNull);
    });

    test('plan: choices by index, word order, accepted character', () {
      QuestionBankItem item(String id, ExerciseType type, ExerciseQuestion q, int i) =>
          QuestionBankItem(
            id: id,
            ownerId: 'a',
            type: type,
            question: q,
            sheetCode: 'H300000Z',
            sheetIndex: i,
          );
      final sheet = QuestionBankSheet(key: 'H300000Z', items: [
        item('q1', ExerciseType.listening,
            const ExerciseQuestion(prompt: '', options: ['A', 'B', 'C']), 0),
        item('q2', ExerciseType.composeSentences,
            const ExerciseQuestion(prompt: '', segments: ['去', '我们']), 1),
        item('q3', ExerciseType.typeHanzi,
            const ExerciseQuestion(prompt: '（ ）', keyword: 'cháng'), 2),
        item('q4', ExerciseType.composeSentences,
            const ExerciseQuestion(prompt: '', segments: ['好', '你']), 3),
      ]);
      final plan = SheetAnswerKeyPlan.of(
        sheet,
        choices: AnswerKeyParser.parse('1 C'),
        written: AnswerKeyParser.parseWritten('2 我们去\n3 长\n4 他好'),
      );
      expect(plan.indexes, {'q1': 2});
      expect(plan.fields['q2'], {'question.segments': ['我们', '去']});
      expect(plan.fields['q3'], {'question.options': ['长']});
      expect(plan.notMatched, [4]);
    });

    test('the key box opens with the answers the worksheet has (owner 2026-11-24)', () {
      QuestionBankItem item(String id, ExerciseType type, ExerciseQuestion q, int i) =>
          QuestionBankItem(id: id, ownerId: 'a', type: type, question: q, sheetCode: 'K', sheetIndex: i);
      final sheet = QuestionBankSheet(key: 'K', items: [
        item('q1', ExerciseType.listening,
            const ExerciseQuestion(prompt: '', options: ['A', 'B', 'C', 'D'], correctIndex: 3), 0),
        item('q2', ExerciseType.listening,
            const ExerciseQuestion(prompt: '', options: ['对 (True)', '错 (False)'], correctIndex: 1), 1),
        item('q3', ExerciseType.composeSentences,
            const ExerciseQuestion(prompt: '', segments: ['我们', '一起', '去吧']), 2),
        item('q4', ExerciseType.typeHanzi,
            const ExerciseQuestion(prompt: '（ ）', keyword: 'cháng', options: ['长']), 3),
        item('q5', ExerciseType.essay, const ExerciseQuestion(prompt: '写'), 4),
      ]);
      final text = SheetAnswerKeyPlan.keyText(sheet);
      expect(text, '1 D  2 ×\n3 我们一起去吧\n4 长');
      // Reading it back changes nothing.
      final plan = SheetAnswerKeyPlan.of(sheet,
          choices: AnswerKeyParser.parse(text), written: AnswerKeyParser.parseWritten(text));
      expect(plan.indexes, isEmpty);
      expect(plan.notMatched, isEmpty);
      expect(plan.fields['q3'], {'question.segments': ['我们', '一起', '去吧']});
      expect(plan.fields['q4'], {'question.options': ['长']});
    });
  });
}
