"use strict";

/**
 * Build 4 (docs/PLAN.md §4): the student progress summary as pure logic.
 * index.js reads the student's documents, calls `summarize`, and writes
 * `progress_summary/{uid}`; the daily job asks `noticesDue` which warning
 * notices to send. Spec: docs/THESIS_FEATURE_BACKLOG.md §9.
 *
 * Times are milliseconds; calendar days and ISO weeks are Jakarta days
 * (UTC+7, no daylight saving).
 */

const DAY_MS = 24 * 60 * 60 * 1000;
const JAKARTA_OFFSET_MS = 7 * 60 * 60 * 1000;
const WEEKS = 12;
const NOTICE_EVERY_MS = 7 * DAY_MS;
const LEVELS = ["1", "2", "3", "4", "5", "6"];

/** Who hears about each warning (the spec's table). */
const NOTIFY = {
  1: ["teacher", "admin"],
  2: ["teacher"],
  3: ["student", "teacher"],
  4: ["student", "admin"],
  5: ["teacher", "admin"],
};

function levelKeyOf(level) {
  const m = /(\d)/.exec(String(level || ""));
  return m && LEVELS.includes(m[1]) ? m[1] : "";
}

function groupOf(key) {
  const n = Number(levelKeyOf(key));
  if (n === 1 || n === 2) return "beginner";
  if (n === 3 || n === 4) return "intermediate";
  if (n === 5 || n === 6) return "advance";
  return "";
}

/** `YYYY-MM-DD` of the Jakarta day of [ms]. */
function jakartaDate(ms) {
  return new Date(ms + JAKARTA_OFFSET_MS).toISOString().slice(0, 10);
}

/** Days from Jakarta day [fromDate] to [toDate] (`YYYY-MM-DD`). */
function daysBetween(fromDate, toDate) {
  const a = Date.parse(`${fromDate}T00:00:00Z`);
  const b = Date.parse(`${toDate}T00:00:00Z`);
  if (!Number.isFinite(a) || !Number.isFinite(b)) return null;
  return Math.round((b - a) / DAY_MS);
}

/**
 * ISO week of the Jakarta day of [ms]: `{key: '2026-W47', monday:
 * '2026-11-16'}`. The week starts on Monday; week 1 holds the year's first
 * Thursday.
 */
function isoWeek(ms) {
  const d = new Date(Date.parse(`${jakartaDate(ms)}T00:00:00Z`));
  const dow = (d.getUTCDay() + 6) % 7; // Monday 0
  const monday = new Date(d.getTime() - dow * DAY_MS);
  const thursday = new Date(monday.getTime() + 3 * DAY_MS);
  const year = thursday.getUTCFullYear();
  const jan1 = Date.UTC(year, 0, 1);
  const week = 1 + Math.floor((thursday.getTime() - jan1) / (7 * DAY_MS));
  return {
    key: `${year}-W${String(week).padStart(2, "0")}`,
    monday: monday.toISOString().slice(0, 10),
  };
}

function avg(list) {
  return list.length ? list.reduce((s, x) => s + x, 0) / list.length : null;
}

function round1(x) {
  return x === null || x === undefined ? null : Math.round(x * 10) / 10;
}

/** Practice = every final package result with a score (owner Q13). */
function practiceRows(exercises) {
  return (exercises || [])
      .filter((e) => e && Number.isFinite(Number(e.submittedAtMs)) &&
        Number.isFinite(Number(e.score)) && (e.status || "final") === "final")
      .map((e) => ({...e, submittedAtMs: Number(e.submittedAtMs), score: Number(e.score)}));
}

/**
 * Practice block: the last 12 ISO weeks (oldest first) with the average
 * score and the attempts of each, the averages of the last 14 days and of
 * the 14 days before, the last practice time and the attempts in 90 days.
 */
