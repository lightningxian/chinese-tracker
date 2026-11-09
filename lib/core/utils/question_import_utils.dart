import '../../models/exercise_skill_category.dart';
import '../../models/exercise_type.dart';
import 'worksheet_text_normalizer.dart';

class ParsedMcQuestion {
  const ParsedMcQuestion({
    required this.prompt,
    this.options = const [],
    this.correctIndex = 0,
    this.keyword = '',
  });

  final String prompt;

  /// Choices; for "type the hanzi" the accepted answers (empty until the
  /// admin fills them in).
  final List<String> options;
  final int correctIndex;

  /// Pinyin hint (type the hanzi) or the required word (picture sentence).
  final String keyword;
}

class ParsedComposeQuestion {
  const ParsedComposeQuestion({
    this.prompt = '',
    required this.segments,
  });

  final String prompt;
  final List<String> segments;
}

class ParsedMatchingQuestion {
  const ParsedMatchingQuestion({
    required this.prompt,
    this.correctIndex = 0,
  });

  final String prompt;
  final int correctIndex;
}

class WorksheetParseResult {
  const WorksheetParseResult({
    this.instructions = '',
    this.suggestedLevel,
    required this.suggestedType,
    required this.detectionSummary,
    this.mcQuestions = const [],
    this.composeQuestions = const [],
    this.matchingOptions = const [],
    this.matchingQuestions = const [],
    this.passage = '',
    this.suggestedSkill,
    this.suggestedTitle,
    this.sheetCode,
  });

  final String instructions;
  final String? suggestedLevel;

  /// The centre's file code at the top of the sheet, e.g. `310001-RDG`.
  final String? sheetCode;

  /// From the centre's file code (`320001-WRT` → typing) or the type.
  final ExerciseSkillCategory? suggestedSkill;

  /// The worksheet heading, e.g. "SOAL LATIHAN HSK 2 (A)".
  final String? suggestedTitle;
  final ExerciseType suggestedType;
  final String detectionSummary;
  final List<ParsedMcQuestion> mcQuestions;
  final List<ParsedComposeQuestion> composeQuestions;

  /// Shared answer bank: matching letters A–F, or the word bank of a
  /// fill-in-the-blank (reading cloze) worksheet.
  final List<String> matchingOptions;
  final List<ParsedMatchingQuestion> matchingQuestions;

  /// Reading-comprehension text that precedes the questions (R3).
  final String passage;

  WorksheetParseResult copyWith({
    String? instructions,
    ExerciseType? suggestedType,
    List<ParsedMcQuestion>? mcQuestions,
    List<ParsedComposeQuestion>? composeQuestions,
    List<String>? matchingOptions,
    List<ParsedMatchingQuestion>? matchingQuestions,
  }) {
    return WorksheetParseResult(
      instructions: instructions ?? this.instructions,
      suggestedLevel: suggestedLevel,
      suggestedType: suggestedType ?? this.suggestedType,
      detectionSummary: detectionSummary,
      mcQuestions: mcQuestions ?? this.mcQuestions,
      composeQuestions: composeQuestions ?? this.composeQuestions,
      matchingOptions: matchingOptions ?? this.matchingOptions,
      matchingQuestions: matchingQuestions ?? this.matchingQuestions,
      passage: passage,
      suggestedSkill: suggestedSkill,
      suggestedTitle: suggestedTitle,
      sheetCode: sheetCode,
    );
  }

  static int countFor(
    ExerciseType type, {
    required int mc,
    required int compose,
    required int bank,
  }) {
    switch (type) {
      case ExerciseType.composeSentences:
        return compose;
      case ExerciseType.matching:
      case ExerciseType.readingCloze:
        return bank;
      case ExerciseType.pictureSentence:
      case ExerciseType.typeHanzi:
      case ExerciseType.multipleChoice:
      case ExerciseType.listening:
        return mc;
    }
  }

  int get questionCount => countFor(
        suggestedType,
        mc: mcQuestions.length,
        compose: composeQuestions.length,
        bank: matchingQuestions.length,
      );

  bool get canImport => suggestedType.isImplemented && hasQuestions;

  bool get hasQuestions => questionCount > 0;

  factory WorksheetParseResult.empty() {
    return const WorksheetParseResult(
      suggestedType: ExerciseType.multipleChoice,
      detectionSummary: 'No worksheet content detected.',
    );
  }
}

