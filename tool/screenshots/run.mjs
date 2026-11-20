#!/usr/bin/env node
// Build 8 (docs/PLAN.md §4, Must 7): the proposal's 15 screenshots in one
// pass. Headless Chrome (DevTools protocol, Node's own WebSocket) against
// the EMULATOR bundle with the trial seed:
//
//   scripts/run_emulator_web.sh            (serves build/web-emulator on :5181)
//   py -I scripts/seed_trial.py emulator
//   node tool/screenshots/run.mjs [--base http://127.0.0.1:5181] [--only 02,05]
//
// Every shot: a fresh browser context, Indonesian, light, 1280 × 800; the
// emulator bundle signs in with ?as=<email> (emulator-only password) and
// opens a tab with ?tab=N. Files: docs/screenshots/proposal/NN_name.png
// (names from docs/THESIS_PROPOSAL_ASSETS.md) and CONTACT_SHEET.md. Never
// point it at the live site: ?as= exists only in the emulator bundle.
import {spawn} from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import {fileURLToPath} from "node:url";

const ROOT = path.join(path.dirname(fileURLToPath(import.meta.url)), "..", "..");
const OUT = path.join(ROOT, "docs", "screenshots", "proposal");
const args = process.argv.slice(2);
const opt = (n, d) => (args.includes(n) ? args[args.indexOf(n) + 1] : d);
const BASE = opt("--base", "http://127.0.0.1:5181").replace(/\/$/, "");
const ONLY = (opt("--only", "") || "").split(",").filter(Boolean);
const FN = "http://127.0.0.1:5001/chinese-tracker/us-central1";
const AUTH = "http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1";
const D = "@test.chinesetracker";
if (!/^http:\/\/(127\.0\.0\.1|localhost)(:\d+)?$/.test(BASE)) {
  console.error("Emulator bundle on localhost only.");
  process.exit(2);
}

// [file, account (null = signed out), start path, tab, deep route, note]
const SHOTS = [
  ["01_login_register.png", null, "/", null, "/register", "Register form with the placement choice"],
  ["02_sesi_kelas.png", `student1${D}`, "/", 0, null, "Student home: Sesi Kelas with seats and Daftar"],
  ["03_soal_latihan.png", null, null, null, null,
    "MANUAL: sign in as student1, open a practice package, answer an R1 fill-in-the-blank question, submit, and capture the review with the pembahasan."],
  ["04_soal_typing.png", `student1${D}`, "/", null, "/student/exercise/pkg_typing", "The typing package (pkg_typing)"],
  ["05_voucher.png", `student1${D}`, "/", 5, null, "Student Payments tab: vouchers and Beli"],
  ["06_tes_token.png", `student1${D}`, "/", null, "/student/test", "Token input with the test code"],
  ["07_leaderboard.png", `student1${D}`, "/", null, "/student/test-leaderboard/H3DEMO1", "Leaderboard of H3DEMO1"],
  ["08_progress.png", `student1${D}`, "/", 3, null, "Student Progress tab: the report"],
  ["09_guru_jadwal.png", `teacher${D}`, "/", null, "/teacher/schedule", "Teacher Schedule: Today"],
  ["10_guru_pengawasan.png", `teacher${D}`, "/", null, "SUPERVISE", "Supervision of a fresh H3DEMO1 session: token and students"],
  ["11_admin_buat_jadwal.png", null, null, null, null,
    "MANUAL: sign in as admin, Kelas → Jadwal mingguan → Jadwal baru; pick Andrea, Monday 16:00, Main: the clash text and the suggested free times appear; capture the dialog."],
  ["12_admin_persetujuan.png", `admin${D}`, "/", null, "/admin/users/approval", "Registration approval (pending1@, pending2@)"],
  ["13_admin_kenaikan.png", `admin${D}`, "/", null, "/admin/tests/promotion", "Promotion verification"],
  ["14_admin_dashboard.png", `admin${D}`, "/", 0, null, "Admin dashboard: the six duty cards"],
  ["15_admin_pembayaran.png", `admin${D}`, "/", 6, null, "Admin Payments: invoice list with status"],
];

const chrome = [process.env.CHROME, "C:/Program Files/Google/Chrome/Application/chrome.exe",
  "C:/Program Files (x86)/Google/Chrome/Application/chrome.exe",
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome", "/usr/bin/google-chrome"]
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

fs.mkdirSync(OUT, {recursive: true});
const sheet = ["# Proposal screenshots (contact sheet)", "",
  "Made by `tool/screenshots/run.mjs` on the emulator bundle with the trial seed",
  `(${new Date().toISOString().slice(0, 10)}), Indonesian, light, 1280 × 800.`, ""];

for (const [file, who, start, tab, deep, note] of SHOTS) {
  const num = file.slice(0, 2);
  if (ONLY.length && !ONLY.includes(num)) continue;
  if (!start) {
    sheet.push(`## ${file}`, "", note, "");
    console.log(`${file}: manual step written`);
    continue;
  }
  const {browserContextId} = await send("Target.createBrowserContext");
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
    const role = who.startsWith("student") ? "/student" : who.startsWith("teacher") ? "/teacher" : "/admin";
    const until = Date.now() + 30000;
    while (!(await evaluate("location.pathname")).startsWith(role)) {
      if (Date.now() > until) throw new Error(`${file}: not signed in as ${who}`);
      await sleep(500);
    }
  }
  await sleep(3000);
  if (deep) {
    const route = deep === "SUPERVISE" ? await openSupervision() : deep;
    await evaluate(`history.pushState({}, '', ${JSON.stringify(route)}); ` +
      "dispatchEvent(new PopStateEvent('popstate')); true");
  }
  await sleep(6000);
  const {data} = await send("Page.captureScreenshot", {format: "png"}, sessionId);
  fs.writeFileSync(path.join(OUT, file), Buffer.from(data, "base64"));
  sheet.push(`## ${file}`, "", note, "", `![${file}](${file})`, "");
  console.log(`${file}: saved`);
  await send("Target.disposeBrowserContext", {browserContextId});
}

if (!ONLY.length) fs.writeFileSync(path.join(OUT, "CONTACT_SHEET.md"), sheet.join("\n"));
ws.close();
proc.kill();
setTimeout(() => {
  try {
    fs.rmSync(profile, {recursive: true, force: true});
  } catch {
    // Chrome may still hold the folder for a moment.
  }
  process.exit(0);
}, 500);
