import 'dart:typed_data';

Future<String> readPaperPage(
  Uint8List png, {
  required int pageMode,
  void Function(double progress)? onProgress,
}) {
  throw UnsupportedError('The built-in paper reader runs in the browser only.');
}

bool get paddleAvailable => false;

Future<String> readPaperPagePaddle(
  Uint8List png, {
  void Function(double progress)? onProgress,
}) {
  throw UnsupportedError('The built-in paper reader runs in the browser only.');
}