abstract final class QuestionImportUtils {
  static final _numberedLine = RegExp(
    r'^\s*(?:\d+|[Qq]uestion\s*\d+)\s*[\.\)、:：\-]\s*(.*)$',
  );
  static final _numberedOnly = RegExp(r'^\s*(\d+)\s*[\.\)、:：\-]?\s*$');
  static final _optionLine = RegExp(
    r'^\s*(?:\(([A-Da-d])\)|([A-Da-d])[\.\):\-]|([A-D])(?=\s+[\u4e00-\u9fff（(]))\s*(.+?)(?:\s*[\*✓√])?\s*$',
  );
  static final _inlineOptionMarker = RegExp(r'(?:^|\s)([A-D])\s+(?=\S)');
  static final _rangeHeader = RegExp(r'^\s*(\d+)\s*[-–]\s*(\d+)\s*[\.．]?\s*$');
  static final _starLine = RegExp(r'^[★☆]\s*(.+?)\s*(?:[（(]\s*[)）])?\s*$');
  static final _pinyinHint = RegExp(
    r'[（(]\s*([a-zA-Züāáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜ\u0300-\u036f][a-zA-Züāáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜ\u0300-\u036f\s]{0,20})\s*[)）]',
  );
  static final _pictureLine = RegExp(
    r'^\s*\d{1,2}[\.．、]\s*([\u4e00-\u9fff]{1,6})\s*[：:]\s*[—_\-–－]*\s*$',
  );
  static final _codeHeader = RegExp(r'^\s*(\d)\d{5,6}-(RDG|KLM|WRT|CRT|KK)\b');
  // A blank drawn as a line (not in the text) leaves a gap inside the
  // sentence: `全新的 。`, or a sentence starting with a comma.
  static final _impliedBlank =
      RegExp(r'(?<=[\u4e00-\u9fff，,])\s+(?=[\u4e00-\u9fff。，])');
  static final _exampleLine = RegExp(r'^\s*(例如|e\.g\.)', caseSensitive: false);
  static final _underscoresOnly = RegExp(r'^[_＿\s]+$');
  static final _correctMarker = RegExp(r'[\*✓√]\s*$|\(correct\)', caseSensitive: false);
  static final _instructionHeader = RegExp(
    r'^(?:instructions?|directions?)\s*[:：]\s*(.*)$',
    caseSensitive: false,
  );
  static final _composeKeywords = RegExp(
    r'(组词成句|连词成句|组句|menyusun\s*kalimat|\b(arrange|reorder|compose|unscramble|jumble|put.+in.+order)\b)',
    caseSensitive: false,
  );
  static final _hskLevel = RegExp(r'HSK\s*(\d)', caseSensitive: false);
  static final _noiseLine = RegExp(
    r'^(?:[\-_=。.·•]+|'
    r'\d{1,2}|'
    r'\d{6}-[A-Z]+|'
    r'easy\s*study|'
    r'\d{1,2}\s+(?:january|february|march|april|may|june|july|august|september|october|november|december)(?:\s+\d{4})?(?:\s+\d{1,2})?)'
    r'$',
    caseSensitive: false,
  );
  static final _mcKeywords = RegExp(
    r'\b(choose|select|circle|multiple\s*choice|which\s+one|correct\s+answer)\b',
    caseSensitive: false,
  );
  static final _matchingBankLine = RegExp(r'^\s*([A-Fa-f])\.\s*(.+)$');
  static final _matchingPromptLine = RegExp(
    r'^\s*(?:例如|e\.g\.)\s*[:：]?\s*(.+?)[\s\(（]+([A-Fa-f])[\)）]?',
    caseSensitive: false,
  );
  static final _matchingKeywords = RegExp(
    r'(latihan\s*soal|对话配对|选择正确的|例如|part\s*\d)',
    caseSensitive: false,
  );
  static final _clozeKeywords = RegExp(
    r'(isilah\s+dengan\s+kata|kata\s+yang\s+tepat|melengkapi\s+kalimat|lengkapi|'
    r'选词填空|选词|填写|填入|填空|完成句子|词组)',
    caseSensitive: false,
  );
  static final _pictureKeywords = RegExp(
    r'(buatlah\s+kalimat|gambar\s+yang\s+tersedia|看图写|根据图片)',
    caseSensitive: false,
  );
  static final _bracketSegment = RegExp(r'\[([^\]]+)\]');
  static final _orderKeywords = RegExp(
    r'(句子排序|排列顺序|排序|排列成|组成一段话|连成一段|urutkan|susunlah\s+kalimat.{0,20}paragraf|'
    r'order\s+the\s+sentences|put\s+the\s+sentences|correct\s+order\s+of\s+the\s+sentences)',
    caseSensitive: false,
  );
  static final _trueFalseKeywords = RegExp(
    r'(判断对错|判断正误|判断题|对错|正误|√\s*×|benar\s*(?:atau|/)\s*salah|true\s*(?:or|/)\s*false)',
    caseSensitive: false,
  );
  static final _comprehensionKeywords = RegExp(
    r'(阅读理解|根据短文|阅读短文|阅读下面|短文|bacalah|teks\s+berikut|bacaan|'
    r'reading\s+comprehension|read\s+the\s+(?:text|passage|story))',
    caseSensitive: false,
  );
  static final _listeningKeywords = RegExp(
    r'(听力|听录音|听对话|听短文|dengarkan|rekaman|listen\s+to)',
    caseSensitive: false,
  );
  static final _blankMarker = RegExp(
    r'（\s*[A-Fa-f]?\s*）|\(\s*[A-Fa-f]?\s*\)|_{2,}|＿{2,}|\[\s*\]|【\s*】|（\s*[\u4e00-\u9fff]{1,4}\s*）',
  );
  static final _letteredSentence = RegExp(
    r'^\s*[（(]?([A-Fa-f])[)）\.、．:：]?\s+(.{3,})$',
  );
  static final _circledSentence = RegExp(r'^\s*([①②③④⑤⑥⑦⑧])\s*(.{3,})$');
  static final _orderKeyLine = RegExp(
    r'^(?:答案|正确顺序|顺序|jawaban|urutan|answer|key)?\s*[:：]?\s*'
    r'((?:[A-Fa-f①-⑧]\s*[-–→,，、>]?\s*){2,})$',
    caseSensitive: false,
  );
  static final _tfBracketMark = RegExp(
    r'[（(]\s*(√|✓|✔|×|✗|✘|对|错|T|F|B|S|True|False|Benar|Salah)\s*[)）]\s*$',
    caseSensitive: false,
  );
  static final _tfSymbolMark = RegExp(r'\s*([√✓✔×✗✘])\s*$');
  static final _tfWordMark = RegExp(
    r'\s+(对|错|True|False|Benar|Salah)\s*$',
    caseSensitive: false,
  );
  static const _tfTrue = {'√', '✓', '✔', '对', 'T', 'B', 'TRUE', 'BENAR'};
  static const trueFalseOptions = ['对 (True)', '错 (False)'];

