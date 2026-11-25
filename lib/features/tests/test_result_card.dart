import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/reports/report_pdf_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/l10n.dart';
import '../../models/test_track.dart';
import 'test_labels.dart';
import 'test_player_screen.dart' show PlacementChip;

/// Centre name printed on the card.
const kCentreName = '易华文教中心 · Easy Study';

/// The line that keeps the card from passing for an official certificate
/// (owner decision 2026-11-16).
const kSimulationLine = 'Simulation by Easy Study';

/// The result card in the style of the official HSK score report: the
/// candidate table on top, the marks table below (one column per part,
/// 总分, 合格情况, pass mark). Labels are Chinese with the app language
/// underneath. No nationality, no gender.
class TestResultCard extends StatelessWidget {
  const TestResultCard({super.key, required this.result});

  final TestResult result;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = result;
    final date = r.finishedAt == null
        ? '—'
        : DateFormat('yyyy-MM-dd').format(r.finishedAt!);
    final ink = AppColors.textPrimary;
    final line = AppColors.tableLine;

    Widget label(String zh, String local) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(zh,
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: ink, fontSize: 13)),
              Text(local,
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        );
    Widget value(String v, {bool big = false, Color? color}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            v,
            style: TextStyle(
              fontWeight: big ? FontWeight.w800 : FontWeight.w600,
              fontSize: big ? 20 : 14,
              color: color ?? ink,
            ),
          ),
        );
    Widget centred(Widget w) => Center(child: w);

    // Build 2A: while a teacher still marks an answer there is no pass or
    // fail yet (待评分 = waiting to be marked).
    final pending = r.isPendingMarking;
    final passedText = pending ? '待评分' : r.passed ? '合格' : '不合格';
    final passedLocal = pending
        ? l.testsPendingMarking
        : r.passed
            ? l.testsPassed
            : l.testsNotPassed;

    return Container(
      constraints: const BoxConstraints(maxWidth: 760),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '汉语水平考试 成绩报告',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          Text(
            l.testsCardTitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            kCentreName,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          if (r.placement) ...[
            const SizedBox(height: 6),
            Center(child: PlacementChip(label: l.placementTestLabel)),
          ],
          // Build 9D: a later sitting says so; a repeat is practice.
          if (sittingLabel(l, r.sittingNo, repeat: r.isRepeat).isNotEmpty) ...[
            const SizedBox(height: 6),
            Center(
              child: PlacementChip(
                  label: sittingLabel(l, r.sittingNo, repeat: r.isRepeat)),
            ),
          ],
          const SizedBox(height: 14),
          Table(
            border: TableBorder.all(color: line),
            columnWidths: const {
              0: IntrinsicColumnWidth(),
              1: FlexColumnWidth(),
            },
            children: [
              TableRow(children: [
                label('姓名', l.testsCardName),
                value(r.studentName),
              ]),
              TableRow(children: [
                label('中文姓名', l.testsCardChineseName),
                value(r.studentNameChinese.isEmpty ? '—' : r.studentNameChinese),
              ]),
              TableRow(children: [
                label('考试类型', l.testsCardExamType),
                value(r.examTypeChinese),
              ]),
              TableRow(children: [
                label('试卷代码', l.testsCardTestCode),
                value(r.releaseYear == null
                    ? r.code
                    : '${r.code} (${r.releaseYear})'),
              ]),
              TableRow(children: [
                label('成绩编号', l.testsCardResultNumber),
                value(r.resultNumber),
              ]),
              TableRow(children: [
                label('考试日期', l.testsCardDate),
                value(date),
              ]),
              TableRow(children: [
                label('监考老师', l.testsCardSupervisor),
                value(r.supervisorName.isEmpty ? '—' : r.supervisorName),
              ]),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 300),
              child: Table(
                border: TableBorder.all(color: line),
                defaultColumnWidth: const IntrinsicColumnWidth(),
                children: [
                  TableRow(children: [
                    for (final p in r.parts)
                      centred(label(p.skill.chinese, p.skill.localized(l))),
                    centred(label('总分', l.testsCardTotal)),
                    centred(label('合格情况', l.testsCardOutcome)),
                  ]),
                  TableRow(children: [
                    for (final p in r.parts)
                      centred(value('${p.mark}', big: true)),
                    centred(value('${r.total}', big: true)),
                    centred(Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      child: Column(
                        children: [
                          Text(
                            r.valid ? passedText : '无效',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: !r.valid
                                  ? AppColors.error
                                  : pending
                                      ? AppColors.chipAmberFg
                                      : r.passed
                                          ? AppColors.success
                                          : AppColors.error,
                            ),
                          ),
                          Text(
                            r.valid ? passedLocal : l.testsInvalid,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    )),
                  ]),
                  TableRow(children: [
                    for (final p in r.parts)
                      centred(value('/ ${p.maxScore}')),
                    centred(value('/ ${r.max}')),
                    centred(value(l.testsCardPassMark(r.passMark))),
                  ]),
                ],
              ),
            ),
          ),
          if (!r.valid) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error),
              ),
              child: Text(
                '${l.testsInvalid}: ${r.invalidReason}',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            kSimulationLine,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// The same card as a printable A4 PDF (Chinese text through the bundled
/// Noto Sans SC font): opens the print / save dialog.
Future<void> printTestResultCard(TestResult r, AppLocalizations l) async {
  final bytes = await buildTestResultCardPdf(r, l);
  await Printing.layoutPdf(
    name: 'easy-study-${r.resultNumber}.pdf',
    onLayout: (_) async => bytes,
  );
}

/// The PDF bytes of the result card (also used by the unit test that checks
/// the Chinese text).
Future<Uint8List> buildTestResultCardPdf(
    TestResult r, AppLocalizations l) async {
  final theme = await ReportPdfFonts.loadTheme();
  final date = r.finishedAt == null
      ? '—'
      : DateFormat('yyyy-MM-dd').format(r.finishedAt!);
  const grey = PdfColor.fromInt(0xFF666666);

  pw.Widget label(String zh, String local) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(zh,
                style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(local, style: const pw.TextStyle(fontSize: 8, color: grey)),
          ],
        ),
      );
  pw.Widget value(String v, {bool big = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: pw.Text(v,
            style: pw.TextStyle(
                fontSize: big ? 16 : 11,
                fontWeight: big ? pw.FontWeight.bold : pw.FontWeight.normal)),
      );
  pw.Widget c(pw.Widget w) => pw.Center(child: w);

  final doc = pw.Document(theme: theme, title: 'Result ${r.resultNumber}');
  doc.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(36),
    build: (_) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text('汉语水平考试 成绩报告',
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(
                fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.Text(l.testsCardTitle,
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(color: grey)),
        pw.Text(kCentreName,
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 9, color: grey)),
        pw.SizedBox(height: 16),
        pw.Table(
          border: pw.TableBorder.all(width: 0.6),
          columnWidths: const {
            0: pw.IntrinsicColumnWidth(),
            1: pw.FlexColumnWidth(),
          },
          children: [
            pw.TableRow(children: [label('姓名', l.testsCardName), value(r.studentName)]),
            pw.TableRow(children: [
              label('中文姓名', l.testsCardChineseName),
              value(r.studentNameChinese.isEmpty ? '—' : r.studentNameChinese),
            ]),
            pw.TableRow(children: [
              label('考试类型', l.testsCardExamType),
              value(r.examTypeChinese),
            ]),
            pw.TableRow(children: [
              label('试卷代码', l.testsCardTestCode),
              value(r.releaseYear == null ? r.code : '${r.code} (${r.releaseYear})'),
            ]),
            pw.TableRow(children: [
              label('成绩编号', l.testsCardResultNumber),
              value(r.resultNumber),
            ]),
            pw.TableRow(children: [label('考试日期', l.testsCardDate), value(date)]),
            pw.TableRow(children: [
              label('监考老师', l.testsCardSupervisor),
              value(r.supervisorName.isEmpty ? '—' : r.supervisorName),
            ]),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Table(
          border: pw.TableBorder.all(width: 0.6),
          children: [
            pw.TableRow(children: [
              for (final p in r.parts) c(label(p.skill.chinese, p.skill.localized(l))),
              c(label('总分', l.testsCardTotal)),
              c(label('合格情况', l.testsCardOutcome)),
            ]),
            pw.TableRow(children: [
              for (final p in r.parts) c(value('${p.mark}', big: true)),
              c(value('${r.total}', big: true)),
              c(value(
                  !r.valid
                      ? '无效 · ${l.testsInvalid}'
                      : r.isPendingMarking
                          ? '待评分 · ${l.testsPendingMarking}'
                          : r.passed
                          ? '合格 · ${l.testsPassed}'
                          : '不合格 · ${l.testsNotPassed}',
                  big: true)),
            ]),
            pw.TableRow(children: [
              for (final p in r.parts) c(value('/ ${p.maxScore}')),
              c(value('/ ${r.max}')),
              c(value(l.testsCardPassMark(r.passMark))),
            ]),
          ],
        ),
        if (!r.valid) ...[
          pw.SizedBox(height: 12),
          pw.Text('${l.testsInvalid}: ${r.invalidReason}',
              style: const pw.TextStyle(
                  color: PdfColors.red, fontWeight: pw.FontWeight.bold)),
        ],
        pw.Spacer(),
        pw.Text(kSimulationLine,
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 9, color: grey)),
      ],
    ),
  ));
  return doc.save();
}
