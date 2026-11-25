"use strict";

/**
 * Build 8 (docs/PLAN.md §4): the monthly centre report as pure logic.
 * index.js reads the documents, turns timestamps into epoch ms and writes
 * `reports/{yyyyMM}`. Months follow Jakarta time.
 */

const JAKARTA_OFFSET_MS = 7 * 60 * 60 * 1000;

/** `yyyyMM` → the month's Jakarta bounds (ms, and `YYYY-MM-DD` days). */
function monthRange(month) {
  const m = String(month || "");
  if (!/^\d{6}$/.test(m)) throw new Error(`month must be yyyyMM, got "${month}"`);
  const y = Number(m.slice(0, 4));
  const mo = Number(m.slice(4));
  if (mo < 1 || mo > 12) throw new Error(`bad month ${month}`);
  const fromMs = Date.UTC(y, mo - 1, 1) - JAKARTA_OFFSET_MS;
  const toMs = Date.UTC(y, mo, 1) - JAKARTA_OFFSET_MS;
  const last = new Date(Date.UTC(y, mo, 0)).getUTCDate();
  const mm = String(mo).padStart(2, "0");
  return {fromMs, toMs, fromDate: `${y}-${mm}-01`, toDate: `${y}-${mm}-${String(last).padStart(2, "0")}`};
}

/**
 * Build 9B: from-month to to-month (both `yyyyMM`, both included) as one
 * range of the same shape as [monthRange].
 */
function periodRange(from, to) {
  const a = monthRange(from);
  const b = monthRange(to);
  if (b.toMs <= a.fromMs) throw new Error(`period ${from}–${to} ends before it starts`);
  return {fromMs: a.fromMs, toMs: b.toMs, fromDate: a.fromDate, toDate: b.toDate};
}

/** The month before the one that holds [nowMs] (Jakarta), as `yyyyMM`. */
function previousMonth(nowMs) {
  const d = new Date(nowMs + JAKARTA_OFFSET_MS);
  const y = d.getUTCFullYear();
  const m = d.getUTCMonth(); // 0-based: the previous month's 1-based number
  return m === 0 ? `${y - 1}12` : `${y}${String(m).padStart(2, "0")}`;
}

const inMs = (ms, r) => Number.isFinite(ms) && ms >= r.fromMs && ms < r.toMs;
const inDay = (day, r) => typeof day === "string" && day >= r.fromDate && day <= r.toDate;

/**
 * @param {Object} input
 * @param {string} input.month yyyyMM (or input.from + input.to, Build 9B)
 * @param {Array} input.students {uid, createdAtMs, level, status, active}
 * @param {Array} input.invoices {status, amount, paidAtMs}
 * @param {Array} input.attendance {studentId, sessionDate, booked, attendanceStatus, status}
 * @param {Array} input.exerciseResults {studentId, submittedAtMs}
 * @param {Array} input.testResults {studentId, createdAtMs}
 * @param {Array} input.recaps teacher_recaps docs of the month {teacherId, teacherName, hours, held}
 * @return {Object} the report
 */
function buildReport({month, from, to, students = [], invoices = [], attendance = [],
  exerciseResults = [], testResults = [], recaps = []}) {
  const r = from ? periodRange(from, to || from) : monthRange(month);
  const studentIds = new Set(students.map((s) => s.uid));
  const newStudents = students.filter((s) => inMs(s.createdAtMs, r)).length;
  const paid = invoices.filter((i) => i.status === "paid" && inMs(i.paidAtMs, r));
  const revenue = paid.reduce((t, i) => t + (Number(i.amount) || 0), 0);

  const active = new Set();
  for (const a of attendance) {
    if (!studentIds.has(a.studentId) || !inDay(a.sessionDate, r)) continue;
    if (a.status === "cancelled") continue;
    if (a.booked === true || a.attendanceStatus) active.add(a.studentId);
  }
  for (const x of exerciseResults) {
    if (studentIds.has(x.studentId) && inMs(x.submittedAtMs, r)) active.add(x.studentId);
  }
  for (const x of testResults) {
    if (studentIds.has(x.studentId) && inMs(x.createdAtMs, r)) active.add(x.studentId);
  }

  const levels = {};
  for (const s of students) {
    if (s.active === false || (s.status && s.status !== "approved" && s.status !== "active")) {
      continue;
    }
    const key = String(s.level || "").trim() || "—";
    levels[key] = (levels[key] || 0) + 1;
  }

  let hadir = 0;
  let alpa = 0;
  let izin = 0;
  for (const a of attendance) {
    if (!inDay(a.sessionDate, r)) continue;
    if (a.attendanceStatus === "hadir") hadir += 1;
    else if (a.attendanceStatus === "alpa") alpa += 1;
    else if (a.attendanceStatus === "izin") izin += 1;
  }
  const attendanceRate = hadir + alpa > 0 ? Math.round((hadir / (hadir + alpa)) * 1000) / 10 : null;

  const teachers = mergeTeachers(recaps);

  return {
    month: month || `${from}-${to || from}`,
    newStudents,
    revenue,
    paidInvoices: paid.length,
    activeStudents: active.size,
    levels,
    attendance: {hadir, izin, alpa, rate: attendanceRate},
    teachers,
    teachingHours: Math.round(teachers.reduce((t, x) => t + x.hours, 0) * 10) / 10,
  };
}

/** Teacher rows summed per teacher (one recap per teacher and month). */
function mergeTeachers(rows) {
  const by = new Map();
  for (const x of rows || []) {
    if (!x || !x.teacherId) continue;
    const t = by.get(x.teacherId) || {teacherId: x.teacherId, teacherName: "", held: 0, hours: 0};
    t.teacherName = x.teacherName || t.teacherName;
    t.held += Number(x.held) || 0;
    t.hours += Number(x.hours) || 0;
    by.set(x.teacherId, t);
  }
  return [...by.values()]
      .map((t) => ({...t, hours: Math.round(t.hours * 10) / 10}))
      .sort((a, b) => a.teacherName.localeCompare(b.teacherName));
}

/**
 * Build 9B: the reports of several months as one. Counts and money are
 * summed; the attendance rate is recomputed from the summed hadir and alpa
 * (never an average of rates); end-of-period figures (active students,
 * levels) come from the last month. `reports` must be oldest first. The
 * Flutter twin is `MonthlyReport.merge` (lib/features/admin/monthly_report_card.dart).
 */
function mergeReports(reports) {
  const list = (reports || []).filter(Boolean);
  if (!list.length) return null;
  const sum = (f) => list.reduce((t, x) => t + (Number(f(x)) || 0), 0);
  const hadir = sum((x) => x.attendance && x.attendance.hadir);
  const izin = sum((x) => x.attendance && x.attendance.izin);
  const alpa = sum((x) => x.attendance && x.attendance.alpa);
  const teachers = mergeTeachers(list.flatMap((x) => x.teachers || []));
  const last = list[list.length - 1];
  return {
    month: `${list[0].month}-${last.month}`,
    newStudents: sum((x) => x.newStudents),
    revenue: sum((x) => x.revenue),
    paidInvoices: sum((x) => x.paidInvoices),
    activeStudents: Number(last.activeStudents) || 0,
    levels: {...(last.levels || {})},
    attendance: {hadir, izin, alpa,
      rate: hadir + alpa > 0 ? Math.round((hadir / (hadir + alpa)) * 1000) / 10 : null},
    teachers,
    teachingHours: Math.round(teachers.reduce((t, x) => t + x.hours, 0) * 10) / 10,
  };
}

module.exports = {monthRange, periodRange, previousMonth, buildReport, mergeReports};
