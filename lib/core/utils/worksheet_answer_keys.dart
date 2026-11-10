import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../models/exercise_type.dart';
import 'question_import_utils.dart';

/// Answer keys for the centre's own worksheets.
///
/// The sheets carry no key, so a fresh scan would store "A" for every choice
/// question and the scrambled order for every compose item. The bundled
/// sample set (`assets/question_sets/contoh_latihan_soal.json`) holds the
/// keyed version of each sheet; when a scanned sheet's code (`310001-RDG`)
/// is in it, the answers are copied over.
class WorksheetAnswerKeys {
  WorksheetAnswerKeys(Map<String, dynamic> questionSet)
      : _bySet = _index(questionSet);

  static const assetPath = 'assets/question_sets/contoh_latihan_soal.json';
  static Future<WorksheetAnswerKeys>? _bundled;

  /// The sample set shipped with the app, decoded once per session.
  static Future<WorksheetAnswerKeys> loadBundled() =>
      _bundled ??= rootBundle.loadString(assetPath).then((raw) =>
          WorksheetAnswerKeys(jsonDecode(raw) as Map<String, dynamic>));

  /// Sheet code → that sheet's questions, in sheet order.
  final Map<String, List<Map<String, dynamic>>> _bySet;

  bool hasKeyFor(String? sheetCode) =>
      sheetCode != null && _bySet.containsKey(sheetCode);

  /// Fills in the answers of [parsed] from the key for its sheet code.
  /// [applied] counts the questions that received an answer; [total] is the
  /// number of questions of the detected type.
  ({WorksheetParseResult result, int applied, int total}) apply(
    WorksheetParseResult parsed,
  ) {
    final key = _bySet[parsed.sheetCode];
    final total = parsed.questionCount;
    if (key == null || total == 0) {
      return (result: parsed, applied: 0, total: total);
    }

    switch (parsed.suggestedType) {
      case ExerciseType.composeSentences:
        final (items, applied) = _applyCompose(parsed.composeQuestions, key);
        return (
          result: parsed.copyWith(composeQuestions: items),
          applied: applied,
          total: total,
        );
      case ExerciseType.matching:
      case ExerciseType.readingCloze:
        // A "connect the words" sheet has no bank the scanner can read; the
        // key carries the bank the centre uses for it.
        final options = parsed.matchingOptions.isNotEmpty
            ? parsed.matchingOptions
            : _sharedOptions(key);
        final (items, applied) = _applyBank(
          parsed.matchingQuestions,
          options,
          key,
        );
        return (
          result: parsed.copyWith(
            matchingOptions: options,
            matchingQuestions: items,
          ),
          applied: applied,
          total: total,
        );
      case ExerciseType.multipleChoice:
      case ExerciseType.listening:
      case ExerciseType.typeHanzi:
      case ExerciseType.pictureSentence:
        final (items, applied) = _applyChoices(parsed.mcQuestions, key);
        return (
          result: parsed.copyWith(mcQuestions: items),
          applied: applied,
          total: total,
        );
    }
  }

  // ----------------------------------------------------------------- per type

