# Cursor prompt — Question Bank upgrade (all four areas)

Upgrade the question bank: **richer metadata + table**, **bulk import & add**,
**harvest from existing exercises**, and **quizzes + media**. Build in the phases
below; each must `flutter analyze` clean and reuse existing patterns. Don't break
the current bank editor, filters, or `showQuestionBankPicker` (which exercises
already use). Log the work in `docs/CURSOR_CHANGES_FOR_CLAUDE.md`.

## Grounding (what already exists — reuse, don't rebuild)
- Model `lib/models/question_bank_item.dart` wraps `ExerciseQuestion` (same
  serialization → drops into exercises). Collection `question_bank`, rules are
  **staff-only** read+write, index `(ownerId, createdAt DESC)`.
- `ExerciseQuestion` (`lib/models/exercise.dart`) already has an `imageUrl`
  field. There is **no per-question audioUrl** (audio is exercise-level).
- `showQuestionBankPicker(...)` in `question_bank_screen.dart` is **already
  multi-select** and returns `List<QuestionBankItem>`; `teacher_exercise_form_screen.dart`
  uses it via a "From bank" button.
- Worksheet OCR/parse: `WorksheetImportService` + `core/utils/question_import_utils.dart`
  already turn worksheets into `ExerciseQuestion`s — reuse for bulk import.
- Shared table widget `lib/core/widgets/app_data_table.dart`; Storage upload
  pattern in `lib/services/materials_storage_service.dart`.
- **No quiz authoring screen exists** — quizzes are only read/taken
  (`getQuizForLesson`, `saveQuizResult`). Phase 4's quiz integration must build one.

---

## Phase 1 — Richer metadata + table
- Model: add `difficulty` (enum `easy|medium|hard`, default `medium`),
  `usageCount` (int, default 0), `lastUsedAt` (timestamp?), `updatedAt`. Update
  `toMap`/`fromFirestore`.
- Editor: add a difficulty selector; keep type/level/skill/tags.
- Replace the card list with **`AppDataTable`** (columns: Prompt, Type, Level,
  Difficulty, Tags, Used, Actions) + the mobile card fallback. Keep search; add a
  **difficulty filter** and column sort (sort client-side — no new index needed).
- Increment `usageCount` + set `lastUsedAt` whenever a question is added to an
  exercise/quiz (see Phases 2/4).

## Phase 2 — Bulk import & add
- **Bulk import into the bank:**
  - Reuse `WorksheetImportService` to OCR/parse a worksheet → many
    `ExerciseQuestion`s → a review screen → batch-insert as bank items.
  - Also a "paste" importer: a textarea of lines → parsed MC/compose questions
    via `question_import_utils`.
  - Add `addQuestionBankItems(List<QuestionBankItem>)` (batched writes) to
    `firestore_service.dart`.
- **Bulk add to an exercise:** the picker is already multi-select — add a
  "Select all (filtered)" action, and on confirm bump `usageCount` for the chosen
  questions.

## Phase 3 — Harvest from existing exercises
- Add a "Import from exercises" action: read `watchAllExercises()`, flatten their
  `questions` into candidate `QuestionBankItem`s (carry type/level/skill).
- **Dedupe:** skip candidates whose `prompt`+`type` already exist in the bank;
  show a count of "new vs already in bank" before importing. Batch-insert the new
  ones. (Optional: store `sourceExerciseId` for traceability.)

## Phase 4 — Quizzes + media
### Media per question
- Support an optional **image** (reuse `ExerciseQuestion.imageUrl`) and add an
  optional **`audioUrl`** to `ExerciseQuestion` (for listening items). Upload via
  a small service mirroring `materials_storage_service.dart` to
  `question_bank_media/{ownerId}/…`; add matching **storage.rules** (staff write,
  signed-in read, size cap). Show image/audio in the editor, the picker, and when
  a question is placed into an exercise/quiz.
### Quiz authoring (new — prerequisite for "use in quizzes")
- Build a minimal **quiz editor** for staff: create/edit a quiz tied to a lesson
  (`quizzes` collection, `lessonId`, `questions[]`, title), reusing the exercise
  form patterns and the **"From bank"** picker. Add `createQuiz`/`updateQuiz` to
  `firestore_service.dart` and a route + entry point (teacher/admin).
- If you'd rather not build the full editor now, implement everything else and
  leave a clear TODO — but the "pull bank questions into a quiz" flow needs it.

## Cross-cutting
- Rules: `question_bank` stays staff-only. Add storage rules for the new media
  path. No new composite index needed if new sorts are client-side; add one only
  if you introduce a server-side `orderBy` on a filtered field.
- Keep `QuestionBankItem` backward-compatible (new fields optional with defaults)
  so existing bank docs still load.
- Reuse `ExerciseQuestion` serialization end-to-end so bank ↔ exercise ↔ quiz
  stay interchangeable.

## Acceptance
- `flutter analyze` clean; existing bank editor, filters, and the exercise "From
  bank" flow still work.
- Bank list is a sortable table with difficulty + usage; bulk import (worksheet +
  paste) adds many questions at once; "Import from exercises" harvests with
  dedupe; a question can carry an image/audio; and (if built) a quiz can be
  authored by pulling questions from the bank.
