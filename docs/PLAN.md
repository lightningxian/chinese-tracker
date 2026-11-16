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
  turn labelled "From Easy Study · PLAN (Fable)"). The first time, the PLAN
  chat sends a test message to prove the link.
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

| Task | State on 2026-11-16 |
|---|---|
| AI Logic "Get started", App Check web key, web push key, `deploy.env` | not done; this is why **Scan paper with AI** fails |
| Midtrans sandbox payment end to end | not run |
| Old-format exercises on live | owner believes none are left |
| Exam mode and APK on live | owner is testing |

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
| HSKK basic / intermediate / advanced | speaking: 27 / 14 / 6 items, about 20 / 23 / 25 minutes | 100 | 60 |
| YCT oral basic / intermediate | speaking | 100 | 60 |
| HSK 3.0 levels 1–6 and 7–9 | drafts, `provisional` | – | – |

YCT part minutes, HSKK timings and every HSK 3.0 number are provisional:
public sources disagree, and HSK 3.0 is reported to start worldwide on
2026-12-13. They ship as editable drafts and are fixed from the owner's own
papers. Speaking formats can be created in Build 1 but cannot be played
before Build 8.

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

### Build 1 — Test formats, test codes, supervised test, result card — **NEXT**

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

### Build 2 — Marking, leaderboard, promotion, names

- **Marking by hand:** questions a machine cannot mark (a sentence written
  with a given word, an essay; new bank type `essay` with a character
  counter) are worth 10 points by default; the result is `pending_marking`
  until a teacher enters points per answer on a marking screen
  (`markTestAnswers`), then it becomes final. HSK 6: the source article is
  shown for 10 minutes, then hidden.
- **Leaderboard per code** (`leaderboards/{codeId}/entries/{uid}`, written by
  functions): final and valid results only, highest total first, earlier
  finish wins a tie. Students see peer labels with their own row highlighted,
  for the codes they have finished; staff see staff labels.
- **Promotion:** `settings/promotion.minCodes` (3, editable). A student is
  eligible with that many different codes passed and valid at their current
  level. Admin **Promotion** screen lists eligible students with the codes
  and marks; **Verify** sets the next level, writes `level_history`, a
  notification and an audit log. `users.level` becomes admin-only in the
  rules and leaves the student profile form.
- **Student Tests place:** "2 dari 3 kode lulus", history with rank.
- **Names:** the two labels of §3 applied to every student list, table and
  picker; search matches both names.
- Screenshots 04, 06, 07, 10, 13 of the proposal list.

### Build 3 — Registration approval, placement tests, rooms

- Self-registered students are `pending`: they can sign in and see a waiting
  page; admins get an **Approval** screen (name, teacher, placement result,
  starting level) with approve and reject (reason). Register form: "Mulai
  dari HSK 1" or "Sudah ikut tes penempatan" with the result code.
- **Placement tests:** up to six test codes flagged `placement`, listed on a
  public page linked from the landing page. The visitor types a teacher code
  (the same invite code used at registration, checked by `resolveLinkCode`),
  name and WhatsApp number, sits the test in the same player through
  functions that need no login (rate-limited per address, attempt protected
  by a secret), and gets marks per part and a result code. No answer review
  is shown, because the six papers are reused. The result is stored in
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
months and sends low-balance and expiry reminders. Needs the Midtrans sandbox
test to have passed. Screenshot 05.

### Build 6 — Weekly timetable and booking

Weekly slots from the flyer (weekday, time, room, teacher, 8 seats, valid
period, no level); teacher availability and days off; a conflict check with
free-slot suggestions; a job that creates the coming weeks' sessions;
`bookSession` / `cancelBooking` functions that reserve a voucher session and
check seats, overlap and a cancel cut-off; a voucher's class day books its
student automatically. Screenshots 02 and 11.

### Build 7 — The teaching day

