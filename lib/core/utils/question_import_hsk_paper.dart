part of 'question_import_utils.dart';

/// One numbered question as found in the page texts.
class _HskRawItem {
  _HskRawItem(this.number, this.page, {this.unsure = false});

  final int number;
  final int page;
  final bool unsure;

  /// Text lines of the question (passage, sentence, ★ line), spaces kept.
  final List<String> lines = [];

  /// Lines carrying its own lettered choices.
  final List<String> optionLines = [];

  /// Pinyin printed above a character gap.
  String pinyin = '';
}

/// A `第 a-b 题` block of the paper.
class _HskRange {
  _HskRange(this.start, this.end, this.section, this.page);

  final int start;
  final int end;
  final String section;
  final int page;

  /// Lettered choices shared by the block (sentences A–F, word bank).
  final List<String> sharedOptionLines = [];
  final List<_HskRawItem> items = [];
  int expected = 0;
}

/// Builds the parts and questions of a whole HSK paper from the text of its
/// pages (docs/PLAN.md, Build 1B, Must 3). The reader's numbers are not
/// trusted blindly: inside a `第 a-b 题` block every numbered line takes the
/// next number of the block when its printed digits do not fit (an OCR
/// `S1.` for `51.`), and every number the level's format expects gets a
/// slot even when no line was read for it.
class _HskPaperParser {
  _HskPaperParser(this.pages);

  final List<String> pages;

  static final _range = RegExp(r'第\s*(\d{1,2})\s*[-–—~～]\s*(\d{1,2})\s*题');
  static final _skillHeading =
      RegExp(r'^\s*([一二三四])\s*[、，,.．]?\s*(听\s*力|阅\s*读|书\s*写)');
  static final _partHeading = RegExp(r'^\s*第\s*([一二三四五])\s*部\s*分');
  static final _numbered = RegExp(
      r'^\s*[(（]?\s*([0-9OoSsIl|Zz]{1,2})\s*(?:[\.．、，,:：)）]|\s+(?=\S))\s*(.*)$');
  static final _example = RegExp(r'^\s*例\s*如');
  // `A:` / `B:` start the lines of a dialogue, not choices.
  // A letter may carry a quote mark the engine glued to it (`”C`).
  static final _letterToken = RegExp(r'^["“”]?([A-F])[\.．]?$');

  /// What the engine reads for a choice letter on a one-line word bank
  /// (measured on H326202Z, docs/PLAN.md §6).
  static const _letterMisreads = <String, Set<String>>{
    'B': {'8', 'BB'},
    'C': {'CC', '(', 'c'},
    'D': {'DD', 'O'},
    'E': {'王', 'EE', '巳'},
    'F': {'下', 'FF', 'r'},
  };
  // "下面是书写部分", "请在书写考试开始后作答": pages between parts.
  static final _between = RegExp(r'下\s*面\s*是.*部\s*分|请\s*在.*作\s*答');
  // What the engine makes of a printed ★.
  static final _starNoise = RegExp(r'^[★☆*%YK广友让X]\s+');
  static final _pinyinOnly = RegExp(r'^[a-zA-Züāáǎàēéěèīíǐìōóǒòūúǔù]{1,8}$');
  static final _code = RegExp(r'H\s*(\d)\s*(\d{5})\s*([A-Z])');
  static final _levelWord = RegExp(r'HSK\s*[（(]\s*([一二三四五六])\s*级');
  static final _cjk = RegExp(r'[一-鿿]');

  static const _chineseDigits = {
    '一': 1, '二': 2, '三': 3, '四': 4, '五': 5, '六': 6,
  };

