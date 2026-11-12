import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/shell_nested_page.dart';
import '../../l10n/l10n.dart';
import '../../models/audit_log.dart';
import '../../services/firestore_service.dart';

/// Admin-only, read-only view of the append-only audit log.
class AuditLogsScreen extends StatelessWidget {
  const AuditLogsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final firestore = context.read<FirestoreService>();

    return ShellNestedPage(
      embedded: embedded,
      title: l.auditLogTitle,
      child: StreamBuilder<List<AuditLog>>(
        stream: firestore.watchAuditLogs(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final logs = snap.data ?? const <AuditLog>[];
          if (logs.isEmpty) {
            return EmptyState(
              icon: Icons.history,
              title: l.auditLogEmptyTitle,
              subtitle: l.auditLogEmptySubtitle,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: logs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _AuditCard(log: logs[i]),
          );
        },
      ),
    );
  }
}

class _AuditCard extends StatelessWidget {
  const _AuditCard({required this.log});

  final AuditLog log;

  @override
  Widget build(BuildContext context) {
    final when = log.createdAt;
    final whenLabel =
        when != null ? DateFormat('d MMM yyyy, HH:mm').format(when) : '—';
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _actionColor(log.action).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_actionIcon(log.action),
                size: 18, color: _actionColor(log.action)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.action,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                if (log.detail.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    log.detail,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '${log.actorName} · $whenLabel',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _actionColor(String action) {
    if (action.contains('paid')) return AppColors.success;
    if (action.contains('created')) return AppColors.navy;
    if (action.contains('permission') || action.contains('revoked')) {
      return AppColors.error;
    }
    return AppColors.teal;
  }

  IconData _actionIcon(String action) {
    if (action.startsWith('invoice')) return Icons.receipt_long_outlined;
    if (action.contains('permission'))
      return Icons.admin_panel_settings_outlined;
    if (action.contains('attendance')) return Icons.event_busy_outlined;
    return Icons.bolt_outlined;
  }
}
