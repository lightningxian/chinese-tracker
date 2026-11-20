import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../l10n/l10n.dart';
import '../../models/app_user.dart';
import '../../models/progress_summary.dart';
import '../../services/progress_service.dart';
import 'student_progress_report_screen.dart';

/// Build 4 (Must 7): students whose progress summary carries warnings. The
/// teacher sees their own students; the admin sees everyone with filters by
/// level and teacher. A tap opens the student's report.
class ProgressAttentionList extends StatefulWidget {
  const ProgressAttentionList({
    super.key,
    this.teacherId,
    this.teachers = const [],
    this.maxRows,
  });

  /// The teacher's uid (their students only); null = every student (admin).
  final String? teacherId;

  /// Admin: teachers for the filter.
  final List<AppUser> teachers;

  /// Rows shown before "show all" (null = all).
  final int? maxRows;

  @override
  State<ProgressAttentionList> createState() => _ProgressAttentionListState();
}

class _ProgressAttentionListState extends State<ProgressAttentionList> {
  late final Stream<List<ProgressSummary>> _summaries =
      ProgressService().watchSummaries(teacherId: widget.teacherId);
  String? _level;
  String? _teacher;
  bool _all = false;

  bool get _admin => widget.teacherId == null;

  String _route(String uid) =>
      _admin ? '/admin/users/$uid/progress' : '/teacher/student/$uid/progress';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return StreamBuilder<List<ProgressSummary>>(
      stream: _summaries,
      builder: (context, snap) {
        var rows = (snap.data ?? const <ProgressSummary>[])
            .where((s) => s.warnings.isNotEmpty)
            .toList();
        if (_level != null) rows = rows.where((s) => s.level == _level).toList();
        if (_teacher != null) {
          rows = rows.where((s) => s.teacherId == _teacher).toList();
        }
        rows.sort((a, b) {
          final byCount = b.warnings.length.compareTo(a.warnings.length);
          if (byCount != 0) return byCount;
          return a.studentName.toLowerCase().compareTo(b.studentName.toLowerCase());
        });
        final shown = !_all && widget.maxRows != null && rows.length > widget.maxRows!
            ? rows.take(widget.maxRows!).toList()
            : rows;
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.chipAmberFg),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.progressAttentionTitle(rows.length),
                      style: TextStyle(
                          fontWeight: FontWeight.w800, color: AppColors.navy),
                    ),
                  ),
                ],
              ),
              if (_admin) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Filter<String>(
                      label: l.commonHskLevel,
                      value: _level,
                      items: {
                        for (final lv in AppConstants.hskLevels) lv: lv,
                      },
                      allLabel: l.progressFilterAll,
                      onChanged: (v) => setState(() => _level = v),
                    ),
                    _Filter<String>(
                      label: l.approvalTeacher,
                      value: _teacher,
                      items: {for (final t in widget.teachers) t.uid: t.staffLabel},
                      allLabel: l.progressFilterAll,
                      onChanged: (v) => setState(() => _teacher = v),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              if (snap.connectionState == ConnectionState.waiting && !snap.hasData)
                const LinearProgressIndicator()
              else if (rows.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(l.progressAttentionEmpty,
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
              for (final s in shown)
                InkWell(
                  onTap: () => context.push(_route(s.studentId)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              AppUser.staffLabelOf(s.studentNameChinese, s.studentName),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            if (s.level.isNotEmpty)
                              Text(s.level,
                                  style: TextStyle(
                                      color: AppColors.textSecondary, fontSize: 12)),
                            ProgressStatusChip(status: s.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            for (final w in s.warnings)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.chipAmberBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(progressWarningTitle(l, w.id),
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.chipAmberFg)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              if (shown.length < rows.length)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => setState(() => _all = true),
                    child: Text(l.progressShowAll(rows.length)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Filter<T> extends StatelessWidget {
  const _Filter({
    required this.label,
    required this.value,
    required this.items,
    required this.allLabel,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final Map<T, String> items;
  final String allLabel;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<T?>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label, isDense: true),
        items: [
          DropdownMenuItem<T?>(value: null, child: Text(allLabel)),
          for (final e in items.entries)
            DropdownMenuItem<T?>(
                value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis)),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
