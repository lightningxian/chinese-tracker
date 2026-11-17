import 'dart:js_interop';
import 'dart:typed_data';

@JS('chineseTrackerPaperOcr')
external JSPromise<JSString> _paperOcr(
  JSUint8Array imageBytes,
  JSNumber pageMode,
  JSFunction onProgress,
);

Future<String> readPaperPage(
  Uint8List png, {
  required int pageMode,
  void Function(double progress)? onProgress,
}) async {
  final listener = (JSString status, JSNumber progress) {
    if (status.toDart != 'recognizing text') return;
    onProgress?.call(progress.toDartDouble.clamp(0.0, 1.0));
  }.toJS;
  final text = await _paperOcr(png.toJS, pageMode.toJS, listener).toDart;
  return text.toDart;
}
