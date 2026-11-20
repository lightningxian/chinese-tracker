#!/usr/bin/env node
// Build 8 (docs/PLAN.md §4, Must 4): the trial seed's `live` mode —
// accounts and structures only, never papers, results or bookings.
//
//   node scripts/seed_trial_live.mjs --credentials <service-account.json> [--dry-run]
//   node scripts/seed_trial_live.mjs --emulator            (test it locally)
//
// Inputs (git-ignored, never committed):
//   scripts/trial/passwords.local.json   {"admin": "...", "teacher1": "...", "student01": "..."}
//   scripts/trial/respondents.local.csv  role,key,email,nameLatin,nameChinese,level
//     (optional; without it the names are placeholders "Siswa Uji 01" etc.)
//
// Fixed uids (trial_admin, trial_teacher_1..4, trial_student_01..30) and
// fixed doc ids make a second run change nothing. The price list is written
// only when settings/pricing does not exist yet (the owner's real prices
// stay). Schedules are written unconfirmed; the Sunday job generates their
// sessions. Vouchers carry `trial: true` and no invoice.
import {createRequire} from "node:module";
import {existsSync, readFileSync} from "node:fs";
import {dirname, join} from "node:path";
import {fileURLToPath} from "node:url";

const HERE = dirname(fileURLToPath(import.meta.url));
const require = createRequire(join(HERE, "..", "functions", "package.json"));
const args = process.argv.slice(2);
const flag = (name) => args.includes(name);
const opt = (name) => {
  const i = args.indexOf(name);
  return i >= 0 ? args[i + 1] : null;
};
const DRY = flag("--dry-run");
const EMULATOR = flag("--emulator");
const PROJECT = "chinese-tracker";

if (EMULATOR) {
  process.env.FIRESTORE_EMULATOR_HOST ||= "127.0.0.1:8080";
  process.env.FIREBASE_AUTH_EMULATOR_HOST ||= "127.0.0.1:9099";
} else {
  const cred = opt("--credentials");
  if (!cred || !existsSync(cred)) {
    console.error("Live mode needs --credentials <service-account.json> (download it from the " +
      "Firebase console, keep it outside the repo).");
    process.exit(2);
  }
  process.env.GOOGLE_APPLICATION_CREDENTIALS = cred;
}

const {initializeApp, applicationDefault} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
initializeApp(EMULATOR ? {projectId: PROJECT} : {credential: applicationDefault(), projectId: PROJECT});
const auth = getAuth();
const db = getFirestore();

// ------------------------------------------------------------------ inputs
const passwordsPath = join(HERE, "trial", "passwords.local.json");
const respondentsPath = join(HERE, "trial", "respondents.local.csv");
const passwords = existsSync(passwordsPath) ? JSON.parse(readFileSync(passwordsPath, "utf8")) : {};
if (!EMULATOR && !DRY && !Object.keys(passwords).length) {
  console.error(`Missing ${passwordsPath}: one password per key (admin, teacher1..4, ` +
    "student01..30). It is git-ignored; never commit it.");
  process.exit(2);
}
const given = {};
if (existsSync(respondentsPath)) {
  const lines = readFileSync(respondentsPath, "utf8").split(/\r?\n/).filter((l) => l.trim());
  for (const line of lines.slice(1)) {
    const [role, key, email, nameLatin, nameChinese, level] = line.split(",").map((x) => x.trim());
    given[key] = {role, email, nameLatin, nameChinese, level};
  }
}

// ------------------------------------------------------------------ plan
// 12 beginner (HSK 1-2), 10 intermediate (HSK 3-4), 8 advanced (HSK 5-6).
const LEVELS = [...Array(6).fill("HSK 1"), ...Array(6).fill("HSK 2"),
  ...Array(5).fill("HSK 3"), ...Array(5).fill("HSK 4"),
  ...Array(4).fill("HSK 5"), ...Array(4).fill("HSK 6")];
const TEACHER_LEVELS = [["HSK 1", "HSK 2"], ["HSK 1", "HSK 2", "HSK 3"], ["HSK 3", "HSK 4"],
  ["HSK 5", "HSK 6"]];
const AVAIL = Object.fromEntries([1, 2, 3, 5].map((d) => [String(d),
  [{startMinutes: 840, endMinutes: 1140}]]));
AVAIL["6"] = [{startMinutes: 570, endMinutes: 900}];
const DOMAIN = "trial.easystudy.local";

const people = [];
people.push({key: "admin", uid: "trial_admin", role: "admin",
  email: `admin@${DOMAIN}`, nameLatin: "Admin Uji", nameChinese: ""});
for (let t = 1; t <= 4; t += 1) {
  people.push({key: `teacher${t}`, uid: `trial_teacher_${t}`, role: "teacher",
    email: `teacher${t}@${DOMAIN}`, nameLatin: `Guru Uji ${t}`, nameChinese: "",
    levels: TEACHER_LEVELS[t - 1]});
}
for (let s = 1; s <= 30; s += 1) {
  const n = String(s).padStart(2, "0");
  people.push({key: `student${n}`, uid: `trial_student_${n}`, role: "student",
    email: `student${n}@${DOMAIN}`, nameLatin: `Siswa Uji ${n}`, nameChinese: "",
    level: LEVELS[s - 1]});
}
for (const p of people) Object.assign(p, Object.fromEntries(
    Object.entries(given[p.key] || {}).filter(([k, v]) => v && k !== "role")));

