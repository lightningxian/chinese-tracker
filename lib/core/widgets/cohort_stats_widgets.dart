import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/cohort_report_models.dart';
import '../../models/teacher_dashboard_stat_kind.dart';
import '../../services/admin_report_export_service.dart';
import '../../services/admin_report_service.dart';
import '../../services/cohort_report_service.dart';
import '../../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/file_download.dart' as file_download;
import 'app_card.dart';
import 'export_report_card.dart';
import 'responsive_card_grid.dart';
import 'status_pill.dart';

class StudentRosterList extends StatelessWidget {
  const StudentRosterList({
    super.key,
    required this.students,
    this.padding = const EdgeInsets.all(20),
  });

  final List<StudentRosterSummary> students;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return const EmptyState(
        icon: Icons.people_outline,
        title: 'No students yet',
        subtitle: 'Students appear here after they register in the app.',
      );
    }

    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = ResponsiveCardGrid.columnCount(
            constraints.maxWidth,
            minCardWidth: 300,
          );
          final compact = columns > 1;

          return ResponsiveCardGrid(
            width: constraints.maxWidth,
            children: [
              for (final student in students)
                AppCard(
                onTap: () =>
                    context.push('/teacher/student/${student.studentId}'),
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 12 : 14,
                  vertical: compact ? 10 : 12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: compact ? 18 : 20,
                      backgroundColor: AppColors.teal.withValues(alpha: 0.12),
                      child: Text(
                        student.name.isNotEmpty
                            ? student.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: AppColors.teal,
                          fontWeight: FontWeight.w700,
                          fontSize: compact ? 14 : 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  student.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: compact ? 14 : 16,
                                  ),
                                ),
                              ),
                              if (!compact)
                                Text(
                                  student.lastActivityLabel,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            student.levelLabel,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: compact ? 12 : 13,
                            ),
                          ),
                          if (compact) ...[
                            const SizedBox(height: 2),
                            Text(
                              student.lastActivityLabel,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              StatusPill(
                                label: student.termProgressLabel,
                                color: AppColors.navy,
                              ),
                              StatusPill(
                                label: student.homeworkLabel,
                                color: student.homeworkOverdue > 0
                                    ? AppColors.error
                                    : AppColors.teal,
                              ),
                              if (student.avgQuizScore != null)
                                StatusPill(
                                  label: 'Quiz ${student.avgQuizScore}%',
                                  color: AppColors.success,
                                ),
                              StatusPill(
                                label:
                                    '${student.sessionsRemaining} session${student.sessionsRemaining == 1 ? '' : 's'} left',
                                color: student.sessionsRemaining > 0
                                    ? AppColors.teal
                                    : AppColors.error,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CohortStatsGrid extends StatelessWidget {
  const CohortStatsGrid({
    super.key,
    required this.stats,
    this.onStatTap,
  });

  final CohortStats stats;
  final ValueChanged<TeacherDashboardStatKind>? onStatTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Centre statistics',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              return ResponsiveCardGrid(
                width: constraints.maxWidth,
                minCardWidth: 140,
                maxColumns: 4,
                gap: 10,
                children: [
                  _StatTile(
                    label: 'Homework done',
                    value: '${stats.homeworkCompletionPercent}%',
                    color: AppColors.teal,
                    onTap: onStatTap == null
                        ? null
                        : () => onStatTap!(
                              TeacherDashboardStatKind.homeworkDone,
                            ),
                  ),
                  _StatTile(
                    label: 'Overdue',
                    value: '${stats.overdueAssignments}',
                    color: stats.overdueAssignments > 0
                        ? AppColors.error
                        : AppColors.textSecondary,
                    onTap: onStatTap == null
                        ? null
                        : () => onStatTap!(TeacherDashboardStatKind.overdue),
                  ),
                  _StatTile(
                    label: 'Avg quiz',
                    value: stats.avgQuizScore != null
                        ? '${stats.avgQuizScore}%'
                        : '—',
                    color: AppColors.navy,
                    onTap: onStatTap == null
                        ? null
                        : () => onStatTap!(TeacherDashboardStatKind.avgQuiz),
                  ),
                  _StatTile(
                    label: 'Avg practice',
                    value: stats.avgPracticeScore != null
                        ? '${stats.avgPracticeScore}%'
                        : '—',
                    color: AppColors.navy,
                    onTap: onStatTap == null
                        ? null
                        : () =>
                            onStatTap!(TeacherDashboardStatKind.avgPractice),
                  ),
                  _StatTile(
                    label: 'Sessions left',
                    value: '${stats.totalSessionsRemaining}',
                    color: AppColors.teal,
                    onTap: onStatTap == null
                        ? null
                        : () =>
                            onStatTap!(TeacherDashboardStatKind.sessionsLeft),
                  ),
                  _StatTile(
                    label: 'Classes this week',
                    value: '${stats.classesThisWeek}',
                    color: AppColors.navy,
                    onTap: onStatTap == null
                        ? null
                        : () => onStatTap!(
                              TeacherDashboardStatKind.classesThisWeek,
                            ),
                  ),
                  _StatTile(
                    label: 'Need attention',
                    value: '${stats.studentsNeedingAttention}',
                    color: stats.studentsNeedingAttention > 0
                        ? AppColors.error
                        : AppColors.success,
                    onTap: onStatTap == null
                        ? null
                        : () =>
                            onStatTap!(TeacherDashboardStatKind.needAttention),
                  ),
                  _StatTile(
                    label: 'Students',
                    value: '${stats.totalStudents}',
                    color: AppColors.navy,
                    onTap: onStatTap == null
                        ? null
                        : () => onStatTap!(TeacherDashboardStatKind.students),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: color.withValues(alpha: 0.7),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return child;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: child,
      ),
    );
  }
}

class CohortExportActions extends StatelessWidget {
  const CohortExportActions({super.key});

  Future<void> _exportPdf(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<CohortReportService>().previewCohortSummary();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _exportCsv(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final service = context.read<CohortReportService>();
      final data = await service.buildCohortSummary();
      final csv = service.buildCohortCsv(data);
      final filename =
          'centre_roster_${DateTime.now().toIso8601String().substring(0, 10)}.csv';

      try {
        file_download.downloadTextFile(filename, csv);
        messenger.showSnackBar(
          const SnackBar(content: Text('Roster CSV downloaded')),
        );
      } on UnsupportedError {
        await Clipboard.setData(ClipboardData(text: csv));
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Roster CSV copied to clipboard'),
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _exportWorksheetInventory(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context
          .read<AdminReportExportService>()
          .exportPdf(AdminExportReport.worksheetInventory);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();

    return StreamBuilder(
      stream: firestore.watchAllStudents(),
      builder: (context, studentsSnap) {
        return StreamBuilder(
          stream: firestore.watchAllExercises(),
          builder: (context, exercisesSnap) {
            final studentCount = (studentsSnap.data ?? []).length;
            final exercises = exercisesSnap.data ?? [];
            final worksheetReport = AdminReportService.build(
              users: const [],
              exercises: exercises,
              classTerms: const [],
            );

            return LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reports',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Export centre summaries and worksheet inventory for your records.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ResponsiveCardGrid(
                      width: constraints.maxWidth,
                      children: [
                        ExportReportCard(
                          title: 'Centre summary',
                          description:
                              'Homework completion, quiz averages, sessions '
                              'remaining, and students needing attention.',
                          preview: [
                            'Students tracked: $studentCount',
                            'Worksheets published: ${worksheetReport.totalExercises}',
                          ],
                          onExport: () => _exportPdf(context),
                        ),
                        ExportReportCard(
                          title: 'Student roster',
                          description:
                              'Full student list with progress, homework, and '
                              'session balance. Spreadsheet export.',
                          preview: [
                            'Students: $studentCount',
                            'Columns: level, homework, quiz, sessions',
                          ],
                          exportLabel: 'Export CSV',
                          exportIcon: Icons.table_chart_outlined,
                          onExport: () => _exportCsv(context),
                        ),
                        ExportReportCard(
                          title: 'Worksheet inventory',
                          description:
                              'All practice worksheets produced, grouped by HSK '
                              'level and skill section (Reading, Listening, etc.).',
                          preview: [
                            'Total worksheets: ${worksheetReport.totalWorksheets}',
                            ...worksheetReport.worksheetInventory
                                .take(3)
                                .map(
                                  (row) => row.skillSummary.isEmpty
                                      ? '${row.hskLevel}: ${row.total}'
                                      : '${row.hskLevel}: ${row.total} '
                                          '(${row.skillSummary})',
                                ),
                          ],
                          onExport: () => _exportWorksheetInventory(context),
                        ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
