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

## B. Nightly backup — done 2026-11-13

Firestore's own scheduled backup is on: daily, 7-day retention (schedule
`c3d18000-952e-4759-8aa6-aaf1df6fa48c`, created with
`firebase firestore:backups:schedules:create`). The old export function
`scheduledFirestoreExport` is gone from the code; the next
`firebase deploy --only functions` asks to delete it on live (answer **yes**).

Check the schedule:

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

Storage files (photos, worksheets, recordings) are not in this backup; they
live in the Storage bucket, which Google keeps. The NAS copy in
`docs/NAS_BACKUP_SETUP.md` is optional and, for Firestore, would now need a
manual `gcloud firestore export`.