  HskPaperDraft build() {
    final (code, level) = _codeAndLevel();
    final ranges = <_HskRange>[];
    var skillHeading = '';
    var partHeading = '';
    _HskRange? current;
    _HskRawItem? item;
    var inExample = false;
    var pendingPinyin = '';

    for (var p = 0; p < pages.length; p++) {
      final pageNo = p + 1;
      for (final raw in pages[p].split('\n')) {
        final line = raw.trim();
        if (line.isEmpty) continue;
        final joined = QuestionImportUtils.joinCjkSpaces(line);

        final skill = _skillHeading.firstMatch(joined);
        if (skill != null) {
          skillHeading = '${skill.group(1)}、${skill.group(2)!.replaceAll(' ', '')}';
          partHeading = '';
          continue;
        }
        final part = _partHeading.firstMatch(joined);
        if (part != null && !_range.hasMatch(joined)) {
          partHeading = '第${part.group(1)}部分';
          continue;
        }
        final range = _range.firstMatch(joined);
        if (range != null && joined.length <= 16) {
          final a = int.parse(range.group(1)!);
          final b = int.parse(range.group(2)!);
          if (b >= a) {
            final section = [
              if (skillHeading.isNotEmpty) skillHeading,
              if (partHeading.isNotEmpty) partHeading,
              '第$a-$b题',
            ].join(' · ');
            current = _HskRange(a, b, section, pageNo)..expected = a;
            ranges.add(current);
            item = null;
            inExample = false;
            pendingPinyin = '';
          }
          continue;
        }
        if (current == null) continue; // cover and instruction pages
        if (_between.hasMatch(joined)) {
          item = null;
          continue;
        }
        if (_example.hasMatch(joined)) {
          inExample = true;
          pendingPinyin = '';
          continue;
        }

        final numbered = _numbered.firstMatch(line);
        final number = numbered == null ? null : _readNumber(numbered.group(1)!);
        if (number != null) {
          final assigned = _assign(current, number);
          if (assigned != null) {
            inExample = false;
            item = _HskRawItem(assigned.$1, pageNo, unsure: assigned.$2);
            if (pendingPinyin.isNotEmpty) {
              item.pinyin = pendingPinyin;
              pendingPinyin = '';
            }
            current.items.add(item);
            final rest = numbered!.group(2)!.trim();
            if (rest.isNotEmpty) {
              if (_markers(rest).length >= 2) {
                item.optionLines.add(rest);
              } else {
                item.lines.add(rest);
              }
            }
            continue;
          }
        }
        final tokens = line.split(RegExp(r'\s+'));
        if (tokens.length == 1 && _pinyinOnly.hasMatch(tokens.single)) {
          // The pinyin above a gap ends an example and belongs to the next
          // numbered line.
          inExample = false;
          pendingPinyin = tokens.single;
          continue;
        }
        if (inExample) continue;
        final markers = _markers(line);
        // Answer-sheet rules, page codes, stray marks: no Chinese, or rule
        // marks (the last line of a passage can be a single `了。`).
        if (markers.isEmpty &&
            (!_cjk.hasMatch(line) || RegExp(r'[-~=_]{3,}').hasMatch(line))) {
          continue;
        }
        final isOptions = markers.length >= 2 ||
            (markers.isNotEmpty && markers.first.$1 == 0);
        if (item == null) {
          if (isOptions) current.sharedOptionLines.add(line);
          continue;
        }
        if (isOptions) {
          item.optionLines.add(line);
        } else {
          item.lines.add(line);
        }
      }
    }

    return _toDraft(code, level, ranges);
  }

  /// Digits of a printed number, with the engine's usual misreads.
  static int? _readNumber(String token) {
    if (!token.contains(RegExp(r'\d'))) return null;
    final fixed = token
        .replaceAll(RegExp('[Oo]'), '0')
        .replaceAll(RegExp('[Ss]'), '5')
        .replaceAll(RegExp('[Il|]'), '1')
        .replaceAll(RegExp('[Zz]'), '2');
    return int.tryParse(fixed);
  }

  /// The number a numbered line stands for in its block: the printed one
  /// when it fits, else the next free one (marked unsure); null when the
  /// block is full (a stray line).
  static (int, bool)? _assign(_HskRange range, int printed) {
    if (range.expected > range.end) return null;
    // At most two lines can be lost between two read ones; a bigger jump
    // is a misread digit (or a stray mark on a picture page).
    final last = range.expected + 2 < range.end ? range.expected + 2 : range.end;
    if (printed >= range.expected && printed <= last) {
      range.expected = printed + 1;
      return (printed, false);
    }
    final n = range.expected;
    range.expected = n + 1;
    return (n, true);
  }

