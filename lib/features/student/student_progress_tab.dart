import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/progress_utils.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/progress_widgets.dart';
import '../../l10n/l10n.dart';
import '../../models/lesson.dart';
import '../../models/student_progress.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class StudentProgressTab extends StatelessWidget {
  const StudentProgressTab({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final student = context.watch<AuthService>().appUser!;
    final contentOwnerId = AppConstants.contentOwnerFor(student);
    final l = context.l10n;

    return StreamBuilder<List<StudentProgress>>(
      stream: firestore.watchStudentProgress(studentId),
      builder: (context, progressSnap) {
        if (progressSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final progress = progressSnap.data ?? [];
        final completed = progress.where((item) => item.completed).toList();

        if (contentOwnerId.isEmpty) {
          return EmptyState(
            icon: Icons.trending_up,
            title: l.studentProgressNoProgressTitle,
            subtitle: l.studentProgressNoProgressSubtitle,
          );
        }

        return StreamBuilder<List<Lesson>>(
          stream: firestore.watchLessons(contentOwnerId),
          builder: (context, lessonsSnap) {
            final allLessons = lessonsSnap.data ?? [];
            final lessons =
                ProgressUtils.lessonsForStudent(allLessons, student);
            final terms = ProgressUtils.buildTermProgress(
              lessons: lessons,
              progress: progress,
              termSize: student.lessonsPerTerm,
            );
            final avgScore = ProgressUtils.averageScore(progress);
            final currentTerm = ProgressUtils.currentTerm(
              lessons: lessons,
              progress: progress,
              termSize: student.lessonsPerTerm,
            );

            if (lessons.isEmpty) {
              return EmptyState(
                icon: Icons.trending_up,
                title: l.studentProgressNoLessonsTitle,
                subtitle: l.studentProgressNoLessonsSubtitle(
                  student.level ?? l.studentProgressYourHskLevel,
                ),
              );
            }

            if (completed.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  ProgressSummaryRow(
                    completed: 0,
                    avgScore: null,
                    thirdLabel: l.studentProgressTermSize,
                    thirdValue: '${student.lessonsPerTerm}',
                  ),
                  const SizedBox(height: 20),
                  if (currentTerm != null) ...[
                    TermProgressCard(
                      term: currentTerm,
                      subtitle: l.studentProgressStartFirst,
                    ),
                    const SizedBox(height: 20),
                  ],
                  SectionHeader(title: l.studentProgressTermPlan),
                  for (final term in terms) ...[
                    TermProgressCard(term: term),
                    const SizedBox(height: 12),
                  ],
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                ProgressSummaryRow(
                  completed: completed.length,
                  avgScore: avgScore,
                  thirdLabel: l.studentProgressCurrentTerm,
                  thirdValue: currentTerm != null
                      ? '${currentTerm.completedCount}/${currentTerm.termSize}'
                      : '—',
                ),
                const SizedBox(height: 20),
                for (final term in terms) ...[
                  SectionHeader(
                    title:
                        '${term.label} (${term.completedCount}/${term.termSize})',
                  ),
                  ...term.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ProgressHistoryTile(item: item),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
        );
      },
    );
  }
}
