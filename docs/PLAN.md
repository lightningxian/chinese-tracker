# PLAN — the bridge between the planning chat and the build chat

Owner decision 2026-11-16: planning happens in one Claude Code chat (model
Fable, on the Mac, titled **Easy Study · PLAN (Fable)**); building happens in
another chat (model Opus, on the PC, titled **Easy Study · BUILD (Opus)**).
This file connects them. The PLAN chat writes §1–§5 and §7. The BUILD chat
builds the item marked **NEXT** in §4 and writes its report into §6.
Everything else about the project is in `CLAUDE.md` and
`docs/CLAUDE_FULL_HANDOFF.md`.

## 0. How the two chats work

### If you are the BUILD chat, do this

1. Read `CLAUDE.md`, then this whole file. Run `git pull`.
2. Find the item marked **NEXT** in §4. Build that item and nothing else.
   Its "Must" list is the definition of done; its "Then" list is for the time
   that is left; its "Not in this build" list is out of bounds.
3. Before the first build on a machine, run **Build 0** (§4).
4. Follow every convention in `CLAUDE.md`: read the matching
   `.claude/rules/*.md` before touching those areas, commit author, change
   log entry on top of `docs/CHANGELOG.md`, session log entry, both languages
   (`app_en.arb` + `app_id.arb`), both palettes, ViewModels for new screens,
   emulator for anything that writes data.
5. Prove the work: analyzer baseline (0 errors, 0 warnings, about 17 infos),
   `flutter test` (74 pass before Build 1; more after), function tests, rules
   tests (41 pass, 1 skipped before Build 1), and an emulator walk of every
   line in the "Must" list. Save screenshots of new screens (Indonesian UI,
   seeded names) to `docs/screenshots/build<N>/`.
6. Ship: commit, push, `scripts/deploy_web.sh --web-only` without asking, a
   GitHub release. **Ask the owner before** deploying rules or functions and
   before any delete on live data; give the exact command.
7. Write the report in §6 (template there), commit, push. If the session
   **Easy Study · PLAN (Fable)** shows in `ListAgents`, send it a five-line
   report with `SendMessage`. Then tell the owner what to test tonight.
8. Something in the plan is wrong or impossible: do not improvise a different
   feature. Build what is still valid, write the problem in the report, and
   stop.

### Rules for both chats

- The BUILD chat is the only chat that edits code. The PLAN chat edits docs
  only and commits at once.
- Both chats `git pull --rebase` before editing and push right after a commit.
  The PLAN chat owns §1–§5 and §7 of this file; the BUILD chat owns §6.
