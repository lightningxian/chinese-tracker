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
import '../../l10n/l10n.dart';
import '../../l10n/labels_admin.dart';
import '../../models/app_user.dart';
import '../../models/attendance_record.dart';
import '../../models/invoice.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/student_report_service.dart';
import '../evaluations/student_evaluations_section.dart';
import 'student_activity.dart';

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

  /// Owner 2026-11-24: the page is a profile card and four tabs.
  int _tab = 0;

  /// Fetched once (a tab change must not reload the page); fetched again
  /// after a new photo.
  late Future<AppUser?> _user =
      context.read<FirestoreService>().getUser(widget.studentId);

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

  /// Owner 2026-11-24: the compact profile: photo (the admin may change it),
  /// names, level, contact, and the report buttons.
  Widget _profileCard(BuildContext context, AppUser student, bool isAdmin, {bool wide = true}) {
    final l = context.l10n;
    if (!wide) return _compactCard(context, student, isAdmin);
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ProfilePhotoAvatar(
              user: student,
              size: 88,
              backgroundColor: AppColors.teal,
              canEdit: isAdmin,
              onPhotoChanged: (_) => setState(() =>
                  _user = context.read<FirestoreService>().getUser(widget.studentId)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            student.displayNameIndonesian,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          if (student.displayNameChinese != null)
            Text(
              student.displayNameChinese!,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              if (student.level != null) HskBadge(label: student.level!),
              StatusPill(
                label: l.studentDetailLessonsPerTerm(student.lessonsPerTerm),
                color: AppColors.textSecondary,
              ),
              if (!student.active)
                StatusPill(label: l.studentInactive, color: AppColors.error),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 10),
          ProfileInfoRow(label: l.commonEmail, value: student.email, icon: Icons.mail_outline),
          if (student.displayWhatsapp != null)
            ProfileInfoRow(
              label: 'WhatsApp',
              value: student.displayWhatsapp!,
              icon: Icons.chat_outlined,
            ),
          if (student.parentName != null)
            ProfileInfoRow(
              label: l.identityParentName,
              value: student.parentName!,
              icon: Icons.family_restroom_outlined,
            ),
          if (student.parentPhone != null)
            ProfileInfoRow(
              label: l.identityParentPhone,
              value: student.parentPhone!,
              icon: Icons.phone_outlined,
            ),
          if (student.createdAt != null)
            ProfileInfoRow(
              label: l.studentMemberSince,
              value: DateFormat('d MMM yyyy').format(student.createdAt!),
              icon: Icons.calendar_today_outlined,
            ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () =>
                context.push('${GoRouterState.of(context).uri.path}/progress'),
            icon: const Icon(Icons.insights_outlined, size: 18),
            label: Text(l.progressReportTitle),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (isAdmin) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/admin/users/${widget.studentId}/edit'),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(l.studentDetailEditProfile),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _exporting ? null : () => _exportReport(student),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: Text(l.studentReportPdf),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Owner 2026-11-24: on a narrower screen the profile is one row.
  Widget _compactCard(BuildContext context, AppUser student, bool isAdmin) {
    final l = context.l10n;
    Widget fact(IconData icon, String text) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.textSecondary),
            const SizedBox(width: 5),
            Text(text, style: const TextStyle(fontSize: 13)),
          ],
        );
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfilePhotoAvatar(
                user: student,
                size: 64,
                backgroundColor: AppColors.teal,
                canEdit: isAdmin,
                onPhotoChanged: (_) => setState(() =>
                    _user = context.read<FirestoreService>().getUser(widget.studentId)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      [
                        student.displayNameIndonesian,
                        if (student.displayNameChinese != null) student.displayNameChinese!,
                      ].join('  '),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (student.level != null) HskBadge(label: student.level!),
                        StatusPill(
                          label: l.studentDetailLessonsPerTerm(student.lessonsPerTerm),
                          color: AppColors.textSecondary,
                        ),
                        if (!student.active)
                          StatusPill(label: l.studentInactive, color: AppColors.error),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      runSpacing: 6,
                      children: [
                        fact(Icons.mail_outline, student.email),
                        if (student.displayWhatsapp != null)
                          fact(Icons.chat_outlined, student.displayWhatsapp!),
                        if (student.parentName != null || student.parentPhone != null)
                          fact(Icons.family_restroom_outlined,
                              [student.parentName, student.parentPhone].whereType<String>().join(' · ')),
                        if (student.createdAt != null)
                          fact(Icons.calendar_today_outlined,
                              '${l.studentMemberSince} ${DateFormat('d MMM yyyy').format(student.createdAt!)}'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () =>
                    context.push('${GoRouterState.of(context).uri.path}/progress'),
                icon: const Icon(Icons.insights_outlined, size: 18),
                label: Text(l.progressReportTitle),
              ),
              if (isAdmin)
                OutlinedButton.icon(
                  onPressed: () => context.push('/admin/users/${widget.studentId}/edit'),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(l.studentDetailEditProfile),
                ),
              OutlinedButton.icon(
                onPressed: _exporting ? null : () => _exportReport(student),
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: Text(l.studentReportPdf),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final firestore = context.read<FirestoreService>();

    return FutureBuilder(
      future: _user,
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
            body: Center(child: Text(l.studentDetailNotFound)),
          );
        }

        final contentOwnerId = AppConstants.contentOwnerFor(student);
        final viewer = context.read<AuthService>().appUser;
        final isAdmin = viewer?.isAdmin ?? false;

        return ShellNestedPage(
          embedded: widget.embedded,
          title: student.staffLabel,
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

                  final wide = MediaQuery.sizeOf(context).width >= 1100;
                  final card = _profileCard(context, student, isAdmin, wide: wide);
                  final tabs = [
                    l.studentTabOverview,
                    l.studentTabClasses,
                    l.studentTabHistory,
                    l.studentTabLearning,
                  ];
                  final tabBar = SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SegmentedButton<int>(
                      showSelectedIcon: false,
                      segments: [
                        for (var i = 0; i < tabs.length; i++)
                          ButtonSegment(value: i, label: Text(tabs[i])),
                      ],
                      selected: {_tab},
                      onSelectionChanged: (v) => setState(() => _tab = v.first),
                    ),
                  );
                  final section = <Widget>[
                    if (_tab == 0) ...[
                      StudentClassTermSection(
                        studentId: widget.studentId,
                        showAddButton: true,
                        allowManage: true,
                      ),
                      const SizedBox(height: 24),
                      SectionHeader(title: l.navPayments),
                      _PaymentsSection(
                        studentId: widget.studentId,
                        firestore: firestore,
                      ),
                    ],
                    if (_tab == 1) ...[
                      SectionHeader(title: l.studentUpcomingClasses),
                      StudentUpcomingClasses(
                        studentId: widget.studentId,
                        onOpen: (id) => context.push(
                            isAdmin ? '/admin/session/$id' : '/teacher/session/$id'),
                      ),
                      const SizedBox(height: 24),
                      SectionHeader(title: l.studentDetailAttendance),
                      _AttendanceSection(
                        studentId: widget.studentId,
                        firestore: firestore,
                      ),
                    ],
                    if (_tab == 2) StudentActivityTimeline(studentId: widget.studentId),
                    if (_tab == 3) ...[
                      StudentEvaluationsSection(
                        studentId: widget.studentId,
                        teacherId: context.read<AuthService>().appUser?.uid ??
                            contentOwnerId,
                      ),
                      const SizedBox(height: 24),
                      SectionHeader(title: l.studentDetailPracticeResults),
                      StudentPracticeResultsSection(
                        studentId: widget.studentId,
                        firestore: firestore,
                      ),
                      const SizedBox(height: 24),
                      SectionHeader(
                        title: l.studentDetailLessonProgressByTerm,
                      ),
                      if (terms.isEmpty)
                        AppCard(
                          child: Text(
                            l.studentDetailNoLessonProgress,
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
                  ];
                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 340,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 20, 0, 20),
                            child: card,
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.all(20),
                            children: [tabBar, const SizedBox(height: 16), ...section],
                          ),
                        ),
                      ],
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      card,
                      const SizedBox(height: 16),
                      tabBar,
                      const SizedBox(height: 16),
                      ...section,
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

  // A getter, not a static final: the locale is read when it is built.
  static DateFormat get _date => DateFormat('d MMM yyyy');

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
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
              l.studentDetailNoInvoices,
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
                    label: l.studentDetailPaidTotal(formatRupiah(paid)),
                    color: AppColors.success,
                  ),
                  if (pending > 0)
                    StatusPill(
                      label: l.studentDetailPendingTotal(formatRupiah(pending)),
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
                              inv.itemLocalized(l),
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
                                inv.methodLocalized(l),
                                if (inv.paidAt != null)
                                  l.studentDetailPaidOn(
                                    _date.format(inv.paidAt!),
                                  )
                                else if (inv.dueDate.isNotEmpty)
                                  l.studentDetailDueOn(inv.dueDate),
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
                        label: inv.status.localized(l),
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
                    l.studentDetailMoreInPayments(invoices.length - 8),
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
    final l = context.l10n;
    return StreamBuilder<List<AttendanceRecord>>(
      stream: firestore.watchStudentAttendance(studentId),
      builder: (context, snap) {
        final records = [...(snap.data ?? const <AttendanceRecord>[])]
          ..sort((a, b) => b.sessionDate.compareTo(a.sessionDate));
        if (records.isEmpty) {
          return AppCard(
            child: Text(
              l.parentOverviewNoClasses,
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
                    label: l.studentDetailPresentCount(presentCount),
                    color: AppColors.success,
                  ),
                  StatusPill(
                    label: l.studentDetailExcusedCount(excused),
                    color: AppColors.brandYellow,
                  ),
                  StatusPill(
                    label: l.studentDetailAbsentCount(absent),
                    color: AppColors.error,
                  ),
                  StatusPill(
                    label: l.historyClassesCount(records.length),
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
                            ? l.attendancePresent
                            : r.isExcused
                                ? l.attendanceExcused
                                : r.normalizedStatus == AttendanceRecord.alpa
                                    ? l.attendanceAbsent
                                    : l.studentDetailNotMarked,
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
