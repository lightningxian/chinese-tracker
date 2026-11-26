/// Reads the text of an answer-sheet PDF (owner 2026-11-26: "I have the
/// pdf, just need to upload it … the work of admin is just checking").
///
/// The PDFs are made on a computer (the text can be selected), one PDF per
/// worksheet: an official HSK key (`1. √ 2. × … 41. A 42. C`, often with
/// the listening script before or after it), a Standard Course workbook
/// key (blocks `一、1. B 2. A  二、1. 你好 …`, numbering starting again in
/// each block) or a key typed by the centre. This reader only splits the
/// text into numbered entries; matching them to the worksheet's questions
/// and checking each one is done by `AnswerSheetCheck`.
///
/// What it understands:
/// - `1. A`, `1．A`, `1、A`, `1) A`, `(1) A`, `1 A`, `1.A2.C3.B` on one line;
/// - ranges `41-45 ECBAD`;
/// - a table: a line of numbers `1 2 3 4 5` with the answers on the next
///   line `√ × √ A C`;
/// - written answers `71. 小狗在桌子下面。`, `76. 名`, blanks `5. 两点；三点`;
/// - the listening script (`听力材料`, `听力文本`, `录音文本` …) is cut out
///   and returned on its own; when the PDF has an answer heading (`答案`,
///   `参考答案`, `Kunci jawaban`, `Answer key`) only the text under such a
///   heading is read, so a paper printed with its key reads the key only.
abstract final class AnswerSheetParser {
  /// The whole text read from the PDF, pages joined with a blank line.
  static AnswerSheetText parse(String raw) {
    final text = normalize(raw);
    final lines = text.split('\n');

    // 1. Regions: key text and listening script.
    final hasAnswerHeading = lines.any(_isAnswerHeading);
    var mode = hasAnswerHeading ? _Region.skip : _Region.key;
    final keyLines = <String>[];
    final scriptLines = <String>[];
    for (final line in lines) {
      if (_isAnswerHeading(line)) {
        mode = _Region.key;
        continue;
      }
      if (_isScriptHeading(line)) {
        mode = _Region.script;
        continue;
      }
      // A key printed after the script with no heading of its own.
      if (mode == _Region.script && _isChoiceKeyLine(line)) {
        mode = _Region.key;
      }
      switch (mode) {
        case _Region.key:
          keyLines.add(line);
        case _Region.script:
          scriptLines.add(line);
        case _Region.skip:
          break;
      }
    }

    // 2. Entries, line by line.
    final raws = <({int number, String value, String heading})>[];
    var heading = '';
    for (var i = 0; i < keyLines.length; i++) {
      final line = keyLines[i].trim();
      if (line.isEmpty) continue;
      // Table: numbers on this line, answers on the next.
      final numbers = _tableNumbers(line);
      if (numbers != null && i + 1 < keyLines.length) {
        final marks = keyLines[i + 1].trim().split(RegExp(r'\s+'));
        if (marks.length == numbers.length && _tableNumbers(keyLines[i + 1].trim()) == null) {
          for (var k = 0; k < numbers.length; k++) {
            raws.add((number: numbers[k], value: marks[k], heading: heading));
          }
          i++;
          continue;
        }
      }
      final found = _entriesOf(line);
      if (found.isEmpty) {
        if (_isBlockHeading(line)) heading = line;
        continue;
      }
      // A block heading on the same line as its first answers:
      // `一、1. × 2. √`, `第一部分 1. A`.
      final lead = _leadHeading.firstMatch(line)?.group(0)?.trim();
      if (lead != null && lead.isNotEmpty) heading = lead;
      for (final e in found) {
        raws.add((number: e.$1, value: e.$2, heading: heading));
      }
    }

    // 3. Blocks: the numbering starting again at 1 opens a new block.
    final entries = <AnswerSheetEntry>[];
    var block = 0;
    final seenInBlock = <int>{};
    for (final r in raws) {
      if (r.number == 1 && seenInBlock.isNotEmpty) {
        block++;
        seenInBlock.clear();
      }
      seenInBlock.add(r.number);
      entries.add(AnswerSheetEntry(
        number: r.number,
        value: r.value,
        block: block,
        heading: r.heading,
      ));
    }

    final script = scriptLines.join('\n').trim();
    return AnswerSheetText(
      entries: entries,
      script: script.isEmpty ? null : script,
    );
  }

