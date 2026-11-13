# Full handoff for Claude — Easy Study (`chinese-tracker`)

**Date:** 2026-10-16  
**From:** Cursor (Mac sessions)  
**To:** Claude — own all next work from here  
**Owner:** Wilsin Kuonadi · GitHub `lightningxian` · `wilsinkarimunwkk@gmail.com`

> **2026-10-18:** Cursor is retired. The owner works only with Claude Code (Mac and PC); `CLAUDE.md` is the entry point and this file is the detailed reference.

This is the single source of truth for continuing the project without Cursor chat history. Read this first, then `docs/BACKLOG.md` and the newest entries in `docs/CHANGELOG.md`.

**Cursor conversation history (separate MD):** `docs/archive/cursor/CURSOR_CHAT_HISTORY.md` —
timeline of what the user asked Cursor, decisions made, and what’s unfinished.

---

## 1. Where the code lives

| What | Value |
|------|--------|
| **GitHub (private)** | https://github.com/lightningxian/chinese-tracker |
| **Clone URL** | `https://github.com/lightningxian/chinese-tracker.git` |
| **Default branch** | `main` (tracks `origin/main`) |
| **Local path (Mac)** | `~/Projects/chinese-tracker` |
| **Initial release notes** | https://github.com/lightningxian/chinese-tracker/releases/tag/v0.1.0-initial |
| **Latest known commits** | `c04f806` initial · `284d871` push-notes · `64d54fa` Mac↔PC handoff |

```bash
git clone https://github.com/lightningxian/chinese-tracker.git
cd chinese-tracker
git pull
flutter pub get
```

**Do not** create a new repo, new Firebase project, or re-run `flutterfire configure`.  
`lib/firebase_options.dart` already points at the live project.

---

## 2. Live product & Firebase

| What | Value |
|------|--------|
| Product name | **Easy Study** / 易华文教中心 |
| Live site | https://chinese-tracker.web.app |
| Firebase project | `chinese-tracker` |
| Region (functions) | `us-central1` |
| Stack | Flutter web (primary) · Firestore · Cloud Functions v2 · Hosting · Storage · Midtrans sandbox |
| Roles | admin · teacher · student · parent |

### Cloud Functions (15, all deployed 2026-11-13 with the current rules; `scheduledFirestoreExport` deleted on live 2026-11-13)

| Export | Role |
|--------|------|
| `resolveLinkCode` | Callable — teacher invite code → teacherId (rate-limited per address) |
| `resolveChildCode` | Callable — child code for parents (rate-limited per address) |
| `linkChild` | Callable — parent↔child link (**server-validated** — pattern to copy for students) |
| `createInvoice` | Callable — creates invoice + Midtrans Snap token |
| `markInvoicePaid` | Callable — admin records a cash/transfer payment, credits the term |
| `midtransNotification` | HTTP webhook — payment status + session credit |
| `startExercise` | Callable — package questions without keys; `peek` for metadata; opens the one-attempt exam clock |
| `checkExerciseAnswer` | Callable — per-question check for old clients; refuses exam packages |
| `finishExercise` | Callable — scores the whole attempt, writes `exercise_results`, returns the review |
| `deleteUserAccount` | Callable — admin deletes a user and their data |
| `onUserCreated` | Trigger — welcome / setup on user doc create |
| `onExerciseResultCreated` | Trigger — notifications on exercise result |
| `cleanupExpiredLinkCodes` | Schedule — every 60 minutes (also clears old `rate_limits`) |
| `onNotificationCreated` | Trigger — pushes a notification addressed to one user to their `push_tokens` devices (added 2026-11-13) |
| `dailyReminders` | Schedule — 07:00 Jakarta, "due today" reminder per unfinished assignment (added 2026-11-13) |

**Webhook URL (registered in Midtrans):**  
`https://us-central1-chinese-tracker.cloudfunctions.net/midtransNotification`

### Build / deploy config (sandbox — current)

```text
CONTENT_OWNER_ID=2orTXFeyAhSlxfTgIlcYgs6ZuCG2
MIDTRANS_CLIENT_KEY=Mid-client-kQ_Bo0DQepeH8IhU
```

