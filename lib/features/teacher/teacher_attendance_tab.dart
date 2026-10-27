import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/class_term_errors.dart';
import '../../core/errors/conclude_errors.dart';
import '../../core/errors/session_errors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/conclude_class_dialog.dart';
import '../../core/widgets/responsive_card_grid.dart';
import '../../core/widgets/status_pill.dart';
import '../../models/app_user.dart';
import '../../models/attendance_record.dart';
import '../../models/class_session.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';

/// Classes tab: one calendar for upcoming and past classes. Tap a day to see
/// its classes (open or concluded) and to create a class on that date.
class TeacherAttendanceTab extends StatefulWidget {
  const TeacherAttendanceTab({super.key});

  @override
  State<TeacherAttendanceTab> createState() => _TeacherAttendanceTabState();
}

class _TeacherAttendanceTabState extends State<TeacherAttendanceTab> {
  CalendarFormat _format = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  static DateTime _dayKey(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  Map<DateTime, List<ClassSession>> _group(List<ClassSession> sessions) {
    final map = <DateTime, List<ClassSession>>{};
    for (final s in sessions) {
      final parsed = DateTime.tryParse(s.sessionDate);
      if (parsed == null) continue;
      map.putIfAbsent(_dayKey(parsed), () => []).add(s);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    }
    return map;
  }

  void _newClass(BuildContext context, AppUser user) {
    final date = DateFormat('yyyy-MM-dd').format(_selectedDay);
    final base = user.isAdmin ? '/admin' : '/teacher';
    context.push('$base/session/new?date=$date');
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().appUser;
    if (user == null) return const SizedBox.shrink();
    final teacherId = AppConstants.contentTeacherId(user);

    return StreamBuilder<List<ClassSession>>(
      stream: context.read<FirestoreService>().watchTeacherSessions(teacherId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                snapshot.error.toString(),
                style: const TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final byDay = _group(snapshot.data ?? const []);
        final selected = byDay[_dayKey(_selectedDay)] ?? const <ClassSession>[];
        final openCount = selected.where((s) => !s.isConcluded).length;

        return LayoutBuilder(
          builder: (context, constraints) {
            const padding = 16.0;
            final gridWidth = constraints.maxWidth - padding * 2;
            return ListView(
              padding: const EdgeInsets.fromLTRB(padding, 8, padding, 88),
              children: [
                AppCard(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                  child: TableCalendar<ClassSession>(
                    firstDay: DateTime.utc(2024, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _format,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    availableCalendarFormats: const {
                      CalendarFormat.month: 'Month',
                      CalendarFormat.week: 'Week',
                    },
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    eventLoader: (day) => byDay[_dayKey(day)] ?? const [],
                    onDaySelected: (selectedDay, focusedDay) => setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    }),
                    onFormatChanged: (f) => setState(() => _format = f),
                    onPageChanged: (focused) => _focusedDay = focused,
                    headerStyle: const HeaderStyle(
                      titleCentered: true,
                      formatButtonShowsNext: false,
                    ),
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.accent),
                      ),
                      todayTextStyle: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      markersMaxCount: 3,
                      markerSize: 6,
                    ),
                    calendarBuilders: CalendarBuilders(
                      // Open classes = teal dot, concluded = grey dot.
                      singleMarkerBuilder: (context, day, session) => Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: session.isConcluded
                              ? AppColors.textSecondary.withValues(alpha: 0.5)
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE, d MMM yyyy').format(_selectedDay),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            selected.isEmpty
                                ? 'No classes'
                                : '${selected.length} class${selected.length == 1 ? '' : 'es'}'
                                    '${openCount < selected.length ? ' · ${selected.length - openCount} concluded' : ''}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => _newClass(context, user),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New class this day'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (selected.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Pick another day, or create a class on this date. '
                      'Dots on the calendar mark days with classes: teal = open, grey = concluded.',
                      style: TextStyle(
                          color: AppColors.textSecondary, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ResponsiveCardGrid(
                    width: gridWidth,
                    minCardWidth: 340,
                    children: [
                      for (final session in selected)
                        _TeacherClassCard(
                          key: ValueKey(session.id),
                          session: session,
                          historyMode: session.isConcluded,
                        ),
                    ],
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _TeacherClassCard extends StatefulWidget {
  const _TeacherClassCard({
    super.key,
    required this.session,
    required this.historyMode,
  });

  final ClassSession session;
  final bool historyMode;

  @override
  State<_TeacherClassCard> createState() => _TeacherClassCardState();
}

class _TeacherClassCardState extends State<_TeacherClassCard> {
  bool _deleting = false;
  bool _concluding = false;
  final Set<String> _busyStudentIds = {};

  ClassSession get session => widget.session;
  bool get historyMode => widget.historyMode;

  Future<void> _confirmConclude() async {
    final statuses = await ConcludeClassDialog.show(
      context,
      sessionId: session.id,
      sessionTitle: session.sessionTitle,
    );
    if (statuses == null || !mounted) return;

    setState(() => _concluding = true);
    final firestore = context.read<FirestoreService>();
    final notifications = context.read<NotificationService>();
    try {
      final result =
          await firestore.concludeClassSession(session.id, statuses: statuses);
      await notifications.notifySession(
        title: 'Class concluded',
        body: '${session.sessionTitle} concluded. ${result.summary}.',
      );
      if (mounted) {
        final msg = result.hasFailures
            ? 'Class concluded. ${result.creditedCount} charged; '
                'could not charge: ${result.failedStudents.join(', ')}'
            : 'Class concluded. ${result.summary}.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _concluding = false);
    }
  }

  Future<void> _addStudent(AppUser student) async {
    if (_busyStudentIds.contains(student.uid)) return;

    setState(() => _busyStudentIds.add(student.uid));
    try {
      await context.read<FirestoreService>().addStudentToSession(
            session: session,
            studentId: student.uid,
            studentName: student.name,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${student.name} added to class')),
        );
      }
    } on SessionFullException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage(e, studentName: student.name)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busyStudentIds.remove(student.uid));
    }
  }

  Future<void> _confirmRemoveStudent(
    AttendanceRecord record,
    String name,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove student?'),
        content: Text(
          'Remove $name from "${session.sessionTitle}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _busyStudentIds.add(record.studentId));
    try {
      await context.read<FirestoreService>().removeStudentFromSession(
            sessionId: session.id,
            studentId: record.studentId,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name removed from class')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busyStudentIds.remove(record.studentId));
      }
    }
  }

  Future<void> _showAddStudentDialog(
    List<AppUser> allStudents,
    Set<String> joinedIds,
  ) async {
    final available =
        allStudents.where((s) => !joinedIds.contains(s.uid)).toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All students are already in this class')),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add student'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: available.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final student = available[index];
              final busy = _busyStudentIds.contains(student.uid);

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.teal.withValues(alpha: 0.12),
                  child: Text(
                    student.name.isNotEmpty
                        ? student.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.teal,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                title: Text(student.name),
                subtitle: student.email.isNotEmpty
                    ? Text(
                        student.email,
                        style: const TextStyle(fontSize: 12),
                      )
                    : null,
                trailing: busy
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                onTap: busy ? null : () => _addStudent(student),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this class?'),
        content: Text(
          'Delete "${session.sessionTitle}"? All student join records for '
          'this class will be removed. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await context.read<FirestoreService>().deleteClassSession(session.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Class deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  String _errorMessage(Object e, {String? studentName}) {
    if (e is ClassConcludeException) {
      return e.message;
    }
    if (e is NoClassCreditsException) {
      final who = studentName ?? 'This student';
      return '$who has no class sessions left. Add an 8 or 16 session term from their profile.';
    }
    if (e is FirebaseException) {
      if (e.code == 'permission-denied') {
        return 'Could not delete: permission denied.';
      }
      return e.message ?? 'Could not delete class (${e.code})';
    }
    return e.toString();
  }

  StatusPill _statusPill(bool concluded) {
    if (concluded) return StatusPills.concluded();
    if (session.isOpen) return StatusPills.open();
    return StatusPills.closed();
  }

  ButtonStyle get _compactButtonStyle => FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 34),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      );

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final date = DateTime.tryParse(session.sessionDate);
    final dateLabel = date != null
        ? DateFormat('EEE, d MMM yyyy').format(date)
        : session.sessionDate;
    final concluded = session.isConcluded || historyMode;
    final busy = _deleting || _concluding;

    return Stack(
      children: [
        AppCard(
          padding: const EdgeInsets.all(14),
          child: StreamBuilder<List<AppUser>>(
            stream: firestore.watchAllStudents(),
            builder: (context, studentsSnap) {
              final studentsById = {
                for (final s in studentsSnap.data ?? []) s.uid: s,
              };

              return StreamBuilder<List<AttendanceRecord>>(
                stream: firestore.watchSessionAttendance(session.id),
                builder: (context, attendanceSnap) {
                  final records = (attendanceSnap.data ?? [])
                      .where((r) => r.attended)
                      .toList();
                  final joined = records.length;
                  final joinedIds = records.map((r) => r.studentId).toSet();
                  final allStudents = studentsSnap.data ?? [];
                  final isFull = firestore.isSessionFull(session, joined);
                  final pendingCharge =
                      records.where((r) => !r.sessionCredited).length;
                  final chargedCount =
                      records.where((r) => r.sessionCredited).length;

                  final statsLine = concluded
                      ? '$joined joined · $chargedCount charged'
                      : '$joined/${session.capacity} joined · '
                          '$pendingCharge pending';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.teal.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.event_outlined,
                              size: 18,
                              color: AppColors.teal,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  session.sessionTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$dateLabel · ${session.timeRangeLabel}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  statsLine,
                                  style: TextStyle(
                                    color: concluded
                                        ? AppColors.navy
                                        : session.isOpen
                                            ? AppColors.success
                                            : AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (concluded && session.concludedAt != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      'Concluded ${DateFormat('d MMM yyyy, HH:mm').format(session.concludedAt!)}',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _statusPill(concluded),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (!concluded)
                            FilledButton.icon(
                              onPressed: busy ? null : _confirmConclude,
                              icon: const Icon(Icons.done_all, size: 16),
                              label: const Text('Conclude'),
                              style: _compactButtonStyle.copyWith(
                                backgroundColor: WidgetStatePropertyAll(
                                  AppColors.teal,
                                ),
                              ),
                            ),
                          if (!concluded)
                            OutlinedButton.icon(
                              onPressed: busy
                                  ? null
                                  : () => context.push(
                                        '/teacher/session/${session.id}/edit',
                                        extra: session,
                                      ),
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              label: const Text('Edit'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                minimumSize: const Size(0, 34),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                textStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          OutlinedButton.icon(
                            onPressed: busy ? null : _confirmDelete,
                            icon: const Icon(Icons.delete_outline, size: 16),
                            label: const Text('Delete'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              minimumSize: const Size(0, 34),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (!concluded)
                            TextButton.icon(
                              onPressed: busy || isFull
                                  ? null
                                  : () => _showAddStudentDialog(
                                        allStudents,
                                        joinedIds,
                                      ),
                              icon: const Icon(
                                Icons.person_add_outlined,
                                size: 16,
                              ),
                              label: Text(isFull ? 'Full' : 'Add'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                minimumSize: const Size(0, 34),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                textStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (!concluded && isFull) ...[
                        const SizedBox(height: 6),
                        const Text(
                          'Class is at capacity.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      Text(
                        'Students ($joined)',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.navy,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (attendanceSnap.hasError)
                        Text(
                          attendanceSnap.error.toString(),
                          style: const TextStyle(color: AppColors.error),
                        )
                      else if (records.isEmpty)
                        const Text(
                          'No students joined yet.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        )
                      else
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: records.map((record) {
                            final student = studentsById[record.studentId];
                            final name = record.studentName?.isNotEmpty == true
                                ? record.studentName!
                                : (student?.name ?? 'Student');
                            final removing =
                                _busyStudentIds.contains(record.studentId);
                            final status = record.sessionCredited
                                ? 'Charged'
                                : concluded
                                    ? 'Not charged'
                                    : record.joinedByStudent
                                        ? 'Joined'
                                        : 'Added';

                            if (removing) {
                              return const Chip(
                                label: SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            }

                            return InputChip(
                              label: Text(
                                name,
                                style: const TextStyle(fontSize: 12),
                              ),
                              avatar: Icon(
                                record.joinedByStudent
                                    ? Icons.person_outline
                                    : Icons.edit_note_outlined,
                                size: 16,
                                color: AppColors.teal,
                              ),
                              labelStyle: TextStyle(
                                color: record.sessionCredited
                                    ? AppColors.teal
                                    : concluded && !record.sessionCredited
                                        ? AppColors.error
                                        : AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                              tooltip: status,
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              onDeleted: concluded || busy
                                  ? null
                                  : () => _confirmRemoveStudent(record, name),
                            );
                          }).toList(),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        if (_deleting || _concluding)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
      ],
    );
  }
}
