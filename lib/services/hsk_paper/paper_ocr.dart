import 'package:flutter/foundation.dart';

import 'paper_ocr_stub.dart' if (dart.library.js_interop) 'paper_ocr_web.dart'
    as impl;

/// The text engine of the built-in paper reader; tests pass a fake.
abstract class PaperOcrEngine {
  /// Reads one cleaned page image (PNG). [pageMode] is Tesseract's page
  /// segmentation mode; the reader always asks for 6 (one block of text),
  /// which keeps each numbered line together on a cleaned page.
  Future<String> read(
    Uint8List png, {
    required int pageMode,
    void Function(double progress)? onProgress,
  });
}

/// The browser engine. Since Build 1C (docs/PLAN.md §4): PP-OCRv5 through
/// onnxruntime-web (`web/paper_ocr_paddle.js`, model files in `web/ocr/`),
/// with Tesseract finding the lines. When the model cannot load (files
/// missing, an old browser), it falls back to tesseract.js alone
/// (`web/worksheet_ocr.js`, `chi_sim+eng`), the engine of Build 1B, for the
/// rest of the visit. Off the web it throws.
class BrowserPaperOcrEngine implements PaperOcrEngine {
  BrowserPaperOcrEngine();

  static const paddle = 'paddle';
  static const tesseract = 'tesseract';

  static bool _paddleFailed = false;

  /// The engine that read the last page ([paddle] or [tesseract]).
  String used = '';

  @override
  Future<String> read(
    Uint8List png, {
    required int pageMode,
    void Function(double progress)? onProgress,
  }) async {
    if (impl.paddleAvailable && !_paddleFailed) {
      try {
        final text = await impl.readPaperPagePaddle(png, onProgress: onProgress);
        used = paddle;
        return text;
      } catch (e) {
        debugPrint('paper reader: PaddleOCR unavailable, using Tesseract ($e)');
        _paddleFailed = true;
      }
    }
    used = tesseract;
    return impl.readPaperPage(png, pageMode: pageMode, onProgress: onProgress);
  }
}
