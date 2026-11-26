import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../l10n/labels_reports.dart';
import '../../models/cohort_report_models.dart';
import '../../models/teacher_dashboard_stat_kind.dart';
import '../../services/admin_report_export_service.dart';
import '../../services/admin_report_service.dart';
import '../../services/cohort_report_service.dart';
import '../../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/file_download.dart' as file_download;
import '../paging/paged_controller.dart';
import 'app_card.dart';
import 'app_data_table.dart';
import 'export_report_card.dart';
import 'paging_bars.dart';
import 'responsive_card_grid.dart';
import 'status_pill.dart';

/// Build 9 part 2: the students table, a page at a time. The page comes
/// from [controller] (the teacher's Students tab reads `users` and joins
/// each page with its `progress_summary`; the drill-downs read the
/// summaries). Column sorting orders the rows of the page on screen.
class StudentRosterList extends StatefulWidget {
  const StudentRosterList({
    super.key,
    required this.controller,
    this.header,
    this.padding = const EdgeInsets.all(20),
    this.inline = false,
  });

  final PagedController<StudentRosterSummary> controller;
  final Widget? header;
  final EdgeInsets padding;

  /// Drawn inside a caller's own scrolling list.
  final bool inline;

  @override
  State<StudentRosterList> createState() => _StudentRosterListState();
}

class _StudentRosterListState extends State<StudentRosterList> {
  String? _sortId;
  bool _sortAscending = true;

  /// "HSK 3 · 8 lessons/term" → "HSK 3".
  static String _levelOf(StudentRosterSummary s) =>
      s.levelLabel.split('·').first.trim();

  List<StudentRosterSummary> _sorted(List<StudentRosterSummary> page) {
    final id = _sortId;
    if (id == null) return page;
    int compare(StudentRosterSummary a, StudentRosterSummary b) {
      switch (id) {
        case 'sessions':
          return a.sessionsRemaining.compareTo(b.sessionsRemaining);
        case 'quiz':
          return (a.avgQuizScore ?? -1).compareTo(b.avgQuizScore ?? -1);
        case 'active':
          return (a.lastActivityAt ?? DateTime(2000))
              .compareTo(b.lastActivityAt ?? DateTime(2000));
        case 'level':
          return _levelOf(a).compareTo(_levelOf(b));
        default:
          return a.staffLabel
              .toLowerCase()
              .compareTo(b.staffLabel.toLowerCase());
      }
    }

    return [...page]
      ..sort((a, b) => _sortAscending ? compare(a, b) : compare(b, a));
  }

  void _onSort(String id) {
    setState(() {
      if (_sortId == id) {
        _sortAscending = !_sortAscending;
      } else {
        _sortId = id;
        _sortAscending = id == 'name' || id == 'level';
      }
    });
  }

