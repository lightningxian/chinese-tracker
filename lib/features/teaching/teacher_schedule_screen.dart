import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../l10n/l10n.dart';
import '../../models/app_user.dart';
import '../../models/attendance_record.dart';
import '../../models/class_session.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/teaching_day_service.dart';
import '../../services/timetable_service.dart';
import '../timetable/admin_timetable_screen.dart' show weekdayLabel;
import '../timetable/teacher_availability_card.dart';
import 'session_life.dart';

String _dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

/// Build 7 (Must 1): the teacher's **Schedule**, one screen with three
/// tabs: Today (start, attendance, close), Week (confirm, ask for a
/// change) and Availability (Build 6's editor and days off).
class TeacherScheduleScreen extends StatelessWidget {
  const TeacherScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final user = context.watch<AuthService>().appUser;
    if (user == null) return const SizedBox.shrink();
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Material(
            color: AppColors.card,
            child: TabBar(
              labelColor: AppColors.navy,
              indicatorColor: AppColors.teal,
              tabs: [
                Tab(text: l.scheduleTabToday),
                Tab(text: l.scheduleTabWeek),
                Tab(text: l.timetableAvailability),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _TodayTab(user: user),
                _WeekTab(user: user),
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [TeacherAvailabilityCard(teacher: user)],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayTab extends StatefulWidget {
  const _TodayTab({required this.user});
  final AppUser user;

  @override
  State<_TodayTab> createState() => _TodayTabState();
}

class _TodayTabState extends State<_TodayTab> {
  late final Stream<List<ClassSession>> _sessions =
      context.read<FirestoreService>().watchTeacherSessions(widget.user.uid);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final today = _dateKey(DateTime.now());
    return StreamBuilder<List<ClassSession>>(
      stream: _sessions,
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final list = snap.data!.where((s) => s.sessionDate == today).toList()
          ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 10),
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(l.scheduleNoSessionsToday,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            for (final s in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SessionDayCard(session: s),
              ),
          ],
        );
      },
    );
  }
}

/// One session of the day: time, room, status, the booked students and
/// the life buttons.
class SessionDayCard extends StatelessWidget {
  const SessionDayCard({super.key, required this.session, this.showDate = false});

  final ClassSession session;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = session;
    final firestore = context.read<FirestoreService>();
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.sessionTitle,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 2),
          Text(
            [
              if (showDate) s.sessionDate,
              s.timeRangeLabel,
              if ((s.room ?? '').isNotEmpty) s.room!,
              if (s.level.isNotEmpty) s.level,
              if (s.teacherName.isNotEmpty) s.teacherName,
            ].join(' · '),
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          SessionStatusChips(session: s),
          const SizedBox(height: 8),
          StreamBuilder<List<AttendanceRecord>>(
            stream: firestore.watchSessionAttendance(s.id),
            builder: (context, snap) {
              final rows = (snap.data ?? const <AttendanceRecord>[])
                  .where((r) => r.inClass)
                  .toList()
                ..sort((a, b) => (a.studentName ?? '').compareTo(b.studentName ?? ''));
              if (rows.isEmpty) {
                return Text(l.scheduleNoStudents,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12));
              }
              final names = rows.map((r) {
                final name =
                    r.studentName?.isNotEmpty == true ? r.studentName! : l.commonStudent;
                final st = r.normalizedStatus;
                return st == null || !s.isClosedOrCancelled ? name : '$name ($st)';
              }).join(', ');
              return Text(
                '${l.scheduleStudents(rows.length)}: $names',
                style: const TextStyle(fontSize: 12, height: 1.4),
              );
            },
          ),
          const SizedBox(height: 10),
          SessionLifeActions(session: s),
        ],
      ),
    );
  }
}

class _WeekTab extends StatefulWidget {
  const _WeekTab({required this.user});
  final AppUser user;

  @override
  State<_WeekTab> createState() => _WeekTabState();
}

class _WeekTabState extends State<_WeekTab> {
  final _timetable = TimetableService();
  final _service = TeachingDayService();
  late final Stream<List<Schedule>> _schedules = _timetable.watchSchedules();
  late final Stream<List<ClassSession>> _sessions =
      context.read<FirestoreService>().watchTeacherSessions(widget.user.uid);
  late final Stream<List<ChangeRequest>> _requests =
      _service.watchChangeRequests(teacherId: widget.user.uid);
  final Set<String> _busy = {};

