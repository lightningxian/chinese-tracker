#!/usr/bin/env node
// Cleans the Bab VI screenshots for the book: the emulator bundle paints a
// red "EMULATOR" ribbon in the top-left corner (Flutter Banner, topStart:
// the band between x + y = 28·√2 and 40·√2 plus its shadow) and the Auth
// emulator adds a warning bar at the bottom. Both say nothing about the
// system, so the ribbon is painted over with the colours next to it and the
// bottom bar is cropped away (1280 × 800 → 1280 × 776). Pixels are handled
// in headless Chrome (canvas 2D), so no image library is needed.
// Afterwards the twelve shots the book shows are copied from
// word/bab6_lengkap/ to word/fig_6_<figure>.png (mapping in bab6_book.mjs).
//
//   node docs/thesis/tools/clean_shots.mjs [files…]   (default: word/bab6_lengkap/fig_6_*.png)
import {spawn} from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import {fileURLToPath} from "node:url";
import {BOOK} from "./bab6_book.mjs";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const WORD = path.join(HERE, "..", "word");
const FULL = path.join(WORD, "bab6_lengkap");
const files = process.argv.slice(2).length ? process.argv.slice(2) :
  fs.readdirSync(FULL).filter((f) => /^fig_6_\d+\.png$/.test(f)).map((f) => path.join(FULL, f));
const HEIGHT = 776;

const chrome = [process.env.CHROME,
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
  "C:/Program Files/Google/Chrome/Application/chrome.exe",
  "C:/Program Files (x86)/Google/Chrome/Application/chrome.exe", "/usr/bin/google-chrome"]
    .filter(Boolean).find((c) => fs.existsSync(c));
if (!chrome) throw new Error("Chrome not found (set CHROME)");

const profile = fs.mkdtempSync(path.join(os.tmpdir(), "clean-chrome-"));
const proc = spawn(chrome, ["--headless=new", "--disable-gpu", "--no-first-run",
  `--user-data-dir=${profile}`, "--remote-debugging-port=0", "about:blank"], {stdio: "ignore"});
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

const {targetId} = await send("Target.createTarget", {url: "about:blank"});
const {sessionId} = await send("Target.attachToTarget", {targetId, flatten: true});
await send("Runtime.enable", {}, sessionId);

// Runs in the page: returns the cleaned PNG as a data URL.
const CLEAN = `(async (dataUrl, height) => {
  const img = new Image();
  await new Promise((ok, bad) => { img.onload = ok; img.onerror = bad; img.src = dataUrl; });
  const c = document.createElement('canvas');
  c.width = img.width; c.height = Math.min(height, img.height);
  const g = c.getContext('2d');
  g.drawImage(img, 0, 0);
  const px = (x, y) => { const d = g.getImageData(x, y, 1, 1).data; return [d[0], d[1], d[2]]; };
  const rgb = (p) => 'rgb(' + p.join(',') + ')';
  // The whole corner up to the band's outer edge plus its shadow (x + y <= 66) is
  // painted row by row: the colour of the bar across the top for the first 56
  // rows (sampled at the right edge, where no icon sits), then the colour of
  // the column under the ribbon. A page without a side menu (the exercise
  // player, the leaderboard) has a white bar over a beige page, so one colour
  // for the whole corner would leave a wedge.
  const head = px(c.width - 6, 20), side = px(2, 72);
  for (let y = 0; y < 66; y++) { g.fillStyle = rgb(y < 56 ? head : side); g.fillRect(0, y, 66 - y, 1); }
  return c.toDataURL('image/png');
})`;

for (const file of files) {
  const data = fs.readFileSync(file).toString("base64");
  const r = await send("Runtime.evaluate", {
    expression: `${CLEAN}("data:image/png;base64,${data}", ${HEIGHT})`,
    awaitPromise: true, returnByValue: true}, sessionId);
  const out = r.result && r.result.value;
  if (!out || !out.startsWith("data:image/png;base64,")) {
    console.log(`${path.basename(file)}: FAILED ${JSON.stringify(r.exceptionDetails || r.result)}`);
    continue;
  }
  fs.writeFileSync(file, Buffer.from(out.slice("data:image/png;base64,".length), "base64"));
  console.log(`${path.basename(file)}: cleaned`);
}

// The book's figures: shot number → Gambar 6.<figure>.
for (const [shot, fig] of Object.entries(BOOK)) {
  const from = path.join(FULL, `fig_6_${shot}.png`);
  if (fs.existsSync(from)) fs.copyFileSync(from, path.join(WORD, `fig_6_${fig}.png`));
}
console.log(`${Object.keys(BOOK).length} book figures copied to ${path.relative(process.cwd(), WORD)}`);

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
