#!/usr/bin/env bash
set -euo pipefail

echo "==> Worksheet import no longer uses cloud OCR or Gemini."
echo ""
echo "Import runs locally in the browser (Tesseract.js + PDF/Word parsers)."
echo "No Blaze plan, Vision API, or Cloud Functions are required."
echo ""
echo "See docs/WORKSHEET_IMPORT.md"
echo ""
echo "Run the app:"
echo "  flutter run -d chrome"
