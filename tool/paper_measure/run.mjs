// Reads a paper PDF with one engine in headless Chrome and saves the page
// texts (docs/PLAN.md, Build 1C, Must 2). No npm packages: a tiny local web
// server for measure.html and the PDF, and the Chrome DevTools protocol over
// Node's own WebSocket.
//
//   node tool/paper_measure/run.mjs <paper.pdf> <engine> <out.json> [chrome]
//
// engine: tess6 (today's reader) | tess6sim | boxes | lines7 | paddle
// Then: flutter test test/paper_measure_test.dart with PAPER_TEXTS=<out.json>
// and PAPER_TRUTH=<truth.json> prints the numbers.

import {spawn} from 'node:child_process';
import fs from 'node:fs';
import http from 'node:http';
import os from 'node:os';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const [pdfPath, engine = 'tess6', outPath, chromeArg] = process.argv.slice(2);
if (!pdfPath || !outPath) {
  console.error('Usage: node tool/paper_measure/run.mjs <paper.pdf> <engine> <out.json> [chrome]');
  process.exit(2);
}

const chrome = [chromeArg, process.env.CHROME,
  'C:/Program Files/Google/Chrome/Application/chrome.exe',
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  '/usr/bin/google-chrome'].filter(Boolean).find((c) => fs.existsSync(c));
if (!chrome) throw new Error('Chrome not found');

const types = {'.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript',
  '.json': 'application/json', '.onnx': 'application/octet-stream', '.wasm': 'application/wasm',
  '.txt': 'text/plain', '.pdf': 'application/pdf'};
const server = http.createServer((req, res) => {
  const url = new URL(req.url, 'http://x');
  const webDir = path.resolve(here, '..', '..', 'web');
  const p = decodeURIComponent(url.pathname);
  const file = p === '/paper.pdf'
    ? path.resolve(pdfPath)
    : p.startsWith('/web/') ? path.join(webDir, p.slice(5)) : path.join(here, p);
  if (!file.startsWith(here) && !file.startsWith(webDir) && file !== path.resolve(pdfPath)) {
    res.writeHead(403); return res.end();
  }
  fs.readFile(file, (err, data) => {
    if (err) { res.writeHead(404); return res.end(); }
    res.writeHead(200, {'Content-Type': types[path.extname(file)] || 'application/octet-stream'});
    res.end(data);
  });
});
await new Promise((r) => server.listen(0, '127.0.0.1', r));
const port = server.address().port;

const profile = fs.mkdtempSync(path.join(os.tmpdir(), 'measure-chrome-'));
const proc = spawn(chrome, ['--headless=new', '--disable-gpu', '--no-first-run',
  '--no-default-browser-check', `--user-data-dir=${profile}`, '--remote-debugging-port=0',
  'about:blank'], {stdio: 'ignore'});

const portFile = path.join(profile, 'DevToolsActivePort');
const started = Date.now();
while (!fs.existsSync(portFile) || !fs.readFileSync(portFile, 'utf8').includes('\n')) {
  if (Date.now() - started > 20000) throw new Error('Chrome did not start');
  await new Promise((r) => setTimeout(r, 200));
}
const devPort = fs.readFileSync(portFile, 'utf8').split('\n')[0].trim();
const pageUrl = `http://127.0.0.1:${port}/measure.html?engine=${engine}&pdf=/paper.pdf`;
const target = await (await fetch(`http://127.0.0.1:${devPort}/json/new?${encodeURIComponent(pageUrl)}`,
  {method: 'PUT'})).json();

const ws = new WebSocket(target.webSocketDebuggerUrl);
await new Promise((r, j) => { ws.onopen = r; ws.onerror = j; });
let nextId = 1;
const pending = new Map();
ws.onmessage = (ev) => {
  const m = JSON.parse(ev.data);
  if (m.id && pending.has(m.id)) { pending.get(m.id)(m); pending.delete(m.id); }
};
const evaluate = (expression) => new Promise((resolve) => {
  const id = nextId++;
  pending.set(id, (m) => resolve(m.result && m.result.result ? m.result.result.value : undefined));
  ws.send(JSON.stringify({id, method: 'Runtime.evaluate', params: {expression, returnByValue: true}}));
});

let last = -1;
for (;;) {
  await new Promise((r) => setTimeout(r, 2000));
  const s = await evaluate('JSON.stringify({done: window.done, n: (window.results||[]).length})');
  if (!s) continue;
  const {done, n} = JSON.parse(s);
  if (n !== last) { process.stdout.write(`\rpage ${n}`); last = n; }
  if (done === true) break;
  if (typeof done === 'string') { console.error('\n' + done); process.exit(1); }
  if (Date.now() - started > 30 * 60 * 1000) throw new Error('timeout');
}
const results = await evaluate('JSON.stringify({meta: window.meta, pages: window.results})');
fs.mkdirSync(path.dirname(path.resolve(outPath)), {recursive: true});
fs.writeFileSync(outPath, results);
const {meta} = JSON.parse(results);
console.log(`\n${engine}: ${(meta.totalMs / 1000).toFixed(1)} s (model load ${(meta.loadMs / 1000).toFixed(1)} s) -> ${outPath}`);
ws.close();
proc.kill();
server.close();
setTimeout(() => { try { fs.rmSync(profile, {recursive: true, force: true}); } catch (_) {} process.exit(0); }, 500);
