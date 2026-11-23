import 'dart:typed_data';

bool get transcriberAvailable => false;

Future<String> transcribe({
  String? url,
  Uint8List? bytes,
  void Function(String stage, double fraction)? onProgress,
}) {
  throw UnsupportedError('The listening-script writer runs in the browser only.');
}
