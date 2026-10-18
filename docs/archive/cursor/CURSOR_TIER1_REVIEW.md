# Review — Cursor's Tier 1 implementation (payments / parent / calendar)

Static review of what Cursor built. Severity: 🔴 high · 🟠 medium · 🟡 low.
No `flutter analyze` was available here — run it first (new deps: `cloud_functions`,
`url_launcher`, `table_calendar`).

## What's good (verified)
- **Invoice writes are locked down**: `invoices` rules are `create, update,
  delete: if false` — status is only ever set by the webhook (admin SDK). ✅
- **Webhook verifies the Midtrans signature** (`sha512(order_id+status_code+
  gross_amount+serverKey)`) and maps status correctly. ✅
- **Server Key is server-only** (`defineSecret("MIDTRANS_SERVER_KEY")`, passed via
  `secrets:`); the Flutter client only calls the `createInvoice` callable and
  opens the returned `redirectUrl`. No key in the app. ✅
- **createInvoice is staff-only** and teachers can only invoice their own
  students. Package sizes are consistent (`[8,16]`) between functions and rules. ✅
- Parent read-scoping added across `invoices`, `student_progress`,
  `exercise_results`, `quiz_results`, `attendance`, and `users`. ✅

## Fixed in this review
- 🟠 **Webhook double-credit race** — the pending→paid flip + credit wasn't
  atomic, so duplicate/concurrent Midtrans notifications could add the session
  package twice. Now wrapped in a Firestore transaction so only the flip that
  wins credits. (`functions/index.js`, `midtransNotification`.)

## Open — fix in Cursor

### R-1 🔴 Parents can link to ANY student (authorization hole) — ✅ FIXED 2026-07-17
Resolved in this repo. `linkChild` Cloud Function now does the authoritative
link (admin SDK, verifies the child code server-side); rules block clients from
writing `studentIds`/`teacherIds` (`selfUserCreateValid` requires them empty for
parents, `selfUserUpdateValid` requires them unchanged); `AuthService.registerParent`
creates an unlinked parent then calls `linkChild`; `ChildLinkService.linkChild`
added. **Cursor: verify** with `flutter analyze` and a rules test (a user cannot
self-register/self-update as a parent of a student whose code they don't hold),
and confirm admin-created parents still link (they use the privileged admin path).

Original issue (for context):
The child-code check exists only on the client. A parent's `users` doc is written
**client-side**, and the rules don't restrict `studentIds`:
- `selfUserCreateValid()` for a parent only checks `studentIds is list`.
- `selfUserUpdateValid()` doesn't check `studentIds`/`teacherIds` at all.

So anyone can self-register (or self-update) as `role: 'parent'` with
`studentIds: ['<any student uid>']` and read that student's progress, attendance,
grades, and invoices — without ever knowing the child code. `resolveChildCode`
returning the id to the client doesn't help, because the client is trusted to
write `studentIds`.

**Fix — move linking server-side and forbid client writes to the link fields:**
1. Add a `linkChild` **callable** (replace/augment `resolveChildCode`): it takes
   the child code, verifies it server-side, and — with the admin SDK — appends the
   resolved `studentId` (and derived `teacherId`) to the **caller's** parent doc
   (`request.auth.uid`). This is the only path that can set `studentIds`.
2. Rules: parent self-create must require `studentIds == []` (empty) and
   `teacherIds == []`; `selfUserUpdateValid()` must require `studentIds` and
   `teacherIds` unchanged. Clients can never set these fields.
3. `AuthService.registerParent`: create the parent auth account + profile with
   **empty** `studentIds`, then call `linkChild(childCode)` to link. Order:
   account exists → callable verifies code → callable writes `studentIds`.
4. `createUserByAdmin` (admin-created parents) can keep setting `studentIds` via
   the admin path, since admin writes are already privileged in rules.

### R-2 🟠 createInvoice trusts the client `amount`
`amount` comes from the client. It's staff-only, so a staff member can only
misprice their own sale (low blast radius) — but prices should be authoritative.
Recommend a **server-side price table** keyed by `packageSize` (e.g. 8→Rp X,
16→Rp Y); derive `amount` in the function and ignore the client value.

### R-3 🟡 No student self-service purchase
Students pay **staff-created** invoices (`student_payments_tab` opens
`invoice.redirectUrl`); there's no student "Buy more sessions" that calls
`createInvoice` (it's staff-only). That's a safe default. If you want
self-service, add a separate callable that derives `studentId` from
`request.auth.uid` and `amount` from the server price table (R-2) — never from
client input.

### R-4 🟡 Verify build + deploy prerequisites
- `flutter analyze` (new deps) and a quick run of the register-parent, invoice,
  and calendar flows.
- Deploy: `firebase functions:secrets:set MIDTRANS_SERVER_KEY`, then
  `firebase deploy --only firestore:rules,firestore:indexes,functions` (Blaze),
  and register the `midtransNotification` URL + a Midtrans **sandbox** Client Key
  before testing end to end.

## Acceptance for R-1
- A parent account created via the normal flow can only link to a child whose
  code they entered; attempting to write `studentIds` directly (create or update)
  is denied by rules.
- Rules test: a signed-in user cannot self-register as a parent of a student
  whose code they don't have.
