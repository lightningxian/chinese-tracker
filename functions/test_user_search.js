"use strict";

// Build 9A session 2: the Users list's search index (functions/user_search.js).
const assert = require("node:assert/strict");
const s = require("./user_search");

const f = s.searchFieldsOf({role: "student", latinName: "Angeline Santoso",
  nameChinese: "陈美琳", email: "Angeline.S@Mail.com"});
assert.equal(f.nameLower, "angeline santoso");
assert.equal(f.listed, true);
for (const q of ["a", "ang", "angeline s", "angeline santoso", "san", "santoso",
  "陈", "陈美", "angeline.s", "angeline.s@mail.com"]) {
  assert.ok(f.searchPrefixes.includes(s.normalizeQuery(q)), q);
}
assert.ok(!f.searchPrefixes.includes("geline"), "beginnings only, not the middle");
assert.equal(s.normalizeQuery("  Angeline   SAN "), "angeline san");
assert.equal(s.normalizeQuery("x".repeat(40)).length, s.MAX_PREFIX);
assert.ok(f.searchPrefixes.every((p) => [...p].length <= s.MAX_PREFIX));

// Waiting and rejected students are not in the list (they are under Approval).
assert.equal(s.searchFieldsOf({role: "student", status: "pending", name: "P"}).listed, false);
assert.equal(s.searchFieldsOf({role: "student", status: "rejected", name: "R"}).listed, false);
assert.equal(s.searchFieldsOf({role: "student", status: "active", name: "A"}).listed, true);
assert.equal(s.searchFieldsOf({role: "student", name: "Old"}).listed, true, "no status = approved");
assert.equal(s.searchFieldsOf({role: "teacher", status: "pending", name: "T"}).listed, true);

// The trigger writes only when something changed (no loop).
assert.equal(s.sameFields({...f}, f), true);
assert.equal(s.sameFields({...f, listed: false}, f), false);
assert.equal(s.sameFields({}, f), false);
assert.deepEqual(s.searchFieldsOf(null).searchPrefixes, []);
assert.equal(s.searchFieldsOf({name: "No flag"}).active, true, "missing active = true");
assert.equal(s.searchFieldsOf({name: "Off", active: false}).active, undefined, "kept as it is");

console.log("user_search: all passed");
