import 'pinyin_syllables.dart';

/// Cleans the text that comes out of a worksheet PDF before the scanner
/// looks for questions:
///
/// * pinyin printed above the characters (common on HSK 1–2 sheets) comes
///   out as separate lines or glued prefixes (`le了`); they are removed and
///   the single-character lines are joined back into sentences;
/// * a pinyin hint inside brackets (`（ gāng ）`, the "type the hanzi" form)
///   is kept and re-joined when the PDF split it over three lines;
/// * `Choose the right answers. 1. 妈妈…` is split so the question starts
///   on its own line;
/// * arrow bullets (➢ ➤ ►) in front of a question line are dropped.
abstract final class WorksheetTextNormalizer {
  // Precomposed tone vowels or combining marks (some PDFs write yì as y+i+̀).
  static final _toneMarked = RegExp(r'[āáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜ\u0300-\u036f]');
  static final _combining = RegExp(r'[\u0300-\u036f]');
  static final _inlineBankStart = RegExp(
      r'(?:^|[\s。．！？、，；：》」）)])(A[\u4e00-\u9fff]{1,4}\s+B[\u4e00-\u9fff]{1,4}\s+C[\u4e00-\u9fff])');
  static final _latinWord = RegExp(r"^[a-zA-Zü']+$");
  static final _cjk = RegExp(r'[一-鿿]');
  static final _gluedPrefix = RegExp(r"^([a-zü']+)([一-鿿].*)$");
  static final _bracketSpan = RegExp(r'（[^）]*）|\([^)]*\)');
  static final _numberAfterSentence =
      RegExp(r'([。．.!?？！:：)）])\s+(\d{1,2}\.\s*)');
  static final _lineStartsItem = RegExp(r'^(\d{1,2}[\.．、]|例如|★|☆)');
  static final _arrowBullet = RegExp(r'^[➢➤►▶→☞•]\s*');
  // Symbol fonts (Wingdings arrows and bullets) come out of the PDF as
  // private-use characters that render as boxes; they carry no text.
  static final _privateUse = RegExp(r'[\uE000-\uF8FF]');

  static const _toneless = {
    'ā': 'a', 'á': 'a', 'ǎ': 'a', 'à': 'a',
    'ē': 'e', 'é': 'e', 'ě': 'e', 'è': 'e',
    'ī': 'i', 'í': 'i', 'ǐ': 'i', 'ì': 'i',
    'ō': 'o', 'ó': 'o', 'ǒ': 'o', 'ò': 'o',
    'ū': 'u', 'ú': 'u', 'ǔ': 'u', 'ù': 'u',
    'ǖ': 'ü', 'ǘ': 'ü', 'ǚ': 'ü', 'ǜ': 'ü',
  };

  static String stripTones(String s) {
    final b = StringBuffer();
    for (final rune in s.replaceAll(_combining, '').runes) {
      final ch = String.fromCharCode(rune);
      b.write(_toneless[ch] ?? ch);
    }
    return b.toString();
  }

  /// `xiǎng`, `si`, `yì` → true; `Part`, `Choose`, `yang` (Indonesian word
  /// but also a syllable) → only the syllable table decides, so callers use
  /// [isPinyinToken] together with the document-level [looksAnnotated].
  static bool isPinyinToken(String token) {
    final t = stripTones(token.toLowerCase().replaceAll("'", ''));
    if (t.isEmpty || !_latinWord.hasMatch(t)) return false;
    if (pinyinSyllables.contains(t)) return true;
    // Two syllables written together (yìsi, tóngwū).
    for (var i = 1; i < t.length; i++) {
      if (pinyinSyllables.contains(t.substring(0, i)) &&
          pinyinSyllables.contains(t.substring(i))) {
        return true;
      }
    }
    return false;
  }

  static bool _isPinyinOnlyLine(String line) {
    if (_cjk.hasMatch(line)) return false;
    final tokens = line.split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
    if (tokens.isEmpty) return false;
    return tokens.every(isPinyinToken);
  }

  /// A sheet with pinyin above the characters: many lines are pinyin only.
  static bool looksAnnotated(List<String> lines) {
    final pinyin = lines.where(_isPinyinOnlyLine).length;
    return pinyin >= 5 && pinyin >= lines.length * 0.2;
  }

  static String normalize(String raw) {
    var text = raw
        .replaceAll('ɡ', 'g')
        .replaceAll('ɑ', 'a')
        .replaceAll(_privateUse, ' ');
    var lines = text
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    lines = _joinBracketHints(lines);
    lines = _splitNumberedSentences(lines);

    final annotated = looksAnnotated(lines);
    lines = [
      for (final line in lines)
        _stripPinyin(_arrowBullet.hasMatch(line) ? line.replaceFirst(_arrowBullet, '') : line, annotated),
    ].where((l) => l.isNotEmpty).toList();

    if (annotated) lines = _splitGluedMarkers(_joinFragments(lines));
    return lines.join('\n');
  }

