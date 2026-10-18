# EASY STUDY APP — Feature Backlog from the Revised TA Proposal

> **Version 2 (18 Oct 2026).** Changed from v1: grading is now *pass 3 different HSK test codes* (no NA/NL/NG formula), leaderboard per test code, optional placement test, tests only at Easy Study with a teacher token, 1 practice set per level. If you already built anything from v1's grading section, tell Will what must change.

> **For Claude Code.** This file lists everything the Easy Study app must have so that it matches the revised thesis proposal (Oct 2026). The owner (Will) is a beginner in Flutter/Firebase: explain each step in simple English, one step at a time, and ask before any big or hard-to-undo decision.

Thesis title: **"Aplikasi Multiplatform Sistem Kursus Bahasa Mandarin Easy Study menggunakan Flutter"** (ISTTS, NRP 221310660, Wilsin).

---

## 0. How to work with this file

1. **Audit first, build second.** Before writing code, read the repo and make a status table: every item in sections 3–11 marked **Done / Partly done / Missing**, with the file(s) where it lives. Show that table to Will before starting.
2. **Work in the phase order** (section 3 → 11). Each phase should run on its own before the next one starts.
3. **Keep existing names.** If the repo already has a collection, class or screen for something below, keep its name and tell Will how it maps to the names here. The thesis book will describe the real names.
4. **Never guess the items in section 13 (Open questions).** Ask Will.
5. Use the **Firebase Emulator Suite** for local testing of Firestore, Auth, Functions and Security Rules. Use the **Midtrans sandbox** only (no real money).

---

## 1. Tech stack (fixed — do not change)

| Part | Choice |
|---|---|
| App | Flutter (Dart), one codebase for Android, iOS and Web |
| Architecture | MVVM: View (widgets) → ViewModel (`ChangeNotifier` + `provider`) → Repository/Service → FlutterFire. Only Repositories talk to Firebase. Dependency injection with `MultiProvider` at the top of the widget tree. |
| Backend | Firebase only — **no separate web server**: Authentication, Cloud Firestore, Cloud Storage, Cloud Messaging (FCM), **Cloud Functions (TypeScript, Node.js)** |
| Payments | Midtrans Snap (sandbox for testing). Server key lives **only** in Cloud Functions secrets. |
| App language | Indonesian (all UI text) |
| Roles | `admin`, `guru` (teacher), `murid` (student) |

---

## 2. Business rules (fixed decisions from the proposal)

**Course & people**
- Easy Study has **4 teachers** and **1 admin**. Classes are face-to-face in Surabaya.
- Levels: **HSK 1–6** (old 6-level HSK) grouped as **Beginner (HSK 1–2), Intermediate (HSK 3–4), Advance (HSK 5–6)**.
- **Admin assigns the teacher** to every schedule. **Students do NOT choose teachers** — they choose a *session* by level and time. The teacher's name is shown only as information.
- Students self-register; the account works only after **admin approval**. At registration the student chooses: **start at HSK 1**, or **take a placement test** (see section 8).

**Jadwal vs Sesi (important — keep them as separate data)**
- **Jadwal (schedule)** = a repeating weekly plan: level, class name, weekdays, start/end time, room, teacher, quota, valid-from/valid-to, active flag. No attendance.
- **Sesi (session)** = one real meeting on one date, generated from a jadwal: date, time, teacher, room, participants, teacher check-in time, attendance, status `dijadwalkan | berlangsung | selesai | dibatalkan`.
- Changing a jadwal changes all *future, not-yet-started* sessions. Changing one sesi changes only that date.

**Voucher kursus**
- A voucher = a package of **X sessions** with an **expiry date**.
- Voucher fields: `totalSesi`, `sesiTerpakai` (used), `sesiDipesan` (booked).
  **Remaining = totalSesi − sesiTerpakai − sesiDipesan.**
- **Izin (excused) before the session starts → no deduction. Hadir (present) or Alpa (absent without notice) → deduct 1 session.**
- Expired voucher → cannot book.

