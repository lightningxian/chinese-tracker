import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../l10n/l10n.dart';
import '../../services/timetable_service.dart';

/// Build 6 (Must 7): **Sesi Kelas** — the centre's sessions of the next 14
/// days with seats left, **Daftar** / **Batalkan**, and the refusal reason
/// in words. The student books for themself; a parent for the child
/// ([forStudentId]).
class StudentSessionsSection extends StatefulWidget {
  const StudentSessionsSection({
    super.key,
    required this.studentId,
    required this.studentLevel,
    this.forStudentId,
  });

  final String studentId;
  final String studentLevel;

  /// Set when a parent books for the child.
  final String? forStudentId;

  @override
  State<StudentSessionsSection> createState() => _StudentSessionsSectionState();
}

class _StudentSessionsSectionState extends State<StudentSessionsSection> {
  final _service = TimetableService();
  late final String _today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  late final Stream<List<BookableSession>> _sessions = _service.watchUpcoming(_today);
  late final Stream<Set<String>> _mine = _service.watchMyBookings(widget.studentId);
  late final Stream<Set<String>> _waiting = _service.watchMyWaitlist(widget.studentId);
  bool _myLevelOnly = false;
  String? _busy;

  String _reasonText(String reason) {
    final l = context.l10n;
    return switch (reason) {
      'full' => l.bookingFull,
      'no_sessions' => l.bookingNoSessions,
      'expired' => l.bookingExpired,
      'overlap' => l.bookingOverlap,
      'too_late' => l.bookingTooLate,
      'needs_teacher' => l.bookingNeedsTeacher,
      'level' => l.bookingLevel,
      'not-yours' => l.bookingNotYours,
      'not_full' => l.waitlistNotFull,
      'already' => l.waitlistAlready,
      _ => l.bookingFailed,
    };
  }

  Future<void> _run(String id, Future<void> Function() action, String done) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = id);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } on BookingException catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(_reasonText(e.reason)),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final end = DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 14)));
    return StreamBuilder<Set<String>>(
      stream: _waiting,
      builder: (context, waitSnap) => StreamBuilder<Set<String>>(
      stream: _mine,
      builder: (context, mineSnap) {
        final mine = mineSnap.data ?? const <String>{};
        final waiting = waitSnap.data ?? const <String>{};
        return StreamBuilder<List<BookableSession>>(
          stream: _sessions,
          builder: (context, snap) {
            var rows = (snap.data ?? const <BookableSession>[])
                .where((s) => s.date.compareTo(end) <= 0 && !s.isOver)
                .toList();
            if (_myLevelOnly) {
              rows = rows
                  .where((s) => s.level.isEmpty || s.level == widget.studentLevel)
                  .toList();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(l.bookingTitle,
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: AppColors.navy)),
                    ),
                    FilterChip(
                      label: Text(l.bookingMyLevel),
                      selected: _myLevelOnly,
                      onSelected: (v) => setState(() => _myLevelOnly = v),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (snap.connectionState == ConnectionState.waiting && !snap.hasData)
                  const LinearProgressIndicator()
                else if (rows.isEmpty)
                  AppCard(
                    child: Text(l.bookingNone,
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                for (final s in rows)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _SessionRow(
                      session: s,
                      booked: mine.contains(s.id),
                      waiting: waiting.contains(s.id),
                      busy: _busy == s.id,
                      onWait: () => _run(
                          s.id,
                          () => _service.joinWaitlist(s.id, studentId: widget.forStudentId),
                          l.waitlistJoined),
                      onLeaveWait: () => _run(
                          s.id,
                          () => _service.leaveWaitlist(s.id, studentId: widget.forStudentId),
                          l.waitlistLeft),
                      onBook: () => _run(
                          s.id,
                          () => _service.book(s.id, studentId: widget.forStudentId),
                          l.bookingDone),
                      onCancel: () => _run(
                          s.id,
                          () => _service.cancel(s.id, studentId: widget.forStudentId),
                          l.bookingCancelled),
                    ),
                  ),
              ],
            );
          },
        );
      },
    ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({
    required this.session,
    required this.booked,
    required this.busy,
    required this.onBook,
    required this.onCancel,
    this.waiting = false,
    this.onWait,
    this.onLeaveWait,
  });

  final BookableSession session;
  final bool booked;

  /// Owner 2026-11-24: on the waiting list of this (full) class.
  final bool waiting;
  final VoidCallback? onWait;
  final VoidCallback? onLeaveWait;
  final bool busy;
  final VoidCallback onBook;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = session;
    final d = DateTime.tryParse(s.date);
    final day = d == null ? s.date : DateFormat('EEE d MMM').format(d);
    final full = s.seatsLeft <= 0 && !booked;
    final noTeacher = s.status == 'needs_teacher';
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$day · ${clockOf(s.startMinutes)}–${clockOf(s.endMinutes)}',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  [
                    s.title,
                    s.room,
                    if (s.teacherName.isNotEmpty) s.teacherName,
                    s.level.isEmpty ? l.bookingAllLevels : s.level,
                  ].join(' · '),
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                if (s.isGoingOn)
                  Text(booked ? l.bookingGoingOnBooked : l.bookingGoingOn,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.chipAmberFg)),
                if (waiting && !booked)
                  Text(l.waitlistOn,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.chipAmberFg)),
                Text(
                  noTeacher ? l.bookingNeedsTeacher : l.bookingSeatsLeft(s.seatsLeft, s.capacity),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: full || noTeacher ? AppColors.error : AppColors.teal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (busy)
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          else if (booked && s.isGoingOn)
            const Icon(Icons.check_circle, color: Colors.green)
          else if (booked)
            OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
              child: Text(l.bookingCancel),
            )
          else if (waiting)
            OutlinedButton(
              onPressed: onLeaveWait,
              child: Text(l.waitlistLeave),
            )
          else if (full && !noTeacher && !s.isGoingOn && onWait != null)
            // Owner 2026-11-24: a full class takes a waiting list.
            OutlinedButton.icon(
              onPressed: onWait,
              icon: const Icon(Icons.hourglass_empty, size: 16),
              label: Text(l.waitlistJoin),
            )
          else
            FilledButton(
              onPressed: full || noTeacher ? null : onBook,
              style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
              child: Text(full
                  ? l.bookingFullShort
                  : (s.isGoingOn ? l.bookingJoinNow : l.bookingBook)),
            ),
        ],
      ),
    );
  }
}
