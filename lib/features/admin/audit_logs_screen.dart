import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/paging/date_range.dart';
import '../../core/paging/paged_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/csv_export.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/paging_bars.dart';
import '../../core/widgets/shell_nested_page.dart';
import '../../l10n/l10n.dart';
import '../../models/audit_log.dart';
import '../../services/firestore_service.dart';

/// Admin-only, read-only view of the append-only audit log.
/// Build 9A (supervisor 2026-11-25): paged (25 rows read per page), a date
/// range (default this month) and an action filter.
class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  AuditActionGroup? _group;
  late final PagedController<AuditLog> _pages;

  @override
  void initState() {
    super.initState();
    final firestore = context.read<FirestoreService>();
    _pages = PagedController<AuditLog>(
      build: (range) => firestore.auditLogSource(range, group: _group),
    );
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  String _groupLabel(BuildContext context, AuditActionGroup? g) {
    final l = context.l10n;
    return switch (g) {
      null => l.auditGroupAll,
      AuditActionGroup.invoice => l.auditGroupInvoice,
      AuditActionGroup.test => l.auditGroupTest,
      AuditActionGroup.promotion => l.auditGroupPromotion,
      AuditActionGroup.registration => l.auditGroupRegistration,
      AuditActionGroup.schedule => l.auditGroupSchedule,
      AuditActionGroup.day => l.auditGroupDay,
      AuditActionGroup.progress => l.auditGroupProgress,
    };
  }

  Future<void> _export() async {
    final rows = await fetchRowsForExport(context, _pages);
    if (rows == null || !mounted) return;
    final f = DateFormat('yyyy-MM-dd HH:mm');
    await CsvExport.download(
      fileStem: 'audit_log_${DateRangeSel.isoDay(DateRangeSel.jakartaToday())}',
      header: const ['created_at', 'action', 'actor', 'target_type', 'target_id', 'detail'],
      rows: [
        for (final r in rows)
          [
            r.createdAt == null ? '' : f.format(r.createdAt!),
            r.action,
            r.actorName,
            r.targetType ?? '',
            r.targetId ?? '',
            r.detail,
          ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ShellNestedPage(
      embedded: widget.embedded,
      title: l.auditLogTitle,
      child: ListenableBuilder(
        listenable: _pages,
        builder: (context, _) => PagedListBody<AuditLog>(
          controller: _pages,
          maxWidth: 1000,
          emptyIcon: Icons.history,
          emptyTitle: l.auditLogEmptyTitle,
          emptySubtitle: l.auditLogEmptySubtitle,
          header: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DateRangeBar(value: _pages.range, onChanged: _pages.setRange),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(l.auditFilterAction,
                      style: TextStyle(color: AppColors.textSecondary)),
                  DropdownButton<AuditActionGroup?>(
                    value: _group,
                    items: [
                      for (final g in [null, ...AuditActionGroup.values])
                        DropdownMenuItem(
                            value: g, child: Text(_groupLabel(context, g))),
                    ],
                    onChanged: (g) {
                      setState(() => _group = g);
                      _pages.reload();
                    },
                  ),
                  OutlinedButton.icon(
                    onPressed: _export,
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: Text(l.pagingExportCsv),
                  ),
                ],
              ),
            ],
          ),
          itemBuilder: (_, log) => _AuditCard(log: log),
        ),
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
    if (action.contains('permission')) {
      return Icons.admin_panel_settings_outlined;
    }
    if (action.contains('attendance')) return Icons.event_busy_outlined;
    return Icons.bolt_outlined;
  }
}
