/// Reads an answer key the admin types or pastes for a worksheet, e.g.
///
/// ```
/// 1 D 2 A 3. C
/// 11 √ 12 × 13 ✓
/// 41-45 ECBAD
/// ```
///
/// Each entry maps a question number (1-based, in sheet order) to the index
/// of the right choice: `A` → 0 … `F` → 5; `√` / `对` / `TRUE` → 0 and
/// `×` / `错` / `FALSE` → 1 (true/false questions store 对 first; a single
/// `T` or `F` is not read as true/false because `F` is also a choice). A range
/// (`41-45 ECBAD`) spreads the letters over the numbers. Later entries
/// overwrite earlier ones.
abstract final class AnswerKeyParser {
  static const _trueMarks = {'√', '✓', '✔', '对', 'TRUE', 'BENAR'};
  static const _falseMarks = {'×', '✗', '✘', 'X', '错', 'FALSE', 'SALAH'};

  static final _range = RegExp(
    r'(\d{1,3})\s*[-–~到]\s*(\d{1,3})\s*[.．、:：)]?\s*([A-Fa-f√✓✔×✗✘xX对错]{2,})',
  );
  static final _pair = RegExp(
    r'(\d{1,3})\s*[.．、:：)]?\s*(TRUE|FALSE|BENAR|SALAH|[A-Fa-f]|[√✓✔×✗✘xX对错])(?![A-Za-z])',
    caseSensitive: false,
  );

  /// Question number → correct index. Empty when nothing was readable.
  static Map<int, int> parse(String text) {
    final out = <int, int>{};
    var rest = text;
    for (final m in _range.allMatches(text)) {
      final from = int.parse(m.group(1)!);
      final to = int.parse(m.group(2)!);
      final marks = m.group(3)!;
      if (to < from || to - from + 1 != marks.length) continue;
      for (var i = 0; i < marks.length; i++) {
        final index = _indexOf(marks[i]);
        if (index != null) out[from + i] = index;
      }
      rest = rest.replaceFirst(m.group(0)!, ' ');
    }
    for (final m in _pair.allMatches(rest)) {
      final index = _indexOf(m.group(2)!);
      if (index != null) out[int.parse(m.group(1)!)] = index;
    }
    return out;
  }

  static int? _indexOf(String mark) {
    final upper = mark.toUpperCase();
    if (upper.length == 1 &&
        upper.codeUnitAt(0) >= 65 &&
        upper.codeUnitAt(0) <= 70) {
      return upper.codeUnitAt(0) - 65;
    }
    if (_trueMarks.contains(mark) || _trueMarks.contains(upper)) return 0;
    if (_falseMarks.contains(mark) || _falseMarks.contains(upper)) return 1;
    return null;
  }
}
