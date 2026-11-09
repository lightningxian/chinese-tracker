import 'dart:js_interop';
import 'dart:typed_data';

import '../worksheet_import_service.dart';

@JS('chineseTrackerOcr')
external JSPromise<JSString> _chineseTrackerOcr(
  JSUint8Array imageBytes,
  JSString lang,
  JSFunction onProgress,
);

/// Tesseract.js reports these statuses, in this order, while it warms up and
/// then recognises. Each gets a slice of the 0–1 progress range.
const _ocrPhases = <String, (double start, double end, String label)>{
  'loading tesseract core': (0.0, 0.12, 'Loading the OCR engine…'),
  'initializing tesseract': (0.12, 0.16, 'Starting the OCR engine…'),
  'loading language traineddata': (
    0.16,
    0.40,
    'Downloading Chinese OCR data (about 15 MB, first time only)…',
  ),
  'initializing api': (0.40, 0.45, 'Preparing OCR…'),
  'recognizing text': (0.45, 1.0, 'Recognising text'),
};

Future<String> ocrImageBytes(
  Uint8List imageBytes, {
  ReadProgress? onProgress,
}) async {
  if (imageBytes.isEmpty) {
    throw WorksheetImportException('Could not prepare image for OCR.');
  }

  onProgress?.call(0.0, 'Starting OCR…');
  final listener = (JSString status, JSNumber progress) {
    final phase = _ocrPhases[status.toDart];
    if (phase == null) return;
    final (start, end, label) = phase;
    final p = progress.toDartDouble.clamp(0.0, 1.0);
    final detail = status.toDart == 'recognizing text'
        ? '$label ${(p * 100).round()}%'
        : label;
    onProgress?.call(start + (end - start) * p, detail);
  }.toJS;

  try {
    final text = await _chineseTrackerOcr(
      imageBytes.toJS,
      'chi_sim+eng'.toJS,
      listener,
    ).toDart;
    onProgress?.call(1.0, 'Recognising text 100%');
    return text.toDart.trim();
  } catch (e) {
    throw WorksheetImportException(
      'Could not read text from this image. Try a clearer scan or a PDF/Word file.',
    );
  }
}
