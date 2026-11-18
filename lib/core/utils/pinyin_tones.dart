/// Tone marks on pinyin (docs/PLAN.md, Build 1C, Must 5): the proofreading
/// screen turns `guan1` into `guān` and sets the tone of a syllable with a
/// tap, because the paper reader cannot always see the marks.
abstract final class PinyinTones {
  static const _marks = {
    'a': ['a', 'ā', 'á', 'ǎ', 'à'],
    'e': ['e', 'ē', 'é', 'ě', 'è'],
    'i': ['i', 'ī', 'í', 'ǐ', 'ì'],
    'o': ['o', 'ō', 'ó', 'ǒ', 'ò'],
    'u': ['u', 'ū', 'ú', 'ǔ', 'ù'],
    'ü': ['ü', 'ǖ', 'ǘ', 'ǚ', 'ǜ'],
  };

  static final Map<String, (String, int)> _plain = {
    for (final e in _marks.entries)
      for (var t = 0; t < e.value.length; t++) e.value[t]: (e.key, t),
  };

  /// A syllable without its mark, and its tone (0 = none or neutral):
  /// `guān` → (`guan`, 1). `v` and `u:` are read as `ü`.
  static (String, int) split(String syllable) {
    var tone = 0;
    final out = StringBuffer();
    final s = syllable.toLowerCase().replaceAll('u:', 'ü').replaceAll('v', 'ü');
    for (final r in s.runes) {
      final c = String.fromCharCode(r);
      final p = _plain[c];
      if (p != null) {
        out.write(p.$1);
        if (p.$2 > 0) tone = p.$2;
      } else {
        out.write(c);
      }
    }
    return (out.toString(), tone);
  }

  /// [base] (no marks) with [tone] 1-4 placed by the usual rule: on `a` or
  /// `e`; on the `o` of `ou`; else on the last vowel. Tone 0 or 5: none.
  static String mark(String base, int tone) {
    final b = base.toLowerCase().replaceAll('u:', 'ü').replaceAll('v', 'ü');
    if (tone < 1 || tone > 4) return b;
    int at;
    if (b.contains('a')) {
      at = b.indexOf('a');
    } else if (b.contains('e')) {
      at = b.indexOf('e');
    } else if (b.contains('ou')) {
      at = b.indexOf('o');
    } else {
      at = -1;
      for (var i = b.length - 1; i >= 0; i--) {
        if (_marks.containsKey(b[i])) {
          at = i;
          break;
        }
      }
      if (at < 0) return b;
    }
    return b.substring(0, at) + _marks[b[at]]![tone] + b.substring(at + 1);
  }

  /// Every `syllable+digit` of [text] as a marked syllable: `ni3 hao3` →
  /// `nǐ hǎo`, `lv4` → `lǜ`. Anything else is left as it is.
  static String fromNumbers(String text) => text.replaceAllMapped(
        RegExp(r'([a-zA-ZüÜ:]+)([0-5])'),
        (m) => mark(m.group(1)!, int.parse(m.group(2)!)),
      );

  /// [text] with the tone of syllable [index] (split at spaces) set.
  static String setTone(String text, int index, int tone) {
    final parts = text.trim().split(RegExp(r'\s+'));
    if (index < 0 || index >= parts.length) return text;
    parts[index] = mark(split(parts[index]).$1, tone);
    return parts.join(' ');
  }

  /// The syllables of [text] (split at spaces), without empty ones.
  static List<String> syllables(String text) =>
      text.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
}