  /// Non-empty lines from OCR or pasted text.
  static List<String> linesFromText(String text) {
    return text
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  /// Parse uploaded worksheet text into instructions, question type, and questions.
  ///
  /// Recognised forms (thesis codes): multiple choice, R1 fill in the blank
  /// (word bank → `readingCloze`), R2 matching, R3 reading comprehension
  /// (passage + multiple choice), R4 order sentences (→ `composeSentences`),
  /// true/false (P1/L2 → multiple choice 对/错), L3 listening (multiple choice
  /// under the listening type; audio is attached later).
  static WorksheetParseResult parseWorksheet(String text) {
    final normalized =
        WorksheetTextNormalizer.normalize(text.replaceAll('\r\n', '\n')).trim();
    if (normalized.isEmpty) return WorksheetParseResult.empty();

    final rawLines = normalized.split('\n').map((line) => line.trim()).toList();
    final code = _readCode(rawLines);
    final (rawInstructions, splitContent) = _splitInstructions(rawLines);
    final contentLines = _mergeContinuations(
      _attachRangePassages(
        _explodeInlineOptions(
          splitContent
              .where((line) => !_isNoiseLine(line) && !_exampleLine.hasMatch(line))
              .toList(),
        ),
      ),
    );
    final filteredLines = contentLines;
    final keywordText = '$rawInstructions\n$normalized';
    final level = extractHskLevel(normalized) ?? code?.level;
    final typing = _parseTypeHanzi(filteredLines);
    final pictures = _parsePictureKeywords(filteredLines);
    final starTrueFalse = _parseStarTrueFalse(filteredLines);

    final (instructions, passage) = _splitPassage(
      rawInstructions,
      filteredLines,
      keywordText,
    );

    final mcQuestions = _parseMcQuestions(filteredLines);
    final composeQuestions = _parseComposeQuestions(filteredLines);
    final matching = _parseMatching(filteredLines);
    final allLines = rawLines.where((line) => !_isNoiseLine(line)).toList();
    final cloze = _parseCloze(
      filteredLines,
      bankSource: allLines,
      // A gap drawn as a line only counts as a blank on a sheet that asks
      // for words to be filled in; spaced words elsewhere are not blanks.
      impliedBlanks: _clozeKeywords.hasMatch(keywordText),
    );
    final orderingAny = _parseOrdering(filteredLines);
    final orderingBare = _parseOrdering(filteredLines, bareOnly: true);
    final trueFalse = _parseTrueFalse(filteredLines);
    final isTyping = typing.length >= 2;
    final isPicture = pictures.length >= 3 ||
        (_pictureKeywords.hasMatch(keywordText) && pictures.isNotEmpty);
    final isStarTrueFalse = starTrueFalse.length >= 2;

    final hasLetteredOptions =
        filteredLines.any((line) => _matchOption(line) != null);
    final isTrueFalse = trueFalse.isNotEmpty &&
        (_trueFalseKeywords.hasMatch(keywordText) ||
            (!hasLetteredOptions && trueFalse.where((q) => q.marked).length >= 2));
    final isListening = _listeningKeywords.hasMatch(keywordText);
    final isCloze = !isTyping &&
        cloze.prompts.isNotEmpty &&
        (_clozeKeywords.hasMatch(keywordText) || cloze.prompts.length >= 2);
    // Several word lists (one per group of blanks), or one list too long
    // for a shared A–H bank: each blank becomes a choice question with its
    // own group's words.
    final clozeAsChoices = isCloze &&
        (cloze.banks.length >= 2 || cloze.options.length > 8);
    // Without an ordering keyword, only bare "1." groups of 3+ sentences
    // count, so multiple-choice items with long options are not mistaken.
    final orderingKeyword = _orderKeywords.hasMatch(keywordText);
    final ordering = orderingKeyword ? orderingAny : orderingBare;
    final isOrdering = ordering.isNotEmpty &&
        (orderingKeyword ||
            (ordering.length >= 2 &&
                ordering.every((q) => q.segments.length >= 3)));
    final structuredMc = mcQuestions.where((q) => q.options.length >= 2).length;
    final isComprehension = passage.isNotEmpty && structuredMc > 0;

    ExerciseType type;
    String form;
    if (isTyping) {
      type = ExerciseType.typeHanzi;
      form = 'T2 type the hanzi for the pinyin (写汉字)';
    } else if (isPicture) {
      type = ExerciseType.pictureSentence;
      form = 'T5 picture + keyword sentence (看图写句子)';
    } else if (isStarTrueFalse) {
      type = ExerciseType.multipleChoice;
      form = 'true/false with ★ statements (判断对错)';
    } else if (isListening) {
      type = ExerciseType.listening;
      form = isTrueFalse ? 'L2 listening true/false' : 'L3 listening';
    } else if (clozeAsChoices) {
      type = ExerciseType.multipleChoice;
      form = 'R1 fill in the blank, ${cloze.banks.length} word list'
          '${cloze.banks.length == 1 ? '' : 's'} (选词填空)';
    } else if (isTrueFalse) {
      type = ExerciseType.multipleChoice;
      form = 'true/false (判断对错)';
    } else if (!isCloze &&
        !isOrdering &&
        _pictureKeywords.hasMatch(keywordText)) {
      type = ExerciseType.pictureSentence;
      form = 'picture + keyword sentence';
    } else if (isCloze) {
      type = ExerciseType.readingCloze;
      form = 'R1 fill in the blank (选词填空)';
    } else if (isOrdering) {
      type = ExerciseType.composeSentences;
      form = 'R4 order the sentences (句子排序)';
    } else if (isComprehension) {
      type = ExerciseType.multipleChoice;
      form = 'R3 reading comprehension (阅读理解)';
    } else {
      type = _suggestType(
        mcQuestions,
        composeQuestions,
        matching,
        filteredLines,
        rawInstructions,
        normalized,
      );
      form = switch (type) {
        ExerciseType.matching => 'R2 matching (对话配对)',
        ExerciseType.composeSentences => 'T4 compose sentences (组词成句)',
        ExerciseType.readingCloze => 'R1 fill in the blank (选词填空)',
        ExerciseType.pictureSentence => 'picture + keyword sentence',
        ExerciseType.typeHanzi => 'T2 type the hanzi (写汉字)',
        ExerciseType.listening => 'L3 listening',
        ExerciseType.multipleChoice => 'multiple choice',
      };
    }

    // A passage only makes sense above choice questions; for other forms
    // keep the text with the instructions so nothing is lost.
    final keepsPassage = type == ExerciseType.multipleChoice ||
        type == ExerciseType.listening ||
        type == ExerciseType.readingCloze;
    var finalInstructions = keepsPassage || passage.isEmpty
        ? instructions
        : [instructions, passage].where((t) => t.isNotEmpty).join('\n');
    if (isCloze && cloze.bankLine != null) {
      // The word bank is data, not an instruction.
      finalInstructions = finalInstructions
          .split('\n')
          .where((line) => line.trim() != cloze.bankLine)
          .join('\n')
          .trim();
    }
    final finalPassage = keepsPassage ? passage : '';

    final finalMc = isTyping
        ? typing
        : isPicture
            ? pictures
            : isStarTrueFalse
                ? starTrueFalse.map((q) => q.question).toList()
                : clozeAsChoices
                    ? _clozeAsChoices(cloze)
                    : isTrueFalse
                        ? trueFalse.map((q) => q.question).toList()
                        : mcQuestions;
    final finalCompose = isOrdering ? ordering : composeQuestions;
    final bankOptions =
        isCloze && !clozeAsChoices ? cloze.options : matching.options;
    final bankPrompts =
        isCloze && !clozeAsChoices ? cloze.prompts : matching.prompts;
    final skill = code?.skill ?? ExerciseSkillCategory.forExerciseType(type);
    final title = _readTitle(rawLines);

    final result = WorksheetParseResult(
      instructions: finalInstructions,
      suggestedLevel: level,
      suggestedType: type,
      detectionSummary: '',
      mcQuestions: finalMc,
      composeQuestions: finalCompose,
      matchingOptions: bankOptions,
      matchingQuestions: bankPrompts,
      passage: finalPassage,
      suggestedSkill: skill,
      suggestedTitle: title,
      sheetCode: code?.code,
    );
    return WorksheetParseResult(
      instructions: result.instructions,
      suggestedLevel: level,
      suggestedType: type,
      detectionSummary: _summary(
        result,
        form,
        unmarkedTrueFalse: isStarTrueFalse
            ? starTrueFalse.where((q) => !q.marked).length
            : isTrueFalse
                ? trueFalse.where((q) => !q.marked).length
                : 0,
        unmarkedBlanks: isCloze
            ? (clozeAsChoices ? cloze.prompts.length : cloze.unmarked)
            : 0,
        unorderedGroups: isOrdering
            ? ordering.where((q) => q.prompt.contains('(order not')).length
            : 0,
        sections: RegExp(r'part\s*2|第二部分', caseSensitive: false)
            .hasMatch(normalized),
      ),
      mcQuestions: finalMc,
      composeQuestions: finalCompose,
      matchingOptions: bankOptions,
      matchingQuestions: bankPrompts,
      passage: finalPassage,
      suggestedSkill: skill,
      suggestedTitle: title,
      sheetCode: code?.code,
    );
  }

  /// The centre's file code at the top of each sheet: first digit = HSK
  /// level, suffix = section (RDG reading, CRT exam reading, KK vocabulary,
  /// KLM sentences, WRT writing).
  static ({String code, String level, ExerciseSkillCategory skill})? _readCode(
    List<String> lines,
  ) {
    for (final line in lines.take(6)) {
      final m = _codeHeader.firstMatch(line);
      if (m == null) continue;
      final skill = switch (m.group(2)) {
        'KLM' || 'WRT' => ExerciseSkillCategory.typing,
        _ => ExerciseSkillCategory.reading,
      };
      return (code: m.group(0)!.trim(), level: 'HSK ${m.group(1)}', skill: skill);
    }
    return null;
  }

  static String? _readTitle(List<String> lines) {
    for (final line in lines.take(8)) {
      if (_isNoiseLine(line) || _codeHeader.hasMatch(line)) continue;
      final t = line.trim();
      if (t.runes.length < 6 || t.runes.length > 60) continue;
      if (RegExp(r'HSK|LATIHAN|Soal|题|练习|Isilah|Buatlah|Menyusun',
              caseSensitive: false)
          .hasMatch(t)) {
        return t;
      }
    }
    return null;
  }

  /// `A 不是南方人 B 会说南方话 C 今天搬到南方` (and `46. A 繁荣 B 单调 …`)
  /// become one option per line so the choice parser can read them.
  static List<String> _explodeInlineOptions(List<String> lines) {
    final out = <String>[];
    for (final line in lines) {
      final marks = _inlineOptionMarker.allMatches(line).toList();
      // Letters must run in order (A, B, C…), starting at A or at the
      // start of the line (a wrapped `C … D …` continuation).
      var ok = marks.length >= 2 &&
          (marks.first.group(1) == 'A' || marks.first.start == 0);
      for (var i = 1; ok && i < marks.length; i++) {
        if (marks[i].group(1)!.codeUnitAt(0) !=
            marks[i - 1].group(1)!.codeUnitAt(0) + 1) {
          ok = false;
        }
      }
      if (!ok) {
        out.add(line);
        continue;
      }
      final head = line.substring(0, marks.first.start).trim();
      if (head.isNotEmpty) out.add(head);
      for (var i = 0; i < marks.length; i++) {
        final start = marks[i].start;
        final end = i + 1 < marks.length ? marks[i + 1].start : line.length;
        final piece = line.substring(start, end).trim();
        if (piece.isNotEmpty) out.add(piece);
      }
    }
    return out;
  }

  /// `46-48.` followed by a passage with numbered gaps, then `46.` option
  /// groups: the passage is attached to each of its questions.
  static List<String> _attachRangePassages(List<String> lines) {
    final out = <String>[];
    var i = 0;
    while (i < lines.length) {
      final header = _rangeHeader.firstMatch(lines[i]);
      if (header == null) {
        out.add(lines[i]);
        i++;
        continue;
      }
      final from = int.parse(header.group(1)!);
      final to = int.parse(header.group(2)!);
      final passage = <String>[];
      var j = i + 1;
      while (j < lines.length &&
          !_looksLikeQuestionStart(lines[j]) &&
          _matchOption(lines[j]) == null &&
          _rangeHeader.firstMatch(lines[j]) == null) {
        passage.add(lines[j]);
        j++;
      }
      final text = passage.join('');
      while (j < lines.length && _rangeHeader.firstMatch(lines[j]) == null) {
        final line = lines[j];
        final q = _numberedLine.firstMatch(line);
        final n = q == null ? null : int.tryParse(RegExp(r'\d+').firstMatch(line)!.group(0)!);
        if (q != null && n != null && n >= from && n <= to) {
          final rest = (q.group(1) ?? '').trim();
          out.add('$n. $text （$n）${rest.isEmpty ? '' : ' $rest'}');
        } else {
          out.add(line);
        }
        j++;
      }
      i = j;
    }
    return out;
  }

  /// A wrapped sentence continues the numbered line above it.
  static List<String> _mergeContinuations(List<String> lines) {
    final out = <String>[];
    var lastWasQuestion = false;
    for (final line in lines) {
      final isQuestion = _looksLikeQuestionStart(line) && !_numberedOnly.hasMatch(line);
      final standalone = _numberedOnly.hasMatch(line) ||
          _matchOption(line) != null ||
          _starLine.hasMatch(line) ||
          _looksLikeMatchingBankLine(line) ||
          _isCjkWordBank(line) ||
          _underscoresOnly.hasMatch(line) ||
          _rangeHeader.hasMatch(line) ||
          _looksLikeComposeLine(line);
      if (!isQuestion && !standalone && lastWasQuestion && out.isNotEmpty) {
        out[out.length - 1] = '${out.last} $line';
        continue;
      }
      out.add(line);
      lastWasQuestion = isQuestion;
    }
    return out;
  }

  /// True/false sheets: `1. text…` then `★ statement （ ）`.
  static List<({ParsedMcQuestion question, bool marked})> _parseStarTrueFalse(
    List<String> lines,
  ) {
    final out = <({ParsedMcQuestion question, bool marked})>[];
    String? context;
    for (final line in lines) {
      final star = _starLine.firstMatch(line);
      if (star != null) {
        var statement = star.group(1)!.trim();
        String? mark;
        for (final re in [_tfBracketMark, _tfSymbolMark, _tfWordMark]) {
          final m = re.firstMatch(statement);
          if (m != null) {
            mark = m.group(1)!.toUpperCase();
            statement = statement.substring(0, m.start).trim();
            break;
          }
        }
        statement = statement.replaceAll(RegExp(r'[（(]\s*[)）]\s*$'), '').trim();
        final prompt = context == null || context.isEmpty
            ? '★ $statement'
            : '$context\n★ $statement';
        out.add((
          question: ParsedMcQuestion(
            prompt: prompt,
            options: trueFalseOptions,
            correctIndex: mark == null || _tfTrue.contains(mark) ? 0 : 1,
          ),
          marked: mark != null,
        ));
        context = null;
        continue;
      }
      if (_looksLikeQuestionStart(line)) {
        context = _stripNumberedPrefix(line);
      } else if (context != null) {
        context = '$context $line';
      }
    }
    return out;
  }

  /// `1. 我（gāng）才…`: the student types the character for the pinyin.
  static List<ParsedMcQuestion> _parseTypeHanzi(List<String> lines) {
    final out = <ParsedMcQuestion>[];
    for (final line in lines) {
      if (!_looksLikeQuestionStart(line)) continue;
      final stripped = _stripNumberedPrefix(line);
      final hint = _pinyinHint.firstMatch(stripped);
      if (hint == null) continue;
      final pinyin = hint.group(1)!.trim();
      if (!pinyin
          .split(RegExp(r'\s+'))
          .every(WorksheetTextNormalizer.isPinyinToken)) {
        continue;
      }
      out.add(
        ParsedMcQuestion(
          prompt: stripped.replaceRange(hint.start, hint.end, '（ ）'),
          keyword: pinyin,
        ),
      );
    }
    return out;
  }

  /// `1. 页：————` : a keyword (with a picture on the sheet) to write a
  /// sentence about.
  static List<ParsedMcQuestion> _parsePictureKeywords(List<String> lines) {
    final out = <ParsedMcQuestion>[];
    for (final line in lines) {
      final m = _pictureLine.firstMatch(line);
      if (m == null) continue;
      out.add(ParsedMcQuestion(prompt: m.group(1)!, keyword: m.group(1)!));
    }
    return out;
  }

  /// Blanks with several word lists: question i takes the words of its
  /// group (lists in order, blanks split evenly); one long list goes whole.
  static List<ParsedMcQuestion> _clozeAsChoices(
    ({
      List<String> options,
      List<ParsedMatchingQuestion> prompts,
      int unmarked,
      String? bankLine,
      List<List<String>> banks,
    }) cloze,
  ) {
    final banks = cloze.banks.isEmpty ? [cloze.options] : cloze.banks;
    final n = cloze.prompts.length;
    final perBank = banks.length > 1 && n % banks.length == 0
        ? n ~/ banks.length
        : n;
    return [
      for (var i = 0; i < n; i++)
        ParsedMcQuestion(
          prompt: cloze.prompts[i].prompt,
          options: banks[(i ~/ perBank).clamp(0, banks.length - 1)],
          correctIndex: 0,
        ),
    ];
  }

  /// R3: the long text before the first question is the passage, not an
  /// instruction. Only applied when the worksheet looks like reading
  /// comprehension or the text is clearly a paragraph.
  static (String instructions, String passage) _splitPassage(
    String instructions,
    List<String> contentLines,
    String keywordText,
  ) {
    if (instructions.isEmpty) return (instructions, '');
    final lines = instructions.split('\n');
    final keyworded = _comprehensionKeywords.hasMatch(keywordText);
    final kept = <String>[];
    final passage = <String>[];
    for (final line in lines) {
      final cjk = RegExp(r'[\u4e00-\u9fff]').allMatches(line).length;
      final looksLikePassage = cjk >= 15 ||
          (keyworded && cjk >= 8 && !_comprehensionKeywords.hasMatch(line));
      if (looksLikePassage) {
        passage.add(line);
      } else {
        kept.add(line);
      }
    }
    final body = passage.join('\n');
    final cjkTotal = RegExp(r'[\u4e00-\u9fff]').allMatches(body).length;
    if (passage.isEmpty || (!keyworded && cjkTotal < 40)) {
      return (instructions, '');
    }
    return (kept.join('\n').trim(), body.trim());
  }

  /// R1: numbered sentences with a blank, plus a word bank.
  static ({
    List<String> options,
    List<ParsedMatchingQuestion> prompts,
    int unmarked,
    String? bankLine,
    List<List<String>> banks,
  }) _parseCloze(
    List<String> lines, {
    required List<String> bankSource,
    bool impliedBlanks = false,
  }) {
    final banks = _clozeBanks(bankSource);
    final bank = banks.isEmpty
        ? (words: const <String>[], line: null)
        : (words: banks.first.words, line: banks.first.line);
    final options = bank.words;
    final prompts = <ParsedMatchingQuestion>[];
    var unmarked = 0;
    for (final line in lines) {
      if (!_looksLikeQuestionStart(line)) continue;
      var stripped = _stripNumberedPrefix(line);
      if (impliedBlanks &&
          !_blankMarker.hasMatch(stripped) &&
          !_pinyinHint.hasMatch(stripped)) {
        if (RegExp(r'^[,，]').hasMatch(stripped)) {
          stripped = '（ ）$stripped';
        } else if (_impliedBlank.hasMatch(stripped)) {
          stripped = stripped.replaceFirst(_impliedBlank, '（ ）');
        }
      }
      final blank = _blankMarker.firstMatch(stripped);
      if (blank == null) continue;
      // A blank at the very end is a matching prompt "(  )", not a cloze.
      if (blank.end == stripped.length && !stripped.contains('_')) {
        final inner = blank.group(0)!;
        if (!RegExp(r'[\u4e00-\u9fff]').hasMatch(inner)) continue;
      }
      var correctIndex = -1;
      final inner = blank.group(0)!;
      final letter = RegExp(r'[A-Fa-f]').firstMatch(inner);
      final word = RegExp(r'[\u4e00-\u9fff]{1,4}').firstMatch(inner);
      if (letter != null) {
        correctIndex = letter.group(0)!.toUpperCase().codeUnitAt(0) - 65;
      } else if (word != null) {
        correctIndex = options.indexOf(word.group(0)!);
      } else {
        final trailing = RegExp(r'[（(]\s*([A-Fa-f])\s*[)）]\s*$').firstMatch(stripped);
        if (trailing != null) {
          correctIndex = trailing.group(1)!.toUpperCase().codeUnitAt(0) - 65;
        }
      }
      if (correctIndex < 0) unmarked++;
      var prompt = stripped.replaceRange(blank.start, blank.end, '（ ）');
      prompt = prompt
          .replaceAll(RegExp(r'[（(]\s*[A-Fa-f]\s*[)）]\s*$'), '')
          .replaceAll(RegExp(r'\s*（ ）\s*'), '（ ）')
          .trim();
      prompts.add(
        ParsedMatchingQuestion(
          prompt: prompt,
          correctIndex: correctIndex < 0 ? 0 : correctIndex.clamp(0, 7),
        ),
      );
    }
    return (
      options: options,
      prompts: prompts,
      unmarked: unmarked,
      bankLine: bank.line,
      banks: [for (final b in banks) b.words],
    );
  }

  /// Every word list on the sheet, in order: lettered (`A想 B意思 …`, one
  /// line or several) or plain boxed lists (`周末 带 游戏 跟 作业`).
  static List<({List<String> words, String? line})> _clozeBanks(
    List<String> lines,
  ) {
    final out = <({List<String> words, String? line})>[];
    final inlineLettered = RegExp(
      r'(?:^|\s)[（(]?([A-Fa-f])[)）\.、．]?\s*([\u4e00-\u9fff]{1,4})(?=\s|$|[（(][A-F])',
    );
    Map<int, String>? lettered;
    void flushLettered() {
      if (lettered != null && lettered!.length >= 2) {
        final max = lettered!.keys.reduce((a, b) => a > b ? a : b);
        out.add((
          words: [for (var i = 0; i <= max; i++) lettered![i] ?? ''],
          line: null,
        ));
      }
      lettered = null;
    }

    for (final line in lines) {
      if (_looksLikeQuestionStart(line) || _blankMarker.hasMatch(line)) {
        flushLettered();
        continue;
      }
      final inline = inlineLettered.allMatches(line).toList();
      if (inline.length >= 2) {
        flushLettered();
        out.add((
          words: [
            for (final m in inline) m.group(2)!,
          ],
          line: line,
        ));
        continue;
      }
      final bankLine = _matchingBankLine.firstMatch(line);
      if (bankLine != null) {
        final word = bankLine.group(2)!.trim();
        if (_isMostlyCjk(word) && word.length <= 4) {
          final idx = bankLine.group(1)!.toUpperCase().codeUnitAt(0) - 65;
          lettered ??= {};
          if (lettered!.containsKey(idx)) flushLettered();
          lettered ??= {};
          lettered![idx] = word;
        }
        continue;
      }
      final cleaned = line.replaceAll(RegExp(r'[【】\[\]（）()「」《》]'), ' ');
      final parts = cleaned
          .split(RegExp(r'[\s、，,／/]+'))
          .where((p) => p.isNotEmpty)
          .toList();
      if (parts.length >= 3 &&
          parts.length <= 10 &&
          parts.every((p) => _isMostlyCjk(p) && p.length <= 4)) {
        flushLettered();
        out.add((words: parts, line: line));
      }
    }
    flushLettered();
    return out;
  }

  /// R4: a numbered item followed by lettered (or ①②③) sentences, optionally
  /// with an answer key line such as "答案：CAB". Segments are returned in the
  /// correct order when the key is known.
  static List<ParsedComposeQuestion> _parseOrdering(
    List<String> lines, {
    bool bareOnly = false,
  }) {
    final out = <ParsedComposeQuestion>[];
    var i = 0;
    while (i < lines.length) {
      final line = lines[i];
      final numbered = _numberedOnly.hasMatch(line) ||
          (!bareOnly &&
              _looksLikeQuestionStart(line) &&
              _stripNumberedPrefix(line).length <= 16 &&
              !_blankMarker.hasMatch(line));
      if (!numbered) {
        i++;
        continue;
      }
      final items = <String, String>{};
      var j = i + 1;
      while (j < lines.length) {
        final next = lines[j];
        if (_looksLikeQuestionStart(next) || _numberedOnly.hasMatch(next)) break;
        final lettered = _letteredSentence.firstMatch(next);
        final circled = _circledSentence.firstMatch(next);
        if (lettered != null && _isMostlyCjk(lettered.group(2)!)) {
          items[lettered.group(1)!.toUpperCase()] = lettered.group(2)!.trim();
        } else if (circled != null) {
          items[circled.group(1)!] = circled.group(2)!.trim();
        } else {
          break;
        }
        j++;
      }
      if (items.length < 2) {
        i++;
        continue;
      }
      // Sentences long enough to be sentences, not A–D answer options.
      final avg =
          items.values.fold<int>(0, (s, v) => s + v.length) / items.length;
      if (avg < 5) {
        i = j;
        continue;
      }
      var ordered = items.values.toList();
      var hasKey = false;
      if (j < lines.length) {
        final key = _orderKeyLine.firstMatch(lines[j]);
        if (key != null) {
          final letters = RegExp(r'[A-Fa-f①-⑧]')
              .allMatches(key.group(1)!)
              .map((m) => m.group(0)!.toUpperCase())
              .toList();
          if (letters.length == items.length &&
              letters.every(items.containsKey)) {
            ordered = [for (final l in letters) items[l]!];
            hasKey = true;
            j++;
          }
        }
      }
      out.add(
        ParsedComposeQuestion(
          prompt: hasKey
              ? 'Arrange the sentences in the correct order'
              : 'Arrange the sentences in the correct order (order not detected: put them in the right order before saving)',
          segments: ordered,
        ),
      );
      i = j;
    }
    return out;
  }

  /// True/false statements: numbered lines ending with √/×, 对/错, (T)/(F),
  /// (B)/(S). Unmarked lines default to 对 and are reported in the summary.
  static List<({ParsedMcQuestion question, bool marked})> _parseTrueFalse(
    List<String> lines,
  ) {
    final out = <({ParsedMcQuestion question, bool marked})>[];
    for (final line in lines) {
      if (!_looksLikeQuestionStart(line)) continue;
      var prompt = _stripNumberedPrefix(line);
      if (prompt.isEmpty || _matchOption(line) != null) continue;
      String? mark;
      for (final re in [_tfBracketMark, _tfSymbolMark, _tfWordMark]) {
        final m = re.firstMatch(prompt);
        if (m != null) {
          mark = m.group(1)!.toUpperCase();
          prompt = prompt.substring(0, m.start).trim();
          break;
        }
      }
      out.add((
        question: ParsedMcQuestion(
          prompt: prompt,
          options: trueFalseOptions,
          correctIndex: mark == null || _tfTrue.contains(mark) ? 0 : 1,
        ),
        marked: mark != null,
      ));
    }
    return out;
  }

  static String _summary(
    WorksheetParseResult r,
    String form, {
    required int unmarkedTrueFalse,
    required int unmarkedBlanks,
    required int unorderedGroups,
    required bool sections,
  }) {
    final level = r.suggestedLevel != null ? ' · ${r.suggestedLevel}' : '';
    String n(int c, String one, [String? many]) =>
        '$c ${c == 1 ? one : (many ?? '${one}s')}';
    final notes = <String>[];
    if (sections) {
      notes.add('Several parts found: split into separate exercises if needed.');
    }
    switch (r.suggestedType) {
      case ExerciseType.readingCloze:
        notes.insert(
          0,
          '${n(r.matchingQuestions.length, 'blank')}, '
          '${n(r.matchingOptions.length, 'word')} in the bank.',
        );
        if (r.matchingOptions.isEmpty) {
          notes.add('No word bank found: type the words into the answer bank.');
        }
        if (unmarkedBlanks > 0) {
          notes.add('${n(unmarkedBlanks, 'blank')} without an answer letter: set the correct word in the editor.');
        }
      case ExerciseType.matching:
        notes.insert(
          0,
          '${n(r.matchingQuestions.length, 'prompt')}, '
          '${n(r.matchingOptions.length, 'shared option')}.',
        );
      case ExerciseType.composeSentences:
        if (r.composeQuestions.isEmpty) {
          notes.insert(0, 'no sentence parts were found.');
        } else {
          notes.insert(
            0,
            '${n(r.composeQuestions.length, 'item')} to reorder.',
          );
          if (unorderedGroups > 0) {
            notes.add('${n(unorderedGroups, 'item')} without an answer key: drag the sentences into the right order before saving.');
          }
        }
      case ExerciseType.multipleChoice:
      case ExerciseType.listening:
        final withOptions = r.mcQuestions.where((q) => q.options.length >= 2).length;
        if (r.mcQuestions.isEmpty) {
          notes.insert(0, 'no questions were found.');
        } else {
          notes.insert(
            0,
            '${n(r.mcQuestions.length, 'question')}, $withOptions with answer options.',
          );
        }
        if (r.passage.isNotEmpty) {
          notes.add('Passage of ${r.passage.length} characters goes above the questions.');
        }
        if (unmarkedBlanks > 0 && r.suggestedType == ExerciseType.multipleChoice) {
          notes.add('Answers are not on the sheet: pick the right word for each blank in the editor.');
        }
        if (unmarkedTrueFalse > 0) {
          notes.add('${n(unmarkedTrueFalse, 'statement')} without √/×: set 对 or 错 in the editor.');
        }
        if (r.suggestedType == ExerciseType.listening) {
          notes.add('Attach the audio in the exercise form.');
        }
      case ExerciseType.pictureSentence:
        notes.insert(
          0,
          '${n(r.mcQuestions.length, 'keyword')}. Students write a sentence '
          'with each keyword; add the pictures in the editor.',
        );
      case ExerciseType.typeHanzi:
        notes.insert(
          0,
          '${n(r.mcQuestions.length, 'sentence')} with a pinyin hint. Type '
          'the hanzi answer for each in the editor.',
        );
    }
    return 'Detected $form$level — ${notes.join(' ')}';
  }

  /// e.g. "HSK 3" from worksheet title.
  static String? extractHskLevel(String text) {
    final match = _hskLevel.firstMatch(text);
    if (match == null) return null;
    return 'HSK ${match.group(1)}';
  }

  static bool _isNoiseLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return true;
    if (_noiseLine.hasMatch(trimmed)) return true;
    if (RegExp(r'^[\-_=。.·•\s]+$').hasMatch(trimmed)) return true;
    return false;
  }

