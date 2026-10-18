# Cursor build prompt — Tier 1 features (Payments, Parent access, Calendar)

Copy the block below into Cursor. It implements the three Tier 1 items from
`docs/FEATURE_COMPARISON_LINGUAHUB.md`: **Midtrans payments/invoicing**,
**parent access**, and a **schedule calendar**. Build in the phases given; each
phase should compile and be reviewable on its own.

---

## Context & ground rules

Stack: Flutter + Firebase (Auth, Firestore, Cloud Functions v2, Storage),
`provider`, `go_router`. Follow existing patterns:

- Collections & roles are in `lib/core/constants/app_constants.dart`
  (`usersCollection`, `classSessionsCollection`, `studentClassTermsCollection`,
  `notificationsCollection`, roles `admin`/`teacher`/`student`).
- Services extend the pattern in `lib/services/firestore_service.dart`; screens
  live under `lib/features/<role>/`; routes in `lib/core/router/app_router.dart`.
- Cloud Functions go in `functions/index.js` (v2, already has `resolveLinkCode`,
  `onUserCreated`, `onExerciseResultCreated`). Firestore rules in
  `firestore.rules`, indexes in `firestore.indexes.json`.
- Reuse `student_class_terms` (session packages: `packageSize`,
  `sessionsRemaining`, `startDate`, `deadlineDate`, `status`) as the "quota."

**Security (non-negotiable):**
- The **Midtrans Server Key lives only in Cloud Functions** (Firebase Secrets:
  `firebase functions:secrets:set MIDTRANS_SERVER_KEY`). Never in the Flutter app
  or committed to git. The client may hold only the **Client Key**.
- **Invoice `status` is written only by the webhook function** (admin SDK). No
  client or rule may set an invoice to paid.
- Verify the Midtrans notification signature server-side
  (`sha512(order_id + status_code + gross_amount + ServerKey)`) before trusting it.
- Requires the Firebase **Blaze** plan (functions + outbound HTTP to Midtrans).

Before starting: `flutter pub get && flutter analyze` and read the current state
of the files above (they've been edited recently).

---

## Phase 1 — Payments & Midtrans invoicing

### Data model — `invoices` collection
```
invoices/{invoiceId}
  invoiceNumber   string   // e.g. ES-INV-1042
  studentId       string   // users/{uid}
  teacherId       string   // owning teacher (for scoping)
  packageSize     number   // sessions purchased (align with allowed sizes, below)
  amount          number   // IDR, integer
  currency        string   // "IDR"
  status          string   // "pending" | "paid" | "expired" | "failed"
  dueDate         string   // yyyy-MM-dd
  midtransOrderId string
  snapToken       string?   // set by createInvoice
  createdAt       timestamp
  paidAt          timestamp?
  createdBy       string    // uid
```
Align `student_class_terms.packageSize` and the invoice `packageSize` with the
packs you sell (the rules currently allow `[8, 16]`; update the enum in
`firestore.rules` if you add 4/12).

### Cloud Functions (`functions/index.js`)
1. `createInvoice` (callable, staff-only OR student self-service):
   - Input: `{ studentId, packageSize, amount, dueDate }` (for self-service,
     derive studentId from `request.auth.uid`).
   - Creates the invoice doc (`status: "pending"`), calls the **Midtrans Snap**
     `/transactions` API with the server key, stores `snapToken` + `midtransOrderId`,
     returns `{ snapToken, redirectUrl, invoiceId }`.
2. `midtransNotification` (HTTPS `onRequest`): the webhook.
   - Verify signature. Map Midtrans status → invoice status
     (`settlement`/`capture` → paid; `expire` → expired; `deny`/`cancel` → failed).
   - On **paid**: set `status: "paid"`, `paidAt`; **credit sessions** — create or
     top up the student's `student_class_terms` (respect existing model:
     `sessionsRemaining = packageSize`, `startDate`, `deadlineDate`). Write a
     `notifications` doc (student + teacher) and an audit entry (see Phase-4
     `audit_logs` if you add it; otherwise skip).
   - Idempotent: ignore repeat notifications for an already-final invoice.
   Register the webhook URL in the Midtrans dashboard.

