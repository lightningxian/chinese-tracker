---
paths:
  - lib/**/*worksheet*
  - lib/**/teacher_exercise_form_screen.dart
  - docs/WORKSHEET_IMPORT.md
---

# Worksheet import: web only

Worksheet **upload and OCR import** is available only to **admins** on **web**
(`kIsWeb`): it writes to the question bank, which teachers only read (see
`exercise-authoring-web-only.md`).

## Enforcement layers

1. **Platform gate**: `WorksheetImportPlatform` in
   `lib/core/constants/worksheet_import_platform.dart`.
   - `isSupportedFor(user)` → `ExerciseAuthoringPlatform.canManageBank(user)`
     (admin on web).
   - `ensureSupportedFor(user)` throws `WorksheetImportPlatformException`
     for teachers and off web.
2. **Service**: `WorksheetImportService.extractTextFromWorksheet()` calls
   `ensureSupported()` first.
3. **UI**: exercise form (`teacher_exercise_form_screen.dart`).
   - Web: upload card + **Choose file** button.
   - Non-web: info card with `unsupportedMessage`, no file picker.

## Do not

- Add worksheet upload buttons on Android or iOS without a web-only guard.
- Remove the service-layer check (the UI can be bypassed).
- Document mobile worksheet upload as supported.

## Docs

Keep `docs/WORKSHEET_IMPORT.md` aligned: web only for upload and OCR.
