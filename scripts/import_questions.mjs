#!/usr/bin/env node
// Build 8 (docs/PLAN.md §4, Must 5): import the owner's own digital
// questions (CSV or JSON) into the question bank, with their audio and
// pictures in Storage. No invented Chinese content: the script only copies
// what the file holds. Official papers are never committed; keep the source
// files outside the repo (or in the git-ignored local_papers/).
//
//   node scripts/import_questions.mjs <file.csv|file.json> --dry-run [--emulator]
//   node scripts/import_questions.mjs <file> --emulator --owner <adminUid>
//   node scripts/import_questions.mjs <file> --credentials <sa.json> --owner <adminUid>
//
// Columns (CSV header, or the keys of each JSON object):
//   sheet_code   worksheet code, e.g. H3TRIAL-L (one worksheet = one code)  required
//   sheet_title  worksheet title                                             optional
//   index        1-based position in the worksheet                          required
//   level        HSK 1 .. HSK 6                                              required
//   category     exercise | quiz | exam | hsk_simulation (default exercise)
//   type         multiple_choice | listening | reading_cloze | matching |
//                compose_sentences | type_hanzi | type_pinyin |
//                picture_sentence | essay                                    required
//   skill        listening | reading | typing (default from the type)
//   section      part heading, e.g. 第一部分
//   prompt       the question text                                          required
//   options      answers separated by |  (choices, or accepted typed answers)
//   correct      A-D or 1-based number (choice types)
//   keyword      pinyin (type_hanzi) or the keyword (picture_sentence)
//   segments     compose_sentences pieces separated by |
//   explanation  shown only with the review
//   audio        path to a local audio file (relative to the input file)
//   image        path to a local picture file
//
// Doc ids are fixed (imp_<sheet_code>_<index>), so a second run updates the
// same questions instead of adding copies.
import {createRequire} from "node:module";
import {existsSync, readFileSync} from "node:fs";
import {basename, dirname, extname, join, resolve} from "node:path";
import {randomUUID} from "node:crypto";
import {fileURLToPath} from "node:url";

const TYPES = ["multiple_choice", "listening", "reading_cloze", "matching", "compose_sentences",
  "type_hanzi", "type_pinyin", "picture_sentence", "essay"];
const CATEGORIES = ["exercise", "quiz", "exam", "hsk_simulation"];
const CHOICE = ["multiple_choice", "listening", "reading_cloze", "matching"];
const SKILL_OF = {listening: "listening", type_hanzi: "typing", type_pinyin: "typing",
  picture_sentence: "typing", essay: "typing", compose_sentences: "typing"};

/** Parses CSV text with quotes; returns objects by header. */
export function parseCsv(text) {
  const rows = [];
  let row = [];
  let cell = "";
  let quoted = false;
  const s = text.replace(/^﻿/, "");
  for (let i = 0; i < s.length; i += 1) {
    const c = s[i];
    if (quoted) {
      if (c === "\"" && s[i + 1] === "\"") {
        cell += "\"";
        i += 1;
      } else if (c === "\"") quoted = false;
      else cell += c;
    } else if (c === "\"") quoted = true;
    else if (c === ",") {
      row.push(cell);
      cell = "";
    } else if (c === "\n" || c === "\r") {
      if (c === "\r" && s[i + 1] === "\n") i += 1;
      row.push(cell);
      cell = "";
      if (row.some((x) => x.trim())) rows.push(row);
      row = [];
    } else cell += c;
  }
  row.push(cell);
  if (row.some((x) => x.trim())) rows.push(row);
  const head = rows[0].map((h) => h.trim().toLowerCase());
  return rows.slice(1).map((r) => Object.fromEntries(head.map((h, i) => [h, (r[i] ?? "").trim()])));
}

const split = (v) => String(v ?? "").split("|").map((x) => x.trim()).filter(Boolean);