### Firestore rules (`firestore.rules`)
```
match /invoices/{id} {
  allow read: if isSignedIn() && (
    isStaff() ||
    resource.data.studentId == request.auth.uid ||
    isParentOf(resource.data.studentId)      // Phase 2 helper
  );
  allow create: if isStaff();                 // self-service goes through the callable
  allow update, delete: if false;             // status only via webhook (admin SDK)
}
```

### Flutter
- Model `lib/models/invoice.dart`; service methods in `firestore_service.dart`
  (`watchStudentInvoices`, `watchAllInvoices`, etc.) + a `PaymentService` that
  calls `createInvoice` via `cloud_functions` and opens Snap (use the
  `midtrans_sdk` package, or open `redirectUrl` with `url_launcher` for web).
- Screens:
  - **Admin**: an Invoices tab (list + status chips + "Create Invoice").
  - **Student**: a Payments/Quota tab — show outstanding bill, invoice history,
    and a **"Buy more sessions"** button → package picker → `createInvoice` → Snap.
- Add `MIDTRANS_CLIENT_KEY` via `--dart-define`; store the Client Key only.

---

## Phase 2 — Parent access

### Model
Add role `parent` (`AppConstants.roleParent = 'parent'`). A parent user doc:
```
users/{parentUid}
  role: "parent"
  studentIds: [ "<studentUid>", ... ]   // linked children
```
Link at registration (parent enters the child's link code or is created by an
admin) — reuse the existing `teacher_link_codes` / admin-create flow.

### Rules
```
function isParentOf(studentId) {
  return isSignedIn() &&
    userDoc().data.get('role','') == 'parent' &&
    (studentId in userDoc().data.get('studentIds', []));
}
```
Extend read rules on `users`, `student_progress`, `attendance`, `invoices`,
`student_class_terms`, `quiz_results`, `exercise_results` to also allow
`isParentOf(resource.data.studentId)`. Parents are **read-only** (no writes).

### Flutter
- Add a **Parent shell** (`lib/features/parent/`) + `/parent` routes in
  `app_router.dart`, with the redirect logic mirroring the other roles.
- Reuse existing student widgets in read-only mode (progress, attendance, grades,
  invoices). If a parent has multiple children, add a child switcher.

---

## Phase 3 — Schedule calendar

Mostly a new **view over existing `class_sessions`** (fields `sessionDate`,
`startMinutes`, `endMinutes`, `teacherId`). Minimal data work.

- Add a Calendar screen for **teacher** and **student** (and parent, read-only):
  Week view default, with Day/Month toggle. Use the `table_calendar` package or a
  custom week grid.
- Teacher: their sessions (`watchTeacherSessions(teacherId)` already exists).
  Student/parent: sessions for the linked teacher (and later, enrolled classes).
- Optional small metadata additions on `class_sessions` (`mode`:
  offline/online/hybrid, `room`) to display on events — this is the seed of the
  Tier-2 class-metadata work; keep it optional so the calendar works without it.
- Add a "View calendar" entry point from the student dashboard.

---

## Phase 4 — Cross-cutting

- **Indexes:** add any composite indexes the new queries need (e.g. `invoices`
  by `studentId`+`createdAt`, or `teacherId`+`status`) to
  `firestore.indexes.json`.
- **Tests:** add rules tests (student can't mark own invoice paid; parent reads
  only linked children) and a unit test for the webhook status mapping.
- **Deploy:**
  ```bash
  firebase deploy --only firestore:rules,firestore:indexes
  firebase functions:secrets:set MIDTRANS_SERVER_KEY
  firebase deploy --only functions   # Blaze required
  ```

## Acceptance
- `flutter analyze` clean; app runs on web.
- Admin creates an invoice; student sees it as pending; completing a Midtrans
  **sandbox** payment flips it to paid **via the webhook** and credits sessions
  to `student_class_terms`. No client path can set an invoice to paid.
- A parent account logs in and sees its child's progress, attendance, grades, and
  invoices — read-only — and nothing for other students.
- Teacher and student calendars render this week's sessions with day/week toggle.

## Guardrails
- Midtrans **Server Key only in Cloud Functions secrets**; Client Key only in the
  app. Never commit either.
- Do not regress the fixes in `docs/DEBUG_REPORT.md` (register ordering,
  notification triggers, content-owner resolution, rules).
- Build incrementally; keep each phase compiling.