  /// After re-joining characters, an example line (例如) or a second word
  /// bank (A… B… C…) can sit glued to the end of the previous item.
  static List<String> _splitGluedMarkers(List<String> lines) {
    final out = <String>[];
    for (var line in lines) {
      while (true) {
        final ex = line.indexOf('例如', 1);
        final bank = _inlineBankStart.firstMatch(line);
        final bankAt =
            bank == null ? -1 : line.indexOf(bank.group(1)!, bank.start);
        var cut = -1;
        for (final i in [ex, bankAt]) {
          if (i > 0 && (cut < 0 || i < cut)) cut = i;
        }
        if (cut <= 0) break;
        out.add(line.substring(0, cut).trim());
        line = line.substring(cut).trim();
      }
      if (line.isNotEmpty) out.add(line);
    }
    return out;
  }

  /// `1. 我 （` / `gāng` / `）才…` → `1. 我 （gāng）才…`
  static List<String> _joinBracketHints(List<String> lines) {
    final out = <String>[];
    var i = 0;
    while (i < lines.length) {
      final line = lines[i];
      if ((line.endsWith('（') || line.endsWith('(')) && i + 1 < lines.length) {
        final buf = StringBuffer(line);
        var j = i + 1;
        var closed = false;
        while (j < lines.length && j <= i + 3) {
          buf.write(lines[j]);
          if (lines[j].startsWith('）') || lines[j].startsWith(')')) {
            closed = true;
            j++;
            break;
          }
          j++;
        }
        if (closed) {
          out.add(buf.toString());
          i = j;
          continue;
        }
      }
      out.add(line);
      i++;
    }
    return out;
  }

  static List<String> _splitNumberedSentences(List<String> lines) {
    final out = <String>[];
    for (final line in lines) {
      final split = line.replaceAllMapped(
        _numberAfterSentence,
        (m) => '${m[1]}\n${m[2]}',
      );
      out.addAll(split.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty));
    }
    return out;
  }

  static String _stripPinyin(String line, bool annotated) {
    // Keep bracketed hints untouched: `（gāng）` is the question's pinyin.
    final parts = <String>[];
    var last = 0;
    for (final m in _bracketSpan.allMatches(line)) {
      parts.add(_stripOutside(line.substring(last, m.start), annotated));
      parts.add(m.group(0)!);
      last = m.end;
    }
    parts.add(_stripOutside(line.substring(last), annotated));
    return parts.join().replaceAll(RegExp(r'[ \t]{2,}'), ' ').trim();
  }

  static String _stripOutside(String text, bool annotated) {
    if (text.trim().isEmpty) return text;
    final tokens = text.split(RegExp(r'[ \t]+'));
    final kept = <String>[];
    for (final token in tokens) {
      if (token.isEmpty) continue;
      // Bank letters and option letters are never pinyin.
      if (RegExp(r'^[A-F][：:.]?$').hasMatch(token)) {
        kept.add(token);
        continue;
      }
      final glued = _gluedPrefix.firstMatch(token);
      if (glued != null && isPinyinToken(glued.group(1)!) &&
          (annotated || _toneMarked.hasMatch(glued.group(1)!))) {
        kept.add(glued.group(2)!);
        continue;
      }
      final toneMarked = _toneMarked.hasMatch(token);
      if (toneMarked && isPinyinToken(token)) continue;
      if (annotated && isPinyinToken(token) && token.toLowerCase() == token) {
        continue;
      }
      kept.add(token);
    }
    return kept.join(' ');
  }

  /// On annotated sheets every character came out on its own line; glue
  /// them back until the next item marker or a long line.
  static List<String> _joinFragments(List<String> lines) {
    final out = <String>[];
    final current = StringBuffer();
    var currentIsFragmentRun = false;

    void flush() {
      final s = current.toString().trim();
      if (s.isNotEmpty) out.add(s);
      current.clear();
      currentIsFragmentRun = false;
    }

    for (final line in lines) {
      final isFragment = line.runes.length <= 8;
      if (_lineStartsItem.hasMatch(line)) {
        flush();
        current.write(line);
        currentIsFragmentRun = true;
        continue;
      }
      if (isFragment && currentIsFragmentRun) {
        current.write(line);
        continue;
      }
      if (isFragment) {
        flush();
        current.write(line);
        currentIsFragmentRun = true;
        continue;
      }
      flush();
      out.add(line);
    }
    flush();
    return out;
  }
}
