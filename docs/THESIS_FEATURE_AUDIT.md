# Audit: Easy Study app vs. the thesis feature backlog

**Date:** 2026-10-16, updated 2026-10-18 for spec v2 · **Spec:** `docs/THESIS_FEATURE_BACKLOG.md` (v2, 18 Oct 2026) · **Assets brief:** `docs/THESIS_PROPOSAL_ASSETS.md` · **By:** Claude
**Method:** read the real code (models, services, screens, `functions/index.js`, rules, tests), not the docs.

## 0. Update for spec v2 (18 Oct 2026)

Version 2 keeps Phases 1–4 and 7–9 as they were and replaces the grading model.
Sections 1–7 below were written against v1 and still hold, except where this
section says otherwise.

### What v2 changed, and where the app stands

| v2 item | App today | Gap |
|---|---|---|
| **Promotion = pass ≥ 3 different HSK test codes** at the current level (≥120 of 200 for HSK 1–2, ≥180 of 300 for HSK 3–6), then admin verifies; count resets per level | No test codes, no pass marks, no promotion. `users.level` is a free string the **student can edit** (`student_profile_tab.dart`, rules allow it) | Missing |
| **Test code** (e.g. `H3216917Z`), one question set per code, each code once per student | No concept of a test code; quizzes are per lesson, exercises per teacher | Missing |
| **Supervised test**: `openTestSession` gives a 6-char token valid 15 min; test mode records "left the page" events; teacher supervision screen; result can be marked **tidak sah** | Nothing. Exercises and quizzes can be done anywhere, any number of times | Missing |
| **Test format per HSK level** (40/60/80/100/100/101 questions, 35–135 min, objective = 1 pt, T5 = 10 pt) | No timer, no sections, no per-level format | Missing |
| **Leaderboard per test code** (`leaderboard/{kodeTes}/entri/{muridId}`, names masked for students, own row highlighted) | Nothing | Missing |
| **Placement test** at registration: "Mulai dari HSK 1" or "Ikut tes penempatan" + target HSK 2–6; later take one code of the level below the target | Register screen lets the student pick any HSK level directly | Missing (and the current behaviour contradicts v2) |
| **Practice**: 1 package of 15 questions per level, built by the teacher from the bank | Exercises are built by **admins only** (web) and assigned per student with a due date; teachers can only assign | Partly, with the roles reversed |
| **Settings**: pass marks and minimum number of codes editable by admin | `settings/org` has 5 booleans | Missing |
| **Progress report**: "2 of 3 codes passed", test history with leaderboard rank; warning 5 = failed 2 tests in a row | Progress tab is a list of lessons/terms; no summary doc, no chart | Missing |
| **Import of old results** from the "Nilai Simulasi HSK" project (`easy-study-hsk`) | Nothing; access to that project not yet checked | Missing, needs owner's go-ahead |
| **Rules** for `leaderboard`, `pelaksanaan_tes` (tokens), `nilai` (teacher marks invalid) | Collections don't exist | Missing |
| **Question bank target**: 731 questions (90 practice + 481 full-format codes + 160 extra HSK 3) via CSV/JSON + audio import tool | Paste and PDF/image/DOC OCR import only; no CSV/JSON, no batch audio; no form codes L1–T5 | Partly (import), Missing (forms) |

### Dropped by v2 (no longer to be built)

NA formula, NL/NU/NG, teacher rubric score, grade bands A–D, remedial retake.
The §7 rows "P6 Teacher enters NG rubric", "P6 calculateFinalScore", "P6 Remedial
retake" and "P6 Admin screen to edit weights" are superseded by the table above.

### App features v2 now lists as out of scope

| App feature | Where | v2 says | Suggested handling |
|---|---|---|---|
| Gradebook with letter grades A–E | `teacher_grades_tab.dart`, `grades` | "no report cards" | Keep for the centre's own use, leave out of the thesis, or hide behind a setting |
| Evaluations (1–5 rating, strengths/improvements) | `evaluations`, `student_evaluations_section.dart` | "no teacher score (NG)" | Same |
| Materials library | `materials` | "no learning materials" | Keep, outside the thesis (owner decision 2026-10-16) |
| Parent role | `lib/features/parent/` | 3 roles only | Keep, outside the thesis (owner decision 2026-10-16) |
| Class mode online/hybrid | `class_sessions.mode` | "no online classes" | Default to offline; hide the picker |

