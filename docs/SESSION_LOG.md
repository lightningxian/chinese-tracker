# Session log — Mac ↔ PC

**Read this first** when starting a session on another machine. Cursor was retired on
2026-10-18; the owner works only with Claude Code now.
Chat history does **not** sync between Mac and PC. This file + git history do.

**Full Claude ownership handoff (preferred for Claude):**  
`docs/CLAUDE_FULL_HANDOFF.md`

Repo: https://github.com/lightningxian/chinese-tracker (private)  
Live site: https://chinese-tracker.web.app  
Owner GitHub: `lightningxian` · Author for commits: `Wilsin Kuonadi <wilsinkarimunwkk@gmail.com>`

---

## How to start on this PC

```bash
git pull
```

Then tell Cursor:

> Read `docs/SESSION_LOG.md` and `docs/BACKLOG.md`. I want to work on: **\<your task\>**.

Before you finish a session: commit, push, and **update this handoff** (What changed / What’s next).

---

## Product (one paragraph)

**Easy Study / 易华文教中心** — Flutter + Firebase LMS for a Chinese teaching centre.  
Roles: **admin**, **teacher**, **student**, **parent**.  
Stack: Flutter web (primary), Firestore, Cloud Functions (v2), Midtrans sandbox payments, Firebase Hosting.

---

## Already done — do not redo

| Area | Status |
|------|--------|
| Full app (4 roles) | Live |
| Firebase functions (9), Firestore + storage rules | Deployed |
| Midtrans server + client wiring (sandbox) | Deployed — **payment E2E test not run** |
| Question bank upgrade (difficulty, bulk import, harvest, media, quiz editor) | Done |
| Landing page restyle | Done + hosted |
| Startup crash (`fontSizeFactor` assertion) | Fixed via `TextScaler.linear(1.12)` in `lib/app.dart` |
| Git history + private remote | Done (`main`) |
| Initial GitHub release notes | `v0.1.0-initial` |
| Push-notes Cursor rule | `CLAUDE.md` |

Detailed change log (newest first): `docs/CHANGELOG.md`  
Priority backlog Claude maintains: `docs/BACKLOG.md`

---

## Priority backlog (do top-down unless user overrides)

1. **Midtrans sandbox payment test** (highest)  
   Invoice → pay sandbox → status paid → sessions credited → replay webhook → **no double-credit**.

2. **Security hardening**  
   - Student registration / link-code: move validation server-side (like parent `linkChild`)  
   - Storage `materials/{ownerId}` writes: uid-scope (`auth.uid == ownerId \|\| isAdmin()`)  
   - Enforce display-only settings: `requireEmailVerification`, `autoGenerateStaffPasswords`  
   - Consolidate `contentTeacherId` vs `contentOwnerFor`

3. **Tests + CI**  
   - Firestore rules unit tests  
   - Midtrans webhook unit test  
   - GitHub Action: `flutter analyze` + `flutter test` + `node --check`

4. **Later / optional**  
   - Student quiz UI: render per-question image/audio  
   - Narrow-width (~360px) overflow pass after text scale  
   - NAS backup scripts (on hold; git + Firestore export cover a lot)  
   - Multi-teacher scoping of published materials (fine for one centre)

---

## Key config (production / hosting builds)

```text
CONTENT_OWNER_ID=2orTXFeyAhSlxfTgIlcYgs6ZuCG2
MIDTRANS_CLIENT_KEY=Mid-client-kQ_Bo0DQepeH8IhU
```

- Content owner uid = “Test Teacher” in production Firestore  
- Midtrans is **sandbox** (client key has no `SB-` prefix; that is normal for this account)  
- Webhook: `https://us-central1-chinese-tracker.cloudfunctions.net/midtransNotification`  
- Demo teacher content is per-teacher (`AppConstants.contentOwnerFor`) — do **not** require `CONTENT_OWNER_ID` for normal local runs  

Test login (if still seeded): `admin@test.chinesetracker` / `testpass123`

### Local run

```bash
flutter pub get
flutter run -d chrome
```

Rebuild + hosting (only when shipping UI/backend to live):

```bash
flutter build web --release \
  --dart-define=CONTENT_OWNER_ID=2orTXFeyAhSlxfTgIlcYgs6ZuCG2 \
  --dart-define=MIDTRANS_CLIENT_KEY=Mid-client-kQ_Bo0DQepeH8IhU
firebase deploy --only hosting
```

