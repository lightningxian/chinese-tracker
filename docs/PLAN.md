# PLAN — the bridge between the planning chat and the build chat

Owner decision 2026-11-16: planning happens in one Claude Code chat (model
Fable, session title **Easy Study · PLAN**); building happens in another chat
(model Opus, session title **Easy Study · BUILD**). This file is what connects
them. The PLAN chat writes §3 and §4; the BUILD chat reads §3, builds the item
marked **NEXT**, and writes its report into §5. Everything else about the
project is in `docs/CLAUDE_FULL_HANDOFF.md`; this file is only the current
state and the current plan.

Rules for the two chats:

1. The BUILD chat is the only chat that edits code. The PLAN chat edits docs
   only (`docs/PLAN.md`, the audit, the handoff) and commits at once, so the
   two chats never hold uncommitted changes in the same folder at the same time.
2. Both chats `git pull` before touching a file.
3. The BUILD chat follows every convention in `CLAUDE.md`: commit author,
   change log entry, session log entry, `scripts/deploy_web.sh --web-only`
   after each push, and it asks the owner before rules, functions or live
   deletes.
4. A build item is finished when its acceptance list in §3 passes, the report
   in §5 is committed, and the owner has been told what to test.
5. When both chats are open on the same Mac, they can message each other
   directly (the `ListAgents` / `SendMessage` tools; a message arrives as a
   user turn labelled "From <session title>"). Across machines, this file in
   git is the only link.

---

## 1. Where the project stands (2026-11-16)

**Live:** https://chinese-tracker.web.app, release v0.1.15 (2026-11-13),
hosting md5 matches the repo. Firebase project `chinese-tracker`, Blaze plan.
15 Cloud Functions deployed on Node 22, rules current. Android APK at
`/downloads/easy-study.apk` (built 2026-11-13, PUB-05 re-test still open).

**Backups:** Firestore scheduled backups are working: 3 nightly backups
(13, 14, 15 Nov, ~03:45 Jakarta) listed as READY, 7-day retention. The old
export function is gone.

**Built and verified (emulator) up to 2026-11-13**

- Four roles (admin, teacher, student, parent), Indonesian + English switch on
  every screen, dark mode, landing page in the Pensil direction.
- Security: teacher self-registration closed, `active` enforced, link codes
  server-validated and rate-limited, answer keys never leave the server,
  invoices and vouchers validated by rules, rules tests 41 pass.
- Exercises are packages from the shared question bank; teachers build and
  assign their own packages; admins manage the bank. Server-side scoring
  (`startExercise` / `finishExercise`), explanations on the result page, time
  limits, one-attempt exam mode with a server clock (late = 0).
- HSK simulation: **Scan paper with AI** (Gemini via Firebase AI Logic), a
  picture per choice, part headings, one listening recording per worksheet,
  Answer key dialog, player with audio + picture grid, HSK marks per part
  (listening / reading / writing out of 100, pass at 180 of 300).
- Payments: every voucher linked to an invoice, admin cash/transfer recording,
  Midtrans sandbox webhook (signature-checked, idempotent), parent may pay.
- Notifications: in-app list; push triggers `onNotificationCreated` and
  `dailyReminders` (07:00 Jakarta) deployed, push itself off until the web
  push key exists.
- Tooling: full emulator suite with seed script, 74 Flutter tests, rules
  tests, function tests, `scripts/deploy_web.sh`, owner runbooks in
  `docs/OWNER_PROCEDURES.md`.

**Not yet proven on live** (owner tests pending)

| Item | Status | Where |
|---|---|---|
| AI Logic "Get started" + App Check reCAPTCHA key + web push key | **Not done**: no `deploy.env` in the repo folder, so the AI scan button and push are still off | `docs/WORKSHEET_IMPORT.md`, `CLAUDE.md` |
| Midtrans sandbox payment end to end | Not run | `docs/OWNER_PROCEDURES.md` §A |
| Old-format exercises deleted on live | Owner said done; not verifiable from Claude | Admin → Exercises, no "Old format" rows |
| Exam mode on live, Android APK (PUB-05) | Not tested | Owner checklist artifact |
| H326202Z paper scanned, listening key typed, recording uploaded | Blocked by the AI Logic setup above | Question bank |

**Docs that need a refresh pass** (PLAN chat task): the status table in
`docs/THESIS_FEATURE_AUDIT.md` §7 still says "Missing" for FCM tokens,
readable answer keys and client-written scores, all of which are done. Refresh
it before ordering the thesis work.

## 2. Thesis status in one view

Spec v2 (`docs/THESIS_FEATURE_BACKLOG.md`), 9 phases. Honest picture:

