# Worksheet import (local scan)

> **App:** Easy Study · Figma UI spec: [design/FIGMA_AI_SPEC.md](design/FIGMA_AI_SPEC.md)

Admins upload **PDF, Word, or image** worksheets on the exercise form (**web only**). The app reads the file **on your device**, detects the worksheet type, and builds draft questions for review.

**No Gemini. No API keys. No separate AI billing.**

> **Platform:** Exercise **creation and editing** is **admin-only on web**. Murid can still **do** exercises on mobile; Gurus can browse and assign published practice but cannot create or edit exercises.

---

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

| Detected type | Worksheet signals | Student UI |
|---------------|-------------------|------------|
| **Compose sentences (组词成句)** | Keywords like 组词成句; spaced segments e.g. `南方的 / 夏天 / 热极了` | Reorder word parts |
| **Matching (对话配对)** | Answer bank **A–F** + numbered prompts; LATIHAN SOAL HSK patterns | Match prompts to options |
| **Multiple choice** | Numbered questions with **A–D** options | Pick one answer |
| **Reading cloze** | ISILAH DENGAN KATA YANG TEPAT; passage + blank choices | Detected only — editor coming soon |
| **Picture + keyword** | Buatlah Kalimat + keyword | Detected only — editor coming soon |

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