  static (String instructions, List<String> contentLines) _splitInstructions(
    List<String> lines,
  ) {
    final instructionParts = <String>[];
    final content = <String>[];
    var pastInstructions = false;

    for (final line in lines) {
      if (line.isEmpty) continue;

      if (!pastInstructions) {
        final headerMatch = _instructionHeader.firstMatch(line);
        if (headerMatch != null) {
          final rest = headerMatch.group(1)?.trim() ?? '';
          if (rest.isNotEmpty) instructionParts.add(rest);
          continue;
        }

        if (_looksLikeQuestionStart(line) ||
            _looksLikeComposeLine(line) ||
            _looksLikeMatchingBankLine(line) ||
            _matchOption(line) != null) {
          pastInstructions = true;
          content.add(line);
          continue;
        }

        if (instructionParts.isNotEmpty) {
          instructionParts.add(line);
          continue;
        }

        instructionParts.add(line);
        continue;
      }

      content.add(line);
    }

    if (content.isEmpty && instructionParts.isNotEmpty) {
      return ('', List<String>.from(instructionParts));
    }

    return (instructionParts.join('\n').trim(), content);
  }

  static List<ParsedMcQuestion> _parseMcQuestions(List<String> lines) {
    final questions = <ParsedMcQuestion>[];
    String? currentPrompt;
    final currentOptions = <String>[];
    int? correctIndex;

    void flush() {
      if (currentPrompt != null &&
          currentPrompt!.trim().isNotEmpty &&
          currentOptions.length >= 2) {
        questions.add(
          ParsedMcQuestion(
            prompt: currentPrompt!.trim(),
            options: List<String>.from(currentOptions),
            correctIndex: (correctIndex ?? 0).clamp(0, currentOptions.length - 1),
          ),
        );
      }
      currentPrompt = null;
      currentOptions.clear();
      correctIndex = null;
    }

    for (final line in lines) {
      if (line.isEmpty) {
        flush();
        continue;
      }

      if (_looksLikeQuestionStart(line)) {
        flush();
        currentPrompt = _stripNumberedPrefix(line);
        continue;
      }

      if (_looksLikeComposeLine(line)) {
        flush();
        continue;
      }

      final option = _matchOption(line);
      if (option != null) {
        if (currentPrompt == null) continue;
        currentOptions.add(option.text);
        if (option.isCorrect) {
          correctIndex = currentOptions.length - 1;
        }
        continue;
      }

      if (currentOptions.isNotEmpty) {
        flush();
      }

      if (currentPrompt == null) {
        currentPrompt = line;
      } else {
        currentPrompt = '$currentPrompt $line';
      }
    }
    flush();

    if (questions.isNotEmpty) return questions;

    for (final line in lines) {
      if (_looksLikeComposeLine(line) || _matchOption(line) != null) continue;
      final prompt = _stripNumberedPrefix(line);
      if (prompt.isNotEmpty) {
        questions.add(ParsedMcQuestion(prompt: prompt));
      }
    }
    return questions;
  }

