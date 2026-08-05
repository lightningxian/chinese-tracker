import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/student_progress_report_data.dart';
import '../constants/app_constants.dart';
import 'report_pdf_fonts.dart';

abstract final class StudentProgressReportPdf {
  static Future<pw.Document> build(StudentProgressReportData data) async {
    final doc = pw.Document(
      theme: await ReportPdfFonts.loadTheme(),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          pw.Text(
            'Student Progress Report',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            data.studentName,
            style: const pw.TextStyle(fontSize: 16),
          ),
          pw.SizedBox(height: 4),
          pw.Text(data.email, style: const pw.TextStyle(fontSize: 11)),
          pw.Text(data.levelLabel, style: const pw.TextStyle(fontSize: 11)),
          pw.SizedBox(height: 4),
          pw.Text(
            'Generated ${data.generatedAtLabel}',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 20),
          _sectionTitle('Summary'),
          _bullet('Lessons completed: ${data.lessonsCompleted} / ${data.lessonsTotal}'),
          if (data.averageQuizScore != null)
            _bullet('Average quiz score: ${data.averageQuizScore}%'),
          _bullet(
            'Practice: ${data.exercisesCompleted} / ${data.exercisesAssigned} completed'
            '${data.exercisesOverdue > 0 ? ' (${data.exercisesOverdue} overdue)' : ''}',
          ),
          _bullet(
            'Class sessions: ${data.classSessionsUsed} used, '
            '${data.classSessionsRemaining} remaining',
          ),
          _bullet('Last activity: ${data.lastActivityLabel}'),
          if (data.terms.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _sectionTitle('Lesson progress by term'),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _tableCell('Term', bold: true),
                    _tableCell('Progress', bold: true),
                  ],
                ),
                ...data.terms.map(
                  (term) => pw.TableRow(
                    children: [
                      _tableCell(term.label),
                      _tableCell('${term.completed} / ${term.total}'),
                    ],
                  ),
                ),
              ],
            ),
          ],
          if (data.exercises.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _sectionTitle('Practice at ${data.levelLabel.split(' ·').first}'),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _tableCell('Exercise', bold: true),
                    _tableCell('Result', bold: true),
                  ],
                ),
                ...data.exercises.map(
                  (line) => pw.TableRow(
                    children: [
                      _tableCell(line.title),
                      _tableCell(_exerciseResultLine(line)),
                    ],
                  ),
                ),
              ],
            ),
          ],
          pw.SizedBox(height: 24),
          pw.Text(
            AppConstants.brandName,
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    return doc;
  }

  static String _exerciseResultLine(ReportExerciseLine line) {
    if (line.bestScore != null) {
      final attempts = line.attempts ?? 1;
      return 'Best ${line.bestScore}% - $attempts attempt${attempts == 1 ? '' : 's'}';
    }
    if (line.status == 'Overdue') return 'Not started - overdue';
    return 'Not started';
  }

  static pw.Widget _sectionTitle(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
    );
  }

  static pw.Widget _bullet(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('- ', style: const pw.TextStyle(fontSize: 11)),
          pw.Expanded(
            child: pw.Text(text, style: const pw.TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _tableCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