  /// Full-width digits, letters and stops to plain ones; Windows line ends
  /// and no-break spaces to plain ones.
  static String normalize(String raw) {
    final b = StringBuffer();
    for (final r in raw.runes) {
      if (r >= 0xFF10 && r <= 0xFF19) {
        b.writeCharCode(r - 0xFF10 + 0x30); // ０-９
      } else if (r >= 0xFF21 && r <= 0xFF3A) {
        b.writeCharCode(r - 0xFF21 + 0x41); // Ａ-Ｚ
      } else if (r >= 0xFF41 && r <= 0xFF5A) {
        b.writeCharCode(r - 0xFF41 + 0x61); // ａ-ｚ
      } else if (r == 0xFF0E) {
        b.write('.'); // ．
      } else if (r == 0x00A0 || r == 0x3000 || r == 0x2002 || r == 0x2003) {
        b.write(' ');
      } else if (r == 0x0D) {
        // dropped: \r\n → \n
      } else {
        b.writeCharCode(r);
      }
    }
    return b.toString();
  }

  // ---- headings -------------------------------------------------------

  static final _answerWords =
      RegExp(r'答案|答\s*案|Kunci\s*jawaban|Answer\s*key|^\s*Answers?\s*$', caseSensitive: false);
  static final _scriptWords = RegExp(
    r'听力材料|听力文本|听力原文|录音文本|听力脚本|录音材料|听力内容|听力录音文本|Listening\s*script|Transcript|Skrip\s*(audio|listening|mendengar)',
    caseSensitive: false,
  );
  static final _sentencePunct = RegExp(r'[，。！？,!?；;]');

  /// A short line naming the key, not a sentence that mentions it
  /// (`请把答案写在答题卡上。`).
  static bool _isAnswerHeading(String line) {
    final t = line.trim();
    if (t.isEmpty || t.length > 20 || _sentencePunct.hasMatch(t)) return false;
    if (t.contains('答题卡')) return false;
    return _answerWords.hasMatch(t) && _entriesOf(t).isEmpty;
  }

  static bool _isScriptHeading(String line) {
    final t = line.trim();
    if (t.isEmpty || t.length > 24 || _sentencePunct.hasMatch(t)) return false;
    return _scriptWords.hasMatch(t) && _entriesOf(t).isEmpty;
  }

  static final _leadHeading = RegExp(
    r'^\s*(?:[一二三四五六七八九十]+\s*[、.]\s*[^\d\s]{0,8}|第\s*[一二三四五六七八九十\d]+\s*(?:部分|题|课|单元|Bagian)\s*|Part\s*\d+\s*|Bagian\s*\d+\s*)(?=\s*[（(]?\d)',
    caseSensitive: false,
  );

  static final _blockWords = RegExp(
    r'^\s*(?:[一二三四五六七八九十]+\s*[、.]|第\s*[一二三四五六七八九十\d]+\s*(?:部分|课|单元)|Part\s*\d|Bagian\s*\d|Bab\s*\d|Lesson\s*\d|听\s*力|阅\s*读|书\s*写)',
    caseSensitive: false,
  );

  static bool _isBlockHeading(String line) => _blockWords.hasMatch(line);

  // ---- entries --------------------------------------------------------

  static const _choiceMarks = 'A-Fa-f√✓✔×✗✘xX对错';

  static final _range = RegExp(
    r'(?<!\d)(\d{1,3})\s*[-–~到]\s*(\d{1,3})(?!\d)\s*[.、:：)）]?\s*((?:[' +
        _choiceMarks +
        r']\s*){2,})(?![A-Za-z一-鿿])',
  );

  /// A number that starts an entry: at the start of the line (any form), or
  /// further on when a stop follows it (`2.`, `2、`, `(2)`) or a lone choice
  /// mark does (`2 C`). A stop followed by a digit is a decimal, not a
  /// marker (`3.5`).
  static final _marker = RegExp(
    r'(?<!\d)(?:[（(](\d{1,3})[)）]|(\d{1,3})(?!\d)(?:\s*[.、:：)）](?!\d)|(?=\s+[' +
        _choiceMarks +
        r'](?![A-Za-z]))|(?=\s*[一-鿿])))',
  );

