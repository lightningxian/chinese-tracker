# EASY STUDY APP — Feature Backlog from the Revised TA Proposal

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
- Students self-register; the account works only after **admin approval**. Admin sets the starting level (from a placement test).

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

**Grading per level**
- Three scores, each 0–100:
  - **NU** (Nilai Ujian) = exam score: (total points ÷ max points) × 100
  - **NL** (Nilai Latihan) = average of all practice scores in that HSK level
  - **NG** (Nilai Evaluasi Guru) = teacher rubric: speaking & pronunciation 40%, participation 30%, assignments 30%
- **NA = 0.6 × NU + 0.2 × NL + 0.2 × NG**
- **Promote** to the next HSK level only if ALL are true: NA ≥ 70, NU ≥ 60, no exam section < 40, attendance in that level ≥ 75%. Then **admin verifies** before the level changes.
- Grade bands: **A 85–100, B 70–84** (promote if other rules pass), **C 60–69** (remedial: teacher coaching + one retake exam), **D < 60** (repeat the level). NA ≥ 70 but attendance < 75% or a section < 40 → also remedial.
- Weights and thresholds must be **editable by admin** (stored in a settings document), with the values above as defaults.
- Worked example to use as a unit test: L 72, R 80, T 65 → 217/300 → NU 72.3; NL 78; NG 80 → **NA = 75.0 (B)** → recommend HSK 3 → HSK 4.

**Out of scope (do NOT build)**
Teacher payroll/salary calculation, accounting, inventory, marketing, online/video classes, learning materials, speaking tests (HSKK), students choosing teachers.

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
- [ ] **Practice vs Exam**

| | Latihan (practice) | Ujian (exam) |
|---|---|---|
| Time limit | none | yes, opened by the teacher |
| Attempts | unlimited | 1 (except remedial retake) |
| Listening audio | replay any number of times | **max 2 plays** |
| Pembahasan | right after answering | after the exam time ends |
| Counts as | NL | NU |

- [ ] Teacher builds a latihan/ujian package from the bank (type, level, duration) and assigns it to a student or class → students notified.
- [ ] **Exam format per level** (ujian tingkat):

| Level | Sections | Questions | Time | Max / Pass |
|---|---|---|---|---|
| Beginner | Listening, Reading (Typing = practice only) | 30 (15 L + 15 R) | 35 min | 200 / 120 |
| Intermediate | Listening, Reading, Typing | 45 (15 + 15 + 15) | 60 min | 300 / 180 |
| Advance | Listening, Reading, Typing | 60 (20 + 20 + 20, incl. 2× T5) | 90 min | 300 / 180 |

