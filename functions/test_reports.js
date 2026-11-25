"use strict";

// Build 8: the monthly centre report (docs/PLAN.md §4, Must 2).
const assert = require("node:assert/strict");
const r = require("./reports");

// Jakarta month bounds: 1 Nov 00:00 WIB = 31 Oct 17:00 UTC.
const nov = r.monthRange("202611");
assert.equal(new Date(nov.fromMs).toISOString(), "2026-10-31T17:00:00.000Z");
assert.equal(new Date(nov.toMs).toISOString(), "2026-11-30T17:00:00.000Z");
assert.equal(nov.toDate, "2026-11-30");
assert.equal(r.monthRange("202402").toDate, "2024-02-29");
assert.throws(() => r.monthRange("2026-11"));
assert.equal(r.previousMonth(Date.parse("2026-12-01T00:30:00+07:00")), "202611");
assert.equal(r.previousMonth(Date.parse("2027-01-01T01:00:00+07:00")), "202612");

const ms = (iso) => Date.parse(iso);
const rep = r.buildReport({
  month: "202611",
  students: [
    {uid: "a", createdAtMs: ms("2026-11-05T10:00:00+07:00"), level: "HSK 1"},
    {uid: "b", createdAtMs: ms("2026-10-31T23:30:00+07:00"), level: "HSK 1"},
    {uid: "c", createdAtMs: ms("2026-11-01T00:10:00+07:00"), level: "HSK 3"},
    {uid: "d", createdAtMs: ms("2026-09-01T00:00:00+07:00"), level: "HSK 2", active: false},
    {uid: "e", createdAtMs: ms("2026-11-20T00:00:00+07:00"), level: "", status: "pending"},
  ],
  invoices: [
    {status: "paid", amount: 800000, paidAtMs: ms("2026-11-02T09:00:00+07:00")},
    {status: "paid", amount: 1500000, paidAtMs: ms("2026-12-01T00:00:00+07:00")},
    {status: "pending", amount: 800000, paidAtMs: null},
    {status: "paid", amount: 750000, paidAtMs: ms("2026-11-30T23:59:00+07:00")},
  ],
  attendance: [
    {studentId: "a", sessionDate: "2026-11-03", booked: true, attendanceStatus: "hadir"},
    {studentId: "b", sessionDate: "2026-11-03", attendanceStatus: "alpa"},
    {studentId: "c", sessionDate: "2026-11-04", booked: true, status: "cancelled"},
    {studentId: "a", sessionDate: "2026-11-10", attendanceStatus: "izin"},
    {studentId: "a", sessionDate: "2026-12-01", attendanceStatus: "hadir"},
  ],
  exerciseResults: [{studentId: "c", submittedAtMs: ms("2026-11-15T10:00:00+07:00")}],
  testResults: [{studentId: "d", createdAtMs: ms("2026-10-15T10:00:00+07:00")}],
  recaps: [
    {teacherId: "t2", teacherName: "Budi", held: 3, hours: 4.5},
    {teacherId: "t1", teacherName: "Andrea", held: 2, hours: 3},
  ],
});
assert.equal(rep.newStudents, 3, "a, c, e (b is 31 Oct Jakarta)");
assert.equal(rep.revenue, 1550000);
assert.equal(rep.paidInvoices, 2);
assert.equal(rep.activeStudents, 3, "a booked, b marked, c a result; c's cancel alone does not count");
assert.deepEqual(rep.levels, {"HSK 1": 2, "HSK 3": 1}, "inactive and pending left out");
assert.deepEqual(rep.attendance, {hadir: 1, izin: 1, alpa: 1, rate: 50});
assert.deepEqual(rep.teachers.map((t) => t.teacherName), ["Andrea", "Budi"]);
assert.equal(rep.teachingHours, 7.5);
assert.equal(r.buildReport({month: "202611"}).attendance.rate, null);

// Build 9B: the merge of three months equals one build over the three
// months for every summed figure; the rate is recomputed, not averaged.
const data = {
  students: [
    {uid: "a", createdAtMs: ms("2026-03-05T10:00:00+07:00"), level: "HSK 1"},
    {uid: "b", createdAtMs: ms("2026-04-30T23:30:00+07:00"), level: "HSK 2"},
    {uid: "c", createdAtMs: ms("2026-05-01T00:10:00+07:00"), level: "HSK 3"},
    {uid: "d", createdAtMs: ms("2026-02-01T00:00:00+07:00"), level: "HSK 1"},
  ],
  invoices: [
    {status: "paid", amount: 800000, paidAtMs: ms("2026-03-02T09:00:00+07:00")},
    {status: "paid", amount: 1500000, paidAtMs: ms("2026-04-30T23:59:00+07:00")},
    {status: "paid", amount: 750000, paidAtMs: ms("2026-05-31T23:59:00+07:00")},
    {status: "paid", amount: 999, paidAtMs: ms("2026-06-01T00:00:00+07:00")},
  ],
  attendance: [
    {studentId: "a", sessionDate: "2026-03-03", attendanceStatus: "hadir"},
    {studentId: "a", sessionDate: "2026-03-10", attendanceStatus: "hadir"},
    {studentId: "a", sessionDate: "2026-03-17", attendanceStatus: "hadir"},
    {studentId: "b", sessionDate: "2026-04-03", attendanceStatus: "alpa"},
    {studentId: "b", sessionDate: "2026-04-05", attendanceStatus: "izin"},
    {studentId: "c", sessionDate: "2026-05-04", attendanceStatus: "hadir"},
    {studentId: "c", sessionDate: "2026-05-11", attendanceStatus: "alpa"},
    {studentId: "c", sessionDate: "2026-05-18", attendanceStatus: "alpa"},
  ],
};
const recapsOf = {
  "202603": [{teacherId: "t1", teacherName: "Andrea", held: 3, hours: 4.5}],
  "202604": [{teacherId: "t1", teacherName: "Andrea", held: 1, hours: 1.5},
    {teacherId: "t2", teacherName: "Budi", held: 2, hours: 3}],
  "202605": [{teacherId: "t2", teacherName: "Budi", held: 1, hours: 1.5}],
};
const months = ["202603", "202604", "202605"];
const perMonth = months.map((m) => r.buildReport({...data, month: m, recaps: recapsOf[m]}));
const merged = r.mergeReports(perMonth);
const whole = r.buildReport({...data, from: "202603", to: "202605",
  recaps: months.flatMap((m) => recapsOf[m])});
for (const f of ["newStudents", "revenue", "paidInvoices", "teachingHours"]) {
  assert.equal(merged[f], whole[f], f);
}
assert.deepEqual(merged.attendance, whole.attendance);
assert.deepEqual(merged.teachers, whole.teachers);
assert.equal(merged.newStudents, 3);
assert.equal(merged.revenue, 3050000);
// Rates of the months: 100, 0, 33.3 → their average 44.4 would be wrong.
assert.deepEqual(perMonth.map((x) => x.attendance.rate), [100, 0, 33.3]);
assert.equal(merged.attendance.rate, 57.1, "4 hadir of 7 marked hadir or alpa");
assert.equal(merged.activeStudents, perMonth[2].activeStudents, "end of period");
assert.equal(merged.month, "202603-202605");
assert.equal(r.mergeReports([]), null);
assert.equal(r.periodRange("202603", "202612").toDate, "2026-12-31");
assert.throws(() => r.periodRange("202605", "202603"));

console.log("test_reports: all passed");
