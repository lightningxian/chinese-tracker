"use strict";

/**
 * Pure helpers for the supervised test track (PLAN.md §3, Build 1): test
 * codes, session tokens, part clocks and HSK-style marks. No Firebase here,
 * so `node functions/test_supervised_test.js` runs them without an emulator.
 *
 * A test code points at one bank worksheet and carries a copy of a format:
 * `parts[]` of `{skill, questions, minutes, maxScore}` plus `passMark`. The
 * worksheet's questions are split into the parts by their skill, in
 * worksheet order. Each part has its own clock; a part's mark is
 * earned ÷ possible × the part's maxScore, rounded.
 */

const play = require("./exercise_play");

/** Token alphabet: no 0/O and no 1/I, so a token read aloud is unambiguous. */
const TOKEN_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
const TOKEN_LENGTH = 6;
const JOIN_WINDOW_SECONDS = 15 * 60;

/** Part skills of a format; `writing` is stored as `typing` on bank items. */
const PART_SKILLS = new Set(["listening", "reading", "writing", "speaking"]);

/**
 * A random token from {@link TOKEN_ALPHABET}.
 * @param {function(number): number} randomInt returns 0 ≤ n < max
 * @return {string}
 */
function makeToken(randomInt) {
  let out = "";
  for (let i = 0; i < TOKEN_LENGTH; i++) {
    out += TOKEN_ALPHABET[randomInt(TOKEN_ALPHABET.length)];
  }
  return out;
}

/** Upper-cases and strips spaces; null when it cannot be a token. */
function normalizeToken(raw) {
  const t = String(raw || "").replace(/\s+/g, "").toUpperCase();
  if (t.length !== TOKEN_LENGTH) return null;
  for (const ch of t) {
    if (!TOKEN_ALPHABET.includes(ch)) return null;
  }
  return t;
}

/** Test codes are typed by the admin: trimmed, upper case, no spaces. */
function normalizeTestCode(raw) {
  return String(raw || "").trim().toUpperCase().replace(/\s+/g, "");
}

/** Part skill a bank item counts for (missing = reading). */
function partSkillOf(item) {
  const s = String(item.skillCategory || "reading");
  if (s === "typing") return "writing";
  return PART_SKILLS.has(s) ? s : "reading";
}

/**
 * The format copy of a test code, cleaned: whole minutes ≥ 1, marks ≥ 0.
 * @param {Object} format `{parts, passMark}`
 * @return {{parts: Array<{skill: string, questions: number, minutes: number,
 *   maxScore: number}>, passMark: number}}
 */
function cleanFormat(format) {
  const f = format && typeof format === "object" ? format : {};
  const parts = (Array.isArray(f.parts) ? f.parts : [])
      .map((p) => ({
        skill: PART_SKILLS.has(String(p && p.skill)) ? String(p.skill) : "reading",
        questions: Math.max(0, Math.round(Number(p && p.questions) || 0)),
        minutes: Math.max(1, Math.round(Number(p && p.minutes) || 0)),
        maxScore: Math.max(0, Math.round(Number(p && p.maxScore) || 0)),
      }));
  const passMark = Math.max(0, Math.round(Number(f.passMark) || 0));
  return {parts, passMark};
}

/**
 * Splits ordered worksheet items into the format's parts by skill. When a
 * format has two parts of the same skill, the first takes as many questions
 * as it expects and the rest go to the next one. Items whose skill has no
 * part are left out.
 * @param {Array<Object>} items ordered bank items
 * @param {Array<{skill: string, questions: number}>} parts
 * @return {Array<Array<Object>>} items per part
 */
function splitIntoParts(items, parts) {
  const out = parts.map(() => []);
  for (const it of items) {
    const skill = partSkillOf(it);
    const candidates = parts
        .map((p, i) => ({p, i}))
        .filter(({p}) => p.skill === skill);
    if (!candidates.length) continue;
    const open = candidates.find(({p, i}) =>
      p.questions > 0 && out[i].length < p.questions);
    const target = open || candidates[candidates.length - 1];
    out[target.i].push(it);
  }
  return out;
}

/**
 * Per part: how many questions the format expects and how many the
 * worksheet has (a difference is a warning for the admin, not a block).
 * @param {Array<Object>} items ordered bank items
 * @param {Object} format
 * @return {Array<{skill: string, expected: number, found: number}>}
 */
function partCounts(items, format) {
  const {parts} = cleanFormat(format);
  const split = splitIntoParts(items, parts);
  return parts.map((p, i) => ({
    skill: p.skill, expected: p.questions, found: split[i].length,
  }));
}

