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

### 2026-11-24 — Claude (BUILD chat, PC): Scan paper reads worksheets

- Owner: all ten sample worksheets gave "No questions were found" on Scan
  paper. Scan paper now hands non-HSK files to the worksheet reader.
  Release v0.1.38 (hosting only).

### 2026-11-24 — Claude (BUILD chat, PC): .mpeg recordings accepted

- Owner's H326202Z recording (`.mp3.mpeg`) was refused; the picker now
  accepts it. Release v0.1.37 (hosting only).

### 2026-11-24 — Claude (BUILD chat, PC): Exam hidden, Standard Course, recording required, remove test codes

- Owner asked: remove Exam, rename to Standard Course, question type HSK,
  listening required for HSK and Standard Course, a remove button on test
  codes. Release v0.1.36 (rules and hosting).

### 2026-11-24 — Claude (BUILD chat, PC): answer key box pre-filled

- Owner asked that the Answer key box show the answers the worksheet
  already has. Release v0.1.35 (hosting only).

### 2026-11-24 — Claude (BUILD chat, PC): word-order and character answers, Standard Course

- Owner asked: an answer for word order, the character for pinyin
  questions, a new type "HSK Standard Course" with its audio, and the audio
  must work.
- Release v0.1.34 (hosting only), see the CHANGELOG entry.

### 2026-11-24 — PLAN chat (Mac): owner's first check of the Word book

- **Owner corrections applied** (`docs/thesis/tools/build_book.py`, `docs/thesis/BAB_I_PENDAHULUAN.md`, book rebuilt):
  name **WILSIN** in capitals on the cover, pengesahan, pernyataan and riwayat hidup (no longer yellow);
  abstract numbers filled with the proposal's targets (24 scenarios, 35 respondents fixed; 24 of 24 passed,
  100 % typing accuracy on 200 answers, SUS 75 stay yellow until the trial); Bab I §1.4 lists **Claude Code**
  as software point 8 (owner decision: AI help is stated; the `[ISI]` note to ask the supervisor is gone).
- **Gambar 3.5 rich picture drawn** (`docs/thesis/word/fig_3_5.png`, static SVG rendered with headless Chrome,
  1400 × 1000, placed at 14 × 10 cm): five actors, four tools, every flow of §3.3.1, the clash mark and four
  thought bubbles. The builder now places any `word/fig_<bab>_<n>.png` as the picture of that figure
  (`FIG_SIZE_CM` for sizes); the other Bab III figures stay yellow boxes.
- **Plan for Daftar Algoritma and Daftar Segmen Program** written into `docs/thesis/README.md` and as yellow
  notes in the Bab V and VI skeleton: 8 algorithms (pseudocode of the server rules: clash check, booking,
  close session, typing matcher, HSK marks, promotion, placement, progress warnings) and 15 program segments
  (Flutter init and role routing, rules, scheduling, booking, close session, matcher, finishExercise,
  promotion, Midtrans, progress, fl_chart, exercise player). Campus rules copied from the criteria file.
- **Open with the owner:** what "3.2.2 before its not existed" means (no teacher scheduling in the old
  system, or only no spreadsheet screenshot for Gambar 3.2); the approved proposal §IV.A point 2 says the
  admin asked availability by chat and kept the schedule in a spreadsheet.
- Checks: package valid, 127 bookmarks all resolved, 2 figure relationships, list point 8 shares the list
  numbering of points 1–7. Pages after the cover are still checked by structure only (no Word on the Mac).
- **Bab V drafted (owner: "go"):** `BAB_V_DESAIN_SISTEM.md` from proposal §IV.B–H and the code as built
  (collections, functions, settings switches, waiting list, level checklists, placement, Standard Course):
  12 sub-chapters, Algoritma 5.1–5.8 as numbered pseudocode in the campus format (builder renders
  `Algoritma x.y` blocks with the template's `01:` numbering and lists them in Daftar Algoritma; the same for
  `Segmen Program` blocks later), Rumus 5.1–5.2 as equations, Tabel 5.1–5.13 (jadwal vs sesi, checks, voucher
  example, exercise vs test, question forms, matcher examples, levels, HSK formats, promotion example,
  warnings, 25 collections with fields, access rules, 74 functions by area), Gambar 5.1–5.9 drawn as SVG
  (architecture, use cases per role, four activity diagrams, sitemap). Tabel 3.2 filled (22 / 24 / 8 of 54).
  Book: 22 figures, 26 tables, 8 algorithms, 4 formulas, 166 bookmarks, 41 `[ISI]` left.
- **v0.1.38 (a987075) reviewed on the Mac:** hosting only; analyzer 17 infos; `flutter test` 174 pass + 2
  skipped; no functions or rules change (74 on live); no new tracked secrets; live `main.dart.js` carries the new
  snackbar text; APK still served (114,190,060 bytes). Scan paper now hands a file without `第 a-b 题` blocks to
  `reviewWorksheetFile`; the admin/web gate still holds in `WorksheetImportService.extractTextFromWorksheet`
  (`ensureSupported()`), and Scan paper itself is admin-only. Known cost: a scan with no text layer is OCR'd twice.
- **v0.1.37 (3c06be8) reviewed on the Mac:** hosting only; analyzer 17 infos; `flutter test` 174 pass + 2
  skipped; no tracked secrets; live bundle from 10:31 WIB; APK still served. The audio picker's new extensions
  map to `audio/*` types, which the Storage rule for question-bank media already accepts.
- **Owner's five answers applied:** founded 1992 (records from 1994), eleven sessions a week (Mon 1, Tue 2,
  Wed 2, Thu 1, Fri 2, Sat 3, Sun 0; a session with fewer than three students is cancelled), teacher levels
  W1 HSK 1–3, S HSK 1–5, M HSK 5–6, W2 HSK 1–4 (Tabel 3.1 lost its "hari mengajar" column: no teacher schedule
  in the old system), about fifty simulation tests a month, UI language stays Indonesian and English with
  Chinese as future work. 61 `[ISI]` left (per-level student counts, Bab V–VIII notes, examiners, dates).
