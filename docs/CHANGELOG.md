# Change log

Append-only log of changes, newest first (Cursor until 2026-10-16, Claude after).
Each entry lists what changed, why, and what to check when reviewing (security, rules,
edge cases, and any manual/deploy steps still required).

---

## 2026-11-12 (later) — Claude: Indonesian for admin, teacher and question bank screens

**What changed**
- Every admin, teacher, question bank, worksheet import, materials and
  exercise player screen now reads `context.l10n`; `app_en.arb` /
  `app_id.arb` grew from 311 to about 1,380 keys. Five parallel Claude
  agents each converted a disjoint file set (admin people and money; admin
  dashboard, reports and settings; teacher classes, attendance, students and
  grades; exercises and question bank; student player and materials), then
  the key sets were merged.
- Model enums keep their English `label`; the UI shows them through
  `lib/l10n/labels_admin.dart`, `labels_reports.dart`, `labels_classes.dart`
  and `labels_exercises.dart` (`localized(l)` extensions). Attention items
  and the teacher activity feed are built with the app language
  (`TeacherActivityUtils.buildFeed(l: …)`, `AttentionItem.localizedMessage`).
- Nested page titles (`ShellRouteUtils.*TitleForLocation(l, path)`), the
  notification sheet, the import progress dialog, the roster labels and the
  platform messages shown in the Exercises tab are localized too.
- Admin and teacher profile tabs have the Language row (ID | EN).
- `LocaleController` sets `Intl.defaultLocale` and `main()` loads the
  Indonesian date symbols, so every `DateFormat` without an explicit locale
  prints Indonesian month and weekday names in Indonesian mode (before, dates
  stayed English even on student screens).

**Why**
- Owner's go-ahead 2026-11-12 on the recommendation list: staff screens were
  English-only while students and parents already had the switch.

**For review**
- Still English on purpose: the legacy exercise editor, quiz and level
  screens (unused), error messages thrown from `lib/services` and
  `lib/core/errors` (shown as they come), PDF and CSV exports built in
  `lib/services`, the worksheet scanner's detection summary and OCR progress
  details, the price list default item names (stored data), and the
  `roleLabel` literals that pick the avatar colour.
- The bank search still matches on the English type label, not the
  Indonesian one.
- Verified on the emulator in Indonesian: admin dashboard, Users, Invoices,
  teacher dashboard, exercises, question bank, student player.
- Hosting deployed; no rules or functions change.

---

## 2026-11-12 — Claude: scores locked to the server, explanations in the review

**What changed**
- **No client writes to `exercise_results`.** `firestore.rules`: the `create`
  rule is gone; only the `finishExercise` function (admin SDK) writes results.
  `FirestoreService.saveExerciseResult` and the client-side scorer
  (`_LocalSession` in `exercise_play_service.dart`) are deleted.
- **Old-format exercises are no longer playable.** An exercise whose questions
  live inside its document (made before the question bank, 2026-11-09) now
  shows the student "Old exercise format … ask your teacher for a new one"
  (`ExercisePlayService.start` throws `LegacyExerciseException`). The
  admin/teacher Exercises table labels them "Old format, students cannot play
  it" so the admin can tick and delete them.
- **Explanation per question.** `ExerciseQuestion.explanation` (stored inside
  the bank item's `question` map, every type). Bank editor: "Explanation
  (optional)" field. `finishExercise` returns it in each review entry
  (`exercise_play.js` `scoreAttempt`); `startExercise` never sends it. The
  result page shows it under the question, for right and wrong answers.
- Rules tests: new "exercise results" group (student / staff cannot create,
  change or delete; own, parent and staff reads; other student denied): 30
  pass, 1 skipped. `functions/test_exercise_play.js` checks the explanation
  is in the review and not in the stripped question.

**Why**
- Owner's go-ahead 2026-11-12 on the recommendation list: a student with the
  browser console could post any score; the thesis rule "students write
  answers, never scores" needs the collection closed. Explanations make the
  new review page a learning tool, not only a mark.

**For review**
- **Deploy needed (owner runs):** `firebase deploy --only firestore:rules,functions
  --project chinese-tracker`. Until the rules ship, a client can still create
  results as before; until the function ships, the review has no explanation.
  Hosting is deployed (client already refuses old-format exercises).
- Owner to delete the old-format exercises on live (Exercises table, tick the
  rows labelled "Old format").
- Worksheet import does not read explanations (printed sheets have none);
  teachers add them in the bank editor.

---

## 2026-11-11 (later) — Claude: history tab, parents as add-on payers, compact student home

**What changed**
- **History tab** (student, was "My Classes"; `student_my_classes_tab.dart`,
  shared `core/widgets/class_history_section.dart`): one card per voucher
  (size, code, validity, Active / Used up / Expired, used-remaining bar) that
  expands to the classes charged to it (attendance records carry
  `classTermId`), then every class visit grouped by month with its attendance
  status (Present / Excused / Absent / Joined). Tapping a class opens who
  joined. The parent's overview shows the same section ("Classes and
  vouchers") instead of the five recent classes.
- **Parents as an optional add-on** (owner decision 2026-11-11): the invoice
  stays on the student; whoever is linked may pay it.
  - `linkChild` (function) now also stamps `linkedParentUid` and
    `linkedParentName` on the student (one batch with the parent's
    `studentIds`). `AppUser` reads and keeps both fields.
  - Parent **Payments** tab has the same **Pay now** as the student (same
    Midtrans link; hidden when payments are off in settings).
  - Student **Payments** tab shows "Payments are handled by <parent>" when a
    parent is linked; Pay buttons stay for students who pay themselves.
  - Admin **Users**: the Role dropdown became chips with counts (All roles ·
    Admin · Guru · Murid · Orang Tua); student rows show "Parent: name",
    parent rows show their children.
- **Compact student home** (`student_home_tab.dart`): greeting plus three
  tiles (sessions left with a ring and the voucher's end date, exercises done
  with a day streak, average score with the best), one row of round quick
  links (Calendar, Grades, Materials, History), the open class sessions, then
  "Continue learning" with at most three pending exercises ("See all" opens
  Lessons), the next lesson, and a card "n done · see your scores" that opens
  Progress. The big voucher card and the finished-exercise grid left the home.
  `StudentShell` passes `onOpenTab` so the home can switch tabs.
- **Fun**: 1–3 stars on finished exercise cards (90 / 70 / above 0), a day
  streak on the home tile, confetti on the result page from 70%
  (`core/widgets/confetti_burst.dart`, no new dependency).
- Helpers `ExerciseUtils.streakDays` and `scoreStars` with tests (65 pass).
  Strings for history, home and payments added to both `.arb` files.

**Why**
- Owner feedback 2026-11-11, points 3–5: long home page, no class/voucher
  history, and a parent role that could see but not pay.

**For review**
- Verified on the emulator: History tab as student2 (voucher expands to its
  two classes), parent overview and Payments as parent@, student1's payments
  note, admin Users chips and relation lines, compact home.
- `linkedParentUid` is informational only (a student could set it on their
  own profile); the parent's access still comes from the parent's
  `studentIds`, which the rules protect. No rules change.
- Functions deployed by the owner on 2026-11-11 (all 14 updated, incl.
  `finishExercise` review/duration and the `linkChild` stamp). Hosting was
  deployed earlier the same day. Review, saved times and the parent stamp are
  live.

---

## 2026-11-11 — Claude: exercise player checks at the end, timer, review, exercise history

**What changed**
- **Player** (`exercise_screen.dart`, `exercise_play_service.dart`): the
  student answers every question first (Back / Next, answers kept when
  moving around, "n of m answered"), then presses **Submit answers** once.
  Skipped questions are confirmed in a dialog and count as wrong. The
  result page shows score, correct count, time taken and a **review**: each
  question with the student's answer and, when wrong or skipped, the right
  answer. A failed submit offers **Try again** without losing the answers.
- **Clock**: counts up in the header from the moment the questions appear.
  A package can carry a **time limit** (`exercises.timeLimitMinutes`, set in
  the package form: "Time limit in minutes (optional)"); then the clock
  counts down, turns red in the last minute and submits by itself at zero.
- **Server** (`functions/index.js`, `functions/exercise_play.js`):
  `finishExercise` returns `review` (per question: answered, correct, key)
  and stores `correct`, `total`, `durationSeconds`, `exerciseTitle` and
  `category` (type of exercise of the first worksheet) on the result.
  `checkExerciseAnswer` is no longer called by the app and stays deployed
  for older cached clients. Old in-document exercises are checked in the app
  at submit time and write the same extra fields.
- **Exercise history**: the student's Progress tab has two segments,
  **Exercises** (every attempt newest first: title, type chip, date,
  correct/total, time, score pill; attempts / average / best on top) and
  **Lessons** (the previous view). The parent's overview "Recent grades" uses
  the same tile (`core/widgets/exercise_results_list.dart`).
  `ExerciseCategoryChip` moved to `core/widgets/`.
- Model: `ExerciseResult` gained `correct`, `total`, `durationSeconds`,
  `exerciseTitle`, `category`; `Exercise` gained `timeLimitMinutes`.
  New helpers `ExerciseUtils.formatClock / newestFirst / resultStats`,
  tests in `test/exercise_history_test.dart` (63 tests pass).
- Strings for the Progress tab added to `app_en.arb` / `app_id.arb`; the
  player itself stays English as before.

**Why**
- Owner feedback 2026-11-11: each answer took seconds to check (one Cloud
  Function call per question, each re-reading the whole worksheet bank from
  us-central1), and students had no score history or timer.

**For review**
- Deployed: functions (`finishExercise`, additive) and hosting, both on
  2026-11-11. No rules change. Verified on the emulator as student2: package
  of 20 questions (submit with skipped questions, review, 1-minute limit
  auto-submit) and the old in-document exercise (3/3, review).
- The time limit is not enforced on the server: a slow network can submit a
  few seconds late and is accepted.
- Known in-app quirk (pre-existing): opening a different exercise while one
  is already open on screen keeps the first one, because the screen has no
  key per exercise id; real navigation always pops first.

---

## 2026-11-10 (night) — Claude: precise admin tables — type and due columns, student page, bulk actions, CSV, monthly income

**What changed**
- **Exercises table** (`teacher_exercises_tab.dart`): a **Type** column
  and filter (type of exercise read from the first worksheet of the package
  in the question bank; older in-document exercises count as "Exercise"),
  a **Due** column (earliest due date among students who have not finished,
  red with "n overdue" when students are late), Students and Done merged
  into one "Done" column (`3/6`, click for names), Edit/Delete as icon
  buttons so the row fits a laptop screen without horizontal scrolling.
- **Student page for admins**: `/admin/users/:id` opens the existing
  `StudentDetailScreen` (profile, contact, vouchers, evaluations, practice
  results, lesson progress). It gained a **Payments** card (the student's
  invoices with paid / pending totals) and an **Attendance** card (present
  / excused / absent counts and the last classes). Clicking a student row in
  Users opens it; teacher and parent rows open the edit form. Admins get an
  edit pencil in the page header.
- **Tick rows for bulk actions**: `AppDataTable` has an optional checkbox
  column (`rowKey`, `selectedKeys`, `onSelectionChanged`; header box ticks
  every row shown). New shared `TableSelectionBar` and
  `SelectionActionButton` in `core/widgets/table_tools.dart`.
  - Users: Activate, Deactivate, Set HSK level (students in the selection);
    admin accounts are never touched. `FirestoreService.setUsersActive`,
    `setUsersLevel` (batched).
  - Exercises: Publish, Set to draft, Delete (admins on web).
    `FirestoreService.setExercisesPublished`; delete loops `deleteExercise`
    so each exercise's assignments are removed too.
  - Question bank: **New exercise (n worksheets)** opens the exercise form
    with the ticked sheets inside, Set type of exercise, Set level, Delete
    (existing `updateQuestionBankSheet` / `deleteQuestionBankItems`).
- **Export CSV** on Users, Exercises, Question bank, Payments and Vouchers
  (`ExportCsvButton`, `core/utils/csv_export.dart`): exports what the table
  shows after filters and sort, UTF-8 with BOM so Excel shows Chinese,
  file `<table>_<date>.csv`. Off web the CSV is copied to the clipboard.
- **Dashboard "Income / mo"** shows this month's paid invoices (Rp 0 when
  none, with the payment count) instead of "—"; its detail page lists the
  last twelve months (payments and totals). `core/utils/invoice_utils.dart`
  holds the month maths; the Financial summary section reuses the same
  invoices stream instead of opening its own.
