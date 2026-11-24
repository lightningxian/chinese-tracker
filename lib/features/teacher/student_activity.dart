import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/money_format.dart';
import '../../core/widgets/app_card.dart';
import '../../l10n/l10n.dart';
import '../../models/attendance_record.dart';
import '../../models/exercise_result.dart';
import '../../models/invoice.dart';
import '../../models/test_track.dart';
import '../../services/firestore_service.dart';
import '../../services/test_service.dart';

/// One line of a student's history.
class _Event {
  const _Event(this.at, this.icon, this.color, this.title, this.detail);
  final DateTime at;
  final IconData icon;
  final Color color;
  final String title;
  final String detail;
}

/// Owner 2026-11-24: what a student did, newest first, in one list: classes
/// (booked, attended, excused, absent), practice, tests, level changes and
/// payments. Read from the documents that already exist.
class StudentActivityTimeline extends StatefulWidget {
  const StudentActivityTimeline({super.key, required this.studentId});

  final String studentId;

  @override
  State<StudentActivityTimeline> createState() => _StudentActivityTimelineState();
}

class _StudentActivityTimelineState extends State<StudentActivityTimeline> {
  late final FirestoreService _fs = context.read<FirestoreService>();
  late final Stream<List<AttendanceRecord>> _attendance =
      _fs.watchStudentAttendance(widget.studentId);
  late final Stream<List<ExerciseResult>> _practice =
      _fs.watchStudentExerciseResults(widget.studentId);
  late final Stream<List<TestResult>> _tests = TestService().watchMyResults(widget.studentId);
  late final Stream<List<Invoice>> _invoices = _fs.watchStudentInvoices(widget.studentId);
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _levels = FirebaseFirestore.instance
      .collection('users')
      .doc(widget.studentId)
      .collection('level_history')
      .snapshots();
  int _shown = 30;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return StreamBuilder<List<AttendanceRecord>>(
      stream: _attendance,
      builder: (context, a) => StreamBuilder<List<ExerciseResult>>(
        stream: _practice,
        builder: (context, p) => StreamBuilder<List<TestResult>>(
          stream: _tests,
          builder: (context, t) => StreamBuilder<List<Invoice>>(
            stream: _invoices,
            builder: (context, inv) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _levels,
              builder: (context, lv) {
                final events = <_Event>[];
                for (final r in a.data ?? const <AttendanceRecord>[]) {
                  final d = DateTime.tryParse(r.sessionDate);
                  if (d == null) continue;
                  final (String what, IconData icon, Color color) = switch (r.normalizedStatus) {
                    AttendanceRecord.hadir => (l.activityAttended, Icons.check_circle_outline, AppColors.success),
                    AttendanceRecord.izin => (l.activityExcused, Icons.event_busy_outlined, AppColors.chipAmberFg),
                    AttendanceRecord.alpa => (l.activityAbsent, Icons.cancel_outlined, AppColors.error),
                    _ => r.status == 'cancelled'
                        ? (l.activityCancelled, Icons.block, AppColors.textSecondary)
                        : (l.activityBooked, Icons.event_available_outlined, AppColors.teal),
                  };
                  events.add(_Event(d, icon, color, '$what · ${r.sessionTitle}',
                      DateFormat('EEE d MMM yyyy').format(d)));
                }
                for (final r in p.data ?? const <ExerciseResult>[]) {
                  final at = r.submittedAt;
                  if (at == null) continue;
                  events.add(_Event(at, Icons.menu_book_outlined, AppColors.navy,
                      l.activityPractice(r.exerciseTitle ?? '—', r.score),
                      DateFormat('d MMM yyyy HH:mm').format(at)));
                }
                for (final r in t.data ?? const <TestResult>[]) {
                  final at = r.finishedAt;
                  if (at == null) continue;
                  events.add(_Event(
                    at,
                    Icons.timer_outlined,
                    r.passed ? AppColors.success : AppColors.chipAmberFg,
                    l.activityTest(r.code, r.total, r.max),
                    '${r.passed ? l.activityPassed : l.activityNotPassed} · ${DateFormat('d MMM yyyy').format(at)}',
                  ));
                }
                for (final i in inv.data ?? const <Invoice>[]) {
                  final at = i.paidAt;
                  if (at == null || !i.isPaid) continue;
                  events.add(_Event(at, Icons.payments_outlined, AppColors.success,
                      l.activityPaid(formatRupiah(i.amount)), i.invoiceNumber));
                }
                for (final d in lv.data?.docs ?? const []) {
                  final m = d.data();
                  final at = (m['date'] as Timestamp?)?.toDate();
                  if (at == null) continue;
                  events.add(_Event(at, Icons.trending_up, AppColors.teal,
                      l.activityLevel('${m['from'] ?? '—'}', '${m['to'] ?? '—'}'),
                      DateFormat('d MMM yyyy').format(at)));
                }
                events.sort((x, y) => y.at.compareTo(x.at));
                if (events.isEmpty) {
                  return AppCard(
                    child: Text(l.activityNone, style: TextStyle(color: AppColors.textSecondary)),
                  );
                }
                final shown = events.take(_shown).toList();
                return AppCard(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final e in shown)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(e.icon, size: 20, color: e.color),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(e.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    Text(e.detail,
                                        style: TextStyle(
                                            fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (events.length > _shown)
                        TextButton(
                          onPressed: () => setState(() => _shown += 30),
                          child: Text(l.activityShowMore(events.length - _shown)),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Owner 2026-11-24: the classes a student is booked into from today on.
class StudentUpcomingClasses extends StatefulWidget {
  const StudentUpcomingClasses({super.key, required this.studentId, this.onOpen});

  final String studentId;
  final void Function(String sessionId)? onOpen;

  @override
  State<StudentUpcomingClasses> createState() => _StudentUpcomingClassesState();
}

class _StudentUpcomingClassesState extends State<StudentUpcomingClasses> {
  late final Stream<List<AttendanceRecord>> _attendance =
      context.read<FirestoreService>().watchStudentAttendance(widget.studentId);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return StreamBuilder<List<AttendanceRecord>>(
      stream: _attendance,
      builder: (context, snap) {
        final list = (snap.data ?? const <AttendanceRecord>[])
            .where((r) => r.inClass && !r.closed && r.sessionDate.compareTo(today) >= 0)
            .toList()
          ..sort((a, b) => a.sessionDate.compareTo(b.sessionDate));
        return AppCard(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          child: list.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(l.activityNoUpcoming,
                      style: TextStyle(color: AppColors.textSecondary)),
                )
              : Column(
                  children: [
                    for (final r in list)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.event_available_outlined, color: AppColors.teal),
                        title: Text(r.sessionTitle,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(DateTime.tryParse(r.sessionDate) == null
                            ? r.sessionDate
                            : DateFormat('EEEE d MMM yyyy').format(DateTime.parse(r.sessionDate))),
                        trailing: widget.onOpen == null ? null : const Icon(Icons.chevron_right),
                        onTap: widget.onOpen == null ? null : () => widget.onOpen!(r.sessionId),
                      ),
                  ],
                ),
        );
      },
    );
  }
}