  static List<ParsedComposeQuestion> _parseComposeQuestions(List<String> lines) {
    final questions = <ParsedComposeQuestion>[];
    var index = 0;

    while (index < lines.length) {
      final line = lines[index];
      if (_isNoiseLine(line)) {
        index++;
        continue;
      }

      final inlineSegments = _segmentsFromComposeLine(line);
      if (inlineSegments != null) {
        questions.add(ParsedComposeQuestion(segments: inlineSegments));
        index++;
        continue;
      }

      if (_numberedOnly.hasMatch(line) || _looksLikeQuestionStart(line)) {
        final segments = <String>[];
        if (_looksLikeQuestionStart(line)) {
          final first = _segmentsFromComposeLine(line);
          if (first != null) {
            questions.add(ParsedComposeQuestion(segments: first));
            index++;
            continue;
          }
        }

        index++;
        while (index < lines.length) {
          final next = lines[index];
          if (_isNoiseLine(next)) {
            index++;
            continue;
          }
          if (_looksLikeQuestionStart(next) || _numberedOnly.hasMatch(next)) {
            break;
          }
          if (_isComposeSegment(next)) {
            segments.add(next.trim());
            index++;
            continue;
          }
          break;
        }

        if (segments.length >= 2) {
          questions.add(ParsedComposeQuestion(segments: segments));
        }
        continue;
      }

      index++;
    }

    return questions;
  }

