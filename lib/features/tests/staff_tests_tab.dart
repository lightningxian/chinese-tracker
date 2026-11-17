import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../l10n/l10n.dart';
import '../../models/app_user.dart';
import '../../models/marking_item.dart';
import '../../models/test_track.dart';
import '../../services/auth_service.dart';
import '../../services/marking_service.dart';
import '../../services/test_service.dart';
import 'test_labels.dart';

/// The **Tests** place of teachers and admins: open a supervised session,
/// the sessions (admins: all; teachers: the ones they opened), results by
/// code, and for admins the formats and codes.
class StaffTestsTab extends StatelessWidget {
  const StaffTestsTab({super.key, required this.user});

  final AppUser user;

  String get _base => user.isAdmin ? '/admin/tests' : '/teacher/tests';

  Future<void> _openSession(BuildContext context) async {
    final l = context.l10n;
    final service = TestService();
    // The dialog opens at once and loads the active codes itself.
    final picked = await showDialog<(TestCode, bool)>(
      context: context,
      builder: (_) => StreamBuilder<List<TestCode>>(
        stream: service.watchCodes(),
        builder: (context, snap) => _OpenSessionDialog(
          codes: snap.data?.where((c) => c.active).toList(),
          error: snap.error,
        ),
      ),
    );
    if (picked == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final opened =
          await service.openSession(picked.$1.id, partClocks: picked.$2);
      if (context.mounted) {
        context.push('$_base/supervise/${opened.sessionId}');
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(testErrorMessage(l, e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final service = TestService();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: () => _openSession(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.navy,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              ),
              icon: const Icon(Icons.play_circle_outline),
              label: Text(l.testsOpenSession),
            ),
            OutlinedButton.icon(
              onPressed: () => context.push('$_base/results'),
              icon: const Icon(Icons.fact_check_outlined),
              label: Text(l.testsResultsTitle),
            ),
            // Build 2A: answers waiting for this teacher's mark.
            StreamBuilder<List<MarkingItem>>(
              stream: MarkingService().watchOpen(user),
              builder: (context, snap) {
                final open = snap.data?.length ?? 0;
                return OutlinedButton.icon(
                  onPressed: () => context.push('$_base/marking'),
                  icon: Badge(
                    isLabelVisible: open > 0,
                    label: Text('$open'),
                    child: const Icon(Icons.rate_review_outlined),
                  ),
                  label: Text(l.markingTitle),
                );
              },
            ),
            if (user.isAdmin) ...[
              OutlinedButton.icon(
                onPressed: () => context.push('/admin/tests/codes'),
                icon: const Icon(Icons.qr_code_2_outlined),
                label: Text(l.testsCodesTitle),
              ),
              OutlinedButton.icon(
                onPressed: () => context.push('/admin/tests/formats'),
                icon: const Icon(Icons.rule_folder_outlined),
                label: Text(l.testsFormatsTitle),
              ),
            ],
          ],
        ),
        const SizedBox(height: 20),
        Text(
          l.testsSessionsTitle,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<TestSession>>(
          stream: service.watchSessions(
              openedBy: user.isAdmin ? null : user.uid),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final sessions = snap.data!;
            if (sessions.isEmpty) {
              return EmptyState(
                icon: Icons.timer_outlined,
                title: l.testsSessionsEmptyTitle,
                subtitle: l.testsSessionsEmptySubtitle,
              );
            }
            final fmt = DateFormat.yMMMd().add_Hm();
            return Column(
              children: [
                for (final s in sessions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      onTap: () => context.push('$_base/supervise/${s.id}'),
                      child: Row(
                        children: [
                          Icon(
                            s.isOpen ? Icons.radio_button_checked : Icons.check,
                            color: s.isOpen
                                ? AppColors.success
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${s.code} · ${s.level}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.navy,
                                  ),
                                ),
                                Text(
                                  [
                                    if (s.createdAt != null)
                                      fmt.format(s.createdAt!),
                                    s.openedByName,
                                    s.isOpen
                                        ? l.testsSessionOpen
                                        : l.testsSessionClosed,
                                  ].join(' · '),
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Pick a code and the clock mode for a new session.
class _OpenSessionDialog extends StatefulWidget {
  const _OpenSessionDialog({required this.codes, this.error});

  /// Null while loading.
  final List<TestCode>? codes;
  final Object? error;

  @override
  State<_OpenSessionDialog> createState() => _OpenSessionDialogState();
}

class _OpenSessionDialogState extends State<_OpenSessionDialog> {
  TestCode? _code;
  bool _partClocks = true;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final codes = widget.codes;
    // Keep the pick only while it is still in the (live) list.
    if (_code != null && !(codes ?? const []).any((c) => c.id == _code!.id)) {
      _code = null;
    }
    return AlertDialog(
      title: Text(l.testsOpenSession),
      content: SizedBox(
        width: 460,
        child: widget.error != null
            ? Text(testErrorMessage(l, widget.error!))
            : codes == null
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            : codes.isEmpty
            ? Text(l.testsNoActiveCodes)
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _code?.id,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l.testsCode,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      for (final c in codes)
                        DropdownMenuItem(
                          value: c.id,
                          child: Text(
                            '${c.code} · ${c.level}'
                            '${c.releaseYear == null ? '' : ' · ${c.releaseYear}'}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (id) => setState(() =>
                        _code = codes.where((c) => c.id == id).firstOrNull),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _partClocks,
                    onChanged: (v) => setState(() => _partClocks = v),
                    title: Text(l.testsPartClocks),
                    subtitle: Text(_partClocks
                        ? l.testsPartClocksOn
                        : l.testsPartClocksOff),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          onPressed: _code == null
              ? null
              : () => Navigator.of(context).pop((_code!, _partClocks)),
          child: Text(l.testsOpen),
        ),
      ],
    );
  }
}

/// The signed-in staff member, for screens pushed outside the shell tabs.
AppUser currentStaff(BuildContext context) =>
    context.read<AuthService>().appUser!;
