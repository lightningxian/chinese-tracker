import 'attendance_record.dart';

/// Owner 2026-11-23: what the teacher compared with the attendance board
/// in the room (students write their names on it).
class BoardCheck {
  const BoardCheck({required this.statuses, required this.board, required this.extras});

  final Map<String, String> statuses;

  /// studentId → signed the board.
  final Map<String, bool> board;

  /// Names on the board that are not in the app's list.
  final String extras;

  /// The differences between the board and the statuses (pure, tested):
  /// present but not signed, signed but not present, names not booked.
  static ({List<String> presentNotSigned, List<String> signedNotPresent, List<String> notBooked})
      differences({
    required Map<String, String> statusById,
    required Map<String, bool> board,
    required Map<String, String> nameById,
    required String extras,
  }) {
    final presentNotSigned = <String>[];
    final signedNotPresent = <String>[];
    for (final e in statusById.entries) {
      final signed = board[e.key] == true;
      final name = nameById[e.key] ?? e.key;
      if (e.value == AttendanceRecord.hadir && !signed) presentNotSigned.add(name);
      if (e.value != AttendanceRecord.hadir && signed) signedNotPresent.add(name);
    }
    final notBooked = [
      for (final n in extras.split(RegExp(r'[,\n]'))) if (n.trim().isNotEmpty) n.trim(),
    ];
    return (
      presentNotSigned: presentNotSigned..sort(),
      signedNotPresent: signedNotPresent..sort(),
      notBooked: notBooked,
    );
  }
}
