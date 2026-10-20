import 'dart:ui' show FontFeature;

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
import 'app_data_table.dart';
import 'export_report_card.dart';
import 'responsive_card_grid.dart';
import 'status_pill.dart';

class StudentRosterList extends StatefulWidget {
  const StudentRosterList({
    super.key,
    required this.students,
    this.padding = const EdgeInsets.all(20),
  });

  final List<StudentRosterSummary> students;
  final EdgeInsetsGeometry padding;

  @override
  State<StudentRosterList> createState() => _StudentRosterListState();
}

class _StudentRosterListState extends State<StudentRosterList> {
  String _query = '';
  String? _level;
  String _sortId = 'name';
  bool _sortAscending = true;

  /// "HSK 3 · 8 lessons/term" → "HSK 3".
  static String _levelOf(StudentRosterSummary s) =>
      s.levelLabel.split('·').first.trim();

  static bool _needsAttention(StudentRosterSummary s) =>
      s.sessionsRemaining <= 2 || s.homeworkOverdue > 0;

  List<String> get _levels {
    final set = {for (final s in widget.students) _levelOf(s)}
      ..removeWhere((l) => l.isEmpty);
    return set.toList()..sort();
  }

  List<StudentRosterSummary> get _visible {
    final q = _query.trim().toLowerCase();
    final rows = widget.students.where((s) {
      if (_level != null && _levelOf(s) != _level) return false;
      if (q.isNotEmpty && !s.name.toLowerCase().contains(q)) return false;
      return true;
    }).toList();

    int compare(StudentRosterSummary a, StudentRosterSummary b) {
      switch (_sortId) {
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
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
    }

    rows.sort((a, b) => _sortAscending ? compare(a, b) : compare(b, a));
    return rows;
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
    if (widget.students.isEmpty) {
      return const EmptyState(
        icon: Icons.people_outline,
        title: 'No students yet',
        subtitle: 'Students appear here after they register in the app.',
      );
    }

    final rows = _visible;
    final attention = widget.students.where(_needsAttention).length;

    return Padding(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RosterToolbar(
            levels: _levels,
            selectedLevel: _level,
            onLevel: (l) => setState(() => _level = l),
            onQuery: (q) => setState(() => _query = q),
            total: widget.students.length,
            shown: rows.length,
            attention: attention,
          ),
          const SizedBox(height: 14),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'No students match this search.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            AppDataTable<StudentRosterSummary>(
              rows: rows,
              sortColumnId: _sortId,
              sortAscending: _sortAscending,
              onSort: _onSort,
              onRowTap: (s) => _open(context, s),
              mobileBreakpoint: 760,
              columns: [
                AppTableColumn(
                  id: 'name',
                  label: 'Student',
                  flex: 3,
                  sortable: true,
                  cell: (s) => _StudentIdentity(student: s),
                ),
                AppTableColumn(
                  id: 'level',
                  label: 'Level',
                  width: 90,
                  sortable: true,
                  cell: (s) =>
                      Text(_levelOf(s), style: const TextStyle(fontSize: 13)),
                ),
                AppTableColumn(
                  id: 'term',
                  label: 'This term',
                  width: 120,
                  cell: (s) => Text(s.termProgressLabel,
                      style: const TextStyle(fontSize: 13)),
                ),
                AppTableColumn(
                  id: 'homework',
                  label: 'Homework',
                  flex: 2,
                  cell: (s) => Text(
                    s.homeworkLabel,
                    style: TextStyle(
                      fontSize: 13,
                      color: s.homeworkOverdue > 0
                          ? AppColors.error
                          : AppColors.textPrimary,
                      fontWeight: s.homeworkOverdue > 0
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
                AppTableColumn(
                  id: 'quiz',
                  label: 'Quiz avg',
                  width: 90,
                  sortable: true,
                  alignment: Alignment.centerRight,
                  cell: (s) => Text(
                    s.avgQuizScore == null ? '—' : '${s.avgQuizScore}%',
                    style: const TextStyle(
                        fontSize: 13,
                        fontFeatures: [FontFeature.tabularFigures()]),
                  ),
                ),
                AppTableColumn(
                  id: 'sessions',
                  label: 'Sessions left',
                  width: 120,
                  sortable: true,
                  cell: (s) => _SessionsPill(remaining: s.sessionsRemaining),
                ),
                AppTableColumn(
                  id: 'active',
                  label: 'Last active',
                  width: 100,
                  sortable: true,
                  cell: (s) => Text(
                    s.lastActivityLabel,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
                AppTableColumn(
                  id: 'go',
                  label: '',
                  width: 32,
                  alignment: Alignment.centerRight,
                  cell: (_) => const Icon(Icons.chevron_right,
                      size: 18, color: AppColors.textSecondary),
                ),
              ],
              mobileCardBuilder: (s) => _StudentRosterCard(
                student: s,
                level: _levelOf(s),
                onTap: () => _open(context, s),
              ),
            ),
        ],
      ),
    );
  }
}

class _RosterToolbar extends StatelessWidget {
  const _RosterToolbar({
    required this.levels,
    required this.selectedLevel,
    required this.onLevel,
    required this.onQuery,
    required this.total,
    required this.shown,
    required this.attention,
  });

  final List<String> levels;
  final String? selectedLevel;
  final ValueChanged<String?> onLevel;
  final ValueChanged<String> onQuery;
  final int total;
  final int shown;
  final int attention;

  @override
  Widget build(BuildContext context) {
    final summary = StringBuffer('$total student${total == 1 ? '' : 's'}');
    if (shown != total) summary.write(' · $shown shown');
    if (attention > 0) summary.write(' · $attention need attention');

    return Wrap(
      spacing: 12,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 260,
          child: TextField(
            onChanged: onQuery,
            decoration: const InputDecoration(
              hintText: 'Search students',
              prefixIcon: Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
        if (levels.length > 1)
          Wrap(
            spacing: 6,
            children: [
              ChoiceChip(
                label: const Text('All levels'),
                selected: selectedLevel == null,
                onSelected: (_) => onLevel(null),
              ),
              for (final l in levels)
                ChoiceChip(
                  label: Text(l),
                  selected: selectedLevel == l,
                  onSelected: (_) => onLevel(selectedLevel == l ? null : l),
                ),
            ],
          ),
        Text(
          summary.toString(),
          style: TextStyle(
            fontSize: 13,
            color:
                attention > 0 ? AppColors.chipAmberFg : AppColors.textSecondary,
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
            style: const TextStyle(
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
                student.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              Text(
                student.levelLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
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
    return StatusPill(label: '$remaining left', color: color);
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
    final detail = <String>[
      student.termProgressLabel,
      student.homeworkLabel,
      if (student.avgQuizScore != null) 'Quiz ${student.avgQuizScore}%',
      student.lastActivityLabel,
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
          const Icon(Icons.chevron_right,
              color: AppColors.textSecondary, size: 18),
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
