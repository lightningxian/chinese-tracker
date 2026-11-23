"use strict";

/**
 * Build 7 (docs/PLAN.md §4): the teaching day as pure logic — what closing
 * a session does to each voucher, the late check-in rule, the reminder
 * window and the monthly recap counters. index.js reads and writes the
 * documents. Spec: backlog §5 (VC-01, VC-02, VC-03, VC-05).
 */

const JAKARTA_OFFSET_MS = 7 * 60 * 60 * 1000;
const LATE_MINUTES = 15;
const CHECKIN_EARLY_MINUTES = 30;
const REMINDER_MINUTES = 60;
const UNCLOSED_HOURS = 2;

/** Epoch ms of a Jakarta day and minute. */
function atMs(date, minutes) {
  return Date.parse(`${date}T00:00:00Z`) - JAKARTA_OFFSET_MS + Number(minutes) * 60000;
}

/**
 * What one student's attendance does to their term when a session closes.
 * hadir and alpa use a session; izin only returns the booking.
 * @return {{booked: number, used: number, remaining: number, delta: number}}
 */
function closeEffect(status) {
  if (status === "hadir" || status === "alpa") {
    return {booked: -1, used: 1, remaining: -1, delta: -1};
  }
  if (status === "izin") return {booked: -1, used: 0, remaining: 0, delta: 0};
  return {booked: 0, used: 0, remaining: 0, delta: 0};
}

/**
 * Whether a close may run: `ongoing` (or `scheduled` when an admin closes a
 * forgotten one). A `done` session is not closed again (VC-02).
 * @return {string} `close`, `already-done`, `not-started`, `cancelled`
 */
function closeDecision(status, byAdmin) {
  if (status === "done") return "already-done";
  if (status === "cancelled") return "cancelled";
  if (status === "ongoing") return "close";
  if (status === "scheduled" && byAdmin) return "close";
  return "not-started";
}

/**
 * Owner 2026-11-23: a session starts by itself at its start time. The
 * status as it should be now: a `scheduled` session past its start is
 * `ongoing` (the 5-minute job writes it; the app and the functions read it
 * this way at once).
 */
function effectiveStatus(session, nowMs) {
  const st = session.status || (session.isConcluded ? "done" : "scheduled");
  if (st === "scheduled" && nowMs >= atMs(session.sessionDate, session.startMinutes)) {
    return "ongoing";
  }
  return st;
}

/** A `scheduled` session whose start has come (the job sets it `ongoing`). */
function autoStartDue(session, nowMs) {
  return (session.status || "scheduled") === "scheduled" && session.isConcluded !== true &&
    nowMs >= atMs(session.sessionDate, session.startMinutes);
}

/**
 * The teacher's check-in (now only the teacher's arrival; the session has
 * started by itself): from 30 minutes before the start until the end.
 */
function checkInDecision(session, nowMs) {
  const start = atMs(session.sessionDate, session.startMinutes);
  const end = atMs(session.sessionDate, session.endMinutes);
  if (nowMs < start - CHECKIN_EARLY_MINUTES * 60000) return {ok: false, reason: "too_early"};
  if (nowMs > end) return {ok: false, reason: "too_late"};
  const late = Math.floor((nowMs - start) / 60000);
  return {ok: true, lateMinutes: late > LATE_MINUTES ? late : 0};
}

/**
 * A session whose teacher has not checked in 15 minutes after its start
 * (flagged once).
 */
function lateCheckInDue(session, nowMs) {
  const st = session.status || "scheduled";
  return (st === "scheduled" || st === "ongoing") && !session.checkInAt &&
    session.lateCheckIn !== true &&
    nowMs >= atMs(session.sessionDate, session.startMinutes) + LATE_MINUTES * 60000;
}

/** A session not done or cancelled 2 hours after its end. */
function unclosedDue(session, nowMs) {
  const st = session.status || "scheduled";
  return st !== "done" && st !== "cancelled" && session.unclosed !== true &&
    nowMs >= atMs(session.sessionDate, session.endMinutes) + UNCLOSED_HOURS * 3600000;
}

/** The reminder goes once, in the hour before the start. */
function reminderDue(session, nowMs) {
  const st = session.status || "scheduled";
  if (st !== "scheduled" || session.reminderSentAt) return false;
  const start = atMs(session.sessionDate, session.startMinutes);
  return nowMs < start && start - nowMs <= REMINDER_MINUTES * 60000;
}

/** Hours of a session (for the recap), one decimal. */
function sessionHours(session) {
  const m = Math.max(0, Number(session.endMinutes) - Number(session.startMinutes));
  return Math.round((m / 60) * 10) / 10;
}

/** `yyyyMM` of a `YYYY-MM-DD` day. */
function monthKey(date) {
  return String(date || "").slice(0, 7).replace("-", "");
}

/**
 * Reconciliation (VC-05): a term's counters against the ledger and the
 * open bookings.
 * @param {Object} term {id, sessionsUsed, sessionsBooked}
 * @param {number} ledgerUsed the session entries that deducted (delta -1)
 * @param {number} openBookings booked, not yet credited attendance docs
 * @return {Array<string>} the mismatches in words
 */
function reconcileTerm(term, ledgerUsed, openBookings) {
  const out = [];
  if ((Number(term.sessionsUsed) || 0) !== ledgerUsed) {
    out.push(`sessionsUsed ${Number(term.sessionsUsed) || 0} but ${ledgerUsed} in the ledger`);
  }
  if ((Number(term.sessionsBooked) || 0) !== openBookings) {
    out.push(`sessionsBooked ${Number(term.sessionsBooked) || 0} but ${openBookings} open bookings`);
  }
  return out;
}

/**
 * The month recap rows: one per teacher, from the `teacher_recaps` docs
 * (held, hours, late check-ins, cancelled) and the month's sessions
 * (scheduled = every session of that teacher that month).
 * @param {Array<Object>} recaps teacher_recaps docs of the month
 * @param {Array<Object>} sessions class_sessions of the month
 * @return {Array<Object>} rows sorted by name
 */
function recapRows(recaps, sessions) {
  const rows = {};
  const row = (id, name) => {
    if (!rows[id]) {
      rows[id] = {teacherId: id, teacherName: name || "", scheduled: 0, held: 0,
        cancelled: 0, lateCheckIns: 0, hours: 0};
    }
    if (name && !rows[id].teacherName) rows[id].teacherName = name;
    return rows[id];
  };
  for (const s of sessions) {
    if (!s.teacherId) continue;
    row(s.teacherId, s.teacherName).scheduled += 1;
  }
  for (const r of recaps) {
    if (!r.teacherId) continue;
    const x = row(r.teacherId, r.teacherName);
    x.held = Number(r.held) || 0;
    x.cancelled = Number(r.cancelled) || 0;
    x.lateCheckIns = Number(r.lateCheckIns) || 0;
    x.hours = Number(r.hours) || 0;
  }
  return Object.values(rows).sort((a, b) => a.teacherName.localeCompare(b.teacherName));
}

module.exports = {
  recapRows,
  LATE_MINUTES,
  atMs,
  closeEffect,
  closeDecision,
  effectiveStatus,
  autoStartDue,
  checkInDecision,
  lateCheckInDue,
  unclosedDue,
  reminderDue,
  sessionHours,
  monthKey,
  reconcileTerm,
};
