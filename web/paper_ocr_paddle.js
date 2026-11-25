// The paper reader's text engine since Build 1C (docs/PLAN.md §4): Tesseract
// (already loaded for the old scanner) finds the lines of a cleaned page;
// each line is cut at its wide gaps and read by the PP-OCRv5 mobile
// recognition model through onnxruntime-web. Measured on the practice
// paper: 79 of 80 questions right as read, against 37 with Tesseract alone
// (tool/paper_measure). The model files (about 31 MB) are served from our
// own hosting under ocr/ (scripts/fetch_paper_ocr.mjs) and loaded only when
// a paper is read. Nothing leaves the computer.
//
// window.chineseTrackerPaperOcrPaddle(imageBytes, onProgress) -> text
// window.chineseTrackerPaperOcrPaddleCanvas(canvas, onProgress) -> text
// window.chineseTrackerPaperOcrPaddleRelease()
// window.chineseTrackerPaperOcrPaddleBase: where ocr/ lives (default: next
// to the page).
(function () {
  'use strict';

  var INK = 160; // a pixel darker than this is ink (the page is cleaned grey)
  var IDLE_MS = 120000;
  var engine = null; // {session, dict}
  var lineWorker = null;
  var idle = null;

  function base() {
    return window.chineseTrackerPaperOcrPaddleBase ||
        new URL('ocr/', document.baseURI).href;
  }

  function loadScript(src) {
    return new Promise(function (resolve, reject) {
      var s = document.createElement('script');
      s.src = src;
      s.onload = resolve;
      s.onerror = function () { reject(new Error('Could not load ' + src)); };
      document.head.appendChild(s);
    });
  }

  async function loadEngine() {
    if (engine) return engine;
    var b = base();
    if (!window.ort) await loadScript(b + 'ort.wasm.min.js');
    window.ort.env.wasm.wasmPaths = b;
    window.ort.env.wasm.numThreads = self.crossOriginIsolated ? 4 : 1;
    var loaded = await Promise.all([
      window.ort.InferenceSession.create(b + 'ppocr_v5_mobile_rec.onnx',
          {executionProviders: ['wasm']}),
      fetch(b + 'ppocr_v5_dict.json').then(function (r) {
        if (!r.ok) throw new Error('character list HTTP ' + r.status);
        return r.json();
      }),
    ]);
    engine = {session: loaded[0], dict: loaded[1]};
    return engine;
  }

  async function lineFinder() {
    if (!window.Tesseract) throw new Error('Tesseract is not loaded.');
    if (!lineWorker) {
      lineWorker = window.Tesseract.createWorker('chi_sim+eng', 1).then(async function (w) {
        await w.setParameters({tessedit_pageseg_mode: '6'});
        return w;
      }).catch(function (e) { lineWorker = null; throw e; });
    }
    return lineWorker;
  }

  function release() {
    if (idle) { clearTimeout(idle); idle = null; }
    var w = lineWorker;
    lineWorker = null;
    if (w) w.then(function (x) { return x.terminate(); }).catch(function () {});
    if (engine && engine.session && engine.session.release) {
      engine.session.release().catch(function () {});
    }
    engine = null;
  }

  var isCjk = function (s) { return /[㐀-鿿　-〿＀-￯]/.test(s); };

  // A Tesseract line rebuilt from its characters' positions (the fallback
  // text of a line the model cannot read).
  function lineFromSymbols(symbols) {
    var sy = symbols.filter(function (s) { return s.text && s.text.trim(); });
    if (!sy.length) return '';
    var hs = sy.map(function (s) { return s.bbox.y1 - s.bbox.y0; }).sort(function (a, b) { return a - b; });
    var h = hs[Math.floor(hs.length / 2)] || 30;
    var out = sy[0].text;
    for (var i = 1; i < sy.length; i++) {
      var a = sy[i - 1], b = sy[i];
      var gap = b.bbox.x0 - a.bbox.x1;
      var change = isCjk(a.text) !== isCjk(b.text);
      out += (gap > h * 0.34 || (change && gap > h * 0.12)) ? ' ' + b.text : b.text;
    }
    return out;
  }

  function linesOf(blocks) {
    var lines = [];
    (blocks || []).forEach(function (block) {
      (block.paragraphs || []).forEach(function (par) {
        (par.lines || []).forEach(function (line) {
          var symbols = [];
          (line.words || []).forEach(function (w) {
            (w.symbols || []).forEach(function (s) { symbols.push(s); });
          });
          var t = lineFromSymbols(symbols);
          if (t.trim()) lines.push({text: t, bbox: line.bbox});
        });
      });
    });
    return lines;
  }

  // Splits a line picture at blank columns wider than [minGap] px.
  function chunksOf(gray, w, h, minGap) {
    var ink = new Array(w).fill(0);
    for (var x = 0; x < w; x++) {
      for (var y = 0; y < h; y++) if (gray[y * w + x] < INK) ink[x]++;
    }
    var chunks = [];
    var start = -1, blank = 0;
    for (x = 0; x <= w; x++) {
      var on = x < w && ink[x] > 0;
      if (on) {
        if (start < 0) start = x;
        else if (blank >= minGap) { chunks.push([start, x - blank]); start = x; }
        blank = 0;
      } else if (start >= 0) blank++;
    }
    if (start >= 0) chunks.push([start, w - blank]);
    return chunks;
  }

  async function readPiece(canvas) {
    var e = await loadEngine();
    var H = 48;
    var W = Math.max(16, Math.min(3200, Math.round(canvas.width * H / canvas.height)));
    var r = document.createElement('canvas');
    r.width = W; r.height = H;
    var g = r.getContext('2d', {willReadFrequently: true});
    g.fillStyle = '#fff'; g.fillRect(0, 0, W, H);
    g.drawImage(canvas, 0, 0, W, H);
    var px = g.getImageData(0, 0, W, H).data;
    var data = new Float32Array(3 * H * W);
    for (var i = 0; i < H * W; i++) {
      // (x / 255 - 0.5) / 0.5 per channel; the page is grey.
      var v = px[i * 4] / 127.5 - 1;
      data[i] = v; data[H * W + i] = v; data[2 * H * W + i] = v;
    }
    var input = new window.ort.Tensor('float32', data, [1, 3, H, W]);
    var feeds = {};
    feeds[e.session.inputNames[0]] = input;
    var res = await e.session.run(feeds);
    var out = res[e.session.outputNames[0]];
    var T = out.dims[1], C = out.dims[2], o = out.data;
    // CTC: best class per step, blanks (0) and repeats dropped.
    var text = '', prev = 0;
    for (var t = 0; t < T; t++) {
      var best = 0, bv = -Infinity;
      for (var k = 0; k < C; k++) { var x = o[t * C + k]; if (x > bv) { bv = x; best = k; } }
      if (best !== 0 && best !== prev) text += best - 1 < e.dict.length ? e.dict[best - 1] : ' ';
      prev = best;
    }
    return text;
  }

  // Thin horizontal rules on the whole page (the blanks of a workbook):
  // [x0, x1, y] of each, shorter than a quarter of the page and longer
  // than [minLen]. A line box often stops above its blank, so the line
  // reader also gets the rules just under it.
  function rulesOf(canvas) {
    var W = canvas.width, H = canvas.height;
    var px = canvas.getContext('2d', {willReadFrequently: true}).getImageData(0, 0, W, H).data;
    var gray = new Uint8Array(W * H);
    for (var i = 0; i < W * H; i++) gray[i] = px[i * 4];
    var minLen = Math.round(W * 0.025), maxLen = Math.round(W * 0.28);
    var out = [];
    for (var y = 1; y < H; y++) {
      var s = -1;
      for (var x = 0; x <= W; x++) {
        var dark = x < W && gray[y * W + x] < INK;
        if (dark && s < 0) s = x;
        if (dark || s < 0) continue;
        var a = s, b = x - 1;
        s = -1;
        var len = b - a + 1;
        if (len < minLen || len > maxLen) continue;
        var above = 0, below = 0, k;
        for (k = a; k <= b; k++) if (gray[(y - 1) * W + k] < INK) above++;
        if (above > len * 0.5) continue;
        var thick = 1;
        while (y + thick < H && thick <= 6) {
          var n = 0;
          for (k = a; k <= b; k++) if (gray[(y + thick) * W + k] < INK) n++;
          if (n < len * 0.8) break;
          thick++;
        }
        if (thick > 6) continue;
        if (y + thick < H) for (k = a; k <= b; k++) if (gray[(y + thick) * W + k] < INK) below++;
        if (below > len * 0.5) continue;
        out.push({x0: a, x1: b, y: y, gray: gray, W: W});
      }
    }
    return out;
  }

  async function readLine(page, bbox, pageRules) {
    var pageW = page.width;
    var pad = 6;
    var x0 = Math.max(0, bbox.x0 - pad), y0 = Math.max(0, bbox.y0 - pad);
    var x1 = Math.min(page.width, bbox.x1 + pad), y1 = Math.min(page.height, bbox.y1 + pad);
    var w = x1 - x0, h = y1 - y0;
    if (w < 4 || h < 4) return '';
    var line = document.createElement('canvas');
    line.width = w; line.height = h;
    var lg = line.getContext('2d', {willReadFrequently: true});
    lg.drawImage(page, x0, y0, w, h, 0, 0, w, h);
    var rgba = lg.getImageData(0, 0, w, h).data;
    var gray = new Uint8Array(w * h);
    for (var i = 0; i < w * h; i++) gray[i] = rgba[i * 4];
    var top = h, bottom = -1, x, y;
    for (y = 0; y < h; y++) {
      for (x = 0; x < w; x++) if (gray[y * w + x] < INK) { if (y < top) top = y; bottom = y; break; }
    }
    var inkH = Math.max(1, bottom - top + 1);

    function extent(a, b) {
      var t0 = h, t1 = -1;
      for (var yy = 0; yy < h; yy++) {
        for (var xx = a; xx <= b; xx++) if (gray[yy * w + xx] < INK) { if (yy < t0) t0 = yy; t1 = yy; break; }
      }
      return [t0, t1];
    }
    // How far the middle of a mark lies right of its ends: negative for
    // `（`, positive for `）`, about 0 for a straight `1`.
    function curve(a, b) {
      var e = extent(a, b), t0 = e[0], t1 = e[1];
      function meanX(ya, yb) {
        var sx = 0, n = 0;
        for (var yy = ya; yy <= yb; yy++) for (var xx = a; xx <= b; xx++) if (gray[yy * w + xx] < INK) { sx += xx; n++; }
        return n ? sx / n : (a + b) / 2;
      }
      var span = t1 - t0 + 1, q = Math.max(1, Math.round(span / 5));
      var ends = (meanX(t0, t0 + q) + meanX(t1 - q, t1)) / 2;
      return meanX(Math.round(t0 + span * 0.4), Math.round(t0 + span * 0.6)) - ends;
    }
    var bend = Math.max(1.5, inkH * 0.05);

    // Answer brackets `（ ）`: two narrow, tall, curved marks facing each
    // other with nothing inside. The model drops them or reads `!`, so they
    // are found by their shape, blanked out and put back as text.
    var runs = [], s = -1;
    for (x = 0; x <= w; x++) {
      var on = false;
      if (x < w) for (y = 0; y < h; y++) if (gray[y * w + x] < INK) { on = true; break; }
      if (on && s < 0) s = x;
      if (!on && s >= 0) { runs.push([s, x - 1]); s = -1; }
    }
    function isBar(r) {
      var e = extent(r[0], r[1]);
      return r[1] - r[0] + 1 <= inkH * 0.38 && e[1] - e[0] + 1 >= inkH * 0.6;
    }
    var marks = [];
    for (var j = 0; j + 1 < runs.length; j++) {
      var gapIn = runs[j + 1][0] - runs[j][1];
      if (isBar(runs[j]) && isBar(runs[j + 1]) && gapIn >= inkH * 0.3 && gapIn <= inkH * 4 &&
          curve(runs[j][0], runs[j][1]) <= -bend && curve(runs[j + 1][0], runs[j + 1][1]) >= bend) {
        marks.push([runs[j][0], runs[j + 1][1], '（ ）']);
        for (y = 0; y < h; y++) for (x = runs[j][0]; x <= runs[j + 1][1]; x++) gray[y * w + x] = 255;
        lg.fillStyle = '#fff';
        lg.fillRect(runs[j][0], 0, runs[j + 1][1] - runs[j][0] + 1, h);
        j++;
      }
    }

    // Blanks to fill in (Standard Course workbooks, 2026-11-25): a long
    // thin rule in the lower half of the line. The rule is wiped so it no
    // longer glues the words around it into one piece; an empty one (no
    // ink above it) is put back as `＿＿`.
    var minRule = Math.max(20, Math.round(inkH * 1.3));
    var thin = Math.max(3, Math.round(inkH * 0.25));
    for (y = Math.round(top + inkH * 0.55); y < h; y++) {
      var rs = -1;
      for (x = 0; x <= w; x++) {
        var dark = x < w && gray[y * w + x] < INK;
        if (dark && rs < 0) rs = x;
        if (dark || rs < 0) continue;
        var ra = rs, rb = x - 1;
        rs = -1;
        if (rb - ra + 1 < minRule) continue;
        // Only from the rule's top row (the row above is mostly blank).
        var above = 0;
        for (var xx = ra; xx <= rb; xx++) if (y > 0 && gray[(y - 1) * w + xx] < INK) above++;
        if (above > (rb - ra + 1) * 0.5) continue;
        // How many rows the rule is thick (most of its columns dark).
        var thick = 0;
        for (var yy = y; yy < h && thick <= thin; yy++) {
          var n = 0;
          for (xx = ra; xx <= rb; xx++) if (gray[yy * w + xx] < INK) n++;
          if (n < (rb - ra + 1) * 0.8) break;
          thick++;
        }
        if (thick < 1 || thick > thin) continue;
        var inked = 0;
        for (xx = ra; xx <= rb; xx++) {
          for (yy = top; yy < y - 1; yy++) if (gray[yy * w + xx] < INK) { inked++; break; }
        }
        for (yy = y; yy < y + thick; yy++) for (xx = ra; xx <= rb; xx++) gray[yy * w + xx] = 255;
        lg.fillStyle = '#fff';
        lg.fillRect(ra, y, rb - ra + 1, thick);
        if (inked < (rb - ra + 1) * 0.12) marks.push([ra, rb, '＿＿']);
      }
    }
    // Rules just under the line box (outside the crop): blanks too, when
    // nothing is written above them inside the line.
    var lineH = bbox.y1 - bbox.y0;
    (pageRules || []).forEach(function (r) {
      if (r.y < y1 || r.y > bbox.y1 + lineH * 0.7) return;
      if (r.x0 < x0 || r.x1 > x1) return;
      if (r.x1 - r.x0 + 1 < lineH * 1.3) return;
      var inked = 0;
      for (var xx = r.x0; xx <= r.x1; xx++) {
        for (var yy = bbox.y0; yy < bbox.y1; yy++) if (r.gray[yy * r.W + xx] < INK) { inked++; break; }
      }
      if (inked < (r.x1 - r.x0 + 1) * 0.12) marks.push([r.x0 - x0, r.x1 - x0, '＿＿']);
    });
    marks.sort(function (p, q) { return p[0] - q[0]; });

    var parts = [];
    var open = false;
    var nextPair = 0;
    var prevEnd = -1;
    var chunks = chunksOf(gray, w, h, Math.max(8, Math.round(inkH * 0.42)));
    for (var c = 0; c < chunks.length; c++) {
      var a = chunks[c][0], b = chunks[c][1];
      while (nextPair < marks.length && marks[nextPair][1] < a) {
        parts.push(marks[nextPair][2]); prevEnd = marks[nextPair][1]; nextPair++;
      }
      // The side tab of a textbook page (the lesson title printed down the
      // right edge) glued to a line: a short piece at the far right.
      if (x0 + a > pageW * 0.915 && b - a < inkH * 2.5) continue;
      // A wide gap between two columns (text | new words) becomes a tab,
      // so the parser can tell the columns apart.
      if (prevEnd >= 0 && a - prevEnd > inkH * 2.2 && parts.length) parts.push('\t');
      prevEnd = b;
      var ex = extent(a, b), cw0 = b - a + 1, ch0 = ex[1] - ex[0] + 1;
      // A single bracket between wide gaps.
      if (cw0 <= inkH * 0.3 && ch0 >= inkH * 0.55 && Math.abs(curve(a, b)) >= bend) {
        parts.push(open ? '）' : '（');
        open = !open;
        continue;
      }
      // A comma or full stop standing alone (after a bracket): a small
      // mark low in the line. A ring is `。`, anything else `，`.
      if (cw0 <= inkH * 0.45 && ch0 <= inkH * 0.45 && ex[0] >= top + inkH * 0.45) {
        var cx = Math.round((a + b) / 2), cy = Math.round((ex[0] + ex[1]) / 2);
        var ring = gray[cy * w + cx] >= INK && cw0 / ch0 > 0.6 && cw0 / ch0 < 1.6;
        var mark = ring ? '。' : '，';
        if (parts.length) parts[parts.length - 1] += mark; else parts.push(mark);
        continue;
      }
      var cw = b - a + 12;
      var cut = document.createElement('canvas');
      cut.width = cw; cut.height = h;
      var cg = cut.getContext('2d');
      cg.fillStyle = '#fff'; cg.fillRect(0, 0, cw, h);
      cg.drawImage(line, Math.max(0, a - 6), 0, cw, h, 0, 0, cw, h);
      var t = (await readPiece(cut)).trim();
      if (/^[a-f]$/.test(t)) t = t.toUpperCase(); // a choice letter
      if (t) parts.push(t);
    }
    while (nextPair < marks.length) { parts.push(marks[nextPair][2]); nextPair++; }
    // A bracket left open had its closing half glued to the next word.
    return parts.join(' ').replace(/（ (?!）)/g, '（ ） ').replace(/ ?\t ?/g, '\t');
  }

  // Reads one cleaned page (canvas): Tesseract finds the lines, the model
  // reads them; a line the model leaves empty keeps Tesseract's text.
  async function readCanvas(canvas, onProgress) {
    if (idle) { clearTimeout(idle); idle = null; }
    try {
      await loadEngine();
      var worker = await lineFinder();
      var r = await worker.recognize(canvas, {}, {blocks: true});
      var lines = linesOf(r.data.blocks);
      var pageRules = rulesOf(canvas);
      var out = [];
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].bbox.x0 > canvas.width * 0.915) continue;
        var t = await readLine(canvas, lines[i].bbox, pageRules);
        out.push(t.trim() ? t : lines[i].text);
        if (typeof onProgress === 'function') {
          try { onProgress('recognizing text', (i + 1) / lines.length); } catch (e) {}
        }
      }
      return out.join('\n');
    } finally {
      idle = setTimeout(release, IDLE_MS);
    }
  }

  window.chineseTrackerPaperOcrPaddleCanvas = readCanvas;

  window.chineseTrackerPaperOcrPaddle = async function (imageBytes, onProgress) {
    var blob = new Blob([imageBytes], {type: 'image/png'});
    var bitmap = await createImageBitmap(blob);
    var canvas = document.createElement('canvas');
    canvas.width = bitmap.width; canvas.height = bitmap.height;
    var g = canvas.getContext('2d', {willReadFrequently: true});
    g.fillStyle = '#fff'; g.fillRect(0, 0, canvas.width, canvas.height);
    g.drawImage(bitmap, 0, 0);
    if (bitmap.close) bitmap.close();
    return readCanvas(canvas, onProgress);
  };

  window.chineseTrackerPaperOcrPaddleRelease = release;
})();
