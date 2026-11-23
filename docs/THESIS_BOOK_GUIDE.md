# Tugas Akhir guide — what the thesis needs, from the owner's own documents

Written by the PLAN chat on 2026-11-23 from the files the owner gave Claude:
the revised proposal packet (`221310660_Wilsin_3.pdf`, 87 pages: form F-048,
the examiners' decisions of 7 October 2026 with the answers, the revised
proposal), the campus book kit (`CEK BUKU MANDIRI V4`: templates, self-check
criteria, binding dividers), the BAA guide for the final PDFs
(`185-BAAPetunjukPembuatanPDFTATesis2024.pdf`), the campus forms
(`S1 dan D3` folder) and one finished campus book as a model
(`219180465`, Toko Emas Diamond, 225 pages, 8 chapters).
Nothing here is a campus rule that Claude invented: every rule below is in
one of those files. Where the owner must still decide, it says so.

Read this once, then use §9 (the to-do list) and §10 (the inputs).

---

## 1. The thesis in one paragraph

**Aplikasi Multiplatform Sistem Kursus Bahasa Mandarin Easy Study menggunakan
Flutter.** Wilsin, NRP 221310660, PROG PROF S1 INFORMATIKA, ISTTS.
Supervisor Ong, Hansel Santoso, S.SI., M.Kom.; co-supervisor Prof. Dr. Ir.
Esther Irawati Setiawan, S.Kom., M.Kom. Proposal defended 7 October 2026,
status *diperbaiki*, revisions accepted, Kaprodi decision printed 21 October
2026, decree 710/23/ISTTS/SKEP/X/2026 of 22 October 2026. **Seminar
registration opens 2027-02-22 and closes 2027-10-22.** The form of September
2026 records 131 SKS passed and IPK 3.32.

The thesis is **three things**, all graded: the app (built, live since
2026-11-21, eight builds), the **trial** with 35 real people at the centre
(January 2027), and the **book** with its abstract, article and poster
(December 2026 to February 2027). The app is done. The other two are not
started.

## 2. What the examiners demanded (the contract)

These are the written conditions from the proposal defence. The book must
show each one was met; the examiners will look for them first.

| Who | Condition | Where it is met in the app | Where to prove it in the book |
|---|---|---|---|
| Reviewer 1 (Suhatati Tjandra, *perbaikan bersyarat*) | Title consistent; focus = course system, not "management" | Scope fixed in the proposal | Bab I (Tujuan, Ruang Lingkup, Batasan) |
| Reviewer 1 | Difference between **jadwal** and **sesi** | `schedules` vs `class_sessions` (Build 6) | Bab V design + one table |
| Reviewer 1 | Describe the current system: 4 teachers, substitute teacher, students do not pick teachers, overlapping schedules | Builds 6 and 7 (`substituteCandidates`, `assignSubstitute`, conflict check) | Bab III (old system), Bab V |
| Reviewer 1 | Comparison apps must be comparable | Teach 'n Go and HelloChinese (proposal Tabel 16), Jesslyn's TA (Tabel 17) | Bab IV |
| Reviewer 1 | Trial scenario clear: levels, enough teachers, number of questions | 35 respondents, 731 questions (`docs/TRIAL_KIT.md`) | Bab VII |
| Reviewer 2 (Esther, co-supervisor) | **Scoring on the server**, never in the Flutter client | `finishExercise`, `submitTestPart`; keys never leave the server; rules block client writes to results | Bab V (architecture, rules table), Bab VI (program segment), Bab VII PN-04 |
| Reviewer 2 | **Voucher deduction in one strong transaction**, safe when close and booking happen together | `closeSession`: one transaction, ledger id `{sessionId}_{studentId}`, idempotent (Build 7) | Bab V, Bab VI segment, Bab VII VC-01..VC-05 |
| Reviewer 2 | **Typing answer matching algorithm** specified: exact or tolerant | `functions/typing_matcher.js`: full-width punctuation, traditional characters, tone numbers = right; one wrong character or wrong tone = half and flagged; essay marked by teacher (Build 2A) | Bab V (the rules as a table), Bab VI, Bab VII PN-01..PN-03 |
| Reviewer 2 | **Functional validation besides SUS**: scoring accuracy, voucher deduction, Midtrans status | The 24 scenario IDs (PN, TS, LV, LB, PL, VC, MT, JD) with node tests, rules tests and the 91-step emulator flow | Bab VII, one table per group |
| Reviewer 3 (Herman Budianto, *diterima*) | State the HSK range; at least 30 users of mixed levels | HSK 1 to 6; 30 students 12/10/8 + 4 teachers + 1 admin | Bab I, Bab VII |
| Reviewer 4 (Herman Thuan To Saurik) | **Student progress report** | `progress_summary`, five warnings, report widget and print (Build 4) | Bab V, Bab VI, Bab VII |
| Sidang decision | Teacher scheduling and its checks in detail | `saveSchedule` with `schedule_locks`, availability, gap, room (Build 6) | Bab V, Bab VII JD-01, JD-02 |
| Sidang decision | Scoring per HSK level explained | pass 120/200 or 180/300, 3 different codes, admin approves (Build 2B) | Bab V |
| Sidang decision | Use and explain Firebase Cloud Functions | 60 functions on live | Bab II theory, Bab V table of functions |
| Sidang decision | Question types clear | Listening, Reading, Typing; forms L1..T5 (proposal Tabel 9 to 11) | Bab V |
| Sidang decision | Old vs new system plus comparison apps | proposal Tabel 1, 2, 16, 17 | Bab III, Bab IV |

