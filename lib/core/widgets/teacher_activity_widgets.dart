import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import '../utils/exercise_utils.dart';
import '../../models/teacher_activity_event.dart';
import 'app_card.dart';
import 'status_pill.dart';

class WeeklyActivityChart extends StatelessWidget {
  const WeeklyActivityChart({
    super.key,
    required this.days,
    this.onTap,
  });

  final List<WeeklyActivityDay> days;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();

    final maxCount = days.fold<int>(
      1,
      (max, day) => day.count > max ? day.count : max,
    );

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity this week',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Lesson completions and practice submissions',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 96,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.map((day) {
                final heightFactor = day.count / maxCount;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (day.count > 0)
                          Text(
                            '${day.count}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.teal,
                            ),
                          )
                        else
                          const SizedBox(height: 14),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor:
                                  day.count == 0 ? 0.08 : heightFactor,
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: day.count == 0
                                      ? AppColors.border
                                      : AppColors.teal.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat('E').format(day.day),
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeworkOverviewCard extends StatelessWidget {
  const HomeworkOverviewCard({
    super.key,
    required this.overview,
    this.onTap,
  });

  final HomeworkOverview overview;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Homework overview',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                ),
              ),
              if (overview.totalAssigned > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => showClassHomeworkOverviewDialog(
                        context: context,
                        overview: overview,
                      ),
                      child: const Text('Quick view'),
                    ),
                    if (onTap != null)
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.textSecondary,
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (overview.totalAssigned == 0)
            Text(
              'No homework assigned yet. Assign practice from the Exercises tab.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            )
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusPill(
                  label: '${overview.pending} to do',
                  color: AppColors.teal,
                ),
                if (overview.overdue > 0)
                  StatusPill(
                    label: '${overview.overdue} overdue',
                    color: AppColors.error,
                  ),
                StatusPill(
                  label: '${overview.completed} done',
                  color: AppColors.success,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${overview.completed}/${overview.totalAssigned} assignments completed',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            if (overview.overdue > 0) ...[
              const SizedBox(height: 12),
              ...overview.rows.where((r) => r.isOverdue).take(3).map(
                    (row) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: InkWell(
                        onTap: () =>
                            context.push('/teacher/student/${row.studentId}'),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.error,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${row.studentName} · ${row.exerciseTitle}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
            ],
          ],
        ],
      ),
    );
  }
}

Future<void> showClassHomeworkOverviewDialog({
  required BuildContext context,
  required HomeworkOverview overview,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
      title: const Text('Homework overview'),
      content: SizedBox(
        width: double.maxFinite,
        child: overview.rows.isEmpty
            ? const Text('No homework assigned yet.')
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${overview.completed}/${overview.totalAssigned} completed',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.teal,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 360),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: overview.rows.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final row = overview.rows[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          onTap: () {
                            Navigator.pop(ctx);
                            context.push('/teacher/student/${row.studentId}');
                          },
                          title: Text(
                            row.studentName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            [
                              row.exerciseTitle,
                              if (row.dueDate != null)
                                ExerciseUtils.dueDateLabel(
                                  row.dueDate,
                                  isOverdue: row.isOverdue,
                                ),
                            ].join(' · '),
                            style: TextStyle(
                              fontSize: 12,
                              color: row.isOverdue
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                            ),
                          ),
                          trailing: row.bestScore != null
                              ? Text(
                                  '${row.bestScore}%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.success,
                                  ),
                                )
                              : StatusPill(
                                  label: row.isOverdue ? 'Overdue' : 'Pending',
                                  color: row.isOverdue
                                      ? AppColors.error
                                      : AppColors.textSecondary,
                                ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

class TeacherActivityFeed extends StatefulWidget {
  const TeacherActivityFeed({
    super.key,
    required this.events,
  });

  final List<TeacherActivityEvent> events;

  @override
  State<TeacherActivityFeed> createState() => _TeacherActivityFeedState();
}

class _TeacherActivityFeedState extends State<TeacherActivityFeed> {
  TeacherActivityFilter _filter = TeacherActivityFilter.all;

  List<TeacherActivityEvent> get _filtered {
    return widget.events.where((event) {
      return switch (_filter) {
        TeacherActivityFilter.all => true,
        TeacherActivityFilter.practice =>
          event.type == TeacherActivityType.exerciseSubmitted ||
              event.type == TeacherActivityType.homeworkAssigned,
        TeacherActivityFilter.lessons =>
          event.type == TeacherActivityType.lessonCompleted,
        TeacherActivityFilter.classes =>
          event.type == TeacherActivityType.sessionJoined ||
              event.type == TeacherActivityType.sessionAdded ||
              event.type == TeacherActivityType.classConcluded ||
              event.type == TeacherActivityType.termCreated,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Recent activity'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: TeacherActivityFilter.values.map((filter) {
              final selected = _filter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(_filterLabel(filter)),
                  selected: selected,
                  onSelected: (_) => setState(() => _filter = filter),
                  selectedColor: AppColors.teal.withValues(alpha: 0.15),
                  checkmarkColor: AppColors.teal,
                  labelStyle: TextStyle(
                    color: selected ? AppColors.teal : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        if (filtered.isEmpty)
          AppCard(
            child: Text(
              'No recent activity for this filter.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          ...filtered.map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                onTap: event.studentRoute != null
                    ? () => context.push(event.studentRoute!)
                    : null,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            _colorForType(event.type).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _iconForType(event.type),
                        color: _colorForType(event.type),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if (event.subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              event.subtitle!,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            _formatWhen(event.occurredAt),
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (event.studentRoute != null)
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.textSecondary,
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  static String _filterLabel(TeacherActivityFilter filter) {
    return switch (filter) {
      TeacherActivityFilter.all => 'All',
      TeacherActivityFilter.practice => 'Practice',
      TeacherActivityFilter.lessons => 'Lessons',
      TeacherActivityFilter.classes => 'Classes',
    };
  }

  static IconData _iconForType(TeacherActivityType type) {
    return switch (type) {
      TeacherActivityType.exerciseSubmitted => Icons.fitness_center_outlined,
      TeacherActivityType.lessonCompleted => Icons.menu_book_outlined,
      TeacherActivityType.homeworkAssigned => Icons.assignment_outlined,
      TeacherActivityType.sessionJoined => Icons.event_available_outlined,
      TeacherActivityType.sessionAdded => Icons.person_add_alt_1_outlined,
      TeacherActivityType.classConcluded => Icons.event_busy_outlined,
      TeacherActivityType.termCreated => Icons.card_membership_outlined,
    };
  }

  static Color _colorForType(TeacherActivityType type) {
    return switch (type) {
      TeacherActivityType.exerciseSubmitted => AppColors.teal,
      TeacherActivityType.lessonCompleted => AppColors.navy,
      TeacherActivityType.homeworkAssigned => AppColors.teal,
      TeacherActivityType.sessionJoined => AppColors.success,
      TeacherActivityType.sessionAdded => AppColors.navy,
      TeacherActivityType.classConcluded => AppColors.textSecondary,
      TeacherActivityType.termCreated => AppColors.navy,
    };
  }

  static String _formatWhen(DateTime at) {
    final now = DateTime.now();
    final diff = now.difference(at);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM yyyy').format(at);
  }
}
