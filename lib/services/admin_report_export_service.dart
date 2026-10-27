import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/reports/admin_ops_reports_pdf.dart';
import '../core/reports/admin_platform_reports_pdf.dart';
import 'admin_ops_report_service.dart';
import 'admin_report_service.dart';
import 'firestore_service.dart';

enum AdminExportReport {
  attendanceMonthly('attendance_monthly'),
  termBalanceAlerts('term_balance_alerts'),
  revenueMonthly('revenue_monthly'),
  studentRetention('students_retention'),
  classFillRate('class_fill_rate'),
  teacherRecap('teacher_recap'),
  progressByLevel('progress_by_level'),
  overdueHomework('overdue_homework'),
  userRoster('user_roster'),
  registrationGrowth('monthly_registration'),
  voucherSessions('voucher_sessions'),
  worksheetInventory('worksheet_inventory');

  const AdminExportReport(this.fileStem);

  final String fileStem;
}

class AdminReportExportService {
  AdminReportExportService({required FirestoreService firestore})
      : _firestore = firestore;

  final FirestoreService _firestore;

  Future<AdminReportData> _buildReport() async {
    final users = await _firestore.watchAllUsers().first;
    final exercises = await _firestore.watchAllExercises().first;
    final classTerms = await _firestore.watchAllClassTerms().first;

    return AdminReportService.build(
      users: users,
      exercises: exercises,
      classTerms: classTerms,
    );
  }

  Future<AdminOpsReportData> _buildOpsReport() async {
    final f = _firestore;
    return AdminOpsReportService.build(
      users: await f.watchAllUsers().first,
      exercises: await f.watchAllExercises().first,
      classTerms: await f.watchAllClassTerms().first,
      attendance: await f.watchAllAttendance().first,
      sessions: await f.watchAllClassSessions().first,
      invoices: await f.watchAllInvoices().first,
      assignments: await f.watchAllExerciseAssignments().first,
      results: await f.watchAllExerciseResults().first,
    );
  }

  Future<void> exportPdf(AdminExportReport type) async {
    final doc = await _document(type, DateTime.now());
    await Printing.layoutPdf(
      onLayout: (_) async => doc.save(),
      name: '${type.fileStem}_${_dateStamp()}.pdf',
    );
  }

  Future<pw.Document> _document(
    AdminExportReport type,
    DateTime generatedAt,
  ) async {
    switch (type) {
      case AdminExportReport.attendanceMonthly:
        return AdminOpsReportsPdf.attendance(await _buildOpsReport());
      case AdminExportReport.termBalanceAlerts:
        return AdminOpsReportsPdf.termAlerts(await _buildOpsReport());
      case AdminExportReport.revenueMonthly:
        return AdminOpsReportsPdf.revenue(await _buildOpsReport());
      case AdminExportReport.studentRetention:
        return AdminOpsReportsPdf.retention(await _buildOpsReport());
      case AdminExportReport.classFillRate:
        return AdminOpsReportsPdf.fillRate(await _buildOpsReport());
      case AdminExportReport.teacherRecap:
        return AdminOpsReportsPdf.teacherRecap(await _buildOpsReport());
      case AdminExportReport.progressByLevel:
        return AdminOpsReportsPdf.progressByLevel(await _buildOpsReport());
      case AdminExportReport.overdueHomework:
        return AdminOpsReportsPdf.overdueHomework(await _buildOpsReport());
      case AdminExportReport.userRoster:
        return AdminPlatformReportsPdf.userRoster(
          users: await _firestore.watchAllUsers().first,
          generatedAt: generatedAt,
        );
      case AdminExportReport.registrationGrowth:
        return AdminPlatformReportsPdf.registrationGrowth(
          report: await _buildReport(),
          generatedAt: generatedAt,
        );
      case AdminExportReport.voucherSessions:
        final users = await _firestore.watchAllUsers().first;
        final report = await _buildReport();
        return AdminPlatformReportsPdf.voucherSessions(
          terms: await _firestore.watchAllClassTerms().first,
          usersById: {for (final u in users) u.uid: u},
          vouchersIssuedByMonth: report.vouchersIssuedByMonth,
          generatedAt: generatedAt,
        );
      case AdminExportReport.worksheetInventory:
        return AdminPlatformReportsPdf.worksheetInventory(
          report: await _buildReport(),
          generatedAt: generatedAt,
        );
    }
  }

  String _dateStamp() => DateTime.now().toIso8601String().substring(0, 10);
}