Everything in the left column already exists in the app. The book's job is
to describe it in the campus format and to report the trial.

## 3. What the proposal promised for the trial

From proposal §V (pages 44 to 47 of the revised proposal):

- **35 respondents at Easy Study**: 30 students (Beginner HSK 1–2: 12,
  Intermediate HSK 3–4: 10, Advance HSK 5–6: 8), all 4 teachers, 1 admin.
  Payments in Midtrans **sandbox**.
- **Question bank for the trial**: 1 practice package of 15 questions per
  level (90) + 1 test code per level in full format (40+60+80+100+100+101 =
  481) + 2 more HSK 3 codes (160) = **731 questions**, imported with the
  import tool. The 731-row checklist is `docs/trial/question_checklist.csv`.
- **Four methods**: (1) black-box per feature, normal case and refused case;
  (2) functional validation, the 24 scenarios of Tabel 19, plus **PN-01: 200
  test answers scored by the system and by a teacher, accuracy = same ÷ 200 ×
  100 %, target 100 %**; (3) user-based testing, the task table per role
  (Tabel 20; sheets in `docs/trial/task_sheet_*.html`); (4) **SUS** from all
  35, mean per role, per student level and overall; **accepted if the mean is
  above 70** (Bangor 2008). Formula: SUS = [Σ(odd − 1) + Σ(5 − even)] × 2.5.

**Before the trial (added 2026-11-23):** v0.1.28 put teacher availability,
schedule confirmation, late check-in and the teacher recap behind one
switch, `settings/scheduling.teacherReadiness`, which ships **off**. Switch it
on in Timetable → Timetable rules before the trial and the screenshots,
or JD-01 and the scheduling screens the examiners asked for will not show.
The book describes the switch in Bab V.

The trial kit for all of this is already built (`docs/TRIAL_KIT.md`,
`docs/trial/TRIAL_DAY.md`). What is missing is the day itself: people, date,
devices, the live seed, the 731 questions typed in.

## 4. The book: structure and where each part comes from

The campus template fixes the front and back matter. The chapter list below
follows the finished campus book that the owner gave as a model (8 chapters:
Pendahuluan, Teori, Proses Bisnis, Analisa, Desain, Implementasi, Uji Coba,
Penutup) and puts the proposal's sections into it. Confirm the chapter list
with the supervisor before writing; some supervisors merge III and IV.