- [ ] **Exam timing uses server time**: start time is saved by the server; answers sent after the deadline are **rejected** even if the phone clock is changed (test PN-05).
- [ ] **Cloud Function `gradeSubmission`** (callable): the app sends only the answers; the function loads the keys, scores, saves the score. Section score = (points ÷ max points) × 100. Choice/true-false/matching/ordering: right = full points, wrong = 0.
- [ ] **Typing answer-matching algorithm** (inside `gradeSubmission`):
  1. **Normalize** both answer and key: trim spaces; full-width ↔ half-width punctuation (“，” = “,”); remove ending punctuation; **traditional → simplified hanzi** with OpenCC (`opencc-js` in Node); for pinyin: lowercase, treat `ü` = `v` = `u:`, convert tone marks to tone numbers (`nǐ hǎo` → `ni3 hao3`), split by syllable.
  2. **Exact match** against every accepted key (a question can have several keys, e.g. 不客气 / 不用客气) → 100%.
  3. **Tolerance**: Levenshtein distance `d` (unit = character for hanzi, syllable for pinyin); similarity `S = 1 − d ÷ n` (n = the longer length).
  4. **Partial credit = 50%**: pinyin with all syllables right but tones wrong/missing; hanzi in **T2/T3** with `d = 1` and `S ≥ 0.75`. **T4 gets no partial credit** (word order is what's tested). Everything else = 0.
  5. Every partial answer is flagged **"perlu ditinjau"** → appears in the teacher's review queue; the teacher can approve or change the score.
  - Unit-test cases: 你好 vs 你好！ → 100% · 谢谢 vs 謝謝 → 100% · nǐ hǎo vs ni3 hao3 → 100% · nǐ hǎo vs ni hao → 50% · 我很喜欢喝茶 vs 我很喜欢和茶 → 50% + review · 把书放在桌子上 vs 书把放在桌子上 (T4) → 0%.
- [ ] **T5 essay grading screen** (teacher): shows character count and which required keywords appear / are missing; teacher scores with rubric **grammar 40%, vocabulary 30%, content 30%**.
- [ ] **Student screens**: do practice/exam (audio player with play counter in exams), see score + pembahasan + history.

## 8. Phase 6 — Level grading & promotion

- [ ] Teacher enters **NG** with the rubric (speaking 40 / participation 30 / assignments 30).
- [ ] **Cloud Function `calculateFinalScore`** (callable): reads NU (with per-section scores), NL, NG and attendance %; computes NA; applies the promotion rules from section 2; returns the recommendation **naik / remedial / ulang** and the grade band.
- [ ] **Admin verification screen**: approve the promotion → level updated + **level history** saved (date, from, to, NA) → student notified.
- [ ] **Remedial flow**: teacher sees students marked remedial; can open one retake exam for them.
- [ ] Moving HSK 2 → 3 means Beginner → Intermediate; HSK 4 → 5 means Intermediate → Advance (level group is derived from the HSK level).
- [ ] Admin screen **"Mengelola Level & Penilaian"** to edit weights and thresholds.

## 9. Phase 7 — Student progress report (monitoring)

- [ ] **One summary document per student** (`progress_summary/{studentId}`) so the report screen reads **one doc**. Updated by the trigger **`updateProgressSummary`** whenever a score, attendance or voucher changes. It holds:
  - current level + HSK level + % of material done toward the next level exam;
  - weekly practice & exam scores (for a line chart);
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
| 5 | Level exam | NA < 70 | teacher + admin |

- [ ] **Status label**: 0 warnings = **Progres Baik**, 1 = **Perlu Perhatian**, ≥ 2 = **Perlu Tindak Lanjut**.
- [ ] **Access**: student → only own report · teacher → students in their classes + list of students who need attention + can add follow-up notes · admin → all students, filter by level, teacher, period.
- [ ] **Report screen** layout (see wireframe in the proposal, "Laporan Progress Murid"): header with status chip → level progress bar → 4 KPI cards (attendance, practice avg, last exam, voucher left) → weekly score line chart (practice line + exam points) → per-skill bars → latest teacher note.

## 10. Phase 8 — Admin reports & dashboard

- [ ] **`monthlyReport`** (scheduled, 1st day of each month): new students, revenue, active students, level distribution, attendance rate, teacher teaching hours.
- [ ] **Admin dashboard**: pending registrations, unconfirmed schedules, late check-ins, unclosed sessions, students needing attention, today's sessions.

## 11. Phase 9 — Notifications (FCM) checklist

- [ ] New registration (→ admin) · approved/rejected (→ student)
- [ ] New/changed schedule (→ teacher) · change request (→ admin)
- [ ] Session reminder 1 h before (→ teacher, students) · late check-in (→ admin)
- [ ] Substitute teacher / session moved / session cancelled (→ booked students)
- [ ] Booking confirmed or rejected (→ student)
- [ ] New practice/exam (→ students) · score ready (→ student, teacher)
- [ ] Payment success / failed (→ student) · voucher low or expiring (→ student, admin)
- [ ] Progress warnings (→ as in the table above) · promotion result (→ student)

## 12. Firestore Security Rules (minimum)

| Collection | murid | guru | admin | Cloud Functions |
|---|---|---|---|---|
| `kunci_jawaban` | no read/write | write (own questions) | read/write | read |
| `jawaban_murid` | create own answers; **cannot set score** | read (own class) | read | read + write score |
| `nilai` | read own | read; write Typing-review score and NG | read | write |
| `voucher`, `riwayat_voucher` | read own | read (own class) | read | write |
| `pembayaran` | read own | no read | read | write |

Plus: a student can read only their own `users`, `progress_summary`, bookings. Voucher counters, session status `selesai`, and payment status are changed **only by Cloud Functions** (Admin SDK). Write **rules unit tests** with the emulator (test PN-04).

## 13. Testing (must exist before the thesis trial)

- [ ] **Seed script** (emulator + staging): 1 admin, **4 teachers**, **30 students** (12 Beginner, 10 Intermediate, 8 Advance), rooms, voucher packages, schedules.
- [ ] **Question bank target**: 1 exam package per HSK level (2×30 + 2×45 + 2×60 = **270**) + 2 practice packages of 15 questions per HSK level (**180**) = **450 questions**. Build an **import tool** (CSV/JSON → Firestore + Storage audio) so Will can load real questions; do not invent Chinese content.
- [ ] **Automated tests for the validation scenarios** (Functions + rules tests on the emulator):

| ID | Scenario | Expected |
|---|---|---|
| PN-01 | 200 test answers graded by the system vs by hand | 100% match with the matching rules |
| PN-02 | Typing with full-width punctuation, spaces, traditional hanzi, tone numbers | 100% |
| PN-03 | wrong tone / one wrong homophone character | 50% + flagged for review |
| PN-04 | student tries to read `kunci_jawaban` or write a score via SDK | denied by rules |
| PN-05 | exam answer sent after the deadline (phone clock changed) | rejected |
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
- [ ] Unit tests for the NA formula (worked example in section 2) and for the Typing matcher (cases in section 7).

## 14. Open questions — ask Will, do not guess

1. Firebase project id(s) to use (dev / prod) and whether Cloud Functions are already deployed (Blaze plan needed).
2. Midtrans sandbox server key + client key (give them as Functions secrets, never commit them).
3. Voucher packages: names, number of sessions, validity days, prices.
4. Room names.
5. **Placement test**: is it an exam inside the app, or does admin just set the level after an offline test? (The proposal's activity diagram has admin set the starting level when approving the account.)
6. **Ranking**: the proposal's comparison table (vs Angelita's thesis) says this app has a "Ranking" feature. Build a simple leaderboard per HSK level, or remove "Ranking" from the proposal table?
7. Exact names already used in the repo for collections and screens (keep them; report the mapping).
8. Should the "Rekap Jam Mengajar" tab and the "Ketersediaan" tab both be on the teacher's schedule screen (as in the wireframe), or separate screens?
