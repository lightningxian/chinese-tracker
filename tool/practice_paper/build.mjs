// Builds the practice HSK 3 paper and its truth file (docs/PLAN.md, Build 1C,
// Must 1a):
//
//   node tool/practice_paper/build.mjs [path/to/chrome]
//
// writes test/fixtures/practice_paper/H399001P.pdf (pages drawn by
// paper.html in headless Chrome, scan-like JPEGs) and
// test/fixtures/practice_paper/H399001P.truth.json (what the reader should
// read, in the shape of the proofreading draft). No npm packages.

import {execFileSync} from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {createRequire} from 'node:module';
import {fileURLToPath, pathToFileURL} from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, '..', '..');
const require = createRequire(import.meta.url);
const PAPER = require('./content.js');
const outDir = path.join(root, 'test', 'fixtures', 'practice_paper');

/** What the reader should make of each question (the truth). */
export function truthOf(paper) {
  const questions = [];
  let skill = 'listening';
  let section = '';
  let part = '';
  const skillOf = (heading) =>
      heading.includes('听力') ? 'listening' : heading.includes('书写') ? 'writing' : 'reading';
  const add = (q) => questions.push({prompt: '', options: [], segments: [], keyword: '', ...q});
  for (const b of paper.blocks) {
    if (b.kind === 'skill') { skill = skillOf(b.text); section = b.text; part = ''; continue; }
    if (b.kind === 'part') { part = b.text; continue; }
    if (b.start == null) continue;
    const sec = [section, part, `第${b.start}-${b.end}题`].filter(Boolean).join(' · ');
    const base = (i) => ({number: b.start + i, skill, section: sec});
    switch (b.kind) {
      case 'pictures':
        for (let n = b.start; n <= b.end; n++) {
          add({number: n, skill, section: sec, form: 'picture_choice', pictures: b.pictures.length});
        }
        break;
      case 'statements':
        b.items.forEach((s, i) => add({...base(i), form: 'true_false', prompt: `★ ${s}`}));
        break;
      case 'choices':
        b.items.forEach((o, i) => add({...base(i), form: 'choice', options: o}));
        break;
      case 'matching':
        b.items.forEach((s, i) => add({...base(i), form: 'matching', prompt: s, options: b.options}));
        break;
      case 'wordbank':
        b.items.forEach((lines, i) =>
          add({...base(i), form: 'cloze', prompt: lines.join(''), options: b.options}));
        break;
      case 'passages':
        b.items.forEach((it, i) => add({...base(i), form: 'choice',
          prompt: `${it.passage}\n★ ${it.question}`, options: it.options}));
        break;
      case 'reorder':
        b.items.forEach((pieces, i) => add({...base(i), form: 'reorder', segments: pieces}));
        break;
      case 'pinyin':
        b.items.forEach((it, i) => add({...base(i), form: 'write_hanzi',
          prompt: it.sentence, keyword: it.pinyin}));
        break;
    }
  }
  return {code: paper.code, level: paper.level, source: 'practice paper (tool/practice_paper)', questions};
}

/** A PDF with one full-page JPEG per page (A4). */
export function pdfOfJpegs(jpegs, width, height) {
  const chunks = [];
  const offsets = [];
  let size = 0;
  const push = (data) => {
    const b = typeof data === 'string' ? Buffer.from(data, 'latin1') : data;
    chunks.push(b); size += b.length;
  };
  const obj = (id, body) => { offsets[id] = size; push(`${id} 0 obj\n`); body(); push('\nendobj\n'); };
  const pw = 595.28, ph = 841.89;
  const n = jpegs.length;
  // 1 catalog, 2 pages, then per page: page, contents, image.
  const pageId = (i) => 3 + i * 3;
  push('%PDF-1.4\n%\xE2\xE3\xCF\xD3\n');
  obj(1, () => push('<< /Type /Catalog /Pages 2 0 R >>'));
  obj(2, () => push(`<< /Type /Pages /Count ${n} /Kids [${jpegs.map((_, i) => `${pageId(i)} 0 R`).join(' ')}] >>`));
  jpegs.forEach((jpg, i) => {
    const p = pageId(i);
    obj(p, () => push(`<< /Type /Page /Parent 2 0 R /MediaBox [0 0 ${pw} ${ph}] ` +
      `/Resources << /XObject << /Im0 ${p + 2} 0 R >> >> /Contents ${p + 1} 0 R >>`));
    const content = `q ${pw} 0 0 ${ph} 0 0 cm /Im0 Do Q`;
    obj(p + 1, () => push(`<< /Length ${content.length} >>\nstream\n${content}\nendstream`));
    obj(p + 2, () => {
      push(`<< /Type /XObject /Subtype /Image /Width ${width} /Height ${height} ` +
        `/ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /DCTDecode /Length ${jpg.length} >>\nstream\n`);
      push(jpg);
      push('\nendstream');
    });
  });
  const xref = size;
  const total = 3 + n * 3;
  push(`xref\n0 ${total}\n0000000000 65535 f \n`);
  for (let id = 1; id < total; id++) push(`${String(offsets[id]).padStart(10, '0')} 00000 n \n`);
  push(`trailer\n<< /Size ${total} /Root 1 0 R >>\nstartxref\n${xref}\n%%EOF\n`);
  return Buffer.concat(chunks);
}

function findChrome(arg) {
  const candidates = [
    arg,
    process.env.CHROME,
    'C:/Program Files/Google/Chrome/Application/chrome.exe',
    'C:/Program Files (x86)/Google/Chrome/Application/chrome.exe',
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    '/usr/bin/google-chrome',
  ].filter(Boolean);
  const found = candidates.find((c) => fs.existsSync(c));
  if (!found) throw new Error('Chrome not found; pass its path as the first argument.');
  return found;
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const chrome = findChrome(process.argv[2]);
  const profile = fs.mkdtempSync(path.join(os.tmpdir(), 'paper-chrome-'));
  const url = pathToFileURL(path.join(here, 'paper.html')).href;
  const started = Date.now();
  const dom = execFileSync(chrome, [
    '--headless=new', '--disable-gpu', '--no-first-run', '--no-default-browser-check',
    `--user-data-dir=${profile}`, '--allow-file-access-from-files',
    '--virtual-time-budget=20000', '--dump-dom', url,
  ], {maxBuffer: 256 * 1024 * 1024, encoding: 'utf8'});
  fs.rmSync(profile, {recursive: true, force: true});
  const m = dom.match(/<pre id="out"[^>]*>([\s\S]*?)<\/pre>/);
  if (!m || !m[1].trim()) throw new Error('paper.html wrote no pages');
  const {width, height, pages} = JSON.parse(m[1].replace(/&quot;/g, '"').replace(/&amp;/g, '&'));
  const jpegs = pages.map((u) => Buffer.from(u.split(',')[1], 'base64'));
  fs.mkdirSync(outDir, {recursive: true});
  const pdf = pdfOfJpegs(jpegs, width, height);
  fs.writeFileSync(path.join(outDir, `${PAPER.code}.pdf`), pdf);
  const truth = truthOf(PAPER);
  fs.writeFileSync(path.join(outDir, `${PAPER.code}.truth.json`), JSON.stringify(truth, null, 2) + '\n');
  console.log(`${pages.length} pages, ${(pdf.length / 1024 / 1024).toFixed(1)} MB, ` +
    `${truth.questions.length} questions, ${((Date.now() - started) / 1000).toFixed(1)} s`);
}
