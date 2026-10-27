import 'package:chinese_tracker/models/app_user.dart';
import 'package:chinese_tracker/models/attendance_record.dart';
import 'package:chinese_tracker/models/class_session.dart';
import 'package:chinese_tracker/models/exercise_assignment.dart';
import 'package:chinese_tracker/models/exercise_result.dart';
import 'package:chinese_tracker/models/invoice.dart';
import 'package:chinese_tracker/models/student_class_term.dart';
import 'package:chinese_tracker/services/admin_ops_report_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 27, 10);

  const teacher = AppUser(
    uid: 't1',
    email: 'andrea@test',
    name: 'Bu Andrea',
    role: 'teacher',
  );
  final s1 = AppUser(
    uid: 's1',
    email: 's1@test',
    name: 'Angeline',
    role: 'student',
    teacherId: 't1',
    level: 'HSK 1',
    createdAt: DateTime(2026, 7, 1),
  );
  final s2 = AppUser(
    uid: 's2',
    email: 's2@test',
    name: 'Budi',
    role: 'student',
    teacherId: 't1',
    level: 'HSK 2',
    createdAt: DateTime(2026, 10, 5),
  );

  AttendanceRecord rec(
    String id,
    String student,
    String session,
    String date, {
    String? status,
    bool attended = false,
  }) =>
      AttendanceRecord(
        id: id,
        sessionId: session,
        studentId: student,
        teacherId: 't1',
        sessionDate: date,
        sessionTitle: 'Class',
        startMinutes: 15 * 60,
        endMinutes: 16 * 60 + 30,
        attended: attended,
        joinedBy: 'student',
        attendanceStatus: status,
      );

  ClassSession session(String id, String date, {bool concluded = true}) =>
      ClassSession(
        id: id,
        teacherId: 't1',
        sessionDate: date,
        sessionTitle: 'Class $id',
        startMinutes: 15 * 60,
        endMinutes: 16 * 60 + 30,
        capacity: 10,
        isOpen: !concluded,
        isConcluded: concluded,
      );

  StudentClassTerm term(String id, String student, int left, String deadline) =>
      StudentClassTerm(
        id: id,
        studentId: student,
        packageSize: 8,
        sessionsRemaining: left,
        sessionsUsed: 8 - left,
        status: 'active',
        startDate: '2026-09-01',
        deadlineDate: deadline,
        voucherCode: 'V-$id',
      );

  Invoice invoice(
    String id,
    int amount, {
    int packageSize = 8,
    String item = 'package',
    InvoiceStatus status = InvoiceStatus.paid,
    DateTime? paidAt,
    String dueDate = '2026-11-05',
  }) =>
      Invoice(
        id: id,
        invoiceNumber: 'INV-$id',
        studentId: 's1',
        teacherId: 't1',
        packageSize: packageSize,
        item: item,
        amount: amount,
        status: status,
        dueDate: dueDate,
        studentName: 'Angeline',
        paidAt: paidAt,
      );

  final data = AdminOpsReportService.build(
    now: now,
    users: [teacher, s1, s2],
    exercises: const [],
    classTerms: [
      term('a', 's1', 2, '2026-11-30'),
      term('b', 's2', 5, '2026-10-30'),
      term('c', 's3', 3, '2026-10-20'),
    ],
    attendance: [
      rec('r1', 's1', 'c1', '2026-10-10', status: 'hadir'),
      rec('r2', 's1', 'c2', '2026-10-12', status: 'izin'),
      rec('r3', 's2', 'c1', '2026-10-10'),
      rec('r4', 's2', 'c3', '2026-10-30'),
    ],
    sessions: [
      session('c1', '2026-10-10'),
      session('c2', '2026-10-12'),
      session('c3', '2026-10-30', concluded: false),
    ],
    invoices: [
      invoice('1', 2450000, paidAt: DateTime(2026, 10, 3)),
      invoice('2', 250000, item: 'book', packageSize: 0, paidAt: DateTime(2026, 10, 15)),
      invoice('3', 3950000, packageSize: 16, status: InvoiceStatus.pending, dueDate: '2026-10-20'),
      invoice('4', 2450000, status: InvoiceStatus.pending),
    ],
    assignments: [
      ExerciseAssignment(id: 'a1', exerciseId: 'ex_1', studentId: 's1', teacherId: 't1', dueDate: DateTime(2026, 10, 20)),
      ExerciseAssignment(id: 'a2', exerciseId: 'ex_2', studentId: 's1', teacherId: 't1', dueDate: DateTime(2026, 10, 20)),
      const ExerciseAssignment(id: 'a3', exerciseId: 'ex_1', studentId: 's2', teacherId: 't1'),
    ],
    results: [
      ExerciseResult(id: 'x1', studentId: 's1', exerciseId: 'ex_2', score: 60, submittedAt: DateTime(2026, 10, 18)),
      ExerciseResult(id: 'x2', studentId: 's1', exerciseId: 'ex_2', score: 80, submittedAt: DateTime(2026, 10, 21)),
    ],
  );

  test('1. attendance per student this month (open classes skipped)', () {
    final m = data.attendance.last;
    expect(m.month.label, 'Oct 2026');
    final byId = {for (final r in m.rows) r.studentId: r};
    expect(byId['s1']!.hadir, 1);
    expect(byId['s1']!.izin, 1);
    expect(byId['s1']!.presentPercent, 50);
    expect(byId['s2']!.alpa, 1); // concluded class, no mark → alpa
    expect(m.total, 3); // the open class (c3) is not counted
    expect(m.presentPercent, 33);
  });

  test('2. term balance alerts, most urgent first', () {
    final t = data.termAlerts;
    expect(t.activeTerms, 3);
    expect(t.count(TermAlertKind.lowBalance), 1);
    expect(t.count(TermAlertKind.expiringSoon), 1);
    expect(t.count(TermAlertKind.expiredWithBalance), 1);
    expect(t.rows.first.studentId, 's3');
    expect(t.rows.first.daysLeft, -7);
  });

  test('3. revenue by item and outstanding invoices', () {
    final r = data.revenue;
    expect(r.thisMonth.package8, 2450000);
    expect(r.thisMonth.book, 250000);
    expect(r.thisMonth.total, 2700000);
    expect(r.thisMonth.invoices, 2);
    expect(r.outstanding.length, 2);
    expect(r.outstandingAmount, 6400000);
    expect(r.overdue.length, 1);
    expect(r.overdue.first.daysOverdue, 7);
  });

  test('4. new students and retention', () {
    final r = data.retention;
    expect(r.newThisMonth, 1);
    expect(r.activeStudents, 2);
    expect(r.eligible, 1); // only s1 joined more than 60 days ago
    expect(r.retained, 1);
    expect(r.retentionPercent, 100);
  });

  test('5. class fill rate this month', () {
    final m = data.fillRate.last;
    expect(m.classes, 3);
    expect(m.joined, 4);
    expect(m.capacity, 30);
    expect(m.fillPercent, 13);
    expect(m.empty, 0);
  });

  test('6. teacher recap this month', () {
    final row = data.teacherRecap.last.rows.single;
    expect(row.name, 'Bu Andrea');
    expect(row.scheduled, 3);
    expect(row.concluded, 2);
    expect(row.teachingHours, 3.0);
    expect(row.studentsTaught, 1);
    expect(row.attendancePercent, 33);
  });

  test('7. progress per HSK level uses best score per exercise', () {
    final byLevel = {for (final l in data.progressByLevel) l.level: l};
    final hsk1 = byLevel['HSK 1']!.students.single;
    expect(hsk1.assigned, 2);
    expect(hsk1.completed, 1);
    expect(hsk1.averageScore, 80);
    final hsk2 = byLevel['HSK 2']!;
    expect(hsk2.completionPercent, 0);
    expect(hsk2.averageScore, isNull);
    expect(hsk2.inactive, 1);
  });

  test('8. overdue homework grouped by the student\'s teacher', () {
    final o = data.overdueHomework;
    expect(o.open, 2);
    expect(o.total, 1);
    final g = o.groups.single;
    expect(g.teacherName, 'Bu Andrea');
    expect(g.rows.single.exerciseTitle, 'ex_1');
    expect(g.rows.single.daysOverdue, 7);
  });
}
