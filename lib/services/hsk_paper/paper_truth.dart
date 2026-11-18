import 'dart:convert';

import '../../core/utils/question_import_utils.dart';
import '../../models/exercise_type.dart';
import '../../models/hsk_paper_draft.dart';
import '../../models/question_bank_item.dart';

/// What one question of a paper really says (docs/PLAN.md, Build 1C,
/// Must 1), in the shape of the proofreading draft ([HskSlot]): the form,
/// the printed text, the choices, the words to order, the pinyin. The
/// answer key is not part of it: the reader never reads keys.
class PaperTruthQuestion {
  const PaperTruthQuestion({
    required this.number,
    required this.form,
    this.skill = '',
    this.section = '',
    this.prompt = '',
    this.options = const [],
    this.segments = const [],
    this.keyword = '',
    this.pictures = 0,
  });

  final int number;
  final String form;
  final String skill;
  final String section;
  final String prompt;
  final List<String> options;
  final List<String> segments;
  final String keyword;

  /// Picture questions: how many pictures the block has (0 = not checked).
  final int pictures;

  factory PaperTruthQuestion.fromJson(Map<String, dynamic> m) =>
      PaperTruthQuestion(
        number: (m['number'] as num).toInt(),
        form: m['form'] as String? ?? '',
        skill: m['skill'] as String? ?? '',
        section: m['section'] as String? ?? '',
        prompt: m['prompt'] as String? ?? '',
        options: [for (final o in (m['options'] as List? ?? const [])) '$o'],
        segments: [for (final s in (m['segments'] as List? ?? const [])) '$s'],
        keyword: m['keyword'] as String? ?? '',
        pictures: (m['pictures'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'number': number,
        'skill': skill,
        'section': section,
        'form': form,
        'prompt': prompt,
        'options': options,
        'segments': segments,
        'keyword': keyword,
        if (pictures > 0) 'pictures': pictures,
      };
}

/// A whole paper's truth: the practice paper's file (written by
/// `tool/practice_paper/build.mjs`) or a proofread worksheet saved with
/// **Download text**.
class PaperTruth {
  const PaperTruth({
    this.code = '',
    this.level,
    this.source = '',
    required this.questions,
  });

  final String code;
  final int? level;
  final String source;
  final List<PaperTruthQuestion> questions;

  factory PaperTruth.fromJson(Map<String, dynamic> m) => PaperTruth(
        code: m['code'] as String? ?? '',
        level: (m['level'] as num?)?.toInt(),
        source: m['source'] as String? ?? '',
        questions: [
          for (final q in (m['questions'] as List? ?? const []))
            PaperTruthQuestion.fromJson(Map<String, dynamic>.from(q as Map)),
        ],
      );

  factory PaperTruth.parse(String json) =>
      PaperTruth.fromJson(Map<String, dynamic>.from(jsonDecode(json) as Map));

  Map<String, dynamic> toJson() => {
        'code': code,
        if (level != null) 'level': level,
        'source': source,
        'questions': [for (final q in questions) q.toJson()],
      };

  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());

  /// The questions of one worksheet as a truth file (**Download text**).
  /// The question number is the worksheet order.
  factory PaperTruth.fromWorksheet(
    List<QuestionBankItem> items, {
    String code = '',
    int? level,
  }) {
    final sorted = [...items]..sort((a, b) =>
        (a.sheetIndex ?? 1 << 30).compareTo(b.sheetIndex ?? 1 << 30));
    return PaperTruth(
      code: code,
      level: level,
      source: 'worksheet ${sorted.isEmpty ? '' : sorted.first.sheetCode ?? ''}'
          .trim(),
      questions: [
        for (var i = 0; i < sorted.length; i++) _fromItem(i + 1, sorted[i]),
      ],
    );
  }

  static PaperTruthQuestion _fromItem(int number, QuestionBankItem item) {
    final q = item.question;
    final skill = switch (item.skillCategory?.value) {
      'listening' => 'listening',
      'typing' || 'writing' => 'writing',
      _ => item.type == ExerciseType.listening ? 'listening' : 'reading',
    };
    // The importer stores "第N题" when a question has no printed text.
    final prompt = q.prompt == '第$number题' ? '' : q.prompt;
    final letters = [
      for (var i = 0; i < q.options.length; i++) String.fromCharCode(65 + i),
    ];
    final isPicture = q.optionImageUrls.any((u) => u.isNotEmpty) ||
        (q.options.length >= 2 && q.options.join() == letters.join());
    final form = switch (item.type) {
      ExerciseType.composeSentences => HskForm.reorder,
      ExerciseType.typeHanzi => HskForm.pinyinChar,
      ExerciseType.pictureSentence => HskForm.sentenceWithWord,
      ExerciseType.readingCloze => HskForm.wordBank,
      ExerciseType.matching => HskForm.matching,
      _ when isPicture => HskForm.picture,
      _ when q.options.join() ==
              QuestionImportUtils.trueFalseOptions.join() =>
        HskForm.trueFalse,
      _ => HskForm.choice,
    };
    return PaperTruthQuestion(
      number: number,
      form: form,
      skill: skill,
      section: item.section ?? '',
      prompt: form == HskForm.picture ? '' : prompt,
      options: form == HskForm.picture || form == HskForm.trueFalse
          ? const []
          : q.options,
      segments: q.segments,
      keyword: q.keyword,
      pictures: form == HskForm.picture ? q.options.length : 0,
    );
  }
}

/// How one question compares with the truth.
class PaperQuestionCheck {
  const PaperQuestionCheck({
    required this.number,
    required this.right,
    required this.flagged,
    this.wrong = const [],
  });

