"use strict";

/**
 * Teacher marking (Build 2A, thesis spec section 7 "T5 essay grading" and
 * the typing matcher's review flag). Pure: no Firebase, so
 * `node functions/test_marking.js` runs it alone.
 *
 * One queue item per answer a teacher must look at: a typed answer the
 * matcher gave half credit, or free writing (never scored by the machine).
 */

const play = require("./exercise_play");

/** Rubric for free writing: grammar 40, vocabulary 30, content 30. */
const RUBRIC = {grammar: 40, vocabulary: 30, content: 30};

/** The answer as text for the teacher (typed text or the word order). */
function answerText(answer) {
  const a = answer || {};
  if (typeof a.text === "string") return a.text.slice(0, 4000);
  if (Array.isArray(a.order)) return a.order.map(String).join(" ");
  return "";
}

/**
 * Queue items of one scored attempt.
 * @param {Array<Object>} items bank items that were played
 * @param {Object<string, Object>} answers questionId → answer
 * @param {Object<string, Object>} points questionId → {earned, max, review, reason}
 * @param {Object} context fields every item carries (source, resultId,
 *   student, teacherIds, ...)
 * @param {Object<string, number>} partOf questionId → part index (tests)
 * @return {Array<{questionId: string, data: Object}>}
 */
function queueItems(items, answers, points, context, partOf = {}) {
  const out = [];
  for (const it of items) {
    const p = points[it.id];
    if (!p || !p.review) continue;
    const q = it.question || {};
    const check = play.checkAnswer(it, answers[it.id]);
    const text = answerText(answers[it.id]);
    out.push({
      questionId: it.id,
      data: {
        ...context,
        questionId: it.id,
        partIndex: Number.isInteger(partOf[it.id]) ? partOf[it.id] : null,
        type: String(it.type || ""),
        prompt: String(q.prompt || ""),
        imageUrl: String(q.imageUrl || ""),
        answerText: text,
        characterCount: Array.from(text.replace(/\s+/g, "")).length,
        accepted: (check.correctAnswer.accepted || []).map(String),
        keywords: (check.correctAnswer.keywords || []).map(String),
        reason: p.reason,
        machinePoints: p.earned,
        maxPoints: p.max,
        status: "open",
      },
    });
  }
  return out;
}

/** Required words found and missing in an answer (for the essay screen). */
function keywordsIn(text, keywords) {
  const t = String(text || "");
  const found = [];
  const missing = [];
  for (const k of keywords || []) {
    (t.includes(String(k)) ? found : missing).push(String(k));
  }
  return {found, missing};
}

/**
 * Points a teacher's decision gives.
 * - Typed answers: `keep` (the machine's points), `full` or `zero`.
 * - Free writing: the rubric; each part is clamped to its maximum and the
 *   sum (0-100) is scaled to the question's points.
 * @param {{machinePoints: number, maxPoints: number, reason: string}} item
 * @param {{decision?: string, rubric?: Object}} input
 * @return {{points: number, rubric: Object|null}}
 */
function markPoints(item, input) {
  const max = Number(item.maxPoints) || 0;
  if (item.reason === "free_writing") {
    const r = (input && input.rubric) || {};
    const rubric = {};
    let sum = 0;
    for (const [key, top] of Object.entries(RUBRIC)) {
      const v = Math.max(0, Math.min(top, Math.round(Number(r[key]) || 0)));
      rubric[key] = v;
      sum += v;
    }
    return {points: Math.round((sum / 100) * max * 10) / 10, rubric};
  }
  const decision = String((input && input.decision) || "keep");
  if (decision === "full") return {points: max, rubric: null};
  if (decision === "zero") return {points: 0, rubric: null};
  return {points: Number(item.machinePoints) || 0, rubric: null};
}

module.exports = {RUBRIC, answerText, queueItems, keywordsIn, markPoints};