- Shared `ExerciseCategoryChip` (moved out of the bank screen).

**Why**
- Owner asked for a precise admin page; these were the six recommendations
  they approved on 2026-11-10.

**For review**
- `flutter analyze` 0 errors / 0 warnings (18 infos, unchanged);
  `flutter test` 60 pass (4 new: CSV quoting, income by month).
- Checked on the emulator as admin: Income card and detail, Users bulk
  "Set HSK level" on two students, student page with Payments and
  Attendance, Exercises table with Type / Due and Publish ↔ Set to draft,
  bank bulk bar and "New exercise (2 worksheets)" opening the form, CSV
  download anchors firing for users and question bank (the in-app browser
  swallows downloads, so the files themselves were not opened).
- Bulk delete removes exercises / worksheets for good after a confirm
  dialog; past results stay.
- Deployed to hosting 2026-11-11 00:xx Jakarta (`scripts/deploy_web.sh
  --web-only`); live `main.dart.js` checksum matches the build. Release
  v0.1.10. From this deploy on, Claude deploys hosting after every push
  (owner decision, recorded in `CLAUDE.md`).

---

## 2026-11-10 (evening) — Claude: assets no longer cached after a deploy; bank picker with filters, edit and scan

**What changed**
- **Stale icon font after deploy.** Firebase Hosting served `assets/**`
  with `max-age=3600`, so right after a deploy the browser kept the old
  `MaterialIcons-Regular.otf` (without the new sun/moon/devices glyphs)
  next to the new app: the Appearance icons were blank. `firebase.json`
  now sends `Cache-Control: no-cache` for `/assets/**` (revalidated with
  the ETag, so unchanged files still cost a 304, not a download).
- **Add from the question bank** (exercise form): the same filter bar as
  the bank (search + Type of exercise + Question type + Level, shared
  `QuestionBankFilterBar` / `QuestionBankFilter` in
  `question_bank_filters.dart`), a pencil per row that opens the worksheet
  page (or the question editor) and returns to the picker, a **Scan
  worksheet** button that imports a sheet into the bank and ticks it, and
  the picker now watches the bank so edits show at once. Rows show the type
  of exercise.
- Theme switch label "Device / Perangkat" → "System / Sistem" (the long
  word wrapped inside the menu).

**For review**
- `flutter analyze` 0 errors / 0 warnings; `flutter test` 56 pass.
- Checked on the emulator: picker filters to Exam, pencil opens the sheet,
  back returns to the picker with the filter kept.
- The header fix needs one more hosting deploy to take effect; the icons
  also appear by themselves once the hour-old cache expires.

---

## 2026-11-10 (later) — Claude: Appearance menu in the header, text size, Type of exercise, exercises table

**What changed**
- **Appearance menu in the top bar** (sun / moon icon left of the bell, on
  every shell: desktop header, tablet row, mobile app bar). Panel with the
  Light · Dark · Device switch and a **Text size** slider (Normal · Big ·
  Bigger = 1.12 / 1.28 / 1.45 text scale; saved under `app_text_size`).
  `AppTextSize` in `theme_controller.dart`; `app.dart` feeds the scale to the
  `TextScaler`. The Profile / Account pages also show a Text size row.
- **Type of exercise on bank worksheets:** `ExerciseCategory` (Exercise ·
  Quiz · Exam · HSK Simulation, `lib/models/exercise_category.dart`) stored
  as `category` on every bank question (missing = Exercise). Set in the
  import review (default Exercise), the Edit worksheet dialog and the
  question editor; shown as a tinted chip column in the bank, with a filter.
  The **Tags** column and the tags input are gone (tag data stays; the
  sheet-code-in-tags fallback still works).
- **Question bank rows:** labelled **Edit** and **Delete** buttons in an
  Actions column (Edit opens the worksheet page, or the editor for a single
  question); the mobile card has the same two buttons.
- **Exercises tab is a table** (`AppDataTable`): Exercise (title + contents),
  Level, Skill, Students (assigned), Done (x/y, click opens the progress
  dialog), Status, Actions (Assign · Edit · Delete). Toolbar: search, Level
  and Skill dropdowns, Question bank, New exercise. The **Quizzes** and
  **Levels** buttons are gone from this tab (their routes still exist).
  Cards remain below the mobile breakpoint.

**Why**
- Owner feedback on the dark-mode build: the toggle was hard to find; the
  exercise cards looked unprofessional; the bank needed Edit in the row and
  bigger buttons; Quizzes/Levels are not wanted; text should be adjustable.

**For review**
- `flutter analyze` 0 errors / 0 warnings; `flutter test` 56 pass.
- Checked on the emulator (admin, dark): Appearance menu opens, slider to
  Bigger scales the whole page live and back; Exercises table at 1500 px;
  bank table with the new columns; Edit worksheet → Type of exercise = Exam
  shows as a chip in the list.
- At 1.45 the header gets tight on narrow windows; tables scroll sideways.
- Deployed by the owner the same day (hosting only, 54 files); live bundle
  checked for the new strings. Release v0.1.9 covers the dark mode, the
  worksheet editor and this entry.

---

## 2026-11-10 — Claude: dark mode; worksheet editor in the bank; New exercise on the empty tab

**What changed**
- **Dark mode** (owner: "my eyes hurt"). `lib/core/theme/app_theme.dart`
  now holds two `AppPalette`s (light, dark). `AppColors` keeps every name
  the screens use but reads them from the palette that is on, so the ~1,100
  call sites did not change except for dropping `const` where the compiler
  demanded it. `ThemeController` (`lib/services/theme_controller.dart`,
  saved under `app_theme` as `light` / `dark` / `system`, default follows the
  device) swaps the palette and `app.dart` remounts the page tree under a
  key so every screen repaints; `theme` / `darkTheme` / `themeMode` are set
  on `MaterialApp`. Toggle **Appearance: Light · Dark · Device**
  (`lib/core/widgets/theme_toggle.dart`, Indonesian strings included) on the
  admin Account, teacher Profile, student Profile and parent Profile pages.
  The public landing page stays light.
- **Worksheet editor in the question bank** (owner: edit "not just the
  name, also the type, level, and question"). Worksheet page: **Edit
  worksheet** dialog (title, type, level, skill; applies to every question,
  the code stays), **Add question** (prefilled from the sheet, goes last),
  move up / down, an edit pencil per row. New `question_bank_editor.dart`
  replaces the old editor: fields follow the type (choices with add/remove,
  shared word bank with a correct-answer picker and blank number, sentence
  parts, pinyin hint with accepted answers, picture keyword); saving a word
  bank copies it to the sheet's other questions.
  `FirestoreService.updateQuestionBankSheet` (replaces
  `renameQuestionBankSheet`) and `reorderQuestionBankSheet`.
- **Matching questions keep their word bank.** `ExerciseQuestion.toMap` /
  `fromMap` dropped `options` for the matching type, so a matching worksheet
  in the bank played with no choices. Fixed in `lib/models/exercise.dart`.
- **Exercises tab, empty state:** the button row and a **New exercise**
  button now show when there are no exercises yet (`EmptyState.action`).

**Why**
- Owner test round on v0.1.8: Activate, assignment and the language switch
  worked; New exercise was missing on the empty tab; the bank needed a real
  editor; the light screen hurt the owner's eyes.

**For review**
- `flutter analyze`: 0 errors, 0 warnings, 18 infos (down from 39:
  `dart fix` re-added `const` where it is still valid). `flutter test`:
  56 pass (3 new for the theme controller).
- Checked on the emulator: dark mode on the admin dashboard, Users table,
  question bank, worksheet page, editor, Account; live switch Light ↔ Dark
  from Account; student Home, Lessons, package play (server check) and
  Profile in dark; "Tampilan · Terang / Gelap / Perangkat" in Indonesian.
  Worksheet: moved a question and back, changed the sheet level (all
  questions follow), added a fill-in-the-blank question with answer B,
  removed it again.
- Not re-checked by hand: teacher screens, Classes/Vouchers/Payments/
  Reports tabs, parent screens in dark. They use the same `AppColors`
  names, so they follow the palette; a spot may still look off (white
  text on a light tint, say). Report it and it is a one-line palette fix.
- Hard-coded `Colors.white` stays only as text on primary-coloured buttons
  and in the auth brand panel; the snackbar uses a dark grey in dark mode.
- Deploy: hosting only (`scripts/deploy_web.sh --web-only`); no functions
  or rules changed.

---

## 2026-11-09 (night) — Claude: exercises are bank packages with server scoring; ID/EN switch; delete account

**What changed**
- **Exercise = package from the question bank.** New exercises hold
  `bankSheets` (worksheet codes) and `bankQuestionIds`; no questions of
  their own (`Exercise.isPackage`). Admin form
  `exercise_package_form_screen.dart` (title, level, skill, instructions,
  published, contents picked from the bank, reorder, "Save and assign").
  Editing a bank worksheet changes every exercise that uses it. Older
  exercises keep their embedded questions and the old editor.
- **Students see only assigned exercises** (`watchAvailableExercisesForStudent`
  now reads `exercise_assignments`; level no longer opens anything).
  Assign dialog `exercise_assign_dialog.dart` (search, level filter, due
  date, untick to unassign) on every exercise card and after saving a
  package. Worksheet page: **Rename** and **Assign this worksheet** (makes
  or reuses a one-sheet package).
- **Answer keys never reach the student for packages.** Cloud Functions
  `startExercise` (questions stripped, compose parts shuffled),
  `checkExerciseAnswer`, `finishExercise` (writes `exercise_results`,
  `scoredBy: server`), with pure helpers in `functions/exercise_play.js`
  (`node functions/test_exercise_play.js` checks them). Flutter side:
  `ExercisePlayService` / `ExercisePlaySession` (server for packages, local
  for legacy); `exercise_screen.dart` rewritten on top of it: question type
  per question, so a package can mix types.
- **Scan worksheet** (Exercises top bar) now imports into the bank and opens
  a new package with that sheet.
- **Delete account** (admin Users → trash icon): callable
  `deleteUserAccount` removes the Auth login, profile, progress,
  assignments (and link codes for teachers), writes an audit log. Admins
  cannot delete themselves.
- **Indonesian / English switch** (thesis Phase 1): `flutter_localizations`,
  ARB files in `lib/l10n/` (189 keys), `LocaleController` (shared_preferences
  `app_locale`, default from the browser language), toggle on login/register
  and in the student and parent Profile tabs. Auth, student and parent
  screens translated; admin/teacher stay English; `intl` bumped to 0.20.2.

**Verified (emulator, with the functions emulator)**
- Admin: load sample sheets → New exercise → add 210001-RDG + 300001-KLM →
  Save and assign → Bryan (student2) assigned; cards show "Assigned to N".
- Student (Bryan) opens the package: 20 questions served by
  `startExercise` without keys (checked the response body: no
  `correctIndex`, compose parts shuffled); "Check answer" → "Correct!"
  from `checkExerciseAnswer`. ID/EN toggle on the login page switches the
  copy. Analyzer 39 infos, 0 warnings, 0 errors; 53 tests pass.
- Follow-up fixes in the same session: student exercise card shows
  "2 worksheets" instead of "0 questions" for a package
  (`Exercise.contentsLabel`); Exercises tab creates its streams once (no
  flicker); package form fills the title after the frame, not during build.

**For review / deploy**
- Needs **functions** and **hosting**: `firebase deploy --only functions
  --project chinese-tracker` then `scripts/deploy_web.sh --web-only`. No
  rules change (students still cannot read `question_bank`; the function
  reads it).
- Functions deployed by the owner on 2026-11-09 (4 created, 10 updated);
  hosting deployed the same evening (live bundle checked). Release v0.1.8.

---

## 2026-11-09 (evening) — Claude: guard against a live bundle on the local dev server

**What changed**
- `lib/app.dart`: a bundle without `USE_EMULATORS` that is served from
  `localhost` / `127.0.0.1` shows a brown **LIVE DATA** ribbon (the emulator
  bundle keeps its red **EMULATOR** ribbon).
- `scripts/run_emulator_web.sh` (new): builds the emulator bundle into
  `build/web-emulator` and serves it on :5181 with `npx serve -s`.
  `CLAUDE.md` says to use it.

**Why**
- Incident: Claude's emulator dev server (`flutter run -d web-server`,
  serving `build/web`) kept running while the owner ran
  `scripts/deploy_web.sh`, which rebuilt `build/web` with the live config.
  The next sign-ins on localhost:5181 (student1@ / student2@test
  .chinesetracker, the shared test password) therefore hit the **live**
  project. Nothing was written (a student login only reads), the session
  was cleared and the server stopped, but it broke the "never sign in to
  live" rule and cost an hour of confusion. Two guards now make the state
  visible and keep the two bundles in separate folders.

