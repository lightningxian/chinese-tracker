# Go-live checklist — Easy Study (chinese-tracker)

End-to-end launch runbook: verify → deploy → wire Midtrans (incl. BNPL) →
smoke-test every role → back up to your UGREEN NAS → switch to production.
Work top to bottom; don't move to production keys until the sandbox payment test
passes. **[you]** = do it yourself · **[dev]** = you or Cursor on the Mac.

Firebase project: `chinese-tracker`. Roles: admin · teacher · student · parent.

---

## 0. Pre-flight (local) — [dev]
- [ ] `flutter pub get`
- [ ] `flutter analyze` is clean (no errors)
- [ ] `flutter test` passes (add tests later — see §8)
- [ ] `cd functions && npm install && node --check index.js && cd ..`
- [ ] `firebase --version` and `firebase login`; `firebase use chinese-tracker`
- [ ] Decide build-time defines you'll pass:
  - `CONTENT_OWNER_ID` — the content-owning teacher's uid (admin views use it;
    teachers/students resolve by their own id automatically).
  - `MIDTRANS_CLIENT_KEY` — Midtrans **Client** key (sandbox first).
  - `ANDROID_APK_URL` — only for the mobile build (see the mobile prompt).

## 1. Billing / Blaze — [you]
- [ ] Upgrade `chinese-tracker` to the **Blaze** plan (required for Cloud
  Functions + the outbound Midtrans call + BNPL).
- [ ] Set a **budget alert** (e.g. cap alert at a small monthly figure) so there
  are no surprises. At your scale the bill is typically near-zero.
- [ ] Confirm these APIs are enabled (usually automatic with Blaze): Cloud
  Functions, Cloud Build, Artifact Registry, Secret Manager, Cloud Scheduler
  (for `cleanupExpiredLinkCodes`).

## 2. Secrets & keys — [you]/[dev]
- [ ] Create a **Midtrans sandbox** account; copy the **Server Key** and
  **Client Key** (Sandbox).
- [ ] `firebase functions:secrets:set MIDTRANS_SERVER_KEY` → paste the **sandbox
  Server Key**. (Never commit it; it lives only in Secret Manager.)
- [ ] Keep the **Client Key** for the app build define (`MIDTRANS_CLIENT_KEY`).

