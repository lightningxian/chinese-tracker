import 'package:cloud_firestore/cloud_firestore.dart';

/// An append-only audit entry (`audit_logs`). Written only by Cloud Functions
/// (admin SDK); readable only by admins.
class AuditLog {
  const AuditLog({
    required this.id,
    required this.action,
    required this.actorId,
    required this.actorName,
    this.targetType,
    this.targetId,
    this.detail = '',
    this.createdAt,
  });

  final String id;
  final String action;
  final String actorId;
  final String actorName;
  final String? targetType;
  final String? targetId;
  final String detail;
  final DateTime? createdAt;

  factory AuditLog.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AuditLog(
      id: doc.id,
      action: data['action'] as String? ?? '',
      actorId: data['actorId'] as String? ?? 'system',
      actorName: data['actorName'] as String? ?? 'System',
      targetType: data['targetType'] as String?,
      targetId: data['targetId'] as String?,
      detail: data['detail'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
