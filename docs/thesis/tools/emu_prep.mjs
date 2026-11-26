// Emulator-only helpers shared by the Bab VI screenshot tool and the demo
// video: a class of the teacher account that is running right now, with
// booked students, so the session page shows attendance on any day of the
// week (the seed's timetable has no class on Thursday or Sunday).
// Everything goes through the app's own callable functions on the local
// emulators; nothing here can reach the live project.
const FN = "http://127.0.0.1:5001/chinese-tracker/us-central1";
const AUTH = "http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1";
const FS = "http://127.0.0.1:8080/v1/projects/chinese-tracker/databases/(default)/documents";
export const D = "@test.chinesetracker";
export const DEMO_CLASS = "Kelas Demo";

export async function idTokenOf(email) {
  const r = await fetch(`${AUTH}/accounts:signInWithPassword?key=fake`, {method: "POST",
    headers: {"Content-Type": "application/json"},
    body: JSON.stringify({email, password: "emulator-only-7", returnSecureToken: true})});
  const j = await r.json();
  if (!j.idToken) throw new Error(`emulator sign-in failed for ${email}`);
  return j.idToken;
}

/** Calls a callable function on the emulator as [email]. */
export async function call(email, name, data) {
  const r = await fetch(`${FN}/${name}`, {method: "POST",
    headers: {"Content-Type": "application/json", Authorization: `Bearer ${await idTokenOf(email)}`},
    body: JSON.stringify({data})});
  const j = await r.json();
  if (j.error) throw new Error(`${name}: ${j.error.message || JSON.stringify(j.error)}`);
  return j.result;
}

/** Reads a collection from the Firestore emulator ("owner" passes the rules locally). */
export async function query(collectionId, field, value) {
  const where = field ? {fieldFilter: {field: {fieldPath: field}, op: "EQUAL", value: {stringValue: value}}} : undefined;
  const r = await fetch(`${FS}:runQuery`, {method: "POST",
    headers: {"Content-Type": "application/json", Authorization: "Bearer owner"},
    body: JSON.stringify({structuredQuery: {from: [{collectionId}], limit: 500, ...(where ? {where} : {})}})});
  return (await r.json()).filter((x) => x.document).map((x) => ({
    id: x.document.name.split("/").pop(),
    ...Object.fromEntries(Object.entries(x.document.fields || {}).map(([k, v]) => [k, Object.values(v)[0]])),
  }));
}

const jakarta = () => new Date(Date.now() + 7 * 3600 * 1000);

/**
 * Makes sure the teacher account has a class that started a little while ago
 * and is still open, with [want] students booked. A demo class of today that
 * is not closed yet is used again; else a new one is made. Students who
 * cannot be booked (no voucher, another class at that time) are passed over.
 * Returns {sessionId, scheduleId, booked, teacherUid}.
 */
export async function ensureRunningClass({teacher = `teacher${D}`, want = 4, minutesAgo = 20} = {}) {
  const admin = `admin${D}`;
  const users = await query("users");
  const teacherUid = (users.find((u) => u.email === teacher) || {}).id;
  if (!teacherUid) throw new Error("Seed the emulator first (seed_trial.py).");
  const now = jakarta();
  const today = now.toISOString().slice(0, 10);
  const weekday = now.getUTCDay() === 0 ? 7 : now.getUTCDay();          // Monday = 1 … Sunday = 7
  const minutes = now.getUTCHours() * 60 + now.getUTCMinutes();
  const open = (await query("class_sessions", "teacherId", teacherUid))
      .filter((x) => x.sessionTitle === DEMO_CLASS && x.sessionDate === today &&
        !["done", "cancelled"].includes(x.status) && x.isConcluded !== true &&
        Number(x.startMinutes) <= minutes && Number(x.endMinutes) > minutes + 10)
      .sort((a, b) => Number(b.bookedCount || 0) - Number(a.bookedCount || 0));
  let sessionId = open.length ? open[0].id : null;
  let scheduleId = open.length ? open[0].scheduleId : null;
  if (!sessionId) {
    // With the readiness switch on, a class must sit inside the teacher's
    // availability: open the whole of today for this teacher (seed data only).
    await fetch(`${FS}/users/${teacherUid}?updateMask.fieldPaths=${encodeURIComponent("availability.`" + weekday + "`")}`, {
      method: "PATCH", headers: {"Content-Type": "application/json", Authorization: "Bearer owner"},
      body: JSON.stringify({fields: {availability: {mapValue: {fields: {[String(weekday)]: {arrayValue: {values: [
        {mapValue: {fields: {startMinutes: {integerValue: "0"}, endMinutes: {integerValue: "1439"}}}}]}}}}}}})});
    const start = Math.max(0, Math.floor((minutes - minutesAgo) / 5) * 5);
    const base = {className: DEMO_CLASS, weekday, startMinutes: start, endMinutes: Math.min(start + 90, 1439),
      teacherId: teacherUid, capacity: 8, level: "", validFrom: today, validTo: today, active: true};
    let saved = null, lastError = null;
    for (const room of ["Sub Room", "Main"]) {
      try {
        saved = await call(admin, "saveSchedule", {...base, room});
        break;
      } catch (err) {
        lastError = err;
      }
    }
    if (!saved) throw new Error(`could not make the demo class: ${lastError.message}`);
    scheduleId = saved.scheduleId;
    sessionId = `${scheduleId}_${today.replace(/-/g, "")}`;
  }
  const seats = (await query("attendance", "sessionId", sessionId)).filter((a) => a.booked === true);
  const booked = seats.map((a) => (users.find((u) => u.id === a.studentId) || {}).email).filter(Boolean);
  for (let n = 1; n <= 30 && booked.length < want; n++) {
    const email = `student${n}${D}`;
    if (booked.includes(email)) continue;
    try {
      await call(email, "bookSession", {sessionId});
      booked.push(email);
    } catch {
      // this student cannot take the class; the next one may
    }
  }
  if (!booked.length) throw new Error("no student could be booked into the demo class");
  return {sessionId, scheduleId, booked, teacherUid};
}
