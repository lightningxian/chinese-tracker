import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Build 6 (docs/PLAN.md §4): the weekly timetable and booking. Schedules
/// are written only by the `saveSchedule` function (with the conflict
/// check); booking goes through `bookSession` / `cancelBooking`.

const weekdayKeys = [1, 2, 3, 4, 5, 6, 7];

String clockOf(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';

/// `16:30` → 990, or null.
int? minutesOf(String text) {
  final m = RegExp(r'^(\d{1,2})[:.](\d{2})$').firstMatch(text.trim());
  if (m == null) return null;
  final h = int.parse(m.group(1)!);
  final min = int.parse(m.group(2)!);
  if (h > 23 || min > 59) return null;
  return h * 60 + min;
}

class Schedule {
  const Schedule({
    required this.id,
    required this.className,
    required this.weekday,
    required this.startMinutes,
    required this.endMinutes,
    required this.room,
    required this.teacherId,
    required this.teacherName,
    required this.capacity,
    required this.level,
    required this.validFrom,
    required this.validTo,
    required this.active,
    required this.status,
  });

  final String id;
  final String className;
  final int weekday;
  final int startMinutes;
  final int endMinutes;
  final String room;
  final String teacherId;
  final String teacherName;
  final int capacity;
  final String level;
  final String validFrom;
  final String validTo;
  final bool active;
  final String status;

  String get timeLabel => '${clockOf(startMinutes)}–${clockOf(endMinutes)}';

  factory Schedule.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const <String, dynamic>{};
    int i(Object? v) => (v as num?)?.toInt() ?? 0;
    return Schedule(
      id: d.id,
      className: m['className'] as String? ?? '',
      weekday: i(m['weekday']),
      startMinutes: i(m['startMinutes']),
      endMinutes: i(m['endMinutes']),
      room: m['room'] as String? ?? '',
      teacherId: m['teacherId'] as String? ?? '',
      teacherName: m['teacherName'] as String? ?? '',
      capacity: i(m['capacity']),
      level: m['level'] as String? ?? '',
      validFrom: m['validFrom'] as String? ?? '',
      validTo: m['validTo'] as String? ?? '',
      active: m['active'] != false,
      status: m['status'] as String? ?? '',
    );
  }

  Map<String, dynamic> toInput() => {
        if (id.isNotEmpty) 'id': id,
        'className': className,
        'weekday': weekday,
        'startMinutes': startMinutes,
        'endMinutes': endMinutes,
        'room': room,
        'teacherId': teacherId,
        'capacity': capacity,
        'level': level,
        'validFrom': validFrom,
        'validTo': validTo,
        'active': active,
      };
}

/// The answer of `checkScheduleConflict`.
class ScheduleCheck {
  const ScheduleCheck({
    required this.ok,
    required this.reasons,
    required this.warnings,
    required this.suggestions,
  });

  final bool ok;
  final List<String> reasons;
  final List<String> warnings;
  final List<({int weekday, int startMinutes, int endMinutes})> suggestions;

  factory ScheduleCheck.fromMap(Map<String, dynamic> m) {
    List<String> texts(Object? v) => [
          for (final x in (v as List? ?? const []))
            if (x is Map) '${x['text'] ?? ''}',
        ];
    return ScheduleCheck(
      ok: m['ok'] == true,
      reasons: texts(m['reasons']),
      warnings: texts(m['warnings']),
      suggestions: [
        for (final x in (m['suggestions'] as List? ?? const []))
          if (x is Map)
            (
              weekday: (x['weekday'] as num?)?.toInt() ?? 0,
              startMinutes: (x['startMinutes'] as num?)?.toInt() ?? 0,
              endMinutes: (x['endMinutes'] as num?)?.toInt() ?? 0,
            ),
      ],
    );
  }
}

/// A generated (or one-off) session as the booking list shows it.
class BookableSession {
  const BookableSession({
    required this.id,
    required this.title,
    required this.date,
    required this.startMinutes,
    required this.endMinutes,
    required this.room,
    required this.teacherName,
    required this.level,
    required this.capacity,
    required this.bookedCount,
    required this.status,
  });

  final String id;
  final String title;
  final String date;
  final int startMinutes;
  final int endMinutes;
  final String room;
  final String teacherName;
  final String level;
  final int capacity;
  final int bookedCount;
  final String status;

  int get seatsLeft => (capacity - bookedCount).clamp(0, capacity);

  factory BookableSession.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const <String, dynamic>{};
    int i(Object? v) => (v as num?)?.toInt() ?? 0;
    return BookableSession(
      id: d.id,
      title: m['sessionTitle'] as String? ?? '',
      date: m['sessionDate'] as String? ?? '',
      startMinutes: i(m['startMinutes']),
      endMinutes: i(m['endMinutes']),
      room: m['room'] as String? ?? '',
      teacherName: m['teacherName'] as String? ?? '',
      level: m['level'] as String? ?? '',
      capacity: i(m['capacity']),
      bookedCount: i(m['bookedCount']),
      status: m['status'] as String? ?? 'scheduled',
    );
  }
}

