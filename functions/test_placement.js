"use strict";

// Build 3: placement logic (docs/PLAN.md §4, PL-01, PL-02).
const assert = require("node:assert/strict");
const p = require("./placement");

// The recommendation rule: passed = paper level + 1, failed = paper level.
assert.equal(p.recommendedKey("HSK 3", true), "4");
assert.equal(p.recommendedKey("HSK 3", false), "3");
assert.equal(p.recommendedKey("HSK 6", true), "6");
assert.equal(p.recommendedKey("YCT", true), "");

// PL-01: approved at HSK 1, passes an HSK 3 paper → HSK 1 → HSK 4.
assert.deepEqual(p.recommendationFor("HSK 1", "HSK 3", true), {fromKey: "1", toKey: "4"});
// Fails it → HSK 3.
assert.deepEqual(p.recommendationFor("HSK 1", "HSK 3", false), {fromKey: "1", toKey: "3"});
// Nothing when it equals the current level.
assert.equal(p.recommendationFor("HSK 3", "HSK 3", false), null);
assert.equal(p.recommendationFor("HSK 2", "HSK 1", true), null);
// No level yet counts as HSK 1.
assert.deepEqual(p.recommendationFor("", "HSK 2", true), {fromKey: "1", toKey: "3"});

// Result codes: 6 characters, no 0/O/1/I, normalised.
let n = 0;
const seq = () => n++;
const code = p.makeResultCode((max) => seq() % max);
assert.equal(code.length, 6);
assert.ok(!/[01IO]/.test(code));
for (let i = 0; i < 200; i++) {
  const c = p.makeResultCode((max) => Math.floor(Math.random() * max));
  assert.ok(/^[A-HJ-NP-Z2-9]{6}$/.test(c), c);
}
assert.equal(p.normalizeResultCode(" abc-def "), "ABCDEF");
assert.equal(p.normalizeResultCode("ABCDE0"), "");
assert.equal(p.normalizeResultCode("ABCDEFG"), "");
assert.equal(p.normalizeResultCode(""), "");

// Visitor key: only the hash is stored; the key matches its hash only.
const key = p.makeVisitorKey();
assert.match(key, /^[0-9a-f]{32}$/);
const hash = p.hashKey(key);
assert.ok(p.keyMatches(key, hash));
assert.ok(!p.keyMatches(p.makeVisitorKey(), hash));
assert.ok(!p.keyMatches("", hash));
assert.ok(!p.keyMatches(key.toUpperCase(), hash));
assert.ok(!p.keyMatches(key, ""));

// Name and WhatsApp.
assert.equal(p.cleanVisitorName("  Budi   Santoso "), "Budi Santoso");
assert.equal(p.cleanVisitorName("B"), "");
assert.equal(p.cleanWhatsapp("+62 812-3456-7890"), "+6281234567890");
assert.equal(p.cleanWhatsapp("0812 3456 789"), "08123456789");
assert.equal(p.cleanWhatsapp("12345"), "");
assert.equal(p.cleanWhatsapp("0812abc"), "");

// Menu entry: minutes summed, question counts from the paper.
const entry = p.menuEntry("H1PLACE", {code: "H1PLACE", level: "HSK 1"},
    {parts: [{skill: "listening", minutes: 2, questions: 3}, {skill: "reading", minutes: 2}]},
    [3, 3]);
assert.equal(entry.minutes, 4);
assert.deepEqual(entry.parts.map((x) => x.questions), [3, 3]);

// Follow-up 2026-11-23: visitor details are cleared after 180 days.
const DAY = 86400000;
const NOWR = Date.parse("2027-06-01T00:00:00Z");
const old = {name: "Visitor", whatsapp: "0812", claimedBy: "", finishedAtMs: NOWR - 181 * DAY};
assert.equal(p.retentionDue(old, NOWR), true);
assert.equal(p.retentionDue({...old, finishedAtMs: NOWR - 179 * DAY}, NOWR), false);
assert.equal(p.retentionDue({...old, claimedBy: "uid1"}, NOWR), false, "a claimed result stays");
assert.equal(p.retentionDue({...old, name: "", whatsapp: ""}, NOWR), false, "already cleared");
assert.equal(p.retentionDue({...old, finishedAtMs: NOWR - 40 * DAY}, NOWR, 30), true);

console.log("test_placement: all passed");
