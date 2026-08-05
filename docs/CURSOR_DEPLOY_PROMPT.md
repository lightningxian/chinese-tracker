# Cursor prompt — deploy Easy Study (go-live §0–§5)

Copy the block below into Cursor and run it on the Mac with the Firebase CLI.
This is the deploy half of `docs/GO_LIVE_CHECKLIST.md`. Some steps need the
**user** (billing, secret values, Midtrans dashboard) — pause and ask when you
hit those; don't invent keys.

---

## Preconditions (confirm, don't guess)
- Firebase project is `chinese-tracker` (`firebase use chinese-tracker`).
- The **user** has upgraded to the **Blaze** plan and set a budget alert. If
  functions deploy fails with a billing error, stop and tell the user to upgrade.
- The **user** has a **Midtrans sandbox** account and will provide the Server Key
  (for the secret) and the Client Key (for the app build). Do not hardcode either.

## 0. Verify
```bash
flutter pub get
flutter analyze          # must be clean
cd functions && npm install && node --check index.js && cd ..
```
Fix any analyzer errors before deploying.

## 1. Secret (ask the user to paste the value)
```bash
firebase functions:secrets:set MIDTRANS_SERVER_KEY   # user pastes SANDBOX server key
```

## 2. Deploy rules, indexes, storage
```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
firebase deploy --only storage
```
Wait until the new composite indexes finish **building** in the console (lessons,
materials, invoices, grades) — lists stay empty until then.

## 3. Deploy functions (Blaze required)
```bash
firebase deploy --only functions
```
Confirm all 8 deploy without error and print their names:
`resolveLinkCode, onUserCreated, onExerciseResultCreated, cleanupExpiredLinkCodes,
resolveChildCode, linkChild, createInvoice, midtransNotification`.
**Copy the `midtransNotification` HTTPS URL** from the output and give it to the
user for the Midtrans dashboard (go-live §4).

## 4. Build + deploy web
Ask the user for `CONTENT_OWNER_ID` (the content-owning teacher's uid) and the
Midtrans **sandbox Client Key**, then:
```bash
flutter build web --release \
  --dart-define=CONTENT_OWNER_ID=<owner-uid> \
  --dart-define=MIDTRANS_CLIENT_KEY=<sandbox-client-key>
firebase deploy --only hosting
```

## 5. Seed
```bash
bash scripts/seed_test_accounts.sh
python3 scripts/seed_report_demo_data.py
```
Then report the hosting URL and the `midtransNotification` URL back to the user so
they can finish Midtrans setup and run the role smoke tests (go-live §4, §6).

## Guardrails
- Never print or commit the Midtrans Server Key; it lives only in Secret Manager.
- Don't switch to Midtrans **production** keys yet — sandbox until the payment
  end-to-end test passes (go-live §6).
- If anything fails, stop and report; don't retry blindly against production.
