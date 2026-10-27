import '../../models/exercise_type.dart';

class ParsedMcQuestion {
  const ParsedMcQuestion({
    required this.prompt,
    this.options = const [],
    this.correctIndex = 0,
  });

  final String prompt;
  final List<String> options;
  final int correctIndex;
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
  });

  final String instructions;
  final String? suggestedLevel;
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
        return 0;
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
    r'^\s*(?:\(([A-Da-d])\)|([A-Da-d])[\.\):\-])\s*(.+?)(?:\s*[\*✓√])?\s*$',
  );
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
    r'\d{1,2}\s+(?:january|february|march|april|may|june|july|august|september|october|november|december))'
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
    r'(isilah\s+dengan\s+kata|kata\s+yang\s+tepat|选词填空|选词)',
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
    final normalized = text.replaceAll('\r\n', '\n').trim();
    if (normalized.isEmpty) return WorksheetParseResult.empty();

    final rawLines = normalized.split('\n').map((line) => line.trim()).toList();
    final (rawInstructions, contentLines) = _splitInstructions(rawLines);
    final filteredLines =
        contentLines.where((line) => !_isNoiseLine(line)).toList();
    final keywordText = '$rawInstructions\n$normalized';
    final level = extractHskLevel(normalized);

    final (instructions, passage) = _splitPassage(
      rawInstructions,
      filteredLines,
      keywordText,
    );

    final mcQuestions = _parseMcQuestions(filteredLines);
    final composeQuestions = _parseComposeQuestions(filteredLines);
    final matching = _parseMatching(filteredLines);
    final allLines = rawLines.where((line) => !_isNoiseLine(line)).toList();
    final cloze = _parseCloze(filteredLines, bankSource: allLines);
    final orderingAny = _parseOrdering(filteredLines);
    final orderingBare = _parseOrdering(filteredLines, bareOnly: true);
    final trueFalse = _parseTrueFalse(filteredLines);

    final hasLetteredOptions =
        filteredLines.any((line) => _matchOption(line) != null);
    final isTrueFalse = trueFalse.isNotEmpty &&
        (_trueFalseKeywords.hasMatch(keywordText) ||
            (!hasLetteredOptions && trueFalse.where((q) => q.marked).length >= 2));
    final isListening = _listeningKeywords.hasMatch(keywordText);
    final isCloze = cloze.prompts.isNotEmpty &&
        (_clozeKeywords.hasMatch(keywordText) ||
            (cloze.prompts.length >= 2 && cloze.options.length >= 2));
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
    if (isListening) {
      type = ExerciseType.listening;
      form = isTrueFalse ? 'L2 listening true/false' : 'L3 listening';
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

    final finalMc = isTrueFalse
        ? trueFalse.map((q) => q.question).toList()
        : mcQuestions;
    final finalCompose = isOrdering ? ordering : composeQuestions;
    final bankOptions = isCloze ? cloze.options : matching.options;
    final bankPrompts = isCloze ? cloze.prompts : matching.prompts;

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
    );
    return WorksheetParseResult(
      instructions: result.instructions,
      suggestedLevel: level,
      suggestedType: type,
      detectionSummary: _summary(
        result,
        form,
        unmarkedTrueFalse:
            isTrueFalse ? trueFalse.where((q) => !q.marked).length : 0,
        unmarkedBlanks: isCloze ? cloze.unmarked : 0,
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
    );
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
  }) _parseCloze(List<String> lines, {required List<String> bankSource}) {
    final bank = _clozeBank(bankSource);
    final options = bank.words;
    final prompts = <ParsedMatchingQuestion>[];
    var unmarked = 0;
    for (final line in lines) {
      if (!_looksLikeQuestionStart(line)) continue;
      final stripped = _stripNumberedPrefix(line);
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
      prompt = prompt.replaceAll(RegExp(r'[（(]\s*[A-Fa-f]\s*[)）]\s*$'), '').trim();
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
    );
  }

  /// The word bank of a cloze worksheet: lettered short words (A. 的 B. 了,
  /// on one line or several) or one line of short CJK words.
  static ({List<String> words, String? line}) _clozeBank(List<String> lines) {
    final lettered = <int, String>{};
    String? letteredLine;
    final inlineLettered = RegExp(
      r'(?:^|\s)[（(]?([A-Fa-f])[)）\.、．]?\s*([\u4e00-\u9fff]{1,4})(?=\s|$|[（(][A-F])',
    );
    for (final line in lines) {
      if (_looksLikeQuestionStart(line)) continue;
      final inline = inlineLettered.allMatches(line).toList();
      if (inline.length >= 2) {
        for (final m in inline) {
          lettered[m.group(1)!.toUpperCase().codeUnitAt(0) - 65] = m.group(2)!;
        }
        letteredLine = line;
        continue;
      }
      final bank = _matchingBankLine.firstMatch(line);
      if (bank != null) {
        final word = bank.group(2)!.trim();
        if (_isMostlyCjk(word) && word.length <= 4) {
          lettered[bank.group(1)!.toUpperCase().codeUnitAt(0) - 65] = word;
        }
      }
    }
    if (lettered.length >= 2) {
      final max = lettered.keys.reduce((a, b) => a > b ? a : b);
      return (
        words: [for (var i = 0; i <= max; i++) lettered[i] ?? ''],
        line: letteredLine,
      );
    }
    for (final line in lines) {
      if (_looksLikeQuestionStart(line) || _blankMarker.hasMatch(line)) continue;
      final cleaned = line.replaceAll(RegExp(r'[【】\[\]（）()「」《》]'), ' ');
      final parts = cleaned
          .split(RegExp(r'[\s、，,／/]+'))
          .where((p) => p.isNotEmpty)
          .toList();
      if (parts.length >= 3 &&
          parts.length <= 10 &&
          parts.every((p) => _isMostlyCjk(p) && p.length <= 4)) {
        return (words: parts, line: line);
      }
    }
    return (words: const <String>[], line: null);
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
        if (unmarkedTrueFalse > 0) {
          notes.add('${n(unmarkedTrueFalse, 'statement')} without √/×: set 对 or 错 in the editor.');
        }
        if (r.suggestedType == ExerciseType.listening) {
          notes.add('Attach the audio in the exercise form.');
        }
      case ExerciseType.pictureSentence:
        notes.insert(0, 'recognised but not editable in the app yet.');
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

    var text = match.group(3)?.trim() ?? '';
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