After code changes, relaunch locally per `CLAUDE.md`.

---

## Project rules Cursor must follow

| Rule | Path |
|------|------|
| Log every change for Claude | `CLAUDE.md` → `docs/CHANGELOG.md` |
| Relaunch app after code changes | `CLAUDE.md` |
| Push notes (overall summary on commit/push) | `CLAUDE.md` |
| Auth / link codes | `.claude/rules/auth-and-link-codes.md` |
| Exercise authoring web-only | `.claude/rules/exercise-authoring-web-only.md` |
| Worksheet import web-only | `.claude/rules/worksheet-import-web-only.md` |

Commit author preference (via env vars, not global git config):  
`Wilsin Kuonadi <wilsinkarimunwkk@gmail.com>`

---

## Useful paths

| What | Where |
|------|--------|
| App entry | `lib/main.dart`, `lib/app.dart` |
| Theme / text scale | `lib/core/theme/app_theme.dart`, `lib/app.dart` |
| Landing | `lib/features/landing/` |
| Question bank | `lib/features/question_bank/` |
| Payments (client) | `lib/services/payment_service.dart` |
| Cloud Functions | `functions/index.js` |
| Firestore rules | `firestore.rules` |
| Storage rules | `storage.rules` |
| Go-live runbook | `docs/GO_LIVE_CHECKLIST.md` |

---

## Session log (newest first)

Update this section when you push from Mac or PC.

### 2026-11-10 (later) — Claude: Appearance menu, text size, Type of exercise, exercises table

- Appearance (theme + text size slider) in the top bar next to the bell.
- Bank: Type of exercise column/filter (Exercise, Quiz, Exam, HSK
  Simulation), Edit/Delete buttons per row, Tags column removed.
- Exercises tab is a table; Quizzes and Levels buttons removed.
- Owner deployed hosting the same day. Release v0.1.9.

### 2026-11-10 — Claude: dark mode, worksheet editor, empty-tab button

- Dark mode: two palettes behind the same `AppColors` names, Light / Dark /
  Device toggle on every profile page, default follows the device.
- Question bank worksheet page: Edit worksheet (title, type, level, skill),
  Add question, move up/down, per-type question editor; matching questions
  keep their word bank.
- Exercises tab shows New exercise when the list is empty.
- Verified on the emulator (admin + student, light and dark). Owner to
  deploy hosting: `scripts/deploy_web.sh --web-only`.

### 2026-11-09 (night) — Claude: packages from the bank, server scoring, ID/EN, delete account

- Exercises are now packages of bank worksheets; students only see assigned
  ones; packages are played through Cloud Functions so answer keys stay on
  the server. Assign dialog, worksheet rename/assign, admin Delete account.
- Indonesian/English switch for auth, student and parent screens.
- Admin flow verified on the emulator; student play of a package and the
  language toggle then checked on the emulator. Owner deployed functions
  and hosting the same evening. Release v0.1.8.

### 2026-11-09 (later) — Claude: bank by worksheet, Kai font, tables, no difficulty

- Question bank shows one row per worksheet; open it for the questions.
  Scan of a sheet already in the bank offers Replace / Keep both. Exercise
  form picker adds a whole worksheet in one tick.
- Chinese text in Kai style (LXGW WenKai, bundled subset); question text
  bigger everywhere; admin tables have column lines and darker row lines;
  difficulty removed from the bank.
- Verified on the emulator (screenshots sent). Owner deployed hosting the
  same day; live bundle checked.

### 2026-11-09 — Claude: import dialog fix, timer, answer keys for known sheets

- Owner: scan "feels stuck". Cause found: from the question bank (and quiz
  editor) the progress dialog was never closed (nested vs root navigator),
  so it sat at 88 % for ever with the review hidden behind it. Fixed.
- Dialog shows elapsed time, a time-left estimate and what is happening
  (page n of m, OCR phase). Tesseract worker reused across pages/scans.
- Scans of the centre's own sheets (code in the bundled sample set) get
  their answers filled in automatically; the review says how many.
- Verified on the emulator with the owner's two PDFs (310001-RDG → 7 MC
  with correct answers; 300001-KLM → 10 compose in correct order).
