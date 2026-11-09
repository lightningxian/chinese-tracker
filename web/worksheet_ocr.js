// Local OCR for worksheet import (Tesseract.js — runs in the browser, no API key).
//
// The worker (engine + Chinese language data, ~15 MB) stays alive between scans
// so a multi-page PDF, or several worksheets in a row, load the data once. It is
// released after five idle minutes to give the memory back.
(function () {
  var IDLE_MS = 5 * 60 * 1000;
  var workerPromise = null;
  var workerLang = null;
  var idleTimer = null;
  var listener = null; // progress callback of the scan currently running

  function report(message) {
    if (!listener || !message || typeof message.status !== 'string') return;
    var progress = typeof message.progress === 'number' ? message.progress : 0;
    try {
      listener(message.status, progress);
    } catch (e) {
      // A UI error must not break the OCR job.
    }
  }

  function getWorker(lang) {
    if (!window.Tesseract) {
      return Promise.reject(
        new Error('OCR engine failed to load. Refresh the page and try again.')
      );
    }
    if (workerPromise && workerLang === lang) return workerPromise;
    releaseWorker();
    workerLang = lang;
    workerPromise = Tesseract.createWorker(lang, 1, { logger: report }).catch(
      function (err) {
        workerPromise = null;
        workerLang = null;
        throw err;
      }
    );
    return workerPromise;
  }

  function releaseWorker() {
    if (idleTimer) {
      clearTimeout(idleTimer);
      idleTimer = null;
    }
    if (!workerPromise) return;
    var pending = workerPromise;
    workerPromise = null;
    workerLang = null;
    pending.then(function (w) { return w.terminate(); }).catch(function () {});
  }

  function scheduleRelease() {
    if (idleTimer) clearTimeout(idleTimer);
    idleTimer = setTimeout(releaseWorker, IDLE_MS);
  }

  // onProgress(status, progress): status is Tesseract's own label
  // ('loading language traineddata', 'recognizing text', ...), progress 0–1.
  window.chineseTrackerOcr = async function (imageBytes, lang, onProgress) {
    if (idleTimer) {
      clearTimeout(idleTimer);
      idleTimer = null;
    }
    listener = typeof onProgress === 'function' ? onProgress : null;
    try {
      var worker = await getWorker(lang || 'chi_sim+eng');
      var result = await worker.recognize(imageBytes);
      return result && result.data ? result.data.text || '' : '';
    } catch (err) {
      // A broken worker would fail every later scan too: start fresh next time.
      releaseWorker();
      throw err;
    } finally {
      listener = null;
      if (workerPromise) scheduleRelease();
    }
  };

  window.chineseTrackerOcrRelease = releaseWorker;
})();
