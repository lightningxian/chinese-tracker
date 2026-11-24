"use strict";

/**
 * Build 6 (docs/PLAN.md §4): the weekly timetable and booking as pure
 * logic. index.js reads and writes the documents. Spec: backlog §4
 * (JD-01, JD-02, VC-04).
 *
 * Times of day are minutes after midnight; dates are Jakarta days
 * `YYYY-MM-DD`; weekdays run 1 (Monday) to 7 (Sunday).
 */

const DAY_MS = 24 * 60 * 60 * 1000;
const JAKARTA_OFFSET_MS = 7 * 60 * 60 * 1000;
const WEEKDAY_NAMES = ["", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday",
  "Saturday", "Sunday"];
const DEFAULTS = {minGapMinutes: 0, weeklyHoursWarning: 20, defaultCapacity: 8,
  bookingCutoffMinutes: 0};

function jakartaDate(ms) {
  return new Date(ms + JAKARTA_OFFSET_MS).toISOString().slice(0, 10);
}

/** Weekday 1..7 of a `YYYY-MM-DD` day. */
function weekdayOf(date) {
  const d = new Date(`${date}T00:00:00Z`).getUTCDay();
  return d === 0 ? 7 : d;
}

function addDays(date, n) {
  return new Date(Date.parse(`${date}T00:00:00Z`) + n * DAY_MS).toISOString().slice(0, 10);
}

/** `16:00` from 960. */
function clock(minutes) {
  const m = Math.max(0, Math.round(Number(minutes) || 0));
  return `${String(Math.floor(m / 60)).padStart(2, "0")}:${String(m % 60).padStart(2, "0")}`;
}

/** Epoch ms of a Jakarta day and minute (a session's start). */
function startMs(date, minutes) {
  return Date.parse(`${date}T00:00:00Z`) - JAKARTA_OFFSET_MS + Number(minutes) * 60000;
}

/**
 * Two time ranges on the same day overlap, widened by the gap: a teacher
 * or a room needs [gap] minutes between two classes.
 */
function overlaps(a, b, gapMinutes = 0) {
  const g = Number(gapMinutes) || 0;
  return a.startMinutes < b.endMinutes + g && b.startMinutes < a.endMinutes + g;
}

/** Whether [start, end] sits inside one of the day's availability windows. */
function insideAvailability(windows, startMinutes, endMinutes) {
  return (windows || []).some((w) =>
    Number(w.startMinutes) <= startMinutes && endMinutes <= Number(w.endMinutes));
}

/** Basic checks of a schedule form. @return {Array<{code, text}>} */
function validate(s, teacher) {
  const out = [];
  if (!(s.weekday >= 1 && s.weekday <= 7)) out.push({code: "weekday", text: "Pick a weekday."});
  if (!(Number(s.endMinutes) > Number(s.startMinutes))) {
    out.push({code: "time", text: "The class must end after it starts."});
  }
  if (!(Number(s.capacity) >= 1)) out.push({code: "capacity", text: "At least 1 seat."});
  if (!String(s.className || "").trim()) out.push({code: "name", text: "Give the class a name."});
  if (!s.teacherId) out.push({code: "teacher", text: "Pick a teacher."});
  if (!String(s.room || "").trim()) out.push({code: "room", text: "Pick a room."});
  if (s.validFrom && s.validTo && s.validTo < s.validFrom) {
    out.push({code: "period", text: "The period ends before it starts."});
  }
  const levels = (teacher && teacher.levels) || [];
  if (s.level && levels.length && !levels.includes(s.level)) {
    out.push({code: "level",
      text: `${teacher.name || "The teacher"} does not teach ${s.level} (${levels.join(", ")}).`});
  }
  return out;
}

/**
 * Owner 2026-11-23: a class may have helper teachers besides its main
 * teacher. Unique, not the main teacher, at most 3.
 */
function cleanCoTeachers(ids, primary) {
  const out = [];
  for (const raw of Array.isArray(ids) ? ids : []) {
    const id = String(raw || "").trim();
    if (!id || id.includes("/") || id === primary || out.includes(id)) continue;
    out.push(id);
  }
  return out.slice(0, 3);
}

/** Every teacher of a schedule or session: the main one, then the helpers. */
function teachersOf(x) {
  return [x.teacherId, ...((x && x.coTeacherIds) || [])].filter(Boolean);
}

/**
 * When the teacher-readiness switch is off (owner 2026-11-23: teachers are
 * taken as ready all the time), free times are looked for in the centre's
 * opening hours instead of a teacher's availability.
 */
const OPEN_HOURS = {startMinutes: 8 * 60, endMinutes: 21 * 60};
function openAllWeek() {
  const out = {};
  for (let d = 1; d <= 7; d += 1) out[String(d)] = [{...OPEN_HOURS}];
  return out;
}

