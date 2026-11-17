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

  // ---- Built-in HSK paper reader (Build 1B) --------------------------------
  // Its own worker, so the page mode below never changes the scanner above.
  // `pageMode` is Tesseract's page segmentation mode: 6 = one uniform block,
  // which keeps each numbered question line together on a cleaned page.
  var paperWorker = null;
  var paperMode = null;
  var paperIdle = null;
  var paperListener = null;

  function releasePaperWorker() {
    if (paperIdle) {
      clearTimeout(paperIdle);
      paperIdle = null;
    }
    if (!paperWorker) return;
    var pending = paperWorker;
    paperWorker = null;
    paperMode = null;
    pending.then(function (w) { return w.terminate(); }).catch(function () {});
  }

  window.chineseTrackerPaperOcr = async function (imageBytes, pageMode, onProgress) {
    if (!window.Tesseract) {
      throw new Error('OCR engine failed to load. Refresh the page and try again.');
    }
    if (paperIdle) {
      clearTimeout(paperIdle);
      paperIdle = null;
    }
    paperListener = typeof onProgress === 'function' ? onProgress : null;
    try {
      if (!paperWorker) {
        paperWorker = Tesseract.createWorker('chi_sim+eng', 1, {
          logger: function (m) {
            if (!paperListener || !m || typeof m.status !== 'string') return;
            try {
              paperListener(m.status, typeof m.progress === 'number' ? m.progress : 0);
            } catch (e) {}
          },
        }).catch(function (err) {
          paperWorker = null;
          throw err;
        });
      }
      var worker = await paperWorker;
      var mode = String(pageMode || 6);
      if (paperMode !== mode) {
        await worker.setParameters({ tessedit_pageseg_mode: mode });
        paperMode = mode;
      }
      var result = await worker.recognize(imageBytes);
      return result && result.data ? result.data.text || '' : '';
    } catch (err) {
      releasePaperWorker();
      throw err;
    } finally {
      paperListener = null;
      if (paperWorker) paperIdle = setTimeout(releasePaperWorker, IDLE_MS);
    }
  };

  window.chineseTrackerPaperOcrRelease = releasePaperWorker;
})();
