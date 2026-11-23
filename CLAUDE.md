# Easy Study (`chinese-tracker`) — Claude project guide

Flutter web + Firebase LMS for a Chinese teaching centre (易华文教中心).
Roles: admin · teacher · student · parent. Live at https://chinese-tracker.web.app.
The owner (Wilsin, a Flutter/Firebase beginner) works **only with Claude Code**, on a Mac
and a PC. Chat does not sync between machines: the docs in this repo are the shared memory,
so keep them current. Explain steps in simple English and ask before big or hard-to-undo
decisions. This app is also the owner's thesis project (see the thesis docs below).

## Read first
0. `docs/PLAN.md`: current state, the build queue (item marked **NEXT**) and the two-chat workflow (PLAN chat = Fable, docs only; BUILD chat = Opus, code). A build chat starts here.
1. `docs/CLAUDE_FULL_HANDOFF.md`: live config, what's built, architecture map.
2. `docs/THESIS_FEATURE_AUDIT.md`: the thesis spec (`docs/THESIS_FEATURE_BACKLOG.md`, v2) compared with the code, open questions, suggested order. `docs/THESIS_PROPOSAL_ASSETS.md` lists the screenshots the proposal needs. `docs/THESIS_BOOK_GUIDE.md` (2026-11-23) is the summary of what the book, trial and campus steps require, from the owner's own documents.
3. `docs/SESSION_LOG.md` (newest session first) and the top of `docs/CHANGELOG.md`.
4. `docs/BACKLOG.md` for the older non-thesis backlog.

