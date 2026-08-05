import 'dart:js_interop';
import 'dart:typed_data';

import '../worksheet_import_service.dart';

@JS('chineseTrackerOcr')
external JSPromise<JSString> _chineseTrackerOcr(
  JSUint8Array imageBytes,
  JSString lang,
);

Future<String> ocrImageBytes(
  Uint8List imageBytes, {
  void Function(double progress)? onProgress,
}) async {
  if (imageBytes.isEmpty) {
    throw WorksheetImportException('Could not prepare image for OCR.');
  }

  onProgress?.call(0.1);
  try {
    final text = await _chineseTrackerOcr(
      imageBytes.toJS,
      'chi_sim+eng'.toJS,
    ).toDart;
    onProgress?.call(1.0);
    return text.toDart.trim();
  } catch (e) {
    throw WorksheetImportException(
      'Could not read text from this image. Try a clearer scan or a PDF/Word file.',
    );
  }
}