  void _open(BuildContext context, StudentRosterSummary s) =>
      context.push('/teacher/student/${s.studentId}');

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) => PagedListBody<StudentRosterSummary>(
        controller: widget.controller,
        header: widget.header,
        padding: widget.padding,
        inline: widget.inline,
        emptyIcon: Icons.people_outline,
        emptyTitle: l.cohortNoStudentsTitle,
        emptySubtitle: l.cohortNoStudentsSubtitle,
        itemBuilder: (_, __) => const SizedBox.shrink(),
        body: AppDataTable<StudentRosterSummary>(
          rows: _sorted(widget.controller.items),
          sortColumnId: _sortId,
          sortAscending: _sortAscending,
          onSort: _onSort,
          onRowTap: (s) => _open(context, s),
          mobileBreakpoint: 760,
          columns: [
            AppTableColumn(
              id: 'name',
              label: l.commonStudent,
              flex: 3,
              sortable: true,
              cell: (s) => _StudentIdentity(student: s),
            ),
            AppTableColumn(
              id: 'level',
              label: l.cohortLevel,
              width: 90,
              sortable: true,
              cell: (s) =>
                  Text(_levelOf(s), style: const TextStyle(fontSize: 13)),
            ),
            AppTableColumn(
              id: 'term',
              label: l.cohortThisTerm,
              width: 120,
              cell: (s) => Text(s.termProgressLabel,
                  style: const TextStyle(fontSize: 13)),
            ),
            AppTableColumn(
              id: 'homework',
              label: l.cohortHomework,
              flex: 2,
              cell: (s) => Text(
                s.homeworkLocalized(l),
                style: TextStyle(
                  fontSize: 13,
                  color: s.homeworkOverdue > 0
                      ? AppColors.error
                      : AppColors.textPrimary,
                  fontWeight:
                      s.homeworkOverdue > 0 ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            AppTableColumn(
              id: 'quiz',
              label: l.cohortQuizAvg,
              width: 90,
              sortable: true,
              alignment: Alignment.centerRight,
              cell: (s) => Text(
                s.avgQuizScore == null ? '—' : '${s.avgQuizScore}%',
                style: const TextStyle(
                    fontSize: 13, fontFeatures: [FontFeature.tabularFigures()]),
              ),
            ),
            AppTableColumn(
              id: 'sessions',
              label: l.cohortSessionsLeft,
              width: 120,
              sortable: true,
              cell: (s) => _SessionsPill(remaining: s.sessionsRemaining),
            ),
            AppTableColumn(
              id: 'active',
              label: l.cohortLastActive,
              width: 100,
              sortable: true,
              cell: (s) => Text(
                s.lastActivityLocalized(l),
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
            AppTableColumn(
              id: 'go',
              label: '',
              width: 32,
              alignment: Alignment.centerRight,
              cell: (_) => Icon(Icons.chevron_right,
                  size: 18, color: AppColors.textSecondary),
            ),
          ],
          mobileCardBuilder: (s) => _StudentRosterCard(
            student: s,
            level: _levelOf(s),
            onTap: () => _open(context, s),
          ),
        ),
      ),
    );
  }
}

/// The Students tab's filters: a search box (a query on the Users search
/// index), the HSK levels, and the counts of the whole list.
class StudentRosterToolbar extends StatelessWidget {
  const StudentRosterToolbar({
    super.key,
    required this.levels,
    required this.selectedLevel,
    required this.onLevel,
    required this.onQuery,
    required this.total,
    required this.attention,
  });

  final List<String> levels;
  final String? selectedLevel;
  final ValueChanged<String?> onLevel;
  final ValueChanged<String> onQuery;
  final int? total;
  final int? attention;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final parts = <String>[
      if (total != null) l.cohortStudentCount(total!),
      if ((attention ?? 0) > 0) l.cohortNeedAttentionCount(attention!),
    ];
    final warn = (attention ?? 0) > 0;

    return Wrap(
      spacing: 12,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 260,
          child: TextField(
            onChanged: onQuery,
            decoration: InputDecoration(
              hintText: l.cohortSearchStudents,
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ChoiceChip(
              label: Text(l.cohortAllLevels),
              selected: selectedLevel == null,
              onSelected: (_) => onLevel(null),
            ),
            for (final lv in levels)
              ChoiceChip(
                label: Text(lv),
                selected: selectedLevel == lv,
                onSelected: (_) => onLevel(selectedLevel == lv ? null : lv),
              ),
          ],
        ),
        if (parts.isNotEmpty)
          Text(
            parts.join(' · '),
            style: TextStyle(
              fontSize: 13,
              color: warn ? AppColors.chipAmberFg : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}

class _StudentIdentity extends StatelessWidget {
  const _StudentIdentity({required this.student});

  final StudentRosterSummary student;

  @override
  Widget build(BuildContext context) {
    final initial =
        student.name.isNotEmpty ? student.name[0].toUpperCase() : '?';
    return Row(
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: AppColors.accentSoft,
          child: Text(
            initial,
            style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 14),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                student.staffLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              Text(
                student.levelLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SessionsPill extends StatelessWidget {
  const _SessionsPill({required this.remaining});

  final int remaining;

  @override
  Widget build(BuildContext context) {
    final color = remaining == 0
        ? AppColors.error
        : remaining <= 2
            ? AppColors.chipAmberFg
            : AppColors.success;
    return StatusPill(label: context.l10n.historyRemaining(remaining), color: color);
  }
}

class _StudentRosterCard extends StatelessWidget {
  const _StudentRosterCard(
      {required this.student, required this.level, required this.onTap});

  final StudentRosterSummary student;
  final String level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final detail = <String>[
      student.termProgressLabel,
      student.homeworkLocalized(l),
      if (student.avgQuizScore != null)
        l.cohortQuizPercent(student.avgQuizScore!),
      student.lastActivityLocalized(l),
    ].join(' · ');
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(child: _StudentIdentity(student: student)),
          const SizedBox(width: 10),
          _SessionsPill(remaining: student.sessionsRemaining),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
        ],
      ),
      // Secondary line is folded into the identity's level label on phones to
      // keep the card to one row; the detail string stays available for tooltips.
    ).withTooltip(detail);
  }
}

extension on Widget {
  Widget withTooltip(String message) => Tooltip(message: message, child: this);
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
    final l = context.l10n;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.cohortCentreStatistics,
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
                    label: l.cohortHomeworkDone,
                    value: '${stats.homeworkCompletionPercent}%',
                    color: AppColors.teal,
                    onTap: onStatTap == null
                        ? null
                        : () => onStatTap!(
                              TeacherDashboardStatKind.homeworkDone,
                            ),
                  ),
                  _StatTile(
                    label: l.cohortOverdue,
                    value: '${stats.overdueAssignments}',
                    color: stats.overdueAssignments > 0
                        ? AppColors.error
                        : AppColors.textSecondary,
                    onTap: onStatTap == null
                        ? null
                        : () => onStatTap!(TeacherDashboardStatKind.overdue),
                  ),
                  _StatTile(
                    label: l.cohortAvgQuiz,
                    value: stats.avgQuizScore != null
                        ? '${stats.avgQuizScore}%'
                        : '—',
                    color: AppColors.navy,
                    onTap: onStatTap == null
                        ? null
                        : () => onStatTap!(TeacherDashboardStatKind.avgQuiz),
                  ),
                  _StatTile(
                    label: l.cohortAvgPractice,
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
                    label: l.cohortSessionsLeft,
                    value: '${stats.totalSessionsRemaining}',
                    color: AppColors.teal,
                    onTap: onStatTap == null
                        ? null
                        : () =>
                            onStatTap!(TeacherDashboardStatKind.sessionsLeft),
                  ),
                  _StatTile(
                    label: l.cohortClassesThisWeek,
                    value: '${stats.classesThisWeek}',
                    color: AppColors.navy,
                    onTap: onStatTap == null
                        ? null
                        : () => onStatTap!(
                              TeacherDashboardStatKind.classesThisWeek,
                            ),
                  ),
                  _StatTile(
                    label: l.cohortNeedAttention,
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
                    label: l.cohortStudents,
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
            style: TextStyle(
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
    final l = context.l10n;
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
          SnackBar(content: Text(l.cohortRosterCsvDownloaded)),
        );
      } on UnsupportedError {
        await Clipboard.setData(ClipboardData(text: csv));
        messenger.showSnackBar(
          SnackBar(content: Text(l.cohortRosterCsvCopied)),
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
    final l = context.l10n;
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
                      l.adminReportsTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.cohortReportsSubtitle,
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
                          title: l.cohortCentreSummary,
                          description: l.cohortCentreSummaryDesc,
                          preview: [
                            l.cohortStudentsTracked(studentCount),
                            l.cohortWorksheetsPublished(
                              worksheetReport.totalExercises,
                            ),
                          ],
                          onExport: () => _exportPdf(context),
                        ),
                        ExportReportCard(
                          title: l.cohortStudentRoster,
                          description: l.cohortStudentRosterDesc,
                          preview: [
                            l.cohortStudentsPreview(studentCount),
                            l.cohortColumnsPreview,
                          ],
                          exportLabel: l.tableToolsExportCsv,
                          exportIcon: Icons.table_chart_outlined,
                          onExport: () => _exportCsv(context),
                        ),
                        ExportReportCard(
                          title: l.adminReportsWorksheetInventoryTitle,
                          description: l.cohortWorksheetInventoryDesc,
                          preview: [
                            l.cohortTotalWorksheets(
                              worksheetReport.totalWorksheets,
                            ),
                            ...worksheetReport.worksheetInventory.take(3).map(
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
