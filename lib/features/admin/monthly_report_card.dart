import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/paging/date_range.dart';
import '../../core/reports/report_pdf_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/csv_export.dart';
import '../../core/widgets/app_card.dart';
import '../../l10n/l10n.dart';

typedef ReportTeacher = ({String id, String name, int held, double hours});

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
  final List<ReportTeacher> teachers;
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
              id: '${t['teacherId'] ?? t['teacherName'] ?? ''}',
              name: '${t['teacherName'] ?? t['teacherId'] ?? ''}',
              held: i(t['held']),
              hours: (t['hours'] as num?)?.toDouble() ?? 0,
            ),
      ],
      teachingHours: (m['teachingHours'] as num?)?.toDouble() ?? 0,
      builtAt: (m['builtAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Build 9B: several months as one (oldest first). Counts and money are
  /// summed; the attendance rate is recomputed from the summed hadir and
  /// alpa, never averaged; active students and levels are the last month's
  /// (end of period). Twin of `mergeReports` in `functions/reports.js`.
  static MonthlyReport? merge(List<MonthlyReport> months) {
    if (months.isEmpty) return null;
    int sum(int Function(MonthlyReport r) f) =>
        months.fold(0, (t, r) => t + f(r));
    final hadir = sum((r) => r.hadir);
    final alpa = sum((r) => r.alpa);
    final byTeacher = <String, ReportTeacher>{};
    for (final t in months.expand((r) => r.teachers)) {
      final o = byTeacher[t.id];
      byTeacher[t.id] = o == null
          ? t
          : (
              id: t.id,
              name: t.name.isEmpty ? o.name : t.name,
              held: o.held + t.held,
              hours: o.hours + t.hours,
            );
    }
    double round1(double v) => (v * 10).round() / 10;
    final teachers = [
      for (final t in byTeacher.values)
        (id: t.id, name: t.name, held: t.held, hours: round1(t.hours)),
    ]..sort((a, b) => a.name.compareTo(b.name));
    final last = months.last;
    return MonthlyReport(
      month: '${months.first.month}-${last.month}',
      newStudents: sum((r) => r.newStudents),
      revenue: sum((r) => r.revenue),
      paidInvoices: sum((r) => r.paidInvoices),
      activeStudents: last.activeStudents,
      levels: Map.of(last.levels),
      hadir: hadir,
      izin: sum((r) => r.izin),
      alpa: alpa,
      attendanceRate:
          hadir + alpa > 0 ? (hadir * 1000 / (hadir + alpa)).round() / 10 : null,
      teachers: teachers,
      teachingHours: round1(teachers.fold(0.0, (t, x) => t + x.hours)),
    );
  }

  String get rateLabel => attendanceRate == null
      ? '—'
      : '${attendanceRate!.toStringAsFixed(1)}%';

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
        '$rateLabel (hadir $hadir · izin $izin · alpa $alpa)',
      ],
      [hoursLabel, teachingHours.toStringAsFixed(1)],
      for (final e in (levels.entries.toList()..sort((a, b) => a.key.compareTo(b.key))))
        ['$levelLabel ${e.key}', '${e.value}'],
      for (final t in teachers)
        ['$teacherLabel ${t.name}', '${t.held} · ${t.hours.toStringAsFixed(1)} h'],
    ];
  }
}

/// The centre report over a period of months (Build 9B): one line per
/// month, a total line, a chart per month and the merged details. A month
/// with no report says "not built" with its own Rebuild button; it is never
/// counted as zero.
class MonthlyReportCard extends StatefulWidget {
  const MonthlyReportCard({super.key, required this.period});

  final MonthPeriod period;

  @override
  State<MonthlyReportCard> createState() => _MonthlyReportCardState();
}

class _MonthlyReportCardState extends State<MonthlyReportCard> {
  late Future<Map<String, MonthlyReport?>> _load;
  final _busy = <String>{};

  @override
  void initState() {
    super.initState();
    _load = _read();
  }

  @override
  void didUpdateWidget(MonthlyReportCard old) {
    super.didUpdateWidget(old);
    if (old.period != widget.period) _load = _read();
  }