/** Two validity periods share at least one day ('' = open-ended). */
function periodsOverlap(a, b) {
  const aFrom = a.validFrom || "0000-01-01";
  const aTo = a.validTo || "9999-12-31";
  const bFrom = b.validFrom || "0000-01-01";
  const bTo = b.validTo || "9999-12-31";
  return aFrom <= bTo && bFrom <= aTo;
}

/**
 * The clashes of a schedule: the teacher's other schedules and one-off
 * sessions, and the room's. Each reason names the clashing class and time.
 * @param {Object} s the schedule being saved (with `id` when editing)
 * @param {Object} ctx {teacherName, teacherSchedules, roomSchedules,
 *   teacherSessions, roomSessions, availability, gapMinutes}
 * @return {Array<{code, text}>}
 */
function conflicts(s, ctx) {
  const out = [];
  const gap = ctx.gapMinutes === undefined ? DEFAULTS.minGapMinutes : ctx.gapMinutes;
  const day = WEEKDAY_NAMES[s.weekday] || "";
  const who = ctx.teacherName || "The teacher";
  const avail = (ctx.availability || {})[String(s.weekday)];
  if (ctx.availability && !insideAvailability(avail, s.startMinutes, s.endMinutes)) {
    out.push({code: "availability", text: `${who} is not available on ${day} ` +
      `${clock(s.startMinutes)}–${clock(s.endMinutes)}.`});
  }
  const live = (x) => x.active !== false && x.id !== s.id;
  // Owner 2026-11-23: back-to-back classes are fine; a clash that only
  // comes from the admin's minimum gap says so.
  const gapNote = (o) => overlaps(o, s, 0) ? "" : ` (${gap} minutes are needed between classes)`;
  for (const o of (ctx.teacherSchedules || []).filter(live)) {
    if (o.weekday === s.weekday && periodsOverlap(o, s) && overlaps(o, s, gap)) {
      out.push({code: "teacher", text: `${who} already teaches ${o.className} on ${day} ` +
        `${clock(o.startMinutes)}–${clock(o.endMinutes)}${gapNote(o)}.`});
    }
  }
  for (const o of (ctx.roomSchedules || []).filter(live)) {
    if (o.weekday === s.weekday && periodsOverlap(o, s) && overlaps(o, s, gap)) {
      out.push({code: "room", text: `${s.room} is taken by ${o.className} on ${day} ` +
        `${clock(o.startMinutes)}–${clock(o.endMinutes)}${gapNote(o)}.`});
    }
  }
  const inPeriod = (date) => (!s.validFrom || date >= s.validFrom) &&
    (!s.validTo || date <= s.validTo);
  for (const x of (ctx.teacherSessions || [])) {
    if (x.scheduleId && x.scheduleId === s.id) continue;
    if (weekdayOf(x.sessionDate) === s.weekday && inPeriod(x.sessionDate) &&
        overlaps(x, s, gap)) {
      out.push({code: "teacher", text: `${who} already teaches ${x.sessionTitle || "a class"} ` +
        `on ${x.sessionDate} ${clock(x.startMinutes)}–${clock(x.endMinutes)}${gapNote(x)}.`});
    }
  }
  for (const x of (ctx.roomSessions || [])) {
    if (x.scheduleId && x.scheduleId === s.id) continue;
    if (weekdayOf(x.sessionDate) === s.weekday && inPeriod(x.sessionDate) &&
        overlaps(x, s, gap)) {
      out.push({code: "room", text: `${s.room} is taken by ${x.sessionTitle || "a class"} ` +
        `on ${x.sessionDate} ${clock(x.startMinutes)}–${clock(x.endMinutes)}${gapNote(x)}.`});
    }
  }
  return out;
}

/** Teaching hours per week of a set of active schedules. */
function weeklyHours(schedules) {
  const mins = (schedules || []).filter((x) => x.active !== false)
      .reduce((sum, x) => sum + Math.max(0, x.endMinutes - x.startMinutes), 0);
  return Math.round((mins / 60) * 10) / 10;
}

/**
 * The first [limit] free windows of [length] minutes for a teacher: inside
 * the availability, clear of the teacher's (and the room's) classes with the
 * gap; [weekday] first, then the other weekdays. 30-minute steps.
 * @param {Object} availability {"1": [{startMinutes, endMinutes}], ...}
 * @param {Array} busy schedules {weekday, startMinutes, endMinutes}
 */
