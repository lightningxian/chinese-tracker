import 'package:printing/printing.dart';

import '../core/reports/admin_platform_reports_pdf.dart';
import 'admin_report_service.dart';
import 'firestore_service.dart';

enum AdminExportReport {
  userRoster,
  registrationGrowth,
  voucherSessions,
  worksheetInventory,
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

  Future<void> exportPdf(AdminExportReport type) async {
    final generatedAt = DateTime.now();
    final users = await _firestore.watchAllUsers().first;

    switch (type) {
      case AdminExportReport.userRoster:
        final doc = await AdminPlatformReportsPdf.userRoster(
          users: users,
          generatedAt: generatedAt,
        );
        await Printing.layoutPdf(
          onLayout: (_) async => doc.save(),
          name: 'user_roster_${_dateStamp()}.pdf',
        );
      case AdminExportReport.registrationGrowth:
        final report = await _buildReport();
        final doc = await AdminPlatformReportsPdf.registrationGrowth(
          report: report,
          generatedAt: generatedAt,
        );
        await Printing.layoutPdf(
          onLayout: (_) async => doc.save(),
          name: 'monthly_registration_${_dateStamp()}.pdf',
        );
      case AdminExportReport.voucherSessions:
        final terms = await _firestore.watchAllClassTerms().first;
        final report = await _buildReport();
        final usersById = {for (final u in users) u.uid: u};
        final doc = await AdminPlatformReportsPdf.voucherSessions(
          terms: terms,
          usersById: usersById,
          vouchersIssuedByMonth: report.vouchersIssuedByMonth,
          generatedAt: generatedAt,
        );
        await Printing.layoutPdf(
          onLayout: (_) async => doc.save(),
          name: 'voucher_sessions_${_dateStamp()}.pdf',
        );
      case AdminExportReport.worksheetInventory:
        final report = await _buildReport();
        final doc = await AdminPlatformReportsPdf.worksheetInventory(
          report: report,
          generatedAt: generatedAt,
        );
        await Printing.layoutPdf(
          onLayout: (_) async => doc.save(),
          name: 'worksheet_inventory_${_dateStamp()}.pdf',
        );
    }
  }

  String _dateStamp() => DateTime.now().toIso8601String().substring(0, 10);
}
