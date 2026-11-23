import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../models/app_user.dart';
import '../../models/attendance_record.dart';
import '../../models/board_check.dart';

export '../../models/board_check.dart';
import '../../services/firestore_service.dart';
import '../theme/app_theme.dart';

/// Attendance check before a class is concluded.
///
/// Lists every joined student with Hadir / Izin / Alpa. Hadir and Alpa charge
/// one session from the student's term; Izin (excused before the class) does
/// not. Returns `studentId → status` for every listed student, or null when
/// the teacher cancels.
class ConcludeClassDialog extends StatefulWidget {
  const ConcludeClassDialog({
    super.key,
    required this.sessionId,
    required this.sessionTitle,
  });

  final String sessionId;
  final String sessionTitle;

  static Future<Map<String, String>?> show(
    BuildContext context, {
    required String sessionId,
    required String sessionTitle,
  }) async =>
      (await showWithBoard(context, sessionId: sessionId, sessionTitle: sessionTitle))
          ?.statuses;

  /// The statuses plus the attendance-board comparison.
  static Future<BoardCheck?> showWithBoard(
    BuildContext context, {
    required String sessionId,
    required String sessionTitle,
  }) {
    return showDialog<BoardCheck>(
      context: context,
      builder: (_) => ConcludeClassDialog(
        sessionId: sessionId,
        sessionTitle: sessionTitle,
      ),
    );
  }

  @override
  State<ConcludeClassDialog> createState() => _ConcludeClassDialogState();
}

class _ConcludeClassDialogState extends State<ConcludeClassDialog> {
  final Map<String, String> _statuses = {};
  final Map<String, bool> _board = {};
  final _extras = TextEditingController();
  List<AttendanceRecord> _pending = const [];
  Map<String, String> _names = const {};

  @override
  void dispose() {
    _extras.dispose();
    super.dispose();
  }
  late final Stream<List<AppUser>> _students =
      context.read<FirestoreService>().watchAllStudents();

  String _statusFor(AttendanceRecord r) =>
      _statuses[r.studentId] ?? r.normalizedStatus ?? AttendanceRecord.hadir;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final firestore = context.read<FirestoreService>();
    return AlertDialog(
      title: Text(l.concludeTitle),
      content: SizedBox(
        width: 560,
        child: StreamBuilder<List<AppUser>>(
          stream: _students,
          builder: (context, studentsSnap) {
            final studentsById = {
              for (final s in studentsSnap.data ?? const <AppUser>[]) s.uid: s,
            };
            // Staff label (PLAN.md §3), falling back to the stored name.
            String nameOf(AttendanceRecord r) =>
                studentsById[r.studentId]?.staffLabel ??
                (r.studentName?.isNotEmpty == true
                    ? r.studentName!
                    : l.commonStudent);
            return _attendanceList(context, firestore, nameOf);
          },
        ),
      ),
      actions: _actions(context),
    );
  }

  Widget _attendanceList(
    BuildContext context,
    FirestoreService firestore,
    String Function(AttendanceRecord) nameOf,
  ) {
    final l = context.l10n;
    return StreamBuilder<List<AttendanceRecord>>(
      stream: firestore.watchSessionAttendance(widget.sessionId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final pending = (snap.data ?? const [])
            .where((r) => r.inClass && !r.sessionCredited && !r.closed)
            .toList()
          ..sort((a, b) => nameOf(a).compareTo(nameOf(b)));

        final charged = pending
            .where((r) => _statusFor(r) != AttendanceRecord.izin)
            .length;
        _pending = pending;
        _names = {for (final r in pending) r.studentId: nameOf(r)};
        final diff = BoardCheck.differences(
          statusById: {for (final r in pending) r.studentId: _statusFor(r)},
          board: _board,
          nameById: _names,
          extras: _extras.text,
        );
        final diffCount = diff.presentNotSigned.length + diff.signedNotPresent.length +
            diff.notBooked.length;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.sessionTitle,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              l.concludeHint,
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4),
            ),
            const SizedBox(height: 12),
            if (pending.isEmpty)
              Text(
                l.concludeNoStudents,
                style: TextStyle(color: AppColors.textSecondary),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: pending.length,
                  separatorBuilder: (_, __) => const Divider(height: 12),
                  itemBuilder: (context, i) {
                    final r = pending[i];
                    return Row(
                      children: [
                        // Owner 2026-11-23: ticked when the name is on the
                        // attendance board in the room.
                        Tooltip(
                          message: l.boardSigned,
                          child: Checkbox(
                            value: _board[r.studentId] == true,
                            onChanged: (v) =>
                                setState(() => _board[r.studentId] = v ?? false),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            nameOf(r),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SegmentedButton<String>(
                          showSelectedIcon: false,
                          style: const ButtonStyle(
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          segments: [
                            ButtonSegment(
                                value: AttendanceRecord.hadir,
                                label: Text(l.attendancePresent)),
                            ButtonSegment(
                                value: AttendanceRecord.izin,
                                label: Text(l.attendanceExcused)),
                            ButtonSegment(
                                value: AttendanceRecord.alpa,
                                label: Text(l.attendanceAbsent)),
                          ],
                          selected: {_statusFor(r)},
                          onSelectionChanged: (s) => setState(
                              () => _statuses[r.studentId] = s.first),
                        ),
                      ],
                    );
                  },
                ),
              ),
            if (pending.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                l.concludeChargeSummary(charged, pending.length),
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 12),
            Text(l.boardTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(l.boardHelp,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4)),
            const SizedBox(height: 6),
            TextField(
              controller: _extras,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                isDense: true,
                labelText: l.boardExtrasLabel,
                hintText: l.boardExtrasHint,
              ),
            ),
            const SizedBox(height: 8),
            if (diffCount == 0)
              Text(l.boardMatches,
                  style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700))
            else
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.boardDifferences(diffCount),
                        style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
                    if (diff.presentNotSigned.isNotEmpty)
                      Text('• ${l.boardPresentNotSigned}: ${diff.presentNotSigned.join(', ')}'),
                    if (diff.signedNotPresent.isNotEmpty)
                      Text('• ${l.boardSignedNotPresent}: ${diff.signedNotPresent.join(', ')}'),
                    if (diff.notBooked.isNotEmpty)
                      Text('• ${l.boardNotBooked}: ${diff.notBooked.join(', ')}'),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  List<Widget> _actions(BuildContext context) {
    final l = context.l10n;
    return [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(l.commonCancel),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(
          context,
          BoardCheck(
            statuses: {
              for (final r in _pending) r.studentId: _statusFor(r),
              ..._statuses,
            },
            board: {for (final r in _pending) r.studentId: _board[r.studentId] == true},
            extras: _extras.text.trim(),
          ),
        ),
        child: Text(l.concludeTitle),
      ),
    ];
  }
}
