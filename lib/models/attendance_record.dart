import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.teacherId,
    required this.sessionDate,
    required this.sessionTitle,
    required this.startMinutes,
    required this.endMinutes,
    required this.attended,
    required this.joinedBy,
    this.studentName,
    this.notes,
    this.joinedAt,
    this.classTermId,
    this.sessionCredited = false,
    this.attendanceStatus,
  });

  final String id;
  final String sessionId;
  final String studentId;
  final String teacherId;
  final String sessionDate;
  final String sessionTitle;
  final int startMinutes;
  final int endMinutes;
  final bool attended;
  final String joinedBy;
  final String? studentName;
  final String? notes;
  final DateTime? joinedAt;

  /// Paid term package this class visit was deducted from.
  final String? classTermId;
  final bool sessionCredited;

  /// `hadir` (present, charged), `izin` (excused before class, not charged),
  /// `alpa` (absent without notice, charged), or null if not marked yet.
  /// Legacy values `present` / `absent` read as hadir / izin.
  final String? attendanceStatus;

  static const hadir = 'hadir';
  static const izin = 'izin';
  static const alpa = 'alpa';

  /// Normalises legacy values; null stays null.
  static String? normalizeStatus(String? raw) {
    switch (raw) {
      case 'present':
        return hadir;
      case 'absent':
        return izin;
      default:
        return raw;
    }
  }

  String? get normalizedStatus => normalizeStatus(attendanceStatus);
  bool get isExcused => normalizedStatus == izin;

  bool get joinedByStudent => joinedBy == 'student';
  bool get joinedByTeacher => joinedBy == 'teacher';
  bool get markedPresent => normalizedStatus == hadir;
  bool get markedAbsent => normalizedStatus == izin || normalizedStatus == alpa;
  String get timeRangeLabel => _formatTimeRange(startMinutes, endMinutes);

  factory AttendanceRecord.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return AttendanceRecord(
      id: doc.id,
      sessionId: data['sessionId'] as String? ?? '',
      studentId: data['studentId'] as String? ?? '',
      teacherId: data['teacherId'] as String? ?? '',
      sessionDate: data['sessionDate'] as String? ?? '',
      sessionTitle: data['sessionTitle'] as String? ?? '',
      startMinutes: data['startMinutes'] as int? ?? 0,
      endMinutes: data['endMinutes'] as int? ?? 0,
      attended: data['attended'] as bool? ?? false,
      joinedBy: data['joinedBy'] as String? ?? 'teacher',
      studentName: data['studentName'] as String?,
      notes: data['notes'] as String?,
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate(),
      classTermId: data['classTermId'] as String?,
      sessionCredited: data['sessionCredited'] as bool? ?? false,
      attendanceStatus: data['attendanceStatus'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'sessionId': sessionId,
        'studentId': studentId,
        'teacherId': teacherId,
        'sessionDate': sessionDate,
        'sessionTitle': sessionTitle,
        'startMinutes': startMinutes,
        'endMinutes': endMinutes,
        'attended': attended,
        'joinedBy': joinedBy,
        if (studentName != null && studentName!.isNotEmpty)
          'studentName': studentName,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
        if (classTermId != null && classTermId!.isNotEmpty)
          'classTermId': classTermId,
        'sessionCredited': sessionCredited,
        if (attendanceStatus != null && attendanceStatus!.isNotEmpty)
          'attendanceStatus': attendanceStatus,
        'joinedAt': FieldValue.serverTimestamp(),
      };

  static String _formatTimeRange(int startMinutes, int endMinutes) {
    String fmt(int minutes) {
      final h = (minutes ~/ 60).toString().padLeft(2, '0');
      final m = (minutes % 60).toString().padLeft(2, '0');
      return '$h:$m';
    }

    return '${fmt(startMinutes)}–${fmt(endMinutes)}';
  }
}
