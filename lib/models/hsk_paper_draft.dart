import '../services/hsk_paper/paper_image_ops.dart';
import 'ai_worksheet.dart';

/// Forms of a question on an HSK paper; the same names the AI reader uses
/// ([AiQuestion.type]), so a draft saves through the same path.
abstract final class HskForm {
  static const picture = 'picture_choice';
  static const trueFalse = 'true_false';
  static const choice = 'choice';
  static const matching = 'matching';
  static const wordBank = 'cloze';
  static const reorder = 'reorder';
  static const pinyinChar = 'write_hanzi';
  static const sentenceWithWord = 'sentence_with_word';

  static const all = [
    picture,
    trueFalse,
    choice,
    matching,
    wordBank,
    reorder,
    pinyinChar,
    sentenceWithWord,
  ];
}

/// One question slot of a paper being proofread. Every number the format
/// expects has a slot, also when the reader found nothing for it.
class HskSlot {
  HskSlot({
    required this.number,
    required this.skill,
    this.section = '',
    this.form = HskForm.choice,
    this.page = 0,
    this.prompt = '',
    List<String>? options,
    List<String>? segments,
    this.keyword = '',
    List<String>? accepted,
    List<PixelBox>? pictures,
    this.picturePage = 0,
    this.missing = false,
    this.unsure = false,
    this.optionsIncomplete = false,
  })  : options = options ?? [],
        segments = segments ?? [],
        accepted = accepted ?? [],
        pictures = pictures ?? [];

  final int number;

  /// `listening`, `reading` or `writing`.
  String skill;

  /// Printed heading, e.g. `一、听力 · 第一部分 · 第1-5题`.
  String section;
  String form;

  /// 1-based page the question was read from (0 = not found).
  int page;
  String prompt;
  List<String> options;
  List<String> segments;

  /// Pinyin of a character gap, or the word to use in a sentence.
  String keyword;
  List<String> accepted;

  /// Picture choices (A, B, C…) on [picturePage], in pixels of that page.
  List<PixelBox> pictures;
  int picturePage;

  /// The reader found no line for this number: type it.
  bool missing;

  /// The printed number was misread; the slot was placed by its order.
  bool unsure;

  /// A shared list had a letter the reader could not read.
  bool optionsIncomplete;

  /// The admin pressed "Looks right": a [doubt] no longer flags the slot.
  bool checked = false;

  static final _cjk = RegExp(r'[㐀-鿿]');
  static final _toneMark = RegExp(r'[āáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜ]');

  /// What looks wrong in what the reader made of this slot, measured on
  /// H326202Z (docs/PLAN.md §6): [doubtOptions] a text choice with no
  /// Chinese character (`H#EXLT`), [doubtTones] pinyin with no tone mark
  /// (the engine drops them), [doubtSplit] words to order that came out
  /// mostly as single characters. Null when nothing does.
  String? get doubt {
    if ((form == HskForm.choice ||
            form == HskForm.matching ||
            form == HskForm.wordBank) &&
        options.any((o) => o.trim().isNotEmpty && !_cjk.hasMatch(o))) {
      return doubtOptions;
    }
    if (form == HskForm.pinyinChar &&
        keyword.trim().isNotEmpty &&
        !_toneMark.hasMatch(keyword)) {
      return doubtTones;
    }
    if (form == HskForm.reorder && segments.length >= 4) {
      final singles = segments.where((s) => s.runes.length == 1).length;
      if (singles / segments.length >= 0.6) return doubtSplit;
    }
    return null;
  }

  static const doubtOptions = 'options';
  static const doubtTones = 'tones';
  static const doubtSplit = 'split';

  /// Needs the admin's eye before saving.
  bool get flagged =>
      missing ||
      unsure ||
      optionsIncomplete ||
      (!checked && doubt != null) ||
      (form == HskForm.picture && pictures.length < 2) ||
      (form == HskForm.reorder && segments.length < 2) ||
      (form == HskForm.pinyinChar && keyword.trim().isEmpty) ||
      ((form == HskForm.choice ||
              form == HskForm.matching ||
              form == HskForm.wordBank) &&
          options.where((o) => o.trim().isNotEmpty).length < 2);
}

/// What the built-in reader made of one paper.
class HskPaperDraft {
  HskPaperDraft({
    this.code = '',
    this.level,
    this.title = '',
    required this.slots,
    Map<String, int>? expected,
  }) : expected = expected ?? {};

  String code;
  int? level;
  String title;
  final List<HskSlot> slots;

  /// Questions per skill the format expects (`listening` → 40).
  final Map<String, int> expected;

  int countFor(String skill) => slots.where((s) => s.skill == skill).length;

  List<int> get missingNumbers =>
      [for (final s in slots) if (s.missing) s.number];

  List<HskSlot> get flagged => [for (final s in slots) if (s.flagged) s];

  /// The draft in the AI reader's shape, so saving reuses
  /// `QuestionBankAiImportUtils` (one worksheet, pictures cut from the
  /// pages). [pageSizes] maps a page to its pixel size (boxes become
  /// thousandths of the page).
  AiWorksheet toAiWorksheet(Map<int, (int width, int height)> pageSizes) {
    AiBox? box(int page, PixelBox b) {
      final size = pageSizes[page];
      if (size == null) return null;
      final (w, h) = size;
      int t(int v, int of) => (v * 1000 / of).round().clamp(0, 1000);
      final out = AiBox(
        page: page,
        ymin: t(b.y0, h),
        xmin: t(b.x0, w),
        ymax: t(b.y1, h),
        xmax: t(b.x1, w),
      );
      return out.isValid ? out : null;
    }

    final sections = <AiSection>[];
    for (final slot in slots) {
      final question = AiQuestion(
        number: slot.number,
        type: slot.form,
        page: slot.page < 1 ? 1 : slot.page,
        prompt: slot.prompt.trim(),
        options: [for (final o in slot.options) o.trim()],
        segments: [
          for (final s in slot.segments)
            if (s.trim().isNotEmpty) s.trim(),
        ],
        keyword: slot.keyword.trim(),
        accepted: [
          for (final a in slot.accepted)
            if (a.trim().isNotEmpty) a.trim(),
        ],
        optionImageBoxes: [
          for (final b in slot.pictures)
            if (box(slot.picturePage, b) case final x?) x,
        ],
      );
      final last = sections.isEmpty ? null : sections.last;
      if (last != null &&
          last.title == slot.section &&
          last.skill == slot.skill) {
        sections[sections.length - 1] = AiSection(
          title: last.title,
          skill: last.skill,
          questions: [...last.questions, question],
        );
      } else {
        sections.add(AiSection(
          title: slot.section,
          skill: slot.skill,
          questions: [question],
        ));
      }
    }
    return AiWorksheet(
      title: title,
      code: code,
      hskLevel: level,
      category: 'hsk_simulation',
      sections: sections,
    );
  }
}