**For review**
- Hosting deploy picks up the banner change whenever the next deploy
  happens; nothing urgent.

---

## 2026-11-09 (later) — Claude: bank grouped by worksheet, Kai font, table lines, difficulty removed

**What changed**
- **Question bank lists worksheets, not loose questions.** A scanned sheet
  is one row (printed title, code, type, level, question count, tags, used);
  opening it shows its questions in sheet order with the stored answer, each
  editable or removable, plus *Delete worksheet*. Questions typed or pasted
  on their own stay single rows. New fields on `question_bank` items:
  `sheetCode`, `sheetTitle`, `sheetIndex`; older items are grouped by their
  code tag (`QuestionBankItem.sheetKey`), so nothing needs migrating.
  `QuestionBankSheet.group` does the grouping (`question_bank_item.dart`);
  `QuestionBankSheetScreen` is the detail page.
- **Check before adding** names the worksheet, adds it with one button
  ("Add worksheet (7 questions)") and, when the same code is already in the
  bank, offers *Replace it* (default, deletes the old copy first) or *Keep
  both*. The level picker is hidden when a batch mixes levels (loading the
  sample set used to stamp all 10 sheets with one level: fixed).
- **Exercise form → From bank** groups the picker by worksheet; ticking the
  worksheet header selects all its questions.
- **Chinese font = Kai style** across the app: LXGW WenKai (OFL 1.1,
  `assets/fonts/LICENSE-LXGWWenKai-OFL.txt`), Regular + Medium (as bold),
  subset to GB2312 + Latin/pinyin/punctuation (~3.5 MB each) and declared in
  `pubspec.yaml`. The theme's CJK fallback moved from Noto Sans SC (runtime
  download) to this family; report PDFs keep Noto Sans SC.
- **Bigger question text:** `AppTextStyles.question` (18 px, 1.5 line
  height, Kai fallback) and `questionDetail` (15 px) used by the bank list
  and worksheet page, Check before adding, the scan review preview and
  extracted text, the exercise form's prompt/option/segment fields, and the
  student exercise/quiz options, compose chips and passage (18–22 px).
- **Tables:** `AppDataTable` draws column separators and darker row lines
  (`AppColors.tableLine`), taller rows (14 px) and 14 px cell padding; fixed
  column widths now mean content width (padding added on top), so icon
  columns keep their room. Affects Users, Reports, Payments, Vouchers, bank.
- **Difficulty removed** from the bank (model field, filter, column, editor,
  paste import, review, picker); `question_difficulty.dart` deleted. Old
  documents keep a stray `difficulty` field that is ignored.
- Sample set JSON: every item has a `title` (the printed sheet title).
- Snackbar after a scan: "Added worksheet 310001-RDG (7 questions)".
- Tests: `question_bank_import_utils_test.dart` now 4 tests (sheet fields,
  sample-set titles and order, grouping with tag fallback); 53 pass.

**Why**
- Owner (2026-11-09): "I want it to become a complete file, not 7 different
  questions", bigger text in KaiTi, clearer table lines, remove difficulty,
  more spacing. KaiTi itself is a Microsoft font and cannot be shipped, so
  the owner chose LXGW WenKai (same Kai style, free).
- Verified on the emulator: sample set → 10 titled worksheets; scan of
  310001-RDG with the sheet already in the bank → Replace → 7 questions in
  order; picker adds a worksheet in one tick; Users table lines.

**For review**
- Hosting deploy only (`scripts/deploy_web.sh --web-only`). No rules or
  functions changes. First load after deploy downloads ~7 MB of font once.
  **Deployed by the owner on 2026-11-09** (54 files; font and new bank code
  checked on the live bundle).
- Emulator-only quirk seen twice: the first sign-in after a page reload
  lands on /complete-profile; signing in again works. Not seen on live.

---

## 2026-11-09 — Claude: import progress never closed from the bank; elapsed time + estimate; answer keys applied to known sheets

**What changed**
- **Bug fix, the real "stuck" cause:** `scanWorksheet` (question bank, quiz
  editor, Exercises → Scan worksheet) popped the progress dialog with
  `Navigator.of(context).pop()`. From a screen inside the admin shell that
  is the nested navigator, so the dialog on the root navigator stayed open
  at 88 % "Detecting question type…" for ever, with the review screen hidden
  behind it. It now pops and pushes on the root navigator
  (`worksheet_scan_flow.dart`). The exercise-form path already did this.
- **Progress dialog** (`worksheet_import_progress_dialog.dart`): shows
  elapsed time (`Elapsed 0:14`), a rough time left ("about 20 s left",
  "almost done") once there is enough progress to estimate from, a detail
  line of what is happening right now, and a footnote on expected times.
  `WorksheetImportStage` gained `detail`.
- **Progress detail wiring:** PDF reader reports "Opening the PDF", "Reading
  page 1 of 3", "Scanned page 2 of 3 · Recognising text 45 %". OCR
  (`worksheet_ocr.js` + `ocr_reader_web.dart`) forwards Tesseract's own
  phases (loading engine, downloading Chinese data ~15 MB, recognising) as
  progress instead of jumping 10 % → 100 %. The Tesseract worker now stays
  alive between pages and between scans (released after 5 idle minutes), so
  a multi-page scan loads the language data once.
- **Answer keys for the centre's sheets** (`worksheet_answer_keys.dart`):
  the sheets carry no key, so a scan used to store "A" for every choice and
  the scrambled order for every compose item. When the scanned sheet's code
  (`310001-RDG`) is in the bundled sample set, the review screen fills in
  the answers from it (choice by answer text, compose order, accepted hanzi,
  and the word bank for the connect-the-words sheet) and says so: "Answer
  key: 7 of 7 answers filled from the centre's sample set (310001-RDG)".
  Sheets without a key show a warning that answers default to A / sheet
  order and must be corrected in the bank. `WorksheetParseResult` gained
  `sheetCode` and `copyWith`; the review's final result no longer drops the
  title and skill.
- Normaliser strips private-use glyphs (Wingdings ➢ bullets came out as □).
- Question bank: compose items show their sentence instead of "(no
  prompt)"; search and sort use that text; imports are tagged with the sheet
  code; the dedupe key uses the content, so two compose imports no longer
  collide on an empty prompt. Skill comes from the sheet code (KLM/WRT →
  typing).
- Tests: `worksheet_answer_keys_test.dart` (6), `question_bank_import_utils_test.dart` (2); 51 pass.

**Why**
- Owner (2026-11-09): "the importing worksheet needs a timer, at least a
  prediction how long, it feels like it was stuck" and "upload some of these
  to the question bank, I want to see the final result". Verified on the
  emulator with the two PDFs the owner sent (310001-RDG, 300001-KLM): both
  import with correct answers.

**For review**
- Hosting deploy only (`scripts/deploy_web.sh --web-only`). No rules or
  functions changes. **Deployed by the owner on 2026-11-09** (release
  v0.1.7).
- `web/worksheet_ocr.js` changed: hard-refresh once after deploy if the old
  file is cached.

---

## 2026-11-05 — Claude: Question bank in the sidebar, Scan worksheet first, sample sheets bundled

**What changed**
- **Question bank** is an entry in the admin sidebar (between Exercises and
  Classes); it opens the bank page. Admin tab indices after it moved by one
  (`shell_route_utils.dart`, dashboard quick actions, notification tabs).
- **Scan worksheet** is the primary action on the admin Exercises tab (top
  bar button and mobile FAB): pick a file → review what the scanner found →
  the exercise form opens already filled in (title, level, type, questions,
  answers where the sheet had them). A **Blank exercise** link stays in the
  tools row for exercises built from the bank.
- **Sample question set bundled**: `assets/question_sets/contoh_latihan_soal.json`
  holds the centre's ten sheets (96 questions) scanned with the real parser
  and keyed by hand (compose sentences in the correct order, 对/错 keys,
  hanzi answers, word choices, exam answers). Question bank → ⋮ → **Load the
  centre's sample sheets** reviews and adds them, skipping duplicates.
  Pictures for the 看图写句子 keywords are added in the editor.

**Why**
- Owner: "the upload is still quite manual", "put the previous upload into
  the bank", "a separate place to access the question bank easily".

**For review**
- Hosting deploy only. The answer keys in the JSON are mine; the owner should
  spot-check a few (ToF 3–6 are 错, HSK 5 exam 46–52 = C B D B A A C).

---

## 2026-10-29 — Claude: scanner reads all ten of the centre's worksheet forms

**What changed**
- `lib/core/utils/worksheet_text_normalizer.dart` (+ `pinyin_syllables.dart`):
  removes pinyin printed above the characters, re-joins the one-character
  lines, keeps `（gāng）` hints, splits `… answers. 1. 妈妈…`, drops ➢ bullets.
- `question_import_utils.dart` now also recognises: ★ true/false, inline
  `A … B … C …` options and `A xxx` option lines, `46-48.` passages with
  numbered gaps, several word lists per sheet (each blank gets its group's
  words as choices), **type the hanzi** (pinyin hint) and **picture +
  keyword** sheets, gaps drawn as lines on fill-in sheets, the centre's file
  code (`320001-WRT` → HSK 3, typing) and the sheet heading as title.
- Two new playable types: `type_hanzi` (student types the character; exact
  match against the admin's accepted answers) and `picture_sentence` (keyword
  + optional picture uploaded in the editor; the sentence must use the
  keyword). Player, exercise form (cards, import, save) and bank import
  support them. Multiple-choice cards now take any number of options.
- Tests: `test/worksheet_fixtures_test.dart` runs the ten real worksheet
  texts (`test/fixtures/worksheets/`); 43 tests pass. Results per sheet in
  `docs/WORKSHEET_FORMS.md`.

**Why**
- Owner: "implement the scanner for all these exercise types; I want to make
  exercises just from uploading."

**For review**
- Hosting deploy only.
- Limits: answer keys are not on the sheets (admin sets them after import);
  the vocabulary-matching sheet's two columns are drawings, so only its
  sentences are read; pictures are not cut out of the PDF (add them in the
  editor); the scanned exam page needs the on-device OCR, checked with a
  transcription, not the real scan.

---

## 2026-10-29 — Claude: exercise form is upload-only; site address easystudy.web.app

**What changed**
- **Exercise form**: no blank question to type into and no **Add question**
  button. Questions come from **Import from worksheet** (scanner) or **From
  bank**; imported questions stay editable so OCR mistakes can be fixed.
  The matching / fill-in-the-blank editor keeps its **Add prompt** for a
  missed line.
- **Hosting**: a move to `easystudy.web.app` was prepared and then reverted
  the same day; the owner keeps https://chinese-tracker.web.app.
- Owner's sample worksheets (`CONTOH LATIHAN SOAL.zip`, 10 PDFs) were run
  through the app's PDF reader + scanner; recognition results and the forms
  to build are listed in `docs/WORKSHEET_FORMS.md` (pending the owner's
  confirmation before implementation).