  Future<void> _confirm(Schedule s) async {
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    setState(() => _busy.add(s.id));
    try {
      await _service.confirmSchedule(s.id);
      messenger.showSnackBar(SnackBar(content: Text(l.scheduleConfirmed)));
    } on TeachingDayException catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text(teachingDayReasonText(l, e)), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _busy.remove(s.id));
    }
  }

  Future<void> _askChange(Schedule s) async {
    final l = context.l10n;
    final reason = TextEditingController();
    final wanted = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.scheduleAskChange),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${weekdayLabel(l, s.weekday)} ${s.timeLabel} · ${s.className}'),
              const SizedBox(height: 10),
              TextField(
                controller: reason,
                maxLength: 500,
                decoration: InputDecoration(labelText: l.scheduleChangeReason),
              ),
              TextField(
                controller: wanted,
                maxLength: 500,
                decoration: InputDecoration(labelText: l.scheduleChangeWanted),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.commonCancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true), child: Text(l.scheduleChangeSend)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _service.requestChange(s.id, reason.text, wanted.text);
      messenger.showSnackBar(SnackBar(content: Text(l.scheduleChangeSent)));
    } on TeachingDayException catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text(e.reason == 'reason-required' ? l.scheduleChangeReasonRequired : e.message),
          backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final now = DateTime.now();
    final days = [for (var i = 0; i < 7; i++) _dateKey(now.add(Duration(days: i)))];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l.scheduleMySchedules,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 8),
        StreamBuilder<List<Schedule>>(
          stream: _schedules,
          builder: (context, snap) {
            final mine = (snap.data ?? const <Schedule>[])
                .where((s) => s.active && s.teacherId == widget.user.uid)
                .toList();
            if (mine.isEmpty) {
              return Text(l.scheduleNoSchedules,
                  style: TextStyle(color: AppColors.textSecondary));
            }
            return Column(
              children: [
                for (final s in mine)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      padding: const EdgeInsets.all(12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '${weekdayLabel(l, s.weekday)} ${s.timeLabel} · ${s.className} · ${s.room}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            s.status == 'confirmed'
                                ? l.scheduleStatusConfirmed
                                : l.scheduleStatusUnconfirmed,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: s.status == 'confirmed'
                                  ? AppColors.success
                                  : AppColors.chipAmberFg,
                            ),
                          ),
                          if (s.status != 'confirmed')
                            FilledButton(
                              onPressed: _busy.contains(s.id) ? null : () => _confirm(s),
                              child: Text(l.scheduleConfirm),
                            ),
                          OutlinedButton(
                            onPressed: () => _askChange(s),
                            child: Text(l.scheduleAskChange),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<ChangeRequest>>(
          stream: _requests,
          builder: (context, snap) {
            final list = snap.data ?? const <ChangeRequest>[];
            if (list.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.scheduleMyRequests,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 8),
                for (final r in list.take(10))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${r.className}: ${r.reason} — ${changeStatusLabel(l, r.status)}'
                      '${r.note.isNotEmpty ? ' (${r.note})' : ''}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
        Text(l.scheduleNextSevenDays,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 8),
        StreamBuilder<List<ClassSession>>(
          stream: _sessions,
          builder: (context, snap) {
            final list = (snap.data ?? const <ClassSession>[])
                .where((s) => days.contains(s.sessionDate))
                .toList()
              ..sort((a, b) => a.sessionDate != b.sessionDate
                  ? a.sessionDate.compareTo(b.sessionDate)
                  : a.startMinutes.compareTo(b.startMinutes));
            if (list.isEmpty) {
              return Text(l.scheduleNoSessionsWeek,
                  style: TextStyle(color: AppColors.textSecondary));
            }
            return Column(
              children: [
                for (final s in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SessionDayCard(session: s, showDate: true),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

String changeStatusLabel(AppLocalizations l, String status) => switch (status) {
      'done' => l.changeStatusDone,
      'declined' => l.changeStatusDeclined,
      _ => l.changeStatusOpen,
    };