### Screenshot readiness (assets brief, part B)

| # | Screen the proposal needs | In the app today | Work before a screenshot is possible |
|---|---|---|---|
| 01 | Register with "Mulai dari HSK 1 / Ikut tes penempatan" + target level | Register exists; picks a level directly | Change the form (Phase 1 + placement) |
| 02 | Sesi Kelas: level, time, room, teacher (info), seats left, **Daftar**, rejection reason | `student_join_session_section.dart`: "spots left", Join, "Class is full" dialog | Indonesian text, level filter, teacher name, seats; booking via function (Phase 2) |
| 03 | R1 fill-in-the-blank with pembahasan | **Partly (2026-10-27):** `reading_cloze` is editable (word bank A–F) and playable, and the worksheet scanner imports it; no explanation (pembahasan) field yet | Add pembahasan (Phase 5) |
| 04 | T2/T3 hanzi typing question | Nothing | Build typing forms (Phase 5) |
| 05 | Voucher Kursus: remaining, expiry, history, **Beli** | Term section shows remaining/expiry/visit history; no self-purchase | Add packages + Beli (Phase 4) |
| 06 | Test token entry with code and duration | Nothing | Build (Phase 5 supervised flow) |
| 07 | Leaderboard per code, masked names, own row highlighted | Nothing | Build (Phase 6) |
| 08 | Laporan Progress: "2 dari 3", KPI cards, chart, per-skill, note, test history | List-style progress tab, no chart library | Build (Phase 7) |
| 09 | Guru: Jadwal Mengajar with status, Mulai Sesi / Isi Absensi / Konfirmasi, availability | Classes tab + calendar; no status/check-in/confirm/availability | Build (Phase 2–3) |
| 10 | Guru: supervision screen with big token and "left page" events | Nothing | Build (Phase 5) |
| 11 | Admin: create jadwal with clash warning + free-slot suggestions | One-off session form, no clash check | Build jadwal + `checkScheduleConflict` (Phase 2) |
| 12 | Admin: registration approval with placement choice | Nothing (accounts are active at once) | Build (Phase 1) |
| 13 | Admin: promotion verification "HSK 3 → HSK 4" with 3 passed codes | Nothing | Build (Phase 6) |
| 14 | Admin dashboard: pending registrations, unconfirmed schedules, late check-ins, unclosed sessions, students needing attention | Dashboard with totals, sign-ups, voucher alerts, finance | Rework after Phases 1–3 exist |
| 15 | Admin: Pembayaran with lunas / pending / expire | Invoices tab with Lunas / Menunggu / Kedaluwarsa / Gagal filters (Indonesian since 2026-11-12) | Done for the labels; Phase 4 filters as spec |

Roughly: 2 screens exist in a usable form, 5 exist partly, 8 don't exist. Taking
the 15 screenshots means building most of the Phase 1–7 UI first, on emulator
demo data (the app has no emulator wiring yet).

### Owner's answers (2026-10-18)

