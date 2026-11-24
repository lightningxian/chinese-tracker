import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/shell_nested_page.dart';
import '../../l10n/l10n.dart';
import '../../models/class_session.dart';
import '../../services/firestore_service.dart';
import '../teacher/teacher_attendance_tab.dart';

/// Owner 2026-11-24: the page of one class, opened by tapping it on the
/// calendar. The facts on top, then the class card in full: close,
/// substitute, cancel, edit, add a student, and the students.
class ClassDetailPage extends StatefulWidget {
  const ClassDetailPage({super.key, required this.sessionId, this.embedded = false});

  final String sessionId;
  final bool embedded;

  @override
  State<ClassDetailPage> createState() => _ClassDetailPageState();
}

class _ClassDetailPageState extends State<ClassDetailPage> {
  late final Stream<ClassSession?> _session =
      context.read<FirestoreService>().watchClassSession(widget.sessionId);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return StreamBuilder<ClassSession?>(
      stream: _session,
      builder: (context, snap) {
        final session = snap.data;
        return ShellNestedPage(
          embedded: widget.embedded,
          title: session?.sessionTitle ?? l.classDetailTitle,
          child: !snap.hasData && snap.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator())
              : session == null
                  ? Center(child: Text(l.studentClassNotFound))
                  : Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            _Facts(session: session),
                            const SizedBox(height: 16),
                            TeacherClassCard(
                              key: ValueKey('detail-${session.id}'),
                              session: session,
                              historyMode: session.isConcluded,
                            ),
                          ],
                        ),
                      ),
                    ),
        );
      },
    );
  }
}

class _Facts extends StatelessWidget {
  const _Facts({required this.session});

  final ClassSession session;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final date = DateTime.tryParse(session.sessionDate);
    final facts = <(IconData, String, String)>[
      (Icons.event_outlined, l.classDetailTitle,
          '${date == null ? session.sessionDate : DateFormat('EEEE, d MMMM yyyy').format(date)} · ${session.timeRangeLabel}'),
      if ((session.room ?? '').isNotEmpty) (Icons.meeting_room_outlined, l.classInfoRoom, session.room!),
      if (session.teachersLabel.isNotEmpty)
        (Icons.person_outline, l.classInfoTeachers, session.teachersLabel),
      (Icons.school_outlined, l.classInfoLevel, session.level.isEmpty ? l.classAllLevels : session.level),
      (Icons.event_seat_outlined, l.classInfoSeats,
          l.classInfoSeatsValue(session.bookedCount, session.capacity)),
      (Icons.repeat, l.classInfoKind, session.generated ? l.classKindTimetable : l.classKindOneOff),
      if (session.holiday.isNotEmpty) (Icons.celebration_outlined, l.classInfoHoliday, session.holiday),
    ];
    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Wrap(
        spacing: 28,
        runSpacing: 14,
        children: [
          for (final f in facts)
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 180, maxWidth: 380),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(f.$1, size: 20, color: AppColors.teal),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(f.$2,
                            style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                        Text(f.$3, style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