/** Points a question is worth (shared with packages: 1, free writing 10). */
const pointsOf = play.pointsOf;

/**
 * Marks of one part: earned ÷ possible × maxScore, rounded. Earned is
 * credit × points (half credit for nearly right typing, Build 2A); a
 * teacher's mark replaces the machine's points for that question.
 * @param {Array<Object>} items the part's bank items
 * @param {Object<string, Object>} answers questionId → answer
 * @param {number} maxScore
 * @param {Object<string, number>} marks questionId → points a teacher gave
 * @return {{earned: number, possible: number, mark: number,
 *   correct: number, total: number, open: number, points: Object}}
 */
function scorePart(items, answers, maxScore, marks = {}) {
  const given = answers && typeof answers === "object" ? answers : {};
  let correct = 0;
  const points = {};
  for (const it of items) {
    const max = pointsOf(it);
    const answered = Object.prototype.hasOwnProperty.call(given, it.id);
    const check = answered ? play.checkAnswer(it, given[it.id]) :
      {credit: 0, review: false, reason: "wrong", correct: false};
    if (check.correct) correct += 1;
    points[it.id] = {earned: check.credit * max, max, review: check.review,
      reason: check.reason};
  }
  const totals = play.totalsOf(points, marks);
  const mark = totals.possible === 0 ? 0 :
    Math.round((totals.earned / totals.possible) * maxScore);
  return {earned: totals.earned, possible: totals.possible, mark, correct,
    total: items.length, open: totals.open, points};
}

/**
 * Scores a whole attempt from the answers stored per part.
 * @param {Array<Array<Object>>} split items per part
 * @param {Object} format cleaned format
 * @param {Object<string, Object<string, Object>>} answersByPart
 *   part index (as string) → questionId → answer
 * @param {boolean} valid
 * @param {Object<string, number>} marks questionId → points a teacher gave
 * @return {{parts: Array<Object>, total: number, max: number,
 *   passMark: number, passed: boolean, open: number, status: string}}
 *   `status` is `pending_marking` while an answer waits for a teacher;
 *   `passed` is then false and decided when the result is final.
 */
function scoreTest(split, format, answersByPart, valid = true, marks = {}) {
  const {parts, passMark} = cleanFormat(format);
  const by = answersByPart && typeof answersByPart === "object" ? answersByPart : {};
  const scored = parts.map((p, i) => ({
    skill: p.skill,
    maxScore: p.maxScore,
    ...scorePart(split[i] || [], by[String(i)] || {}, p.maxScore, marks),
  }));
  const total = scored.reduce((s, p) => s + p.mark, 0);
  const max = parts.reduce((s, p) => s + p.maxScore, 0);
  const open = scored.reduce((s, p) => s + p.open, 0);
  const status = open > 0 ? "pending_marking" : "final";
  return {parts: scored, total, max, passMark, open, status,
    passed: status === "final" && isPassed(total, passMark, valid)};
}

/**
 * Points of every question of a scored test in one map, each with its part
 * index, as stored on the result (so a teacher's mark can re-score it
 * without loading the worksheet again).
 * @param {{parts: Array<{points: Object}>}} scored from scoreTest
 * @return {Object<string, Object>}
 */
function pointsByQuestion(scored) {
  const out = {};
  scored.parts.forEach((p, part) => {
    for (const [id, v] of Object.entries(p.points || {})) out[id] = {...v, part};
  });
  return out;
}

/**
 * Re-scores a stored result with the teacher's marks.
 * @param {{parts: Array<{maxScore: number}>, points: Object, passMark: number,
 *   valid: boolean}} result
 * @param {Object<string, number>} marks questionId → points
 * @return {{parts: Array<Object>, total: number, open: number,
 *   status: string, passed: boolean}}
 */
function rescore(result, marks) {
  const points = result.points || {};
  const parts = (result.parts || []).map((p, i) => {
    const mine = Object.fromEntries(
        Object.entries(points).filter(([, v]) => v.part === i));
    const t = play.totalsOf(mine, marks);
    const mark = t.possible === 0 ? 0 :
      Math.round((t.earned / t.possible) * (Number(p.maxScore) || 0));
    return {...p, earned: t.earned, possible: t.possible, mark, open: t.open};
  });
  const total = parts.reduce((s, p) => s + p.mark, 0);
  const open = parts.reduce((s, p) => s + p.open, 0);
  const status = open > 0 ? "pending_marking" : "final";
  return {parts, total, open, status,
    passed: status === "final" && isPassed(total, result.passMark, result.valid !== false)};
}

