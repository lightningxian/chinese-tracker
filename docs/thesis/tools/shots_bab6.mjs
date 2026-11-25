#!/usr/bin/env node
// Thesis Bab VI (Implementasi Desain): one screenshot per page, written as
// docs/thesis/word/bab6_lengkap/fig_6_<n>.png (n = shot number). The book
// shows twelve of them: clean_shots.mjs cleans the shots and copies those
// twelve to docs/thesis/word/fig_6_<figure>.png (mapping in bab6_book.mjs).
// Same mechanics as tool/screenshots/run.mjs: headless Chrome through the
// DevTools protocol against the EMULATOR bundle with the trial seed.
//
//   firebase emulators:start --project chinese-tracker
//   python3 -I scripts/seed_trial.py emulator
//   scripts/run_emulator_web.sh                  (serves build/web-emulator on :5181)
//   node docs/thesis/tools/shots_bab6.mjs [--base http://127.0.0.1:5181] [--only 6,12]
//   node docs/thesis/tools/clean_shots.mjs
//
// Every shot: a fresh browser context, Indonesian, light, 1280 x 800. The
// emulator bundle signs in with ?as=<email> (emulator-only password) and
// opens a tab with ?tab=N. Never point it at the live site: ?as= exists
// only in the emulator bundle. Ids that depend on the seed (today's
// session, a booked class) are looked up on the Firestore emulator.
import {spawn} from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import {fileURLToPath} from "node:url";
import {BOOK} from "./bab6_book.mjs";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.join(HERE, "..", "..", "..");
const OUT = path.join(ROOT, "docs", "thesis", "word", "bab6_lengkap");
const args = process.argv.slice(2);
const opt = (n, d) => (args.includes(n) ? args[args.indexOf(n) + 1] : d);
const BASE = opt("--base", "http://127.0.0.1:5181").replace(/\/$/, "");
const ONLY = (opt("--only", "") || "").split(",").filter(Boolean).map(Number);
const FN = "http://127.0.0.1:5001/chinese-tracker/us-central1";
const AUTH = "http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1";
const FS = "http://127.0.0.1:8080/v1/projects/chinese-tracker/databases/(default)/documents";
const D = "@test.chinesetracker";
if (!/^http:\/\/(127\.0\.0\.1|localhost)(:\d+)?$/.test(BASE)) {
  console.error("Emulator bundle on localhost only.");
  process.exit(2);
}

// ---- seed lookups (Firestore emulator REST; "owner" bypasses the rules locally)
async function runQuery(collectionId, where) {
  const body = {structuredQuery: {from: [{collectionId}], limit: 500, ...(where ? {where} : {})}};
  const r = await fetch(`${FS}:runQuery`, {method: "POST",
    headers: {"Content-Type": "application/json", Authorization: "Bearer owner"},
    body: JSON.stringify(body)});
  const rows = await r.json();
  return rows.filter((x) => x.document).map((x) => ({
    id: x.document.name.split("/").pop(),
    ...Object.fromEntries(Object.entries(x.document.fields || {})
        .map(([k, v]) => [k, Object.values(v)[0]])),
  }));
}
const eq = (fieldPath, stringValue) =>
  ({fieldFilter: {field: {fieldPath}, op: "EQUAL", value: {stringValue}}});
const jakartaToday = () => new Date(Date.now() + 7 * 3600 * 1000).toISOString().slice(0, 10);

const users = await runQuery("users");
const uidOf = (email) => (users.find((u) => u.email === email) || {}).id;
const teacherUid = uidOf(`teacher${D}`);
const student1Uid = uidOf(`student1${D}`);
if (!teacherUid || !student1Uid) throw new Error("Seed the emulator first (seed_trial.py).");
const today = jakartaToday();
const teacherSessions = (await runQuery("class_sessions", eq("teacherId", teacherUid)))
    .filter((s) => s.sessionDate >= today && s.status !== "cancelled")
    .sort((a, b) => `${a.sessionDate}${a.startMinutes}`.localeCompare(`${b.sessionDate}${b.startMinutes}`));
