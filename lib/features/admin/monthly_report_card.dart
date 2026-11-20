import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/reports/report_pdf_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/csv_export.dart';
import '../../core/widgets/app_card.dart';
import '../../l10n/l10n.dart';

/// Build 8 (Must 2): `reports/{yyyyMM}`, written by the `monthlyReport` job
/// (1st, 01:00 Jakarta) or rebuilt by an admin.
class MonthlyReport {
  const MonthlyReport({
    required this.month,
    required this.newStudents,
    required this.revenue,
    required this.paidInvoices,
    required this.activeStudents,
    required this.levels,
    required this.hadir,
    required this.izin,
    required this.alpa,
    required this.attendanceRate,
    required this.teachers,
    required this.teachingHours,
    this.builtAt,
  });

  final String month;
  final int newStudents;
  final int revenue;
  final int paidInvoices;
  final int activeStudents;
  final Map<String, int> levels;
  final int hadir;
  final int izin;
  final int alpa;
  final double? attendanceRate;
  final List<({String name, int held, double hours})> teachers;
  final double teachingHours;
  final DateTime? builtAt;

  factory MonthlyReport.fromMap(Map<String, dynamic> m) {
    int i(Object? v) => (v as num?)?.toInt() ?? 0;
    final att = (m['attendance'] as Map?) ?? const {};
    return MonthlyReport(
      month: m['month'] as String? ?? '',
      newStudents: i(m['newStudents']),
      revenue: i(m['revenue']),
      paidInvoices: i(m['paidInvoices']),
      activeStudents: i(m['activeStudents']),
      levels: {
        for (final e in ((m['levels'] as Map?) ?? const {}).entries) '${e.key}': i(e.value),
      },
      hadir: i(att['hadir']),
      izin: i(att['izin']),
      alpa: i(att['alpa']),
      attendanceRate: (att['rate'] as num?)?.toDouble(),
      teachers: [
        for (final t in (m['teachers'] as List? ?? const []))
          if (t is Map)
            (
              name: '${t['teacherName'] ?? t['teacherId'] ?? ''}',
              held: i(t['held']),
              hours: (t['hours'] as num?)?.toDouble() ?? 0,
            ),
      ],
      teachingHours: (m['teachingHours'] as num?)?.toDouble() ?? 0,
      builtAt: (m['builtAt'] as Timestamp?)?.toDate(),
    );
  }

  /// The rows of the CSV and the PDF: label, value.
  List<List<String>> rows({
    required String newStudentsLabel,
    required String revenueLabel,
    required String activeLabel,
    required String attendanceLabel,
    required String hoursLabel,
    required String levelLabel,
    required String teacherLabel,
  }) {
    final money = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return [
      [newStudentsLabel, '$newStudents'],
      [revenueLabel, '${money.format(revenue)} ($paidInvoices)'],
      [activeLabel, '$activeStudents'],
      [
        attendanceLabel,
        '${attendanceRate == null ? '—' : '${attendanceRate!.toStringAsFixed(1)}%'} '
            '(hadir $hadir · izin $izin · alpa $alpa)',
      ],
      [hoursLabel, teachingHours.toStringAsFixed(1)],
      for (final e in (levels.entries.toList()..sort((a, b) => a.key.compareTo(b.key))))
        ['$levelLabel ${e.key}', '${e.value}'],
      for (final t in teachers)
        ['$teacherLabel ${t.name}', '${t.held} · ${t.hours.toStringAsFixed(1)} h'],
    ];
  }
}

class MonthlyReportCard extends StatefulWidget {
  const MonthlyReportCard({super.key});

  @override
  State<MonthlyReportCard> createState() => _MonthlyReportCardState();
}

class _MonthlyReportCardState extends State<MonthlyReportCard> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month - 1);
  bool _busy = false;

  String get _key => DateFormat('yyyyMM').format(_month);

  Stream<MonthlyReport?> get _stream => FirebaseFirestore.instance
      .collection('reports')
      .doc(_key)
      .snapshots()
      .map((d) => d.exists ? MonthlyReport.fromMap(d.data()!) : null);

  Future<void> _rebuild() async {
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      await FirebaseFunctions.instance
          .httpsCallable('rebuildMonthlyReport')
          .call({'month': _key});
      messenger.showSnackBar(SnackBar(content: Text(l.monthlyReportRebuilt)));
    } on FirebaseFunctionsException catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text(e.message ?? e.code), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<List<String>> _rows(MonthlyReport r) {
    final l = context.l10n;
    return r.rows(
      newStudentsLabel: l.monthlyNewStudents,
      revenueLabel: l.monthlyRevenue,
      activeLabel: l.monthlyActive,
      attendanceLabel: l.monthlyAttendance,
      hoursLabel: l.monthlyHours,
      levelLabel: l.monthlyLevel,
      teacherLabel: l.monthlyTeacher,
    );
  }

  Future<void> _csv(MonthlyReport r) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await CsvExport.download(
      fileStem: 'monthly_report_$_key',
      header: [l.monthlyItem, l.monthlyValue],
      rows: _rows(r),
    );
    if (!ok) messenger.showSnackBar(SnackBar(content: Text(l.recapCopied)));
  }

  Future<void> _pdf(MonthlyReport r) async {
    final l = context.l10n;
    final title = '${l.monthlyReportTitle} · ${DateFormat('MMMM yyyy').format(_month)}';
    final rows = _rows(r);
    final theme = await ReportPdfFonts.loadTheme();
    final doc = pw.Document(theme: theme);
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Easy Study · 易华文教中心', style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 6),
          pw.Text(title, style: const pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 14),
          pw.TableHelper.fromTextArray(
            headers: [l.monthlyItem, l.monthlyValue],
            data: rows,
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    ));
    await Printing.layoutPdf(
      onLayout: (_) async => doc.save(),
      name: 'monthly_report_$_key.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: StreamBuilder<MonthlyReport?>(
        key: ValueKey(_key),
        stream: _stream,
        builder: (context, snap) {
          final r = snap.data;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(l.monthlyReportTitle,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  IconButton(
                    onPressed: () => setState(
                        () => _month = DateTime(_month.year, _month.month - 1)),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(DateFormat('MMMM yyyy').format(_month),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  IconButton(
                    onPressed: () => setState(
                        () => _month = DateTime(_month.year, _month.month + 1)),
                    icon: const Icon(Icons.chevron_right),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _rebuild,
                    icon: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.refresh, size: 18),
                    label: Text(l.monthlyRebuild),
                  ),
                  if (r != null) ...[
                    OutlinedButton.icon(
                      onPressed: () => _csv(r),
                      icon: const Icon(Icons.download_outlined, size: 18),
                      label: const Text('CSV'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _pdf(r),
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                      label: const Text('PDF'),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              if (snap.connectionState == ConnectionState.waiting && r == null)
                const LinearProgressIndicator()
              else if (r == null)
                Text(l.monthlyNotBuilt,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13))
              else
                Table(
                  columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(3)},
                  children: [
                    for (final row in _rows(r))
                      TableRow(children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(row[0],
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(row[1],
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                      ]),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}