- A build is one working session of about 3 to 4 hours (owner's choice); the
  owner tests at night.
- `deploy.env` (git-ignored: `APP_CHECK_SITE_KEY`, `FCM_VAPID_KEY`) must exist
  on every machine that deploys. A deploy without it switches the AI paper
  scan and push off for everyone.

### How the chats are linked

- The BUILD chat runs on the PC with **Remote Control** switched on. PC
  sessions then show up in the PLAN chat's `ListAgents` list on the Mac, and
  the PLAN chat sends the build order with `SendMessage` (it arrives as a user
  turn labelled "From Easy Study · PLAN (Fable)"). Proven in both directions
  on 2026-11-16: the BUILD chat answers with `SendMessage` to the `from`
  address of the message it received.
- A session truly nested inside the PLAN chat can only be created on the
  machine the PLAN chat runs on (the Mac). With the BUILD chat on the PC,
  "nested" means: the PLAN chat gives the orders and reads the reports.
- If messaging is not available (PC offline, Remote Control off), git is the
  link: this file carries the order and the report.

### What the owner types into the new chat

```
Read docs/PLAN.md. You are the BUILD chat. Follow section 0, run Build 0 if this machine has not been checked, then build the item marked NEXT.
```

---

## 1. Where the project stands (2026-11-16)

**Live:** https://chinese-tracker.web.app, release v0.1.15 (2026-11-13).
Firebase project `chinese-tracker`, Blaze plan, 15 Cloud Functions on Node 22,
rules current. Android APK at `/downloads/easy-study.apk` (built 2026-11-13).
Firestore scheduled backups run nightly (3 backups READY on 2026-11-16).

**Built and verified on the emulator**

- Four roles, Indonesian + English on every screen, dark mode, landing page.
- Security: teacher self-registration closed, `active` enforced, link codes
  resolved and rate-limited on the server, answer keys never leave the
  server, invoice and voucher writes validated by rules.
- Exercises are packages from one shared question bank. Teachers build and
  assign their own packages; admins manage the bank. `startExercise` /
  `finishExercise` score on the server; explanations on the result page; time
  limit; one-attempt exam mode with a server clock.
- HSK simulation: **Scan paper with AI** (Gemini through Firebase AI Logic),
  a picture per choice, part headings, one listening recording per worksheet,
  Answer key dialog, player with audio and picture grid, marks per part.
- Payments: vouchers linked to invoices, admin cash/transfer recording,
  Midtrans sandbox webhook, parent may pay. Price list already carries the
  flyer prices (registration 100,000; 8 sessions 2,450,000; 16 sessions
  3,950,000; materials and book 250,000; 60 days).
- Push triggers deployed, push itself off until the web push key exists.

**Owner tasks still open** (steps in `docs/OWNER_PROCEDURES.md`,
`docs/WORKSHEET_IMPORT.md`, `docs/CLAUDE_FULL_HANDOFF.md`)

| Task | State on 2026-11-16 (evening) |
|---|---|
| AI Logic "Get started" | done |
| App Check web key | optional since 2026-11-17: papers are read by the built-in reader (Build 1B). Only **Scan paper with AI** needs the key (steps in `docs/WORKSHEET_IMPORT.md`). |
| Web push key | created in the console; the real key (starts with `B`) is still to be given. The Mac's `deploy.env` held only placeholder text and was removed on 2026-11-16 |
| Both public keys | the BUILD chat stores them as defaults in `scripts/deploy_web.sh`; no file to copy between machines |
| `firebase login` on the PC | to do (needed for deploys from the PC) |
| Midtrans sandbox payment end to end | not run; owner will report |
| Old-format exercises on live | none left (owner checked) |
| Exam mode on live | owner is testing |
| Android APK on live | **off.** Every `--web-only` deploy publishes the site without the APK, and the landing page then hides the download button. The last APK build is from 2026-11-12 (before HSK simulation and Build 1). The keystore is on the Mac only, so the APK is built there. Owner decides: rebuild and publish it now, or with the Build 2A deploy |

**Build status:** Build 0 passed on the PC (Windows 11, notes in `CLAUDE.md`).
**Build 1 is built** (release v0.1.16, report in §6) and reviewed by the PLAN
chat on the Mac: analyzer baseline, 83 Flutter tests, node tests pass; the
seven functions check role, ownership and clocks in transactions; no key
reaches a student before the session is closed. **Live since 2026-11-16
(night):** the owner deployed rules and functions (22 functions on live), the
PLAN chat published hosting from the Mac with `--no-keys`. The owner's live
test of one real session is still to run; it waits for a real HSK paper in
the bank, so **Build 1B (built-in paper reader) is NEXT**, Build 2A follows
in the same session.

**PLAN chat backlog:** refresh the status table in
`docs/THESIS_FEATURE_AUDIT.md` §7 (several rows say "Missing" for things that
are done).

---

## 2. Owner decisions (2026-11-16)

1. **Order of work:** test-code track, then registration approval and
   placement, then the progress report, then voucher self-purchase, then
   schedules. One build is one 3 to 4 hour session.
2. **Deploys:** hosting automatically after each push; rules and functions
   only after asking.
3. **Machines:** BUILD chat on the PC (the owner reaches it by remote), PLAN
   chat on the Mac.
4. **Prices and terms** come from the centre's flyer: registration Rp 100,000;
   16 meetings (24 hours) Rp 3,950,000 and 8 meetings (12 hours) Rp 2,450,000,
   each valid 2 months; one meeting is 1.5 hours; HSK materials and book
   Rp 250,000. Terms: a term not finished in 2 months is forfeited; remaining
   meetings cannot be moved to another student; payment in full before the
   first class; no refunds. Students are 13 or older.
5. **Timetable** (flyer), 6 to 8 students per class: Monday 16:00–17:30;
   Tuesday, Wednesday, Friday 15:00–16:30 and 16:30–18:00; Saturday
   10:00–11:30, 11:30–13:00, 13:00–14:30. Teaching is **semi-private**: one
   class holds students of different levels, each with their own material. A
   class slot therefore has **no HSK level**.
6. **Rooms:** `Main` and `Sub Room` for now.
7. **Placement test:** six tests (HSK-style papers uploaded by the admin),
   playable from the landing page **without login**, unlocked by a teacher
   code.
8. **Names:** admins and teachers see every student as
   `Chinese name (Latin name)`. A student sees other students by Chinese name
   only.
9. **Teacher schedule:** tabs on one screen, as few taps as possible.
10. **HSK tests:** a clock per part; a printable result card that looks like
    the official HSK score report (candidate table on top; listening, reading,
    writing, total, pass or fail below). The owner has papers for HSK 1–6,
    HSKK, YCT and HSK 3.0 and wants a format template for each, so papers can
    be uploaded at once.

**Second round, same day**

11. **Result card:** the line reads "Simulation by Easy Study". No nationality
    and no gender.
12. **HSK tests need the teacher:** an HSK test starts only with the code a
    teacher gives in the room, every test is taken once, and there is no
    retake. After the test it becomes **learning material**: the student may
    open it again to read the questions, their answers, the keys and the
    explanations. Before the test starts the teacher decides whether the
    **clock per part** is on or off.
13. **Chinese names:** every student should have one; when it is missing, the
    first name is shown.
14. **Leaderboard:** a student sees it only for the codes they finished.
15. **Placement:** not settled. Both ways are to be prepared: the proposal's
    (a registered student sits one test code after approval) and the public
    one on the landing page; full papers and short ones.
16. **Additions accepted:** QR code for the token and the placement link,
    item analysis per test code, black-box tables for the book, the flyer's
    terms with a tick box at purchase, automatic checks on GitHub.

17. **Paper reader (2026-11-17):** papers are read inside the app, on the
    admin's computer, with no outside API and no key. The AI scan stays as
    an extra. Every paper has its official recording and gets a transcript,
    shown to students only in the review after the session.

---

## 3. Shared design for the test track

Repo names stay English (see `docs/THESIS_FEATURE_AUDIT.md` §4 for the thesis
words). Two kinds of timed work exist side by side from now on:

| | Package (exists) | Test code (new) |
|---|---|---|
| What | practice or home simulation | the centre's supervised test |
| Who starts it | teacher assigns it | teacher opens a session, student types a token |
| Attempts | unlimited, or one in exam mode | one per code per student |
| Clock | one clock for the whole package | one clock per part, listening plays once |
| Counts for | history | result card, leaderboard, promotion |

**Collections (all written by functions unless noted)**

- `test_formats/{id}`: `family` (`hsk`, `hsk3`, `yct`, `hskk`, `yct_oral`),
  `level` label, `parts[]` (`skill`, `questions`, `minutes`, `maxScore`),
  `passMark`, `provisional`. Written by admins. Seeded by a **Load standard
  formats** button that adds missing formats and never overwrites an edited
  one.
- `test_codes/{id}`: `code` (typed by the admin, unique, upper case),
  `family`, `level`, `releaseYear`, `sheetKey` (one bank worksheet),
  `format` (a **copy** of the format's parts and pass mark, editable per code
  because every paper prints its own timing), `active`,
  `countsForPromotion`. Written by admins.
- `test_sessions/{id}`: `codeId`, `token` (6 characters, no 0/O/1/I),
  `joinUntil` (15 minutes), `openedBy`, `status`.
- `test_attempts/{codeId_uid}`: one per code per student; `sessionId`,
  current part, start time of each part, answers of each submitted part,
  left-page counter with the last 20 events, `finishedAt`.
- `test_results/{codeId_uid}`: scaled mark per part, `total`, `max`,
  `passMark`, `passed`, `valid` (+ reason), `status` (`final`, or
  `pending_marking` from Build 2), names, code, level, date, supervising
  teacher.
- Build 2 adds `leaderboards/{codeId}/entries/{uid}`,
  `settings/promotion`, `users/{uid}/level_history`.

**Marks.** A part's mark = points earned ÷ points possible × the part's
`maxScore`, rounded. A question is worth 1 point unless it says otherwise.
Questions belong to a part by their skill (listening, reading, writing), in
worksheet order. Total = sum of parts. Passed = total ≥ pass mark and the
result is valid.

**Standard formats** (listening minutes include the paper's "fill in the
answer sheet" minutes; the admin corrects a code against its cover page)

| Format | Parts: questions / minutes | Max | Pass |
|---|---|---|---|
| HSK 1 | listening 20 / 18, reading 20 / 17 | 200 | 120 |
| HSK 2 | listening 35 / 28, reading 25 / 22 | 200 | 120 |
| HSK 3 | listening 40 / 40, reading 30 / 30, writing 10 / 15 | 300 | 180 |
| HSK 4 | listening 45 / 35, reading 40 / 40, writing 15 / 25 | 300 | 180 |
| HSK 5 | listening 45 / 35, reading 45 / 45, writing 10 / 40 | 300 | 180 |
| HSK 6 | listening 50 / 40, reading 50 / 50, writing 1 / 45 | 300 | 180 |
| YCT 1 | listening 20, reading 15; 30 minutes in all | 200 | 120 |
| YCT 2 | listening 20, reading 20; 45 minutes in all | 200 | 120 |
| YCT 3 | listening 35, reading 25; 55 minutes in all | 200 | 120 |
| YCT 4 | listening 40, reading 30, writing 10; 80 minutes in all | 300 | 180 |
| HSKK basic (paper H726119Z) | speaking: repeat 15 items / 6 min, answer 10 / 4, respond 2 / 3, plus 7 min preparation; about 20 minutes | 100 | 60 |
| HSKK intermediate / advanced | speaking: 14 / 6 items, about 23 / 25 minutes (provisional) | 100 | 60 |
| YCT oral basic / intermediate | speaking (provisional) | 100 | 60 |
| HSK 3.0 level 1 | listening 20 / 15, reading 20 / 20 | 200 | 120 (provisional) |
| HSK 3.0 level 2 | listening 25 / 20, reading 25 / 25, writing 10 / 10 | 300 | 180 (provisional) |
| HSK 3.0 level 3 | listening 30 / 28, reading 30 / 30, writing 10 / 20 | 300 | 180 (provisional) |
| HSK 3.0 level 4 | listening 32 / 25, reading 32 / 30, writing 6 / 25 | 300 | 180 (provisional) |
| HSK 3.0 levels 5, 6, 7–9 | empty drafts until the owner sends those papers | – | – |

The HSK 3.0 and HSKK basic rows come from the cover pages of the owner's own
papers (2026-11-16); those papers do not print marks, so 100 per part and a
pass at 60 percent are provisional. YCT part minutes and the other speaking
formats are provisional too. Speaking formats can be created in Build 1 but
not played.

**The thesis covers HSK 1 to 6 only** (proposal, section L: no speaking test,
six HSK levels). YCT, HSKK and HSK 3.0 are extras for the centre: they get a
format so papers can be uploaded, and nothing else until the thesis builds
are done.

**The approved proposal is the contract.** The revised Tugas Akhir proposal
(defended 2026-10-07, approved 2026-10-22) is summarised in
`docs/THESIS_FEATURE_BACKLOG.md`; its section 13 lists the validation
scenarios the book must report. Each build proves its share and names the ID
in the test that proves it:

| Build | Scenario IDs |
|---|---|
| 1 (done) | TS-01, TS-02, PN-04, PN-05, LV-02 |
| 2A | PN-01, PN-02, PN-03 |
| 2B | LV-01, LV-03, LB-01 |
| 3 | PL-01, PL-02 |
| 5 | MT-01 … MT-05 |
| 6 | JD-01, JD-02, VC-04 |
| 7 | VC-01, VC-02, VC-03, VC-05 |

Where the owner's newer wishes differ from the proposal, the plan is:

| Topic | Proposal | Owner, November | Plan |
|---|---|---|---|
| Names on the leaderboard | students see first name + initial (LB-01) | students see the Chinese name | Chinese name; the book states it. **Owner to confirm with the supervisor** (§5) |
| Placement | registered student, after approval, one code of the level below the target, teacher token | public page, no login, teacher code | build both on the same token and player (Build 3) |
| Schedule level | every weekly schedule has one HSK level; students see sessions of their level | semi-private, mixed levels | level on a schedule becomes optional ("all levels"); settle at Build 6 |
| Who edits the question bank | admin and teachers | admin only (2026-11-13) | teachers add and edit **their own** questions; scanning stays with the admin (Build 2, owner to confirm) |
| Platforms | Android, iOS and web | no native iOS app | iOS through Safari "add to home screen"; a risk to raise with the supervisor |
| Test audio | at most two plays | – | a question's clip: two plays; a whole-part recording: once (it reads each item twice) |
| Speaking, YCT, HSK 3.0 | out of scope | wanted by the centre | formats now, the rest after the thesis builds |

**Names.** One helper on `AppUser`: the staff label is
`nameChinese (Latin name)`, or the Latin name alone when there is no Chinese
name; the peer label (what another student sees) is `nameChinese`, or the
first word of the Latin name when there is none. The Latin name is
`nameIndonesian`, falling back to `name`.

---

## 4. Build queue

### Build 0 — machine check (once per machine, about 30 minutes)

1. `git pull`, `flutter --version`, `flutter pub get`, `flutter analyze`,
   `flutter test`, `node -v` (22), `node --check functions/index.js`,
   `node functions/test_exercise_play.js`, `node functions/test_reminders.js`.
2. Java 21 and the rules tests; `firebase emulators:start`,
   `python3 -I scripts/seed_emulator.py`, `scripts/run_emulator_web.sh`
   (bash; on Windows use Git Bash). Sign in on the emulator bundle as
   `admin@test.chinesetracker`.
3. `firebase login:list` and `gh auth status` show the owner's accounts.
4. `deploy.env` is present in the repo root.
5. Anything missing: stop, tell the owner exactly what to install or copy,
   and continue when it is there. Write what differs from the Mac (paths,
   shell) into `CLAUDE.md` under Commands, as a short PC note.
6. Add a guard to `scripts/deploy_web.sh`: stop with a clear message when
   `APP_CHECK_SITE_KEY` is empty, unless the flag `--no-keys` is given.

### Build 1 — Test formats, test codes, supervised test, result card — done 2026-11-16 (v0.1.16, report in §6)

**Changes after the first version of this build (sent to the BUILD chat on
2026-11-16; they override the lists below where they differ)**

1. App Check on web uses `ReCaptchaEnterpriseProvider` (the console no longer
   offers v3). Owner steps in the docs: Google Cloud console → Security →
   reCAPTCHA → Create key, Website, score-based, domains
   `chinese-tracker.web.app` and `chinese-tracker.firebaseapp.com`. No
   `localhost` on this key: local runs use the debug provider.
2. The two public keys (App Check site key, web push key) become defaults in
   `scripts/deploy_web.sh`; `deploy.env` is an optional override.
3. `openTestSession` takes `partClocks` (default on), chosen by the teacher
   when opening the session. Off = one clock for the whole paper, free
   movement between parts, recording may be replayed, one submit.
4. Review as learning material: when the session is closed, the student can
   open their finished test with answers, keys, explanations and audio
   (`getTestReview`, refused while the session is open). Never a retake.
5. HSK Simulation worksheets are played only through test codes: the package
   form stops offering them and `startExercise` refuses packages of category
   `hsk_simulation`, pointing to Tests. Exam packages are unchanged.
6. Result card line: "Simulation by Easy Study". No nationality, no gender.
7. `test_results` stores `durationSeconds` (server time).
8. A question's own clip plays at most twice in a test, with a counter.
9. Tests that prove TS-01, TS-02, PN-04, PN-05 and LV-02 carry the ID in
   their name; the report lists the five.
10. Formats: the table in §3, including the exact HSKK basic and HSK 3.0
    level 1 to 4 rows.

**Goal.** An admin turns a scanned paper into a test code. A teacher opens a
supervised session and shows a token. A student types the token, sits the
test part by part under server clocks, and receives a result card in the
style of the official HSK score report. The teacher watches the session live
and may mark a result invalid.

**Must**

1. *Formats.* Admin screen **Test formats**: list, edit (parts, minutes,
   marks, pass mark), **Load standard formats** with the table in §3.
2. *Test codes.* Admin screen **Test codes**: create from a bank worksheet
   (code, family, level, release year, format), edit the copied timing,
   deactivate. Creating shows, per part, how many questions the format
   expects and how many the worksheet has; a difference is a warning, not a
   block. A duplicate code is refused. A **Create test code** action on the
   worksheet screen opens the same form filled in.
3. *Functions* (callables in `us-central1`, pure logic in its own module with
   a node test, like `functions/reminders.js`; reuse `stripQuestion` and
   `scoreAttempt` from `functions/exercise_play.js`, the rate-limit helper
   and `LATE_GRACE_SECONDS`):
   - `openTestSession` (staff): code → token and `joinUntil`; a new token
     for the same session extends the join window.
   - `startTest` (student): token → checks active student, join window, no
     earlier attempt for this code; with `peek` returns the start-screen
     facts only; otherwise creates or resumes the attempt and returns the
     **current part's** questions without keys, the seconds left in the part
     and the elapsed seconds of the recording. Wrong tokens are rate-limited.
   - `submitTestPart` (student): stores the part's answers, refuses a part
     that is already closed, treats a submit later than the part clock plus
     the grace as empty, opens the next part and returns its questions. After
     the last part it scores the attempt and writes `test_results`.
   - `reportTestEvent` (student): "left the page" / "came back", throttled.
   - `closeTestSession` (staff): finishes every open attempt of the session;
     parts never submitted count as empty.
   - `setTestResultValidity` (staff): invalid with a reason, or valid again.
4. *Student.* A **Tests** place with **Enter token**, the start screen (code,
   level, parts with minutes, the rules), the test player, the result card
   and a list of the student's own results. Player: the part's heading and
   clock; the listening recording starts with the part, has no pause, seek or
   replay, and after a reload continues from the elapsed position after one
   tap; **Next part** asks for confirmation, is disabled while the recording
   plays, and there is no way back to a closed part; the clock at zero
   submits the part by itself; answers of the open part survive a reload
   (kept on the device); leaving the tab or window shows a notice that it was
   recorded. Build the player from question widgets extracted out of
   `lib/features/student/exercise_screen.dart`, shared by both players, with
   no change in how packages behave.
5. *Result card.* On screen and as a PDF (`printing`; check that Chinese text
   renders in the PDF). Top table: name (Latin), 中文姓名, 考试类型 (for
   example HSK 三级), test code, result number, date, supervising teacher.
   Bottom table: one column per part, 总分, 合格情况 (合格 / 不合格), pass
   mark. Labels in Chinese with the app language underneath. The card carries
   the centre's name and the line "Simulasi Easy Study, bukan sertifikat
   resmi" so it cannot pass for an official certificate. An invalid result
   shows "Tidak sah" and the reason.
6. *Teacher and admin.* A **Tests** place: **Open session** (pick a code),
   the supervision screen (token in very large type, join countdown, **New
   token**, one row per student: staff label, part, time left, left-page
   count highlighted from 1, status; **End test for everyone**), and the
   results list by code with **Mark invalid** / **Mark valid**. Admins see
   every session and result; teachers see the sessions they opened.
7. *Rules and tests.* Students cannot read `test_codes` internals they do not
   need, other students' attempts or results, or write any new collection;
   staff read sessions, attempts and results; only admins write formats and
   codes. Rules tests prove each line. Function tests cover tokens, part
   clocks, lateness, scaling and the one-attempt rule.
8. *Seed.* `scripts/seed_emulator.py` adds an HSK 3-style worksheet (all
   three skills, a recording from local test media, a few picture choices),
   the standard formats and one test code, so the walk and the screenshots
   are repeatable.
9. *Regression.* One practice package and one exam-mode package still play
   end to end.

**Then (if time is left)**

- Admin **Reset attempt** on a result (deletes attempt and result, audit
  log), for power cuts.
- QR code of the token on the supervision screen.
- The hourly cleanup job also finishes attempts whose last clock ended more
  than 10 minutes ago.

**Not in this build:** marking by hand, leaderboard, promotion, speaking
tests, placement tests, changes to how packages are timed.

**Acceptance walk (emulator, then the same on live by the owner)**

1. Load formats twice: the second load changes nothing; an edited format
   keeps its edit.
2. Create a code from the seeded worksheet; create it again: refused.
3. Open a session: 6-character token, countdown from 15:00. A wrong token is
   refused; many wrong tokens are blocked for a while; a token after the
   window is refused.
4. Student starts: part 1 with its clock; the recording cannot be paused;
   reload: same clock, recording continues; leaving the tab raises the count
   on the supervision screen within 5 seconds.
5. Let a part run out: it submits itself and the next part opens. Going back
   is impossible in the app and refused by the function.
6. Finish: result card with marks per part, total, pass mark, 合格 or 不合格;
   the PDF shows the same with Chinese text.
7. The same student with a fresh token for the same code: refused.
8. Mark invalid with a reason, then valid again: the card follows.
9. Second student stops after part 1; **End test for everyone**: their
   result exists, later parts are 0.
10. Indonesian and English, dark mode, 360 px width: no overflow.

**After the build, the owner:** runs
`firebase deploy --only firestore:rules,functions --project chinese-tracker`,
loads the formats on live, creates a code from a scanned paper, and runs one
real session with a test student.

### Build 1B — Built-in HSK paper reader, no outside service — **NEXT**

**Owner decision (2026-11-17).** A paper is read **inside the app, on the
admin's computer, with no outside API and no key**: "the job is only to read
the PDF and build the questions". Every paper has its official recording,
and the centre wants a transcript of it. **Scan paper with AI** (Gemini)
stays in the code as an extra and is not part of this build; it is switched
off on live until an App Check key exists (cause proven 2026-11-17: AI Logic
answers `401 Firebase App Check token is invalid`; steps in
`docs/WORKSHEET_IMPORT.md`). The PLAN chat does not type official exam
papers out itself: the reading is done by the app on the owner's own file.

**Measured by the PLAN chat on paper `H326202Z`** (HSK 3, 16 scanned pages,
no text layer, the centre's coloured watermark across every page), with the
engine the app already ships (`tesseract.js` 5, `chi_sim+eng`), pages
rendered at 3× (1738 × 2442 px), 1 to 3 seconds per page on the Mac:

| Page kind | As scanned | After removing the watermark, page mode 6 |
|---|---|---|
| Dense text (passages 61–70) | good, about 97 to 98 of 100 characters right by eye, order kept, one choice lost | not needed; check that mode 6 keeps it as good |
| ★ statements (11–20) | text good; ★ and the brackets come out as noise | — |
| Word bank (51–55), word order (71–75), pinyin gaps (76–80) | bad: lines lost or mixed | **good: every question line is there**, a few wrong characters (伞, 裙) |
| Picture page (1–10) | no text to read | pictures must be found by image analysis |

- Watermark removal that worked: a pixel is watermark when
  `max(r,g,b) − min(r,g,b) > 28` and `max > 150` → white; luminance above
  205 → white; everything else keeps its grey value. A hard black/white
  threshold made the text worse.
- Page mode 6 (`tessedit_pageseg_mode: 6`) keeps each numbered line
  together; the default mode separated the numbers from their sentences on
  cleaned pages.
- Pinyin tone marks are **not** read (`guān` comes out as `guan`, `cháng`
  as `chdng`): the admin types the pinyin of 76–80.
- The paper has 80 questions: listening 1–40 (1–10 pictures A–F and A–E
  with no printed text, 11–20 ★ statements, 21–40 three text choices),
  reading 41–70 (41–50 match a sentence, 51–60 word bank, 61–70 passage and
  question), writing 71–80 (71–75 order the words, 76–80 character for the
  pinyin). No key and no transcript are printed in it.
- Today's on-device scanner stops at 8 scanned pages
  (`PdfTextReader._maxOcrPages`) and the recording upload at 10 MB
  (`QuestionBankMediaService._maxBytes`, `storage.rules`).

**The owner puts the test paper on the PC** at
`local_papers/H326202Z.pdf` inside the repo folder. Official papers are
never committed: the first commit of this build adds `local_papers/` to
`.gitignore`.

**Must**

1. *Measure first.* Run the reader steps below on the real paper in the
   browser on the PC and write the numbers in §6 before building the rest:
   seconds per page, and per page kind how many question lines came out
   whole. If the result is clearly worse than the table above, stop and
   tell the PLAN chat.
2. *Reading.* Question bank → **Scan paper** (the main button; **Scan paper
   with AI** moves into the ⋮ menu): render every page (`pdfrx`, about 3×),
   remove the watermark, read with page mode 6, progress "page n of m", no
   8-page limit on this path (up to 30 pages). Everything runs in the
   browser; no file leaves the computer.
3. *Structure.* Build parts and questions from the page texts: the
   headings (`一、听力`, `二、阅读`, `三、书写`, `第一部分`, `第 1-5 题`),
   the printed numbers, examples (`例如`) skipped, cover and "下面是…部分"
   pages skipped. The level comes from the cover and the paper code
   (`H3…` = HSK 3) and picks the standard test format: **every number the
   format expects gets a question slot**, also when the reader missed the
   line (the slot is empty and flagged "type this one"). Forms: picture
   choice without text, ★ true/false, three or four text choices, a shared
   list of lettered sentences, a shared word bank, passage and question,
   word order, character for a pinyin. Extend `QuestionImportUtils` and the
   normaliser that exist; do not write a second parser. Characters are
   joined (the engine puts spaces between hanzi).
4. *Pictures.* Find picture boxes on a cleaned page by image analysis
   (large non-text regions), in reading order, and make them the choices
   A–F of that range. The admin can redraw a box on the page picture.
   Cropping and upload: `WorksheetPageImages` and the media service that
   exist.
5. *Proofreading screen.* Page by page: the page picture on one side, the
   questions read from it on the other, every field editable in place,
   flagged slots first, the counts against the format on top ("Listening
   40 of 40", "missing: 12, 27"). Nothing the reader returned may vanish
   without a line on this screen. Saving makes one worksheet, as today.
6. *Answer key.* The **Answer key** dialog keeps working for choice
   questions and is offered right after saving. It also takes the writing
   answers: `71 …the sentence…` reorders that question's words into the
   sentence, `76 长` sets the accepted character.
7. *Recording and transcript.* Audio files up to 60 MB in
   `question_bank_media` (`storage.rules`, `QuestionBankMediaService`),
   pictures stay at 10 MB, upload progress, a rules test for both limits.
   A worksheet gets a **Transcript** of its recording: typed or pasted, or
   read from the official listening script (PDF or image) with the same
   reader. It is stored with the worksheet in the bank, which students
   cannot read; a student receives it only from `getTestReview` after the
   session is closed, and the review shows it under the recording. Teachers
   see it on the worksheet screen.
8. *Tests.* Unit tests for the watermark removal, the page-mode call, the
   structure builder (with short texts written for the test, not copied
   from a real paper) and the answer key lines; the Build 1 flow test still
   passes; analyzer baseline.

**Then (if time is left)**

- A list of pinyin syllables with tone marks to pick from for 76–80.
- Remember the admin's corrections of one paper as hints for the next one
  of the same level.

**Not in this build:** speech-to-text from the recording (needs a speech
model; the owner decides after seeing the transcript field), any change to
the AI scan, the App Check key, HSKK papers.

**Acceptance (emulator on the PC, with `local_papers/H326202Z.pdf`)**

1. Scan: under 2 minutes; HSK 3 and the code `H326202Z` are detected.
2. The proofreading screen shows 80 slots in listening / reading / writing
   = 40 / 30 / 10, and 11 pictures as the choices of 1–10.
3. The report states how many of the 80 questions needed no correction and
   how long proofreading took.
4. Answer key typed once for 1–80; the recording (a file above 10 MB)
   uploads and plays; the transcript is saved.
5. **Create test code** with format HSK 3: every part says its count
   matches. A session with a test student runs to the result card; after
   the session closes, the review shows the transcript.
6. Indonesian and English, dark mode, 1280 px and 360 px: no overflow.

**After the build, the owner:** deploys storage rules and functions (the
BUILD chat gives the command), then scans one paper on live. **Per paper
the owner needs:** the paper (PDF), the official answer key, the recording,
and the official listening script if there is one.

### Build 2A — Typing matcher and marking — after Build 1B, same session

**Goal.** Typed answers are scored the way the approved proposal promises
(tolerant of writing variants, half marks for near misses, a teacher reviews
the doubtful ones), free writing is marked by a teacher with the rubric, and
the loose ends of Build 1 are tied. Rules and cases:
`docs/THESIS_FEATURE_BACKLOG.md` section 7 ("Typing answer-matching
algorithm", "T5 essay grading screen") and section 13 (PN-01 to PN-03).

**Must**

1. *Build 1 follow-ups, first.*
   - The emulator seed and the flow test use a password that is **not** the
     live test accounts' password, so a saved emulator sign-in can never
     work on live. Keep the guard of Build 1.
   - **Ending a session keeps typed work.** "End test for everyone" first
     asks every sitting student's player to submit the open part (a flag on
     the attempt that the player listens to), then finishes the attempts
     about 15 seconds later. A student who was typing keeps those answers.
   - **A forgotten session closes itself.** The hourly job closes sessions
     whose last possible end (join window + paper time + grace) passed more
     than 10 minutes ago, with the same routine as the button. Only then can
     the students open their review.
   - Admin **Reset attempt** on a result (deletes attempt and result, audit
     log), for power cuts.
   - **QR code** of the token on the supervision screen; scanning opens the
     token page with the token filled in.
   - Walk the Build 1 screens in English and in light mode; fix overflow.
2. *Typing matcher* as a pure module with a node test, called by the scoring
   that packages and tests share (`functions/exercise_play.js`):
   - normalise answer and keys: trim, full-width to half-width punctuation,
     drop ending punctuation, traditional to simplified hanzi (`opencc-js`,
     the dependency the proposal names), and for pinyin lower case,
     `ü` = `v` = `u:`, tone marks to tone numbers, split into syllables;
   - exact match against every accepted key: full points;
   - Levenshtein distance `d` (character for hanzi, syllable for pinyin),
     similarity `S = 1 − d ÷ n`;
   - half points: pinyin with every syllable right and tones wrong or
     missing; typed hanzi with `d = 1` and `S ≥ 0.75`; never for sentence
     building; everything else zero;
   - every half-point answer is flagged for review.
   Repo types: `type_hanzi` covers the proposal's T2 and T3,
   `compose_sentences` is T4, a new **`type_pinyin`** is T1 (editor, player,
   importers). Scores become points (0, 0.5, 1 × the question's points);
   part marks and package scores are computed from points; old results keep
   reading correctly.
3. *Free writing (T5).* `picture_sentence` and a new bank type **`essay`**
   (prompt, optional picture, required keywords, optional source text shown
   for a set time and then hidden, as HSK 6 needs) are worth 10 points and
   are never scored by the machine.
4. *Marking.* One queue for both kinds of open item (flagged typing answers,
   free writing), from tests and from packages: collection written by the
   scoring functions, one document per answer (student, source, question,
   answer, keys, machine points, maximum, reason, status). A result with
   open items has status `pending_marking`: the card and the package result
   say "Menunggu penilaian", and `passed` is decided only when it is final.
   Teacher **Marking** tab in the Tests place: the queue (own students and
   own sessions; admins see all), and per item the question, the answer, the
   keys, the character count, required keywords found or missing, then
   either "keep / full / zero" for a flagged answer or the rubric for free
   writing (grammar 40, vocabulary 30, content 30 → points). A callable
   stores the mark, recomputes the result, makes it final when nothing is
   open, and notifies the student.
5. *PN-01 tool.* A script that reads a CSV of answers (type, keys, answer,
   the teacher's mark) and prints the system's mark per row and the
   agreement in percent; a small fixture with the spec's six cases. The 200
   real answers come from the trial.
6. *Tests.* Node tests named PN-02 and PN-03 with the spec's cases; rules
   tests for the marking collection (students never read keys or write
   marks; a teacher marks only their own queue); the Build 1 flow test still
   passes; choice questions score exactly as before.

**Then (if time is left)**

- The hourly job also finishes single attempts whose last clock ended more
  than 10 minutes ago in a session that is still running.
- Item analysis per test code (percent correct per question) on the results
  screen.

**Not in this build:** leaderboard, promotion, the names rule, teachers
editing the bank, placement, speaking.

**Acceptance walk (emulator)**

1. A package question "type the hanzi": the same answer with a full-width
   comma, with a trailing "！" and in traditional characters gets full
   marks; one wrong homophone gets half and appears in the teacher's queue.
2. A pinyin question: `ni3 hao3` and `nǐ hǎo` are full marks, `ni hao` is
   half and flagged.
3. Sentence building with two words swapped: zero, not flagged.
4. The teacher opens the queue, turns the half into full: the student's
   result changes and a notification arrives.
5. A test code with a free-writing question: after the last part the card
   says "Menunggu penilaian" with no pass or fail; the teacher marks with
   the rubric; the card becomes final with total and 合格 or 不合格.
6. The PN-01 script on the fixture prints 100 percent agreement.
7. Teacher presses "End test for everyone" while a student is typing in a
   part: those answers are in the result.
8. A session left open is closed by the job; the review opens.
9. Admin resets an attempt: the student can sit the code again; the audit
   log shows it.
10. The QR code opens the token page with the token filled.
11. English and light mode on the test screens, 360 px: no overflow.

**After the build, the owner:** deploys rules and functions (the BUILD chat
gives the command), then tests a typed-answer package and the marking tab.

### Build 2B — Leaderboard, promotion, names

Proves LV-01, LV-03, LB-01.

- **Leaderboard per code** (`leaderboards/{codeId}/entries/{uid}`, written by
  a trigger on final, valid, non-placement results): highest total first,
  shorter time wins a tie. Students see peer labels, own row highlighted,
  only for codes they finished; staff see staff labels.
- **Promotion:** a trigger counts the different codes passed and valid at the
  student's level; at `settings/promotion.minCodes` (3, editable, with the
  pass marks) it creates a recommendation in `level_promotions`. Admin
  **Promotion** screen: verify → next level, `level_history`, notification,
  audit log; the count starts again. `users.level` becomes admin-only in the
  rules and leaves the student profile form.
- **Student Tests place:** "2 dari 3 kode lulus", history with rank.
- **Names:** the two labels of §3 on every student list, table and picker;
  search matches both names; the Chinese name becomes required on the
  register and profile forms.
- **Teachers and the bank** (only if the owner confirms, §5): a teacher may
  type, paste and edit their own bank questions; scanning and other
  people's questions stay with the admin.
- Screenshots 04, 06, 07, 10, 13 of the proposal list.

### Build 3 — Registration approval, placement tests, rooms

- Self-registered students are `pending`: they can sign in and see a waiting
  page; admins get an **Approval** screen (name, teacher, placement result,
  starting level) with approve and reject (reason). Register form: "Mulai
  dari HSK 1" or "Sudah ikut tes penempatan" with the result code.
- **Placement, the proposal's way (PL-01, PL-02):** a registered and approved
  student who chose "tes penempatan" with a target level sits one test code
  of the level below the target, with a teacher token. Passed: the target
  level is recommended; failed: the tested level. The admin confirms the
  starting level. The code counts as taken; the result stays off the
  leaderboard.
- **Placement, the public way:** test codes flagged `placement` (full papers
  or short ones, each with its own timing) listed on a public page linked
  from the landing page. A teacher opens a placement session; the visitor
  types that token, a name and a WhatsApp number, sits the test in the same
  player through functions that need no login (rate-limited, attempt
  protected by a secret) and gets marks per part and a result code. No
  review is shown, because these papers are reused. The result is stored in
  `placement_results` and shows on the Approval screen.
- **Rooms:** `settings/rooms` with `Main` and `Sub Room`; the class form
  uses a picker. Teacher profile: levels the teacher can teach.
- Screenshots 01 and 12.

### Build 4 — Progress report

`progress_summary/{studentId}` kept by functions; report screen for student,
parent, teacher and admin: codes passed at the level, attendance, exercises,
marks over time (chart: add `fl_chart`), per-skill bars, teacher note, test
history with rank, the five warnings of the spec and a status label;
printable PDF. Screenshot 08.

### Build 5 — Voucher packages and self-purchase

Chinese names on the price list (proposal: 报名费, 8次课程, 16次课程,
HSK教材费); the student's voucher screen gets **Beli**: choose a package,
tick the flyer terms, pay through Midtrans (`createInvoice` opened to the
student for their own account); a daily job expires vouchers after their 2
months and sends low-balance and expiry reminders. Proves MT-01 to MT-05
(function tests for signature, repeat and status mapping; MT-05 is the
owner's comparison with the Midtrans dashboard). Screenshot 05.

### Build 6 — Weekly timetable and booking

Weekly slots from the flyer (weekday, time, room, teacher, 8 seats, valid
period, no level); teacher availability and days off; a conflict check with
free-slot suggestions; a job that creates the coming weeks' sessions;
`bookSession` / `cancelBooking` functions that reserve a voucher session and
check seats, overlap and a cancel cut-off; a voucher's class day books its
student automatically. Vouchers get `sessionsBooked`. Proves JD-01, JD-02
and VC-04. Screenshots 02 and 11.

### Build 7 — The teaching day

Teacher **Schedule** with tabs on one screen (today, week, availability):
confirm, request a change, check in with server time, attendance, close the
session in one transaction with a ledger (ends the double-charge risk);
substitute teacher; cancelling a session returns the bookings; reminder one
hour before; late check-in and unclosed-session flags; monthly recap; the
reconciliation script. Proves VC-01, VC-02, VC-03 and VC-05. Screenshot 09.

### Build 8 — Dashboard, trial kit, screenshot pass

Admin dashboard of the spec and the monthly report job; a GitHub Action
running analyze and tests; the trial kit: seed of 1 admin, 4 teachers and 30
students (12 beginner, 10 intermediate, 8 advanced), a checklist of the 731
questions the trial needs (one practice package of 15 per level, one test
code per level, two more HSK 3 codes), the task sheets of the proposal's
Table 20 and the SUS questionnaire; one pass that produces all 15 proposal
screenshots from seeded data. Screenshots 14 and 15.

### After the thesis builds — extras for the centre

Speaking tests (HSKK, YCT oral: answers recorded in the browser, marked by a
teacher), final HSK 3.0 formats for levels 5 to 9, YCT timing.

Builds 2B to 8 are outlines. The PLAN chat writes each one out in full (Must,
Then, Not, acceptance walk) after reading the report of the build before it.

---

## 5. Questions still open

For the owner, before Build 2B:

1. The proposal says students see other students on the leaderboard as
   "first name + initial" (scenario LB-01). The new rule is "Chinese name
   only". Tell the supervisor, or keep the proposal's rule?
2. The proposal lets teachers add and edit questions in the bank. The app
   keeps the bank admin-only since 2026-11-13. Plan: teachers add and edit
   their own questions. Agreed?
3. Reading of decision 12, to confirm: "teacher code" is the 6-character
   token of the session a teacher opens (new every time, valid 15 minutes),
   not the teacher's permanent invite code; the token in the room is enough
   and no test is assigned to named students beforehand; the review opens
   when the teacher closes the session, so answers cannot travel during it.

Before Build 3:

4. Public placement: does the visitor type name and WhatsApp before the test
   (assumed yes), and see marks at once without the review (assumed yes)?

Before Build 6:

5. The proposal gives every weekly schedule one HSK level; the flyer says
   classes mix levels. Plan: level optional ("all levels"). Does every
   student have one fixed weekly slot, or pick a slot each week?

Any time:

6. HSK 3.0 papers for levels 5, 6 and 7–9, and the marks per part if a paper
   or its answer sheet prints them.
7. iOS: the proposal promises Android, iOS and web. Today iOS means Safari
   with "add to home screen". Ask the supervisor whether that is accepted.

## 6. Build reports (newest first, written by the BUILD chat)

### 2026-11-17 — Build 1B Built-in HSK paper reader — d3b27b9..b2d4a30, release v0.1.17 (not deployed)
- Built: **Scan paper** (main button; AI scan in the ⋮ menu) → render,
  watermark removal, page mode 6, up to 30 pages, all in the browser →
  structure builder in `QuestionImportUtils` (part file
  `question_import_hsk_paper.dart`) → picture boxes by connected regions →
  proofreading screen with a ViewModel → one worksheet. Answer key dialog
  shared and extended for writing. Audio to 60 MB with progress. Transcript
  card on the worksheet screen; `getTestReview` returns it after the session
  closes; the review shows it under the recording.
- Must list: 1 measure pass (entry below) · 2 reading pass · 3 structure
  pass · 4 pictures pass (cut with a new `ColourPageCutter` that redraws the
  colour page at the reader's width, not `WorksheetPageImages`; upload
  through the media service) · 5 proofreading pass · 6 answer key pass ·
  7 recording + transcript pass (teachers see the transcript read-only on
  the worksheet screen) · 8 tests pass.
- Then list: not done (pinyin picker for 76–80, remembering corrections).
- **Acceptance on the emulators with `local_papers/H326202Z.pdf`:**
  1. Scan: 16 pages read in **30–32 s** (open to proofreading screen about
     40 s). HSK 3 and `H326202Z` detected. Pass.
  2. 80 slots, Listening 40 of 40, Reading 30 of 30, Writing 10 of 10;
     page 2 gives 6 boxes (A–F) and page 3 gives 5 (A–E): 11 pictures for
     1–10, cut in colour. Pass.
  3. **Needed no correction:** the first walk flagged 14 slots (46–50 lost
     choice E, 51 not read, 56–60 word bank misread, 61 lost choice B, 77 and
     80 lost pinyin); I fixed them in **2 min 27 s** (my clicks, typing
     placeholders such as `(E)` because I do not copy the paper; an admin
     reading the paper will take longer), and the app reported "66 of 80
     untouched". Reading the saved text showed that number was too kind:
     garbled choices (`H#EXLT`, `BARER`), a missing choice C on 70, pinyin
     without tones on all of 76–80, word order split into single
     characters, stray `Kk` / `CC` / `(`. The reader now flags those and
     cleans the marks: a fresh scan flags **25 of 80**. Of the 55 not
     flagged, about 18 still carry a wrong character inside a sentence
     (`符爷` for `爷爷`, `荣慢点儿`, `提和高`, `上而`), which no check can see.
     **So about 37 of 80 questions are right as read; the admin should read
     every question against the page, the flags only order the work.**
     The owner's own proofreading time is still to be measured on live.
  4. Answer key typed once for 1–80 (**test answers, not an official key**:
     the paper prints none); writing 71–75 as sentences, 76–80 as
     characters; all 80 matched. A 12,480,044-byte WAV uploaded under the new
     rule and was served to the student as the part 1 recording (playback
     not pressed). Transcript saved. Pass.
  5. Test code `H326B1` with format HSK 3: each part says its count matches.
     A session (script on the callables, student2, every fifth answer
     wrong) → result card 80/80/80 = 240/300, 合格; the review was refused
     while the session was open and showed the transcript after it closed.
     Pass.
  6. Indonesian dark at 1280 px (admin walk, result card, review), English
     light at 1280 px (result card, review), 360 px (review, proofreading
     screen): no overflow seen. Pass.
- Proof: analyzer 0 errors / 0 warnings / 17 infos; `flutter test` 100 pass
  (+17); rules tests 53 pass, 1 skipped (+5 Storage); node tests pass; flow
  test 24/24 on the emulators after a re-seed. Screenshots:
  `docs/screenshots/build1b/` (5, none showing the paper itself).
- Owner must: (1) deploy storage rules and the changed function:
  `firebase deploy --only storage,functions:getTestReview --project chinese-tracker`;
  (2) then hosting `scripts/deploy_web.sh --web-only --no-keys` (the PC has
  no `firebase login`, so from the Mac); (3) on live: Bank soal → Pindai
  kertas soal → `H326202Z.pdf`, check every question against the page
  (note the minutes), save, type the official key, upload the recording,
  add the transcript, Buat kode tes.
- Left out and why: the Then list (time); playing the long recording in
  the player (the upload and the URL were checked).
- Notes for the PLAN chat:
  - The "untouched" count in the save message counts slots the admin did
    not edit; it is not a correctness measure. The thesis number should
    come from the owner checking each question against the paper.
  - Word order (71–75): the engine spaces most characters, so the words to
    order often come out as single characters and need regrouping by hand.
  - The worksheet's skill label in the bank list is the first item's
    ("Menyimak") for a full paper.
  - The browser pane must be visible for a UI walk; hidden, its frames
    freeze.

### 2026-11-17 — Build 1B Must 1: measurement on the PC (before building)
Paper `H326202Z` (16 scanned pages), in the browser on the PC (Chrome in the
Claude app), pdf.js render at 1738 px wide, the watermark rule of §4 Build 1B,
tesseract.js 5 `chi_sim+eng`, page mode 6. A question line counts as whole
when its printed number starts a line followed by its text.

- **Time:** render 0.9 s per page on average, reading 1.8 s (0.8–3.5 s), so
  about 2.8 s per page and about 45 s for the 16 pages. Unprocessed default
  mode would be 1.1 s per page, but it misses far more lines (below).
- **Question lines whole, cleaned + mode 6** (unprocessed default mode in
  brackets):
  - 1–10 pictures: no printed text, as expected; only the number marks show
    (pictures must come from image analysis).
  - 11–20 ★ statements: 10 of 10 (10).
  - 21–40 three text choices: 20 of 20 (17).
  - 41–50 match a sentence: 10 of 10 (5).
  - 51–55 word bank: 5 of 5 sentence lines present; the numbers 51 and 52
    are misread (`S1.`, `32，`) (2 of 5).
  - 56–60 word bank: 5 of 5 (5).
  - 61–70 passage and question: 10 of 10 passages present; 65 is misread as
    `63.` (unprocessed: 4 of 10).
  - 71–75 word order: 5 of 5 (0).
  - 76–80 pinyin gaps: 5 of 5 (0); the pinyin above them has no tone marks
    (`chdng`, `zhdng`, `yudn`), as the PLAN chat found.
- **Total:** 73 of 80 numbers found as line starts (unprocessed: 45). The
  7 not found are 6, 8, 9, 10 (picture page, no text), 51, 52 and 65
  (misread digits). So the structure builder must assign numbers by the
  expected sequence of each range, not trust every printed digit.
- **Noise to handle:** spaces between hanzi; `，` or `、` instead of `.`
  after a number; `〈 )` for `( )`; the page footer code is sometimes
  misread (`13262027 - 8` for `H326202Z - 8`) but read right on most pages.
- Result is not worse than the PLAN chat's table: the build goes on.

### 2026-11-16 — Build 1 Test formats, test codes, supervised test, result card — d539d7e..029c9d8, release v0.1.16 (deployed the same night, see the last line)
- Built: 7 callables (`openTestSession`, `startTest`, `submitTestPart`,
  `reportTestEvent`, `closeTestSession`, `setTestResultValidity`,
  `getTestReview`) with pure logic in `functions/supervised_test.js`; rules
  for the 5 collections; admin Test formats / Test codes; staff Tests place,
  supervision, results; student Tests place, start screen, player, result
  card (screen + PDF), review; shared `QuestionAnswerView`; seed for the walk.
  All 10 changes of the PLAN chat are in (partClocks option, review,
  HSK Simulation only via codes, "Simulation by Easy Study", durationSeconds,
  clip played at most twice, exact HSKK basic / HSK 3.0 1–4 formats, thesis
  IDs, reCAPTCHA Enterprise, key defaults in `deploy_web.sh`).
- Must list: 1 formats pass · 2 codes pass (duplicate refused, counts warning,
  worksheet action) · 3 functions pass · 4 student pass · 5 result card pass
  (PDF with Chinese checked by rendering it) · 6 teacher/admin pass · 7 rules
  and tests pass · 8 seed pass · 9 regression pass (practice + exam package
  in the flow test).
- Thesis IDs: TS-01 pass, TS-02 pass, PN-04 pass, PN-05 pass, LV-02 pass
  (`functions/test_supervised_flow.mjs` step names, `test_supervised_test.js`,
  rules tests "PN-04 …" / "TS-02 …").
- Then list: not done (Reset attempt, QR code, cleanup job).
- Proof: analyzer 0 errors / 0 warnings / 17 infos; `flutter test` 83 pass
  (+9); rules tests 48 pass, 1 skipped (+7); node tests pass; flow test 24/24
  on the emulators; emulator walk in Indonesian, dark mode: walk lines 1–6
  and 8 by hand, 7 and 9 by the flow test, 10 partly (Indonesian, dark,
  360 px checked; English and light mode not walked on the new screens).
  Screenshots: `docs/screenshots/build1/` (14). Deploy: **not done** — the
  Firebase CLI on the PC is not signed in, so `scripts/deploy_web.sh` cannot
  run; rules and functions wait for the owner anyway.
- Owner must: (1) `firebase login` on the PC; (2) give the App Check site key
  and the web push key (they become defaults in `deploy_web.sh`); (3) run
  `firebase deploy --only firestore:rules,functions --project chinese-tracker`
  (adds 7 functions, changes `startExercise` / `finishExercise`); (4) then
  hosting: `scripts/deploy_web.sh --web-only` (or `--no-keys` until the keys
  exist). Tonight on live after (3)+(4): Tests → Format tes → Muat format
  standar; Bank soal → a scanned HSK paper → Buat kode tes; Tes → Buka sesi;
  a test student types the token and sits the paper; check the result card
  and its PDF.
- Left out and why: Then list (time). English/light walk of the new screens.
- PLAN chat note, 2026-11-16 night: **deployed.** The owner ran the rules
  and functions deploy on the Mac (7 functions created, 15 updated, 22 on
  live). The PLAN chat then ran `scripts/deploy_web.sh --web-only --no-keys`
  from the Mac; the live page serves the new build. AI paper scan and push
  stay off until the two public keys exist. The Android APK is not on live
  (see §1).
- Notes for the PLAN chat:
  - **Live sign-in incident (2026-11-16, emulator walk):** after a reload,
    the emulator bundle left Firebase Auth on the LIVE project, and a
    saved-account tap signed `admin@test.chinesetracker` in to live Auth with
    the emulator password, which is the same on live. Firestore stayed on
    the emulator, so no live data was read or written; the browser session
    was cleared at once. Cause: Auth starts before `useAuthEmulator` when a
    user is persisted. Fixed with `lib/core/utils/emulator_guard*.dart`
    (signs out locally, reloads once, else refuses to start). Suggest the
    owner changes the live test accounts' password so it differs from the
    emulator's `testpass123`.
  - Wrong-token limit is per student uid (8 per 10 minutes), not per address.
  - A reload with a token in the URL fails once the teacher gives a new
    token; the student uses **Lanjutkan tes** on the Tests page instead.
  - Clip "at most twice" is counted on the device (kept across reloads, not
    across devices).
  - HSKK basic marks per part (30/30/40) are a draft; the paper prints none.
  - On the PC the emulators need `JAVA_TOOL_OPTIONS` (CLAUDE.md PC note).

```
### <date> — Build <N> <name> — <first commit>..<last commit>, release <tag>
- Built: ...
- Must list: each line, pass or fail
- Then list: what was done
- Proof: analyzer, tests (numbers), emulator walk, deploy result
- Owner must: deploy command, what to test tonight
- Left out and why: ...
- Notes for the PLAN chat: surprises, debts, questions
```

---

## 7. Tugas Akhir track (PLAN chat)

**Facts (from the owner's documents, 2026-11-16)**

- Institut Sains dan Teknologi Terpadu Surabaya, PROG PROF S1 INFORMATIKA.
  A **Tugas Akhir** (bachelor), so the "TUGAS AKHIR" templates and dividers
  apply, not "TESIS".
- Wilsin, NRP 221310660. Title: "Aplikasi Multiplatform Sistem Kursus Bahasa
  Mandarin Easy Study menggunakan Flutter".
- Supervisor: Ong, Hansel Santoso, S.SI., M.Kom. Co-supervisor: Prof. Dr. Ir.
  Esther Irawati Setiawan, S.Kom., M.Kom.
- Proposal defended 2026-10-07, revised, decree 710/23/ISTTS/SKEP/X/2026 of
  2026-10-22. **Registration for the Tugas Akhir seminar is possible from
  2027-02-22 to 2027-10-22.**
- Examiners' conditions, all answered in the revised proposal and therefore
  owed by the app: scoring on the server (done); voucher deduction in one
  transaction, idempotent (Build 7); the typing matcher with tolerance and
  teacher review (Build 2); functional validation besides SUS (the scenario
  IDs in §3); teacher scheduling with conflict checks (Build 6); a progress
  report (Build 4); the difference between schedule and session; HSK 1 to 6.
- Trial promised: 35 respondents (30 students: 12 beginner, 10 intermediate,
  8 advanced; 4 teachers; 1 admin) at the centre; black-box tests,
  functional validation, task scenarios per role, SUS with a mean above 70;
  731 questions in the bank; Midtrans in sandbox mode.
- Proposal limits: Indonesian UI; three roles; no learning materials; no
  speaking test; no online classes; tests only at the centre with a token.
  The app's extras (English switch, parent role, materials, HSK 3.0, YCT)
  stay outside the book.

**Format rules received** (`CEK BUKU MANDIRI V4`: book, abstract, article and
appendix templates, the self-check criteria, binding dividers; plus the BAA
guide for the final PDFs): Microsoft Word 2013 or newer, one file per
chapter; A4, margins 4 / 4 / 3 / 3 cm; Times New Roman 12, spacing 1.5;
chapter titles 16 bold upper case with Roman numbers; program segments in
Courier New 10; formulas as equations; captions bold, figure below and table
above; three PDFs for yudisium (book named by NRP, abstract, article) with
upper-case properties and bookmarks made in Adobe Acrobat. Word and Acrobat
are on the PC.

**How the builds feed the book:** each build's acceptance walk becomes a
black-box table; the scenario IDs become the functional validation chapter;
`docs/screenshots/` supplies the figures; the collections and functions
supply the data model and the program segments.

**Suggested calendar:** thesis builds 1 to 8 finished by mid-January 2027;
trial with the 35 respondents in the second half of January; book written
from December, finished in February; seminar registration when the window
opens on 2027-02-22.

**Still needed from the owner**

1. The campus guide book for writing a Tugas Akhir (the criteria file says it
   is being revised; the current PDF is enough) and, if possible, one
   finished Tugas Akhir book from the campus as a model for the chapters.
2. The Word file of the revised proposal (the PDF is here; the Word file
   keeps figures and tables editable).
3. The centre today, for chapter 1 and the "old system" section: number of
   active students per level group; the four teachers and the levels each
   teaches; classes per week and students per class; payments and simulation
   tests per month; photos or screenshots of the tools used now (schedule
   spreadsheet, paper attendance sheet, a WhatsApp registration chat with
   names hidden, the old "Nilai Simulasi HSK" page).
4. The trial: when 30 students can come, which devices they will use, who
   acts as admin.
5. Dates as soon as they are known: guidance meetings, seminar, defence.
6. Whether the supervisor wants the article sent to a journal or on the
   campus template.
