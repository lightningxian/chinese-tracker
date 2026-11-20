// Build 8: the question import (scripts/import_questions.mjs) on a sample
// file with placeholder text (no Chinese content is invented).
import assert from "node:assert/strict";
import {loadRows, parseCsv, toBankDoc} from "../scripts/import_questions.mjs";

const rows = loadRows("test/fixtures/import_sample/sample_questions.csv");
assert.equal(rows.length, 4);
assert.equal(rows[1].prompt, "Sample prompt, with a comma", "quoted commas");
const docs = rows.map((r, i) => toBankDoc(r, i + 2, "owner1"));
assert.equal(docs[0].id, "imp_SAMPLE-L_001");
assert.deepEqual(docs[0].doc.question, {prompt: "Sample listening prompt 1",
  options: ["option A", "option B", "option C"], correctIndex: 1,
  explanation: "Sample explanation"});
assert.equal(docs[0].audio, "sample_audio.mp3");
assert.equal(docs[1].doc.question.correctIndex, 0, "1-based number");
assert.deepEqual(docs[2].doc.question.segments, ["piece one", "piece two", "piece three"]);
assert.equal(docs[2].doc.skillCategory, "typing");
assert.equal(docs[3].doc.sheetIndex, 1);
assert.throws(() => toBankDoc({...rows[0], correct: "E"}, 9, "o"), /row 9: correct/);
assert.throws(() => toBankDoc({...rows[0], level: "HSK 7"}, 9, "o"), /level/);
assert.throws(() => toBankDoc({...rows[0], type: "speaking"}, 9, "o"), /type/);
assert.equal(parseCsv("a,b\n\"x\"\"y\",2\n")[0].a, "x\"y");
console.log("test_import_questions: all passed");
