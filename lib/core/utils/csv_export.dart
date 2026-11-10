import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'file_download.dart' as file_download;

/// Builds a CSV file from table rows and hands it to the browser as a
/// download (`<stem>_<yyyy-mm-dd>.csv`). Off web, where there is no download,
/// the text is copied to the clipboard instead. Excel opens the file
/// directly: a UTF-8 byte-order mark is written first so Chinese text shows.
abstract final class CsvExport {
  /// Returns true when the file was downloaded, false when it was copied.
  static Future<bool> download({
    required String fileStem,
    required List<String> header,
    required List<List<Object?>> rows,
  }) async {
    final csv = build(header: header, rows: rows);
    final date = DateTime.now().toIso8601String().substring(0, 10);
    if (kIsWeb) {
      file_download.downloadTextFile('${fileStem}_$date.csv', '﻿$csv');
      return true;
    }
    await Clipboard.setData(ClipboardData(text: csv));
    return false;
  }

  static String build({
    required List<String> header,
    required List<List<Object?>> rows,
  }) {
    final lines = <String>[
      header.map(cell).join(','),
      for (final row in rows) row.map(cell).join(','),
    ];
    return '${lines.join('\r\n')}\r\n';
  }

  /// Quotes a value when it holds a comma, quote or line break; null is an
  /// empty cell.
  static String cell(Object? value) {
    final text = value == null ? '' : value.toString();
    if (!text.contains(RegExp(r'[",\r\n]'))) return text;
    return '"${text.replaceAll('"', '""')}"';
  }
}