**Why**
- Owner: "new questions only by upload", "change the web.app name to
  easystudy.web.app", "check this zip and list what you recognise".

**For review**
- Hosting deploy only (after creating the site). No rules or functions.

---

## 2026-10-27 — Claude: Cloud Functions on Node 22

**What changed**
- `functions/package.json`: `engines.node` 20 → **22**; `firebase-functions`
  5.1 → 7.4, `firebase-admin` 12.7 → 14.5, `@google-cloud/firestore` 7 → 9.
  No code changes were needed (all imports are the explicit v2 modules).
  `node --check` and a local `require()` of `index.js` list all 10 functions.

**Why**
- The deploy on 2026-10-27 warned that the Node.js 20 runtime is
  decommissioned on **2026-10-30**; after that date functions cannot be
  deployed without this upgrade.

**For review**
- Redeploy: `firebase deploy --only functions --project chinese-tracker --force`.
  Each function is recreated on the Node 22 runtime; a few seconds of cold
  start on first call afterwards.

---

## 2026-10-27 — Claude: payments ↔ vouchers linked, Price list tab

**What changed**
- **Price list** (`/admin/price-list`, button on Payments and a card in
  Settings): the rows a payment can be for — name, price, what it gives
  (N class sessions, book, registration, other) — plus voucher validity days.
  Stored as `settings/pricing.items[]` (`PriceItem`); the four legacy fields
  are still written and read as a fallback. Defaults = the flyer.
  `functions/index.js` `loadPricing()` / `findPriceItem()` read the same list,
  so the charged amount is always the list price.
- **Every voucher belongs to a payment.** `student_class_terms.sourceInvoiceId`
  links a term to its invoice (the Midtrans webhook already wrote it).
  - Admin → Vouchers → **New voucher** requires picking the student's paid or
    pending session invoice (or **Record a cash / transfer payment** right
    there); package size comes from the payment.
  - Teacher **Add term** on a student page still works and now also records
    a **pending** cash/transfer invoice linked to that term (`classTermId`),
    so the admin sees it under Payments.
  - Vouchers tab: **Payment** column (Paid · date / Pending payment /
    No payment) with filter chips; term cards on the student page show the
    same line.
- **Payments tab**: Create invoice picks an item from the Price list and a
  method: **Cash / transfer** (pending manual invoice, written by the client;
  rules allow staff to create `status: pending, paymentMethod: manual` only)
  or **Online link** (Midtrans via `createInvoice`, now taking `priceItemId`
  and an optional `classTermId`). Pending invoices have a menu: **Mark as
  paid (cash / transfer)** → new callable `markInvoicePaid` (admin only;
  one transaction: flips to paid, then credits via the shared
  `creditPaidInvoice()`: marks the linked term paid or opens a new voucher;
  book/registration credit nothing; notifies + audit) and **Delete pending
  invoice** (admin, manual only; rules allow delete of pending only).
  Method column, Overdue pill.
- **Admin dashboard**: Financial summary now shows Revenue this month,
  **Pending payments** (count + Rp) with the oldest five to chase, and
  **Vouchers without payment** (active terms with no invoice: the old ones),
  each tapping through to Payments / Vouchers.
- Student Payments: a manual pending invoice says "Pay at the centre by cash
  or bank transfer" instead of a Pay now button.
- Rules: `student_class_terms.packageSize` any positive int (was 8/16) so a
  price-list row like a trial class can become a voucher; rules tests +3
  (invoices) → 27 total, 26 pass, 1 skipped. Flutter tests +3
  (`pricing_settings_test.dart`) → 33. Seed writes the items.

**Why**
- Owner: "connect payment and voucher; a voucher needs a payment; a separate
  tab with the list of things a payment can be for; teachers can add a term
  but admin must see a pending payment; old vouchers show as pending on the
  dashboard."

**For review**
- Deploy needs **functions** (`createInvoice`, `markInvoicePaid`,
  `midtransNotification`), **rules** and **hosting**. `markInvoicePaid`
  cannot run on the emulator (no functions emulator), so the cash path was
  checked on the live site by the owner.
- `createInvoice` still accepts the old `item` / `packageSize` arguments.

---

## 2026-10-27 — Claude: scanner-first question bank, quiz scan, tidier Reports

