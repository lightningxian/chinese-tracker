import 'dart:js_interop';
import 'dart:typed_data';

@JS('chineseTrackerTranscribe')
external JSPromise<JSString> _transcribe(JSAny input, JSFunction onProgress);

@JS('chineseTrackerTranscribe')
external JSAny? get _transcribeFunction;

bool get transcriberAvailable => _transcribeFunction != null;

Future<String> transcribe({
  String? url,
  Uint8List? bytes,
  void Function(String stage, double fraction)? onProgress,
}) async {
  final JSAny input = bytes != null ? bytes.toJS : (url ?? '').toJS;
  final listener = (JSString stage, JSNumber fraction) {
    onProgress?.call(stage.toDart, fraction.toDartDouble.clamp(0.0, 1.0));
  }.toJS;
  final text = await _transcribe(input, listener).toDart;
  return text.toDart;
}
