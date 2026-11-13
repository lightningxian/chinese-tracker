# Easy Study (`chinese-tracker`) — Claude project guide

Flutter web + Firebase LMS for a Chinese teaching centre (易华文教中心).
Roles: admin · teacher · student · parent. Live at https://chinese-tracker.web.app.
The owner (Wilsin, a Flutter/Firebase beginner) works **only with Claude Code**, on a Mac
and a PC. Chat does not sync between machines: the docs in this repo are the shared memory,
so keep them current. Explain steps in simple English and ask before big or hard-to-undo
decisions. This app is also the owner's thesis project (see the thesis docs below).

## Read first
1. `docs/CLAUDE_FULL_HANDOFF.md`: live config, what's built, architecture map.
2. `docs/THESIS_FEATURE_AUDIT.md`: the thesis spec (`docs/THESIS_FEATURE_BACKLOG.md`, v2) compared with the code, open questions, suggested order. `docs/THESIS_PROPOSAL_ASSETS.md` lists the screenshots the proposal needs.
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
- **Exercises = packages from the question bank (2026-11-09):** an exercise lists bank worksheets (`bankSheets`) and single questions (`bankQuestionIds`); students see only exercises assigned to them; packages are played through the `startExercise` / `checkExerciseAnswer` / `finishExercise` functions so answer keys never reach the client. Levels stay (they assign several exercises at once). **Teachers build packages too (2026-11-13):** a teacher creates, edits, publishes and deletes their own packages (`teacherId` = their uid) and assigns them; admins manage every exercise. The question bank (scan, paste, edit) and the old-format editor stay admin-only. See `.claude/rules/exercise-authoring-web-only.md`.
- **UI language (2026-11-12):** every screen reads `context.l10n` (`lib/l10n/app_en.arb` template + `app_id.arb`, ~1,380 keys). Model enums keep their English `label` (sorting, CSV fixtures, logs); the UI shows them through the `localized(l)` extensions in `lib/l10n/labels_*.dart`. `LocaleController` also sets `Intl.defaultLocale`, so `DateFormat` follows the switch. Still English on purpose: the legacy exercise editor, quiz and level screens (unused), service error messages, PDF/CSV exports built in `lib/services`, OCR progress details.
- **Quizzes and Levels (2026-11-10):** owner does not need them. Buttons removed from the Exercises tab; routes/screens still exist. The bank carries a **Type of exercise** per worksheet instead (`ExerciseCategory`: Exercise · Quiz · Exam · HSK Simulation).
- **Exercise play (2026-11-11):** students answer every question first and submit once; `finishExercise` checks the whole attempt and returns the review. No per-answer function calls. A package may carry `timeLimitMinutes` (counts down, auto-submits).
- **Parents (2026-11-11):** the parent is an optional add-on account linked by the child code. Invoices stay on the student; both the student and the linked parent see them and may pay. `linkChild` stamps `linkedParentUid`/`linkedParentName` on the student so the student's Payments tab can say who handles payments. Admin Users is split by role with chips.
- **Exam mode (2026-11-13):** a package whose first worksheet is Exam or HSK Simulation is one attempt with a server clock (`exercise_attempts`, `startExercise` `peek` → start screen → `finishExercise` closes it; late = 0). Practice packages stay unlimited. `resolveLinkCode` / `resolveChildCode` are rate-limited per address.
- **Scores (2026-11-12):** `exercise_results` is written only by `finishExercise`; the rules have no client write. Old-format exercises (questions inside the doc) cannot be played; the admin deletes them. Bank questions may carry an `explanation`, sent only with the review.
- **HSK simulation (2026-11-13):** a paper is scanned with **Scan paper with AI** (Gemini `gemini-3.8-flash` via Firebase AI Logic, `lib/services/worksheet_ai_import_service.dart`; needs the console setup in `docs/WORKSHEET_IMPORT.md`), reviewed, and saved as one worksheet with part headings (`section`), a picture per choice (`optionImageUrls`) and, later, one listening recording for the sheet (`sectionAudioUrl`, uploaded on the worksheet screen). Keys the reader cannot know (listening) are typed with the worksheet's **Answer key** dialog. The player shows the part, the recording, picture choices, and HSK marks per part (listening / reading / writing out of 100, pass at 60%). The on-device scanner stays as **Scan without AI**. App Check is activated when `APP_CHECK_SITE_KEY` is set (`deploy.env`), enforcement only for AI Logic.
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
- **Push notes:** each commit body has a 2–6 bullet plain-language summary. For milestones and deploys, also `gh release create vX.Y.Z` with the same summary (latest: v0.1.15).
- **Change log:** after any code, rules, functions or config change, add an entry at the **top** of `docs/CHANGELOG.md` (What changed / Why / For review).
- **Session log:** when a session ships something, add a dated entry at the top of `docs/SESSION_LOG.md`. Update `docs/THESIS_FEATURE_AUDIT.md` status when a spec item is finished.
- **Scoped invariants:** `.claude/rules/*.md` (auth and link codes, exercise authoring admin/web-only, worksheet import web-only). Read the matching file before editing those areas.
- **Auto deploy (owner decision 2026-11-11):** after a change is committed and pushed, run `scripts/deploy_web.sh --web-only` without asking and report the result. The owner tests on the live site afterwards. Still ask before anything hard to undo on live data (rules, functions, deletes).
- There is **no staging**: a local `flutter run` talks to the live database. Use the emulator (below) for anything that writes test data.

