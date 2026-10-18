---
paths:
  - lib/**/*exercise*
  - lib/**/firestore_service.dart
  - lib/core/router/app_router.dart
---

# Exercise authoring: admin only, web only

Creating, editing and deleting exercises is available only to **admins** on
**web** (`kIsWeb`). Teachers can view exercises and student progress but cannot
create, edit, delete, or export worksheet inventory reports.

Note: thesis spec v2 (`docs/THESIS_FEATURE_BACKLOG.md`, Phase 5) wants teachers
to build practice packages from the question bank. When that phase lands,
update every layer below together and then rewrite this rule.

## Enforcement layers

1. **Platform gate**: `ExerciseAuthoringPlatform.canManageExercises(user)` in
   `lib/core/constants/exercise_authoring_platform.dart`.
2. **Router**: redirects exercise authoring routes for non-admins.
3. **Admin shell**: **New exercise** only when `canManageExercises`.
4. **Teacher shell**: no **New exercise** action; the exercises tab is read-only.
5. **Form screen**: shows the unsupported message for non-admins.
6. **Firestore**: `createExercise`, `updateExercise`, `deleteExercise` verify the
   admin role; rules: exercises write = `isAdmin()`.

## Related

Worksheet upload is also admin-only on web
(`WorksheetImportPlatform.isSupportedFor(user)`), see
`worksheet-import-web-only.md`.

## Do not

- Expose exercise authoring to teachers without updating all layers above.
- Add report export UI to the teacher dashboard or profile.
