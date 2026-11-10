import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/exercise_authoring_platform.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/exercise_utils.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_data_table.dart';
import '../../core/widgets/exercise_widgets.dart';
import '../../models/app_user.dart';
import '../../models/exercise.dart';
import '../../models/exercise_assignment.dart';
import '../../models/exercise_result.dart';
import '../../models/exercise_skill_category.dart';
import '../../models/exercise_type.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import 'exercise_assign_dialog.dart';

/// Admin / teacher list of exercises as a table: one row per exercise with
/// its level, skill, how many students it is assigned to, how many of them
/// finished, and the actions (Assign, Edit, Delete). Filters: search text,
/// HSK level, skill. Below the mobile breakpoint the rows become cards.
class TeacherExercisesTab extends StatefulWidget {
  const TeacherExercisesTab({super.key});

  @override
  State<TeacherExercisesTab> createState() => _TeacherExercisesTabState();
}

class _TeacherExercisesTabState extends State<TeacherExercisesTab> {
  String? _levelFilter;
  ExerciseSkillCategory? _skillFilter;
  String _search = '';
  String? _sortColumnId;
  bool _sortAscending = true;

  // Created once: a new stream per build would reset every StreamBuilder
  // to "waiting" and make the counts flicker after each change.
  late final Stream<List<Exercise>> _exercises =
      context.read<FirestoreService>().watchAllExercises();
  late final Stream<List<ExerciseResult>> _results =
      context.read<FirestoreService>().watchAllExerciseResults();
  late final Stream<List<AppUser>> _students =
      context.read<FirestoreService>().watchAllStudents();
  late final Stream<List<ExerciseAssignment>> _assignments =
      context.read<FirestoreService>().watchAllExerciseAssignments();

  String get _base => GoRouterState.of(context).uri.path.startsWith('/admin')
      ? '/admin'
      : '/teacher';

