import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../models/class_session.dart';

/// Week/Day/Month calendar over class sessions. Shared by teacher, student and
/// parent — pass the session stream for whichever scope you need.
class ClassCalendarScreen extends StatefulWidget {
  const ClassCalendarScreen({
    super.key,
    required this.title,
    required this.sessions,
    this.onTapSession,
    this.showAppBar = true,
  });

  final String title;
  final Stream<List<ClassSession>> sessions;
  final void Function(ClassSession session)? onTapSession;
  final bool showAppBar;

  @override
  State<ClassCalendarScreen> createState() => _ClassCalendarScreenState();
}

class _ClassCalendarScreenState extends State<ClassCalendarScreen> {
  CalendarFormat _format = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  static DateTime _dayKey(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  Map<DateTime, List<ClassSession>> _group(List<ClassSession> sessions) {
    final map = <DateTime, List<ClassSession>>{};
    for (final s in sessions) {
      final parsed = DateTime.tryParse(s.sessionDate);
      if (parsed == null) continue;
      final key = _dayKey(parsed);
      map.putIfAbsent(key, () => []).add(s);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final body = StreamBuilder<List<ClassSession>>(
      stream: widget.sessions,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final events = _group(snap.data ?? []);
        final selected = events[_dayKey(_selectedDay)] ?? const [];

        return Column(
          children: [
            Card(
              margin: const EdgeInsets.all(12),
              child: TableCalendar<ClassSession>(
                firstDay: DateTime.utc(2023, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _format,
                availableCalendarFormats: const {
                  CalendarFormat.month: 'Month',
                  CalendarFormat.twoWeeks: '2 weeks',
                  CalendarFormat.week: 'Week',
                },
                startingDayOfWeek: StartingDayOfWeek.monday,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                eventLoader: (day) => events[_dayKey(day)] ?? const [],
                calendarStyle: const CalendarStyle(
                  markerDecoration: BoxDecoration(
                    color: AppColors.teal,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: AppColors.navy,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: AppColors.teal,
                    shape: BoxShape.circle,
                  ),
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) => setState(() => _format = format),
                onPageChanged: (focusedDay) => _focusedDay = focusedDay,
              ),
            ),
            Expanded(
              child: selected.isEmpty
                  ? EmptyState(
                      icon: Icons.event_busy_outlined,
                      title: 'No classes',
                      subtitle:
                          'No class sessions on ${DateFormat('EEE, d MMM').format(_selectedDay)}.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                      itemCount: selected.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _SessionTile(
                        session: selected[i],
                        onTap: widget.onTapSession == null
                            ? null
                            : () => widget.onTapSession!(selected[i]),
                      ),
                    ),
            ),
          ],
        );
      },
    );

    if (!widget.showAppBar) return body;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: Text(widget.title)),
      body: body,
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, this.onTap});

  final ClassSession session;
  final VoidCallback? onTap;

  static String _metaLine(ClassSession s) {
    final parts = <String>[
      if (s.mode != null) s.mode!.label,
      if (s.room != null && s.room!.isNotEmpty) s.room!,
      'Cap ${s.capacity}',
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (session.isConcluded ? AppColors.textSecondary : AppColors.teal)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              session.isConcluded
                  ? Icons.event_available_outlined
                  : Icons.event_outlined,
              color: session.isConcluded
                  ? AppColors.textSecondary
                  : AppColors.teal,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.sessionTitle.isNotEmpty
                      ? session.sessionTitle
                      : 'Class session',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  session.timeRangeLabel +
                      (session.isConcluded ? ' · concluded' : ''),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                if (_metaLine(session).isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _metaLine(session),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (session.isOpenForRegistration) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Open for registration',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onTap != null)
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
