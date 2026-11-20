import 'package:chinese_tracker/features/timetable/teacher_availability_card.dart';
import 'package:chinese_tracker/services/timetable_service.dart';
import 'package:flutter_test/flutter_test.dart';

// Build 6: times typed on the availability and schedule forms.
void main() {
  test('minutesOf and clockOf', () {
    expect(minutesOf('16:30'), 990);
    expect(minutesOf('9.05'), 545);
    expect(minutesOf('25:00'), isNull);
    expect(minutesOf('abc'), isNull);
    expect(clockOf(990), '16:30');
  });

  test('availability windows parse, and a bad range is refused', () {
    final w = parseWindows('15:00-18:00, 19:00 – 20:30');
    expect(w, [(startMinutes: 900, endMinutes: 1080), (startMinutes: 1140, endMinutes: 1230)]);
    expect(parseWindows(''), isEmpty);
    expect(parseWindows('18:00-15:00'), isNull);
    expect(parseWindows('15:00'), isNull);
    expect(windowsText(w!), '15:00-18:00, 19:00-20:30');
  });
}