- **Bab IV drafted, Bab III completed from the owner's documents:** the owner answered the ten Bab IV
  questions and sent the Google Form (4 screenshots), a kwitansi, the Excel "Daftar Siswa Easy Study (2024)"
  (1,324 names since 1994; sheet Aktif 54 active students, 27 on 8 and 27 on 16 sessions) and "Rekap Absensi
  Murid" (33 running 16-session and 29 running 8-session terms; about 100 attendances a month in Oct and Nov
  2026), and the old score app https://student-hsk-score.netlify.app ("Nilai Simulasi HSK", so the proposal was
  right). Bab III: address from the kwitansi header, roles of admin T and teachers W, S, M, W, Google Form
  fields as Tabel 3.3 (prices Rp3.950.000 / Rp2.450.000, two-month validity), Gambar 3.4 = the old web app
  (figures 3.4–3.7 became 3.5–3.8), Tabel 3.4 problems reordered by the owner's ranking. Bab IV
  (`BAB_IV_ANALISA_SISTEM.md`): facts, document table, new students per year 2019–2026 from the Excel, package
  table, problem-to-need mapping, comparison tables from the proposal (Teach 'n Go, HelloChinese, Jesslyn),
  requirements per role and non-functional; Gambar 4.1–4.4 (form page, kwitansi and Excel excerpts with
  personal data blurred). Only aggregates from the Excel files are in the book; the files themselves stay out
  of the repo. Book: 13 figures, 13 tables, 137 bookmarks, 75 `[ISI]` left.
- **v0.1.36 (98151f6) reviewed on the Mac:** analyzer 17 infos; `flutter test` 174 pass + 2 skipped; `node
  --check` ok; no tracked secrets; live bundle from 09:39 WIB; APK still served. **Rules tests 85 pass, 1 fail:**
  the suite still asserts that an admin cannot delete `test_codes/{id}` while the rule now says
  `allow delete: if isAdmin()`; the BUILD chat fixed the test in 6763fb3 (admin delete succeeds, teacher delete
  fails) and the Mac run is back to 86 pass, 0 fail, 1 skipped. The rule is
  acceptable for an admin-only action: `removeCode` checks `test_sessions`, `test_results` and
  `placement_results` (all staff-readable) and hides a used code instead of deleting it; a server-side callable
  would make that guarantee client-independent (noted to the BUILD chat).
- **v0.1.35 (9fbf606) reviewed on the Mac:** hosting only, six files; analyzer 17 infos; `flutter test` 171 pass
  + 2 skipped; `node --check` ok; no tracked secrets; live bundle from 09:22 WIB; APK still served.
- **v0.1.34 (ae29dc1) reviewed on the Mac:** hosting only; analyzer 17 infos; `flutter test` 170 pass + 2
  skipped; node tests pass; no tracked secrets; live bundle from 09:07 WIB carries "HSK Standard Course"; APK
  still served. `storage.cors.json` (f2ca003) allows GET and HEAD from our two hosting origins and the emulator
  bundle only; the owner applied it from Cloud Shell on 2026-11-24 (BUILD chat checked the header; the command
  stays in `docs/OWNER_PROCEDURES.md`).
- **v0.1.33 (3f1519a) reviewed on the Mac:** analyzer 17 infos; `flutter test` 168 pass + 2 skipped; node tests
  pass; rules tests 86 pass, 1 skipped; no tracked secrets; 74 functions on live (`onExerciseResultForPath`,
  `onLevelPathWritten`); APK still served. Rules read: `level_paths` staff read / admin write, `paper_drafts`
  admin only, Storage `paper_drafts/{uid}/{file}` admin only with PDF type and a 60 MB cap. `pathProgress` is pure
  (exercise item = best final score at or above its minimum, test item = a final, valid, passed, non-placement
  result of that code); the triggers only call `syncPromotion`. The waitlist "already" nit is fixed.
- **Bab III finished from the owner's sixteen answers:** one admin, four teachers (two teach each session,
  mixed levels, the rest stand by), the owner (the author's mother) only gets payment notices; registration by
  WhatsApp or walk-in (some via Instagram), no free trial, data through a Google Form, level by the student's
  choice (Beginner or a short oral test); packages 8 or 16 sessions by transfer or cash, transfer proof forwarded
  to the owner, paper receipt, Excel of active vouchers, sessions deducted the next day from the paper list,
  admin reminds about expiring packages; the admin posts tomorrow's session list after the 18:00 class; tests
  when the teacher sees the need, printed past HSK papers (about 14 years of them), teacher supervises and
  plays the audio, pass about 60 % per part, promotion after 2–3 passed tests plus exercises, told orally;
  Gambar 3.3 is the official HSK result page (format reference), not the old web app. §3.1, §3.2.1, §3.2.2,
  §3.2.4 rewritten; Gambar 3.5 (use case), 3.6 and 3.7 (activity, swimlanes) drawn as SVG and placed; the
  Mermaid drawing aids removed. Open: does the old "Nilai Simulasi HSK" web app (project `easy-study-hsk`)
  really exist, or were simulation scores kept on paper or in Excel? Asked in chat.
- **v0.1.32 (6d65b92) reviewed on the Mac:** analyzer 17 infos; `flutter test` 165 pass + 2 skipped; node tests
  pass (scheduling covers the waiting list); rules tests 85 pass, 1 skipped; no tracked secrets; 72 functions on
  live (`joinWaitlist`, `leaveWaitlist`, trigger `onSessionSeatsChanged`); APK still served after the PC deploy.
  Read: `waitlist/{sessionId}_{studentId}` readable by the student, a linked parent and staff only, written by
  functions; `joinWaitlist` goes through `requireBookingCaller` and every booking check but the seat
  (`waitlistRefusal`); the trigger books the queue in `createdAt` order with the normal booking transaction and
  stops at "full". Nit sent to the BUILD chat: two seat changes at once could make the second attempt hit
  "already" and send a needless "could not book you" notice.
- **Fourth round (e3abac3, v0.1.31) reviewed on the Mac:** analyzer 17 infos; `flutter test` 165 pass + 2
  skipped; `node --check` and the 12 node tests pass (payments covers discarded invoices); no tracked secrets;
  69 functions on live with `discardInvoice` (admin only through `requireAdmin`, reason capped at 300, a paid
  invoice cannot be discarded, restore puts the old status back, audit written; a payment that lands on a
  discarded invoice still credits the sessions and tells the admin). No rules change. The PC's web-only deploy
  kept the APK (`/downloads/easy-study.apk` still the APK content type).
- **Owner's third check:** class times in the old system = an agreed day per student, but students pick any
  session by writing their name on the daily session list the admin posts in the student WhatsApp group
  (§3.2.1 rewritten, no yellow left there); Gambar 3.1 is now that WhatsApp list (names, number and avatar
  blurred), Gambar 3.2 the paper attendance sheet (cropped to the paper, names readable as the owner asked),
  Gambar 3.3 the HSK score page (name, Chinese name and candidate numbers blurred); blurring done with a
  headless-Chrome overlay (`scratchpad` only), crop with `sips`. §1.5 says implementation = coding, Agustus 2026
  (first commit 2026-08-05, yellow) to November 2026. Use case and activity diagrams (3.5–3.7) wait for the
  owner's answers to the questions asked in chat.
- **Owner's second check (uploaded his edited book):** his edits ported into the builder (examiner lines removed
  from the pengesahan page, sidang month, pernyataan date and the tab before "Yang Membuat Pernyataan", prodi
  line "Prog Prof S1 Informatika"); English month names made Indonesian (JANUARI 2027, 28 Desember 2026, yellow
  to confirm). **Old system had no teacher scheduling at all** (owner): Bab III §3.2.2 and Gambar 3.2 and 3.8
  removed, sections and figures renumbered (rich picture is Gambar 3.4, `word/fig_3_4.png`, redrawn without the
  schedule flows), §3.2.1 says how class times were agreed (one yellow sentence to confirm), Tabel 3.3 row 1,
  use case and rich-picture text, Bab I §1.1 and §1.5 and both abstracts reworded. The approved proposal §IV.A
  point 2 still describes a spreadsheet schedule; the owner should mention the correction to the supervisor.