- Content owner uid = “Test Teacher” in production Firestore  
- Midtrans is **sandbox** (client key has **no** `SB-` prefix — normal for this account)  
- Server key lives in Firebase **Secret Manager** as `MIDTRANS_SERVER_KEY` (never commit)  
- Demo content is per-teacher via `AppConstants.contentOwnerFor` — **do not** require `CONTENT_OWNER_ID` for normal local `flutter run`

### Hosting rebuild

```bash
flutter build web --release \
  --dart-define=CONTENT_OWNER_ID=2orTXFeyAhSlxfTgIlcYgs6ZuCG2 \
  --dart-define=MIDTRANS_CLIENT_KEY=Mid-client-kQ_Bo0DQepeH8IhU
firebase deploy --only hosting
```

### App Check + push: what the owner sets up (added 2026-11-13)

The code is wired; both features stay off until these keys exist. Do them
once, on the Mac, in this order.

1. **App Check site key (web).** Firebase console → **Build → App Check**
   (under Security) → **Apps** tab → find the **Web** app → **Register** →
   choose **reCAPTCHA v3** → the console sends you to the reCAPTCHA admin
   page: create a key of type **v3**, domain `chinese-tracker.web.app`
   (add `localhost` too) → copy the **site key** (public, long string
   starting with `6L`) and paste it into the Firebase App Check dialog; the
   **secret key** goes into the same dialog (Firebase keeps it, never the
   app). Save.
2. **Keep App Check unenforced** for Firestore, Cloud Functions and
   Storage (App Check → **APIs** tab: leave them "Unenforced"). The Android
   APK is installed from our download link, not from Google Play, so Play
   Integrity cannot vouch for it; enforcing would lock Android users out.
   Only **Firebase AI Logic** is enforced (it requires it).
3. **Web Push key.** Firebase console → **Project settings** (gear) →
   **Cloud Messaging** tab → section **Web configuration → Web Push
   certificates** → **Generate key pair** → copy the key (starts with `B`).
4. **Put both keys on the Mac.** Create the file `deploy.env` in the repo
   root (it is git-ignored) with two lines:
   ```bash
   APP_CHECK_SITE_KEY=6L...your site key...
   FCM_VAPID_KEY=B...your web push key...
   ```
   `scripts/deploy_web.sh` reads this file on every deploy. Copy the same
   file to the PC when you deploy from there.
5. **Deploy.** `scripts/deploy_web.sh --web-only` (hosting, picks up the
   keys), then `firebase deploy --only firestore:rules,functions --project
   chinese-tracker` (the `push_tokens` rules and the two new functions
   `onNotificationCreated`, `dailyReminders`).
6. **Try it.** Sign in on the live site → Profile → **Push
   notifications** → switch on → allow in the browser prompt. Then, as a
   teacher, assign an exercise due today to that student: the 07:00
   reminder (or any grading notification) arrives as a browser
   notification. The switch is hidden until step 4 + 5 are done.
7. **Local runs with App Check on.** `APP_CHECK_DEBUG=true
   scripts/run_emulator_web.sh` → open the browser console → copy the
   printed debug token → Firebase console → App Check → Apps → Web app
   → ⋮ → **Manage debug tokens** → add it. Keep that token private.

### Test login (if still seeded)

`admin@test.chinesetracker` / `testpass123`

---

## 3. What is already done — do not redo

### Product / features
- Full LMS UI for all four roles (shells, dashboards, students, sessions, exercises, grades, materials, calendar, parent linking, payments UI)
- **Question bank upgrade (4 phases):** usage counts, sort/filter table, bulk import (worksheet + paste), harvest from exercises with dedupe, image/audio media, quiz list/editor (`/admin/quizzes`, `/teacher/quizzes`). Difficulty was removed 2026-11-09 (owner request). Since 2026-11-09 the bank is grouped by worksheet (`sheetCode`/`sheetTitle`/`sheetIndex` on each item; older items fall back to the code tag).
- **Chinese font:** LXGW WenKai (Kai style, OFL) bundled in `assets/fonts/`, subset to GB2312 + Latin/pinyin (~3.5 MB per weight); `AppTextStyles.chineseFamily`/`question` in `lib/core/theme/app_theme.dart`. Report PDFs still use Noto Sans SC.
- **Landing page restyle** matching `docs/landing_mockup.html` (Unsplash + YouTube embed, Orang Tua card)
- Worksheet import on **web only** (PDF / Word / image OCR path)
- Teacher rotating link codes; parent child-link via callables

