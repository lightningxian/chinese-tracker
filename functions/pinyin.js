"use strict";

/**
 * Pinyin as the typing matcher compares it: a list of syllables, each a
 * base (letters, `v` for u with umlaut) and a tone 1-4 (0 = neutral or not
 * typed). Tone marks (`nǐ`), tone numbers (`ni3`), `u:` / `v` / `ü` and
 * missing spaces (`nihao`) all read the same.
 *
 * Syllable boundaries come from a pattern: an optional starting consonant
 * and an ending. It accepts a few combinations Chinese does not use; that
 * is harmless here because answer and key are split the same way.
 */

const STARTS = "zh|ch|sh|b|p|m|f|d|t|n|l|g|k|h|j|q|x|r|z|c|s|y|w";
const ENDS = [
  "a", "ai", "an", "ang", "ao", "e", "ei", "en", "eng", "er", "i", "ia",
  "ian", "iang", "iao", "ie", "in", "ing", "iong", "iu", "o", "ong", "ou",
  "u", "ua", "uai", "uan", "uang", "ue", "ui", "un", "uo", "v", "ve",
].join("|");
const SYLLABLE = new RegExp(`^(?:${STARTS})?(?:${ENDS})$`);

/** Combining tone marks after NFD: macron, acute, caron, grave. */
const TONE_MARKS = {"\u0304": 1, "\u0301": 2, "\u030c": 3, "\u0300": 4};
const UMLAUT = "\u0308";

/**
 * Letters of the text in chunks; a chunk ends at a space, a mark or a tone
 * number. Each letter carries the tone mark written on it (0 if none).
 */
function chunksOf(text) {
  const s = String(text || "").toLowerCase().normalize("NFD")
      .replace(/u:/g, "v");
  const chunks = [];
  let cur = {letters: [], digit: null};
  const close = () => {
    if (cur.letters.length) chunks.push(cur);
    cur = {letters: [], digit: null};
  };
  for (const ch of s) {
    if (ch >= "a" && ch <= "z") {
      cur.letters.push({c: ch, tone: 0});
    } else if (TONE_MARKS[ch] && cur.letters.length) {
      cur.letters[cur.letters.length - 1].tone = TONE_MARKS[ch];
    } else if (ch === UMLAUT && cur.letters.length) {
      const last = cur.letters[cur.letters.length - 1];
      if (last.c === "u") last.c = "v";
    } else if (ch >= "0" && ch <= "5") {
      cur.digit = Number(ch) % 5;
      close();
    } else {
      close();
    }
  }
  close();
  return chunks;
}

/**
 * Splits letters into syllables: the fewest pieces that each fit the
 * pattern, a longer first piece when two splits tie. Null if none fits.
 */
function split(word) {
  const n = word.length;
  const best = new Array(n + 1).fill(null);
  best[n] = [];
  for (let i = n - 1; i >= 0; i--) {
    for (let len = Math.min(6, n - i); len >= 1; len--) {
      const piece = word.slice(i, i + len);
      const rest = best[i + len];
      if (rest === null || !SYLLABLE.test(piece)) continue;
      if (best[i] === null || rest.length + 1 < best[i].length) {
        best[i] = [piece, ...rest];
      }
    }
  }
  return best[0];
}

/**
 * @param {string} text typed pinyin
 * @return {Array<{base: string, tone: number}>}
 */
function parse(text) {
  const out = [];
  for (const chunk of chunksOf(text)) {
    const word = chunk.letters.map((l) => l.c).join("");
    const pieces = split(word) || [word];
    let at = 0;
    pieces.forEach((piece, k) => {
      const letters = chunk.letters.slice(at, at + piece.length);
      at += piece.length;
      let tone = letters.reduce((t, l) => l.tone || t, 0);
      if (!tone && k === pieces.length - 1 && chunk.digit !== null) {
        tone = chunk.digit;
      }
      out.push({base: piece, tone});
    });
  }
  return out;
}

/** `ni3 hao3` style, for logs and the teacher's queue. */
function toNumbered(syllables) {
  return syllables.map((s) => `${s.base}${s.tone || ""}`).join(" ");
}

module.exports = {parse, split, toNumbered};
