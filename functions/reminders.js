"use strict";

/**
 * Pure helpers for the daily "due today" reminders (no Firebase here, so
 * `node test_reminders.js` runs without an emulator).
 */

const JAKARTA_OFFSET_MS = 7 * 60 * 60 * 1000;

/** `yyyy-mm-dd` of the Jakarta calendar day (UTC+7, no daylight saving). */
function jakartaDateKey(millis) {
  return new Date(millis + JAKARTA_OFFSET_MS).toISOString().slice(0, 10);
}

/**
 * Assignments that are due inside [now, now + windowMs] and have not been
 * reminded today. Each item: {dueMillis, reminderSentOn?}.
 *
 * @param {Array<Object>} assignments
 * @param {number} nowMillis
 * @param {number} windowMs
 * @param {string} todayKey from {@link jakartaDateKey}
 * @return {Array<Object>}
 */
function dueSoon(assignments, nowMillis, windowMs, todayKey) {
  return assignments.filter((a) => {
    const due = Number(a.dueMillis);
    if (!Number.isFinite(due)) return false;
    if (due < nowMillis || due > nowMillis + windowMs) return false;
    return a.reminderSentOn !== todayKey;
  });
}

/**
 * The notification text. Notifications written by the functions are English
 * (like the grading and registration ones); the app shows them as-is.
 * @param {string} exerciseTitle
 * @param {number} dueMillis
 * @param {number} nowMillis
 * @return {{title: string, body: string}}
 */
function reminderText(exerciseTitle, dueMillis, nowMillis) {
  const title = (exerciseTitle || "").trim() || "an exercise";
  const today = jakartaDateKey(nowMillis) === jakartaDateKey(dueMillis);
  return {
    title: today ? "Exercise due today" : "Exercise due tomorrow",
    body: `${title} is due ${today ? "today" : "tomorrow"}. ` +
      "Open Easy Study to finish it.",
  };
}

module.exports = {jakartaDateKey, dueSoon, reminderText};