## Decisions already made by the owner (don't re-ask)
- Design: landing page = direction "A · Pensil" (shipped 2026-10-18, `lib/features/landing/`); signed-in app = the same brand, calmer (white surfaces, less decoration). Brand tokens: `lib/features/landing/landing_brand.dart`, logo assets in `assets/brand/`.
- Keep the parent role, materials library and class modes even though the thesis leaves them out.
- UI language: Indonesian + English switch for every role (auth/student/parent 2026-11-09; admin/teacher/question bank 2026-11-12). Toggle on login and on each profile tab.
- Teacher self-registration is closed; admins create teachers.
- Keep the Grades and Evaluations tabs (outside the thesis).
- Thesis test codes are random strings typed by the admin, with HSK level and release year as separate fields. No access to the old `easy-study-hsk` project: no import of old results.
- Voucher packages: Chinese name, validity (e.g. 2 months), 8 or 16 sessions, the student's class day. Prices live in the admin **Price list** (`settings/pricing.items`, flyer defaults).
- **Payments ↔ vouchers (2026-10-27):** every voucher links to an invoice (`sourceInvoiceId`). Admin records cash/transfer payments (`markInvoicePaid` callable); teachers may still add a term on a student page, which creates a pending invoice for the admin; old vouchers without a payment are shown on the admin dashboard as "Vouchers without payment".
- Order of work: quick security fixes (done) → emulator (done) → design system → thesis phases in order, rebuilding each screen in the new design as its phase touches it, with ViewModels.
- **Exercises = packages from the question bank (2026-11-09):** an exercise lists bank worksheets (`bankSheets`) and single questions (`bankQuestionIds`); students see only exercises assigned to them; packages are played through the `startExercise` / `checkExerciseAnswer` / `finishExercise` functions so answer keys never reach the client. Levels stay (they assign several exercises at once). **Teachers build packages too (2026-11-13):** a teacher creates, edits, publishes and deletes their own packages (`teacherId` = their uid) and assigns them; admins manage every exercise. The old-format editor stays admin-only. **Build 2B (2026-11-20):** a teacher types, pastes, edits and deletes their own bank questions and worksheets (`createdBy` = their uid); scanning, samples and test codes stay admin-only. See `.claude/rules/exercise-authoring-web-only.md`.
- **UI language (2026-11-12):** every screen reads `context.l10n` (`lib/l10n/app_en.arb` template + `app_id.arb`, ~1,380 keys). Model enums keep their English `label` (sorting, CSV fixtures, logs); the UI shows them through the `localized(l)` extensions in `lib/l10n/labels_*.dart`. `LocaleController` also sets `Intl.defaultLocale`, so `DateFormat` follows the switch. Still English on purpose: the legacy exercise editor, quiz and level screens (unused), service error messages, PDF/CSV exports built in `lib/services`, OCR progress details.
- **Quizzes and Levels (2026-11-10):** owner does not need them. Buttons removed from the Exercises tab; routes/screens still exist. The bank carries a **Type of exercise** per worksheet instead (`ExerciseCategory`: Exercise · Quiz · Exam · HSK Simulation).
- **Exercise play (2026-11-11):** students answer every question first and submit once; `finishExercise` checks the whole attempt and returns the review. No per-answer function calls. A package may carry `timeLimitMinutes` (counts down, auto-submits).
- **Parents (2026-11-11):** the parent is an optional add-on account linked by the child code. Invoices stay on the student; both the student and the linked parent see them and may pay. `linkChild` stamps `linkedParentUid`/`linkedParentName` on the student so the student's Payments tab can say who handles payments. Admin Users is split by role with chips.
- **Exam mode (2026-11-13):** a package whose first worksheet is Exam or HSK Simulation is one attempt with a server clock (`exercise_attempts`, `startExercise` `peek` → start screen → `finishExercise` closes it; late = 0). Practice packages stay unlimited. `resolveLinkCode` / `resolveChildCode` are rate-limited per address.
- **Scores (2026-11-12):** `exercise_results` is written only by `finishExercise`; the rules have no client write. Old-format exercises (questions inside the doc) cannot be played; the admin deletes them. Bank questions may carry an `explanation`, sent only with the review.
- **HSK simulation (2026-11-13):** a paper is scanned with **Scan paper with AI** (Gemini `gemini-3.8-flash` via Firebase AI Logic, `lib/services/worksheet_ai_import_service.dart`; needs the console setup in `docs/WORKSHEET_IMPORT.md`), reviewed, and saved as one worksheet with part headings (`section`), a picture per choice (`optionImageUrls`) and, later, one listening recording for the sheet (`sectionAudioUrl`, uploaded on the worksheet screen). Keys the reader cannot know (listening) are typed with the worksheet's **Answer key** dialog. The player shows the part, the recording, picture choices, and HSK marks per part (listening / reading / writing out of 100, pass at 60%). The on-device scanner stays as **Scan without AI**. App Check is activated when `APP_CHECK_SITE_KEY` is set (`deploy.env`), enforcement only for AI Logic.
- **Owner answers 2026-11-16** (full list in `docs/PLAN.md` §2): staff see students as `Chinese name (Latin name)`, students see other students by Chinese name only; rooms are `Main` and `Sub Room`; class slots have no HSK level (semi-private teaching, 6–8 seats); placement tests are public on the landing page behind a teacher code; supervised tests run through test codes with a clock per part and an HSK-style result card; teacher schedule = tabs on one screen; builds are 3–4 hour sessions in the BUILD chat on the PC.
- **Paper reader (2026-11-17):** HSK papers are read **inside the app with no outside API** (owner: "the job is only to read the PDF and build the questions"): on-device OCR with watermark removal, a structure builder that follows the test format, a proofreading screen, pictures cut by image analysis (Build 1B in `docs/PLAN.md`). **Scan paper with AI** stays as an extra, off on live until an App Check key exists. Official exam papers are never committed (`local_papers/` is git-ignored) and Claude does not type them out by hand. Each worksheet may carry a transcript of its recording, sent to students only with the review.
- **Typing matcher and marking (Build 2A, 2026-11-17, from the proposal):** typed hanzi and pinyin are matched in `functions/typing_matcher.js` (full-width, ending punctuation, traditional characters and tone numbers all count; one wrong character or wrong tones = half, flagged; sentence order never half). Free writing (`picture_sentence`, `essay`) is 10 points and only a teacher marks it. Open items go to `marking_items` (written by functions only); a result with open items is `pending_marking` with no pass or fail; `markAnswer` makes it final and notifies the student. Teachers see their own queue, admins all.
- **Paper reader engine (Build 1C, owner 2026-11-18):** Scan paper reads with PP-OCRv5 mobile (PaddlePaddle, Apache-2.0) through onnxruntime-web (MIT) in the browser (`web/paper_ocr_paddle.js`); Tesseract finds the lines and is the fallback. The ~31 MB of model files are served from our hosting, fetched at build time (`scripts/fetch_paper_ocr.mjs`), never committed. Flags by HSK level (`HskCharacters`, old HSK 1-3 lists) and stray marks; tone buttons for pinyin; a proofreading record per scanned worksheet; **Download text** gives a truth file for measuring.
- **Leaderboard and promotion (Build 2B, 2026-11-20):** the `onTestResultWritten` trigger keeps `leaderboards/{codeId}/entries/{uid}` (final, valid, non-placement results; students see Chinese names) and `promotion_progress/{uid}`; at `settings/promotion.minCodes` (3) different codes passed at the student's level it writes `level_promotions/{uid_levelKey}` for the admin, who approves (`decidePromotion`: level up, `level_history`, student + parent told) or declines with a reason. `users.level` is admin-only. Pure logic in `functions/promotion.js`.
- **Registration approval and placement (Build 3, 2026-11-20):** a self-registered student is `status: 'pending'` (rules require it; `active` stays the admin's on/off switch; no `status` = an old, approved account) and sees only `/waiting` until an admin approves on Users → **Approval** (`decideRegistration`: level, teacher, a result code claimed once; reject with a reason). The teacher link code is optional at registration. A **placement session** (tick on Open session) keeps results off the board and the count and writes `level_promotions/{uid}_placement` (passed = paper level + 1, failed = paper level) for the Promotion screen. A **placement code** (tick on the code form) may be sat by visitors with no account from `/placement` behind a session token (`startPlacement` / `submitPlacementPart` / `resolvePlacementResult`, key hash on the attempt, no review ever); they get a 6-character result code for the register form. Rooms: `settings/rooms`; teacher levels: `users.levels` (admin only). Pure logic in `functions/placement.js`.
- **Progress report (Build 4, 2026-11-20):** `progress_summary/{uid}` is written only by functions (`refreshProgressSummary`; pure logic and the five warnings in `functions/progress.js`), refreshed by triggers on exercise results, attendance, vouchers, `progress_notes` and test results, and by the daily 07:00 job, which also sends warning notices (kind `progress`) at most once per 7 days per student and warning. Practice = every final package result; attendance % = hadir ÷ (hadir + alpa). One report widget (`StudentProgressReport`, `fl_chart`) serves the student Progress tab, the parent's first tab and `/teacher/student/:id/progress`, `/admin/users/:id/progress`; Print report uses the same summary. Teachers write follow-up notes for their own students. After a deploy that changes the summary, press **Rebuild progress summaries** (Org settings).
- **Vouchers in the app (Build 5, 2026-11-20):** students and linked parents buy session packages from the Price list (`nameChinese`, `validDays`, `active`) through `createInvoice` (terms ticked, one open purchase reused); a paid invoice becomes a term with its validity and a `voucher_history` entry; `expireVouchers` (00:30 Jakarta) forfeits what is left after the deadline. Pure logic in `functions/payments.js`. On the emulator, `functions/.secret.local` (`MIDTRANS_SERVER_KEY=emulator-only-midtrans-key`) and `functions/.env.local` (`MIDTRANS_SNAP_URL_EMULATOR=http://127.0.0.1:5199/snap`) are needed by the flow test; both are git-ignored and must never be committed.
- **Timetable and booking (Build 6, 2026-11-21):** `schedules` are written only by `saveSchedule` (admin; conflict check in `functions/scheduling.js` inside a transaction with `schedule_locks`); `generateSessions` creates `class_sessions/{scheduleId_yyyyMMdd}` 14 days ahead (`generated: true`); students and linked parents book through `bookSession` / `cancelBooking` (a voucher session is reserved in `sessionsBooked`); students no longer write `attendance` themselves. A voucher's `classDay` books its student each week.
- **Teaching day (Build 7, 2026-11-21):** a session's life (`status` scheduled / ongoing / done / cancelled / needs_teacher, check-in, flags, `teacherId`) is written only by functions. `closeSession` is the only way a voucher session is used: one transaction, ledger doc `voucher_history/{sessionId}_{studentId}`, `teacher_recaps/{teacherId}_{yyyyMM}`; a second call changes nothing. Teachers run the day from `/teacher/schedule`; admins use Timetable → Follow-up / Teacher recap and Org settings → Voucher check (`reconcileVouchers`).
- **Dashboard, report, trial kit (Build 8, 2026-11-21):** the admin dashboard opens with six duty cards; `reports/{yyyyMM}` is written by `monthlyReport` / `rebuildMonthlyReport` only. The trial kit is `docs/TRIAL_KIT.md` (seed, 731-question checklist, task sheets, SUS, screenshots). Emulator bundles accept `?as=<email>` (sign-in with the emulator password) and `?tab=N`; never in live builds. Trial passwords and respondent names live in git-ignored `scripts/trial/*.local.*`.
- **Dark mode (2026-11-10):** `AppColors.*` are getters over the palette that is on (`AppPalette.light` / `.dark` in `lib/core/theme/app_theme.dart`, switched by `ThemeController`). Never write `const` in front of a widget or style that uses an `AppColors` value (the analyzer will refuse). A new colour goes into **both** palettes. The landing page keeps its own light `LandingBrand` tokens.

## Never
- Create a new GitHub repo or Firebase project, or re-run `flutterfire configure`.
  `lib/firebase_options.dart` already points at the live `chinese-tracker` project.
- Commit the Midtrans **server** key. It lives in Firebase Secret Manager as `MIDTRANS_SERVER_KEY`.
- Switch Midtrans to production keys before the sandbox payment E2E test passes.
- Rewrite old commits (the first commit's author name is wrong, and that's accepted).
- Sign in to the live site with a password yourself; the owner signs in. Local emulator accounts are fine.

## Conventions
- **Commit author:** `GIT_AUTHOR_NAME="Wilsin Kuonadi" GIT_AUTHOR_EMAIL=wilsinkarimunwkk@gmail.com`
  (and matching `GIT_COMMITTER_*`) per commit. Don't change global git config.
- **Push notes:** each commit body has a 2–6 bullet plain-language summary. For milestones and deploys, also `gh release create vX.Y.Z` with the same summary (latest: v0.1.26).
- **Change log:** after any code, rules, functions or config change, add an entry at the **top** of `docs/CHANGELOG.md` (What changed / Why / For review).
- **Session log:** when a session ships something, add a dated entry at the top of `docs/SESSION_LOG.md`. Update `docs/THESIS_FEATURE_AUDIT.md` status when a spec item is finished.
- **Scoped invariants:** `.claude/rules/*.md` (auth and link codes, exercise authoring admin/web-only, worksheet import web-only). Read the matching file before editing those areas.
- **Auto deploy (owner decision 2026-11-11):** after a change is committed and pushed, run `scripts/deploy_web.sh --web-only` without asking and report the result. The owner tests on the live site afterwards. Still ask before anything hard to undo on live data (rules, functions, deletes).
- There is **no staging**: a local `flutter run` talks to the live database. Use the emulator (below) for anything that writes test data.
- **Two chats (owner decision 2026-11-16):** planning in a Fable session titled "Easy Study · PLAN" (edits docs only, commits at once), building in an Opus session on the PC titled "Easy Study · BUILD (Opus)" (the only chat that edits code; builds the §4 item marked NEXT in `docs/PLAN.md`, writes its report in §6). Both `git pull --rebase` before editing. The chats message each other with `ListAgents` / `SendMessage` (the PC session has Remote Control on; proven both ways 2026-11-16). The approved Tugas Akhir proposal (summarised in `docs/THESIS_FEATURE_BACKLOG.md`, facts in `docs/PLAN.md` §7) is the contract; seminar registration opens 2027-02-22.

## Commands
```bash
flutter pub get
flutter run -d chrome                 # no CONTENT_OWNER_ID needed locally; talks to LIVE Firebase
flutter analyze                       # baseline: 0 errors, 0 warnings, 17 infos
flutter test                          # 152 pass + 2 measuring tests skipped (2026-11-21, Build 8)
node --check functions/index.js
node functions/test_exercise_play.js && node functions/test_reminders.js
node functions/test_supervised_test.js          # Build 1 pure logic (TS-01, PN-05)
node functions/test_typing_matcher.js           # Build 2A matcher (PN-02, PN-03)
node functions/test_marking.js                  # Build 2A queue + rubric
node functions/test_promotion.js                # Build 2B board order + promotion (LV-01, LV-03, LB-01)
node functions/test_placement.js                # Build 3 recommendation rule, result codes, visitor key
node functions/test_progress.js                 # Build 4 summary, weeks, the five warnings, notices
node functions/test_payments.js                 # Build 5 Midtrans MT-01..04, deadlines, expiry
node functions/test_scheduling.js               # Build 6 clashes, availability, generation, booking (VC-04)
node functions/test_teaching_day.js             # Build 7 close arithmetic, idempotency, late, reminders, recap
node tool/reconcile_vouchers.mjs                # Build 7 VC-05 on the emulator (--live with an admin ID token)
node functions/test_reports.js                  # Build 8 monthly report
node tool/test_sus_score.mjs && node tool/test_import_questions.mjs   # Build 8 SUS scoring, question import
# Build 8 trial kit: py -I scripts/seed_trial.py emulator|live|verify; node scripts/import_questions.mjs <csv> --dry-run;
# node tool/trial_kit/build_kit.mjs (731-row checklist, black-box tables); node tool/screenshots/run.mjs (emulator bundle on :5181)
# GitHub: .github/workflows/checks.yml runs analyze, flutter test, node tests and rules tests on every push
node functions/pn01_agreement.js functions/fixtures/pn01_sample.csv   # PN-01: 6 of 6

# Firestore rules tests (needs Java 21: brew install openjdk@21)
export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"
npm --prefix rules-tests run test:emulator      # 81 pass, 1 skipped (Firestore + Storage)

# Full emulator suite (auth 9099, firestore 8080, functions 5001, storage 9199,
# pubsub 8085 for the hourly job, UI 4000).
# The app and the seed use project id chinese-tracker (callables are routed by it).
# Emulator accounts use the password `emulator-only-7` (never the live one).
firebase emulators:start --project chinese-tracker
python3 -I scripts/seed_emulator.py            # ~5 s; codes H3DEMO1, H3ESSAY, H1PLACE (placement); package pkg_typing; pending1@ / pending2@
node functions/test_supervised_flow.mjs        # end-to-end on the emulators, 91 steps (~12 min)
                                               # (TS-01, TS-02, PN-02..05, LV-01..03, LB-01, PL-01, PL-02, visitor path, progress, MT-01..04;
                                               # needs functions/.secret.local + .env.local, see Build 5)
# Run the hourly job by hand on the emulator:
# curl -X POST http://127.0.0.1:5001/chinese-tracker/us-central1/closeForgottenTestSessions-0
# Web app against the emulators: ALWAYS this script (builds to build/web-emulator,
# serves on :5181). Never serve build/web for emulator work: deploy_web.sh rebuilds
# build/web with the LIVE config, and a dev server pointing there silently switches
# to the live database (happened 2026-11-09). A local bundle on live shows a
# "LIVE DATA" ribbon; the emulator bundle shows "EMULATOR".
scripts/run_emulator_web.sh

# Paper reader (Build 1C): PaddleOCR files into web/ocr/ (not in git, ~31 MB,
# pinned + SHA-256; deploy_web.sh and run_emulator_web.sh run it first).
node scripts/fetch_paper_ocr.mjs
# Measure the reader: read a PDF with one engine in headless Chrome, then compare
# with a truth file (practice paper H399001P is committed with its truth).
node tool/paper_measure/run.mjs test/fixtures/practice_paper/H399001P.pdf paddle out.json
PAPER_TEXTS=out.json PAPER_TRUTH=test/fixtures/practice_paper/H399001P.truth.json   flutter test test/paper_measure_test.dart      # paddle: 79 of 80 right as read
node tool/practice_paper/build.mjs               # rebuild the practice paper + truth

# Hosting deploy: ALWAYS via the script. It builds web with the live config,
# copies the Android APK to /downloads/easy-study.apk (hosting deploys are
# full snapshots, a bare deploy would drop the APK) and deploys.
scripts/deploy_web.sh --web-only # until billing is enabled (free plan refuses .apk uploads)
scripts/deploy_web.sh            # web + APK, reuse last APK build (needs Blaze)
scripts/deploy_web.sh --apk      # rebuild the APK too (~6 min, needs JDK 21)
```
**PC note (Windows 11, BUILD chat, checked 2026-11-16).** Repo at
`D:\Wilsin Private Stuff\S1 Informatika Professional ISTTS\11. Semester 8 ()(OFFLINE)\TA\PROJECT EASY STUDY`.
Shell: Git Bash for the `.sh` scripts. Flutter 3.44.9 lives in
`C:\Users\Wilsin Karimun\flutter_windows_3.16.9-stable\flutter` (the folder name is old).
- `flutter test` fails through that path ("'C:\Users\Wilsin' is not recognized", native-assets
  hook of `objective_c`): the space in the user folder breaks the hook. Run it through the
  8.3 short path instead: `C:\Users\WILSIN~1\FLUTTE~1.9-S\flutter\bin\flutter.bat test`.
- Python: use `py -I scripts/seed_emulator.py` (`python3` is only the Microsoft Store stub).
- Java: JDK 23 at `C:\Program Files\Java\jdk-23` (the Mac uses 21). The emulators crash
  ("Unable to establish loopback connection") unless the JDK gets a short socket folder:
  `export JAVA_TOOL_OPTIONS="-Djdk.net.unixdomain.tmpdir=C:\\Users\\Public\\jtmp"` (folder exists).
- Node 22 at `C:\Program Files\nodejs`, firebase-tools in `%APPDATA%\npm`; Git Bash may need
  `export PATH="/c/Program Files/nodejs:/c/Users/Wilsin Karimun/AppData/Roaming/npm:$PATH"`.
- `scripts/run_emulator_web.sh` calls `flutter`; in Git Bash define it first:
  `flutter() { cmd //c 'C:\Users\WILSIN~1\FLUTTE~1.9-S\flutter\bin\flutter.bat' "$@"; }; export -f flutter`.
- `deploy_web.sh` refuses to deploy when `APP_CHECK_SITE_KEY` is empty; `--no-keys` overrides.
- Windows desktop builds need Developer Mode (symlinks); web and tests do not.
- **Emulator bundle and live Auth (found 2026-11-16):** reloading the emulator web app while
  signed in started Firebase Auth before `useAuthEmulator`, so Auth silently stayed on the
  LIVE project (a saved-account sign-in then reached live Auth; Firestore stayed on the
  emulator). `lib/core/utils/emulator_guard*.dart` now checks this at start-up: it signs out
  locally and reloads once, or refuses to start. In the emulator you sign in again after a
  reload.

Android: `flutter config --jdk-dir=/opt/homebrew/opt/openjdk@21` is set on this Mac; the
release keystore is referenced by `android/key.properties` (never commit the keystore).
iOS: no native app; Xcode is incomplete on this Mac and there is no Apple Developer
account on record. Users add the web app to the home screen from Safari.

## Known blockers (update when resolved)
- Cloud Functions run on **Node 22** since 2026-11-05 (Node 20 was retired 2026-10-30); `functions/package.json` engines = 22, firebase-functions 7, firebase-admin 14.
- Billing was off 2026-10-13 → 2026-10-20. Owner upgraded to **Blaze on 2026-10-20**; all 9 functions and the APK were redeployed and work (owner re-test PUB-09 passed).
- **Nightly backup: resolved 2026-11-13.** The owner created a Firestore scheduled backup (daily, 7-day retention, `firebase firestore:backups:schedules:create`, schedule id `c3d18000-…`). The failing `scheduledFirestoreExport` function was removed from the code and deleted on live the same day (15 functions remained; Build 1 added 7 test callables, **22 on live since its deploy on 2026-11-16**; Build 2A added `markAnswer`, `resetTestAttempt` and the hourly `closeForgottenTestSessions`: **25 on live since 2026-11-17**; Build 2B added `onTestResultWritten` and `decidePromotion`: 27; Build 3 added 7 (`decideRegistration`, `registrationPlacement` and five public placement callables): 34; Build 4 added 5 (four summary triggers and `rebuildProgressSummaries`): 39; Build 5 added `expireVouchers`: 40; Build 6 added 5 (timetable and booking): 45; Build 7 added 13 (teaching day): 58; Build 8 added 2 (monthly report): **60 on live since 2026-11-21**; the PC is signed in to the Firebase CLI since that day, the CLI sits at `%LOCALAPPDATA%\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Roaming\npm\firebase.cmd` for a normal terminal). List / restore commands: `docs/OWNER_PROCEDURES.md` §B. The NAS pull in `docs/NAS_BACKUP_SETUP.md` no longer receives Firestore exports.
- Test accounts on the live project: `admin@`, `teacher@`, `student1-3@test.chinesetracker`, password in `docs/CLAUDE_FULL_HANDOFF.md`. No test parent yet.

## Tools on the owner's Mac
- **Caveman** (`@caveman-ai/cli`, getcaveman.dev) is enabled for Claude Code since 2026-10-22: traffic goes through a local proxy (`ANTHROPIC_BASE_URL=http://127.0.0.1:8787/w/claude` in `~/.claude/settings.json`), plus hooks that add context notes to prompts. If Claude can't connect, the proxy isn't running: run `caveman status`, or undo with `caveman disable claude`.
- **Owner test checklist:** https://claude.ai/artifact/7U7WnXt1rKRArcDDvoiBEb (results in its db collection `results`, read with the Artifact tool `read_db`). PUB-01…09 checked; PUB-05 (Android) needs a re-test since the APK went live.
