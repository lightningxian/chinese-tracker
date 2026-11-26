import '../../core/utils/answer_key_parser.dart';
import '../../core/utils/answer_sheet_parser.dart';
import '../../core/utils/question_import_utils.dart';
import '../../models/exercise_type.dart';
import '../../models/question_bank_item.dart';
import 'sheet_answer_key.dart';

/// How one question stands after the answer sheet was read.
enum AnswerSheetStatus {
  /// The key read is the key the question already has.
  same,

  /// A good key that differs from the stored one: Save writes it.
  changed,

  /// Read, but it does not fit the question: the admin looks.
  check,

  /// Nothing was read for this question; the stored key stays.
  missing,

  /// Free writing: a teacher marks it, there is no key.
  free,
}

/// Why a row is [AnswerSheetStatus.check] (the screen words it).
enum AnswerSheetIssue {
  none,

  /// Not a letter, mark or choice text of this question.
  notAChoice,

  /// A letter past the last choice (`E` on a four-choice question).
  pastLastChoice,

  /// The words of the word-order question do not make the sentence.
  wordsDoNotMatch,

  /// A different number of answers than the question has blanks.
  blankCount,

  /// The key printed two different answers for this number.
  readTwice,

  /// Matched by position because the key's parts did not line up with the
  /// worksheet's parts.
  matchedInOrder,

  /// Characters expected, none read (or pinyin expected, characters read).
  wrongScript,
}

/// One question of the worksheet next to what the answer sheet says.
class AnswerSheetRow {
  AnswerSheetRow({
    required this.number,
    required this.item,
    required this.read,
    required this.current,
    this.readIssue = AnswerSheetIssue.none,
    this.heading = '',
  }) : value = read;

  /// 1-based position on the worksheet (the number the dialog uses).
  final int number;
  final QuestionBankItem item;

  /// What the PDF says for it, as printed; empty when nothing was found.
  final String read;

  /// The key the question has now, in the Answer key dialog's form.
  final String current;

  /// A problem found while matching (read twice, matched in order).
  final AnswerSheetIssue readIssue;

  /// The key's block heading above this answer, if any.
  final String heading;

  /// What the admin keeps; starts as [read], edited on the check screen.
  String value;

  /// [readIssue] stays until the admin changes the value.
  bool get edited => value != read;

  AnswerSheetVerdict get verdict {
    final v = AnswerSheetCheck.evaluate(item, value, current: current);
    // Read twice: the admin picks (any edit, even typing it back, clears
    // it). Matched in order is a hint only, the banner says it.
    if (!edited &&
        readIssue == AnswerSheetIssue.readTwice &&
        (v.status == AnswerSheetStatus.same || v.status == AnswerSheetStatus.changed)) {
      return AnswerSheetVerdict(AnswerSheetStatus.check, readIssue,
          v.choice, v.written);
    }
    return v;
  }
}

class AnswerSheetVerdict {
  const AnswerSheetVerdict(this.status, [this.issue = AnswerSheetIssue.none, this.choice, this.written]);

  final AnswerSheetStatus status;
  final AnswerSheetIssue issue;

  /// The choice index to store (choice questions).
  final int? choice;

  /// The text to give the Answer key plan (written questions).
  final String? written;
}

/// Matches the entries of an answer sheet to a worksheet and checks each
/// one (pure, unit tested).
abstract final class AnswerSheetCheck {
  static bool isChoice(ExerciseType t) => switch (t) {
        ExerciseType.multipleChoice ||
        ExerciseType.listening ||
        ExerciseType.matching ||
        ExerciseType.readingCloze =>
          true,
        _ => false,
      };

  static bool isFree(ExerciseType t) =>
      t == ExerciseType.essay || t == ExerciseType.pictureSentence;