1. **Test code:** treat it as a random string. The **admin types the code** and also records the **HSK level** and the **year the code was released** as separate fields. Do not parse level from the code (the spec's "first two characters give the level" does not hold).
2. **Old results project `easy-study-hsk`:** the owner has **no access**. The import script is dropped. The `H3216917Z` leaderboard for the proposal must come from a file the owner supplies, or be demo data.
3. **Simulation papers:** digital audio and answer keys exist. The owner will send examples; design the import tool (CSV/JSON + audio) after seeing them.
4. **Voucher package fields:** name **in Chinese**, validity (e.g. 2 months), **8 or 16 sessions**, and the day/date the student comes (their class slot). Prices and room names: still to confirm when Phase 4 / Phase 1 start.
5. **Grades and Evaluations tabs:** **keep** them (outside the thesis text).
6. Teacher schedule screen tabs vs separate screens: ask when Phase 2 starts.

## 1. The short version

| | Count |
|---|---|
| Items in the spec (phases 1–9, rules, testing) | **70** |
| Done | **8** |
| Partly done (something exists, but not the way the spec wants it) | **23** |
| Missing | **39** |

The app today is a working centre-management tool: accounts, one-off classes, 8/16-session terms, exercises, quizzes, grades, materials, Midtrans invoices, PDF reports. The thesis spec describes a different, more rigorous system on top of it: repeating schedules with conflict checks, booking, teacher check-in, server-side grading with a typing matcher, a final-score formula with promotion rules, a per-student progress summary, and push notifications. Almost all of that is new work.

Roughly: **Phases 1 and 4 are half there. Phases 2, 3, 5, 6, 7, 8 and 9 are mostly new.**

## 2. Problems found that need fixing regardless of the thesis

Ordered by seriousness.

1. **Anyone can register as a teacher.** The Register screen offers "Teacher", and the rules allow it (`firestore.rules` `selfUserCreateValid`). A teacher is staff, and staff can edit any student's session balance (`firestore.rules` terms write rule). Fix: self-registration only for students and parents; admins create teacher accounts (which the admin screen already does).
2. **Answer keys are visible to students.** The correct answers live inside `exercises` and `quizzes`, which every signed-in user can read. Scoring happens in the app, and the rules accept whatever score the student's device sends (`exercise_results`, `quiz_results` create rules). Fix is Phase 5: keys in a separate collection, scoring in a Cloud Function.
3. **Deactivating a user does nothing.** The `active` flag is set by the admin screen but never checked at sign-in, in routing, or in the rules.
4. **Any signed-in user can create a teacher link code pointing at themselves** (`teacher_link_codes` create rule), and `resolveLinkCode` doesn't check that the code's owner is a teacher.
5. **The notifications list is probably broken.** `watchNotificationsForUser` reads the whole `notifications` collection and filters in the app. Firestore rules are not filters, so that query is likely refused for every role. Confirm in the browser console, then fix with a filtered query.
6. **Concluding a class can double-charge.** `concludeClassSession` deducts sessions in several separate writes from the app. Two concurrent concludes, or a crash halfway, can charge a student twice. The spec's `closeSession` function with a fixed-id ledger fixes this.
7. **Joining a class doesn't reserve a session.** The join check only needs remaining > 0, so a student with 1 session left can join five classes. The spec's `sesiDipesan` (booked) counter fixes this.
8. **Nightly database backup has failed every night since at least 13 Oct** (`PERMISSION_DENIED` in the function log). Separate from the spec; needs an IAM role on the function's service account.

## 3. Decisions needed before building (the spec conflicts with the app)

| Topic | Spec says | App has | Options |
|---|---|---|---|
| Roles | admin, guru, murid | also **parent** (Orang Tua): optional add-on linked by the child code; sees the child's history and scores and may pay the child's invoices (2026-11-11) | Kept (owner decision) |
| Scope | no materials, no online/video classes | Materials library; class `mode` online/hybrid | Keep as-is (not described in thesis), or remove |
| Language | all UI text Indonesian | Indonesian + English switch on every screen since 2026-11-12 (`lib/l10n/`); owner chose the switch over Indonesian-only | Decided: Indonesian + English switch |
| Functions | TypeScript | JavaScript (9 working functions) | New functions in TS alongside, convert old ones later · stay JS |
| Architecture | MVVM with ViewModels | widgets call `FirestoreService` directly (48 files, ~98 StreamBuilders) | New and rebuilt screens get ViewModels; old ones migrate as the redesign touches them |
| Teacher sign-up | admin creates teachers | self-registration allowed | Close self-registration (recommended, see §2.1) |
| Student level | admin sets it at approval | student picks it at sign-up and can change it later | Lock `level` to admin writes when the approval flow lands |
| Testing | Firebase Emulator Suite | none; seed scripts hit the live project | Set up emulators first (also fixes "every test touches live data") |

## 4. Names: spec word → what the repo already calls it

Keep the repo names in code; use this table when writing the thesis.

| Spec | Repo | Notes |
|---|---|---|
| guru / murid | `teacher` / `student` (role strings); labels Guru / Murid | Role strings stay English |
| Sesi (one meeting) | `class_sessions` + `attendance` | One-off only; no `level` field yet |
| Jadwal (weekly plan) | — | New |
| Voucher kursus | `student_class_terms` (`packageSize`, `sessionsRemaining`, `sessionsUsed`) | No `sesiDipesan` (booked) yet; expiry only checked in app |
| riwayat_voucher | partly the `attendance` doc (`classTermId`, `sessionCredited`) | New ledger collection needed |
| Paket voucher | hard-coded 8/16 in `app_constants.dart` and `functions/index.js` | New catalog collection needed |
| pembayaran | `invoices` | Webhook already idempotent and signature-checked |
| createMidtransTransaction | `createInvoice` | Staff-only today; students can't buy themselves |
| bookSession / cancelBooking | `joinSession` / `leaveSession` (in-app) | Need to become callables |
| closeSession | `concludeClassSession` (in-app) | Needs to become a callable |
| Bank soal | `question_bank` (+ keys inside `exercises`/`quizzes`) | No form codes, no explanation field |
| kunci_jawaban / jawaban_murid / nilai | — / `exercise_results`, `quiz_results` / `grades` | Keys collection new; results hold only a score |
| NG rubric / evaluations | `evaluations` (1–5 rating, text) | Rubric fields new |
| progress_summary | — (in-app `TeacherAttentionUtils`) | New |
| Ruang (rooms) | free-text `room` on a session | New collection |
| Settings | `settings/org` (5 booleans) | Add `settings/grading`, `settings/scheduling` |
| Notifications (FCM) | in-app `notifications` collection only | `firebase_messaging` not installed |

## 5. Open questions (spec §14) and what is already known

1. **Firebase project:** one project, `chinese-tracker`, Blaze plan, 9 functions deployed (`us-central1`, two triggers in `asia-southeast2`). There is no separate dev project. Emulators would give a local dev environment without a second project.
2. **Midtrans keys:** server key already in Secret Manager as `MIDTRANS_SERVER_KEY`; client key `Mid-client-kQ_Bo0DQepeH8IhU` (sandbox). Nothing to add.
3. **Voucher packages** (names, sessions, validity days, prices): **ask Will.** Today: 8 sessions Rp 800,000 and 16 sessions Rp 1,500,000, 90-day validity, hard-coded.
4. **Room names:** **ask Will.**
5. **Placement test:** **ask Will.** The app has nothing for it.
6. **Ranking / leaderboard:** **ask Will.**
7. **Existing names:** see §4.
8. **Teacher schedule screen tabs:** **ask Will** when Phase 2 starts.

## 6. Suggested order of work

1. **Quick security fixes** (small, independent): close teacher self-registration; enforce `active` at sign-in and in rules; lock `teacher_link_codes` creation to teachers; fix the notifications query. Half a day.
2. **Emulator setup + first rules tests.** Gives a safe place to test everything after it.
3. **Design system** (theme, type, components) in the chosen direction. Restyles every screen at once; new screens are built in it from the start.
4. **Phase 1** (approval flow, rooms, settings docs, teacher levels, FCM, Indonesian text).
5. **Phases 2 → 9** in spec order, rebuilding each existing screen in the new design as its phase touches it, with ViewModels.

## 7. Full status table

Status per spec item. Evidence is `file:line` in this repo.

| Item | Status | Evidence | Existing name |
|---|---|---|---|
| **P1** Email+password auth, role in users/{uid}.role | Done | `auth_service.dart:307-325`; `app_user.dart:32`; `firestore.rules:16-42` | AuthService, `users.role` |
| P1 Student self-registration with pending status + admin notified | Partly | Self-registration via link code (`auth_service.dart:111-162`); no pending status (`firestore.rules` forces active=true); admins get an in-app notification only (`index.js:127-179`) | `register()`, `onUserCreated` |
| P1 Admin approve/reject screen with starting HSK level | Missing | Student picks own level (`register_screen.dart:261`); admin can only edit level or deactivate | — |
| P1 Admin create/edit/delete teacher & student | Partly | Create `auth_service.dart:214-286`; edit `admin_edit_user_screen.dart:95`; no delete; Deactivate not enforced | AdminCreateUser/EditUser screens |
| P1 Teacher profile with teachable HSK levels | Missing | `teacher_profile_tab.dart:108-124` has names, WhatsApp, photo only | TeacherProfileTab |
| P1 Rooms list | Missing | Room is free text (`class_session.dart:75`) | `class_sessions.room` |
| P1 Settings for grading weights/thresholds, check-in limit, min gap, weekly hours | Missing | `settings/org` holds 5 booleans only (`org_settings.dart:17-21`) | `settings/org` |
| P1 Profile screen with photo upload | Done | `profile_photo_service.dart:14-44` | ProfilePhotoAvatar |
| P1 FCM device tokens | Missing | No `firebase_messaging` in `pubspec.yaml` | — |
| P1 Security rules | Partly | Role-based, but teachers can self-register, any staff can edit sessions and terms, answer keys exposed | firestore.rules |
| **P2** Teacher weekly availability + unavailable dates | Missing | Not found | — |
| P2 Admin repeating schedule (level/weekdays/time/room/teacher/quota/valid period) | Missing | One-off sessions only (`firestore_service.dart:781-845`); admin sessions get `CONTENT_OWNER_ID` as teacher (`app_router.dart:225-231`) | class_sessions |
| P2 Conflict check function with suggestions | Missing | Not found | — |
| P2 Scheduled generateSessions | Missing | Only `cleanupExpiredLinkCodes` and `scheduledFirestoreExport` are scheduled | — |
| P2 Teacher schedule screen with confirm + request change | Missing | Calendar and list only (`class_calendar_screen.dart`) | class calendar |
| P2 Schedule confirmation status | Missing | `registrationState` is about student registration | — |
| P2 Substitute teacher picker | Missing | `updateClassSession` never changes teacherId | — |
| P2 Cancel session returning bookings | Partly | `deleteClassSession` hard-deletes, no refund, no notification (`firestore_service.dart:847-860`) | deleteClassSession |
| P2 Student bookSession callable with quota/voucher/overlap checks | Partly | In-app `joinSession` (`firestore_service.dart:1239-1281,1329-1353`); capacity count can race; balance not reserved; no overlap check | joinSession |
| P2 cancelBooking | Partly | `leaveSession` in-app (`:1303-1327`); no cutoff | leaveSession |
| P2 Student session list with seats left + book button | Done | `student_join_session_section.dart:213,252-282` | StudentJoinSessionSection |
| **P3** sessionReminder 1h before | Missing | Not found | — |
| P3 Teacher check-in with server time | Missing | Not found | — |
| P3 checkTeacherCheckIn late notify | Missing | Not found | — |
| P3 Attendance hadir/izin/alpa | Partly | Teacher picks hadir / izin / alpa per student when concluding the class (`conclude_class_dialog.dart`); izin is not charged. History shows Present / Excused / Absent (2026-11-11). No change after conclude (`setAttendanceStatus` unused) | ConcludeClassDialog |
| P3 closeSession transaction, idempotent, ledger | Partly | `concludeClassSession` in-app (`:1100-1147`), not atomic overall | concludeClassSession |
| P3 Unclosed-session flag 2h after | Missing | Not found | — |
| P3 Teacher monthly recap | Missing | Only "classes this week" count | — |
| **P4** Voucher packages catalog | Partly | Hard-coded 8/16 and prices (`app_constants.dart:56-59`, `index.js:30-40`); 90-day validity | PACKAGE_PRICES |
| P4 Student voucher screen (remaining/expiry/history/buy) | Partly | Remaining, expiry, history (`class_term_widgets.dart`); pay staff-created invoices only; no self-buy | StudentPaymentsTab |
| P4 createMidtransTransaction | Partly | `createInvoice` (`index.js:380-529`), staff-only | createInvoice |
| P4 Webhook: signature + mapping + idempotent credit | Done | `index.js:556-670`; amount not cross-checked against invoice | midtransNotification |
| P4 Admin payments screen with filters | Partly | Sortable table, no status/date filters (`admin_invoices_tab.dart`) | AdminInvoicesTab |
| P4 expireVouchers daily + low-balance reminders | Missing | Expiry only checked in app (`student_class_term.dart:42-58`) | voucherAlerts |
| **P5** Question bank with form/topic/explanation/audio | Partly | Has type, level, skill, tags, difficulty, image/audio and, since 2026-11-12, an explanation shown in the review (`ExerciseQuestion.explanation`); no form code | question_bank |
| P5 Question forms L1–L3, R1–R4, T1–T5 | Partly | R1 (fill in the blank), R2 (matching), R3 (passage + choice), R4 (order sentences, via compose), true/false and L3 (listening, no audio upload) exist and are detected by the worksheet scanner (2026-10-27); T1–T3 typing and picture forms missing (`exercise_type.dart`) | ExerciseType |
| P5 Answer keys students cannot read | Done | Package keys stay in `question_bank` (staff-only read); `startExercise` strips them; old-format exercises are no longer playable (2026-11-12). Quizzes (unused) still carry keys | startExercise |
| P5 Practice vs exam | Partly | Unlimited attempts, best score (`exercise_utils.dart`); since 2026-11-11 answers are checked at submit (not per question), a clock runs and a package can carry a time limit that auto-submits (`exercises.timeLimitMinutes`) | ExerciseScreen |
| P5 Teacher builds and assigns packages | Partly | Exercises admin-only; teachers assign with due date (`firestore_service.dart:524-554`); per-lesson quizzes | exercise_assignments, quiz_editor |
| P5 Exam format per level | Missing | Not found | — |
| P5 Server-time deadline enforcement | Missing | `dueDate` checked in app only | — |
| P5 gradeSubmission function | Partly | Packages are scored by `finishExercise` (server, returns the review, stores correct/total/time); old in-document exercises and quizzes still score in the app | finishExercise |
| P5 Typing matcher | Missing | Not found | — |
| P5 T5 essay grading screen | Missing | Generic manual gradebook only (`teacher_grades_tab.dart`) | Gradebook |
| P5 Student do practice/exam + history | Partly | MCQ, compose, matching, typing; result review after submit; history in the Progress tab (Exercises segment, 2026-11-11) and `transcript_view.dart`; no exam mode; no media shown | ExerciseScreen |
| **P6** Teacher enters NG rubric | Missing | Free-form grades and 1–5 evaluations only | grades / evaluations |
| P6 calculateFinalScore + promotion rules | Missing | Letter bands only (`grade_utils.dart:7-16`) | — |
| P6 Admin verification + level history | Missing | `users.level` editable by admin and student | `users.level` |
| P6 Remedial retake | Missing | Not found | — |
| P6 Level group derivation | Partly | Report-only bands (`admin_report_service.dart:231-233`) | HskBandCount |
| P6 Admin screen to edit weights | Missing | Not found | — |
| **P7** progress_summary doc per student | Missing | Only per-lesson `student_progress` docs | — |
| P7 Warning indicators (5) | Partly | In-app: inactive 7 days, ≤2 sessions (`teacher_attention_utils.dart:28-30`) | TeacherAttentionUtils |
| P7 Status label | Missing | Not found | — |
| P7 Access scoping | Partly | Student/parent limited to own; any teacher reads all students | rules |
| P7 Report screen layout | Missing | `student_progress_tab.dart` is a list; no chart library | StudentProgressTab |
| **P8** monthlyReport scheduled | Missing | Admin PDFs on demand only | admin PDF exports |
| P8 Admin dashboard (6 items) | Partly | Totals, signups chart, voucher alerts, finance (`admin_dashboard_tab.dart`) | AdminDashboardTab |
| **P9** FCM notifications | Missing | In-app only, 4 events; read query likely denied | `notifications` |
| **Rules** kunci_jawaban unreadable | Missing | Keys in readable docs | — |
| Rules jawaban_murid create-own, no score | Done | `exercise_results` has no client write at all; `finishExercise` scores and writes (rules 2026-11-12, deploy pending) | exercise_results |
| Rules nilai read-own | Done | `firestore.rules:225-230` | grades |
| Rules voucher/riwayat read-own | Partly | Terms OK; attendance of open sessions readable by any student | student_class_terms |
| Rules pembayaran read-own | Partly | Own/parent OK; teachers can read all invoices | invoices |
| Rules counters only by functions | Missing | Staff update terms/attendance from app | — |
| **Testing** seed script | Partly | `scripts/seed_test_accounts.sh`, `seed_report_demo_data.py`, run against live | seed scripts |
| Testing question import (CSV/JSON + audio) | Partly | Paste + PDF/image/DOC OCR import; no CSV/JSON, no batch audio | Worksheet import |
| Testing emulator rules tests | Done | `rules-tests/firestore.rules.test.mjs`, 30 pass (`npm --prefix rules-tests run test:emulator`) | rules-tests |
| Testing reconciliation script | Missing | Not found | — |
| Testing unit tests NA formula / typing matcher | Missing | Tests cover constants and worksheet parser only | — |
