# Cursor build prompt — Tier 3 features (operational maturity)

Copy the block below into Cursor. Implements the Tier 3 items from
`docs/FEATURE_COMPARISON_LINGUAHUB.md`. These are "operational maturity" features;
several are scale-dependent — **do the scope decision first**, then build the
chosen phases. Follow existing patterns and don't regress the fixes in
`docs/DEBUG_REPORT.md` / `docs/CURSOR_TIER1_REVIEW.md` (content-owner resolution,
parent `linkChild` security, server-authoritative pricing).

Prereqs: `flutter pub get && flutter analyze` clean. Append a summary to
`docs/CHANGELOG.md` when done, flagging anything incomplete.

## Scope decision (do this first)
This is a single Chinese centre (one owner/admin). Recommended order:
1. **Org Settings** (cheap, unlocks toggles used by other features) — do first.
2. **Audit log** (valuable now that money moves through the app).
3. **Materials repository** (shared files beyond structured lessons).
4. **Semester evaluations** (gated by a Settings toggle).
5. **Admin financial summary** (reuse Admin — you now have invoices).
6. **Granular admin permissions** — only if you add more than one admin.
Skip the separate **Owner role** and **teacher performance ratings** unless you
scale to a multi-teacher institution; an admin financial summary covers the need.

---

## Phase 1 — Org Settings

### Data — single doc `settings/org`
```
settings/org
  requireEmailVerification   bool
  autoGenerateStaffPasswords bool
  enablePayments             bool   // gates the invoice/Buy UI
  allowTeacherReschedule     bool
  evaluationFormsOpen        bool   // gates evaluation creation (Phase 4)
  updatedAt / updatedBy
```
Rules: `allow read: if isSignedIn(); allow write: if isAdmin();`

### Flutter
- Model + `watchOrgSettings()` / `updateOrgSettings()`; provide via `provider`.
- Admin **Settings** tab with toggles.
- Wire the cheap ones: `enablePayments` gates the payments UI; `evaluationFormsOpen`
  gates evaluation writes; `allowTeacherReschedule` gates the session reschedule
  action for teachers.

## Phase 2 — Audit log

### Data — `audit_logs` collection
```
audit_logs/{id}
  action    string   // "invoice.created" | "invoice.paid" | "user.permissions" | "attendance.revoked" | ...
  actorId   string   // uid or "system"
  actorName string
  targetType string?  targetId string?
  detail    string
  createdAt timestamp
```
Rules: `allow read: if isAdmin(); allow create, update, delete: if false;`
(all writes via Cloud Functions with the admin SDK).

### Cloud Functions (`functions/index.js`)
- Add a small `writeAudit(entry)` helper and emit entries from existing paths:
  `midtransNotification` (invoice.paid), `createInvoice` (invoice.created), and
  new triggers for permission changes / attendance revocation as needed.
- For staff-initiated UI actions that should be audited, prefer a callable that
  performs the action **and** writes the audit entry server-side (so the log
  can't be forged or skipped).

### Flutter
- Admin **Audit Logs** screen: reverse-chronological list (actor · action · time).

## Phase 3 — Materials repository

### Data — `materials` collection + Firebase Storage
```
materials/{id}
  ownerId    string   // contentOwnerFor(user)
  title      string
  level      string?  skill string?
  tags       array<string>
  status     string   // "draft" | "published"
  fileUrl    string?  fileName string?  fileType string?
  createdBy / createdAt
```
- Rules: `read: if isSignedIn() && (isStaff() || resource.data.status ==
  'published');` `create, update, delete: if isStaff();`
- **Storage rules** (`storage.rules`): allow staff upload under
  `materials/{ownerId}/...`; read for signed-in users. Reuse the
  `profile_photo_service` upload pattern; cap file size and validate type.

### Flutter
- Model + service; **Materials** screen (staff CRUD + upload via `file_picker`);
  student/parent read-only list of **published** materials filtered by level/class.

## Phase 4 — Semester evaluations

### Data — `evaluations` collection
```
evaluations/{id}
  studentId  string  teacherId string  term string
  rating     number? // 1..5 (optional)
  strengths  string  improvements string  comment string
  status     string  // "draft" | "published"
  createdAt / updatedAt
```
- Only writable when `settings.org.evaluationFormsOpen` is true (enforce in the
  callable/UI; rules can't read another doc cheaply for every write, so gate in a
  callable if you want it server-enforced).
- Rules: staff write; student reads own **published**; parent reads linked child's
  published (`isParentOf`).

### Flutter
- Teacher: write/publish an evaluation per student per term (the dashboard already
  surfaces "evaluations to write" — wire the count).
- Student/Parent: read published evaluations in the transcript/profile area.

## Phase 5 — Admin financial summary (reuse Admin, no Owner role)
- An Admin dashboard section computed from `invoices`: revenue this month,
  outstanding (pending+overdue), recent payments. Read-only; reuse existing chart
  widgets. This gives the "owner" financial view without a new role.

## Phase 6 — Granular admin permissions (only if >1 admin)
- Add `permissions: array<string>` to admin users (e.g. `["payments","users",
  "reports"]`). Add `hasPermission(p)` helpers in rules + UI gating. Keep a
  "full access" admin as the default. Migrate existing admins to full access.

## Cross-cutting
- Add composite indexes for new queries (e.g. `materials(ownerId,status)`,
  `audit_logs(createdAt)`, `evaluations(studentId,term)`).
- Rules tests for each collection (student can't read audit logs / draft
  materials / others' evaluations; parent reads only linked child's published
  evaluations).
- Deploy: `firebase deploy --only firestore:rules,firestore:indexes,functions`
  and `firebase deploy --only storage` for the materials Storage rules.

## Acceptance
- Admin toggles a setting and a dependent feature responds (e.g. disabling
  payments hides the Buy/invoice UI).
- A staff action writes an audit entry that only admins can read.
- Staff upload a material, publish it, and a student sees only published ones.
- A teacher writes an evaluation only while forms are open; the linked parent sees
  it once published.
- Admin sees a revenue/outstanding summary derived from invoices.
