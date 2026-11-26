import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/shell_nested_page.dart';
import '../../l10n/l10n.dart';
import '../../models/org_settings.dart';
import '../../services/firestore_service.dart';
import '../../services/list_pages_service.dart';
import '../../services/progress_service.dart';
import '../../services/promotion_service.dart';
import '../../services/rooms_service.dart';
import '../teaching/admin_teaching_views.dart';

/// Admin-only centre settings. Toggles persist immediately to `settings/org`
/// and gate dependent features (payments, evaluations, teacher reschedule).
class OrgSettingsScreen extends StatelessWidget {
  const OrgSettingsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final firestore = context.read<FirestoreService>();

    return ShellNestedPage(
      embedded: embedded,
      title: l.orgSettingsTitle,
      child: StreamBuilder<OrgSettings>(
        stream: firestore.watchOrgSettings(),
        builder: (context, snap) {
          final settings = snap.data ?? OrgSettings.defaults;
          final loading =
              snap.connectionState == ConnectionState.waiting && !snap.hasData;
          if (loading) {
            return const Center(child: CircularProgressIndicator());
          }

          Future<void> update(OrgSettings next) async {
            try {
              await firestore.updateOrgSettings(next);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l.adminPriceSaveFailed('$e')),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            }
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SectionHeader(title: l.orgSettingsFeatures),
              _ToggleCard(
                title: l.navPayments,
                subtitle: l.orgSettingsPaymentsHint,
                icon: Icons.receipt_long_outlined,
                value: settings.enablePayments,
                onChanged: (v) => update(settings.copyWith(enablePayments: v)),
              ),
              _ToggleCard(
                title: l.orgSettingsEvalOpen,
                subtitle: l.orgSettingsEvalOpenHint,
                icon: Icons.assignment_outlined,
                value: settings.evaluationFormsOpen,
                onChanged: (v) =>
                    update(settings.copyWith(evaluationFormsOpen: v)),
              ),
              _ToggleCard(
                title: l.orgSettingsTeacherReschedule,
                subtitle: l.orgSettingsTeacherRescheduleHint,
                icon: Icons.event_repeat_outlined,
                value: settings.allowTeacherReschedule,
                onChanged: (v) =>
                    update(settings.copyWith(allowTeacherReschedule: v)),
              ),
              const SizedBox(height: 12),
              SectionHeader(title: l.orgSettingsAccounts),
              _ToggleCard(
                title: l.orgSettingsRequireEmailVerification,
                subtitle: l.orgSettingsRequireEmailVerificationHint,
                icon: Icons.mark_email_read_outlined,
                value: settings.requireEmailVerification,
                onChanged: (v) =>
                    update(settings.copyWith(requireEmailVerification: v)),
              ),
              _ToggleCard(
                title: l.orgSettingsAutoPasswords,
                subtitle: l.orgSettingsAutoPasswordsHint,
                icon: Icons.password_outlined,
                value: settings.autoGenerateStaffPasswords,
                onChanged: (v) =>
                    update(settings.copyWith(autoGenerateStaffPasswords: v)),
              ),
              const SizedBox(height: 12),
              SectionHeader(title: l.roomsTitle),
              const _RoomsCard(),
              const SizedBox(height: 12),
              SectionHeader(title: l.orgSettingsPrices),
              AppCard(
                onTap: () => context.push('/admin/price-list'),
                child: _NavRow(
                  icon: Icons.sell_outlined,
                  title: l.adminPriceTitle,
                  subtitle: l.orgSettingsPriceListHint,
                ),
              ),
              const SizedBox(height: 12),
              SectionHeader(title: l.orgSettingsAdministration),
              AppCard(
                onTap: () => context.push('/admin/audit-logs'),
                child: _NavRow(
                  icon: Icons.history,
                  title: l.auditLogTitle,
                  subtitle: l.orgSettingsAuditLogsHint,
                ),
              ),
              const SizedBox(height: 10),
              // Build 4: rebuild every student's progress summary (once
              // after the deploy; the functions keep them after that).
              const _RebuildSummariesCard(),
              const SizedBox(height: 12),
              const _RebuildSummariesCard(leaderboards: true),
              const SizedBox(height: 12),
              const _RebuildSummariesCard(userSearch: true),
              const SizedBox(height: 12),
              const _RebuildSummariesCard(listIndexes: true),
              const SizedBox(height: 10),
              // Build 7: vouchers against the ledger (VC-05).
              const ReconcileVouchersCard(),
              const SizedBox(height: 10),
              AppCard(
                onTap: () => context.push('/admin/materials'),
                child: _NavRow(
                  icon: Icons.folder_open_outlined,
                  title: l.studentHomeQuickMaterials,
                  subtitle: l.orgSettingsMaterialsHint,
                ),
              ),
              if (settings.updatedAt != null) ...[
                const SizedBox(height: 16),
                Text(
                  l.orgSettingsLastUpdated('${settings.updatedAt}'),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  const _ToggleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: value,
          onChanged: onChanged,
          secondary: Icon(icon, color: AppColors.navy),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.navy),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.chevron_right, color: AppColors.textSecondary),
      ],
    );
  }
}

