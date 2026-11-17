"use strict";

/**
 * Typing answer matcher (thesis spec section 7, Build 2A). Pure: no
 * Firebase, so `node functions/test_typing_matcher.js` runs it alone.
 *
 * Hanzi: trim, full-width to half-width, spaces out, ending punctuation
 * out, traditional to simplified (opencc-js). Exact match against any key
 * is full credit; one character off with similarity >= 0.75 is half
 * credit and needs a teacher's look; anything else is zero.
 *
 * Pinyin: see pinyin.js. Exact (same syllables, same tones) is full;
 * every syllable right but a tone wrong or missing is half and needs a
 * look; anything else is zero.
 */

const OpenCC = require("opencc-js");
const pinyin = require("./pinyin");

const toSimplified = OpenCC.Converter({from: "t", to: "cn"});

/** Full-width forms (U+FF01..U+FF5E) and the ideographic space to ASCII. */
function toHalfWidth(s) {
  let out = "";
  for (const ch of String(s || "")) {
    const c = ch.codePointAt(0);
    if (c >= 0xff01 && c <= 0xff5e) out += String.fromCodePoint(c - 0xfee0);
    else if (c === 0x3000) out += " ";
    else out += ch;
  }
  return out;
}

/** Chinese punctuation that has no full-width twin, to its ASCII form. */
const CJK_PUNCT = {"。": ".", "、": ",", "「": "\"", "」": "\"", "『": "\"",
  "』": "\"", "“": "\"", "”": "\"", "‘": "'", "’": "'", "《": "<", "》": ">",
  "…": "..."};

const ENDING = /[.,!?;:"'~\s]+$/;

/**
 * A typed hanzi answer or key in the form the matcher compares.
 * @param {string} text
 * @return {string}
 */
function normalizeHanzi(text) {
  let s = toHalfWidth(text);
  s = Array.from(s).map((ch) => CJK_PUNCT[ch] || ch).join("");
  s = s.replace(/\s+/g, "");
  s = s.replace(ENDING, "");
  return toSimplified(s);
}

/** Edit distance between two lists (characters or syllables). */
function levenshtein(a, b) {
  const m = a.length;
  const n = b.length;
  let prev = Array.from({length: n + 1}, (_, j) => j);
  for (let i = 1; i <= m; i++) {
    const cur = [i];
    for (let j = 1; j <= n; j++) {
      const cost = a[i - 1] === b[j - 1] ? 0 : 1;
      cur[j] = Math.min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost);
    }
    prev = cur;
  }
  return prev[n];
}

/** S = 1 - d / n, n the longer length (1 for two empty lists). */
function similarity(a, b, d) {
  const n = Math.max(a.length, b.length);
  return n === 0 ? 1 : 1 - d / n;
}

const FULL = {credit: 1, review: false, reason: "exact"};
const ZERO = {credit: 0, review: false, reason: "wrong"};

/** Accepted keys as a list of non-empty strings. */
function keyList(keys) {
  return (Array.isArray(keys) ? keys : [keys])
      .map((k) => String(k || "")).filter((k) => k.trim());
}

/**
 * Typed hanzi (T2, T3) against every accepted key.
 * @param {string} answer
 * @param {string|string[]} keys
 * @return {{credit: number, review: boolean, reason: string}}
 */
function matchHanzi(answer, keys) {
  const typed = Array.from(normalizeHanzi(answer));
  if (!typed.length) return ZERO;
  let best = ZERO;
  for (const key of keyList(keys)) {
    const want = Array.from(normalizeHanzi(key));
    const d = levenshtein(typed, want);
    if (d === 0) return FULL;
    if (d === 1 && similarity(typed, want, d) >= 0.75) {
      best = {credit: 0.5, review: true, reason: "one_character"};
    }
  }
  return best;
}

/**
 * Typed pinyin (T1) against every accepted key. A key typed without any
 * tone is compared on the letters only.
 * @param {string} answer
 * @param {string|string[]} keys
 * @return {{credit: number, review: boolean, reason: string}}
 */
function matchPinyin(answer, keys) {
  const typed = pinyin.parse(answer);
  if (!typed.length) return ZERO;
  let best = ZERO;
  for (const key of keyList(keys)) {
    const want = pinyin.parse(key);
    if (want.length !== typed.length) continue;
    const sameLetters = want.every((s, i) => s.base === typed[i].base);
    if (!sameLetters) continue;
    const keyHasTones = want.some((s) => s.tone);
    const sameTones = want.every((s, i) => s.tone === typed[i].tone);
    if (!keyHasTones || sameTones) return FULL;
    best = {credit: 0.5, review: true, reason: "tone"};
  }
  return best;
}

module.exports = {
  toHalfWidth,
  normalizeHanzi,
  levenshtein,
  similarity,
  matchHanzi,
  matchPinyin,
  pinyin,
};
