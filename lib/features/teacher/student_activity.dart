import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/paging/date_range.dart';
import '../../core/paging/paged_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/money_format.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/paging_bars.dart';
import '../../l10n/l10n.dart';
import '../../models/attendance_record.dart';
import '../../models/exercise_result.dart';
import '../../models/invoice.dart';
import '../../models/test_track.dart';
import '../../services/firestore_service.dart';
import '../../services/test_service.dart';

/// One line of a student's history, kept as data; the words are made in
/// the language on screen when the line is drawn.
class _Event {
  const _Event(this.at, this.build);
  final DateTime at;
  final (IconData, Color, String, String) Function(AppLocalizations l) build;
}

/// Owner 2026-11-24: what a student did, newest first, in one list: classes
/// (booked, attended, excused, absent), practice, tests, level changes and
/// payments. Build 9 part 2: one page at a time in a date range, merged
/// from the five sources (each reads at most a page), not every document
/// of the student streamed at once.
class StudentActivityTimeline extends StatefulWidget {
  const StudentActivityTimeline({super.key, required this.studentId});

  final String studentId;

  @override
  State<StudentActivityTimeline> createState() => _StudentActivityTimelineState();
}

class _StudentActivityTimelineState extends State<StudentActivityTimeline> {
  late final FirestoreService _fs = context.read<FirestoreService>();
  late final PagedController<_Event> _pages = PagedController<_Event>(
    range: DateRangeSel.preset(RangePreset.thisYear),
    build: _source,
  );

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  PageSource<_Event> _source(DateRangeSel range) {
    final id = widget.studentId;
    final db = FirebaseFirestore.instance;
    final visits = MappedPageSource<AttendanceRecord, _Event?>(
      _fs.studentVisitSource(id, range),
      (page) async => [for (final r in page) _visit(r)],
    );
    final practice = FirestorePageSource<_Event?>(
        _fs.studentResultsQuery(id, range), (d) {
      final r = ExerciseResult.fromFirestore(d);
      final at = r.submittedAt;
      if (at == null) return null;
      return _Event(at, (l) => (
            Icons.menu_book_outlined,
            AppColors.navy,
            l.activityPractice(r.exerciseTitle ?? '—', r.score),
            DateFormat('d MMM yyyy HH:mm').format(at),
          ));
    });
    final tests = MappedPageSource<TestResult, _Event?>(
      TestService().resultSource(range, studentId: id),
      (page) async => [
        for (final r in page)
          if (r.finishedAt == null)
            null
          else
            _Event(r.finishedAt!, (l) => (
                  Icons.timer_outlined,
                  r.passed ? AppColors.success : AppColors.chipAmberFg,
                  l.activityTest(r.code, r.total, r.max),
                  '${r.passed ? l.activityPassed : l.activityNotPassed} · ${DateFormat('d MMM yyyy').format(r.finishedAt!)}',
                )),
      ],
    );
    final paid = FirestorePageSource<_Event?>(
      applyDateRange(
        db
            .collection(AppConstants.invoicesCollection)
            .where('studentId', isEqualTo: id)
            .where('status', isEqualTo: 'paid')
            .orderBy('paidAt', descending: true),
        'paidAt',
        range,
      ),
      (d) {
        final i = Invoice.fromFirestore(d);
        final at = i.paidAt;
        if (at == null) return null;
        return _Event(at, (l) => (
              Icons.payments_outlined,
              AppColors.success,
              l.activityPaid(formatRupiah(i.amount)),
              i.invoiceNumber,
            ));
      },
    );
    final levels = FirestorePageSource<_Event?>(
      applyDateRange(
        db
            .collection('users')
            .doc(id)
            .collection('level_history')
            .orderBy('date', descending: true),
        'date',
        range,
      ),
      (d) {
        final m = d.data() ?? const <String, dynamic>{};
        final at = (m['date'] as Timestamp?)?.toDate();
        if (at == null) return null;
        return _Event(at, (l) => (
              Icons.trending_up,
              AppColors.teal,
              l.activityLevel('${m['from'] ?? '—'}', '${m['to'] ?? '—'}'),
              DateFormat('d MMM yyyy').format(at),
            ));
      },
    );
    final merged = MergedPageSource<_Event?>(
      [visits, practice, tests, paid, levels],
      newer: (a, b) => (a?.at ?? DateTime(1970)).isAfter(b?.at ?? DateTime(1970)),
    );
    return MappedPageSource<_Event?, _Event>(
      FilteredPageSource<_Event?>(merged, (e) => e != null, innerCount: true),
      (page) async => [for (final e in page) e!],
    );
  }

  static _Event? _visit(AttendanceRecord r) {
    final d = DateTime.tryParse(r.sessionDate);
    if (d == null) return null;
    return _Event(d, (l) {
      final (String what, IconData icon, Color color) = switch (r.normalizedStatus) {
        AttendanceRecord.hadir => (l.activityAttended, Icons.check_circle_outline, AppColors.success),
        AttendanceRecord.izin => (l.activityExcused, Icons.event_busy_outlined, AppColors.chipAmberFg),
        AttendanceRecord.alpa => (l.activityAbsent, Icons.cancel_outlined, AppColors.error),
        _ => r.status == 'cancelled'
            ? (l.activityCancelled, Icons.block, AppColors.textSecondary)
            : (l.activityBooked, Icons.event_available_outlined, AppColors.teal),
      };
      return (icon, color, '$what · ${r.sessionTitle}', DateFormat('EEE d MMM yyyy').format(d));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListenableBuilder(
      listenable: _pages,
      builder: (context, _) => AppCard(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: PagedListBody<_Event>(
          controller: _pages,
          inline: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          separator: 0,
          header: DateRangeBar(value: _pages.range, onChanged: _pages.setRange),
          emptyIcon: Icons.history,
          emptyTitle: l.activityNone,
          itemBuilder: (context, e) {
            final (icon, color, title, detail) = e.build(l);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 20, color: color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(detail,
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
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
  // Build 9 part 2: only the classes from today on (bounded), not every
  // class the student ever booked.
  static final String _today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  late final Stream<List<AttendanceRecord>> _attendance = FirebaseFirestore.instance
      .collection(AppConstants.attendanceCollection)
      .where('studentId', isEqualTo: widget.studentId)
      .where('sessionDate', isGreaterThanOrEqualTo: _today)
      .orderBy('sessionDate')
      .limit(60)
      .snapshots()
      .map((s) => s.docs.map(AttendanceRecord.fromFirestore).toList());

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
