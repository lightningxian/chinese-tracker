import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/app_user.dart';
import '../../models/progress_summary.dart';
import 'report_pdf_fonts.dart';

/// Build 4 (Must 8): the printable progress report, built from the same
/// summary the screen shows. English text, like the other exports built
/// outside the screens; names keep their Chinese characters (Noto Sans SC).
abstract final class ProgressReportPdf {
  static const _statusText = {
    ProgressStatus.good: 'Progres Baik (good progress)',
    ProgressStatus.attention: 'Perlu Perhatian (needs attention)',
    ProgressStatus.followUp: 'Perlu Tindak Lanjut (needs follow-up)',
  };

  static const _warningText = {
    1: 'Attendance under 75% in the last 30 days',
    2: 'Practice average under 60, or 10 points lower than the 14 days before',
    3: 'No practice for 14 days',
    4: 'Voucher: 2 or fewer sessions left, or the deadline within 7 days',
    5: 'Two tests failed in a row',
  };

  static Future<pw.Document> build(ProgressSummary s, {DateTime? now}) async {
    final doc = pw.Document(theme: await ReportPdfFonts.loadTheme());
    final date = DateFormat('d MMM yyyy');
    final name = AppUser.staffLabelOf(s.studentNameChinese, s.studentName);
    final generated = DateFormat('d MMM yyyy HH:mm').format(now ?? DateTime.now());

    pw.Widget title(String t) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
          child: pw.Text(t,
              style: const pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        );
    pw.Widget table(List<String> head, List<List<String>> rows) => rows.isEmpty
        ? pw.Text('None yet.', style: const pw.TextStyle(color: PdfColors.grey700))
        : pw.TableHelper.fromTextArray(
            headers: head,
            data: rows,
            headerStyle: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            cellAlignment: pw.Alignment.centerLeft,
          );

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (context) => [
        pw.Text('Student Progress Report',
            style: const pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text(name, style: const pw.TextStyle(fontSize: 15)),
        pw.Text([s.level, if (s.group.isNotEmpty) s.group].join(' · '),
            style: const pw.TextStyle(fontSize: 11)),
        pw.Text('Status: ${_statusText[s.status]}',
            style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        pw.Text('Generated $generated',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        title('Summary'),
        table(['Item', 'Value'], [
          [
            'Codes passed toward ${s.nextLevel.isEmpty ? 'the top level' : s.nextLevel}',
            '${s.codesCount} of ${s.minCodes}',
          ],
          [
            'Attendance (30 days)',
            s.attendancePercent == null
                ? '-'
                : '${s.attendancePercent}% (present ${s.hadir}, absent ${s.alpa}, excused ${s.izin})',
          ],
          [
            'Practice average (14 days)',
            s.average14 == null
                ? '-'
                : '${s.average14!.toStringAsFixed(0)}'
                    '${s.averagePrev14 == null ? '' : ' (before: ${s.averagePrev14!.toStringAsFixed(0)})'}',
          ],
          ['Tests passed at ${s.level}', '${s.passedAtLevel}'],
          [
            'Voucher sessions left',
            !s.hasVoucher
                ? 'No active voucher'
                : '${s.sessionsRemaining}'
                    '${s.daysLeft == null ? '' : ', ${s.daysLeft} days to ${s.deadlineDate}'}',
          ],
        ]),
        title('Warnings'),
        if (s.warnings.isEmpty)
          pw.Text('None.')
        else
          table(['Warning', 'Detail'], [
            for (final w in s.warnings) [_warningText[w.id] ?? '${w.id}', w.detail],
          ]),
        title('Weekly practice (average score)'),
        table(['Week from', 'Average', 'Attempts'], [
          for (final w in s.weeks)
            if (w.attempts > 0)
              [w.monday, w.average?.toStringAsFixed(0) ?? '-', '${w.attempts}'],
        ]),
        title('Skills (last 90 days)'),
        table(['Skill', 'Correct'], [
          for (final k in s.skills) [k.skill, '${k.percent}%'],
        ]),
        title('Test history'),
        table(['Code', 'Date', 'Parts', 'Total', 'Result', 'Rank'], [
          for (final t in s.tests)
            [
              [t.code, if (t.placement) '(placement)', if (!t.valid) '(invalid)'].join(' '),
              t.finishedAt == null ? '' : date.format(t.finishedAt!),
              t.parts.map((p) => '${p.skill} ${p.mark}').join(', '),
              '${t.total} / ${t.max}',
              t.pendingMarking ? 'waiting for marking' : (t.passed ? 'passed' : 'not passed'),
              t.rank == null ? '' : '${t.rank} of ${t.boardSize}',
            ],
        ]),
        title('Teacher note'),
        pw.Text(s.latestNote == null
            ? 'No note yet.'
            : '${s.latestNote!.text}\n- ${s.latestNote!.teacherName}'
                '${s.latestNote!.createdAt == null ? '' : ', ${date.format(s.latestNote!.createdAt!)}'}'),
        title('Level history'),
        table(['Date', 'From', 'To', 'How'], [
          for (final h in s.levelHistory)
            [
              h.date == null ? '' : date.format(h.date!),
              h.from,
              h.to,
              h.kind == 'placement' ? 'placement test' : 'promotion',
            ],
        ]),
      ],
    ));
    return doc;
  }
}
