import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/shell_nested_page.dart';
import '../../models/exercise.dart';
import '../../models/exercise_skill_category.dart';
import '../../models/question_bank_item.dart';
import '../../services/firestore_service.dart';
import '../question_bank/question_bank_text.dart';
import 'exercise_assign_dialog.dart';

/// An exercise built from the question bank: a title, a level and a list of
/// worksheets (and single questions). Students never get a copy; the
/// `startExercise` function reads the bank when they open it, so a bank edit
/// shows up in every exercise that uses the sheet.
class ExercisePackageFormScreen extends StatefulWidget {
  const ExercisePackageFormScreen({
    super.key,
    required this.teacherId,
    this.exercise,
    this.initialSheets = const [],
    this.embedded = false,
  });

  final String teacherId;

  /// Existing package to edit, or null for a new one.
  final Exercise? exercise;

  /// Worksheet codes to start with (after "Scan worksheet").
  final List<String> initialSheets;
  final bool embedded;

  @override
  State<ExercisePackageFormScreen> createState() =>
      _ExercisePackageFormScreenState();
}

class _ExercisePackageFormScreenState extends State<ExercisePackageFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.exercise?.title ?? '');
  late final _instructions =
      TextEditingController(text: widget.exercise?.instructions ?? '');
  late String _level = widget.exercise?.level ?? AppConstants.hskLevels.first;
  late ExerciseSkillCategory _skill =
      widget.exercise?.skillCategory ?? ExerciseSkillCategory.reading;
  late bool _published = widget.exercise?.isPublished ?? true;
  late final List<String> _sheets = [
    ...?widget.exercise?.bankSheets,
    ...widget.initialSheets.where(
      (s) => !(widget.exercise?.bankSheets.contains(s) ?? false),
    ),
  ];
  late final List<String> _questionIds = [...?widget.exercise?.bankQuestionIds];
  bool _saving = false;
  bool _titleTouched = false;

  bool get _isEditing => widget.exercise != null;

  @override
  void dispose() {
    _title.dispose();
    _instructions.dispose();
    super.dispose();
  }

  /// Title and level follow the first worksheet until the admin types.
  void _followFirstSheet(List<QuestionBankSheet> bank) {
    if (_isEditing || _titleTouched || _sheets.isEmpty) return;
    final first = bank.where((s) => s.key == _sheets.first).firstOrNull;
    if (first == null) return;
    if (_title.text.isEmpty) _title.text = first.title;
    if (first.level != null && AppConstants.hskLevels.contains(first.level)) {
      _level = first.level!;
    }
    _skill = first.first.skillCategory ?? _skill;
  }

  Future<void> _save({bool thenAssign = false}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_sheets.isEmpty && _questionIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one worksheet or question.')),
      );
      return;
    }
    setState(() => _saving = true);
    final firestore = context.read<FirestoreService>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final id = await firestore.saveExercisePackage(
        exerciseId: widget.exercise?.id,
        teacherId: widget.teacherId,
        title: _title.text,
        instructions: _instructions.text,
        level: _level,
        skillCategory: _skill,
        bankSheets: _sheets,
        bankQuestionIds: _questionIds,
        isPublished: _published,
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(_isEditing ? 'Exercise saved.' : 'Exercise created.')),
      );
      if (thenAssign) {
        final saved = await firestore.getExercise(id);
        if (saved != null && mounted) {
          await showExerciseAssignDialog(context, exercise: saved);
        }
      }
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text('Could not save: $e')));
    }
  }

  Future<void> _pickFromBank(List<QuestionBankSheet> bank) async {
    final picked = await showModalBottomSheet<_BankPick>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _BankPicker(
        bank: bank,
        sheets: _sheets.toSet(),
        questionIds: _questionIds.toSet(),
      ),
    );
    if (picked == null) return;
    setState(() {
      _sheets
        ..removeWhere((s) => !picked.sheets.contains(s))
        ..addAll(picked.sheets.where((s) => !_sheets.contains(s)));
      _questionIds
        ..removeWhere((q) => !picked.questionIds.contains(q))
        ..addAll(picked.questionIds.where((q) => !_questionIds.contains(q)));
      _followFirstSheet(bank);
    });
  }

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    return ShellNestedPage(
      embedded: widget.embedded,
      title: _isEditing ? 'Edit exercise' : 'New exercise',
      child: StreamBuilder<List<QuestionBankItem>>(
        stream: firestore.watchQuestionBank(widget.teacherId),
        builder: (context, snap) {
          final bank = QuestionBankSheet.group(snap.data ?? const []);
          if (snap.hasData) _followFirstSheet(bank);
          final byKey = {for (final s in bank) if (s.isSheet) s.key!: s};
          final byQuestion = {
            for (final s in bank)
              for (final q in s.items) q.id: q,
          };
          final total = _sheets.fold<int>(0, (n, k) => n + (byKey[k]?.count ?? 0)) +
              _questionIds.length;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _title,
                        onChanged: (_) => _titleTouched = true,
                        decoration: const InputDecoration(labelText: 'Title'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              key: ValueKey('level-$_level'),
                              initialValue: _level,
                              isExpanded: true,
                              decoration: const InputDecoration(labelText: 'HSK level'),
                              items: [
                                for (final l in AppConstants.hskLevels)
                                  DropdownMenuItem(value: l, child: Text(l)),
                              ],
                              onChanged: (v) => setState(() {
                                _titleTouched = true;
                                _level = v ?? _level;
                              }),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<ExerciseSkillCategory>(
                              key: ValueKey('skill-${_skill.value}'),
                              initialValue: _skill,
                              isExpanded: true,
                              decoration:
                                  const InputDecoration(labelText: 'Skill section'),
                              items: [
                                for (final c in ExerciseSkillCategory.values)
                                  DropdownMenuItem(value: c, child: Text(c.label)),
                              ],
                              onChanged: (v) => setState(() => _skill = v ?? _skill),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _instructions,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Instructions (optional)',
                          alignLabelWithHint: true,
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _published,
                        title: const Text('Published'),
                        subtitle: const Text(
                          'Assigned students can open it. Drafts stay hidden.',
                        ),
                        onChanged: (v) => setState(() => _published = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Contents · ${QuestionBankText.questionCount(total)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: snap.hasData ? () => _pickFromBank(bank) : null,
                      style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
                      icon: const Icon(Icons.inventory_2_outlined, size: 18),
                      label: const Text('Add from bank'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_sheets.isEmpty && _questionIds.isEmpty)
                  const AppCard(
                    child: Text(
                      'Nothing yet. Add worksheets from the question bank; the '
                      'students get them in this order. Edit a worksheet in the '
                      'bank later and this exercise follows.',
                      style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                    ),
                  ),
                for (final (i, key) in _sheets.indexed)
                  _ContentRow(
                    index: i,
                    icon: Icons.description_outlined,
                    title: byKey[key]?.title ?? key,
                    subtitle: byKey[key] == null
                        ? 'Not in the bank any more'
                        : '$key · ${byKey[key]!.type.label} · '
                            '${QuestionBankText.questionCount(byKey[key]!.count)}',
                    canMoveUp: i > 0,
                    canMoveDown: i < _sheets.length - 1,
                    onMove: (d) => setState(() {
                      final item = _sheets.removeAt(i);
                      _sheets.insert(i + d, item);
                    }),
                    onRemove: () => setState(() => _sheets.removeAt(i)),
                  ),
                for (final (i, id) in _questionIds.indexed)
                  _ContentRow(
                    index: _sheets.length + i,
                    icon: Icons.help_outline,
                    title: byQuestion[id]?.displayText ?? '(question removed)',
                    subtitle: byQuestion[id] == null
                        ? 'Not in the bank any more'
                        : QuestionBankText.answerLine(byQuestion[id]!),
                    canMoveUp: i > 0,
                    canMoveDown: i < _questionIds.length - 1,
                    onMove: (d) => setState(() {
                      final item = _questionIds.removeAt(i);
                      _questionIds.insert(i + d, item);
                    }),
                    onRemove: () => setState(() => _questionIds.removeAt(i)),
                  ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : () => _save(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(_isEditing ? 'Save' : 'Save as draft or publish'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _saving ? null : () => _save(thenAssign: true),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.assignment_ind_outlined, size: 18),
                        label: const Text('Save and assign'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ContentRow extends StatelessWidget {
  const _ContentRow({
    required this.index,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMove,
    required this.onRemove,
  });

  final int index;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool canMoveUp;
  final bool canMoveDown;
  final ValueChanged<int> onMove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        child: Row(
          children: [
            Text(
              '${index + 1}.',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 10),
            Icon(icon, color: AppColors.navy, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.question.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_upward, size: 18),
              onPressed: canMoveUp ? () => onMove(-1) : null,
              tooltip: 'Move up',
            ),
            IconButton(
              icon: const Icon(Icons.arrow_downward, size: 18),
              onPressed: canMoveDown ? () => onMove(1) : null,
              tooltip: 'Move down',
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: AppColors.error),
              onPressed: onRemove,
              tooltip: 'Remove',
            ),
          ],
        ),
      ),
    );
  }
}

class _BankPick {
  const _BankPick({required this.sheets, required this.questionIds});
  final Set<String> sheets;
  final Set<String> questionIds;
}

/// Every row of the bank (worksheets and single questions) with a tick box.
class _BankPicker extends StatefulWidget {
  const _BankPicker({
    required this.bank,
    required this.sheets,
    required this.questionIds,
  });

  final List<QuestionBankSheet> bank;
  final Set<String> sheets;
  final Set<String> questionIds;

  @override
  State<_BankPicker> createState() => _BankPickerState();
}

class _BankPickerState extends State<_BankPicker> {
  late final Set<String> _sheets = {...widget.sheets};
  late final Set<String> _questionIds = {...widget.questionIds};
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final needle = _filter.trim().toLowerCase();
    final rows = widget.bank.where((s) {
      if (needle.isEmpty) return true;
      return [
        s.code,
        s.title,
        s.type.label,
        s.level ?? '',
        for (final i in s.items) i.displayText,
      ].join(' ').toLowerCase().contains(needle);
    }).toList();
    final count = _sheets.length + _questionIds.length;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Add from the question bank',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(
                        context,
                        _BankPick(sheets: _sheets, questionIds: _questionIds),
                      ),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
                      child: Text('Done ($count)'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search worksheets and questions…',
                    isDense: true,
                    prefixIcon: Icon(Icons.search, size: 20),
                  ),
                  onChanged: (v) => setState(() => _filter = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: rows.isEmpty
                ? const EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'Nothing in the bank matches',
                    subtitle: 'Scan a worksheet first.',
                  )
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                    itemCount: rows.length,
                    itemBuilder: (context, i) {
                      final row = rows[i];
                      final ticked = row.isSheet
                          ? _sheets.contains(row.key)
                          : _questionIds.contains(row.first.id);
                      return CheckboxListTile(
                        value: ticked,
                        controlAffinity: ListTileControlAffinity.leading,
                        secondary: Icon(
                          row.isSheet
                              ? Icons.description_outlined
                              : Icons.help_outline,
                          color: AppColors.navy,
                        ),
                        title: Text(
                          row.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.question.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          row.isSheet
                              ? '${row.code} · ${row.type.label} · '
                                  '${row.level ?? ''} · '
                                  '${QuestionBankText.questionCount(row.count)}'
                              : '${row.type.label} · ${row.level ?? ''}',
                        ),
                        onChanged: (v) => setState(() {
                          if (row.isSheet) {
                            v == true ? _sheets.add(row.key!) : _sheets.remove(row.key);
                          } else {
                            v == true
                                ? _questionIds.add(row.first.id)
                                : _questionIds.remove(row.first.id);
                          }
                        }),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