function suggestFreeSlots(availability, busy, weekday, length, gapMinutes = 15, limit = 5) {
  const out = [];
  const days = [weekday, ...[1, 2, 3, 4, 5, 6, 7].filter((d) => d !== weekday)];
  for (const d of days) {
    for (const w of (availability || {})[String(d)] || []) {
      for (let t = Number(w.startMinutes); t + length <= Number(w.endMinutes); t += 30) {
        const slot = {weekday: d, startMinutes: t, endMinutes: t + length};
        const clash = (busy || []).some((b) => b.active !== false && b.weekday === d &&
          overlaps(b, slot, gapMinutes));
        if (!clash) out.push(slot);
        if (out.length >= limit) return out;
      }
    }
  }
  return out;
}

/** The days a schedule meets from [fromDate] for [days] days, in its period. */
function sessionDates(s, fromDate, days = 14) {
  const out = [];
  for (let i = 0; i < days; i++) {
    const d = addDays(fromDate, i);
    if (weekdayOf(d) !== s.weekday) continue;
    if (s.validFrom && d < s.validFrom) continue;
    if (s.validTo && d > s.validTo) continue;
    out.push(d);
  }
  return out;
}

/** The deterministic id of a generated session. */
function sessionIdFor(scheduleId, date) {
  return `${scheduleId}_${date.replace(/-/g, "")}`;
}

/**
 * Why a student cannot book a session, or null.
 * @param {Object} session {status, sessionDate, startMinutes, endMinutes,
 *   bookedCount, capacity, level}
 * @param {Object|null} term the student's active term {status,
 *   sessionsRemaining, sessionsBooked, deadlineDate}
 * @param {Array} booked the student's other booked sessions (same shape)
 * @param {number} nowMs
 * @param {Object} opts {studentLevel}
 * @return {string|null} full, no_sessions, expired, overlap, too_late,
 *   needs_teacher, level, closed
 *
 * Owner 2026-11-23: a late student may still join a class that is going
 * on; booking closes when the class ends.
 */
function bookingRefusal(session, term, booked, nowMs, opts = {}) {
  const st = session.status || "scheduled";
  if (st === "needs_teacher") return "needs_teacher";
  if ((st !== "scheduled" && st !== "ongoing") || session.isConcluded === true) return "closed";
  if (startMs(session.sessionDate, session.endMinutes) <= nowMs) return "too_late";
  if (session.level && opts.studentLevel && session.level !== opts.studentLevel) return "level";
  if ((Number(session.bookedCount) || 0) >= (Number(session.capacity) || 0)) return "full";
  if (!term) return "no_sessions";
  const today = jakartaDate(nowMs);
  if (term.status === "expired" || (term.deadlineDate && term.deadlineDate < session.sessionDate) ||
      (term.deadlineDate && term.deadlineDate < today)) {
    return "expired";
  }
  if ((Number(term.sessionsRemaining) || 0) - (Number(term.sessionsBooked) || 0) <= 0) {
    return "no_sessions";
  }
  for (const b of booked || []) {
    if (b.sessionDate === session.sessionDate && overlaps(b, session, 0)) return "overlap";
  }
  return null;
}

/**
 * Owner 2026-11-24: may the student join the waiting list of a full class?
 * Everything a booking checks except the free seat, before the class
 * starts; a class with a free seat says "not_full" (book it instead).
 */
function waitlistRefusal(session, term, booked, nowMs, opts = {}) {
  if (startMs(session.sessionDate, session.startMinutes) <= nowMs) return "too_late";
  const full = (Number(session.bookedCount) || 0) >= (Number(session.capacity) || 0);
  const r = bookingRefusal({...session, capacity: Number.MAX_SAFE_INTEGER}, term, booked, nowMs,
      opts);
  if (r) return r;
  return full ? null : "not_full";
}

/**
 * The term a booking draws from: active, not past its deadline, with a
 * free session; the one ending first.
 */
function termForBooking(terms, sessionDate) {
  return (terms || [])
      .filter((t) => (t.status || "active") === "active")
      .filter((t) => !t.deadlineDate || t.deadlineDate >= sessionDate)
      .filter((t) => (Number(t.sessionsRemaining) || 0) - (Number(t.sessionsBooked) || 0) > 0)
      .sort((a, b) => String(a.deadlineDate || "9").localeCompare(String(b.deadlineDate || "9")))[0] ||
    null;
}

module.exports = {
  DEFAULTS,
  WEEKDAY_NAMES,
  jakartaDate,
  weekdayOf,
  addDays,
  clock,
  startMs,
  overlaps,
  cleanCoTeachers,
  teachersOf,
  openAllWeek,
  insideAvailability,
  validate,
  periodsOverlap,
  conflicts,
  weeklyHours,
  suggestFreeSlots,
  sessionDates,
  sessionIdFor,
  bookingRefusal,
  waitlistRefusal,
  termForBooking,
};
