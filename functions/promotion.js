"use strict";

/**
 * Build 2B (docs/PLAN.md §4): the leaderboard of a test code and the
 * promotion count, as pure logic. The trigger on `test_results` in
 * index.js reads the documents and writes what these functions decide.
 * Spec: docs/THESIS_FEATURE_BACKLOG.md §8 (LV-01, LV-03, LB-01).
 */

const LEVELS = ["1", "2", "3", "4", "5", "6"];
const DEFAULT_MIN_CODES = 3;

/** `HSK 3`, `hsk3`, `3` → `3`; anything else → "". */
function levelKeyOf(level) {
  const m = /(\d)/.exec(String(level || ""));
  return m && LEVELS.includes(m[1]) ? m[1] : "";
}

/** The level after [key], or null at HSK 6 (no next level). */
function nextLevelKey(key) {
  const i = LEVELS.indexOf(String(key));
  return i < 0 || i === LEVELS.length - 1 ? null : LEVELS[i + 1];
}

/** Beginner (HSK 1-2), Intermediate (3-4), Advance (5-6). */
function groupOf(key) {
  const n = Number(levelKeyOf(key));
  if (n === 1 || n === 2) return "beginner";
  if (n === 3 || n === 4) return "intermediate";
  if (n === 5 || n === 6) return "advance";
  return "";
}

/** What another student sees: the Chinese name, else the first Latin word. */
function peerLabel(chinese, latin) {
  const c = String(chinese || "").trim();
  if (c) return c;
  const words = String(latin || "").trim().split(/\s+/);
  return words[0] || "";
}

/** A result counts as final when marking is done (results before Build 2A
 * carry no status and are final). */
function isFinal(result) {
  return (result.status || "final") === "final";
}

function isValid(result) {
  return result.valid !== false;
}

/** Placement results (Build 3) never reach a board or the count. */
function isPlacement(result, code) {
  return result.placement === true || (code || {}).placement === true ||
    (code || {}).purpose === "placement";
}

function millis(t) {
  if (!t) return null;
  if (typeof t.toMillis === "function") return t.toMillis();
  if (t instanceof Date) return t.getTime();
  if (typeof t === "number") return t;
  return null;
}

/**
 * The leaderboard entry of a result, or null when it must not be on the
 * board (pending marking, invalid, placement).
 * @param {Object} result a `test_results` document
 * @param {Object} code its `test_codes` document (may be empty)
 * @return {Object|null}
 */
function entryOf(result, code) {
  if (!result || !isFinal(result) || !isValid(result) || isPlacement(result, code)) {
    return null;
  }
  return {
    codeId: result.codeId || "",
    studentId: result.studentId || "",
    name: peerLabel(result.studentNameChinese, result.studentName),
    parts: (result.parts || []).map((p) => ({
      skill: p.skill || "",
      mark: Number(p.mark) || 0,
      maxScore: Number(p.maxScore || p.max) || 0,
    })),
    total: Number(result.total) || 0,
    max: Number(result.max) || 0,
    passed: result.passed === true,
    seconds: Number.isFinite(Number(result.durationSeconds)) &&
      result.durationSeconds !== null && result.durationSeconds !== undefined ?
      Number(result.durationSeconds) : null,
    finishedAtMs: millis(result.finishedAt),
  };
}

/** Board order: total high to low, then fewer seconds, then earlier finish. */
function compareEntries(a, b) {
  if (b.total !== a.total) return b.total - a.total;
  const sa = a.seconds === null ? Infinity : a.seconds;
  const sb = b.seconds === null ? Infinity : b.seconds;
  if (sa !== sb) return sa - sb;
  const fa = a.finishedAtMs === null ? Infinity : a.finishedAtMs;
  const fb = b.finishedAtMs === null ? Infinity : b.finishedAtMs;
  return fa - fb;
}

/** Sorted entries with `rank` (equal total and seconds share a rank). */
function rankEntries(entries) {
  const sorted = [...entries].sort(compareEntries);
  let rank = 0;
  return sorted.map((e, i) => {
    const prev = sorted[i - 1];
    if (!prev || prev.total !== e.total || prev.seconds !== e.seconds) rank = i + 1;
    return {...e, rank};
  });
}

/**
 * Whether a result counts toward promotion at [levelKey]: final, valid,
 * passed, an HSK code of that level that counts for promotion, not a
 * placement.
 */
