// Build 8: SUS scoring on a known sheet (mean 72.5).
import assert from "node:assert/strict";
import {parseCsv, summarise, susScore} from "./sus_score.mjs";

const sample = `respondent,role,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10
R01,student,4,2,4,2,4,2,3,2,3,2
R02,student,4,2,4,2,4,2,4,2,4,2
R03,teacher,3,2,3,2,3,2,3,2,3,3
R04,admin,5,2,5,1,4,2,4,1,4,2
`;
const rows = parseCsv(sample);
assert.deepEqual(rows.map((r) => susScore(r.answers)), [70, 75, 60, 85]);
const s = summarise(rows);
assert.equal(s.mean, 72.5);
assert.equal(s.aboveTarget, true);
assert.deepEqual(s.byRole, {student: 72.5, teacher: 60, admin: 85});
assert.equal(s.itemMeans[0], 4);
assert.equal(susScore([5, 1, 5, 1, 5, 1, 5, 1, 5, 1]), 100);
assert.equal(susScore([1, 5, 1, 5, 1, 5, 1, 5, 1, 5]), 0);
assert.throws(() => parseCsv("respondent,role,q1\nX,student,9"), /1 to 5/);
console.log("test_sus_score: all passed (mean 72.5 on the sample)");
