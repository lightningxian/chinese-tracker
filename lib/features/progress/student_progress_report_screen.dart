import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/shell_nested_page.dart';
import '../../l10n/l10n.dart';
import '../../models/app_user.dart';
import '../../models/progress_summary.dart';
import '../../models/test_track.dart';
import '../../services/auth_service.dart';
import '../../services/progress_service.dart';
import '../../services/student_report_service.dart';
import '../tests/promotion_screen.dart' show levelGroupName;
import '../tests/test_labels.dart';
import '../tests/test_player_screen.dart' show PlacementChip;

/// Build 4 (docs/PLAN.md §4, Must 6): the progress report of one student,
/// the same widget for the student, the parent, the teacher and the admin.
/// It reads `progress_summary/{id}` (functions keep it) and streams the
/// teacher's notes.
class StudentProgressReportScreen extends StatelessWidget {
  const StudentProgressReportScreen({
    super.key,
    required this.studentId,
    this.embedded = false,
    this.page = false,
  });

  final String studentId;

  /// Inside a role shell (no own app bar).
  final bool embedded;

  /// As its own page with a title bar (staff open it from a student).
  final bool page;

  @override
  Widget build(BuildContext context) {
    final body = StudentProgressReport(studentId: studentId);
    if (!page) return body;
    return ShellNestedPage(
      embedded: embedded,
      title: context.l10n.progressReportTitle,
      child: body,
    );
  }
}

/// The report body (a scrolling list).
class StudentProgressReport extends StatefulWidget {
  const StudentProgressReport({super.key, required this.studentId});

  final String studentId;

  @override
  State<StudentProgressReport> createState() => _StudentProgressReportState();
}

class _StudentProgressReportState extends State<StudentProgressReport> {
  final _service = ProgressService();
  late final Stream<ProgressSummary?> _summary =
      _service.watchSummary(widget.studentId);
  late final Stream<List<ProgressNote>> _notes =
      _service.watchNotes(widget.studentId);
  bool _printing = false;

  Future<void> _print() async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _printing = true);
    try {
      await context.read<StudentReportService>().previewReport(widget.studentId);
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(l.progressPrintFailed('$e')),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final viewer = context.watch<AuthService>().appUser;
    return StreamBuilder<ProgressSummary?>(
      stream: _summary,
      builder: (context, snap) {
        if (snap.hasError) {
          return EmptyState(
            icon: Icons.lock_outline,
            title: l.progressReportUnavailable,
            subtitle: '',
          );
        }
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final s = snap.data;
        if (s == null) {
          return EmptyState(
            icon: Icons.insights_outlined,
            title: l.progressReportEmptyTitle,
            subtitle: l.progressReportEmptySubtitle,
          );
        }
        final staff = viewer?.isStaff ?? false;
        final canNote = viewer != null &&
            (viewer.isAdmin || (viewer.isTeacher && viewer.uid == s.teacherId));
        return LayoutBuilder(builder: (context, c) {
          final wide = c.maxWidth >= 760;
          return ListView(
            padding: EdgeInsets.all(wide ? 24 : 16),
            children: [
              _Header(summary: s, staff: staff, printing: _printing, onPrint: _print),
              const SizedBox(height: 12),
              _CodesBar(summary: s),
              const SizedBox(height: 12),
              _Kpis(summary: s, wide: wide),
              const SizedBox(height: 12),
              if (s.warnings.isNotEmpty) ...[
                _Warnings(summary: s),
                const SizedBox(height: 12),
              ],
              _Section(
                title: l.progressPracticeChart,
                child: _PracticeChart(weeks: s.weeks),
              ),
              const SizedBox(height: 12),
              if (wide)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                          child: _Section(
                              title: l.progressSkills,
                              child: _SkillBars(skills: s.skills))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _NotesSection(
                          studentId: s.studentId,
                          notes: _notes,
                          canNote: canNote,
                          viewer: viewer,
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                _Section(
                    title: l.progressSkills, child: _SkillBars(skills: s.skills)),
                const SizedBox(height: 12),
                _NotesSection(
                  studentId: s.studentId,
                  notes: _notes,
                  canNote: canNote,
                  viewer: viewer,
                ),
              ],
              const SizedBox(height: 12),
              _Section(
                title: l.progressTestHistory,
                child: _TestHistory(summary: s, viewer: viewer),
              ),
              const SizedBox(height: 12),
              _Section(
                title: l.progressAttendance,
                child: _AttendanceList(summary: s),
              ),
              const SizedBox(height: 12),
              _Section(
                title: l.progressLevelHistory,
                child: _LevelHistory(summary: s),
              ),
            ],
          );
        });
      },
    );
  }
}

