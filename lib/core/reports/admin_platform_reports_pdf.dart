import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/app_user.dart';
import '../../models/exercise_skill_category.dart';
import '../../models/student_class_term.dart';
import '../../services/admin_report_service.dart';
import '../constants/app_constants.dart';

abstract final class AdminPlatformReportsPdf {
  static String _dateLabel(DateTime? date) {
    if (date == null) return '—';
    return DateFormat('MMM d, yyyy', 'en_US').format(date);
  }

  static pw.Widget _title(String text) => pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
      );

  static pw.Widget _subtitle(String text) => pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
      );

  static pw.Widget _section(String text) => pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
      );

  static pw.Widget _cell(String text, {bool bold = false}) => pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );

  /// 1 — Full user roster (Admin / Guru / Murid).
  static Future<pw.Document> userRoster({
    required List<AppUser> users,
    required DateTime generatedAt,
  }) async {
    final doc = pw.Document();
    final sorted = [...users]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => [
          _title('${AppConstants.brandName} — User roster'),
          pw.SizedBox(height: 4),
          _subtitle(
              'Generated ${DateFormat('d MMM yyyy, HH:mm', 'en_US').format(generatedAt)}'),
          pw.SizedBox(height: 12),
          _subtitle('Total users: ${users.length}'),
          pw.SizedBox(height: 16),
          if (sorted.isEmpty)
            pw.Text('No users in Firestore yet.')
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.2),
                1: const pw.FlexColumnWidth(2.2),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1.2),
                4: const pw.FlexColumnWidth(0.8),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _cell('Name', bold: true),
                    _cell('Email', bold: true),
                    _cell('Role', bold: true),
                    _cell('Joined', bold: true),
                    _cell('Status', bold: true),
                  ],
                ),
                ...sorted.map(
                  (user) => pw.TableRow(
                    children: [
                      _cell(user.name),
                      _cell(user.email),
                      _cell(user.roleDisplayLabel),
                      _cell(_dateLabel(user.createdAt)),
                      _cell(user.active ? 'Active' : 'Inactive'),
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

  /// 2 — Registration & HSK growth.
  static Future<pw.Document> registrationGrowth({
    required AdminReportData report,
    required DateTime generatedAt,
  }) async {
    final doc = pw.Document();
    final maxMonth = report.newStudentsByMonth.fold<int>(
      1,
      (max, m) => m.count > max ? m.count : max,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _title('${AppConstants.brandName} — Monthly registration & growth'),
          pw.SizedBox(height: 4),
          _subtitle(
              'Generated ${DateFormat('d MMM yyyy, HH:mm', 'en_US').format(generatedAt)}'),
          pw.SizedBox(height: 16),
          _section('Summary'),
          pw.SizedBox(height: 8),
          pw.Text('Total murid (all): ${report.totalMurid}'),
          pw.Text('Active murid: ${report.activeStudents}'),
          pw.Text(
              'Guru: ${report.totalTeachers} · Admin: ${report.totalAdmins}'),
          pw.SizedBox(height: 20),
          _section('New murid registrations / month'),
          pw.SizedBox(height: 10),
          ...report.newStudentsByMonth.map((month) {
            final barWidth = month.count / maxMonth;
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Row(
                children: [
                  pw.SizedBox(
                    width: 36,
                    child: pw.Text(month.label,
                        style: const pw.TextStyle(fontSize: 10)),
                  ),
                  pw.Expanded(
                    child: pw.Container(
                      height: 14,
                      alignment: pw.Alignment.centerLeft,
                      child: pw.Container(
                        width: 200 * barWidth,
                        height: 14,
                        color: PdfColors.teal,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Text('${month.count}',
                      style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            );
          }),
          pw.SizedBox(height: 20),
          _section('Students by HSK band'),
          pw.SizedBox(height: 10),
          ...report.hskBands.map(
            (band) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(band.label, style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    '${band.count}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    return doc;
  }

  /// 3 — Voucher & session packages.
  static Future<pw.Document> voucherSessions({
    required List<StudentClassTerm> terms,
    required Map<String, AppUser> usersById,
    required List<MonthlyCount> vouchersIssuedByMonth,
    required DateTime generatedAt,
  }) async {
    final doc = pw.Document();
    final sorted = [...terms]
      ..sort((a, b) => b.sessionsRemaining.compareTo(a.sessionsRemaining));
    final maxMonth = vouchersIssuedByMonth.fold<int>(
      1,
      (max, m) => m.count > max ? m.count : max,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => [
          _title('${AppConstants.brandName} — Vouchers & monthly packages'),
          pw.SizedBox(height: 4),
          _subtitle(
              'Generated ${DateFormat('d MMM yyyy, HH:mm', 'en_US').format(generatedAt)}'),
          pw.SizedBox(height: 12),
          _subtitle('Packages tracked: ${terms.length}'),
          pw.SizedBox(height: 16),
          _section('Vouchers issued / month'),
          pw.SizedBox(height: 10),
          ...vouchersIssuedByMonth.map((month) {
            final barWidth = month.count / maxMonth;
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Row(
                children: [
                  pw.SizedBox(
                    width: 56,
                    child: pw.Text(
                      month.label,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Container(
                      height: 14,
                      alignment: pw.Alignment.centerLeft,
                      child: pw.Container(
                        width: 200 * barWidth,
                        height: 14,
                        color: PdfColors.teal,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Text('${month.count}',
                      style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            );
          }),
          pw.SizedBox(height: 16),
          _section('All packages'),
          pw.SizedBox(height: 10),
          if (sorted.isEmpty)
            pw.Text('No voucher packages issued yet.')
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.5),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(0.8),
                4: const pw.FlexColumnWidth(0.8),
                5: const pw.FlexColumnWidth(1),
                6: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _cell('Voucher code', bold: true),
                    _cell('Murid', bold: true),
                    _cell('Package', bold: true),
                    _cell('Left', bold: true),
                    _cell('Used', bold: true),
                    _cell('Status', bold: true),
                    _cell('Valid until', bold: true),
                  ],
                ),
                ...sorted.map((term) {
                  final student = usersById[term.studentId];
                  return pw.TableRow(
                    children: [
                      _cell(term.voucherCode ?? '—'),
                      _cell(student?.name ?? term.studentId),
                      _cell('${term.packageSize} sessions'),
                      _cell('${term.sessionsRemaining}'),
                      _cell('${term.sessionsUsed}'),
                      _cell(term.voucherStatusLabel),
                      _cell(term.deadlineDate),
                    ],
                  );
                }),
              ],
            ),
        ],
      ),
    );
    return doc;
  }

  /// 4 — Worksheet / exercise inventory by HSK and skill.
  static Future<pw.Document> worksheetInventory({
    required AdminReportData report,
    required DateTime generatedAt,
  }) async {
    final doc = pw.Document();
    final skillHeaders =
        ExerciseSkillCategory.values.map((category) => category.label).toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => [
          _title('${AppConstants.brandName} — Worksheet inventory'),
          pw.SizedBox(height: 4),
          _subtitle(
            'Generated ${DateFormat('d MMM yyyy, HH:mm', 'en_US').format(generatedAt)}',
          ),
          pw.SizedBox(height: 12),
          _subtitle(
            'Total worksheets produced: ${report.totalWorksheets} '
            '(${report.totalExercises} published · '
            '${report.totalWorksheets - report.totalExercises} draft)',
          ),
          pw.SizedBox(height: 16),
          if (report.worksheetInventory.isEmpty)
            pw.Text('No worksheets created yet.')
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.1),
                1: const pw.FlexColumnWidth(0.7),
                for (var i = 0; i < skillHeaders.length; i++)
                  i + 2: const pw.FlexColumnWidth(1),
                2 + skillHeaders.length: const pw.FlexColumnWidth(0.8),
                3 + skillHeaders.length: const pw.FlexColumnWidth(0.8),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _cell('HSK level', bold: true),
                    _cell('Total', bold: true),
                    for (final header in skillHeaders)
                      _cell(header, bold: true),
                    _cell('Published', bold: true),
                    _cell('Draft', bold: true),
                  ],
                ),
                ...report.worksheetInventory.map(
                  (row) => pw.TableRow(
                    children: [
                      _cell(row.hskLevel),
                      _cell('${row.total}'),
                      for (final skill in row.skills) _cell('${skill.count}'),
                      _cell('${row.published}'),
                      _cell('${row.draft}'),
                    ],
                  ),
                ),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _cell('All levels', bold: true),
                    _cell('${report.totalWorksheets}', bold: true),
                    for (final category in ExerciseSkillCategory.values)
                      _cell(
                        '${report.worksheetInventory.fold<int>(0, (sum, row) => sum + row.skills[category.index].count)}',
                        bold: true,
                      ),
                    _cell('${report.totalExercises}', bold: true),
                    _cell(
                      '${report.totalWorksheets - report.totalExercises}',
                      bold: true,
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
    return doc;
  }
}
