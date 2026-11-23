"use strict";

/**
 * Build 3 (docs/PLAN.md §4): placement tests as pure logic. A placement
 * result recommends a starting level; a visitor (no account) sits a short
 * paper behind a teacher's token and gets a result code to register with.
 * index.js reads and writes the documents. Spec: PL-01, PL-02
 * (docs/THESIS_FEATURE_BACKLOG.md §3, §8).
 */

const crypto = require("crypto");

const LEVELS = ["1", "2", "3", "4", "5", "6"];
// Same alphabet as test tokens: no 0/O, no 1/I.
const CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
const RESULT_CODE_LENGTH = 6;

/** `HSK 3`, `hsk3`, `3` → `3`; anything else → "". */
function levelKeyOf(level) {
  const m = /(\d)/.exec(String(level || ""));
  return m && LEVELS.includes(m[1]) ? m[1] : "";
}

/**
 * The level a placement paper recommends: passed = the paper's level + 1
 * (HSK 6 stays HSK 6), failed = the paper's level. "" for a paper with no
 * HSK level.
 * @param {string} paperLevel `HSK 3` or `3`
 * @param {boolean} passed
 * @return {string} the level key (`4`) or ""
 */
function recommendedKey(paperLevel, passed) {
  const key = levelKeyOf(paperLevel);
  if (!key) return "";
  if (!passed) return key;
  const i = LEVELS.indexOf(key);
  return LEVELS[Math.min(i + 1, LEVELS.length - 1)];
}

/**
 * The recommendation for a signed-in student, or null when it would not
 * move them (it equals their current level) or the paper has no level.
 * @param {string} currentLevel the student's `users.level`
 * @param {string} paperLevel the result's level
 * @param {boolean} passed
 * @return {{fromKey: string, toKey: string}|null}
 */
function recommendationFor(currentLevel, paperLevel, passed) {
  const toKey = recommendedKey(paperLevel, passed);
  if (!toKey) return null;
  const fromKey = levelKeyOf(currentLevel) || "1";
  if (fromKey === toKey) return null;
  return {fromKey, toKey};
}

/** A result code: 6 characters, no 0/O/1/I. */
function makeResultCode(randomInt) {
  let out = "";
  for (let i = 0; i < RESULT_CODE_LENGTH; i++) {
    out += CODE_ALPHABET[randomInt(CODE_ALPHABET.length)];
  }
  return out;
}

/** Upper case, spaces and dashes dropped; "" when it cannot be a code. */
function normalizeResultCode(raw) {
  const v = String(raw || "").toUpperCase().replace(/[\s-]/g, "");
  if (v.length !== RESULT_CODE_LENGTH) return "";
  for (const ch of v) if (!CODE_ALPHABET.includes(ch)) return "";
  return v;
}

/** A random 128-bit key (hex), returned to the visitor once. */
function makeVisitorKey(randomBytes = crypto.randomBytes) {
  return randomBytes(16).toString("hex");
}

/** SHA-256 of a visitor key (only the hash is stored). */
function hashKey(key) {
  return crypto.createHash("sha256").update(`placement:${String(key || "")}`)
      .digest("hex");
}

/** Whether [key] belongs to [keyHash], in constant time. */
function keyMatches(key, keyHash) {
  if (typeof key !== "string" || !/^[0-9a-f]{32}$/.test(key)) return false;
  const a = Buffer.from(hashKey(key), "hex");
  const b = Buffer.from(String(keyHash || ""), "hex");
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}

/** The visitor's name: trimmed, 2 to 80 characters, or "". */
function cleanVisitorName(raw) {
  const v = String(raw || "").replace(/\s+/g, " ").trim();
  return v.length >= 2 && v.length <= 80 ? v : "";
}

/**
 * A WhatsApp number: digits with an optional leading +, 8 to 15 digits
 * (spaces and dashes dropped), or "".
 */
function cleanWhatsapp(raw) {
  const v = String(raw || "").replace(/[\s().-]/g, "");
  if (!/^\+?\d{8,15}$/.test(v)) return "";
  return v;
}

/** The start-screen facts of a placement code for the public menu. */
function menuEntry(codeId, code, format, questionCounts) {
  return {
    codeId,
    code: code.code || codeId,
    level: code.level || "",
    title: String(code.title || "").trim(),
    parts: (format.parts || []).map((p, i) => ({
      skill: p.skill,
      minutes: p.minutes,
      questions: Number((questionCounts || [])[i]) || p.questions || 0,
    })),
    minutes: (format.parts || []).reduce((s, p) => s + (Number(p.minutes) || 0), 0),
  };
}

/**
 * Follow-up 2026-11-23 (privacy): a visitor's name and WhatsApp number on a
 * placement result nobody claimed are cleared after [days] (default 180).
 * The marks stay for the item analysis; a claimed result belongs to a
 * student account and is kept.
 * @param {Object} r the result {name, whatsapp, claimedBy, finishedAtMs}
 */
const RETENTION_DAYS = 180;
function retentionDue(r, nowMs, days = RETENTION_DAYS) {
  if (r.claimedBy) return false;
  if (!r.name && !r.whatsapp) return false;
  const at = Number(r.finishedAtMs) || 0;
  return at > 0 && nowMs - at >= Number(days) * 86400000;
}

module.exports = {
  RETENTION_DAYS,
  retentionDue,
  CODE_ALPHABET,
  RESULT_CODE_LENGTH,
  levelKeyOf,
  recommendedKey,
  recommendationFor,
  makeResultCode,
  normalizeResultCode,
  makeVisitorKey,
  hashKey,
  keyMatches,
  cleanVisitorName,
  cleanWhatsapp,
  menuEntry,
};