// ----------------------------------------------------------------- labels

String progressStatusLabel(AppLocalizations l, ProgressStatus s) => switch (s) {
      ProgressStatus.good => l.progressStatusGood,
      ProgressStatus.attention => l.progressStatusAttention,
      ProgressStatus.followUp => l.progressStatusFollowUp,
    };

Color progressStatusColor(ProgressStatus s) => switch (s) {
      ProgressStatus.good => AppColors.success,
      ProgressStatus.attention => AppColors.chipAmberFg,
      ProgressStatus.followUp => AppColors.error,
    };

String progressWarningTitle(AppLocalizations l, int id) => switch (id) {
      1 => l.progressWarn1,
      2 => l.progressWarn2,
      3 => l.progressWarn3,
      4 => l.progressWarn4,
      5 => l.progressWarn5,
      _ => '',
    };

String progressWarningRule(AppLocalizations l, int id) => switch (id) {
      1 => l.progressWarn1Rule,
      2 => l.progressWarn2Rule,
      3 => l.progressWarn3Rule,
      4 => l.progressWarn4Rule,
      5 => l.progressWarn5Rule,
      _ => '',
    };

/// The status chip (also on the attention lists).
class ProgressStatusChip extends StatelessWidget {
  const ProgressStatusChip({super.key, required this.status});

  final ProgressStatus status;

  @override
  Widget build(BuildContext context) {
    final color = progressStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        progressStatusLabel(context.l10n, status),
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title,
              style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text, style: TextStyle(color: AppColors.textSecondary)),
      );
}

// ----------------------------------------------------------------- header

class _Header extends StatelessWidget {
  const _Header({
    required this.summary,
    required this.staff,
    required this.printing,
    required this.onPrint,
  });

  final ProgressSummary summary;
  final bool staff;
  final bool printing;
  final VoidCallback onPrint;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = summary;
    final name = staff
        ? AppUser.staffLabelOf(s.studentNameChinese, s.studentName)
        : AppUser.staffLabelOf(s.studentNameChinese, s.studentName);
    final group = levelGroupName(l, s.level);
    return AppCard(
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            name,
            style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.navy),
          ),
          if (s.level.isNotEmpty)
            Chip(
              visualDensity: VisualDensity.compact,
              label: Text(group.isEmpty ? s.level : '${s.level} · $group'),
            ),
          ProgressStatusChip(status: s.status),
          TextButton.icon(
            onPressed: printing ? null : onPrint,
            icon: printing
                ? const SizedBox(
                    width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.print_outlined, size: 18),
            label: Text(l.progressPrint),
          ),
        ],
      ),
    );
  }
}

class _CodesBar extends StatelessWidget {
  const _CodesBar({required this.summary});

  final ProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = summary;
    final min = s.minCodes <= 0 ? 3 : s.minCodes;
    final count = s.codesCount > min ? min : s.codesCount;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.nextLevel.isEmpty
                ? l.promotionTopLevel
                : l.progressCodesToward(count, min, s.nextLevel),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (count / min).clamp(0, 1).toDouble(),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------- KPIs

class _Kpis extends StatelessWidget {
  const _Kpis({required this.summary, required this.wide});