/** Validates one row and builds the bank doc (without Storage URLs). */
export function toBankDoc(row, n, ownerId) {
  const err = (m) => {
    throw new Error(`row ${n}: ${m}`);
  };
  const type = String(row.type || "").trim();
  if (!TYPES.includes(type)) err(`type "${type}" is not one of ${TYPES.join(", ")}`);
  const sheetCode = String(row.sheet_code || "").trim();
  if (!sheetCode) err("sheet_code is required");
  const index = Number(row.index);
  if (!Number.isInteger(index) || index < 1) err("index must be 1, 2, 3, …");
  const level = String(row.level || "").trim();
  if (!/^HSK [1-6]$/.test(level)) err(`level "${level}" must be HSK 1 .. HSK 6`);
  const category = String(row.category || "exercise").trim();
  if (!CATEGORIES.includes(category)) err(`category "${category}"`);
  const prompt = String(row.prompt || "").trim();
  if (!prompt && type !== "compose_sentences") err("prompt is required");
  const options = split(row.options);
  const question = {prompt};
  if (CHOICE.includes(type)) {
    if (options.length < 2) err("a choice question needs 2 or more options (a|b|c)");
    const c = String(row.correct || "").trim().toUpperCase();
    const correctIndex = /^[A-Z]$/.test(c) ? c.charCodeAt(0) - 65 : Number(c) - 1;
    if (!Number.isInteger(correctIndex) || correctIndex < 0 || correctIndex >= options.length) {
      err(`correct "${row.correct}" is not one of the options`);
    }
    Object.assign(question, {options, correctIndex});
  } else if (type === "compose_sentences") {
    const segments = split(row.segments);
    if (segments.length < 2) err("compose_sentences needs segments (a|b|c)");
    question.segments = segments;
  } else if (type === "type_hanzi" || type === "type_pinyin") {
    if (!options.length) err("a typing question needs the accepted answers in options");
    question.options = options;
    if (type === "type_hanzi") question.keyword = String(row.keyword || "").trim();
  } else if (type === "picture_sentence") {
    question.keyword = String(row.keyword || "").trim();
    if (!question.keyword) err("picture_sentence needs a keyword");
  } else if (type === "essay") {
    question.keywords = split(row.keyword);
  }
  const explanation = String(row.explanation || "").trim();
  if (explanation) question.explanation = explanation;
  const id = `imp_${sheetCode.replace(/[^A-Za-z0-9_-]/g, "_")}_${String(index).padStart(3, "0")}`;
  return {
    id,
    audio: String(row.audio || "").trim(),
    image: String(row.image || "").trim(),
    doc: {
      ownerId, type, prompt, question,
      skillCategory: String(row.skill || "").trim() || SKILL_OF[type] || "reading",
      level, category, tags: [sheetCode],
      sheetCode, sheetTitle: String(row.sheet_title || "").trim() || sheetCode,
      sheetIndex: index - 1,
      ...(String(row.section || "").trim() ? {section: String(row.section).trim()} : {}),
      usageCount: 0, createdBy: ownerId, importedFrom: "",
    },
  };
}

export function loadRows(file) {
  const text = readFileSync(file, "utf8");
  if (extname(file).toLowerCase() === ".json") {
    const data = JSON.parse(text);
    return Array.isArray(data) ? data : data.questions || [];
  }
  return parseCsv(text);
}

