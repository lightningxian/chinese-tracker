import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/attendance_record.dart';
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
  }) {
    return showDialog<Map<String, String>>(
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

  String _statusFor(AttendanceRecord r) =>
      _statuses[r.studentId] ?? r.normalizedStatus ?? AttendanceRecord.hadir;

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    return AlertDialog(
      title: const Text('Conclude class'),
      content: SizedBox(
        width: 460,
        child: StreamBuilder<List<AttendanceRecord>>(
          stream: firestore.watchSessionAttendance(widget.sessionId),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final pending = (snap.data ?? const [])
                .where((r) => r.attended && !r.sessionCredited)
                .toList()
              ..sort((a, b) =>
                  (a.studentName ?? '').compareTo(b.studentName ?? ''));

            final charged = pending
                .where((r) => _statusFor(r) != AttendanceRecord.izin)
                .length;

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
                  'Mark who came. Hadir and Alpa charge 1 session from the '
                  "student's term; Izin (excused before class) is not charged.",
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4),
                ),
                const SizedBox(height: 12),
                if (pending.isEmpty)
                  Text(
                    'No students to charge. Concluding only closes the class.',
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
                            Expanded(
                              child: Text(
                                r.studentName?.isNotEmpty == true
                                    ? r.studentName!
                                    : 'Student',
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
                              segments: const [
                                ButtonSegment(
                                    value: AttendanceRecord.hadir,
                                    label: Text('Hadir')),
                                ButtonSegment(
                                    value: AttendanceRecord.izin,
                                    label: Text('Izin')),
                                ButtonSegment(
                                    value: AttendanceRecord.alpa,
                                    label: Text('Alpa')),
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
                    '$charged of ${pending.length} will be charged. This cannot be undone.',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, Map<String, String>.from(_statuses)),
          child: const Text('Conclude class'),
        ),
      ],
    );
  }
}
