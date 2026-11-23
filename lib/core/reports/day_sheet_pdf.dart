import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/attendance_record.dart';
import '../../models/class_session.dart';
import 'report_pdf_fonts.dart';

/// Follow-up 2026-11-23 (Build 7 "Then"): the teacher's printable day
/// sheet — every class of the day with its booked students and empty boxes
/// for hadir / izin / alpa, plus blank rows for late joiners and walk-ins.
/// Like the other exports it keeps English labels with the Indonesian
/// attendance words; names keep their Chinese characters (Noto Sans SC).
abstract final class DaySheetPdf {
  static const blankRows = 3;

  /// The rows of one class: booked students first (by name), then
  /// [blankRows] empty lines.
  static List<List<String>> rowsFor(List<AttendanceRecord> records) {
    final booked = records.where((r) => r.inClass).toList()
      ..sort((a, b) => (a.studentName ?? '').compareTo(b.studentName ?? ''));
    return [
      for (var i = 0; i < booked.length; i++)
        ['${i + 1}', booked[i].studentName ?? '', '', '', '', ''],
      for (var i = 0; i < blankRows; i++) ['${booked.length + i + 1}', '', '', '', '', ''],
    ];
  }

  static Future<pw.Document> build({
    required String teacherName,
    required DateTime day,
    required List<({ClassSession session, List<AttendanceRecord> records})> classes,
    DateTime? now,
  }) async {
    final doc = pw.Document(theme: await ReportPdfFonts.loadTheme());
    final printed = DateFormat('d MMM yyyy HH:mm').format(now ?? DateTime.now());
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Easy Study · Day sheet',
                style: const pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Text('${DateFormat('EEEE, d MMMM yyyy').format(day)} · $teacherName',
                style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 8),
          ],
        ),
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Printed $printed · page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ),
        build: (_) => [
          if (classes.isEmpty) pw.Text('No classes on this day.'),
          for (final c in classes) ...[
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 10, bottom: 4),
              child: pw.Text(
                [
                  '${c.session.timeRangeLabel}  ${c.session.sessionTitle}',
                  if ((c.session.room ?? '').isNotEmpty) c.session.room!,
                  if (c.session.level.isNotEmpty) c.session.level,
                ].join(' · '),
                style: const pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.TableHelper.fromTextArray(
              headers: const ['No', 'Student', 'Hadir', 'Izin', 'Alpa', 'Notes'],
              data: rowsFor(c.records),
              headerStyle: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 10),
              cellHeight: 22,
              columnWidths: const {
                0: pw.FixedColumnWidth(26),
                1: pw.FlexColumnWidth(4),
                2: pw.FixedColumnWidth(40),
                3: pw.FixedColumnWidth(40),
                4: pw.FixedColumnWidth(40),
                5: pw.FlexColumnWidth(3),
              },
            ),
            pw.SizedBox(height: 4),
            pw.Text('Started: ______   Ended: ______   Teacher signature: ______________',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          ],
        ],
      ),
    );
    return doc;
  }
}
