"use strict";

// Build 2B: leaderboard and promotion logic (docs/PLAN.md §4, spec §8 and
// §13: LV-01, LV-03, LB-01). Names and marks invented for the test.
const assert = require("node:assert/strict");
const p = require("./promotion");

const code = (id, levelKey = "3", extra = {}) =>
  ({code: id, family: "hsk", levelKey, countsForPromotion: true, ...extra});
const result = (codeId, total, extra = {}) => ({
  codeId, studentId: "s1", family: "hsk", levelKey: "3", total, max: 300,
  passed: total >= 180, valid: true, status: "final", ...extra,
});
const row = (codeId, total, extra = {}, codeExtra = {}) =>
  ({result: result(codeId, total, extra), code: code(codeId, "3", codeExtra)});

// Levels and groups.
assert.equal(p.levelKeyOf("HSK 3"), "3");
assert.equal(p.levelKeyOf("hsk3"), "3");
assert.equal(p.levelKeyOf("YCT"), "");
assert.equal(p.nextLevelKey("3"), "4");
assert.equal(p.nextLevelKey("6"), null);
assert.deepEqual(["1", "2", "3", "4", "5", "6"].map(p.groupOf),
    ["beginner", "beginner", "intermediate", "intermediate", "advance", "advance"]);

// LV-01, the spec's example: an HSK 3 student, code A 170 (fail), B 195,
// C 200, D 205 → three passes → recommend HSK 4.
let s = p.promotionState(
    [row("A", 170), row("B", 195), row("C", 200), row("D", 205)], "3", 3);
assert.deepEqual(s.codes, ["B", "C", "D"]);
assert.equal(s.count, 3);
assert.equal(s.reached, true);
assert.equal(s.next, "4");

// LV-03: two passes and one fail → 2 of 3, no recommendation.
s = p.promotionState([row("A", 170), row("B", 195), row("C", 200)], "3", 3);
assert.equal(s.count, 2);
assert.equal(s.reached, false);

// What does not count: pending marking, invalid, placement, a code that does
// not count for promotion, another level, another family; one code once.
s = p.promotionState([
  row("B", 195),
  row("C", 200),
  row("D", 205, {status: "pending_marking", passed: false}),
  row("E", 210, {valid: false}),
  row("F", 220, {placement: true}),
  row("G", 230, {}, {countsForPromotion: false}),
  {result: result("H", 240, {levelKey: "2"}), code: code("H", "2")},
  {result: result("Y", 250, {family: "yct"}), code: code("Y", "3", {family: "yct"})},
  row("C", 260),
], "3", 3);
assert.deepEqual(s.codes, ["B", "C"]);
assert.equal(s.reached, false);
// minCodes from the settings.
assert.equal(p.promotionState([row("B", 195), row("C", 200)], "3", 2).reached, true);
// HSK 6 has no next level.
s = p.promotionState(["X", "Y", "Z"].map((c) =>
  ({result: result(c, 250, {levelKey: "6"}), code: code(c, "6")})), "6", 3);
assert.equal(s.count, 3);
assert.equal(s.reached, false);

// Board entries: only final, valid, not placement; the peer label, never
// the Latin full name.
assert.equal(p.entryOf(result("A", 200, {status: "pending_marking"}), code("A")), null);
assert.equal(p.entryOf(result("A", 200, {valid: false}), code("A")), null);
assert.equal(p.entryOf(result("A", 200, {placement: true}), code("A")), null);
let e = p.entryOf(result("A", 200, {studentName: "Angeline Santoso",
  studentNameChinese: "陈美琳", durationSeconds: 3000,
  parts: [{skill: "listening", mark: 70, maxScore: 100}]}), code("A"));
assert.equal(e.name, "陈美琳");
assert.equal(e.passed, true);
assert.deepEqual(e.parts, [{skill: "listening", mark: 70, maxScore: 100}]);
e = p.entryOf(result("A", 200, {studentName: "Angeline Santoso"}), code("A"));
assert.equal(e.name, "Angeline", "no Chinese name: the first word only");
assert.ok(!JSON.stringify(e).includes("Santoso"));

// LB-01: 15 results of one code against a ranking written by hand.
// total desc; equal total → fewer seconds; equal both → earlier finish.
const people = [
  // [name, total, seconds, finished minute]
  ["甲", 250, 3400, 5], ["乙", 280, 3600, 1], ["丙", 250, 3100, 9],
  ["丁", 199, 3500, 2], ["戊", 280, 3500, 7], ["己", 150, 2000, 3],
  ["庚", 250, 3100, 4], ["辛", 300, 3700, 8], ["壬", 179, 3000, 6],
  ["癸", 220, 3300, 1], ["子", 220, 3300, 2], ["丑", 260, 3550, 3],
  ["寅", 180, 3550, 4], ["卯", 0, null, 10], ["辰", 240, 2900, 5],
];
const entries = people.map(([name, total, seconds, minute], i) => p.entryOf(
    result("L1", total, {studentId: `u${i}`, studentNameChinese: name,
      durationSeconds: seconds, finishedAt: new Date(Date.UTC(2026, 10, 20, 9, minute))}),
    code("L1")));
const ranked = p.rankEntries(entries);
const byHand = [
  [1, "辛", 300], [2, "戊", 280], [3, "乙", 280], [4, "丑", 260],
  [5, "庚", 250], [5, "丙", 250], [7, "甲", 250], [8, "辰", 240],
  [9, "癸", 220], [9, "子", 220], [11, "丁", 199], [12, "寅", 180],
  [13, "壬", 179], [14, "己", 150], [15, "卯", 0],
];
assert.deepEqual(ranked.map((x) => [x.rank, x.name, x.total]), byHand);
assert.deepEqual(ranked.map((x) => x.passed), byHand.map(([, , t]) => t >= 180));

console.log("promotion: all checks passed (LV-01, LV-03, LB-01)");
