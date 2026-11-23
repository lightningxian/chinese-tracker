import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/conclude_class_dialog.dart';
import '../../l10n/l10n.dart';
import '../../models/class_session.dart';
import '../../services/auth_service.dart';
import '../../services/teaching_day_service.dart';
import '../../services/timetable_service.dart';

/// Build 7: the words for a session's life status.
String sessionStatusLabel(AppLocalizations l, String status) => switch (status) {
      'ongoing' => l.sessionStatusOngoing,
      'done' => l.sessionStatusDone,
      'cancelled' => l.sessionStatusCancelled,
      'needs_teacher' => l.sessionStatusNeedsTeacher,
      _ => l.sessionStatusScheduled,
    };

/// The reason codes of the teaching-day functions, in words.
String teachingDayReasonText(AppLocalizations l, TeachingDayException e) =>
    switch (e.reason) {
      'too_early' => l.checkInTooEarly,
      'too_late' => l.checkInTooLate,
      'not-started' => l.closeNotStarted,
      'not-yours' => l.sessionNotYours,
      'admin-only' => l.cancelAdminOnly,
      'done' => l.sessionAlreadyClosed,
      'cancelled' => l.sessionStatusCancelled,
      _ => e.message,
    };

Color _statusColor(String status) => switch (status) {
      'ongoing' => AppColors.teal,
      'done' => AppColors.navy,
      'cancelled' => AppColors.error,
      'needs_teacher' => AppColors.chipAmberFg,
      _ => AppColors.textSecondary,
    };

Widget _chip(String text, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );

/// Status chips: the life status, late check-in, unclosed, substitute.
class SessionStatusChips extends StatelessWidget {
  const SessionStatusChips({super.key, required this.session});

  final ClassSession session;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final st = session.lifeStatus;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _chip(sessionStatusLabel(l, st), _statusColor(st)),
        if (session.lateCheckIn || session.lateMinutes > 0)
          _chip(
              session.lateMinutes > 0
                  ? l.sessionLateMinutes(session.lateMinutes)
                  : l.sessionLateCheckIn,
              AppColors.chipAmberFg),
        if (session.unclosed && !session.isClosedOrCancelled)
          _chip(l.sessionUnclosed, AppColors.error),
        if (session.substituteFor.isNotEmpty) _chip(l.sessionSubstitute, AppColors.teal),
      ],
    );
  }
}

/// The buttons of a session's life: **Mulai sesi** (check-in), **Tutup
/// sesi** (attendance + the close), and for the admin **Substitute** and
/// **Cancel** (a teacher may cancel only their own one-off session).
class SessionLifeActions extends StatefulWidget {
  const SessionLifeActions({super.key, required this.session, this.onChanged});

  final ClassSession session;
  final VoidCallback? onChanged;

  @override
  State<SessionLifeActions> createState() => _SessionLifeActionsState();
}

class _SessionLifeActionsState extends State<SessionLifeActions> {
  final _service = TeachingDayService();
  late final Stream<SchedulingRules> _rules = TimetableService().watchSettings();
  bool _busy = false;

  ClassSession get s => widget.session;