- Owner deployed hosting the same day (`scripts/deploy_web.sh --web-only`,
  51 files, release complete). Release v0.1.7.

### 2026-11-05 (later) — Claude: bank in sidebar, scan-first exercises, sample set

- Question bank sidebar entry; Scan worksheet opens the pre-filled exercise
  form; the ten sample sheets ship as a question set the bank loads in one
  click (96 keyed questions). Needs a hosting deploy.

### 2026-11-05 — owner deploys

- Functions redeployed on Node 22 (all 10). Hosting deployed on the second
  try (first upload hit a network error). Live bundle checked: scanner,
  new exercise types, price list and mark-as-paid present. Release v0.1.6.

### 2026-10-29 — Claude: upload-only exercise form, easystudy.web.app, sample worksheets

- Exercise form has no manual question entry (scanner or bank only).
- Address stays https://chinese-tracker.web.app (owner decided against
  easystudy.web.app after it was prepared; the hosting change was reverted).
- Owner's 10 sample worksheets analysed and the scanner now reads all ten
  (pinyin stripping, ★ true/false, inline options, exam passages, several
  word lists, type-the-hanzi and picture-sentence types). Results per sheet
  in `docs/WORKSHEET_FORMS.md`; fixture tests in
  `test/worksheet_fixtures_test.dart`.

### 2026-10-27 (evening) — Claude: owner's second review

- Question bank is scanner-first (Scan worksheet → check list → add); quiz
  editor can scan a worksheet too; Reports tab tidied into sections with
  uniform tiles. Details in CHANGELOG.
- Payments ↔ vouchers linked (owner's answers: admin records cash/transfer;
  teachers may add a term but a pending invoice is created for the admin;
  old vouchers without payment are flagged on the dashboard). New Price list
  tab (`settings/pricing.items`). New callable `markInvoicePaid`. Details in
  CHANGELOG. Needs functions + rules + hosting deploy.

### 2026-10-27 (later) — Claude: calendar, Levels, 8 reports

- Classes tab is now a month/week calendar (teacher + admin); Active/History
  lists removed; New class from a day.
- **Levels**: bundles of exercises assigned to a group of students
  (`exercise_levels` → materialised `exercise_assignments` with `levelId`).
  Exercises → Levels for all staff.
- Admin → Reports: 8 operational reports with PDF export (attendance per
  student, term alerts, revenue, retention, fill rate, teacher recap, progress
  per HSK level, overdue homework) + the old 4 below. Unit tests for the maths.
- Sign-in race guard (`isProfileLoading`) so a valid account is not bounced to
  `/complete-profile` mid sign-in.
- Verified on the emulator (release build): calendar, Levels create + assignment
  docs, Reports tab. **Deployed by the owner the same day** (rules + hosting,
  release v0.1.5 at commit 75cc6e1); live bundle checked for the new screens.
- Worksheet scanner detects the form (R1 fill in the blank, R2 matching,
  R3 comprehension + passage, R4 order sentences, true/false, L3 listening);
  fill in the blank is editable and playable; reading passage field added.
  All five owner items from the admin review are now built; owner tests on
  the live site after deploy.

### 2026-10-27 — Claude: admin review fixes

- Owner's `review_web.pdf` (5 admin items) done and deployed: children search
  in Create user, admin term editing on Edit user, Vouchers explanation, HSK
  book invoice item, Hadir/Izin/Alpa attendance on Conclude class (Izin not
  charged). Details in CHANGELOG. Caveman mode on in this chat at owner's request.

### 2026-10-22 — Claude: handoff to a new chat (end of the first Claude session)

Where things stand, so the next session can start without this chat:
- **Live:** landing page (direction A, WhatsApp-first, prices from the flyer),
  brand design system inside the app, Students table, simplified class form,
  Android APK at `/downloads/easy-study.apk`, all 9 Cloud Functions (Blaze
  since 2026-10-20). Latest release notes: v0.1.4.
- **Owner checklist:** PUB-01…09 pass except PUB-05 (Android, re-test now the
  APK is live). Remaining sections (AUTH, ADM, TCH, STU, PAR, PAY, SYS, DEV)
  not started.
- **Open problems:** nightly backup PERMISSION_DENIED (IAM fix in CLAUDE.md
  "Known blockers"); functions still charge old prices Rp 800k / 1.5M vs flyer
  Rp 2.45M / 3.95M (fix in thesis Phase 4); no native iOS app (needs Apple
  Developer account, owner deciding).
