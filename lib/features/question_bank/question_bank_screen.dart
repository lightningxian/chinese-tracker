import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/exercise_authoring_platform.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_data_table.dart';
import '../../core/widgets/shell_nested_page.dart';
import '../../core/widgets/table_tools.dart';
import '../../l10n/l10n.dart';
import '../../l10n/labels_exercises.dart';
import '../../models/app_user.dart';
import '../../models/exercise_category.dart';
import '../../models/exercise_type.dart';
import '../../models/question_bank_item.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../core/widgets/exercise_category_chip.dart';
import 'question_bank_ai_import.dart';
import 'question_bank_bulk_import.dart';
import 'question_bank_editor.dart';
import 'question_bank_filters.dart';
import 'question_bank_harvest.dart';
import 'question_bank_sheet_screen.dart';
import 'question_bank_text.dart';

/// Admin/teacher screen for the shared question bank (`question_bank`
/// collection). A scanned worksheet is one row (open it to see and edit its
/// questions); a question typed or pasted on its own is a row by itself.
/// Rows can be ticked for bulk actions (new exercise from the ticked
/// worksheets, set type of exercise or level, delete) and the list exports
/// to CSV from the header.
class QuestionBankScreen extends StatefulWidget {
  const QuestionBankScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends State<QuestionBankScreen> {
  QuestionBankFilter _filter = const QuestionBankFilter();
  String? _sortColumnId;
  bool _sortAscending = true;

  /// Row keys ([_rowKey]) ticked in the table.
  Set<String> _selected = {};
  bool _busy = false;

  /// Rows the table shows now, for the CSV export in the header.
  List<QuestionBankSheet> _visible = const [];

  static String _rowKey(QuestionBankSheet sheet) =>
      sheet.isSheet ? 'sheet:${sheet.key}' : 'question:${sheet.first.id}';

  static List<String> _csvHeader(AppLocalizations l) => [
        l.bankCsvWorksheetOrQuestion,
        l.bankCsvCode,
        l.bankFiltersTypeOfExercise,
        l.bankFiltersQuestionType,
        l.bankFiltersLevel,
        l.bankQuestions,
        l.bankUsed,
      ];

  static List<Object?> _csvRow(AppLocalizations l, QuestionBankSheet sheet) => [
        sheet.title,
        sheet.isSheet ? sheet.code : '',
        sheet.category.localized(l),
        sheet.type.localized(l),
        sheet.level ?? '',
        sheet.count,
        sheet.usageCount,
      ];

  List<QuestionBankSheet> _selectedRows(List<QuestionBankSheet> rows) => [
        for (final r in rows)
          if (_selected.contains(_rowKey(r))) r
      ];

  Future<void> _runBulk(
    Future<void> Function() action,
    String done,
  ) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
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

  /// Opens the exercise form with the ticked worksheets already inside.
  void _newExerciseFrom(List<QuestionBankSheet> picked, AppUser user) {
    final codes = [
      for (final s in picked)
        if (s.isSheet) s.key!,
    ];
    final base = user.isAdmin ? '/admin' : '/teacher';
    context.push('$base/exercise/new', extra: codes);
  }

  Future<void> _bulkSetCategory(
    FirestoreService firestore,
    List<QuestionBankSheet> picked,
  ) async {
    final l = context.l10n;
    final category = await _pickOption<ExerciseCategory>(
      title: l.bankTypeOfExerciseFor(_countLabel(l, picked)),
      options: [for (final c in ExerciseCategory.values) (c, c.localized(l))],
      initial: picked.first.category,
    );
    if (category == null || !mounted) return;
    await _runBulk(
      () => firestore.updateQuestionBankSheet(
        [for (final s in picked) ...s.items.map((i) => i.id)],
        category: category,
      ),
      l.bankSetTo(_countLabel(l, picked), category.localized(l)),
    );
  }

  Future<void> _bulkSetLevel(
    FirestoreService firestore,
    List<QuestionBankSheet> picked,
  ) async {
    final l = context.l10n;
    final level = await _pickOption<String>(
      title: l.bankLevelFor(_countLabel(l, picked)),
      options: [for (final level in AppConstants.hskLevels) (level, level)],
      initial: picked.first.level,
    );
    if (level == null || !mounted) return;
    await _runBulk(
      () => firestore.updateQuestionBankSheet(
        [for (final s in picked) ...s.items.map((i) => i.id)],
        level: level,
      ),
      l.bankSetTo(_countLabel(l, picked), level),
    );
  }

  Future<void> _bulkDelete(
    FirestoreService firestore,
    List<QuestionBankSheet> picked,
  ) async {
    final l = context.l10n;
    final questions = picked.fold(0, (n, s) => n + s.count);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.bankDeleteWhat(_countLabel(l, picked))),
        content: Text(
          l.bankDeleteBulkBody(QuestionBankText.questionCount(l, questions)),
        ),
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
    if (ok != true || !mounted) return;
    await _runBulk(
      () => firestore.deleteQuestionBankItems(
        [for (final s in picked) ...s.items.map((i) => i.id)],
      ),
      l.bankDeleted(_countLabel(l, picked)),
    );
  }

