import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/constants/app_constants.dart';
import '../../core/reports/report_pdf_fonts.dart';
import '../../models/leaderboard.dart';

/// Build 9C (supervisor 2026-11-25): the leaderboard as CSV and PDF for
/// staff, and one student's own result as a shareable card. The card
/// carries no other student's name.
abstract final class LeaderboardExport {
  static final _when = DateFormat('d MMM yyyy, HH:mm', 'en_US');

  /// "20 Nov 2026, 16:05 WIB" (Jakarta time).
  static String finishedText(LeaderboardEntry e) {
    final j = e.finishedAtJakarta;
    return j == null ? '' : '${_when.format(j)} WIB';
  }

  static String _nowJakarta() =>
      '${_when.format(DateTime.now().toUtc().add(const Duration(hours: 7)))} WIB';

  /// The skills present on the board, in order of first appearance.
  static List<String> skills(List<LeaderboardEntry> rows) {
    final out = <String>[];
    for (final e in rows) {
      for (final p in e.parts) {
        if (!out.contains(p.skill)) out.add(p.skill);
      }
    }
    return out;
  }

  static List<String> header(List<String> skills, String Function(String) skillName) => [
        'Rank',
        'Name',
        for (final s in skills) skillName(s),
        'Total',
        'Max',
        'Passed',
        'Finished at',
      ];

  static List<List<Object?>> rows(
    List<LeaderboardEntry> board,
    List<String> skills,
    String Function(LeaderboardEntry) nameOf,
  ) =>
      [
        for (final e in board)
          [
            e.rank,
            nameOf(e),
            for (final s in skills)
              e.parts.where((p) => p.skill == s).map((p) => p.mark).firstOrNull ?? '',
            e.total,
            e.max,
            e.passed ? 'yes' : 'no',
            finishedText(e),
          ],
      ];

  /// The whole board (staff only).
  static Future<Uint8List> boardPdf({
    required String code,
    required String level,
    required List<LeaderboardEntry> board,
    required String Function(LeaderboardEntry) nameOf,
    required String Function(String) skillName,
  }) async {
    final doc = pw.Document(theme: await ReportPdfFonts.loadTheme());
    final sk = skills(board);
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      footer: (ctx) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
      ),
      build: (_) => [
        pw.Text('${AppConstants.brandName} — Leaderboard $code',
            style: const pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text(
          [
            if (level.isNotEmpty) 'Paper level: $level',
            '${board.length} students',
            'Exported ${_nowJakarta()}',
          ].join(' · '),
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 12),
        pw.TableHelper.fromTextArray(
          headers: header(sk, skillName),
          data: [
            for (final r in rows(board, sk, nameOf)) [for (final c in r) '$c'],
          ],
          cellStyle: const pw.TextStyle(fontSize: 9),
          headerStyle: const pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          cellAlignment: pw.Alignment.centerLeft,
        ),
      ],
    ));
    return doc.save();
  }

  /// One student's own result: rank, their own name, marks, date, code.
  static Future<Uint8List> myResultPdf({
    required String code,
    required String level,
    required LeaderboardEntry me,
    required int boardSize,
    required String Function(String) skillName,
  }) async {
    final doc = pw.Document(theme: await ReportPdfFonts.loadTheme());
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a5.landscape,
      margin: const pw.EdgeInsets.all(28),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('${AppConstants.brandName} · 易华文教中心',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(height: 8),
          pw.Text(me.name,
              style: const pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Test $code${level.isEmpty ? '' : ' · $level'}',
              style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 14),
          pw.Text('Rank ${me.rank} of $boardSize',
              style: const pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text('${me.total} / ${me.max} · ${me.passed ? '合格 Passed' : '不合格 Not passed'}',
              style: const pw.TextStyle(fontSize: 14)),
          pw.SizedBox(height: 8),
          for (final p in me.parts)
            pw.Text('${skillName(p.skill)}: ${p.mark} / ${p.maxScore}',
                style: const pw.TextStyle(fontSize: 11)),
          pw.Spacer(),
          pw.Text(finishedText(me),
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        ],
      ),
    ));
    return doc.save();
  }
}
