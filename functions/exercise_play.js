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

const matcher = require("./typing_matcher");

/** Types a teacher marks by hand (T5); the machine never scores them. */
const TEACHER_MARKED = new Set(["picture_sentence", "essay"]);

/** Points of a question: its own `points`, else 10 for free writing, else 1. */
function pointsOf(item) {
  const n = Number(item && item.points);
  if (Number.isFinite(n) && n > 0) return n;
  return TEACHER_MARKED.has(String(item && item.type)) ? 10 : 1;
}

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
    // HSK papers: which skill the question counts for, the heading of its
    // part and the recording of the listening part (none of these is a key).
    skill: String(item.skillCategory || ""),
    section: String(item.section || ""),
    sectionAudioUrl: String(item.sectionAudioUrl || ""),
  };
  const optionImages = Array.isArray(q.optionImageUrls) ?
    q.optionImageUrls.map(String) : [];
  const withImages = optionImages.length ? {optionImageUrls: optionImages} : {};
  switch (type) {
    case "compose_sentences":
      return {...base, segments: seededShuffle(q.segments || [], item.id)};
    case "type_hanzi":
      return {...base, keyword: String(q.keyword || "")};
    case "type_pinyin":
      // The hanzi to write in pinyin is the prompt; the keys stay here.
      return base;
    case "picture_sentence":
      return {...base, keyword: String(q.keyword || "")};
    case "essay":
      // Free writing (T5): the words to use and, for HSK 6, a text shown
      // for a set time and then hidden. None of these is a key.
      return {
        ...base,
        keywords: (q.keywords || []).map(String),
        sourceText: String(q.sourceText || ""),
        sourceSeconds: Number.isInteger(q.sourceSeconds) ? q.sourceSeconds : 0,
      };
    case "matching":
    case "reading_cloze":
      return {
        ...base,
        options: (q.options || []).map(String),
        blankNumber: Number.isInteger(q.blankNumber) ? q.blankNumber : null,
        ...withImages,
      };
    default:
      return {...base, options: (q.options || []).map(String), ...withImages};
  }
}

/**
 * Checks one answer against the bank item. The answer shape depends on the
 * type: `{index}` for choices and the word bank, `{order: [...]}` for
 * compose, `{text}` for typed hanzi, typed pinyin and free writing.
 *
 * `credit` is 1, 0.5 (a typed answer that is nearly right, thesis spec
 * section 7) or 0. `review` says a teacher must look at it: half credit,
 * or free writing, which the machine never scores. `correct` is
 * `credit === 1`.
 *
 * @param {Object} item bank doc data
 * @param {Object} answer
 * @return {{correct: boolean, credit: number, review: boolean,
 *   reason: string, correctAnswer: Object}}
 */
function checkAnswer(item, answer) {
  const q = item.question || {};
  const type = String(item.type || "multiple_choice");
  const a = answer || {};
  const out = (credit, review, reason, correctAnswer) =>
    ({correct: credit === 1, credit, review, reason, correctAnswer});
  switch (type) {
    case "compose_sentences": {
      // T4: the word order is what is tested, so no half credit.
      const want = (q.segments || []).map(String);
      const got = Array.isArray(a.order) ? a.order.map(String) : [];
      const ok = got.length === want.length && want.every((s, i) => s === got[i]);
      return out(ok ? 1 : 0, false, ok ? "exact" : "wrong", {order: want});
    }
    case "type_hanzi": {
      const accepted = (q.options || []).map(String);
      const m = matcher.matchHanzi(a.text, accepted);
      return out(m.credit, m.review, m.reason, {accepted});
    }
    case "type_pinyin": {
      const accepted = (q.options || []).map(String);
      const m = matcher.matchPinyin(a.text, accepted);
      return out(m.credit, m.review, m.reason, {accepted});
    }
    case "picture_sentence":
    case "essay": {
      const keywords = type === "essay" ?
        (q.keywords || []).map(String) :
        [String(q.keyword || "")].filter((k) => k);
      const written = String(a.text || "").trim();
      // Nothing written is zero; anything written waits for the teacher.
      return out(0, written.length > 0, written ? "free_writing" : "wrong",
          {keywords, keyword: String(q.keyword || "")});
    }
    default: {
      const want = Number.isInteger(q.correctIndex) ? q.correctIndex : 0;
      const ok = Number.isInteger(a.index) && a.index === want;
      return out(ok ? 1 : 0, false, ok ? "exact" : "wrong", {index: want});
    }
  }
}

