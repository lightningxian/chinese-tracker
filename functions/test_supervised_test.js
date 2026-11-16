"use strict";
// Run with: node functions/test_supervised_test.js
const assert = require("assert");
const t = require("./supervised_test");

// Thesis scenario IDs (docs/THESIS_FEATURE_BACKLOG.md §13) proved here:
// TS-01 (token shape; the join window is checked by startTest with
// JOIN_WINDOW_SECONDS), PN-05 (late answers). TS-02, PN-04 and LV-02 are in
// rules-tests and the emulator walk.

// ---- TS-01 Tokens: 6 characters, no 0/O/1/I, typed in any case.
let n = 0;
const token = t.makeToken((max) => (n++ * 7) % max);
assert.strictEqual(token.length, 6);
assert.ok(!/[0O1I]/.test(token), "no look-alike characters");
assert.ok([...token].every((c) => t.TOKEN_ALPHABET.includes(c)));
assert.strictEqual(t.normalizeToken(" ab c2 3d "), "ABC23D");
assert.strictEqual(t.normalizeToken("ABC10D"), null, "0/1 are never in a token");
assert.strictEqual(t.normalizeToken("ABCDE"), null, "too short");
assert.strictEqual(t.normalizeToken(""), null);
assert.strictEqual(t.JOIN_WINDOW_SECONDS, 900, "15-minute join window");

// ---- Codes are upper case without spaces.
assert.strictEqual(t.normalizeTestCode(" h31 005 "), "H31005");

// ---- A worksheet split into an HSK 3-style format by skill, in order.
const q = (id, skill, correctIndex = 0, extra = {}) => ({
  id, type: "multiple_choice", skillCategory: skill,
  question: {prompt: id, options: ["A", "B", "C"], correctIndex}, ...extra,
});
const items = [
  q("L1", "listening"), q("L2", "listening"), q("L3", "listening", 1),
  q("R1", "reading"), q("R2", undefined), // missing skill = reading
  q("W1", "typing", 2, {points: 2}), // writing is stored as typing
  q("S1", "speaking"), // no speaking part: left out
];
const format = {
  parts: [
    {skill: "listening", questions: 3, minutes: 2, maxScore: 100},
    {skill: "reading", questions: 3, minutes: 2, maxScore: 100},
    {skill: "writing", questions: 1, minutes: 1, maxScore: 100},
  ],
  passMark: 180,
};
const split = t.splitIntoParts(items, t.cleanFormat(format).parts);
assert.deepStrictEqual(split.map((p) => p.map((i) => i.id)),
    [["L1", "L2", "L3"], ["R1", "R2"], ["W1"]]);

// Expected vs found per part (a warning for the admin, not a block).
assert.deepStrictEqual(t.partCounts(items, format), [
  {skill: "listening", expected: 3, found: 3},
  {skill: "reading", expected: 3, found: 2},
  {skill: "writing", expected: 1, found: 1},
]);

// Two parts of the same skill: the first fills up, the rest go on.
const twoReading = t.splitIntoParts(
    [q("a", "reading"), q("b", "reading"), q("c", "reading")],
    [{skill: "reading", questions: 2}, {skill: "reading", questions: 5}]);
assert.deepStrictEqual(twoReading.map((p) => p.map((i) => i.id)), [["a", "b"], ["c"]]);

// cleanFormat: whole minutes ≥ 1, unknown skill → reading.
assert.deepStrictEqual(t.cleanFormat({parts: [{skill: "x", questions: "4", minutes: 0,
  maxScore: 99.6}], passMark: "60"}), {parts: [{skill: "reading", questions: 4,
  minutes: 1, maxScore: 100}], passMark: 60});

// ---- Marks: earned ÷ possible × maxScore, rounded; 1 point unless set.
assert.strictEqual(t.pointsOf(items[0]), 1);
assert.strictEqual(t.pointsOf(items[5]), 2);
const p0 = t.scorePart(split[0], {L1: {index: 0}, L2: {index: 2}, L3: {index: 1}}, 100);
assert.deepStrictEqual(p0, {earned: 2, possible: 3, mark: 67, correct: 2, total: 3});
assert.strictEqual(t.scorePart([], {}, 100).mark, 0, "empty part = 0, no division by 0");

