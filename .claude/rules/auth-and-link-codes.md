---
paths:
  - lib/services/auth_service.dart
  - lib/services/teacher_link_code_service.dart
  - lib/services/notification_service.dart
  - lib/features/auth/**
  - functions/index.js
  - firestore.rules
---

# Auth, link codes and notifications: invariants

Do not regress these when editing the files above. Background in
`docs/FIREBASE_BACKEND.md`.

## Registration order

- In `AuthService.register()`, resolve the teacher link code **before**
  `createUserWithEmailAndPassword`. Creating the auth account first and then
  hitting an invalid code leaves an orphaned account whose email can't be
  reused.

## Who can create accounts

- Self-registration is for **students and parents only** (`selfUserCreateValid`
  in `firestore.rules`, closed to teachers on 2026-10-17). Teachers and admins
  are created by an admin (`AuthService.createUserByAdmin`).
- `active == false` removes every role right in the rules (`isActive()`), and
  `AuthService.signIn` / `init` sign such accounts out. Keep both halves.

## Link-code resolution is server-side

- Students resolve codes through the `resolveLinkCode` Cloud Function, called
  from `TeacherLinkCodeService.resolveTeacherId`. Do **not** reintroduce a
  direct Firestore read of `teacher_link_codes` for resolution: it must work
  before sign-in and must not expose the collection.
- Only teachers may create or update `teacher_link_codes` / `teacher_link_state`
  docs, and only for their own uid. `resolveLinkCode` also checks that the
  code's owner is an active teacher.
- Code generation in `ensureLinkCode` treats a permission-denied read as "taken".

## Notifications

- Clients cannot write to `notifications` (rules require staff). Registration
  notifications are created by the `onUserCreated` trigger; do not add
  client-side notification writes to the student registration flow.
- Broadcasts store `userId: ''` (never omit the field). The client reads with
  two narrow queries (`userId == uid`, and `userId == '' && forRole in [...]`);
  a broad `collection('notifications')` read is refused by the rules.

## Progress ownership

- `student_progress` updates require the existing doc to already belong to the
  caller. Keep the ownership check on both create and update.

## After backend changes

- Run the rules tests: `npm --prefix rules-tests run test:emulator`.
- Deploy: `firebase deploy --only firestore:rules,functions` (confirm with the
  owner first; functions need project billing enabled).
