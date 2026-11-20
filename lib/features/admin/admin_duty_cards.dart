import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/responsive_card_grid.dart';
import '../../l10n/l10n.dart';
import '../../models/app_user.dart';
import '../../models/class_session.dart';
import '../../models/progress_summary.dart';
import '../../services/firestore_service.dart';
import '../../services/progress_service.dart';
import '../../services/timetable_service.dart';
import 'admin_dashboard_widgets.dart';

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
  });

  final int pendingRegistrations;
  final int unconfirmedSchedules;
  final int lateToday;
  final int lateWeek;
  final int unclosed;
  final int needingAttention;
  final int todaySessions;

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

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
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
            return ResponsiveCardGrid(
              minCardWidth: 200,
              maxColumns: 3,
              children: [
                AdminStatCard(
                  label: l.dutyPending,
                  value: '${c.pendingRegistrations}',
                  icon: Icons.how_to_reg_outlined,
                  color: AppColors.chipAmberFg,
                  onTap: () => context.push('/admin/users/approval'),
                ),
                AdminStatCard(
                  label: l.dutyUnconfirmed,
                  value: '${c.unconfirmedSchedules}',
                  icon: Icons.event_note_outlined,
                  color: AppColors.navy,
                  onTap: () => context.push('/admin/timetable?view=followup'),
                ),
                AdminStatCard(
                  label: l.dutyLate,
                  value: '${c.lateToday}',
                  subtitle: l.dutyLateWeek(c.lateWeek),
                  icon: Icons.timer_off_outlined,
                  color: AppColors.error,
                  onTap: () => context.push('/admin/timetable?view=followup'),
                ),
                AdminStatCard(
                  label: l.dutyUnclosed,
                  value: '${c.unclosed}',
                  icon: Icons.lock_open_outlined,
                  color: AppColors.error,
                  onTap: () => context.push('/admin/timetable?view=followup'),
                ),
                AdminStatCard(
                  label: l.dutyAttention,
                  value: '${c.needingAttention}',
                  icon: Icons.flag_outlined,
                  color: AppColors.chipAmberFg,
                  onTap: () => context.push('/admin/attention'),
                ),
                AdminStatCard(
                  label: l.dutyToday,
                  value: '${c.todaySessions}',
                  icon: Icons.today_outlined,
                  color: AppColors.teal,
                  onTap: widget.onOpenClasses,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
