part of 'question_import_utils.dart';

/// The textbook pages of an HSK Standard Course lesson (owner 2026-11-25)
/// as one text the students read while doing the workbook questions: the
/// dialogues (课文) with their headings, then the new words (生词) with
/// pinyin and meaning. Built from the reader's page texts, where a tab
/// marks a wide gap between the dialogue column and the new-words box.
/// The warm-up before the first dialogue and the pinyin texts after the
/// last one are left out. The admin corrects the result on the
/// proofreading screen, so a stray word here and there is expected.
abstract final class StandardCourseText {
  // `01-1`: the track of a dialogue, printed at its heading.
  static final _track = RegExp(r'(?<!\d)\d{2}\s*-\s*\d(?!\d)');
  static final _speaker = RegExp(r'^([一-鿿]{1,4})\s*[：:]\s*(.+)$');
  static final _word =
      RegExp(r'^(\d{1,2})\s*[\.．]\s*([一-鿿][一-鿿（）()]{0,7})\s*(.*)$');
  // A new word glued to the end of a dialogue line (`吃饭、 1.周末`).
  static final _wordInLine = RegExp(r'\s(?=\d{1,2}\s*[\.．]\s*[一-鿿])');
  static final _meaning = RegExp(
      r'^(n|v|adj|adv|prep|part|conj|pron|num|m|mw|int|aux|n\./v)\s*\.',
      caseSensitive: false);
  static final _toneMark = RegExp(r'[āáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜ]');
  static final _onlyText =
      RegExp(r'^[一-鿿，。、？！?!,.\s“”"…：:；;（）()《》—]+$');
  static final _cjk = RegExp(r'[一-鿿]');
  static final _labels =
      RegExp(r'生\s*词|New\s*Words|专\s*有\s*名\s*词|Proper\s*Nouns');

