#!/usr/bin/env node
// Makes the demonstration video of the book (Bab VI): a scripted walk through
// the EMULATOR bundle with caption text, no voice. Node standard library and
// headless Chrome through the DevTools protocol; Chrome itself writes the MP4
// (canvas captureStream + MediaRecorder, H.264), so nothing is installed.
//
//   firebase emulators:start --project chinese-tracker
//   python3 -I scripts/seed_trial.py emulator
//   scripts/run_emulator_web.sh                       (serves :5181)
//   node docs/thesis/tools/video/make_demo_video.mjs  (about 15 minutes: 7 to film, 6.5 to record)
//
// Start from a fresh emulator and seed: the walk approves a student, closes a class and sits a test,
// so a second run on the same data meets a different state (the class is found again or made anew,
// but the waiting student is gone and the test becomes a repeat sitting).
//
// Options:
//   --only admin,guru,murid   film only these scenes (title cards stay)
//   --explore <email> <route> print the labelled elements of one page and save
//                             explore.png in the work folder, then stop
//   --work <dir>              frames and timeline (default: a temp folder)
//   --capture-only            film only; the timeline and the pictures stay in --work
//   --render-only             record again from the timeline in --work (after a change to the player)
//   --out <file>              default docs/thesis/local/video/Demo Easy Study.mp4
//   --check <file> <dir> [seconds,...]  read a finished video in Chrome: prints its length and size and saves
//                             one PNG per given second into <dir>, then stops
//
// How it works. Pass 1 drives the app in a 1440 x 738 window (Chrome runs at 4/3 scale) and keeps the
// screencast frames with their times, the captions and the click points
// (demo_steps.mjs is the script: one step = one action, an optional caption
// and a wait). Loading pauses are cut. Pass 2 plays the frames in real time
// on a 1920 x 1080 canvas (app picture, caption strip, a ring at each click)
// and records it. The emulator ribbon is painted over and the Auth warning
// bar is hidden, as clean_shots.mjs does for the figures. macOS `avconvert`
// then rewrites the file so every player reads its length.
//
// Never point it at the live site: ?as=<email> exists only in the emulator
// bundle, and every account and number on screen is seed data.
import {spawn, spawnSync} from "node:child_process";
import fs from "node:fs";
import http from "node:http";
import os from "node:os";
import path from "node:path";
import {fileURLToPath} from "node:url";
import {SCENES} from "./demo_steps.mjs";
import {call, query, idTokenOf} from "../emu_prep.mjs";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.join(HERE, "..", "..", "..", "..");
const args = process.argv.slice(2);
const opt = (n, d) => (args.includes(n) ? args[args.indexOf(n) + 1] : d);
const BASE = opt("--base", "http://127.0.0.1:5181").replace(/\/$/, "");
const ONLY = (opt("--only", "") || "").split(",").filter(Boolean);
const WORK = path.resolve(opt("--work", fs.mkdtempSync(path.join(os.tmpdir(), "demo-video-"))));
const OUT = path.resolve(opt("--out", path.join(ROOT, "docs", "thesis", "local", "video", "Demo Easy Study.mp4")));
const RENDER_ONLY = args.includes("--render-only");
const EXPLORE = args.includes("--explore") ? args.slice(args.indexOf("--explore") + 1, args.indexOf("--explore") + 3) : null;
// The app runs in a VW x VH window drawn at SCALE device pixels, so the film is 1920 x 1080 and sharp.
const VW = 1440, VH = 738, SCALE = 4 / 3;
const W = Math.round(VW * SCALE), APP_H = Math.round(VH * SCALE), STRIP = 96, H = APP_H + STRIP;
if (!/^http:\/\/(127\.0\.0\.1|localhost)(:\d+)?$/.test(BASE)) {
  console.error("Emulator bundle on localhost only.");
  process.exit(2);
}
fs.mkdirSync(path.join(WORK, "frames"), {recursive: true});
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// ---------------------------------------------------------------- Chrome
const chrome = [process.env.CHROME,
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
  "C:/Program Files/Google/Chrome/Application/chrome.exe",
  "C:/Program Files (x86)/Google/Chrome/Application/chrome.exe", "/usr/bin/google-chrome"]
    .filter(Boolean).find((c) => fs.existsSync(c));