// The trial seed also plants a "late check-in" session at 00:00 today; a
// real class of the day is the better picture.
const todaySession = (teacherSessions.find((s) => s.sessionDate === today && Number(s.startMinutes) > 0) ||
  teacherSessions.find((s) => s.sessionDate === today) || teacherSessions[0] || {}).id;
const attendance = (await runQuery("attendance", eq("studentId", student1Uid)))
    .filter((a) => a.sessionDate >= today)
    .sort((a, b) => a.sessionDate.localeCompare(b.sessionDate));
// A booking first; the demo seed also lists the student on older-style sessions.
const bookedSession = ((attendance.find((a) => a.booked === true) || attendance[0]) || {}).sessionId;
console.log(`teacher ${teacherUid} · student1 ${student1Uid} · today ${today} · ` +
  `session ${todaySession || "-"} · booked ${bookedSession || "-"}`);

// [number, account (null = signed out), start path, tab, deep route, caption, click]
// click = [x, y] pressed after the page is up (the teacher shell has no ?tab=, and
// a dialog shows more than an empty list).
// The caption is the Indonesian figure title used in BAB_VI_IMPLEMENTASI.md.
const SHOTS = [
  [1, null, "/", null, null, "Halaman depan"],
  [2, null, "/login", null, null, "Halaman masuk"],
  [3, null, "/register", null, null, "Halaman pendaftaran murid"],
  [4, `pending1${D}`, "/", null, null, "Halaman tunggu persetujuan"],
  [5, null, "/placement", null, null, "Tes penempatan untuk calon murid"],
  [6, `admin${D}`, "/", 0, null, "Dashboard admin"],
  [7, `admin${D}`, "/", 1, null, "Daftar pengguna"],
  [8, `admin${D}`, "/", null, "/admin/users/approval", "Persetujuan pendaftaran"],
  [9, `admin${D}`, "/", null, `/admin/users/${student1Uid}`, "Profil murid di sisi admin"],
  [10, `admin${D}`, "/", 2, null, "Daftar paket latihan"],
  [11, `admin${D}`, "/", null, "/admin/question-bank", "Bank soal"],
  [12, `admin${D}`, "/", null, "/admin/tests/codes", "Daftar kode tes"],
  [13, `admin${D}`, "/", null, "/admin/timetable", "Jadwal mingguan"],
  [14, `admin${D}`, "/", 4, null, "Daftar sesi kelas"],
  [15, `admin${D}`, "/", 5, null, "Daftar voucher"],
  [16, `admin${D}`, "/", null, "/admin/price-list", "Daftar harga"],
  [17, `admin${D}`, "/", 6, null, "Daftar tagihan dan pembayaran"],
  [18, `admin${D}`, "/", null, "/admin/tests/promotion", "Verifikasi kenaikan tingkat"],
  [19, `admin${D}`, "/", 7, null, "Laporan bulanan", [731, 212]],
  [20, `admin${D}`, "/", 9, null, "Pengumuman", [1150, 104]],
  [21, `teacher${D}`, "/", 0, null, "Dashboard guru"],
  [22, `teacher${D}`, "/", null, "/teacher/schedule", "Jadwal mengajar guru"],
  [23, `teacher${D}`, "/", null, todaySession ? `/teacher/session/${todaySession}` : null,
    "Halaman sesi dan absensi"],
  [24, `teacher${D}`, "/", null, null, "Paket latihan guru", [84, 285]],
  [25, `teacher${D}`, "/", null, null, "Tes di sisi guru", [66, 435]],
  [26, `teacher${D}`, "/", null, "SUPERVISE", "Pengawasan sesi tes"],
  [27, `teacher${D}`, "/", null, "/teacher/tests/marking", "Antrean penilaian"],
  [28, `teacher${D}`, "/", null, `/teacher/student/${student1Uid}/progress`, "Laporan progress murid di sisi guru"],
  [29, `student1${D}`, "/", 0, null, "Beranda murid"],
  [30, `student1${D}`, "/", 1, null, "Pemesanan sesi kelas"],
  [31, `student1${D}`, "/", null, bookedSession ? `/student/class/${bookedSession}` : null,
    "Halaman kelas yang dipesan"],
  [32, `student1${D}`, "/", 2, null, "Daftar latihan murid"],
  [33, `student1${D}`, "/", null, "/student/exercise/pkg_typing", "Pemutar latihan (soal ketik)"],
  [34, `student1${D}`, "/", 4, null, "Tes: memasukkan token"],
  [35, "student26@test.chinesetracker", "/", null, "/student/test-leaderboard/PRG2", "Leaderboard kode tes"],   // a student with a result on that code (trial seed)
  [36, `student1${D}`, "/", 5, null, "Voucher dan pembayaran murid"],
  [37, `student1${D}`, "/", 3, null, "Laporan progress murid"],
];