  static String fromPages(List<String> pages) {
    final dialogue = <String>[];
    final words = <int, String>{};
    final proper = <String>[];
    String? lastWordKey; // 'w3' or 'p1': where a meaning line goes
    var started = false;
    var texts = 0;
    var inProper = false;
    String? pending; // a continuation line waiting for the next line

    void flushPending({String? next}) {
      final p = pending;
      pending = null;
      if (p == null || dialogue.isEmpty) return;
      final current = dialogue.last;
      // The engine reads some lines twice (once cut short): drop a line
      // the utterance already has, or one the next line repeats.
      final chars = _cjk.allMatches(p).map((m) => m.group(0)!).toList();
      final seen = chars.where(current.contains).length;
      if (chars.isNotEmpty && seen / chars.length >= 0.8) return;
      // A line cut short and read again whole on the next line.
      String bare(String t) => _cjk.allMatches(t).map((m) => m.group(0)!).join();
      if (next != null && bare(p).isNotEmpty && bare(next).contains(bare(p))) return;
      dialogue[dialogue.length - 1] = '$current$p';
    }

    void addWord(String entry) {
      final m = _word.firstMatch(entry.trim());
      if (m == null) return;
      final n = int.parse(m.group(1)!);
      final hanzi = m.group(2)!;
      final rest = m.group(3)!.trim();
      final pinyin = rest.split(RegExp(r'\s{2,}|\s(?=[A-Z])')).first.trim();
      final line = [hanzi, if (pinyin.isNotEmpty) pinyin].join(' ');
      if (inProper) {
        proper.add(line);
        lastWordKey = 'p${proper.length - 1}';
        return;
      }
      final old = words[n];
      // The same number read twice: keep the reading with tone marks.
      if (old == null || (!_toneMark.hasMatch(old) && _toneMark.hasMatch(line))) {
        words[n] = line;
      }
      lastWordKey = 'w$n';
    }

    void addMeaning(String text) {
      final key = lastWordKey;
      if (key == null) return;
      final i = int.parse(key.substring(1));
      if (key.startsWith('p')) {
        if (!proper[i].contains(' — ')) proper[i] = '${proper[i]} — $text';
      } else if (words[i] != null && !words[i]!.contains(' — ')) {
        words[i] = '${words[i]} — $text';
      }
    }

    for (final page in pages) {
      for (final raw in page.split('\n')) {
        final whole = raw.replaceAll('\t', ' ').trim();
        if (whole.isEmpty) continue;
        if (whole.contains('拼音课文') ||
            RegExp(r'Texts\s+in\s+pinyin', caseSensitive: false)
                .hasMatch(whole)) {
          flushPending();
          return _compose(dialogue, words, proper);
        }
        if (whole.contains('专有名词') || whole.contains('Proper Nouns')) {
          inProper = true;
        } else if (whole.contains('生词') || whole.contains('New Words')) {
          inProper = false;
        }
        // A dialogue heading: `1 谈周末的打算 Talking about … 01-1`.
        final track = _track.firstMatch(whole);
        if (track != null) {
          flushPending();
          texts++;
          final before = QuestionImportUtils.joinCjkSpaces(
              whole.substring(0, track.start));
          final title = RegExp(r'[一-鿿]{2,}').firstMatch(before)?.group(0);
          dialogue.add('');
          dialogue.add('$texts. ${title ?? '课文 $texts'}');
          started = true;
          inProper = false;
          continue;
        }
        if (!started) continue;

        // Columns: the dialogue on the left, new words on the right.
        final cols = raw.split('\t').map((c) => c.trim()).toList();
        var left = cols.first;
        final right = <String>[...cols.skip(1)];
        final cut = _wordInLine.firstMatch(left);
        if (cut != null) {
          final head = left.substring(0, cut.start);
          if (_speaker.hasMatch(head) ||
              _onlyText.hasMatch(QuestionImportUtils.joinCjkSpaces(head))) {
            right.insert(0, left.substring(cut.start).trim());
            left = head;
          }
        }
        final labelAt = _labels.firstMatch(left);
        if (labelAt != null) left = left.substring(0, labelAt.start);
        final leftText = QuestionImportUtils.joinCjkSpaces(left.trim());
        final leftIsWord = _word.hasMatch(leftText);
        if (leftIsWord) addWord(leftText);
        for (final r in right) {
          final t = r.replaceAll(_labels, '').trim();
          if (t.isEmpty) continue;
          if (_word.hasMatch(t)) {
            addWord(t);
          } else if (_meaning.hasMatch(t)) {
            addMeaning(t);
          }
        }

        final text = leftText;
        if (text.isEmpty || leftIsWord) continue;
        if (_meaning.hasMatch(text)) {
          addMeaning(text);
          continue;
        }
        final speaker = _speaker.firstMatch(text);
        if (speaker != null && _cjk.hasMatch(speaker.group(2)!)) {
          flushPending(next: speaker.group(2));
          final line = '${speaker.group(1)}：${speaker.group(2)!.trim()}';
          // The same speaker's line read again, cut short.
          String bare(String t) =>
              _cjk.allMatches(t).map((m) => m.group(0)!).join();
          if (dialogue.isNotEmpty &&
              dialogue.last.startsWith('${speaker.group(1)}：') &&
              bare(dialogue.last).contains(bare(line))) {
            continue;
          }
          dialogue.add(line);
          continue;
        }
        // Scattered single characters (`丽。 如 中 脑 地 四`): picture noise.
        final tokens = left.trim().split(RegExp(r'\s+'));
        if (tokens.length >= 4 &&
            tokens.where((t) => _cjk.allMatches(t).length <= 1).length >=
                tokens.length * 0.75) {
          continue;
        }
        // A wrapped dialogue line: Chinese and punctuation only.
        if (dialogue.isNotEmpty &&
            dialogue.last.isNotEmpty &&
            _onlyText.hasMatch(text) &&
            _cjk.allMatches(text).length >= 2) {
          flushPending(next: text);
          pending = text;
        }
      }
    }
    flushPending();
    return _compose(dialogue, words, proper);
  }

  static String _compose(
    List<String> dialogue,
    Map<int, String> words,
    List<String> proper,
  ) {
    final out = <String>[
      ...dialogue.skipWhile((l) => l.isEmpty),
      if (words.isNotEmpty) ...[
        '',
        '生词 New Words',
        for (final n in (words.keys.toList()..sort())) '$n. ${words[n]}',
      ],
      if (proper.isNotEmpty) ...[
        '',
        '专有名词 Proper Nouns',
        ...proper,
      ],
    ];
    return out.join('\n').trim();
  }
}