  /// The worksheet's questions with the answer read for each.
  ///
  /// - One numbering for the whole key (an HSK key, 1–80): number n is the
  ///   n-th question; a key that starts later (a sheet holding questions
  ///   41–60 only) is shifted so its first number is the first question.
  /// - The numbering starts again (a Standard Course key, each exercise
  ///   from 1): block k is the k-th part of the worksheet (`section`), or
  ///   the k-th part that has a key when the free-writing parts are left out
  ///   of the key. When the blocks still do not line up, the answers are
  ///   given out in order and every row says so.
  static List<AnswerSheetRow> match(QuestionBankSheet sheet, AnswerSheetText read) {
    final items = sheet.items;
    final assigned = <int, List<AnswerSheetEntry>>{};
    var inOrder = false;

    if (read.entries.isNotEmpty) {
      if (read.blockCount <= 1) {
        final maxNumber = read.entries.map((e) => e.number).reduce((a, b) => a > b ? a : b);
        final minNumber = read.entries.map((e) => e.number).reduce((a, b) => a < b ? a : b);
        final shift = maxNumber > items.length ? minNumber - 1 : 0;
        for (final e in read.entries) {
          (assigned[e.number - 1 - shift] ??= []).add(e);
        }
      } else {
        final runs = _runs(sheet);
        final keyed = [
          for (final r in runs)
            if (r.any((i) => !isFree(items[i].type))) r,
        ];
        final blocks = <int, List<AnswerSheetEntry>>{};
        for (final e in read.entries) {
          (blocks[e.block] ??= []).add(e);
        }
        final target = blocks.length == runs.length
            ? runs
            : blocks.length == keyed.length
                ? keyed
                : null;
        if (target != null) {
          for (final (b, run) in target.indexed) {
            final entries = blocks[b] ?? const [];
            if (entries.isEmpty) continue;
            final first = entries.map((e) => e.number).reduce((a, c) => a < c ? a : c);
            for (final e in entries) {
              final pos = e.number - first;
              if (pos >= 0 && pos < run.length) (assigned[run[pos]] ??= []).add(e);
            }
          }
        } else {
          inOrder = true;
          final keyable = [
            for (var i = 0; i < items.length; i++)
              if (!isFree(items[i].type)) i,
          ];
          for (final (k, e) in read.entries.indexed) {
            if (k < keyable.length) (assigned[keyable[k]] ??= []).add(e);
          }
        }
      }
    }

    return [
      for (var i = 0; i < items.length; i++)
        _row(i, items[i], assigned[i] ?? const [], inOrder),
    ];
  }

  static AnswerSheetRow _row(
    int i,
    QuestionBankItem item,
    List<AnswerSheetEntry> entries,
    bool inOrder,
  ) {
    final values = {for (final e in entries) e.value};
    var issue = AnswerSheetIssue.none;
    if (values.length > 1) {
      issue = AnswerSheetIssue.readTwice;
    } else if (inOrder && entries.isNotEmpty) {
      issue = AnswerSheetIssue.matchedInOrder;
    }
    return AnswerSheetRow(
      number: i + 1,
      item: item,
      read: entries.isEmpty ? '' : _display(item, entries.last.value),
      current: SheetAnswerKeyPlan.keyFor(item) ?? '',
      readIssue: issue,
      heading: entries.isEmpty ? '' : entries.last.heading,
    );
  }

  /// Runs of questions with the same part heading, in sheet order.
  static List<List<int>> _runs(QuestionBankSheet sheet) {
    final out = <List<int>>[];
    String? last;
    for (var i = 0; i < sheet.items.length; i++) {
      final s = sheet.items[i].section?.trim() ?? '';
      if (out.isEmpty || s != last) out.add([]);
      out.last.add(i);
      last = s;
    }
    return out;
  }

  /// The printed answer in the form the check screen edits: a choice as
  /// its letter (or √ / ×), blanks with ` | ` between them.
  static String _display(QuestionBankItem item, String value) {
    if (isChoice(item.type)) {
      final index = choiceIndex(item, value);
      if (index != null && index < item.question.options.length) {
        return _isTrueFalse(item) ? (index == 0 ? '√' : '×') : String.fromCharCode(65 + index);
      }
      return value;
    }
    if (item.type == ExerciseType.fillBlanks) {
      final parts = blankAnswers(item, value);
      if (parts != null) return parts.join(' | ');
    }
    return value;
  }

  static bool _isTrueFalse(QuestionBankItem item) =>
      item.question.options.length == 2 &&
      item.question.options.join() == QuestionImportUtils.trueFalseOptions.join();

  static final _strip = RegExp(r'[\s。，,.!?！？、；;：:“”"‘’（）()]');

  /// The choice a printed answer names: a letter (`A`, `(B)`, `C 苹果`),
  /// a true/false mark, or the text of exactly one choice.
  static int? choiceIndex(QuestionBankItem item, String value) {
    final v = value.trim();
    if (v.isEmpty) return null;
    final letter = RegExp(r'^[（(]?([A-Fa-f])[)）]?(?:$|[\s.、:：])').firstMatch(v);
    if (letter != null) return letter.group(1)!.toUpperCase().codeUnitAt(0) - 65;
    final mark = AnswerKeyParser.parse('1 $v')[1];
    if (mark != null && RegExp(r'^[√✓✔×✗✘xX对错]$|^(TRUE|FALSE|BENAR|SALAH)$', caseSensitive: false).hasMatch(v)) {
      return mark;
    }
    final bare = v.replaceAll(_strip, '');
    if (bare.isEmpty) return null;
    final hits = [
      for (final (i, o) in item.question.options.indexed)
        if (o.replaceAll(_strip, '') == bare) i,
    ];
    return hits.length == 1 ? hits.single : null;
  }

