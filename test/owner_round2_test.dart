import 'package:chinese_tracker/features/announcements/announcements.dart';
import 'package:chinese_tracker/models/attendance_record.dart';
import 'package:chinese_tracker/models/board_check.dart';
import 'package:chinese_tracker/services/timetable_service.dart';
import 'package:flutter_test/flutter_test.dart';

Announcement _a(String audience, String toDate) => Announcement(
    id: 'a', title: 'T', body: '', audience: audience, kind: 'info', date: '', toDate: toDate);

void main() {
  group('Owner 2026-11-23 (second round)', () {
    test('attendance board: present not signed, signed not present, not booked', () {
      final d = BoardCheck.differences(
        statusById: {
          'a': AttendanceRecord.hadir,
          'b': AttendanceRecord.hadir,
          'c': AttendanceRecord.alpa,
          'e': AttendanceRecord.izin,
        },
        board: {'a': true, 'c': true},
        nameById: {'a': 'Ani', 'b': 'Budi', 'c': 'Cici', 'e': 'Eko'},
        extras: 'Dodi, \nFani,',
      );
      expect(d.presentNotSigned, ['Budi']);
      expect(d.signedNotPresent, ['Cici']);
      expect(d.notBooked, ['Dodi', 'Fani']);
      final same = BoardCheck.differences(
          statusById: {'a': AttendanceRecord.hadir},
          board: {'a': true},
          nameById: const {},
          extras: ' ');
      expect(same.presentNotSigned.length + same.signedNotPresent.length + same.notBooked.length, 0);
    });

    test('timetable rules: defaults, readiness off, limits', () {
      final r = SchedulingRules.fromMap(const {});
      expect(r.minGapMinutes, 0);
      expect(r.minStudents, 0, reason: 'off until the admin sets it');
      expect(r.minStudentsHours, 3);
      expect(r.teacherReadiness, isFalse);
      expect(SchedulingRules.fromMap(const {'teacherReadiness': true}).teacherReadiness, isTrue);
      expect(SchedulingRules.invalid(gap: 0, hours: 20, minStudents: 3, checkHours: 3), isNull);
      expect(SchedulingRules.invalid(gap: -1, hours: 20, minStudents: 3, checkHours: 3), 'gap');
      expect(SchedulingRules.invalid(gap: 0, hours: 0, minStudents: 3, checkHours: 3), 'hours');
      expect(SchedulingRules.invalid(gap: 0, hours: 20, minStudents: 31, checkHours: 3), 'min');
      expect(SchedulingRules.invalid(gap: 0, hours: 20, minStudents: 0, checkHours: 0), 'check');
      expect(r.toMap()['minStudents'], 0);
    });

    test('announcements: audience and the last day', () {
      expect(_a('all', '2027-01-01').shownTo('teacher'), isTrue);
      expect(_a('students', '2027-01-01').shownTo('parent'), isTrue);
      expect(_a('students', '2027-01-01').shownTo('teacher'), isFalse);
      expect(_a('teachers', '2027-01-01').shownTo('student'), isFalse);
      expect(_a('teachers', '2027-01-01').shownTo('admin'), isTrue);
      expect(_a('all', '2027-01-01').activeOn('2027-01-01'), isTrue);
      expect(_a('all', '2027-01-01').activeOn('2027-01-02'), isFalse);
    });

    test('a holiday reads its decision', () {
      expect(Holiday.fromMap('2027-01-01', const {'name': 'Tahun Baru', 'decision': 'closed'}).closed,
          isTrue);
      final h = Holiday.fromMap('2027-03-10', const {'name': 'Idulfitri'});
      expect(h.date, '2027-03-10');
      expect(h.kind, 'national');
      expect(h.closed, isFalse);
    });
  });
}
