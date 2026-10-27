# Worksheet import (local scan)

> **App:** Easy Study · Figma UI spec: [design/FIGMA_AI_SPEC.md](design/FIGMA_AI_SPEC.md)

Admins upload **PDF, Word, or image** worksheets on the exercise form (**web only**). The app reads the file **on your device**, detects the worksheet type, and builds draft questions for review.

**No Gemini. No API keys. No separate AI billing.**

> **Platform:** Exercise **creation and editing** is **admin-only on web**. Murid can still **do** exercises on mobile; Gurus can browse and assign published practice but cannot create or edit exercises.

---

## Where the scanner is used

- **Question bank → Scan worksheet** (main button): detected questions go through a *Check before adding* list (type + answer per question, untick to skip, set level/difficulty) and then into the bank.
- **Quizzes → edit → Scan worksheet**: the multiple-choice questions become quiz questions.
- **Exercise form → Import from worksheet**: fills the whole exercise (type, instructions, passage, questions).

All three share `lib/features/teacher/worksheet_scan_flow.dart` (pick file → read → review screen).

## Admin workflow

1. Sign in as **Admin**
2. **Exercises → New exercise** (or edit an existing draft)
3. Tap **Choose file to upload**
4. Wait for progress: **Prepare file → Read file → Detect questions**
5. In the review dialog:
   - Check the **detected type** and question preview
   - Edit extracted text if OCR missed anything
   - Tap **Re-analyze** after edits
6. **Import questions**, then publish and assign as usual

Always review before saving — OCR can misread handwriting, small text, or watermarks.

---

## Supported files

| Format | How it is read |
|--------|----------------|
| **PDF** (text-based) | Text layer extracted directly (`pdfrx`) |
| **PDF** (scanned) | Each page rendered and OCR’d in the browser (Tesseract.js) |
| **DOCX** | Word XML parsed locally |
| **JPG / PNG / WebP** | OCR in the browser |
| **DOC** (legacy Word) | Not supported — save as **DOCX** or **PDF** |

**Limits**

- Max file size: **15 MB**
- Scanned PDF OCR: up to **8 pages** (split larger files)

---

## Question detection

After text is extracted, `QuestionImportUtils` (`lib/core/utils/question_import_utils.dart`) inspects layout and keywords to pick an exercise type and parse questions.

| Detected form (thesis code) | Worksheet signals | Saved as | Student UI |
|---|---|---|---|
| **Multiple choice** | Numbered questions with **A–D** options; `*`/`✓` marks the key | `multiple_choice` | Pick one answer |
| **R1 Fill in the blank (选词填空)** | 选词填空 / ISILAH DENGAN KATA; sentences with `（ ）`, `（B）` or `____`; a word bank (`A. 的 B. 了 …` or `（喜欢 因为 所以）`) | `reading_cloze` (shared word bank + one prompt per blank, same data as matching) | Choose the word for each blank |
| **R2 Matching (对话配对)** | Answer bank **A–F** listed once + numbered prompts ending `（ ）`/`（A）`; LATIHAN SOAL patterns | `matching` | Match prompts to options |
| **R3 Reading comprehension (阅读理解)** | 阅读理解 / 短文 / bacalah; a paragraph before numbered A–D questions | `multiple_choice` + `passage` | Passage card above every question |
| **R4 Order the sentences (句子排序)** | 句子排序 / urutkan; `1.` then lettered sentences `A …` `B …`; optional key `答案：BCA` | `compose_sentences` (one sentence per part, in the key's order) | Drag sentences into order |
| **True/false (判断对错, P1/L2)** | 判断对错 / benar atau salah; statements ending `（√）` `（×）` / 对 错 / (T) (F) | `multiple_choice` with options 对 (True) / 错 (False) | Pick 对 or 错 |
| **L3 Listening (听力)** | 听力 / 听录音 / dengarkan + A–D questions | `listening` (questions only; attach audio in the form) | Listen and pick |
| **Compose sentences (组词成句)** | 组词成句 / menyusun kalimat; spaced or `/`-separated parts | `compose_sentences` | Reorder word parts |
| **Picture + keyword** | Buatlah Kalimat + gambar | detected only, not editable yet | — |

The review screen names the detected form and counts in its summary (e.g. "Detected R1 fill in the blank (选词填空) · HSK 2 — 3 blanks, 4 words in the bank. 1 blank without an answer letter: set the correct word in the editor."). Unmarked true/false statements default to 对; unmarked blanks default to A; ordering groups without a key keep the printed order and say so in the prompt, so the admin fixes them before saving. The type dropdown on the review screen overrides the guess.

The parser also tries to read **HSK level** from the worksheet title (e.g. “HSK 3”) and filters noise (page numbers, watermarks).

---

## How it works (technical)

```
Upload file
    ↓
WorksheetImportService (client)
    ├── PDF  → PdfTextReader (text layer, then OCR fallback)
    ├── DOCX → DocxTextReader
    └── Image → Tesseract.js via web/worksheet_ocr.js (chi_sim+eng)
    ↓
Plain text
    ↓
QuestionImportUtils.parseWorksheet()
    ↓
Review dialog → Import into exercise form
```

**Web (Chrome):** full support — PDF, Word, and image OCR.

**iOS / Android:** worksheet upload is **not available**. Create exercises manually on mobile, or use the web app to import worksheets.

Files are processed in the browser. Nothing is uploaded to Gemini, Cloud Vision, or any third-party AI service for import.

---

## Run the app

```bash
cd ~/Projects/chinese-tracker
flutter run -d chrome
```

Worksheet import requires **web** (`flutter run -d chrome`). It is not available on Android or iOS builds.

No extra setup, secrets, or Firebase Functions are required for worksheet import.

---

## Troubleshooting

| Error | Fix |
|-------|-----|
| No text found | Use a sharper scan, export as PDF/DOCX, or paste/edit text in the review dialog |
| Scanned PDF too many pages | Split into files of ≤ 8 pages |
| Old `.doc` file | Save as `.docx` or PDF in Word |
| OCR slow on first run | Tesseract downloads Chinese + English language data once |
| Wrong question type | Edit text in the review dialog → **Re-analyze**, or change type manually on the form |
| Matching split across sections | Parser may warn — create two exercises (Part 1 / Part 2) |
| “Cloud AI” / Gemini / quota errors | Hard-refresh the browser — you may be on an old build; current import is local only |

---

## Privacy

Worksheet files stay on your device during import. Only the exercise you save is stored in Firestore (questions, instructions, assignments).

---

## Related docs

- [APP_OVERVIEW.md](../APP_OVERVIEW.md) — exercise types and teacher workflows
- [SETUP.md](../SETUP.md) — Firebase and first-time app setup
- [Screen inventory](../screen-inventory/SCREEN_INVENTORY.md) — all screens, routes, and dialogs