if (!chrome) throw new Error("Chrome not found (set CHROME)");
const profile = fs.mkdtempSync(path.join(os.tmpdir(), "demo-chrome-"));
const proc = spawn(chrome, ["--headless=new", "--no-first-run", "--no-default-browser-check",
  `--user-data-dir=${profile}`, "--remote-debugging-port=0", "--force-color-profile=srgb",
  "--autoplay-policy=no-user-gesture-required", "--disable-background-timer-throttling",
  "--disable-renderer-backgrounding", "--disable-backgrounding-occluded-windows",
  // The whole browser runs at this scale: the screencast then gives 1920 x 984 pictures of a 1440 x 738 window.
  `--force-device-scale-factor=${SCALE}`, "about:blank"], {stdio: "ignore"});
const portFile = path.join(profile, "DevToolsActivePort");
const t0 = Date.now();
while (!fs.existsSync(portFile) || !fs.readFileSync(portFile, "utf8").includes("\n")) {
  if (Date.now() - t0 > 20000) throw new Error("Chrome did not start");
  await sleep(200);
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
const listeners = new Map();          // sessionId -> (method, params) => void
ws.onmessage = (ev) => {
  const m = JSON.parse(ev.data);
  if (m.id && pending.has(m.id)) {
    pending.get(m.id)(m);
    pending.delete(m.id);
  } else if (m.method && m.sessionId && listeners.has(m.sessionId)) {
    listeners.get(m.sessionId)(m.method, m.params);
  }
};
const send = (method, params = {}, sessionId) => new Promise((resolve, reject) => {
  const id = nextId++;
  pending.set(id, (m) => (m.error ? reject(new Error(`${method}: ${m.error.message}`)) : resolve(m.result)));
  ws.send(JSON.stringify({id, method, params, ...(sessionId ? {sessionId} : {})}));
});
function finish(code) {
  try {
    ws.close();
  } catch {
    // already closed
  }
  proc.kill();
  setTimeout(() => {
    try {
      fs.rmSync(profile, {recursive: true, force: true});
    } catch {
      // Chrome may still hold the folder for a moment.
    }
    process.exit(code);
  }, 500);
}

// What a step's `do` may use: the app's callable functions and the Firestore emulator (emu_prep.mjs).
const emu = {call, query, idTokenOf};

// ---------------------------------------------------------------- the app tab
const IN_PAGE = `
window.__all = (root, acc = []) => { for (const e of root.querySelectorAll('*')) { acc.push(e); if (e.shadowRoot) window.__all(e.shadowRoot, acc); } return acc; };
window.__labels = () => { const out = []; for (const e of window.__all(document)) { if (e.tagName.toLowerCase() !== 'flt-semantics') continue;
  const own = [...e.childNodes].filter((n) => n.nodeType === 3 || (n.tagName && n.tagName.toLowerCase() === 'span')).map((n) => n.textContent).join('').trim();
  const text = (e.getAttribute('aria-label') || own || '').replace(/\\s*\\n\\s*/g, ' / ');
  const r = e.getBoundingClientRect(); if (!text || r.width < 2 || r.height < 2) continue;
  const input = e.querySelector(':scope > input, :scope > textarea') ? 'textbox' : '';
  out.push({x: Math.round(r.x + r.width / 2), y: Math.round(r.y + r.height / 2), w: Math.round(r.width), h: Math.round(r.height), role: e.getAttribute('role') || input, text}); }
  return out; };
window.__semantics = () => { const ph = window.__all(document).find((e) => e.tagName.toLowerCase() === 'flt-semantics-placeholder'); if (ph) ph.click(); return !!ph; };
`;
class App {
  constructor(sessionId) {
    this.s = sessionId;
    this.mouse = [VW / 2, VH / 2];
  }
  async eval(expression) {
    return (await send("Runtime.evaluate", {expression, returnByValue: true, awaitPromise: true}, this.s)).result.value;
  }
  async labels() {
    return (await this.eval(`(${"() => { " + IN_PAGE + " window.__semantics(); return window.__labels(); }"})()`)) || [];
  }
  /**
   * The element whose label matches: a string or {text, exact, role, nth, last}.
   * A label equal to the text wins over one that only contains it; among
   * equals the shortest label, then top to bottom, left to right. Elements
   * outside the window or clipped to a sliver do not count.
   */
  async find(target, timeout = 9000) {
    const q = typeof target === "string" ? {text: target} : target;
    const want = q.text.toLowerCase();
    const until = Date.now() + timeout;
    for (;;) {
      const seen = (await this.labels()).filter((l) => (!q.role || l.role === q.role) &&
        l.x > 0 && l.x < VW && l.y > 0 && l.y < VH && l.h >= 14 && l.w >= 14);
      const exact = seen.filter((l) => l.text.toLowerCase() === want);
      const loose = q.exact ? [] : seen.filter((l) => l.text.toLowerCase().includes(want));
      const hits = (exact.length ? exact : loose)
          .sort((a, b) => a.text.length - b.text.length || a.y - b.y || a.x - b.x);
      const ordered = q.nth !== undefined || q.last ? [...hits].sort((a, b) => a.y - b.y || a.x - b.x) : hits;
      const hit = q.last ? ordered[ordered.length - 1] : ordered[q.nth || 0];
      if (hit) return hit;
      if (Date.now() > until) return null;
      await sleep(400);
    }
  }
  async move(x, y) {
    this.mouse = [x, y];
    await send("Input.dispatchMouseEvent", {type: "mouseMoved", x, y}, this.s);
  }
  async press(x, y) {
    await send("Input.dispatchMouseEvent", {type: "mousePressed", x, y, button: "left", clickCount: 1}, this.s);
    await send("Input.dispatchMouseEvent", {type: "mouseReleased", x, y, button: "left", clickCount: 1}, this.s);
  }
  async type(text, perChar = 70) {
    for (const ch of [...text]) {
      await send("Input.insertText", {text: ch}, this.s);
      await sleep(perChar);
    }
  }
  async key(key) {
    const codes = {Enter: 13, Tab: 9, Escape: 27, Backspace: 8, ArrowDown: 40, ArrowUp: 38};
    const base = {key, code: key, windowsVirtualKeyCode: codes[key] || 0, nativeVirtualKeyCode: codes[key] || 0};
    await send("Input.dispatchKeyEvent", {type: "keyDown", ...base, ...(key === "Enter" ? {text: "\r"} : {})}, this.s);
    await send("Input.dispatchKeyEvent", {type: "keyUp", ...base}, this.s);
  }
  async wheel(dy, x = 840, y = 430) {
    const steps = Math.max(1, Math.round(Math.abs(dy) / 80));
    for (let i = 0; i < steps; i++) {
      await send("Input.dispatchMouseEvent", {type: "mouseWheel", x, y, deltaX: 0, deltaY: dy / steps}, this.s);
      await sleep(40);
    }
  }
  async route(route) {
    await this.eval(`history.pushState({}, '', ${JSON.stringify(route)}); dispatchEvent(new PopStateEvent('popstate')); true`);
  }
}

async function openApp(who, start) {
  const {browserContextId} = await send("Target.createBrowserContext");
  // A window of its own, sized so that the page area is VW x VH (no emulated
  // metrics: an emulated scale makes every screenshot resize the page, which closes open menus).
  const {targetId} = await send("Target.createTarget", {url: "about:blank", browserContextId, newWindow: true, width: VW, height: VH + 87});
  const {sessionId} = await send("Target.attachToTarget", {targetId, flatten: true});
  await send("Page.enable", {}, sessionId);
  for (let i = 0; i < 3; i++) {
    const inner = (await send("Runtime.evaluate", {expression: "[innerWidth, innerHeight, outerWidth, outerHeight]", returnByValue: true}, sessionId)).result.value;
    if (inner[0] === VW && inner[1] === VH) break;
    const {windowId} = await send("Browser.getWindowForTarget", {targetId});
    await send("Browser.setWindowBounds", {windowId, bounds: {width: VW + (inner[2] - inner[0]), height: VH + (inner[3] - inner[1])}});
    await sleep(400);
  }
  await send("Emulation.setEmulatedMedia", {features: [{name: "prefers-color-scheme", value: "light"}]}, sessionId);
  await send("Page.addScriptToEvaluateOnNewDocument", {source:
    "try { localStorage.setItem('flutter.app_locale', '\"id\"'); } catch (e) {}\n" +
    // The Auth emulator's warning bar says nothing about the system.
    "(() => { const add = () => { const st = document.createElement('style'); st.textContent = '.firebase-emulator-warning{display:none!important}'; (document.head || document.documentElement).appendChild(st); }; if (document.documentElement) add(); else addEventListener('DOMContentLoaded', add); })();"},
  sessionId);
  const app = new App(sessionId);
  app.context = browserContextId;
  const q = new URLSearchParams();
  let pathPart = start || "/";
  if (pathPart.includes("?")) {
    for (const [k, v] of new URLSearchParams(pathPart.split("?")[1])) q.set(k, v);
    pathPart = pathPart.split("?")[0];
  }
  if (who) q.set("as", who);
  await send("Page.navigate", {url: `${BASE}${pathPart}${q.toString() ? `?${q}` : ""}`}, sessionId);
  if (who) {
    const role = who.startsWith("pending") ? "/waiting" : who.startsWith("student") ? "/student" :
      who.startsWith("parent") ? "/parent" : who.startsWith("admin") ? "/admin" : "/teacher";
    const until = Date.now() + 45000;
    while (!String(await app.eval("location.pathname")).startsWith(role)) {
      if (Date.now() > until) throw new Error(`not signed in as ${who}`);
      await sleep(500);
    }
  }
  await sleep(3500);
  await app.labels();                 // turns the labelled tree on
  return app;
}

// ---------------------------------------------------------------- explore one page
if (EXPLORE) {
  const [who, route] = EXPLORE;
  const app = await openApp(who === "-" ? null : who, route && route.startsWith("/?") ? route : "/");
  if (route && route !== "-" && !route.startsWith("/?")) {
    await app.route(route);
    await sleep(5000);
  }
  // Extra arguments act on the page first: "x,y" clicks a point, "@Label" clicks an element, "type:text" types.
  for (const extra of args.slice(args.indexOf("--explore") + 3)) {
    if (extra.startsWith("--")) break;
    if (/^\d+,\d+$/.test(extra)) {
      const [x, y] = extra.split(",").map(Number);
      await app.move(x, y);
      await app.press(x, y);
    } else if (extra.startsWith("@")) {
      const hit = await app.find(extra.slice(1));
      if (!hit) console.log(`(no element "${extra.slice(1)}")`);
      else {
        await app.move(hit.x, hit.y);
        await app.press(hit.x, hit.y);
      }
    } else if (extra.startsWith("type:")) {
      await app.type(extra.slice(5), 30);
    }
    await sleep(3500);
  }
  console.log(await app.eval("location.pathname + location.search"));
  for (const l of await app.labels()) console.log(`${l.x},${l.y}  ${l.w}x${l.h}  [${l.role}]  ${l.text.slice(0, 90)}`);
  const {data} = await send("Page.captureScreenshot", {format: "png"}, app.s);
  fs.writeFileSync(path.join(WORK, "explore.png"), Buffer.from(data, "base64"));
  console.log(path.join(WORK, "explore.png"));
  finish(0);
  await sleep(2000);
}

// ---------------------------------------------------------------- check a finished video
if (args.includes("--check")) {
  const i = args.indexOf("--check");
  const file = path.resolve(args[i + 1]);
  const dir = path.resolve(args[i + 2] || WORK);
  const times = (args[i + 3] || "1").split(",").map(Number);
  const size = fs.statSync(file).size;
  fs.mkdirSync(dir, {recursive: true});
  const srv = http.createServer((req, res) => {
    if (req.url === "/v") {
      const m = /bytes=(\d+)-(\d*)/.exec(req.headers.range || "");
      const a = m ? Number(m[1]) : 0;
      const b = m && m[2] ? Number(m[2]) : size - 1;
      res.writeHead(m ? 206 : 200, {"Content-Type": "video/mp4", "Accept-Ranges": "bytes", "Content-Length": b - a + 1,
        ...(m ? {"Content-Range": `bytes ${a}-${b}/${size}`} : {})});
      fs.createReadStream(file, {start: a, end: b}).pipe(res);
    } else {
      res.writeHead(200, {"Content-Type": "text/html"});
      res.end("<video id=v src=/v muted preload=auto></video>");
    }
  });
  await new Promise((r) => srv.listen(0, "127.0.0.1", r));
  const {targetId} = await send("Target.createTarget", {url: "about:blank"});
  const {sessionId} = await send("Target.attachToTarget", {targetId, flatten: true});
  await send("Page.enable", {}, sessionId);
  await send("Page.navigate", {url: `http://127.0.0.1:${srv.address().port}/`}, sessionId);
  await sleep(800);
  const ev = async (expression) => (await send("Runtime.evaluate", {expression, returnByValue: true, awaitPromise: true}, sessionId)).result.value;
  const meta = await ev(`(async () => { const v = document.getElementById('v'); if (v.readyState < 1) await new Promise((r, j) => { v.onloadedmetadata = r; v.onerror = () => j(new Error('cannot read the video')); }); return [v.duration, v.videoWidth, v.videoHeight]; })()`);
  console.log(`${path.basename(file)}: ${Number(meta[0]).toFixed(1)} s (${(meta[0] / 60).toFixed(2)} min), ${meta[1]} x ${meta[2]}, ${(size / 1e6).toFixed(1)} MB`);
  for (const t of times) {
    const png = await ev(`(async () => { const v = document.getElementById('v'); v.currentTime = ${t}; await new Promise((r) => { v.onseeked = r; }); const c = document.createElement('canvas'); c.width = v.videoWidth; c.height = v.videoHeight; c.getContext('2d').drawImage(v, 0, 0); return c.toDataURL('image/png'); })()`);
    const out = path.join(dir, `check_${String(t).padStart(4, "0")}s.png`);
    fs.writeFileSync(out, Buffer.from(png.split(",")[1], "base64"));
    console.log(out);
  }
  srv.close();
  finish(0);
  await sleep(2000);
}

// ---------------------------------------------------------------- pass 1: film
const timelineFile = path.join(WORK, "timeline.json");
let timeline = [];
let frameNo = 0;

class Clip {
  constructor(app, role) {
    this.app = app;
    this.data = {type: "clip", role, frames: [], captions: [], clicks: [], dur: 0};
    this.clock = 0;          // recorded milliseconds so far
    this.since = null;       // wall time when recording was switched on
    this.lastKept = -1000;
    listeners.set(app.s, (method, params) => {
      if (method !== "Page.screencastFrame") return;
      send("Page.screencastFrameAck", {sessionId: params.sessionId}, app.s).catch(() => {});
      if (this.since === null) return;
      const t = this.now();
      if (t - this.lastKept < 110) return;          // about 9 pictures a second are enough
      this.keep(t, params.data);
    });
  }
  now() {
    return this.clock + (this.since === null ? 0 : Date.now() - this.since);
  }
  keep(t, base64) {
    const f = `f${String(++frameNo).padStart(6, "0")}.jpg`;
    fs.writeFileSync(path.join(WORK, "frames", f), Buffer.from(base64, "base64"));
    this.data.frames.push({t: Math.round(t), f});
    this.lastKept = t;
  }
  async on() {
    if (this.since !== null) return;
    // The screencast only sends a picture when the page changes: take the first one by hand.
    const {data} = await send("Page.captureScreenshot", {format: "jpeg", quality: 88}, this.app.s);
    this.since = Date.now();
    this.lastKept = -1000;
    this.keep(this.now(), data);
  }
  off() {
    if (this.since === null) return;
    this.clock = this.now();
    this.since = null;
  }
  async start() {
    await send("Page.startScreencast", {format: "jpeg", quality: 88, maxWidth: W, maxHeight: APP_H, everyNthFrame: 1}, this.app.s);
  }
  async stop() {
    this.off();
    this.data.dur = Math.round(this.clock);
    await send("Page.stopScreencast", {}, this.app.s).catch(() => {});
    listeners.delete(this.app.s);
  }
}

async function runStep(step, app, clip, shared) {
  const hidden = step.hidden === true;
  if (hidden) clip.off();
  if (step.caption !== undefined && !hidden) clip.data.captions.push({t: Math.round(clip.now()), text: step.caption});
  try {
    if (step.do) await step.do({app, emu, shared, sleep});
    if (step.go) {
      await app.route(typeof step.go === "function" ? step.go(shared) : step.go);
    }
    if (step.waitFor) {
      const hit = await app.find(typeof step.waitFor === "function" ? step.waitFor(shared) : step.waitFor, step.timeout || 15000);
      if (!hit) throw new Error(`waited for "${JSON.stringify(step.waitFor)}"`);
    }
    if (step.click) {
      let target = typeof step.click === "function" ? step.click(shared) : step.click;
      let x, y;
      if (Array.isArray(target)) [x, y] = target;
      else {
        const hit = await app.find(target, step.timeout || 9000);
        if (!hit) throw new Error(`no element "${JSON.stringify(target)}"`);
        x = hit.x + (step.dx || 0);
        y = hit.y + (step.dy || 0);
      }
      await app.move(x, y);
      if (!hidden) clip.data.clicks.push({t: Math.round(clip.now()) + 650, x, y});
      await sleep(hidden ? 50 : 650);            // the pointer travels in the film
      await app.press(x, y);
    }
    if (step.hover) {
      const hit = await app.find(typeof step.hover === "function" ? step.hover(shared) : step.hover, step.timeout || 9000);
      if (!hit) throw new Error(`no element "${JSON.stringify(step.hover)}"`);
      await app.move(hit.x, hit.y);
      if (!hidden) clip.data.clicks.push({t: Math.round(clip.now()) + 650, x: hit.x, y: hit.y, soft: true});
      await sleep(650);
    }
    if (step.type !== undefined) {
      await sleep(250);
      await app.type(typeof step.type === "function" ? step.type(shared) : step.type);
    }
    if (step.key) await app.key(step.key);
    if (step.scroll) await app.wheel(step.scroll, ...(step.at || []));
  } catch (err) {
    if (!step.optional) throw new Error(`step ${JSON.stringify(step, (k, v) => (typeof v === "function" ? "fn" : v)).slice(0, 160)}: ${err.message}`);
    console.log(`   (skipped optional step: ${err.message})`);
  }
  await sleep(step.wait === undefined ? (step.caption ? 2600 : 1200) : step.wait);
  if (hidden) await clip.on();
}

if (!RENDER_ONLY) {
  const shared = {};
  for (const scene of SCENES) {
    if (scene.card) {
      timeline.push({type: "card", ...scene.card});
      continue;
    }
    if (ONLY.length && !ONLY.includes(scene.name)) continue;
    console.log(`▶ ${scene.name}`);
    if (scene.before) await scene.before({emu, shared, sleep});
    const who = typeof scene.as === "function" ? scene.as(shared) : scene.as;
    const app = await openApp(who, typeof scene.start === "function" ? scene.start(shared) : scene.start);
    const clip = new Clip(app, scene.role || "");
    await clip.start();
    await clip.on();
    let n = 0;
    for (const step of scene.steps) {
      n += 1;
      try {
        await runStep(step, app, clip, shared);
      } catch (err) {
        const {data} = await send("Page.captureScreenshot", {format: "png"}, app.s);
        fs.writeFileSync(path.join(WORK, `failed_${scene.name}_${n}.png`), Buffer.from(data, "base64"));
        console.error(`✗ ${scene.name} step ${n}: ${err.message}\n  picture: ${path.join(WORK, `failed_${scene.name}_${n}.png`)}`);
        clip.off();
        clip.data.dur = Math.round(clip.clock);
        fs.writeFileSync(timelineFile, JSON.stringify([...timeline, clip.data]));     // what was filmed so far, to look at
        finish(1);
        await sleep(3000);
      }
    }
    await clip.stop();
    timeline.push(clip.data);
    console.log(`  ${(clip.data.dur / 1000).toFixed(0)} s, ${clip.data.frames.length} pictures`);
    await send("Target.disposeBrowserContext", {browserContextId: app.context});
  }
  fs.writeFileSync(timelineFile, JSON.stringify(timeline));
} else {
  timeline = JSON.parse(fs.readFileSync(timelineFile, "utf8"));
}
if (args.includes("--capture-only")) {
  console.log(`timeline in ${WORK}`);
  finish(0);
  await sleep(2000);
}

// ---------------------------------------------------------------- pass 2: play and record
const total = timeline.reduce((a, x) => a + (x.type === "card" ? x.ms : x.dur), 0);
console.log(`▶ recording ${(total / 60000).toFixed(1)} minutes in real time`);
const raw = path.join(WORK, "raw.mp4");
const rawStream = fs.createWriteStream(raw);
let doneResolve;
const done = new Promise((r) => (doneResolve = r));
const server = http.createServer((req, res) => {
  const url = new URL(req.url, "http://x");
  if (url.pathname === "/timeline") {
    res.writeHead(200, {"Content-Type": "application/json"});
    res.end(JSON.stringify(timeline));
  } else if (url.pathname.startsWith("/frames/")) {
    const f = path.join(WORK, "frames", path.basename(url.pathname));
    res.writeHead(200, {"Content-Type": "image/jpeg"});
    fs.createReadStream(f).pipe(res);
  } else if (url.pathname === "/chunk" && req.method === "POST") {
    req.on("data", (d) => rawStream.write(d));
    req.on("end", () => res.end("ok"));
  } else if (url.pathname === "/done") {
    res.end("ok");
    rawStream.end(() => doneResolve(url.searchParams.get("mime")));
  } else if (url.pathname === "/") {
    res.writeHead(200, {"Content-Type": "text/html; charset=utf-8"});
    res.end(PLAYER);
  } else {
    res.writeHead(404);
    res.end();
  }
});
const PLAYER = `<!doctype html><meta charset="utf-8"><body style="margin:0;background:#000"><canvas id="c" width="${W}" height="${H}"></canvas><script>
const W = ${W}, APP_H = ${APP_H}, H = ${H}, STRIP = ${STRIP}, K = ${SCALE};
const c = document.getElementById('c'), g = c.getContext('2d');
const FONT = '-apple-system, "Helvetica Neue", Helvetica, Arial, sans-serif';
const GREEN = '#0b6b50', INK = '#1f2937';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
function strip(text, role) {
  g.fillStyle = GREEN; g.fillRect(0, APP_H, W, STRIP);
  let x0 = 36;
  if (role) { g.font = 'bold 30px ' + FONT; const w = g.measureText(role).width + 44; g.fillStyle = '#ffffff';
    g.beginPath(); g.roundRect(30, APP_H + 21, w, 54, 27); g.fill(); g.fillStyle = GREEN; g.textAlign = 'center'; g.textBaseline = 'middle';
    g.fillText(role, 30 + w / 2, APP_H + 49); x0 = 30 + w + 30; }
  g.fillStyle = '#ffffff'; g.textAlign = 'left'; g.textBaseline = 'middle';
  let size = 38; g.font = size + 'px ' + FONT;
  while (g.measureText(text || '').width > W - x0 - 36 && size > 24) { size -= 1; g.font = size + 'px ' + FONT; }
  g.fillText(text || '', x0, APP_H + STRIP / 2 + 1);
}
function ribbon() {
  // The emulator ribbon in the top-left corner (Flutter Banner and its shadow, inside x + y <= 66): painted over row by row,
  // with the colour of the bar across the top for the first 56 rows and the colour of the column below it after that.
  const px = (x, y) => { const d = g.getImageData(x, y, 1, 1).data; return 'rgb(' + d[0] + ',' + d[1] + ',' + d[2] + ')'; };
  const head = px(W - 6, Math.round(20 * K)), side = px(Math.round(2 * K), Math.round(72 * K));
  for (let y = 0; y < 66; y++) { g.fillStyle = y < 56 ? head : side; g.fillRect(0, y * K, (66 - y) * K, K + 0.5); }
}
function pointer(vx, vy, pulse) {
  const x = vx * K, y = vy * K, u = 1.5;
  if (pulse > 0) { g.strokeStyle = 'rgba(220,38,38,' + (0.85 * pulse) + ')'; g.lineWidth = 5; g.beginPath(); g.arc(x, y, 16 + 30 * (1 - pulse), 0, 6.283); g.stroke(); }
  g.fillStyle = '#111827'; g.strokeStyle = '#ffffff'; g.lineWidth = 2; g.beginPath();
  g.moveTo(x, y); g.lineTo(x, y + 19 * u); g.lineTo(x + 5 * u, y + 14.5 * u); g.lineTo(x + 8.5 * u, y + 22 * u); g.lineTo(x + 11.5 * u, y + 20.6 * u); g.lineTo(x + 8 * u, y + 13.4 * u); g.lineTo(x + 14 * u, y + 13 * u); g.closePath(); g.fill(); g.stroke();
}
function card(k, alpha) {
  g.fillStyle = '#ffffff'; g.fillRect(0, 0, W, H); g.fillStyle = GREEN; g.fillRect(0, 0, W, 20); g.fillRect(0, H - 20, W, 20);
  g.textAlign = 'center'; g.textBaseline = 'middle';
  const lines = k.lines; const heights = lines.map((l) => (l.size || 44) * 1.5); let y = H / 2 - heights.reduce((a, b) => a + b, 0) / 2;
  lines.forEach((l, i) => { g.font = (l.bold ? 'bold ' : '') + (l.size || 44) + 'px ' + FONT; g.fillStyle = l.color === 'green' ? GREEN : (l.color === 'grey' ? '#6b7280' : INK);
    g.fillText(l.text, W / 2, y + heights[i] / 2); y += heights[i]; });
  if (alpha < 1) { g.fillStyle = 'rgba(255,255,255,' + (1 - alpha) + ')'; g.fillRect(0, 0, W, H); }
}
(async () => {
  const timeline = await (await fetch('/timeline')).json();
  const types = ['video/mp4;codecs=avc1.42E01E', 'video/mp4', 'video/webm;codecs=vp9', 'video/webm'];
  const mime = types.find((t) => MediaRecorder.isTypeSupported(t));
  const rec = new MediaRecorder(c.captureStream(25), {mimeType: mime, videoBitsPerSecond: 5000000});
  let chain = Promise.resolve();
  rec.ondataavailable = (e) => { if (e.data.size) chain = chain.then(() => fetch('/chunk', {method: 'POST', body: e.data})); };
  const stopped = new Promise((r) => rec.onstop = r);
  g.fillStyle = '#fff'; g.fillRect(0, 0, W, H);
  rec.start(1000);
  let tick = 0;
  const nudge = () => { tick ^= 1; g.fillStyle = tick ? 'rgba(11,107,80,1)' : 'rgba(11,107,81,1)'; g.fillRect(W - 2, H - 2, 2, 2); };   // keeps the stream alive on a still picture
  for (const item of timeline) {
    const start = performance.now();
    if (item.type === 'card') {
      for (;;) { const t = performance.now() - start; if (t >= item.ms) break;
        card(item, Math.min(1, t / 400, (item.ms - t) / 400)); nudge(); await sleep(40); }
      continue;
    }
    const frames = item.frames; const cache = new Map(); let loadedTo = -1;
    const load = async (i) => { if (i >= frames.length || cache.has(i)) return; cache.set(i, null);
      const b = await createImageBitmap(await (await fetch('/frames/' + frames[i].f)).blob()); cache.set(i, b); };
    for (let i = 0; i < Math.min(12, frames.length); i++) await load(i);
    let cur = -1, shown = null, mx = W / K / 2, my = APP_H / K / 2, from = [mx, my], ci = 0;
    for (;;) {
      const t = performance.now() - start; if (t >= item.dur) break;
      let n = cur; while (n + 1 < frames.length && frames[n + 1].t <= t) n += 1;
      for (let i = n + 1; i < Math.min(frames.length, n + 14); i++) load(i);
      if (n !== cur && cache.get(n)) { if (shown && shown !== cache.get(n)) shown.close(); shown = cache.get(n); for (const k of [...cache.keys()]) if (k < n) cache.delete(k); cur = n; }
      if (shown) { g.drawImage(shown, 0, 0, W, APP_H); ribbon(); }
      let caption = ''; for (const cp of item.captions) if (cp.t <= t) caption = cp.text;
      // pointer: travels to the next click during the 650 ms before it, pulses after it
      while (ci < item.clicks.length && t > item.clicks[ci].t + 500) { from = [item.clicks[ci].x, item.clicks[ci].y]; ci += 1; }
      let pulse = 0; const k = item.clicks[ci];
      if (k) { const a = Math.max(0, Math.min(1, (t - (k.t - 650)) / 600)); const e = a * a * (3 - 2 * a); mx = from[0] + (k.x - from[0]) * e; my = from[1] + (k.y - from[1]) * e;
        if (t >= k.t && !k.soft) pulse = Math.max(0, 1 - (t - k.t) / 500); } else { mx = from[0]; my = from[1]; }
      if (item.clicks.length) pointer(mx, my, pulse);
      strip(caption, item.role); nudge();
      await sleep(40);
    }
    if (shown) shown.close();
  }
  await sleep(300);
  rec.stop(); await stopped; await chain;
  await fetch('/done?mime=' + encodeURIComponent(mime));
})();
</script>`;
await new Promise((r) => server.listen(0, "127.0.0.1", r));
const port = server.address().port;
{
  const {targetId} = await send("Target.createTarget", {url: "about:blank"});
  const {sessionId} = await send("Target.attachToTarget", {targetId, flatten: true});
  await send("Page.enable", {}, sessionId);
  await send("Page.navigate", {url: `http://127.0.0.1:${port}/`}, sessionId);
}
const mime = await done;
server.close();
fs.mkdirSync(path.dirname(OUT), {recursive: true});
const ext = String(mime).startsWith("video/mp4") ? ".mp4" : ".webm";
const outFile = OUT.replace(/\.[a-z0-9]+$/i, ext);
// MediaRecorder writes a fragmented file without a total length; avconvert (macOS) rewrites it for every player.
let rewritten = false;
if (ext === ".mp4" && fs.existsSync("/usr/bin/avconvert")) {
  const r = spawnSync("/usr/bin/avconvert", ["--preset", "PresetPassthrough", "--source", raw, "--output", outFile, "--replace"], {encoding: "utf8"});
  rewritten = r.status === 0 && fs.existsSync(outFile) && fs.statSync(outFile).size > 1000;
  if (!rewritten) console.log(`avconvert did not rewrite the file: ${(r.stderr || r.stdout || "").trim().slice(0, 200)}`);
}
if (!rewritten) fs.copyFileSync(raw, outFile);
console.log(`${outFile}  ${(fs.statSync(outFile).size / 1e6).toFixed(1)} MB  ${mime}${rewritten ? "  (rewritten by avconvert)" : "  (as recorded)"}`);
console.log(`work folder: ${WORK}`);
finish(0);
