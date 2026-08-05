// Local OCR for worksheet import (Tesseract.js — runs in the browser, no API key).
(function () {
  let workerPromise = null;

  async function getWorker(lang) {
    if (!window.Tesseract) {
      throw new Error('OCR engine failed to load. Refresh the page and try again.');
    }
    if (!workerPromise) {
      workerPromise = Tesseract.createWorker(lang, 1, {
        logger: function () {},
      });
    }
    return workerPromise;
  }

  window.chineseTrackerOcr = async function (imageBytes, lang) {
    const worker = await getWorker(lang || 'chi_sim+eng');
    try {
      const result = await worker.recognize(imageBytes);
      return result && result.data ? result.data.text || '' : '';
    } finally {
      if (workerPromise) {
        await workerPromise.then((w) => w.terminate());
        workerPromise = null;
      }
    }
  };
})();
