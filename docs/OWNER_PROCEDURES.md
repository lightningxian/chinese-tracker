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
`scheduledFirestoreExport` is gone from the code and was deleted on live the
same day.

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

## C. Reset the live test passwords (security, open since 2026-11-17)

**Why.** The GitHub repository is public, and the password of the five live
test accounts (`admin@`, `teacher@`, `student1@`, `student2@`,
`student3@test.chinesetracker`) is written in 8 files of it (docs, app code,
seed scripts). Git keeps every old version, so deleting it from the files
is not enough: anyone can still read it and sign in to the live site as
**admin**. Only a new password closes this. (Checked 2026-11-25: the live
web app itself does not contain the password; the repository does.)

**1. Give each account a new password (about 10 minutes, in the app).**
For each of the five accounts:
1. Open https://chinese-tracker.web.app and sign in with the account and
   its current password.
2. Open the **Profile** tab and press **Change password**.
3. Type the current password, then the new one twice (at least 8
   characters), and press **Change password**. You should see
   "Password changed."
4. Sign out, and do the next account.

Keep the new password in your own password manager. Do not type it in a
Claude chat and do not write it into any file in the repository.

If an account is not needed any more: Firebase Console → **Authentication**
→ **Users** → the account's row → ⋮ → **Disable account**. (The console
cannot set a password itself, and its "Reset password" sends an e-mail to
the `test.chinesetracker` address, which does not exist.)

**Check:** sign in once with the **old** password on any of the five
accounts. The app must say the password is wrong.

**2. Decide: private or public repository.** Once step 1 is done, the old
password in the history is worthless, so keeping the repository public is
safe again. Reasons to make it private anyway: the code of a thesis that
is not yet defended. What changes if private: the GitHub checks run on
your free monthly minutes (GitHub → Settings → Billing shows the use);
anyone who should read it (supervisor, examiners) must be added as a
collaborator. Hosting, the APK and releases do not change. To switch:
GitHub → the repository → **Settings** → **General** → bottom of the page,
**Danger Zone** → **Change visibility** → **Private**.

**3. Tell the BUILD chat "test passwords reset".** It then removes the old
password from the 8 files: the docs (`CLAUDE_FULL_HANDOFF.md`,
`FIREBASE_BACKEND.md`, `SESSION_LOG.md`, `PLAN.md`), the app code
(`lib/core/constants/test_accounts.dart` gets no live default,
`test_login_screen.dart`) and the seed scripts (`seed_test_accounts.sh`,
`seed_report_demo_data.py` read the password from an environment
variable). Nothing on the live site changes. The new password never goes
into the repository.

## Storage rules that read Firestore (one-time grant, 2026-11-24)

The Storage rules check "is this person an admin / staff?" by reading
`users/{uid}` in Firestore (`firestore.get`). On the live project Google
allows this only after the Storage service agent has the role **Firebase
Rules Firestore Service Agent**. Without it, every staff upload is refused
with `firebase_storage/unauthorized` (scan drafts, scanned pictures,
question pictures and recordings, materials). The emulator does not need it.

Grant it once, either way:

1. On the PC, in a terminal: `firebase deploy --only storage --project
   chinese-tracker` and answer **Y** when it asks to grant the role.
2. Or in Google Cloud console → IAM → **Grant access**: principal
   `service-345172802163@gcp-sa-firebasestorage.iam.gserviceaccount.com`,
   role **Firebase Rules Firestore Service Agent**.

Automated deploys (`--non-interactive`) skip the question, so the grant has
to be done by hand once.

**On the PC, if the terminal says `firebase` is "not recognized"** (the
Firebase CLI is installed inside the Claude app's own folder, which a normal
terminal cannot see), run it by its full path. This worked on 2026-11-26:

```powershell
& "C:\Program Files\nodejs\node.exe" "$env:LOCALAPPDATA\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Roaming\npm\node_modules\firebase-tools\lib\bin\firebase.js" deploy --only storage --project chinese-tracker
```

Swap `storage` for whatever needs deploying (e.g.
`"storage,functions:markInvoicePaid"`).

## Storage bucket CORS (one-time, 2026-11-24)

The web app downloads some files from Storage itself (reopening a scan
draft's PDF, **Write from the recording**). A browser only allows that when
the bucket sends `Access-Control-Allow-Origin`, which needs a CORS setting
on the bucket (the file is `storage.cors.json` in the repo). Without it the
app shows `ClientException: Failed to fetch`.

Set it once in Google Cloud **Cloud Shell** (console.cloud.google.com,
project chinese-tracker, the `>_` button at the top right):

```
echo '[{"origin":["https://chinese-tracker.web.app","https://chinese-tracker.firebaseapp.com","http://localhost:5181"],"method":["GET","HEAD"],"responseHeader":["Content-Type","Content-Length","Content-Range","Range"],"maxAgeSeconds":3600}]' > cors.json
gcloud storage buckets update gs://chinese-tracker.firebasestorage.app --cors-file=cors.json
```

Check: `gcloud storage buckets describe gs://chinese-tracker.firebasestorage.app --format="default(cors_config)"`.