function practiceOf(exercises, nowMs) {
  const rows = practiceRows(exercises);
  const weeks = [];
  for (let i = WEEKS - 1; i >= 0; i--) {
    const w = isoWeek(nowMs - i * 7 * DAY_MS);
    weeks.push({week: w.key, monday: w.monday, scores: []});
  }
  const byKey = new Map(weeks.map((w) => [w.week, w]));
  const last14 = [];
  const prev14 = [];
  let attempts90 = 0;
  let lastMs = null;
  for (const r of rows) {
    const age = nowMs - r.submittedAtMs;
    if (age < 0) continue;
    const w = byKey.get(isoWeek(r.submittedAtMs).key);
    if (w) w.scores.push(r.score);
    if (age < 14 * DAY_MS) last14.push(r.score);
    else if (age < 28 * DAY_MS) prev14.push(r.score);
    if (age < 90 * DAY_MS) attempts90 += 1;
    if (lastMs === null || r.submittedAtMs > lastMs) lastMs = r.submittedAtMs;
  }
  return {
    weeks: weeks.map((w) => ({week: w.week, monday: w.monday,
      average: round1(avg(w.scores)), attempts: w.scores.length})),
    average14: round1(avg(last14)),
    attempts14: last14.length,
    averagePrev14: round1(avg(prev14)),
    attemptsPrev14: prev14.length,
    lastPracticeMs: lastMs,
    attempts90,
  };
}

/** Average per skill (percent) from `bySkill` over 90 days. */
function skillsOf(exercises, nowMs) {
  const sums = {};
  for (const r of practiceRows(exercises)) {
    if (nowMs - r.submittedAtMs >= 90 * DAY_MS || nowMs < r.submittedAtMs) continue;
    for (const [skill, b] of Object.entries(r.bySkill || {})) {
      const total = Number((b || {}).total) || 0;
      if (total <= 0) continue;
      const s = sums[skill] || (sums[skill] = {correct: 0, total: 0});
      s.correct += Number(b.correct) || 0;
      s.total += total;
    }
  }
  const out = {};
  for (const [skill, s] of Object.entries(sums)) {
    out[skill] = {percent: Math.round((s.correct / s.total) * 100),
      correct: s.correct, total: s.total};
  }
  return out;
}

/** Attendance status: hadir / izin / alpa; legacy present / absent. */
function attendanceStatusOf(raw) {
  if (raw === "present") return "hadir";
  if (raw === "absent") return "izin";
  return raw === "hadir" || raw === "izin" || raw === "alpa" ? raw : "";
}

/**
 * Attendance of the last 30 days: hadir ÷ (hadir + alpa), izin left out
 * (owner Q16); the counts and the last 10 marked records.
 */
function attendanceOf(records, nowMs) {
  const today = jakartaDate(nowMs);
  const marked = (records || [])
      .map((r) => ({...r, status: attendanceStatusOf(r.status)}))
      .filter((r) => r.status && /^\d{4}-\d{2}-\d{2}$/.test(String(r.sessionDate || "")))
      .filter((r) => r.sessionDate <= today)
      .sort((a, b) => (a.sessionDate < b.sessionDate ? 1 : -1));
  const counts = {hadir: 0, izin: 0, alpa: 0};
  for (const r of marked) {
    const d = daysBetween(r.sessionDate, today);
    if (d !== null && d < 30) counts[r.status] += 1;
  }
  const denom = counts.hadir + counts.alpa;
  return {
    percent: denom === 0 ? null : Math.round((counts.hadir / denom) * 100),
    records30: counts.hadir + counts.izin + counts.alpa,
    ...counts,
    last: marked.slice(0, 10).map((r) => ({sessionDate: r.sessionDate,
      status: r.status, title: String(r.title || "")})),
  };
}

/** The active voucher (the active term with the latest deadline). */
function voucherOf(terms, nowMs) {
  const active = (terms || [])
      .filter((t) => (t.status || "active") === "active")
      .sort((a, b) => String(b.deadlineDate || "").localeCompare(String(a.deadlineDate || "")));
  const t = active[0];
  if (!t) return null;
  const days = t.deadlineDate ? daysBetween(jakartaDate(nowMs), String(t.deadlineDate)) : null;
  return {
    termId: t.id || "",
    sessionsRemaining: Number(t.sessionsRemaining) || 0,
    booked: 0,
    deadlineDate: String(t.deadlineDate || ""),
    daysLeft: days,
    status: t.status || "active",
  };
}

function isCountedTest(t) {
  return (t.status || "final") === "final" && t.valid !== false && t.placement !== true;
}

