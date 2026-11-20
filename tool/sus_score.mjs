#!/usr/bin/env node
// Build 8 (docs/PLAN.md §4, Must 6): SUS scoring for the trial.
//   node tool/sus_score.mjs docs/trial/sus_results.csv
// CSV: respondent,role,q1,...,q10 (answers 1 to 5). Standard SUS: odd items
// give (answer - 1), even items (5 - answer); the sum times 2.5 is the
// respondent's score (0 to 100). Prints the mean, per role, per item.
import {readFileSync} from "node:fs";
import {fileURLToPath} from "node:url";

export function parseCsv(text) {
  const lines = text.replace(/^﻿/, "").split(/\r?\n/).filter((l) => l.trim());
  const head = lines[0].split(",").map((h) => h.trim().toLowerCase());
  return lines.slice(1).map((line, n) => {
    const cells = line.split(",").map((c) => c.trim());
    const row = Object.fromEntries(head.map((h, i) => [h, cells[i]]));
    const answers = Array.from({length: 10}, (_, i) => Number(row[`q${i + 1}`]));
    if (answers.some((a) => !Number.isInteger(a) || a < 1 || a > 5)) {
      throw new Error(`row ${n + 2} (${row.respondent}): every q1..q10 must be 1 to 5`);
    }
    return {respondent: row.respondent || `#${n + 1}`, role: row.role || "", answers};
  });
}

export function susScore(answers) {
  const sum = answers.reduce((t, a, i) => t + (i % 2 === 0 ? a - 1 : 5 - a), 0);
  return sum * 2.5;
}

const mean = (xs) => (xs.length ? xs.reduce((t, x) => t + x, 0) / xs.length : 0);
const round = (x) => Math.round(x * 100) / 100;

export function summarise(rows) {
  const scores = rows.map((r) => ({...r, score: susScore(r.answers)}));
  const roles = {};
  for (const s of scores) (roles[s.role] ||= []).push(s.score);
  return {
    respondents: scores.length,
    mean: round(mean(scores.map((s) => s.score))),
    byRole: Object.fromEntries(Object.entries(roles).map(([k, v]) => [k, round(mean(v))])),
    itemMeans: Array.from({length: 10}, (_, i) => round(mean(rows.map((r) => r.answers[i])))),
    scores: scores.map((s) => ({respondent: s.respondent, role: s.role, score: s.score})),
    aboveTarget: mean(scores.map((s) => s.score)) > 70,
  };
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  const file = process.argv[2];
  if (!file) {
    console.error("usage: node tool/sus_score.mjs <results.csv>");
    process.exit(2);
  }
  const s = summarise(parseCsv(readFileSync(file, "utf8")));
  console.log(`respondents: ${s.respondents}`);
  console.log(`SUS mean: ${s.mean} (${s.aboveTarget ? "above" : "not above"} the target of 70)`);
  for (const [role, m] of Object.entries(s.byRole)) console.log(`  ${role || "(no role)"}: ${m}`);
  console.log(`item means: ${s.itemMeans.map((m, i) => `q${i + 1}=${m}`).join(" ")}`);
  for (const r of s.scores) console.log(`  ${r.respondent} (${r.role}): ${r.score}`);
}