/// Editable prices and term validity (`settings/pricing`). The server reads
/// the same document when it creates invoices, so what the admin types here
/// is what students are charged. The landing page shows these too.

/// Build 3: the rooms of the session forms (`settings/rooms`). Opening the
/// screen writes the defaults (Main, Sub Room) when the doc is missing.
class _RoomsCard extends StatefulWidget {
  const _RoomsCard();

  @override
  State<_RoomsCard> createState() => _RoomsCardState();
}

class _RoomsCardState extends State<_RoomsCard> {
  final _service = RoomsService();
  late final Stream<List<String>> _rooms = _service.watchRooms();

  @override
  void initState() {
    super.initState();
    _service.ensureDefaults().catchError((Object e) {
      debugPrint('rooms: $e');
    });
  }

  Future<String?> _ask(String title, {String initial = ''}) async {
    final l = context.l10n;
    final c = TextEditingController(text: initial);
    final out = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: InputDecoration(labelText: l.roomsName),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, c.text),
            child: Text(l.roomsSave),
          ),
        ],
      ),
    );
    c.dispose();
    final v = out?.trim() ?? '';
    return v.isEmpty ? null : v;
  }

  Future<void> _save(List<String> rooms) async {
    try {
      await _service.save(rooms);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return StreamBuilder<List<String>>(
      stream: _rooms,
      builder: (context, snap) {
        final rooms = snap.data ?? RoomsService.defaults;
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.roomsHint,
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              for (var i = 0; i < rooms.length; i++)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.meeting_room_outlined),
                  title: Text(rooms[i]),
                  trailing: Wrap(
                    children: [
                      IconButton(
                        tooltip: l.roomsRename,
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () async {
                          final v =
                              await _ask(l.roomsRename, initial: rooms[i]);
                          if (v == null) return;
                          await _save([...rooms]..[i] = v);
                        },
                      ),
                      IconButton(
                        tooltip: l.roomsRemove,
                        icon: const Icon(Icons.delete_outline),
                        onPressed: rooms.length <= 1
                            ? null
                            : () => _save([...rooms]..removeAt(i)),
                      ),
                    ],
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () async {
                    final v = await _ask(l.roomsAdd);
                    if (v != null) await _save([...rooms, v]);
                  },
                  icon: const Icon(Icons.add),
                  label: Text(l.roomsAdd),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RebuildSummariesCard extends StatefulWidget {
  const _RebuildSummariesCard(
      {this.leaderboards = false, this.userSearch = false, this.listIndexes = false});

  /// Build 9 part 2: the same card for **Rebuild list indexes**.
  final bool listIndexes;

  /// Build 9C: the same card for **Rebuild leaderboards**.
  final bool leaderboards;

  /// Build 9A session 2: the same card for **Rebuild user search**.
  final bool userSearch;

  @override
  State<_RebuildSummariesCard> createState() => _RebuildSummariesCardState();
}

class _RebuildSummariesCardState extends State<_RebuildSummariesCard> {
  bool _busy = false;

  Future<void> _run() async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      if (widget.listIndexes) {
        final r = await ListPagesService(FirestoreService()).rebuildListIndexes();
        messenger.showSnackBar(SnackBar(
            content: Text(l.listIndexRebuildDone(
                (r['sheets'] as num?)?.toInt() ?? 0,
                (r['exercises'] as num?)?.toInt() ?? 0))));
      } else if (widget.userSearch) {
        final n = await FirestoreService().rebuildUserSearch();
        messenger.showSnackBar(SnackBar(content: Text(l.orgRebuildUserSearchDone(n))));
      } else if (widget.leaderboards) {
        final n = await PromotionService().rebuildLeaderboards();
        messenger.showSnackBar(
            SnackBar(content: Text(l.orgRebuildLeaderboardsDone(n))));
      } else {
        final n = await ProgressService().rebuildAll();
        messenger.showSnackBar(SnackBar(content: Text(l.progressRebuilt(n))));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('$e'),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppCard(
      onTap: _busy ? null : _run,
      child: Row(
        children: [
          _busy
              ? const SizedBox(
                  width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(Icons.refresh, color: AppColors.navy),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    widget.listIndexes
                        ? l.listIndexRebuild
                        : widget.userSearch
                        ? l.orgRebuildUserSearch
                        : widget.leaderboards
                            ? l.orgRebuildLeaderboards
                            : l.progressRebuildTitle,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                    widget.listIndexes
                        ? l.listIndexRebuildHint
                        : widget.userSearch
                        ? l.orgRebuildUserSearchHint
                        : widget.leaderboards
                            ? l.orgRebuildLeaderboardsHint
                            : l.progressRebuildHint,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
