# Firebase Backend — Easy Study

Maps the **Figma Make v1.2** prototype (`Follow MD file instructions.zip`) to the Flutter + Firestore backend in this repo.

## Roles (Figma → Firebase)

| Figma | Firestore `users.role` | Flutter route |
|-------|------------------------|---------------|
| Admin | `admin` | `/admin` |
| Guru | `teacher` | `/teacher` |
| Murid | `student` | `/student` |

Admin has full centre access (users, vouchers, reports). Guru uses the teacher shell. Murid uses the student shell.

## Collections

| Collection | Purpose |
|------------|---------|
| `users` | Profiles: name, email, role, `active`, `teacherId`, `level`, `termSize` |
| `lessons` | Lesson content per teacher |
| `quizzes` / `quiz_results` | Lesson quizzes |
| `exercises` | Practice (MC, compose, matching, listening, …) |
| `exercise_assignments` | Homework assigned to students |
| `exercise_results` | Practice scores |
| `student_progress` | Lesson completion + quiz scores |
| `class_sessions` | Scheduled classes |
| `attendance` | Join records + `attendanceStatus` (`present` / `absent`) |
| `student_class_terms` | Voucher packages (`voucherCode`, sessions remaining) |
| `notifications` | In-app alerts (`forRole`, optional `userId`) |
| `teacher_link_codes` | Rotating 6-character codes linking students to a teacher (15-min TTL) |
| `teacher_link_state` | Per-teacher link code rotation state |

## New in v1.2 backend

### Admin platform
- `AppUser.isAdmin`, `active` flag
- `FirestoreService.watchAllUsers()`, `setUserActive()`
- `AdminShell` with Dashboard, Users, Exercises, Classes, Vouchers, Reports, Profile
- `AdminReportService` — monthly signups, HSK bands, exercise completion

### Vouchers
- Auto-generated `voucherCode` on `createClassTermPackage()` (e.g. `ES-8SESS-A1B2`)
- Admin **Vouchers** tab lists all `student_class_terms`

### Notifications
- `notifications` collection + `NotificationService`
- Kinds: `registration`, `session`, `grading`
- Filtered by `forRole` (`admin`, `teacher`, `student`, `all`)

### Listening exercises
- `ExerciseType.listening` + optional `audioUrl` on exercises

### Attendance
- `attendanceStatus` on attendance records for present/absent marking

## Cloud Functions

Source: `functions/index.js` (Node 20, firebase-functions v2). Deploy with:

```bash
firebase deploy --only functions
```

| Function | Type | Purpose |
|----------|------|---------|
| `resolveLinkCode` | callable (`onCall`) | Resolves a teacher link code → `teacherId` with admin privileges. Invokable **before sign-in** (email/password registration has no auth account yet), so `teacher_link_codes` can stay closed to client reads. Throws `HttpsError` for invalid / expired codes. |
| `onUserCreated` | Firestore trigger (`users/{uid}` create) | When a **student** doc is created, writes `registration` notifications for the admin and the student's teacher. Clients can't write `notifications` (staff-only), so the trigger owns this. Runs once per student, covering self-registration and admin-created students. |

> Requires the Firebase **Blaze** plan (gen-2 functions). The Flutter client calls `resolveLinkCode` via the `cloud_functions` package (`FirebaseFunctions.instance`).

## Security rules

Deploy after changes:

```bash
firebase deploy --only firestore:rules
```

- `isStaff()` = teacher **or** admin
- Admin can activate/deactivate users
- **Exercise writes** (`create` / `update` / `delete`) = **admin only**
- Staff (teacher + admin) can manage classes, vouchers, attendance, and **assign** exercises
- **`users` collection** — students can read only themselves + staff profiles; self-registration cannot set `role: admin`; users cannot change their own `role`, `teacherId`, or `active` flag
- **`notifications`** — users only see notifications for their role; mark-read limited to the `read` field
- **`student_progress`** — `update` requires the **existing** doc already belongs to the caller, so a student can't overwrite another student's progress by guessing its id
- **`teacher_link_codes`** — no anonymous reads. A teacher may read their own code docs (and non-existent candidates during generation); resolving a code for registration goes through the `resolveLinkCode` function instead of a direct read

## Recent backend fixes (registration hardening)

Applied July 2026. See commit history for exact diffs.

1. **Orphaned account on bad link code** — `AuthService.register()` now validates the link code (`resolveLinkCode`) **before** creating the Firebase Auth user. Previously a bad code left an auth account with no profile, and the email couldn't be re-registered.
2. **False "registration failed" error** — student self-registration no longer writes notifications client-side (which rules blocked). The `onUserCreated` function handles it server-side.
3. **Link-code enumeration** — resolution moved server-side (`resolveLinkCode`) and the `teacher_link_codes` read rule was locked down.
4. **Progress hijack** — `student_progress` update rule now checks existing ownership.

## Test accounts

```bash
bash scripts/seed_test_accounts.sh
python3 scripts/seed_report_demo_data.py   # optional demo data
```

| Account | Email | Password |
|---------|-------|----------|
| Admin | `admin@test.chinesetracker` | `testpass123` |
| Guru | `teacher@test.chinesetracker` | `testpass123` |
| Murid 1–3 | `student1@test.chinesetracker` … | `testpass123` |

Sign in at `/dev-login`.

## Figma zip vs Flutter

The zip is a **React UI prototype** with mock data. Flutter implements the real Firebase backend. Do not run the zip as production — use it as the design reference; wire screens in `lib/features/`.

### Still mock in Figma (wire next)
- Income/revenue charts (no payments in scope)
- Notification tap-through routing
- Listening player UI (type exists in backend)
- Admin user create/edit forms (activate toggle is live)

## Suggested endpoints (implemented as Firestore streams)

| Figma mock API | Flutter implementation |
|----------------|------------------------|
| `GET /api/teacher/students` | `watchAllStudents()` |
| `GET /api/teacher/exercises` | `watchAllExercises()` |
| `GET /api/teacher/classes` | `watchAllClassSessions()` |
| `GET /api/teacher/activity` | `TeacherActivityUtils.buildFeed()` |
| Admin users | `watchAllUsers()` |
| Admin vouchers | `watchAllClassTerms()` |
| Admin reports | `AdminReportService.build()` |
