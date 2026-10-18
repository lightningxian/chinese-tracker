# EASY STUDY APP — Assets needed for the TA proposal

> **For Claude Code.** Will's thesis proposal (Bab IV) needs real screenshots and real data from the Easy Study app so the documents match the code. Collect everything below, put it in **one folder called `proposal_assets/`** in the project root, zip it as `proposal_assets.zip`, and tell Will it is ready. He will send the zip back to the Claude that writes the proposal.
>
> Work in simple, small steps and explain each one in simple English — Will is a beginner. Read `EASY_STUDY_APP.md` (version 2) first: it has the features and data names the proposal uses.
>
> **Privacy rule:** never put real student names, phone numbers or emails in any screenshot or file. Use the demo data from part A. The only real data is the leaderboard scores in part C, and those use first name + initial only.

---

## A. Demo data (do this first)

Create demo data in the **Firebase Emulator** (not production) so every screenshot looks full and realistic:

- 1 admin, 4 teachers (example names: Andrea Natasha, Budi Santoso, Clara Wijaya, Daniel Hartono), 30 students across HSK 1–6 (Indonesian first names; you may add a Chinese name like 陈美琳).
- Rooms: Ruang 1, Ruang 2, Ruang 3.
- Schedules and sessions for the week of 12–18 Oct 2026, including **one clash** (same teacher, same time) so the clash warning can be shown.
- 2–3 voucher packages and a few paid vouchers (sandbox).
- For one HSK 3 student ("Angeline"): 8 weeks of practice scores, attendance about 85%, 3 simulation tests (1 fail, 2 pass) so the progress report shows "2 dari 3".
- One leaderboard filled with the real scores from part C (or demo scores if part C is not done yet).

If a screen in part B is **not built yet**, build its UI first (following `EASY_STUDY_APP.md`), using the demo data. Tell Will which screens you had to build.

## B. Screenshots

**Settings for every screenshot**
- Run the app with Flutter **web** in Chrome (`flutter run -d chrome`), window **1280 × 800**, browser zoom 100%.
- Also take a **phone** version (Chrome DevTools device mode, 390 × 844) of the screens marked 📱.
- Save as **PNG**, no browser bars, no DevTools visible, no debug banner (`debugShowCheckedModeBanner: false`).
- Use the **exact file names** below, in `proposal_assets/screens/`.

| # | File name | Screen | What must be visible |
|---|---|---|---|
| 1 | `01_login_register.png` 📱 | Login / Register | Register form with the choice **"Mulai dari HSK 1"** or **"Ikut tes penempatan"** + target level (HSK 2–6) |
| 2 | `02_sesi_kelas.png` 📱 | Student: Sesi Kelas | Sessions for the student's level with time, room, **teacher name (info only)**, **seats left**, **Daftar** button; one session showing a rejection reason (e.g. "Kelas penuh") |
| 3 | `03_soal_latihan.png` 📱 | Student: practice question | A Reading **R1 fill-in-the-blank** question, after answering, with **pembahasan** shown |
| 4 | `04_soal_typing.png` 📱 | Student: Typing question | A **T2/T3** hanzi typing question with the answer box |
| 5 | `05_voucher.png` 📱 | Student: Voucher Kursus | Remaining sessions, expiry date, usage history, **Beli** button |
| 6 | `06_tes_token.png` 📱 | Student: start a simulation test | Token input screen showing the **test code** (e.g. H3216917Z) and duration |
| 7 | `07_leaderboard.png` 📱 | Student: Leaderboard per kode tes | Rank, name (first name + initial), L/R/T scores, total, Lulus/Tidak lulus, **own row highlighted** |
| 8 | `08_progress.png` | Student: Laporan Progress | "2 dari 3 kode lulus", KPI cards, practice chart, per-skill scores, teacher note, test history |
| 9 | `09_guru_jadwal.png` | Teacher: Jadwal Mengajar | Sessions per day with status, Mulai Sesi / Isi Absensi / Konfirmasi buttons, availability panel |
| 10 | `10_guru_pengawasan.png` | Teacher: test supervision | The **token** shown big, list of students taking the test, and "keluar halaman" events |
| 11 | `11_admin_buat_jadwal.png` | **Admin: create schedule** | The form (level, class name, days, time, room, teacher, quota, period) **with the clash warning** and suggested free slots |
| 12 | `12_admin_persetujuan.png` | **Admin: registration approval** | Pending students, whether they chose the placement test, Approve / Reject buttons |
| 13 | `13_admin_kenaikan.png` | **Admin: promotion verification** | A recommendation "HSK 3 → HSK 4" with the 3 passed test codes and an Approve button |
| 14 | `14_admin_dashboard.png` | **Admin: dashboard** | Pending registrations, unconfirmed schedules, late check-ins, unclosed sessions, students needing attention |
| 15 | `15_admin_pembayaran.png` | **Admin: payments** | Transaction list with status (lunas / pending / expire), amount, student, date |

## C. Leaderboard data for test code `H3216917Z`

Will says **15 people already took the HSK 3 test `H3216917Z`**. The proposal needs a real example leaderboard.

1. **Ask Will first** before reading anything. The scores may be in his old web app "Nilai Simulasi HSK" (Firebase project `easy-study-hsk`, collections `students` and `records`; a record has `sid`, `date`, `level`, `set` = test code, `scores{listening, reading, writing}`), or Will may give you a file.
2. Export one CSV: `proposal_assets/data/leaderboard_H3216917Z.csv` with columns
   `rank,display_name,date,listening,reading,writing,total,result`
   - `display_name` = **first name + initial only** (e.g. "Angeline S.").
   - `total` = listening + reading + writing; `result` = `Lulus` if total ≥ 180, else `Tidak lulus`.
   - Sort by total (high → low). The old app has no time-taken field, so for equal totals keep the earlier date first and add a note.
3. **Do not change** anything in the `easy-study-hsk` project (read only).

## D. Real Firestore data structure

The proposal has a table of Firestore collections (Bab IV.B). Export what the code **really** uses so the table can match:

- `proposal_assets/data/firestore_structure.md` — for **every** collection and subcollection:
  - name, what it stores, document ID format (e.g. `{jadwalId}_{yyyyMMdd}`),
  - every field: name, type, example value, required or optional,
  - relations (which field points to which collection).
- Build it from the Dart models, repositories, Cloud Functions code and `firestore.rules`. If you can read the emulator, add one **demo** example document per collection (never real personal data).
- Also copy, as they are now:
  - `proposal_assets/data/firestore.rules`
  - `proposal_assets/data/functions_list.md` — every Cloud Function: exact name, trigger type (callable / HTTP / Firestore trigger / scheduled + schedule), one line on what it does.
- Add a short **mapping table**: name in `EASY_STUDY_APP.md` → real name in the code, for anything that differs.

## E. Final checklist

- [ ] `proposal_assets/screens/` has 15 web PNGs (+ phone versions named `..._phone.png` for the 📱 ones)
- [ ] `proposal_assets/data/leaderboard_H3216917Z.csv` (or a note saying Will will send it)
- [ ] `proposal_assets/data/firestore_structure.md`, `firestore.rules`, `functions_list.md`
- [ ] `proposal_assets/README.md` listing which screens were already built and which you built now
- [ ] Zipped as `proposal_assets.zip`
