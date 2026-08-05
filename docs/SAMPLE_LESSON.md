# Sample lesson & quiz (Firestore)

After you register as a **teacher**, copy your **User UID** from Firebase Console → Authentication or Firestore `users` document.

Replace `YOUR_TEACHER_UID` below.

## HSK levels & terms

- **Student level:** `HSK 1` … `HSK 6` (set at registration)
- **Term size:** `8` or `16` lessons per term (set at registration on student profile as `termSize`)
- **Lesson fields:**
  - `level` — e.g. `HSK 1` (must match student’s HSK to appear for them)
  - `termNumber` — `1`, `2`, `3`…
  - `order` — lesson number within the term (`1`–`8` or `1`–`16`)

## Collection: `lessons`

Document ID: auto or `lesson_greetings`

```json
{
  "title": "Greetings",
  "unit": "Term 1 — Basics",
  "termNumber": 1,
  "order": 1,
  "teacherId": "YOUR_TEACHER_UID",
  "level": "HSK 1",
  "content": "你好 (nǐ hǎo) — Hello\n\n谢谢 (xièxie) — Thank you\n\n再见 (zàijiàn) — Goodbye",
  "audioUrl": ""
}
```

Copy the lesson document **ID** for the quiz (`lessonId`).

## Collection: `quizzes`

```json
{
  "lessonId": "PASTE_LESSON_DOC_ID",
  "teacherId": "YOUR_TEACHER_UID",
  "title": "Greetings quiz",
  "questions": [
    {
      "question": "What does 你好 mean?",
      "options": ["Thank you", "Hello", "Goodbye", "Please"],
      "correctIndex": 1
    },
    {
      "question": "How do you say Thank you?",
      "options": ["再见", "你好", "谢谢", "请"],
      "correctIndex": 2
    }
  ]
}
```

## Teacher invite (automatic)

When a teacher registers, the app creates `teacher_invites/{CODE}` → `{ "teacherId": "..." }`.

Students use that 6-character code on registration.

## Student document example

```json
{
  "name": "Student Name",
  "email": "student@example.com",
  "role": "student",
  "teacherId": "YOUR_TEACHER_UID",
  "level": "HSK 1",
  "termSize": 8
}
```
