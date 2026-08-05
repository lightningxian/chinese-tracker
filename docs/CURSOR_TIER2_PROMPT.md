# Cursor build prompt — Tier 2 features (Gradebook, Question Bank, Class metadata)

Copy the block below into Cursor. Implements the Tier 2 items from
`docs/FEATURE_COMPARISON_LINGUAHUB.md`. Build in phases; each phase must compile
(`flutter analyze`) and follow existing patterns (see the Tier 1 prompt and
`docs/DEBUG_REPORT.md` for conventions and the fixes not to regress).

Prereqs: `flutter pub get && flutter analyze` clean first. Reuse the existing
collections/roles in `lib/core/constants/app_constants.dart` and the service
pattern in `lib/services/firestore_service.dart`. Don't regress the content-owner
resolution fix (teachers resolve by their own id) or the parent-link security fix
(`linkChild` only).

---

## Phase 1 — Gradebook

Today scores live in `quiz_results` and `exercise_results` only. Add
first-class **grades** so teachers have a "grades pending" queue and students/
parents get a transcript.

### Data model — `grades` collection
```
grades/{gradeId}
  studentId     string
  teacherId     string
  classSessionId string?    // optional link to a session/class
  title         string      // e.g. "Speaking Test", "Midterm"
  category      string      // "quiz" | "exercise" | "speaking" | "writing" | "exam" | "other"
  score         number      // 0..100
  letterGrade   string?     // derived (see helper) or manual
  status        string      // "pending" | "graded"
  gradedBy      string
  createdAt     timestamp
  gradedAt      timestamp?
```
- Add a `letterGradeFor(score)` helper in `lib/core/utils/` (e.g. 90+ A, 85+ B+,
  80+ B, …) — reuse for display.
- A teacher can create a `pending` grade (assessment scheduled) and later fill the
  score → `graded`. Existing quiz/exercise scores can also be surfaced read-only
  in the same transcript view without duplicating (query all three sources).

### Rules (`firestore.rules`)
```
match /grades/{id} {
  allow read: if isSignedIn() && (
    isStaff() ||
    resource.data.studentId == request.auth.uid ||
    isParentOf(resource.data.get('studentId',''))
  );
  allow create, update, delete: if isStaff();   // teachers own the gradebook
}
```
Add a composite index if you query `grades` by `teacherId`+`status` or
`studentId`+`createdAt`.

### Flutter
- Model `lib/models/grade.dart` + `firestore_service` methods
  (`watchStudentGrades`, `watchTeacherPendingGrades`, `createGrade`, `setGrade`).
- Teacher: a **Grades** tab (list + "grades pending" count on the dashboard —
  wire the existing dashboard stat) with an entry/edit form.
- Student & Parent: a **Grades / transcript** view (read-only), merging `grades`
  with existing quiz/exercise scores, newest first, with letter grades.

## Phase 2 — Question Bank

Exercises currently embed `ExerciseQuestion`s inline. Add a reusable pool so
teachers/admin author once and reuse across exercises/quizzes.

### Data model — `question_bank` collection
```
question_bank/{questionId}
  ownerId       string      // contentTeacherId(user) — same ownership model as lessons
  type          string      // reuse ExerciseType values (mc, compose, matching, listening)
  prompt        string
  options       array?      // for MC
  answer        ...         // shape per type (reuse ExerciseQuestion serialization)
  skillCategory string?     // reuse exercise_skill_category
  level         string?     // "HSK 1".."HSK 6"
  tags          array<string>
  createdBy     string
  createdAt     timestamp
```
Reuse the existing `ExerciseQuestion` / `ExerciseType` / `exercise_skill_category`
models for serialization so bank questions drop straight into exercises.

### Rules
```
match /question_bank/{id} {
  allow read: if isSignedIn();                 // any signed-in staff/student may read
  allow create, update, delete: if isStaff();
}
```
Scope reads to staff if you don't want students reading raw answers
(recommended: `allow read: if isStaff();`).

### Flutter
- Model + service (`watchQuestionBank(ownerId)`, CRUD).
- Admin/Teacher **Question Bank** screen (list, filter by type/level/tag, CRUD).
- In the exercise/quiz authoring form, add **"Add from Question Bank"** — pick
  questions to copy into the exercise (reuse `matching_exercise_editor` patterns).
- Optional: "Save question to bank" from the authoring form.

## Phase 3 — Class metadata

Enrich `class_sessions` so the calendar and class views show mode/room/capacity
and a registration state (this also improves the Tier 1 calendar).

### Model additions — `class_sessions`
```
mode           string?   // "offline" | "online" | "hybrid"
room           string?
capacity       number?
registrationState string? // "draft" | "open" | "active" | "closed"
```
`enrolledCount` can be derived from attendance/enrolment rather than stored; if
you add explicit enrolment, track it separately.

### Flutter
- Extend `ClassSession` model + `teacher_session_form_screen` with mode/room/
  capacity/registration fields (all optional; keep existing sessions valid).
- Show mode/room + occupancy (`enrolled/capacity`) on the calendar events
  (`class_calendar_screen`), teacher session cards, and student class views.
- Add an "Open for registration" state so students can see/join open classes.

## Cross-cutting
- Add any needed composite indexes to `firestore.indexes.json`.
- Rules tests: parent can read their child's grades; a student can't write grades;
  students can't read the question bank if you scope it to staff.
- Keep each phase compiling; run `flutter analyze` between phases.

## Acceptance
- Teacher creates a pending grade, fills a score → it appears in the student's and
  linked parent's transcript with a letter grade; teacher "grades pending" count
  reflects it.
- A teacher authors an exercise by pulling questions from the Question Bank.
- A session with mode=hybrid, room, capacity shows correctly on the calendar and
  class cards, and an "open for registration" class is visible to students.
