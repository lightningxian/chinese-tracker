import 'package:chinese_tracker/core/utils/answer_key_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('letters, marks and ranges', () {
    final key = AnswerKeyParser.parse('''
1 D 2. A 3、C 4) f
11 √ 12 × 13 ✓ 14 对 15 错
41-45 ECBAD
''');
    expect(key[1], 3);
    expect(key[2], 0);
    expect(key[3], 2);
    expect(key[4], 5);
    expect(key[11], 0);
    expect(key[12], 1);
    expect(key[13], 0);
    expect(key[14], 0);
    expect(key[15], 1);
    expect(key[41], 4);
    expect(key[42], 2);
    expect(key[43], 1);
    expect(key[44], 0);
    expect(key[45], 3);
    expect(key.length, 14);
  });

  test('a range with the wrong number of letters is skipped', () {
    expect(AnswerKeyParser.parse('1-5 ABC'), isEmpty);
  });

  test('true/false words; a bare F is the choice F', () {
    final key = AnswerKeyParser.parse('6 TRUE 7 false 8 benar 9 salah 10 F');
    expect(key, {6: 0, 7: 1, 8: 0, 9: 1, 10: 5});
  });

  test('nothing readable', () {
    expect(AnswerKeyParser.parse('hello'), isEmpty);
  });
}
