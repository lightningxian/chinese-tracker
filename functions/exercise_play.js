"use strict";

/**
 * Pure helpers for playing a bank-based exercise ("package") with the
 * answer keys kept on the server. No Firebase here, so `node
 * test_exercise_play.js` can run them without an emulator.
 *
 * A package exercise holds `bankSheets` (worksheet codes) and
 * `bankQuestionIds`; its questions are read from `question_bank` when a
 * student starts it. The student only ever receives the stripped form
 * ({@link stripQuestion}); answers are checked by {@link checkAnswer}.
 */

/** Chinese sheet codes sort as plain strings; the number inside is enough. */
function bySheetOrder(a, b) {
  const ai = Number.isInteger(a.sheetIndex) ? a.sheetIndex : Number.MAX_SAFE_INTEGER;
  const bi = Number.isInteger(b.sheetIndex) ? b.sheetIndex : Number.MAX_SAFE_INTEGER;
  if (ai !== bi) return ai - bi;
  const ac = a.createdAtMillis || 0;
  const bc = b.createdAtMillis || 0;
  return ac - bc;
}

/**
 * Orders bank items the way the package lists them: worksheet by worksheet
 * in the order the exercise names them, questions in sheet order inside;
 * then the single questions in the order the exercise names them.
 *
 * @param {Array<Object>} items bank docs as {id, ...data, createdAtMillis}
 * @param {string[]} sheets `bankSheets` of the exercise
 * @param {string[]} questionIds `bankQuestionIds` of the exercise
 * @return {Array<Object>}
 */
function orderPackageItems(items, sheets, questionIds) {
  const sheetKey = (it) => {
    if (typeof it.sheetCode === "string" && it.sheetCode) return it.sheetCode;
    for (const t of it.tags || []) {
      if (/^\d{6,7}-(RDG|KLM|WRT|CRT|KK)$/.test(t)) return t;
    }
    return null;
  };
  const out = [];
  const seen = new Set();
  for (const code of sheets) {
    const inSheet = items.filter((it) => sheetKey(it) === code && !seen.has(it.id));
    inSheet.sort(bySheetOrder);
    for (const it of inSheet) {
      seen.add(it.id);
      out.push(it);
    }
  }
  for (const id of questionIds) {
    const it = items.find((x) => x.id === id);
    if (it && !seen.has(id)) {
      seen.add(id);
      out.push(it);
    }
  }
  return out;
}

/** Deterministic shuffle so a reload shows the same word order. */
function seededShuffle(list, seed) {
  const out = [...list];
  let h = 2166136261;
  for (const ch of String(seed)) {
    h ^= ch.charCodeAt(0);
    h = Math.imul(h, 16777619) >>> 0;
  }
  for (let i = out.length - 1; i > 0; i--) {
    h = (Math.imul(h, 1103515245) + 12345) >>> 0;
    const j = h % (i + 1);
    [out[i], out[j]] = [out[j], out[i]];
  }
  // A shuffle that lands on the answer gives it away: rotate once.
  if (out.length > 1 && out.every((s, i) => s === list[i])) {
    out.push(out.shift());
  }
  return out;
}

/**
 * The question as the student may see it: no correctIndex, no ordered
 * segments, no accepted hanzi.
 * @param {Object} item bank doc data with `id`, `type`, `question`
 * @return {Object}
 */
function stripQuestion(item) {
  const q = item.question || {};
  const type = String(item.type || "multiple_choice");
  const base = {
    id: item.id,
    type,
    prompt: String(q.prompt || ""),
    imageUrl: String(q.imageUrl || ""),
    audioUrl: String(q.audioUrl || ""),
  };
  switch (type) {
    case "compose_sentences":
      return {...base, segments: seededShuffle(q.segments || [], item.id)};
    case "type_hanzi":
      return {...base, keyword: String(q.keyword || "")};
    case "picture_sentence":
      return {...base, keyword: String(q.keyword || "")};
    case "matching":
    case "reading_cloze":
      return {
        ...base,
        options: (q.options || []).map(String),
        blankNumber: Number.isInteger(q.blankNumber) ? q.blankNumber : null,
      };
    default:
      return {...base, options: (q.options || []).map(String)};
  }
}

const PUNCT = /[\s。．.，,！!？?、：:；;「」『』“”"()（）]/g;
const clean = (s) => String(s || "").replace(PUNCT, "").trim();

/**
 * Checks one answer against the bank item. The answer shape depends on the
 * type: `{index}` for choices and the word bank, `{order: [...]}` for
 * compose, `{text}` for typed hanzi and picture sentences.
 *
 * @param {Object} item bank doc data
 * @param {Object} answer
 * @return {{correct: boolean, correctAnswer: Object}}
 */
function checkAnswer(item, answer) {
  const q = item.question || {};
  const type = String(item.type || "multiple_choice");
  const a = answer || {};
  switch (type) {
    case "compose_sentences": {
      const want = (q.segments || []).map(String);
      const got = Array.isArray(a.order) ? a.order.map(String) : [];
      const correct = got.length === want.length &&
        want.every((s, i) => s === got[i]);
      return {correct, correctAnswer: {order: want}};
    }
    case "type_hanzi": {
      const accepted = (q.options || []).map(String);
      const typed = clean(a.text);
      const correct = typed.length > 0 && accepted.some((x) => clean(x) === typed);
      return {correct, correctAnswer: {accepted}};
    }
    case "picture_sentence": {
      const k = clean(q.keyword);
      const typed = clean(a.text);
      const correct = k ?
        typed.includes(k) && typed.length > k.length :
        typed.length >= 2;
      return {correct, correctAnswer: {keyword: String(q.keyword || "")}};
    }
    default: {
      const want = Number.isInteger(q.correctIndex) ? q.correctIndex : 0;
      const correct = Number.isInteger(a.index) && a.index === want;
      return {correct, correctAnswer: {index: want}};
    }
  }
}

/**
 * Scores a whole attempt. Unanswered questions count as wrong.
 * @param {Array<Object>} items ordered bank items
 * @param {Object<string, Object>} answers questionId → answer
 * @return {{score: number, correct: number, total: number}}
 */
function scoreAttempt(items, answers) {
  let correct = 0;
  for (const it of items) {
    if (checkAnswer(it, (answers || {})[it.id]).correct) correct++;
  }
  const total = items.length;
  const score = total === 0 ? 0 : Math.round((correct / total) * 100);
  return {score, correct, total};
}

module.exports = {
  orderPackageItems,
  stripQuestion,
  checkAnswer,
  scoreAttempt,
  seededShuffle,
};
