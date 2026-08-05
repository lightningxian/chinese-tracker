import 'package:cloud_firestore/cloud_firestore.dart';

/// Centre-wide settings stored at `settings/org`. Readable by any signed-in
/// user; only admins write. Missing fields fall back to sensible defaults so
/// the app works before the doc exists.
class OrgSettings {
  const OrgSettings({
    this.requireEmailVerification = false,
    this.autoGenerateStaffPasswords = false,
    this.enablePayments = true,
    this.allowTeacherReschedule = true,
    this.evaluationFormsOpen = false,
    this.updatedAt,
    this.updatedBy,
  });

  final bool requireEmailVerification;
  final bool autoGenerateStaffPasswords;
  final bool enablePayments;
  final bool allowTeacherReschedule;
  final bool evaluationFormsOpen;
  final DateTime? updatedAt;
  final String? updatedBy;

  static const defaults = OrgSettings();

  factory OrgSettings.fromMap(Map<String, dynamic>? data) {
    final map = data ?? const {};
    return OrgSettings(
      requireEmailVerification:
          map['requireEmailVerification'] as bool? ?? false,
      autoGenerateStaffPasswords:
          map['autoGenerateStaffPasswords'] as bool? ?? false,
      enablePayments: map['enablePayments'] as bool? ?? true,
      allowTeacherReschedule: map['allowTeacherReschedule'] as bool? ?? true,
      evaluationFormsOpen: map['evaluationFormsOpen'] as bool? ?? false,
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      updatedBy: map['updatedBy'] as String?,
    );
  }

  factory OrgSettings.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) =>
      OrgSettings.fromMap(doc.data());

  Map<String, dynamic> toMap() => {
        'requireEmailVerification': requireEmailVerification,
        'autoGenerateStaffPasswords': autoGenerateStaffPasswords,
        'enablePayments': enablePayments,
        'allowTeacherReschedule': allowTeacherReschedule,
        'evaluationFormsOpen': evaluationFormsOpen,
      };

  OrgSettings copyWith({
    bool? requireEmailVerification,
    bool? autoGenerateStaffPasswords,
    bool? enablePayments,
    bool? allowTeacherReschedule,
    bool? evaluationFormsOpen,
  }) {
    return OrgSettings(
      requireEmailVerification:
          requireEmailVerification ?? this.requireEmailVerification,
      autoGenerateStaffPasswords:
          autoGenerateStaffPasswords ?? this.autoGenerateStaffPasswords,
      enablePayments: enablePayments ?? this.enablePayments,
      allowTeacherReschedule:
          allowTeacherReschedule ?? this.allowTeacherReschedule,
      evaluationFormsOpen: evaluationFormsOpen ?? this.evaluationFormsOpen,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
    );
  }
}
