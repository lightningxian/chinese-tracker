import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/cohort_report_models.dart';
import '../constants/app_constants.dart';

abstract final class CohortSummaryReportPdf {
  static Future<pw.Document> build(CohortSummaryReportData data) async {
    final doc = pw.Document();
    final stats = data.stats;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => [
          pw.Text(
            '${AppConstants.brandName} — Centre Summary',
            style: const pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Generated ${data.generatedAtLabel}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 16),
          _sectionTitle('Centre statistics'),
          pw.Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _statChip('Students', '${stats.totalStudents}'),
              _statChip('Active this week', '${stats.activeThisWeek}'),
              _statChip(
                'Homework completion',
                '${stats.homeworkCompletionPercent}%',
              ),
              _statChip('Overdue', '${stats.overdueAssignments}'),
              if (stats.avgQuizScore != null)
                _statChip('Avg quiz score', '${stats.avgQuizScore}%'),
              if (stats.avgPracticeScore != null)
                _statChip('Avg practice score', '${stats.avgPracticeScore}%'),
              _statChip(
                'Sessions remaining',
                '${stats.totalSessionsRemaining}',
              ),
              _statChip('Classes this week', '${stats.classesThisWeek}'),
              _statChip(
                'Need attention',
                '${stats.studentsNeedingAttention}',
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          _sectionTitle('Student roster'),
          pw.SizedBox(height: 8),
          if (data.students.isEmpty)
            pw.Text('No students registered yet.')
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(1.2),
                3: const pw.FlexColumnWidth(1.2),
                4: const pw.FlexColumnWidth(1.5),
                5: const pw.FlexColumnWidth(1),
                6: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _cell('Student', bold: true),
                    _cell('Level', bold: true),
                    _cell('Term', bold: true),
                    _cell('Homework', bold: true),
                    _cell('Quiz avg', bold: true),
                    _cell('Sessions', bold: true),
                    _cell('Last active', bold: true),
                  ],
                ),
                ...data.students.map(
                  (student) => pw.TableRow(
                    children: [
                      _cell(student.name),
                      _cell(student.levelLabel),
                      _cell(student.termProgressLabel),
                      _cell(student.homeworkLabel),
                      _cell(
                        student.avgQuizScore != null
                            ? '${student.avgQuizScore}%'
                            : '—',
                      ),
                      _cell('${student.sessionsRemaining}'),
                      _cell(student.lastActivityLabel),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );

    return doc;
  }

  static pw.Widget _sectionTitle(String text) {
    return pw.Text(
      text,
      style: const pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
    );
  }

  static pw.Widget _statChip(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label: ',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.TextSpan(
              text: value,
              style: const pw.TextStyle(
                  fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _cell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
