import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pdfrx/pdfrx.dart';

import '../core/constants/worksheet_import_platform.dart';
import '../models/app_user.dart';
import 'hsk_paper/hsk_paper_reader.dart';

/// A picked answer-sheet PDF.
class PickedAnswerSheet {
  const PickedAnswerSheet(this.name, this.bytes);
  final String name;
  final Uint8List bytes;
}

/// The worksheet's **Answer sheet** (owner 2026-11-26): the admin picks the
/// answer PDF, its text is read on this computer (the PDF's own text, or
/// the built-in paper reader when a page is only a picture; no outside
/// service), and the file is kept in Storage at `answer_sheets/{uid}/…`
/// (admin only, it is the key). Admin on web, like Scan paper
/// (`.claude/rules/worksheet-import-web-only.md`).
class AnswerSheetService {
  AnswerSheetService({FirebaseStorage? storage, HskPaperReader? reader})
      : _storage = storage,
        _reader = reader;

  final FirebaseStorage? _storage;
  final HskPaperReader? _reader;

  FirebaseStorage get _store => _storage ?? FirebaseStorage.instance;

  /// Same limit as `storage.rules`.
  static const maxBytes = 25 * 1024 * 1024;

  /// Pages read from the PDF's text; the picture reader takes fewer.
  static const maxPages = 60;

  Future<PickedAnswerSheet?> pick(AppUser? user) async {
    WorksheetImportPlatform.ensureSupportedFor(user);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    final file = result?.files.singleOrNull;
    if (file == null) return null;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw StateError('Could not read the selected file.');
    }
    if (bytes.length > maxBytes) {
      throw StateError('The PDF must be smaller than ${maxBytes ~/ (1024 * 1024)} MB.');
    }
    return PickedAnswerSheet(file.name, bytes);
  }

  /// The text of every page, pages joined with a blank line. [usedReader]
  /// is true when the pages had no text and the built-in reader read the
  /// pictures instead.
  Future<({String text, bool usedReader})> readText(
    AppUser? user,
    Uint8List bytes, {
    void Function(int page, int pages)? onPage,
  }) async {
    WorksheetImportPlatform.ensureSupportedFor(user);
    final doc = await PdfDocument.openData(bytes);
    final pages = <String>[];
    try {
      final count = doc.pages.length;
      if (count > maxPages) {
        throw StateError('This PDF has $count pages; an answer sheet may have up to $maxPages.');
      }
      for (var i = 0; i < count; i++) {
        onPage?.call(i + 1, count);
        final text = await doc.pages[i].loadStructuredText();
        pages.add(text.fullText);
      }
    } finally {
      await doc.dispose();
    }
    final joined = pages.join('\n\n');
    // Owner 2026-11-26: the keys are made on a computer, so the text is
    // there. A scan has none: read the pictures on the device instead.
    final letters = joined.replaceAll(RegExp(r'\s'), '').length;
    if (letters >= 10 * pages.length.clamp(1, maxPages) || pages.length > HskPaperReader.maxPages) {
      return (text: joined, usedReader: false);
    }
    final read = await (_reader ?? HskPaperReader()).readPdf(
      bytes,
      onProgress: (_, page, pages) => onPage?.call(page, pages),
    );
    return (text: read.map((p) => p.text).join('\n\n'), usedReader: true);
  }

  /// Stores the PDF and returns its Storage path.
  Future<String> upload(AppUser? user, String name, Uint8List bytes) async {
    WorksheetImportPlatform.ensureSupportedFor(user);
    final safe = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path =
        'answer_sheets/${user!.uid}/${DateTime.now().millisecondsSinceEpoch}_$safe';
    await _store
        .ref(path)
        .putData(bytes, SettableMetadata(contentType: 'application/pdf'));
    return path;
  }

  Future<Uint8List> download(String path) async {
    final bytes = await _store.ref(path).getData(maxBytes);
    if (bytes == null) throw StateError('The answer sheet could not be loaded.');
    return bytes;
  }

  /// Removes a stored PDF; a file already gone is fine.
  Future<void> delete(String path) async {
    try {
      await _store.ref(path).delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') rethrow;
    }
  }
}