  /// `(number, value)` pairs of one line, in order.
  static List<(int, String)> _entriesOf(String line) {
    var rest = line;
    final found = <(int pos, int number, String value)>[];
    for (final m in _range.allMatches(line)) {
      final from = int.parse(m.group(1)!);
      final to = int.parse(m.group(2)!);
      final marks = m.group(3)!.replaceAll(RegExp(r'\s'), '');
      if (to < from || to - from + 1 != marks.length) continue;
      for (var i = 0; i < marks.length; i++) {
        found.add((m.start, from + i, marks[i]));
      }
      rest = rest.replaceRange(m.start, m.end, ' ' * (m.end - m.start));
    }
    final markers = <({int start, int end, int number})>[];
    for (final m in _marker.allMatches(rest)) {
      final n = int.parse(m.group(1) ?? m.group(2)!);
      final atStart = rest.substring(0, m.start).trim().isEmpty ||
          _leadHeading.hasMatch(rest.substring(0, m.end));
      final hasStop = m.group(1) != null ||
          RegExp(r'^\d{1,3}\s*[.、:：)）]').hasMatch(rest.substring(m.start));
      // Mid-line, a bare number before a character is part of an answer
      // (`两点 3点`), unless it is the next number in sequence with a stop.
      if (!atStart && !hasStop) {
        final after = rest.substring(m.end).trimLeft();
        final isMark = after.isNotEmpty &&
            RegExp('^[$_choiceMarks](?![A-Za-z])').hasMatch(after);
        if (!isMark) continue;
      }
      markers.add((start: m.start, end: m.end, number: n));
    }
    // Inside a written answer only the next number in sequence starts a
    // new entry (`1. 两点 2. 3点` → 3 stays inside the second answer).
    final kept = <({int start, int end, int number})>[];
    for (final k in markers) {
      if (kept.isEmpty || k.number == kept.last.number + 1 || _isChoiceRun(rest, kept.last, k)) {
        if (kept.isNotEmpty && k.start < kept.last.end) continue;
        kept.add(k);
      }
    }
    for (var i = 0; i < kept.length; i++) {
      final end = i + 1 < kept.length ? kept[i + 1].start : rest.length;
      final value = _cleanValue(rest.substring(kept[i].end, end));
      if (value.isEmpty) continue;
      found.add((kept[i].start, kept[i].number, value));
    }
    // Reading order (a range and single entries may share a line).
    found.sort((a, b) => a.$1.compareTo(b.$1));
    return [for (final f in found) (f.$2, f.$3)];
  }

  /// A line of the key itself: two or more entries that are all single
  /// choice marks (`1. √ 2. × 3. A`). A script line never looks like that.
  static bool _isChoiceKeyLine(String line) {
    final e = _entriesOf(line);
    return e.length >= 2 &&
        e.every((x) => RegExp('^[$_choiceMarks]\$').hasMatch(x.$2));
  }

  /// Out-of-order numbers are still entries when the value before is a
  /// single choice mark (two-column keys: `1. A 6. E`).
  static bool _isChoiceRun(
    String line,
    ({int start, int end, int number}) prev,
    ({int start, int end, int number}) next,
  ) {
    if (next.start <= prev.end) return false;
    final between = _cleanValue(line.substring(prev.end, next.start));
    return RegExp('^[$_choiceMarks]\$').hasMatch(between);
  }

  static String _cleanValue(String v) => v
      .trim()
      .replaceAll(RegExp(r'^[.、:：)）\s]+'), '')
      .replaceAll(RegExp(r'[\s,，;；]+$'), '')
      .trim();

  /// `1 2 3 4 5` (three or more numbers in a row, nothing else).
  static List<int>? _tableNumbers(String line) {
    if (!RegExp(r'^\d{1,3}(?:\s+\d{1,3}){2,}$').hasMatch(line)) return null;
    final nums = [for (final p in line.split(RegExp(r'\s+'))) int.parse(p)];
    for (var i = 1; i < nums.length; i++) {
      if (nums[i] != nums[i - 1] + 1) return null;
    }
    return nums;
  }
}

enum _Region { key, script, skip }

/// One numbered answer read from the PDF.
class AnswerSheetEntry {
  const AnswerSheetEntry({
    required this.number,
    required this.value,
    required this.block,
    this.heading = '',
  });

  /// The number printed in the key.
  final int number;

  /// What follows the number, as printed (`A`, `√`, `小狗在桌子下面。`).
  final String value;

  /// 0-based block: a new block starts where the numbering starts again
  /// at 1 (Standard Course keys number each exercise from 1).
  final int block;

  /// The last block heading seen above it (`一、听力`, `第二部分`), for
  /// the check screen only.
  final String heading;

  @override
  String toString() => '$block:$number=$value';
}

class AnswerSheetText {
  const AnswerSheetText({required this.entries, this.script});

  final List<AnswerSheetEntry> entries;

  /// The listening script found in the PDF, if any.
  final String? script;

  int get blockCount =>
      entries.isEmpty ? 0 : entries.map((e) => e.block).reduce((a, b) => a > b ? a : b) + 1;
}
