import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/exercise_authoring_platform.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/exercise_utils.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_data_table.dart';
import '../../core/widgets/exercise_widgets.dart';
import '../../core/widgets/table_tools.dart';
import '../../l10n/l10n.dart';
import '../../l10n/labels_exercises.dart';
import '../../models/app_user.dart';
import '../../models/exercise.dart';
import '../../models/exercise_assignment.dart';
import '../../models/exercise_category.dart';
import '../../models/exercise_result.dart';
import '../../models/exercise_skill_category.dart';
import '../../models/exercise_type.dart';
import '../../models/question_bank_item.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../core/widgets/exercise_category_chip.dart';
import 'exercise_assign_dialog.dart';

/// Admin / teacher list of exercises as a table: one row per exercise with
/// its type of exercise (read from the worksheets inside it), level, skill,
/// how many students it is assigned to, how many of them finished, the next
/// due date with an overdue count, and the actions (Assign, Edit, Delete).
/// Filters: search text, type of exercise, HSK level, skill. Rows can be
/// ticked for bulk publish / unpublish / delete, and the table exports to
/// CSV. Below the mobile breakpoint the rows become cards.
class TeacherExercisesTab extends StatefulWidget {
  const TeacherExercisesTab({super.key});

  @override
  State<TeacherExercisesTab> createState() => _TeacherExercisesTabState();
}

class _TeacherExercisesTabState extends State<TeacherExercisesTab> {
  String? _levelFilter;
  ExerciseSkillCategory? _skillFilter;
  ExerciseCategory? _categoryFilter;
  String _search = '';
  String? _sortColumnId;
  bool _sortAscending = true;

  /// Exercise ids ticked in the table.
  Set<String> _selected = {};
  bool _busy = false;

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
  // The bank gives each package its type of exercise.
  late final Stream<List<QuestionBankItem>> _bank = () {
    final user = context.read<AuthService>().appUser;
    return context.read<FirestoreService>().watchQuestionBank(
          user == null ? '' : AppConstants.contentTeacherId(user),
        );
  }();

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

  /// Type of exercise of a package: the first worksheet's (or single
  /// question's) type in the bank. Older exercises that keep their questions
  /// inside the document count as plain exercises. Null while the bank is
  /// still loading or when every worksheet was deleted from it.
  static ExerciseCategory? _categoryOf(
    Exercise exercise,
    Map<String, ExerciseCategory> bySheet,
    Map<String, ExerciseCategory> byQuestion,
  ) {
    if (!exercise.isPackage) return ExerciseCategory.exercise;
    for (final code in exercise.bankSheets) {
      final c = bySheet[code];
      if (c != null) return c;
    }
    for (final id in exercise.bankQuestionIds) {
      final c = byQuestion[id];
      if (c != null) return c;
    }
    return null;
  }

