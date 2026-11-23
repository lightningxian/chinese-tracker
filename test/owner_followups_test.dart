import 'package:chinese_tracker/core/reports/day_sheet_pdf.dart';
import 'package:chinese_tracker/models/attendance_record.dart';
import 'package:chinese_tracker/models/class_session.dart';
import 'package:chinese_tracker/services/timetable_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

String _day(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
int _minutes(DateTime d) => d.hour * 60 + d.minute;

ClassSession _session(DateTime start, {String status = 'scheduled'}) => ClassSession(
      id: 's',
      teacherId: 't',
      sessionDate: _day(start),
      sessionTitle: 'A',
      startMinutes: _minutes(start),
      endMinutes: _minutes(start) + 90,
      capacity: 8,
      isOpen: true,
      isConcluded: false,
      status: status,
      generated: true,
    );

AttendanceRecord _rec(String name, {bool booked = true, String status = ''}) => AttendanceRecord(
      id: name,
      sessionId: 's',
      studentId: name,
      teacherId: 't',
      sessionDate: '2099-01-05',
      sessionTitle: 'A',
      startMinutes: 960,
      endMinutes: 1050,
      attended: false,
      joinedBy: 'student',
      booked: booked,
      status: status,
      studentName: name,
    );

BookableSession _bookable(DateTime start, {int minutes = 90, String status = 'scheduled'}) =>
    BookableSession(
      id: 'b',
      title: 'A',
      date: _day(start),
      startMinutes: _minutes(start),
      endMinutes: _minutes(start) + minutes,
      room: 'Main',
      teacherName: 'T',
      level: '',
      capacity: 8,
      bookedCount: 1,
      status: status,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Owner 2026-11-23: sessions start by themselves', () {
    test('a scheduled session past its start reads ongoing', () {
      final now = DateTime.now();
      // Stay inside one day so the minutes do not wrap past midnight.
      final base = DateTime(now.year, now.month, now.day, 12);
      final earlier = base.isBefore(now) ? base : base.subtract(const Duration(days: 1));
      expect(_session(earlier).lifeStatus, 'ongoing');
      expect(_session(DateTime(now.year + 1, 1, 5, 10)).lifeStatus, 'scheduled');
      expect(_session(earlier, status: 'cancelled').lifeStatus, 'cancelled');
      expect(_session(earlier, status: 'done').lifeStatus, 'done');
      expect(_session(earlier, status: 'needs_teacher').lifeStatus, 'needs_teacher');
    });

    test('a class going on can be joined until it ends', () {
      final now = DateTime.now();
      final start = now.subtract(const Duration(minutes: 30));
      if (start.day == now.day) {
        expect(_bookable(start).isGoingOn, isTrue);
        expect(_bookable(start).isOver, isFalse);
        expect(_bookable(start, minutes: 20).isOver, isTrue, reason: 'ended 10 minutes ago');
      }
      final next = DateTime(now.year + 1, 1, 5, 10);
      expect(_bookable(next).isGoingOn, isFalse);
      expect(_bookable(next).isOver, isFalse);
      expect(_bookable(next, status: 'cancelled').isOver, isTrue);
    });
  });

  group('Day sheet', () {
    test('booked students by name, then blank rows; cancelled left out', () {
      final rows = DaySheetPdf.rowsFor([
        _rec('Budi'),
        _rec('Ani'),
        _rec('Cici', status: 'cancelled'),
        _rec('Dodi', booked: false),
      ]);
      expect(rows.map((r) => r[1]).toList(), ['Ani', 'Budi', '', '', '']);
      expect(rows.map((r) => r[0]).toList(), ['1', '2', '3', '4', '5']);
    });

    test('the PDF builds with an empty day and with a class', () async {
      final empty = await DaySheetPdf.build(
          teacherName: 'T', day: DateTime(2026, 11, 23), classes: const []);
      expect((await empty.save()).isNotEmpty, isTrue);
      final one = await DaySheetPdf.build(
          teacherName: 'T',
          day: DateTime(2026, 11, 23),
          classes: [(session: _session(DateTime(2099, 1, 5, 16)), records: [_rec('Ani')])]);
      expect((await one.save()).isNotEmpty, isTrue);
    });
  });
}
