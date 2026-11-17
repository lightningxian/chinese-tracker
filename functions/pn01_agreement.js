"use strict";

/**
 * PN-01 (thesis spec section 13): the system's marks on typed answers
 * compared with a teacher's marks. Reads a CSV with the columns
 *
 *   type,keys,answer,teacher
 *
 * - type: type_hanzi | type_pinyin | compose_sentences
 * - keys: accepted keys separated by `|`; for compose_sentences the words
 *   in the right order separated by `/`
 * - answer: what the student typed; for compose_sentences the words in the
 *   student's order separated by `/`
 * - teacher: the teacher's mark as a share of the question: 1, 0.5 or 0
 *
 * and prints the system's mark per row and the agreement in percent.
 *
 *   node functions/pn01_agreement.js functions/fixtures/pn01_sample.csv
 *
 * The 200 real answers come from the trial (owner's CSV, same columns).
 */

const fs = require("node:fs");
const play = require("./exercise_play");

/** One CSV line into fields; double quotes may wrap a field. */
function splitCsvLine(line) {
  const out = [];
  let cur = "";
  let quoted = false;
  for (let i = 0; i < line.length; i++) {
    const ch = line[i];
    if (quoted) {
      if (ch === "\"" && line[i + 1] === "\"") {
        cur += "\"";
        i++;
      } else if (ch === "\"") {
        quoted = false;
      } else {
        cur += ch;
      }
    } else if (ch === "\"") {
      quoted = true;
    } else if (ch === ",") {
      out.push(cur);
      cur = "";
    } else {
      cur += ch;
    }
  }
  out.push(cur);
  return out;
}

/** Rows of the CSV (header skipped, empty lines and `#` comments too). */
function readRows(text) {
  const lines = String(text).replace(/^﻿/, "").split(/\r?\n/)
      .filter((l) => l.trim() && !l.trim().startsWith("#"));
  return lines.slice(1).map((l) => {
    const [type, keys, answer, teacher] = splitCsvLine(l);
    return {type: type.trim(), keys, answer, teacher: Number(teacher)};
  });
}

/** The system's mark (credit 1, 0.5 or 0) for one row. */
function systemMark(row) {
  if (row.type === "compose_sentences") {
    const item = {id: "x", type: row.type,
      question: {segments: row.keys.split("/").map((s) => s.trim())}};
    return play.checkAnswer(item, {order: row.answer.split("/").map((s) => s.trim())}).credit;
  }
  const item = {id: "x", type: row.type,
    question: {options: row.keys.split("|").map((s) => s.trim())}};
  return play.checkAnswer(item, {text: row.answer}).credit;
}

/**
 * @param {Array<Object>} rows
 * @return {{rows: Array<Object>, agree: number, total: number, percent: number}}
 */
function agreement(rows) {
  const marked = rows.map((r) => ({...r, system: systemMark(r)}));
  const agree = marked.filter((r) => r.system === r.teacher).length;
  const total = marked.length;
  return {rows: marked, agree, total,
    percent: total ? Math.round((agree / total) * 1000) / 10 : 0};
}

if (require.main === module) {
  const file = process.argv[2];
  if (!file) {
    console.error("Usage: node functions/pn01_agreement.js <answers.csv>");
    process.exit(2);
  }
  const result = agreement(readRows(fs.readFileSync(file, "utf8")));
  result.rows.forEach((r, i) => {
    const flag = r.system === r.teacher ? "  " : "≠ ";
    console.log(`${flag}${String(i + 1).padStart(3)}  ${r.type.padEnd(17)} ` +
      `system ${String(r.system).padEnd(3)} teacher ${String(r.teacher).padEnd(3)} ` +
      `${r.answer}  ⇢  ${r.keys}`);
  });
  console.log(`PN-01 agreement: ${result.agree} of ${result.total} = ${result.percent}%`);
}

module.exports = {splitCsvLine, readRows, systemMark, agreement};