**Front matter (from `[TEMPLATE] BUKU TA - TESIS.dotx`):** Halaman Judul ·
Halaman Pengesahan (pembimbing, co-pembimbing, penguji I to III) · Surat
Pernyataan Keaslian · Abstrak · Abstract · Kata Pengantar · Daftar Isi ·
Daftar Gambar · Daftar Tabel · Daftar Algoritma · Daftar Segmen Program ·
Daftar Rumus. Roman page numbers.

| Bab | Content | Source already written | Still needed |
|---|---|---|---|
| **I Pendahuluan** | 1.1 Latar Belakang; 1.2 Tujuan (the 5 goals); 1.3 Ruang Lingkup: 1.3.1 Role (admin, guru, murid), 1.3.2 Batasan Sistem; 1.4 Software yang Digunakan; 1.5 Metodologi (Waterfall); 1.6 Sistematika Pembahasan | Proposal §I, §II, §IV.L, §V | Centre facts: founded when, address, students per level, classes per week |
| **II Teori Penunjang** | Dart, Flutter, multiplatform, Firebase (Firestore, Auth, Storage, FCM), Cloud Functions (4 trigger kinds), Midtrans Snap + webhook, NoSQL, MVVM with Provider, HSK (6 levels, 200/300, 60 %), SUS, black-box testing; add Firestore Security Rules, Firestore transactions and idempotency, Levenshtein and OpenCC for the typing matcher | Proposal §III and its 20 references | Newer references (the 2025 feedback said no Google or YouTube as sources) |
| **III Proses Bisnis** (old system) | Easy Study today; the manual flow (WhatsApp, student list in a spreadsheet, **no teacher schedule at all** (owner 2026-11-24), paper attendance, transfer proof, paper tests, the old "Nilai Simulasi HSK" page); rich picture, use case and activity diagram of the old way; the problems | Proposal §IV.A (Tabel 1 and 2) | Photos or screenshots of the old tools (names hidden); numbers per month (payments, tests) |
| **IV Analisa Sistem** | Fact gathering (interview with the admin and teachers, document analysis), problem list, comparison with Teach 'n Go, HelloChinese and Jesslyn's TA, requirement specification per role | Proposal §IV.A, §IV.M (Tabel 16, 17), §IV.I (roles) | Short interview notes with dates (appendix) |
| **V Desain Sistem** | New system description; jadwal vs sesi; scheduling checks; voucher consistency; question types; level and scoring rule; progress report; use case and activity diagrams per role; architecture (Flutter MVVM, FlutterFire, Functions, Midtrans); data design = Firestore collections with the **real names** (§5 below); security rules table; functions table; interface design (wireframes, then the real screens) | Proposal §IV.B to §IV.K, §IV.N; `docs/CLAUDE_FULL_HANDOFF.md`; `firestore.rules`; `functions/index.js` | Diagrams redrawn with the real names (draw.io) |
| **VI Implementasi** | 6.1 Implementasi desain: one screen per feature per role with a screenshot and a paragraph; 6.2 Implementasi program: program segments of the parts the examiners asked about: `closeSession` transaction, `typing_matcher.js`, `saveSchedule` conflict check, promotion counter, placement rule, Midtrans signature check, rules excerpts, `finishExercise` | `docs/screenshots/proposal/` (13 of 15 shots), the `functions/*.js` pure-logic modules, build reports in `docs/PLAN.md` §6 | 2 missing screenshots; segments trimmed to the lines that matter (Courier New 10) |
| **VII Uji Coba** | 7.1 Kompatibilitas (Chrome, Edge, Safari, Android, iPhone Safari web, screen sizes); 7.2 Black-box per role (normal + refused case); 7.3 Validasi fungsional: the 24 scenarios with the result and the proof (node test, rules test, emulator flow, live); PN-01 accuracy with 200 answers; 7.4 User-based testing: tasks done, problems seen; 7.5 SUS: table per respondent (appendix), mean per role, per level, overall, verdict | `docs/trial/blackbox_template.md`, the acceptance walks in `docs/PLAN.md` §6, `functions/test_*.js`, `docs/trial/sus_results_template.csv`, `tool/sus_score.mjs` | **The trial** (January 2027) |
| **VIII Penutup** | 8.1 Kesimpulan: one line per goal of Bab I, with the number that proves it (accuracy %, SUS mean, scenarios passed); 8.2 Saran: from the SUS comments and the extras outside the thesis | | After the trial |

