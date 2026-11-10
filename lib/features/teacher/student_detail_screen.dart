import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/money_format.dart';
import '../../core/utils/progress_utils.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/class_term_widgets.dart';
import '../../core/widgets/exercise_widgets.dart';
import '../../core/widgets/profile_widgets.dart';
import '../../core/widgets/progress_widgets.dart';
import '../../core/widgets/shell_nested_page.dart';
import '../../core/widgets/status_pill.dart';
import '../../models/app_user.dart';
import '../../models/attendance_record.dart';
import '../../models/invoice.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/student_report_service.dart';
import '../evaluations/student_evaluations_section.dart';

/// One student on one page: profile and contact, vouchers (class terms),
/// payments, attendance, evaluations, practice results and lesson progress.
/// Teachers reach it from their Students tab, admins from a row in Users.
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
        final viewer = context.read<AuthService>().appUser;
        final isAdmin = viewer?.isAdmin ?? false;

        return ShellNestedPage(
          embedded: widget.embedded,
          title: student.displayNameIndonesian,
          actions: [
            if (isAdmin)
              IconButton(
                onPressed: () =>
                    context.push('/admin/users/${widget.studentId}/edit'),
                tooltip: 'Edit profile',
                icon: const Icon(Icons.edit_outlined),
              ),
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
              final lessons =
                  ProgressUtils.lessonsForStudent(allLessons, student);

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
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    student.email,
                                    style: TextStyle(
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
                                          style: TextStyle(
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
                            side: BorderSide(color: AppColors.border),
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
                      const SectionHeader(title: 'Payments'),
                      _PaymentsSection(
                        studentId: widget.studentId,
                        firestore: firestore,
                      ),
                      const SizedBox(height: 24),
                      const SectionHeader(title: 'Attendance'),
                      _AttendanceSection(
                        studentId: widget.studentId,
                        firestore: firestore,
                      ),
                      const SizedBox(height: 24),
                      StudentEvaluationsSection(
                        studentId: widget.studentId,
                        teacherId: context.read<AuthService>().appUser?.uid ??
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
                        AppCard(
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

/// The student's invoices, newest first: what for, amount, status, date.
class _PaymentsSection extends StatelessWidget {
  const _PaymentsSection({
    required this.studentId,
    required this.firestore,
  });

  final String studentId;
  final FirestoreService firestore;

  static final _date = DateFormat('d MMM yyyy');

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Invoice>>(
      stream: firestore.watchStudentInvoices(studentId),
      builder: (context, snap) {
        final invoices = [...(snap.data ?? const <Invoice>[])]..sort((a, b) {
            final aAt = a.paidAt ?? a.createdAt ?? DateTime(1970);
            final bAt = b.paidAt ?? b.createdAt ?? DateTime(1970);
            return bAt.compareTo(aAt);
          });
        if (invoices.isEmpty) {
          return AppCard(
            child: Text(
              'No invoices yet.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }
        final paid =
            invoices.where((i) => i.isPaid).fold(0, (n, i) => n + i.amount);
        final pending =
            invoices.where((i) => i.isPending).fold(0, (n, i) => n + i.amount);
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  StatusPill(
                    label: 'Paid ${formatRupiah(paid)}',
                    color: AppColors.success,
                  ),
                  if (pending > 0)
                    StatusPill(
                      label: 'Pending ${formatRupiah(pending)}',
                      color: AppColors.brandYellow,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              for (final inv in invoices.take(8))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              inv.itemLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              [
                                inv.invoiceNumber,
                                inv.methodLabel,
                                if (inv.paidAt != null)
                                  'paid ${_date.format(inv.paidAt!)}'
                                else if (inv.dueDate.isNotEmpty)
                                  'due ${inv.dueDate}',
                              ].join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: inv.isOverdue
                                    ? AppColors.error
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatRupiah(inv.amount),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusPill(
                        label: inv.status.label,
                        color: inv.isPaid
                            ? AppColors.success
                            : inv.isPending
                                ? AppColors.brandYellow
                                : AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              if (invoices.length > 8)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'and ${invoices.length - 8} more in Payments',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
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

/// Present / excused / absent counts, then the last classes attended.
class _AttendanceSection extends StatelessWidget {
  const _AttendanceSection({
    required this.studentId,
    required this.firestore,
  });

  final String studentId;
  final FirestoreService firestore;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AttendanceRecord>>(
      stream: firestore.watchStudentAttendance(studentId),
      builder: (context, snap) {
        final records = [...(snap.data ?? const <AttendanceRecord>[])]
          ..sort((a, b) => b.sessionDate.compareTo(a.sessionDate));
        if (records.isEmpty) {
          return AppCard(
            child: Text(
              'No classes attended yet.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }
        // A visit that was concluded before statuses existed has no mark but
        // was attended; count it as present.
        bool present(AttendanceRecord r) =>
            r.markedPresent || (r.attended && r.normalizedStatus == null);
        final presentCount = records.where(present).length;
        final excused = records.where((r) => r.isExcused).length;
        final absent = records
            .where((r) => r.normalizedStatus == AttendanceRecord.alpa)
            .length;
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  StatusPill(
                    label: '$presentCount present',
                    color: AppColors.success,
                  ),
                  StatusPill(
                    label: '$excused excused',
                    color: AppColors.brandYellow,
                  ),
                  StatusPill(label: '$absent absent', color: AppColors.error),
                  StatusPill(
                    label: '${records.length} classes',
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final r in records.take(6))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${r.sessionDate} · ${r.sessionTitle}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Text(
                        present(r)
                            ? 'Present'
                            : r.isExcused
                                ? 'Excused'
                                : r.normalizedStatus == AttendanceRecord.alpa
                                    ? 'Absent'
                                    : 'Not marked',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: present(r)
                              ? AppColors.success
                              : r.normalizedStatus == AttendanceRecord.alpa
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
