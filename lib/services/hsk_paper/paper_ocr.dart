import 'dart:typed_data';

import 'paper_ocr_stub.dart' if (dart.library.js_interop) 'paper_ocr_web.dart'
    as impl;

/// The text engine of the built-in paper reader. The browser engine is
/// tesseract.js (`web/worksheet_ocr.js`, `chi_sim+eng`); tests pass a fake.
abstract class PaperOcrEngine {
  /// Reads one page image (PNG). [pageMode] is Tesseract's page
  /// segmentation mode; the reader always asks for 6 (one block of text),
  /// which keeps each numbered line together on a cleaned page.
  Future<String> read(
    Uint8List png, {
    required int pageMode,
    void Function(double progress)? onProgress,
  });
}

/// tesseract.js in the browser; off the web it throws (the reader is web
/// only, like the rest of the worksheet import).
class BrowserPaperOcrEngine implements PaperOcrEngine {
  const BrowserPaperOcrEngine();

  @override
  Future<String> read(
    Uint8List png, {
    required int pageMode,
    void Function(double progress)? onProgress,
  }) =>
      impl.readPaperPage(png, pageMode: pageMode, onProgress: onProgress);
}