**Back matter:** Daftar Pustaka (alphabetical, TNR 12, spacing 1.0, one
blank line between entries) · Riwayat Hidup · Lampiran, each with a cover
page "LAMPIRAN A / JUDUL" and pages A-1, A-2: A diagrams that need a full
page (Firestore structure, use cases), B long program segments, C respondent
list (names may be initials), D SUS answers per respondent, E black-box
tables, F the 731-question checklist, G the interview notes.

**Stays out of the book** (owner decision, proposal limits): the English UI
switch, the parent role, the materials library, class modes, HSK 3.0 and YCT
papers, the in-app paper reader (OCR) and the AI scan, dark mode. Mention
them in Saran at most.

## 5. Name mapping: proposal names → real names in the code

The proposal used Indonesian names. The code uses English names. The book
describes the real system, so use the real names and add this table once
(Bab V) so the examiners can follow.

| Proposal | Real collection or place |
|---|---|
| users | `users` (+ `users/{uid}/level_history`) |
| ketersediaan_guru | `users.availability`, `teacher_days_off` |
| ruang | `settings/rooms` (Main, Sub Room) |
| jadwal | `schedules` (+ `schedule_locks`, `schedule_change_requests`) |
| sesi + peserta | `class_sessions` + `attendance` |
| paket_voucher | `settings/pricing.items` |
| voucher | `student_class_terms` (totals, used, booked, deadline) |
| riwayat_voucher | `voucher_history` (id `{sessionId}_{studentId}`) |
| pembayaran | `invoices` |
| soal, kunci_jawaban | `question_bank` (staff-only read; students get questions only through functions, keys never) |
| paket_soal | `exercises` (practice), `test_codes` + `test_formats` (simulation and placement) |
| pelaksanaan_tes | `test_sessions` (token) |
| jawaban_murid | `test_attempts`, `exercise_attempts` |
| nilai | `test_results`, `exercise_results`, `marking_items` (teacher review) |
| leaderboard | `leaderboards/{codeId}/entries/{uid}` |
| kenaikan_tingkat | `level_promotions`, `promotion_progress` |
| progress_summary | `progress_summary`, `progress_notes` |
| pengaturan | `settings/*` (promotion.minCodes, rooms, pricing, scheduling) |
| (new) | `placement_results`, `teacher_recaps`, `reports/{yyyyMM}`, `notifications`, `audit_logs` |

| Proposal function (15) | Real function (60 on live) |
|---|---|
| checkScheduleConflict | `checkScheduleConflict`, `saveSchedule` (check inside the transaction) |
| generateSessions | `generateSessions` |
| bookSession | `bookSession`, `cancelBooking` |
| sessionReminder | `sessionReminders` |
| checkTeacherCheckIn | `checkTeacherCheckIn`, `checkInSession` |
| closeSession | `closeSession` (+ `reconcileVouchers`, `teacherRecap`) |
| openTestSession | `openTestSession`, `startTest`, `submitTestPart`, `reportTestEvent`, `closeTestSession`, `closeForgottenTestSessions` |
| gradeSubmission | `submitTestPart` (tests), `startExercise` / `finishExercise` (practice), `markAnswer` (teacher) |
| updateProgressSummary | `onExerciseResultWritten`, `onAttendanceWritten`, `onClassTermWritten`, `onProgressNoteWritten`, `rebuildProgressSummaries` |
| checkLevelPromotion, updateLeaderboard | `onTestResultWritten`, `decidePromotion` |
| (placement) | `placementMenu`, `startPlacement`, `submitPlacementPart`, `resolvePlacementResult`, `registrationPlacement`, `decideRegistration` |
| createMidtransTransaction | `createInvoice` (Snap token), `markInvoicePaid` (cash) |
| midtransNotification | `midtransNotification` |
| expireVouchers | `expireVouchers` |
| monthlyReport | `monthlyReport`, `rebuildMonthlyReport` |