  (List<ParsedMcQuestion>, int) _applyChoices(
    List<ParsedMcQuestion> questions,
    List<Map<String, dynamic>> key,
  ) {
    var applied = 0;
    final out = <ParsedMcQuestion>[];
    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      final k =
          _find(key, i, questions.length, prompt: q.prompt, keyword: q.keyword);
      if (k == null) {
        out.add(q);
        continue;
      }
      final keyOptions = _strings(k['options']);
      final keyIndex = k['correctIndex'] as int? ?? 0;

      if (q.options.isEmpty) {
        // Type the hanzi: the key holds the accepted answers.
        if (keyOptions.isEmpty) {
          out.add(q);
          continue;
        }
        out.add(ParsedMcQuestion(
          prompt: q.prompt,
          options: keyOptions,
          correctIndex: 0,
          keyword: q.keyword.isNotEmpty
              ? q.keyword
              : (k['keyword'] as String? ?? ''),
        ));
        applied++;
        continue;
      }

      // Prefer the answer *text* so a differently ordered option list still
      // gets the right choice; fall back to the raw index.
      var index = -1;
      if (keyIndex >= 0 && keyIndex < keyOptions.length) {
        index = q.options
            .indexWhere((o) => _norm(o) == _norm(keyOptions[keyIndex]));
      }
      if (index < 0 && keyIndex >= 0 && keyIndex < q.options.length) {
        index = keyIndex;
      }
      if (index < 0) {
        out.add(q);
        continue;
      }
      out.add(ParsedMcQuestion(
        prompt: q.prompt,
        options: q.options,
        correctIndex: index,
        keyword: q.keyword,
      ));
      applied++;
    }
    return (out, applied);
  }

  (List<ParsedComposeQuestion>, int) _applyCompose(
    List<ParsedComposeQuestion> questions,
    List<Map<String, dynamic>> key,
  ) {
    var applied = 0;
    final out = <ParsedComposeQuestion>[];
    for (final q in questions) {
      final bag = _bag(q.segments);
      Map<String, dynamic>? match;
      for (final k in key) {
        if (_bag(_strings(k['segments'])) == bag) {
          match = k;
          break;
        }
      }
      if (match == null) {
        out.add(q);
        continue;
      }
      out.add(ParsedComposeQuestion(
        prompt: q.prompt,
        segments: _strings(match['segments']),
      ));
      applied++;
    }
    return (out, applied);
  }

  (List<ParsedMatchingQuestion>, int) _applyBank(
    List<ParsedMatchingQuestion> questions,
    List<String> options,
    List<Map<String, dynamic>> key,
  ) {
    var applied = 0;
    final out = <ParsedMatchingQuestion>[];
    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      final k = _find(key, i, questions.length, prompt: q.prompt);
      if (k == null) {
        out.add(q);
        continue;
      }
      final keyOptions = _strings(k['options']);
      final keyIndex = k['correctIndex'] as int? ?? 0;
      var index = -1;
      if (keyIndex >= 0 && keyIndex < keyOptions.length) {
        final answer = _norm(keyOptions[keyIndex]);
        index = options.indexWhere((o) => _norm(o) == answer);
      }
      if (index < 0 && keyIndex >= 0 && keyIndex < options.length) {
        index = keyIndex;
      }
      if (index < 0) {
        out.add(q);
        continue;
      }
      out.add(ParsedMatchingQuestion(prompt: q.prompt, correctIndex: index));
      applied++;
    }
    return (out, applied);
  }

  // ------------------------------------------------------------------ helpers

  /// The key entry for a scanned question: same prompt, else one prompt
  /// contains the other (the scan may carry the passage, the key may not),
  /// else the same keyword, else the same position when the counts agree.
  Map<String, dynamic>? _find(
    List<Map<String, dynamic>> key,
    int index,
    int count, {
    required String prompt,
    String keyword = '',
  }) {
    final p = _norm(prompt);
    if (p.isNotEmpty) {
      for (final k in key) {
        if (_norm(k['prompt'] as String? ?? '') == p) return k;
      }
      for (final k in key) {
        final kp = _norm(k['prompt'] as String? ?? '');
        if (kp.length < 6 || p.length < 6) continue;
        if (p.contains(kp) || kp.contains(p)) return k;
      }
    }
    if (keyword.isNotEmpty) {
      for (final k in key) {
        if (_norm(k['keyword'] as String? ?? '') == _norm(keyword)) return k;
      }
    }
    if (key.length == count && index < key.length) return key[index];
    return null;
  }

  /// The option list every entry of [key] shares, or empty when they differ.
  static List<String> _sharedOptions(List<Map<String, dynamic>> key) {
    if (key.isEmpty) return const [];
    final first = _strings(key.first['options']);
    if (first.isEmpty) return const [];
    for (final k in key.skip(1)) {
      if (_strings(k['options']).join('|') != first.join('|')) return const [];
    }
    return first;
  }

  static Map<String, List<Map<String, dynamic>>> _index(
    Map<String, dynamic> questionSet,
  ) {
    final bySet = <String, List<Map<String, dynamic>>>{};
    for (final raw in questionSet['items'] as List? ?? const []) {
      if (raw is! Map) continue;
      final code = raw['set'] as String?;
      final question = raw['question'];
      if (code == null || question is! Map) continue;
      bySet
          .putIfAbsent(code, () => [])
          .add(Map<String, dynamic>.from(question));
    }
    return bySet;
  }

  static List<String> _strings(Object? value) =>
      value is List ? value.map((e) => e.toString()).toList() : const [];

  static String _bag(List<String> segments) =>
      (segments.map(_norm).toList()..sort()).join('|');

  static final _ignored = RegExp(
    r'[\s　（）()「」『』“”"‘’'
    "'"
    r'，,。．.、：:；;！!？?★☆□■…—\-_～~·•]+',
  );

  /// Prompt text without spaces, punctuation and markers, for matching.
  static String _norm(String text) => text.replaceAll(_ignored, '');
}