// Students go round-robin to the teachers who teach their level.
const teacherFor = (level, n) => {
  const can = TEACHER_LEVELS.map((ls, i) => (ls.includes(level) ? i : -1)).filter((i) => i >= 0);
  return `trial_teacher_${(can.length ? can[n % can.length] : 0) + 1}`;
};

// The flyer: Monday 16:00; Tue, Wed, Fri 15:00 and 16:30; Sat 10:00, 11:30, 13:00.
const slots = [[1, 960, "Main"]];
for (const d of [2, 3, 5]) slots.push([d, 900, "Main"], [d, 990, "Sub Room"]);
slots.push([6, 600, "Main"], [6, 690, "Sub Room"], [6, 780, "Main"]);

// ------------------------------------------------------------------ write
const log = [];
const write = async (path, data, {onlyIfMissing = false} = {}) => {
  const ref = db.doc(path);
  if (onlyIfMissing && (await ref.get()).exists) {
    log.push(`keep ${path} (exists)`);
    return;
  }
  log.push(`set ${path}`);
  if (!DRY) await ref.set(data, {merge: true});
};

async function account(p) {
  const password = passwords[p.key] || (EMULATOR ? "emulator-only-7" : null);
  if (!password && !DRY) throw new Error(`no password for ${p.key} in passwords.local.json`);
  let exists = true;
  try {
    await auth.getUser(p.uid);
  } catch {
    exists = false;
  }
  log.push(`${exists ? "keep" : "create"} auth ${p.uid} <${p.email}>`);
  if (!exists && !DRY) {
    await auth.createUser({uid: p.uid, email: p.email, password, displayName: p.nameLatin});
  }
}

const today = new Date(Date.now() + 7 * 3600000).toISOString().slice(0, 10);
const addDays = (d, n) => new Date(Date.parse(`${d}T00:00:00Z`) + n * 86400000)
    .toISOString().slice(0, 10);

let nStudent = 0;
for (const p of people) {
  await account(p);
  const base = {email: p.email, name: p.nameLatin, nameIndonesian: p.nameLatin,
    nameChinese: p.nameChinese || "", role: p.role, active: true, trial: true,
    createdAt: FieldValue.serverTimestamp()};
  if (p.role === "teacher") Object.assign(base, {levels: p.levels, availability: AVAIL});
  if (p.role === "student") {
    Object.assign(base, {level: p.level, teacherId: teacherFor(p.level, nStudent++), termSize: 8,
      status: "active"});
  }
  await write(`users/${p.uid}`, base);
}
await write("settings/rooms", {names: ["Main", "Sub Room"]});
await write("settings/pricing", {items: [
  {id: "registration", name: "Registration (one-time)", nameChinese: "报名费", price: 100000,
    kind: "registration", sessions: 0, validDays: 0, active: true},
  {id: "package8", name: "8 class sessions", nameChinese: "8次课程", price: 2450000,
    kind: "sessions", sessions: 8, validDays: 60, active: true},
  {id: "package16", name: "16 class sessions", nameChinese: "16次课程", price: 3950000,
    kind: "sessions", sessions: 16, validDays: 60, active: true},
]}, {onlyIfMissing: true});
const scheduleIds = [];
for (let i = 0; i < slots.length; i += 1) {
  const [weekday, start, room] = slots[i];
  const teacherId = `trial_teacher_${(i % 4) + 1}`;
  const id = `trial_sch_${String(i + 1).padStart(2, "0")}`;
  scheduleIds.push(id);
  await write(`schedules/${id}`, {className: `Kelas Uji ${"ABCDEFGHIJK"[i]}`, weekday,
    startMinutes: start, endMinutes: start + 90, room, teacherId,
    teacherName: people.find((x) => x.uid === teacherId).nameLatin, capacity: 8, level: "",
    validFrom: today, validTo: addDays(today, 120), active: true, status: "unconfirmed",
    trial: true, createdBy: "trial_admin", updatedAt: FieldValue.serverTimestamp()});
}
let k = 0;
for (const p of people.filter((x) => x.role === "student")) {
  const classDay = scheduleIds[k % scheduleIds.length];
  k += 1;
  await write(`student_class_terms/trial_term_${p.uid}`, {studentId: p.uid, packageSize: 8,
    sessionsRemaining: 8, sessionsUsed: 0, sessionsBooked: 0, status: "active",
    startDate: today, deadlineDate: addDays(today, 60), nameChinese: "8次课程",
    validDays: 60, classDay, source: "trial", trial: true, createdBy: "trial_admin"},
  {onlyIfMissing: true});
}

console.log(log.join("\n"));
console.log(`${DRY ? "DRY RUN — nothing written. " : ""}${people.length} accounts ` +
  `(${EMULATOR ? "emulator" : "LIVE"}), ${scheduleIds.length} schedules, 30 vouchers.`);
process.exit(0);