**Grading = only for moving up an HSK level** (Easy Study is a course center, not a school: no report cards, no final-score formula)
- Every **HSK simulation test** (tes simulasi) has a unique **test code** (kode tes), e.g. `H3216917Z` = an HSK 3 test. Each code is a different set of questions. The first two characters give the HSK level.
- Section score 0–100 = round(points earned ÷ max points × 100) — the same way Easy Study's current "Nilai Simulasi HSK" web app stores scores. Total = sum of sections.
- **Pass** a code: total ≥ **120** (HSK 1–2, max 200) or ≥ **180** (HSK 3–6, max 300).
- **Move up** to the next HSK level = **passed at least 3 different test codes** at the student's current level. Each code can be taken **only once** per student. Then **admin verifies** before the level changes. After moving up, the count starts again from 0.
- Practice scores, attendance and teacher notes do **not** affect promotion (they only show in the progress report).
- Pass marks and the minimum number of codes (default 3) are **editable by admin** (settings document).

**Out of scope (do NOT build)**
Teacher payroll/salary calculation, accounting, inventory, marketing, online/video classes, learning materials, speaking tests (HSKK), students choosing teachers, report cards / NA formula / teacher score (NG), remedial flow.

---

## 3. Phase 1 — Foundation

- [ ] **Auth**: login with username/email + password (Firebase Auth). Role stored in `users/{uid}.role`.
- [ ] **Self-registration** for students → `status: menunggu` (waiting). Admin gets a notification.
- [ ] **Admin approval screen**: approve (and set starting HSK level) or reject with a reason → student is notified.
- [ ] **Admin user management**: create/edit/delete teacher and student accounts.
- [ ] **Teacher profile**: list of HSK levels the teacher can teach.
- [ ] **Rooms** (`ruang`) list managed by admin.
- [ ] **Settings document** (`settings/grading`, `settings/scheduling`): grading weights and thresholds, check-in limit (15 min), min gap between sessions (default 15 min), weekly teaching-hours warning limit.
- [ ] **Profile screen** for every role (name, photo in Cloud Storage, contact).
- [ ] **FCM setup**: save each device token on login; remove on logout.
- [ ] **Firestore Security Rules** (see section 12) — write them now, not at the end.

## 4. Phase 2 — Teacher scheduling & checking

