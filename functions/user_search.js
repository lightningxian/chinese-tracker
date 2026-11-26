"use strict";

/**
 * Build 9A session 2 (supervisor 2026-11-25): the admin's Users list is read
 * a page at a time, so its search must be a query. Each `users` document
 * carries a small index written only by the `onUserSearchIndex` trigger:
 * - `nameLower`: the Latin name in lower case (the list's order);
 * - `searchPrefixes`: every beginning (1–20 characters) of the Latin name,
 *   each word of it, the Chinese name, the e-mail and its part before "@";
 *   the app asks `searchPrefixes array-contains <what was typed>`;
 * - `listed`: false for a student waiting for approval or rejected (they
 *   are shown under Approval, not in the list).
 * The Flutter twin of [normalizeQuery] is `UserSearch.normalize`.
 */

const MAX_PREFIX = 20;

function normalizeQuery(text) {
  return String(text || "").trim().toLowerCase().replace(/\s+/g, " ").slice(0, MAX_PREFIX);
}

function prefixesOf(text, out) {
  const t = normalizeQuery(text);
  if (!t) return;
  const chars = [...t];
  for (let i = 1; i <= Math.min(chars.length, MAX_PREFIX); i++) {
    out.add(chars.slice(0, i).join(""));
  }
}

function latinNameOf(u) {
  return String(u.latinName || u.name || u.displayName || "").trim();
}

/** The index fields of one user document. */
function searchFieldsOf(u) {
  const user = u || {};
  const latin = latinNameOf(user);
  const set = new Set();
  prefixesOf(latin, set);
  for (const word of latin.split(/\s+/)) prefixesOf(word, set);
  prefixesOf(user.nameChinese, set);
  prefixesOf(user.nameIndonesian, set);
  const email = String(user.email || "").trim().toLowerCase();
  prefixesOf(email, set);
  prefixesOf(email.split("@")[0], set);
  const waiting = (user.role || "") === "student" &&
    (user.status === "pending" || user.status === "rejected");
  const out = {
    nameLower: latin.toLowerCase(),
    searchPrefixes: [...set].sort(),
    listed: !waiting,
  };
  // The app reads a missing `active` as true; the list filters on it.
  if (typeof user.active !== "boolean") out.active = true;
  return out;
}

/** True when the stored fields already equal [fields] (no write needed). */
function sameFields(user, fields) {
  const u = user || {};
  if (fields.active !== undefined && u.active !== fields.active) return false;
  return u.nameLower === fields.nameLower && u.listed === fields.listed &&
    Array.isArray(u.searchPrefixes) &&
    u.searchPrefixes.length === fields.searchPrefixes.length &&
    u.searchPrefixes.every((x, i) => x === fields.searchPrefixes[i]);
}

/** Profile fields the progress summary copies (name, level, on/off …). */
const SUMMARY_FIELDS = ["active", "status", "level", "name", "nameChinese", "nameIndonesian",
  "latinName", "termSize", "teacherId"];

function summaryFieldsChanged(before, after) {
  return SUMMARY_FIELDS.some((k) => JSON.stringify((before || {})[k] ?? null) !==
    JSON.stringify((after || {})[k] ?? null));
}

module.exports = {MAX_PREFIX, normalizeQuery, searchFieldsOf, sameFields, summaryFieldsChanged};
