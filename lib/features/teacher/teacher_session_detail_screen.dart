import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/conclude_class_dialog.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/status_pill.dart';
import '../../core/widgets/shell_nested_page.dart';
import '../../models/app_user.dart';
import '../../models/class_session.dart';
import '../../models/org_settings.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';

class TeacherSessionDetailScreen extends StatefulWidget {
  const TeacherSessionDetailScreen({
    super.key,
    required this.sessionId,
    this.embedded = false,
  });

  final String sessionId;
  final bool embedded;

  @override
  State<TeacherSessionDetailScreen> createState() =>
      _TeacherSessionDetailScreenState();
}

class _TeacherSessionDetailScreenState
    extends State<TeacherSessionDetailScreen> {
  bool _deleting = false;
  bool _concluding = false;

  Future<void> _confirmDelete(ClassSession session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this class?'),
        content: Text(
          'Delete "${session.sessionTitle}"? All student join records for '
          'this class will be removed. This cannot be undone.',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.border),
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
        context.go('/teacher');
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

  Future<void> _confirmConclude(ClassSession session) async {
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
        setState(() {});
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

  String _errorMessage(Object e) {
    if (e is FirebaseException) {
      if (e.code == 'permission-denied') {
        return 'Could not complete action: permission denied.';
      }
      return e.message ?? 'Could not complete action (${e.code})';
    }
    return e.toString();
  }

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final busy = _deleting || _concluding;

    return FutureBuilder<ClassSession?>(
      future: firestore.getClassSession(widget.sessionId),
      builder: (context, sessionSnap) {
        if (sessionSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = sessionSnap.data;
        if (session == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Class not found')),
          );
        }

        final date = DateTime.tryParse(session.sessionDate);
        final dateLabel = date != null
            ? DateFormat('EEE, d MMM yyyy').format(date)
            : session.sessionDate;
        final durationMinutes = session.endMinutes - session.startMinutes;

        final isAdmin = context.read<AuthService>().appUser?.isAdmin ?? false;

        return ShellNestedPage(
          embedded: widget.embedded,
          title: session.sessionTitle,
          actions: [
            // Admins can always reschedule. Teachers only when the org allows
            // it (allowTeacherReschedule). Gate the edit entry point.
            StreamBuilder<OrgSettings>(
              stream: firestore.watchOrgSettings(),
              builder: (context, settingsSnap) {
                final canReschedule = isAdmin ||
                    (settingsSnap.data ?? OrgSettings.defaults)
                        .allowTeacherReschedule;
                if (!canReschedule) return const SizedBox.shrink();
                return IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: busy
                      ? null
                      : () => context.push(
                            '/teacher/session/${session.id}/edit',
                            extra: session,
                          ),
                );
              },
            ),
          ],
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    StreamBuilder<List<AppUser>>(
                      stream: firestore.watchAllStudents(),
                      builder: (context, studentsSnap) {
                        final studentsById = {
                          for (final s in studentsSnap.data ?? []) s.uid: s,
                        };

                        return StreamBuilder(
                          stream: firestore.watchSessionAttendance(session.id),
                          builder: (context, attendanceSnap) {
                            final records = attendanceSnap.data ?? [];
                            final joined = records.length;
                            final isFull = joined >= session.capacity;

                            return ListView(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 20, 20, 120),
                              children: [
                                AppCard(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dateLabel,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18,
                                          color: AppColors.navy,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${session.timeRangeLabel} · $durationMinutes min',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      if (session.mode != null ||
                                          (session.room != null &&
                                              session.room!.isNotEmpty)) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          [
                                            if (session.mode != null)
                                              session.mode!.label,
                                            if (session.room != null &&
                                                session.room!.isNotEmpty)
                                              session.room!,
                                          ].join(' · '),
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          if (session.isConcluded)
                                            StatusPills.concluded()
                                          else if (session.isOpen)
                                            StatusPills.open()
                                          else
                                            StatusPills.closed(),
                                          if (isFull && !session.isConcluded)
                                            StatusPills.full(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.teal
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              '$joined / ${session.capacity} joined',
                                              style: TextStyle(
                                                color: AppColors.teal,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          if (session.registrationState != null)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.navy
                                                    .withValues(alpha: 0.08),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                session
                                                    .registrationState!.label,
                                                style: TextStyle(
                                                  color: AppColors.navy,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (session.isConcluded &&
                                          session.concludedAt != null) ...[
                                        const SizedBox(height: 10),
                                        Text(
                                          'Concluded ${DateFormat('d MMM yyyy, HH:mm').format(session.concludedAt!)}',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const SectionHeader(
                                    title: 'Students who joined'),
                                if (records.isEmpty)
                                  AppCard(
                                    child: Text(
                                      'No students have joined yet.',
                                      style: TextStyle(
                                          color: AppColors.textSecondary),
                                    ),
                                  )
                                else
                                  ...records.map((record) {
                                    final student =
                                        studentsById[record.studentId];
                                    final name =
                                        record.studentName?.isNotEmpty == true
                                            ? record.studentName!
                                            : (student?.name ?? 'Student');
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: AppCard(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
                                        ),
                                        child: Row(
                                          children: [
                                            AppUserAvatar(
                                              initials: userInitials(name),
                                              size: 36,
                                              backgroundColor: AppColors.teal,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    name,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  Text(
                                                    record.joinedByStudent
                                                        ? 'Self join'
                                                        : 'Added by teacher',
                                                    style: TextStyle(
                                                      color: AppColors
                                                          .textSecondary,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    if (busy)
                      const ColoredBox(
                        color: Color(0x88000000),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
              ),
              if (session.isConcluded)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : () => _confirmDelete(session),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete class'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                )
              else
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed:
                                busy ? null : () => _confirmDelete(session),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Delete'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: BorderSide(color: AppColors.error),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed:
                                busy ? null : () => _confirmConclude(session),
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Conclude class'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.navy,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
