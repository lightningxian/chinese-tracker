// Fetches the files of the listening-script writer into web/asr/ (owner
// 2026-11-24, Q7: "generate the listening scripts"). Speech recognition runs
// in the admin's browser like the paper reader: nothing is sent to an outside
// service. The files are not in git (about 280 MB); the deploy and emulator
// scripts run this first. Every file is pinned by version and checked by its
// SHA-256; a file already in place with the right fingerprint is not fetched
// again. The browser downloads them once and keeps them in its cache.
//
//   node scripts/fetch_whisper.mjs
//
// - transformers.js 4.3.2 (Hugging Face, Apache-2.0): transformers.min.js.
// - onnxruntime-web 1.31.0-dev.20260914 (Microsoft, MIT): the asyncify
//   WebAssembly runtime transformers.js 4.3.2 is built against.
// - Whisper small (OpenAI, MIT; ONNX export by onnx-community): the 8-bit
//   encoder and merged decoder, the tokenizer and the configs, at a fixed
//   commit.
// - opencc-js 1.0.5 (MIT): traditional → simplified characters for the
//   text Whisper writes.

import {createHash} from 'node:crypto';
import {execFileSync} from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const out = path.join(root, 'web', 'asr');

/** npm tarballs: {url, sha256, files: {published name: [path in tarball, sha256]}} */
const TARBALLS = [
  {
    url: 'https://registry.npmjs.org/@huggingface/transformers/-/transformers-4.3.2.tgz',
    sha256: '5414fb47b11ae2a8c10a3aac68f833e6fb6e9bde03e9e612ad7da3ea9e9d2663',
    files: {
      'transformers.min.js': ['package/dist/transformers.min.js',
        '8b5a3171f8876bab2b1820a7d65eb87628e3d30bb5ea85b9dd398e76eb34decb'],
    },
  },
  {
    url: 'https://registry.npmjs.org/onnxruntime-web/-/onnxruntime-web-1.31.0-dev.20260914-8d85527a0.tgz',
    sha256: '0de27582f3e3189dec4a2082513a0af1ea79ae7fd3039bbfe634a526e173cbe0',
    files: {
      'ort-wasm-simd-threaded.asyncify.mjs': ['package/dist/ort-wasm-simd-threaded.asyncify.mjs',
        '0966b6105cd936744498aa60df7a22cbd47af3374dbc64a9ab561c08a71e3611'],
      'ort-wasm-simd-threaded.asyncify.wasm': ['package/dist/ort-wasm-simd-threaded.asyncify.wasm',
        '49871f5a4409519797e127440868a6d1923339d9185907f301a5b2a1d90af082'],
    },
  },
  {
    url: 'https://registry.npmjs.org/opencc-js/-/opencc-js-1.0.5.tgz',
    sha256: '40fc09c707fac99d6df9112850872ee38281220f480809962086e101c697f552',
    files: {
      'opencc-t2cn.js': ['package/dist/umd/t2cn.js',
        'dd83e327be1845bf30cae59b5c4a365f2ea883fcf4934080caf340e356243707'],
    },
  },
];

const HF = 'https://huggingface.co/onnx-community/whisper-small/resolve/36050c46d777d46dc4b5f43f6d90574fc38f8732';
const MODEL_DIR = path.join('models', 'onnx-community', 'whisper-small');
const MODEL_FILES = {
  'config.json': '457854d452f17661e197d74aee12b8e74fb75ba30ebfaa7426d0d61ea1e08a18',
  'generation_config.json': 'f538b28220c6a6d6f1af1458d4141cacb4ef4963df3de98a19490440c412ddf0',
  'preprocessor_config.json': 'a6a76d28c93edb273669eb9e0b0636a2bddbb1272c3261e47b7ca6dfdbac1b8d',
  'tokenizer.json': '27fc476bfe7f17299480be2273fc0608e4d5a99aba2ab5dec5374b4482d1a566',
  'tokenizer_config.json': '2a4c4281cf9f51ac6ccc406fdc711a087afe6530f671fa7b80953edc498275ce',
  'onnx/encoder_model_quantized.onnx': 'a43a83f3c5361cd591cfa7c36f14b43cf7cb22f47a415cc14a8d557be800fa92',
  'onnx/decoder_model_merged_quantized.onnx': 'ec07c3cbb64172c39791e26ee870a65ac22b458c36722bfe2776b3dbf741e0c9',
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

fs.mkdirSync(out, {recursive: true});
let fetched = 0;

for (const t of TARBALLS) {
  if (Object.entries(t.files).every(([n, [, h]]) => okFile(path.join(out, n), h))) continue;
  const tgz = await download(t.url, t.sha256);
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'asr-'));
  fs.writeFileSync(path.join(tmp, 'pkg.tgz'), tgz);
  execFileSync('tar', ['-xzf', 'pkg.tgz', ...Object.values(t.files).map(([p]) => p)], {cwd: tmp});
  for (const [n, [p, h]] of Object.entries(t.files)) {
    const buf = fs.readFileSync(path.join(tmp, ...p.split('/')));
    if (sha(buf) !== h) throw new Error(`${n}: unexpected SHA-256`);
    fs.writeFileSync(path.join(out, n), buf);
  }
  fs.rmSync(tmp, {recursive: true, force: true});
  fetched++;
}

for (const [name, h] of Object.entries(MODEL_FILES)) {
  const file = path.join(out, MODEL_DIR, ...name.split('/'));
  if (okFile(file, h)) continue;
  fs.mkdirSync(path.dirname(file), {recursive: true});
  console.log(`  downloading ${name}…`);
  fs.writeFileSync(file, await download(`${HF}/${name}`, h));
  fetched++;
}

fs.writeFileSync(path.join(out, 'NOTICE.txt'), `Files of the listening-script writer (scripts/fetch_whisper.mjs).

transformers.min.js:
  transformers.js 4.3.2, Hugging Face, Apache License 2.0.
  https://github.com/huggingface/transformers.js

ort-wasm-simd-threaded.asyncify.mjs, ort-wasm-simd-threaded.asyncify.wasm:
  onnxruntime-web 1.31.0-dev.20260914, Copyright (c) Microsoft Corporation, MIT License.
  https://github.com/microsoft/onnxruntime

models/onnx-community/whisper-small/:
  Whisper small, OpenAI, MIT License (https://github.com/openai/whisper);
  ONNX export by onnx-community (https://huggingface.co/onnx-community/whisper-small).

opencc-t2cn.js:
  opencc-js 1.0.5, MIT License (https://github.com/nk2028/opencc-js).
`);

console.log(fetched ? `listening-script files: ${fetched} fetched into web/asr` : 'listening-script files: up to date');