  List<_ExerciseRow> _rows({
    required List<Exercise> exercises,
    required List<ExerciseResult> results,
    required List<AppUser> students,
    required List<ExerciseAssignment> assignments,
    required List<QuestionBankItem> bank,
  }) {
    final byId = {for (final s in students) s.uid: s};
    final bySheet = <String, ExerciseCategory>{};
    final byQuestion = <String, ExerciseCategory>{};
    for (final sheet in QuestionBankSheet.group(bank)) {
      if (sheet.isSheet) bySheet[sheet.key!] = sheet.category;
      for (final item in sheet.items) {
        byQuestion[item.id] = item.category;
      }
    }
    final needle = _search.trim().toLowerCase();
    final rows = <_ExerciseRow>[];
    for (final exercise in exercises) {
      if (_levelFilter != null && exercise.level != _levelFilter) continue;
      if (_skillFilter != null && exercise.skillCategory != _skillFilter) {
        continue;
      }
      final category = _categoryOf(exercise, bySheet, byQuestion);
      if (_categoryFilter != null && category != _categoryFilter) continue;
      if (needle.isNotEmpty &&
          !'${exercise.title} ${exercise.instructions}'
              .toLowerCase()
              .contains(needle)) {
        continue;
      }
      final scores = ExerciseUtils.bestScoresByStudentForExercise(
        exercise.id,
        results,
      );
      final assigned = <AppUser>[];
      DateTime? nextDue;
      var overdue = 0;
      for (final a in assignments) {
        if (a.exerciseId != exercise.id) continue;
        final student = byId[a.studentId];
        if (student == null) continue;
        assigned.add(student);
        final due = a.dueDate;
        if (due == null || scores.containsKey(a.studentId)) continue;
        if (a.isOverdue) overdue++;
        if (nextDue == null || due.isBefore(nextDue)) nextDue = due;
      }
      rows.add(_ExerciseRow(
        exercise: exercise,
        category: category,
        assigned: assigned,
        completed: assigned.where((s) => scores.containsKey(s.uid)).length,
        nextDue: nextDue,
        overdue: overdue,
      ));
    }
    final col = _sortColumnId;
    if (col != null) {
      rows.sort((a, b) {
        final cmp = switch (col) {
          'title' => a.exercise.title
              .toLowerCase()
              .compareTo(b.exercise.title.toLowerCase()),
          'category' =>
            (a.category?.index ?? 99).compareTo(b.category?.index ?? 99),
          'level' => (a.exercise.level ?? '').compareTo(b.exercise.level ?? ''),
          'skill' => a.exercise.skillCategory.index
              .compareTo(b.exercise.skillCategory.index),
          'done' => a.assigned.length == b.assigned.length
              ? a.completed.compareTo(b.completed)
              : a.assigned.length.compareTo(b.assigned.length),
          // No due date sorts last whichever way the arrow points.
          'due' => a.nextDue == null && b.nextDue == null
              ? 0
              : a.nextDue == null
                  ? (_sortAscending ? 1 : -1)
                  : b.nextDue == null
                      ? (_sortAscending ? -1 : 1)
                      : a.nextDue!.compareTo(b.nextDue!),
          'status' => (a.exercise.isPublished ? 1 : 0)
              .compareTo(b.exercise.isPublished ? 1 : 0),
          _ => 0,
        };
        return _sortAscending ? cmp : -cmp;
      });
    }
    return rows;
  }

  static final _dueFormat = DateFormat('d MMM yyyy');

  static List<Object?> _csvRow(AppLocalizations l, _ExerciseRow row) => [
        row.exercise.title,
        row.category?.localized(l) ?? '',
        row.exercise.level ?? '',
        row.exercise.skillCategory.localized(l),
        _contentsLabel(l, row.exercise),
        row.assigned.length,
        row.completed,
        row.nextDue == null ? '' : _dueFormat.format(row.nextDue!),
        row.overdue,
        row.exercise.isPublished ? l.teacherExPublished : l.teacherExDraft,
      ];

  static List<String> _csvHeader(AppLocalizations l) => [
        l.teacherExExercise,
        l.bankFiltersTypeOfExercise,
        l.bankFiltersLevel,
        l.bankEditorSkill,
        l.teacherExContents,
        l.teacherExStudents,
        l.teacherExDone,
        l.teacherExNextDue,
        l.exerciseCardStatusOverdue,
        l.teacherExStatus,
      ];

  /// Ticked rows that are still in the table (a deleted or filtered-out
  /// exercise keeps its id in [_selected] until Clear).
  List<_ExerciseRow> _selectedRows(List<_ExerciseRow> rows) => [
        for (final r in rows)
          if (_selected.contains(r.exercise.id)) r
      ];

  Future<void> _runBulk(
    List<_ExerciseRow> rows,
    Future<void> Function(List<String> ids) action,
    String done,
  ) async {
    final ids = [for (final r in rows) r.exercise.id];
    if (ids.isEmpty) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action(ids);
      messenger.showSnackBar(SnackBar(content: Text(done)));
      if (mounted) setState(() => _selected = {});
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _bulkPublish(List<_ExerciseRow> rows, bool published) {
    final l = context.l10n;
    final firestore = context.read<FirestoreService>();
    return _runBulk(
      rows,
      (ids) => firestore.setExercisesPublished(ids, published),
      published
          ? l.teacherExBulkPublished(rows.length)
          : l.teacherExBulkDraft(rows.length),
    );
  }

  Future<void> _bulkDelete(List<_ExerciseRow> rows) async {
    final l = context.l10n;
    final n = rows.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.teacherExDeleteCountTitle(n)),
        content: Text(l.teacherExDeleteBulkBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l.bankDelete),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final firestore = context.read<FirestoreService>();
    await _runBulk(
      rows,
      (ids) async {
        for (final id in ids) {
          await firestore.deleteExercise(id);
        }
      },
      l.teacherExBulkDeleted(n),
    );
  }

