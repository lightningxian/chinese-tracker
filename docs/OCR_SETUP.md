# Worksheet import — cloud OCR (deprecated)

**This guide is outdated.** Worksheet import no longer uses Firebase Storage, Cloud Functions, Cloud Vision, or Gemini.

Import now runs **locally in the browser** — see **[WORKSHEET_IMPORT.md](WORKSHEET_IMPORT.md)**.

You do **not** need to:

- Upgrade to Blaze for OCR
- Enable Cloud Vision API
- Deploy `extractWorksheetText` / `processWorksheetAi` functions
- Set `GEMINI_API_KEY` or any API key

Just run `flutter run -d chrome` and use **Choose file to upload** on the exercise form.