## 6. Format rules (from `KRITERIA CEK BUKU MANDIRI` and the templates)

The campus checks format with a *dosen korektor buku* (form F-076) before
the PDFs are accepted. The template's own note: copy the **formatting**, not
the content; everything in yellow must be replaced.

- **Word 2013 or newer**, never WPS or Google Docs. **One file per chapter**
  and per front-matter part.
- A4 portrait; margins top 4, left 4, bottom 3, right 3 cm; header 2.5 cm,
  footer 1.5 cm. Page number: first page of a chapter centred in the footer,
  other pages right in the header. Roman numbers for the front matter.
- Times New Roman 12, line spacing 1.5, before/after paragraph **0**,
  justified, first line indent 1.27 cm.
- Chapter title: TNR 16 bold, centred, UPPER CASE, Roman chapter number on its
  own line. Sub-heading: TNR 14 bold, left, Capitalize Each Word, hanging
  indent 1.27 cm.
- Captions TNR 12 bold centred, spacing 1.0, numbered per chapter (Gambar
  4.1, Tabel 4.2). Figure caption **below**, table caption **above**. A table
  that continues gets "Tabel 4.2 (Lanjutan)" and repeats its header.
- Never put a figure, table, segment or formula directly after a heading:
  at least one paragraph first. Nothing may fill a whole page (then it goes
  to an appendix). Pictures compressed in Word, in line with text, inside the
  margins. A picture of a table is not allowed: retype it as a table.
- Program segments and algorithms: Courier New 10, spacing 1.0, numbered lines
  from the template, captioned "Segmen Program 6.1 Nama".
- Formulas with the Equation editor only (Cambria Math 12), numbered (3.1).
- Bullets for unordered points, numbering for steps. Footnotes TNR 10,
  numbered through the whole book, never Wikipedia or blogs; every footnote
  source also in Daftar Pustaka.
- Appendices: cover page per appendix, page numbers A-1 by Page Number
  field; A4 landscape or A3 only in appendices; A3 is not folded.
- Binding dividers (`PEMBATAS ... TUGAS AKHIR`) are printed once for binding
  and never put inside the book.

## 7. The three PDFs, the abstract, the article and the poster

From the BAA guide (`185-BAAPetunjukPembuatanPDFTATesis2024`):

- **Three PDFs for yudisium**: `221310660.pdf` (the book), `ABSTRAK.pdf`,
  `ARTIKEL ILMIAH.pdf`. Each made with Word **Save As → PDF** (not "Save as
  Adobe PDF"), page size 8.27 × 11.69 inch, merged in Adobe Acrobat (combine
  files, bookmarks option off), properties filled **in UPPER CASE**: Title =
  the Indonesian title confirmed by BAA, Author, Subject = TUGAS AKHIR /
  ABSTRAK TUGAS AKHIR / ARTIKEL ILMIAH TUGAS AKHIR, Keywords = the article's
  keywords. Book: initial view Bookmarks Panel and Page, single page, Fit
  Page; **bookmarks for every heading** in hierarchy, chapter names in
  UPPER CASE, sub-headings Capitalize Each Word, no numbers, each bookmark
  set to Fit Page. Abstract and article: initial view Page Only.
- **Remove every comment, marker and highlight** from the .docx first.
- **Abstract**: separate template `[TEMPLATE] ABSTRAK UNTUK PDF.dotx`;
  Indonesian and English on separate pages; the English title and the
  translation must be approved by the **ECC lecturer** (the same one as for
  the poster). Minimum 4 keywords.