  Future<Map<String, MonthlyReport?>> _read() async {
    final col = FirebaseFirestore.instance.collection('reports');
    final keys = widget.period.monthKeys;
    final docs = await Future.wait(keys.map((k) => col.doc(k).get()));
    return {
      for (var i = 0; i < keys.length; i++)
        keys[i]: docs[i].exists ? MonthlyReport.fromMap(docs[i].data()!) : null,
    };
  }

  String _monthLabel(String key) => DateFormat('MMM yyyy')
      .format(DateTime(int.parse(key.substring(0, 4)), int.parse(key.substring(4))));

  Future<void> _rebuild(String key) async {
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    setState(() => _busy.add(key));
    try {
      await FirebaseFunctions.instance
          .httpsCallable('rebuildMonthlyReport')
          .call({'month': key});
      messenger.showSnackBar(SnackBar(content: Text(l.monthlyReportRebuilt)));
      if (mounted) setState(() => _load = _read());
    } on FirebaseFunctionsException catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text(e.message ?? e.code), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _busy.remove(key));
    }
  }

  List<List<String>> _detailRows(MonthlyReport r) {
    final l = context.l10n;
    return r.rows(
      newStudentsLabel: l.monthlyNewStudents,
      revenueLabel: l.monthlyRevenue,
      activeLabel: l.monthlyActiveEnd,
      attendanceLabel: l.monthlyAttendance,
      hoursLabel: l.monthlyHours,
      levelLabel: l.monthlyLevel,
      teacherLabel: l.monthlyTeacher,
    );
  }

  static final _money =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  List<String> _monthHeader() {
    final l = context.l10n;
    return [
      l.monthlyMonth,
      l.monthlyNewStudents,
      l.monthlyRevenueShort,
      l.monthlyPaidShort,
      l.monthlyActive,
      l.monthlyAttendance,
      l.monthlyHours,
    ];
  }

  List<String> _monthRow(String label, MonthlyReport? r) => r == null
      ? [label, context.l10n.monthlyNotBuiltShort, '', '', '', '', '']
      : [
          label,
          '${r.newStudents}',
          _money.format(r.revenue),
          '${r.paidInvoices}',
          '${r.activeStudents}',
          r.rateLabel,
          r.teachingHours.toStringAsFixed(1),
        ];

  String get _periodText =>
      widget.period.describe(Localizations.localeOf(context).toLanguageTag());

  String get _fileStem =>
      'centre_report_${widget.period.monthKeys.first}_${widget.period.monthKeys.last}';

  Future<void> _csv(Map<String, MonthlyReport?> data, MonthlyReport total) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await CsvExport.download(
      fileStem: _fileStem,
      header: _monthHeader(),
      rows: [
        [l.monthlyPeriodLine(_periodText), '', '', '', '', '', ''],
        for (final e in data.entries) _monthRow(_monthLabel(e.key), e.value),
        _monthRow(l.monthlyTotal, total),
        [],
        for (final row in _detailRows(total)) [...row, '', '', '', '', ''],
      ],
    );
    if (!ok) messenger.showSnackBar(SnackBar(content: Text(l.recapCopied)));
  }

  Future<void> _pdf(Map<String, MonthlyReport?> data, MonthlyReport total) async {
    final l = context.l10n;
    final theme = await ReportPdfFonts.loadTheme();
    final doc = pw.Document(theme: theme);
    final monthRows = [
      for (final e in data.entries) _monthRow(_monthLabel(e.key), e.value),
      _monthRow(l.monthlyTotal, total),
    ];
    final details = _detailRows(total);
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (_) => [
        pw.Text('Easy Study · 易华文教中心', style: const pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 6),
        pw.Text(l.monthlyReportTitle,
            style: const pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 2),
        pw.Text(l.monthlyPeriodLine(_periodText),
            style: const pw.TextStyle(fontSize: 11)),
        pw.SizedBox(height: 14),
        pw.TableHelper.fromTextArray(
          headers: _monthHeader(),
          data: monthRows,
          cellStyle: const pw.TextStyle(fontSize: 9),
          headerStyle: const pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          cellAlignment: pw.Alignment.centerLeft,
        ),
        pw.SizedBox(height: 14),
        pw.TableHelper.fromTextArray(
          headers: [l.monthlyItem, l.monthlyValue],
          data: details,
          cellAlignment: pw.Alignment.centerLeft,
        ),
      ],
    ));
    await Printing.layoutPdf(
      onLayout: (_) async => doc.save(),
      name: '$_fileStem.pdf',
    );
  }

  Widget _chart(Map<String, MonthlyReport?> data) {
    final keys = data.keys.toList();
    final maxRev = data.values
        .whereType<MonthlyReport>()
        .fold<int>(0, (m, r) => r.revenue > m ? r.revenue : m);
    return SizedBox(
      height: 170,
      child: BarChart(
        BarChartData(
          maxY: maxRev == 0 ? 1 : maxRev * 1.15,
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (g, _, rod, __) => BarTooltipItem(
                '${_monthLabel(keys[g.x])}\n${_money.format(rod.toY)}',
                const TextStyle(fontSize: 11),
              ),
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= keys.length) return const SizedBox.shrink();
                  return Text(
                    DateFormat('MMM').format(DateTime(
                        int.parse(keys[i].substring(0, 4)),
                        int.parse(keys[i].substring(4)))),
                    style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < keys.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: (data[keys[i]]?.revenue ?? 0).toDouble(),
                  width: 16,
                  color: data[keys[i]] == null ? AppColors.border : AppColors.teal,
                  borderRadius: BorderRadius.circular(3),
                ),
              ]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: FutureBuilder<Map<String, MonthlyReport?>>(
        future: _load,
        builder: (context, snap) {
          final data = snap.data;
          final built = data?.values.whereType<MonthlyReport>().toList() ?? const [];
          final total = MonthlyReport.merge(built);
          final missing = data?.values.where((r) => r == null).length ?? 0;
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
                  Text(_periodText,
                      style: TextStyle(color: AppColors.textSecondary)),
                  if (data != null && total != null) ...[
                    OutlinedButton.icon(
                      onPressed: () => _csv(data, total),
                      icon: const Icon(Icons.download_outlined, size: 18),
                      label: const Text('CSV'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _pdf(data, total),
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                      label: const Text('PDF'),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              if (snap.hasError)
                Text('${snap.error}', style: TextStyle(color: AppColors.error))
              else if (data == null)
                const LinearProgressIndicator()
              else ...[
                if (missing > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(l.monthlyMissingMonths(missing),
                        style: TextStyle(color: AppColors.error, fontSize: 12.5)),
                  ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowHeight: 36,
                    dataRowMinHeight: 34,
                    dataRowMaxHeight: 40,
                    columnSpacing: 18,
                    columns: [
                      for (final h in _monthHeader()) DataColumn(label: Text(h)),
                      const DataColumn(label: SizedBox.shrink()),
                    ],
                    rows: [
                      for (final e in data.entries)
                        DataRow(cells: [
                          for (final c in _monthRow(_monthLabel(e.key), e.value))
                            DataCell(Text(c,
                                style: e.value == null
                                    ? TextStyle(color: AppColors.textSecondary)
                                    : null)),
                          DataCell(IconButton(
                            tooltip: l.monthlyRebuild,
                            onPressed: _busy.contains(e.key) ? null : () => _rebuild(e.key),
                            icon: _busy.contains(e.key)
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2))
                                : Icon(Icons.refresh,
                                    size: 18,
                                    color: e.value == null ? AppColors.teal : null),
                          )),
                        ]),
                      if (total != null && data.length > 1)
                        DataRow(cells: [
                          for (final c in _monthRow(l.monthlyTotal, total))
                            DataCell(Text(c,
                                style: const TextStyle(fontWeight: FontWeight.w700))),
                          const DataCell(SizedBox.shrink()),
                        ]),
                    ],
                  ),
                ),
                if (data.length > 1) ...[
                  const SizedBox(height: 12),
                  Text(l.monthlyRevenueShort,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                  const SizedBox(height: 6),
                  _chart(data),
                ],
                if (total != null) ...[
                  const SizedBox(height: 12),
                  Table(
                    columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(3)},
                    children: [
                      for (final row in _detailRows(total))
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
                ] else
                  Text(l.monthlyNotBuilt,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ],
          );
        },
      ),
    );
  }
}
