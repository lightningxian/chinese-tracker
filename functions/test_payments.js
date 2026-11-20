"use strict";

// Build 5: payments and vouchers (docs/PLAN.md §4, MT-01 to MT-04).
const assert = require("node:assert/strict");
const p = require("./payments");

const KEY = "test-server-key";
const sig = (order, status, gross) => p.signatureFor(order, status, gross, KEY);

// MT-04: the signature (a wrong one is refused).
const good = sig("ES-1", "200", "2450000.00");
assert.match(good, /^[0-9a-f]{128}$/);
assert.ok(p.signatureOk(good, "ES-1", "200", "2450000.00", KEY));
assert.ok(!p.signatureOk(good, "ES-1", "200", "2450001.00", KEY), "another amount");
assert.ok(!p.signatureOk(good, "ES-2", "200", "2450000.00", KEY), "another order");
assert.ok(!p.signatureOk(sig("ES-1", "200", "2450000.00").replace(/.$/, "0"), "ES-1", "200",
    "2450000.00", KEY) || good.endsWith("0"));
assert.ok(!p.signatureOk("", "ES-1", "200", "2450000.00", KEY));
assert.ok(!p.signatureOk(good, "ES-1", "200", "2450000.00", "other-key"));

// Status mapping.
assert.equal(p.invoiceStatusFor("settlement"), "paid");
assert.equal(p.invoiceStatusFor("capture", "accept"), "paid");
assert.equal(p.invoiceStatusFor("capture", "challenge"), null);
assert.equal(p.invoiceStatusFor("pending"), null);
assert.equal(p.invoiceStatusFor("expire"), "expired");
assert.equal(p.invoiceStatusFor("cancel"), "failed");
assert.equal(p.invoiceStatusFor("deny"), "failed");
assert.equal(p.invoiceStatusFor("failure"), "failed");

// MT-01: settlement on a pending invoice → credit once.
const pending = {status: "pending", amount: 2450000};
assert.equal(p.creditDecision(pending, "paid", "2450000.00"), "credit");
// MT-03: the same notification again on the now final invoice → nothing.
assert.equal(p.creditDecision({...pending, status: "paid"}, "paid", "2450000.00"), "ignore-final");
// MT-02: pending stays pending; expire and cancel → no credit.
assert.equal(p.creditDecision(pending, null, "2450000.00"), "no-change");
assert.equal(p.creditDecision(pending, "expired", "2450000.00"), "flip");
assert.equal(p.creditDecision(pending, "failed", "2450000.00"), "flip");
assert.equal(p.creditDecision({...pending, status: "expired"}, "paid", "2450000.00"), "ignore-final",
    "an expired invoice is never credited later");
// A different amount is not credited.
assert.equal(p.creditDecision(pending, "paid", "100.00"), "amount-mismatch");

// Deadlines and expiry (Jakarta days).
assert.equal(p.termDeadline("2026-11-20", 60), "2027-01-19");
assert.equal(p.termDeadline("2026-11-20", 0), "2027-01-19", "60 by default");
assert.equal(p.jakartaDate(Date.parse("2026-11-19T17:00:00Z")), "2026-11-20");
const terms = [
  {id: "a", status: "active", deadlineDate: "2026-11-19", sessionsRemaining: 3},
  {id: "b", status: "active", deadlineDate: "2026-11-20", sessionsRemaining: 2},
  {id: "c", status: "expired", deadlineDate: "2026-10-01", sessionsRemaining: 4},
  {id: "d", status: "active", deadlineDate: "", sessionsRemaining: 4},
  {id: "e", status: "depleted", deadlineDate: "2026-10-01", sessionsRemaining: 0},
];
assert.deepEqual(p.expiredTerms(terms, "2026-11-20"), [{id: "a", forfeited: 3}],
    "the deadline day itself is still valid; expired / depleted / no date skipped");

// Price list rows.
const row = p.cleanPriceItem({id: "package8", name: "8 class sessions", nameChinese: "8次课程",
  price: 2450000, kind: "sessions", sessions: 8, validDays: 60});
assert.equal(row.nameChinese, "8次课程");
assert.equal(row.validDays, 60);
assert.equal(row.active, true);
assert.equal(p.cleanPriceItem({id: "book", price: 1, kind: "book", sessions: 4}).sessions, 0);
assert.equal(p.cleanPriceItem({id: "x", price: 1, kind: "sessions", sessions: 8, active: false}).active, false);

// Who may buy.
assert.equal(p.buyerRole({role: "student"}, "s1", "s1"), "self");
assert.equal(p.buyerRole({role: "student"}, "s1", "s2"), "");
assert.equal(p.buyerRole({role: "parent", studentIds: ["s1"]}, "p1", "s1"), "parent");
assert.equal(p.buyerRole({role: "parent", studentIds: ["s1"]}, "p1", "s2"), "");
assert.equal(p.buyerRole({role: "teacher"}, "t1", "s2"), "staff");

console.log("test_payments: all passed (MT-01, MT-02, MT-03, MT-04)");
