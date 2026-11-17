"use strict";

// Typing matcher cases (thesis spec section 7; PN-02, PN-03). Run:
//   node functions/test_typing_matcher.js
const assert = require("node:assert/strict");
const m = require("./typing_matcher");

let passed = 0;
function check(name, fn) {
  fn();
  passed += 1;
  console.log(`ok - ${name}`);
}

// PN-02: variants of the same answer get full credit.
check("PN-02 ending punctuation: 你好 vs 你好！", () => {
  assert.deepEqual(m.matchHanzi("你好！", ["你好"]).credit, 1);
});
check("PN-02 traditional hanzi: 謝謝 vs 谢谢", () => {
  assert.equal(m.matchHanzi("謝謝", ["谢谢"]).credit, 1);
});
check("PN-02 full-width comma and spaces", () => {
  assert.equal(m.matchHanzi(" 你好，老师 ", ["你好,老师"]).credit, 1);
});
check("PN-02 tone marks vs tone numbers: nǐ hǎo vs ni3 hao3", () => {
  assert.equal(m.matchPinyin("ni3 hao3", ["nǐ hǎo"]).credit, 1);
  assert.equal(m.matchPinyin("nǐ hǎo", ["ni3 hao3"]).credit, 1);
});
check("PN-02 no spaces and upper case: NIhao with tones", () => {
  assert.equal(m.matchPinyin("Nǐhǎo", ["ni3 hao3"]).credit, 1);
  assert.equal(m.matchPinyin("ni3hao3", ["nǐ hǎo"]).credit, 1);
});
check("PN-02 u with umlaut written as v or u:", () => {
  assert.equal(m.matchPinyin("lv4", ["lǜ"]).credit, 1);
  assert.equal(m.matchPinyin("lu:4", ["lǜ"]).credit, 1);
});
check("PN-02 any accepted key counts", () => {
  assert.equal(m.matchHanzi("不用客气", ["不客气", "不用客气"]).credit, 1);
});

// PN-03: near misses get half credit and go to the teacher.
check("PN-03 pinyin without tones: nǐ hǎo vs ni hao", () => {
  const r = m.matchPinyin("ni hao", ["nǐ hǎo"]);
  assert.equal(r.credit, 0.5);
  assert.equal(r.review, true);
});
check("PN-03 pinyin with a wrong tone", () => {
  const r = m.matchPinyin("ni2 hao3", ["nǐ hǎo"]);
  assert.equal(r.credit, 0.5);
  assert.equal(r.review, true);
});
check("PN-03 one wrong homophone: 我很喜欢和茶 vs 我很喜欢喝茶", () => {
  const r = m.matchHanzi("我很喜欢和茶", ["我很喜欢喝茶"]);
  assert.equal(r.credit, 0.5);
  assert.equal(r.review, true);
});

// Zero.
check("one wrong character in a two-character word is zero (S = 0.5)", () => {
  assert.equal(m.matchHanzi("你号", ["你好"]).credit, 0);
});
check("wrong pinyin letters are zero, not flagged", () => {
  const r = m.matchPinyin("ni3 hen3", ["ni3 hao3"]);
  assert.equal(r.credit, 0);
  assert.equal(r.review, false);
});
check("an empty answer is zero", () => {
  assert.equal(m.matchHanzi("  ", ["你好"]).credit, 0);
  assert.equal(m.matchPinyin("", ["ni3"]).credit, 0);
});
check("a key typed without tones compares letters only", () => {
  assert.equal(m.matchPinyin("ni3 hao3", ["ni hao"]).credit, 1);
});
check("syllable split: xi'an is two syllables, xian is one", () => {
  assert.equal(m.pinyin.parse("xi'an").length, 2);
  assert.equal(m.pinyin.parse("xian1").length, 1);
});

console.log(`typing_matcher: ${passed} checks passed`);