  final ProgressSummary summary;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = summary;
    final change = s.practiceChange;
    final cards = [
      _Kpi(
        icon: Icons.event_available_outlined,
        label: l.progressKpiAttendance,
        value: s.attendancePercent == null ? '—' : '${s.attendancePercent}%',
        note: l.progressKpiAttendanceNote(s.hadir, s.alpa, s.izin),
      ),
      _Kpi(
        icon: Icons.edit_note_outlined,
        label: l.progressKpiPractice,
        value: s.average14 == null ? '—' : s.average14!.toStringAsFixed(0),
        note: change == null
            ? l.progressKpiPracticeNote(s.attempts14)
            : l.progressKpiPracticeChange(
                '${change >= 0 ? '+' : ''}${change.toStringAsFixed(0)}'),
        noteColor: change == null
            ? null
            : change >= 0
                ? AppColors.success
                : AppColors.error,
      ),
      _Kpi(
        icon: Icons.emoji_events_outlined,
        label: l.progressKpiTests,
        value: '${s.passedAtLevel}',
        note: s.level.isEmpty ? '' : l.progressKpiTestsNote(s.level),
      ),
      _Kpi(
        icon: Icons.confirmation_number_outlined,
        label: l.progressKpiVoucher,
        value: s.hasVoucher ? '${s.sessionsRemaining}' : '—',
        note: !s.hasVoucher
            ? l.progressKpiNoVoucher
            : s.daysLeft == null
                ? ''
                : l.progressKpiVoucherNote(s.daysLeft!),
        noteColor: s.hasVoucher && (s.daysLeft ?? 99) <= 7 ? AppColors.error : null,
      ),
    ];
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 760 ? 4 : 2;
      final w = (c.maxWidth - 12 * (cols - 1)) / cols;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [for (final k in cards) SizedBox(width: w, child: k)],
      );
    });
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.icon,
    required this.label,
    required this.value,
    required this.note,
    this.noteColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final String note;
  final Color? noteColor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 18, color: AppColors.teal),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ),
          ]),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.navy)),
          if (note.isNotEmpty)
            Text(note,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12, color: noteColor ?? AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------- warnings

class _Warnings extends StatelessWidget {
  const _Warnings({required this.summary});

  final ProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return _Section(
      title: l.progressWarnings,
      child: Column(
        children: [
          for (final w in summary.warnings)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.warning_amber_rounded, color: AppColors.chipAmberFg),
              title: Text(progressWarningTitle(l, w.id),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${progressWarningRule(l, w.id)}\n${w.detail}'),
              isThreeLine: true,
            ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------- chart

class _PracticeChart extends StatelessWidget {
  const _PracticeChart({required this.weeks});

  final List<PracticeWeek> weeks;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final points = practiceChartPoints(weeks);
    if (points.isEmpty) return _Empty(l.progressPracticeEmpty);
    final line = AppColors.teal;
    final grid = AppColors.border;
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (weeks.length - 1).toDouble(),
          minY: 0,
          maxY: 100,
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (_) => FlLine(color: grid, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 25,
                reservedSize: 32,
                getTitlesWidget: (v, _) => Text('${v.toInt()}',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 24,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= weeks.length || i % 2 == 1) {
                    return const SizedBox.shrink();
                  }
                  final d = DateTime.tryParse(weeks[i].monday);
                  return Text(d == null ? '' : DateFormat('d/M').format(d),
                      style: TextStyle(fontSize: 10, color: AppColors.textSecondary));
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => [
                for (final s in spots)
                  LineTooltipItem(
                    '${s.y.toStringAsFixed(0)} · '
                    '${l.progressAttempts(weeks[s.x.toInt()].attempts)}',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
              ],
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [for (final p in points) FlSpot(p.x, p.y)],
              color: line,
              barWidth: 3,
              isCurved: false,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: line.withValues(alpha: 0.12)),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- skills

class _SkillBars extends StatelessWidget {
  const _SkillBars({required this.skills});

  final List<SkillAverage> skills;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (skills.isEmpty) return _Empty(l.progressSkillsEmpty);
    return Column(
      children: [
        for (final s in skills)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 96,
                  child: Text(TestSkill.fromValue(s.skill).localized(l)),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: s.percent / 100,
                      minHeight: 10,
                      color: s.percent >= 60 ? AppColors.teal : AppColors.chipAmberFg,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 44,
                  child: Text('${s.percent}%',
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ----------------------------------------------------------------- notes

class _NotesSection extends StatelessWidget {
  const _NotesSection({
    required this.studentId,
    required this.notes,
    required this.canNote,
    required this.viewer,
  });

  final String studentId;
  final Stream<List<ProgressNote>> notes;
  final bool canNote;
  final AppUser? viewer;

  Future<void> _edit(BuildContext context, {ProgressNote? note}) async {
    final l = context.l10n;
    final controller = TextEditingController(text: note?.text ?? '');
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(note == null ? l.progressAddNote : l.progressEditNote),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(hintText: l.progressNoteHint),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l.commonCancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l.roomsSave),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text == null || text.isEmpty || viewer == null) return;
    final service = ProgressService();
    if (note == null) {
      await service.addNote(
        studentId: studentId,
        teacherId: viewer!.uid,
        teacherName: viewer!.latinName,
        text: text,
      );
    } else {
      await service.updateNote(note.id, text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return _Section(
      title: l.progressTeacherNote,
      child: StreamBuilder<List<ProgressNote>>(
        stream: notes,
        builder: (context, snap) {
          final list = snap.data ?? const [];
          final latest = list.isEmpty ? null : list.first;
          final mine = latest != null &&
              viewer != null &&
              (viewer!.isAdmin || latest.teacherId == viewer!.uid);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (latest == null)
                _Empty(l.progressNoteEmpty)
              else ...[
                Text(latest.text),
                const SizedBox(height: 4),
                Text(
                  [
                    latest.teacherName,
                    if (latest.createdAt != null)
                      DateFormat.yMMMd().format(latest.createdAt!),
                  ].join(' · '),
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
              if (canNote)
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () => _edit(context),
                      icon: const Icon(Icons.add_comment_outlined, size: 18),
                      label: Text(l.progressAddNote),
                    ),
                    if (mine)
                      TextButton.icon(
                        onPressed: () => _edit(context, note: latest),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: Text(l.progressEditNote),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

// ----------------------------------------------------------------- tests

class _TestHistory extends StatelessWidget {
  const _TestHistory({required this.summary, required this.viewer});

  final ProgressSummary summary;
  final AppUser? viewer;

  String? _resultRoute(ProgressTestRow t) {
    final v = viewer;
    if (v == null || t.resultId.isEmpty) return null;
    if (v.isStudent) return '/student/test-result/${t.resultId}';
    if (v.isAdmin) return '/admin/tests/result/${t.resultId}';
    if (v.isTeacher) return '/teacher/tests/result/${t.resultId}';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (summary.tests.isEmpty) return _Empty(l.progressTestsEmpty);
    return Column(
      children: [
        for (final t in summary.tests)
          InkWell(
            onTap: _resultRoute(t) == null
                ? null
                : () => context.push(_resultRoute(t)!),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          [
                            t.code,
                            if (t.level.isNotEmpty) t.level,
                            if (t.finishedAt != null)
                              DateFormat.yMMMd().format(t.finishedAt!),
                          ].join(' · '),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            for (final p in t.parts)
                              Text(
                                  '${TestSkill.fromValue(p.skill).localized(l)} ${p.mark}',
                                  style: TextStyle(
                                      fontSize: 12, color: AppColors.textSecondary)),
                            if (t.rank != null && t.boardSize != null)
                              Text(l.progressRank(t.rank!, t.boardSize!),
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.teal)),
                            if (t.placement) PlacementChip(label: l.placementTestLabel),
                            if (!t.valid) _Tag(l.progressTagInvalid, AppColors.error),
                            if (t.pendingMarking)
                              _Tag(l.testsPendingMarking, AppColors.chipAmberFg),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${t.total} / ${t.max}',
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      if (!t.pendingMarking)
                        Text(
                          t.passed ? '合格' : '不合格',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: t.passed ? AppColors.success : AppColors.error,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, this.color);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      );
}

// ----------------------------------------------------------------- attendance

class _AttendanceList extends StatelessWidget {
  const _AttendanceList({required this.summary});

  final ProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (summary.attendanceLast.isEmpty) return _Empty(l.progressAttendanceEmpty);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final r in summary.attendanceLast)
          Chip(
            visualDensity: VisualDensity.compact,
            avatar: Icon(
              r.status == 'hadir'
                  ? Icons.check_circle
                  : r.status == 'izin'
                      ? Icons.schedule
                      : Icons.cancel,
              size: 16,
              color: r.status == 'hadir'
                  ? AppColors.success
                  : r.status == 'izin'
                      ? AppColors.chipAmberFg
                      : AppColors.error,
            ),
            label: Text(_dateLabel(r.sessionDate)),
          ),
      ],
    );
  }

  static String _dateLabel(String ymd) {
    final d = DateTime.tryParse(ymd);
    return d == null ? ymd : DateFormat.MMMd().format(d);
  }
}

// ----------------------------------------------------------------- levels

class _LevelHistory extends StatelessWidget {
  const _LevelHistory({required this.summary});

  final ProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (summary.levelHistory.isEmpty) return _Empty(l.progressLevelHistoryEmpty);
    return Column(
      children: [
        for (final h in summary.levelHistory)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
                h.kind == 'placement' ? Icons.explore_outlined : Icons.trending_up,
                color: AppColors.teal),
            title: Text('${h.from.isEmpty ? '—' : h.from} → ${h.to}'),
            subtitle: Text([
              if (h.kind == 'placement') l.placementTestLabel,
              if (h.date != null) DateFormat.yMMMd().format(h.date!),
            ].join(' · ')),
          ),
      ],
    );
  }
}