/** Test history newest first, and the codes passed at [levelKey]. */
function testsOf(tests, levelKey) {
  const rows = (tests || []).map((t) => ({
    resultId: t.resultId || "",
    codeId: t.codeId || "",
    code: t.code || t.codeId || "",
    level: t.level || "",
    finishedAtMs: Number.isFinite(Number(t.finishedAtMs)) ? Number(t.finishedAtMs) : null,
    parts: (t.parts || []).map((p) => ({skill: p.skill || "", mark: Number(p.mark) || 0,
      maxScore: Number(p.maxScore) || 0})),
    total: Number(t.total) || 0,
    max: Number(t.max) || 0,
    passed: t.passed === true,
    valid: t.valid !== false,
    status: t.status || "final",
    placement: t.placement === true,
    rank: Number.isFinite(Number(t.rank)) && t.rank !== null ? Number(t.rank) : null,
    boardSize: Number.isFinite(Number(t.boardSize)) && t.boardSize !== null ?
      Number(t.boardSize) : null,
  })).sort((a, b) => (b.finishedAtMs || 0) - (a.finishedAtMs || 0));
  const passedCodes = new Set();
  for (const t of rows) {
    if (isCountedTest(t) && t.passed && levelKeyOf(t.level) === levelKey && levelKey) {
      passedCodes.add(t.codeId);
    }
  }
  return {history: rows, passedAtLevel: passedCodes.size};
}

/**
 * The five warnings of the spec. [previous] keeps `since` of a warning that
 * was already on.
 * @return {Array<{id: number, since: number, detail: string}>}
 */
function warningsOf(summary, nowMs, previous = []) {
  const prevSince = new Map((previous || []).map((w) => [Number(w.id), Number(w.since)]));
  const out = [];
  const add = (id, detail) => out.push({id, detail,
    since: Number.isFinite(prevSince.get(id)) ? prevSince.get(id) : nowMs});
  const a = summary.attendance || {};
  if (a.records30 >= 4 && a.percent !== null && a.percent < 75) {
    add(1, `Attendance ${a.percent}% in 30 days (${a.hadir} present, ${a.alpa} absent)`);
  }
  const p = summary.practice || {};
  if (p.attempts14 >= 2 && p.average14 !== null) {
    if (p.average14 < 60) {
      add(2, `Practice average ${p.average14} in the last 14 days`);
    } else if (p.attemptsPrev14 >= 2 && p.averagePrev14 !== null &&
        p.averagePrev14 - p.average14 >= 10) {
      add(2, `Practice average fell from ${p.averagePrev14} to ${p.average14}`);
    }
  }
  const lastActive = p.lastPracticeMs !== null && p.lastPracticeMs !== undefined ?
    p.lastPracticeMs : summary.activeSinceMs;
  if (Number.isFinite(lastActive) && nowMs - lastActive >= 14 * DAY_MS) {
    add(3, `No practice for ${Math.floor((nowMs - lastActive) / DAY_MS)} days`);
  }
  const v = summary.voucher;
  if (v && (v.sessionsRemaining <= 2 || (v.daysLeft !== null && v.daysLeft <= 7))) {
    add(4, `${v.sessionsRemaining} sessions left` +
      (v.daysLeft !== null ? `, ${v.daysLeft} days to the deadline` : ""));
  }
  const counted = ((summary.tests || {}).history || []).filter(isCountedTest);
  if (counted.length >= 2 && !counted[0].passed && !counted[1].passed) {
    add(5, `Failed ${counted[1].code} and ${counted[0].code} in a row`);
  }
  return out;
}

/** 0 warnings = good, 1 = attention, 2 or more = follow_up. */
function statusOf(warnings) {
  const n = (warnings || []).length;
  return n === 0 ? "good" : n === 1 ? "attention" : "follow_up";
}

/**
 * The whole summary.
 * @param {Object} inputs {user, promotion, exercises, attendance, terms,
 *   tests, note, levelHistory, previous}
 * @param {number} nowMs
 * @return {Object} the `progress_summary` document (without timestamps)
 */
function summarize(inputs, nowMs) {
  const user = inputs.user || {};
  const levelKey = levelKeyOf(user.level);
  const promotion = inputs.promotion || {};
  const tests = testsOf(inputs.tests, levelKey);
  const summary = {
    level: levelKey ? `HSK ${levelKey}` : String(user.level || ""),
    levelKey,
    group: groupOf(levelKey),
    codes: {
      count: Number(promotion.count) || 0,
      minCodes: Number(promotion.minCodes) || 3,
      next: String(promotion.next || ""),
      decision: String(promotion.decision || ""),
    },
    practice: practiceOf(inputs.exercises, nowMs),
    skills: skillsOf(inputs.exercises, nowMs),
    tests,
    attendance: attendanceOf(inputs.attendance, nowMs),
    voucher: voucherOf(inputs.terms, nowMs),
    latestNote: inputs.note ? {text: String(inputs.note.text || ""),
      teacherName: String(inputs.note.teacherName || ""),
      createdAtMs: Number(inputs.note.createdAtMs) || null} : null,
    levelHistory: (inputs.levelHistory || [])
        .map((h) => ({from: h.from || "", to: h.to || "", kind: h.kind || "promotion",
          dateMs: Number(h.dateMs) || null}))
        .sort((a, b) => (b.dateMs || 0) - (a.dateMs || 0)),
    activeSinceMs: Number.isFinite(Number(user.activeSinceMs)) ?
      Number(user.activeSinceMs) : null,
  };
  const previous = (inputs.previous || {}).warnings || [];
  summary.warnings = warningsOf(summary, nowMs, previous);
  summary.status = statusOf(summary.warnings);
  return summary;
}

