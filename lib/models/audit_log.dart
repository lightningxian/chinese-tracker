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

/// Build 9A: the audit log's action filter. Each group lists the actions
/// `writeAudit` writes in `functions/index.js` (a test keeps them in step).
enum AuditActionGroup {
  invoice(['invoice.created', 'invoice.paid', 'invoice.discard', 'invoice.restore']),
  test([
    'test.session.open',
    'test.session.close',
    'test.result.valid',
    'test.result.invalid',
    'test.attempt.reset',
  ]),
  promotion([
    'promotion.approve',
    'promotion.decline',
    'promotion.approve.placement',
    'promotion.decline.placement',
    'promotion.manual',
  ]),
  registration(['registration.approve', 'registration.reject']),
  schedule(['schedule.create', 'schedule.update', 'schedule.delete']),
  day(['day.close', 'day.open']),
  progress(['progress.rebuild', 'leaderboard.rebuild']);

  const AuditActionGroup(this.actions);

  final List<String> actions;
}
