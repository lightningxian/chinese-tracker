import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../services/admin_ops_report_service.dart';
import '../constants/app_constants.dart';
import '../utils/money_format.dart';
import 'report_pdf_fonts.dart';

/// PDF layouts for the eight operational admin reports. One builder per
/// report; all share the same header and table style.
abstract final class AdminOpsReportsPdf {
  static String rp(int v) => formatRupiah(v);

  static String _date(DateTime? d) =>
      d == null ? '—' : DateFormat('d MMM yyyy').format(d);

  static String _isoDate(String iso) => _date(DateTime.tryParse(iso));

  static Future<pw.Document> _doc(
    String title,
    DateTime generatedAt,
    List<pw.Widget> body, {
    bool landscape = false,
  }) async {
    final doc = pw.Document(theme: await ReportPdfFonts.loadTheme());
    doc.addPage(
      pw.MultiPage(
        pageFormat: landscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ),
        build: (_) => [
          pw.Text(
            '${AppConstants.brandName} — $title',
            style: const pw.TextStyle(
                fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Generated ${DateFormat('d MMM yyyy, HH:mm').format(generatedAt)}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 14),
          ...body,
        ],
      ),
    );
    return doc;
  }

  static pw.Widget _h(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 10, bottom: 6),
        child: pw.Text(
          text,
          style:
              const pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
      );