const chrome = [process.env.CHROME,
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
  "C:/Program Files/Google/Chrome/Application/chrome.exe",
  "C:/Program Files (x86)/Google/Chrome/Application/chrome.exe", "/usr/bin/google-chrome"]
    .filter(Boolean).find((c) => fs.existsSync(c));
if (!chrome) throw new Error("Chrome not found (set CHROME)");

async function openSupervision() {
  const r = await fetch(`${AUTH}/accounts:signInWithPassword?key=fake`, {method: "POST",
    headers: {"Content-Type": "application/json"},
    body: JSON.stringify({email: `teacher${D}`, password: "emulator-only-7", returnSecureToken: true})});
  const {idToken} = await r.json();
  const s = await fetch(`${FN}/openTestSession`, {method: "POST",
    headers: {"Content-Type": "application/json", Authorization: `Bearer ${idToken}`},
    body: JSON.stringify({data: {codeId: "H3DEMO1"}})});
  const j = await s.json();
  if (!j.result) throw new Error(`openTestSession: ${JSON.stringify(j.error)}`);
  return `/teacher/tests/supervise/${j.result.sessionId}`;
}

const profile = fs.mkdtempSync(path.join(os.tmpdir(), "shots-chrome-"));
const proc = spawn(chrome, ["--headless=new", "--disable-gpu", "--no-first-run",
  "--no-default-browser-check", `--user-data-dir=${profile}`, "--remote-debugging-port=0",
  "--force-color-profile=srgb", "about:blank"], {stdio: "ignore"});
const portFile = path.join(profile, "DevToolsActivePort");
const t0 = Date.now();
while (!fs.existsSync(portFile) || !fs.readFileSync(portFile, "utf8").includes("\n")) {
  if (Date.now() - t0 > 20000) throw new Error("Chrome did not start");
  await new Promise((r) => setTimeout(r, 200));
}
const devPort = fs.readFileSync(portFile, "utf8").split("\n")[0].trim();
const version = await (await fetch(`http://127.0.0.1:${devPort}/json/version`)).json();
const ws = new WebSocket(version.webSocketDebuggerUrl);
await new Promise((r, j) => {
  ws.onopen = r;
  ws.onerror = j;
});
let nextId = 1;
const pending = new Map();
ws.onmessage = (ev) => {
  const m = JSON.parse(ev.data);
  if (m.id && pending.has(m.id)) {
    pending.get(m.id)(m);
    pending.delete(m.id);
  }
};
const send = (method, params = {}, sessionId) => new Promise((resolve, reject) => {
  const id = nextId++;
  pending.set(id, (m) => (m.error ? reject(new Error(`${method}: ${m.error.message}`)) : resolve(m.result)));
  ws.send(JSON.stringify({id, method, params, ...(sessionId ? {sessionId} : {})}));
});
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const sheet = ["# Bab VI screenshots", "",
  "Made by `docs/thesis/tools/shots_bab6.mjs` on the emulator bundle with the trial seed",
  `(${new Date().toISOString().slice(0, 10)}), Indonesian, light, 1280 x 800.`, "",
  "All shots are in `docs/thesis/word/bab6_lengkap/`. The book shows the twelve with a figure",
  "number (`bab6_book.mjs`); `clean_shots.mjs` copies them to `docs/thesis/word/fig_6_<n>.png`.", "",
  "| Tangkapan | Gambar di buku | Halaman |", "|---|---|---|"];
