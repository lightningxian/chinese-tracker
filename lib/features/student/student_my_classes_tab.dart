import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/class_history_section.dart';
import '../../l10n/l10n.dart';
import '../../models/app_user.dart';
import '../../models/attendance_record.dart';
import '../../models/student_class_term.dart';
import '../../services/firestore_service.dart';

/// History tab: the student's vouchers with the classes charged to each,
/// then every class visit by month. Tapping a class opens who joined it.
class StudentMyClassesTab extends StatelessWidget {
  const StudentMyClassesTab({super.key, required this.student});

  final AppUser student;

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    return StreamBuilder<List<StudentClassTerm>>(
      stream: firestore.watchStudentClassTerms(student.uid),
      builder: (context, termsSnap) {
        return StreamBuilder<List<AttendanceRecord>>(
          stream: firestore.watchStudentJoinedSessions(student.uid),
          builder: (context, visitsSnap) {
            if (termsSnap.connectionState == ConnectionState.waiting ||
                visitsSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final error = termsSnap.error ?? visitsSnap.error;
            if (error != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    error.toString(),
                    style: TextStyle(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            final terms = termsSnap.data ?? const <StudentClassTerm>[];
            final visits = visitsSnap.data ?? const <AttendanceRecord>[];
            if (terms.isEmpty && visits.isEmpty) {
              return EmptyState(
                icon: Icons.history_outlined,
                title: context.l10n.studentMyClassesEmptyTitle,
                subtitle: context.l10n.studentMyClassesEmptySubtitle,
              );
            }
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                ClassHistorySection(
                  terms: terms,
                  visits: visits,
                  onOpenSession: (record) =>
                      context.push('/student/class/${record.sessionId}'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
