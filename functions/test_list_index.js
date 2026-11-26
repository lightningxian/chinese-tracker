"use strict";

// Build 9 part 2: the worksheet index and the package list fields.
const assert = require("node:assert/strict");
const x = require("./list_index");

// Sheet key: the code field, else a code-shaped tag; stand-alone otherwise.
assert.equal(x.sheetKeyOf({sheetCode: "SC3-01"}), "SC3-01");
assert.equal(x.sheetKeyOf({tags: ["hsk3", "310001-RDG"]}), "310001-RDG");
assert.equal(x.sheetKeyOf({tags: ["hsk3"]}), null);
assert.equal(x.sheetDocId("310001-RDG"), "s_310001-RDG");
assert.equal(x.sheetDocId(null, "abc"), "q_abc");

// A worksheet: sheet order, title from any question, newest time, recording.
const items = [
  {id: "b", sheetCode: "H31", sheetIndex: 1, prompt: "第二", type: "multiple_choice",
    category: "hsk_simulation", level: "HSK 3", usageCount: 2, createdBy: "t1", createdAt: 3000},
  {id: "a", sheetCode: "H31", sheetIndex: 0, prompt: "你好吗", type: "true_false",
    category: "hsk_simulation", level: "HSK 3", usageCount: 1, sheetTitle: "HSK 3 Paper",
    createdBy: "t1", createdAt: 1000},
];
const s = x.sheetSummaryOf("H31", items);
assert.deepEqual(s.itemIds, ["a", "b"], "sheet order");
assert.equal(s.type, "true_false", "type of the first question in sheet order");
assert.equal(s.title, "HSK 3 Paper");
assert.equal(s.count, 2);
assert.equal(s.usageCount, 3);
assert.equal(s.createdAtMs, 3000, "listed by its newest question");
assert.equal(s.missingRecording, true, "HSK sheet without its recording");
assert.deepEqual(s.creators, ["t1"]);
for (const q of ["h", "hsk", "paper", "h31", "你好", "第二"]) {
  assert.ok(s.searchPrefixes.includes(q), `search finds "${q}"`);
}
assert.equal(x.sheetSummaryOf("H31", [{...items[0], sectionAudioUrl: "u"}]).missingRecording, false);
assert.equal(x.sheetSummaryOf("H31", []), null, "an emptied sheet is removed");

// A stand-alone question is its own row, titled by its text.
const q = x.sheetSummaryOf(null, [{id: "q1", question: {segments: ["我", "是"]}, type: "compose_sentences"}]);
assert.equal(q.itemId, "q1");
assert.equal(q.title, "我 / 是");
assert.equal(q.isSheet, false);
assert.equal(q.missingRecording, false);

// Package list fields.
const f = x.exerciseListFieldsOf({title: "Latihan Membaca", bankSheets: ["H31"], createdAt: 5},
    "hsk_simulation", 99);
assert.equal(f.listCategory, "hsk_simulation");
assert.equal(f.listSkill, "reading", "a missing skill reads as reading");
assert.equal(f.listPublished, true);
assert.equal(f.listAt, 5);
assert.ok(f.searchPrefixes.includes("membaca"));
assert.equal(x.exerciseListFieldsOf({title: "Old", questions: [{}]}, null, 99).listCategory, "exercise");
assert.equal(x.exerciseListFieldsOf({title: "P", bankQuestionIds: ["z"]}, null, 99).listCategory,
    "unknown", "a package whose worksheets were deleted");
assert.equal(x.exerciseListFieldsOf({title: "P"}, null, 99).listAt, 99, "no createdAt: now");
assert.equal(x.sameListFields({...f}, f), true);
assert.equal(x.sameListFields({...f, listSkill: "writing"}, f), false);

console.log("test_list_index: all passed");
