import 'dart:typed_data';

import '../worksheet_import_service.dart';

Future<String> ocrImageBytes(
  Uint8List imageBytes, {
  void Function(double progress)? onProgress,
}) async {
  throw WorksheetImportException(
    'Image OCR is only available in the web app. '
    'Use a PDF or Word file, or paste worksheet text in the review dialog.',
  );
}