- **Article**: template `[TEMPLATE] ARTIKEL ILMIAH NOVEMBER 2023.dotx`
  (two columns, abstract 200 to 400 words, 4 or 5 keywords in alphabetical
  order), unless the supervisor wants a journal's template. Form F-069 signed
  by the supervisor.
- **Poster**: consultation form F-033 with content (supervisor), English
  (ECC) and design (DKV) sign-offs. Adobe Acrobat and Word are on the PC.

## 8. The campus steps and forms (what happens around the book)

From the forms in the `S1 dan D3` folder and the academic guide:

1. **Consultations**: card F-026, **at least 10 consultations**, about 70 %
   with the supervisor and 30 % with the co-supervisor. Start now; each
   build report in `docs/PLAN.md` §6 is a good consultation topic.
2. **Seminar attendance card** F-027: attend **3 pra-seminars and 5
   seminars** of other students **before** registering the own seminar.
   Start attending now; registration opens 2027-02-22.
3. **Pra-seminar**: registration F-005 with the supervisor's percentages
   (book % done, program % done); berita acara F-002, valid only for the two
   nearest seminar slots, needs at least one student in the room.
4. **Seminar** in the window 2027-02-22 to 2027-10-22, then revisions.
5. **Format check** by the dosen korektor buku (F-076), article approval
   (F-069), ECC approval of the English title and abstract.
6. **Yudisium**: the three PDFs, the poster, bebas administrasi F-012 (book,
   PDF and poster, lab, library, alumni), title change form F-025 only if the
   title changes.
7. **Graduation requirements** from the academic guide: 144 SKS, IPK at
   least 2.00, at most 18 SKS of D, **5 certified student activities**. The
   form says 131 SKS: check the rest with the dosen wali.

## 9. Order of work (today is 2026-11-23)

| When | Work | Who |
|---|---|---|
| Now | Ask the supervisor two things: the chapter list (8 chapters as the model book?) and the rule on AI help with the text. Start the consultation card and the seminar attendance card. | Owner |
| Now to early December | The seven live owner tasks (security first) and the live test walk; Build 9 "live fixes" if the walk finds bugs | Owner, BUILD chat |
| December | Bab I to V drafted from the proposal and the docs; diagrams redrawn with real names; Bab VI screenshots and segments | PLAN chat drafts, owner rewrites and checks |
| December | Gather the centre facts and photos (§10), set the trial date, invite the 35 people, type the 731 questions | Owner |
| Second half of January 2027 | The trial at the centre: live seed, task sheets, SUS, PN-01 with a teacher, black-box tables filled | Owner with the kit |
| Late January | Bab VII from the trial data, Bab VIII, abstract, article, poster draft | PLAN chat drafts, owner finalises |
| February | Format pass against the criteria, the three PDFs, pra-seminar; seminar registration when the window opens 2027-02-22 | Owner |

## 10. What the owner must give (nothing can replace these)

1. The supervisor's answer on chapter structure and on AI-assisted writing.
2. The centre today: number of active students per level group, the four
   teachers and the levels each teaches, classes per week and seats per
   class, payments and simulation tests per month, founding year and
   address, photos or screenshots of the old tools (schedule spreadsheet,
   paper attendance sheet, a WhatsApp registration chat with names hidden,
   the old "Nilai Simulasi HSK" page).
3. The trial: a date when 30 students can come, which devices they use, who
   plays admin, the respondent list (git-ignored `scripts/trial/*.local.*`).
4. Dates as they come: consultations, pra-seminar, seminar.
5. Whether the article goes to a journal or stays on the campus template.
6. A Word copy of the revised proposal, to reuse its figures and tables
   (the PDF is already read).

## 11. Who writes what

The owner writes and defends the book. The PLAN chat prepares: outlines,
tables, the name mapping, first drafts of descriptive chapters from the
docs, the scenario and SUS tables from the trial data. Nothing goes into the
book that the owner has not read and can explain at the seminar: at the
defence the examiners pick any screen, rule or function and ask how it
works. The BUILD chat never touches the book.
