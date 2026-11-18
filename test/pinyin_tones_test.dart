import 'package:chinese_tracker/core/utils/pinyin_tones.dart';
import 'package:chinese_tracker/models/paper_proof_record.dart';
import 'package:flutter_test/flutter_test.dart';

// Build 1C (docs/PLAN.md §4): Must 5 (tones for 76-80) and Must 6 (the
// proofreading record).
void main() {
  test('tone numbers become marks, placed by the usual rule', () {
    expect(PinyinTones.fromNumbers('guan1'), 'guān');
    expect(PinyinTones.fromNumbers('ni3 hao3'), 'nǐ hǎo');
    expect(PinyinTones.fromNumbers('xue2'), 'xué');
    expect(PinyinTones.fromNumbers('shou3'), 'shǒu', reason: 'ou: the o');
    expect(PinyinTones.fromNumbers('liu4'), 'liù', reason: 'last vowel');
    expect(PinyinTones.fromNumbers('gui4'), 'guì');
    expect(PinyinTones.fromNumbers('lv4 nu:3'), 'lǜ nǚ');
    expect(PinyinTones.fromNumbers('ma5'), 'ma', reason: 'neutral tone');
    expect(PinyinTones.fromNumbers('cháng'), 'cháng', reason: 'already marked');
  });

  test('a syllable splits into its letters and tone; a tap sets the tone', () {
    expect(PinyinTones.split('guān'), ('guan', 1));
    expect(PinyinTones.split('lǜ'), ('lü', 4));
    expect(PinyinTones.split('guan'), ('guan', 0));
    expect(PinyinTones.setTone('zhong jian', 1, 1), 'zhong jiān');
    expect(PinyinTones.setTone('zhōng', 0, 4), 'zhòng');
    expect(PinyinTones.syllables(' ni  hao '), ['ni', 'hao']);
  });

  test('the proofreading record round-trips and counts what was kept', () {
    final r = PaperProofRecord(
      slots: 80,
      flagged: 20,
      changed: 14,
      proofSeconds: 600,
      readSeconds: 41,
      engine: 'paddle',
      savedAt: DateTime.utc(2026, 11, 18, 6),
    );
    expect(r.untouched, 66);
    final back = PaperProofRecord.fromMap(r.toMap());
    expect(back.flagged, 20);
    expect(back.engine, 'paddle');
    expect(back.savedAt, DateTime.utc(2026, 11, 18, 6));
  });
}