  /// Positions (token index) and letters of the choice markers of a line.
  static List<(int, String)> _markers(String line) {
    final tokens = line.split(RegExp(r'\s+'));
    return [
      for (var i = 0; i < tokens.length; i++)
        if (_letterToken.firstMatch(tokens[i]) case final m?) (i, m.group(1)!),
    ];
  }

  /// Lettered choices of some lines, by letter: `A 天 气 很 好 B …` →
  /// {A: 天气很好, B: …}. A letter the engine misread is absent.
  static Map<String, String> _options(List<String> lines) {
    final out = <String, String>{};
    for (final line in lines) {
      final tokens = line.split(RegExp(r'\s+'));
      // A word bank on one line (`A 喝 B 看 CC 买 D 去 王 吃 下 走`):
      // where the next letter is due, a token the engine often reads for
      // that letter counts as the letter.
      final banked = _markers(line).length >= 2;
      String? letter;
      final buffer = <String>[];
      void flush() {
        final l = letter;
        if (l != null && buffer.isNotEmpty) {
          out[l] = QuestionImportUtils.joinCjkSpaces(buffer.join(' '))
              .replaceAll(RegExp(r'^["“”]+|[\s.·]+$'), '')
              .trim();
        }
        buffer.clear();
      }

      for (final t in tokens) {
        final m = _letterToken.firstMatch(t);
        final next = letter == null
            ? null
            : String.fromCharCode(letter.codeUnitAt(0) + 1);
        if (m != null) {
          flush();
          letter = m.group(1);
        } else if (banked &&
            next != null &&
            buffer.isNotEmpty &&
            (_letterMisreads[next]?.contains(t) ?? false)) {
          flush();
          letter = next;
        } else if (letter != null) {
          buffer.add(t);
        }
      }
      flush();
    }
    return out;
  }

  /// Letters A… up to the last one found; a gap is an empty choice.
  static (List<String>, bool incomplete) _optionList(Map<String, String> byLetter) {
    if (byLetter.isEmpty) return (const [], false);
    final last = byLetter.keys.map((k) => k.codeUnitAt(0)).reduce((a, b) => a > b ? a : b);
    final list = <String>[];
    var incomplete = false;
    for (var c = 65; c <= last; c++) {
      final text = byLetter[String.fromCharCode(c)] ?? '';
      if (text.isEmpty) incomplete = true;
      list.add(text);
    }
    return (list, incomplete);
  }