async function main() {
  const args = process.argv.slice(2);
  const file = args.find((a) => !a.startsWith("--") && !args[args.indexOf(a) - 1]?.startsWith("--o") &&
    !args[args.indexOf(a) - 1]?.startsWith("--c"));
  const opt = (n) => (args.includes(n) ? args[args.indexOf(n) + 1] : null);
  const DRY = args.includes("--dry-run");
  const EMULATOR = args.includes("--emulator");
  if (!file || !existsSync(file)) {
    console.error("usage: node scripts/import_questions.mjs <file.csv|file.json> " +
      "[--dry-run] [--emulator | --credentials sa.json] --owner <adminUid>");
    process.exit(2);
  }
  const owner = opt("--owner") || "";
  if (!DRY && !owner) {
    console.error("--owner <adminUid> is required to write (the bank owner).");
    process.exit(2);
  }
  const base = dirname(resolve(file));
  const built = [];
  const errors = [];
  loadRows(file).forEach((row, i) => {
    try {
      const b = toBankDoc(row, i + 2, owner || "(owner)");
      b.doc.importedFrom = basename(file);
      for (const k of ["audio", "image"]) {
        if (b[k] && !existsSync(join(base, b[k]))) throw new Error(`row ${i + 2}: ${k} file ${b[k]} not found`);
      }
      built.push(b);
    } catch (e) {
      errors.push(e.message);
    }
  });
  const ids = new Set();
  for (const b of built) {
    if (ids.has(b.id)) errors.push(`${b.id}: the same sheet_code and index twice`);
    ids.add(b.id);
  }
  const bySheet = {};
  for (const b of built) bySheet[b.doc.sheetCode] = (bySheet[b.doc.sheetCode] || 0) + 1;
  console.log(`${built.length} questions in ${Object.keys(bySheet).length} worksheets: ` +
    Object.entries(bySheet).map(([k, v]) => `${k} (${v})`).join(", "));
  console.log(`audio files: ${built.filter((b) => b.audio).length}, pictures: ` +
    `${built.filter((b) => b.image).length}`);
  if (errors.length) {
    console.error(`${errors.length} problems:\n- ${errors.join("\n- ")}`);
    process.exit(1);
  }
  if (DRY) {
    for (const b of built.slice(0, 5)) console.log(`would write question_bank/${b.id}`);
    if (built.length > 5) console.log(`… and ${built.length - 5} more`);
    console.log("DRY RUN — nothing written.");
    return;
  }

  const require = createRequire(join(dirname(fileURLToPath(import.meta.url)), "..", "functions",
      "package.json"));
  if (EMULATOR) {
    process.env.FIRESTORE_EMULATOR_HOST ||= "127.0.0.1:8080";
    process.env.FIREBASE_STORAGE_EMULATOR_HOST ||= "127.0.0.1:9199";
  } else {
    const cred = opt("--credentials");
    if (!cred || !existsSync(cred)) {
      console.error("Live writes need --credentials <service-account.json>.");
      process.exit(2);
    }
    process.env.GOOGLE_APPLICATION_CREDENTIALS = cred;
  }
  const {initializeApp, applicationDefault} = require("firebase-admin/app");
  const {getFirestore, FieldValue} = require("firebase-admin/firestore");
  const {getStorage} = require("firebase-admin/storage");
  const bucketName = "chinese-tracker.firebasestorage.app";
  initializeApp({projectId: "chinese-tracker", storageBucket: bucketName,
    ...(EMULATOR ? {} : {credential: applicationDefault()})});
  const db = getFirestore();
  const bucket = getStorage().bucket();
  const upload = async (local, id) => {
    const token = randomUUID();
    const dest = `question_bank_media/${owner}/${id}_${basename(local)}`;
    await bucket.upload(join(base, local), {destination: dest,
      metadata: {metadata: {firebaseStorageDownloadTokens: token}}});
    const host = EMULATOR ? `http://${process.env.FIREBASE_STORAGE_EMULATOR_HOST}` :
      "https://firebasestorage.googleapis.com";
    return `${host}/v0/b/${bucketName}/o/${encodeURIComponent(dest)}?alt=media&token=${token}`;
  };
  for (const b of built) {
    if (b.audio) b.doc.question.audioUrl = await upload(b.audio, b.id);
    if (b.image) b.doc.question.imageUrl = await upload(b.image, b.id);
    await db.collection("question_bank").doc(b.id).set({...b.doc,
      updatedAt: FieldValue.serverTimestamp(), createdAt: FieldValue.serverTimestamp()},
    {merge: true});
  }
  console.log(`wrote ${built.length} questions (${EMULATOR ? "emulator" : "LIVE"}).`);
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) {
  main().catch((e) => {
    console.error(e.message);
    process.exit(1);
  });
}
