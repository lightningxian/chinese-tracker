# Worksheet forms in the centre's material (from `CONTOH LATIHAN SOAL.zip`, 2026-10-29)

What each sample is, what the scanner sees today, and what must be built so
the scanner recognises it. Status column is filled in after the owner confirms.

File-name code: `<HSK level><set><number>-<category>`, e.g. `320001-WRT` =
HSK 3, category WRT. Categories seen: RDG (reading), KLM (kalimat / sentences),
WRT (writing), CRT (cerita / exam reading), KK (kosa kata / vocabulary).
The scanner should read the level and category from this code.

| # | File | What it is | Scanner now (2026-10-29) | Imported as |
|---|---|---|---|---|
| 1 | 210001-RDG HSK 2 填写 | Fill in the blank with a lettered word bank (A–F), two parts of 5 sentences, pinyin printed above every character | 10 blanks, 2 word lists, pinyin stripped, 例如 lines skipped | Multiple choice: each sentence with its part's 6 words; answers set in the editor |
| 2 | 210002-RDG HSK 2 ToF | True / false: numbered short text, then ★ statement with （ ） | 10 items, text + ★ statement paired | Multiple choice 对 / 错 |
| 3 | 300001-KLM HSK 3 组词成句 | Arrange words into a sentence | 10 items | Compose sentences |
| 4 | 310001-RDG HSK 3 reading | Short text per question, ➢ prompt, A B C on one line | 7 questions, text + prompt, 3 options each | Multiple choice |
| 5 | 320001-WRT Isilah Han Zi | Type the hanzi for the pinyin in （ ） | 15 sentences with pinyin hint | **Type the hanzi** (new type): student types; admin enters the accepted hanzi |
| 6 | 320002-WRT HSK 3 填写 | Fill in the blank from boxed word lists, 4 groups of 5 | 20 blanks, 4 word lists mapped to their 5 sentences | Multiple choice with 5 options each |
| 7 | 400003-KLM HSK 4 gambar | Picture + keyword → write a sentence | 8 keywords | **Picture sentence** (new type): keyword, optional picture (uploaded in the editor); auto check = sentence uses the keyword |
| 8 | 510001-CRT HSK 5 exam | Passage with numbered blanks 46–52, A–D per number; scanned image | After OCR: 7 questions, each with the passage + （46）… and its A–D | Multiple choice |
| 9 | 520002-KK Menjodohkan | Two columns to connect, then 5 sentences to complete | The columns are drawings, not text: only the 5 sentences are read | Fill in the blank with an empty word list; admin types the phrases A–F |
| 10 | 5400001-RDG HSK 5 阅读 61–70 | Paragraph then 4 statements A–D | 4 questions (one page), paragraph + 4 options | Multiple choice |

The scanner also reads the file code (`320001-WRT`) for the HSK level and the
skill section, and the heading (`SOAL LATIHAN HSK 3 (A)`) as the title.
Tests: `test/worksheet_fixtures_test.dart` runs all ten texts.

Answer keys are not printed on any sheet except the 例如 examples, so the
admin sets the answers in the editor after import (or uploads the key sheet).
