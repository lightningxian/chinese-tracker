"use strict";

// Teacher marking (Build 2A). Run: node functions/test_marking.js
const assert = require("node:assert/strict");
const play = require("./exercise_play");
const mk = require("./marking");

const near = {id: "h1", type: "type_hanzi", question: {prompt: "p", options: ["我很喜欢喝茶"]}};
const exact = {id: "h2", type: "type_hanzi", question: {prompt: "p", options: ["你好"]}};
const essay = {id: "e1", type: "essay", question: {prompt: "写", keywords: ["周末", "公园"]}};
const order = {id: "c1", type: "compose_sentences", question: {segments: ["把书", "放在", "桌子上"]}};
const items = [near, exact, essay, order];
const answers = {h1: {text: "我很喜欢和茶"}, h2: {text: "你好"},
  e1: {text: "周末 我去书店。"}, c1: {order: ["放在", "把书", "桌子上"]}};
const scored = play.scoreAttempt(items, answers);

const queue = mk.queueItems(items, answers, scored.points,
    {source: "package", resultId: "r1", studentId: "s1", teacherIds: ["t1"]});
assert.deepEqual(queue.map((q) => q.questionId), ["h1", "e1"],
    "half credit and free writing only; word order never");
assert.equal(queue[0].data.reason, "one_character");
assert.equal(queue[0].data.machinePoints, 0.5);
assert.deepEqual(queue[0].data.accepted, ["我很喜欢喝茶"]);
assert.equal(queue[1].data.reason, "free_writing");
assert.equal(queue[1].data.maxPoints, 10);
assert.equal(queue[1].data.characterCount, 7, "spaces do not count");
assert.deepEqual(queue[1].data.keywords, ["周末", "公园"]);
assert.equal(queue[1].data.resultId, "r1");

assert.deepEqual(mk.keywordsIn("周末我去书店。", ["周末", "公园"]),
    {found: ["周末"], missing: ["公园"]});

// Typed answers: keep / full / zero.
assert.equal(mk.markPoints(queue[0].data, {decision: "keep"}).points, 0.5);
assert.equal(mk.markPoints(queue[0].data, {decision: "full"}).points, 1);
assert.equal(mk.markPoints(queue[0].data, {decision: "zero"}).points, 0);
// Free writing: grammar 40 + vocabulary 30 + content 30, clamped, scaled.
const r = mk.markPoints(queue[1].data, {rubric: {grammar: 30, vocabulary: 99, content: 20}});
assert.deepEqual(r.rubric, {grammar: 30, vocabulary: 30, content: 20});
assert.equal(r.points, 8);

console.log("marking: all checks passed");
