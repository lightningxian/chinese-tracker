import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/progress_utils.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/class_term_widgets.dart';
import '../../core/widgets/exercise_widgets.dart';
import '../../core/widgets/profile_widgets.dart';
import '../../core/widgets/progress_widgets.dart';
import '../../core/widgets/shell_nested_page.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/student_report_service.dart';
import '../evaluations/student_evaluations_section.dart';

class StudentDetailScreen extends StatefulWidget {
  const StudentDetailScreen({
    super.key,
    required this.studentId,
    this.embedded = false,
  });

  final String studentId;
  final bool embedded;

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  bool _exporting = false;

  Future<void> _exportReport(AppUser student) async {
    setState(() => _exporting = true);
    try {
      await context
          .read<StudentReportService>()
          .previewReport(widget.studentId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();

    return FutureBuilder(
      future: firestore.getUser(widget.studentId),
      builder: (context, userSnap) {
        if (userSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final student = userSnap.data;
        if (student == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Student not found')),
          );
        }

        final contentOwnerId = AppConstants.contentOwnerFor(student);

        return ShellNestedPage(
          embedded: widget.embedded,
          title: student.displayNameIndonesian,
          actions: [
            IconButton(
              onPressed: _exporting ? null : () => _exportReport(student),
              tooltip: 'Export progress report',
              icon: _exporting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined),
            ),
          ],
          child: StreamBuilder(
            stream: firestore.watchLessons(contentOwnerId),
            builder: (context, lessonsSnap) {
              final allLessons = lessonsSnap.data ?? [];
              final lessons = ProgressUtils.lessonsForStudent(allLessons, student);

              return StreamBuilder(
                stream: firestore.watchStudentProgress(widget.studentId),
                builder: (context, progressSnap) {
                  final progress = progressSnap.data ?? [];
                  final terms = ProgressUtils.buildTermProgress(
                    lessons: lessons,
                    progress: progress,
                    termSize: student.lessonsPerTerm,
                  );

                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      AppCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppUserAvatar(
                              initials: userInitials(
                                student.displayNameIndonesian,
                              ),
                              size: 56,
                              backgroundColor: AppColors.teal,
                              photoUrl: student.photoUrl,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student.displayNameIndonesian,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.navy,
                                        ),
                                  ),
                                  if (student.displayNameChinese != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      student.displayNameChinese!,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    student.email,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      if (student.level != null)
                                        HskBadge(label: student.level!),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.surface,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: AppColors.border,
                                          ),
                                        ),
                                        child: Text(
                                          '${student.lessonsPerTerm} lessons/term',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (student.displayWhatsapp != null ||
                          student.parentName != null ||
                          student.parentPhone != null) ...[
                        const SizedBox(height: 12),
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Contact',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.navy,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              if (student.displayWhatsapp != null)
                                ProfileInfoRow(
                                  label: 'WhatsApp',
                                  value: student.displayWhatsapp!,
                                  icon: Icons.chat_outlined,
                                ),
                              if (student.parentName != null)
                                ProfileInfoRow(
                                  label: 'Parent name',
                                  value: student.parentName!,
                                  icon: Icons.family_restroom_outlined,
                                ),
                              if (student.parentPhone != null)
                                ProfileInfoRow(
                                  label: 'Parent telephone',
                                  value: student.parentPhone!,
                                  icon: Icons.phone_outlined,
                                ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      AppCard(
                        child: OutlinedButton.icon(
                          onPressed:
                              _exporting ? null : () => _exportReport(student),
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                          label: const Text('Export progress report (PDF)'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.navy,
                            side: const BorderSide(color: AppColors.border),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      StudentClassTermSection(
                        studentId: widget.studentId,
                        showAddButton: true,
                        allowManage: true,
                      ),
                      const SizedBox(height: 24),
                      StudentEvaluationsSection(
                        studentId: widget.studentId,
                        teacherId:
                            context.read<AuthService>().appUser?.uid ??
                                contentOwnerId,
                      ),
                      const SizedBox(height: 24),
                      const SectionHeader(title: 'Practice results'),
                      StudentPracticeResultsSection(
                        studentId: widget.studentId,
                        firestore: firestore,
                      ),
                      const SizedBox(height: 24),
                      const SectionHeader(title: 'Lesson progress by term'),
                      if (terms.isEmpty)
                        const AppCard(
                          child: Text(
                            'No lesson progress yet.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      else
                        ...terms.map(
                          (term) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TermProgressCard(term: term),
                          ),
                        ),
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
