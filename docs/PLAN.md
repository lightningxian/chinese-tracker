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

## 1. Where the project stands (2026-11-20)

**Live:** https://chinese-tracker.web.app, hosting at release v0.1.46
(Build 9 part 2, the heavy lists, from the PC 2026-11-26: the teacher Students tab, the
dashboard drill-downs, exercise packages, the question bank, the History timeline, Grades, the
transcript and Timetable follow-up read a page at a time; 5 new functions, 82 on live; 55 new
indexes, 97 on live; rules: `bank_sheets` staff read, no client write; checked from the Mac the
same day: analyzer 16 infos, 209 Flutter tests, node suites, 87 rules tests, functions and
indexes on live equal to the repo, the live bundle carries the build, no secret tracked. Two
notes for a later session, neither blocks: `stampAssignments` writes with merge, so an
assignment deleted during a refresh can come back as a two-field ghost; `onQuestionBankIndexed`
reads then sets without a transaction, so questions of one worksheet written one by one can
leave an old count until the next write or **Rebuild list indexes**. Owner once: Org settings →
Rebuild list indexes, then Rebuild progress summaries. v0.1.45
Build 9 Then list part 1 from the PC 2026-11-26: News, test sessions and results, declined
promotions, the student's exercise results and admin Vouchers are paged, the bell reads the
newest 30 notices of each kind; hosting and 8 indexes, 42 on live, no function or rules change;
checked from the Mac the same day: analyzer 16 infos, 204 Flutter tests, 42 indexes and 77
functions on live equal to the repo, no secret tracked. v0.1.44
Build 9 session 2 from the PC 2026-11-26: Payments, Users, the marking queue and the student
and parent History are paged; search on Users is a query on an index the new trigger
`onUserSearchIndex` writes; `rebuildUserSearch` for old accounts; functions, 10 new indexes and
hosting; **77 functions**, 34 indexes, rules unchanged; checked from the Mac the same day:
analyzer 16 infos, 204 Flutter tests, every node suite, 77 functions and 34 indexes on live
equal to the repo, no secret tracked. **Open for the owner: press Rebuild user search once (the
live Users list shows only accounts written since the deploy until then), and Rebuild
leaderboards once.** v0.1.43
Build 9D test-code retakes from the PC 2026-11-26: a student sits a code again only in a new
session, the first valid sitting counts for the board, promotion and placement, repeats are
practice; functions and hosting, 75 functions unchanged, rules and indexes unchanged; checked
from the Mac the same day: analyzer 16 infos, 202 Flutter tests, every node suite, the bundle
carries the new strings, no secret tracked. v0.1.42
Build 9 session 1 from the PC 2026-11-26: the shared paging pieces, the paged audit log with
a date range, reports over a period of months, leaderboard time stamps with staff export and
"Share my result", timed exam packages that can be sat again; functions, one index and
hosting; **75 functions** with the new `rebuildLeaderboards`; checked from the Mac the same
night: analyzer 16 infos, 202 Flutter tests, every node suite, 75 functions and 24 indexes on
live equal to the repo, the bundle carries the new strings, no secret tracked. Open: the owner
presses Org settings → **Rebuild leaderboards** once. v0.1.41
recheck with four small fixes, hosting only, from the PC 2026-11-25, checked from the Mac;
v0.1.40 Fill in the blanks for the Standard Course review and v0.1.39 the Standard Course
scanner, both functions and hosting, 74 functions unchanged; v0.1.38 Scan paper hands a
non-HSK file to the worksheet reader; v0.1.37 more audio file types for recordings; v0.1.36 Exam hidden, "Standard Course",
recording required for HSK sheets, test codes removable by admins with a
rules change; v0.1.35 the pre-filled Answer key dialog; v0.1.34 word-order and
character answers, the HSK Standard Course type, recording preview; v0.1.33 scan drafts, shuffled choices
and level checklists with Firestore and Storage rules; v0.1.32 profiles and waiting list,
v0.1.31 the fourth round, v0.1.30 App Store readiness with the Android APK
back at `/downloads/easy-study.apk`, v0.1.29 the third round plus the
listening-script writer Q7; Build 8 was v0.1.26 on 2026-11-21). **All eight thesis builds are
built, reviewed and live (2026-11-21).** Firebase project
`chinese-tracker`, Blaze plan, **74 Cloud Functions** on Node 22 and 23
composite indexes (2026-11-23: v0.1.27 added `deleteSchedule`,
`cleanPlacementResults` and `runPlacementCleanup`; v0.1.28 added
`importHolidays` and `setDayClosed`; 2026-11-24: v0.1.29 added
`promoteStudent` and `onAnnouncementCreated`; v0.1.30 added
`deleteMyAccount`; v0.1.31 added `discardInvoice`; v0.1.32 added
`joinWaitlist`, `leaveWaitlist` and `onSessionSeatsChanged`; v0.1.33 added
`onExerciseResultForPath` and `onLevelPathWritten`. Since 7157d16 a
`--web-only` deploy downloads the live APK first and keeps it on hosting,
proven by the v0.1.31 deploy) (Builds 2B to 5 went live on 2026-11-20, Builds 6, 7
and 8 on 2026-11-21, each
deployed from the PC; the PLAN chat counts the functions and indexes from
the Mac after every build). **Owner decision 2026-11-20 (said in the BUILD
chat, recorded here):** every build in the queue is built and deployed
without asking ("all auto build, all automatically confirmed"); the BUILD
chat stops when the weekly usage limit reaches 99 percent. The PLAN chat
still reviews every build on the Mac before the next one is marked NEXT.
The
backend of Builds 1B and 2A (Storage rules, Firestore rules, two marking
indexes, functions) is live since 2026-11-17: the owner signed in to the
Firebase CLI on the PC and had the BUILD chat run the deploy. The PLAN chat
checked from the Mac that `markAnswer`, `resetTestAttempt` and
`getTestReview` answer on live. The
Android APK is off (table below). Firestore scheduled backups run nightly.

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