  /// "2 worksheets and 1 question" for the ticked rows.
  static String _countLabel(
    AppLocalizations l,
    List<QuestionBankSheet> picked,
  ) {
    final sheets = picked.where((s) => s.isSheet).length;
    final singles = picked.length - sheets;
    if (sheets > 0 && singles > 0) {
      return l.bankCountJoin(
        l.exerciseCardWorksheets(sheets),
        l.bankTextQuestionCount(singles),
      );
    }
    return sheets > 0
        ? l.exerciseCardWorksheets(sheets)
        : l.bankTextQuestionCount(singles);
  }

  Future<T?> _pickOption<T>({
    required String title,
    required List<(T, String)> options,
    T? initial,
  }) {
    final l = context.l10n;
    var value = initial ?? options.first.$1;
    return showDialog<T>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(title),
          content: DropdownButtonFormField<T>(
            initialValue: value,
            isExpanded: true,
            items: [
              for (final (v, label) in options)
                DropdownMenuItem(value: v, child: Text(label)),
            ],
            onChanged: (v) {
              if (v != null) setDialogState(() => value = v);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, value),
              child: Text(l.bankApply),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectionBar(
    FirestoreService firestore,
    AppUser user,
    List<QuestionBankSheet> rows,
  ) {
    final l = context.l10n;
    final picked = _selectedRows(rows);
    final sheetsPicked = picked.where((s) => s.isSheet).length;
    final canManageBank = ExerciseAuthoringPlatform.canManageBank(user);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: TableSelectionBar(
        count: picked.length,
        noun: l.teacherExSelected,
        onClear: () => setState(() => _selected = {}),
        actions: [
          if (ExerciseAuthoringPlatform.canManageExercises(user))
            SelectionActionButton(
              label: sheetsPicked == 0
                  ? l.teacherExNewExercise
                  : l.bankNewExerciseWithSheets(
                      l.exerciseCardWorksheets(sheetsPicked)),
              icon: Icons.add,
              onPressed: _busy || sheetsPicked == 0
                  ? null
                  : () => _newExerciseFrom(picked, user),
            ),
          if (canManageBank) ...[
            SelectionActionButton(
              label: l.bankSetTypeOfExercise,
              icon: Icons.category_outlined,
              onPressed:
                  _busy ? null : () => _bulkSetCategory(firestore, picked),
            ),
            SelectionActionButton(
              label: l.bankSetLevel,
              icon: Icons.signal_cellular_alt_outlined,
              onPressed: _busy ? null : () => _bulkSetLevel(firestore, picked),
            ),
            SelectionActionButton(
              label: l.bankDelete,
              icon: Icons.delete_outline,
              destructive: true,
              onPressed: _busy ? null : () => _bulkDelete(firestore, picked),
            ),
          ],
        ],
      ),
    );
  }

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

  List<QuestionBankSheet> _sorted(List<QuestionBankSheet> sheets) {
    final col = _sortColumnId;
    if (col == null) return sheets;
    final sorted = [...sheets];
    sorted.sort((a, b) {
      final cmp = switch (col) {
        'title' => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        'type' => a.type.label.compareTo(b.type.label),
        'category' => a.category.index.compareTo(b.category.index),
        'level' => (a.level ?? '').compareTo(b.level ?? ''),
        'count' => a.count.compareTo(b.count),
        'used' => a.usageCount.compareTo(b.usageCount),
        _ => 0,
      };
      return _sortAscending ? cmp : -cmp;
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final firestore = context.read<FirestoreService>();
    final user = context.watch<AuthService>().appUser;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final ownerId = AppConstants.contentTeacherId(user);
    // Teachers browse the bank (to build packages); only admins change it.
    final canManageBank = ExerciseAuthoringPlatform.canManageBank(user);

    return ShellNestedPage(
      embedded: widget.embedded,
      title: l.bankTitle,
      actions: [
        ExportCsvButton(
          fileStem: 'question_bank',
          label: l.teacherExExportCsv,
          header: _csvHeader(l),
          rows: () => _visible.map((s) => _csvRow(l, s)).toList(),
        ),
        const SizedBox(width: 8),
        if (canManageBank) ...[
          TextButton.icon(
            onPressed: () => _openEditor(ownerId: ownerId),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text(l.bankTypeAQuestion),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (action) async {
              switch (action) {
                case 'samples':
                  final all = await firestore.watchQuestionBank(ownerId).first;
                  if (!context.mounted) return;
                  await runQuestionBankSampleSetImport(
                    context,
                    ownerId: ownerId,
                    existingBank: all,
                  );
                case 'scan_local':
                  await runQuestionBankWorksheetImport(context,
                      ownerId: ownerId);
                case 'paste':
                  await showQuestionBankPasteImport(context, ownerId: ownerId);
                case 'harvest':
                  final all = await firestore.watchQuestionBank(ownerId).first;
                  if (!context.mounted) return;
                  await showQuestionBankHarvestFromExercises(
                    context,
                    ownerId: ownerId,
                    existingBank: all,
                  );
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'scan_local',
                child: Text(l.bankScanWithoutAi),
              ),
              PopupMenuItem(
                value: 'samples',
                child: Text(l.bankLoadSamples),
              ),
              PopupMenuItem(value: 'paste', child: Text(l.bankBulkPaste)),
              PopupMenuItem(
                value: 'harvest',
                child: Text(l.bankHarvestTitle),
              ),
            ],
          ),
        ],
      ],
      // Scanner first: upload a paper, the AI reader types and keys each
      // question (pictures cut out), and the admin checks the list before it
      // is added. The on-device scanner (text PDFs, OCR) stays in the menu.
      floatingActionButton: !canManageBank
          ? null
          : FloatingActionButton.extended(
              onPressed: () => runQuestionBankAiImport(
                context,
                ownerId: ownerId,
              ),
              backgroundColor: AppColors.navy,
              icon: const Icon(Icons.auto_awesome_outlined),
              label: Text(l.bankAiScanWorksheet),
            ),
      child: StreamBuilder<List<QuestionBankItem>>(
        stream: firestore.watchQuestionBank(ownerId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snap.data ?? const <QuestionBankItem>[];
          final sheets = QuestionBankSheet.group(all);
          final l = context.l10n;
          final rows =
              _sorted(sheets.where((s) => _filter.matches(s, l: l)).toList());
          _visible = rows;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: QuestionBankFilterBar(
                  filter: _filter,
                  onChanged: (f) => setState(() => _filter = f),
                ),
              ),
              _selectionBar(firestore, user, rows),
              Expanded(
                child: all.isEmpty
                    ? EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: l.bankNoWorksheetsTitle,
                        subtitle: l.bankNoWorksheetsSubtitle,
                      )
                    : rows.isEmpty
                        ? EmptyState(
                            icon: Icons.filter_alt_off_outlined,
                            title: l.bankNoMatchesTitle,
                            subtitle: l.bankAdjustFilters,
                          )
                        : Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                            child: SingleChildScrollView(
                              child: AppDataTable<QuestionBankSheet>(
                                rows: rows,
                                sortColumnId: _sortColumnId,
                                sortAscending: _sortAscending,
                                onSort: _onSort,
                                rowKey: _rowKey,
                                selectedKeys: _selected,
                                onSelectionChanged: (keys) =>
                                    setState(() => _selected = keys),
                                onRowTap: (sheet) => _open(ownerId, sheet),
                                columns: _buildColumns(firestore),
                                mobileCardBuilder: (sheet) => _SheetCard(
                                  sheet: sheet,
                                  onTap: () => _open(ownerId, sheet),
                                  onEdit: () => _open(ownerId, sheet),
                                  onDelete: canManageBank
                                      ? () => _delete(firestore, sheet)
                                      : null,
                                ),
                              ),
                            ),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<AppTableColumn<QuestionBankSheet>> _buildColumns(
    FirestoreService firestore,
  ) {
    final l = context.l10n;
    final user = context.read<AuthService>().appUser!;
    final ownerId = AppConstants.contentTeacherId(user);
    final canManageBank = ExerciseAuthoringPlatform.canManageBank(user);
    return [
      AppTableColumn(
        id: 'title',
        label: l.bankCsvWorksheetOrQuestion,
        flex: 3,
        sortable: true,
        cell: (sheet) => _TitleCell(sheet: sheet),
      ),
      AppTableColumn(
        id: 'category',
        label: l.bankFiltersTypeOfExercise,
        width: 140,
        sortable: true,
        cell: (sheet) => ExerciseCategoryChip(category: sheet.category),
      ),
      AppTableColumn(
        id: 'type',
        label: l.bankFiltersQuestionType,
        width: 150,
        sortable: true,
        cell: (sheet) => Text(sheet.type.localized(l)),
      ),
      AppTableColumn(
        id: 'level',
        label: l.bankFiltersLevel,
        width: 70,
        sortable: true,
        cell: (sheet) => Text(sheet.level ?? '—'),
      ),
      AppTableColumn(
        id: 'count',
        label: l.bankQuestions,
        width: 96,
        sortable: true,
        alignment: Alignment.centerRight,
        cell: (sheet) => Text('${sheet.count}'),
      ),
      AppTableColumn(
        id: 'used',
        label: l.bankUsed,
        width: 56,
        sortable: true,
        alignment: Alignment.centerRight,
        cell: (sheet) => Text('${sheet.usageCount}'),
      ),
      AppTableColumn(
        id: 'actions',
        label: l.bankActions,
        width: 200,
        cell: (sheet) => _RowActions(
          onEdit: () => _open(ownerId, sheet),
          onDelete: canManageBank ? () => _delete(firestore, sheet) : null,
        ),
      ),
    ];
  }

  void _open(String ownerId, QuestionBankSheet sheet) {
    final user = context.read<AuthService>().appUser;
    if (sheet.isSheet) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => QuestionBankSheetScreen(
            ownerId: ownerId,
            sheetKey: sheet.key!,
          ),
        ),
      );
    } else if (ExerciseAuthoringPlatform.canManageBank(user)) {
      _openEditor(ownerId: ownerId, existing: sheet.first);
    }
  }

  Future<void> _delete(
      FirestoreService firestore, QuestionBankSheet sheet) async {
    if (!sheet.isSheet) {
      await firestore.deleteQuestionBankItem(sheet.first.id);
      return;
    }
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.bankSheetDeleteSheetTitle(sheet.code)),
        content: Text(
          l.bankSheetDeleteSheetBody(
            QuestionBankText.questionCount(l, sheet.count),
          ),
        ),
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
    if (ok == true) {
      await firestore.deleteQuestionBankItems(sheet.items.map((i) => i.id));
    }
  }

  Future<void> _openEditor({
    required String ownerId,
    QuestionBankItem? existing,
  }) {
    return showQuestionBankEditor(
      context,
      ownerId: ownerId,
      existing: existing,
    );
  }
}

/// First column: the sheet title with its code underneath, or the single
/// question's text in the question face.
class _TitleCell extends StatelessWidget {
  const _TitleCell({required this.sheet});
  final QuestionBankSheet sheet;

  @override
  Widget build(BuildContext context) {
    if (!sheet.isSheet) {
      return Text(
        sheet.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.question.copyWith(fontSize: 17),
      );
    }
    return Row(
      children: [
        Icon(Icons.description_outlined, size: 20, color: AppColors.navy),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sheet.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.question.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                ),
              ),
              if (sheet.title != sheet.code)
                Text(
                  sheet.code,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SheetCard extends StatelessWidget {
  const _SheetCard({
    required this.sheet,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final QuestionBankSheet sheet;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  /// Null when the viewer may not change the bank (teachers).
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sheet.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.question.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (sheet.isSheet) _Chip(label: sheet.code),
                    _Chip(label: sheet.category.localized(l)),
                    _Chip(label: sheet.type.localized(l)),
                    if (sheet.level != null && sheet.level!.isNotEmpty)
                      _Chip(label: sheet.level!),
                    if (sheet.isSheet)
                      _Chip(
                          label:
                              QuestionBankText.questionCount(l, sheet.count)),
                    if (sheet.usageCount > 0)
                      _Chip(label: l.bankUsedCount(sheet.usageCount)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _RowActions(onEdit: onEdit, onDelete: onDelete, compact: true),
        ],
      ),
    );
  }
}

/// Edit and Delete as labelled buttons: big enough to hit, and Edit is
/// visible without opening the worksheet first. Without [onDelete] (a
/// teacher browsing the bank) only a View button is shown.
class _RowActions extends StatelessWidget {
  const _RowActions({
    required this.onEdit,
    required this.onDelete,
    this.compact = false,
  });

  final VoidCallback onEdit;
  final VoidCallback? onDelete;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final style = OutlinedButton.styleFrom(
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12, vertical: 8),
      minimumSize: const Size(0, 36),
      visualDensity: VisualDensity.compact,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          onPressed: onEdit,
          style: style,
          icon: Icon(
            onDelete == null ? Icons.visibility_outlined : Icons.edit_outlined,
            size: 18,
          ),
          label: Text(onDelete == null ? l.bankView : l.bankEdit),
        ),
        if (onDelete != null) ...[
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onDelete,
            style: style.copyWith(
              foregroundColor: WidgetStatePropertyAll(AppColors.error),
              side: WidgetStatePropertyAll(BorderSide(color: AppColors.error)),
            ),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: Text(l.bankDelete),
          ),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: AppColors.navy)),
    );
  }
}