### Backend / deploy
- Firestore rules + indexes, storage rules (incl. `question_bank_media/{ownerId}/`), all 9 functions, hosting with `no-cache` on critical Flutter assets
- Midtrans **wired** (createInvoice + notification + client Snap) — **E2E sandbox test never run**
- Payment-integrity logic exists (no double-credit intended) — **unverified manually**

### Fixes / process
- Startup crash: `fontSizeFactor: 1.12` removed from theme; ~12% scale via `TextScaler.linear(1.12)` in `lib/app.dart`
- Git history + private remote established Aug 2025–2026
- Cursor rules: log-for-Claude, relaunch-after-changes, push-notes, cross-machine-handoff, auth/link-codes, web-only authoring/import
- Docs: `SESSION_LOG.md` (Mac↔PC), `BACKLOG.md`, `GO_LIVE_CHECKLIST.md`, long change log

### Explicitly deferred / on hold
- Midtrans sandbox E2E test  
- Switch to Midtrans **production** keys (blocked until sandbox passes)  
- NAS backup GCP setup (`scripts/setup_nas_backup_gcp.sh` — needs `gcloud auth login`)  
- Student quiz UI rendering of per-question image/audio  
- Broad automated tests / CI  

---

## 4. Priority backlog (do top-down unless user overrides)

### P0 — Midtrans sandbox payment test
Manual (or Claude-guided) verification:

1. Create invoice (admin/teacher flow) → status pending  
2. Pay with Midtrans **sandbox** Snap  
3. Webhook → invoice **paid**  
4. Sessions credited once  
5. **Replay** the same notification → **no double-credit**

See also `docs/GO_LIVE_CHECKLIST.md` §4–6. Do **not** move to production Midtrans keys until this passes.

### P1 — Security hardening
From Claude’s earlier debug pass (still open):

1. **Student registration / link-code** — currently client-set `teacherId` + client-side code check. Move to a callable that validates like `linkChild`.  
2. **Storage** `materials/{ownerId}` writes — not uid-scoped; any staff can write under any owner. Tighten to `request.auth.uid == ownerId || isAdmin()`.  
3. Enforce display-only org settings: `requireEmailVerification`, `autoGenerateStaffPasswords`.  
4. Consolidate `contentTeacherId` vs `contentOwnerFor` (drift risk).  
5. Cross-owner reads of published materials / student profiles — OK for one centre; scope if multi-teacher.

### P2 — Tests + CI
- Firestore rules unit tests (`@firebase/rules-unit-testing`)  
- Webhook unit test (status mapping + idempotent credit)  
- GitHub Action: `flutter analyze` + `flutter test` + `node --check` on push  

Today’s tests are thin: constants check, PDF import probe, question import utils (~7 tests). `widget_test.dart` is not a real widget test.

### P3 — Later / polish
- Student `QuizScreen`: show question image/audio  
- ~360px overflow pass after global text scale  
- NAS backup (optional; git + scheduled Firestore export already help)  
- Multi-teacher material scoping  

---

## 5. Architecture map (where to look)

| Area | Path |
|------|------|
| App entry / text scale | `lib/main.dart`, `lib/app.dart` |
| Theme | `lib/core/theme/app_theme.dart` |
| Router | `lib/core/router/app_router.dart` |
| Constants / content owner | `lib/core/constants/app_constants.dart` |
| Auth | `lib/services/auth_service.dart` |
| Firestore | `lib/services/firestore_service.dart` |
| Payments (client) | `lib/services/payment_service.dart` |
| Question bank media | `lib/services/question_bank_media_service.dart` |
| Landing | `lib/features/landing/` |
| Question bank | `lib/features/question_bank/` |
| Quiz editor | `lib/features/teacher/quiz_editor_screen.dart` |
| Student quiz | `lib/features/student/quiz_screen.dart` |
| Cloud Functions | `functions/index.js` |
| Firestore rules | `firestore.rules` (~379 lines) |
| Storage rules | `storage.rules` |
| Firebase config | `.firebaserc`, `firebase.json`, `lib/firebase_options.dart` |
| Go-live runbook | `docs/GO_LIVE_CHECKLIST.md` |
| Cursor change log | `docs/CHANGELOG.md` |
| Mac↔PC Cursor brief | `docs/SESSION_LOG.md` |
| Backlog Claude owns | `docs/BACKLOG.md` |
| Design reference (tracked) | `.figma-import/` (Vite/shadcn mock — not the Flutter app) |

