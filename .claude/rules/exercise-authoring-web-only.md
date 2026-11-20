---
paths:
  - lib/**/*exercise*
  - lib/**/firestore_service.dart
  - lib/core/router/app_router.dart
---

# Exercise authoring: packages by staff, the bank by admins, all on web

Since 2026-11-13 (thesis Phase 5, owner's go-ahead) **teachers build
practice packages** from the question bank. The gates:

| What | Who | Gate |
|---|---|---|
| Packages (`bankSheets` / `bankQuestionIds`): create, edit, publish, delete | admin: any; teacher: **own** packages (`teacherId` = their uid) | `ExerciseAuthoringPlatform.canManageExercises(user)` + `canEditExercise(user, exercise)` |
| Question bank: scan worksheets, load samples, harvest, every question | admin | `ExerciseAuthoringPlatform.canManageBank(user)` |
| Question bank: type / paste questions; edit, move, delete **own** questions and worksheets made only of own questions (Build 2B, 2026-11-20) | teacher | `canWriteOwnBankQuestions(user)` + `canEditBankItem(user, item)` / `canEditBankSheet(user, sheet)` (`createdBy` = their uid) |
| Old-format exercises (questions inside the document, `TeacherExerciseFormScreen`) | admin | `ExerciseAuthoringPlatform.canManageLegacyExercises(user)` |

Everything above is **web only** (`kIsWeb`). Teachers **read** the whole
bank (rules: staff read) so the package form's *From bank* picker and the
worksheet screen work for them; other people's questions stay read-only. Assigning an exercise to students
stays staff.

Note: admin-created content uses `AppConstants.contentTeacherId`, which is
the `CONTENT_OWNER_ID` teacher uid when set. That teacher therefore owns
(and may edit) the admin-made packages. Accepted: it is the centre's own
content account.

## Enforcement layers

1. **Platform gate**: `lib/core/constants/exercise_authoring_platform.dart`
   (`canManageExercises`, `canEditExercise`, `canManageBank`,
   `canManageLegacyExercises`).
2. **Router**: `redirectFromAuthoringRoute` sends non-staff and non-web away
   from `/exercise/new` and `/exercise/:id/edit`. Teacher routes pass the
   teacher's own uid as `teacherId`.
3. **Admin shell**: **Scan worksheet** only when `canManageBank`.
4. **Teacher exercises tab**: **New exercise** / **Question bank** for
   staff on web; edit and delete (row and bulk) only for rows that pass
   `canEditExercise`; other rows are assign-only.
5. **Bank screens** (`question_bank_screen.dart`, `question_bank_sheet_screen.dart`,
   the picker in `exercise_package_form_screen.dart`): scan, type, paste,
   samples, harvest, edit, move, delete, "Add question" only when
   `canManageBank`; teachers see **View** and **Assign this**.
6. **Legacy form screen**: shows `adminOnlyMessage` unless
   `canManageLegacyExercises`.
7. **Service** (`firestore_service.dart`): `_ensureCanManagePackages` —
   admin passes; a teacher must be active, `teacherId` must be their uid, and
   every existing doc touched must be their own package (no `questions`
   inside). Used by `saveExercisePackage`, `setExercisesPublished`,
   `deleteExercise`. `createExercise` / `updateExercise` (legacy) stay
   admin-only.
8. **Bank rules (Build 2B)**: `question_bank` create = admin, or a teacher
   with `createdBy` = their uid; update = admin, or the creator (and
   `createdBy` unchanged), or any teacher touching only `usageCount` /
   `lastUsedAt`; delete = admin or the creator. Tests: "leaderboard,
   promotion, level, teacher bank (Build 2B)" in
   `rules-tests/firestore.rules.test.mjs`.
9. **Firestore rules**: `exercises` create/update/delete = `isAdmin()`, or
   `isTeacher()` with `ownsPackage(...)` on the existing and the new data
   (`teacherId == uid`, `questions` empty, at least one sheet or question;
   `teacherId` cannot change). Tests: "teacher packages (2026-11-13)" in
   `rules-tests/firestore.rules.test.mjs`.

## Related

Worksheet upload is admin-only on web
(`WorksheetImportPlatform.isSupportedFor(user)` = `canManageBank`), see
`worksheet-import-web-only.md`.

## Do not

- Let a teacher scan worksheets, load samples, harvest, or change another
  person's bank question from the UI (the rules refuse it too).
- Let a teacher edit old-format exercises or another author's package
  without updating the service check, the rules and the tests together.
- Add report export UI to the teacher dashboard or profile.