  static List<String>? _segmentsFromComposeLine(String line) {
    if (!_looksLikeComposeLine(line)) return null;
    final segments = segmentsFromLine(line);
    return segments.length >= 2 ? segments : null;
  }

  static bool _isComposeSegment(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || _isNoiseLine(trimmed)) return false;
    if (_looksLikeQuestionStart(trimmed)) return false;
    if (_matchOption(trimmed) != null) return false;
    return _isMostlyCjk(trimmed) && trimmed.length <= 12;
  }

  static ({List<String> options, List<ParsedMatchingQuestion> prompts})
      _parseMatching(List<String> lines) {
    final options = <String>[];
    final prompts = <ParsedMatchingQuestion>[];

    for (final line in lines) {
      final example = _matchingPromptLine.firstMatch(line);
      if (example != null) continue;

      final bank = _matchingBankLine.firstMatch(line);
      if (bank != null) {
        final letter = bank.group(1)!.toUpperCase();
        final text = bank.group(2)!.trim();
        final index = letter.codeUnitAt(0) - 'A'.codeUnitAt(0);
        if (index >= 0 && index < 8) {
          while (options.length <= index) {
            options.add('');
          }
          options[index] = text;
        }
        continue;
      }

      final promptMatch = _numberedLine.firstMatch(line);
      if (promptMatch != null) {
        var promptText = promptMatch.group(1)?.trim() ?? '';
        promptText = promptText
            .replaceAll(RegExp(r'[\(（]\s*[\)）]\s*$'), '')
            .trim();
        if (promptText.isEmpty) continue;

        var correctIndex = 0;
        final answerMatch = RegExp(r'[\(（]\s*([A-Fa-f])\s*[\)）]\s*$')
            .firstMatch(promptMatch.group(1) ?? '');
        if (answerMatch != null) {
          correctIndex = answerMatch.group(1)!.toUpperCase().codeUnitAt(0) -
              'A'.codeUnitAt(0);
        }

        prompts.add(
          ParsedMatchingQuestion(
            prompt: promptText,
            correctIndex: correctIndex.clamp(0, 7),
          ),
        );
      }
    }

    while (options.isNotEmpty && options.last.isEmpty) {
      options.removeLast();
    }

    return (options: options, prompts: prompts);
  }

  static bool _looksLikeMatchingBankLine(String line) {
    return _matchingBankLine.hasMatch(line);
  }

  static ExerciseType _suggestType(
    List<ParsedMcQuestion> mcQuestions,
    List<ParsedComposeQuestion> composeQuestions,
    ({List<String> options, List<ParsedMatchingQuestion> prompts}) matching,
    List<String> lines,
    String instructions,
    String fullText,
  ) {
    final keywordText = '$instructions\n${lines.join('\n')}\n$fullText';

    if (_pictureKeywords.hasMatch(keywordText)) {
      return ExerciseType.pictureSentence;
    }
    if (_clozeKeywords.hasMatch(keywordText)) {
      return ExerciseType.readingCloze;
    }

    var mcScore = mcQuestions.where((q) => q.options.length >= 2).length * 4;
    var composeScore = composeQuestions.length * 4;
    var matchingScore = 0;

    if (matching.options.length >= 2 && matching.prompts.length >= 2) {
      matchingScore += 12;
    }
    if (_matchingKeywords.hasMatch(keywordText)) matchingScore += 8;
    matchingScore += lines.where(_looksLikeMatchingBankLine).length;

    if (_composeKeywords.hasMatch(keywordText)) composeScore += 8;
    if (_mcKeywords.hasMatch(keywordText)) mcScore += 6;

    composeScore += lines.where(_looksLikeComposeLine).length * 2;
    mcScore += lines.where((line) => _matchOption(line) != null).length;

    final structuredMc = mcQuestions.where((q) => q.options.length >= 2).length;
    // Options that restart at "A" under each question are per-question
    // choices; a matching bank lists A–F once.
    final optionListsStartingAtA = lines.where((line) {
      final m = _matchingBankLine.firstMatch(line);
      return m != null && m.group(1)!.toUpperCase() == 'A';
    }).length;
    if (structuredMc >= 2 && optionListsStartingAtA >= 2) {
      return ExerciseType.multipleChoice;
    }

    if (matchingScore >= composeScore &&
        matchingScore >= mcScore &&
        matching.prompts.isNotEmpty) {
      return ExerciseType.matching;
    }

    if (structuredMc > 0 && composeQuestions.isEmpty) {
      return ExerciseType.multipleChoice;
    }
    if (composeQuestions.isNotEmpty && structuredMc == 0) {
      return ExerciseType.composeSentences;
    }
    if (composeScore > mcScore && composeQuestions.isNotEmpty) {
      return ExerciseType.composeSentences;
    }
    if (matching.prompts.isNotEmpty && matching.options.length >= 2) {
      return ExerciseType.matching;
    }
    if (mcQuestions.isNotEmpty) return ExerciseType.multipleChoice;
    if (composeQuestions.isNotEmpty) return ExerciseType.composeSentences;
    return ExerciseType.multipleChoice;
  }

  static bool _looksLikeQuestionStart(String line) {
    return _numberedLine.hasMatch(line);
  }

  static bool _looksLikeComposeLine(String line) {
    final stripped = _stripNumberedPrefix(line);
    if (stripped.contains('/') && stripped.split('/').length >= 2) return true;
    if (stripped.contains('|') && stripped.split('|').length >= 2) return true;
    if (_bracketSegment.allMatches(stripped).length >= 2) return true;
    return _isCjkWordBank(stripped);
  }

  static bool _isCjkWordBank(String line) {
    if (!line.contains(' ')) return false;
    final parts =
        line.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.length < 2) return false;
    return parts.every(_isMostlyCjk);
  }

  static bool _isMostlyCjk(String text) {
    if (text.isEmpty) return false;
    final cjkMatches = RegExp(r'[\u4e00-\u9fff]').allMatches(text).length;
    return cjkMatches >= (text.length * 0.5).ceil();
  }

  static String _stripNumberedPrefix(String line) {
    final match = _numberedLine.firstMatch(line);
    if (match != null) return match.group(1)?.trim() ?? line;
    return line.trim();
  }

  static ({String text, bool isCorrect})? _matchOption(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return null;

    final match = _optionLine.firstMatch(trimmed);
    if (match == null) return null;

    var text = match.group(4)?.trim() ?? '';
    if (text.isEmpty) return null;

    final isCorrect = _correctMarker.hasMatch(trimmed) ||
        _correctMarker.hasMatch(text);
    text = text.replaceAll(_correctMarker, '').trim();
    return (text: text, isCorrect: isCorrect);
  }

  /// Split a sentence into compose segments (space-separated, or per-character).
  static List<String> segmentsFromLine(String line) {
    final trimmed = _stripNumberedPrefix(line).trim();
    if (trimmed.isEmpty) return [];

    final bracketParts = _bracketSegment
        .allMatches(trimmed)
        .map((match) => match.group(1)!.trim())
        .where((segment) => segment.isNotEmpty)
        .toList();
    if (bracketParts.length >= 2) return bracketParts;

    if (trimmed.contains('/')) {
      return trimmed
          .split('/')
          .map((segment) => segment.trim())
          .where((segment) => segment.isNotEmpty)
          .toList();
    }
    if (trimmed.contains('|')) {
      return trimmed
          .split('|')
          .map((segment) => segment.trim())
          .where((segment) => segment.isNotEmpty)
          .toList();
    }
    if (trimmed.contains(' ')) {
      final wideParts = trimmed
          .split(RegExp(r'\s{2,}'))
          .map((segment) => segment.trim())
          .where((segment) => segment.isNotEmpty)
          .toList();
      if (wideParts.length >= 2) return wideParts;

      return trimmed
          .split(RegExp(r'\s+'))
          .where((segment) => segment.isNotEmpty)
          .toList();
    }
    if (trimmed.length <= 24) {
      return trimmed.split('');
    }
    return [trimmed];
  }

  static int suggestedQuestionCount(String text, ExerciseType type) {
    final parsed = parseWorksheet(text);
    return WorksheetParseResult.countFor(
      type,
      mc: parsed.mcQuestions.length,
      compose: parsed.composeQuestions.length,
      bank: parsed.matchingQuestions.length,
    );
  }
}
