import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../l10n/l10n.dart';
import '../../models/app_user.dart';
import '../../models/class_session.dart';
import '../../models/progress_summary.dart';
import '../../services/firestore_service.dart';
import '../../services/progress_service.dart';
import '../../services/timetable_service.dart';
import 'dashboard_extras.dart';

/// Build 8 (Must 1): the six counts of the proposal's admin dashboard.
class DutyCounts {
  const DutyCounts({
    required this.pendingRegistrations,
    required this.unconfirmedSchedules,
    required this.lateToday,
    required this.lateWeek,
    required this.unclosed,
    required this.needingAttention,
    required this.todaySessions,
    this.todayList = const [],
  });

  final int pendingRegistrations;
  final int unconfirmedSchedules;
  final int lateToday;
  final int lateWeek;
  final int unclosed;
  final int needingAttention;
  final int todaySessions;

  /// Today's sessions that are not cancelled (the countdown).
  final List<ClassSession> todayList;

  static String _key(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  /// Pure mapping from the streams to the counts (unit-tested).
  static DutyCounts compute({
    required List<AppUser> users,
    required List<Schedule> schedules,
    required List<ClassSession> sessions,
    required List<ProgressSummary> summaries,
    required DateTime now,
  }) {
    final today = _key(now);
    final weekStart = _key(now.subtract(const Duration(days: 6)));
    bool late(ClassSession s) => s.lateCheckIn || s.lateMinutes > 0;
    final live = sessions.where((s) => !s.isCancelled).toList();
    return DutyCounts(
      pendingRegistrations: users.where((u) => u.isStudent && u.isPending).length,
      unconfirmedSchedules:
          schedules.where((s) => s.active && s.status != 'confirmed').length,
      lateToday: live.where((s) => s.sessionDate == today && late(s)).length,
      lateWeek: live
          .where((s) =>
              s.sessionDate.compareTo(weekStart) >= 0 &&
              s.sessionDate.compareTo(today) <= 0 &&
              late(s))
          .length,
      unclosed: live.where((s) => s.unclosed && !s.isClosedOrCancelled).length,
      needingAttention:
          summaries.where((s) => s.status != ProgressStatus.good).length,
      todaySessions: live.where((s) => s.sessionDate == today).length,
      todayList: live.where((s) => s.sessionDate == today).toList(),
    );
  }
}

/// The six cards; each opens its list.
class AdminDutyCards extends StatefulWidget {
  const AdminDutyCards({super.key, required this.users, required this.onOpenClasses});

  final List<AppUser> users;
  final VoidCallback onOpenClasses;

  @override
  State<AdminDutyCards> createState() => _AdminDutyCardsState();
}

class _AdminDutyCardsState extends State<AdminDutyCards> {
  late final Stream<List<Schedule>> _schedules = TimetableService().watchSchedules();
  late final Stream<List<ClassSession>> _sessions =
      context.read<FirestoreService>().watchAllClassSessions();
  late final Stream<List<ProgressSummary>> _summaries = ProgressService().watchSummaries();
  late final Stream<SchedulingRules> _rules = TimetableService().watchSettings();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return StreamBuilder<SchedulingRules>(
      stream: _rules,
      builder: (context, ru) {
    // Owner 2026-11-23: unconfirmed schedules and late check-ins only with
    // the teacher-readiness switch on.
    final ready = ru.data?.teacherReadiness ?? false;
    return StreamBuilder<List<Schedule>>(
      stream: _schedules,
      builder: (context, sc) => StreamBuilder<List<ClassSession>>(
        stream: _sessions,
        builder: (context, se) => StreamBuilder<List<ProgressSummary>>(
          stream: _summaries,
          builder: (context, su) {
            final c = DutyCounts.compute(
              users: widget.users,
              schedules: sc.data ?? const [],
              sessions: se.data ?? const [],
              summaries: su.data ?? const [],
              now: DateTime.now(),
            );
            // Owner 2026-11-24: one calm card instead of six tiles. Rows
            // with nothing to do are quiet; the header says how many classes
            // run today.
            final rows = <_DutyRow>[
              _DutyRow(l.dutyPending, c.pendingRegistrations, Icons.how_to_reg_outlined,
                  () => context.push('/admin/users/approval')),
              if (ready)
                _DutyRow(l.dutyUnconfirmed, c.unconfirmedSchedules, Icons.event_note_outlined,
                    () => context.push('/admin/timetable?view=followup')),
              if (ready)
                _DutyRow(l.dutyLate, c.lateToday, Icons.timer_off_outlined,
                    () => context.push('/admin/timetable?view=followup'),
                    note: c.lateWeek > 0 ? l.dutyLateWeek(c.lateWeek) : null),
              _DutyRow(l.dutyUnclosed, c.unclosed, Icons.lock_open_outlined,
                  () => context.push('/admin/timetable?view=followup')),
              _DutyRow(l.dutyAttention, c.needingAttention, Icons.flag_outlined,
                  () => context.push('/admin/attention')),
            ];
            final open = rows.where((r) => r.count > 0).length;
            return AppCard(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.dashTodayTitle,
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text(
                              open == 0 ? l.dashAllClear : l.dashOpenTasks(open),
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                            // Owner 2026-11-24: a countdown to the next class.
                            NextClassCountdown(sessions: c.todayList),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: widget.onOpenClasses,
                        icon: const Icon(Icons.today_outlined, size: 18),
                        label: Text(l.dashClassesToday(c.todaySessions)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (var k = 0; k < rows.length; k++) ...[
                    if (k > 0) Divider(height: 1, color: AppColors.border),
                    _DutyTile(row: rows[k]),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
      },
    );
  }
}

class _DutyRow {
  const _DutyRow(this.label, this.count, this.icon, this.onTap, {this.note});
  final String label;
  final int count;
  final IconData icon;
  final VoidCallback onTap;
  final String? note;
}

class _DutyTile extends StatelessWidget {
  const _DutyTile({required this.row});
  final _DutyRow row;

  @override
  Widget build(BuildContext context) {
    final busy = row.count > 0;
    final fg = busy ? AppColors.ink : AppColors.textSecondary;
    return InkWell(
      onTap: row.onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
        child: Row(
          children: [
            Icon(row.icon, size: 20, color: busy ? AppColors.chipAmberFg : AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: row.label),
                  if (row.note != null)
                    TextSpan(
                      text: '  ·  ${row.note}',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                    ),
                ]),
                style: TextStyle(color: fg, fontWeight: busy ? FontWeight.w600 : FontWeight.w400),
              ),
            ),
            if (busy)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.chipAmberFg.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('${row.count}',
                    style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.chipAmberFg)),
              )
            else
              Icon(Icons.check_circle_outline, size: 18, color: AppColors.success),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
