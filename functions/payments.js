"use strict";

/**
 * Build 5 (docs/PLAN.md §4): Midtrans payments and vouchers as pure logic.
 * index.js reads and writes the documents. Spec:
 * docs/THESIS_FEATURE_BACKLOG.md §6 (MT-01 to MT-04).
 */

const crypto = require("crypto");

const DAY_MS = 24 * 60 * 60 * 1000;
const JAKARTA_OFFSET_MS = 7 * 60 * 60 * 1000;

/** The version of the flyer's terms a buyer ticks (decision 4). */
const TERMS_VERSION = "2026-10-flyer";

/** Midtrans notification signature: SHA-512 of order, status, amount, key. */
function signatureFor(orderId, statusCode, grossAmount, serverKey) {
  return crypto.createHash("sha512")
      .update(`${orderId}${statusCode}${grossAmount}${serverKey}`)
      .digest("hex");
}

/** Whether [given] is the right signature, in constant time. */
function signatureOk(given, orderId, statusCode, grossAmount, serverKey) {
  const expected = Buffer.from(signatureFor(orderId, statusCode, grossAmount, serverKey), "utf8");
  const g = Buffer.from(String(given || ""), "utf8");
  return expected.length === g.length && crypto.timingSafeEqual(expected, g);
}

/**
 * Invoice status for a Midtrans transaction status: `paid`, `expired`,
 * `failed`, or null (pending / challenge: leave the invoice as it is).
 */
function invoiceStatusFor(transactionStatus, fraudStatus) {
  if (transactionStatus === "settlement" ||
      (transactionStatus === "capture" && fraudStatus !== "challenge")) {
    return "paid";
  }
  if (transactionStatus === "expire") return "expired";
  if (["deny", "cancel", "failure"].includes(transactionStatus)) return "failed";
  return null;
}

/**
 * What a notification does to an invoice.
 * @return {string} `credit` (flip to paid and credit), `flip` (flip to
 *   expired / failed, no credit), `ignore-final` (already final: MT-03),
 *   `amount-mismatch` (paid for another amount: left pending), `no-change`
 *   (pending / challenge)
 */
function creditDecision(invoice, newStatus, grossAmount) {
  const status = (invoice || {}).status || "pending";
  // Owner 2026-11-24: an invoice the admin discarded that the buyer pays
  // anyway is credited (the money is real); any other news about it is
  // ignored.
  if (status === "discarded" && newStatus !== "paid") return "ignore-final";
  if (status !== "pending" && status !== "discarded") return "ignore-final";
  if (!newStatus) return "no-change";
  if (newStatus !== "paid") return "flip";
  if (Math.round(Number(grossAmount)) !== Math.round(Number((invoice || {}).amount))) {
    return "amount-mismatch";
  }
  return "credit";
}

/** `YYYY-MM-DD` of the Jakarta day of [ms]. */
function jakartaDate(ms) {
  return new Date(ms + JAKARTA_OFFSET_MS).toISOString().slice(0, 10);
}

/** The deadline of a term starting [startDate] that is valid [validDays]. */
function termDeadline(startDate, validDays) {
  const start = Date.parse(`${startDate}T00:00:00Z`);
  const days = Number(validDays) > 0 ? Math.floor(Number(validDays)) : 60;
  return new Date(start + days * DAY_MS).toISOString().slice(0, 10);
}

/**
 * Active terms whose deadline has passed ([todayKey] = Jakarta `YYYY-MM-DD`;
 * the deadline day itself is still valid).
 * @return {Array<{id: string, forfeited: number}>}
 */
function expiredTerms(terms, todayKey) {
  return (terms || [])
      .filter((t) => (t.status || "active") === "active")
      .filter((t) => /^\d{4}-\d{2}-\d{2}$/.test(String(t.deadlineDate || "")))
      .filter((t) => String(t.deadlineDate) < String(todayKey))
      .map((t) => ({id: t.id, forfeited: Math.max(0, Number(t.sessionsRemaining) || 0)}));
}

/** A clean Price list row (server side). */
function cleanPriceItem(it) {
  const price = Number(it.price);
  const kind = String(it.kind || "other");
  const sessions = kind === "sessions" && Number.isInteger(Number(it.sessions)) &&
    Number(it.sessions) > 0 ? Number(it.sessions) : 0;
  const valid = Number(it.validDays);
  return {
    id: String(it.id),
    name: String(it.name || it.id),
    nameChinese: String(it.nameChinese || "").trim(),
    price,
    kind,
    sessions,
    validDays: Number.isInteger(valid) && valid > 0 ? valid : 0,
    active: it.active !== false,
  };
}

/**
 * Who may buy for [studentId]: the student themself, or a parent linked to
 * them. Staff create invoices as before.
 * @return {string} `self`, `parent`, `staff` or "" (refused)
 */
function buyerRole(caller, callerUid, studentId) {
  const role = (caller || {}).role || "student";
  if (role === "admin" || role === "teacher") return "staff";
  if (role === "student") return callerUid === studentId ? "self" : "";
  if (role === "parent") {
    return ((caller || {}).studentIds || []).includes(studentId) ? "parent" : "";
  }
  return "";
}

/**
 * Owner 2026-11-24: may [invoice] be discarded (or [restore]d)? Returns an
 * error code or "".
 */
function discardRefusal(invoice, restore, reason) {
  const status = (invoice || {}).status || "pending";
  if (restore) return status === "discarded" ? "" : "not-discarded";
  if (status === "paid") return "paid";
  if (status === "discarded") return "already";
  if (!String(reason || "").trim()) return "reason";
  return "";
}

module.exports = {
  discardRefusal,
  TERMS_VERSION,
  signatureFor,
  signatureOk,
  invoiceStatusFor,
  creditDecision,
  jakartaDate,
  termDeadline,
  expiredTerms,
  cleanPriceItem,
  buyerRole,
};
