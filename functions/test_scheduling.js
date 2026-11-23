"use strict";

// Build 6: timetable and booking logic (docs/PLAN.md §4, JD-01, JD-02, VC-04).
const assert = require("node:assert/strict");
const s = require("./scheduling");

// Overlap with the gap.
const r = (a, b) => ({startMinutes: a, endMinutes: b});
assert.ok(s.overlaps(r(960, 1050), r(990, 1080)));
assert.ok(!s.overlaps(r(960, 1050), r(1050, 1140), 0), "back to back without a gap is fine");
assert.ok(s.overlaps(r(960, 1050), r(1050, 1140), 15), "15 minutes are needed in between");
assert.ok(!s.overlaps(r(960, 1050), r(1065, 1155), 15));
assert.ok(!s.overlaps(r(600, 690), r(960, 1050), 15));
assert.equal(s.DEFAULTS.minGapMinutes, 0, "owner 2026-11-23: no gap unless the admin sets one");

// Availability.
assert.ok(s.insideAvailability([r(900, 1200)], 960, 1050));
assert.ok(!s.insideAvailability([r(900, 1000)], 960, 1050));
assert.ok(!s.insideAvailability([], 960, 1050));

// Weekdays and Jakarta days.
assert.equal(s.weekdayOf("2026-11-23"), 1, "a Monday");
assert.equal(s.weekdayOf("2026-11-29"), 7, "a Sunday");
assert.equal(s.jakartaDate(Date.parse("2026-11-22T17:00:00Z")), "2026-11-23");
assert.equal(s.clock(990), "16:30");

// Form checks, the level check.
const andrea = {name: "Andrea", levels: ["HSK 1", "HSK 2", "HSK 3"]};
const base = {className: "Kelas Dasar B", weekday: 1, startMinutes: 960, endMinutes: 1050,
  capacity: 8, teacherId: "t1", room: "Main", level: ""};
assert.deepEqual(s.validate(base, andrea), []);
assert.deepEqual(s.validate({...base, level: "HSK 5"}, andrea).map((x) => x.code), ["level"]);
assert.deepEqual(s.validate({...base, endMinutes: 900}, andrea).map((x) => x.code), ["time"]);
assert.deepEqual(s.validate({...base, capacity: 0}, andrea).map((x) => x.code), ["capacity"]);

// JD-01 conflicts: teacher, room, availability, with the class named.
const existing = {id: "x", className: "Kelas Dasar A", weekday: 1, startMinutes: 960,
  endMinutes: 1050, room: "Main", teacherId: "t1"};
const avail = {"1": [r(900, 1200)], "6": [r(600, 900)]};
let c = s.conflicts({...base, startMinutes: 990, endMinutes: 1080},
    {teacherName: "Andrea", teacherSchedules: [existing], roomSchedules: [], availability: avail});
assert.deepEqual(c.map((x) => x.code), ["teacher"]);
assert.match(c[0].text, /Andrea already teaches Kelas Dasar A on Monday 16:00–17:30/);
c = s.conflicts({...base, teacherId: "t2"}, {teacherName: "Budi", teacherSchedules: [],
  roomSchedules: [existing], availability: {"1": [r(900, 1200)]}});
assert.deepEqual(c.map((x) => x.code), ["room"]);
assert.match(c[0].text, /Main is taken by Kelas Dasar A/);
c = s.conflicts({...base, startMinutes: 1200, endMinutes: 1290},
    {teacherName: "Andrea", teacherSchedules: [], roomSchedules: [], availability: avail});
assert.deepEqual(c.map((x) => x.code), ["availability"]);
// Owner 2026-11-23 (screenshot): 15:00-16:30 and 16:31-18:00, same teacher
// and room, no clash with the default gap; a gap the admin set says so.
const tue1 = {id: "t1c", className: "Tuesday Class 1", weekday: 2, startMinutes: 900,
  endMinutes: 990, room: "Main", teacherId: "t1"};
const tue2 = {...base, weekday: 2, startMinutes: 991, endMinutes: 1080};
assert.deepEqual(s.conflicts(tue2, {teacherName: "Test Teacher", teacherSchedules: [tue1],
  roomSchedules: [tue1]}), []);
assert.deepEqual(s.conflicts({...tue2, startMinutes: 990}, {teacherSchedules: [tue1],
  roomSchedules: [tue1]}), [], "back to back");
c = s.conflicts(tue2, {teacherName: "Test Teacher", teacherSchedules: [tue1],
  roomSchedules: [tue1], gapMinutes: 15});
assert.deepEqual(c.map((x) => x.code), ["teacher", "room"]);
assert.match(c[0].text, /\(15 minutes are needed between classes\)/);
// Editing a schedule does not clash with itself; another period does not clash.
assert.deepEqual(s.conflicts({...existing, id: "x"}, {teacherSchedules: [existing],
  roomSchedules: [existing], availability: avail}), []);