function isPassed(total, passMark, valid) {
  return valid !== false && Number(total) >= Number(passMark);
}

/**
 * The clocks a session runs: the format's own parts (`partClocks` true, the
 * supervised test), or one clock for the whole paper, the sum of the parts'
 * minutes (`partClocks` false: free movement, one submit at the end).
 * @param {Object} format
 * @param {boolean} partClocks
 * @return {Object} a cleaned format whose parts are the clocks
 */
function clockFormat(format, partClocks) {
  const f = cleanFormat(format);
  if (partClocks !== false) return f;
  const minutes = f.parts.reduce((s, p) => s + p.minutes, 0);
  return {parts: [{skill: "reading", questions: 0, minutes: Math.max(1, minutes),
    maxScore: 0}], passMark: f.passMark};
}

/** Seconds of a part's clock. */
function partSeconds(format, index) {
  const {parts} = cleanFormat(format);
  const p = parts[index];
  return p ? p.minutes * 60 : 0;
}

/** Seconds left on the open part (never below 0). */
function secondsLeft(partStartedAtMs, seconds, nowMs) {
  return Math.max(0, seconds - Math.floor((nowMs - partStartedAtMs) / 1000));
}

/** Seconds since the open part started (the listening recording's position). */
function elapsedSeconds(partStartedAtMs, nowMs) {
  return Math.max(0, Math.floor((nowMs - partStartedAtMs) / 1000));
}

/** Whole seconds from the start to the last submit (0 without a start). */
function durationSeconds(startedAtMs, finishedAtMs) {
  if (!startedAtMs) return 0;
  return Math.max(0, Math.round((finishedAtMs - startedAtMs) / 1000));
}

/** A submit after the part clock plus the grace counts as empty. */
function isPartLate(partStartedAtMs, seconds, graceSeconds, nowMs) {
  return nowMs > partStartedAtMs + (seconds + graceSeconds) * 1000;
}

/** Keeps only answers to the part's own questions. */
function answersForPart(items, answers) {
  const given = answers && typeof answers === "object" ? answers : {};
  const out = {};
  for (const it of items) {
    if (Object.prototype.hasOwnProperty.call(given, it.id)) {
      const a = given[it.id];
      if (a && typeof a === "object") out[it.id] = sanitizeAnswer(a);
    }
  }
  return out;
}

/** Only the answer shapes the player sends: index, order, text. */
function sanitizeAnswer(a) {
  const out = {};
  if (Number.isInteger(a.index)) out.index = a.index;
  if (Array.isArray(a.order)) out.order = a.order.slice(0, 50).map((s) => String(s).slice(0, 200));
  if (typeof a.text === "string") out.text = a.text.slice(0, 2000);
  return out;
}

/** Left-page events: newest last, at most 20 kept. */
function appendEvent(events, event, max = 20) {
  const list = Array.isArray(events) ? [...events] : [];
  list.push(event);
  return list.slice(Math.max(0, list.length - max));
}

/** Short printable number of a result, stable for its id. */
function resultNumber(resultId, finishedAtMs) {
  const d = new Date(finishedAtMs);
  const ymd = `${d.getUTCFullYear()}${String(d.getUTCMonth() + 1).padStart(2, "0")}` +
    `${String(d.getUTCDate()).padStart(2, "0")}`;
  let h = 2166136261;
  for (const ch of String(resultId)) {
    h ^= ch.charCodeAt(0);
    h = Math.imul(h, 16777619) >>> 0;
  }
  let tail = "";
  for (let i = 0; i < 6; i++) {
    tail += TOKEN_ALPHABET[h % TOKEN_ALPHABET.length];
    h = Math.floor(h / TOKEN_ALPHABET.length) || (h ^ 0x9e3779b9) >>> 0;
  }
  return `ES-${ymd}-${tail}`;
}

module.exports = {
  TOKEN_ALPHABET,
  TOKEN_LENGTH,
  JOIN_WINDOW_SECONDS,
  makeToken,
  normalizeToken,
  normalizeTestCode,
  partSkillOf,
  cleanFormat,
  clockFormat,
  splitIntoParts,
  partCounts,
  pointsOf,
  scorePart,
  scoreTest,
  pointsByQuestion,
  rescore,
  isPassed,
  partSeconds,
  secondsLeft,
  elapsedSeconds,
  durationSeconds,
  isPartLate,
  answersForPart,
  sanitizeAnswer,
  appendEvent,
  resultNumber,
};
