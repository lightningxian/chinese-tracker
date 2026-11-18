import 'package:chinese_tracker/core/constants/hsk_characters.dart';
import 'package:chinese_tracker/models/hsk_paper_draft.dart';
import 'package:flutter_test/flutter_test.dart';

// Build 1C (docs/PLAN.md §4, Must 4): what flags a question the new reader
// read with a small mistake. Sentences invented for the test.
HskSlot _slot(String form, {String prompt = '', List<String>? options, String keyword = '', int? level = 3}) =>
    HskSlot(number: 1, skill: 'reading', form: form, prompt: prompt,
        options: options, keyword: keyword)
      ..paperLevel = level;

void main() {
  test('the HSK 1-3 lists hold the everyday characters', () {
    expect(HskCharacters.upTo(3)!.length, greaterThan(600));
    expect(HskCharacters.outside('我们今天去学校。', 3), isEmpty);
    expect(HskCharacters.outside('很安靜', 3), ['靜'], reason: 'a traditional form');
    expect(HskCharacters.outside('鸟在川', 3), ['川']);
    expect(HskCharacters.outside('anything', 4), isEmpty, reason: 'no list above 3');
  });

  test('a character above the level flags; a clean sentence does not', () {
    expect(_slot(HskForm.choice, prompt: '他每天去学校。', options: ['八点', '九点']).doubt, isNull);
    expect(_slot(HskForm.choice, prompt: '这里很安靜。', options: ['对', '错']).doubt,
        HskSlot.doubtLevel);
    expect(_slot(HskForm.choice, prompt: '这里很安靜。', options: ['对', '错'], level: null).doubt,
        isNull, reason: 'no level, no check');
  });

  test('stray marks flag', () {
    expect(_slot(HskForm.matching, prompt: '下次再来问我。（ ），').doubt, HskSlot.doubtMarks);
    expect(
        _slot(HskForm.matching, prompt: '下次再来问我。（ ），', options: ['他来了。', '好的。']).doubt,
        HskSlot.doubtMarks,
        reason: 'the sentence is checked, not only the end of all the text');
    expect(_slot(HskForm.choice, prompt: '我们去问问老师。。', options: ['对', '错']).doubt,
        HskSlot.doubtMarks);
    expect(_slot(HskForm.choice, prompt: '我认识- 一个医生。', options: ['对', '错']).doubt,
        HskSlot.doubtMarks);
    expect(_slot(HskForm.matching, prompt: '好的。', options: ['我们走吧，', '他来了。']).doubt,
        HskSlot.doubtMarks);
    // An em dash in a sentence is fine.
    expect(_slot(HskForm.choice, prompt: '做些小事——喝杯茶。', options: ['对', '错']).doubt, isNull);
  });

  test('a pinyin question without its gap flags', () {
    expect(_slot(HskForm.pinyinChar, prompt: '他在（ ）下看书。', keyword: 'shù').doubt, isNull);
    expect(_slot(HskForm.pinyinChar, prompt: '他在下看书。', keyword: 'shù').doubt, HskSlot.doubtGap);
    expect(_slot(HskForm.pinyinChar, prompt: '她的头发又黑又（，）。', keyword: 'cháng').doubt,
        HskSlot.doubtGap);
  });

  test('"Looks right" clears a doubt', () {
    final s = _slot(HskForm.choice, prompt: '这里很安靜。', options: ['对', '错']);
    expect(s.flagged, isTrue);
    s.checked = true;
    expect(s.flagged, isFalse);
  });
}
