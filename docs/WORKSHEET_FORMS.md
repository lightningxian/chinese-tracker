# Worksheet forms in the centre's material (from `CONTOH LATIHAN SOAL.zip`, 2026-10-29)

What each sample is, what the scanner sees today, and what must be built so
the scanner recognises it. Status column is filled in after the owner confirms.

File-name code: `<HSK level><set><number>-<category>`, e.g. `320001-WRT` =
HSK 3, category WRT. Categories seen: RDG (reading), KLM (kalimat / sentences),
WRT (writing), CRT (cerita / exam reading), KK (kosa kata / vocabulary).
The scanner should read the level and category from this code.

| # | File | What it is | Scanner today | To build |
|---|---|---|---|---|
| 1 | 210001-RDG HSK 2 填写 | Fill in the blank with a lettered word bank (A–F), two parts of 5 sentences, pinyin printed above every character, 例如 example line shows the answer letter | Wrong: pinyin lines break it (1 blank, no bank) | Strip pinyin lines; one bank per part; skip the 例如 line |
| 2 | 210002-RDG HSK 2 ToF | True / false: numbered short text, then ★ statement with （ ） for √/× | Wrong (488 "questions") | Pair text + ★ statement into one true/false item; strip pinyin |
| 3 | 300001-KLM HSK 3 组词成句 | Arrange words into a sentence (parts separated by spaces) | Correct: compose sentences, 10 items | Nothing |
| 4 | 310001-RDG HSK 3 reading | Short text per question, ➢ prompt line, A / B / C options on one line | Wrong (compose) | Inline options `A … B … C …`; text before ➢ becomes that question's passage |
| 5 | 320001-WRT Isilah Han Zi | Type the hanzi for the pinyin shown in （ ） | Wrong (matching) | New typing type T2 (pinyin → hanzi), auto-graded by exact hanzi; answer key typed by admin |
| 6 | 320002-WRT HSK 3 填写 | Fill in the blank from a boxed word bank (no letters), 4 groups of 5 | Partly (20 blanks, 1 bank) | Several banks: use all words of the group; blanks `_________` |
| 7 | 400003-KLM HSK 4 gambar | Picture + keyword → write a sentence (teacher grades) | Recognised, not editable | Picture-sentence type T5: crop the picture from the page, keyword, free text answer, teacher marks it |
| 8 | 510001-CRT HSK 5 exam | Real exam page: passage with numbered blanks 46–52, A–D options per number; scanned image (needs OCR) | Nothing (no text layer) | OCR on web, then: passage + "blank 46…" questions with their own A–D |
| 9 | 520002-KK Menjodohkan | Two columns I / II to connect into phrases, then 5 sentences to complete with those phrases | Wrong (compose) | Two exercises from one sheet: matching (column I → column II) and fill in the blank with the phrases |
| 10 | 5400001-RDG HSK 5 阅读 61–70 | Reading: paragraph then 4 statements A–D, pick the consistent one | Wrong (matching) | Numbered paragraph + A–D lines = one multiple-choice question with its own passage |

Answer keys are not printed on any sheet except the 例如 examples, so the
admin sets the answers in the editor after import (or uploads the key sheet).