/**
 * Warnings whose notice is due: on now and not sent in the last 7 days
 * (owner Q15). [notifiedAt] maps a warning id to the last send time.
 * @return {Array<{id: number, roles: Array<string>, detail: string}>}
 */
function noticesDue(summary, nowMs, notifiedAt = {}) {
  const due = [];
  for (const w of summary.warnings || []) {
    const last = Number((notifiedAt || {})[String(w.id)]);
    if (Number.isFinite(last) && nowMs - last < NOTICE_EVERY_MS) continue;
    due.push({id: w.id, roles: NOTIFY[w.id] || [], detail: w.detail});
  }
  return due;
}

/** The notice text of a warning for one role. */
function noticeText(id, name, detail) {
  const titles = {
    1: "Attendance below 75%",
    2: "Practice scores dropping",
    3: "No practice for 14 days",
    4: "Voucher running out",
    5: "Two tests failed in a row",
  };
  return {title: titles[id] || "Progress warning", body: `${name}: ${detail}`};
}

// ---------------------------------------------------------------------------
// Build 9 part 2 (supervisor 2026-11-25, "pagination so it doesn't bloat the
// website"): the numbers of one row of the teacher's Students list and the
// dashboard drill-downs, worked out here once instead of in every browser
// from six whole collections. Same rules as the app's TeacherStatsUtils and
// TeacherAttentionUtils (lib/core/utils), on Jakarta calendar days.
// ---------------------------------------------------------------------------
const STALE_ASSIGNMENT_DAYS = 3;
const INACTIVE_DAYS = 7;
const LOW_SESSIONS = 2;
const ROSTER_LESSONS_MAX = 300;

function dayOf(dateText) {
  const t = String(dateText || "").slice(0, 10);
  return /^\d{4}-\d{2}-\d{2}$/.test(t) ? t : null;
}

/** Active (status active, sessions left) and today within its dates. */
function termCounts(t, today) {
  if ((t.status || "active") !== "active") return false;
  if (!(Number(t.sessionsRemaining) > 0)) return false;
  const start = dayOf(t.startDate);
  const end = dayOf(t.deadlineDate);
  if (!start || !end) return true;
  return today >= start && today <= end;
}

function maxMs(...values) {
  let out = null;
  for (const v of values) {
    if (Number.isFinite(v) && (out === null || v > out)) out = v;
  }
  return out;
}

/**
 * The roster block of `progress_summary` and the "done" stamp of each
 * assignment.
 * @param {Object} inputs {assignments: [{id, exerciseId, assignedAtMs,
 *   dueAtMs, done, bestScore}], exercises: [{exerciseId, score,
 *   submittedAtMs}], terms, lessons: [{lessonId, completed, score,
 *   completedAtMs}], attendance: [{attended, joinedAtMs}], user:
 *   {lessonsPerTerm, level}}
 * @param {number} nowMs
 * @return {{roster: Object, stamps: Array<{id, done, bestScore}>}}
 */
