// Fetches the files of the paper reader's PaddleOCR engine into web/ocr/
// (docs/PLAN.md, Build 1C, Must 3). They are not in git (about 31 MB); the
// deploy and emulator scripts run this first. Every file is pinned by
// version and checked by its SHA-256; a file already in place with the
// right fingerprint is not fetched again.
//
//   node scripts/fetch_paper_ocr.mjs
//
// - onnxruntime-web 1.31.1 (Microsoft, MIT): ort.wasm.min.js and its
//   single-file WebAssembly runtime, from the npm registry tarball.
// - PP-OCRv5 mobile text recognition (PaddlePaddle, Apache-2.0):
//   inference.onnx and the character list from inference.yml, from
//   huggingface.co/PaddlePaddle/PP-OCRv5_mobile_rec_onnx at a fixed commit.

import {createHash} from 'node:crypto';
import {execFileSync} from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const out = path.join(root, 'web', 'ocr');

const ORT = {
  url: 'https://registry.npmjs.org/onnxruntime-web/-/onnxruntime-web-1.31.1.tgz',
  sha256: 'bdccdb9fbb9ab537247c0c734e9b1d2b1b338b4f2a09faa58f0dc1cfa27c312c',
  files: {
    'ort.wasm.min.js': 'b8a78c408c40da65fdc8ba0846f7b2948e92a4c6d6b23cc8e4165e428ad95443',
    'ort-wasm-simd-threaded.wasm': '4b884c203b0fa48d057be3332c65513ff85aa3c5bddd6946acc0fab7ecda001d',
    'ort-wasm-simd-threaded.mjs': '30ed0b5cd1182ede931fea448afb567d4dc705ec957af09f108a2be5f770dac3',
  },
};
const HF = 'https://huggingface.co/PaddlePaddle/PP-OCRv5_mobile_rec_onnx/resolve/ed152b8b495f84de93cda5709d768548a9127622';
const MODEL = {
  url: `${HF}/inference.onnx`,
  name: 'ppocr_v5_mobile_rec.onnx',
  sha256: 'da72dc72ca4dc220df0dfde68c1dedc31c58d3e76a25871122e5056227d50092',
};
const YML = {
  url: `${HF}/inference.yml`,
  sha256: '5dfeb2777f6d0db8177d8128a8acfcf6e6276dc4ac73ea3bf0dc06d6a5e85d8e',
};
const DICT = {
  name: 'ppocr_v5_dict.json',
  sha256: '02c0a0121c577dfa211f11de21084e3abd23478a77ea4fbdf71ee7a3e990a717',
};

const sha = (buf) => createHash('sha256').update(buf).digest('hex');
const okFile = (file, want) => fs.existsSync(file) && sha(fs.readFileSync(file)) === want;

async function download(url, want) {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`${url}: HTTP ${res.status}`);
  const buf = Buffer.from(await res.arrayBuffer());
  const got = sha(buf);
  if (got !== want) throw new Error(`${url}: SHA-256 ${got}, expected ${want}`);
  return buf;
}

/** The character list (PostProcess.character_dict) of inference.yml. */
export function dictFromYml(text) {
  const lines = text.split(/\r?\n/);
  let i = lines.findIndex((l) => l.trim() === 'character_dict:');
  if (i < 0) throw new Error('inference.yml has no character_dict');
  const chars = [];
  for (i++; i < lines.length; i++) {
    const m = /^  - (.*)$/.exec(lines[i]);
    if (!m) break;
    let v = m[1];
    if (v.startsWith("'") && v.endsWith("'")) v = v.slice(1, -1).replace(/''/g, "'");
    else if (v.startsWith('"') && v.endsWith('"')) v = JSON.parse(v);
    chars.push(v);
  }
  return chars;
}

fs.mkdirSync(out, {recursive: true});
let fetched = 0;

if (!Object.entries(ORT.files).every(([n, h]) => okFile(path.join(out, n), h))) {
  const tgz = await download(ORT.url, ORT.sha256);
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'ort-'));
  const tgzPath = path.join(tmp, 'ort.tgz');
  fs.writeFileSync(tgzPath, tgz);
  execFileSync('tar', ['-xzf', 'ort.tgz', ...Object.keys(ORT.files).map((n) => `package/dist/${n}`)],
      {cwd: tmp});
  for (const [n, h] of Object.entries(ORT.files)) {
    const buf = fs.readFileSync(path.join(tmp, 'package', 'dist', n));
    if (sha(buf) !== h) throw new Error(`${n}: unexpected SHA-256`);
    fs.writeFileSync(path.join(out, n), buf);
  }
  fs.rmSync(tmp, {recursive: true, force: true});
  fetched++;
}

if (!okFile(path.join(out, MODEL.name), MODEL.sha256)) {
  fs.writeFileSync(path.join(out, MODEL.name), await download(MODEL.url, MODEL.sha256));
  fetched++;
}

if (!okFile(path.join(out, DICT.name), DICT.sha256)) {
  const yml = await download(YML.url, YML.sha256);
  const json = JSON.stringify(dictFromYml(yml.toString('utf8')));
  if (sha(Buffer.from(json)) !== DICT.sha256) throw new Error('character list: unexpected SHA-256');
  fs.writeFileSync(path.join(out, DICT.name), json);
  fetched++;
}

fs.writeFileSync(path.join(out, 'NOTICE.txt'), `Files of the paper reader's text engine (scripts/fetch_paper_ocr.mjs).

ort.wasm.min.js, ort-wasm-simd-threaded.wasm, ort-wasm-simd-threaded.mjs:
  onnxruntime-web 1.31.1, Copyright (c) Microsoft Corporation, MIT License.
  https://github.com/microsoft/onnxruntime

ppocr_v5_mobile_rec.onnx, ppocr_v5_dict.json:
  PP-OCRv5_mobile_rec (ONNX), PaddlePaddle authors, Apache License 2.0.
  https://huggingface.co/PaddlePaddle/PP-OCRv5_mobile_rec_onnx
  The character list is the model's own (inference.yml, PostProcess).
`);

console.log(fetched ? `paper OCR files: ${fetched} fetched into web/ocr` : 'paper OCR files: up to date');