- [ ] **Teacher availability**: teacher fills weekly available hours (day + time ranges) and **unavailable dates** (izin/cuti) with a reason. Admin sees all teachers' availability on one calendar view.
- [ ] **Create/edit jadwal** (admin): level, class name, weekdays, start/end, room, teacher, quota, valid period.
- [ ] **Cloud Function `checkScheduleConflict`** (callable) — runs inside a **Firestore transaction** and rejects the save if:
  1. data invalid (end ≤ start, quota < 1, level not in the teacher's teachable levels);
  2. time is outside the teacher's availability or on an unavailable date;
  3. **teacher clash** — the teacher has another jadwal/sesi that overlaps (A and B overlap if `startA < endB && startB < endA`), including the min-gap setting;
  4. **room clash** — the room is used by another class at an overlapping time.
  Weekly teaching hours above the limit → **warning only** (still saves).
  On rejection, return the reason (e.g. "Guru sudah mengajar HSK 1 – Kelas Dasar B pada Senin 15.00–16.30") **and suggest free time slots** inside the teacher's availability.
  The same check must run when admin edits a jadwal, changes the teacher of one sesi, or adds a replacement sesi.
  Two admins saving the same slot at the same time → only one succeeds (test JD-02).
- [ ] **Cloud Function `generateSessions`** (scheduled, weekly on Sunday): create sessions for the next **2 weeks** from every active jadwal. Must not create duplicates if it runs twice (use a deterministic id like `{jadwalId}_{yyyyMMdd}`).
- [ ] **Teacher "Jadwal Mengajar" screen**: sessions per day with status chips; **Konfirmasi** button; **Ajukan Perubahan** (request change + reason) → goes to admin.
- [ ] Schedule status: `menunggu konfirmasi` → `terkonfirmasi`. Unconfirmed ones show on the admin dashboard.
- [ ] **Substitute teacher (guru pengganti)**: when a teacher is unavailable for one sesi, admin opens the sesi and sees a **filtered list** of teachers who are (a) available at that time, (b) can teach that level, (c) have no clash. Admin picks one → booked students get a notification.
- [ ] **Cancel a sesi** (no substitute found): status `dibatalkan`, all bookings returned to the vouchers (`sesiDipesan − 1`), students notified to pick another session.
- [ ] **Student booking — Cloud Function `bookSession`** (callable, **one transaction**): check quota, active voucher, remaining sessions > 0, voucher not expired, **student has no other booked session that overlaps**. On success: participants +1, `sesiDipesan` +1, notify the student. On failure: return a clear reason (kelas penuh, voucher habis, bentrok, etc.).
- [ ] **Cancel booking / izin before start — Cloud Function `cancelBooking`** (one transaction): `sesiDipesan − 1`.
- [ ] **Student "Sesi Kelas" screen**: list of sessions for the student's level, with time, room, teacher name (info only), seats left, and a **Daftar** button.

## 5. Phase 3 — Running and closing a session

- [ ] **`sessionReminder`** (scheduled, hourly): push notification **1 hour before** each session to the teacher and booked students.
- [ ] **Teacher check-in**: "Mulai Sesi" button → saves server time as `checkInAt`, status `berlangsung`.
- [ ] **`checkTeacherCheckIn`** (scheduled, every 15 min): sessions more than **15 min** past start and still not started → notify admin. Save lateness for the teacher recap.
- [ ] **Attendance**: teacher marks each booked student **hadir / izin / alpa**, reviews, then presses **Tutup Sesi**.
- [ ] **Cloud Function `closeSession`** (callable, **one Firestore transaction**, must be **idempotent**):
  - continue only if the session status is still `berlangsung`;
  - for **hadir/alpa**: `sesiDipesan − 1`, `sesiTerpakai + 1`; for **izin**: `sesiDipesan − 1`;
  - create `riwayat_voucher/{sessionId}_{studentId}` for each student (this fixed id makes a second call unable to deduct twice);
  - set session status `selesai`; add the session hours to the teacher's monthly recap.
  - Progress summary and notifications run **after** the transaction, in separate trigger functions (a failure there must not touch voucher data).
- [ ] Sessions not closed **2 hours after end time** → flagged "belum ditutup" on the admin dashboard.
- [ ] **Teacher recap (admin)**: per teacher per month — sessions scheduled, held, cancelled, late check-ins, total teaching hours. (Data only — no salary calculation.)

## 6. Phase 4 — Vouchers & Midtrans payment

- [ ] **Voucher packages** (admin): name, number of sessions, validity (days), price.
- [ ] **Student "Voucher Kursus" screen**: active vouchers, remaining sessions, expiry date, usage history (from `riwayat_voucher`), **Beli** button.
- [ ] **`createMidtransTransaction`** (callable): create a `pembayaran` doc (`status: pending`, unique `order_id`), call Midtrans Snap with the **server key** (Functions secret), return the Snap token / redirect URL. Open the Snap page in the app (WebView on mobile, redirect on web).
- [ ] **`midtransNotification`** (HTTP webhook):
  - verify `signature_key = SHA512(order_id + status_code + gross_amount + ServerKey)`; wrong signature → reject, change nothing;
  - map `transaction_status`: `settlement` (or `capture` with `fraud_status: accept`) → `lunas`; `pending` → pending; `expire` / `cancel` / `deny` → failed;
  - on `lunas`: **in one transaction**, create the voucher and link it to the payment **only if the payment has no voucher yet** (idempotent — the same notification arriving twice must create only one voucher);
  - notify the student.
- [ ] **Admin "Pembayaran" screen**: all transactions with status, amount, student, date, filters. No manual proof-of-transfer checking.
- [ ] **`expireVouchers`** (scheduled, daily): deactivate expired vouchers; remind students whose voucher has ≤ 2 sessions left or expires within 7 days.

## 7. Phase 5 — Question bank, practice & exams

**Question bank** (admin and teachers can add/edit). Each question has: type, form, HSK level, topic, difficulty, answer key(s), explanation (pembahasan), audio file (Listening only, in Cloud Storage).

| Type | Form | Example | Levels | Grading |
|---|---|---|---|---|
| Listening | L1 Match audio to picture | hear a word → pick the picture | Beginner | auto |
| | L2 True/False | hear a sentence → is the statement true? | Beginner–Intermediate | auto |
| | L3 Multiple choice | dialog/monolog → choose A–D | all | auto |
| Reading | R1 Fill in the blank | 冬天到了，天气（ ）变冷了。 | all | auto |
| | R2 Match sentences | question ↔ answer | Beginner–Intermediate | auto |
| | R3 Reading comprehension | short text → multiple choice | Intermediate–Advance | auto |
| | R4 Order sentences | arrange sentences into a paragraph | Advance | auto |
| Typing | T1 Type pinyin | 你好 → nǐ hǎo (ni3 hao3 also OK) | Beginner | auto |
| | T2 Type hanzi from pinyin | nǐ hǎo → 你好 | Beginner–Intermediate | auto |
| | T3 Complete hanzi | 我＿喜欢喝茶 (hint: hěn) | Intermediate | auto |
| | T4 Build a sentence | 书 / 放 / 把 / 在桌子上 → 把书放在桌子上。 | Intermediate–Advance | auto |
| | T5 Free writing (essay) | write from keywords/picture | Advance | **teacher** (system helps) |

- [ ] **Answer keys** in a separate collection `kunci_jawaban` that **students can never read** (only Cloud Functions + admin/teacher). Never send keys to the student's device.
- [ ] **Practice vs HSK simulation test**

| | Latihan (practice) | Tes simulasi HSK |
|---|---|---|
| Where | anywhere | **only at Easy Study, supervised, needs a token from the teacher** |
| Time limit | none | per HSK format (table below) |
| Attempts | unlimited | **1 per test code** |
| Listening audio | replay any number of times | **max 2 plays** |
| Pembahasan | right after answering | after the test time ends |
| Score is used for | progress report only | promotion + leaderboard |

- [ ] Teacher builds a practice package from the bank (type, level) and assigns it to a student or class → students notified. Admin builds **test packages**, each with a unique **test code**.
- [ ] **Test format per HSK level** (official HSK structure; Typing replaces 书写 writing):

| Level | Listening | Reading | Typing | Total | Time | Max / Pass |
|---|---|---|---|---|---|---|
| HSK 1 | 20 | 20 | – | 40 | 35 min | 200 / 120 |
| HSK 2 | 35 | 25 | – | 60 | 50 min | 200 / 120 |
| HSK 3 | 40 | 30 | 10 (5× T4 + 5× T3) | 80 | 85 min | 300 / 180 |
| HSK 4 | 45 | 40 | 15 (10× T4 + 5× T5) | 100 | 100 min | 300 / 180 |
| HSK 5 | 45 | 45 | 10 (8× T4 + 2× T5) | 100 | 120 min | 300 / 180 |
| HSK 6 | 50 | 50 | 1 (T5) | 101 | 135 min | 300 / 180 |

  Objective questions = 1 point; T5 = 10 points (teacher rubric).
- [ ] **Supervised test flow**:
  - **Cloud Function `openTestSession`** (callable, teacher only): pick a test code → returns a **6-character token valid 15 minutes**.
  - Student enters the token to start; no valid token = cannot start (so tests can't be done at home).
  - **Test mode**: no other menus; every time the student leaves the test page (app goes to background / browser tab hidden) save an event; show these events live on the **teacher's supervision screen**.
  - Teacher can mark a result **tidak sah** (invalid) → not counted for promotion or leaderboard.
- [ ] **Test timing uses server time**: start time is saved by the server; answers sent after the deadline are **rejected** even if the phone clock is changed (test PN-05).
- [ ] **Cloud Function `gradeSubmission`** (callable): the app sends only the answers; the function loads the keys, scores, saves the score. Section score = (points ÷ max points) × 100. Choice/true-false/matching/ordering: right = full points, wrong = 0.
- [ ] **Typing answer-matching algorithm** (inside `gradeSubmission`):
  1. **Normalize** both answer and key: trim spaces; full-width ↔ half-width punctuation (“，” = “,”); remove ending punctuation; **traditional → simplified hanzi** with OpenCC (`opencc-js` in Node); for pinyin: lowercase, treat `ü` = `v` = `u:`, convert tone marks to tone numbers (`nǐ hǎo` → `ni3 hao3`), split by syllable.
  2. **Exact match** against every accepted key (a question can have several keys, e.g. 不客气 / 不用客气) → 100%.
  3. **Tolerance**: Levenshtein distance `d` (unit = character for hanzi, syllable for pinyin); similarity `S = 1 − d ÷ n` (n = the longer length).
  4. **Partial credit = 50%**: pinyin with all syllables right but tones wrong/missing; hanzi in **T2/T3** with `d = 1` and `S ≥ 0.75`. **T4 gets no partial credit** (word order is what's tested). Everything else = 0.
  5. Every partial answer is flagged **"perlu ditinjau"** → appears in the teacher's review queue; the teacher can approve or change the score.
  - Unit-test cases: 你好 vs 你好！ → 100% · 谢谢 vs 謝謝 → 100% · nǐ hǎo vs ni3 hao3 → 100% · nǐ hǎo vs ni hao → 50% · 我很喜欢喝茶 vs 我很喜欢和茶 → 50% + review · 把书放在桌子上 vs 书把放在桌子上 (T4) → 0%.
- [ ] **T5 essay grading screen** (teacher): shows character count and which required keywords appear / are missing; teacher scores with rubric **grammar 40%, vocabulary 30%, content 30%**.
- [ ] **Student screens**: do practice/test (audio player with play counter in tests), see score + pembahasan + history.

## 8. Phase 6 — Promotion, placement test & leaderboard

**Promotion**
- [ ] **Cloud Function `checkLevelPromotion`** (Firestore trigger on a new valid test score): count **distinct passed test codes** at the student's current HSK level; if ≥ the minimum (default 3) → create a `kenaikan_tingkat` recommendation (status: waiting for admin).
- [ ] **Admin verification screen**: approve → level updated + **level history** saved (date, from, to, the passed codes) → student notified. Count resets for the new level.
- [ ] Block taking the same test code twice (test LV-02).
- [ ] Moving HSK 2 → 3 = Beginner → Intermediate; HSK 4 → 5 = Intermediate → Advance (group derived from the HSK level).
- [ ] Unit-test example: HSK 3 student — Code A 170 (fail), Code B 195, Code C 200, Code D 205 → 3 passes → recommend HSK 4.

**Placement test (optional, for new students)**
- [ ] Registration form: "Mulai dari HSK 1" or "Ikut tes penempatan" + **target level (HSK 2–6)**.
- [ ] After approval, the student takes **one existing simulation test of the level just below the target** (target HSK 4 → take an HSK 3 code), at Easy Study with a teacher token. No new question bank needed.
- [ ] Pass → recommend the target level; fail → recommend the tested level. Admin confirms the starting level (no test → HSK 1).
- [ ] The code used counts as "already taken" by that student, but placement results are **not shown in the leaderboard**.

**Leaderboard per test code**
- [ ] **Cloud Function `updateLeaderboard`** (trigger on a new valid, non-placement test score) writes `leaderboard/{kodeTes}/entri/{muridId}`.
- [ ] Order: total score (high → low); tie → shorter time taken first.
- [ ] Shows rank, name, section scores, total, pass/fail; highlights the viewer's own row.
- [ ] **Privacy**: students see other students as first name + initial (e.g. "Angeline S."); teachers and admin see full names. Students cannot read other students' `nilai` directly — only the `leaderboard` collection.
- [ ] **Import old results**: script to import past results for a code from the "Nilai Simulasi HSK" Firestore project (`easy-study-hsk`, collections `students` and `records`, field `set` = test code) so codes like `H3216917Z` already have a leaderboard. Ask Will before reading that project.

## 9. Phase 7 — Student progress report (monitoring)

- [ ] **One summary document per student** (`progress_summary/{studentId}`) so the report screen reads **one doc**. Updated by the trigger **`updateProgressSummary`** whenever a score, attendance or voucher changes. It holds:
  - current level + HSK level + **number of passed test codes at this level (e.g. 2 of 3)**;
  - weekly practice scores (for a line chart) + test history (code, date, scores, pass/fail, leaderboard rank);
  - average per skill: Listening, Reading, Typing;
  - attendance % and history;
  - voucher remaining sessions + expiry;
  - teacher notes and level history.
- [ ] **Warning indicators** (checked in the same trigger):

| # | Indicator | Warning when | Notify |
|---|---|---|---|
| 1 | Attendance | < 75% in the last 30 days | teacher + admin |
| 2 | Score drop | avg practice in last 2 weeks < 60, or dropped ≥ 10 points | teacher |
| 3 | Inactive | no practice for 14 days | student + teacher |
| 4 | Voucher | ≤ 2 sessions left or expires within 7 days | student + admin |
| 5 | Simulation tests | failed 2 tests in a row | teacher + admin |

- [ ] **Status label**: 0 warnings = **Progres Baik**, 1 = **Perlu Perhatian**, ≥ 2 = **Perlu Tindak Lanjut**.
- [ ] **Access**: student → only own report · teacher → students in their classes + list of students who need attention + can add follow-up notes · admin → all students, filter by level, teacher, period.
- [ ] **Report screen** layout (see wireframe in the proposal, "Laporan Progress Murid"): header with status chip → "2 of 3 codes passed" progress → 4 KPI cards (attendance, practice avg, tests passed, voucher left) → weekly practice line chart → per-skill bars + latest teacher note → test history table with leaderboard rank.

## 10. Phase 8 — Admin reports & dashboard

- [ ] **`monthlyReport`** (scheduled, 1st day of each month): new students, revenue, active students, level distribution, attendance rate, teacher teaching hours.
- [ ] **Admin dashboard**: pending registrations, unconfirmed schedules, late check-ins, unclosed sessions, students needing attention, today's sessions.

## 11. Phase 9 — Notifications (FCM) checklist

- [ ] New registration (→ admin) · approved/rejected (→ student)
- [ ] New/changed schedule (→ teacher) · change request (→ admin)
- [ ] Session reminder 1 h before (→ teacher, students) · late check-in (→ admin)
- [ ] Substitute teacher / session moved / session cancelled (→ booked students)
- [ ] Booking confirmed or rejected (→ student)
- [ ] New practice (→ students) · score ready (→ student, teacher) · promotion recommendation (→ admin)
- [ ] Payment success / failed (→ student) · voucher low or expiring (→ student, admin)
- [ ] Progress warnings (→ as in the table above) · promotion result (→ student)

## 12. Firestore Security Rules (minimum)

| Collection | murid | guru | admin | Cloud Functions |
|---|---|---|---|---|
| `kunci_jawaban` | no read/write | write (own questions) | read/write | read |
| `jawaban_murid` | create own answers; **cannot set score** | read (own class) | read | read + write score |
| `nilai` | read own | read; write T5 score and Typing-review score; mark result invalid | read | write |
| `leaderboard` | read (other names masked) | read | read | write |
| `pelaksanaan_tes` (tokens) | no read (token checked by function) | create via `openTestSession` | read | read/write |
| `voucher`, `riwayat_voucher` | read own | read (own class) | read | write |
| `pembayaran` | read own | no read | read | write |

Plus: a student can read only their own `users`, `progress_summary`, bookings. Voucher counters, session status `selesai`, and payment status are changed **only by Cloud Functions** (Admin SDK). Write **rules unit tests** with the emulator (test PN-04).

## 13. Testing (must exist before the thesis trial)

- [ ] **Seed script** (emulator + staging): 1 admin, **4 teachers**, **30 students** (12 Beginner, 10 Intermediate, 8 Advance), rooms, voucher packages, schedules.
- [ ] **Question bank target (reduced)**: **1 practice package of 15 questions per HSK level (90)** + **1 test code per HSK level** in full format (40+60+80+100+100+101 = **481**) + **2 extra HSK 3 codes** (160) so the 3-code rule can be tested for real = **731 questions**. Most come from Easy Study's existing simulation papers, so build a good **import tool** (CSV/JSON → Firestore + Storage audio). Do not invent Chinese content.
- [ ] **Automated tests for the validation scenarios** (Functions + rules tests on the emulator):

| ID | Scenario | Expected |
|---|---|---|
| PN-01 | 200 test answers graded by the system vs by hand | 100% match with the matching rules |
| PN-02 | Typing with full-width punctuation, spaces, traditional hanzi, tone numbers | 100% |
| PN-03 | wrong tone / one wrong homophone character | 50% + flagged for review |
| PN-04 | student tries to read `kunci_jawaban` or write a score via SDK | denied by rules |
| PN-05 | test answer sent after the deadline (phone clock changed) | rejected |
| TS-01 | start a test with no token, a wrong token, or a token older than 15 min | rejected |
| TS-02 | student leaves the test page and comes back | event saved and shown on the teacher's screen |
| LV-01 | HSK 3 student passes a 3rd different code | promotion recommendation waiting for admin |
| LV-02 | student tries the same code a 2nd time | rejected |
| LV-03 | 2 passes + 1 fail | no recommendation; progress shows 2 of 3 |
| LB-01 | leaderboard of `H3216917Z` (15 people) vs manual ranking | same order and scores; names masked for students |
| PL-01 | new student, target HSK 4, passes the HSK 3 placement test | recommends HSK 4, waiting for admin |
| PL-02 | new student skips the placement test | starts at HSK 1 |
| VC-01 | close session: 3 hadir, 1 izin, 1 alpa | 4 vouchers +1 used; izin not deducted |
| VC-02 | `closeSession` called twice | deducted once |
| VC-03 | close session while the same student books another | both succeed, counts correct |
| VC-04 | book with 0 sessions left | rejected |
| VC-05 | reconciliation after the trial | `sesiTerpakai` = count of `riwayat_voucher` |
| MT-01 | sandbox payment settlement | paid + exactly one voucher |
| MT-02 | pending then expire/cancel | status follows Midtrans; no voucher |
| MT-03 | same notification sent twice | still one voucher |
| MT-04 | wrong signature key | rejected, no change |
| MT-05 | compare all test payments with the Midtrans sandbox dashboard | all statuses match |
| JD-01 | save a schedule with teacher/room/student clash or outside availability | rejected with the reason |
| JD-02 | two admins save the same teacher + time at once | only one saved |

- [ ] A small **reconciliation script** for VC-05.
- [ ] Unit tests for the promotion counter (example in section 8) and for the Typing matcher (cases in section 7).

## 14. Open questions — ask Will, do not guess

1. Firebase project id(s) to use (dev / prod) and whether Cloud Functions are already deployed (Blaze plan needed).
2. Midtrans sandbox server key + client key (give them as Functions secrets, never commit them).
3. Voucher packages: names, number of sessions, validity days, prices.
4. Room names.
5. Test code format: what do the characters in a code like `H3216917Z` mean, and who creates new codes (admin types it, or the app generates it)?
6. Do the existing simulation papers come with audio files and answer keys in digital form (for the import tool)?
7. Exact names already used in the repo for collections and screens (keep them; report the mapping).
8. Should the "Rekap Jam Mengajar" tab and the "Ketersediaan" tab both be on the teacher's schedule screen (as in the wireframe), or separate screens?
