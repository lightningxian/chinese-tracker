import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import '../worksheet_import_service.dart';

abstract final class DocxTextReader {
  static String extract(Uint8List bytes) {
    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw WorksheetImportException('Could not read this Word file.');
    }

    final entry = archive.findFile('word/document.xml');
    if (entry == null) {
      throw WorksheetImportException('Invalid Word document.');
    }

    final content = entry.content;
    final xmlText = String.fromCharCodes(content);
    final document = XmlDocument.parse(xmlText);
    final buffer = StringBuffer();

    for (final paragraph in document.findAllElements('w:p')) {
      final line = paragraph
          .findAllElements('w:t')
          .map((node) => node.innerText)
          .join();
      if (line.trim().isNotEmpty) {
        buffer.writeln(line);
      }
    }

    final text = buffer.toString().trim();
    if (text.isEmpty) {
      throw WorksheetImportException(
        'No text found in this Word file. Try exporting as PDF.',
      );
    }
    return text;
  }
}
