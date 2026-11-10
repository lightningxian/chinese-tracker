import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_data_table.dart';
import '../../core/widgets/shell_nested_page.dart';
import '../../models/exercise_type.dart';
import '../../models/question_bank_item.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import 'question_bank_bulk_import.dart';
import 'question_bank_editor.dart';
import 'question_bank_harvest.dart';
import 'question_bank_sheet_screen.dart';
import 'question_bank_text.dart';

/// Admin/teacher screen for the shared question bank (`question_bank`
/// collection). A scanned worksheet is one row (open it to see and edit its
/// questions); a question typed or pasted on its own is a row by itself.
class QuestionBankScreen extends StatefulWidget {
  const QuestionBankScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends State<QuestionBankScreen> {
  ExerciseType? _typeFilter;
  String? _levelFilter;
  String _search = '';
  String? _sortColumnId;
  bool _sortAscending = true;

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

  /// A worksheet matches when its type and level match and the search text
  /// is in its code, title, tags or any of its questions.
  bool _matchesFilters(QuestionBankSheet sheet) {
    if (_typeFilter != null && sheet.type != _typeFilter) return false;
    if (_levelFilter != null && sheet.level != _levelFilter) return false;
    if (_search.isNotEmpty) {
      final needle = _search.toLowerCase();
      final hay = [
        sheet.code,
        sheet.title,
        ...sheet.tags,
        for (final item in sheet.items) item.displayText,
      ].join(' ').toLowerCase();
      if (!hay.contains(needle)) return false;
    }
    return true;
  }

  List<QuestionBankSheet> _sorted(List<QuestionBankSheet> sheets) {
    final col = _sortColumnId;
    if (col == null) return sheets;
    final sorted = [...sheets];
    sorted.sort((a, b) {
      final cmp = switch (col) {
        'title' => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        'type' => a.type.label.compareTo(b.type.label),
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
    final firestore = context.read<FirestoreService>();
    final user = context.watch<AuthService>().appUser;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final ownerId = AppConstants.contentTeacherId(user);

    return ShellNestedPage(
      embedded: widget.embedded,
      title: 'Question bank',
      actions: [
        TextButton.icon(
          onPressed: () => _openEditor(ownerId: ownerId),
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Type a question'),
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
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'samples',
              child: Text("Load the centre's sample sheets (10 worksheets)"),
            ),
            PopupMenuItem(value: 'paste', child: Text('Bulk import — paste')),
            PopupMenuItem(
              value: 'harvest',
              child: Text('Import from exercises'),
            ),
          ],
        ),
      ],
      // Scanner first: upload a worksheet, the app detects each question's
      // type and answer, and the admin checks the list before it is added.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => runQuestionBankWorksheetImport(
          context,
          ownerId: ownerId,
        ),
        backgroundColor: AppColors.navy,
        icon: const Icon(Icons.document_scanner_outlined),
        label: const Text('Scan worksheet'),
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
          final rows = _sorted(sheets.where(_matchesFilters).toList());

          return Column(
            children: [
              _Filters(
                typeFilter: _typeFilter,
                levelFilter: _levelFilter,
                onType: (t) => setState(() => _typeFilter = t),
                onLevel: (l) => setState(() => _levelFilter = l),
                onSearch: (s) => setState(() => _search = s),
              ),
              Expanded(
                child: all.isEmpty
                    ? const EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'No worksheets yet',
                        subtitle:
                            'Scan a worksheet to add it whole, or type a single '
                            'question. Exercises pull from here.',
                      )
                    : rows.isEmpty
                        ? const EmptyState(
                            icon: Icons.filter_alt_off_outlined,
                            title: 'No matches',
                            subtitle: 'Adjust the filters.',
                          )
                        : Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                            child: SingleChildScrollView(
                              child: AppDataTable<QuestionBankSheet>(
                                rows: rows,
                                sortColumnId: _sortColumnId,
                                sortAscending: _sortAscending,
                                onSort: _onSort,
                                onRowTap: (sheet) => _open(ownerId, sheet),
                                columns: _buildColumns(firestore),
                                mobileCardBuilder: (sheet) => _SheetCard(
                                  sheet: sheet,
                                  onTap: () => _open(ownerId, sheet),
                                  onDelete: () => _delete(firestore, sheet),
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
    return [
      AppTableColumn(
        id: 'title',
        label: 'Worksheet / question',
        flex: 3,
        sortable: true,
        cell: (sheet) => _TitleCell(sheet: sheet),
      ),
      AppTableColumn(
        id: 'type',
        label: 'Type',
        width: 130,
        sortable: true,
        cell: (sheet) => Text(sheet.type.label),
      ),
      AppTableColumn(
        id: 'level',
        label: 'Level',
        width: 70,
        sortable: true,
        cell: (sheet) => Text(sheet.level ?? '—'),
      ),
      AppTableColumn(
        id: 'count',
        label: 'Questions',
        width: 96,
        sortable: true,
        alignment: Alignment.centerRight,
        cell: (sheet) => Text('${sheet.count}'),
      ),
      AppTableColumn(
        id: 'tags',
        label: 'Tags',
        flex: 2,
        cell: (sheet) => Text(
          sheet.tags.map((t) => '#$t').join(' '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13),
        ),
      ),
      AppTableColumn(
        id: 'used',
        label: 'Used',
        width: 56,
        sortable: true,
        alignment: Alignment.centerRight,
        cell: (sheet) => Text('${sheet.usageCount}'),
      ),
      AppTableColumn(
        id: 'actions',
        label: '',
        width: 48,
        cell: (sheet) => IconButton(
          icon: Icon(Icons.delete_outline, color: AppColors.error),
          onPressed: () => _delete(firestore, sheet),
          tooltip: sheet.isSheet ? 'Delete worksheet' : 'Delete',
        ),
      ),
    ];
  }

  void _open(String ownerId, QuestionBankSheet sheet) {
    if (sheet.isSheet) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => QuestionBankSheetScreen(
            ownerId: ownerId,
            sheetKey: sheet.key!,
          ),
        ),
      );
    } else {
      _openEditor(ownerId: ownerId, existing: sheet.first);
    }
  }

  Future<void> _delete(
      FirestoreService firestore, QuestionBankSheet sheet) async {
    if (!sheet.isSheet) {
      await firestore.deleteQuestionBankItem(sheet.first.id);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete worksheet ${sheet.code}?'),
        content: Text(
          'All ${QuestionBankText.questionCount(sheet.count)} leave the bank. '
          'Exercises that already use them keep their copies.',
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

class _Filters extends StatelessWidget {
  const _Filters({
    required this.typeFilter,
    required this.levelFilter,
    required this.onType,
    required this.onLevel,
    required this.onSearch,
  });

  final ExerciseType? typeFilter;
  final String? levelFilter;
  final ValueChanged<ExerciseType?> onType;
  final ValueChanged<String?> onLevel;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search worksheet, question or tag',
                isDense: true,
              ),
              onChanged: onSearch,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<ExerciseType?>(
              initialValue: typeFilter,
              isExpanded: true,
              decoration:
                  const InputDecoration(labelText: 'Type', isDense: true),
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                for (final t in ExerciseType.values)
                  DropdownMenuItem(value: t, child: Text(t.label)),
              ],
              onChanged: onType,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: DropdownButtonFormField<String?>(
              initialValue: levelFilter,
              isExpanded: true,
              decoration:
                  const InputDecoration(labelText: 'Level', isDense: true),
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                for (final l in AppConstants.hskLevels)
                  DropdownMenuItem(value: l, child: Text(l)),
              ],
              onChanged: onLevel,
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetCard extends StatelessWidget {
  const _SheetCard({
    required this.sheet,
    required this.onTap,
    required this.onDelete,
  });

  final QuestionBankSheet sheet;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
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
                    _Chip(label: sheet.type.label),
                    if (sheet.level != null && sheet.level!.isNotEmpty)
                      _Chip(label: sheet.level!),
                    if (sheet.isSheet)
                      _Chip(label: QuestionBankText.questionCount(sheet.count)),
                    if (sheet.usageCount > 0)
                      _Chip(label: 'Used ${sheet.usageCount}'),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: onDelete,
          ),
        ],
      ),
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
                              'Add from bank — ${widget.type.label}',
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
                            child: Text('Add (${_selected.length})'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: const InputDecoration(
                          hintText: 'Filter worksheets and questions…',
                          isDense: true,
                          prefixIcon: Icon(Icons.search, size: 20),
                        ),
                        onChanged: (v) => setState(() => _filter = v),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed:
                              items.isEmpty ? null : () => _toggle(items, true),
                          child: Text('Select all (${items.length} filtered)'),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: items.isEmpty
                      ? const EmptyState(
                          icon: Icons.inventory_2_outlined,
                          title: 'No matching bank questions',
                          subtitle:
                              'Add questions of this type to the bank first.',
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
        '${sheet.code} · ${QuestionBankText.questionCount(sheet.count)}'
        '${sheet.level != null ? ' · ${sheet.level}' : ''}',
      ),
      onChanged: (_) => _toggle(sheet.items, !all),
    );
  }

  Widget _questionTile(QuestionBankItem item, {required bool indented}) {
    return CheckboxListTile(
      value: _selected.contains(item.id),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.only(left: indented ? 36 : 16, right: 16),
      title: Text(
        item.displayText.isEmpty ? '(no prompt)' : item.displayText,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.question.copyWith(fontSize: 17),
      ),
      subtitle: Text(
        [
          if (!indented && item.level != null) item.level!,
          if (item.question.imageUrl.isNotEmpty) '🖼',
          if (item.question.audioUrl.isNotEmpty) '🔊',
          QuestionBankText.answerLine(item),
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.questionDetail.copyWith(fontSize: 13),
      ),
      onChanged: (v) => _toggle([item], v == true),
    );
  }
}
