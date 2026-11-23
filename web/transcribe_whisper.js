// The listening-script writer (owner 2026-11-24, Q7): Whisper small through
// transformers.js and onnxruntime-web, in the admin's browser. The files
// (about 270 MB) are served from our own hosting under asr/
// (scripts/fetch_whisper.mjs); the browser downloads them once and keeps
// them in its cache. Nothing leaves the computer.
//
// The recording is cut at quiet moments into pieces of at most 29 seconds
// (Whisper reads 30 seconds at a time), each piece is written down in
// Mandarin, and traditional characters are turned into simplified ones
// (opencc-js). One line per piece.
//
// window.chineseTrackerTranscribe(audioBytes | url, onProgress) -> text
//   onProgress(stage, fraction): stage 'loading' (model download) or
//   'writing' (pieces written).
// window.chineseTrackerTranscribeRelease()
// window.chineseTrackerAsrBase: where asr/ lives (default: next to the page).
(function () {
  'use strict';

  var RATE = 16000;
  var MAX_PIECE = 29; // seconds
  var MIN_PIECE = 18; // seconds; look for a quiet moment after this
  var asr = null;
  var t2s = null;

  function base() {
    return window.chineseTrackerAsrBase || new URL('asr/', document.baseURI).href;
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

  async function simplifier() {
    if (t2s) return t2s;
    if (!window.OpenCC) await loadScript(base() + 'opencc-t2cn.js');
    t2s = window.OpenCC.Converter({from: 't', to: 'cn'});
    return t2s;
  }

  async function loadAsr(onProgress) {
    if (asr) return asr;
    var T = await import(base() + 'transformers.min.js');
    T.env.allowRemoteModels = false;
    T.env.allowLocalModels = true;
    // A path on this site, not a full http address: transformers.js only
    // checks which local files exist (tokenizer, preprocessor) for paths.
    T.env.localModelPath = new URL('models/', base()).pathname;
    T.env.useBrowserCache = true;
    T.env.backends.onnx.wasm.wasmPaths = base();
    // Our hosting is not cross-origin isolated: one thread.
    T.env.backends.onnx.wasm.numThreads = 1;
    var files = {};
    asr = await T.pipeline('automatic-speech-recognition', 'onnx-community/whisper-small', {
      device: 'wasm',
      dtype: {encoder_model: 'q8', decoder_model_merged: 'q8'},
      progress_callback: function (p) {
        if (p.status !== 'progress' || !p.file || !p.total) return;
        files[p.file] = [p.loaded || 0, p.total];
        var loaded = 0, total = 0;
        Object.keys(files).forEach(function (k) {
          loaded += files[k][0];
          total += files[k][1];
        });
        // The two model files are about 250 MB of the total.
        onProgress('loading', Math.min(1, loaded / Math.max(total, 250e6)));
      },
    });
    return asr;
  }

  async function decode(input) {
    var buf;
    if (typeof input === 'string') {
      var res = await fetch(input);
      if (!res.ok) throw new Error('Could not download the recording (HTTP ' + res.status + ')');
      buf = await res.arrayBuffer();
    } else {
      // A Uint8Array from Dart: copy into its own ArrayBuffer.
      buf = input.slice().buffer;
    }
    var Ctx = window.OfflineAudioContext || window.webkitOfflineAudioContext;
    var ctx = new Ctx(1, RATE, RATE);
    var audio = await ctx.decodeAudioData(buf);
    // Mono at 16 kHz: render the decoded sound through an offline context.
    var len = Math.ceil(audio.duration * RATE);
    var off = new Ctx(1, len, RATE);
    var src = off.createBufferSource();
    src.buffer = audio;
    src.connect(off.destination);
    src.start();
    var rendered = await off.startRendering();
    return rendered.getChannelData(0);
  }

  /** Cut points (in samples) at the quietest 0.2 s between MIN and MAX. */
  function pieces(samples) {
    var win = Math.round(0.2 * RATE);
    var out = [];
    var start = 0;
    while (start < samples.length) {
      if (samples.length - start <= MAX_PIECE * RATE) {
        out.push([start, samples.length]);
        break;
      }
      var best = start + MAX_PIECE * RATE, bestEnergy = Infinity;
      for (var at = start + MIN_PIECE * RATE; at + win <= start + MAX_PIECE * RATE; at += win / 2) {
        var e = 0;
        for (var i = at; i < at + win; i++) e += samples[i] * samples[i];
        if (e < bestEnergy) {
          bestEnergy = e;
          best = at + Math.round(win / 2);
        }
      }
      out.push([start, best]);
      start = best;
    }
    return out;
  }

  function quiet(samples) {
    var e = 0;
    for (var i = 0; i < samples.length; i++) e += samples[i] * samples[i];
    return Math.sqrt(e / Math.max(1, samples.length)) < 0.004;
  }

  window.chineseTrackerTranscribe = async function (input, onProgress) {
    var report = typeof onProgress === 'function' ? onProgress : function () {};
    report('loading', 0);
    var model = await loadAsr(report);
    var conv = await simplifier();
    var samples = await decode(input);
    var cuts = pieces(samples);
    var lines = [];
    report('writing', 0);
    for (var k = 0; k < cuts.length; k++) {
      var piece = samples.subarray(cuts[k][0], cuts[k][1]);
      if (!quiet(piece)) {
        var r = await model(piece, {language: 'chinese', task: 'transcribe'});
        var text = conv(String((r && r.text) || '').trim());
        if (text) lines.push(text);
      }
      report('writing', (k + 1) / cuts.length);
    }
    return tidy(lines);
  };

  /** Chinese punctuation; one line per question when the recording names
   * them (第一题 …), else one line per piece. */
  function tidy(lines) {
    var zh = function (s) {
      return s.replace(/,/g, '，').replace(/\?/g, '？').replace(/!/g, '！')
          .replace(/;/g, '；').replace(/:(?!\d)/g, '：');
    };
    var all = zh(lines.join(''));
    var q = /第[一二三四五六七八九十百零〇\d]+题/;
    if (q.test(all)) {
      return all.replace(/\s*(第[一二三四五六七八九十百零〇\d]+题)/g, '\n$1').trim();
    }
    return lines.map(zh).join('\n');
  }

  window.chineseTrackerTranscribeRelease = function () {
    if (asr && typeof asr.dispose === 'function') asr.dispose();
    asr = null;
  };
})();