## 3. Deploy backend — [dev]
- [ ] `firebase deploy --only firestore:rules`
- [ ] `firebase deploy --only firestore:indexes` (wait for indexes to finish
  **building** — lesson/material lists stay empty until they're ready)
- [ ] `firebase deploy --only storage`
- [ ] `firebase deploy --only functions`
- [ ] Confirm all 8 functions deployed:
  `resolveLinkCode`, `onUserCreated`, `onExerciseResultCreated`,
  `cleanupExpiredLinkCodes`, `resolveChildCode`, `linkChild`, `createInvoice`,
  `midtransNotification`.
- [ ] Copy the **`midtransNotification`** trigger URL from the deploy output
  (needed in §4).

## 4. Midtrans configuration — [you]
- [ ] In the Midtrans dashboard → **Settings → Configuration**, set the
  **Payment Notification URL** to the `midtransNotification` function URL.
- [ ] Enable the channels you want under **Snap Preferences / Payment channels**:
  cards, bank VA, e-wallets, QRIS, and — for your installment need ("meaning
  one") — **Kredivo** and **Akulaku PayLater** (BNPL: the customer splits, you're
  paid in full). No app code needed; Snap shows whatever you enable.
- [ ] Note: cards + BNPL may require **business verification** before they go
  live; VA/QRIS usually work in sandbox immediately.

## 5. Hosting & seed — [dev]
- [ ] Build + deploy web:
  `flutter build web --release --dart-define=CONTENT_OWNER_ID=<owner uid> --dart-define=MIDTRANS_CLIENT_KEY=<sandbox client key>`
  then `firebase deploy --only hosting`.
- [ ] Create the first **admin** account; then a **teacher**; a couple of
  **students**; and one **parent** (via child code).
- [ ] Seed lessons/exercises under the teacher: `bash scripts/seed_test_accounts.sh`
  and `python3 scripts/seed_report_demo_data.py` (or create real content).
- [ ] In **admin → Centre settings**: confirm `enablePayments` is ON and set the
  other toggles as desired.

## 6. Smoke test every role (sandbox) — [you]
- [ ] **Admin**: dashboard, users, create an invoice (→ pending), settings
  toggles take effect, audit logs list, materials upload+publish, financial
  summary shows the invoice.
- [ ] **Teacher**: dashboard counts, students, create+score a **grade**,
  question bank + "from bank" in exercise authoring, sessions on the **calendar**
  (mode/room), write+publish an **evaluation** (only when eval forms are open),
  attendance.
- [ ] **Student**: lessons/exercises (submit → score; grading notification
  appears via trigger), quota, **grades transcript**, calendar.
- [ ] **Parent**: register with the child code (`linkChild`), see the child's
  progress/grades/attendance/invoices **read-only**, and confirm you **cannot**
  see a non-linked student.
- [ ] **Payment end-to-end (the important one)**: student opens a pending invoice
  → pay in **sandbox** with (a) a test card and (b) one BNPL method → confirm the
  `midtransNotification` webhook flips the invoice to **paid**, credits a
  `student_class_terms` package, sends student+teacher notifications, and writes
  an `invoice.paid` **audit log**. Pay the same invoice twice / replay the
  notification → it must **not** double-credit (transaction guard).

## 7. Back up to your UGREEN NAS — [you]
Goal: you own a recovery copy of all data on hardware you control, without the
NAS being in the live path.
- [ ] Enable a scheduled **Firestore export** to a Cloud Storage bucket
  (e.g. `gs://chinese-tracker-backups`): use **Cloud Scheduler + the Firestore
  export API** (daily). Storage files already live in a GCS bucket.
- [ ] Create a **least-privilege GCP service account** with read-only access to
  the backup bucket(s); download its JSON key.
- [ ] On the NAS (UGOS): if it supports **Docker**, run **`rclone`** in a
  container with a Google Cloud Storage remote (the service-account key), and a
  daily `rclone sync gcs:chinese-tracker-backups /volume/backups/easystudy`
  cron. If no Docker, use UGOS **cloud sync** if it supports GCS/S3.
- [ ] Verify one sync actually lands files on the NAS, and write down the
  **restore** steps (how to re-import a Firestore export) so a recovery is known,
  not hoped for.

## 8. Safety net (recommended before real users) — [dev]
- [ ] Add **Firestore rules tests** (`@firebase/rules-unit-testing`): student
  can't read others' data / can't self-link as a parent / can't mark invoices
  paid; parent reads only linked child.
- [ ] Add a **webhook unit test** (status mapping + no double-credit).
- [ ] Wire a **GitHub Action**: `flutter analyze` + `flutter test` + `node --check`.
- [ ] Confirm Crashlytics / the global `FlutterError` logging is capturing errors.

## 9. Go production — [you]/[dev]
- [ ] Get **Midtrans production** Server + Client keys (after verification).
- [ ] `firebase functions:secrets:set MIDTRANS_SERVER_KEY` → **production** key;
  redeploy functions. Rebuild the app with the **production** `MIDTRANS_CLIENT_KEY`.
- [ ] Register the **production** Payment Notification URL in Midtrans.
- [ ] Point **easystudy.id** at Firebase Hosting (custom domain + SSL).
- [ ] Do one **small real transaction** end-to-end, then you're live.

---

## Small follow-ups (not blockers)
- Enforce the stored settings that are currently display-only:
  `requireEmailVerification`, `autoGenerateStaffPasswords`.
- Published **materials** are readable by any signed-in user regardless of owner
  (fine for one centre; scope by owner if you add other teachers).
- Two content-owner helpers (`contentTeacherId` / `contentOwnerFor`) coexist —
  consolidate to one to avoid future drift.

## Deferred features (revisit at scale)
Granular admin permissions (multi-admin), separate Owner role, teacher
performance ratings, student self-service purchase. Not needed for one centre.
