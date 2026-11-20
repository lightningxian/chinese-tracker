"use strict";

// Build 4: progress summary logic (docs/PLAN.md §4, spec §9).
const assert = require("node:assert/strict");
const p = require("./progress");

const DAY = p.DAY_MS;
// Thursday 2026-11-19 12:00 Jakarta = 05:00 UTC.
const NOW = Date.parse("2026-11-19T05:00:00Z");
const daysAgo = (n) => NOW - n * DAY;

// ---- Jakarta days and ISO weeks.
assert.equal(p.jakartaDate(Date.parse("2026-11-15T16:59:59Z")), "2026-11-15");
assert.equal(p.jakartaDate(Date.parse("2026-11-15T17:00:00Z")), "2026-11-16",
    "Jakarta midnight is 17:00 UTC");
// Sunday 23:59 Jakarta is still the old week; Monday 00:00 the new one.
assert.equal(p.isoWeek(Date.parse("2026-11-15T16:59:00Z")).key, "2026-W46");
assert.equal(p.isoWeek(Date.parse("2026-11-15T17:00:00Z")).key, "2026-W47");
assert.equal(p.isoWeek(Date.parse("2026-11-15T17:00:00Z")).monday, "2026-11-16");
assert.equal(p.isoWeek(Date.parse("2027-01-01T05:00:00Z")).key, "2026-W53");
assert.equal(p.isoWeek(Date.parse("2026-01-01T05:00:00Z")).key, "2026-W01");
assert.equal(p.daysBetween("2026-11-19", "2026-11-26"), 7);

// ---- Practice: weeks, 14-day averages, pending marking left out.
const ex = (dAgo, score, extra = {}) => ({submittedAtMs: daysAgo(dAgo), score, ...extra});
let pr = p.practiceOf([ex(1, 80), ex(2, 60), ex(20, 90), ex(15, 70), ex(3, 10,
    {status: "pending_marking"}), ex(100, 50)], NOW);
assert.equal(pr.weeks.length, 12);
assert.equal(pr.weeks[11].week, "2026-W47");
assert.equal(pr.weeks[11].average, 70);
assert.equal(pr.weeks[11].attempts, 2);
assert.equal(pr.average14, 70);
assert.equal(pr.averagePrev14, 80);
assert.equal(pr.attempts90, 4);
assert.equal(pr.lastPracticeMs, daysAgo(1));

// ---- Skills over 90 days.
const sk = p.skillsOf([
  ex(1, 0, {bySkill: {listening: {correct: 3, total: 4}, reading: {correct: 1, total: 2}}}),
  ex(5, 0, {bySkill: {listening: {correct: 1, total: 4}}}),
  ex(95, 0, {bySkill: {typing: {correct: 1, total: 1}}}),
], NOW);
assert.deepEqual(Object.keys(sk).sort(), ["listening", "reading"]);
assert.equal(sk.listening.percent, 50);
assert.equal(sk.reading.percent, 50);

// ---- Attendance: hadir ÷ (hadir + alpa), izin left out, 30 days.
const att = (dAgo, status) => ({sessionDate: p.jakartaDate(daysAgo(dAgo)), status});
let at = p.attendanceOf([att(1, "hadir"), att(3, "izin"), att(5, "alpa"), att(7, "hadir"),
  att(9, "present"), att(40, "alpa"), att(2, null)], NOW);
assert.equal(at.hadir, 3);
assert.equal(at.izin, 1);
assert.equal(at.alpa, 1);
assert.equal(at.percent, 75);
assert.equal(at.records30, 5);
assert.equal(at.last.length, 6);

// ---- Warnings at and beside their boundaries.
const base = (extra = {}) => ({
  attendance: {percent: 100, records30: 5, hadir: 5, alpa: 0},
  practice: {attempts14: 3, average14: 80, attemptsPrev14: 3, averagePrev14: 80,
    lastPracticeMs: daysAgo(1)},
  voucher: {sessionsRemaining: 5, daysLeft: 30},
  tests: {history: []},
  activeSinceMs: daysAgo(100),
  ...extra,
});
const ids = (s) => p.warningsOf(s, NOW).map((w) => w.id);
assert.deepEqual(ids(base()), []);
// 1: under 75 with at least 4 records.
assert.deepEqual(ids(base({attendance: {percent: 74, records30: 4, hadir: 3, alpa: 1}})), [1]);
assert.deepEqual(ids(base({attendance: {percent: 75, records30: 4, hadir: 3, alpa: 1}})), []);
assert.deepEqual(ids(base({attendance: {percent: 50, records30: 3, hadir: 1, alpa: 1}})), [],
    "fewer than 4 records: no warning");
// 2: average under 60, or 10 points under the 14 days before.
const prac = (a14, n14, prev, nPrev) => base({practice: {attempts14: n14, average14: a14,
  attemptsPrev14: nPrev, averagePrev14: prev, lastPracticeMs: daysAgo(1)}});
