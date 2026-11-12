"use strict";
// Run with: node functions/test_exercise_play.js
const assert = require("assert");
const play = require("./exercise_play");

const mc = {id: "q1", type: "multiple_choice", sheetCode: "310001-RDG", sheetIndex: 1,
  question: {prompt: "我（ ）喜欢喝茶。", options: ["很", "是", "的"], correctIndex: 0,
    explanation: "很 + verb of feeling, no 是."}};
const mc0 = {id: "q0", type: "multiple_choice", tags: ["310001-RDG"], sheetIndex: 0,
  question: {prompt: "p0", options: ["A", "B"], correctIndex: 1}};
const compose = {id: "c1", type: "compose_sentences", sheetCode: "300001-KLM", sheetIndex: 0,
  question: {prompt: "", segments: ["经理的", "办公室在", "二楼"]}};
const hanzi = {id: "h1", type: "type_hanzi",
  question: {prompt: "我（ ）到了。", keyword: "gāng", options: ["刚"]}};
const picture = {id: "p1", type: "picture_sentence",
  question: {prompt: "", keyword: "跑步", imageUrl: "x"}};
const single = {id: "s1", type: "multiple_choice",
  question: {prompt: "single", options: ["x", "y"], correctIndex: 1}};

// Order: sheets as named, sheet order inside (tag fallback counts), then ids.
const ordered = play.orderPackageItems(
    [single, mc, compose, mc0], ["300001-KLM", "310001-RDG"], ["s1"]);
assert.deepStrictEqual(ordered.map((i) => i.id), ["c1", "q0", "q1", "s1"]);

// Stripped questions carry no key.
const sc = play.stripQuestion(compose);
assert.ok(!("correctIndex" in sc));
assert.deepStrictEqual([...sc.segments].sort(), ["二楼", "办公室在", "经理的"]);
assert.notDeepStrictEqual(sc.segments, compose.question.segments, "shuffled");
assert.deepStrictEqual(play.stripQuestion(compose).segments, sc.segments, "stable");
const sh = play.stripQuestion(hanzi);
assert.ok(!("options" in sh) && sh.keyword === "gāng");
const sm = play.stripQuestion(mc);
assert.deepStrictEqual(sm.options, ["很", "是", "的"]);
assert.ok(!("correctIndex" in sm));
assert.ok(!("explanation" in sm), "explanation stays until the review");

// Checking.
assert.strictEqual(play.checkAnswer(mc, {index: 0}).correct, true);
assert.strictEqual(play.checkAnswer(mc, {index: 2}).correct, false);
assert.deepStrictEqual(play.checkAnswer(mc, {}).correctAnswer, {index: 0});
assert.strictEqual(play.checkAnswer(compose, {order: ["经理的", "办公室在", "二楼"]}).correct, true);
assert.strictEqual(play.checkAnswer(compose, {order: ["办公室在", "经理的", "二楼"]}).correct, false);
assert.strictEqual(play.checkAnswer(hanzi, {text: " 刚 "}).correct, true);
assert.strictEqual(play.checkAnswer(hanzi, {text: "钢"}).correct, false);
assert.strictEqual(play.checkAnswer(picture, {text: "我每天跑步。"}).correct, true);
assert.strictEqual(play.checkAnswer(picture, {text: "跑步"}).correct, false);

// Scoring: unanswered counts as wrong; the review carries every key.
const scored = play.scoreAttempt(
    [mc, compose, hanzi, picture], {q1: {index: 0}, h1: {text: "刚"}});
assert.strictEqual(scored.score, 50);
assert.strictEqual(scored.correct, 2);
assert.strictEqual(scored.total, 4);
assert.deepStrictEqual(scored.review.map((r) => r.questionId), ["q1", "c1", "h1", "p1"]);
assert.deepStrictEqual(scored.review.map((r) => r.answered), [true, false, true, false]);
assert.deepStrictEqual(scored.review.map((r) => r.correct), [true, false, true, false]);
assert.deepStrictEqual(scored.review[1].correctAnswer, {order: ["经理的", "办公室在", "二楼"]});
assert.strictEqual(scored.review[0].explanation, "很 + verb of feeling, no 是.");
assert.strictEqual(scored.review[1].explanation, "", "no explanation -> empty string");
assert.deepStrictEqual(play.scoreAttempt([], null), {score: 0, correct: 0, total: 0, review: []});

console.log("exercise_play: all checks passed");