  static pw.Widget _note(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Text(
          text,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
      );

  static pw.Widget _cell(String text, {bool bold = false}) => pw.Padding(
        padding: const pw.EdgeInsets.all(5),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );

  static pw.Widget _table(
    List<String> headers,
    List<List<String>> rows, {
    List<double>? widths,
    List<String>? total,
  }) {
    if (rows.isEmpty) return _note('Nothing to show.');
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {
        for (var i = 0; i < headers.length; i++)
          i: pw.FlexColumnWidth(
              widths != null && i < widths.length ? widths[i] : 1),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [for (final h in headers) _cell(h, bold: true)],
        ),
        for (final r in rows)
          pw.TableRow(children: [for (final c in r) _cell(c)]),
        if (total != null)
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey100),
            children: [for (final c in total) _cell(c, bold: true)],
          ),
      ],
    );
  }

  // 1
  static Future<pw.Document> attendance(AdminOpsReportData d) => _doc(
        'Attendance per student per month',
        d.generatedAt,
        [
          _note('Hadir = present, Izin = excused (not charged), Alpa = absent. '
              'Open classes are not counted until they are concluded.'),
          for (final m in d.attendance.reversed) ...[
            _h('${m.month.label} · ${m.rows.length} students · '
                '${m.presentPercent}% present'),
            _table(
              const ['Student', 'Level', 'Hadir', 'Izin', 'Alpa', 'Present %'],
              [
                for (final r in m.rows)
                  [
                    r.name,
                    r.level,
                    '${r.hadir}',
                    '${r.izin}',
                    '${r.alpa}',
                    '${r.presentPercent}%'
                  ],
              ],
              widths: const [2.4, 0.9, 0.7, 0.7, 0.7, 0.9],
              total: m.rows.isEmpty
                  ? null
                  : [
                      'All',
                      '',
                      '${m.hadir}',
                      '${m.izin}',
                      '${m.alpa}',
                      '${m.presentPercent}%'
                    ],
            ),
          ],
        ],
      );

  // 2
  static Future<pw.Document> termAlerts(AdminOpsReportData d) {
    final t = d.termAlerts;
    return _doc(
      'Term balance alerts',
      d.generatedAt,
      [
        _note('${t.activeTerms} active terms. '
            '${t.count(TermAlertKind.lowBalance)} with 2 or fewer sessions left, '
            '${t.count(TermAlertKind.expiringSoon)} expiring within 7 days, '
            '${t.count(TermAlertKind.expiredWithBalance)} expired with sessions left. '
            'Most urgent first.'),
        _table(
          const ['Student', 'Level', 'Voucher', 'Left', 'Deadline', 'Why'],
          [
            for (final r in t.rows)
              [
                r.name,
                r.level,
                r.voucherCode,
                '${r.sessionsRemaining}/${r.packageSize}',
                _date(r.deadline),
                r.reason,
              ],
          ],
          widths: const [2, 0.8, 1.2, 0.7, 1.2, 2.6],
        ),
      ],
    );
  }

  // 3
  static Future<pw.Document> revenue(AdminOpsReportData d) {
    final r = d.revenue;
    final total = RevenueMonth(
      month: r.months.last.month,
      package8: r.months.fold(0, (s, m) => s + m.package8),
      package16: r.months.fold(0, (s, m) => s + m.package16),
      book: r.months.fold(0, (s, m) => s + m.book),
      other: r.months.fold(0, (s, m) => s + m.other),
      invoices: r.months.fold(0, (s, m) => s + m.invoices),
    );
    return _doc(
      'Revenue per month',
      d.generatedAt,
      landscape: true,
      [
        _h('Paid invoices, last 6 months (by payment date)'),
        _table(
          const [
            'Month',
            '8 sessions',
            '16 sessions',
            'Book',
            'Other',
            'Total',
            'Invoices'
          ],
          [
            for (final m in r.months)
              [
                m.month.label,
                rp(m.package8),
                rp(m.package16),
                rp(m.book),
                rp(m.other),
                rp(m.total),
                '${m.invoices}'
              ],
          ],
          widths: const [1, 1.2, 1.2, 1.1, 1, 1.3, 0.8],
          total: [
            '6 months',
            rp(total.package8),
            rp(total.package16),
            rp(total.book),
            rp(total.other),
            rp(total.total),
            '${total.invoices}'
          ],
        ),
        _h('Outstanding · ${r.outstanding.length} unpaid = ${rp(r.outstandingAmount)} '
            '· overdue ${r.overdue.length} = ${rp(r.overdueAmount)}'),
        _table(
          const ['Invoice', 'Student', 'Item', 'Amount', 'Due', 'Overdue'],
          [
            for (final o in r.outstanding)
              [
                o.invoiceNumber,
                o.studentName,
                o.itemLabel,
                rp(o.amount),
                _date(o.dueDate),
                o.isOverdue ? '${o.daysOverdue} days' : 'not yet',
              ],
          ],
          widths: const [1.4, 2, 1.4, 1.2, 1.1, 0.9],
        ),
      ],
    );
  }

  // 4
  static Future<pw.Document> retention(AdminOpsReportData d) {
    final r = d.retention;
    return _doc(
      'New students & retention',
      d.generatedAt,
      [
        _note(
            'Active = account active and (a class term with sessions left, or a '
            'class attended in the last 30 days). Retention = active students '
            'among those who joined more than 60 days ago.'),
        _h('Today: ${r.totalStudents} students · ${r.activeStudents} active · '
            'retention ${r.retentionPercent}% (${r.retained} of ${r.eligible})'),
        _table(
          const ['Join month', 'New students', 'Still active', 'Retention'],
          [
            for (final c in r.cohorts)
              [
                c.month.label,
                '${c.joined}',
                '${c.stillActive}',
                '${c.retentionPercent}%'
              ],
          ],
          widths: const [1.2, 1, 1, 1],
        ),
      ],
    );
  }

  // 5
  static Future<pw.Document> fillRate(AdminOpsReportData d) {
    final thisMonth = d.fillRate.last;
    return _doc(
      'Class fill rate',
      d.generatedAt,
      [
        _h('Per month (joined seats / capacity)'),
        _table(
          const [
            'Month',
            'Classes',
            'Capacity',
            'Joined',
            'Fill',
            'Empty',
            'Full'
          ],
          [
            for (final m in d.fillRate)
              [
                m.month.label,
                '${m.classes}',
                '${m.capacity}',
                '${m.joined}',
                '${m.fillPercent}%',
                '${m.empty}',
                '${m.full}'
              ],
          ],
        ),
        _h('${thisMonth.month.label} · every class'),
        _table(
          const ['Date', 'Class', 'Teacher', 'Joined', 'Fill', 'Status'],
          [
            for (final s in thisMonth.sessions)
              [
                _isoDate(s.date),
                s.title,
                s.teacherName,
                '${s.joined}/${s.capacity}',
                '${s.fillPercent}%',
                s.concluded ? 'Concluded' : 'Open',
              ],
          ],
          widths: const [1.1, 2.2, 1.5, 0.8, 0.7, 0.9],
        ),
      ],
    );
  }

  // 6
  static Future<pw.Document> teacherRecap(AdminOpsReportData d) => _doc(
        'Teacher recap per month',
        d.generatedAt,
        landscape: true,
        [
          _note('Hours and students count concluded classes only. Attendance = '
              'Hadir marks over all marks in those classes.'),
          for (final m in d.teacherRecap.reversed) ...[
            _h(m.month.label),
            _table(
              const [
                'Teacher',
                'Scheduled',
                'Concluded',
                'Hours',
                'Students taught',
                'Attendance'
              ],
              [
                for (final r in m.rows)
                  [
                    r.name,
                    '${r.scheduled}',
                    '${r.concluded}',
                    r.teachingHours.toStringAsFixed(1),
                    '${r.studentsTaught}',
                    r.marked == 0 ? '—' : '${r.attendancePercent}%',
                  ],
              ],
              widths: const [2.2, 1, 1, 0.8, 1.2, 1],
            ),
          ],
        ],
      );

  // 7
  static Future<pw.Document> progressByLevel(AdminOpsReportData d) => _doc(
        'Student progress per HSK level',
        d.generatedAt,
        [
          _note('Active students only. Done = assigned exercises with at least '
              'one submission; score = average of each student\'s best scores.'),
          _h('Summary'),
          _table(
            const [
              'Level',
              'Students',
              'Assigned',
              'Done',
              'Completion',
              'Avg score',
              'No activity'
            ],
            [
              for (final l in d.progressByLevel)
                [
                  l.level,
                  '${l.studentCount}',
                  '${l.assigned}',
                  '${l.completed}',
                  '${l.completionPercent}%',
                  l.averageScore == null ? '—' : '${l.averageScore}',
                  '${l.inactive}',
                ],
            ],
          ),
          for (final l in d.progressByLevel) ...[
            _h('${l.level} · ${l.studentCount} students'),
            _table(
              const [
                'Student',
                'Assigned',
                'Done',
                'Completion',
                'Avg score',
                'Last activity'
              ],
              [
                for (final s in l.students)
                  [
                    s.name,
                    '${s.assigned}',
                    '${s.completed}',
                    '${s.completionPercent}%',
                    s.averageScore == null ? '—' : '${s.averageScore}',
                    _date(s.lastActivity),
                  ],
              ],
              widths: const [2.4, 0.9, 0.8, 1, 0.9, 1.3],
            ),
          ],
        ],
      );

  // 8
  static Future<pw.Document> overdueHomework(AdminOpsReportData d) {
    final o = d.overdueHomework;
    return _doc(
      'Overdue homework per teacher',
      d.generatedAt,
      [
        _note(
            '${o.total} overdue of ${o.open} open assignments. Grouped by the '
            'student\'s teacher; most overdue first.'),
        for (final g in o.groups) ...[
          _h('${g.teacherName} · ${g.count} overdue · ${g.students} students'),
          _table(
            const ['Student', 'Exercise', 'Due', 'Overdue'],
            [
              for (final r in g.rows)
                [
                  r.studentName,
                  r.exerciseTitle,
                  _date(r.dueDate),
                  '${r.daysOverdue} days'
                ],
            ],
            widths: const [2, 3, 1.2, 0.9],
          ),
        ],
      ],
    );
  }
}