  /// One answer per blank: `两点 | 三点`, `两点；三点`, `两点，三点` or
  /// `两点 三点`; null when no way of splitting gives the number of blanks.
  static List<String>? blankAnswers(QuestionBankItem item, String value) {
    final blanks = ExerciseType.blankMark.allMatches(item.question.prompt).length;
    if (blanks == 0) return null;
    for (final sep in [
      RegExp(r'\s*[|｜]\s*'),
      RegExp(r'\s*[;；]\s*'),
      RegExp(r'\s*[,，、]\s*'),
      RegExp(r'\s+'),
    ]) {
      final parts = [
        for (final p in value.split(sep))
          if (p.trim().isNotEmpty) p.trim(),
      ];
      if (parts.length == blanks) return parts;
      if (blanks == 1 && parts.length > 1 && sep.pattern.contains('|')) return null;
    }
    return null;
  }

  static final _hanzi = RegExp(r'[一-鿿]');
  static final _latin = RegExp(r'[A-Za-zāáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜü]');

  /// What [value] would do to [item]; [current] is its key now.
  static AnswerSheetVerdict evaluate(
    QuestionBankItem item,
    String value, {
    required String current,
  }) {
    final v = value.trim();
    if (isFree(item.type)) return const AnswerSheetVerdict(AnswerSheetStatus.free);
    if (v.isEmpty) return const AnswerSheetVerdict(AnswerSheetStatus.missing);
    final q = item.question;

    if (isChoice(item.type)) {
      final index = choiceIndex(item, v);
      if (index == null) {
        return const AnswerSheetVerdict(AnswerSheetStatus.check, AnswerSheetIssue.notAChoice);
      }
      if (index >= q.options.length) {
        return const AnswerSheetVerdict(AnswerSheetStatus.check, AnswerSheetIssue.pastLastChoice);
      }
      final same = q.correctIndex == index && current.isNotEmpty;
      return AnswerSheetVerdict(
          same ? AnswerSheetStatus.same : AnswerSheetStatus.changed, AnswerSheetIssue.none, index);
    }

    switch (item.type) {
      case ExerciseType.composeSentences:
        final ordered = AnswerKeyParser.orderSegments(q.segments, v);
        if (ordered == null) {
          return const AnswerSheetVerdict(AnswerSheetStatus.check, AnswerSheetIssue.wordsDoNotMatch);
        }
        final same = ordered.join('\u0000') == q.segments.join('\u0000');
        return AnswerSheetVerdict(same ? AnswerSheetStatus.same : AnswerSheetStatus.changed,
            AnswerSheetIssue.none, null, v);
      case ExerciseType.typeHanzi || ExerciseType.typePinyin:
        final wantHanzi = item.type == ExerciseType.typeHanzi;
        if (wantHanzi ? !_hanzi.hasMatch(v) : !_latin.hasMatch(v)) {
          return const AnswerSheetVerdict(AnswerSheetStatus.check, AnswerSheetIssue.wrongScript);
        }
        final accepted = SheetAnswerKeyPlan.alternatives(v);
        final same = accepted.join('\u0000') ==
            [for (final o in q.options) if (o.trim().isNotEmpty) o.trim()].join('\u0000');
        return AnswerSheetVerdict(same ? AnswerSheetStatus.same : AnswerSheetStatus.changed,
            AnswerSheetIssue.none, null, accepted.join(' / '));
      case ExerciseType.fillBlanks:
        final parts = blankAnswers(item, v);
        if (parts == null) {
          return const AnswerSheetVerdict(AnswerSheetStatus.check, AnswerSheetIssue.blankCount);
        }
        final same = parts.join('\u0000') == q.options.join('\u0000');
        return AnswerSheetVerdict(same ? AnswerSheetStatus.same : AnswerSheetStatus.changed,
            AnswerSheetIssue.none, null, parts.join(' | '));
      default:
        return const AnswerSheetVerdict(AnswerSheetStatus.free);
    }
  }

  /// What Save writes: only the rows whose key changes, through the same
  /// plan as the Answer key dialog.
  static SheetAnswerKeyPlan plan(QuestionBankSheet sheet, List<AnswerSheetRow> rows) {
    final choices = <int, int>{};
    final written = <int, String>{};
    for (final r in rows) {
      final v = r.verdict;
      if (v.status != AnswerSheetStatus.changed) continue;
      if (v.choice != null) choices[r.number] = v.choice!;
      if (v.written != null) written[r.number] = v.written!;
    }
    return SheetAnswerKeyPlan.of(sheet, choices: choices, written: written);
  }

  /// Counts per status, for the summary line.
  static Map<AnswerSheetStatus, int> counts(List<AnswerSheetRow> rows) {
    final out = {for (final s in AnswerSheetStatus.values) s: 0};
    for (final r in rows) {
      out[r.verdict.status] = out[r.verdict.status]! + 1;
    }
    return out;
  }
}
