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
// Build 2A: free writing is never scored by the machine; anything written
// waits for the teacher, nothing written is zero.
const written = play.checkAnswer(picture, {text: "我每天跑步。"});
assert.strictEqual(written.credit, 0);
assert.strictEqual(written.review, true);
assert.strictEqual(play.checkAnswer(picture, {text: "  "}).review, false);
// A wrong homophone in typed hanzi is half and flagged (PN-03 shape).
const near = {id: "h2", type: "type_hanzi", question: {prompt: "", options: ["我很喜欢喝茶"]}};
assert.deepStrictEqual(
    [play.checkAnswer(near, {text: "我很喜欢和茶"}).credit,
      play.checkAnswer(near, {text: "我很喜欢和茶"}).review], [0.5, true]);
// Typed pinyin (T1): keys stay on the server.
const py = {id: "y1", type: "type_pinyin", question: {prompt: "你好", options: ["nǐ hǎo"]}};
assert.ok(!("options" in play.stripQuestion(py)));
assert.strictEqual(play.checkAnswer(py, {text: "ni3 hao3"}).credit, 1);
assert.strictEqual(play.checkAnswer(py, {text: "ni hao"}).credit, 0.5);
// Essay (T5): 10 points, the words to use and the source text travel, no key.
const essay = {id: "e1", type: "essay", question: {prompt: "写一写", keywords: ["周末", "公园"],
  sourceText: "原文", sourceSeconds: 600}};
assert.strictEqual(play.pointsOf(essay), 10);
assert.deepStrictEqual(play.stripQuestion(essay).keywords, ["周末", "公园"]);
assert.strictEqual(play.stripQuestion(essay).sourceSeconds, 600);

// Scoring: unanswered counts as wrong; the review carries every key. Points:
// 1 each, free writing 10, so 2 of 13 points.
const scored = play.scoreAttempt(
    [mc, compose, hanzi, picture], {q1: {index: 0}, h1: {text: "刚"}});
assert.strictEqual(scored.score, 15);
assert.strictEqual(scored.earned, 2);
assert.strictEqual(scored.possible, 13);
assert.strictEqual(scored.open, 0, "nothing written: nothing to mark");
// Choice questions only: the score is correct ÷ total × 100, as before.
assert.strictEqual(play.scoreAttempt([mc, mc0, single],
    {q1: {index: 0}, q0: {index: 1}}).score, 67);
// A teacher's marks replace the machine's points.
const withHalf = play.scoreAttempt([near, mc], {h2: {text: "我很喜欢和茶"}, q1: {index: 0}});
assert.deepStrictEqual([withHalf.earned, withHalf.open], [1.5, 1]);
assert.deepStrictEqual(play.totalsOf(withHalf.points, {h2: 1}),
    {earned: 2, possible: 2, score: 100, open: 0});
assert.strictEqual(scored.correct, 2);
assert.strictEqual(scored.total, 4);
assert.deepStrictEqual(scored.review.map((r) => r.questionId), ["q1", "c1", "h1", "p1"]);
assert.deepStrictEqual(scored.review.map((r) => r.answered), [true, false, true, false]);
assert.deepStrictEqual(scored.review.map((r) => r.correct), [true, false, true, false]);
assert.deepStrictEqual(scored.review[1].correctAnswer, {order: ["经理的", "办公室在", "二楼"]});
assert.strictEqual(scored.review[0].explanation, "很 + verb of feeling, no 是.");
assert.strictEqual(scored.review[1].explanation, "", "no explanation -> empty string");
assert.deepStrictEqual(play.scoreAttempt([], null),
    {score: 0, correct: 0, total: 0, earned: 0, possible: 0, open: 0, review: [],
      bySkill: {}, points: {}});

// Marks per skill (HSK parts): missing skill counts as reading.
const listening = {id: "l1", type: "listening", skillCategory: "listening",
  section: "一、听力 · 第一部分", sectionAudioUrl: "https://a/x.mp3",
  question: {prompt: "", options: ["A", "B", "C"], correctIndex: 2,
    optionImageUrls: ["https://i/a.png", "https://i/b.png", "https://i/c.png"]}};
const skilled = play.scoreAttempt([listening, mc, compose], {l1: {index: 2}, q1: {index: 0}});
assert.deepStrictEqual(skilled.bySkill,
    {listening: {correct: 1, total: 1}, reading: {correct: 1, total: 2}});
// Picture choices, the heading and the recording travel with the question;
// the key still does not.
const sl = play.stripQuestion(listening);
assert.deepStrictEqual(sl.optionImageUrls, listening.question.optionImageUrls);
assert.strictEqual(sl.section, "一、听力 · 第一部分");
assert.strictEqual(sl.sectionAudioUrl, "https://a/x.mp3");
assert.strictEqual(sl.skill, "listening");
assert.ok(!("correctIndex" in sl));
assert.ok(!("optionImageUrls" in play.stripQuestion(mc)), "no images -> no field");

// Exams and HSK simulations are one attempt; the category follows the first
// worksheet that has one.
assert.strictEqual(play.packageCategory([compose, {...mc, category: "exam"}]), "exam");
assert.strictEqual(play.packageCategory([mc]), "exercise");
assert.strictEqual(play.isOneAttempt("exam"), true);
assert.strictEqual(play.isOneAttempt("hsk_simulation"), true);
assert.strictEqual(play.isOneAttempt("quiz"), false);
assert.strictEqual(play.isOneAttempt(undefined), false);

// Standard Course (owner 2026-11-25): the context text goes out once per
// run of questions that share it.
const ctx = "1. 买水果\n大明：今天下午你去哪儿？";
const withCtx = [
  play.stripQuestion({...mc0, context: ctx}),
  play.stripQuestion({...mc, context: ctx}),
  play.stripQuestion(single),
  play.stripQuestion({...compose, context: ctx}),
];
assert.strictEqual(withCtx[0].context, ctx);
assert.strictEqual(play.stripQuestion(single).context, "");
const shared = play.shareContext(withCtx);
assert.strictEqual(shared[0].context, ctx);
assert.deepStrictEqual([shared[1].context, shared[1].contextSame], ["", true]);
assert.strictEqual(shared[2].context, "");
assert.ok(!shared[2].contextSame, "no text is not 'the same text'");
assert.strictEqual(shared[3].context, ctx, "sent again after a question without it");

console.log("exercise_play: all checks passed");