assert.deepEqual(ids(prac(59.9, 2, null, 0)), [2]);
assert.deepEqual(ids(prac(60, 2, null, 0)), []);
assert.deepEqual(ids(prac(50, 1, null, 0)), [], "one attempt is not enough");
assert.deepEqual(ids(prac(70, 2, 80, 2)), [2], "a 10-point drop");
assert.deepEqual(ids(prac(70.1, 2, 80, 2)), []);
assert.deepEqual(ids(prac(70, 2, 80, 1)), [], "the window before needs 2 attempts");
// 3: no practice for 14 days; never practised counts from approval.
assert.deepEqual(ids(base({practice: {attempts14: 0, lastPracticeMs: daysAgo(14)}})), [3]);
assert.deepEqual(ids(base({practice: {attempts14: 0, lastPracticeMs: daysAgo(13.9)}})), []);
assert.deepEqual(ids(base({practice: {attempts14: 0, lastPracticeMs: null},
  activeSinceMs: daysAgo(20)})), [3]);
assert.deepEqual(ids(base({practice: {attempts14: 0, lastPracticeMs: null},
  activeSinceMs: daysAgo(3)})), []);
// 4: 2 or fewer sessions, or the deadline within 7 days.
assert.deepEqual(ids(base({voucher: {sessionsRemaining: 2, daysLeft: 30}})), [4]);
assert.deepEqual(ids(base({voucher: {sessionsRemaining: 3, daysLeft: 8}})), []);
assert.deepEqual(ids(base({voucher: {sessionsRemaining: 3, daysLeft: 7}})), [4]);
assert.deepEqual(ids(base({voucher: null})), []);
// 5: the last two counted results failed (placement / invalid / pending skipped).
const t = (code, passed, ms, extra = {}) => ({code, codeId: code, passed, finishedAtMs: ms,
  valid: true, status: "final", ...extra});
const tests = (rows) => base({tests: p.testsOf(rows, "3")});
assert.deepEqual(ids(tests([t("A", false, 1), t("B", false, 2)])), [5]);
assert.deepEqual(ids(tests([t("A", false, 1), t("B", true, 2)])), []);
assert.deepEqual(ids(tests([t("A", false, 1), t("B", false, 2),
  t("C", true, 3, {placement: true})])), [5], "a placement result does not break the row");
assert.deepEqual(ids(tests([t("A", false, 1), t("B", false, 2, {valid: false})])), []);
assert.deepEqual(ids(tests([t("A", false, 1)])), []);
// `since` stays from the previous summary.
const prevW = [{id: 4, since: daysAgo(3)}];
assert.equal(p.warningsOf(base({voucher: {sessionsRemaining: 1, daysLeft: 30}}), NOW, prevW)[0].since,
    daysAgo(3));

// ---- Status label.
assert.equal(p.statusOf([]), "good");
assert.equal(p.statusOf([{id: 1}]), "attention");
assert.equal(p.statusOf([{id: 1}, {id: 3}]), "follow_up");

// ---- Tests passed at the level and the history order.
const th = p.testsOf([t("A", true, 1, {level: "HSK 3"}), t("B", true, 3, {level: "HSK 3"}),
  t("A", true, 2, {level: "HSK 3"}), t("C", true, 4, {level: "HSK 2"}),
  t("D", true, 5, {level: "HSK 3", placement: true})], "3");
assert.equal(th.passedAtLevel, 2);
assert.deepEqual(th.history.map((x) => x.code), ["D", "C", "B", "A", "A"]);

// ---- The whole summary.
const s = p.summarize({
  user: {level: "HSK 3", activeSinceMs: daysAgo(200)},
  promotion: {count: 2, minCodes: 3, next: "HSK 4"},
  exercises: [ex(1, 90), ex(3, 85)],
  attendance: [att(1, "hadir"), att(2, "hadir"), att(4, "hadir"), att(6, "hadir")],
  terms: [{id: "t1", status: "active", sessionsRemaining: 6, deadlineDate: "2026-12-31"},
    {id: "t0", status: "depleted", sessionsRemaining: 0, deadlineDate: "2026-10-01"}],
  tests: [],
  note: {text: "Good work", teacherName: "Andrea", createdAtMs: daysAgo(2)},
  levelHistory: [{from: "HSK 2", to: "HSK 3", dateMs: daysAgo(60)}],
}, NOW);
assert.equal(s.status, "good");
assert.equal(s.group, "intermediate");
assert.equal(s.codes.count, 2);
assert.equal(s.voucher.termId, "t1");
assert.equal(s.voucher.daysLeft, 42);
assert.equal(s.attendance.percent, 100);
assert.equal(s.latestNote.text, "Good work");

// ---- Notices: once per 7 days per warning.
const warned = {warnings: [{id: 1, detail: "a"}, {id: 4, detail: "b"}]};
assert.deepEqual(p.noticesDue(warned, NOW, {}).map((n) => n.id), [1, 4]);
assert.deepEqual(p.noticesDue(warned, NOW, {"1": daysAgo(6.9)}).map((n) => n.id), [4]);
assert.deepEqual(p.noticesDue(warned, NOW, {"1": daysAgo(7)}).map((n) => n.id), [1, 4]);
assert.deepEqual(p.noticesDue({warnings: []}, NOW, {}), [], "a cleared warning sends nothing");
assert.deepEqual(p.noticesDue(warned, NOW, {}).find((n) => n.id === 4).roles, ["student", "admin"]);

console.log("test_progress: all passed");
