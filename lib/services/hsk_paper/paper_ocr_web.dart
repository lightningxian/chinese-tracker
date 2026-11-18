import 'dart:js_interop';
import 'dart:typed_data';

@JS('chineseTrackerPaperOcr')
external JSPromise<JSString> _paperOcr(
  JSUint8Array imageBytes,
  JSNumber pageMode,
  JSFunction onProgress,
);

@JS('chineseTrackerPaperOcrPaddle')
external JSPromise<JSString> _paperOcrPaddle(
  JSUint8Array imageBytes,
  JSFunction onProgress,
);

@JS('chineseTrackerPaperOcrPaddle')
external JSAny? get _paddleFunction;

JSFunction _listener(void Function(double progress)? onProgress) =>
    (JSString status, JSNumber progress) {
      if (status.toDart != 'recognizing text') return;
      onProgress?.call(progress.toDartDouble.clamp(0.0, 1.0));
    }.toJS;

/// Tesseract alone (`web/worksheet_ocr.js`): the engine of Build 1B, now
/// the fallback.
Future<String> readPaperPage(
  Uint8List png, {
  required int pageMode,
  void Function(double progress)? onProgress,
}) async {
  final text =
      await _paperOcr(png.toJS, pageMode.toJS, _listener(onProgress)).toDart;
  return text.toDart;
}

/// Whether `web/paper_ocr_paddle.js` is on the page.
bool get paddleAvailable => _paddleFunction != null;

/// PP-OCRv5 through onnxruntime-web (`web/paper_ocr_paddle.js`, Build 1C).
Future<String> readPaperPagePaddle(
  Uint8List png, {
  void Function(double progress)? onProgress,
}) async {
  final text = await _paperOcrPaddle(png.toJS, _listener(onProgress)).toDart;
  return text.toDart;
}