/**
 * Scores a whole attempt. Unanswered questions count as wrong. The review
 * lists every question in play order with its key and the teacher's
 * explanation (if any), so the result page can show the right answers once
 * the attempt is submitted. The explanation is only ever sent here, never
 * by stripQuestion.
 * @param {Array<Object>} items ordered bank items
 * @param {Object<string, Object>} answers questionId → answer
 * `bySkill` counts per skill (listening / reading / typing / speaking, as
 * stored on the bank items; missing = reading) so an HSK simulation can show
 * a mark per part.
 * @return {{score: number, correct: number, total: number,
 *   review: Array<{questionId: string, answered: boolean,
 *   correct: boolean, correctAnswer: Object, explanation: string}>,
 *   bySkill: Object<string, {correct: number, total: number}>}}
 */
function scoreAttempt(items, answers) {
  const given = answers && typeof answers === "object" ? answers : {};
  const bySkill = {};
  // Build 2A: points per question (credit × points). With 1-point choice
  // questions only, the score is the same as correct ÷ total × 100.
  const points = {};
  const review = items.map((it) => {
    const answered = Object.prototype.hasOwnProperty.call(given, it.id);
    const check = checkAnswer(it, given[it.id]);
    const q = it.question || {};
    const skill = String(it.skillCategory || "reading");
    const max = pointsOf(it);
    const earned = check.credit * max;
    points[it.id] = {earned, max, skill, review: check.review, reason: check.reason};
    const bucket = bySkill[skill] || (bySkill[skill] = {correct: 0, total: 0});
    bucket.total += 1;
    if (check.correct) bucket.correct += 1;
    return {
      questionId: it.id,
      answered,
      correct: check.correct,
      credit: check.credit,
      needsMarking: check.review,
      points: earned,
      maxPoints: max,
      correctAnswer: check.correctAnswer,
      explanation: String(q.explanation || ""),
    };
  });
  const totals = totalsOf(points);
  return {
    score: totals.score,
    correct: review.filter((r) => r.correct).length,
    total: items.length,
    earned: totals.earned,
    possible: totals.possible,
    open: totals.open,
    review,
    bySkill,
    points,
  };
}

/**
 * Totals of a points map, with the teacher's marks in place of the
 * machine's where there is one. `open` counts answers still waiting for a
 * teacher.
 * @param {Object<string, {earned: number, max: number, review: boolean}>} points
 * @param {Object<string, number>} marks questionId → points the teacher gave
 * @return {{earned: number, possible: number, score: number, open: number}}
 */
function totalsOf(points, marks = {}) {
  let earned = 0;
  let possible = 0;
  let open = 0;
  for (const [id, p] of Object.entries(points || {})) {
    possible += Number(p.max) || 0;
    if (Object.prototype.hasOwnProperty.call(marks, id)) {
      earned += Number(marks[id]) || 0;
    } else {
      earned += Number(p.earned) || 0;
      if (p.review) open += 1;
    }
  }
  const score = possible === 0 ? 0 : Math.round((earned / possible) * 100);
  return {earned, possible, score, open};
}

/** Categories that allow a single attempt with a server-side clock. */
const ONE_ATTEMPT = new Set(["exam", "hsk_simulation"]);

/** Type of exercise of a package: its first worksheet's, else "exercise". */
function packageCategory(items) {
  const first = items.find((it) => typeof it.category === "string" && it.category);
  return first ? first.category : "exercise";
}

function isOneAttempt(category) {
  return ONE_ATTEMPT.has(String(category || ""));
}

module.exports = {
  TEACHER_MARKED,
  pointsOf,
  totalsOf,
  packageCategory,
  isOneAttempt,
  orderPackageItems,
  stripQuestion,
  checkAnswer,
  scoreAttempt,
  seededShuffle,
};
