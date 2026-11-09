import 'dart:typed_data';

import '../core/constants/exercise_authoring_platform.dart';
import '../core/constants/worksheet_import_platform.dart';
import '../models/worksheet_import_stage.dart';
import 'worksheet_text/docx_text_reader.dart';
import 'worksheet_text/ocr_reader_stub.dart'
    if (dart.library.js_interop) 'worksheet_text/ocr_reader_web.dart';
import 'worksheet_text/pdf_text_reader.dart';

/// Progress of one reader: how far it is (0–1) and what it is doing now.
typedef ReadProgress = void Function(double fraction, String detail);

/// User-facing worksheet import failure.
class WorksheetImportException implements Exception {
  WorksheetImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Reads worksheets locally (PDF, Word, images) — no cloud AI or API keys.
class WorksheetImportService {
  static const maxBytes = 15 * 1024 * 1024;
  static const allowedExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
    'heic',
    'pdf',
    'doc',
    'docx',
  };

  static const supportedFormatsLabel =
      'PDF, images (JPG/PNG), and Word (DOC/DOCX)';

  Future<String> extractTextFromWorksheet({
    required Uint8List bytes,
    required String fileName,
    void Function(WorksheetImportStage stage)? onProgress,
  }) async {
    ExerciseAuthoringPlatform.ensureWeb();

    final extension = _extension(fileName);
    if (!allowedExtensions.contains(extension)) {
      throw WorksheetImportException(
        'Unsupported file type. Use $supportedFormatsLabel.',
      );
    }
    if (bytes.length > maxBytes) {
      throw WorksheetImportException('File is too large. Maximum size is 15 MB.');
    }
    if (bytes.isEmpty) {
      throw WorksheetImportException('The selected file is empty.');
    }

    onProgress?.call(WorksheetImportStage.prepare());

    return switch (extension) {
      'pdf' => _extractPdf(bytes, onProgress),
      'docx' => _extractDocx(bytes, onProgress),
      'doc' => throw WorksheetImportException(
          'Old .doc files are not supported. Save as .docx or PDF and try again.',
        ),
      _ => _extractImage(bytes, extension, onProgress),
    };
  }

  Future<String> _extractPdf(
    Uint8List bytes,
    void Function(WorksheetImportStage stage)? onProgress,
  ) async {
    onProgress?.call(WorksheetImportStage.reading(0.02, detail: 'Opening the PDF…'));
    final text = await PdfTextReader.extract(
      bytes,
      onProgress: (fraction, detail) {
        onProgress?.call(WorksheetImportStage.reading(fraction, detail: detail));
      },
    );
    return _ensureText(text);
  }

  Future<String> _extractDocx(
    Uint8List bytes,
    void Function(WorksheetImportStage stage)? onProgress,
  ) async {
    onProgress?.call(
      WorksheetImportStage.reading(0.4, detail: 'Reading the Word document…'),
    );
    final text = DocxTextReader.extract(bytes);
    onProgress?.call(WorksheetImportStage.reading(0.9, detail: 'Read the Word document'));
    return _ensureText(text);
  }

  Future<String> _extractImage(
    Uint8List bytes,
    String extension,
    void Function(WorksheetImportStage stage)? onProgress,
  ) async {
    onProgress?.call(WorksheetImportStage.reading(0.05, detail: 'Photo · starting OCR…'));
    final text = await ocrImageBytes(
      bytes,
      onProgress: (fraction, detail) {
        onProgress?.call(
          WorksheetImportStage.reading(0.05 + fraction * 0.9, detail: 'Photo · $detail'),
        );
      },
    );
    return _ensureText(text);
  }

  String _ensureText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw WorksheetImportException(
        'No text found in this file. Try a clearer scan or a PDF/Word export.',
      );
    }
    return trimmed;
  }

  String _extension(String fileName) {
    final parts = fileName.toLowerCase().split('.');
    if (parts.length < 2) return '';
    final ext = parts.last;
    if (ext == 'jpeg') return 'jpg';
    return ext;
  }
}

/// Strip exception prefixes for UI display.
String formatUserFacingError(Object error) {
  if (error is ExerciseAuthoringPlatformException) return error.message;
  if (error is WorksheetImportPlatformException) return error.message;
  if (error is WorksheetImportException) return error.message;
  if (error is StateError) return error.message;
  final text = error.toString();
  const prefixes = ['Bad state: ', 'Exception: '];
  for (final prefix in prefixes) {
    if (text.startsWith(prefix)) return text.substring(prefix.length);
  }
  return text;
}
