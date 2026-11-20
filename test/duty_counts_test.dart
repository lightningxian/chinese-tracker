import 'package:chinese_tracker/features/admin/admin_duty_cards.dart';
import 'package:chinese_tracker/features/admin/monthly_report_card.dart';
import 'package:chinese_tracker/models/app_user.dart';
import 'package:chinese_tracker/models/class_session.dart';
import 'package:chinese_tracker/models/progress_summary.dart';
import 'package:chinese_tracker/services/timetable_service.dart';
import 'package:flutter_test/flutter_test.dart';

Schedule _schedule(String id, {String status = '', bool active = true}) => Schedule(
      id: id,
      className: 'A',
      weekday: 1,
      startMinutes: 960,
      endMinutes: 1050,
      room: 'Main',
      teacherId: 't',
      teacherName: 'T',
      capacity: 8,
      level: '',
      validFrom: '',
      validTo: '',
      active: active,
      status: status,
    );

ClassSession _session(String date,
        {String status = 'scheduled', bool late = false, bool unclosed = false}) =>
    ClassSession(
      id: date,
      teacherId: 't',
      sessionDate: date,
      sessionTitle: 'A',
      startMinutes: 960,
      endMinutes: 1050,
      capacity: 8,
      isOpen: true,
      status: status,
      lateCheckIn: late,
      unclosed: unclosed,
    );

void main() {
  test('Build 8: the six dashboard counts', () {
    final now = DateTime(2026, 11, 21, 10);
    final c = DutyCounts.compute(
      users: const [
        AppUser(uid: 'p1', email: '', name: 'P', role: 'student', status: 'pending'),
        AppUser(uid: 'p2', email: '', name: 'P', role: 'student', status: 'pending'),
        AppUser(uid: 's1', email: '', name: 'S', role: 'student'),
        AppUser(uid: 't1', email: '', name: 'T', role: 'teacher'),
      ],
      schedules: [
        _schedule('a'),
        _schedule('b', status: 'confirmed'),
        _schedule('c', status: 'unconfirmed'),
        _schedule('d', active: false),
      ],
      sessions: [
        _session('2026-11-21', late: true),
        _session('2026-11-21'),
        _session('2026-11-21', status: 'cancelled', late: true),
        _session('2026-11-18', late: true, unclosed: true),
        _session('2026-11-10', late: true),
        _session('2026-11-19', status: 'done', unclosed: true),
      ],
      summaries: [
        ProgressSummary.fromMap('u1', const {'status': 'attention'}),
        ProgressSummary.fromMap('u2', const {'status': 'follow_up'}),
        ProgressSummary.fromMap('u3', const {'status': 'good'}),
      ],
      now: now,
    );
    expect(c.pendingRegistrations, 2);
    expect(c.unconfirmedSchedules, 2, reason: 'active and not confirmed');
    expect(c.lateToday, 1, reason: 'a cancelled session is not counted');
    expect(c.lateWeek, 2, reason: 'today and the 18th; the 10th is older');
    expect(c.unclosed, 1, reason: 'a done session is not unclosed');
    expect(c.needingAttention, 2);
    expect(c.todaySessions, 2);
  });

  test('Build 8: the monthly report reads the function map', () {
    final r = MonthlyReport.fromMap({
      'month': '202611',
      'newStudents': 3,
      'revenue': 1550000,
      'paidInvoices': 2,
      'activeStudents': 3,
      'levels': {'HSK 1': 2, 'HSK 3': 1},
      'attendance': {'hadir': 1, 'izin': 1, 'alpa': 1, 'rate': 50},
      'teachers': [
        {'teacherId': 't1', 'teacherName': 'Andrea', 'held': 2, 'hours': 3},
      ],
      'teachingHours': 3,
    });
    final rows = r.rows(
      newStudentsLabel: 'New',
      revenueLabel: 'Revenue',
      activeLabel: 'Active',
      attendanceLabel: 'Attendance',
      hoursLabel: 'Hours',
      levelLabel: 'Level',
      teacherLabel: 'Teacher',
    );
    expect(rows.first, ['New', '3']);
    expect(rows[3][1], startsWith('50.0%'));
    expect(rows.where((x) => x[0].startsWith('Level')).length, 2);
    expect(rows.last, ['Teacher Andrea', '2 · 3.0 h']);
  });
}
