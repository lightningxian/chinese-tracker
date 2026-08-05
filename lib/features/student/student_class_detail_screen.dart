import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/leave_class_dialog.dart';
import '../../core/widgets/status_pill.dart';
import '../../models/app_user.dart';
import '../../models/attendance_record.dart';
import '../../core/errors/session_errors.dart';
import '../../services/firestore_service.dart';

class StudentClassDetailScreen extends StatelessWidget {
  const StudentClassDetailScreen({
    super.key,
    required this.sessionId,
    required this.student,
  });

  final String sessionId;
  final AppUser student;

  Future<void> _confirmLeave(BuildContext context) async {
    final leave = await showLeaveClassDialog(context);

    if (leave != true || !context.mounted) return;

    try {
      await context.read<FirestoreService>().leaveSession(
            sessionId: sessionId,
            studentId: student.uid,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You left this class')),
        );
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage(e))),
        );
      }
    }
  }

  static String _errorMessage(Object e) {
    if (e is SessionFullException) {
      return e.toString();
    }
    if (e is FirebaseException) {
      return e.message ?? 'Could not leave class (${e.code})';
    }
    return e.toString();
  }

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();

    return FutureBuilder(
      future: firestore.getClassSession(sessionId),
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

        return Scaffold(
          appBar: AppBar(title: Text(session.sessionTitle)),
          body: FutureBuilder<AppUser?>(
            future: firestore.getUser(session.teacherId),
            builder: (context, teacherSnap) {
              final teacherName = teacherSnap.data?.name ?? 'Your teacher';

              return StreamBuilder<List<AttendanceRecord>>(
            stream: firestore.watchSessionAttendance(sessionId),
            builder: (context, rosterSnap) {
              final roster = (rosterSnap.data ?? [])
                  .where((r) => r.attended)
                  .toList();
              roster.sort((a, b) {
                final nameA = a.studentName ?? a.studentId;
                final nameB = b.studentName ?? b.studentId;
                return nameA.toLowerCase().compareTo(nameB.toLowerCase());
              });

              final iAmJoined =
                  roster.any((r) => r.studentId == student.uid);
              final isFull = firestore.isSessionFull(session, roster.length);
              final spotsLeft =
                  (session.capacity - roster.length).clamp(0, session.capacity);

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${session.timeRangeLabel} · Teacher: $teacherName',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
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
                            if (isFull && !session.isConcluded) StatusPills.full(),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${roster.length}/${session.capacity} students joined'
                          '${isFull ? ' · Full' : ' · $spotsLeft spot${spotsLeft == 1 ? '' : 's'} left'}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isFull ? AppColors.error : AppColors.teal,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (iAmJoined) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => _confirmLeave(context),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Leave class'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SectionHeader(
                    title: 'Who joined (${roster.length})',
                  ),
                  if (rosterSnap.hasError)
                    AppCard(
                      child: Text(
                        rosterSnap.error.toString(),
                        style: const TextStyle(color: AppColors.error),
                      ),
                    )
                  else if (roster.isEmpty)
                    const AppCard(
                      child: Text(
                        'No students have joined yet.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  else
                    ...roster.map((record) {
                      final isMe = record.studentId == student.uid;
                      final name = record.studentName?.isNotEmpty == true
                          ? record.studentName!
                          : 'Student';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: isMe
                                    ? AppColors.navy.withValues(alpha: 0.12)
                                    : AppColors.teal.withValues(alpha: 0.12),
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: isMe ? AppColors.navy : AppColors.teal,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isMe ? '$name (you)' : name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      record.joinedByStudent
                                          ? 'Joined from app'
                                          : 'Added by teacher',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isMe)
                                const Icon(
                                  Icons.check_circle,
                                  color: AppColors.success,
                                  size: 20,
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
        );
      },
    );
  }
}
