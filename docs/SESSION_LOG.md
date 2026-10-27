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

### 2026-10-27 (evening) — Claude: owner's second review

- Question bank is scanner-first (Scan worksheet → check list → add); quiz
  editor can scan a worksheet too; Reports tab tidied into sections with
  uniform tiles. Details in CHANGELOG.
- Open decision for the owner: payments ↔ vouchers link and a Price list tab
  (asked in chat; not built yet).

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
