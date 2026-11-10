import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/errors/class_term_errors.dart';
import '../../core/errors/conclude_errors.dart';
import '../../core/errors/session_errors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/leave_class_dialog.dart';
import '../../core/widgets/responsive_card_grid.dart';
import '../../l10n/l10n.dart';
import '../../models/student_class_term.dart';
import '../../models/app_user.dart';
import '../../models/attendance_record.dart';
import '../../models/class_session.dart';
import '../../services/firestore_service.dart';

class StudentJoinSessionSection extends StatefulWidget {
  const StudentJoinSessionSection({super.key, required this.student});

  final AppUser student;

  @override
  State<StudentJoinSessionSection> createState() =>
      _StudentJoinSessionSectionState();
}

class _StudentJoinSessionSectionState extends State<StudentJoinSessionSection> {
  final Set<String> _justJoinedSessionIds = {};

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();

    return StreamBuilder<List<ClassSession>>(
      stream: firestore.watchOpenSessions(
        teacherId: widget.student.teacherId,
      ),
      builder: (context, sessionsSnap) {
        if (sessionsSnap.hasError) {
          return _JoinSectionFrame(
            child: AppCard(
              child: Text(
                _errorMessage(context.l10n, sessionsSnap.error!),
                style: TextStyle(color: AppColors.error),
              ),
            ),
          );
        }

        if (sessionsSnap.connectionState == ConnectionState.waiting) {
          return const _JoinSectionFrame(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        final sessions = sessionsSnap.data ?? [];

        return StreamBuilder<List<StudentClassTerm>>(
          stream: firestore.watchStudentClassTerms(widget.student.uid),
          builder: (context, termsSnap) {
            final terms = termsSnap.data ?? [];
            final sessionsLeft = firestore.totalRemainingClassSessions(terms);

            return StreamBuilder<List<AttendanceRecord>>(
              stream: firestore.watchStudentJoinedSessions(widget.student.uid),
              builder: (context, attendanceSnap) {
                final joinedSessionIds = {
                  ..._justJoinedSessionIds,
                  for (final record in attendanceSnap.data ?? [])
                    if (record.attended || record.joinedByStudent)
                      record.sessionId,
                };

                return _JoinSectionFrame(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (sessions.isEmpty)
                        EmptyState(
                          icon: Icons.event_busy_outlined,
                          title: context.l10n.studentJoinNoSessionsTitle,
                          subtitle: context.l10n.studentJoinNoSessionsSubtitle,
                        )
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return ResponsiveCardGrid(
                              width: constraints.maxWidth,
                              children: [
                                for (final session in sessions)
                                  _OpenSessionJoinCard(
                                    session: session,
                                    student: widget.student,
                                    sessionsLeft: sessionsLeft,
                                    joined:
                                        joinedSessionIds.contains(session.id),
                                    onJoined: () => setState(
                                      () =>
                                          _justJoinedSessionIds.add(session.id),
                                    ),
                                    onLeft: () => setState(
                                      () => _justJoinedSessionIds
                                          .remove(session.id),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  static String _errorMessage(AppLocalizations l, Object e) {
    if (e is ClassConcludeException) {
      return e.message;
    }
    if (e is NoClassCreditsException) {
      return e.toString();
    }
    if (e is SessionFullException) {
      return e.toString();
    }
    if (e is FirebaseException) {
      if (e.code == 'permission-denied') {
        return l.studentJoinPermissionDenied;
      }
      return e.message ?? l.studentJoinFailed(e.code);
    }
    if (e is StateError) {
      return e.message;
    }
    return e.toString();
  }
}

class _OpenSessionJoinCard extends StatelessWidget {
  const _OpenSessionJoinCard({
    required this.session,
    required this.student,
    required this.sessionsLeft,
    required this.joined,
    required this.onJoined,
    required this.onLeft,
  });

  final ClassSession session;
  final AppUser student;
  final int sessionsLeft;
  final bool joined;
  final VoidCallback onJoined;
  final VoidCallback onLeft;

  Future<void> _showClassFullDialog(BuildContext context, int joinedCount) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.studentJoinClassFullTitle),
        content: Text(
          ctx.l10n.studentJoinClassFullBody(session.capacity, joinedCount),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.l10n.commonOk),
          ),
        ],
      ),
    );
  }

  Future<void> _join(BuildContext context, int joinedCount, bool isFull) async {
    if (isFull) {
      await _showClassFullDialog(context, joinedCount);
      return;
    }

    if (sessionsLeft <= 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              const NoClassCreditsException().toString(),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    final firestore = context.read<FirestoreService>();
    final l = context.l10n;
    try {
      await firestore.joinSession(
        session: session,
        studentId: student.uid,
        studentName: student.name,
      );
      onJoined();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.studentJoinJoined)),
        );
      }
    } on SessionFullException {
      if (context.mounted) {
        await _showClassFullDialog(context, joinedCount);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_StudentJoinSessionSectionState._errorMessage(l, e)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final l = context.l10n;
    final date = DateTime.tryParse(session.sessionDate);
    final dateLabel = date != null
        ? DateFormat('EEE, d MMM yyyy', l.localeName).format(date)
        : session.sessionDate;

    return StreamBuilder<List<AttendanceRecord>>(
      stream: firestore.watchSessionAttendance(session.id),
      builder: (context, rosterSnap) {
        final joinedCount =
            (rosterSnap.data ?? []).where((r) => r.attended).length;
        final isFull = firestore.isSessionFull(session, joinedCount);
        final spotsLeft =
            (session.capacity - joinedCount).clamp(0, session.capacity);

        return AppCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.sessionTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$dateLabel · ${session.timeRangeLabel}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l.studentJoinCount(joinedCount, session.capacity)}'
                      ' · ${isFull ? l.commonFull : l.commonSpotsLeft(spotsLeft)}',
                      style: TextStyle(
                        color: isFull ? AppColors.error : AppColors.teal,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (joined)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () =>
                          context.push('/student/class/${session.id}'),
                      child: Text(l.studentJoinView),
                    ),
                    TextButton(
                      onPressed: () async {
                        final confirm = await showLeaveClassDialog(context);
                        if (confirm != true || !context.mounted) return;
                        try {
                          await firestore.leaveSession(
                            sessionId: session.id,
                            studentId: student.uid,
                          );
                          onLeft();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l.studentJoinLeftClass),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  _StudentJoinSessionSectionState._errorMessage(
                                      l, e),
                                ),
                              ),
                            );
                          }
                        }
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                      child: Text(l.studentJoinLeave),
                    ),
                  ],
                )
              else if (isFull)
                OutlinedButton(
                  onPressed: () => _showClassFullDialog(context, joinedCount),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error),
                  ),
                  child: Text(l.commonFull),
                )
              else
                FilledButton(
                  onPressed:
                      rosterSnap.connectionState == ConnectionState.waiting ||
                              sessionsLeft <= 0
                          ? null
                          : () => _join(context, joinedCount, isFull),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                  ),
                  child: Text(
                    sessionsLeft <= 0
                        ? l.studentJoinNoSessionsLeft
                        : l.studentJoinJoin,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _JoinSectionFrame extends StatelessWidget {
  const _JoinSectionFrame({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: context.l10n.studentJoinTitle),
        const SizedBox(height: 4),
        Text(
          context.l10n.studentJoinHint,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