- **Next planned work:** thesis Phase 1 (registration approval with starting
  level, rooms list, settings docs, teacher teachable levels, FCM tokens,
  Indonesian + English text), per `docs/THESIS_FEATURE_AUDIT.md`. Waiting on
  the owner's sample simulation paper (audio + answer key) for Phase 5.
- Owner enabled Caveman for Claude Code on this Mac (see CLAUDE.md "Tools").

### 2026-10-18 (later) — Claude: design system + emulator mode

- Signed-in app restyled through the theme ("A, calmer": teal/green/yellow on
  warm white, Lexend). Emulator mode (`USE_EMULATORS`) + `scripts/seed_emulator.py`
  so Claude can sign in locally with demo accounts. Cursor retired; docs renamed
  (CHANGELOG, SESSION_LOG, BACKLOG). Thesis spec v2 compared in
  `THESIS_FEATURE_AUDIT.md` §0; owner answered the open questions there.
- Next: screen-by-screen polish on the new theme, then thesis Phase 1.

### 2026-10-18 — Claude: landing page rebuilt (direction A)

- New landing page in the logo's yellow/teal/green with the pencil mascot,
  HSK ruler and an About section (HSK standard, past exam questions, classes
  at the centre). Deployed to hosting. Next: design system for the signed-in
  app ("A, calmer"), then thesis Phase 1. Billing still needs re-enabling
  before functions can deploy.

### 2026-10-17 — Claude: security fixes + emulator; billing problem found

- Closed teacher self-registration, enforced deactivation, teacher-only link
  codes, fixed the notifications query. Rules + hosting deployed; **functions
  deploy blocked: Firebase project billing is disabled** (Secret Manager 403).
  Re-enable billing, then `firebase deploy --only functions`.
- Firebase emulators configured; `rules-tests/` added (18 pass, 1 skipped).
- Thesis spec saved to `docs/THESIS_FEATURE_BACKLOG.md`; audit in
  `docs/THESIS_FEATURE_AUDIT.md`. Decisions: keep parent/materials; Indonesian
  + English switch later; next = design system (direction A, calmer inside),
  then Phase 1.

### 2026-10-16 — Claude: first fixes shipped + redesign started

- Added `CLAUDE.md` (project guide Claude reads every session) and a local
  preview config in `.claude/launch.json`.
- Web now uses clean addresses (`/login`, not `/#/login`); deep links and
  refreshes keep their page. "Forgot password?" added to sign-in. Three dead
  landing photos replaced; dead YouTube video swapped for a photo until the
  centre supplies its own video. Deployed to hosting.
- Full manual test checklist published (claude.ai artifact, owner-only) and
  three landing page design directions built from the real logo/mascot.
  User approved the landing direction and asked for a redesign of all pages.

### 2026-10-16 — Full handoff to Claude

- Added `docs/CLAUDE_FULL_HANDOFF.md` (GitHub location, done/backlog, config,
  architecture, risks). User continues all further work with Claude.
- No feature code changes in this session.

### 2026-08-10 — Handoff doc for PC Cursor

- Added this file so PC sessions can see Mac work without chat history.
- User will run **different tasks** on PC; do not assume Midtrans is next unless they ask.
- Repo was already private on GitHub; pull before starting.

### 2026-08-05 — Git + GitHub baseline

- First commit + private remote `lightningxian/chinese-tracker`
- Release `v0.1.0-initial` summarizing the full snapshot
- Push-notes rule added

### 2026-07-22 — Feature / deploy wave (summary)

- Question bank upgrade (4 phases)
- Landing restyle + hosting redeploy + cache headers
- Font crash fix (`TextScaler` instead of `fontSizeFactor`)
- Functions / storage / hosting deployed; Midtrans sandbox E2E still deferred

---

## For the agent on PC

1. **Do not** recreate Firebase, re-run `flutterfire configure`, or invent a new repo.  
2. **Do not** assume you must continue the Mac backlog — the user may assign a new task. Still skim this file so you don’t undo finished work.  
3. After any code/config change: update `docs/CHANGELOG.md`, update **Session log** above, commit with an overall push note, and `git push`.  
4. If the user asks “what’s next?”, point at **Priority backlog** above / `docs/BACKLOG.md`.