assert.deepEqual(s.conflicts({...base, validFrom: "2027-01-01"}, {teacherSchedules: [
  {...existing, validTo: "2026-12-31"}], availability: avail}), []);
// A one-off session on that weekday in the period clashes.
c = s.conflicts({...base, validFrom: "2026-11-01", validTo: "2026-12-31"}, {teacherName: "Andrea",
  availability: avail, teacherSessions: [{sessionDate: "2026-11-23", startMinutes: 1000,
    endMinutes: 1090, sessionTitle: "Extra"}]});
assert.deepEqual(c.map((x) => x.code), ["teacher"]);

// Weekly hours, free-slot suggestions.
assert.equal(s.weeklyHours([existing, {...existing, id: "y", weekday: 3}]), 3);
const slots = s.suggestFreeSlots(avail, [existing], 1, 90, 15, 3);
assert.equal(slots.length, 3);
assert.ok(slots.every((x) => !s.overlaps(x, existing, 15) || x.weekday !== 1));
assert.equal(slots[0].weekday, 1);
assert.equal(s.suggestFreeSlots({}, [], 1, 90).length, 0);

// Generation: dates in the period, deterministic ids.
const mon = {weekday: 1, validFrom: "2026-11-24", validTo: "2026-12-31"};
assert.deepEqual(s.sessionDates(mon, "2026-11-20", 14), ["2026-11-30"],
    "the 23rd is before the period");
assert.deepEqual(s.sessionDates({weekday: 1}, "2026-11-20", 14), ["2026-11-23", "2026-11-30"]);
assert.equal(s.sessionIdFor("sch1", "2026-11-30"), "sch1_20261130");

// Booking refusals (VC-04 and the others).
const NOW = Date.parse("2026-11-20T05:00:00Z");
const sess = {status: "scheduled", sessionDate: "2026-11-23", startMinutes: 960,
  endMinutes: 1050, bookedCount: 3, capacity: 8, level: ""};
const term = {status: "active", sessionsRemaining: 2, sessionsBooked: 0, deadlineDate: "2026-12-31"};
assert.equal(s.bookingRefusal(sess, term, [], NOW), null);
assert.equal(s.bookingRefusal(sess, {...term, sessionsBooked: 2}, [], NOW), "no_sessions", "VC-04");
assert.equal(s.bookingRefusal(sess, null, [], NOW), "no_sessions");
assert.equal(s.bookingRefusal({...sess, bookedCount: 8}, term, [], NOW), "full");
assert.equal(s.bookingRefusal(sess, {...term, deadlineDate: "2026-11-22"}, [], NOW), "expired");
assert.equal(s.bookingRefusal(sess, term, [{sessionDate: "2026-11-23", startMinutes: 1000,
  endMinutes: 1090}], NOW), "overlap");
assert.equal(s.bookingRefusal({...sess, sessionDate: "2026-11-20", startMinutes: 600,
  endMinutes: 690}, term, [], NOW), "too_late", "12:00 Jakarta is after the 11:30 end");
// Owner 2026-11-23: a late student joins a class that is going on.
assert.equal(s.bookingRefusal({...sess, sessionDate: "2026-11-20", startMinutes: 660,
  endMinutes: 750}, term, [], NOW), null, "11:00-12:30 is going on at 12:00");
assert.equal(s.bookingRefusal({...sess, status: "ongoing", sessionDate: "2026-11-20",
  startMinutes: 660, endMinutes: 750}, term, [], NOW), null);
assert.equal(s.bookingRefusal({...sess, status: "done"}, term, [], NOW), "closed");
assert.equal(s.bookingRefusal({...sess, status: "needs_teacher"}, term, [], NOW), "needs_teacher");
assert.equal(s.bookingRefusal({...sess, level: "HSK 3"}, term, [], NOW, {studentLevel: "HSK 1"}),
    "level");

// The term a booking uses: active, in time, a free session; the earliest end.
assert.equal(s.termForBooking([
  {id: "a", status: "active", sessionsRemaining: 2, sessionsBooked: 2, deadlineDate: "2026-12-01"},
  {id: "b", status: "active", sessionsRemaining: 5, sessionsBooked: 0, deadlineDate: "2027-01-10"},
  {id: "c", status: "active", sessionsRemaining: 3, sessionsBooked: 0, deadlineDate: "2026-12-10"},
  {id: "d", status: "expired", sessionsRemaining: 3, deadlineDate: "2026-11-01"},
], "2026-11-23").id, "c");
assert.equal(s.termForBooking([], "2026-11-23"), null);

console.log("test_scheduling: all passed (JD-01 logic, VC-04)");