  void _onSort(String columnId) {
    setState(() {
      if (_sortColumnId == columnId) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumnId = columnId;
        _sortAscending = true;
      }
    });
  }

  List<_ExerciseRow> _rows({
    required List<Exercise> exercises,
    required List<ExerciseResult> results,
    required List<AppUser> students,
    required List<ExerciseAssignment> assignments,
  }) {
    final byId = {for (final s in students) s.uid: s};
    final needle = _search.trim().toLowerCase();
    final rows = <_ExerciseRow>[];
    for (final exercise in exercises) {
      if (_levelFilter != null && exercise.level != _levelFilter) continue;
      if (_skillFilter != null && exercise.skillCategory != _skillFilter) {
        continue;
      }
      if (needle.isNotEmpty &&
          !'${exercise.title} ${exercise.instructions}'
              .toLowerCase()
              .contains(needle)) {
        continue;
      }
      final assigned = [
        for (final a in assignments)
          if (a.exerciseId == exercise.id && byId.containsKey(a.studentId))
            byId[a.studentId]!,
      ];
      final scores = ExerciseUtils.bestScoresByStudentForExercise(
        exercise.id,
        results,
      );
      rows.add(_ExerciseRow(
        exercise: exercise,
        assigned: assigned,
        completed: assigned.where((s) => scores.containsKey(s.uid)).length,
      ));
    }
    final col = _sortColumnId;
    if (col != null) {
      rows.sort((a, b) {
        final cmp = switch (col) {
          'title' => a.exercise.title
              .toLowerCase()
              .compareTo(b.exercise.title.toLowerCase()),
          'level' => (a.exercise.level ?? '').compareTo(b.exercise.level ?? ''),
          'skill' => a.exercise.skillCategory.index
              .compareTo(b.exercise.skillCategory.index),
          'students' => a.assigned.length.compareTo(b.assigned.length),
          'done' => a.completed.compareTo(b.completed),
          'status' => (a.exercise.isPublished ? 1 : 0)
              .compareTo(b.exercise.isPublished ? 1 : 0),
          _ => 0,
        };
        return _sortAscending ? cmp : -cmp;
      });
    }
    return rows;
  }

  Widget _buildManageBanner(AppUser? user) {
    if (ExerciseAuthoringPlatform.canManageExercises(user)) {
      return const SizedBox.shrink();
    }

    final isTeacherOnWeb =
        user?.isTeacher == true && ExerciseAuthoringPlatform.isWeb;
    final message = !ExerciseAuthoringPlatform.isWeb
        ? ExerciseAuthoringPlatform.unsupportedMessage
        : isTeacherOnWeb
            ? ExerciseAuthoringPlatform.teacherReadOnlyMessage
            : ExerciseAuthoringPlatform.adminOnlyMessage;
    final title = isTeacherOnWeb ? 'View only' : 'Admin access required';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isTeacherOnWeb
                  ? Icons.visibility_outlined
                  : ExerciseAuthoringPlatform.isWeb
                      ? Icons.admin_panel_settings_outlined
                      : Icons.laptop_mac_outlined,
              color: AppColors.navy,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Exercise exercise) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete exercise?'),
        content: Text(
          'Delete "${exercise.title}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await context.read<FirestoreService>().deleteExercise(exercise.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exercise deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _edit(Exercise exercise) {
    context.push('$_base/exercise/${exercise.id}/edit', extra: exercise);
  }

  void _showProgress(
    _ExerciseRow row,
    List<ExerciseAssignment> assignments,
    List<ExerciseResult> results,
    List<AppUser> students,
  ) {
    showExerciseHomeworkProgressDialog(
      context: context,
      exercise: row.exercise,
      assignments:
          assignments.where((a) => a.exerciseId == row.exercise.id).toList(),
      results: results,
      students: students,
    );
  }

  /// "3 worksheets · 1 question" for a package, "Multiple choice · 7
  /// questions" otherwise.
  static String _contentsLabel(Exercise exercise) {
    if (exercise.isPackage) {
      final n = exercise.bankSheets.length;
      final q = exercise.bankQuestionIds.length;
      return [
        if (n > 0) '$n worksheet${n == 1 ? '' : 's'}',
        if (q > 0) '$q single question${q == 1 ? '' : 's'}',
      ].join(' · ');
    }
    final n = exercise.questions.length;
    final unit = exercise.type == ExerciseType.composeSentences
        ? 'sentence'
        : 'question';
    return '${exercise.type.label} · $n $unit${n == 1 ? '' : 's'}';
  }

  Widget _toolbar(bool canManage) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 280,
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search exercises',
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          SizedBox(
            width: 120,
            child: DropdownButtonFormField<String?>(
              initialValue: _levelFilter,
              isExpanded: true,
              decoration:
                  const InputDecoration(labelText: 'Level', isDense: true),
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                for (final l in AppConstants.hskLevels)
                  DropdownMenuItem(value: l, child: Text(l)),
              ],
              onChanged: (v) => setState(() => _levelFilter = v),
            ),
          ),
          SizedBox(
            width: 170,
            child: DropdownButtonFormField<ExerciseSkillCategory?>(
              initialValue: _skillFilter,
              isExpanded: true,
              decoration:
                  const InputDecoration(labelText: 'Skill', isDense: true),
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                for (final c in ExerciseSkillCategory.values)
                  DropdownMenuItem(value: c, child: Text(c.label)),
              ],
              onChanged: (v) => setState(() => _skillFilter = v),
            ),
          ),
          if (canManage) ...[
            OutlinedButton.icon(
              onPressed: () => context.push('$_base/question-bank'),
              icon: const Icon(Icons.inventory_2_outlined, size: 18),
              label: const Text('Question bank'),
            ),
            FilledButton.icon(
              onPressed: () => context.push('$_base/exercise/new'),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New exercise'),
            ),
          ],
        ],
      ),
    );
  }

  List<AppTableColumn<_ExerciseRow>> _columns({
    required bool canManage,
    required List<ExerciseAssignment> assignments,
    required List<ExerciseResult> results,
    required List<AppUser> students,
  }) {
    return [
      AppTableColumn(
        id: 'title',
        label: 'Exercise',
        flex: 3,
        sortable: true,
        cell: (row) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              row.exercise.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.question.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              [
                if (row.exercise.isPackage) 'From the question bank',
                _contentsLabel(row.exercise),
              ].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      AppTableColumn(
        id: 'level',
        label: 'Level',
        width: 74,
        sortable: true,
        cell: (row) => Text(row.exercise.level ?? '—'),
      ),
      AppTableColumn(
        id: 'skill',
        label: 'Skill',
        width: 130,
        sortable: true,
        cell: (row) => Text(row.exercise.skillCategory.label),
      ),
      AppTableColumn(
        id: 'students',
        label: 'Students',
        width: 90,
        sortable: true,
        alignment: Alignment.centerRight,
        cell: (row) => Text(
          !row.exercise.isPublished
              ? '—'
              : row.assigned.isEmpty
                  ? 'None'
                  : '${row.assigned.length}',
        ),
      ),
      AppTableColumn(
        id: 'done',
        label: 'Done',
        width: 86,
        sortable: true,
        alignment: Alignment.centerRight,
        cell: (row) => row.assigned.isEmpty
            ? const Text('—')
            : TextButton(
                onPressed: () =>
                    _showProgress(row, assignments, results, students),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                ),
                child: Text('${row.completed}/${row.assigned.length}'),
              ),
      ),
      AppTableColumn(
        id: 'status',
        label: 'Status',
        width: 100,
        sortable: true,
        cell: (row) => _StatusChip(published: row.exercise.isPublished),
      ),
      AppTableColumn(
        id: 'actions',
        label: 'Actions',
        width: canManage ? 318 : 110,
        cell: (row) => _RowActions(
          row: row,
          canManage: canManage,
          onAssign: () =>
              showExerciseAssignDialog(context, exercise: row.exercise),
          onEdit: () => _edit(row.exercise),
          onDelete: () => _confirmDelete(row.exercise),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().appUser;
    final canManage = ExerciseAuthoringPlatform.canManageExercises(user);

    return StreamBuilder<List<Exercise>>(
      stream: _exercises,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              snapshot.error.toString(),
              style: TextStyle(color: AppColors.error),
            ),
          );
        }

        final exercises = snapshot.data ?? [];
        if (exercises.isEmpty) {
          return Column(
            children: [
              _buildManageBanner(user),
              Expanded(
                child: EmptyState(
                  icon: Icons.fitness_center_outlined,
                  title: 'No exercises yet',
                  subtitle: canManage
                      ? 'An exercise bundles worksheets from the question bank; '
                          'students see it once it is assigned to them.'
                      : 'An exercise bundles worksheets from the question bank; '
                          'students see it once it is assigned to them. '
                          'Admins create exercises on web.',
                  action: canManage
                      ? FilledButton.icon(
                          onPressed: () => context.push('$_base/exercise/new'),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('New exercise'),
                        )
                      : null,
                ),
              ),
            ],
          );
        }

        return StreamBuilder<List<ExerciseResult>>(
          stream: _results,
          builder: (context, resultsSnap) {
            return StreamBuilder<List<AppUser>>(
              stream: _students,
              builder: (context, studentsSnap) {
                return StreamBuilder<List<ExerciseAssignment>>(
                  stream: _assignments,
                  builder: (context, assignSnap) {
                    final results = resultsSnap.data ?? [];
                    final students = studentsSnap.data ?? [];
                    final assignments =
                        assignSnap.data ?? const <ExerciseAssignment>[];
                    final rows = _rows(
                      exercises: exercises,
                      results: results,
                      students: students,
                      assignments: assignments,
                    );

                    return Column(
                      children: [
                        _buildManageBanner(user),
                        _toolbar(canManage),
                        Expanded(
                          child: rows.isEmpty
                              ? const EmptyState(
                                  icon: Icons.filter_alt_off_outlined,
                                  title: 'No matches',
                                  subtitle: 'Adjust the filters.',
                                )
                              : Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 8, 20, 80),
                                  child: SingleChildScrollView(
                                    child: AppDataTable<_ExerciseRow>(
                                      rows: rows,
                                      sortColumnId: _sortColumnId,
                                      sortAscending: _sortAscending,
                                      onSort: _onSort,
                                      onRowTap: canManage
                                          ? (row) => _edit(row.exercise)
                                          : null,
                                      columns: _columns(
                                        canManage: canManage,
                                        assignments: assignments,
                                        results: results,
                                        students: students,
                                      ),
                                      mobileCardBuilder: (row) =>
                                          _ExerciseMobileCard(
                                        row: row,
                                        contents: _contentsLabel(row.exercise),
                                        canManage: canManage,
                                        onProgress: row.assigned.isEmpty
                                            ? null
                                            : () => _showProgress(
                                                  row,
                                                  assignments,
                                                  results,
                                                  students,
                                                ),
                                        onAssign: () =>
                                            showExerciseAssignDialog(
                                          context,
                                          exercise: row.exercise,
                                        ),
                                        onEdit: () => _edit(row.exercise),
                                        onDelete: () =>
                                            _confirmDelete(row.exercise),
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

/// One exercise with what the table needs next to it.
class _ExerciseRow {
  const _ExerciseRow({
    required this.exercise,
    required this.assigned,
    required this.completed,
  });

  final Exercise exercise;

  /// Students the exercise is assigned to (active accounts only).
  final List<AppUser> assigned;

  /// How many of [assigned] have a result.
  final int completed;
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.published});
  final bool published;

  @override
  Widget build(BuildContext context) {
    final color = published ? AppColors.success : AppColors.textSecondary;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          published ? 'Published' : 'Draft',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

/// Assign (published only), Edit and Delete (admins on web).
class _RowActions extends StatelessWidget {
  const _RowActions({
    required this.row,
    required this.canManage,
    required this.onAssign,
    required this.onEdit,
    required this.onDelete,
  });

  final _ExerciseRow row;
  final bool canManage;
  final VoidCallback onAssign;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final outlined = OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      minimumSize: const Size(0, 36),
      visualDensity: VisualDensity.compact,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (row.exercise.isPublished)
          FilledButton.icon(
            onPressed: onAssign,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.navy,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 36),
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(Icons.assignment_ind_outlined, size: 18),
            label: const Text('Assign'),
          ),
        if (canManage) ...[
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onEdit,
            style: outlined,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onDelete,
            style: outlined.copyWith(
              foregroundColor: WidgetStatePropertyAll(AppColors.error),
              side: WidgetStatePropertyAll(BorderSide(color: AppColors.error)),
            ),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Delete'),
          ),
        ],
      ],
    );
  }
}

/// Narrow screens: the same row as a card.
class _ExerciseMobileCard extends StatelessWidget {
  const _ExerciseMobileCard({
    required this.row,
    required this.contents,
    required this.canManage,
    required this.onProgress,
    required this.onAssign,
    required this.onEdit,
    required this.onDelete,
  });

  final _ExerciseRow row;
  final String contents;
  final bool canManage;
  final VoidCallback? onProgress;
  final VoidCallback onAssign;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final e = row.exercise;
    final access = !e.isPublished
        ? 'Draft — not visible to students'
        : row.assigned.isEmpty
            ? 'Not assigned yet'
            : '${row.completed}/${row.assigned.length} students done';
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: onProgress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  e.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.question.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(published: e.isPublished),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${e.level ?? '—'} · ${e.skillCategory.label} · $contents\n$access',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (e.isPublished)
                FilledButton.icon(
                  onPressed: onAssign,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.assignment_ind_outlined, size: 18),
                  label: const Text('Assign'),
                ),
              if (canManage) ...[
                OutlinedButton.icon(
                  onPressed: onEdit,
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
                OutlinedButton.icon(
                  onPressed: onDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