function rosterOf(inputs, nowMs) {
  const today = jakartaDate(nowMs);
  const best = new Map();
  let lastExerciseMs = null;
  for (const r of inputs.exercises || []) {
    const id = String(r.exerciseId || "");
    const score = Number(r.score);
    if (id && Number.isFinite(score)) {
      if (!best.has(id) || score > best.get(id)) best.set(id, score);
    }
    lastExerciseMs = maxMs(lastExerciseMs, Number(r.submittedAtMs));
  }
  const assignments = inputs.assignments || [];
  let completed = 0;
  let overdue = 0;
  let practiceSum = 0;
  const attention = [];
  const stamps = [];
  for (const a of assignments) {
    const score = best.has(a.exerciseId) ? Math.round(best.get(a.exerciseId)) : null;
    const done = score !== null;
    if (done) {
      completed += 1;
      practiceSum += score;
    } else if (Number.isFinite(a.dueAtMs) && jakartaDate(a.dueAtMs) < today) {
      overdue += 1;
      attention.push({reason: "overdueExercise", count: null});
    } else if (Number.isFinite(a.assignedAtMs)) {
      const days = Math.floor((nowMs - a.assignedAtMs) / DAY_MS);
      if (days >= STALE_ASSIGNMENT_DAYS) attention.push({reason: "staleAssignment", count: days});
    }
    if (a.id && (a.done !== done || (a.bestScore ?? null) !== score)) {
      stamps.push({id: a.id, done, bestScore: score});
    }
  }
  const lessons = (inputs.lessons || []).map((p) => ({
    lessonId: String(p.lessonId || ""),
    completed: p.completed === true,
    score: Number.isFinite(Number(p.score)) && p.score !== null ? Number(p.score) : null,
    completedAtMs: Number.isFinite(Number(p.completedAtMs)) && p.completedAtMs !== null ?
      Number(p.completedAtMs) : null,
  }));
  const scored = lessons.filter((p) => p.score !== null).map((p) => p.score);
  const lastLessonMs = maxMs(...lessons.filter((p) => p.completed).map((p) => p.completedAtMs));
  const lastAttendMs = maxMs(...(inputs.attendance || [])
      .filter((r) => r.attended === true).map((r) => Number(r.joinedAtMs)));
  const sessions = (inputs.terms || []).filter((t) => termCounts(t, today))
      .reduce((s, t) => s + Number(t.sessionsRemaining), 0);
  // Inactive: has done something before, nothing in the last 7 days.
  const hasHistory = lessons.some((p) => p.completed) || (inputs.exercises || []).length > 0;
  const lastActivity = maxMs(lastLessonMs, lastExerciseMs);
  if (hasHistory && (lastActivity === null || lastActivity < nowMs - INACTIVE_DAYS * DAY_MS)) {
    attention.push({reason: "inactiveStudent", count: INACTIVE_DAYS});
  }
  if (sessions <= LOW_SESSIONS) attention.push({reason: "lowSessions", count: sessions});
  const user = inputs.user || {};
  const roster = {
    homeworkAssigned: assignments.length,
    homeworkCompleted: completed,
    homeworkOverdue: overdue,
    practiceAvg: completed ? Math.round(practiceSum / completed) : null,
    practiceCount: completed,
    sessionsRemaining: sessions,
    lessonsCompleted: lessons.filter((p) => p.completed).length,
    lessonAvg: scored.length ? Math.round(scored.reduce((s, x) => s + x, 0) / scored.length) : null,
    lessons: lessons.slice(0, ROSTER_LESSONS_MAX),
    lessonsPerTerm: Number(user.lessonsPerTerm) > 0 ? Number(user.lessonsPerTerm) : 8,
    rawLevel: user.level ? String(user.level) : null,
    lastActiveMs: maxMs(lastLessonMs, lastExerciseMs, lastAttendMs),
    attention,
    attentionCount: attention.length,
    hasAttention: attention.length > 0,
    // The Students list's "needs attention" figure (few sessions or late work).
    needsAttention: sessions <= LOW_SESSIONS || overdue > 0,
    dayKey: today,
  };
  return {roster, stamps};
}

const STAMP_KEYS = new Set(["done", "bestScore"]);

function sameValue(a, b) {
  if (a === b) return true;
  if (a && typeof a.isEqual === "function") return a.isEqual(b);
  return JSON.stringify(a) === JSON.stringify(b);
}

/** True when an assignment changed only in the stamp the refresh writes. */
function onlyStampChanged(before, after) {
  const keys = new Set([...Object.keys(before || {}), ...Object.keys(after || {})]);
  for (const k of keys) {
    if (STAMP_KEYS.has(k)) continue;
    if (!sameValue((before || {})[k], (after || {})[k])) return false;
  }
  return true;
}

module.exports = {
  onlyStampChanged,
  rosterOf,
  STALE_ASSIGNMENT_DAYS,
  INACTIVE_DAYS,
  DAY_MS,
  NOTIFY,
  jakartaDate,
  daysBetween,
  isoWeek,
  practiceOf,
  skillsOf,
  attendanceOf,
  voucherOf,
  testsOf,
  warningsOf,
  statusOf,
  summarize,
  noticesDue,
  noticeText,
};
