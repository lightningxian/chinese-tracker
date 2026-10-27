import 'package:chinese_tracker/core/reports/admin_ops_reports_pdf.dart';
import 'package:chinese_tracker/models/app_user.dart';
import 'package:chinese_tracker/models/attendance_record.dart';
import 'package:chinese_tracker/models/class_session.dart';
import 'package:chinese_tracker/models/exercise_assignment.dart';
import 'package:chinese_tracker/models/exercise_result.dart';
import 'package:chinese_tracker/models/invoice.dart';
import 'package:chinese_tracker/models/student_class_term.dart';
import 'package:chinese_tracker/services/admin_ops_report_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every report PDF renders with real (Chinese-capable) fonts and non-trivial
/// data; a column-count mismatch or layout error would throw here.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 10, 27);
  final data = AdminOpsReportService.build(
    now: now,
    users: [
      const AppUser(uid: 't1', email: 't@x', name: '陈老师', role: 'teacher'),
      AppUser(
        uid: 's1',
        email: 's@x',
        name: 'Angeline 王',
        role: 'student',
        teacherId: 't1',
        level: 'HSK 1',
        createdAt: DateTime(2026, 6, 1),
      ),
    ],
    exercises: const [],
    classTerms: const [
      StudentClassTerm(
        id: 'a',
        studentId: 's1',
        packageSize: 8,
        sessionsRemaining: 1,
        sessionsUsed: 7,
        status: 'active',
        startDate: '2026-09-01',
        deadlineDate: '2026-10-29',
        voucherCode: 'ABC123',
      ),
    ],
    attendance: const [
      AttendanceRecord(
        id: 'r1',
        sessionId: 'c1',
        studentId: 's1',
        teacherId: 't1',
        sessionDate: '2026-10-10',
        sessionTitle: 'HSK 1',
        startMinutes: 900,
        endMinutes: 990,
        attended: true,
        joinedBy: 'student',
        attendanceStatus: 'hadir',
      ),
    ],
    sessions: const [
      ClassSession(
        id: 'c1',
        teacherId: 't1',
        sessionDate: '2026-10-10',
        sessionTitle: 'HSK 1 · 听力',
        startMinutes: 900,
        endMinutes: 990,
        capacity: 8,
        isOpen: false,
        isConcluded: true,
      ),
    ],
    invoices: [
      Invoice(
        id: 'i1',
        invoiceNumber: 'INV-1',
        studentId: 's1',
        teacherId: 't1',
        packageSize: 8,
        amount: 2450000,
        status: InvoiceStatus.paid,
        dueDate: '2026-10-05',
        studentName: 'Angeline 王',
        paidAt: DateTime(2026, 10, 2),
      ),
      const Invoice(
        id: 'i2',
        invoiceNumber: 'INV-2',
        studentId: 's1',
        teacherId: 't1',
        packageSize: 0,
        item: 'book',
        amount: 250000,
        status: InvoiceStatus.pending,
        dueDate: '2026-10-20',
        studentName: 'Angeline 王',
      ),
    ],
    assignments: [
      ExerciseAssignment(
        id: 'a1',
        exerciseId: 'ex_1',
        studentId: 's1',
        teacherId: 't1',
        dueDate: DateTime(2026, 10, 20),
      ),
    ],
    results: const [
      ExerciseResult(id: 'x', studentId: 's1', exerciseId: 'ex_9', score: 70),
    ],
  );

  final builders = {
    'attendance': AdminOpsReportsPdf.attendance,
    'termAlerts': AdminOpsReportsPdf.termAlerts,
    'revenue': AdminOpsReportsPdf.revenue,
    'retention': AdminOpsReportsPdf.retention,
    'fillRate': AdminOpsReportsPdf.fillRate,
    'teacherRecap': AdminOpsReportsPdf.teacherRecap,
    'progressByLevel': AdminOpsReportsPdf.progressByLevel,
    'overdueHomework': AdminOpsReportsPdf.overdueHomework,
  };

  for (final entry in builders.entries) {
    test('${entry.key} PDF renders', () async {
      final doc = await entry.value(data);
      final bytes = await doc.save();
      expect(bytes.length, greaterThan(1000));
    });
  }
}