| Phase | State | Notes |
|---|---|---|
| P1 accounts, approval, rooms, settings, FCM tokens | half | self-registration exists but no approval screen; rooms are free text; `settings/org` holds booleans; push tokens done |
| P2 repeating schedules, conflict check, booking function | mostly missing | one-off sessions, in-app join without reservation |
| P3 check-in, atomic close, reminders, recap | mostly missing | attendance exists; `concludeClassSession` is not atomic |
| P4 voucher catalog, self-purchase, expiry job | half | invoices ↔ vouchers done; packages hard-coded; students cannot buy themselves |
| P5 question bank, forms, server grading, exam mode | mostly done | typing matcher and per-level exam format missing |
| P6 (v2) test codes, supervised token, leaderboard, promotion by 3 passed codes | missing | the thesis core; the exam player and HSK marks it needs already exist |
| P7 progress summary, warnings, report screen | mostly missing | in-app attention list only |
| P8 monthly report job, dashboard rework | partly | PDFs on demand |
| P9 push notifications | wired | off until the web push key exists |

Of the 15 proposal screenshots, 2 exist, 5 partly, 8 not yet
(`docs/THESIS_FEATURE_AUDIT.md` §0, "Screenshot readiness").

## 3. Build queue

Items are written by the PLAN chat only after the owner's answers in §4. Each
item carries: goal, acceptance (observable checks), files or layers to touch,
proof to run, non-goals. The BUILD chat builds the one item marked **NEXT**.

_No item is marked NEXT yet. Waiting for the answers in §4._

Candidates, not ordered:

- **A. HSK test-code track (thesis core, P6 v2):** `test_codes` collection
  (admin types code, HSK level, release year, links one package), one attempt
  per code per student, supervised test token (6 characters, 15 minutes),
  "left the page" events, teacher supervision screen, leaderboard per code
  with masked names, promotion check (3 passed codes at the level) with admin
  verification. Reuses exam mode and HSK marks. Gives screenshots 06, 07, 10, 13.
- **B. P1 approval flow:** pending registrations, admin approve/reject with
  starting HSK level or placement choice, `users.level` locked to admin
  writes. Screenshots 01, 12.
- **C. P4 voucher catalog + self-purchase:** `settings/pricing` already
  exists; add package picker and "Beli" for students, daily expiry job,
  low-balance reminder. Screenshot 05.
- **D. P2 schedules:** weekly plan, conflict check function with suggestions,
  booking callable with reservation. Screenshots 02, 09, 11.
- **E. P7 progress report:** `progress_summary` per student, "2 of 3 codes"
  card, chart, per-skill, warnings, status label. Screenshot 08.
- **F. HSK polish:** per-part timing (listening once, then reading and
  writing clocks), printable result card, bulk CSV/JSON + audio import.
- **G. Hardening leftovers** (`docs/BACKLOG.md` §4–5): storage write scoping,
  GitHub Action for analyze + test, webhook unit test.

Recommended order if the owner has no objection: **A → B → E → C → D**, with
F and G slotted in between when a build session has spare time. Reason: A is
the thesis's centre and is cheapest now, B and E give the proposal its
remaining student and admin screenshots, C and D are the largest and least
thesis-specific.

## 4. Questions for the owner (answer in the PLAN chat)

Status I cannot see from here:

1. Have you done the three console steps (AI Logic "Get started", App Check
   web key, Cloud Messaging web push key)? There is no `deploy.env` in the
   repo folder yet, so nothing has been redeployed with the keys.
2. Did the Midtrans sandbox test (runbook §A) run, and what did you see?
3. Does the admin Exercises table still show any "Old format" rows?
4. Did you test exam mode and the Android APK on live, and did anything break?
5. Did the AI scan of the H326202Z paper work once AI Logic was on?

Decisions that shape the queue:

6. When is the thesis proposal due and when is the defense? Which of the 15
   screenshots do you need first?
7. Do you accept the order A → B → E → C → D above, or do you want a
   different first item?
8. How big should one build item be: one build-chat session (about 2 to 4
   hours of Claude work) or smaller pieces you can test one by one?
9. Should the BUILD chat keep auto-deploying hosting after every push, and
   keep asking you before rules and functions deploys? (Current rule: yes to
   both.)
10. Will the BUILD chat run only on this Mac, or also on the PC? Direct
    messaging between the chats works only on the same machine.

Thesis details still unconfirmed (needed when their item starts):

11. Voucher packages: Chinese names, validity, prices per package (P4).
12. Room names (P1).
13. Placement test: one test code of the level below the target, as the spec
    says, or something simpler?
14. Leaderboard: how are names masked for students (first name plus initial,
    or nickname), and does a student see only the codes they took?
15. Teacher schedule screen: tabs on one screen or separate screens (P2)?
16. HSK: do you want per-part timing (listening plays once, then the reading
    and writing clocks), a printable result card, and which HSK levels do you
    have papers and audio for?

## 5. Build reports (newest first, written by the BUILD chat)

_None yet._

Template:

```
### <date> — <item letter and name> — <commit range>
- Built: ...
- Acceptance: each check from §3, pass/fail
- Proof: analyzer, tests, emulator walk, deploy result
- Owner must: deploy command / test steps
- Left out and why: ...
```
