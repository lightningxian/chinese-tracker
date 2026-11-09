import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:pdfrx/pdfrx.dart';

import '../worksheet_import_service.dart';
import 'ocr_reader_stub.dart'
    if (dart.library.js_interop) 'ocr_reader_web.dart';

abstract final class PdfTextReader {
  static const _maxOcrPages = 8;

  static Future<String> extract(
    Uint8List bytes, {
    ReadProgress? onProgress,
  }) async {
    onProgress?.call(0.02, 'Opening the PDF…');
    final doc = await PdfDocument.openData(bytes);
    try {
      final textBuffer = StringBuffer();
      final pageCount = doc.pages.length;
      onProgress?.call(0.1, 'Reading page 1 of $pageCount');

      for (var i = 0; i < pageCount; i++) {
        final page = doc.pages[i];
        final pageText = await page.loadText();
        final text = pageText?.fullText.trim() ?? '';
        if (text.isNotEmpty) {
          textBuffer.writeln(text);
        }
        onProgress?.call(
          0.1 + ((i + 1) / pageCount) * 0.35,
          i + 1 < pageCount
              ? 'Reading page ${i + 2} of $pageCount'
              : 'Read $pageCount ${pageCount == 1 ? 'page' : 'pages'}',
        );
      }

      final embedded = textBuffer.toString().trim();
      if (embedded.isNotEmpty) return embedded;

      if (pageCount > _maxOcrPages) {
        throw WorksheetImportException(
          'This scanned PDF has $pageCount pages. '
          'OCR supports up to $_maxOcrPages pages — split the file or use a text-based PDF.',
        );
      }

      // No text layer: this is a scan. OCR takes 20–40 s per page, so tell
      // the user which page we are on and how far Tesseract has got.
      final ocrBuffer = StringBuffer();
      for (var i = 0; i < pageCount; i++) {
        final page = doc.pages[i];
        final pageLabel = 'Scanned page ${i + 1} of $pageCount';
        onProgress?.call(0.45 + (i / pageCount) * 0.5, '$pageLabel · rendering');
        const scale = 2.5;
        final width = (page.width * scale).round().clamp(1, 4096);
        final height = (page.height * scale).round().clamp(1, 4096);

        final rendered = await page.render(
          width: width,
          height: height,
          fullWidth: page.width * scale,
          fullHeight: page.height * scale,
        );
        if (rendered == null) continue;

        try {
          final png = _encodePng(rendered);
          final pageText = await ocrImageBytes(
            png,
            onProgress: (fraction, detail) {
              final overall = 0.45 + ((i + fraction) / pageCount) * 0.5;
              onProgress?.call(overall, '$pageLabel · $detail');
            },
          );
          if (pageText.isNotEmpty) {
            ocrBuffer.writeln(pageText);
          }
        } finally {
          rendered.dispose();
        }
      }

      final ocrText = ocrBuffer.toString().trim();
      if (ocrText.isEmpty) {
        throw WorksheetImportException(
          'Could not read this PDF. Try a clearer scan or a Word file.',
        );
      }
      return ocrText;
    } finally {
      await doc.dispose();
    }
  }

  static Uint8List _encodePng(PdfImage image) {
    final rgba = image.pixels;
    final bitmap = img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: rgba.buffer,
      numChannels: 4,
      order: img.ChannelOrder.rgba,
    );
    return Uint8List.fromList(img.encodePng(bitmap));
  }
}