  final int number;
  final bool right;
  final bool flagged;

  /// What differs: `missing`, `form`, `prompt`, `options`, `segments`,
  /// `keyword`, `pictures`.
  final List<String> wrong;
}

/// The reader measured against a truth (the number for docs/PLAN.md §6).
class PaperMeasure {
  const PaperMeasure(this.checks, {this.seconds});

  final List<PaperQuestionCheck> checks;
  final double? seconds;

  int get total => checks.length;
  int get right => checks.where((c) => c.right).length;
  int get flagged => checks.where((c) => c.flagged).length;
  int get wrongFlagged => checks.where((c) => !c.right && c.flagged).length;

  /// The ones that count against the reader: wrong and nothing says so.
  int get wrongNotFlagged => checks.where((c) => !c.right && !c.flagged).length;
  int get rightButFlagged => checks.where((c) => c.right && c.flagged).length;

  String summary() => '$right of $total right as read · $flagged flagged · '
      '$wrongNotFlagged wrong and not flagged'
      '${seconds == null ? '' : ' · ${seconds!.toStringAsFixed(1)} s'}';

  /// Compares a draft with the truth, question by question.
  /// [checkPictures]: also require the number of pictures (only when the
  /// draft came from page images, not from text alone).
  static PaperMeasure compare(
    HskPaperDraft draft,
    PaperTruth truth, {
    bool checkPictures = true,
    double? seconds,
  }) {
    final slotOf = {for (final s in draft.slots) s.number: s};
    return PaperMeasure([
      for (final t in truth.questions)
        _check(t, slotOf[t.number], checkPictures),
    ], seconds: seconds);
  }

  static PaperQuestionCheck _check(
      PaperTruthQuestion t, HskSlot? s, bool checkPictures) {
    if (s == null) {
      return PaperQuestionCheck(
          number: t.number, right: false, flagged: true, wrong: const ['missing']);
    }
    final wrong = <String>[];
    if (s.missing) wrong.add('missing');
    if (s.form != t.form) wrong.add('form');
    switch (t.form) {
      case HskForm.picture:
        if (checkPictures && t.pictures > 0 && s.pictures.length != t.pictures) {
          wrong.add('pictures');
        }
      case HskForm.reorder:
        if (!_sameBag(s.segments, t.segments)) wrong.add('segments');
      case HskForm.pinyinChar:
        if (norm(s.prompt) != norm(t.prompt)) wrong.add('prompt');
        if (normPinyin(s.keyword) != normPinyin(t.keyword)) wrong.add('keyword');
      default:
        if (norm(s.prompt) != norm(t.prompt)) wrong.add('prompt');
        if (t.options.isNotEmpty && !_sameList(s.options, t.options)) {
          wrong.add('options');
        }
    }
    return PaperQuestionCheck(
      number: t.number,
      right: wrong.isEmpty,
      flagged: s.flagged,
      wrong: wrong,
    );
  }

  static const _halfToFull = {
    ',': '，', '?': '？', '!': '！', ':': '：', ';': '；',
    '(': '（', ')': '）',
  };

  /// Text as a reader of the paper sees it: no spaces or line breaks,
  /// Western punctuation as Chinese, no empty answer bracket at the end.
  static String norm(String s) {
    var out = s.replaceAll(RegExp(r'\s+'), '');
    _halfToFull.forEach((a, b) => out = out.replaceAll(a, b));
    return out.replaceFirst(RegExp(r'（）$'), '');
  }

  static String normPinyin(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (norm(a[i]) != norm(b[i])) return false;
    }
    return true;
  }

  static bool _sameBag(List<String> a, List<String> b) {
    final x = [for (final s in a) norm(s)]..sort();
    final y = [for (final s in b) norm(s)]..sort();
    return x.join('|') == y.join('|');
  }
}
