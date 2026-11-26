"use strict";

/**
 * Build 9 part 2 (supervisor 2026-11-25: "pagination ... so it doesn't bloat
 * the website"): the question bank and the exercise packages are read a page
 * at a time, so what their lists sort, filter and search on is kept as small
 * index documents by triggers instead of being worked out in the browser
 * from the whole bank.
 *
 * - `bank_sheets/{id}`: one document per worksheet (all questions with the
 *   same sheet code) or per stand-alone question (`q_<questionId>`), with
 *   what the bank table shows and filters on.
 * - On `exercises/{id}`: `listAt` (the list order), `listCategory` (the
 *   type of exercise of its first worksheet), `listSkill` and
 *   `searchPrefixes` (the title).
 *
 * The Dart twins: QuestionBankItem.sheetKey, QuestionBankSheet (title, type,
 * level, category, missingRecording), UserSearch.normalize.
 */

const {normalizeQuery, MAX_PREFIX} = require("./user_search");

const SHEET_CODE = /^\d{6,7}-(RDG|KLM|WRT|CRT|KK)$/;
const MAX_SEARCH_ENTRIES = 3000;
const NEEDS_RECORDING = new Set(["hsk_simulation", "hsk_standard_course"]);

/** The worksheet of a bank question, or null for a stand-alone question. */
function sheetKeyOf(item) {
  const code = String((item || {}).sheetCode || "");
  if (code) return code;
  for (const tag of (item || {}).tags || []) {
    if (SHEET_CODE.test(String(tag))) return String(tag);
  }
  return null;
}

/** The index document id of a worksheet or a stand-alone question. */
function sheetDocId(key, itemId) {
  if (key) return `s_${String(key).replace(/[/\s]+/g, "_")}`;
  return `q_${itemId}`;
}

/** What identifies a question in a list (QuestionBankItem.displayText). */
function displayTextOf(item) {
  const q = (item || {}).question || {};
  const prompt = String(item.prompt || q.prompt || "");
  if (prompt.trim()) return prompt;
  const segments = Array.isArray(q.segments) ? q.segments : [];
  if (segments.length) return segments.join(" / ");
  return String(q.keyword || "");
}

function addPrefixes(text, set) {
  const t = normalizeQuery(text);
  if (!t) return;
  const chars = [...t];
  for (let i = 1; i <= Math.min(chars.length, MAX_PREFIX); i++) {
    set.add(chars.slice(0, i).join(""));
  }
}

function addWordPrefixes(text, set) {
  addPrefixes(text, set);
  for (const w of String(text || "").split(/\s+/)) addPrefixes(w, set);
}

function ms(v) {
  if (!v) return null;
  if (typeof v.toMillis === "function") return v.toMillis();
  if (v instanceof Date) return v.getTime();
  return Number.isFinite(v) ? v : null;
}

/** Sheet order: sheetIndex, else creation time (QuestionBankSheet.group). */
function bySheetOrder(a, b) {
  const ai = Number.isFinite(a.sheetIndex) ? a.sheetIndex : null;
  const bi = Number.isFinite(b.sheetIndex) ? b.sheetIndex : null;
  if (ai !== null && bi !== null) return ai - bi;
  if (ai !== null) return -1;
  if (bi !== null) return 1;
  return (ms(a.createdAt) || 0) - (ms(b.createdAt) || 0);
}

/**
 * The index document of one worksheet ([key] set) or one stand-alone
 * question. [items] are `{id, ...data}`; returns null when none is left.
 * `createdAtMs` is the newest question's time: the bank lists sheets in the
 * order of their newest question, as the whole-bank stream did.
 */
function sheetSummaryOf(key, items) {
  const list = (items || []).filter(Boolean).slice().sort(bySheetOrder);
  if (!list.length) return null;
  const first = list[0];
  let title = null;
  if (key) {
    for (const it of list) {
      const t = String(it.sheetTitle || "").trim();
      if (t) {
        title = t;
        break;
      }
    }
  }
  const text = displayTextOf(first);
  if (!title) title = key || text;
  const category = String(first.category || "exercise");
  const audio = list.some((it) => String(it.sectionAudioUrl || ""));
  const search = new Set();
  addWordPrefixes(title, search);
  if (key) addPrefixes(key, search);
  for (const it of list) {
    if (search.size >= MAX_SEARCH_ENTRIES) break;
    addPrefixes(displayTextOf(it), search);
  }
  let newest = null;
  for (const it of list) {
    const t = ms(it.createdAt);
    if (t !== null && (newest === null || t > newest)) newest = t;
  }
  const creators = [...new Set(list.map((it) => String(it.createdBy || "")))].sort();
  return {
    key: key || null,
    isSheet: Boolean(key),
    itemId: key ? null : first.id,
    itemIds: list.map((it) => it.id),
    code: key || "",
    title,
    titleLower: String(title).toLowerCase(),
    firstText: text,
    type: String(first.type || "multiple_choice"),
    category,
    level: first.level ? String(first.level) : null,
    count: list.length,
    usageCount: list.reduce((s, it) => s + (Number(it.usageCount) || 0), 0),
    hasRecording: audio,
    missingRecording: Boolean(key) && NEEDS_RECORDING.has(category) && !audio,
    hasPaperRecord: list.some((it) => it.paperRecord && typeof it.paperRecord === "object"),
    creators,
    ownerId: String(first.ownerId || ""),
    createdAtMs: newest,
    searchPrefixes: [...search].slice(0, MAX_SEARCH_ENTRIES).sort(),
  };
}

/** Normalised skill (a missing value reads as reading, like the app). */
function skillOf(exercise) {
  const v = String((exercise || {}).skillCategory || "");
  return v || "reading";
}

/**
 * The list fields of one exercise. [category] is the type of exercise of
 * its first worksheet or question (null when the bank no longer has it);
 * an old exercise with its questions inside is a plain exercise.
 */
function exerciseListFieldsOf(exercise, category, nowMs) {
  const e = exercise || {};
  const isPackage = (e.bankSheets || []).length > 0 || (e.bankQuestionIds || []).length > 0;
  const search = new Set();
  addWordPrefixes(e.title, search);
  const at = ms(e.createdAt) ?? ms(e.listAt) ?? nowMs;
  return {
    listAt: at,
    listCategory: isPackage ? (category || "unknown") : "exercise",
    listSkill: skillOf(e),
    listPublished: e.isPublished !== false,
    searchPrefixes: [...search].sort(),
  };
}

/** True when the stored list fields already equal [fields]. */
function sameListFields(exercise, fields) {
  const e = exercise || {};
  const at = ms(e.listAt);
  return at === fields.listAt && e.listCategory === fields.listCategory &&
    e.listSkill === fields.listSkill && e.listPublished === fields.listPublished &&
    Array.isArray(e.searchPrefixes) &&
    e.searchPrefixes.length === fields.searchPrefixes.length &&
    e.searchPrefixes.every((x, i) => x === fields.searchPrefixes[i]);
}

module.exports = {
  sheetKeyOf,
  sheetDocId,
  displayTextOf,
  sheetSummaryOf,
  exerciseListFieldsOf,
  sameListFields,
};