  (String, int?) _codeAndLevel() {
    final votes = <String, int>{};
    int? levelWord;
    for (final page in pages) {
      for (final m in _code.allMatches(page)) {
        final code = 'H${m.group(1)}${m.group(2)}${m.group(3)}';
        votes[code] = (votes[code] ?? 0) + 1;
      }
      final w = _levelWord.firstMatch(QuestionImportUtils.joinCjkSpaces(page));
      if (w != null) levelWord ??= _chineseDigits[w.group(1)];
    }
    if (votes.isEmpty) return ('', levelWord);
    final code = (votes.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .first
        .key;
    final level = int.tryParse(code.substring(1, 2));
    return (
      code,
      level != null && level >= 1 && level <= 6 ? level : levelWord,
    );
  }

  HskPaperDraft _toDraft(String code, int? level, List<_HskRange> ranges) {
    // Questions per skill from the level's standard format.
    final format = level == null
        ? null
        : standardTestFormats()
            .where((f) => f.family == TestFamily.hsk && f.levelKey == '$level')
            .firstOrNull;
    final expected = <String, int>{};
    final skillOf = <int, String>{};
    var total = 0;
    if (format != null) {
      for (final part in format.parts) {
        final skill = part.skill.value;
        expected[skill] = (expected[skill] ?? 0) + part.questions;
        for (var i = 0; i < part.questions; i++) {
          skillOf[++total] = skill;
        }
      }
    } else {
      for (final r in ranges) {
        if (r.end > total) total = r.end;
      }
    }

    final rangeOf = <int, _HskRange>{};
    for (final r in ranges) {
      for (var n = r.start; n <= r.end; n++) {
        rangeOf.putIfAbsent(n, () => r);
      }
    }
    final itemOf = <int, _HskRawItem>{};
    for (final r in ranges) {
      for (final it in r.items) {
        itemOf.putIfAbsent(it.number, () => it);
      }
    }

    final slots = <HskSlot>[];
    for (var n = 1; n <= total; n++) {
      final range = rangeOf[n];
      final skill = skillOf[n] ?? _skillFromSection(range?.section ?? '');
      final raw = itemOf[n];
      final slot = HskSlot(
        number: n,
        skill: skill,
        section: range?.section ?? '',
        page: raw?.page ?? range?.page ?? 0,
        missing: raw == null,
        unsure: raw?.unsure ?? false,
      );
      _fill(slot, raw, range);
      slots.add(slot);
    }
    // A missing slot takes the form most of its block has.
    for (final slot in slots.where((s) => s.missing)) {
      final range = rangeOf[slot.number];
      if (range == null) continue;
      final forms = <String, int>{};
      for (final s in slots) {
        if (!s.missing && rangeOf[s.number] == range) {
          forms[s.form] = (forms[s.form] ?? 0) + 1;
        }
      }
      if (forms.isEmpty) continue;
      slot.form = (forms.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value)))
          .first
          .key;
      if (slot.form == HskForm.picture) slot.picturePage = range.page;
      if (slot.form == HskForm.matching || slot.form == HskForm.wordBank) {
        final (shared, incomplete) =
            _optionList(_options(range.sharedOptionLines));
        final needed = range.end - range.start + 1;
        slot.options = [
          ...shared,
          for (var i = shared.length; i < needed; i++) '',
        ];
        slot.optionsIncomplete = incomplete || shared.length < needed;
      }
    }
    // Questions of one block have as many choices as each other (A B C on
    // HSK 3): a shorter list lost a letter.
    for (final range in ranges) {
      final block = [
        for (final s in slots)
          if (rangeOf[s.number] == range && s.form == HskForm.choice) s,
      ];
      if (block.length < 2) continue;
      final counts = <int, int>{};
      for (final s in block) {
        counts[s.options.length] = (counts[s.options.length] ?? 0) + 1;
      }
      final usual = (counts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value)))
          .first
          .key;
      for (final s in block) {
        if (s.options.isNotEmpty && s.options.length < usual) {
          s.options = [
            ...s.options,
            for (var i = s.options.length; i < usual; i++) '',
          ];
          s.optionsIncomplete = true;
        }
      }
    }
    return HskPaperDraft(
      code: code,
      level: level,
      title: [if (level != null) 'HSK $level', if (code.isNotEmpty) code]
          .join(' · '),
      slots: slots,
      expected: expected,
    );
  }

  static String _skillFromSection(String section) {
    if (section.contains('听力')) return 'listening';
    if (section.contains('书写')) return 'writing';
    return 'reading';
  }

  /// Decides the form of one question and fills its fields.
  void _fill(HskSlot slot, _HskRawItem? raw, _HskRange? range) {
    final shared = range == null
        ? const <String, String>{}
        : _options(range.sharedOptionLines);
    if (raw == null) return;
    final text = raw.lines.join('\n');
    // Each printed line joined on its own (the engine's spaces between
    // characters go); wrapped lines of a passage run on, and the last line
    // stays apart when the question has its own choices (passage, then
    // the ★ question).
    final lines = [
      for (final l in raw.lines)
        QuestionImportUtils.joinCjkSpaces(l.replaceFirst(_starNoise, '★ ')),
    ];
    final own = _options(raw.optionLines);
    final body = own.length >= 2 && lines.length >= 2
        ? '${lines.sublist(0, lines.length - 1).join()}\n${lines.last}'
        : lines.join();
    final joined = _cleanTail(_normalizeGaps(body)
        .replaceFirst(RegExp(r'^[\s，,、.．:：]+'), '')
        .trim());
    final cjkCount = _cjk.allMatches(joined).length;

    if (slot.skill == 'writing') {
      if (raw.pinyin.isNotEmpty || joined.contains('（ ）')) {
        slot.form = HskForm.pinyinChar;
        slot.keyword = raw.pinyin;
        slot.prompt = joined;
        if (raw.pinyin.isEmpty) slot.unsure = true;
        return;
      }
      slot.form = HskForm.reorder;
      slot.segments = [
        for (final t in text.split(RegExp(r'\s+')))
          if (t.replaceAll(RegExp(r'["“”‘’「」。，,.·\-]'), '').isNotEmpty)
            t.replaceAll(RegExp(r'["“”‘’「」]'), ''),
      ];
      return;
    }

    if (own.length >= 2) {
      final (list, incomplete) = _optionList(own);
      slot.form = HskForm.choice;
      slot.options = list;
      slot.optionsIncomplete = incomplete;
      slot.prompt = joined;
      return;
    }
    // A listening line with no real sentence is a picture question (the
    // engine finds stray marks on a picture page).
    if (slot.skill == 'listening' && cjkCount < 4) {
      slot.form = HskForm.picture;
      slot.picturePage = range?.page ?? raw.page;
      return;
    }
    if (slot.skill == 'listening' || joined.contains('★')) {
      // A listening statement to judge (★ … ( )); the ★ is often misread.
      slot.form = HskForm.trueFalse;
      final statement = joined.contains('★')
          ? joined.substring(joined.indexOf('★') + 1)
          : joined;
      // Stray Latin marks before the statement (`★ Kk 说话人…`).
      slot.prompt = '★ ${statement.trim().replaceFirst(RegExp(r'^[A-Za-z]{1,3}\s+'), '')}';
      return;
    }
    if (shared.length >= 2) {
      var (list, incomplete) = _optionList(shared);
      // A shared list has at least one choice per question of its block; a
      // shorter one lost its last letters (an `E` read as `王`).
      final needed = range == null ? 0 : range.end - range.start + 1;
      if (list.length < needed) {
        list = [...list, for (var i = list.length; i < needed; i++) ''];
        incomplete = true;
      }
      // A gap inside the sentence takes a word from the bank; a bracket at
      // the end is where the letter of a matching sentence goes.
      slot.form = _hasMidGap(joined) ? HskForm.wordBank : HskForm.matching;
      slot.options = list;
      slot.optionsIncomplete = incomplete;
      slot.prompt = joined;
      return;
    }
    slot.form = HskForm.choice;
    slot.prompt = joined;
  }

  /// A gap with words after it (not only the answer bracket at the end).
  static bool _hasMidGap(String text) {
    final i = text.indexOf('（ ）');
    if (i < 0) return false;
    final after = text.substring(i + 3).replaceAll(RegExp(r'[\s。，,.!?！？]'), '');
    return after.isNotEmpty;
  }

  /// What the engine leaves after the last sentence mark: half an answer
  /// bracket (`… (`, `… ？(0`) or a Latin mark or two (`… 水？CC`).
  static String _cleanTail(String text) => text
      .replaceFirst(RegExp(r'\s*[(（〈][^)）]{0,2}$'), '')
      .replaceFirst(RegExp(r'(?<=[。？！?!])\s*[A-Za-z0-9]{1,3}$'), '')
      .trim();

  /// `〈 )`, `( )`, a lone `)` → the gap mark `（ ）`.
  static String _normalizeGaps(String text) {
    var out = text.replaceAll(RegExp(r'[（(〈<]\s*[-_—]*\s*[)）]'), '（ ）');
    if (!out.contains('（ ）') && !out.contains(RegExp(r'[(（]'))) {
      out = out.replaceFirst(RegExp(r'\s*[)）]'), '（ ）');
    }
    // The engine's spaces around the gap go too (the brackets are not
    // Chinese characters, so joinCjkSpaces leaves them).
    return out.replaceAll(RegExp(r'\s*（ ）\s*'), '（ ）');
  }
}
