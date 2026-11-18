# Live test: Build 2A (typing matcher and marking)

For the owner, on https://chinese-tracker.web.app. About 15 minutes. Use the
live test accounts (`admin@`, `teacher@`, `student1@test.chinesetracker`,
password in `docs/CLAUDE_FULL_HANDOFF.md`). Button names are given as
**English (Indonesian)**; switch the language on the sign-in page or the
Profile tab if you like.

If a step does not look like "You should see", stop there, take a screenshot
and tell the BUILD chat the step number.

## Part A: three questions in the bank (admin)

1. Open https://chinese-tracker.web.app and sign in as `admin@`.
2. In the left menu open **Question bank (Bank soal)**.
3. Click **Type a question (Ketik soal)**.
4. Question 1, typed hanzi:
   - **Type (Tipe)**: **Type the hanzi (写汉字) / Tulis hanzi (写汉字)**
   - **Pinyin hint (Petunjuk pinyin)**: `wǒ hěn xǐhuan hē chá`
   - **Accepted answers (Jawaban yang diterima)**: `我很喜欢喝茶`
   - Click **Add to bank (Tambah ke bank soal)**.
5. Click **Type a question (Ketik soal)** again. Question 2, typed pinyin:
   - **Type**: **Type the pinyin (写拼音) / Ketik pinyin (写拼音)**
   - **Hanzi to write in pinyin (Hanzi yang ditulis pinyinnya)**: `你好`
   - **Accepted pinyin (Pinyin yang diterima)**: `nǐ hǎo`
   - Click **Add to bank**.
6. Click **Type a question** again. Question 3, free writing:
   - **Type**: **Free writing (写作) / Menulis bebas (写作)**
   - **Writing task (Tugas menulis)**: `用"周末"和"公园"写一段话。`
   - **Words to use (Kata yang harus dipakai)**: `周末, 公园`
   - Leave **Text to read first** empty.
   - Click **Add to bank**.

You should see: the three questions in the bank list.

## Part B: a package for student1 (admin)

7. Left menu: **Exercises (Latihan)** → **New exercise (Latihan baru)**.
8. **Title (Judul)**: `Tes 2A mengetik`.
9. Click **Add from bank (Tambah dari bank soal)**, find the three questions
   (search `周末`, `你好`, `喝茶`), tick each one, then **Done (Selesai)**.
10. Turn **Published (Terbit)** on, then click **Save and assign (Simpan dan
    tugaskan)**.
11. Tick **student1** and click **Save (1 student) / Simpan (1 murid)**.

You should see: "Assigned to 1 student".

## Part C: the student answers (student1)

12. Sign out (bottom of the left menu). Sign in as `student1@`.
13. Open **Lessons (Pelajaran)** and tap **Tes 2A mengetik**.
14. Question 1: type `我很喜欢和茶` (和 instead of 喝, on purpose).
15. Question 2: type `ni hao` (no tones, on purpose).
16. Question 3: type `这个周末我和朋友去书店买书。`
17. Click **Submit answers (Kirim jawaban)**.

You should see:
- Questions 1 and 2 with an hourglass and **"Half marks for now; your
  teacher will check it" (Setengah nilai untuk sementara; guru akan
  memeriksanya)**.
- Question 3 with **"Waiting for your teacher's marking" (Menunggu penilaian guru)**
  and the words to use.
- The line "Some answers wait for your teacher. The score can still change." (Beberapa jawaban menunggu guru. Nilai masih bisa berubah.)
- No confetti.
- The bell gets a notification "Waiting for marking".

## Part D: the teacher marks (teacher)

18. Sign out. Sign in as `teacher@`.
19. Left menu **Tests (Tes)** → **Marking (Penilaian)**. The button shows a
    red number (3).
    - If the page shows an error, wait 5 minutes (the new database indexes
      may still be building) and reload.
    - If the list is empty, sign in as `admin@` instead and open Tests →
      Marking: admins see every item. Tell the BUILD chat which teacher
      student1 belongs to.
20. Open the item **"one character off" (beda satu karakter)** → click
    **Full marks (Nilai penuh)**.
21. Open the item **"tone wrong or missing" (nada salah atau tidak ada)** → click **Keep half (Tetap
    setengah)**.
22. Open the item **"free writing" (menulis bebas)**. You should see `周末`
    with a tick and `公园` with a cross. Move the sliders to Grammar 30,
    Vocabulary 20, Content 20 (the line shows "70 / 100 = 7 of 10 points"),
    then **Save mark (Simpan nilai)**.

You should see: "Mark saved." after each one, and at the end "Nothing to
mark (Tidak ada yang perlu dinilai)".

## Part E: the student sees the final result (student1)

23. Sign out. Sign in as `student1@`.
24. The bell: a notification **"Marked"** with the package name and a
    percent.
25. **Lessons** → **Tes 2A mengetik**: the best score is now **71%**
    (1 + 0.5 + 7 = 8.5 of 12 points).
26. Open the result review if offered: question 3 says "Your teacher gave 7
    of 10 points".

## Afterwards

- Keep or delete the package (admin → Exercises). The bank questions can
  stay as examples.
- Report: all passed, or the first step that failed (number + screenshot).
- The supervised-test parts of Build 2A (End test keeps typed answers, the
  hourly close, Reset attempt, QR code) were walked on the emulators; on live
  they need a test code with a free-writing question, which can wait for the
  trial.