function countsAt(result, code, levelKey) {
  const c = code || {};
  if (!result || !isFinal(result) || !isValid(result) || result.passed !== true) return false;
  if (isPlacement(result, c)) return false;
  if (c.countsForPromotion === false) return false;
  const family = String(result.family || c.family || "hsk").toLowerCase();
  if (family !== "hsk") return false;
  const key = levelKeyOf(result.levelKey || c.levelKey || result.level || c.level);
  return key !== "" && key === String(levelKey);
}

/**
 * The promotion count of one student.
 * @param {Array<{result: Object, code: Object}>} rows the student's results
 * @param {string} levelKey the student's current level (`3`)
 * @param {number} minCodes codes needed (settings/promotion.minCodes)
 * @return {{levelKey: string, next: string|null, codes: Array<string>,
 *   count: number, minCodes: number, reached: boolean}}
 */
function promotionState(rows, levelKey, minCodes = DEFAULT_MIN_CODES) {
  const min = Number(minCodes) >= 1 ? Math.floor(Number(minCodes)) : DEFAULT_MIN_CODES;
  const codes = [];
  for (const {result, code} of rows || []) {
    if (!countsAt(result, code, levelKey)) continue;
    const id = String(result.codeId || "");
    if (id && !codes.includes(id)) codes.push(id);
  }
  codes.sort();
  const next = nextLevelKey(levelKey);
  return {
    levelKey: String(levelKey || ""),
    next,
    codes,
    count: codes.length,
    minCodes: min,
    reached: next !== null && levelKey !== "" && codes.length >= min,
  };
}

/** The id of a recommendation: one per student and level. */
function promotionId(uid, levelKey) {
  return `${uid}_${levelKey}`;
}

/**
 * Owner 2026-11-24 (Q12): the admin may promote a capable student straight
 * away. [toLevel] must be a real level above the current one (skipping
 * levels is allowed).
 * @return {{error: string}|{fromKey: string, toKey: string, fromLevel: string, toLevel: string}}
 */
function manualPromotion(fromLevel, toLevel) {
  const fromKey = levelKeyOf(fromLevel);
  const toKey = levelKeyOf(toLevel);
  if (!toKey) return {error: "bad-level"};
  if (fromKey && Number(toKey) <= Number(fromKey)) return {error: "not-higher"};
  return {fromKey, toKey, fromLevel: fromKey ? `HSK ${fromKey}` : String(fromLevel || ""),
    toLevel: `HSK ${toKey}`};
}

/**
 * Owner 2026-11-24: a level's checklist ("to go from HSK 1 to HSK 2, finish
 * these"), set by the admin in `level_paths/{levelKey}`. It replaces the
 * test-code count for a level that has one. An exercise item is done with
 * a final result at or above its minimum score (0 = finished); a test item
 * with a final, valid, passed, non-placement result of that code.
 * @param {Array} items [{kind: "exercise"|"test", id, title, minScore}]
 * @param {Array} exerciseResults `exercise_results` of the student
 * @param {Array} testRows [{result, code}] of the student
 */
function pathProgress(items, exerciseResults, testRows) {
  const list = (items || []).filter((i) => i && (i.kind === "exercise" || i.kind === "test") &&
    String(i.id || ""));
  const out = list.map((i) => {
    const id = String(i.id);
    if (i.kind === "exercise") {
      const min = Math.max(0, Number(i.minScore) || 0);
      const scores = (exerciseResults || [])
          .filter((r) => r && r.exerciseId === id && r.status !== "pending_marking")
          .map((r) => Number(r.score) || 0);
      const best = scores.length ? Math.max(...scores) : null;
      return {kind: "exercise", id, title: String(i.title || ""), minScore: min, best,
        done: best !== null && best >= min};
    }
    const passed = (testRows || []).some(({result, code}) => result &&
      result.codeId === id && isFinal(result) && isValid(result) &&
      !isPlacement(result, code) && result.passed === true);
    return {kind: "test", id, title: String(i.title || ""), done: passed};
  });
  const done = out.filter((x) => x.done).length;
  return {items: out, done, total: out.length, complete: out.length > 0 && done === out.length};
}

module.exports = {
  pathProgress,
  LEVELS, DEFAULT_MIN_CODES, levelKeyOf, nextLevelKey, groupOf, peerLabel,
  isFinal, isValid, isPlacement, entryOf, compareEntries, rankEntries,
  countsAt, promotionState, promotionId, manualPromotion,
};
