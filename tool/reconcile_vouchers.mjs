#!/usr/bin/env node
// Build 7 (VC-05): runs the admin-only `reconcileVouchers` function and
// prints every voucher whose counters do not match the voucher ledger and
// the open bookings.
//
// Emulator (default): signs in as the seeded admin with the emulator-only
// password.
//   node tool/reconcile_vouchers.mjs
// Live: pass a signed-in admin's ID token (never a password); copy it from
// the browser console of the live app while signed in as an admin:
//   await firebase.auth().currentUser.getIdToken()   (or the app's debug tools)
//   RECONCILE_ID_TOKEN=<token> node tool/reconcile_vouchers.mjs --live
//
// Exit code 0 = everything matches, 1 = mismatches, 2 = error.

const PROJECT = "chinese-tracker";
const live = process.argv.includes("--live");
const base = live ?
  `https://us-central1-${PROJECT}.cloudfunctions.net` :
  `http://127.0.0.1:5001/${PROJECT}/us-central1`;

async function emulatorToken() {
  const r = await fetch("http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/" +
    "accounts:signInWithPassword?key=fake", {
    method: "POST",
    headers: {"Content-Type": "application/json"},
    body: JSON.stringify({email: "admin@test.chinesetracker", password: "emulator-only-7",
      returnSecureToken: true}),
  });
  const j = await r.json();
  if (!j.idToken) throw new Error(`emulator sign-in failed: ${JSON.stringify(j).slice(0, 200)}`);
  return j.idToken;
}

try {
  const token = live ? process.env.RECONCILE_ID_TOKEN : await emulatorToken();
  if (!token) throw new Error("Set RECONCILE_ID_TOKEN to a signed-in admin's ID token.");
  const r = await fetch(`${base}/reconcileVouchers`, {
    method: "POST",
    headers: {"Content-Type": "application/json", Authorization: `Bearer ${token}`},
    body: JSON.stringify({data: {}}),
  });
  const j = await r.json();
  if (j.error) throw new Error(`${j.error.status}: ${j.error.message}`);
  const {checked, mismatches} = j.result;
  console.log(`${live ? "LIVE" : "emulator"}: ${checked} vouchers checked, ` +
    `${mismatches.length} mismatches`);
  for (const m of mismatches) {
    console.log(`- ${m.termId} (student ${m.studentId}): ${m.problems.join("; ")}`);
  }
  process.exit(mismatches.length ? 1 : 0);
} catch (e) {
  console.error(e.message);
  process.exit(2);
}
