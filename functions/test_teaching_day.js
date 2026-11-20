"use strict";

// Build 7: the teaching day (docs/PLAN.md §4, VC-01, VC-02, VC-05).
const assert = require("node:assert/strict");
const t = require("./teaching_day");

// VC-01 arithmetic: hadir and alpa use a session, izin only returns the booking.
assert.deepEqual(t.closeEffect("hadir"), {booked: -1, used: 1, remaining: -1, delta: -1});
assert.deepEqual(t.closeEffect("alpa"), {booked: -1, used: 1, remaining: -1, delta: -1});
assert.deepEqual(t.closeEffect("izin"), {booked: -1, used: 0, remaining: 0, delta: 0});
assert.deepEqual(t.closeEffect(""), {booked: 0, used: 0, remaining: 0, delta: 0});

// VC-02: a done session is not closed again.
assert.equal(t.closeDecision("ongoing", false), "close");
assert.equal(t.closeDecision("done", true), "already-done");
assert.equal(t.closeDecision("scheduled", false), "not-started");
assert.equal(t.closeDecision("scheduled", true), "close", "an admin closes a forgotten one");
assert.equal(t.closeDecision("cancelled", true), "cancelled");

// Check-in window and the late rule (Jakarta 16:00 = 09:00 UTC).
const s = {sessionDate: "2026-11-23", startMinutes: 960, endMinutes: 1050, status: "scheduled"};
const at = (h, m) => Date.parse(`2026-11-23T${String(h).padStart(2, "0")}:${String(m).padStart(2, "0")}:00Z`);
assert.equal(t.checkInDecision(s, at(8, 29)).reason, "too_early");
assert.deepEqual(t.checkInDecision(s, at(8, 30)), {ok: true, lateMinutes: 0});
assert.deepEqual(t.checkInDecision(s, at(9, 15)), {ok: true, lateMinutes: 0}, "15 minutes is not late");
assert.deepEqual(t.checkInDecision(s, at(9, 20)), {ok: true, lateMinutes: 20});
assert.equal(t.checkInDecision(s, at(10, 31)).reason, "too_late");

// Late flag, unclosed flag, reminder window — each once.
assert.ok(!t.lateCheckInDue(s, at(9, 14)));
assert.ok(t.lateCheckInDue(s, at(9, 15)));
assert.ok(!t.lateCheckInDue({...s, lateCheckIn: true}, at(9, 30)));
assert.ok(!t.lateCheckInDue({...s, status: "ongoing"}, at(9, 30)));
assert.ok(!t.unclosedDue(s, at(12, 29)));
assert.ok(t.unclosedDue(s, at(12, 30)));
assert.ok(!t.unclosedDue({...s, status: "done"}, at(13, 0)));
assert.ok(t.reminderDue(s, at(8, 0)));
assert.ok(!t.reminderDue(s, at(7, 59)), "more than an hour before");
assert.ok(!t.reminderDue({...s, reminderSentAt: 1}, at(8, 30)));
assert.ok(!t.reminderDue(s, at(9, 0)), "not after the start");

// Recap and reconciliation (VC-05).
assert.equal(t.sessionHours(s), 1.5);
assert.equal(t.monthKey("2026-11-23"), "202611");
assert.deepEqual(t.reconcileTerm({sessionsUsed: 3, sessionsBooked: 1}, 3, 1), []);
assert.equal(t.reconcileTerm({sessionsUsed: 4, sessionsBooked: 1}, 3, 1).length, 1);
assert.equal(t.reconcileTerm({sessionsUsed: 3, sessionsBooked: 0}, 3, 1).length, 1);

// Month recap rows.
const rows = t.recapRows(
    [{teacherId: "t1", teacherName: "Budi", held: 2, hours: 3, lateCheckIns: 1, cancelled: 1}],
    [{teacherId: "t1", teacherName: "Budi"}, {teacherId: "t1"}, {teacherId: "t1"},
      {teacherId: "t2", teacherName: "Ani"}]);
assert.equal(rows.length, 2);
assert.equal(rows[0].teacherName, "Ani");
assert.deepEqual(rows[1], {teacherId: "t1", teacherName: "Budi", scheduled: 3, held: 2,
  cancelled: 1, lateCheckIns: 1, hours: 3});

console.log("test_teaching_day: all passed (VC-01, VC-02, VC-05 logic)");