## Commands
```bash
flutter pub get
flutter run -d chrome                 # no CONTENT_OWNER_ID needed locally; talks to LIVE Firebase
flutter analyze                       # baseline: 0 errors, 0 warnings, ~18 infos
flutter test                          # 65 pass
node --check functions/index.js

# Firestore rules tests (needs Java 21: brew install openjdk@21)
export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"
npm --prefix rules-tests run test:emulator      # 37 pass, 1 skipped (emulator limitation)

# Full emulator suite (auth 9099, firestore 8080, functions 5001, storage 9199, UI 4000)
firebase emulators:start --project demo-chinese-tracker
# Web app against the emulators: ALWAYS this script (builds to build/web-emulator,
# serves on :5181). Never serve build/web for emulator work: deploy_web.sh rebuilds
# build/web with the LIVE config, and a dev server pointing there silently switches
# to the live database (happened 2026-11-09). A local bundle on live shows a
# "LIVE DATA" ribbon; the emulator bundle shows "EMULATOR".
scripts/run_emulator_web.sh

# Hosting deploy: ALWAYS via the script. It builds web with the live config,
# copies the Android APK to /downloads/easy-study.apk (hosting deploys are
# full snapshots, a bare deploy would drop the APK) and deploys.
scripts/deploy_web.sh --web-only # until billing is enabled (free plan refuses .apk uploads)
scripts/deploy_web.sh            # web + APK, reuse last APK build (needs Blaze)
scripts/deploy_web.sh --apk      # rebuild the APK too (~6 min, needs JDK 21)
```
Android: `flutter config --jdk-dir=/opt/homebrew/opt/openjdk@21` is set on this Mac; the
release keystore is referenced by `android/key.properties` (never commit the keystore).
iOS: no native app; Xcode is incomplete on this Mac and there is no Apple Developer
account on record. Users add the web app to the home screen from Safari.

## Known blockers (update when resolved)
- Cloud Functions run on **Node 22** since 2026-11-05 (Node 20 was retired 2026-10-30); `functions/package.json` engines = 22, firebase-functions 7, firebase-admin 14.
- Billing was off 2026-10-13 → 2026-10-20. Owner upgraded to **Blaze on 2026-10-20**; all 9 functions and the APK were redeployed and work (owner re-test PUB-09 passed).
- **Nightly backup: resolved 2026-11-13.** The owner created a Firestore scheduled backup (daily, 7-day retention, `firebase firestore:backups:schedules:create`, schedule id `c3d18000-…`). The failing `scheduledFirestoreExport` function was removed from the code the same day; the next `firebase deploy --only functions` asks to delete it on live (answer yes). List / restore commands: `docs/OWNER_PROCEDURES.md` §B. The NAS pull in `docs/NAS_BACKUP_SETUP.md` no longer receives Firestore exports.
- Test accounts on the live project: `admin@`, `teacher@`, `student1-3@test.chinesetracker`, password in `docs/CLAUDE_FULL_HANDOFF.md`. No test parent yet.

## Tools on the owner's Mac
- **Caveman** (`@caveman-ai/cli`, getcaveman.dev) is enabled for Claude Code since 2026-10-22: traffic goes through a local proxy (`ANTHROPIC_BASE_URL=http://127.0.0.1:8787/w/claude` in `~/.claude/settings.json`), plus hooks that add context notes to prompts. If Claude can't connect, the proxy isn't running: run `caveman status`, or undo with `caveman disable claude`.
- **Owner test checklist:** https://claude.ai/artifact/7U7WnXt1rKRArcDDvoiBEb (results in its db collection `results`, read with the Artifact tool `read_db`). PUB-01…09 checked; PUB-05 (Android) needs a re-test since the APK went live.