---

## 6. Conventions Claude / Cursor already follow

1. **Append** to `docs/CHANGELOG.md` (newest on top) after code/rules/config changes.  
2. **Push notes:** every meaningful commit/push gets a plain-language overall summary (commit body + GitHub release/PR when milestone). Rule: `CLAUDE.md`.  
3. **Commit author:** prefer `Wilsin Kuonadi <wilsinkarimunwkk@gmail.com>` via `GIT_AUTHOR_*` / `GIT_COMMITTER_*` env vars (do not rewrite old commits; first commit author was mistakenly “Wilsin Karimun” — left as-is).  
4. **Relaunch** after Flutter code changes: `pkill -f "flutter_tools.*run"; flutter run -d chrome`.  
5. Exercise authoring + worksheet import are **web-only** (see `.claude/rules/*`).  
6. Update **session log** in `docs/SESSION_LOG.md` when finishing a session that ships.

---

## 7. Known risks / sharp edges

| Risk | Detail |
|------|--------|
| Payments untested | Midtrans sandbox E2E never completed — highest business risk |
| Student link-code client-side | Motivated user could attach to wrong teacher |
| Storage materials path | Staff can write under another ownerId |
| Thin test suite | Almost no coverage of rules, payments, auth |
| Flutter analyze | Historically clean of **errors**; many style `info`s OK |
| Service worker cache | Users sometimes see old blank/cached web builds — hard refresh / incognito; `no-cache` headers already on key assets |
| Missing Noto glyphs | Console warning for some CJK/missing chars in Chrome — non-blocking |
| `.figma-import/` in git | Design-reference tree (~808K); confirm if Claude wants it kept long-term |

---

## 8. What the user decided / process notes

- Continuing **everything from Claude** as of this handoff (2026-10-16).  
- Mac and PC both use Cursor; chat does **not** sync — use this file + git.  
- User may assign tasks off-backlog; still don’t undo finished work.  
- Midtrans sandbox test was repeatedly deferred in favor of landing/features; still P0.  
- First GitHub snapshot documented as release `v0.1.0-initial`.  
- NAS backup scripts exist under `scripts/` but GCP auth was never completed.

---

## 9. Suggested first actions for Claude

1. `git pull` and confirm `main` matches GitHub.  
2. Skim this file + newest `CHANGELOG.md` entries.  
3. Either **run/guide the Midtrans sandbox E2E test**, or **implement P1 student registration callable** — whichever the user chooses.  
4. After any ship: update `BACKLOG.md` checkmarks, this handoff’s “already done” if needed, change log, commit with overall note, push.

---

## 10. Related docs index

| Doc | Purpose |
|-----|---------|
| `docs/CLAUDE_FULL_HANDOFF.md` | **This file** — full Claude ownership handoff |
| `docs/archive/cursor/CURSOR_CHAT_HISTORY.md` | Cursor ↔ user chat timeline + brief rundown |
| `docs/SESSION_LOG.md` | Shorter Mac↔PC Cursor session brief |
| `docs/BACKLOG.md` | Priority backlog Claude maintains |
| `docs/CHANGELOG.md` | Append-only change history |
| `docs/OWNER_PROCEDURES.md` | Step-by-step: Midtrans sandbox test, nightly backup (owner runs) |
| `docs/WORKSHEET_IMPORT.md` | Both scanners; the AI reader's one-time console setup (AI Logic + App Check) |
| `docs/GO_LIVE_CHECKLIST.md` | Launch / Midtrans / smoke-test runbook |
| `docs/FIREBASE_BACKEND.md` | Functions & rules overview |
| `docs/APP_OVERVIEW.md` | Product overview |
| `docs/SETUP.md` / `INSTALL.md` | Local setup / tester install |

---

*End of handoff. Code of record: https://github.com/lightningxian/chinese-tracker*