  Widget _selectionBar(bool canManage, List<_ExerciseRow> rows) {
    final l = context.l10n;
    final picked = _selectedRows(rows);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: TableSelectionBar(
        count: picked.length,
        noun: l.teacherExSelected,
        onClear: () => setState(() => _selected = {}),
        actions: [
          if (canManage) ...[
            SelectionActionButton(
              label: l.teacherExPublish,
              icon: Icons.visibility_outlined,
              onPressed: _busy ? null : () => _bulkPublish(picked, true),
            ),
            SelectionActionButton(
              label: l.teacherExSetToDraft,
              icon: Icons.visibility_off_outlined,
              onPressed: _busy ? null : () => _bulkPublish(picked, false),
            ),
            SelectionActionButton(
              label: l.bankDelete,
              icon: Icons.delete_outline,
              destructive: true,
              onPressed: _busy ? null : () => _bulkDelete(picked),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildManageBanner(AppUser? user) {
    if (ExerciseAuthoringPlatform.canManageExercises(user)) {
      return const SizedBox.shrink();
    }

    final l = context.l10n;
    final isTeacherOnWeb =
        user?.isTeacher == true && ExerciseAuthoringPlatform.isWeb;
    final message = !ExerciseAuthoringPlatform.isWeb
        ? l.teacherExAuthoringUnsupported
        : isTeacherOnWeb
            ? l.teacherExAuthoringReadOnly
            : l.teacherExAuthoringAdminOnly;
    final title =
        isTeacherOnWeb ? l.teacherExViewOnly : l.teacherExAdminRequired;

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
    final l = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.teacherExDeleteTitle),
        content: Text(l.teacherExDeleteBody(exercise.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l.bankDelete),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await context.read<FirestoreService>().deleteExercise(exercise.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.teacherExDeleted)),
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
  static String _contentsLabel(AppLocalizations l, Exercise exercise) {
    if (exercise.isPackage) {
      final n = exercise.bankSheets.length;
      final q = exercise.bankQuestionIds.length;
      return [
        if (n > 0) l.exerciseCardWorksheets(n),
        if (q > 0) l.teacherExSingleQuestions(q),
      ].join(' · ');
    }
    final n = exercise.questions.length;
    final unit = exercise.type == ExerciseType.composeSentences
        ? l.teacherExSentences(n)
        : l.bankTextQuestionCount(n);
    return '${exercise.type.localized(l)} · $unit';
  }

  Widget _toolbar(bool canManage, List<_ExerciseRow> rows) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 260,
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l.teacherExSearchExercises,
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          SizedBox(
            width: 170,
            child: DropdownButtonFormField<ExerciseCategory?>(
              initialValue: _categoryFilter,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l.bankFiltersTypeOfExercise,
                isDense: true,
              ),
              items: [
                DropdownMenuItem(value: null, child: Text(l.bankFiltersAll)),
                for (final c in ExerciseCategory.values)
                  DropdownMenuItem(value: c, child: Text(c.localized(l))),
              ],
              onChanged: (v) => setState(() => _categoryFilter = v),
            ),
          ),
          SizedBox(
            width: 120,
            child: DropdownButtonFormField<String?>(
              initialValue: _levelFilter,
              isExpanded: true,
              decoration:
                  InputDecoration(labelText: l.bankFiltersLevel, isDense: true),
              items: [
                DropdownMenuItem(value: null, child: Text(l.bankFiltersAll)),
                for (final level in AppConstants.hskLevels)
                  DropdownMenuItem(value: level, child: Text(level)),
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
                  InputDecoration(labelText: l.bankEditorSkill, isDense: true),
              items: [
                DropdownMenuItem(value: null, child: Text(l.bankFiltersAll)),
                for (final c in ExerciseSkillCategory.values)
                  DropdownMenuItem(value: c, child: Text(c.localized(l))),
              ],
              onChanged: (v) => setState(() => _skillFilter = v),
            ),
          ),
          ExportCsvButton(
            fileStem: 'exercises',
            label: l.teacherExExportCsv,
            header: _csvHeader(l),
            rows: () => rows.map((r) => _csvRow(l, r)).toList(),
          ),
          if (canManage) ...[
            OutlinedButton.icon(
              onPressed: () => context.push('$_base/question-bank'),
              icon: const Icon(Icons.inventory_2_outlined, size: 18),
              label: Text(l.bankTitle),
            ),
            FilledButton.icon(
              onPressed: () => context.push('$_base/exercise/new'),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l.teacherExNewExercise),
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
    final l = context.l10n;
    return [
      AppTableColumn(
        id: 'title',
        label: l.teacherExExercise,
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
                row.exercise.isPackage
                    ? l.teacherExFromBank
                    : l.teacherExOldFormat,
                _contentsLabel(l, row.exercise),
              ].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      AppTableColumn(
        id: 'category',
        label: l.bankImportType,
        width: 112,
        sortable: true,
        cell: (row) => row.category == null
            ? const Text('—')
            : ExerciseCategoryChip(category: row.category!),
      ),
      AppTableColumn(
        id: 'level',
        label: l.bankFiltersLevel,
        width: 58,
        sortable: true,
        cell: (row) => Text(row.exercise.level ?? '—'),
      ),
      AppTableColumn(
        id: 'skill',
        label: l.bankEditorSkill,
        width: 100,
        sortable: true,
        cell: (row) => Text(
          row.exercise.skillCategory.localized(l),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      // "3/6" = students finished / students assigned; click for names.
      AppTableColumn(
        id: 'done',
        label: l.teacherExDone,
        width: 76,
        sortable: true,
        alignment: Alignment.centerRight,
        cell: (row) => !row.exercise.isPublished
            ? const Text('—')
            : row.assigned.isEmpty
                ? Text(l.teacherExNone)
                : Tooltip(
                    message: l.teacherExStudentsFinished(
                      row.completed,
                      row.assigned.length,
                    ),
                    child: TextButton(
                      onPressed: () =>
                          _showProgress(row, assignments, results, students),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 32),
                      ),
                      child: Text('${row.completed}/${row.assigned.length}'),
                    ),
                  ),
      ),
      AppTableColumn(
        id: 'due',
        label: l.teacherExDue,
        width: 92,
        sortable: true,
        cell: (row) => _DueCell(row: row),
      ),
      AppTableColumn(
        id: 'status',
        label: l.teacherExStatus,
        width: 88,
        sortable: true,
        cell: (row) => _StatusChip(published: row.exercise.isPublished),
      ),
      AppTableColumn(
        id: 'actions',
        label: l.bankActions,
        width: canManage ? 190 : 100,
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
    final l = context.l10n;
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
                  title: l.teacherExNoExercisesTitle,
                  subtitle: canManage
                      ? l.teacherExNoExercisesSubtitle
                      : l.teacherExNoExercisesSubtitleReadOnly,
                  action: canManage
                      ? FilledButton.icon(
                          onPressed: () => context.push('$_base/exercise/new'),
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(l.teacherExNewExercise),
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
                    return StreamBuilder<List<QuestionBankItem>>(
                      stream: _bank,
                      builder: (context, bankSnap) {
                        final results = resultsSnap.data ?? [];
                        final students = studentsSnap.data ?? [];
                        final assignments =
                            assignSnap.data ?? const <ExerciseAssignment>[];
                        final rows = _rows(
                          exercises: exercises,
                          results: results,
                          students: students,
                          assignments: assignments,
                          bank: bankSnap.data ?? const <QuestionBankItem>[],
                        );

                        return Column(
                          children: [
                            _buildManageBanner(user),
                            _toolbar(canManage, rows),
                            _selectionBar(canManage, rows),
                            Expanded(
                              child: rows.isEmpty
                                  ? EmptyState(
                                      icon: Icons.filter_alt_off_outlined,
                                      title: l.bankNoMatchesTitle,
                                      subtitle: l.bankAdjustFilters,
                                    )
                                  : Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          20, 8, 20, 80),
                                      child: SingleChildScrollView(
                                        child: AppDataTable<_ExerciseRow>(
                                          rows: rows,
                                          sortColumnId: _sortColumnId,
                                          sortAscending: _sortAscending,
                                          onSort: _onSort,
                                          rowKey: (row) => row.exercise.id,
                                          selectedKeys: _selected,
                                          onSelectionChanged: (keys) =>
                                              setState(() => _selected = keys),
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
                                            contents:
                                                _contentsLabel(l, row.exercise),
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
      },
    );
  }
}

/// One exercise with what the table needs next to it.
class _ExerciseRow {
  const _ExerciseRow({
    required this.exercise,
    required this.category,
    required this.assigned,
    required this.completed,
    required this.nextDue,
    required this.overdue,
  });

  final Exercise exercise;

  /// Type of exercise from the bank; null when unknown.
  final ExerciseCategory? category;

  /// Students the exercise is assigned to (active accounts only).
  final List<AppUser> assigned;

  /// How many of [assigned] have a result.
  final int completed;

  /// Earliest due date among students who have not finished yet.
  final DateTime? nextDue;

  /// Students past their due date without a result.
  final int overdue;
}

/// Next due date, red with the count when students are late.
class _DueCell extends StatelessWidget {
  const _DueCell({required this.row});
  final _ExerciseRow row;

  @override
  Widget build(BuildContext context) {
    final due = row.nextDue;
    if (due == null) return const Text('—');
    final late = row.overdue > 0;
    final color = late ? AppColors.error : AppColors.textPrimary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat('d MMM').format(due),
          style: TextStyle(
            color: color,
            fontWeight: late ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        if (late)
          Text(
            context.l10n.exerciseCardOverdueCount(row.overdue),
            style: TextStyle(
              fontSize: 11,
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
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
          published
              ? context.l10n.teacherExPublished
              : context.l10n.teacherExDraft,
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

/// Assign (published only) as a labelled button; Edit and Delete (admins on
/// web) as icon buttons so the row fits a laptop screen without scrolling.
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
    final l = context.l10n;
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
            label: Text(l.teacherExAssign),
          ),
        if (canManage) ...[
          const SizedBox(width: 8),
          _IconAction(
            icon: Icons.edit_outlined,
            tooltip: l.bankEdit,
            color: AppColors.navy,
            onPressed: onEdit,
          ),
          const SizedBox(width: 8),
          _IconAction(
            icon: Icons.delete_outline,
            tooltip: l.bankDelete,
            color: AppColors.error,
            onPressed: onDelete,
          ),
        ],
      ],
    );
  }
}

/// 36×36 outlined icon button with a tooltip.
class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withValues(alpha: 0.5)),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
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
    final l = context.l10n;
    final e = row.exercise;
    final access = !e.isPublished
        ? l.teacherExDraftHidden
        : row.assigned.isEmpty
            ? l.teacherExNotAssigned
            : l.teacherExStudentsDone(row.completed, row.assigned.length);
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
            [
              if (row.category != null) row.category!.localized(l),
              e.level ?? '—',
              e.skillCategory.localized(l),
              contents,
            ].join(' · '),
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          Text(
            [
              access,
              if (row.nextDue != null)
                l.teacherExDueLower(DateFormat('d MMM').format(row.nextDue!)),
              if (row.overdue > 0) l.exerciseCardOverdueCount(row.overdue),
            ].join(' · '),
            style: TextStyle(
              fontSize: 12,
              color:
                  row.overdue > 0 ? AppColors.error : AppColors.textSecondary,
            ),
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
                  label: Text(l.teacherExAssign),
                ),
              if (canManage) ...[
                OutlinedButton.icon(
                  onPressed: onEdit,
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(l.bankEdit),
                ),
                OutlinedButton.icon(
                  onPressed: onDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(l.bankDelete),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
