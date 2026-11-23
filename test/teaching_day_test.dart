import 'package:chinese_tracker/models/attendance_record.dart';
import 'package:chinese_tracker/models/class_session.dart';
import 'package:chinese_tracker/services/teaching_day_service.dart';
import 'package:flutter_test/flutter_test.dart';

ClassSession _session({String status = '', bool concluded = false}) => ClassSession(
      id: 's',
      teacherId: 't',
      sessionDate: '2099-01-05',
      sessionTitle: 'A',
      startMinutes: 960,
      endMinutes: 1050,
      capacity: 8,
      isOpen: true,
      isConcluded: concluded,
      status: status,
    );

AttendanceRecord _record({bool attended = false, bool booked = false, String status = ''}) =>
    AttendanceRecord(
      id: 'a',
      sessionId: 's',
      studentId: 'u',
      teacherId: 't',
      sessionDate: '2099-01-05',
      sessionTitle: 'A',
      startMinutes: 960,
      endMinutes: 1050,
      attended: attended,
      joinedBy: 'student',
      booked: booked,
      status: status,
    );

void main() {
  group('Build 7 session life', () {
    test('an old one-off session reads its status from isConcluded', () {
      expect(_session().lifeStatus, 'scheduled');
      expect(_session(concluded: true).lifeStatus, 'done');
      expect(_session(concluded: true).isClosedOrCancelled, isTrue);
    });

    test('the function status wins', () {
      expect(_session(status: 'ongoing').isOngoing, isTrue);
      expect(_session(status: 'cancelled').isClosedOrCancelled, isTrue);
      expect(_session(status: 'needs_teacher').isClosedOrCancelled, isFalse);
    });

    test('a booking is in the class until it is cancelled; a walk-in too', () {
      expect(_record(booked: true).inClass, isTrue);
      expect(_record(attended: true).inClass, isTrue);
      expect(_record(booked: true, status: 'cancelled').inClass, isFalse);
      expect(_record().inClass, isFalse);
    });

    test('the close answer and the recap rows read the function maps', () {
      final r = CloseResult.fromMap({
        'credited': 4,
        'excused': 1,
        'failed': ['Budi'],
        'already': false,
      });
      expect([r.credited, r.excused, r.failed, r.already], [4, 1, ['Budi'], false]);
      expect(CloseResult.fromMap({'already': true}).already, isTrue);
      final row = RecapRow.fromMap({
        'teacherId': 't1',
        'teacherName': 'Andrea',
        'scheduled': 8,
        'held': 7,
        'cancelled': 1,
        'lateCheckIns': 2,
        'hours': 10.5,
      });
      expect([row.scheduled, row.held, row.cancelled, row.lateCheckIns, row.hours],
          [8, 7, 1, 2, 10.5]);
    });
  });
}