const failures = [];

for (const [n, who, start, tab, deep, caption, click] of SHOTS) {
  if (ONLY.length && !ONLY.includes(n)) continue;
  const file = `fig_6_${n}.png`;
  if (deep === null && start === null) {
    failures.push(`${file}: no route (seed id missing)`);
    continue;
  }
  const {browserContextId} = await send("Target.createBrowserContext");
  try {
    const {targetId} = await send("Target.createTarget", {url: "about:blank", browserContextId});
    const {sessionId} = await send("Target.attachToTarget", {targetId, flatten: true});
    await send("Page.enable", {}, sessionId);
    await send("Emulation.setDeviceMetricsOverride",
        {width: 1280, height: 800, deviceScaleFactor: 1, mobile: false}, sessionId);
    await send("Emulation.setEmulatedMedia",
        {features: [{name: "prefers-color-scheme", value: "light"}]}, sessionId);
    await send("Page.addScriptToEvaluateOnNewDocument", {source:
      "try { localStorage.setItem('flutter.app_locale', '\"id\"'); } catch (e) {}"}, sessionId);
    const q = new URLSearchParams();
    if (who) q.set("as", who);
    if (tab !== null) q.set("tab", String(tab));
    await send("Page.navigate", {url: `${BASE}${start}${q.toString() ? `?${q}` : ""}`}, sessionId);
    const evaluate = async (expression) => (await send("Runtime.evaluate",
        {expression, returnByValue: true, awaitPromise: true}, sessionId)).result.value;
    if (who) {
      const role = who.startsWith("pending") ? "/waiting" : who.startsWith("student") ? "/student" :
        who.startsWith("teacher") ? "/teacher" : "/admin";
      const until = Date.now() + 40000;
      while (!(await evaluate("location.pathname")).startsWith(role)) {
        if (Date.now() > until) throw new Error(`not signed in as ${who}`);
        await sleep(500);
      }
    }
    await sleep(3000);
    if (deep) {
      const route = deep === "SUPERVISE" ? await openSupervision() : deep;
      await evaluate(`history.pushState({}, '', ${JSON.stringify(route)}); ` +
        "dispatchEvent(new PopStateEvent('popstate')); true");
    }
    if (click) {
      await sleep(4000);
      const [x, y] = click;
      await send("Input.dispatchMouseEvent", {type: "mouseMoved", x, y}, sessionId);
      await send("Input.dispatchMouseEvent", {type: "mousePressed", x, y, button: "left", clickCount: 1}, sessionId);
      await send("Input.dispatchMouseEvent", {type: "mouseReleased", x, y, button: "left", clickCount: 1}, sessionId);
    }
    await sleep(deep || click ? 7000 : 5000);
    const {data} = await send("Page.captureScreenshot", {format: "png"}, sessionId);
    fs.writeFileSync(path.join(OUT, file), Buffer.from(data, "base64"));
    sheet.push(`| ${n} | ${BOOK[n] ? `6.${BOOK[n]}` : "–"} | ${caption} |`);
    console.log(`${file}: saved (${caption})`);
  } catch (err) {
    failures.push(`${file}: ${err.message}`);
    console.log(`${file}: FAILED ${err.message}`);
  }
  await send("Target.disposeBrowserContext", {browserContextId});
}

if (!ONLY.length) fs.writeFileSync(path.join(HERE, "shots_bab6.md"), sheet.join("\n") + "\n");
if (failures.length) console.log(`\n${failures.length} failed:\n${failures.join("\n")}`);
ws.close();
proc.kill();
setTimeout(() => {
  try {
    fs.rmSync(profile, {recursive: true, force: true});
  } catch {
    // Chrome may still hold the folder for a moment.
  }
  process.exit(failures.length ? 1 : 0);
}, 500);