**What changed**
- **Question bank**: the main button is now **Scan worksheet** (upload a PDF,
  Word file or photo; the scanner detects each question's type and answer).
  Before anything is added, a **Check before adding** screen lists every
  detected question with its type chip and the answer the scanner read;
  untick wrong ones, set HSK level and difficulty for the batch, then add.
  Typing a question by hand moved to a **Type a question** button; paste and
  "Import from exercises" stay in the ⋮ menu. Fill-in-the-blank questions
  keep their word bank in the bank item (`options`), and pulling one into an
  empty fill-in-the-blank exercise fills the exercise's word bank.
  Shared scan flow: `lib/features/teacher/worksheet_scan_flow.dart`;
  review screen: `lib/features/question_bank/question_bank_import_review.dart`.
- **Quiz editor**: new **Scan worksheet** button next to **From bank**; the
  scanner's multiple-choice questions (incl. true/false and listening forms)
  are added to the quiz with their answers for the admin to check before
  saving.
- **Admin → Reports** redesigned: four sections (Students, Classes &
  teachers, Money, Platform exports), one uniform tile per report (number,
  title, one-line description, three figures, PDF button), two columns on
  wide screens. (`ExportReportCard` stays for the teacher cohort exports.)

**Why**
- Owner's second review: "New question should just upload to the scanner",
  "the report looks messy", "upload a quiz and check it".

**For review**
- Hosting deploy only.

---

## 2026-10-27 — Claude: worksheet scanner detects the exercise form

**What changed**
- `QuestionImportUtils.parseWorksheet` (`lib/core/utils/question_import_utils.dart`)
  now recognises, besides multiple choice / compose / matching:
  **R1 fill in the blank** (blanks + word bank → `reading_cloze`),
  **R3 reading comprehension** (passage + A–D → multiple choice with
  `passage`), **R4 order the sentences** (lettered sentences + optional
  answer key → compose sentences), **true/false** (√/× marks → 对/错 options)
  and **L3 listening** (listening type, audio attached later). The detection
  summary names the form and what still needs a hand (unmarked blanks,
  statements without √/×, groups without a key). Full table in
  `docs/WORKSHEET_IMPORT.md`.
- **Fill in the blank is now playable and editable**: `reading_cloze` reuses
  the matching data (shared bank + one prompt per blank), so the form shows
  the A–F bank editor and the student screen plays it like matching
  ("Blank 1 of 5", "Choose the word for the blank").
- **Reading passage** field on the exercise form (multiple choice, listening,
  fill in the blank); saved as `passage` and shown in a card above every
  question in the student screen. `createExercise` / `updateExercise` take
  `passage`.
- Tests: `test/worksheet_forms_detection_test.dart` (7 cases, incl. a guard
  that per-question A–C options are not mistaken for a matching bank).
  38 tests pass.

**Why**
- Owner's admin review item 2: upload a PDF and let the scanner determine
  what kind of exercise it is.

**For review**
- No rules or function changes; hosting deploy only.
- Still not detected: typing forms (T1–T3 pinyin/hanzi) and picture
  exercises (images are not extracted from PDFs). Listening worksheets
  import their questions but the form has no audio upload yet.

---

## 2026-10-27 — Claude: Classes calendar, Levels bundles, 8 admin reports

**What changed**
- **Classes tab is a calendar** (teacher and admin, `teacher_attendance_tab.dart`):
  month/week `TableCalendar`, dots per day (teal = open, grey = concluded),
  tap a day to see its classes and **New class this day** (pre-filled date via
  `session/new?date=yyyy-MM-dd`). The Active / History lists are gone; the
  same class card and Conclude dialog are reused.
- **Levels** (`exercise_levels` collection, `ExerciseLevel` model): a named
  bundle of published exercises assigned to a group of students. Saving a
  level materialises one `exercise_assignments` doc per (exercise, student),
  tagged `levelId`; editing the level adds/removes those docs for everyone
  in it, deleting the level removes them. Student views, stats and reports
  are unchanged because they already read `exercise_assignments`.
  Screens: Exercises → **Levels** (list, delete) and the editor (name, HSK
  filter, searchable exercise/student checklists with "Select all shown").
  Staff only (rules: `exercise_levels` read/write for teacher + admin;
  rules tests +2, 24 total: 23 pass, 1 skipped).
- **Admin → Reports**: eight new operational reports, each a card with live
  numbers and a PDF export (`admin_ops_report_service.dart` pure
  calculations, `admin_ops_reports_pdf.dart` layouts, unit tests
  `test/admin_ops_report_service_test.dart`, 8 cases):
  1. Attendance per student per month (Hadir/Izin/Alpa, present %).
  2. Term balance alerts (≤2 sessions, expiring ≤7 days, expired with balance).
  3. Revenue per month by item (8/16 sessions, book) + unpaid and overdue invoices.
  4. New students per month + retention (active = term with sessions left or a
     class in the last 30 days; retention over students who joined 60+ days ago).
  5. Class fill rate (seats taken / capacity, per month and per class).
  6. Teacher recap per month (scheduled, concluded, hours, students, attendance %).
  7. Student progress per HSK level (assigned, done, best-score average, no activity).
  8. Overdue homework per teacher (student's teacher; most overdue first).
  The four older exports stay below as 9–12. PDFs use the Noto Sans SC theme so
  Chinese names render. `formatRupiah` helper in `core/utils/money_format.dart`.
- Shell titles: Levels / New level / Edit level; levels routes highlight the
  Exercises tab.
- Sign-in race guard: `AuthService.isProfileLoading` is true between
  `signInWithEmailAndPassword` and the profile read; the router no longer
  redirects to `/complete-profile` during that window (seen once on the
  emulator with the saved-account button in a release build).
- Class form: Mode / Room / Registration fields hidden (one location, no
  rooms yet); existing values are kept on save.

**Why**
- Owner's admin review items 3, 4 and 5 (Levels, richer reports, calendar
  instead of Active/History).

**For review**
- Deploy needs rules + hosting (`firebase deploy --only firestore:rules` and
  `scripts/deploy_web.sh`). No function changes in this entry.
- Levels write up to (exercises × students) assignment docs in 400-doc
  batches; a level with 20 exercises × 30 students = 600 writes, fine for
  the centre's size.
- Attendance report counts a concluded class with no Hadir/Izin/Alpa mark as
  Alpa (pre-feature data); open classes are skipped.

---

## 2026-10-27 — Claude: editable prices (`settings/pricing`)

**What changed**
- New `settings/pricing` document (`PricingSettings` model): 8-session,
  16-session, HSK book, registration (display only) and term validity days.
  Defaults = the course flyer: Rp 2.450.000 / 3.950.000 / 250.000 / 100.000,
  60 days. Public read (landing page), admin write (`firestore.rules`).
- Admin **Settings → Prices** card edits it (`org_settings_screen.dart`).
- `functions/index.js`: `createInvoice` and the webhook read the document
  (`loadPricing()`); hard-coded `PACKAGE_PRICES` / `BOOK_PRICE` /
  `TERM_VALID_DAYS = 90` removed. Term validity is now 60 days by default.
- Admin Create invoice dropdown and the landing Prices section show the live
  values. `AppConstants.packagePricesIdr` is a fallback only.
- Rules tests: +3 (22 total, 21 pass, 1 skipped). Seed writes the doc.

**Why**
- Owner: prices must be editable by admin, and the old Rp 800k / 1.5M were
  wrong.

**For review**
- Deploy needs rules + all functions + hosting.

---

## 2026-10-27 — Claude: owner's admin review (review_web.pdf), 5 items

**What changed**
1. Create user → Ortu: the **Linked children** list has a search box (name,
   email, HSK level) and shows how many are selected
   (`admin_create_user_screen.dart`, `_SearchableStudentList`).
2. Admin **Edit user** for a student now embeds the same **term editor** the
   teacher has (add term, edit sessions and deadline, delete):
   `StudentClassTermSection(allowManage: true)` in `admin_edit_user_screen.dart`.
3. **Vouchers** tab explains what a voucher is (a student's paid 8/16-session
   term with a deadline, same as "Term packages" on the student page); column
   renamed "Voucher code".
4. **HSK materials & book** invoice item (Rp 250.000, no sessions credited):
   `functions/index.js` (`item: "book"`, `BOOK_PRICE`, webhook skips term
   creation, notifications/audit wording), `Invoice.item/itemLabel`,
   `PaymentService.createInvoice(item:)`, admin Create invoice dropdown.
5. **Conclude class** now opens an attendance dialog
   (`core/widgets/conclude_class_dialog.dart`): each joined student is Hadir /
   Izin / Alpa. Hadir and Alpa charge 1 session; **Izin is not charged**.
   `concludeClassSession(sessionId, statuses:)` writes `attendanceStatus`
   (`hadir|izin|alpa`; legacy `present|absent` normalised) and reports
   "N charged, M excused". Used by the Classes tab and the class detail page.

**Why**
- Owner review of the admin account (`review_web.pdf`, 27 Oct).

**For review**
- Verified on the emulator: conclude with 1 Izin → "4 charged, 1 excused".
- Functions redeployed (book item). Package prices are still the old
  Rp 800k / 1.5M (flyer: Rp 2.45M / 3.95M); owner has not asked to change them.

---

## 2026-10-20 — Claude: Android APK download, clearer link-code errors (owner test results)

**What changed**
- `scripts/deploy_web.sh`: builds web with `ANDROID_APK_URL`, copies the
  release APK to `build/web/downloads/easy-study.apk` and deploys hosting.
  **Use it for every hosting deploy**; a bare deploy drops the APK.
- Android release APK built on this Mac (JDK 21 via `flutter config
  --jdk-dir`, release keystore from `android/key.properties`). ~98 MB universal.
  **Not published yet:** Hosting on the free plan rejected it ("Executable
  files are forbidden on the Spark billing plan"). `deploy_web.sh --web-only`
  deploys without it until billing is enabled.
- Link-code and child-code checks now say "couldn't check right now, try again
  or contact the centre" when the Cloud Function returns internal/unavailable,
  instead of showing "internal".

**Why**
- Owner's test run: PUB-05 failed (no Android download), PUB-09 failed with an
  "internal" error. The error is the project's **disabled billing**: the live
  `resolveLinkCode` function answers HTTP 503 and its log says "billing is
  disabled for this project". Student registration, parent linking, invoices
  and the Midtrans webhook are all down until billing is re-enabled.

**Later the same day: billing re-enabled (Blaze)**
- All 9 Cloud Functions redeployed (includes the 17 Oct changes: link-code
  owner check, `userId: ''` on broadcasts). Website redeployed with the
  Android APK at `/downloads/easy-study.apk` and the landing button wired to it.
- Backup: watch the 02:00 Jakarta `scheduledFirestoreExport` run.

**For review**
- No native iOS app: needs a full Xcode install and an Apple Developer
  account. Web app on the iPhone home screen works (owner confirmed).

---

## 2026-10-20 — Claude: Students table, class form trimmed, landing menu/scroll

**What changed**
- Teacher **Students** tab (`StudentRosterList` in `cohort_stats_widgets.dart`,
  also used by the dashboard stat detail): search box, HSK level filter chips,
  "N students · M need attention" summary, sortable table (student, level,
  this term, homework, quiz avg, sessions left pill, last active) on wide
  screens; one-row cards on phones.
- Class form: **Mode**, **Room / link** and **Registration state** fields
  removed from the UI. Existing values are preserved on save. Registration
  state was only ever a label shown on the class detail; the real switch is
  "Open for students to join" (`isOpen`). Thesis Phase 2 adds rooms and real
  session statuses.
- Landing: top menu in page order; menu clicks scroll sections to sit below
  the sticky bar; plan-card corners no longer painted over; hero 易 drawn as
  text (the cursive logo crop looked broken).
- Landing: **WhatsApp** button in the hero and a floating round button
  (bottom corner) that open `wa.me/6282333836362` with an Indonesian greeting.
  Number from the flyer; change `_whatsAppNumber` in `landing_screen.dart`.
- Landing is now **WhatsApp-first** (owner's decision): "Start learning" and
  "I'm a parent" removed from the hero; plan cards say "Ask on WhatsApp"; the
  bottom CTA is "WhatsApp us" + "Sign in". Self sign-up remains only via the
  top-bar "Sign up" button and `/register`.
- WhatsApp mark drawn with widgets (`_WhatsAppMark`: green bubble + tail +
  white handset); floating button is white with the mark. No icon font or
  asset needed, so it cannot render blank.

**For review**
- `SessionMode` / `RegistrationState` enums and the `room` field stay in the
  model for old documents.

---

## 2026-10-18 — Claude: landing fixes (back buttons, prices section, plan cards)

**What changed**
- Landing CTAs use `context.push` instead of `go`, so Register/Login have a
  page to go back to. Register and Login back arrows fall back to `/` when
  there is nothing to pop. Login now shows a back arrow.
- New **Prices** section from the centre's flyer: registration Rp 100.000;
  8 meetings (12 h) Rp 2.450.000; 16 meetings (24 h) Rp 3.950.000; both valid
  2 months; 1.5 h per meeting; 6–8 students; ages 13+; HSK materials and book
  Rp 250.000; open class times; Midtrans payment note. Plan cards replace the
  old term tickets. Nav link "Prices".
- Footer: address (Jl. Manyar Tirtomoyo 7/11, Surabaya), phone, Instagram.
- Auth brand panel uses the logo-with-tagline artwork.

**For review**
- **Price mismatch:** `functions/index.js` `PACKAGE_PRICES` still charges
  Rp 800.000 / 1.500.000 for 8/16 sessions, and `student_class_terms` use a
  90-day validity. The flyer says Rp 2.450.000 / 3.950.000 and 2 months.
  Align when Phase 4 (voucher packages) is built; until then, invoices created
  in the app use the old prices.

---

## 2026-10-18 — Claude: app design system ("A, calmer"), emulator mode, seed script

**What changed**
- `lib/core/theme/app_theme.dart` rewritten: brand teal primary, green
  secondary, yellow accent, warm off-white page, Lexend text, 12px radius
  buttons, themed chips/segmented buttons/tabs/snackbars. Legacy names
  `AppColors.navy` / `teal` now alias the brand colours so all ~360 call sites
  restyle without edits. Sidebar shows the full logo lockup.
- Emulator mode: `--dart-define=USE_EMULATORS=true` connects Auth, Firestore,
  Functions and Storage to the local emulators (`lib/main.dart`,
  `lib/core/constants/build_flags.dart`) and shows a red EMULATOR banner.
- `scripts/seed_emulator.py`: demo data for the emulator (1 admin, 4 teachers,
  30 students across HSK 1–6, 1 parent, terms, this week's sessions,
  attendance, lessons, quizzes, exercises, results, grades, invoices).
- Register subtitle: "as a student or parent".

**Why**
- Owner chose direction A for the landing and "A, calmer" inside. The emulator
  lets Claude sign in locally with demo accounts to see and redesign screens
  without touching live data, and is required by the thesis spec.

**For review / lessons**
- `flutter run -d web-server` serves whatever is already in `build/web` while
  it compiles. A stale production bundle was served once on the emulator port
  and the test admin login hit the live project for a few seconds (signed out
  immediately, nothing changed). Mitigations: the EMULATOR banner, and
  `rm -rf build/web` before an emulator run.
- Run order: `firebase emulators:start --only auth,firestore,storage --project chinese-tracker`
  → `python3 scripts/seed_emulator.py` → `flutter run ... --dart-define=USE_EMULATORS=true`.

---

## 2026-10-18 — Claude: landing page rebuilt in brand direction "A · Pensil"

**What changed**
- `lib/features/landing/landing_screen.dart` rewritten; `landing_brand.dart`
  added (brand yellow/teal/green/black from the logo, Lilita One display,
  Lexend body via google_fonts, flat "sticker" shadows).
- Sections: nav (logo, anchors), yellow hero with the logo calligraphy 易
  cropped from `mascot_writing.png`, pencil mascot and 你好 bubble; scallop
  edge (pencil tip); teal HSK ruler (HSK 1–6 word counts); **About Easy Study**
  (new: HSK-standard centre, exercises per level, past exam questions from the
  real test, face-to-face classes at the centre); features; roles + 8/16
  session tickets; get-the-app (web); CTA; black footer.
- Copy corrected per owner: classes are at the centre only (no "from home").
- Stock Unsplash photos and the YouTube block are no longer on the page
  (`landing_media.dart` and the embed widget remain for a future real video).

**Why**
- Owner found the old navy page plain and off-brand; chose direction A for the
  landing and "A, calmer" for the signed-in app (next: design system).

**For review**
- Verified locally at 1280px and 375px. `flutter analyze` 0 errors/warnings.
- Fonts load from Google Fonts at runtime (same as the rest of the app).

---

## 2026-10-17 — Claude: security fixes, emulator + rules tests, billing problem found

**What changed**
- Teacher self-registration closed (Register + Complete-profile screens, `selfUserCreateValid`). Admins create teachers.
- Deactivated accounts: rules helper `isActive()` strips role rights; app signs them out at sign-in and launch.
- `teacher_link_codes` / `teacher_link_state` writes now require `isTeacher()`; `resolveLinkCode` checks the owner is an active teacher.
- Notifications: two provable queries in `watchNotificationsForUser`; broadcasts stored with `userId: ''` (app model + functions). Parents see `all` broadcasts.
- `firebase.json`: emulators (auth 9099, firestore 8080, functions 5001, storage 9199, UI 4000).
- `rules-tests/`: 19 Firestore rules tests (`npm --prefix rules-tests run test:emulator`). 18 pass, 1 skipped (emulator evaluates broad queries against data, production refuses them). Needs Java: `brew install openjdk@21`, then `export PATH=/opt/homebrew/opt/openjdk@21/bin:$PATH`.
- `docs/THESIS_FEATURE_BACKLOG.md` (spec) and `docs/THESIS_FEATURE_AUDIT.md` (status table, defects, decisions).

**Deploy status**
- Rules + hosting: deploy attempted 2026-10-17 (check `firebase hosting` release list / rules in console).
- **Functions NOT deployed: Secret Manager returned 403 "requires billing to be enabled"** → the project appears to have lost its Blaze/billing link. This also explains `scheduledFirestoreExport` PERMISSION_DENIED since 13 Oct. Owner must re-enable billing in the Google Cloud console, then run `firebase deploy --only functions`.

**For review**
- Until functions redeploy, `resolveLinkCode` owner check and `userId: ''` on function-written broadcasts are not live; app-written broadcasts already use `''`.
- Test checklist item PUB-08 ("Register a new Guru") is now expected to show no Teacher option.

---

## 2026-10-16 — Claude: deep links, forgot password, landing media (not deployed yet)

**What changed**
- `lib/main.dart` + `pubspec.yaml`: `usePathUrlStrategy()` (adds `flutter_web_plugins`).
  Web addresses are now `/login`, not `/#/login`. Hosting already rewrites `**`
  to `index.html`. Old `/#/...` links open the app at `/`.
- `lib/core/router/app_router.dart`: while auth initialises, redirect to
  `/splash?from=<target>` and return to `from` afterwards (internal paths only),
  so deep links and browser refreshes keep their page.
- `lib/services/auth_service.dart` + `lib/features/auth/login_screen.dart`:
  "Forgot password?" under the manual sign-in form, using Firebase's
  `sendPasswordResetEmail` with a neutral confirmation message.
- `lib/features/landing/landing_media.dart` + `landing_screen.dart`: replaced
  3 Unsplash photo IDs that returned 404. The YouTube video (`sWqnIyquCbM`) is
  unavailable, so the ID is now empty and the section shows a photo until the
  centre provides its own video.
- `lib/core/constants/worksheet_import_platform.dart`: removed unused import
  (analyzer now 0 errors, 0 warnings).

**Why**
- Found while writing the full test checklist: broken landing photos and video,
  `/login` and `/register` links opening the home page, and no password reset.

**For review**
- Verified locally (release web build): `/login` and `/register` open directly,
  reset dialog appears, all landing photos load. Reset email itself not sent in
  testing. `flutter test` 7/7 pass.
- Needs `flutter build web` + `firebase deploy --only hosting` to go live.

---

## 2026-10-16 — Cursor chat history MD + Claude handoff

**What changed**
- Added `docs/archive/cursor/CURSOR_CHAT_HISTORY.md` — brief rundown + dated timeline of Cursor
  sessions (git/GitHub, Mac↔PC, Midtrans deferrals, handoff to Claude).
- Added `docs/CLAUDE_FULL_HANDOFF.md` — complete ownership brief (GitHub URL,
  Firebase/Midtrans config, done vs P0–P3, architecture, risks).
- Cross-linked from `SESSION_LOG.md` / `BACKLOG.md`.

**Why**
- User continues all work with Claude; chat UI does not sync — need durable MDs
  in the private GitHub repo including conversation context.

**For Claude to review**
- Start: `docs/CLAUDE_FULL_HANDOFF.md`; conversation context:
  `docs/archive/cursor/CURSOR_CHAT_HISTORY.md`.
- Code of record: https://github.com/lightningxian/chinese-tracker

---

## 2026-08-10 — PC handoff doc

**What changed**
- Added `docs/SESSION_LOG.md` — Mac ↔ PC agent brief (done work, backlog,
  config keys, rules, session log).
- `docs/BACKLOG.md`: pointer to the handoff at the top.

**Why**
- User runs Cursor on a PC with different tasks; chat history does not sync, so
  the repo needs a durable handoff file.

**For Claude to review**
- Keep handoff session log updated when priorities or live config change.

---

## 2026-08-05 — Push-notes rule + initial GitHub release

**What changed**
- `CLAUDE.md`: every commit/push must include an overall
  summary note (commit body + GitHub release/PR when meaningful). Future
  author preference: `Wilsin Kuonadi <wilsinkarimunwkk@gmail.com>` (first
  commit author left as-is; do not rewrite).
- GitHub release `v0.1.0-initial` on `lightningxian/chinese-tracker` documenting
  what the first push contained.

**Why**
- User wants every push to carry a plain-language overall note; first snapshot
  documented on GitHub rather than only in chat.

**For Claude to review**
- Release notes accuracy vs actual tree; rule scope is always-on.

---

## 2026-08-05 — Initial git commit + private GitHub remote

**What changed**
- `.gitignore`: added `node_modules/`, `.firebase/`, and `docs.zip`.
- Removed a stale `.git/index.lock` (dated 2026-07-17) that blocked staging.
- First commit of the full project (~441 files) as author Wilsin Karimun
  (`wilsinkarimunwkk@gmail.com`), without writing global `git config`.
- Created private GitHub repo under `lightningxian` and pushed `main`.

**Why**
- The project previously had zero commits and no remote — single point of failure
  on one local disk.

**For Claude to review**
- Confirm the private repo exists and `main` is the only branch.
- Confirm `.figma-import/` (design-reference Vite project) should stay tracked.
- Next priorities unchanged: Midtrans sandbox payment test, then security
  hardening (§4 in `docs/BACKLOG.md`).

---

## 2026-07-22 — Fix startup crash (fontSizeFactor assertion)

**What changed**
- `lib/core/theme/app_theme.dart`: removed `fontSizeFactor: 1.12` from
  `TextTheme.apply()` — it asserted when some Google Fonts styles had null
  `fontSize`.
- `lib/app.dart`: applies the same ~12% text scale via `TextScaler.linear(1.12)`
  in `MaterialApp.router` builder instead.
- Rebuilt and redeployed hosting.

**Why**
- App crashed on startup (`text_style.dart` assertion) blocking local dev and
  potentially causing a blank page on the live site.

**For Claude to review**
- Confirm `TextScaler.linear(1.12)` respects accessibility expectations vs the
  old `fontSizeFactor` approach; consider clamping if system text scale should
  compound.

---

## 2026-07-22 — Hosting redeploy + cache headers (site access fix)

**What changed**
- Rebuilt and deployed hosting with the new landing page bundle (was only local
  before — live site still served the pre-restyle build).
- `firebase.json`: `Cache-Control: no-cache` on `index.html`, `flutter_bootstrap.js`,
  `flutter_service_worker.js`, and `main.dart.js` so browser/PWA caches don't stick
  on old bundles after deploys.

**Why**
- User reported the website could not be accessed; live curl returned 200 but the
  landing restyle had never been deployed to hosting.

**For Claude to review**
- If users still see a blank page, have them hard-refresh or clear site data for
  `chinese-tracker.web.app` (Flutter service worker).

---

**What changed**
- `landing_screen.dart`: full restyle to match `docs/landing_mockup.html` — sticky
  nav (Features / For you), hero with preview card + background image, trust bar,
  6 feature cards, 4 roles (**Orang Tua** included), how-it-works steps, CTA,
  footer.
- `landing_media.dart` + `widgets/landing_youtube_embed*.dart`: Unsplash photos
  (classroom, study, calligraphy) and embedded YouTube showcase on web.
- `pubspec.yaml`: added `web` for iframe embed.
- `BACKLOG.md`: landing marked done; Midtrans sandbox test
  deferred.

**Why**
- User requested professional landing with internet photos/video; Midtrans test
  queued for later.

**For Claude to review**
- Eyeball landing at mobile (~360px) and desktop; confirm Unsplash/YouTube load
  on deployed hosting (needs `firebase deploy --only hosting` to go live).
- YouTube embed id `sWqnIyquCbM` — swap if a centre-specific promo video is preferred.

---

## 2026-07-22 — Deploy per BACKLOG.md §1

**What changed** (deploy)
- `npm install` in `functions/`, then `firebase deploy --only functions` — all
  9 functions updated (payment-integrity fixes + `@google-cloud/firestore` dep).
- `flutter build web --release` with `CONTENT_OWNER_ID` + `MIDTRANS_CLIENT_KEY`,
  then `firebase deploy --only hosting,storage` — live bundle includes question
  bank upgrade + `question_bank_media` storage rules.
- `flutter analyze` — 0 errors.
- Updated `docs/BACKLOG.md` (§1 + question bank marked done).

**Why**
- User asked to execute Claude's recommendations list top-down.

**For Claude to review**
- Manual sandbox payment test still outstanding (§2).
- Node 20 deprecation warning on functions deploy — plan upgrade before Oct 2026.

---

## 2026-07-22 — Question bank upgrade (all 4 phases)

**What changed**
- **Phase 1 — metadata + table:** `QuestionDifficulty` enum; `QuestionBankItem` gains
  `difficulty`, `usageCount`, `lastUsedAt`, `updatedAt`, `sourceExerciseId`.
  Bank list is now `AppDataTable` (Prompt/Type/Level/Difficulty/Tags/Used/Actions)
  with difficulty filter and client-side sort. Editor adds difficulty selector.
- **Phase 2 — bulk import:** `addQuestionBankItems` (batched writes) in
  `firestore_service.dart`. Worksheet import + paste import via
  `question_bank_bulk_import.dart` (reuses `WorksheetImportService` /
  `QuestionImportUtils`). Picker gets "Select all (filtered)"; `incrementQuestionBankUsage`
  on confirm.
- **Phase 3 — harvest:** `question_bank_harvest.dart` — "Import from exercises"
  flattens `watchAllExercises()`, dedupes by prompt+type, batch-inserts new ones.
- **Phase 4 — media + quizzes:** `audioUrl` on `ExerciseQuestion`; image/audio
  upload via `QuestionBankMediaService` → `question_bank_media/{ownerId}/…`;
  `storage.rules` updated. Minimal quiz authoring: `QuizListScreen` +
  `QuizEditorScreen` with "From bank" picker; `createQuiz`/`updateQuiz`/
  `watchQuizzesForTeacher`/`deleteQuiz`. Routes `/admin/quizzes` and
  `/teacher/quizzes`; entry from Exercises tab.

**Why**
- Ran `docs/CURSOR_QUESTION_BANK_UPGRADE_PROMPT.md` from Claude.

**For Claude to review**
- Deploy `storage.rules` for `question_bank_media` before testing uploads.
- Quiz model still uses `QuizQuestion` (MC-only) at runtime — bank items with
  image/audio map through on save; student `QuizScreen` does not yet render
  per-question media (future enhancement).
- `usageCount` bumps in picker confirm — exercise "From bank" path inherits this
  automatically (no double-count).

---

**What changed**
- `scripts/setup_nas_backup_gcp.sh`: one-shot Mac script — creates
  `gs://chinese-tracker-backups`, IAM for `scheduledFirestoreExport`, read-only
  `nas-backup` SA + `nas-backup-key.json`, and writes `scripts/nas/rclone.conf`
  with the project number.
- `scripts/nas/nas_backup_sync.sh`: Docker-based daily pull for UGOS (Firestore
  exports + Firebase Storage files → `/volume1/backups/easystudy/`).
- `docs/NAS_BACKUP_SETUP.md`: added Quick start (UGREEN UGOS) section.
- `.gitignore`: `nas-backup-key.json`.
- Installed `gcloud` CLI via Homebrew on the dev Mac (was missing).

**Why**
- User asked to connect backups to their UGREEN NAS.

**For Claude to review**
- GCP script not run yet — `gcloud auth login` required on the Mac first.
- Confirm gen2 runtime SA (`{projectNumber}-compute@developer.gserviceaccount.com`)
  is correct for `scheduledFirestoreExport` IAM; adjust if the function uses a
  custom SA in console.
- After setup: verify first export lands in GCS, then NAS sync copies locally.

---

**What was checked**
- Opened `https://chinese-tracker.web.app` in browser: landing loads with the
  restyled LinguaHub UI (hero, features, roles). Flutter `flutter-view` present.
- Navigated to `#/login`: AuthScaffold split-screen login renders ("Learn
  Chinese, the easy way.", email/password form after "Sign in with another
  email").
- Live `main.dart.js` size `5156546` matches the local rebuild; contains
  `CONTENT_OWNER_ID` uid; client-key literal tree-shaken as expected
  (`hasMidtransClientKey` constant-folded).

**Blocked**
- Admin login (`admin@test.chinesetracker`) was not completed — password fill
  in the live browser was rejected by the approval gate. So the invoices-screen
  "client key not configured" banner and Users/Payments tables were **not**
  visually confirmed while authenticated.

**For Claude to review**
- Owner can finish the authenticated half: sign in as admin → Payments →
  confirm no Midtrans warning → Users/Vouchers/Grades tables render.

---

## 2026-07-18 — Hosting rebuilt + redeployed (client key wired, fixes live)

**What changed** (deploy)
- Rebuilt web with
  `--dart-define=CONTENT_OWNER_ID=2orTXFeyAhSlxfTgIlcYgs6ZuCG2` and the Midtrans
  **sandbox** client key (`Mid-client-…`, no `SB-` prefix — matches Midtrans's
  current sandbox format), then `firebase deploy --only hosting` (50 files,
  release complete). Live site returns `200`.
- The live bundle now includes today's shared-`AppDataTable` fixes (Users /
  Payments / Vouchers / Grades display), the Storage-backed Materials/profile
  paths, and a non-empty `MIDTRANS_CLIENT_KEY` so Snap checkout can initialize.

**Why**
- Previous live bundle was from 2026-07-14 with no client key and stale UI.

**Verification done**
- `CONTENT_OWNER_ID` concern (Claude flagged it as a possible dead dev
  placeholder): **resolved** — signed in as admin and read
  `users/2orTXFeyAhSlxfTgIlcYgs6ZuCG2` from production Firestore; it **exists
  and is `role: teacher`** ("Test Teacher" / teacher@test.chinesetracker), i.e.
  the seeded content-owning teacher. Correct for the current sandbox/testing
  phase; swap to the real teacher uid when a production teacher is onboarded.
- Client-key-in-bundle: the literal `Mid-client-…` is intentionally **not**
  present in `main.dart.js`. It's only referenced via
  `AppConstants.hasMidtransClientKey` (`.isNotEmpty`), which dart2js
  constant-folds to `true`, so the string is tree-shaken. Checkout does **not**
  need the client key client-side: `createInvoice` (server, uses the secret
  server key) returns a Snap `redirectUrl`, and the app opens it via
  `launchUrl`. The client key only toggles the "not configured" admin warning.
- Live site returns `200`; served bundle references the freshly deployed
  `main.dart.js` (buildConfig hash present in `flutter_bootstrap.js`).

**For Claude to review**
- Confirm the reasoning that the public client key is unnecessary in-bundle for
  the redirect-based Snap flow (no client-side Snap.js embed) — if you intended
  an embedded Snap popup instead of a redirect, that path would need the key at
  runtime and a code change.
- Server key never leaves Functions secrets (unchanged).

---

## 2026-07-18 — Deploy status recheck (hosting rebuild still pending key)

**Current live state (verified)**
- Functions: 9/9 `v2` deployed and listed.
- Storage: rules deployed, bucket live (see entry below).
- Webhook `midtransNotification`: `GET=405`, `POST {}=400` (healthy).
- Hosting `https://chinese-tracker.web.app`: `200` — but still the
  **2026-07-14 bundle** (no `MIDTRANS_CLIENT_KEY`, and missing today's
  table/display + Storage-dependent fixes).

**Blocked on owner input**
- Hosting rebuild is queued but waiting on the **Midtrans sandbox client key**
  (`SB-Mid-client-…`). Decided `CONTENT_OWNER_ID=2orTXFeyAhSlxfTgIlcYgs6ZuCG2`
  (per user). Planned command:
  `flutter build web --release --dart-define=CONTENT_OWNER_ID=2orTXFeyAhSlxfTgIlcYgs6ZuCG2 --dart-define=MIDTRANS_CLIENT_KEY=<sandbox-client-key>` then
  `firebase deploy --only hosting`.
- The client key is not stored anywhere in the repo (only injected via
  `--dart-define`); `app_constants.dart` reads it from the environment.

**For Claude to review**
- No code change in this entry — purely a state snapshot. Nothing to review
  beyond confirming the pending hosting rebuild is the only gap before the live
  site reflects current `main`.

---

## 2026-07-18 — Firebase Storage initialized + rules deployed

**What changed** (deploy)
- `firebase deploy --only storage` succeeded: enabled
  `firebasestorage.googleapis.com` and released `storage.rules`. This clears the
  earlier "Storage has not been set up" blocker.

**Why**
- Materials feature + profile photos need a live Storage bucket and rules.

**For Claude to review**
- Confirm `storage.rules` (`isStaff()` gate, `materials/` and `profile_photos/`
  paths) matches intended access; verify an actual upload/download round-trip
  from the Materials screen once hosting is rebuilt.

---

## 2026-07-18 — Backend deploy verified; remaining config gaps flagged

**What changed** (no code — deploy/verification pass)
- Confirmed all 9 Cloud Functions are live: `createInvoice`,
  `midtransNotification`, `linkChild`, `resolveLinkCode`, `resolveChildCode`,
  `cleanupExpiredLinkCodes`, `scheduledFirestoreExport` (us-central1) plus
  `onUserCreated`, `onExerciseResultCreated` (asia-southeast2). The two
  asia-southeast2 triggers that previously failed with an Eventarc Service
  Agent permission error deployed successfully on retry (transient first-time
  2nd-gen propagation).
- `MIDTRANS_SERVER_KEY` secret has an enabled version bound to the functions'
  runtime SA; validated it authenticates against the Midtrans **sandbox** API
  (404 "transaction doesn't exist", not 401). Earlier "duplicated prefix" was a
  terminal display artifact, not a bad key.
- Live webhook health: `GET → 405`, `POST {} → 400` (rejects non-POST /
  invalid payloads as expected). Hosting `https://chinese-tracker.web.app → 200`.

**Why**
- User asked for a general post-deploy status check.

**For Claude to review — open items (need owner action, not code):**
- **Midtrans dashboard**: Payment Notification URL must be set to
  `https://us-central1-chinese-tracker.cloudfunctions.net/midtransNotification`.
- **Hosted web build is stale + missing client key**: last hosting deploy
  (2026-07-14) used only `CONTENT_OWNER_ID`, no
  `--dart-define=MIDTRANS_CLIENT_KEY=…`, so Snap checkout won't open on the
  live site, and today's table/display fixes are not yet deployed. Needs a
  rebuild + `firebase deploy --only hosting`.
- **Firebase Storage**: still needs "Get Started" in console for Materials +
  profile photos (storage rules deploy previously blocked).
- **Secret hygiene**: 4 enabled `MIDTRANS_SERVER_KEY` versions; only latest is
  used — old ones can be destroyed.

---

## 2026-07-17 — Fix user/student lists blank or overflowing with sidebar

**What changed**
- `lib/core/widgets/app_data_table.dart`: breakpoint and horizontal scroll now
  use the **content pane width** (`LayoutBuilder`), not `MediaQuery` window
  width. With the 240px sidebar, a ~800–1100px window was choosing the desktop
  table while the pane was too narrow for the fixed columns → `RenderFlex`
  overflow (and in some cases an empty-looking body). Narrow panes now fall
  back to the card grid; slightly-tight panes get horizontal scroll.
- Also stopped wrapping left-aligned cells in `Align` (loosened width broke
  `Expanded` name cells) and simplified sortable headers.
- `watchAllUsers()` now also merges the `parent` role; admin Users role filter
  includes Orang Tua.
- `teacher_students_tab.dart`: clearer error when the students query fails;
  roster still renders if supporting streams are empty/errored.
- Grades "New grade" student picker: admins see all murid (not only
  `teacherId == contentTeacherId`).

**Why**
- User reported users still not displaying for admin and teacher after the
  shared-table refactor.

**For Claude to review**
- Spot-check Users / Payments / Vouchers / Grades at ~900px and ~1200px
  window widths (sidebar on).
- Confirm parent docs appear for admins and stay invisible to teachers'
  student queries.

---

## 2026-07-17 — Shared AppDataTable + Payments/Vouchers/Grades converted

Implements `docs/CURSOR_TABLES_PROMPT.md`. Visual/refactor only — no changes to
queries, models, rules, functions, or routes. `flutter analyze` clean
(pre-existing infos only).

**Task 1 — `lib/core/widgets/app_data_table.dart` (new)**
- `AppTableColumn<T>` (id, label, width|flex, sortable, alignment, cell
  builder) + `AppDataTable<T>` extracted from the Users tab's private
  `_UsersTable` / `_SortableHeaderCell` / `_UserTableRow`: navy-tinted header,
  sortable header cells with up/down arrows, striped rows with bottom borders,
  wrapped in `AppCard(padding: zero)` + `ClipRRect(16)`. Parent owns sort state
  (`sortColumnId` / `sortAscending` / `onSort(columnId)`); optional `onRowTap`.
- Below `mobileBreakpoint` (default 720, checked against screen width exactly
  like the Users tab did) it renders `mobileCardBuilder` cards in a
  `ResponsiveCardGrid` instead of the table.
- `admin_users_tab.dart` refactored onto it — the three private table classes
  were deleted, the name cell became `_UserNameCell`, sort/filter state and the
  `_UserSortColumn` enum stay in the tab (ids map via `enum.name`). Columns,
  widths, styles, actions, and the `_UserMobileCard` fallback are unchanged.

**Task 2 — three tabs converted (desktop table + existing card fallback)**
- Payments (`admin_invoices_tab.dart`): now stateful for sort state. Columns
  Invoice # · Student · Package · Amount (IDR via `NumberFormat.currency`) ·
  Due · Status (`StatusPill`: paid=success, pending=brandYellow, failed=error,
  expired=grey). Mobile fallback = the existing `InvoiceCard` (still exported,
  student payments tab untouched). Create-invoice toolbar, payments-disabled
  gate, and info banner unchanged.
- Vouchers (`admin_vouchers_tab.dart`): columns Code (monospace) · Student
  (same `usersById` lookup) · Package · Sessions left (`x/N`) · Deadline ·
  Status pill · Actions (edit/delete, same handlers incl. delete confirm).
  Mobile fallback = existing `_VoucherCard`. Search box unchanged.
- Grades (`teacher_grades_tab.dart`): now stateful; kept the
  pending-vs-recorded split as **two** `AppDataTable`s sharing one sort state.
  Columns Student (same async `_StudentLine` lookup) · Assessment · Category ·
  Score · Letter · Status pill (graded=success, pending=brandYellow) · Date
  (`gradedAt ?? createdAt`) · Actions. Row tap still opens the score/edit
  sheet; mobile fallback = existing `_GradeCard`.

**Beyond styling (small, flagged per the prompt's acceptance note)**
- Payments/Vouchers/Grades gained *local* sort state (the old list/card views
  had none); default order (no sort selected) is the stream's original order.
- Grades desktop rows expose a **Delete** action directly (confirm dialog →
  same `deleteGrade`); previously delete was only inside the edit sheet, which
  still has it. `_GradeIconAction` mirrors the voucher icon-action style.
- Vouchers: removed a now-unneeded outer `LayoutBuilder` (grid width is
  computed inside `AppDataTable`'s mobile branch instead).

**For Claude to review**
- Users tab must be pixel/behavior identical — the extraction is faithful
  except the table's inner `ClipRRect` radius went 12 → 16 to match the
  restyled `AppCard` radius (the old 12 predates the redesign).
- `AppDataTable` wraps every cell in `Align(column.alignment)` — spot-check no
  cell relied on stretching to full column width.

---

## 2026-07-17 — NAS backup CF, partial deploy, LinguaHub restyle

Ran three prompts: `docs/NAS_BACKUP_SETUP.md` (code half),
`docs/CURSOR_DEPLOY_PROMPT.md` (as far as possible without the user), and
`docs/CURSOR_REDESIGN_PROMPT.md` (full visual restyle). `flutter analyze` clean
(pre-existing infos only); `node --check functions/index.js` passes.

**1) NAS backup (code side done, GCP side pending)**
- `functions/`: installed `@google-cloud/firestore`; appended
  `scheduledFirestoreExport` (daily 02:00 Asia/Jakarta) exporting all
  collections to `gs://chinese-tracker-backups/firestore/<date>`.
- NOT done (needs user/gcloud — gcloud CLI is not installed on this Mac):
  creating the backup bucket, the IAM bindings for the runtime SA, the
  read-only `nas-backup` SA + key, and the NAS-side rclone jobs.
- The function itself deploys with the rest of functions once Blaze is active.

**2) Deploy (go-live §0–§5) — partially done, blocked on user**
- §0 verify: pub get + analyze clean, functions install + syntax check pass.
- §2: `firestore:rules` and `firestore:indexes` deployed successfully to
  `chinese-tracker`. (Console reports 3 stale remote indexes not in the local
  file — left in place, can be cleaned with `--force` later.)
- §2 storage: **failed** — Firebase Storage is not set up on the project yet
  (user must click "Get Started" in the console first).
- §1/§3: **blocked** — functions deploy requires the Blaze plan (error
  confirmed); `MIDTRANS_SERVER_KEY` secret not set (user must paste it).
- §4/§5: not run (needs `CONTENT_OWNER_ID`, Midtrans client key, and hosting
  deploy after the web build).

**3) LinguaHub restyle (visual only, no logic changes)**
- `app_theme.dart`: new tokens (`sidebarBg`, `sidebarActive #14181F`,
  `pageBg`, 4 pastel chip tint pairs); scaffold bg = `pageBg`; CardTheme radius
  16 + border + soft shadow; Filled/Outlined button themes (navy, radius 10);
  AppBarTheme flat white; inputs soft-filled.
- `app_shell.dart`: sidebar is now **white** with a right border; active nav
  item is a solid near-black navy **pill** with white text; inactive items are
  muted gray. Top bar gained a light-gray **role chip** and shows name + role
  next to the avatar. Mobile Figma app bar flipped from navy to white.
- `app_card.dart`: radius 16, default padding 20, very soft drop shadow,
  `margin: zero`.
- New `lib/core/widgets/stat_card.dart`: shared `StatCard` (muted label, 28px
  bold value, green subtitle, 44px tinted rounded-square icon chip) +
  `StatChipTint` (green/blue/purple/amber) with a `fromColor` mapper.
  `AdminStatCard` is now a thin wrapper delegating to it (all admin/teacher
  dashboard tiles restyled with zero call-site churn); parent overview
  `_StatCard` also delegates.
- `status_pill.dart`: radius 20 → 8, weight 700 (soft pastel pills kept).
- `auth_scaffold.dart`: brand panel now matches the reference (logo top-left,
  large white headline, muted subtitle, © footer); form panel is white.
  `test_login_screen.dart` now uses `AuthScaffold` (same split layout as
  login/register); its redundant logo card was removed.

**What Claude should focus on**
- Restyle only: verify no behavioral drift (nav `IndexedStack` indices,
  `AppShellScaffold` API — one added required-with-default param `roleLabel`
  on the private `_AppTopBar` only).
- `AppCard` now sets `margin: EdgeInsets.zero` (Card's default 4px margin
  removed) — spot-check dense lists for spacing regressions.
- Deploy follow-ups for the user: Blaze upgrade, Storage "Get Started",
  `firebase functions:secrets:set MIDTRANS_SERVER_KEY`, then
  `firebase deploy --only functions` (9 functions incl.
  `scheduledFirestoreExport`), then web build with `CONTENT_OWNER_ID` +
  `MIDTRANS_CLIENT_KEY` and hosting deploy; NAS doc §A bucket/IAM via gcloud.

---

## 2026-07-17 — Tier 3: Org Settings, Audit log, Materials, Evaluations, Financials

Implements `docs/CURSOR_TIER3_PROMPT.md`. Per the prompt's scope decision (single
centre, one admin) we built **Phases 1–5** and intentionally **skipped Phase 6**
(granular admin permissions — only needed with >1 admin) and the separate Owner
role / teacher ratings. `flutter analyze` is clean (only pre-existing infos);
`node --check functions/index.js` passes.

**What changed**

Phase 1 — Org Settings (`settings/org`)
- Model `lib/models/org_settings.dart` (defaults: payments on, reschedule on,
  eval forms closed, verification/auto-password off). Falls back to defaults
  when the doc is missing.
- Service: `watchOrgSettings()` / `getOrgSettings()` / `updateOrgSettings()`
  (merge write, stamps `updatedAt`/`updatedBy`).
- `lib/features/admin/org_settings_screen.dart` — admin-only toggles; each
  toggle persists immediately. Links to Audit logs + Materials. Reached from the
  admin **Account** tab → "Centre settings" card (`/admin/settings`).
- Gates wired:
  - `enablePayments` gates the Buy/invoice UI — `AdminInvoicesTab` and
    `StudentPaymentsTab` show a "Payments are disabled" state when off.
  - `evaluationFormsOpen` gates evaluation create/edit (Phase 4 UI).
  - `allowTeacherReschedule` gates the teacher session **Edit** action in
    `teacher_session_detail_screen.dart` (admins always allowed).
- `requireEmailVerification` and `autoGenerateStaffPasswords` are **stored
  preferences only** — not yet enforced in auth flows (flagged for later).

Phase 2 — Audit log (`audit_logs`)
- Model `lib/models/audit_log.dart`; `watchAuditLogs()` (newest first, limit
  200). `lib/features/admin/audit_logs_screen.dart` (admin read-only).
- Cloud Functions: added `writeAudit(entry)` helper (best-effort; never breaks
  the audited action). Emits `invoice.created` (in `createInvoice`, actor = the
  admin caller) and `invoice.paid` (in `midtransNotification`, actor = system).
- Rules: `audit_logs` — `read: if isAdmin(); create/update/delete: if false;`
  (all writes via admin SDK).

Phase 3 — Materials (`materials` + Storage)
- Model `lib/models/material_item.dart` (named `MaterialItem` to avoid clashing
  with Flutter's `Material`). Service CRUD + `watchMaterials(ownerId)` (staff)
  and `watchPublishedMaterials(ownerId)` (student/parent).
- `lib/services/materials_storage_service.dart` — mirrors `ProfilePhotoService`;
  validates extension + caps at 25 MB; uploads to `materials/{ownerId}/...`.
  Provided in `app.dart`.
- `lib/features/materials/materials_screen.dart` — staff CRUD + upload +
  publish toggle; read-only published list for students/parents (opens files via
  `url_launcher`). Entry points: teacher dashboard card, admin Settings card,
  student home card (`/student/materials`), parent overview card
  (`/parent/materials/:childId`, guarded by linked-child check).
- Rules: `materials` — read for staff OR `status == 'published'`; write staff.
  Storage rules: staff write under `materials/{ownerId}`, read for signed-in.

Phase 4 — Semester evaluations (`evaluations`)
- Model `lib/models/evaluation.dart`; service watch (teacher / student, with
  `publishedOnly`) + CRUD.
- Teacher: `lib/features/evaluations/student_evaluations_section.dart` embedded
  in the teacher **student detail** screen — create/edit/publish/delete per term
  with a 1–5 star rating; New/Edit disabled unless `evaluationFormsOpen`.
- Student/Parent: published evaluations render as a "Teacher evaluations"
  section in `TranscriptView` (reused for both).
- Rules: staff write; student reads own **published**; parent reads linked
  child's published (`isParentOf`).

Phase 5 — Admin financial summary
- `_FinancialSummarySection` on the admin dashboard, computed from `invoices`:
  revenue this month (paid, `paidAt` in current month), outstanding (pending),
  and the 5 most recent payments. Read-only; reuses `AdminStatCard`.

Indexes: added `materials(ownerId, createdAt DESC)` and
`materials(ownerId, status, createdAt DESC)`. Evaluations queries filter by a
single equality field and sort client-side, so no composite index is required.

**What Claude should focus on when reviewing**
- Rules: confirm students/parents cannot read `audit_logs`, draft `materials`,
  or unpublished/other students' `evaluations`; confirm parent reads are limited
  to linked children (`isParentOf`).
- `evaluationFormsOpen` is enforced **only in the UI** (Firestore rules can't
  cheaply read another doc per write). If server enforcement is required, move
  evaluation writes into a callable that checks `settings/org`.
- `requireEmailVerification` / `autoGenerateStaffPasswords` are not yet enforced.
- Materials `ownerId` uses `AppConstants.contentOwnerFor(user)` so staff writes
  and student/parent reads resolve to the same owner — verify this matches the
  content-owner model for admins vs teachers.
- Deploy still required: `firebase deploy --only
  firestore:rules,firestore:indexes,functions` and `firebase deploy --only
  storage` (materials Storage rules). Functions need the Blaze plan.

---

## 2026-07-17 — Tier 2: Gradebook, Question Bank, Class metadata

Implements `docs/CURSOR_TIER2_PROMPT.md` in three phases. `flutter analyze` is
clean (only pre-existing infos); `node --check functions/index.js` passes.

**What changed**

Phase 1 — Gradebook
- New `grades` collection. Model `lib/models/grade.dart` (`GradeCategory`,
  `GradeStatus`, derived `displayLetter`).
- `lib/core/utils/grade_utils.dart` — `letterGradeFor(score)` (90 A · 85 B+ ·
  80 B · 75 C+ · 70 C · 60 D · else E), reused everywhere.
- `firestore_service.dart`: `watchTeacherGrades`, `watchTeacherPendingGrades`,
  `watchStudentGrades`, `createGrade`, `setGradeScore`, `updateGradeMeta`,
  `deleteGrade`; plus `watchStudentQuizResults` + `lib/models/quiz_result.dart`
  for the transcript.
- Teacher **Grades** tab (`lib/features/teacher/teacher_grades_tab.dart`):
  pending queue + recorded list, create/score/edit/delete bottom sheet. Wired
  into `teacher_shell.dart` (new tab) and a live "Gradebook · N pending" card on
  `teacher_dashboard_tab.dart` that opens `/teacher/grades`.
- Read-only transcript (`lib/features/grades/transcript_view.dart`) merging
  grades + quiz + exercise scores. Reached from student home
  (`/student/grades`) and parent overview (`/parent/grades/:childId`, guarded to
  linked children).
- Rules: `grades` — staff read/write, student reads own, parent reads linked
  child's. Indexes: `grades(teacherId,createdAt)` and `grades(studentId,createdAt)`.

Phase 2 — Question Bank
- New `question_bank` collection. `lib/models/question_bank_item.dart` wraps
  `ExerciseQuestion` (same serialization → drops into exercises).
- `firestore_service.dart`: `watchQuestionBank(ownerId)` + create/update/delete.
  Index `question_bank(ownerId,createdAt)`.
- Screen `lib/features/question_bank/question_bank_screen.dart`: list, filter by
  type/level, search prompt/tags, full editor (MC/listening/compose/matching +
  level/skill/tags), and `showQuestionBankPicker(...)`.
- Exercise authoring form (`teacher_exercise_form_screen.dart`): "From bank"
  button opens a type-filtered picker and appends selected questions to drafts.
- Entry point from the Exercises tab; routes `/admin/question-bank` and
  `/teacher/question-bank`.
- Rules: `question_bank` scoped to **staff only** (read + write) so students
  never read raw answers.

Phase 3 — Class metadata
- `lib/models/class_session.dart`: added optional `mode` (`SessionMode`:
  offline/online/hybrid), `room`, `registrationState` (`RegistrationState`:
  draft/open/active/closed) + `isOpenForRegistration`. Older sessions stay valid.
- `firestore_service.dart`: `createClassSession`/`updateClassSession` accept the
  new fields (update clears via `FieldValue.delete()` when unset).
- Session form exposes mode/room/registration. Calendar tiles
  (`class_calendar_screen.dart`) show `mode · room · Cap N` + an "Open for
  registration" badge. Session detail shows mode/room + a registration pill.

**Why**
- First-class grades give teachers a pending queue and students/parents a real
  transcript; a reusable question bank avoids re-authoring; class metadata makes
  the calendar/class views informative and enables an open-for-registration state.

**For Claude to review**
- Rules tests: student cannot write `grades`; parent can read only their linked
  child's grades; students cannot read `question_bank`.
- Confirm the gradebook `teacherId` (uses `AppConstants.contentTeacherId`) lines
  up with the dashboard pending-count query (`teacherId = contentOwnerFor`) for
  admins with `CONTENT_OWNER_ID` set — they match for teachers; double-check the
  admin-with-override case.
- Question Bank + "From bank" are gated to authoring-capable staff (admin on web
  per `ExerciseAuthoringPlatform`). Decide if teachers should build/browse the
  bank on web even though exercise authoring stays admin-only.
- Deploy still required (adds rules + composite indexes):
  `firebase deploy --only firestore:rules,firestore:indexes`.

---

## 2026-07-17 — Tier 1 review fixes (payments / parent / calendar)

Follow-up to `docs/CURSOR_TIER1_REVIEW.md`.

**What changed**
- R-2: `functions/index.js` `createInvoice` now derives `amount` from a
  server-side `PACKAGE_PRICES` table (8 → Rp 800k, 16 → Rp 1.5M) and ignores the
  client-supplied amount. Matches `AppConstants.packagePricesIdr` (display only).
- Verified R-1 (parent link authorization) and the webhook double-credit
  transaction fix were already applied and correct: `linkChild` callable +
  rules blocking client writes to `studentIds`/`teacherIds`.

**Why**
- Prices should be authoritative on the server so a caller can't misprice a sale.

**For Claude to review**
- Deploy prerequisites (Blaze): `firebase functions:secrets:set
  MIDTRANS_SERVER_KEY`, then deploy functions/rules/indexes, register the
  `midtransNotification` URL, and set a sandbox Client Key before end-to-end test.