- **APK published (owner: "publish the APK"), v0.1.30 reviewed:** the APK was rebuilt from 3169334 (new pencil
  icon) and published with `scripts/deploy_web.sh --no-keys` from the Mac at 06:34 WIB after the PC's v0.1.30
  deploy (functions 68 with `deleteMyAccount`, /privacy). Live: `/downloads/easy-study.apk` returns 200 with the
  APK content type (109 MB), the bundle carries the APK link, "Write from the recording" and "Delete my account",
  the Whisper encoder is served. Checks on 3169334: analyzer 17 infos, `flutter test` 162 pass + 2 skipped (the first run after my `flutter clean` failed the PDF probe test: the clean had removed `.dart_tool/native_assets.yaml`, which the pdfium loader needs under `flutter test`; one throwaway `dart run` of a script importing `pdfium_dart` writes it again),
  `node --check` and the 12 node tests pass; `deleteMyAccount` read: signed-in student or parent only, sign-in at
  most 10 minutes old, shared `deleteAccountCore` unlinks parent and child, records stay. The privacy page
  publishes the centre's phone and Instagram only. 7157d16 (BUILD chat) makes `--web-only` deploys keep the
  live APK, so no Mac redeploy is needed after a PC web deploy.
- **Round three and Q7 reviewed on the Mac** (d04d962 and e637636, release v0.1.29): analyzer 17 infos;
  `flutter test` 162 pass + 2 skipped; `node --check` and the 12 node tests pass; rules tests 84 pass, 1
  skipped; no tracked secrets; `firebase functions:list` 67 with `promoteStudent` and `onAnnouncementCreated`;
  live `main.dart.js` from 06:03 WIB carries "More figures", "Promote a student" and "Write from the
  recording"; the Whisper encoder (92 MB) is served from `/asr/`. Security read: `promoteStudent` checks the
  admin role, limits the reason, reads before it writes and closes open recommendations; the announcement
  trigger writes one deterministic notice per role; `fetch_whisper.mjs` pins every tarball and model file by
  SHA-256 and the browser never calls an outside service. Note for the owner: hosting grows by about 270 MB
  and each admin browser downloads that once (Blaze bandwidth is 10 GB a month free, then USD 0.15 a GB).
- **Q8 (APK):** the live `/downloads/easy-study.apk` is gone (the PC's web-only deploys are full snapshots);
  the keystore is only on the Mac, so the release APK was rebuilt here with the deploy script's defines:
  `build/app/outputs/flutter-apk/app-release.apk`, 114 MB, 06:11 WIB, from e637636. The first two builds
  failed with "cannot find symbol FlutterFirebaseStoragePlugin": the storage plugin's incremental Kotlin
  output under `build/firebase_storage/` dated from October and held only the pigeon classes; `flutter clean`
  fixed it (no code or Gradle change; `android.builtInKotlin=false` was already in `gradle.properties`).
  Publishing it (hosting deploy from the Mac, web + APK, `scripts/deploy_web.sh --no-keys`) waits for the
  owner's word in the PLAN chat.

### 2026-11-24 — Claude (BUILD chat, PC): scan drafts and answers, level checklists

- Owner asked: the clock does not move; drafts of unfinished scans; the
  save error; the right answer beside each question; choices as proper
  multiple choice with a tick; shuffled choices; the paper's matching
  layout; X asks first; a level checklist with a progress bar.
- Release v0.1.33 (74 functions), see the CHANGELOG entry.

### 2026-11-24 — Claude (BUILD chat, PC): profiles, waiting list

- Owner said "yes, build them" to the recommendations: teacher and parent
  profile pages, the discard pop-up on the remaining forms, and a waiting
  list for full classes. Release v0.1.32 (72 functions).

### 2026-11-24 — Claude (BUILD chat, PC): owner requests, fourth round

- Owner asked: the missing box E in the paper reader, easier page
  browsing, a pop-up before discarding edits, a Mixed skill section,
  discarding invoices with a reason, optional News end date and holiday
  notices, a class page, a compact student profile with photo and
  history, news and a clock on the dashboard.
- Built in release v0.1.31 (69 functions), see the CHANGELOG entry.

### 2026-11-24 — Claude (BUILD chat, PC): App Store preparation (Q9 option B)

- Owner chose an App Store app. Built what Apple needs from the code side:
  icon, iOS settings, in-app account deletion, a privacy policy page, and
  a build script. Release v0.1.30 (68 functions).
- The owner's steps (Apple Developer account, Xcode, signing, App Store
  Connect, TestFlight) are in `docs/IOS_SPEC.md`.

### 2026-11-24 — Claude (BUILD chat, PC): owner requests, third round

- Owner asked: a calmer admin dashboard; cancelled classes gone from the
  calendar; announcements on their own page for everyone; answers to Q6
  (leave), Q7 (generate listening scripts), Q8 (rebuild the APK), Q9 (iOS,
  specify), Q12 (the admin may just promote).
- Built in release v0.1.29 (67 functions), see the CHANGELOG entries. iOS
  options written in `docs/IOS_SPEC.md`. Listening scripts are written
  from the recording in the browser (Whisper small, Q7).
- Checked: analyzer 17 infos, `flutter test` 162 pass, node tests, flow
  test 103 steps, emulator walk.

### 2026-11-23 — Claude (BUILD chat, PC): owner requests, second round

- Owner asked: a bigger, clearer Timetable rules dialog; several teachers
  per class; drop the teacher recap ("teachers are always ready");
  Indonesian holidays on the calendar with an open/closed decision; close a
  class with fewer than 3 students; announcements on the home pages; no
  class-day picker at purchase; compare the paper attendance board at close.
- Built in release v0.1.28 (65 functions), see the CHANGELOG entry. The
  minimum-students rule is off on live until the owner types a number.
- Checked: analyzer 17 infos, `flutter test` 160 pass, rules tests 84 pass,
  flow test 101 steps, emulator walk.

### 2026-11-23 — Claude (BUILD chat, PC): owner requests + After-Build-8 follow-ups

- Owner asked (with two screenshots): delete button on the quick sign-in
  list, change own password, timetable clash at 16:31 after a 16:30 class,
  Recheck, delete a weekly schedule, automatic session start, late students
  joining, then "build the rest". All built in release v0.1.27 (63
  functions): see the CHANGELOG entry of the same day.
- Checked: analyzer 17 infos, `flutter test` 156 pass, node tests, flow
  test 97 steps, an emulator walk of the new screens.

### 2026-11-23 — PLAN chat (Mac): thesis requirements summarised

