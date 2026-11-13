"use strict";

// node test_reminders.js
const assert = require("assert");
const {jakartaDateKey, dueSoon, reminderText} = require("./reminders");

// 2026-11-13 07:00 Jakarta = 2026-11-13T00:00:00Z
const now = Date.parse("2026-11-13T00:00:00Z");
const day = 24 * 3600 * 1000;
const today = jakartaDateKey(now);
assert.strictEqual(today, "2026-11-13");
// 23:30 UTC is already the 14th in Jakarta.
assert.strictEqual(jakartaDateKey(Date.parse("2026-11-13T23:30:00Z")), "2026-11-14");

const dueTonight = Date.parse("2026-11-13T16:59:59Z"); // 23:59:59 Jakarta
const items = [
  {id: "a", dueMillis: dueTonight},
  {id: "b", dueMillis: dueTonight, reminderSentOn: today},
  {id: "c", dueMillis: now - 1},
  {id: "d", dueMillis: now + 2 * day},
  {id: "e", dueMillis: NaN},
  {id: "f", dueMillis: now + day, reminderSentOn: "2026-11-12"},
];
assert.deepStrictEqual(
    dueSoon(items, now, day, today).map((i) => i.id),
    ["a", "f"],
    "only due within the window and not yet reminded today",
);

const text = reminderText("  HSK 2 Reading A ", dueTonight, now);
assert.strictEqual(text.title, "Exercise due today");
assert.strictEqual(
    text.body, "HSK 2 Reading A is due today. Open Easy Study to finish it.",
);
const tomorrow = reminderText("", now + day, now);
assert.strictEqual(tomorrow.title, "Exercise due tomorrow");
assert.ok(tomorrow.body.startsWith("an exercise is due tomorrow"));

console.log("test_reminders: ok");