Teacher **Schedule** with tabs on one screen (today, week, availability):
confirm, request a change, check in with server time, attendance, close the
session in one transaction with a ledger (ends the double-charge risk);
substitute teacher; cancelling a session returns the bookings; reminder one
hour before; late check-in and unclosed-session flags; monthly recap.
Screenshot 09.

### Build 8 — Speaking tests, HSK 3.0, dashboard, screenshot pass

HSKK and YCT oral (answers recorded in the browser, marked by a teacher on
the Build 2 marking screen); final HSK 3.0 formats; admin dashboard of the
spec and the monthly report job; a GitHub Action running analyze and tests;
one pass that produces all 15 proposal screenshots from seeded data.
Screenshots 14 and 15.

Builds 2 to 8 are outlines. The PLAN chat writes each one out in full (Must,
Then, Not, acceptance walk) after reading the report of the build before it.

---

## 5. Questions still open

Needed before Build 2:

1. May the result card carry the line "Simulasi Easy Study, bukan sertifikat
   resmi"? Nationality and gender are on the official report but not in the
   app: leave them out (assumed) or add both fields to the profile?
2. Home practice: assigned HSK Simulation packages keep one clock for the
   whole paper (assumed), and only the supervised test has a clock per part.
   Or should home practice also run part by part?
3. A student with no Chinese name appears to other students by first name
   (assumed). Acceptable?
4. Does a student see the leaderboard only for codes they finished
   (assumed), or for every code?

Needed before Build 3:

5. Placement: does the visitor type name and WhatsApp before the test
   (assumed yes, so the admin sees who it was)? Are marks shown to the
   visitor at once (assumed yes, without the answer review)? Is the "teacher
   code" the same invite code students use to register (assumed yes)? Are
   the six tests full-length papers or shorter ones?

Needed before Build 5 and 6:

6. Are the Chinese package names in Build 5 right?
7. Does every student have one fixed weekly slot, or may they pick a
   different slot each week?

Needed before Build 8:

8. One HSK 3.0 paper per level (or its cover page) and one HSKK paper, so
   the formats can be exact. Who marks speaking answers?

---

## 6. Build reports (newest first, written by the BUILD chat)

_None yet._

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

## 7. Thesis track (PLAN chat)

The owner writes the thesis in the PLAN chat. Institut Sains dan Teknologi
Terpadu Surabaya; the BAA guide "Petunjuk Pembuatan File PDF Buku Tugas Akhir
/ Tesis" (2024) asks for:

- three PDFs for yudisium: the thesis book, the abstract (Indonesian and
  English, on the official abstract template) and the scientific article
  (for S2: the article already published in a journal);
- the book written in **Microsoft Word 2013 or newer** on the official
  template (not Google Docs or WPS), one file per part (title page, approval
  page, statement of originality, abstracts, preface, tables of contents,
  figures, tables, program segments, algorithms, formulas, chapters,
  bibliography, curriculum vitae, appendices);
- A4 pages, PDF properties in upper case (title, author, subject `TESIS`,
  keywords; file name = the 9-digit NRP), bookmarks that mirror the table of
  contents, made in Adobe Acrobat.

How the builds feed the thesis: each build's acceptance walk becomes a
black-box test table; `docs/screenshots/` supplies the figures; the
collections in §3 and the functions supply the data model and the program
segments.

What the PLAN chat needs from the owner:

1. The official template folder (TEMPLATE BUKU, with the abstract and
   article templates) and the thesis writing guide (chapter structure,
   citation style).
2. Full name as registered, NRP, study programme, supervisor and
   co-supervisor, the approved title in Indonesian and English.
3. The proposal as it stands (Word file), anything already written, and the
   examiners' notes from the proposal seminar.
4. Dates: next seminar, defence, yudisium.
5. The article: target journal and its template; whether it must be
   published before yudisium.
6. The evaluation the supervisor expects (black-box tests, user acceptance
   test, a questionnaire such as SUS) and how many students and teachers can
   take part.
7. Facts about the centre for chapter 1: number of students and teachers,
   how tests, schedules and payments are handled today.
8. Whether Word and Adobe Acrobat are available on the Mac or the PC.