- Read the owner's own documents: the revised proposal packet (form F-048,
  the four reviewers' conditions and the sidang decision of 2026-10-07 with
  the answers, the proposal itself), the campus book kit (`CEK BUKU MANDIRI
  V4`), the BAA PDF guide, the campus forms and a finished campus book as a
  model.
- Wrote `docs/THESIS_BOOK_GUIDE.md`: the contract with the examiners, the
  trial promise, the chapter plan with sources, the name mapping from the
  proposal to the code, the format rules, the PDFs, the forms (10
  consultations, 3 + 5 seminars attended, pra-seminar), the order of work
  and the inputs still owed by the owner. `docs/PLAN.md` §7 points to it.
- Drafted Bab I Pendahuluan, Bab II Teori Penunjang and Bab III Proses
  Bisnis in Indonesian from the proposal text (`docs/thesis/`), with the
  Daftar Pustaka re-sorted alphabetically and Mermaid sketches as drawing
  aids for the old-system diagrams.
- Reviewed v0.1.27 (BUILD chat, owner requests and the After-Build-8
  follow-ups): analyzer 17 infos, 156 Flutter tests, node and tool tests,
  rules tests 81 pass and 1 skipped; live 63 functions and the new
  strings in the bundle; security read of `deleteSchedule`, the placement
  retention job, the change-password flow and the visitor token limits.
  Note in PLAN §1; owner live step: Timetable rules gap 15 → 0.
- Reviewed v0.1.28 (second round: holidays, announcements, helper
  teachers, readiness switch, minimum students, board compare): analyzer
  17 infos, 160 Flutter tests, node tests, rules tests 84 pass and 1
  skipped, live 65 functions and 23 indexes, bundle checked, rules diff
  read. Thesis note in PLAN §1: switch teacher readiness on before the
  trial.
- The BUILD chat then made both trial seeds switch readiness on (381a982);
  proven here with `firebase emulators:exec`: `seed_trial.py emulator` writes
  `settings/scheduling` with `teacherReadiness: true`, `minStudents: 0`, gap 0.
  The live seed is parse-checked only (needs credentials at the trial).
- No code, rules or functions changed. Nothing to deploy.

### 2026-11-21 — Claude (PLAN chat, Mac): Build 8 reviewed; the eight thesis builds are done

- Pulled Build 8 (v0.1.26) and checked it on the Mac: analyzer 17 infos,
  `flutter test` 152 pass and 2 skipped, node tests (+ `test_reports.js`,
  `tool/test_sus_score.mjs`, `tool/test_import_questions.mjs`), rules tests
  81 pass and 1 skipped. Live: 60 functions, 23 indexes equal to the repo,
  the bundle carries the monthly report; the GitHub checks are green.
- Read: `reports` admin-read and functions-write; the workflow has no
  secret; the live trial seed takes a key by path and keeps names and
  passwords in git-ignored files; the emulator-only sign-in is not in the
  live bundle. One hygiene item: a `.pyc` file was committed.
- Plan: Build 8 done; **nothing marked NEXT**. PLAN.md §4 gained "After
  Build 8": the owner's live tasks in order, the trial steps, the small
  follow-ups, the book inputs. The hourly check loop of the PLAN chat
  stops here.

### 2026-11-21 — Claude (BUILD chat, PC): Build 8 dashboard, trial kit, screenshots

- Built Build 8 (release v0.1.26): the admin dashboard's six duty cards,
  the monthly report, automatic checks on GitHub, the trial seed (emulator
  and live), the question import and checklist, task sheets and SUS, the
  screenshot pass.
- Checked: analyzer 17 infos, `flutter test` 152 pass, rules tests, node
  tests, flow test 91/91.

### 2026-11-21 — Claude (PLAN chat, Mac): Build 7 reviewed, Build 8 is NEXT

- Pulled Build 7 (v0.1.25) and checked it on the Mac: analyzer 17 infos,
  `flutter test` 150 pass and 2 skipped, node tests (+ `test_teaching_day.js`),
  rules tests 80 pass and 1 skipped. Live: 58 functions, 23 indexes equal
  to the repo, the bundle carries the Schedule screen.
- Read: the close is one idempotent transaction with a fixed-id ledger;
  check-in, close and cancel are limited to the session's teacher or an
  admin; jobs claim their work in transactions; the life fields are
  function-only in the rules. The six choices are accepted; one follow-up
  (a zero result for a forgotten exam attempt) went to Build 8's "Then".
- Plan: Build 7 done, **Build 8 (dashboard, monthly report, GitHub checks,
  trial kit, screenshot pass) NEXT**; the spec holds against the report.

### 2026-11-21 — Claude (BUILD chat, PC): Build 7 the teaching day

- Built Build 7 (release v0.1.25): check-in with server time, the close
  in one idempotent transaction with the voucher ledger, substitutes and
  cancellations, confirmations and change requests, reminders and late /
  unclosed flags, the monthly teacher recap, voucher reconciliation, the
  teacher Schedule screen and the admin Follow-up.
- Checked: analyzer 17 infos, `flutter test` 150 pass, rules tests 80
  pass, node tests (+ `test_teaching_day.js`), flow test 89/89.

### 2026-11-21 — Claude (PLAN chat, Mac): Build 6 reviewed, Build 7 is NEXT

- Pulled Build 6 (v0.1.24) and checked it on the Mac: analyzer 17 infos,
  `flutter test` 146 pass and 2 skipped, node tests (+ `test_scheduling.js`),
  rules tests 77 pass and 1 skipped. Live: 45 functions, 23 indexes equal
  to the repo, the bundle carries the timetable and booking.
- Read: schedules and generated sessions are functions-only; the conflict
  check runs in a transaction with lock documents; booking is one
  transaction limited to the caller's own account or child; students lost
  the direct attendance writes. Two deviations accepted (shared timetable
  reads; class day on the voucher form).
- Walked the new screens on the emulator from the Mac (the BUILD chat had
  not): the Timetable (week grid with a horizontal scroll, list, availability with the day off), the New schedule form, where a Monday 16:00 class in Main for Andrea was refused with "Main is taken by Kelas A on Monday 16:00–17:30" and five free times, Save disabled; the student home list of the next 14 days with **Book**: "Booked." appeared, the row turned to **Cancel** and the seats went from 7 of 8 to 6 of 8; the same list at 375 px. All fine. One finding for Build 7: the admin Classes calendar shows no generated sessions (it lists one-off sessions only), so the admin finds them on the Timetable screen for now.
- Plan: Build 6 done, **Build 7 (the teaching day) NEXT**; the class day
  in the buy sheet moved to Build 7's "Then".

### 2026-11-21 — Claude (PLAN chat, Mac): Build 5 reviewed, Build 6 is NEXT

- Pulled Build 5 (v0.1.23) and checked it on the Mac: analyzer 17 infos,
  `flutter test` 144 pass and 2 skipped, node tests (+ `test_payments.js`,
  MT-01 to MT-04), rules tests 73 pass and 1 skipped. Live: 40 functions,
  20 indexes equal to the repo, the bundle carries the buy sheet.