/// Create/edit a single bank question.
/// Multi-select picker; bumps usageCount on confirm.
Future<List<QuestionBankItem>?> showQuestionBankPicker(
  BuildContext context, {
  required String ownerId,
  required ExerciseType type,
}) {
  return showModalBottomSheet<List<QuestionBankItem>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _QuestionBankPicker(ownerId: ownerId, type: type),
  );
}

class _QuestionBankPicker extends StatefulWidget {
  const _QuestionBankPicker({required this.ownerId, required this.type});

  final String ownerId;
  final ExerciseType type;

  @override
  State<_QuestionBankPicker> createState() => _QuestionBankPickerState();
}

class _QuestionBankPickerState extends State<_QuestionBankPicker> {
  final Set<String> _selected = {};
  String _filter = '';

  Future<void> _confirm(List<QuestionBankItem> items) async {
    final picked = items.where((i) => _selected.contains(i.id)).toList();
    if (picked.isEmpty) return;
    await context.read<FirestoreService>().incrementQuestionBankUsage(
          picked.map((p) => p.id),
        );
    if (!mounted) return;
    Navigator.of(context).pop(picked);
  }

  void _toggle(Iterable<QuestionBankItem> items, bool on) => setState(() {
        for (final item in items) {
          on ? _selected.add(item.id) : _selected.remove(item.id);
        }
      });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final firestore = context.read<FirestoreService>();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return StreamBuilder<List<QuestionBankItem>>(
          stream: firestore.watchQuestionBank(widget.ownerId),
          builder: (context, snap) {
            final all = (snap.data ?? const <QuestionBankItem>[])
                .where((i) => i.type == widget.type)
                .toList();
            final needle = _filter.toLowerCase();
            // One block per worksheet (tick the header to take the whole
            // sheet), stand-alone questions after them.
            final sheets = QuestionBankSheet.group(all).where((sheet) {
              if (needle.isEmpty) return true;
              return [
                sheet.code,
                sheet.title,
                for (final i in sheet.items) i.displayText,
              ].join(' ').toLowerCase().contains(needle);
            }).toList()
              ..sort(
                  (a, b) => a.isSheet == b.isSheet ? 0 : (a.isSheet ? -1 : 1));
            final items = [for (final s in sheets) ...s.items];

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l.bankAddFromBankType(widget.type.localized(l)),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: AppColors.navy,
                              ),
                            ),
                          ),
                          FilledButton(
                            onPressed: _selected.isEmpty
                                ? null
                                : () => _confirm(items),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.navy,
                            ),
                            child: Text(l.bankAddCount(_selected.length)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: InputDecoration(
                          hintText: l.bankFilterHint,
                          isDense: true,
                          prefixIcon: const Icon(Icons.search, size: 20),
                        ),
                        onChanged: (v) => setState(() => _filter = v),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed:
                              items.isEmpty ? null : () => _toggle(items, true),
                          child: Text(l.bankSelectAllFiltered(items.length)),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: items.isEmpty
                      ? EmptyState(
                          icon: Icons.inventory_2_outlined,
                          title: l.bankNoMatchingTitle,
                          subtitle: l.bankNoMatchingSubtitle,
                        )
                      : ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                          children: [
                            for (final sheet in sheets) ...[
                              if (sheet.isSheet) _sheetHeader(sheet),
                              for (final item in sheet.items)
                                _questionTile(item, indented: sheet.isSheet),
                            ],
                          ],
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Ticking the worksheet ticks every question on it.
  Widget _sheetHeader(QuestionBankSheet sheet) {
    final picked = sheet.items.where((i) => _selected.contains(i.id)).length;
    final all = picked == sheet.count;
    return CheckboxListTile(
      value: all ? true : (picked == 0 ? false : null),
      tristate: true,
      controlAffinity: ListTileControlAffinity.leading,
      tileColor: AppColors.navy.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      secondary: Icon(Icons.description_outlined, color: AppColors.navy),
      title: Text(
        sheet.title,
        style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy),
      ),
      subtitle: Text(
        '${sheet.code} · ${QuestionBankText.questionCount(context.l10n, sheet.count)}'
        '${sheet.level != null ? ' · ${sheet.level}' : ''}',
      ),
      onChanged: (_) => _toggle(sheet.items, !all),
    );
  }

  Widget _questionTile(QuestionBankItem item, {required bool indented}) {
    final l = context.l10n;
    return CheckboxListTile(
      value: _selected.contains(item.id),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.only(left: indented ? 36 : 16, right: 16),
      title: Text(
        item.displayText.isEmpty ? l.bankSheetNoPrompt : item.displayText,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.question.copyWith(fontSize: 17),
      ),
      subtitle: Text(
        [
          if (!indented && item.level != null) item.level!,
          if (item.question.imageUrl.isNotEmpty) '🖼',
          if (item.question.audioUrl.isNotEmpty) '🔊',
          QuestionBankText.answerLine(l, item),
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.questionDetail.copyWith(fontSize: 13),
      ),
      onChanged: (v) => _toggle([item], v == true),
    );
  }
}
