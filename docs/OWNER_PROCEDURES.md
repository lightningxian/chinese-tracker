# Owner procedures

Step-by-step runbooks for the things only the owner can do (console logins,
money, the live project). Written 2026-11-13. Claude keeps them current.

---

## A. Midtrans sandbox payment, end to end

Goal: prove that an online payment flips an invoice to **paid**, credits the
student's sessions, notifies, and is not credited twice. Do not switch
Midtrans to production keys before this passes.

**Before you start**

1. Open the Midtrans **sandbox** dashboard (dashboard.sandbox.midtrans.com)
   → **Settings → Configuration**.
2. **Payment Notification URL** must be exactly:
   `https://us-central1-chinese-tracker.cloudfunctions.net/midtransNotification`
   (the `…run.app` address printed by `firebase deploy` works too; either one).
3. Optional: **Finish Redirect URL** = `https://chinese-tracker.web.app/student/payments`
   so the student lands back in the app after paying.
4. In a terminal, start watching the function logs and leave it open:

```bash
firebase functions:log --only createInvoice,midtransNotification --project chinese-tracker
```

   (Or tell Claude "watch the payment logs" and paste the order id afterwards.)

**The test**

5. Sign in as **admin** on https://chinese-tracker.web.app → **Payments** →
   **Invoices** → **Create invoice**: student = `student1@test.chinesetracker`,
   item = **8 class sessions**, a due date next week → **Create**.
   The invoice shows **Pending**.
6. Open a **private window**, sign in as `student1@test.chinesetracker`
   (password in `docs/CLAUDE_FULL_HANDOFF.md`) → **Payments** → the new
   invoice → **Pay now**. The Midtrans Snap page opens.
7. Choose **Credit/Debit Card** and use the sandbox test card:
   - number `4811 1111 1111 1114`
   - expiry any future month/year, for example `01/30`
   - CVV `123`
   - on the 3-D Secure page, OTP `112233`
8. Wait ~10 seconds, then check, in this order:
   - student **Payments**: the invoice is **Paid** and a term/voucher with
     **8 sessions** appears (refresh if needed);
   - admin **Payments**: the same invoice is **Paid**, paid by *Midtrans*;
   - admin bell: a payment notification; **Audit logs**: `invoice.paid`;
   - the terminal: `midtransNotification` logged the order (`ES-INV-…`) with
     `settlement` or `capture`.
9. **No double credit**: in the Midtrans dashboard → **Transactions** → open
   the same order → **Resend notification** (or **Retry HTTP notification**).
   The invoice must stay paid with the same 8 sessions. The log shows the
   repeat was ignored.
10. Optional failure path: create a second invoice, on the Snap page choose
    **Bank transfer (BCA Virtual Account)** and close the page. The invoice
    stays **Pending**; Midtrans expires it after 24 h.

**Send Claude**: the order id(s) and what you saw in step 8/9. Claude checks the
log lines and marks the Midtrans item done. After that, production keys:
`firebase functions:secrets:set MIDTRANS_SERVER_KEY` with the production key,
`MIDTRANS_CLIENT_KEY` in the build define, and the Snap URL in
`functions/index.js` (`MIDTRANS_SNAP_URL`, drop `sandbox.`).

---

## B. Nightly backup

The Cloud Function export (`scheduledFirestoreExport`) keeps failing with
`PERMISSION_DENIED`. Two ways out.

### Option 1 (recommended): Firestore's own scheduled backups

One command, no bucket, no IAM, costs cents per month for this database:

```bash
firebase firestore:backups:schedules:create --database '(default)' --recurrence DAILY --retention 7d --project chinese-tracker
```

Check it exists:

```bash
firebase firestore:backups:schedules:list --database '(default)' --project chinese-tracker
```

From the next day, backups are listed with:

```bash
firebase firestore:backups:list --project chinese-tracker
```

To restore (only if ever needed; it creates a **new** database next to the live
one, it never overwrites):

```bash
firebase firestore:databases:restore --backup <backup name from the list> --database restored-copy --project chinese-tracker
```

Then tell Claude "backups are on": Claude removes the old export function from
the code and the next `firebase deploy --only functions` asks to delete
`scheduledFirestoreExport` (answer **yes**).

### Option 2: keep the export function and fix IAM in the Google Cloud console

1. https://console.cloud.google.com → project **chinese-tracker** →
   **IAM & Admin → IAM** → find
   `345172802163-compute@developer.gserviceaccount.com` → pencil icon →
   **Add another role** → **Cloud Datastore Import Export Admin** → **Save**.
2. **Cloud Storage → Buckets**: if `chinese-tracker-backups` does not exist,
   **Create** it (name `chinese-tracker-backups`, region `asia-southeast2`,
   everything else default).
3. Open the bucket → **Permissions** → **Grant access** → principal
   `345172802163-compute@developer.gserviceaccount.com` → role
   **Storage Object Admin** → **Save**.
4. Force a run instead of waiting for 02:00: **Cloud Scheduler** → the job
   named like `firebase-schedule-scheduledFirestoreExport-us-central1` →
   **Force run**.
5. Check: `firebase functions:log --only scheduledFirestoreExport --project chinese-tracker`
   shows no error, and the bucket has a folder `firestore/<today>`.
