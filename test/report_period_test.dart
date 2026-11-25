// Build 9B (supervisor 2026-11-25): the centre report over a period. The
// three months below are what `buildReport` (functions/reports.js) writes
// for the fixture in functions/test_reports.js; the merge must give what
// `mergeReports` gives there (and one build over the three months).
import 'dart:convert';

import 'package:chinese_tracker/features/admin/monthly_report_card.dart';
import 'package:chinese_tracker/services/admin_ops_report_service.dart';
import 'package:flutter_test/flutter_test.dart';

const _perMonth = '''
[{"month":"202603","newStudents":1,"revenue":800000,"paidInvoices":1,"activeStudents":1,"levels":{"HSK 1":2,"HSK 2":1,"HSK 3":1},"attendance":{"hadir":3,"izin":0,"alpa":0,"rate":100},"teachers":[{"teacherId":"t1","teacherName":"Andrea","held":3,"hours":4.5}],"teachingHours":4.5},
 {"month":"202604","newStudents":1,"revenue":1500000,"paidInvoices":1,"activeStudents":1,"levels":{"HSK 1":2,"HSK 2":1,"HSK 3":1},"attendance":{"hadir":0,"izin":1,"alpa":1,"rate":0},"teachers":[{"teacherId":"t1","teacherName":"Andrea","held":1,"hours":1.5},{"teacherId":"t2","teacherName":"Budi","held":2,"hours":3}],"teachingHours":4.5},
 {"month":"202605","newStudents":1,"revenue":750000,"paidInvoices":1,"activeStudents":2,"levels":{"HSK 1":3,"HSK 2":1,"HSK 3":1},"attendance":{"hadir":1,"izin":0,"alpa":2,"rate":33.3},"teachers":[{"teacherId":"t2","teacherName":"Budi","held":1,"hours":1.5}],"teachingHours":1.5}]
''';

void main() {
  final months = [
    for (final m in jsonDecode(_perMonth) as List)
      MonthlyReport.fromMap(Map<String, dynamic>.from(m as Map)),
  ];

  test('the merge sums counts and money, as mergeReports does', () {
    final t = MonthlyReport.merge(months)!;
    expect(t.month, '202603-202605');
    expect(t.newStudents, 3);
    expect(t.revenue, 3050000);
    expect(t.paidInvoices, 3);
    expect([t.hadir, t.izin, t.alpa], [4, 1, 3]);
    expect(t.teachingHours, 10.5);
    expect(t.teachers.map((x) => (x.name, x.held, x.hours)),
        [('Andrea', 4, 6.0), ('Budi', 3, 4.5)]);
  });

  test('the rate is recomputed from the sums, never averaged', () {
    final t = MonthlyReport.merge(months)!;
    // The months' rates are 100, 0 and 33.3; their average (44.4) is wrong.
    expect(t.attendanceRate, 57.1);
  });

  test('end-of-period figures come from the last month', () {
    final t = MonthlyReport.merge(months)!;
    expect(t.activeStudents, 2);
    expect(t.levels['HSK 1'], 3);
  });

  test('one month merges to itself; no month gives nothing', () {
    final one = MonthlyReport.merge([months[1]])!;
    expect(one.revenue, 1500000);
    expect(one.attendanceRate, 0);
    expect(MonthlyReport.merge(const []), isNull);
  });

  test('report months follow the period, March to December', () {
    final ms = ReportMonth.range(DateTime(2026, 3), DateTime(2026, 12));
    expect(ms.length, 10);
    expect(ms.first, const ReportMonth(2026, 3));
    expect(ReportMonth.periodLabelEn(ms), 'March 2026 – December 2026');
    expect(ReportMonth.periodLabelEn([const ReportMonth(2026, 3)]), 'March 2026');
  });
}
