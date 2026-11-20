import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/placement_choice_fields.dart';
import '../../core/widgets/shell_nested_page.dart';
import '../../l10n/l10n.dart';
import '../../models/app_user.dart';
import '../../models/placement.dart';
import '../../services/firestore_service.dart';
import '../../services/placement_service.dart';
import '../tests/test_labels.dart';

/// `/admin/users/approval` (the admin's "waiting for approval" notice).
class RegistrationApprovalPage extends StatelessWidget {
  const RegistrationApprovalPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ShellNestedPage(
      embedded: embedded,
      title: l.approvalTitle,
      child: StreamBuilder<List<AppUser>>(
        stream: context.read<FirestoreService>().watchAllUsers(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [RegistrationApprovalView(users: snap.data!)],
          );
        },
      ),
    );
  }
}

/// Build 3 (Must 4): the Approval section of the admin Users tab. One card
/// per pending student; rejected accounts in a collapsed list below.
class RegistrationApprovalView extends StatelessWidget {
  const RegistrationApprovalView({super.key, required this.users});

  /// Every user (the teachers fill the picker).
  final List<AppUser> users;

  /// Pending students in [users].
  static int pendingCount(List<AppUser> users) =>
      users.where((u) => u.isStudent && u.isPending).length;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final teachers = users.where((u) => u.isTeacher && u.active).toList()
      ..sort((a, b) => a.staffLabel.compareTo(b.staffLabel));
    int newest(AppUser a, AppUser b) => (b.createdAt ?? DateTime(2000))
        .compareTo(a.createdAt ?? DateTime(2000));
    final pending = users.where((u) => u.isStudent && u.isPending).toList()
      ..sort(newest);
    final rejected = users.where((u) => u.isStudent && u.isRejected).toList()
      ..sort(newest);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.approvalIntro, style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        if (pending.isEmpty)
          AppCard(
            child: Text(l.approvalEmpty,
                style: TextStyle(color: AppColors.textSecondary)),
          ),
        for (final u in pending)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ApprovalCard(
                key: ValueKey(u.uid), student: u, teachers: teachers),
          ),
        if (rejected.isNotEmpty)
          Card(
            elevation: 0,
            color: AppColors.card,
            child: ExpansionTile(
              title: Text(l.approvalRejectedList(rejected.length)),
              children: [
                for (final u in rejected)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: _ApprovalCard(
                        key: ValueKey(u.uid), student: u, teachers: teachers),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ApprovalCard extends StatefulWidget {
  const _ApprovalCard({
    super.key,
    required this.student,
    required this.teachers,
  });

  final AppUser student;
  final List<AppUser> teachers;

  @override
  State<_ApprovalCard> createState() => _ApprovalCardState();
}

class _ApprovalCardState extends State<_ApprovalCard> {
  final _service = PlacementService();
  late String? _teacherId = widget.teachers
          .any((t) => t.uid == widget.student.teacherId)
      ? widget.student.teacherId
      : null;
  String _level = 'HSK 1';
  bool _levelTouched = false;
  PlacementSummary? _placement;
  bool _loadingPlacement = false;
  bool _busy = false;

  AppUser get _s => widget.student;

  @override
  void initState() {
    super.initState();
    final code = _s.placementResultCode ?? '';
    if (code.isNotEmpty) {
      _loadingPlacement = true;
      _service.registrationPlacement(code).then((p) {
        if (!mounted) return;
        setState(() {
          _placement = p;
          _loadingPlacement = false;
          final rec = p?.recommendedLevel ?? '';
          if (!_levelTouched && AppConstants.hskLevels.contains(rec)) {
            _level = rec;
          }
        });
      }, onError: (_) {
        if (mounted) setState(() => _loadingPlacement = false);
      });
    }
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } on FirebaseFunctionsException catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(testErrorMessage(l, e)),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _approve() async {
    final l = context.l10n;
    final teacherId = _teacherId;
    if (teacherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l.approvalErrTeacher),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    await _run(
      () => _service.approve(_s.uid, level: _level, teacherId: teacherId),
      l.approvalApproved(_s.staffLabel, _level),
    );
  }

  Future<void> _reject() async {
    final l = context.l10n;
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(l.approvalRejectTitle(_s.staffLabel)),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            decoration: InputDecoration(labelText: l.approvalRejectReason),
            onChanged: (_) => setLocal(() {}),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.commonCancel),
            ),
            FilledButton(
              onPressed: controller.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(ctx, controller.text.trim()),
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: Text(l.approvalReject),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (reason == null || reason.isEmpty || !mounted) return;
    await _run(() => _service.reject(_s.uid, reason), l.approvalRejected);
  }

  Future<void> _delete() async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.adminUsersDeleteTitle(_s.staffLabel)),
        content: Text(l.adminUsersDeleteBody(_s.email)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l.adminUsersDeleteAccount),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _run(
      () => FirebaseFunctions.instance
          .httpsCallable('deleteUserAccount')
          .call({'uid': _s.uid}),
      l.adminUsersDeleted(_s.email),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final created = _s.createdAt;
    final choice = _s.placementChoice == AppUser.choiceTest
        ? l.waitingChoiceTest(_s.placementTarget ?? '')
        : l.registerChoiceHsk1;
    final claimedByOther = _placement?.claimedByOther(_s.uid) ?? false;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _s.staffLabel,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              _Fact(Icons.email_outlined, _s.email),
              if ((_s.displayWhatsapp ?? '').isNotEmpty)
                _Fact(Icons.chat_outlined, _s.displayWhatsapp!),
              if (created != null)
                _Fact(Icons.event_outlined,
                    DateFormat.yMMMd().add_Hm().format(created)),
            ],
          ),
          const SizedBox(height: 8),
          Text('${l.waitingYourChoice} $choice',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          if ((_s.placementResultCode ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(l.waitingResultCode(_s.placementResultCode!),
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            if (_loadingPlacement)
              const LinearProgressIndicator()
            else if (_placement == null)
              Text(l.placementErrBadResultCode,
                  style: TextStyle(color: AppColors.error))
            else ...[
              PlacementSummaryBox(summary: _placement!),
              if (claimedByOther)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(l.placementErrClaimed,
                      style: TextStyle(color: AppColors.error)),
                ),
            ],
          ],
          if (_s.isRejected) ...[
            const SizedBox(height: 8),
            Text(l.approvalRejectedBecause(_s.rejectReason ?? '—'),
                style: TextStyle(color: AppColors.error)),
          ],
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, c) {
            final teacher = DropdownButtonFormField<String>(
              initialValue: _teacherId,
              isExpanded: true,
              decoration: InputDecoration(labelText: l.approvalTeacher),
              items: [
                for (final t in widget.teachers)
                  DropdownMenuItem(
                    value: t.uid,
                    child: Text(t.staffLabel, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: _busy ? null : (v) => setState(() => _teacherId = v),
            );
            final level = DropdownButtonFormField<String>(
              key: ValueKey('level_$_level'),
              initialValue: _level,
              decoration: InputDecoration(labelText: l.approvalStartLevel),
              items: [
                for (final lv in AppConstants.hskLevels)
                  DropdownMenuItem(value: lv, child: Text(lv)),
              ],
              onChanged: _busy
                  ? null
                  : (v) => setState(() {
                        _level = v ?? _level;
                        _levelTouched = true;
                      }),
            );
            if (c.maxWidth < 480) {
              return Column(children: [teacher, const SizedBox(height: 8), level]);
            }
            return Row(children: [
              Expanded(flex: 3, child: teacher),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: level),
            ]);
          }),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              if (_s.isRejected)
                TextButton.icon(
                  onPressed: _busy ? null : _delete,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l.adminUsersDeleteAccount),
                  style:
                      TextButton.styleFrom(foregroundColor: AppColors.error),
                ),
              if (!_s.isRejected)
                OutlinedButton.icon(
                  onPressed: _busy ? null : _reject,
                  icon: const Icon(Icons.close),
                  label: Text(l.approvalReject),
                  style:
                      OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                ),
              FilledButton.icon(
                onPressed: _busy || claimedByOther ? null : _approve,
                icon: const Icon(Icons.check),
                label: Text(l.approvalApprove),
                style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(text,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ),
      ],
    );
  }
}
