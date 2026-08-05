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
  });

  final String instructions;
  final String? suggestedLevel;
  final ExerciseType suggestedType;
  final String detectionSummary;
  final List<ParsedMcQuestion> mcQuestions;
  final List<ParsedComposeQuestion> composeQuestions;
  final List<String> matchingOptions;
  final List<ParsedMatchingQuestion> matchingQuestions;

  int get questionCount {
    switch (suggestedType) {
      case ExerciseType.composeSentences:
        return composeQuestions.length;
      case ExerciseType.matching:
        return matchingQuestions.length;
      case ExerciseType.readingCloze:
      case ExerciseType.pictureSentence:
      case ExerciseType.listening:
        return 0;
      case ExerciseType.multipleChoice:
        return mcQuestions.length;
    }
  }

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

  /// Non-empty lines from OCR or pasted text.
  static List<String> linesFromText(String text) {
    return text
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  /// Parse uploaded worksheet text into instructions, question type, and questions.
  static WorksheetParseResult parseWorksheet(String text) {
    final normalized = text.replaceAll('\r\n', '\n').trim();
    if (normalized.isEmpty) return WorksheetParseResult.empty();

    final rawLines = normalized.split('\n').map((line) => line.trim()).toList();
    final (instructions, contentLines) = _splitInstructions(rawLines);
    final filteredLines =
        contentLines.where((line) => !_isNoiseLine(line)).toList();

    final mcQuestions = _parseMcQuestions(filteredLines);
    final composeQuestions = _parseComposeQuestions(filteredLines);
    final matching = _parseMatching(filteredLines);
    final suggestedType = _suggestType(
      mcQuestions,
      composeQuestions,
      matching,
      filteredLines,
      instructions,
      normalized,
    );
    final detectionSummary = _buildDetectionSummary(
      suggestedType,
      mcQuestions,
      composeQuestions,
      matching,
      filteredLines,
      normalized,
      suggestedLevel: extractHskLevel(normalized),
    );

    return WorksheetParseResult(
      instructions: instructions,
      suggestedLevel: extractHskLevel(normalized),
      suggestedType: suggestedType,
      detectionSummary: detectionSummary,
      mcQuestions: mcQuestions,
      composeQuestions: composeQuestions,
      matchingOptions: matching.options,
      matchingQuestions: matching.prompts,
    );
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

    if (matchingScore >= composeScore &&
        matchingScore >= mcScore &&
        matching.prompts.isNotEmpty) {
      return ExerciseType.matching;
    }

    final structuredMc = mcQuestions.where((q) => q.options.length >= 2).length;
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

  static String _buildDetectionSummary(
    ExerciseType type,
    List<ParsedMcQuestion> mcQuestions,
    List<ParsedComposeQuestion> composeQuestions,
    ({List<String> options, List<ParsedMatchingQuestion> prompts}) matching,
    List<String> lines,
    String fullText, {
    String? suggestedLevel,
  }) {
    final levelNote =
        suggestedLevel != null ? ' ($suggestedLevel)' : '';

    switch (type) {
      case ExerciseType.matching:
        final count = matching.prompts.length;
        final optionCount = matching.options.length;
        var summary =
            'Detected matching / dialogue pairing$levelNote — '
            '$count prompt${count == 1 ? '' : 's'}, '
            '$optionCount shared option${optionCount == 1 ? '' : 's'}.';
        if (RegExp(r'part\s*2', caseSensitive: false).hasMatch(fullText)) {
          summary += ' Multiple sections found — split into separate exercises if needed.';
        }
        return summary;
      case ExerciseType.readingCloze:
        return 'Detected reading cloze (选词填空 / ISILAH DENGAN KATA)$levelNote. '
            'This type is recognized but not editable in the app yet — '
            'use multiple choice for now or enter manually.';
      case ExerciseType.pictureSentence:
        return 'Detected picture + keyword sentences$levelNote. '
            'This type is recognized but not editable in the app yet — '
            'images must be added manually when supported.';
      case ExerciseType.composeSentences:
        final count = composeQuestions.length;
        if (count == 0) {
          return 'Detected 组词成句 / compose sentences$levelNote, '
              'but no sentence parts were found.';
        }
        return 'Detected 组词成句 / compose sentences$levelNote — '
            '$count sentence${count == 1 ? '' : 's'} with word parts to reorder.';
      case ExerciseType.multipleChoice:
        final withOptions =
            mcQuestions.where((question) => question.options.length >= 2).length;
        final count = mcQuestions.length;
        if (count == 0) {
          return 'Detected multiple choice worksheet, but no questions were found.';
        }
        if (withOptions > 0) {
          return 'Detected multiple choice — $count question${count == 1 ? '' : 's'}, '
              '$withOptions with answer options.';
        }
        if (lines.any((line) => _matchOption(line) != null)) {
          return 'Detected multiple choice — found answer options; review question prompts.';
        }
        return 'Detected multiple choice — $count question prompt${count == 1 ? '' : 's'} '
            '(add or edit answer options).';
      case ExerciseType.listening:
        return 'Listening exercises need an audio file — create manually in the exercise form.';
    }
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
    return type == ExerciseType.composeSentences
        ? parsed.composeQuestions.length
        : parsed.mcQuestions.length;
  }
}