| Task | State on 2026-11-20 |
|---|---|
| AI Logic "Get started" | done |
| App Check web key | optional since 2026-11-17: papers are read by the built-in reader (Build 1B). Only **Scan paper with AI** needs the key (steps in `docs/WORKSHEET_IMPORT.md`). |
| Web push key | created in the console; the real key (starts with `B`) is still to be given. The Mac's `deploy.env` held only placeholder text and was removed on 2026-11-16 |
| Both public keys | the BUILD chat stores them as defaults in `scripts/deploy_web.sh`; no file to copy between machines |
| `firebase login` on the PC | done 2026-11-17 |
| Midtrans sandbox payment end to end | not run; owner will report |
| Old-format exercises on live | none left (owner checked) |
| Exam mode on live | owner is testing |
| Backend of Builds 1B and 2A | done 2026-11-17 (deployed from the PC) |
| Try Build 2A on live | make a small package with one "type the hanzi" and one "type the pinyin" question, play it as `student1@`, mark it as `teacher@` in Tests, **Marking** |
| Deploy Build 3 (rules, indexes, functions, then hosting) | done 2026-11-20 (night), from the PC at the owner's go, in that order: 34 functions, hosting v0.1.21 |
| After the Build 3 deploy | open **Org settings** once (writes `settings/rooms`); tick **Placement code** on one short paper's code; tell the admin that new students now wait on Users, **Approval**. Placement papers for visitors should be choice and typing questions only (free writing counts as zero for a visitor) |
| After the Build 8 deploy | **to do:** Laporan, **Laporan bulanan**, Hitung ulang once for October and November; when the respondents are known, the live trial seed (names and passwords in the git-ignored `scripts/trial/*.local.*` files, a service-account key downloaded outside the repo, `--dry-run` first); fill the question bank from `docs/TRIAL_KIT.md`. The GitHub checks are green on main (badge in `README.md`) |
| After the Build 7 deploy | **to do:** the teachers confirm their schedules on **Schedule**, Week; the first real session is closed through the app (Mulai sesi, Absensi, Tutup sesi) and checked on Timetable, **Teacher recap**; press Org settings, **Voucher check** once (older vouchers are measured from their first close through the app) |
| After the Build 6 deploy | **to do:** enter the real timetable (admin Classes, **Timetable**: the flyer's slots, each with its teacher and room), each teacher's availability (teacher profile), and the class day on the active vouchers (admin voucher form). Students book only through **Daftar** from now on; old one-off sessions keep working |
| After the Build 5 deploy: **sandbox payment E2E (MT-05)** | **to do:** on live as `student1@`, Payments, **Beli voucher**, tick the terms, pay in Midtrans Snap with a sandbox test card (`docs/GO_LIVE_CHECKLIST.md` §4–6); check the invoice turns paid and one voucher with 8 sessions and a 60-day deadline appears; compare every test payment with the Midtrans sandbox dashboard. Production keys stay off until this passes |
| After the Build 4 deploy | **to do:** sign in as admin on live, Org settings, **Rebuild progress summaries** once (the report screens are empty until then). Expect the first 07:00 run after that to send "no practice for 14 days" notices to every student who has not practised in the app for two weeks (the proposal's warning 3; students who never practised count from their approval or creation date) |
| Try Build 2B on live | as admin: Tests, **Promotion** opens and shows the minimum codes (3); Tests, Results, a code, **Leaderboard**. As `student1@`: the Tests tab shows "0 of 3 codes passed". Results written before 2026-11-20 reach a board only when they next change (mark invalid and valid again does it) |
| Functions deploy for Build 1C | done 2026-11-19 (deployed from the PC at the owner's go; 25 functions updated, the PLAN chat listed them from the Mac). Marking items of a test now also reach the student's own teacher, for attempts started from that day on |
| Proofread `H326202Z` on live | to do: Question bank, **Scan paper**, check every question against the page, note the minutes, save, type the official key, upload the recording, add the transcript, **Create test code**. Then **Download text** on the worksheet and put the file on the PC as `local_papers/H326202Z.truth.json` (never committed): that gives the reader's real right-as-read number for the thesis |
| **Security: the GitHub repository is PUBLIC** (found by the PLAN chat 2026-11-17) | `docs/CLAUDE_FULL_HANDOFF.md` and `docs/FIREBASE_BACKEND.md` show the live test accounts' password. Owner: (1) reset the passwords of `admin@`, `teacher@`, `student1-3@test.chinesetracker` in Firebase Authentication; (2) decide whether the repository becomes private. Steps: `docs/OWNER_PROCEDURES.md` §C (written 2026-11-25). The password is in 8 files (docs, app code, seed scripts), not in the live web app; after the owner says "test passwords reset", the BUILD chat removes it from all 8 |
| Android APK on live | **off.** Every `--web-only` deploy publishes the site without the APK, and the landing page then hides the download button. The last APK build is from 2026-11-12 (before HSK simulation and Build 1). The keystore is on the Mac only, so the APK is built there. Owner decides: rebuild and publish it now, or with the Build 2A deploy |

**Build status:** Build 0 passed on the PC (Windows 11, notes in `CLAUDE.md`).
**Build 1 is built** (release v0.1.16, report in §6) and reviewed by the PLAN
chat on the Mac: analyzer baseline, 83 Flutter tests, node tests pass; the
seven functions check role, ownership and clocks in transactions; no key
reaches a student before the session is closed. **Live since 2026-11-16
(night):** the owner deployed rules and functions (22 functions on live), the
PLAN chat published hosting from the Mac with `--no-keys`. The owner's live
test of one real session is still to run; it waits for a real HSK paper in
the bank.

**Build 1B is built** (release v0.1.17, report in §6) and reviewed by the
PLAN chat on the Mac on 2026-11-17: analyzer baseline (17 infos), 100
Flutter tests, node tests, rules tests 53 pass and 1 skipped. The transcript
sits on the bank questions, which only staff can read; the player's
questions pass through `stripQuestion`, a fixed list of fields, so the
transcript reaches a student only through `getTestReview` after the session
is closed. The committed screenshots show test text, not the paper. Hosting
is published; the owner's deploy of Storage rules and `getTestReview` is
open. **What the reader can do today:** all 80 slots and the 11 pictures in
about 30 seconds, but only about 37 of 80 questions are right as read (25
flagged, about 18 with a wrong character that no check sees). The admin
reads every question against the page. Making the reader better is
**Build 1C**.

**Build 2A is built** (release v0.1.18, report in §6) and reviewed by the
PLAN chat on the Mac on 2026-11-17: analyzer baseline, 105 Flutter tests,
node tests (typing matcher 15 checks, marking, PN-01 sample 6 of 6), rules
tests 56 pass and 1 skipped. `markAnswer` checks the role and the queue
owner, clamps every rubric part and re-scores inside one transaction;
`marking_items` (they hold the accepted keys) are read only by the admin and
the teachers named on the item, and written only by functions; the new
question types reach the player without their keys; `resetTestAttempt` is
admin-only and writes the audit log. The service check asked for in the
Build 1B review is in (`hsk_paper_import.dart`). Hosting is published; the
client reads an older server without breaking, so the order of the two
deploys does not matter.

**Build 1C is built** (release v0.1.19, report in §6; the owner told the
BUILD chat "1C go next", so it ran in the same session) and reviewed by the
PLAN chat on the Mac on 2026-11-18: analyzer baseline, 118 Flutter tests,
node tests, rules tests 57 pass and 1 skipped; the fetch script's SHA-256
pins were proven on the Mac (the same files download and verify there);
the reader loads its model from our own hosting under `ocr/` and nothing
leaves the computer; the practice paper is our own text; the only function
change is `teacherIdsFor` (live since 2026-11-19). **The reader now reads 79 of 80 questions right
on the practice paper** (37 before) and finds every slot of the real paper
in about 70 seconds; the real paper's number waits for the owner's truth
file.

**Build 2B is built** (release v0.1.20, report in §6) and reviewed by the
PLAN chat on the Mac on 2026-11-20: analyzer baseline, 127 Flutter tests,
node tests (+ `test_promotion.js`), rules tests 62 pass and 1 skipped. Read:
`leaderboards`, `level_promotions`, `promotion_progress` and `level_history`
are written only by the trigger and `decidePromotion`; a student reads a
board only for a code they sat and reads their own recommendation (the
decline reason is in it; the app does not show it); `decidePromotion` is
admin-only, runs in one transaction and refuses a recommendation that is not
waiting or whose student changed level; `users.level` cannot be changed by
the student; a teacher's bank writes are tied to `createdBy`. Live checked
from the Mac: the hosting bundle carries the new routes, 27 functions, the 18
composite indexes match the repo.

**Build 3 is built** (release v0.1.21, report in §6) and reviewed by the
PLAN chat on the Mac on 2026-11-20 (night): analyzer baseline, 135 Flutter
tests, node tests (+ `test_placement.js`), rules tests 68 pass and 1
skipped. Read: a pending student is refused by `isStudent()`,
`isApprovedUser()` and `requireCaller()`; the self-update rule locks
`status`, the placement fields and `levels`; `decideRegistration` is
admin-only in one transaction, needs an active teacher and a level from the
list, claims a result code once; the visitor path is public but every call
is rate-limited per address, the attempt key is a random 128-bit value
stored as a hash and compared in constant time, visitor attempts have an
empty `studentId` so no student reads them, `placement_results` is staff
only, a visitor may only join a placement session on a placement code, and
the result view and the result-code lookup carry no name, number or key.
Two notes, no change asked: the wrong-token block for visitors is per
address (8 wrong tokens in 10 minutes), so a classroom behind one Wi-Fi
router can block itself for a while if several visitors mistype; and
`decideRegistration` writes the default minimum of 3 codes into
`promotion_progress` instead of `settings/promotion.minCodes` (the trigger
corrects it at the next result). **Live since 2026-11-20 (night):** rules,
index, functions and hosting, deployed from the PC at the owner's go.
**Build 4 is built and live** (release v0.1.22, report in §6; rules, two
indexes, five functions and hosting deployed from the PC on 2026-11-20
under the owner's standing go) and reviewed by the PLAN chat on the Mac the
same night: analyzer baseline, 140 Flutter tests, node tests (+
`test_progress.js`), rules tests 71 pass and 1 skipped. Read:
`progress_summary` is written only by `refreshProgressSummary` (bounded
queries; a failed refresh never fails the write that triggered it);
`progress_notes` are created only by an admin or the student's own teacher
with a fixed field shape and a 500-character text, edited by the author or
an admin; the daily pass sends each warning at most once per 7 days;
`rebuildProgressSummaries` is admin-only with an audit line. Live from the
Mac: 39 functions, 20 indexes equal to the repo, the bundle carries the
report.

**Build 5 is built and live** (release v0.1.23, report in §6; rules, one
function and hosting deployed from the PC on 2026-11-20 under the owner's
standing go) and reviewed by the PLAN chat on the Mac on 2026-11-21:
analyzer baseline, 144 Flutter tests, node tests (+ `test_payments.js`,
MT-01 to MT-04), rules tests 73 pass and 1 skipped. Read: `createInvoice`
lets a student buy only for themself and a parent only for a linked child,
demands the ticked terms, sells only active session packages, keeps the
server-side amount and reuses one open purchase; the webhook's signature
check, status mapping and idempotent credit moved to `functions/payments.js`
unchanged in behaviour; the Snap stub URL is read only when the function
runs on the emulator; the emulator secret and stub files are git-ignored
and no `.local` or `.env` file is tracked; `voucher_history` is read by the
owner, staff and the linked parent and written by nobody; the expiry job
runs one idempotent transaction per term. Live from the Mac: 40 functions,
20 indexes equal to the repo, the bundle carries the buy sheet. The sandbox
E2E (MT-05) is the owner's (table above).

**Build 6 is built and live** (release v0.1.24, report in §6; rules, three
indexes, five functions and hosting deployed from the PC on 2026-11-21
under the owner's standing go) and reviewed by the PLAN chat on the Mac on
2026-11-21: analyzer baseline, 146 Flutter tests, node tests (+
`test_scheduling.js`), rules tests 77 pass and 1 skipped. Read: schedules
are written only by `saveSchedule`, whose conflict check runs inside a
transaction that bumps the teacher's and the room's lock document (two
saves at once end with one schedule); generated sessions are written only
by functions and students can no longer create or delete `attendance`
themselves; `bookSession` checks the seat, the voucher and the overlap in
one transaction and a student or parent may book only for their own
account or child. Two deviations accepted: generated sessions are readable
by every student and parent (the centre's timetable is shared), and the
class day is set on the admin voucher form, not yet in the buy sheet
(moved to Build 7's "Then"). The BUILD chat did not open the new screens
by hand; the PLAN chat walked them on the emulator from the Mac: the Timetable (week grid with a horizontal scroll, list, availability with the day off), the New schedule form, where a Monday 16:00 class in Main for Andrea was refused with "Main is taken by Kelas A on Monday 16:00–17:30" and five free times, Save disabled; the student home list of the next 14 days with **Book**: "Booked." appeared, the row turned to **Cancel** and the seats went from 7 of 8 to 6 of 8; the same list at 375 px. All fine. One finding for Build 7: the admin Classes calendar shows no generated sessions (it lists one-off sessions only), so the admin finds them on the Timetable screen for now.

**Build 7 is built and live** (release v0.1.25, report in §6; rules, 13
functions and hosting deployed from the PC on 2026-11-21 under the owner's
standing go) and reviewed by the PLAN chat on the Mac on 2026-11-21:
analyzer baseline, 150 Flutter tests, node tests (+ `test_teaching_day.js`),
rules tests 80 pass and 1 skipped. Read: `closeSession` runs in one
transaction, writes one ledger document per student under a fixed id and
answers "already done" to a second call (VC-02); only the session's
teacher or an admin may check in, close or cancel, and only an admin may
cancel a timetable session; a timetable session cannot be closed before it
starts; reminders and the late flag are claimed in transactions so a job
run twice sends once; the session's life fields and the attendance status
are closed to clients in the rules; the reconciliation tool never holds a
password (an admin's ID token on live). The BUILD chat's six choices are
accepted, with one follow-up: a forgotten exam attempt is closed without a
result, so it never shows in the history; Build 8's "Then" asks for a zero
result instead, as a late test gets. Live from the Mac: 58 functions, 23
indexes equal to the repo, the bundle carries the Schedule screen.

**Build 8 is built and live** (release v0.1.26, report in §6; rules, two
functions and hosting deployed from the PC on 2026-11-21 under the owner's
standing go; the GitHub checks are green on main) and reviewed by the PLAN
chat on the Mac on 2026-11-21: analyzer baseline, 152 Flutter tests, node
tests (+ `test_reports.js` and the two tool tests), rules tests 81 pass and
1 skipped. Read: `reports/{yyyyMM}` is written by functions and read by
admins only; the rebuild is admin-only; the workflow holds no secret and
pins the Flutter version; the live trial seed takes a service-account key
by path and never embeds one, and the names and passwords live in
git-ignored files; the emulator-only `?as=` sign-in and its password are
absent from the live bundle; the forgotten-attempt zero result is in. One
hygiene item for the next BUILD session: `scripts/__pycache__/*.pyc` was
committed and `__pycache__/` is not git-ignored. Live from the Mac: 60
functions, 23 indexes equal to the repo, the bundle carries the monthly
report. **Nothing is marked NEXT: the thesis builds are finished, the
owner decides what follows ("After Build 8" in §4).**

**2026-11-26: Build 9 is finished and live, part 2 (the heavy lists) as
v0.1.46; nothing is marked NEXT.** Owner: Org settings → Rebuild list
indexes, then Rebuild progress summaries, once. Earlier: 2026-11-25 Build 9 was marked NEXT (paged lists with a date range,
reports over a period, leaderboard export and time stamps, HSK simulation
retakes): the supervisor's four remarks about the app, §4.

**v0.1.27 (owner requests and the After-Build-8 follow-ups) is live**
(242e287 + d2ddbeb, functions and hosting from the PC on 2026-11-23 under
the owner's standing go; no rules change) and reviewed by the PLAN chat on
the Mac on 2026-11-23: analyzer 17 infos, `flutter test` 156 pass and 2
skipped, every node and tool test passes, rules tests 81 pass and 1
skipped. Read: `deleteSchedule` is admin-only, cancels only coming sessions
(bookings and voucher sessions return) and writes an audit entry; the daily
`cleanPlacementResults` clears only the name and WhatsApp number of visitor
results nobody claimed after 180 days and keeps the marks; the emulator-only
clock override of `runPlacementCleanup` is guarded by `FUNCTIONS_EMULATOR`;
the change-password card re-authenticates with the current password before
`updatePassword` and asks for 8 characters; the buy-sheet class day is
checked against an active schedule and the id is sanitised; visitor wrong
tokens are 8 per browser tab and 40 per address (a rotated tab id still hits
the address cap); booking stays open until the class ends. Live from the
Mac: 63 functions with the three new names, the bundle carries Timetable
rules, Recheck, Teacher check-in, Print day sheet and Change password. No
tracked secrets. **Owner live step:** open Timetable → Timetable rules once;
if the gap shows 15, set 0.

**v0.1.28 (owner requests, second round) is live** (545ef58, rules,
functions and hosting from the PC on 2026-11-23 under the owner's standing
go) and reviewed by the PLAN chat on the Mac on 2026-11-23: analyzer 17
infos, `flutter test` 160 pass and 2 skipped, every node and tool test
passes, rules tests 84 pass and 1 skipped. Read: the three new rules are
tight (a helper teacher reads only sessions whose `coTeacherIds` hold their
uid; `holidays` has no client write; `announcements` are admin-written with
required keys, length caps and a fixed audience list, read by approved users
and shown only until `toDate`); `importHolidays` and `setDayClosed` are
admin-only, idempotent and audited, closing cancels only sessions not yet
started and reopening restores only generated sessions it had cancelled;
helpers are clash-checked with a lock per teacher inside the `saveSchedule`
transaction and may close their sessions; the board-compare fields are
length-capped; the minimum-students rule ships off (0). The 2027 holiday
dates were copied by the BUILD chat from the government list and are not
verified by the PLAN chat; the admin decides each day anyway. Live from the
Mac: 65 functions, 23 indexes equal to the repo, the bundle carries
holidays, announcements, helper teachers and the readiness switch. No
tracked secrets. **Thesis note:** `settings/scheduling.teacherReadiness`
ships off, which hides availability, confirmation, late check-in and the
recap; **switch it on before the trial** (Timetable → Timetable rules) so
the JD and VC scenarios and the screenshots show them, and describe the
switch in Bab V.

**PLAN chat decision 2026-11-17** (the BUILD chat asked): an answer from a
supervised test that needs marking goes to the teacher who opened the
session **and** to the student's own teacher, the same as packages. The
owner may change this; it is a small follow-up in Build 1C.

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

### Build 1B — Built-in HSK paper reader, no outside service — done 2026-11-17 (v0.1.17, report in §6)

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

### Build 2A — Typing matcher and marking — done 2026-11-17 (v0.1.18, report in §6)

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

### Build 1C — Reader accuracy — done 2026-11-18 (v0.1.19, report in §6)

**Why.** Build 1B measured the built-in reader on `H326202Z` (report in §6):
every slot and picture is found in about 30 seconds, but only about 37 of 80
questions are right as read. 25 are flagged; about 18 more carry a wrong
character that no check sees. So today the admin reads all 80 questions
against the page. The goal: most questions right as read, and every doubtful
one flagged, with still no outside API.

**What is known**

- Engine: tesseract.js 5 with `chi_sim+eng` (a 2.5 MB model), page mode 6.
  Only the text is used; the positions of lines and words are thrown away.
- Kinds of error in the report: lost choices (E on 46–50, B on 61, C on 70),
  word bank lines misread (51–60), short choices read as Latin letters,
  single wrong characters inside sentences, pinyin without tone marks
  (76–80), word-order pieces split into single characters (71–75).
- PLAN chat check on the Mac, four cleaned pages, page mode 6: `chi_sim`
  alone reads the same as `chi_sim+eng` (hanzi counts 104/421/73/79 against
  104/413/71/79, the same five pinyin misreads) and is about 40% faster. So
  dropping `eng` saves time but does not fix the errors.
- Truth text never comes from Claude typing out a real paper. There are two
  sources: a **practice paper made for the test** (Must 1, can be built at
  once) and the worksheet the **owner proofreads on live** (§1 owner tasks;
  it gives the real number when it exists). The build does not wait for the
  owner.

**Must**

1. **Two truths.**
   a. **A practice paper made for the test:** a script writes an HSK 3
      paper in the real layout from sentences made up for it (80 questions:
      picture pages with drawn shapes, ★ statements, three choices, match a
      sentence, word bank, passage and question, word order, pinyin with
      tone marks above a gap), a pastel watermark on every page, then turns
      each page into a picture of scan quality (the resolution of the real
      scan, a little blur and noise) and saves the PDF with its truth JSON
      under `test/fixtures/` (committed: it is our own text).
   b. **The real paper:** on a worksheet screen, admin only, **Download
      text** saves the worksheet's questions as one JSON file. When the
      owner has proofread `H326202Z` on live he puts that file on the PC as
      `local_papers/H326202Z.truth.json` (never committed).
   A measure page or script on the emulator bundle scans a PDF and compares
   with its truth: questions right as read, flagged, wrong and not flagged,
   seconds. Report the practice paper always, the real paper when its truth
   file is there; without it give the real paper's flag counts only.
2. **Measure before building** (numbers in §6). Candidates:
   a. the engine of today, using positions: word boxes from Tesseract, the
      choices and the word bank built from columns, word-order pieces
      regrouped by the gaps between them;
   b. each line cut out and read on its own (page mode 7);
   c. a stronger Chinese reading model that still runs in the browser: the
      PP-OCR models (PaddleOCR, detection + recognition) through ONNX
      Runtime Web, files served from our own hosting and loaded only when
      **Scan paper** opens. Look up the current docs and model files, do not
      work from memory; check the licence, the download size (aim under
      25 MB) and the time (16 pages under 2 minutes on the PC).
   If no candidate reaches 60 of 80 right as read, write the numbers in §6
   and stop.
3. **Build the winner** behind `PaperOcrEngine`; the engine of today stays
   as the fallback when the model cannot load.
4. **Flag by level.** A character outside the level's character list (HSK 1
   to 3 for an HSK 3 paper; a data file with its source named) flags the
   question. Names and places will flag too: that is accepted.
5. **Pinyin for 76–80** (left over from Build 1B): the admin picks the tone
   on each syllable or types `guan1`; the field shows `guān`.
6. **Proofreading record** saved with the worksheet: slots, flagged, changed
   by the admin, minutes on the proofreading screen. The admin sees it on
   the worksheet screen. This is the number for the thesis test chapter.
7. **Indexes file.** The deploy of 2026-11-17 reported three indexes that
   exist on live but not in `firestore.indexes.json`. Add them to the file
   (`firebase firestore:indexes --project chinese-tracker` prints them), so
   a later deploy can never remove them. Never deploy indexes with
   `--force` before that.
8. **Follow-up of Build 2A:** a marking item from a supervised test also
   names the student's own teacher in `teacherIds` (today only the teacher
   who opened the session), the same as packages. A node test and a rules
   test prove it.

**Not in this build:** an outside API, speech-to-text, changes to the AI
scan.

**Acceptance** (emulator; the practice paper, and `H326202Z` when its truth
file exists): at least 60 of 80 right as read; at most 5 wrong and not
flagged; scan under 2 minutes; the
pinyin of 76–80 saved with tone marks; the proofreading record shown;
Indonesian and English, dark, 1280 px and 360 px. These targets are the PLAN
chat's; if the measurement of Must 2 shows they are out of reach, say so in
the report.

### Build 2B — Leaderboard, promotion, names — done 2026-11-20 (v0.1.20, report in §6)

**Goal.** A final, valid test result puts the student on the leaderboard of
its code and counts toward promotion: three different codes passed at the
student's level, and the admin gets a recommendation to move the student
up. Everyone sees student names by the two labels of §3. Proves LV-01,
LV-03 and LB-01. Spec: `docs/THESIS_FEATURE_BACKLOG.md` section 8.

**What exists.** `test_results/{codeId_uid}` (parts, `total`, `max`,
`passed`, `valid`, `status` `final` or `pending_marking`, time taken),
`countsForPromotion` on a code, `markAnswer` (pending becomes final),
`setTestResultValidity`, `resetTestAttempt` (deletes the result),
`users.level`.

**Defaults taken for the open questions of §5** (the owner may change them
before the build starts): students see other students by the Chinese name
(the book says so, the owner tells the supervisor); teachers add and edit
their own bank questions.

**Must**

1. **One trigger on `test_results`** (create, update, delete) keeps both the
   leaderboard and the promotion count right after every change: a new
   final result, pending marking that becomes final, a result switched to
   invalid or back, an attempt reset. Pure logic in its own module with a
   node test.
2. **Leaderboard** `leaderboards/{codeId}/entries/{uid}`: an entry exists
   only while the result is final, valid and not a placement result. It
   holds the peer label (never the Latin full name), the mark of each part,
   total, max, passed, seconds taken, finished time. Order: total high to
   low, then fewer seconds, then earlier finish. Rules: staff read all; a
   student reads the entries of a code only when their own result for that
   code exists; nobody writes from the app; a student still cannot read
   another student's `test_results`.
3. **Leaderboard screens.** Student: My results, a code, **Leaderboard**:
   rank, name, part marks, total, passed or not, own row highlighted.
   Staff: Test results of a code, **Leaderboard**, with the staff label
   (read from `users`).
4. **Promotion count.** `settings/promotion` holds `minCodes` (3, the admin
   edits it). Counted: different codes at the student's current level whose
   result is final, valid, passed, counts for promotion and is not a
   placement. At `minCodes` the trigger writes one recommendation
   `level_promotions/{uid_level}` (waiting, from, to, the codes) and
   notifies the admins. If a result later turns invalid or is reset and the
   count falls below, a waiting recommendation is withdrawn. HSK 6 has no
   next level: no recommendation.
5. **Admin Promotion screen** (Tests, **Promotion**, with a badge): the
   waiting list with the codes and marks. **Approve** (callable, admin
   only): `users.level` goes up one level, `users/{uid}/level_history` gets
   date, from, to and the codes, the student and a linked parent are told,
   audit log. **Decline** with a reason. The group shown with a level:
   Beginner (HSK 1 and 2), Intermediate (3 and 4), Advance (5 and 6).
6. **`users.level` is set by the admin only:** rules refuse a student's own
   change, and the field leaves the student profile form. Rules tests.
7. **Student Tests tab:** "2 of 3 codes passed" for the current level, and
   the history with the rank on each code.
8. **Names.** The two labels of §3 on every student list, table and picker;
   search matches both names; the Chinese name becomes required on the
   register and profile forms.
9. **Teachers and the bank.** A teacher types, pastes and edits their own
   bank questions (`createdBy` = their uid) and deletes only those; rules
   say the same; scanning and other people's questions stay with the admin.
   Update `.claude/rules/exercise-authoring-web-only.md`.
10. **Tests.** The spec's example (code A 170 fails, B 195, C 200, D 205:
    three passes, recommend HSK 4) for LV-01; two passes and one fail for
    LV-03; LB-01 with 15 seeded results against a ranking written by hand
    in the test; the flow test walks marking, invalid and reset and checks
    the board and the count after each.

**Then:** the Build 2A leftovers (the hourly job that closes forgotten
single attempts of packages, item analysis per question); a CSV of a
leaderboard.

**Not in this build:** placement tests (Build 3), parents on the
leaderboard, import of old results (no access to the old project),
speaking.

**Acceptance** (emulator): a third passed code creates the recommendation
and the admin badge; approve moves the level and writes the history; two
passes and one fail show "2 of 3" and no recommendation; a result marked
invalid leaves the board and the count at once and comes back when set
valid; a pending result is on no board until it is marked; a student opens
the board of a finished code and is refused for a code they have not sat;
names follow the two labels as student, teacher and admin; a teacher edits
their own question and is refused on another's; Indonesian and English,
dark, 1280 px and 360 px. Screenshots 04, 06, 07, 10 and 13 of the
proposal list.

**After the build, the owner:** deploys rules, indexes and functions (the
BUILD chat gives the command).

### Build 3 — Registration approval, placement tests, rooms — done 2026-11-20 (v0.1.21, report in §6; live after the owner's deploy)

**Goal.** A new student registers and waits; the admin approves them with a
teacher and a starting level, or rejects them with a reason. A placement
test exists in both ways the owner asked for: the proposal's way (an
approved student sits one code of the level below their target in a
placement session) and the public way (a visitor on the landing page sits a
short placement paper behind a teacher's token, with no account). Rooms
become a list. Proves PL-01 and PL-02. Spec: `docs/THESIS_FEATURE_BACKLOG.md`
sections 3 and 8; owner decisions 6, 7 and 15 in §2.

**What exists.** `AuthService.register()` resolves a teacher link code
through `resolveLinkCode`, then creates the auth account and the `users`
doc (`active: true`, `level` picked by the student, `termSize`).
`onUserCreated` tells the admins and the teacher. `openTestSession`,
`startTest`, `submitTestPart`, `closeTestSession` and `finishSession` run a
supervised test; `writeTestResult` writes `test_results`;
`functions/promotion.js` already skips results with `placement: true`
(`isPlacement`) for the board and the count; `decidePromotion` and the
admin **Promotion** screen move a level up. `settings/org` is edited on the
admin Org settings screen (`org_settings_screen.dart`). The session form has
a free-text room. `qr_flutter` is in the app.

**Defaults taken for the open questions of §5** (the owner may change them
before the build starts): the visitor types a name and a WhatsApp number
before the test and sees marks at once with no review (Q4); the teacher
link code becomes optional at registration and the admin sets the teacher
at approval (Q10); a student who chose the placement test is approved at
HSK 1 first and moved by the placement result through the Promotion screen
(Q11).

**Must**

1. **Pending accounts.** A self-registered student gets `status: 'pending'`
   (`active` stays `true`, so the two flags keep their meanings: `active`
   is the admin's on/off switch, `status` is the approval). The register
   form loses the level picker and gets the choice **"Mulai dari HSK 1"**
   or **"Ikut tes penempatan"** with a target level HSK 2 to 6, plus an
   optional **result code** from a public placement test (resolved live by
   `resolvePlacementResult`, which shows the paper's level, the mark and
   the recommended level before the form is sent). The teacher link code
   becomes optional; when typed it is still resolved before the auth
   account is created (`.claude/rules/auth-and-link-codes.md`). Term size
   stays as it is. Stored: `placementChoice` (`hsk1` or `test`),
   `placementTarget` (`HSK 4`), `placementResultCode`.
2. **Rules.** `isStudent()` also requires `status` to be missing or
   `active` (existing students have no `status` field; no migration). A
   pending or rejected student can read only their own `users` doc and the
   notifications addressed to them. The self-update rule refuses changes
   to `status`, `placement*` fields and `levels`. `selfUserCreateValid`
   accepts `status: 'pending'`, an empty `level` and an empty `teacherId`.
   Rules tests for each line.
3. **Waiting page.** The router sends a signed-in student whose `status` is
   `pending` or `rejected` to `/waiting` (and nowhere else): the name, what
   they chose (HSK 1, or the target level and the result code), "waiting
   for the admin", the centre's WhatsApp, **Sign out**. A rejected student
   sees the reason. `AuthService` keeps them signed in (they are active).
4. **Approval.** Admin Users tab, a new **Approval** section (first chip,
   with a badge of pending accounts): one card per pending student with
   the staff label, email, WhatsApp, registered date, the choice, the
   placement result when a code was given (paper level, mark, passed,
   recommended level), a teacher picker (prefilled from the link code) and
   a starting level picker (prefilled with the recommended level, else
   HSK 1). **Approve** and **Reject** (reason required) call
   `decideRegistration` (admin only, one transaction): approve sets
   `status: 'active'`, `level`, `teacherId`, `approvedAt`, `approvedBy`,
   stamps `claimedBy` on the placement result so a code is used once, tells
   the student (kind `registration`, opens `/student`) and the teacher, and
   writes the audit log; reject sets `status: 'rejected'` and
   `rejectReason`, tells the student, audit log. A rejected account may be
   approved later. `onUserCreated` sends the admin notice to
   `/admin/users/approval` and says "waiting for approval". Rejected
   accounts sit in a collapsed list under the pending ones; deleting one
   uses the existing `deleteUserAccount`.
5. **Placement sessions.** `openTestSession` takes `placement: true`
   (a tick on the Open session dialog, "Placement session: results stay off
   the leaderboard and the count"). Every attempt and result of such a
   session carries `placement: true` (`writeTestResult` stamps it; the
   trigger of Build 2B already ignores it; a test proves the board and the
   count are untouched). The start screen and the result card say
   "Placement test". For a signed-in student the trigger also writes a
   recommendation `level_promotions/{uid}_placement` (kind `placement`,
   from the current level, to the recommended level: **passed = the paper's
   level + 1, failed = the paper's level**; nothing when that equals the
   current level) and tells the admins; the Promotion screen shows it with
   a "Placement" chip and `decidePromotion` approves or declines it as
   today (approve writes `level_history` with `kind: 'placement'` and sets
   `placementDone: true`). The student's Tests tab card says "Placement
   test: waiting for the admin" and then the result. Pure logic
   (recommendation rule, result code, visitor key) in
   `functions/placement.js` with a node test.
6. **Placement codes and the public menu.** A test code gets `placement:
   true` (tick on the code form, forces `countsForPromotion: false`); short
   papers are ordinary worksheets with their own copied timing. A visitor
   may only join a placement session on a placement code. Callable
   `placementMenu` (no sign-in, rate-limited): active placement codes with
   level, parts, minutes and question counts.
7. **Visitor functions** (no sign-in; `request.auth` is null; every call
   rate-limited per address with `throttle`; keys never leave the server,
   reuse `stripQuestion` / `partPayload` / `scoreTest`):
   - `startPlacement` `{token, name, whatsapp}`: the session must be open,
     a placement session on a placement code, inside the join window;
     creates `test_attempts/{sessionId_random}` with `visitor: true`,
     `studentId: ''`, `visitorName`, `visitorWhatsapp` and `keyHash`
     (SHA-256 of a random 128-bit key); returns the key **once**, the
     attempt id, the facts and part 1. Wrong tokens count against the
     address like `assertNotTokenBlocked` does for a uid.
   - `submitPlacementPart` `{attemptId, key, partIndex, answers}`: checks
     the key hash, then behaves like `submitTestPart` (closed part refused,
     late = empty, next part returned). After the last part it writes
     `placement_results/{attemptId}`: name, WhatsApp, codeId, code, level,
     parts, total, max, passMark, passed, `recommendedLevel`, `resultCode`
     (6 characters, no 0/O/1/I, unique), sessionId, openedBy, finishedAt,
     `claimedBy: ''`; returns the marks per part, passed and the result
     code. No keys, no review, ever (the papers are reused).
   - `resolvePlacementResult` `{resultCode}`: level, total, max, passed,
     recommended level, whether it is already claimed. Nothing else.
   - `closeTestSession`, `finishSession` and `closeForgottenTestSessions`
     also finish visitor attempts, through the same `placement_results`
     path. Rules: `placement_results` read by staff, written by nobody;
     visitor attempts are readable by staff only (`studentId` is empty).
8. **Public pages** (routes `/placement`, `/placement/test`,
   `/placement/result`, public in the router like `/register`): a
   **Placement test** section on the landing page (after the levels ruler)
   that links to `/placement`: the list from `placementMenu`, the token
   form (token, name, WhatsApp, one line that says the name and number are
   kept for registration), the player (reuse `test_player_screen.dart` in
   a visitor mode that calls the visitor functions; attempt id and key kept
   in `sessionStorage` so a reload resumes), the result page (marks per
   part, passed or not, the recommended level, the result code in large
   type with **Copy**, and **Daftar sekarang** that opens
   `/register?placement=CODE` with the code filled in). The supervision
   screen of a placement session shows visitor rows as "Visitor · name"
   and a QR code of `https://chinese-tracker.web.app/placement?token=…`
   beside the token.
9. **Rooms and teacher levels.** `settings/rooms` `{names: ['Main', 'Sub
   Room']}` edited on the Org settings screen (add, rename, remove; the
   defaults are written when the doc is missing); the session forms use a
   picker (a stored room that is not in the list stays selectable).
   Teachers get `users.levels` (a list of `HSK 1` to `HSK 6`) ticked by the
   admin on the user form and shown read-only on the teacher's profile tab;
   Build 6 uses it. Rules: `settings/rooms` admin write; `levels` admin
   only.
10. **Notifications.** Kind `registration` opens `/admin/users/approval`
    for the admin and `/student` for the student
    (`notification_routes.dart` + its test).
11. **Seed and tests.** `scripts/seed_emulator.py`: two pending students
    (one "Mulai dari HSK 1", one target HSK 4 with a visitor result code
    already in `placement_results`), one placement code `H1PLACE` (a short
    HSK 1 paper of 6 questions, 2 minutes per part, from seeded bank items),
    `settings/rooms`, `levels` on the teachers. Tests with the scenario IDs
    in their names: **PL-02** (approve a "Mulai dari HSK 1" student: level
    HSK 1, status active) and **PL-01** (target HSK 4, approved at HSK 1,
    placement session on `H3DEMO1`, passes: recommendation to HSK 4 waits
    for the admin; approve: level HSK 4, history, no board row, count 0 of
    3 at HSK 4) in `functions/test_supervised_flow.mjs`; the visitor path
    end to end in the same flow test (menu, token, two parts, result code,
    resolve, claimed once; wrong key refused; a visitor calling `startTest`
    or `getTestReview` refused); rules tests (pending student refused on
    `exercises`, `class_sessions`, `test_results`; self-update of `status`,
    `level`, `levels`, `teacherId` refused; `placement_results` staff only;
    `settings/rooms` admin write); a Flutter test of the register form's
    choice logic.

**Then (if time is left):** a declined promotion recommendation reopens
when the student passes one more different code after the decline (§5
Q12); the Build 2B leftovers (the hourly job that closes forgotten single
attempts of packages, item analysis per question, a CSV of a leaderboard);
a WhatsApp link on the Approval card.

**Not in this build:** the timetable and room clashes (Build 6), the
progress report (Build 4), payments and self-purchase (Build 5), sending
WhatsApp or SMS, email verification, speaking tests, deleting visitor data
by itself (the admin deletes a `placement_results` doc by hand; a retention
rule is a Build 8 question).

**Acceptance walk (emulator)**

1. Register as a new student with "Mulai dari HSK 1" and no link code: the
   waiting page opens; `/student` and every other route send back to it;
   the admin badge shows 1. Approve with teacher Andrea and HSK 1: the
   student's next load lands on the home at HSK 1 (PL-02); the student
   and the teacher get a notice.
2. Register with "Ikut tes penempatan", target HSK 4. Approve at HSK 1. The
   teacher opens a **placement** session on `H3DEMO1`; the student passes
   it: the Promotion screen shows "Placement · HSK 1 → HSK 4" with the
   mark; approve: level HSK 4, `level_history` has the entry, the
   leaderboard of `H3DEMO1` has no row for them, the Tests tab says "0 of
   3 codes passed toward HSK 5" (PL-01). Fail the same test with another
   student: the recommendation says HSK 3.
3. Visitor: landing page, **Placement test**, the token of a placement
   session on `H1PLACE`, name and WhatsApp, two short parts, the result page
   with marks and a code; reload in the middle resumes the same part. Register
   with that code: the form shows the paper's level and mark; the Approval
   card shows the same and prefills the level; approve; a second
   registration with the same code is refused as claimed.
4. Reject a pending student with a reason: their waiting page shows it;
   approve them afterwards: it works.
5. Wrong token ten times from one address: blocked for a while; a wrong
   key on `submitPlacementPart` is refused; the visitor's browser never
   receives a `correctIndex`, `answer` or `transcript` (check the network
   panel); a student cannot read `placement_results`.
6. The session form offers Main and Sub Room; the admin adds "Room 3" in
   Org settings and the picker shows it; a teacher's profile lists their
   levels.
7. Indonesian (dark) and English (light), 1280 px and 360 px: register
   form, waiting page, Approval, placement pages, supervision with a
   visitor row and the QR. Screenshots 01 and 12 of the proposal list, plus
   the placement token page for the book.

**After the build, the owner:** deploys rules and functions (the BUILD
chat gives the command), opens Org settings once so `settings/rooms` is
written, ticks `placement` on one short paper's code on live, and tells the
admin that new students now wait on the Approval screen.

### Build 4 — Progress report — done 2026-11-20 (v0.1.22, report in §6)

**Goal.** One summary document per student, kept by functions, feeds one
report screen for the student, the parent, the teacher and the admin in the
proposal's layout: status chip, "2 of 3 codes passed", four KPI cards, the
weekly practice chart, per-skill bars, the latest teacher note, the test
history with the leaderboard rank. The five warnings of the spec and the
status label are computed in the same place and notified once a day. A
printable PDF. Screenshot 08. Spec: `docs/THESIS_FEATURE_BACKLOG.md`
section 9 (LV-03's "progress shows 2 of 3" is already proven by Build 2B).

**What exists.** `exercise_results` (score 0 to 100, `correct`, `total`,
`bySkill` `{skill: {correct, total}}`, `category`, `submittedAt`, `late`),
written only by `finishExercise`; `test_results`, `leaderboards` (the rank
is computed from the entries), `promotion_progress` (count of codes at the
level), `users/{uid}/level_history`; `attendance` records with
`attendanceStatus` `hadir` / `izin` / `alpa`, `sessionDate`, `classTermId`;
`student_class_terms` (`sessionsRemaining`, `deadlineDate`, `status`);
`evaluations` (a teacher's rating, strengths, improvements, comment per
term); `TeacherAttentionUtils` (client side: overdue exercise, stale
assignment, inactive 7 days, low sessions) on the teacher dashboard and the
admin metrics section; `AdminAttentionUtils.buildVoucherAlerts`; the old PDF
`StudentProgressReportPdf` behind `StudentReportService.previewReport`
(lessons, terms, exercises); `student_progress_tab.dart` (two segments:
lessons by term, exercise attempts); the parent overview tab; the
`dailyReminders` job at 07:00 Jakarta (assignment reminders, pure logic in
`functions/reminders.js`); packages `pdf` and `printing` with the Chinese
font of the result card. No chart package yet.

**Defaults taken for the open questions of §5** (the owner may change them
before the build starts): practice = every package result, whatever its
category (Q13); the teacher note is a new follow-up note, the latest one is
shown, evaluations stay as they are (Q14); warning notices go out once a
day at 07:00 Jakarta and at most once per 7 days per student and warning
(Q15); attendance % = hadir ÷ (hadir + alpa), izin left out (Q16).

**Must**

1. **`progress_summary/{studentId}`**, written only by functions. Fields:
   `level`, `levelKey`, `group`; `codes` (count, minCodes, next, copied
   from `promotion_progress`); `practice` (the last 12 ISO weeks, Jakarta
   time: average score and attempts per week; average of the last 14 days;
   average of the 14 days before; last practice date; attempts in 90 days);
   `skills` (average per skill from `bySkill` over 90 days: listening,
   reading, typing, plus writing and speaking when present); `tests`
   (history newest first: codeId, code, level, date, marks per part, total,
   max, passed, valid, status, rank and board size, placement flag; passed
   count at the current level); `attendance` (percent in the last 30 days,
   counts of hadir / izin / alpa, the last 10 records); `voucher`
   (sessions remaining, `booked` 0 until Build 6, deadline, days left,
   status); `latestNote` (text, teacher, date); `levelHistory`;
   `warnings[]` (`{id: 1..5, since, detail}`); `status` (`good` with 0
   warnings, `attention` with 1, `follow_up` with 2 or more); `updatedAt`.
   Pure logic in `functions/progress.js`: `summarize(inputs, nowMs)`,
   `warningsOf(summary, nowMs)`, `statusOf(warnings)`, ISO-week buckets,
   with a node test (Must 9).
2. **Warnings**, exactly the spec's table: (1) attendance under 75 percent
   in the last 30 days, when at least 4 records exist; (2) practice average
   of the last 14 days under 60, or at least 10 points under the 14 days
   before (each window needs at least 2 attempts); (3) no practice for 14
   days (students with no practice ever count from their approval date);
   (4) voucher with 2 or fewer sessions left, or a deadline within 7 days,
   on the active term; (5) the last two final, valid, non-placement test
   results both failed. Boundary values in the node test.
3. **Who refreshes it.** One helper `refreshProgressSummary(uid)` in
   `index.js` reads the student's documents with bounded queries
   (`exercise_results` by `studentId` ordered by `submittedAt` desc, limit
   200: add the composite index to `firestore.indexes.json`; `attendance`
   by `studentId` and `sessionDate` desc, limit 60, the index exists;
   `student_class_terms` by `studentId`; `test_results` by `studentId`; the
   rank from `leaderboards/{codeId}/entries` of each code, at most 20
   codes; the latest `progress_notes`; `level_history`) and writes the
   summary. Called from `onDocumentWritten` triggers on `exercise_results`,
   `attendance`, `student_class_terms` and `progress_notes`, from the
   existing `onTestResultWritten`, and after an approve in
   `decideRegistration` and `decidePromotion`. A failed refresh is logged
   and never fails the write that triggered it.
4. **Daily pass and notices.** The `dailyReminders` job (07:00 Jakarta)
   also refreshes the summary of every active, approved student (warnings
   1, 3 and 4 move with time, not with writes) and then sends the warning
   notices of the spec's table as `notifications` docs (the student's own
   teacher = `users.teacherId`; admin broadcasts), kind `progress`, at most
   once per 7 days per student and warning (`notifiedAt[id]` on the
   summary). A cleared warning sends nothing. Pure selection logic in
   `progress.js` (`noticesDue(summary, nowMs)`).
5. **Rules.** `progress_summary/{uid}`: read by the student, staff and the
   linked parent; write false. `progress_notes/{id}` (`studentId`,
   `teacherId`, `teacherName`, `text` up to 500 characters, `createdAt`):
   create by a teacher for a student with `teacherId` = their uid, or by an
   admin; read by staff, the student and the linked parent; update and
   delete by the author or an admin. Rules tests.
6. **Report screen**, one widget for every role (`StudentProgressReport
   Screen(studentId)`; reads the summary doc and streams `progress_notes`):
   header with the name label of the viewer's role, the level chip with
   its group and the status chip (Progres Baik / Perlu Perhatian / Perlu
   Tindak Lanjut); the "2 of 3 codes passed toward HSK 4" bar; four KPI
   cards (attendance 30 days, practice average 14 days with the change
   against the 14 days before, tests passed at the level, voucher sessions
   left with the days to the deadline); the weekly practice line chart of
   12 weeks (`fl_chart`, the owner approves the dependency; the BUILD chat
   reads `AppColors` for both palettes); per-skill bars; the latest
   teacher note with **Add note** for staff; the warnings with the rule's
   text; the test history table (code, date, marks per part, total, passed,
   rank "3 of 15", tags invalid / placement / pending marking, a tap opens
   the result card); the level history. Every block has an empty state.
   Where it lives: student Progress tab = this screen, with the old
   exercise-attempt list as a second segment (the lessons-by-term segment
   stays when the student has lessons); parent overview = the report of
   the selected child; teacher student detail gets **Progress report**;
   admin Users, a student, **Progress report**.
7. **Attention lists.** The teacher dashboard's attention list shows the
   five warnings from the summaries of the teacher's students (status
   chip, warning chips, tap opens the report) and keeps the two
   assignment items of `TeacherAttentionUtils` (overdue exercise, stale
   assignment); the inactive and low-sessions items move to the summary's
   warnings 3 and 4 so nothing is counted twice. The admin metrics section
   gets **Students needing attention** with filters by level and teacher.
8. **PDF.** **Print report** builds the same report with `pdf` and
   `printing` (Chinese font as the result card): header, status, KPIs, the
   weekly averages as a table, the skill table, the warnings, the test
   history, the latest note. It replaces the content of
   `StudentProgressReportPdf`; `previewReport` keeps its entry points.
9. **Backfill, seed, tests.** Admin-only callable `rebuildProgressSummaries`
   behind a button on the Org settings screen (every active student; the
   owner presses it once after the deploy; the seed uses it on the
   emulator). Seed: five students shaped for the five warnings (attendance
   under 75, falling scores, inactive 20 days, two failed tests, a voucher
   with 1 session left) plus one healthy student with 12 weeks of practice
   and 2 of 3 codes. Tests: `functions/test_progress.js` (week buckets at
   the Jakarta midnight boundary, averages, skill averages, attendance
   with izin left out, every warning at and beside its boundary, the
   status label, `noticesDue` once per 7 days); flow test steps: a new
   practice result updates the summary, a test result adds a history row
   with its rank, a note appears for the student and the parent, a student
   cannot read another summary, the daily job sends each notice once and
   not again, `rebuildProgressSummaries` is admin-only; a Flutter test of
   the chart data mapping and the empty states; `notification_routes_test`
   for kind `progress`.
10. **Notifications.** Kind `progress` opens the student's Progress tab,
    the teacher's student report, the admin's student page.

**Then (if time is left):** a period filter (this month, last 3 months) and
a CSV on the admin attention list; the leftovers of Builds 2B and 3 (§5 Q12
reopen after a decline, the hourly job that closes forgotten single package
attempts, item analysis per question, a leaderboard CSV, a WhatsApp link on
the Approval card).

**Not in this build:** the monthly admin report and dashboard rework (Build
8), schedules and booking (`booked` stays 0 until Build 6), voucher
purchase and expiry jobs (Build 5), new push plumbing (the notices ride on
`onNotificationCreated`), speaking.

**Acceptance walk (emulator)**

1. The healthy seeded student: header, status Progres Baik, "2 of 3 codes
   passed", four KPIs, a 12-week chart, skill bars, the note, the history
   with a rank "2 of 15" and the level history. Empty blocks show their
   empty states on a brand-new student.
2. Play a practice package as that student: the current week's point and
   the 14-day average move within seconds.
3. Finish a test code as another student: the history row appears with its
   rank and the "tests passed" KPI follows; mark it invalid: the row is
   tagged and the KPI drops.
4. Conclude a class with one izin and one alpa: the attendance percent
   follows hadir ÷ (hadir + alpa).
5. The five shaped students show the right warning chips and labels; the
   teacher dashboard lists them with the two assignment items; the admin
   list filters by level and teacher.
6. Run the daily job by hand on the emulator: the notices land once for
   the roles of the table; run it again: nothing new.
7. A teacher adds a note: the student and the parent see it; a student
   cannot add one; another teacher cannot edit it.
8. Print: the PDF shows Chinese names, the tables and the note.
9. The parent sees the selected child's report and never another child's.
10. Indonesian (dark) and English (light), 1280 px and 360 px. Screenshot
    08 of the proposal list.

**After the build, the owner:** approves `fl_chart`, deploys rules, index
and functions (the BUILD chat gives the command), then hosting, and presses
**Rebuild progress summaries** once in Org settings.

### Build 5 — Voucher packages and self-purchase — done 2026-11-20 (v0.1.23, report in §6)

**Goal.** A student (or the linked parent) buys a voucher package inside the
app: picks a package from the Price list with its Chinese name, ticks the
flyer's terms, pays through Midtrans Snap, and the paid invoice becomes a
term (voucher) by itself. A daily job expires vouchers after their validity.
Proves MT-01 to MT-04 in function tests; MT-05 is the owner's comparison
with the Midtrans sandbox dashboard. Screenshots 05 and 15. Spec:
`docs/THESIS_FEATURE_BACKLOG.md` section 6; owner decision 4 (prices and
terms) and the voucher decision of 2026-10-27 in `CLAUDE.md`.

**What exists.** `settings/pricing.items` (id, name, price, kind, sessions;
flyer defaults in `functions/index.js` and `pricing_settings.dart`) edited on
the admin Price list screen; one `termValidDays` (60) for every item;
`createInvoice` (staff only; derives the amount on the server; creates the
Midtrans Snap transaction with the server key from Secret Manager; sandbox
URL); `midtransNotification` (SHA-512 signature in constant time, status
mapping in `midtransStatusToInvoice`, amount check, one transaction that
flips the invoice and credits the term through `creditPaidInvoice`,
idempotent on a final invoice); `markInvoicePaid` (admin, cash or
transfer); `student_class_terms` (`packageSize`, `sessionsRemaining`,
`sessionsUsed`, `startDate`, `deadlineDate`, `status`, `voucherCode`,
`sourceInvoiceId`); the student and parent Payments tabs ("Pay now" on a
staff-created invoice, `PaymentService.openPayment` opens Snap in a tab); the
admin Invoices tab (sortable, status labels, no filters); `AdminAttentionUtils
.buildVoucherAlerts` (in-app). The sandbox E2E test has never been run
(`docs/CLAUDE_FULL_HANDOFF.md`). **Never** switch to production keys before
it passes (`CLAUDE.md`).

**Defaults taken for the open questions of §5:** the terms to tick are the
four of decision 4 (Q17); the student and the linked parent may buy, staff
keep creating invoices as today (Q18).

**Must**

1. **Price list items** gain `nameChinese` (proposal: 报名费, 8次课程,
   16次课程, HSK教材费), `validDays` (60 for the packages, 0 for one-time
   items) and `active`; the admin Price list screen edits them; the flyer
   defaults carry the Chinese names. `termValidDays` stays as the fallback
   for items without `validDays`.
2. **Buy flow.** The student Payments tab and the parent Payments tab get
   **Beli voucher**: the active session packages as cards (Chinese name,
   name, sessions, validity, price in Rupiah), the four terms of the flyer
   with one tick box ("I agree"), **Bayar** → `createInvoice` → Snap opens
   in a new tab; back in the app the invoice shows as pending with **Pay
   now** until the webhook flips it. One pending self-purchase at a time
   per student (a second **Beli** reuses the open invoice's Snap link).
3. **`createInvoice` opened to students and parents.** A student may
   create an invoice only for their own uid; a parent only for a student in
   their `studentIds`; staff as today. Self-purchases carry
   `acceptedTerms: true`, `termsVersion` (the date of the flyer) and
   `createdByRole`. Everything else stays: server-side amount, Snap call,
   the dangling-invoice cleanup, audit. Pending students (Build 3) are
   refused by `requireCaller`.
4. **Paid → term.** `creditPaidInvoice` uses the item's `validDays`, copies
   `nameChinese` and `priceItemId` onto the term, writes `sessionsBooked: 0`
   (Build 6 counts bookings there) and a ledger entry
   `voucher_history/{invoiceId}_purchase` (`kind: purchase`, +N sessions,
   termId, studentId, date). The cash and transfer path of `markInvoicePaid`
   does the same. Registration and book items credit nothing, as today.
5. **Pure logic** in `functions/payments.js`: `signatureFor(orderId,
   statusCode, grossAmount, serverKey)`, `invoiceStatusFor(transactionStatus,
   fraudStatus)` (moved from `index.js`), `creditDecision(invoice, status,
   grossAmount)` (credit / ignore-final / amount-mismatch / no-credit),
   `expiredTerms(terms, todayKey)`, `termDeadline(startDate, validDays)`;
   `functions/test_payments.js` proves **MT-01** (settlement → paid and one
   credit), **MT-02** (pending stays pending; expire and cancel → no credit),
   **MT-03** (the same notification twice → one credit), **MT-04** (a wrong
   signature → rejected) on the pure functions, and the flow test does the
   same against the emulator by posting signed notifications to the webhook
   (the secret for the emulator lives in `functions/.secret.local`, never
   committed; the Snap call in the emulator goes to a tiny local stub
   started by the flow test, selected by an environment variable the
   function reads only when it runs on the emulator).
6. **Expiry job.** A daily `expireVouchers` at 00:30 Jakarta: active terms
   whose `deadlineDate` has passed become `status: expired` with
   `sessionsForfeited` = remaining, a ledger entry `kind: expiry`, and a
   notice to the student, the linked parent and the admins. The voucher
   reminders (2 sessions left, 7 days to the deadline) are **not** sent
   here: Build 4's daily notices already carry warning 4; this job only
   expires. The in-app `isWithinTermDates` check stays as the display
   guard.
7. **Screens.** Student and parent voucher card: Chinese name, sessions
   remaining, booked (0 until Build 6), deadline with days left, status,
   and the history from `voucher_history` plus the credited attendance as
   today. Admin Invoices tab: filters by status (lunas, menunggu,
   kedaluwarsa, gagal), by item and by month, a "bought in the app" chip,
   and the Rupiah total of the filtered rows (screenshot 15). Admin
   Vouchers tab shows `nameChinese` and the source (bought in the app,
   cash, transfer, added by a teacher).
8. **Rules.** `voucher_history`: read by the student, staff and the linked
   parent; write false. `invoices` unchanged (clients never create or flip
   an invoice; the pending cash invoice by staff stays). `settings/pricing`
   admin write, as today. Rules tests.
9. **Seed and tests.** Seed: the flyer's four items with Chinese names and
   validity; one expired term and one term with 2 sessions left; a paid
   self-purchase with its ledger entry. Tests: `test_payments.js` (Must 5);
   flow test steps: a student buys (stub Snap), the webhook settles it once,
   a second settlement changes nothing, an expire notification on a pending
   invoice gives no term, a wrong signature is refused, a parent buys for
   their child and not for another student, a student cannot buy for
   another uid, the expiry job expires a term once; rules tests; a Flutter
   test of the package card mapping and the terms tick gate.

**Then (if time is left):** a receipt PDF for a paid invoice; the CSV of the
filtered invoices; the leftovers of Builds 2B to 4.

**Not in this build:** production Midtrans keys (blocked until the sandbox
E2E passes); the class day of a voucher and booking (Build 6); refunds;
Snap inside the app (it stays a browser tab); WhatsApp or email receipts.

**Acceptance walk (emulator with the Snap stub, then the sandbox on live by
the owner)**

1. As a student: **Beli voucher**, pick 8次课程, the terms must be ticked
   before **Bayar** is enabled, Snap opens, the invoice shows pending.
2. Post a settlement notification for that order: the invoice is paid, one
   term appears with 8 sessions, the deadline 60 days ahead, the ledger
   entry and the student's notice; post it again: nothing changes (MT-03).
3. A second pending purchase reuses the open invoice.
4. Post an expire notification on a new pending invoice: status expired, no
   term (MT-02). Post a notification with a wrong signature: 403, nothing
   changes (MT-04).
5. As the parent: buy for the child; the term is the child's; buying for
   another uid is refused.
6. Run the expiry job by hand: the seeded past-deadline term is expired with
   its forfeited sessions and the notices; run again: nothing.
7. Admin Invoices: filter by status and month, the total follows; the Price
   list shows and edits the Chinese names and validity.
8. Indonesian (dark) and English (light), 1280 px and 360 px. Screenshots 05
   and 15.

**After the build, the owner:** deploys rules and functions, then hosting;
runs the **sandbox E2E on live** as `student1@` with a Midtrans sandbox test
card (`docs/GO_LIVE_CHECKLIST.md` §4–6), checks the invoice flips to paid
and one term appears, and compares every test payment with the sandbox
dashboard (**MT-05**). The webhook URL is already registered.

### Build 6 — Weekly timetable and booking — done 2026-11-21 (v0.1.24, report in §6)

**Goal.** The centre's weekly timetable lives in the app: repeating
schedules from the flyer (weekday, time, room, teacher, 8 seats, valid
period, level optional), teacher availability and days off, a conflict
check with the reason and free-slot suggestions, a job that creates the
coming two weeks' sessions, and booking through functions that reserve a
voucher session. A voucher's class day books its student by itself. Proves
JD-01, JD-02 and VC-04. Screenshots 02 and 11. Spec: backlog section 4;
owner decisions 5, 6 and 9; §3's note that a slot has no level.

**What exists.** One-off `class_sessions` (teacherId, sessionDate,
sessionTitle, startMinutes, endMinutes, capacity 20, isOpen, isConcluded,
room from `settings/rooms` since Build 3, mode); a student joins by writing
`attendance/{sessionId_uid}` from the app (`joinSession`, rules allow it;
`leaveSession` deletes it); `isSessionFull` counts in the app (can race);
no availability, no overlap check, no reservation on the voucher; the
teacher calendar (`class_calendar_screen.dart`); `users.levels` on teachers
(Build 3); `student_class_terms.sessionsBooked` (Build 5).

**Defaults taken for the open questions of §5:** a schedule's level is
optional and empty means all levels; a student has one fixed weekly slot
through the voucher's class day **and** may book other sessions while they
have sessions left (Q5); capacity 8, minimum gap 15 minutes, weekly
teaching-hours warning at 20 hours (Q19).

**Must**

1. **Schedules** `schedules/{id}`: `className`, `weekday` (1 Monday to 7
   Sunday), `startMinutes`, `endMinutes`, `room` (from `settings/rooms`),
   `teacherId`, `teacherName`, `capacity` (8), `level` ('' = all levels),
   `validFrom`, `validTo`, `active`, `status` (`unconfirmed` until the
   teacher confirms in Build 7), `createdBy`, timestamps. Written only by
   functions (`saveSchedule`, admin) so the conflict check cannot be
   skipped; read by approved users. `settings/scheduling`: `minGapMinutes`
   15, `weeklyHoursWarning` 20, `defaultCapacity` 8, `bookingCutoffMinutes`
   0 (Build 7 may use it), edited on Org settings.
2. **Teacher availability.** `users/{uid}.availability` (per weekday a
   list of `{startMinutes, endMinutes}`) edited by the teacher on the
   profile tab and by the admin on the user form (rules: the teacher may
   change only their own `availability`); `teacher_days_off/{id}`
   (`teacherId`, `date`, `reason`) created by the teacher or the admin.
   Admin **Availability** overview: one table, weekdays as columns, one row
   per teacher, days off listed under it.
3. **Conflict check** as pure logic in `functions/scheduling.js`:
   `validate(schedule, teacher)` (end after start, capacity at least 1,
   level inside the teacher's `levels` when both are set), `insideAvail
   ability`, `overlaps(a, b, gapMinutes)` with `startA < endB && startB <
   endA` widened by the gap, teacher clash against the teacher's other
   schedules on that weekday and their one-off sessions in the valid
   period, room clash against other schedules and sessions in that room,
   `weeklyHours(teacher)` (warning only), `suggestFreeSlots(teacher,
   weekday, length)` (the first 5 free windows inside the availability on
   that weekday, then the other weekdays). The reason text names the
   clashing class and time ("Andrea already teaches Kelas Dasar B on Monday
   15:00–16:30"). `checkScheduleConflict` (callable, admin) returns
   `{ok, reasons[], warnings[], suggestions[]}` for the form as the admin
   types; `saveSchedule` (callable, admin) runs the same check **inside a
   transaction** that reads and bumps `schedule_locks/{teacherId}` and
   `schedule_locks/room_{room}` (version counters), so two admins saving
   the same teacher and time at once end with one schedule (JD-02: the
   second transaction retries, sees the first schedule and is refused).
   The same path runs on edit, on a teacher change and on a replacement
   session (Build 7 reuses it).
4. **Session generation.** `generateSessions` runs every Sunday 20:00
   Jakarta and after every `saveSchedule`: for each active schedule inside
   its valid period, `class_sessions/{scheduleId_yyyyMMdd}` for the next 14
   days (deterministic id, so a second run creates nothing), with
   `scheduleId`, `status: scheduled`, `bookedCount: 0`, `capacity`, `room`,
   `level`, the teacher, `isOpen: true`; on a day off the session is created
   with `status: needs_teacher` and no bookings are accepted until Build 7
   assigns a substitute or cancels it. Editing a schedule updates its
   future sessions that have no bookings yet and flags the others for the
   admin.
5. **Booking.** `bookSession` (callable, student or the linked parent for
   their child, one transaction): the session is `scheduled`, in the
   future, has a seat (`bookedCount < capacity`), the level matches or is
   empty; the student has an active, unexpired term with `remaining −
   booked > 0`; no other booked session overlaps; then it writes
   `attendance/{sessionId_uid}` (`joinedBy: student`, `booked: true`,
   `classTermId`), `bookedCount + 1`, `sessionsBooked + 1` on the term, a
   notice to the student. Refusals carry a reason code (`full`,
   `no_sessions`, `expired`, `overlap`, `too_late`, `needs_teacher`, `level`).
   `cancelBooking` (same callers, before the session starts): deletes the
   attendance doc, `bookedCount − 1`, `sessionsBooked − 1`. The rules stop
   students from creating or deleting `attendance` docs themselves (the
   old `joinSession` / `leaveSession` are removed from the app); staff may
   still add a walk-in with `joinedBy: teacher` (credited only at close,
   Build 7).
6. **A voucher's class day.** A term gets `classDay` = a schedule id,
   chosen at purchase (Build 5's cards show the schedules of the flyer) or
   set by the admin on the voucher form. `generateSessions` books the
   student into each new session of that schedule through the same
   `bookSession` checks (a refusal is logged, not raised); the student may
   cancel one and book another session.
7. **Screens.** Admin **Timetable**: the week as a grid (weekdays across,
   rooms down, each cell the class with teacher, level and seats), a list
   view, **New schedule** form (class name, weekday, time, room, teacher,
   level, capacity, period) that shows the reasons, warnings and the
   suggested free slots as it is filled (screenshot 11), schedule detail
   with its coming sessions and bookings. Student **Sesi Kelas** (replaces
   the join section): the next 14 days, filter "my level" or "all", each
   row with day, time, room, teacher name (information only), seats left,
   **Daftar** or **Batalkan**, and the refusal reason in words
   (screenshot 02). Parent: the same for the selected child. Teacher: the
   week view reads the new sessions (the full Schedule screen with tabs is
   Build 7).
8. **Rules and indexes.** `schedules` read approved users, write false;
   `teacher_days_off` create and delete by the owning teacher or admin,
   read staff; `schedule_locks` nobody; `attendance` create and delete
   closed to students; `class_sessions` read as today, write staff for
   one-off sessions, functions for generated ones (a generated session's
   `scheduleId` cannot be set by a client). Indexes for `class_sessions`
   by `scheduleId` and `sessionDate`, and by `room` and `sessionDate`.
9. **Seed and tests.** Seed: the flyer's timetable (Monday 16:00; Tuesday,
   Wednesday, Friday 15:00 and 16:30; Saturday 10:00, 11:30, 13:00) across
   the four teachers and two rooms, availability for each teacher, one day
   off, generated sessions for two weeks, class days on the seeded terms.
   Tests: `functions/test_scheduling.js` (overlap and gap math, availability,
   level check, suggestions, weekly hours, Jakarta weekday and date
   generation over a valid period, idempotent ids); flow test steps:
   **JD-01** (a teacher clash, a room clash, outside availability and a
   level outside the teacher's levels are each refused with the reason and
   suggestions), **JD-02** (two concurrent `saveSchedule` calls for the
   same teacher and time: one saved), generate twice (no duplicates),
   **VC-04** (book with 0 sessions left refused), a full class refused, an
   overlapping booking refused, book then cancel before start, cancel after
   start refused, the class day books the student on generation, the parent
   books for the child only; rules tests for Must 8.

**Then (if time is left):** an ICS export of a teacher's sessions; a real
calendar view of availability; the leftovers of earlier builds.

**Not in this build:** confirmation, change requests, check-in, attendance,
closing, substitutes, reminders and the recap (Build 7); payments (Build 5).

**Acceptance walk (emulator)**

1. Create the flyer's Monday 16:00 class for Andrea in Main: saved; create
   another at Monday 16:30 for Andrea: refused with the reason and three
   suggestions; in Sub Room with Budi: saved; Andrea on Monday 20:00
   (outside her availability): refused.
2. Two browser tabs save the same teacher and time together: one wins.
3. Generated sessions appear for 14 days with the deterministic ids; run
   the job again: the same count.
4. As a student with 2 sessions left: book two sessions (booked 2, remaining
   unchanged until close), a third is refused ("no sessions left"); a full
   class shows "full"; an overlapping one "clash"; cancel one before it
   starts: booked 1.
5. A term with a class day: after generation the student is booked into
   next week's session by itself; the notice arrives.
6. Admin timetable grid and list, Indonesian (dark) and English (light),
   1280 px and 360 px. Screenshots 02 and 11.

**After the build, the owner:** deploys rules, indexes and functions, then
hosting; enters the real timetable and each teacher's availability; sets
the class day on the active vouchers.

### Build 7 — The teaching day — done 2026-11-21 (v0.1.25, report in §6)

**Goal.** A teacher runs the day from one **Schedule** screen with tabs:
confirms the week, asks for a change, checks in with server time, marks
attendance, and closes the session in one idempotent transaction that
writes the voucher ledger. The admin assigns substitutes, cancels sessions
(bookings return), sees late check-ins and unclosed sessions, and reads a
monthly recap per teacher. Proves VC-01, VC-02, VC-03 and VC-05.
Screenshot 09. Spec: backlog section 5; owner decision 9; the examiners'
condition "voucher deduction in one transaction, idempotent" (§7).

**What exists.** Build 6's schedules, generated sessions and bookings in
`attendance` with `booked: true` and `classTermId`; the conclude dialog
(`conclude_class_dialog.dart`: hadir / izin / alpa per student, credits the
term in the app, not atomic); `ClassSession.isOpen` / `isConcluded`;
`allowTeacherReschedule` in Org settings; `cleanupExpiredLinkCodes` as the
hourly job; `teacher_recaps` not yet; `voucher_history` purchase and expiry
entries (Build 5).

**Defaults taken for the open questions of §5:** a booking may be cancelled
(izin) until the session starts (Q20); the late check-in limit is 15
minutes (Q21).

**Must**

1. **Teacher Schedule screen**, one screen with three tabs (owner decision
   9): **Today** (sessions of the day with status chips `scheduled`,
   `ongoing`, `done`, `cancelled`, `needs_teacher`; the booked students;
   **Mulai sesi**, **Absensi**, **Tutup sesi**), **Week** (the 7 days with
   **Konfirmasi** per schedule and **Ajukan perubahan**), **Availability**
   (Build 6's editor and days off). The teacher calendar screen stays for
   the month view.
2. **Confirmation and change requests.** `confirmSchedule` (teacher, own
   schedule) sets `status: confirmed`; `requestScheduleChange` (teacher)
   writes `schedule_change_requests/{id}` (scheduleId, teacherId, reason,
   wanted change in words, status `open`) and tells the admins; the admin
   resolves it on the schedule detail (edit through `saveSchedule`, or
   decline with a note); the teacher is told. Unconfirmed schedules are
   listed for the admin (the dashboard card is Build 8).
3. **Check-in.** `checkInSession` (teacher of the session or admin): server
   time into `checkInAt`, `status: ongoing`, `lateMinutes` when the check-in
   is more than 15 minutes after the start. A session cannot be checked in
   more than 30 minutes before its start or after its end.
4. **Attendance and close.** The attendance step marks each booked student
   hadir / izin / alpa (and walk-ins added by the teacher); `closeSession`
   (callable, teacher of the session or admin, **one transaction,
   idempotent**): continues only while `status` is `ongoing` (or
   `scheduled` when the admin closes a forgotten one); for hadir and alpa:
   `sessionsBooked − 1`, `sessionsUsed + 1`, `sessionsRemaining − 1` on the
   student's term; for izin: `sessionsBooked − 1` only; one ledger doc
   `voucher_history/{sessionId}_{studentId}` per student with the fixed id
   (`kind: session`, status, −1 or 0), so a second call cannot deduct
   twice; the attendance docs get `attendanceStatus` and `sessionCredited`;
   `status: done`, `closedAt`, `isConcluded: true`; the teacher's month doc
   `teacher_recaps/{teacherId}_{yyyyMM}` gets `held + 1` and the session's
   hours. The progress summary (Build 4) and the notices run from the
   attendance trigger after the transaction. The conclude dialog calls the
   function; the in-app `concludeClassSession` path is removed and the
   rules close attendance status changes to clients.
5. **Substitute and cancel.** The admin Classes calendar lists generated
   sessions too (today it shows one-off sessions only, found in the PLAN
   chat's walk of Build 6). On a session, the admin sees **Substitute
   teacher** with the candidates that are available at that time, can
   teach the level and have no clash (Build 6's check, reused);
   `assignSubstitute` (admin, transaction) sets `teacherId`,
   `substituteFor`, and tells both teachers and the booked students.
   `cancelSession` (admin; the teacher for their own one-off session):
   `status: cancelled`, every booking returned (`sessionsBooked − 1`, the
   attendance docs marked `cancelled`), the students told to pick another
   session. Cancelling a schedule cancels its future sessions the same way.
6. **Jobs.** `sessionReminders` (hourly): one notice per session to the
   teacher and the booked students one hour before the start
   (`reminderSentAt` on the session); `checkTeacherCheckIn` (every 15
   minutes): sessions 15 minutes past their start and still `scheduled` →
   `lateCheckIn: true`, one admin notice; sessions 2 hours past their end
   and not `done` or `cancelled` → `unclosed: true` (the admin's list on
   the sessions tab; the dashboard card is Build 8). The hourly job also
   closes forgotten single attempts of exam-mode packages (the Build 2A
   leftover), through the existing `closeForgottenTestSessions` or next to
   it.
7. **Monthly recap.** Admin **Teacher recap**: month picker, one row per
   teacher (scheduled, held, cancelled, late check-ins, hours; data only,
   no pay), from `teacher_recaps` with a CSV. Pure logic for the counters
   in `functions/teaching_day.js`.
8. **Reconciliation (VC-05).** Admin-only callable `reconcileVouchers`:
   for every term compares `sessionsUsed` with the count of
   `voucher_history` session entries that deducted, and `sessionsBooked`
   with the open bookings; returns the mismatches; a button on Org settings
   shows the result and `tool/reconcile_vouchers.mjs` calls it from the
   command line (emulator or live with a signed-in admin token).
9. **Rules and tests.** `schedule_change_requests` create by the owning
   teacher, read staff, update admin; `teacher_recaps` read staff, write
   false; `attendance` update closed to clients except the staff `notes`;
   `class_sessions` status fields written only by functions. Tests:
   `functions/test_teaching_day.js` (close arithmetic per status, the
   idempotency decision, late rule, reminder window, recap hours); flow
   test steps: **VC-01** (3 hadir, 1 izin, 1 alpa: four terms used + 1, the
   izin term untouched, five ledger docs), **VC-02** (`closeSession` twice:
   deducted once), **VC-03** (close while the same student books another
   session: both succeed, counts right), **VC-05** (reconcile reports no
   mismatch; a hand-broken counter is reported), late check-in flagged
   once, reminder sent once, substitute assigned and told, cancel returns
   bookings; rules tests.

**Then (if time is left):** the class day picker in the buy sheet (Build
6 leftover); a printable day sheet for the teacher; the unconfirmed and
unclosed cards on the admin dashboard (else Build 8).

**Not in this build:** payroll (out of scope by the proposal), the admin
dashboard rework and the monthly centre report (Build 8), online classes.

**Acceptance walk (emulator)**

1. Teacher Week tab: confirm two schedules; ask for a change with a
   reason: the admin sees it and declines with a note; the teacher sees it.
2. Today tab: **Mulai sesi** 20 minutes after the start: the session is
   ongoing and flagged late; the admin got one notice.
3. Attendance 3 hadir, 1 izin, 1 alpa, **Tutup sesi**: the terms follow
   VC-01, the ledger has five docs, the session is done, the recap counts
   it; press **Tutup sesi** again: nothing changes (VC-02).
4. During a close, book another session as one of those students: both
   succeed (VC-03).
5. Substitute: the candidate list leaves out the busy teacher; assign:
   everyone told. Cancel a session with two bookings: both returned, both
   told.
6. Run the hourly job by hand: the reminder lands once; the forgotten
   session is flagged unclosed.
7. Reconcile: no mismatch; break a counter by hand: reported.
8. Indonesian (dark) and English (light), 1280 px and 360 px. Screenshot 09.

**After the build, the owner:** deploys rules and functions, then hosting;
the teachers confirm their schedules; the first real session is closed
through the app and the recap checked.

### Build 8 — Dashboard, trial kit, screenshot pass — done 2026-11-21 (v0.1.26, report in §6)

**Goal.** The admin dashboard of the proposal, the monthly centre report,
automatic checks on GitHub, and the kit for the thesis trial: a seed of 35
respondents, the 731-question checklist, the task sheets of the proposal's
Table 20, the SUS questionnaire with its scoring, and one pass that
produces the 15 proposal screenshots. Screenshots 14 and 15 (15 done in
Build 5). Spec: backlog sections 10 and 13; §7's trial facts; owner
addition 16 (black-box tables, automatic checks on GitHub).

**What exists.** The admin dashboard (totals, sign-ups chart, voucher
alerts, finance) and metrics section; `progress_summary` statuses (Build
4); pending registrations (Build 3); unconfirmed schedules, late check-ins
and unclosed sessions flags (Build 7); `scripts/seed_emulator.py` (1 admin,
4 teachers, 30 students, codes, packages); `docs/THESIS_PROPOSAL_ASSETS.md`
(the 15 screenshots by name); `tool/paper_measure/` (headless Chrome
runner); the paper reader as the import tool for printed papers; no CI.

**Must**

1. **Admin dashboard** rework to the proposal's six cards, each a count
   that opens its list: pending registrations, unconfirmed schedules, late
   check-ins (today and this week), unclosed sessions, students needing
   attention (summaries with status `attention` or `follow_up`), today's
   sessions; the finance and sign-up cards stay below (screenshot 14).
2. **Monthly report.** `monthlyReport` on the 1st at 01:00 Jakarta writes
   `reports/{yyyyMM}`: new students, revenue (paid invoices), active
   students (a booking or a result in the month), level distribution,
   attendance rate, teaching hours per teacher; admin **Reports** screen
   with a month picker, the same numbers, CSV and a PDF; **Rebuild** for a
   past month (admin callable).
3. **Automatic checks on GitHub.** `.github/workflows/checks.yml` on every
   push and pull request: Flutter (pinned version) `pub get`, `analyze`,
   `test`; Node 22 `node --check functions/index.js` and every
   `functions/test_*.js`; the rules tests with the Firebase emulators
   (Java 21). No secrets needed; the paper-reader tests skip without the
   model files. A badge in `README.md`. (The repository is public today;
   Actions run free.)
4. **Trial seed.** `scripts/seed_trial.py` with two modes: `emulator`
   (everything) and `live` (accounts and structures only, never papers):
   1 admin, 4 teachers with levels and availability, 30 students (12
   beginner, 10 intermediate, 8 advanced; Chinese and Latin names from a
   list the owner gives, else placeholders), the rooms, the price list, the
   flyer's timetable, vouchers with class days, and for the emulator the
   seeded sessions, results and bookings that make every dashboard card
   non-empty. Idempotent (fixed ids). The live accounts get passwords from
   a file that is never committed; the owner distributes them.
5. **Question bank checklist.** `docs/TRIAL_KIT.md`: the table of the 731
   questions the trial needs (per level: one practice package of 15, one
   test code in the full format; two more HSK 3 codes), each row with its
   source paper, the import route (paper reader, CSV/JSON import, typed),
   who checks it, and its state; a CSV/JSON import `scripts/import
   _questions.mjs` for the owner's digital questions (bank docs and
   Storage audio; no invented Chinese content; official papers never
   committed), with a dry run that reports what it would write.
6. **Task sheets and SUS.** `docs/trial/` holds the task sheets per role
   from the proposal's Table 20 (student, teacher, admin: numbered tasks
   with the expected result and a pass/fail column), the SUS questionnaire
   (the 10 standard items in Indonesian, 1 to 5), a printable page for
   each (PDF from the docs with the existing `pdf` package or a plain
   print stylesheet), a results sheet template (CSV) and
   `tool/sus_score.mjs` that computes the SUS mean and the per-item
   numbers from the CSV. The black-box table template per build
   (`docs/trial/blackbox_template.md`) with the acceptance walks of §4
   already filled in as rows.
7. **Screenshot pass.** `tool/screenshots/run.mjs`: headless Chrome against
   the emulator bundle (`scripts/run_emulator_web.sh`) with the trial seed,
   signs in per role, navigates to each of the 15 screens, waits for data,
   and saves `docs/screenshots/proposal/NN_name.png` at 1280×800,
   Indonesian, light mode, with the file names of
   `docs/THESIS_PROPOSAL_ASSETS.md`; a Markdown contact sheet lists them.
   Screens the runner cannot reach (the Snap tab) get a written step in the
   same doc.
8. **Tests.** The workflow is green on the commit; the seed runs twice
   without duplicates (checked by a count step in the flow test); the SUS
   script has a node test with a known sheet (mean 72.5 on a sample); the
   dashboard cards have a Flutter test for the count mapping; the monthly
   report's pure logic in `functions/reports.js` has a node test.

**Then (if time is left):** a forgotten exam attempt gets a zero result
in `exercise_results` when the hourly job closes it (today it is closed
with no result, so it never shows in the student's history); the class
day picker in the buy sheet and the printable day sheet (Build 6 and 7
leftovers); a "Trial day" checklist for the admin
(accounts, devices, Wi-Fi, order of tasks); a one-page student guide in
Indonesian; the leftovers of earlier builds.

**Not in this build:** speaking tests, HSK 3.0 levels 5 to 9, iOS native,
a staging project (there is none by decision), the book itself.

**Acceptance walk (emulator)**

1. Seed the trial: every dashboard card shows a count; each opens its list.
2. Rebuild last month's report: the numbers match a hand count of the seed;
   CSV and PDF download.
3. Push a branch: the workflow runs analyze, tests, node and rules tests
   and is green; break a test on purpose: red.
4. Run the screenshot pass: 15 files appear with the right names; open the
   contact sheet.
5. `TRIAL_KIT.md` lists 731 rows with a state each; the import dry run on a
   sample CSV reports the rows and writes nothing; the real run writes the
   bank docs and audio on the emulator.
6. Print the task sheets and the SUS page; score a filled sample CSV.
7. Indonesian (dark) and English (light), 1280 px and 360 px for the new
   screens. Screenshot 14.

**After the build, the owner:** approves the workflow file, runs the trial
seed on live in `live` mode, gives the respondents' names and the trial
dates (§7), and fills the question bank from the checklist.

### After Build 8 — what comes next (PLAN chat, 2026-11-21)

All eight thesis builds are live (v0.1.16 to v0.1.26, 60 functions), two
months ahead of the calendar in §7. **Nothing is marked NEXT**: the owner
chooses the order below and says so in the BUILD chat (code) or here
(docs). Since 2026-11-25 **Build 9** (below) is marked NEXT.

**A. The owner's live tasks, in order** (details in the §1 table)

1. Security: reset the five test passwords in Firebase Authentication and
   decide whether the repository becomes private; the PLAN chat then
   removes the password from the docs.
2. Org settings: **Rebuild progress summaries** once, **Voucher check**
   once.
3. The real timetable, each teacher's availability, the class day on the
   active vouchers; the teachers confirm their schedules; tick **Placement
   code** on one short paper; tell the admin that new students wait on
   Users, **Approval**.
4. The sandbox payment E2E on live (MT-05); production keys stay off until
   it passes.
5. Proofread `H326202Z` and make its truth file; fill the question bank
   from `docs/TRIAL_KIT.md` (731 questions).
6. Laporan bulanan: Hitung ulang once for October and November.
7. Android APK: rebuild on the Mac and publish, or leave it off (§5 Q8).

**B. The trial** (second half of January 2027 in §7's calendar)

- Respondents' names in `scripts/trial/respondents.local.csv` and
  passwords in `scripts/trial/passwords.local.json` (both git-ignored);
  `py -I scripts/seed_trial.py live --credentials <key> --dry-run`, then
  without `--dry-run`; `verify` prints the counts.
- Print `docs/trial/task_sheet_*.html`, `sus_questionnaire.html` and
  `student_guide.html`; follow `docs/trial/TRIAL_DAY.md`.
- Check the task sheets against the proposal's Table 20 when the Word
  file arrives (§7 "Still needed" 2).
- After the trial: `node tool/sus_score.mjs` on the filled
  `sus_results_template.csv`; **Voucher check** (VC-05); the black-box
  tables from `docs/trial/blackbox_template.md`; screens 03 and 11 by hand
  for the book (`docs/screenshots/proposal/CONTACT_SHEET.md`).

**C. Follow-ups the builds left** (small; a BUILD session when the owner
wants them)

- Repository hygiene: done 2026-11-23 (`eebd352`: the `.pyc` file left git,
  `__pycache__/` and `*.pyc` are ignored).
- Done 2026-11-23 (BUILD chat, v0.1.27): the class day picker in the buy
  sheet; the printable teacher day sheet; visitor wrong tokens per browser
  tab before the address; `decideRegistration` reads
  `settings/promotion.minCodes`; `placement_results` visitor details
  cleared after 180 days. Same release, owner requests: timetable gap 0 +
  Timetable rules + Recheck + Delete, sessions start by themselves, late
  students join, quick sign-in delete button, Change password for every
  role.
- The open questions of §5: Q6 (HSK 3.0 papers), Q7 (listening scripts),
  Q8 (APK), Q9 (iOS acceptance), Q12 (reopen a declined recommendation).

**D. The book** (§7): the inputs still needed from the owner (campus guide
and a model book, the proposal's Word file, the centre's facts and photos
of the old tools, the trial dates and devices, the supervisor's dates);
each build's acceptance walk becomes a black-box table; the scenario IDs
(§3) become the functional validation chapter; `docs/screenshots/proposal/`
supplies the figures.

### Build 9 — Paged lists, period reports, leaderboard export, simulation retakes — done 2026-11-26 except part 2 below (v0.1.42 to v0.1.45, reports in §6)

The supervisor looked at the app and the book on 2026-11-25. Four of the
thirteen remarks are about the app (the owner's points 10 to 13); the other
nine are about the book and the seminar (§7). The owner asked the PLAN chat
to plan these four and hand them to the BUILD chat.

**What the supervisor asked, in the owner's words**

- 10: "reports need what we call range date, and pagination, include it in
  every page, so it doesn't bloat the website."
- 11: "Leaderboard can be exported, shared, and every entry needs a
  timestamp."
- 12: "HSK simulation should be able to be tested multiple times."
- 13: "Audit logs also need pagination. Every page that has a long list
  should have pagination and range date. Reports need range date, like from
  March to December."

**What the code does today** (read on `1c45cf0`)

- No list pages through a cursor: `startAfter` appears nowhere in `lib/`,
  `.limit(` nine times, and there is no date-range picker. Lists are streams
  over a whole query, drawn in one `ListView`.
- Audit log: `FirestoreService.watchAuditLogs(limit: 200)`, one list
  (`lib/features/admin/audit_logs_screen.dart`).
- Reports tab (`lib/features/admin/admin_reports_tab.dart`): every card is
  fixed to the current month; the centre report reads one `reports/{yyyyMM}`
  (`monthly_report_card.dart`); twelve PDF exports in
  `AdminExportReport`.
- Leaderboard (`lib/features/tests/leaderboard_screen.dart`): an entry
  already stores `finishedAt` and `seconds`; the row shows the working time
  but no date; no export.
- Packages: `ONE_ATTEMPT = {exam, hsk_simulation}` in
  `functions/exercise_play.js`; the attempt is
  `exercise_attempts/{exerciseId}_{uid}`; a second start is refused ("This
  exam allows one attempt.").
- Test codes: the attempt is `test_attempts/{codeId}_{uid}`; a second
  sitting is refused ("You have already sat this test."); staff can wipe a
  sitting with `resetTestAttempt`. Students see the review after a test, so
  a second sitting of the same paper is easier than the first.

**9A. Paged lists with a date range (points 10 and 13)**

Build three shared pieces once, then use them on every long list.

1. A paging controller (ViewModel) over a Firestore query: page size 25
   (choice of 10 / 25 / 50), `startAfterDocument` cursors, next, previous,
   reload, and the total from the count aggregation, shown as "1–25 of
   312". It reads only the page on screen. Slicing a full download in
   memory does not count: the point is fewer reads and a lighter page.
2. A date range bar: presets (today, 7 days, this month, last month, this
   year, all) and a custom from–to with `showDateRangePicker`. Dates are
   Asia/Jakarta and both ends are included. Default: this month. The choice
   is kept while the page is open.
3. A pager bar: previous, "page n", next, rows per page, the count.

Rules for using them:

- A list that can pass 25 rows gets the pager. A list ordered by a date
  also gets the date range bar. Lists that are small by nature stay as they
  are (rooms, price list, the week calendar, a level checklist, the six
  duty cards, the today lists on the dashboards).
- A paged list is fetched, not streamed. It reloads after the page's own
  writes and has a refresh button.
- Search must still find a row that is not on the current page. Where a
  page has a search box, make the search a query (for names: a stored
  lower-case field with a prefix query, back-filled once), not a filter
  over the visible page.
- An export (CSV or PDF) follows the chosen date range, not the visible
  page. It reads the range in batches, with a ceiling of 5,000 rows and a
  message when the ceiling is reached.
- Every new (filter, date order) pair needs its composite index in
  `firestore.indexes.json`. Queries must keep the limits the rules already
  demand (a teacher's own students, a student's own rows).

Pages. The BUILD chat first lists every screen that draws a collection
query and puts the table in its report (screen, collection, order field,
pager yes/no, date range yes/no). Expected at least:

- Admin: Users (each role chip and Approval), Payments, Vouchers and
  voucher history, **Audit log** (date range and an action filter), News,
  Timetable follow-up, Teacher recap, test codes, test results, sessions
  list, decided promotions, marking queue, question bank (worksheets and
  questions), exercise packages, placement results, the bell list.
- Teacher: students, marking queue, exercise results, test sessions and
  results, packages, own question bank.
- Student and parent: History, exercise results, test results, payments,
  the bell list.

**9B. Reports over a period (points 10 and 13)**

- The Reports tab gets one period bar for the whole tab: from month to
  month (for example March 2026 to December 2026), with presets this
  month, last 3 months, this year. Default: this month, so the tab opens as
  it does today.
- The centre report merges the `reports/{yyyyMM}` documents of the period:
  counts and money are summed, rates are recomputed from summed numerators
  and denominators (never an average of percentages), end-of-period
  figures (active students, open vouchers) come from the last month. It
  shows one line per month, a total line, and the chart per month. If
  `buildReport` does not store a numerator or denominator that the merge
  needs, add it and rebuild the old months with `rebuildMonthlyReport`.
- A month in the period with no report shows "not built" with the rebuild
  button; it is not silently counted as zero.
- The other report cards and their twelve exports follow the same period
  wherever their data has a date. Every PDF and CSV prints the period in
  its header ("Periode: Maret 2026 – Desember 2026").
- The merge is a pure function with tests: the merge of three months
  equals one build over the same three months for every summed figure.

**9C. Leaderboard: time stamp, export, share (point 11)**

- Every row shows when the result was finished (`finishedAt`, Jakarta
  time, date and hour) next to the working time. If old entries lack the
  field, rebuild them from `test_results` (one admin callable or a
  script).
- Export, staff only (admin; a teacher for the codes they may see): CSV
  and PDF with rank, name (staff format), marks per part, total, passed,
  finished at; the header carries the code, the paper level, and the time
  of the export. Use the `pdf` and `printing` packages already in
  `pubspec.yaml`.
- Share: staff share the PDF through the device share sheet
  (`Printing.sharePdf`; on the web this is a download). A student gets
  **Share my result**: a card with their own rank, their own name, marks,
  date and the code. It carries no other student's name.
- Not built: a public link to a board. It would need public read access to
  student names.
- The board itself is paged (25 per page) and keeps the student's own row
  visible.
- `/privacy` must stay true: add the sentence about staff exports if the
  policy lists what staff can take out of the app.

**9D. HSK simulation can be sat again (point 12)**

Packages (build now):

- A package of type HSK Simulation (and old Exam sheets) is no longer one
  attempt. Each start is a new attempt with its own server clock. Only one
  attempt can be open at a time; coming back resumes it. When it is
  finished or its time is over, the start screen offers a new attempt and
  lists the earlier ones (date, total, marks per part).
- `exercise_results` carries `attemptNo`; the result card says which
  attempt it is. A late attempt is still 0, as today.
- The progress summary keeps counting every final result (the Build 4
  rule). No change there.

Test codes (**owner's answer 2026-11-26, given in the BUILD chat: "First
sitting counts"**; being built after session 1):

- Recommended rule: a student may sit the same code again, but only in a
  **new session** opened by staff. Sittings are numbered. **The first
  valid sitting is the one that counts** for the leaderboard, the
  promotion count and a placement recommendation; later sittings are kept
  with their result card and marked as repeats in the student's and the
  staff's lists. Reason: the student has seen the review, so a repeat is
  practice, not a measurement.
- The other possible rule is "best sitting counts". It is simpler to
  explain but lets a student pass a paper by repeating it, which weakens
  the promotion rule of the proposal (three different codes).
- `resetTestAttempt` stays for a broken sitting and removes only that
  sitting. Visitor placement stays one sitting per result code.

**Must list**

1. The three shared pieces exist once and are used by every page below; no
   page has its own copy of paging code.
2. Audit log: pager, date range, action filter; opening the page reads 25
   documents, not 200 (shown with the network panel or the emulator's
   request log).
3. Payments, Users, History and the marking queue are paged; search on
   Users finds a student who is not on the first page.
4. Reports tab: the period March to December gives one line per month and
   a total; the PDF prints the period; the merge test passes.
5. Leaderboard rows show date and hour; CSV and PDF export work for admin
   and teacher; a student sees **Share my result** and no export of the
   board.
6. A student finishes an HSK Simulation package, starts it again, and both
   results are in the history with attempt numbers; an open attempt is
   resumed, not doubled.
7. Emulator seed: enough rows to see page 2 on the audit log, Payments and
   a leaderboard (`scripts/seed_emulator.py` or the trial seed).
8. Tests: analyzer baseline unchanged; `flutter test`, the node suites and
   the rules tests pass; `test_exercise_play.js` covers the second
   attempt; the supervised flow test still passes, with new steps when the
   test-code part is built.

**Then list**

- Roll the pager out to every remaining screen of the inventory.
- The test-code part of 9D, after the owner's answer.
- Indonesian and English strings for every new label.

**Size and order.** More than one session. Session 1: the shared pieces,
Audit log, Reports period, the leaderboard (9C) and package retakes: these
are the four things the supervisor named. Session 2: the rest of the
inventory. Indexes and functions deploy from the PC as usual; say in the
report whether rules changed.

**One favour for the book** (five minutes, PC only): open
`docs/thesis/word/BUKU TA Easy Study.docx` with Word (COM automation is
fine), refresh the fields, and report the total page count and the page on
which each BAB, the Daftar Pustaka and the Riwayat Hidup start. The
supervisor set a limit of 100 to 120 pages and the Mac has no Word.

### Build 9, part 2 — the heavy lists — done 2026-11-26 (v0.1.46, report in §6)

Build 9's Must list and part 1 of its Then list are live (v0.1.42 to
v0.1.45): every page the supervisor named is paged. What is left are the
screens that stream whole collections to work out counts and statistics.
A pager alone does not help them; each needs its numbers from a count, a
sum or a stored summary. The BUILD chat that built Build 9 asked for a
fresh session for this part, because its context was long.

**Screens** (from the inventory in the §6 report of v0.1.42 and the note of
v0.1.45)

- Teacher **Students** tab: reads six full collections today. Read the
  teacher's own students a page at a time; take each row's numbers from
  `progress_summary` instead of raw results.
- **Exercise packages** (admin and teacher): streams every result and
  assignment to show counts per package. Use count aggregations per package
  on the page, or a counter kept by a trigger if the reads are too many.
- **Question bank**: streams the whole bank. Page by worksheet; open a
  worksheet's questions only when it is opened.
- Staff **History timeline** (`student_activity.dart`), teacher **Grades**,
  **Transcript**, Timetable **Follow-up**, the dashboard drill-downs: pager
  and date range with the shared pieces, reading only the page.

**Must list**

1. No screen in the list starts a stream over a whole collection. Show it
   with the emulator's request log or the network panel for the three
   biggest: Students, Exercise packages, Question bank.
2. Counts and averages on those screens equal what they showed before, on
   the emulator seed.
3. Only the shared paging pieces are used; no screen has its own copy.
4. Tests and the analyzer baseline as before; new indexes in
   `firestore.indexes.json`; say in the report whether a function or a rule
   changed.

**Then list:** anything of the inventory still streaming after this; a
note in the report of what stays unpaged on purpose and why.

### After the thesis builds — extras for the centre

Speaking tests (HSKK, YCT oral: answers recorded in the browser, marked by a
teacher), final HSK 3.0 formats for levels 5 to 9, YCT timing.

Builds 5 to 8 are written in full (2026-11-21, while Build 4 was being
built). The PLAN chat re-reads each one against the report of the build
before it and adjusts it before marking it NEXT.

---

## 5. Questions still open

Settled by Build 2B (shipped 2026-11-20 with these defaults; the owner
still tells the supervisor):

1. The proposal says students see other students on the leaderboard as
   "first name + initial" (scenario LB-01). The app shows the Chinese name
   (owner decision 8). The book states the change.
2. The proposal lets teachers add and edit questions in the bank. Teachers
   now add and edit their own questions; scanning stays with the admin.
3. Reading of decision 12, to confirm: "teacher code" is the 6-character
   token of the session a teacher opens (new every time, valid 15 minutes),
   not the teacher's permanent invite code; the token in the room is enough
   and no test is assigned to named students beforehand; the review opens
   when the teacher closes the session, so answers cannot travel during it.

Build 3 was built with the answers in bold (2026-11-20); say so if one is
wrong and it becomes a follow-up:

4. Public placement: does the visitor type name and WhatsApp before the test
   (**yes**), and see marks at once without the review (**yes**)?
10. Registration: the teacher link code becomes **optional** and the admin
    sets the teacher on the Approval screen (the proposal: students do not
    choose teachers). Keep the code required instead?
11. A student who chose the placement test is **approved at HSK 1 first**;
    the placement result then moves them through the Promotion screen
    (one more admin tap). Or should approval wait until the test is sat?
12. A declined promotion recommendation stays declined for that level today
    (the BUILD chat asked). Plan: it **reopens after one more passed code**.
    Agreed? **Owner 2026-11-24: the admin may simply promote a capable
    student** (built: Promotion → Promote a student / Promote anyway).

Before Build 4 (Build 4 is written with the answers in bold; say so if one
is wrong):

13. Practice for the chart and the averages = **every package result**
    (exercise, quiz, exam and HSK simulation packages); supervised test
    codes are "tests". Should exam-mode packages be left out of practice?
14. The "teacher note" of the report is a **new follow-up note** (teachers
    add one from the report; the latest is shown); the Evaluations tab
    stays as it is. Or should the latest evaluation comment be the note?
15. Warning notices go out **once a day at 07:00 Jakarta, at most once per
    7 days** per student and warning, not on every change. Agreed?
16. Attendance percent = **hadir ÷ (hadir + alpa)**; izin (excused before
    class) is left out, as it is for the voucher. Agreed?

Before Build 5 (written with the answers in bold):

17. The terms the buyer ticks are the four of decision 4 (**a term not
    finished in 2 months is forfeited; sessions cannot move to another
    student; payment in full before the first class; no refunds**). Any
    other line from the flyer?
18. **The student and the linked parent may buy** in the app; staff keep
    creating invoices as today. Agreed?

Before Build 6 (written with the answers in bold):

5. The proposal gives every weekly schedule one HSK level; the flyer says
   classes mix levels. Plan: level optional ("all levels"). Does every
   student have one fixed weekly slot, or pick a slot each week? **Both:
   the voucher's class day books the fixed slot by itself, and the student
   may book other sessions while sessions are left.**
19. Defaults: **capacity 8 seats, minimum gap 15 minutes between a
    teacher's classes, a warning above 20 teaching hours a week**. Change
    any?

Before Build 7 (written with the answers in bold):

20. A booking may be cancelled, or marked izin, **until the session
    starts**; after that it counts as alpa unless the teacher marks izin
    at close. Agreed?
21. **Late check-in = more than 15 minutes after the start** (the
    proposal). Agreed?

Before Build 8: the trial names, devices and dates (§7 "Still needed").

Any time:

6. HSK 3.0 papers for levels 5, 6 and 7–9, and the marks per part if a paper
   or its answer sheet prints them. **Owner 2026-11-24: leave it.**
7. Do the papers come with an official listening script? With it the
   transcript is pasted or scanned; without it someone types it from the
   recording. **Owner 2026-11-24: generate it** (BUILD chat: speech
   recognition in the browser from the worksheet's recording).
8. Android APK: rebuild and publish it now, or with the Build 2A deploy?
   **Owner 2026-11-24: rebuild it** (the release keystore is on the Mac).
9. iOS: the proposal promises Android, iOS and web. Today iOS means Safari
   with "add to home screen". Ask the supervisor whether that is accepted.
   **Owner 2026-11-24: wants iOS, asked for a specification** →
   `docs/IOS_SPEC.md`. **Then chose option B, an App Store app**; the code is
   ready (icon, iOS settings, account deletion, privacy policy,
   `scripts/build_ios.sh`); the owner's steps are in `docs/IOS_SPEC.md`.

## 6. Build reports (newest first, written by the BUILD chat)

### 2026-11-26 — Build 9, part 2 (the heavy lists) — 95fa704, release v0.1.46 (rules, 55 indexes, functions and hosting)

- **Done (Must 1–4):** the teacher Students tab, both dashboards' drill-downs,
  exercise packages, the question bank (and the worksheet screen), the staff
  History timeline, teacher Grades, the transcript and Timetable follow-up
  read a page at a time; none starts a stream over a whole collection.
  Upcoming classes read from today on only.
- **How the numbers are kept:** `progress_summary.roster` (functions,
  `progress.rosterOf`, same rules as TeacherStatsUtils /
  TeacherAttentionUtils) gives each student's homework, practice average,
  sessions left, lessons, last activity and attention reasons; the refresh
  stamps every assignment `done` / `bestScore`, so package counts and the
  homework lists are queries. The bank reads a new `bank_sheets` index (one
  doc per worksheet or stand-alone question); packages carry `listAt`,
  `listCategory`, `listSkill`, `searchPrefixes`. Shared pieces only:
  `MergedPageSource`, `FilteredPageSource`, `MappedPageSource` were added to
  `lib/core/paging/` and every screen uses them with `PagedController`,
  `DateRangeBar`, `PagerBar`, `PagedListBody`.
- **Must 1, reads on opening (emulator seed, same queries as the app):**
  Students 224 documents streamed before → 26 users + 25 summaries (+3
  lessons) now; packages 121 → 5 packages + their 15 assignments; bank 28
  questions → 6 worksheet rows. The gap grows with real data (the old
  screens grew with every result ever written).
- **Must 2, same numbers:** a script recomputed every student's row from the
  raw collections with the old rules and compared it with the roster: 29 of
  29 equal. Homework overview 3 done / 10 to do / 2 overdue = the old 20 % and
  2; the package "HSK 1 Reading" 3/6 with 2 late; bank sheet counts sum to the
  28 questions; Timetable follow-up gives the same single session.
  Differences on purpose: the Students list leaves out the 2 registrations
  still waiting (they are under Approval: 29 instead of 31); column sorting
  orders the page on screen; package counts include assignments of switched-off
  students; bank and package search finds the beginning of a word of the title
  or code (or of a question's text), not any substring.
- **Must 4:** analyzer 16 infos; `flutter test` 209 pass (2 skipped); node
  suites pass, new `functions/test_list_index.js`, `test_progress.js` covers
  the roster and the stamp; Firestore rules tests pass with a new
  `bank_sheets` test (the 2 Storage tests fail only when run against the
  shared dev emulator; CI runs them on their own). **Functions changed:** 5
  new (`onAssignmentWritten`, `onLessonProgressWritten`,
  `onQuestionBankIndexed`, `onExerciseListIndex`, `rebuildListIndexes`; 82 on
  live), `refreshProgressSummary` and `onUserSearchIndex` extended. **Rules
  changed:** `bank_sheets` staff read, no client write. 55 composite indexes.
- **Owner after the deploy (once):** Org settings → **Rebuild list indexes**,
  then **Rebuild progress summaries**. Until then older packages and
  worksheets are missing from those two lists (an admin banner on both says
  so, with the button) and Students rows show dashes.
- **Still streaming, left on purpose or for later (Then list):** the teacher
  dashboard tab itself (its cohort cards still stream the six collections;
  next step: compute them from the summaries), the student picker in the
  grade form, the package form's "From bank" picker, the test-code form and
  the bank imports' duplicate check (they read the whole bank once, as an
  action, not a list). Small by nature and left as they are: rooms, price
  list, holidays, schedules, level paths, unconfirmed schedules.

### 2026-11-26 — Build 9 Then list, part 1 — release v0.1.45 (hosting + 8 indexes)

- **Paged now:** News, test sessions, staff and student test results,
  declined promotions, student exercise results, admin Vouchers (search as
  a bounded query); the bell reads the newest 30 notices of each kind.
- **Part 2 (next BUILD session):** teacher Grades, transcript, the staff
  History timeline (`student_activity.dart`), the teacher's Students tab
  (streams 6 full collections), exercise packages (streams all results and
  assignments), the question bank (streams the whole bank), Timetable
  follow-up, dashboard drill-downs. These are the heavy screens; each needs
  its own data change (counts or summaries instead of full streams), not
  only a pager.
- Checked: flutter test 204, analyzer 16 infos, emulator walk of Vouchers,
  test results, News. No function or rules change.

### 2026-11-26 — Build 9, session 2 (Must 3: Payments, Users, marking queue, History) — release v0.1.44

- **Done:** Must 3. Payments (range, status and item as queries, count and
  total by aggregation, CSV of the range), Users (role, status and search
  as queries through a per-account search index; Approval reads only the
  registrations and teachers), marking queue (range, opens on all dates),
  student and parent History (visits paged in a range, vouchers read their
  classes when opened). Shared pieces only; no page has its own paging code.
- **Owner after the deploy:** Users → the red banner's **Rebuild user
  search** button (or Org settings) once, and Org settings → **Rebuild
  leaderboards** once if not done yet.
- **Checked:** emulator walk of the four screens; flutter test 204; node
  suites; analyzer 16 infos. Deployed indexes (10 new), functions (77) and
  hosting. Rules unchanged.
- **Left from the inventory (Then list), for a later session:** Vouchers,
  News, Timetable follow-up, test sessions and test results lists,
  declined promotions, question bank, exercise packages, teacher Students
  and Grades, student exercise results and test results, transcript, the
  bell list, the staff History timeline, dashboard drill-downs.

### 2026-11-26 — Build 9D test-code retakes (owner: "Keep in Tests", "First sitting counts") — release v0.1.43

- A student sits a code again only in a **new session** (new token); the
  same session refuses ("already-attempted"). Sitting n>1 lives at
  `{codeId}_{uid}_s{n}`; sitting 1 keeps its ids and `latestSitting`.
- The first valid sitting counts for the board, the promotion count and
  placement; repeats carry `counts: false` and show "Sitting n · practice".
  Invalid first → the next valid one counts; pending first still counts.
- Reset works on the latest sitting only; the review opens per sitting.
- Checked: promotion pure tests, supervised flow 110 steps (2 new:
  sitting 2 through a new session with the board unchanged and both
  reviews, reset rules), flutter test 202. Deployed functions + hosting.
  Rules and indexes unchanged.
- Still open in Build 9: session 2 (the rest of the inventory, §6 table
  below).

### 2026-11-26 — Build 9, session 1 (9A shared pieces + audit log, 9B, 9C, 9D packages) — release v0.1.42

**Done.** Must 1 (shared pieces, used by the audit log, the leaderboard and
the Reports tab), 2, 4, 5, 6 (for exam packages, see question 1), 7 (seed
for the audit log and a board), 8 (tests). Must 3 (Payments, Users, History,
marking queue) is session 2 with the rest of the inventory below.

Checked on the emulator: audit log "1–25 of 47", page 2 "26–47 of 47", 26
documents read per page; Reports with the month bar and a "Not built" month;
leaderboard H3BOARD as admin (ranks 1,1,3,3,…, rank 25 shared across the page
break, CSV / PDF / Share PDF) and as student27 (Chinese names only, own place
pinned at rank 27, Share my result, no export); exam package as student1:
attempt 1 (50 %), start screen "Attempt 1 · 50 %", **Start attempt 2** with a
fresh 10-minute clock, then both attempts listed and **Start attempt 3**.

Deployed: functions (75), the audit index, hosting. Rules unchanged.
Owner: Org settings → **Rebuild leaderboards** once (old board rows get
their `rankKey`; until then a board is ranked from one read, correct but not
paged).

**Questions for the owner (through the PLAN chat):**
1. **HSK Simulation packages.** Owner decision 2026-11-16 (§ decisions, item
   5) makes `startExercise` refuse HSK Simulation packages: simulations run
   only as test codes. So "sit an HSK simulation again" reaches students
   only through the test-code part of 9D, which waits for the owner. The
   package retakes are built for every timed package and work today for exam
   packages. Options: (a) keep simulations in Tests only and build the
   test-code retakes (PLAN's recommended rule: first valid sitting counts);
   (b) also allow HSK Simulation packages as timed practice with retakes (one
   line in `startExercise`/`finishExercise` and the package form). I
   recommend (a), and (b) only if the owner wants practice runs outside the
   supervised sessions.
   **Owner answer 2026-11-26: (a) "Keep in Tests".** HSK Simulation
   packages stay refused; the test-code retakes are next, after the rule.
2. Test-code retakes (rule) — still waiting, as planned.

**Inventory for session 2** (screens that draw a collection; from the code
at `ad86562`). "Client" = the whole collection is streamed and sorted or
filtered in the browser today.

| Role | Screen | Collection | Order today | Pager | Date range |
|---|---|---|---|---|---|
| admin | Users (role chips, Approval) | users | client by name | yes | createdAt |
| admin | Approval (reads all users) | users (status) | client | yes (use `watchRegistrations`) | createdAt |
| admin | Payments (invoices) | invoices | client createdAt | yes | createdAt |
| admin | Vouchers | student_class_terms | client | yes | createdAt |
| admin | **Audit log** | audit_logs | createdAt desc | **done** | **done** |
| admin | News | announcements | createdAt desc, limit 40 | yes | createdAt |
| admin | Timetable follow-up | schedule_change_requests + all class_sessions | client | yes | createdAt / sessionDate |
| admin/teacher | Test codes | test_codes | client | no (small) | — |
| admin/teacher | Test sessions | test_sessions (openedBy) | client | yes | createdAt |
| admin/teacher | Test results | test_results (openedBy) | client | yes | finishedAt |
| admin | Promotions (declined) | level_promotions | createdAt desc, limit 20 | yes | createdAt |
| admin/teacher | Marking queue | marking_items | createdAt desc, limit 200 | yes | createdAt |
| admin/teacher | Question bank (whole bank) | question_bank | createdAt desc | yes, per worksheet | createdAt |
| admin/teacher | Exercise packages (+ all results, assignments) | exercises | client | yes | createdAt |
| admin/teacher | Leaderboard | leaderboards/…/entries | rankKey | **done** | — |
| teacher | Students (6 full collections) | users + 5 | client | yes | — |
| teacher | Grades | grades | createdAt desc | yes | createdAt |
| teacher/admin | Attendance calendar | class_sessions | sessionDate | by month already | sessionDate |
| teacher/admin | Student activity timeline | attendance, results, invoices | client, "show more" | yes | per kind |
| student | Progress (exercise results) | exercise_results | client | yes | submittedAt |
| student/parent | Transcript | grades, results, quiz, evaluations | client | yes | createdAt |
| student | Tests (results) | test_results | client | yes | finishedAt |
| student | Class history | attendance | client | yes | sessionDate |
| student/parent | Payments | invoices | client | yes | createdAt |
| all | Bell list | notifications (2 queries) | client, take 12 | yes | createdAt |

Small by nature, left as they are: rooms, price list, settings, formats,
levels, level paths, holidays, days off, schedules, week calendar, duty
cards, one session's attendance, lessons, placement menu, paper drafts.
Indexes missing today for session 2: notifications, test results/sessions
(openedBy/studentId + time), voucher_history, student_class_terms,
schedule_change_requests, users (role + name).

### 2026-11-25 — Recheck of v0.1.38–v0.1.40, four fixes — COMMIT, release v0.1.41 (hosting only)
- Checked: CI green on every push; analyzer 17 infos; `flutter test` 186
  pass; all node tests; rules tests 86 pass + 1 skipped; live
  `main.dart.js` = build, OCR script = repo, APK / privacy / OCR model 200,
  74 functions.
- Fixed (from an independent review): review numbering with two blocks,
  one blank count everywhere, digits in a blanks key line, essay line
  breaks in the result review.
- **For the PLAN chat (the PC session could not reach it on 2026-11-25):**
  please review v0.1.39, v0.1.40 and v0.1.41 on the Mac, update the §1
  Live line (still says v0.1.38), and take these recommendations, most
  urgent first:
  1. **Security, owner action, open since 2026-11-17.** The repository is
     still public and `docs/CLAUDE_FULL_HANDOFF.md` and
     `docs/FIREBASE_BACKEND.md` still show the live test accounts'
     password. Ask the owner to reset the passwords of `admin@`,
     `teacher@`, `student1-3@test.chinesetracker` in Firebase
     Authentication first (git history keeps the old one, so removing it
     from the docs alone is not enough), then decide private or public;
     then remove the password from the docs.
  2. **Owner live walk of the Standard Course scanner:** Scan paper with
     Bab 1 on live, correct the lesson text, mark the answers (choices,
     word order, characters, review blanks), save, upload `01.mp3.mpeg`,
     make a package, play it as `student1@`. Note the minutes; that is the
     first real use.
  3. **Decision for the owner: points of 组词 (make words).** They are
     saved as free writing: 10 points each against 1 for every other
     question, and every Standard Course result stays `pending_marking`
     until a teacher marks them. Options: (a) keep; (b) 2 points each,
     still teacher-marked; (c) leave them out of the worksheet.
     Recommendation: (b), a small BUILD item (a `points` field on the
     bank item, read by `pointsOf`).
  4. **Small BUILD items, one session together:** the lesson text in the
     test-code player (only practice packages show it); the package editor
     checks the recording of HSK / Standard Course sheets as the worksheet
     screen does; Scan paper hands the already-read pages to the worksheet
     reader instead of reading a scanned worksheet twice.
  5. **Still open from §4 "After Build 8" A:** MT-05 sandbox payment,
     Rebuild progress summaries and Voucher check once, the real
     timetable, H326202Z truth file. None of these changed; the trial in
     January needs 1, 2 and 4 of that list.

### 2026-11-25 — Fill in the blanks for the Standard Course review — COMMIT, release v0.1.40 (functions and hosting)
- Review questions take one answer per blank (proofreading, answer key,
  editor) and are checked blank by blank; checked on the emulator.

### 2026-11-25 — Standard Course scanner — COMMIT, release v0.1.39 (functions and hosting)
- Built: Scan paper reads a Standard Course lesson (textbook + workbook)
  into one Standard Course worksheet; block forms from the instruction
  lines; open answers to teacher marking; lesson text for students.
- Proof: analyzer 17 infos; `flutter test` 182 pass; node tests green; HSK
  practice paper 79 of 80; owner's Bab 1 end to end on the emulator.
- Left: the test-code player does not show the lesson text; OCR misses a
  few blanks (flagged for proofreading).

### 2026-11-24 — Scan paper falls back to the worksheet reader — COMMIT, release v0.1.38 (hosting only)
- A PDF that is not an HSK paper goes to the worksheet reader instead of
  "No questions were found". Checked on the emulator with 210001 and 210002.

### 2026-11-24 — Recordings saved as .mpeg accepted — COMMIT, release v0.1.37 (hosting only)
- The audio picker accepts `.mpeg` and other common audio endings; the
  owner's 42 MB H326202Z recording uploaded and played on the emulator.

### 2026-11-24 — Standard Course name, Exam hidden, recording required, remove test codes — COMMIT, release v0.1.36 (rules and hosting)
- Built: Exam hidden from pickers; "Standard Course"; question type HSK /
  Standard Course; listening recording required before a test code or an
  assignment; Remove on test codes (delete if unused, else hide).
- Proof: analyzer 17 infos; `flutter test` 174 pass.
- Left: the package editor does not check the recording; the UI was not
  walked in the browser this round.

### 2026-11-24 — Answer key box pre-filled — COMMIT, release v0.1.35 (hosting only)
- The Answer key dialog opens with the worksheet's current key; the text
  reads back to the same answers. `flutter test` 171 pass; analyzer 17 infos.

### 2026-11-24 — Word-order and character answers, HSK Standard Course, recording preview — COMMIT, release v0.1.34 (hosting only)
- Built: tap-to-order answer for word order; character answer for pinyin
  questions; new Type of exercise **HSK Standard Course** (practice);
  Play button for a worksheet's recording.
- Proof: analyzer 17 infos; `flutter test` 170 pass; node tests pass;
  emulator: a 69 s recording uploaded and played on the worksheet screen.
- Left: the scan screen with the new fields was not walked in the browser
  this round (unit tests cover keeping and saving the answers).

### 2026-11-24 — Scan drafts and answers, shuffled choices, level checklists — 3f1519a, release v0.1.33 (rules, storage rules, functions and hosting live from the PC; 74 functions)
- Built: clock fix; scan drafts (save, list, reopen without reading),
  answers marked while proofreading (choice rows with a tick, the paper's
  matching layout, picture and true/false letters), the proofreading
  screen over the whole window, a clear save-error dialog; shuffled
  text choices; level checklists that replace the code count.
- Owner answers (AskUserQuestion): shuffle the choice order; the checklist
  replaces the codes; exercises and test codes; the save showed an error.
- Proof: analyzer 17 infos; `flutter test` 168 pass; node tests pass
  (level checklist); rules tests; flow test 108 steps (new: a level
  checklist recommends the next level); emulator walk: two full scans of
  the practice paper (save to the bank, draft save and reopen, the
  matching layout, the leave dialog).
- Left: the owner's exact save error on live (not reproduced; the new
  dialog shows it).

### 2026-11-24 — Profiles, waiting list, discard pop-up everywhere — 6d65b92, release v0.1.32 (rules, functions and hosting live from the PC; 72 functions)
- Built the three recommendations the owner accepted: teacher and parent
  profile pages (every Users row opens a profile); the discard pop-up on
  create user, one-off class, voucher and price item; a waiting list for
  full classes that books the first one waiting when a seat opens.
- Proof: analyzer 17 infos; `flutter test` 165 pass; node tests pass
  (waiting-list rule); rules tests 85 pass and 1 skipped; flow test 107
  steps (new: a cancelled seat goes to the first one waiting).

### 2026-11-24 — Owner requests, fourth round — e3abac3, release v0.1.31 (functions and hosting live from the PC; 69 functions)
- Built: paper reader preview shows drawn boxes + page thumbnails;
  "Discard your changes?" on nine editors; Mixed skill section; discarded
  invoices with reason and restore (`discardInvoice`); optional News end
  date and holiday open/close notices; dashboard clock, next-class
  countdown and latest news; compact class cards opening a class page;
  student page with profile card, photo and tabs including History.
- Proof: analyzer 17 infos; `flutter test` 165 pass; node tests pass
  (discarded invoices); flow test 106 steps (new: reopened holiday notice,
  discard and restore an invoice); emulator walk of the dashboard, class
  page, student page, discarding an invoice.
- Left: the owner's Apple steps (`docs/IOS_SPEC.md`).

### 2026-11-24 — Ready for the App Store (Q9 option B) — 3169334, release v0.1.30 (functions and hosting live from the PC; 68 functions)
- Built: app icon from the mascot (iOS and Android); iOS name, iPhone only,
  iOS 15, Podfile, permission texts; **Delete my account** for students and
  parents (`deleteMyAccount`, shared `deleteAccountCore`); public privacy
  policy `/privacy`; `scripts/build_ios.sh`; owner step list in
  `docs/IOS_SPEC.md`.
- Choices: push notifications stay off on iOS for the first version (the
  app's push code is web and Android only; an APNs key would be needed);
  iPhone only so no iPad screenshots or iPad review; payments stay sandbox
  until MT-05.
- Proof: analyzer 17 infos; `flutter test` 162 pass; flow test 104 steps
  (new: a student deletes their own account, staff cannot, records stay);
  emulator walk of the privacy page and deleting student29 from the
  profile tab.
- Left: everything on the owner's list (Apple account, Xcode, signing,
  upload); the APK needs a rebuild on the Mac for the new icon.

### 2026-11-24 — Owner requests, third round — d04d962 + Q7 commit, release v0.1.29 (functions and hosting live from the PC under the owner's standing go; 67 functions)
- Built: admin **News** page (post, edit, delete, audience, end date,
  optional bell notice through `onAnnouncementCreated`); calmer admin
  dashboard (Today card, four numbers, chart beside alerts, More figures
  folded); cancelled classes hidden on the calendar; **Promote a student**
  and **Promote anyway** (`promoteStudent`, Q12); `docs/IOS_SPEC.md` (Q9).
- Owner answers: Q6 leave it; Q7 generate the listening script; Q8 rebuild
  the APK; Q9 wants iOS, specify it; Q12 the admin may just promote.
- Q7 built in the same release: **Write from the recording** in the
  worksheet's Transcript dialog (Whisper small in the browser,
  `web/transcribe_whisper.js`, files from `scripts/fetch_whisper.mjs`);
  a 69-second HSK-style test dialogue was written in 32 seconds with one
  character wrong.
- Left: Q8 needs the Mac (the release keystore is not on the PC); Q9 waits for the
  owner's choice between the installed web app and an App Store app.
- Proof: analyzer 17 infos; `flutter test` 162 pass and 2 skipped; node
  tests pass (manual promotion); flow test 103 steps; emulator walk of the
  dashboard, News (post with notice), the Promotion dialog and the student
  banner.

### 2026-11-23 — Owner requests, second round — 545ef58, release v0.1.28 (rules, functions and hosting live from the PC under the owner's standing go; 65 functions)
- Built: Timetable rules dialog; teacher readiness switch (default off;
  recap, availability, confirmation, late check-in hidden); helper teachers
  (`coTeacherIds`); minimum students (job, 3 hours before, off until set);
  Indonesian holidays (`holidays_id.js`, `importHolidays`), closing and
  opening a day (`setDayClosed`), announcements with home banners and the
  calendar; attendance-board compare at close; class-day picker removed from
  the buy sheet.
- Owner answers (AskUserQuestion): "multiple teachers" = one class, 2+
  teachers; recap/availability/confirmation hidden behind one switch, kept
  for the thesis; small classes close 3 hours before; board = compare
  screen.
- Choices: the minimum rule ships off on live (0) so classes without
  bookings are not cancelled before the centre uses bookings; announcements
  of a closed day are written in the admin's language; holiday dates are
  copied from the government page, never typed from memory.
- Proof: analyzer 17 infos; `flutter test` 160 pass and 2 skipped; node
  tests pass (new cases for helpers, the minimum rule, the holiday list);
  rules tests 84 pass and 1 skipped; flow test 101 steps; emulator walk of
  the rules dialog, the schedule form, Holidays & news, closing a day and the
  student banner.
- Left: the open questions Q6–Q9 and Q12.

### 2026-11-23 — Owner requests and the After-Build-8 follow-ups — 242e287, release v0.1.27 (functions and hosting live from the PC under the owner's standing go; 63 functions)
- Built: timetable gap 0 by default with **Timetable rules**, **Recheck**,
  **Delete** (`deleteSchedule`); sessions start by themselves (app,
  `closeSession`, the 5-minute job); late students join until the end;
  quick sign-in delete button; **Change password** for every role; the
  class-day picker in the buy sheet and class-day booking by trigger; the
  printable day sheet; visitor wrong tokens per tab; `minCodes` at
  approval; placement result retention (180 days).
- Choices: the teacher check-in stays (arrival and the late flag) but no
  longer starts the class; booking closes at the end of the class, the
  booking cut-off setting is gone; deleting a schedule leaves a class that
  has already started today alone; the day sheet keeps English labels with
  hadir / izin / alpa, like the other exports.
- Proof: analyzer 17 infos; `flutter test` 156 pass and 2 skipped; node
  tests pass (new cases in `test_scheduling.js`, `test_teaching_day.js`,
  `test_placement.js`); flow test 97 steps (new: late join, auto start,
  back-to-back and gap, delete schedule, class-day booking, minCodes,
  placement clean-up); rules unchanged.
- Left: the open questions Q6–Q9 and Q12 (owner decisions).

### 2026-11-21 — Build 8 Dashboard, trial kit, screenshot pass — 2b1d798 + a2575ff, release v0.1.26 (rules, functions and hosting live from the PC 2026-11-21 under the owner's standing go; 60 functions)
- Built: six duty cards on the admin dashboard; `functions/reports.js` +
  `test_reports.js`, `monthlyReport`, `rebuildMonthlyReport`, the Laporan
  bulanan card (CSV, PDF); `.github/workflows/checks.yml`; the trial seed
  (emulator / live / verify); `scripts/import_questions.mjs`; the trial kit
  docs and printables; `tool/sus_score.mjs`; `tool/screenshots/run.mjs`;
  zero results for forgotten exam attempts.
- Must list: 1 dashboard · 2 monthly report · 3 GitHub checks · 4 trial
  seed · 5 question checklist and import · 6 task sheets and SUS · 7
  screenshot pass · 8 tests. All done, with these limits: the runner saves
  13 of 15 screens (03 needs an answered practice question, 11 a typed
  schedule form: written steps in the contact sheet); the task sheets
  follow the proposal's screens and scenario IDs and still need a check
  against its Table 20 (the Word file has not arrived).
- Choices: live mode writes through firebase-admin with a service-account
  file the owner downloads (never committed); its 30 vouchers carry
  `trial: true` and no invoice, and the price list is written only when
  none exists; the black-box tables are generated from the acceptance
  walks so they follow the plan; respondents' names stay in a git-ignored
  CSV.
- Acceptance walk: the trial seed ran twice with the same counts; every
  dashboard card shows a count on the emulator (2 pending, 10 unconfirmed,
  1 late today / 2 this week, 1 unclosed, 26 needing attention, 4 today);
  the flow test rebuilds the month and checks the revenue against the paid
  invoices; the workflow ran on the `ci-check` branch: Node and rules jobs
  green, the Flutter job red on the PDFium test until it learned to skip,
  then green on main (a2575ff: Flutter, Node and rules jobs all pass); the screenshot pass saved the 13 files; the import dry run
  reported 4 questions and wrote nothing, the real run wrote them with the
  audio on the emulator; the SUS sample scores 72.5.
- Proof: analyzer 17 infos; `flutter test` 152 pass (+2) and 2 skipped;
  rules tests 81 pass (+1), 1 skipped; node tests pass (+ `test_reports.js`,
  `tool/test_sus_score.mjs`, `tool/test_import_questions.mjs`); flow test
  91/91.
- Owner: the workflow is on main and green (Actions tab; the badge is in README.md); when the respondents are known, put the names in `scripts/trial/respondents.local.csv` and the passwords in `scripts/trial/passwords.local.json`, download a service-account key from the Firebase console (outside the repo), run `py -I scripts/seed_trial.py live --credentials <key> --dry-run`, then without `--dry-run`; fill the question bank from `docs/TRIAL_KIT.md`; press Laporan → Laporan bulanan → Hitung ulang once for October and November.
- Left out ("Then"): the class day picker in the buy sheet and the
  printable day sheet. Done from "Then": the forgotten-attempt zero result,
  the trial-day checklist, the one-page student guide.

### 2026-11-21 — Build 7 The teaching day — e2aabdb, release v0.1.25 (rules, functions and hosting live from the PC 2026-11-21 under the owner's standing go; 58 functions)
- Built: `functions/teaching_day.js` + `test_teaching_day.js`;
  `checkInSession`, `closeSession` (one transaction, ledger, recap),
  `confirmSchedule`, `requestScheduleChange`, `resolveScheduleChange`,
  `substituteCandidates`, `assignSubstitute`, `cancelSession`,
  `teacherRecap`, `reconcileVouchers`, `runTeachingDayPass`, the jobs
  `sessionReminders` and `checkTeacherCheckIn`; rules; teacher Schedule
  screen; admin Follow-up and Teacher recap on the Timetable; Voucher check
  on Org settings; `tool/reconcile_vouchers.mjs`.
- Must list: 1 Schedule screen · 2 confirm and change requests · 3
  check-in · 4 attendance and close · 5 substitute, cancel, the admin
  calendar lists generated sessions · 6 jobs (with the forgotten exam
  attempts) · 7 recap · 8 reconciliation · 9 rules and tests. All done.
- Choices: a teacher's own one-off session (not from the timetable) may
  be closed without a check-in, so the old Classes flow keeps working;
  walk-ins without a booking are charged from the oldest usable voucher;
  a student with no usable voucher gets a ledger doc with 0 and
  `noVoucher: true` and is listed in the result; the change request is
  "done" after the admin edits the schedule with the normal form; a
  forgotten exam attempt is closed with no score.
- Acceptance walk: the flow test covers check-in (another teacher and a
  student refused, server time, late), VC-01 with VC-03 (3 hadir, 1 izin,
  1 alpa while one of them books another session: both succeed, counts
  right, five ledger docs), VC-02 (second close: nothing), VC-05 (no
  mismatch; a broken counter reported), reminder once, late flag once
  with one admin notice, unclosed after 2 hours, substitute (the busy
  teacher left out; everyone told), cancel (two bookings returned,
  both told, a second cancel returns nothing), confirm and a declined
  change request, the recap, a forgotten exam attempt. The new screens were walked on the emulator at 1280 px and 360 px: the teacher Schedule (Today changed live from Terjadwal to Berlangsung · Terlambat 20 mnt while the flow test checked in), the admin Follow-up and Teacher recap, and the admin Classes calendar listing timetable sessions with Mulai sesi / Guru pengganti / Batalkan sesi.
- Proof: analyzer 17 infos; `flutter test` 150 pass (+4) and 2 skipped;
  rules tests 80 pass (+3), 1 skipped; node tests pass (+
  `test_teaching_day.js`); flow test 89/89.
- Owner: the teachers confirm their schedules on Schedule → Week; close the first real session through the app and look at Timetable → Teacher recap; press Org settings → **Voucher check** once (older vouchers are measured from their first close).
- Left out: the "Then" items (printable day sheet, the class day picker in
  the buy sheet; the dashboard cards are Build 8).

### 2026-11-21 — Build 6 Weekly timetable and booking — 0343ef7, release v0.1.24 (rules, indexes, functions and hosting live from the PC 2026-11-21 under the owner's standing go; 45 functions)
- Built: `functions/scheduling.js` + `test_scheduling.js`;
  `checkScheduleConflict`, `saveSchedule` (locks), `generateSessions`
  (scheduled and after saves), `bookSession`, `cancelBooking`; rules,
  three indexes; admin Timetable (grid, list, availability, live form),
  student and parent booking lists, teacher availability and days off,
  the voucher form's class day.
- Must list: 1 schedules + settings · 2 availability and days off · 3
  conflict check with locks · 4 generation · 5 booking · 6 class day · 7
  screens · 8 rules and indexes · 9 seed and tests. All done; the class
  day is set on the voucher form (edit), not yet chosen in the buy sheet.
- Acceptance walk: the flow test covers JD-01 (teacher clash with the
  class named and suggestions, room clash, outside availability, level),
  JD-02 (two concurrent saves, one schedule), generation twice with the
  same count, VC-04 (two bookings, the third refused "no_sessions"), full,
  overlap, needs_teacher, cancel before and after the start, the class day
  booking, the parent and the student refused for another uid. The new
  screens were not walked by hand in this build (the browser pane was
  small); analyzer and the Flutter tests pass.
- Proof: analyzer 17 infos; `flutter test` 146 pass (+2) and 2 skipped;
  rules tests 77 pass, 1 skipped (+4); node tests pass (+
  `test_scheduling.js`); flow test 78/78 (+8).
- Owner: deployed (5 functions created, 45 on live, 3 indexes, rules, hosting). The owner enters the real timetable (admin Classes → Timetable), each teacher's availability (teacher profile), and the class day on active vouchers (voucher form). Old one-off sessions keep working; students now book only through Daftar.
- Left out: the "Then" items (ICS export, calendar view of availability);
  the class day in the buy sheet.

### 2026-11-20 — Build 5 Voucher packages and self-purchase — a2be4f3, release v0.1.23 (rules, functions and hosting live from the PC 2026-11-20 under the owner's standing go; 40 functions)
- Built: Price list `nameChinese` / `validDays` / `active`; the buy sheet
  and the voucher cards with history on the student and parent Payments
  tabs; `createInvoice` for students and linked parents (terms, one open
  purchase reused); validity, Chinese name, `sessionsBooked`, source and a
  `voucher_history` purchase entry on every paid voucher (Midtrans, cash,
  transfer); `functions/payments.js` + `test_payments.js`; the daily
  `expireVouchers`; admin Invoices filters with total and the in-app tag;
  Vouchers tab Chinese name and source; rules for `voucher_history`.
- Must list: 1 Price list fields · 2 buy flow · 3 createInvoice for
  students and parents · 4 paid → term with ledger · 5 pure logic with
  MT-01..04 · 6 expiry job · 7 screens · 8 rules · 9 seed and tests. All
  done.
- Acceptance walk (emulator): 1 the buy sheet lists 8次课程 and 16次课程
  with validity and price, the four terms, Pay disabled until a package and
  the tick; 2–6 (settlement once, MT-03 repeat, reuse of the open invoice,
  MT-02 pending / expire, MT-04 wrong signature 403, a parent buying for
  the child and refused for another student, a student refused for another
  uid, the expiry job once) run in the flow test against the emulator with
  the Snap stub; 7 the admin Invoices tab filters by status, item and month
  with "5 invoices · Rp 15.250.000" and the in-app tag; the Price list
  dialog edits the Chinese name, validity and "sold in the app". Not walked
  by hand: the parent tab and 360 px for these screens.
- Proof: analyzer 0 errors / 0 warnings / 17 infos; `flutter test` 144
  pass (+4) and 2 skipped; rules tests 73 pass, 1 skipped (+2); node tests
  pass (+ `test_payments.js`, MT-01 to MT-04); flow test 70/70 (+8).
- Owner: deployed (1 function created, 40 on live, rules, hosting). Then the **sandbox E2E on live** as `student1@` with a
  Midtrans sandbox test card (`docs/GO_LIVE_CHECKLIST.md` §4–6) and MT-05
  (compare with the sandbox dashboard). Production keys stay off.
- Left out and why: the "Then" items (receipt PDF, invoice CSV of the
  filter is the existing Export CSV of the visible rows).
- Note: staff-made invoices get the Chinese name and validity from the
  Price list row at payment time (`withPriceItem`).

### 2026-11-20 — Build 4 Progress report — 3ca62ff, release v0.1.22 (rules, indexes, functions and hosting live from the PC 2026-11-20 under the owner's standing go; 39 functions)
- Built: `progress_summary/{uid}` kept by `refreshProgressSummary` (pure
  logic, ISO weeks in Jakarta time, the five warnings, the status label and
  `noticesDue` in `functions/progress.js`); triggers on `exercise_results`,
  `attendance`, `student_class_terms`, `progress_notes` and the existing
  test-result trigger; refresh after approvals; the daily pass in
  `dailyReminders` with notices to the spec's roles once per 7 days;
  `progress_notes` with rules; `rebuildProgressSummaries` (admin) behind a
  button on Org settings; the report widget (header, status, codes bar,
  four KPIs, `fl_chart` 12-week line chart, skill bars, note with Add /
  Edit, warnings, test history with rank and tags, attendance, level
  history, Print report) on the student Progress tab, the parent's first
  tab and the staff student page; attention lists on the teacher dashboard
  and the admin metrics (level and teacher filters); the PDF from the same
  summary; `progress` notices; two indexes.
- Must list: 1 summary doc + pure module · 2 the five warnings with
  boundary tests · 3 refresh helper + triggers, never failing the write ·
  4 daily pass + notices once per 7 days · 5 rules for summary and notes ·
  6 report screen in every place · 7 attention lists (inactive and low
  sessions moved to warnings 3 and 4) · 8 PDF · 9 rebuild, seed, tests ·
  10 `progress` notification routes. All done.
- Acceptance walk (emulator): the healthy student13 in Indonesian, dark, 1280 px:
  status "Progres Baik", the codes bar, four KPIs (attendance 100%,
  practice 84 with +6, tests 3, voucher 9 sessions / 40 days), the 12-week
  chart, skill bars, the teacher's note, the history with "rank 9 of 15",
  attendance chips, the level history's empty state. At 360 px (light) the
  KPIs fit two per row; the segment labels wrapped, fixed by hiding the
  segment icons below 480 px. Admin dashboard: "Students needing attention
  (27)" with level and teacher filters, status and warning chips. The
  rest (a new practice result moving the summary, a test row with its
  rank, notes for the student and the parent and refused for others, a
  student refused on another summary, notices once and not again, the
  rebuild admin-only) runs in the flow test. Not walked by hand: the PDF
  print dialog, the teacher dashboard list, the parent tab.
- Proof: analyzer 0 errors / 0 warnings / 17 infos; `flutter test` 140
  pass (+5) and 2 skipped; rules tests 71 pass, 1 skipped (+3); node tests
  pass (+ `test_progress.js`); flow test 62/62 (+6).
- Owner: `fl_chart` approved in chat; deploys are pre-approved ("all auto build, also all is automatically confirmed"). Deployed: 5 functions created (39 on live), 2 indexes, rules, hosting. **Still to do by the owner:** sign in as admin on live → Org settings → **Rebuild progress summaries** once (it needs an admin sign-in, which Claude does not do on live).
- Left out and why: the "Then" items (period filter and CSV on the admin
  list, Builds 2B / 3 leftovers). The parent's old overview content
  (stat cards) is replaced by the report, which covers it.
- Notes for the PLAN chat:
  - Warning 1 counts when at least 4 marked records (hadir, izin or alpa)
    exist in 30 days; the percent leaves izin out.
  - Students who never practised count from their approval date (or the
    account's creation for older accounts), so most old seed accounts
    carry warning 3 until they practise.

### 2026-11-20 — Build 3 Registration approval, placement tests, rooms — 41543cc, release v0.1.21 (rules, indexes, functions and then hosting live from the PC 2026-11-20 at the owner's go; 34 functions)
- Built: pending accounts (`status: 'pending'`, rules, `/waiting`), the
  register form's start-level choice with a live result-code check, the
  admin **Approval** section and page with `decideRegistration`, placement
  sessions (`placement: true` on sessions, attempts and results) with
  `level_promotions/{uid}_placement` on the Promotion screen, placement
  codes and the public visitor path (`placementMenu`, `startPlacement`,
  `submitPlacementPart`, `reportPlacementEvent`, `resolvePlacementResult`,
  `registrationPlacement`, `placement_results`, pages `/placement*`, the
  landing section, visitor rows and QR on supervision), `settings/rooms`
  with the room picker, teacher `levels`, registration notices. Pure logic
  in `functions/placement.js`.
- Must list: 1 pending accounts + choice + optional link code · 2 rules
  (`statusApproved`, `isApprovedUser`, self-update locks, create shape) ·
  3 waiting page · 4 Approval + `decideRegistration` (claimed once, audit,
  reject then approve) · 5 placement sessions + recommendation rule +
  Promotion chip + Tests tab card · 6 placement codes + `placementMenu` ·
  7 visitor functions (key hash, throttles, finish by close / hourly job) ·
  8 public pages + landing section + QR · 9 rooms + teacher levels · 10
  `registration` notices + test · 11 seed + tests. All done.
- Acceptance walk (emulator, 2026-11-20):
  1. Registered `walk1@` with "Mulai dari HSK 1" and no link code: the
     waiting page opened; `/student` sent back to `/waiting`. Approval page
     listed it; approved with Andrea at HSK 1 ("approved at HSK 1"). Pass.
  2. PL-01 and the failed case run in the flow test (approve at HSK 1,
     placement session on `H3DEMO1`, pass → "HSK 1 → HSK 4" waits, approve:
     level HSK 4, history `placement`, no board row, 0 of 3 toward HSK 5;
     fail → HSK 3). The Promotion screen shows the cards with the
     Placement chip and "Placement paper not passed". Pass.
  3. Visitor at 400 px: `/placement?token=…` (from the QR link) prefilled
     the token, the menu showed "HSK 1 · 4 min · 6 questions"; start screen
     with the Placement chip and "no review" rule; a reload resumed part 1
     with the answer and the clock; the network reply had no `correctIndex`;
     two parts → 100 / 33, 133 of 200, passed, HSK 2, code shown with Copy
     and Daftar sekarang; the register form opened with the code, Check
     showed "HSK 1 paper: 133 of 200 · Passed · HSK 2" and filled the
     target level. Supervision showed "Visitor · Visitor Walk · Left the
     page: 1 · finished". Claimed-once runs in the flow test. Pass.
  4. Reject with a reason, then approve: flow test. Pass.
  5. Wrong tokens, wrong key, a visitor calling `startTest` /
     `getTestReview`, a student reading `placement_results`: flow and rules
     tests. Pass.
  6. Org settings Rooms: Main, Sub Room; added "Room 3"; the class form's
     picker lists all three. Andrea's user form shows HSK 1–3 ticked. Pass.
  7. Indonesian light at 360 px: the result page fits (the app-bar title
     is cut with "…"); English dark at 1280 px for the admin screens.
     Not walked: the waiting page in Indonesian and the Approval page at
     360 px.
- Fixed during the walk: the Approval page's top bar said "Student" (it
  matched `/users/:id`); it now says "Registrations to approve".
- Proof: analyzer 0 errors / 0 warnings / 17 infos; `flutter test` 135
  pass (+8) and 2 skipped; rules tests 68 pass, 1 skipped (+6); node tests
  pass (+ `test_placement.js`); flow test 56/56 (+15).
- Deployed 2026-11-20 at the owner's go: rules, indexes and functions
  (7 created, 34 on live), then hosting right after. Checked on live: the
  bundle carries `/placement` and `/admin/users/approval`, `placementMenu`
  answers without sign-in (no placement code yet).
- Owner must: (1) Open Org settings once
  (writes `settings/rooms`). (3) Tick **Placement code** on one short
  paper's code. (4) Tell the admin that new students now wait on Users →
  Approval.
- Left out and why: the "Then" items (§5 Q12 reopen after a decline, the
  Build 2B leftovers, a WhatsApp link on the Approval card). Staff have no
  list of visitor results yet (they see them on supervision and through a
  result code on the Approval card). Testing two tabs in one browser: a
  reload in one tab signs the other out in the emulator bundle (the
  emulator guard); a visitor on their own phone is not affected.
- Notes for the PLAN chat:
  - A placement session on an ordinary code (PL-01 on `H3DEMO1`) is for
    signed-in students only; visitors join only a placement code's session
    (`visitorsAllowed` on the session decides the QR link).
  - Answers a teacher would mark (free writing) count as zero for a
    visitor: placement papers should be choice and typing only.

### 2026-11-20 — Build 2B Leaderboard, promotion, names — 4ee0f42, release v0.1.20 (hosting, rules, indexes and functions live from the PC 2026-11-20 at the owner's go)
- Built: the `onTestResultWritten` trigger with pure logic in
  `functions/promotion.js`; `leaderboards/{codeId}/entries/{uid}`;
  `promotion_progress/{uid}`; `level_promotions/{uid_levelKey}`;
  `decidePromotion`; the Leaderboard screen (student and staff), the admin
  Promotion screen with a badge and the minimum-codes setting, the progress
  card and ranks on the student Tests tab; the two name labels everywhere;
  teachers in the bank; rules, index, tests.
- Must list: 1 trigger + pure module + node test pass · 2 leaderboard (peer
  label stored, rules: staff, or a student with a result for that code)
  pass · 3 leaderboard screens pass · 4 promotion count, `settings/promotion`
  `minCodes`, withdraw on invalid / reset, no next level after HSK 6 pass ·
  5 Promotion screen, Approve (level, history, student + parent told,
  audit), Decline with a reason, level groups pass · 6 `users.level`
  admin-only in the rules and gone from the student form, rules test pass ·
  7 Tests tab "2 of 3" and rank per result pass · 8 names pass, with one gap
  (below) · 9 teachers type, paste, edit and delete their own bank
  questions, rules + `.claude/rules/exercise-authoring-web-only.md` pass ·
  10 tests pass: LV-01 (170 / 195 / 200 / 205 → recommend HSK 4), LV-03,
  LB-01 (15 people against a hand ranking) in `functions/test_promotion.js`;
  the flow test walks marking, invalid / valid, reset, LV-03, LV-01,
  Approve, Decline.
- **Acceptance on the emulators:**
  1. A third passed code: the recommendation appears live on the Promotion
     screen and the badge counts it; Approve moved student11 to HSK 4,
     wrote `level_history` (HSK 3 → HSK 4, intermediate), restarted the
     count at HSK 4 ("next HSK 5", 0). Pass.
  2. Two passes and one fail: "HSK 3 · Intermediate, 2 of 3 codes passed,
     toward HSK 4", no recommendation. Pass.
  3. Invalid leaves the board and the count at once, valid brings both
     back; a pending result is on no board until marked; a reset takes the
     result off (flow test). Pass.
  4. A student opens the board of a code they sat (own row framed, ties
     share rank 2, next rank 4) and is refused ("Not open for you") on a
     code they have not sat. Pass.
  5. Names: student sees Chinese names; admin board and Promotion card show
     `陈美琳 (Kelvin Santoso)`. Pass. Teacher bank: covered by rules tests
     (own question edited, another's refused) and the gates in the code;
     not clicked through in the browser.
  6. Decline: the dialog stays open without a reason; with one, "Ditolak."
     and the student's card says "Not moved up to HSK 4 yet. Your teacher
     will talk with you about the next step." Pass.
  7. Indonesian (dark) and English (light), 1280 px and 360 px: the board
     cut long staff labels at 360 px (now 2 lines); otherwise no overflow.
     Pass.
- Fixed during the walk: the admin "Promotion to check" notice opened the
  Classes tab (unknown kind read as a class notice); student test notices
  pointed at `/student/tests`, which is not a route (also the Build 2A
  "Marked" notice, live since 2A): now the kind `promotion` exists and both
  open the Tests tab (`test/notification_routes_test.dart`). A declined
  recommendation left the student's card on "waiting for the admin"
  forever: `promotion_progress.decision` now says `declined`.
- Proof: analyzer 0 errors / 0 warnings / 17 infos; `flutter test` 127 pass
  (+9) and 2 skipped; rules tests 62 pass, 1 skipped (+5); node tests pass
  (+ `test_promotion.js`); flow test 41/41 (+9).
- Deployed: with the owner's yes, the BUILD chat ran
  `firebase deploy --only firestore:rules,firestore:indexes,functions --project chinese-tracker`
  on 2026-11-20 (rules, indexes, `onTestResultWritten` and `decidePromotion`
  created: 27 functions on live). Hosting was deployed before that
  (`scripts/deploy_web.sh --web-only --no-keys`). Results written before the
  deploy reach a board and the count only when they next change.
- Left out and why: the "Then" items (2A leftovers, a CSV of a leaderboard)
  are not started. Classmates on attendance lists see the first Latin word,
  not the Chinese name: attendance stores only the Latin name.
- Notes for the PLAN chat:
  - **Question:** a declined recommendation stays declined for that level;
    passing more codes at the same level makes no new one. Should a new
    passed code (or a number of them) reopen it?
  - A student can read their own `level_promotions` doc (rules), so the
    decline reason is not secret from a curious student; the app does not
    show it.
  - The staff label on the leaderboard is read from `users` with a
    `role == student` query in chunks of 30 (teachers may only read
    students).

### 2026-11-18 — Build 1C Reader accuracy — b38a4f9, release v0.1.19 (hosting live from the PC 2026-11-18; functions deployed from the PC 2026-11-19 at the owner's go, 25 updated)
- Built: PP-OCRv5 mobile recognition in the browser (`web/paper_ocr_paddle.js`,
  model files fetched into `web/ocr/` by `scripts/fetch_paper_ocr.mjs`, not
  in git) behind `BrowserPaperOcrEngine`, Tesseract as fallback; practice
  paper `H399001P` + truth; measuring tools; Download text; level and mark
  flags; tone buttons; proofreading record; a picture-box fix; test
  marking items for the student's own teacher; indexes file = live.
- **Must 2, measured before building** (Tesseract finds the lines in a, b
  and c; the structure builder of Build 1B reads the texts; "right as read"
  = form, text, choices, pieces and pinyin equal to the truth, spaces and
  Western punctuation ignored; picture questions count by form in this
  text-only run):

  | Engine on the practice paper `H399001P` (13 pages) | Right as read | Flagged | Wrong, not flagged | Time |
  |---|---|---|---|---|
  | Build 1B (Tesseract `chi_sim+eng`, page mode 6) | 37 | 36 | 17 | 13 s |
  | Tesseract `chi_sim` only | 28 | 39 | 23 | 10 s |
  | a. Tesseract + character positions | 41 | 33 | 17 | 14 s |
  | b. each line read alone (page mode 7) | 52 | 17 | 22 | 25 s |
  | c. PP-OCRv5 mobile (first try) | 51 | 16 | 24 | 29 s |
  | c. + answer brackets and lone punctuation by shape (the winner) | **79** | 24 | **1** | 28 s |

  The practice paper is a fair stand-in: Build 1B read it as badly as the
  real paper (37 of 80 both). Candidate c's files: model 16.5 MB + runtime
  14.8 MB (over the 25 MB aim; the owner approved shipping it 2026-11-18).
  On the real paper `H326202Z` (no truth file yet: flag counts only):
  Build 1B 3 missing, 46 text questions flagged; c **0 missing, 20 flagged**
  (the 10 picture questions not counted), 41 s. My own reading of c's
  result (not a measure): about 64 of 80 right as read; every error a rule
  can see is flagged; 2 are not (a lost 一, and 已 for 己).
- Must list: 1a practice paper + truth pass · 1b Download text pass ·
  1 measure page (`tool/paper_measure`, `test/paper_measure_test.dart`;
  Compare with a truth file in the emulator bundle) pass · 2 measure pass ·
  3 winner built pass · 4 flag by level pass (old HSK 1-3 lists; papers above
  HSK 3 are not checked, there is no list) · 5 pinyin tones pass · 6 record
  pass · 7 indexes file pass · 8 marking items pass (node + rules + flow).
- **Acceptance on the emulators (in the app, Scan paper):**
  1. Practice paper: **78 of 80 right as read, 1 wrong and not flagged**,
     read in **52 s** (13 pages, first model load included). Pass.
  2. Real paper: 16 pages in **70-75 s**, 40/30/10, 0 missing, 6 + 5
     pictures, 19 to check. Pass on time; right-as-read waits for the
     owner's truth file.
  3. Pinyin of 76-80 read with tone marks; the saved practice worksheet
     exported `guān`; tone buttons and `chang2` → `cháng` work. Pass.
  4. Proofreading record on the worksheet screen ("80 soal · 15 ditandai
     pembaca · 0 diubah admin … Dibaca oleh PaddleOCR dalam 52 dtk"). Pass.
  5. Indonesian and English, dark, 1280 px and 360 px (proofreading screen,
     worksheet screen): no overflow after the helper text fix. Pass.
- Fixed during the walk: the picture finder took three closely set text
  lines for a picture (now a picture needs a shape taller than a line);
  "form differs from its block" on a picture question (the block check now
  runs after the pictures are known); the pinyin helper text was cut.
- Proof: analyzer 0 errors / 0 warnings / 17 infos; `flutter test` 118 pass
  (+13) and 2 measuring tests that run with files; rules tests 57 pass, 1
  skipped (+1); node tests pass; flow test 32/32.
- Owner must: (1) functions deploy for Must 8:
  `firebase deploy --only functions --project chinese-tracker`; (2) hosting
  (the BUILD chat runs it from the PC: `scripts/deploy_web.sh --web-only
  --no-keys`); (3) on live: Scan paper with `H326202Z`, proofread, save,
  then **Download text** on the worksheet and put the file on the PC as
  `local_papers/H326202Z.truth.json`: that gives the real right-as-read.
- Left out and why: nothing of the Must list. Not measured: a weak laptop
  or a phone (only this PC).
- Notes for the PLAN chat:
  - PaddleOCR reads the characters very well; the remaining work was the
    layout (brackets, lone punctuation). New paper layouts may need the
    same kind of shape rules.
  - The level list flags names, places and some everyday words outside the
    old HSK 3 list (留, 窗户): expected, the admin presses Looks right.
  - The scan dialog's time note now says about 5 s per page for Scan paper
    and about 45 MB for its first download.

### 2026-11-17 — Build 2A Typing matcher and marking — bc6057a, release v0.1.18 (hosting live 2026-11-17; Storage rules, Firestore rules, indexes and functions deployed from the PC on 2026-11-17 at the owner's request, 25 functions)
- Built: typing matcher (`functions/typing_matcher.js`, `functions/pinyin.js`)
  used by the scoring that packages and tests share; types `type_pinyin`
  and `essay`; points instead of right/wrong; the `marking_items` queue,
  `markAnswer`, the **Penilaian / Marking** screen; pending results; the
  Build 1 follow-ups; the PN-01 script.
- Must list: 1 follow-ups pass (password `emulator-only-7` in seed, flow
  test and app; End test sends the open part and waits 15 s; hourly
  `closeForgottenTestSessions`; Reset attempt with audit; QR on the
  supervision screen; Build 1 screens walked, see below) · 2 matcher pass ·
  3 free writing pass (10 points, required words, source text with a timer
  in the player) · 4 marking pass · 5 PN-01 tool pass · 6 tests pass.
- Then list: not done (hourly job for single attempts, item analysis).
- **Acceptance on the emulators:**
  1. Package: full-width comma, trailing "！" and traditional characters are
     full marks (node test PN-02 and flow step); in the browser, one
     homophone (`和` for `喝`) showed "half marks for now; your teacher will
     check it" and appeared in the teacher's queue. Pass.
  2. `ni3 hao3` and `nǐ hǎo` full (node test PN-03, flow); `ni hao` typed in
     the browser: half, flagged. Pass.
  3. Two words swapped in sentence building: zero, not in the queue (browser
     and flow). Pass.
  4. Teacher: kept the half on one, full marks on the other; the package
     result went from 33% to 50% and the student got "Marked … 50%". Pass.
  5. `H3ESSAY` in a supervised session: card 100 / 100 / 9, 209, 待评分
     "Waiting for marking", no pass or fail; rubric 30 / 20 / 20 = 7 of 10;
     the card turned into 273 / 300, 合格, live on the student's screen;
     "Marked H3ESSAY: 273 / 300" arrived. Pass.
  6. `node functions/pn01_agreement.js functions/fixtures/pn01_sample.csv`
     prints 6 of 6 = 100%. Pass.
  7. The student was typing the essay and had not pressed Finish; the
     teacher pressed End test for everyone; the student's app sent the part
     and the essay was in the marking queue word for word. Pass.
  8. The hourly job closed a forgotten session and the review opened (flow
     step; run by hand on the emulator). Pass.
  9. Admin Reset attempt with a reason: "The student can sit the code
     again"; the result left the list; audit `test.attempt.reset` (flow).
     Pass.
  10. The QR code shows on the supervision screen and encodes
      `<site>/student/test?token=…`, a route that already fills the token.
      Opening it was not tried on the emulator (the local file server has no
      page rewrites); hosting has them. Pass with that gap.
  11. English light (teacher, admin), English dark (student: start screen,
      player, essay, result card, review), Indonesian light (teacher Tests
      and Marking), 360 px (Tests tab, Test results): no overflow after the
      fixes below. Pass.
- Fixed during the walk: "Session closed · 0 tests finished" when the
  students' apps had sent during the wait (now counts them); the End test
  dialog said unsent parts count as empty without mentioning that typed work
  is sent first; the Marking page showed the title "Tests"; the rubric label
  "30 / 40" wrapped; "0.5 of 1 points" now reads "0.5 / 1"; the test start
  screen said "1 questions" (Build 1 text).
- Proof: analyzer 0 errors / 0 warnings / 17 infos; `flutter test` 105 pass
  (+5); rules tests 56 pass, 1 skipped (+3 marking queue); node tests pass
  (+ `test_typing_matcher.js` 15 checks, `test_marking.js`); flow test 32/32
  (+8) after a re-seed.
- Owner must: (1) deploy rules, indexes and functions:
  `firebase deploy --only firestore:rules,firestore:indexes,functions --project chinese-tracker`
  (25 functions after it, 3 new); (2) hosting from the Mac,
  `scripts/deploy_web.sh --web-only --no-keys`; (3) on live: make a small
  package with one "type the hanzi" and one "type the pinyin" question,
  play it as `student1@`, mark it as `teacher@` in Tes → Penilaian.
- Left out and why: the Then list (time); opening the QR link on the
  emulator (no page rewrites on the local server).
- Notes for the PLAN chat:
  - Test items go to the teacher who opened the session, not also to the
    student's own teacher (packages go to both). Say if tests should go to
    both.
  - Saved accounts on the sign-in page remember the old emulator password,
    so on the emulator they now fail with Firebase's own English message;
    sign in by email. Live is not affected.
  - `pubsub` emulator (port 8085) is needed for the hourly job to exist
    locally; it starts with the others.

### 2026-11-17 — Build 1B Built-in HSK paper reader — d3b27b9..b2d4a30, release v0.1.17 (hosting live 2026-11-17; Storage rules and `getTestReview` wait for the owner)
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

**Full summary of the thesis requirements (2026-11-23):** `docs/THESIS_BOOK_GUIDE.md`:
the examiners' conditions mapped to builds and chapters, the trial promise, the
chapter plan with sources, the proposal-to-code name mapping, the format rules,
the three PDFs, the campus forms and the order of work.

**Book drafts (2026-11-23):** `docs/thesis/` holds Bab I, II and III in
Indonesian with `[ISI: …]` placeholders for the centre's facts, plus the
alphabetical Daftar Pustaka and a README on how to move them into the Word
template. Bab IV to VI follow once the supervisor confirms the chapter list.

**Supervisor's review of the book, 2026-11-25** (the owner's points 1 to 9;
points 10 to 13 are Build 9 in §4)

| # | Remark | What it means for the work |
|---|---|---|
| 1 | Teori Penunjang is too short; diagrams or pictures may be added | Bab II grows from about 9 to about 14 pages; it has no figure today, so each main theory gets one drawn figure (own drawings, source cited) |
| 2 | Desain Sistem must use many diagrams | Bab V: text and tables give way to diagrams; the owner answers the PLAN chat's questions first (which diagram kinds the supervisor expects) |
| 3 | Implementasi: only the important parts; a demonstration video is allowed | Bab VI shrinks from 37 screenshots and 17 segments to the parts the examiners asked about; the full set moves to an appendix or a video with a QR code |
| 4 | 100 pages or more, 120 at most | A page budget per chapter (below); the exact count comes from Word on the PC |
| 5 | Every mention of Claude Code is removed | Done 2026-11-25: Bab I §1.4 item 8 and the Bab VI tools row are gone; this replaces the owner's decision of 2026-11-24 |
| 6 | Five objectives, so five conclusions | Bab VIII §8.1 gets exactly five points, one per objective of Bab I §1.2, in the same order, each with its proof from Bab VII |
| 7 | A presentation for the seminar | Later; the PLAN chat asks the owner what it needs (length, template, live demo or video) |
| 8 | Artikel Ilmiah, a summary of the book | Later, on the campus article template in `CEK BUKU MANDIRI V4`, after Bab VII |
| 9 | A poster | Later; the campus size and template are needed |

**Page budget** (real numbers: Word on the PC, 2026-11-25, book at
`ad86562`: 148 physical pages, of which 20 front pages and 128 printed
pages from Bab I to the Riwayat Hidup; the limit is read as the printed
pages until the owner says otherwise)

| Part | Now (Word) | Target |
|---|---|---|
| I Pendahuluan | 10 | 10 |
| II Teori Penunjang | 10 | 15 |
| III Proses Bisnis | 14 | 12 |
| IV Analisa Sistem | 13 | 12 |
| V Desain Sistem | 26 | 26 (diagrams replace tables and text, no growth) |
| VI Implementasi | 49 | 16 |
| VII Uji Coba | 2 (headings only) | 16 |
| VIII Penutup | 1 (headings only) | 3 |
| Daftar Pustaka, Riwayat Hidup | 3 | 3 |
| Total | 128 | 113 |

One page of this book holds about 250 words, less than the usual estimate,
because of the wide margins and the 1.5 spacing.

**After the rework of Bab II and Bab VI** (`f1b5d61`, Word on the PC,
2026-11-26): 123 physical pages, 19 of them front pages, 104 printed.

| Part | Pages now | Target |
|---|---|---|
| I Pendahuluan | 10 | 10 |
| II Teori Penunjang | 15 | 15 |
| III Proses Bisnis | 14 | 12 |
| IV Analisa Sistem | 13 | 12 |
| V Desain Sistem | 26 | 26 |
| VI Implementasi | 20 | 17 |
| VII Uji Coba | 2 (headings only) | 15 |
| VIII Penutup | 1 (headings only) | 3 |
| Daftar Pustaka, Riwayat Hidup | 3 | 3 |
| Total | 104 | 113 |

**Owner's answers 2026-11-26** (to the PLAN chat's questions)

- **The limit of 120 pages counts the front pages.** So the whole file from
  the cover to the Riwayat Hidup stays at 120 physical pages or fewer. The
  appendices are taken as outside the count (the campus template has its own
  appendix files, one of them "Tampilan Program"); to be confirmed with the
  supervisor.
- Bab V diagrams and the drawing tool: the owner asked for recommendations
  (given 2026-11-26: the UML set drawn by the PLAN chat; his pick is open).
- The demonstration video is made **on the emulator**. The PLAN chat can
  make it: headless Chrome on the Mac records an MP4 from a canvas with no
  extra software (tested 2026-11-26), so the video is a scripted walk
  through the emulator with caption text and no voice. It is made after
  Build 9 is complete, because the pages change.
- Presentation, article and poster: later. Rebuild leaderboards on live:
  later.

**Owner's answers 2026-11-26, second round**

- **Page count: not a worry for now.** The supervisor told the owner not to
  worry about the page count; appendices outside the 120 pages are fine; the
  count is looked at again at the end. So no chapter is cut further for
  pages. The budget below stays as a reference only.
- **Bab V: option A** (the UML set): architecture, use case per role,
  activity diagrams, page map, plus data model diagrams of the collections,
  sequence diagrams and a status diagram.
- **Rule for every diagram: at most half a page, two diagrams on a page,
  each with its explanation.** Diagrams are drawn 14 cm wide and at most
  7.7 cm high; one that does not fit is split in two. The shared drawing
  kit `docs/thesis/tools/figkit.py` refuses a taller canvas. The existing
  diagrams of Bab III and Bab V are redrawn to this rule.
- **Video:** the PLAN chat makes it from the emulator after Build 9 is
  complete (scripted walk with captions, no voice).
- **Riwayat Hidup:** schools, work history (from the owner's CV) and the
  photo received; kept in the git-ignored `docs/thesis/local/` and only in
  the book built there.

**Budget for 120 physical pages** (replaces the targets above)

| Part | Pages now | Target |
|---|---|---|
| Front pages | 19 | 18 |
| I Pendahuluan | 10 | 10 |
| II Teori Penunjang | 15 | 14 |
| III Proses Bisnis | 14 | 12 |
| IV Analisa Sistem | 13 | 11 |
| V Desain Sistem | 26 | 22 |
| VI Implementasi | 20 | 13 |
| VII Uji Coba | 2 (headings only) | 13 |
| VIII Penutup | 1 (headings only) | 3 |
| Daftar Pustaka, Riwayat Hidup | 3 | 3 |
| Total | 123 | 119 |

How the pages are won: Bab VI keeps 12 screenshots and 6 program segments;
Bab V moves its three long tables (collections, access rules, the function
list) to an appendix and shows diagrams in their place; the black-box
tables of Bab VII go to their appendix with a summary table in the chapter;
Bab II, III and IV are tuned last (figure sizes and page breaks), when every
chapter exists and Word can count the pages after each change.

**Daftar Isi page numbers: no fault in the builder.** The first automation
run showed page 8 on every BAB line because the fields were refreshed before
Word had laid out the pages. With Repaginate first and the field update
twice, every line is right. By hand: Ctrl+A, then F9 twice.

**Riwayat Hidup:** the owner gave the birth place and date, the home
address and the starting year (2021) on 2026-11-25. The repository is
public, so the birth date and address are not committed: they are in
`docs/thesis/local/riwayat.json` (git-ignored) and only a book built into
`docs/thesis/local/` carries them. Still missing: primary, junior and senior
school with years, work experience, a photo.

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