const full = t.scoreTest(split, format, {
  "0": {L1: {index: 0}, L2: {index: 0}, L3: {index: 1}}, // 3/3 → 100
  "1": {R1: {index: 0}}, // 1/2 → 50
  "2": {W1: {index: 2}}, // 2/2 points → 100
}, true);
assert.deepStrictEqual(full.parts.map((p) => p.mark), [100, 50, 100]);
assert.strictEqual(full.total, 250);
assert.strictEqual(full.max, 300);
assert.strictEqual(full.passMark, 180);
assert.strictEqual(full.passed, true);

// A part never submitted counts as empty (closeTestSession).
const stopped = t.scoreTest(split, format, {"0": {L1: {index: 0}}}, true);
assert.deepStrictEqual(stopped.parts.map((p) => p.mark), [33, 0, 0]);
assert.strictEqual(stopped.passed, false);

// Invalid results never pass.
assert.strictEqual(t.isPassed(250, 180, false), false);
assert.strictEqual(t.isPassed(180, 180, true), true, "pass mark itself passes");
assert.strictEqual(t.isPassed(179, 180, true), false);

// ---- Part clocks.
assert.strictEqual(t.partSeconds(format, 0), 120);
assert.strictEqual(t.partSeconds(format, 9), 0);
const start = 1_000_000;
assert.strictEqual(t.secondsLeft(start, 120, start + 30_500), 90);
assert.strictEqual(t.secondsLeft(start, 120, start + 999_000), 0, "never negative");
assert.strictEqual(t.elapsedSeconds(start, start + 45_900), 45, "recording position");
// PN-05: answers after the server deadline (part clock + grace) are refused
// (stored as empty by submitTestPart).
assert.strictEqual(t.isPartLate(start, 120, 180, start + 300_000), false, "PN-05 on the edge");
assert.strictEqual(t.isPartLate(start, 120, 180, start + 300_001), true, "PN-05 late");
// Duration for the Build 2 tie-break.
assert.strictEqual(t.durationSeconds(start, start + 61_400), 61);
assert.strictEqual(t.durationSeconds(0, start), 0, "no start, no duration");

// ---- One clock for the whole paper (session option partClocks = false).
const single = t.clockFormat(format, false);
assert.strictEqual(single.parts.length, 1);
assert.strictEqual(t.partSeconds(single, 0), 5 * 60, "2 + 2 + 1 minutes");
assert.strictEqual(t.clockFormat(format, true).parts.length, 3, "part clocks as planned");
assert.strictEqual(t.clockFormat(format, undefined).parts.length, 3, "default: part clocks");

// ---- Only the part's own questions are stored, in known shapes.
assert.deepStrictEqual(
    t.answersForPart(split[1], {R1: {index: 1, evil: true}, L1: {index: 0}, R2: "x"}),
    {R1: {index: 1}}, "other parts' answers and junk are dropped");
assert.deepStrictEqual(t.sanitizeAnswer({order: ["a", 1], text: "好"}),
    {order: ["a", "1"], text: "好"});

// ---- Left-page events keep the last 20.
let events = [];
for (let i = 0; i < 25; i++) events = t.appendEvent(events, {type: "left", at: i});
assert.strictEqual(events.length, 20);
assert.strictEqual(events[0].at, 5);

// ---- Result numbers are stable and dated.
const rn = t.resultNumber("H31005_uid1", Date.UTC(2026, 10, 16));
assert.match(rn, /^ES-20261116-[A-Z2-9]{6}$/);
assert.strictEqual(rn, t.resultNumber("H31005_uid1", Date.UTC(2026, 10, 16)));
assert.notStrictEqual(rn, t.resultNumber("H31005_uid2", Date.UTC(2026, 10, 16)));

console.log("supervised_test: all checks passed");