- Read: self-purchase is limited to the buyer's own account or linked
  child, terms required, server-side amount kept; the Snap stub applies
  only on the emulator; no secret or `.local` file is tracked. No change
  asked.
- Plan: Build 5 done, **Build 6 (weekly timetable and booking) NEXT**; the
  spec holds against the Build 5 report (`sessionsBooked` exists on new
  terms). The owner's sandbox E2E (MT-05) is in the §1 table.

### 2026-11-21 — Claude (PLAN chat, Mac): Build 4 reviewed, Build 5 is NEXT

- Pulled Build 4 (v0.1.22) and checked it on the Mac: analyzer 17 infos,
  `flutter test` 140 pass and 2 skipped, node tests (+ `test_progress.js`),
  rules tests 71 pass and 1 skipped. Live: 39 functions, 20 indexes equal
  to the repo, the bundle carries the report screens.
- Read the rules and functions: the summary is functions-only; notes are
  shaped and tied to the student's own teacher; notices once per 7 days;
  the rebuild is admin-only. No change asked.
- Recorded the owner's standing go (said in the BUILD chat) in PLAN.md §1.
- Plan: Build 4 done, **Build 5 (voucher packages and self-purchase)
  NEXT**, re-read against the Build 4 report: no change needed (Build 4
  already sends the voucher warning, so Build 5's job only expires).

### 2026-11-21 — Claude (PLAN chat, Mac): Builds 5 to 8 written in full

- While the BUILD chat builds Build 4, the PLAN chat wrote Builds 5
  (voucher packages and self-purchase, MT-01 to MT-05), 6 (weekly
  timetable, availability, conflict check with suggestions, session
  generation, booking through functions, JD-01, JD-02, VC-04), 7 (the
  teaching day: confirm, change request, check-in, idempotent close with
  the voucher ledger, substitutes, cancel, reminders, recap, VC-01 to
  VC-05) and 8 (dashboard, monthly report, GitHub checks, trial seed, the
  731-question checklist, task sheets, SUS, screenshot pass) out in full in
  `docs/PLAN.md` §4, each with Must, Then, Not and an acceptance walk.
- §5 gained Q17 to Q21 with the defaults those builds take. Each spec is
  re-read against the report of the build before it before it is marked
  NEXT.

### 2026-11-20 (night) — Claude (PLAN chat, Mac): Build 3 reviewed, Build 4 is NEXT

- Pulled Build 3 (v0.1.21) and checked it on the Mac: analyzer 17 infos,
  `flutter test` 135 pass and 2 skipped, node tests (+ `test_placement.js`),
  rules tests 68 pass and 1 skipped.
- Read the rules and the seven new functions: pending students are refused
  by rules and functions alike; `decideRegistration` is admin-only in one
  transaction; the visitor path is rate-limited per address, keyed by a
  hashed 128-bit key, staff-only to read, and never returns a key, a name
  or a number. Two notes (per-address token block in a classroom; the
  default minimum of codes written at approval), no change asked.
- Hosting is on hold on purpose: the new register form needs the new rules
  and the Approval buttons the new functions, so rules, index, functions
  and hosting go live together after the owner's go (PLAN.md §1 table).
- Plan: Build 3 done. **Build 4 (progress report: summary doc, five
  warnings, report screen for four roles, chart, PDF, daily notices)
  written in full and marked NEXT**, with defaults for §5 Q13 to Q16.

### 2026-11-21 — Claude (BUILD chat, PC): Build 6 timetable and booking

- Built Build 6 (release v0.1.24): weekly schedules with the conflict
  check and locks, generated sessions, booking through functions that
  reserve a voucher session, the admin Timetable, the student and parent
  booking lists, teacher availability and days off.
- Checked: analyzer 17 infos, `flutter test` 146 pass, rules tests, node
  tests (+ `test_scheduling.js`), flow test 78/78 (+8).

### 2026-11-20 — Claude (BUILD chat, PC): Build 5 vouchers and self-purchase

- Built Build 5 (release v0.1.23): students and linked parents buy
  voucher packages in the app (Midtrans Snap), paid invoices become
  vouchers with their validity and a ledger, a daily job expires old
  vouchers, admin invoice filters with totals.
- Checked: analyzer 17 infos, `flutter test` 144 pass, rules tests 73 pass,
  node tests (+ `test_payments.js`, MT-01..04), flow test 70/70, an
  emulator walk. The owner still runs the sandbox E2E on live (MT-05).

### 2026-11-20 — Claude (BUILD chat, PC): Build 4 progress report

- Built Build 4 (release v0.1.22): `progress_summary/{uid}` kept by
  functions (triggers + the daily job), the five warnings and the status
  label, warning notices once per 7 days, teachers' follow-up notes, one
  report screen (`fl_chart`, approved by the owner) for students, parents,
  teachers and admins, attention lists, the PDF, a rebuild button.
- Owner instructions this session: build the queue and deploy without
  asking; stop at 99% of the weekly limit (both in Claude's memory).
- Checked: analyzer 17 infos, `flutter test` 140 pass, rules tests 71 pass,
  node tests (+ `test_progress.js`), flow test 62/62, an emulator walk.

### 2026-11-20 — Claude (BUILD chat, PC): Build 3 registration approval, placement tests, rooms

- Built Build 3 (release v0.1.21): self-registered students wait as
  `pending` on `/waiting` until the admin approves them on Users →
  Approval (`decideRegistration`); the register form asks "Mulai dari HSK 1"
  or "Ikut tes penempatan" with an optional result code; placement sessions
  recommend a level on the Promotion screen; visitors sit placement codes
  from `/placement` with no account and get a result code; rooms list and
  teacher levels.
- Checked: analyzer 17 infos, `flutter test` 135 pass, rules tests 68 pass,
  node tests (+ `test_placement.js`), flow test 56/56 (PL-01, PL-02, the
  visitor path), an emulator walk at 1280, 400 and 360 px.
- Deployed the same day at the owner's go: rules, indexes and functions
  (34 on live), then hosting.

### 2026-11-20 — Claude (PLAN chat, Mac): Build 2B reviewed, Build 3 is NEXT

- Pulled Build 2B (v0.1.20) and checked it on the Mac: analyzer 17 infos,
  `flutter test` 127 pass and 2 skipped, node tests (+ `test_promotion.js`,
  PN-01 6 of 6), rules tests 62 pass and 1 skipped.
- Read the rules and functions: the four new collections are written only
  by the trigger and `decidePromotion`; a student reads a board only for a
  code they sat; `decidePromotion` is admin-only in one transaction;
  `users.level` is closed to students; teacher bank writes follow
  `createdBy`. Live from the Mac: the bundle carries the new routes, 27
  functions, 18 indexes equal to the repo. No change asked.
- Plan: Build 2B done. **Build 3 (registration approval, placement tests
  in both ways, rooms, teacher levels) written in full and marked NEXT**,
  with defaults for §5 Q4, Q10, Q11 and Q12. The public-repository
  security item is still open for the owner.

### 2026-11-20 — Claude (BUILD chat, PC): Build 2B leaderboard, promotion, names

- Backend live the same day (owner said yes): rules, indexes and functions
  deployed; `onTestResultWritten` and `decidePromotion` created, 27
  functions on live.
- Built Build 2B (`4ee0f42`, release v0.1.20): leaderboard per test code,
  promotion count and the admin Promotion screen (approve / decline), the
  progress card and ranks on the student Tests tab, the two name labels,
  teachers editing their own bank questions, `users.level` admin-only.
- Walked it on the emulators (Indonesian dark, English light, 1280 px and
  360 px); fixed a cut name on the board at 360 px, the admin promotion
  notice opening Classes, student test notices pointing at a missing route,
  and a declined student's card staying on "waiting".
- Proof: analyzer 17 infos; `flutter test` 127 + 2 skipped; rules tests 62
  + 1 skipped; node tests; flow test 41/41. Report in `docs/PLAN.md` §6.
- Hosting deployed from the PC; rules, indexes and functions followed the
  same day (first bullet).

### 2026-11-19 — Claude (BUILD chat, PC): Build 1C functions deployed

- At the owner's go, ran `firebase deploy --only functions --project
  chinese-tracker` from the PC: exit 0, all 25 functions updated (Must 8:
  marking items of a supervised test also name the student's own teacher;
  only attempts started from now carry `studentTeacherId`).
- Checked: `startTest` answers "Sign in first." without a sign-in.

### 2026-11-18 — Claude (PLAN chat, Mac): Build 1C reviewed, Build 2B is NEXT

- Pulled Build 1C (v0.1.19) and checked it on the Mac: analyzer 17 infos,
  `flutter test` 118, node tests, rules tests 57 pass and 1 skipped;
  `scripts/fetch_paper_ocr.mjs` downloads and verifies the same files on
  the Mac (SHA-256 pins hold), so a hosting deploy from the Mac still works.
- Read: the reader loads the model from our own hosting (`ocr/`), the
  practice paper is made-up text, `Download text` is admin + web, the only
  function change is `teacherIdsFor` (functions deploy open for the owner).
- Hosting at v0.1.19 was published from the PC; the PLAN chat checked the
  live site serves `paper_ocr_paddle.js` and the model.
- Plan: Build 1C done, Build 2B (leaderboard, promotion, names) is NEXT.
  The public-repository security item stays open for the owner.

### 2026-11-18 — Claude (BUILD chat, PC): Build 1C reader accuracy

- Wrote `docs/LIVE_TEST_BUILD_2A.md` (26 steps for the owner on live).
- Built Build 1C (`docs/PLAN.md` §4, report in §6): a practice HSK 3 paper
  from our own sentences with a truth file, measuring tools, and PaddleOCR
  (PP-OCRv5) in the browser as the reader's engine: 79 of 80 right as read
  on the practice paper in the measure, 78 in the app, against 37 before.
  Owner approved the downloads (onnxruntime-web, the model, the HSK lists)
  and shipping the model on hosting.
- Also: level and stray-mark flags, tone buttons, proofreading record,
  Download text, a picture-box fix, test marking items for the student's
  own teacher, indexes file equal to live.
- Proof: analyzer 17 infos; `flutter test` 118 (+2 with files); rules 57 + 1
  skipped; node tests; flow 32/32.
- Deploy: hosting from the PC; functions (Must 8) wait for the owner's go.

### 2026-11-17 — Claude (BUILD chat, PC): Builds 1B and 2A backend deployed

- The owner signed in to the Firebase CLI on the PC and asked the BUILD chat
  to deploy. Ran
  `firebase deploy --only storage,firestore:rules,firestore:indexes,functions --project chinese-tracker`:
  Storage rules (60 MB audio), Firestore rules (`marking_items`), the 2
  marking indexes, 25 functions (3 created: `markAnswer`,
  `resetTestAttempt`, `closeForgottenTestSessions`). Exit 0.
- Checked: the site answers 200; `markAnswer` and `resetTestAttempt` answer
  "Sign in first." without a sign-in.
- The deploy said 3 indexes on live are not in `firestore.indexes.json`;
  they were left alone (no `--force`).
- PC note: the Firebase CLI was installed inside the Claude app, so a
  normal terminal finds it only by its full path (CLAUDE.md, Known
  blockers).

### 2026-11-17 — Claude (PLAN chat, Mac): Build 2A reviewed, hosting live, Build 1C is NEXT

- Pulled Build 2A (v0.1.18) and checked it on the Mac: analyzer 17 infos,
  `flutter test` 105, node tests (typing matcher, marking, PN-01 sample
  6 of 6), rules tests 56 pass and 1 skipped.
- Read the backend: `markAnswer` (role, queue owner, clamped rubric, one
  transaction), `marking_items` rules (admin and the named teachers read,
  functions write), the new question types reach the player without keys,
  `resetTestAttempt` admin-only with audit.
- Published hosting from the Mac (`--web-only --no-keys`). Open for the
  owner, one command for Builds 1B and 2A:
  `firebase deploy --only storage,firestore:rules,firestore:indexes,functions --project chinese-tracker`.
- Plan: Build 1C (reader accuracy) is NEXT and no longer waits for the
  owner (a practice paper made for the test gives a truth file); marking
  items of a test also go to the student's own teacher; Build 2B
  (leaderboard, promotion, names) is written in full.

### 2026-11-17 — Claude (BUILD chat, PC): Build 2A typing matcher and marking

- Built Build 2A (`docs/PLAN.md` §4, report in §6): typed hanzi and pinyin
  are matched with the proposal's rules (variants count, near misses get
  half and go to the teacher), new types `type_pinyin` and `essay`, free
  writing is 10 points and marked by a teacher with the rubric, one
  **Penilaian / Marking** queue for tests and packages, results wait as
  "Menunggu penilaian" until marked.
- Build 1 follow-ups: emulator password `emulator-only-7`, End test keeps
  typed answers, an hourly job closes forgotten sessions, admin Reset
  attempt, QR code of the token.
- Walked on the emulators in the browser pane (student, teacher, admin;
  English light and dark, Indonesian, 360 px). Fixed what the walk found:
  the end-test message count, the dialog text, the Marking page title, a
  wrapped rubric label.
- Proof: analyzer 17 infos; `flutter test` 105; rules tests 56 + 1 skipped;
  node tests; PN-01 fixture 6 of 6; flow test 32/32.
- Not deployed: the owner deploys rules, indexes and functions (command in
  the changelog), then hosting from the Mac.

### 2026-11-17 — Claude (PLAN chat, Mac): Build 1B reviewed, hosting live

- Pulled Build 1B (v0.1.17) and checked it on the Mac: analyzer 17 infos,
  `flutter test` 100, node tests, rules tests 53 pass and 1 skipped.
- Read the backend changes: the transcript is stored on bank questions
  (staff-only read), the player gets questions through `stripQuestion` (a
  fixed list of fields), so students receive the transcript only from
  `getTestReview` after the session is closed. Storage rule: `audio/*` under
  60 MB, every other file under 10 MB, staff only.
- Published hosting from the Mac (`scripts/deploy_web.sh --web-only
  --no-keys`); **Scan paper** is on live. Still open for the owner:
  `firebase deploy --only storage,functions:getTestReview --project chinese-tracker`.
- The reader's measured quality (about 37 of 80 questions right as read) is
  written into `docs/PLAN.md` as **Build 1C — Reader accuracy**, after Build
  2A. A quick check showed that reading without the English model changes
  nothing but the speed.

### 2026-11-17 — Claude (BUILD chat, PC): Build 1B built-in HSK paper reader

- Built Build 1B (`docs/PLAN.md` §4, report in §6): **Scan paper** reads a
  scanned HSK PDF in the browser (watermark removed, page mode 6, picture
  boxes by image analysis), builds 80 slots from the HSK format, and opens a
  proofreading screen; the answer key takes writing answers; recordings up
  to 60 MB; a transcript per worksheet shown in the review after the
  session.
- Walked on the emulators with the owner's paper `H326202Z` (kept in
  `local_papers/`, git-ignored): read in 30–32 s, 40/30/10, 11 pictures,
  saved, key, 12 MB recording, transcript, test code HSK 3, a session to the
  result card and the review.
- Proof: analyzer 17 infos; `flutter test` 100; rules tests 53 + 1 skipped;
  node tests; flow test 24/24.
- Not deployed: the owner deploys storage rules and `getTestReview` (command
  in the changelog), then hosting.

### 2026-11-17 — Claude (PLAN chat): why the AI scan fails, Build 1B

- Owner: nothing of Build 1 can be used without scanning a real HSK paper
  (`H326202Z`, 16 scanned pages) and the AI scan fails on live.
- Proven on the Mac: AI Logic answers `401 Firebase App Check token is
  invalid` without a token; the live site has no App Check key. The model
  name is valid. Fix: the owner creates the reCAPTCHA Enterprise key and
  registers it (10 minutes), the PLAN chat deploys with it.
- Also found: the listening recording is limited to 10 MB (too small for an
  HSK recording), and the importer drops questions it cannot build without
  saying so.
- `docs/PLAN.md` §4: new **Build 1B** (NEXT); Build 2A follows in the same
  session.
- Later the same day the owner decided: papers are read **inside the app,
  no outside API**, and each recording gets a transcript. Build 1B was
  rewritten as the built-in paper reader. Measured on the Mac with the
  app's own engine (tesseract.js 5): dense pages read well as scanned;
  sparse pages (word bank, word order, pinyin gaps) read well only after
  removing the coloured watermark and with page mode 6; pinyin tone marks
  are not read; pictures need image analysis. Numbers in the plan.
- The owner puts `H326202Z.pdf` on the PC in `local_papers/` (never
  committed).

---

### 2026-11-16 (night) — Claude (PLAN chat): Build 1 is live

- The owner ran `firebase deploy --only firestore:rules,functions` on the
  Mac: 7 test functions created, 15 updated, 22 on live.
- PLAN chat published hosting from the Mac
  (`scripts/deploy_web.sh --web-only --no-keys`). The Mac's `deploy.env`
  (placeholder text only) was removed first.
- Still off on live: AI paper scan and push (no App Check key, no web push
  key yet).
- Found: the Android APK is not on live. Web-only deploys publish without
  it and the landing page hides the download button. The last APK build is
  from 2026-11-12. Owner to decide when to rebuild and publish it.
- Next: the owner tests one real session on live, then says "go" in the
  BUILD chat for Build 2A.

---

### 2026-11-16 — Claude (BUILD chat, PC): Build 0 and Build 1

- Build 0 on the PC: Node 22 and firebase-tools installed (owner approved),
  analyzer / tests / rules / emulators / seed all run; PC quirks in
  CLAUDE.md (Flutter short path, JDK socket folder, `py`).
- Build 1 committed (029c9d8): supervised tests with test codes, part
  clocks, supervision, result card + PDF, review; 7 new functions, rules
  for 5 collections. Report in `docs/PLAN.md` §6.
- Not deployed: the Firebase CLI on the PC is not signed in; rules and
  functions wait for the owner's deploy command.
- Incident: an emulator reload signed the test admin in to live Auth
  (no data touched). Guarded now; details in PLAN.md §6.

---

### 2026-11-16 — Claude (PLAN chat): rundown, two-chat workflow, questions

- Backups confirmed on live: 3 nightly Firestore backups READY (13–15 Nov).
- Owner decision: plan in a Fable chat, build in an Opus chat. New
  `docs/PLAN.md` holds the state rundown, the build queue (nothing marked
  NEXT yet), 16 questions for the owner, and the report template. CLAUDE.md
  "Read first" and conventions point to it.
- Not done by the owner yet: `deploy.env` keys (AI Logic / App Check / push),
  Midtrans sandbox test, live tests of exam mode and the APK.
- Owner answered the 16 questions the same day. `docs/PLAN.md` rewritten:
  decisions (§2), the test-track design (§3), Build 0 and **Build 1 marked
  NEXT** in full, Builds 2–8 as outlines, open questions (§5), thesis needs
  (§7). The BUILD chat will run on the PC.
- Evening: BUILD chat is up on the PC (Build 0 passed, Build 1 running) and
  the message link works both ways. Owner's second answers and documents
  (revised proposal, decree, campus templates, HSKK and HSK 3.0 papers) went
  into `docs/PLAN.md`: decisions 11–16, exact formats, the proposal's
  scenario IDs per build, differences between the proposal and the newer
  wishes, Build 1 changes (Enterprise App Check provider, part clocks on or
  off, review after the session, HSK Simulation only through test codes),
  Build 2 with the typing matcher, Tugas Akhir facts and calendar.
- Night: Build 1 arrived (v0.1.16, not deployed). PLAN chat reviewed it on
  the Mac (analyzer baseline, 83 tests, node tests, the functions and rules
  read line by line) and wrote **Build 2A** (typing matcher, marking,
  Build 1 follow-ups) in full as NEXT; Build 2B holds leaderboard,
  promotion and names. BUILD reported signing the live test admin in by
  accident from an emulator bundle (no data touched, guard added); Build 2A
  separates the emulator password from the live one.

### 2026-11-13 (day) — Claude: HSK simulation, AI paper reader, teachers' packages, App Check + push

- Owner: items 6 and 7 "go for it"; a scanned HSK 3 paper (H326202Z, 16
  pages) was "not readable" by the scanner (8-page OCR limit); wants pictures
  cut into the questions, a listening upload, an HSK simulation.
- Three tracks (two agents in worktrees, merged): **teachers build and
  assign their own packages** (bank stays admin-only); **App Check + web
  push reminders** (keys from the console, feature off until set);
  **HSK simulation**: AI paper reader (Gemini via Firebase AI Logic), a
  picture per choice, part headings, listening recording per worksheet,
  Answer key dialog, player with audio + picture grid + HSK marks per part.
  Change log has the detail.
- Proof: analyzer baseline, 74 Flutter tests, rules tests 41 pass /
  1 skipped, function tests, emulator walk (HSK-style sheet seeded by REST).
- **Owner to do** (plain steps in the change log and
  `docs/OWNER_PROCEDURES.md`): Firebase console → AI Logic *Get started* +
  App Check web key (`deploy.env`); Cloud Messaging web push key; the
  Midtrans sandbox test; the one-command Firestore backup schedule.
- Owner ran `firebase deploy --only firestore:rules,functions`: rules
  released, 14 functions updated, `dailyReminders` and
  `onNotificationCreated` created. Teacher packages, marks per part and
  push triggers are live.
- Owner ran the backup command: Firestore scheduled backup created (daily,
  7-day retention). `scheduledFirestoreExport` removed from the code and deleted on live
  (owner's `firebase deploy --only functions`: 15 updated, 1 deleted).
- Not possible from here: a live Firestore read (item 2, old-format
  exercises) was refused by the sandbox.

### 2026-11-13 — Claude: exam mode, rate limits

- Owner: "go for it" on the recommendation list. Built one-attempt exams
  with a server clock (Exam / HSK Simulation packages), closed the exam key
  oracle, rate-limited the public code resolvers. Change log has the detail.
- Owner ran `firebase deploy --only firestore:rules,functions --project
  chinese-tracker`: rules released, all 14 functions updated. Exam mode,
  rate limits and the 2026-11-12 hardening are live. APK rebuilt and live.
- Not done (needs the owner or a decision): App Check (console setup),
  web push reminders (VAPID key from the console), teachers building
  packages (owner's earlier decision keeps authoring admin-only).

### 2026-11-12 — Claude: scores locked to the server, explanations

- Owner deployed yesterday's functions, then approved the recommendation list
  ("implement what needs no input; list the rest").
- `exercise_results` is now function-only in the rules; the client-side
  scorer is gone; old-format exercises show an "Old exercise format" message
  and are labelled in the Exercises table for deletion.
- Question explanations: bank editor field, returned by `finishExercise` in
  the review only, shown on the result page.
- Attendance Present / Excused / Absent already exists in the conclude dialog
  (`ConcludeClassDialog`); the audit row was stale. No edit after conclude.
- Proof: analyzer baseline, 65 tests, rules tests 30 pass, function test
  passes, emulator run of the player (explanation shown, old format blocked).
- Rules and functions deployed by the owner in the 2026-11-13 session.
  Owner still to delete the old-format exercises on live.
- **Still needs the owner:** Midtrans sandbox end-to-end test (owner clicks,
  Claude watches logs); nightly backup IAM fix in the Google Cloud console
  (CLAUDE.md "Known blockers").
- Later: Indonesian for admin, teacher and question bank screens (five
  parallel agents in worktrees, merged by key union; ~1,070 new keys),
  Language row on both staff profiles, `Intl.defaultLocale` follows the
  switch. See the change log for what stays English.
- Night: full recheck (diff review + backend security review + emulator
  walk of every role). Backend hardening in rules, storage rules and
  functions (see the change log), rules tests 36 pass. Deployed by the owner
  in the 2026-11-13 session.
- **Bab I in the campus template (15:20).** Owner uploaded `[TEMPLATE] BUKU TA - TESIS.dotx` and asked for Bab I in it. Built `docs/thesis/word/BAB I PENDAHULUAN.docx` with `docs/thesis/tools/build_bab.py` (stdlib Python: keeps the template's styles, numbering, headers, footers and page setup; adds per-chapter numbering for 1.3.x headings and restarting numbered lists; `[ISI]` gaps highlighted yellow; Gambar 1.1 Waterfall drawn as `word/fig_1_1.png`; unused template pictures and sample footnotes stripped). Checked: zip and XML valid, 2,318 words = the draft, page 1 rendered by QuickLook. Pages could not export a PDF (AppleEvent timeout), so pages 2+ are checked only by structure; the owner checks in Word. Template is not committed (`docs/thesis/local/` ignored).
- **Whole book in one Word file (16:00).** Owner asked for cover to end. `docs/thesis/tools/build_book.py` builds `docs/thesis/word/BUKU TA Easy Study.docx` from the template: cover table and approval page with the real title, name, NRP, supervisors (examiners yellow), surat pernyataan, drafted Abstrak/Abstract with keywords, Kata Pengantar, Daftar Isi/Gambar/Tabel/Algoritma/Segmen/Rumus with PAGEREF fields on 123 bookmarks (Ctrl+A, F9), Bab I–III from the drafts (tables in the template's table format, two formulas as equations, 9 yellow figure placeholders in Bab III), skeleton Bab IV–VIII (sub-bab headings from the guide with yellow notes), numbered Daftar Pustaka, Riwayat Hidup with a placeholder photo; 12 sections copied from the template (Roman front matter, Bab I restarts at 1). Checked: package and XML valid, every PAGEREF resolves, cover page rendered. Open point for the supervisor: citations are `[n]` in the text while the campus footnote rule exists.


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

### 2026-11-11 — Claude: player checks at the end, timer, review, exercise history

- Student player: answer all questions, Submit once, review page with the right
  answers, clock in the header, optional time limit per package (counts down,
  auto-submits). `finishExercise` returns the review and stores correct / total /
  time / title / type on the result. Progress tab: Exercises history segment.
- Functions and hosting deployed 2026-11-11 (owner OK'd the functions deploy).
- Owner decisions 2026-11-11: checking at the end for every type of exercise;
  parent stays an optional add-on account, invoices stay on the student and a
  linked parent may pay them.
- Later the same day: History tab (vouchers with their classes, all classes by
  month; same section on the parent overview), parent Pay now, "payments
  handled by <parent>" note for linked students, admin Users role chips with
  counts and parent/child lines, compact student home with tiles, streak, stars
  and confetti. Hosting deployed.
- Owner ran `firebase deploy --only functions --project chinese-tracker`
  (Claude's sandbox refuses production function deploys): all 14 functions
  updated. Live now: `finishExercise` review + time on results, `linkChild`
  parent stamp. Owner tests on the live site next.

### 2026-11-10 (night) — Claude: precise admin tables

- Exercises table: Type (from the bank) and Due (overdue count) columns.
- Admin student page at `/admin/users/:id` with Payments and Attendance.
- Tick rows for bulk actions on Users, Exercises and Question bank.
- Export CSV on every admin table; dashboard Income / mo shows real money
  with a twelve-month detail page.
- Deployed to hosting the same night (v0.1.10). Owner decision 2026-11-11:
  Claude deploys hosting after every push from now on (see CLAUDE.md).

### 2026-11-10 (evening) — Claude: asset caching fix, bank picker filters

- `/assets/**` no longer cached for an hour (stale icon font after deploy).
- Bank picker in the exercise form: filters, edit pencil, Scan worksheet.

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
