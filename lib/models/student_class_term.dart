import 'package:cloud_firestore/cloud_firestore.dart';

class StudentClassTerm {
  const StudentClassTerm({
    required this.id,
    required this.studentId,
    required this.packageSize,
    required this.sessionsRemaining,
    required this.sessionsUsed,
    required this.status,
    required this.startDate,
    required this.deadlineDate,
    this.createdBy,
    this.notes,
    this.voucherCode,
    this.purchasedAt,
    this.createdAt,
  });

  final String id;
  final String studentId;
  final int packageSize;
  final int sessionsRemaining;
  final int sessionsUsed;
  final String status;
  /// `yyyy-MM-dd` — term valid from this date (inclusive).
  final String startDate;
  /// `yyyy-MM-dd` — term valid through this date (inclusive).
  final String deadlineDate;
  final String? createdBy;
  final String? notes;
  final String? voucherCode;
  final DateTime? purchasedAt;
  final DateTime? createdAt;

  bool get isActive =>
      status == StudentClassTerm.statusActive && sessionsRemaining > 0;

  static const statusActive = 'active';
  static const statusDepleted = 'depleted';

  static bool isValidOnDate({
    required String startDate,
    required String deadlineDate,
    DateTime? on,
  }) {
    final day = on ?? DateTime.now();
    final today = DateTime(day.year, day.month, day.day);
    final start = DateTime.tryParse(startDate);
    final end = DateTime.tryParse(deadlineDate);
    if (start == null || end == null) return true;
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    return !today.isBefore(startDay) && !today.isAfter(endDay);
  }

  bool get isWithinTermDates =>
      isValidOnDate(startDate: startDate, deadlineDate: deadlineDate);

  String get voucherStatusLabel {
    if (voucherCode == null || voucherCode!.isEmpty) return status;
    if (sessionsRemaining <= 0) return 'depleted';
    if (sessionsRemaining <= 2) return 'low';
    return 'active';
  }

  factory StudentClassTerm.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final packageSize = data['packageSize'] as int? ?? 8;
    return StudentClassTerm(
      id: doc.id,
      studentId: data['studentId'] as String? ?? '',
      packageSize: packageSize,
      sessionsRemaining: data['sessionsRemaining'] as int? ?? 0,
      sessionsUsed: data['sessionsUsed'] as int? ?? 0,
      status: data['status'] as String? ?? statusActive,
      startDate: data['startDate'] as String? ?? '',
      deadlineDate: data['deadlineDate'] as String? ?? '',
      createdBy: data['createdBy'] as String?,
      notes: data['notes'] as String?,
      voucherCode: data['voucherCode'] as String?,
      purchasedAt: (data['purchasedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'studentId': studentId,
        'packageSize': packageSize,
        'sessionsRemaining': sessionsRemaining,
        'sessionsUsed': sessionsUsed,
        'status': status,
        'startDate': startDate,
        'deadlineDate': deadlineDate,
        if (createdBy != null && createdBy!.isNotEmpty) 'createdBy': createdBy,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
        if (voucherCode != null && voucherCode!.isNotEmpty)
          'voucherCode': voucherCode,
        'purchasedAt': purchasedAt != null
            ? Timestamp.fromDate(purchasedAt!)
            : FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };
}