  Future<void> _run(Future<String?> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      final msg = await action();
      if (msg != null) messenger.showSnackBar(SnackBar(content: Text(msg)));
      widget.onChanged?.call();
    } on TeachingDayException catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text(teachingDayReasonText(l, e)), backgroundColor: AppColors.error));
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkIn() => _run(() async {
        final l = context.l10n;
        final late = await _service.checkIn(s.id);
        return late > 0 ? l.checkInDoneLate(late) : l.checkInDone;
      });

  Future<void> _close() async {
    final l = context.l10n;
    final check = await ConcludeClassDialog.showWithBoard(context,
        sessionId: s.id, sessionTitle: s.sessionTitle);
    if (check == null || !mounted) return;
    await _run(() async {
      final r = await _service.close(s.id, check.statuses, board: check);
      if (r.already) return l.closeAlreadyDone;
      return r.failed.isEmpty
          ? l.closeDone(r.credited, r.excused)
          : l.closeDoneWithFailures(r.credited, r.failed.join(', '));
    });
  }

  Future<void> _cancel() async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.cancelSessionTitle),
        content: Text(l.cancelSessionBody(s.sessionTitle, s.sessionDate)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancelSessionKeep)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.cancelSessionConfirm),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _run(() async {
      await _service.cancel(s.id);
      return l.cancelSessionDone;
    });
  }

  Future<void> _substitute() async {
    final l = context.l10n;
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.substituteTitle),
        content: SizedBox(
          width: 380,
          child: FutureBuilder<List<({String uid, String name})>>(
            future: _service.substituteCandidates(s.id),
            builder: (ctx, snap) {
              if (snap.hasError) {
                return Text('${snap.error}', style: TextStyle(color: AppColors.error));
              }
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final list = snap.data!;
              if (list.isEmpty) return Text(l.substituteNone);
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.substituteHint,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 8),
                  for (final c in list)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.person_outline),
                      title: Text(c.name),
                      onTap: () => Navigator.pop(ctx, c.uid),
                    ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.commonCancel)),
        ],
      ),
    );
    if (picked == null || !mounted) return;
    await _run(() async {
      await _service.assignSubstitute(s.id, picked);
      return l.substituteDone;
    });
  }

  ButtonStyle get _small => FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 34),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      );

  ButtonStyle get _smallOutlined => OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 34),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final user = context.watch<AuthService>().appUser;
    final admin = user?.isAdmin == true;
    final mine = user != null &&
        (user.uid == s.teacherId || s.coTeacherIds.contains(user.uid));
    final st = s.lifeStatus;
    final open = !s.isClosedOrCancelled;
    final canRun = admin || mine;
    // Owner 2026-11-23: the session starts by itself at its start time;
    // the teacher's check-in only records their arrival (late after 15 min).
    final showCheckIn = mine && open && s.generated && s.checkInAt == null &&
        (st == 'scheduled' || st == 'ongoing') && user.uid == s.teacherId;
    final showClose = canRun && open && st != 'needs_teacher' &&
        (st == 'ongoing' || !s.generated);
    final showSub = admin && open;
    final showCancel = open && (admin || (mine && s.scheduleId.isEmpty));
    return StreamBuilder<SchedulingRules>(
      stream: _rules,
      builder: (context, ru) {
    // Owner 2026-11-23: the teacher check-in only with teacher readiness on.
    final checkIn = showCheckIn && (ru.data?.teacherReadiness ?? false);
    if (!checkIn && !showClose && !showSub && !showCancel) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (checkIn)
          FilledButton.icon(
            onPressed: _busy ? null : _checkIn,
            style: _small.copyWith(backgroundColor: WidgetStatePropertyAll(AppColors.navy)),
            icon: const Icon(Icons.how_to_reg_outlined, size: 16),
            label: Text(l.checkInButton),
          ),
        if (showClose)
          FilledButton.icon(
            onPressed: _busy ? null : _close,
            style: _small.copyWith(backgroundColor: WidgetStatePropertyAll(AppColors.teal)),
            icon: const Icon(Icons.done_all, size: 16),
            label: Text(l.closeSessionButton),
          ),
        if (showSub)
          OutlinedButton.icon(
            onPressed: _busy ? null : _substitute,
            style: _smallOutlined,
            icon: const Icon(Icons.swap_horiz, size: 16),
            label: Text(l.substituteButton),
          ),
        if (showCancel)
          OutlinedButton.icon(
            onPressed: _busy ? null : _cancel,
            style: _smallOutlined.copyWith(
                foregroundColor: WidgetStatePropertyAll(AppColors.error)),
            icon: const Icon(Icons.event_busy_outlined, size: 16),
            label: Text(l.cancelSessionButton),
          ),
        if (_busy)
          const SizedBox(
              width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
      ],
    );
      },
    );
  }
}