class BookingException implements Exception {
  const BookingException(this.reason, this.message);
  final String reason;
  final String message;
}

class TimetableService {
  TimetableService({FirebaseFirestore? firestore, FirebaseFunctions? functions})
      : _db = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  Stream<List<Schedule>> watchSchedules() => _db.collection('schedules').snapshots().map(
      (s) => s.docs.map(Schedule.fromDoc).toList()
        ..sort((a, b) => a.weekday != b.weekday
            ? a.weekday.compareTo(b.weekday)
            : a.startMinutes.compareTo(b.startMinutes)));

  Future<ScheduleCheck> check(Map<String, dynamic> input) async {
    final r = await _functions.httpsCallable('checkScheduleConflict').call(input);
    return ScheduleCheck.fromMap(Map<String, dynamic>.from(r.data as Map));
  }

  /// Saves (the function refuses a clash; its message lists the reasons).
  Future<List<String>> save(Map<String, dynamic> input) async {
    final r = await _functions.httpsCallable('saveSchedule').call(input);
    final m = Map<String, dynamic>.from(r.data as Map);
    return [
      for (final w in (m['warnings'] as List? ?? const []))
        if (w is Map) '${w['text']}',
    ];
  }

  /// The centre's generated sessions from [fromDate] (`yyyy-MM-dd`).
  Stream<List<BookableSession>> watchUpcoming(String fromDate) => _db
      .collection('class_sessions')
      .where('generated', isEqualTo: true)
      .where('sessionDate', isGreaterThanOrEqualTo: fromDate)
      .orderBy('sessionDate')
      .limit(200)
      .snapshots()
      .map((s) => s.docs.map(BookableSession.fromDoc).toList()
        ..sort((a, b) => a.date != b.date
            ? a.date.compareTo(b.date)
            : a.startMinutes.compareTo(b.startMinutes)));

  /// Session ids the student has booked.
  Stream<Set<String>> watchMyBookings(String studentId) => _db
      .collection('attendance')
      .where('studentId', isEqualTo: studentId)
      .where('booked', isEqualTo: true)
      .snapshots()
      .map((s) => {for (final d in s.docs) (d.data()['sessionId'] as String? ?? '')});

  Future<void> book(String sessionId, {String? studentId}) => _call('bookSession', {
        'sessionId': sessionId,
        if (studentId != null) 'studentId': studentId,
      });

  Future<void> cancel(String sessionId, {String? studentId}) => _call('cancelBooking', {
        'sessionId': sessionId,
        if (studentId != null) 'studentId': studentId,
      });

  Future<void> _call(String name, Map<String, dynamic> data) async {
    try {
      await _functions.httpsCallable(name).call(data);
    } on FirebaseFunctionsException catch (e) {
      final d = e.details;
      throw BookingException(d is Map ? '${d['reason'] ?? ''}' : '', e.message ?? '');
    }
  }

  // ------------------------------------------------ availability, days off

  Future<void> saveAvailability(
          String teacherId, Map<int, List<({int startMinutes, int endMinutes})>> days) =>
      _db.collection('users').doc(teacherId).update({
        'availability': {
          for (final e in days.entries)
            '${e.key}': [
              for (final w in e.value)
                {'startMinutes': w.startMinutes, 'endMinutes': w.endMinutes},
            ],
        },
      });

  Stream<List<({String id, String teacherId, String date, String reason})>> watchDaysOff(
          {String? teacherId}) =>
      (teacherId == null
              ? _db.collection('teacher_days_off')
              : _db.collection('teacher_days_off').where('teacherId', isEqualTo: teacherId))
          .snapshots()
          .map((s) => [
                for (final d in s.docs)
                  (
                    id: d.id,
                    teacherId: d.data()['teacherId'] as String? ?? '',
                    date: d.data()['date'] as String? ?? '',
                    reason: d.data()['reason'] as String? ?? '',
                  ),
              ]..sort((a, b) => a.date.compareTo(b.date)));

  Future<void> addDayOff(String teacherId, String date, String reason) =>
      _db.collection('teacher_days_off').add({
        'teacherId': teacherId,
        'date': date,
        'reason': reason.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

  Future<void> deleteDayOff(String id) => _db.collection('teacher_days_off').doc(id).delete();
}

/// A teacher's availability from the profile map.
Map<int, List<({int startMinutes, int endMinutes})>> availabilityOf(Object? raw) {
  final out = <int, List<({int startMinutes, int endMinutes})>>{};
  if (raw is! Map) return out;
  for (final e in raw.entries) {
    final day = int.tryParse('${e.key}');
    if (day == null || e.value is! List) continue;
    out[day] = [
      for (final w in e.value as List)
        if (w is Map)
          (
            startMinutes: (w['startMinutes'] as num?)?.toInt() ?? 0,
            endMinutes: (w['endMinutes'] as num?)?.toInt() ?? 0,
          ),
    ];
  }
  return out;
}
