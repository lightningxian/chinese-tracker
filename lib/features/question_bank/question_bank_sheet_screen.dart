import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/exercise_authoring_platform.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/constants/app_constants.dart';
import '../../models/exercise_skill_category.dart';
import '../../models/exercise_type.dart';
import '../../models/question_bank_item.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../teacher/exercise_assign_dialog.dart';
import 'question_bank_editor.dart';
import 'question_bank_text.dart';

/// One worksheet in the bank: its questions in sheet order with the stored
/// answer. Tap a question to edit it, the arrows move it, the trash icon
/// removes it from the sheet; "Add question" appends one. The app bar edits
/// the sheet as a whole (title, type, level, skill), deletes it, or assigns
/// it: that creates an exercise holding just this worksheet and opens the
/// student picker.
class QuestionBankSheetScreen extends StatelessWidget {
  const QuestionBankSheetScreen({
    super.key,
    required this.ownerId,
    required this.sheetKey,
  });

  final String ownerId;

  /// [QuestionBankItem.sheetKey] of the worksheet to show.
  final String sheetKey;

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    return StreamBuilder<List<QuestionBankItem>>(
      stream: firestore.watchQuestionBank(ownerId),
      builder: (context, snap) {
        final sheet = QuestionBankSheet.group(snap.data ?? const [])
            .where((s) => s.key == sheetKey)
            .firstOrNull;

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            backgroundColor: AppColors.card,
            foregroundColor: AppColors.navy,
            elevation: 0,
            title: Text(sheet?.title ?? sheetKey),
            actions: [
              if (sheet != null) ...[
                if (ExerciseAuthoringPlatform.canManageExercises(
                  context.watch<AuthService>().appUser,
                ))
                  FilledButton.icon(
                    onPressed: () => _assignSheet(context, sheet),
                    icon: const Icon(Icons.assignment_ind_outlined, size: 18),
                    label: const Text('Assign this worksheet'),
                    style:
                        FilledButton.styleFrom(backgroundColor: AppColors.navy),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _editSheet(context, sheet),
                  icon: const Icon(Icons.tune),
                  tooltip: 'Edit worksheet (title, type, level)',
                ),
                IconButton(
                  onPressed: () => _deleteSheet(context, sheet),
                  icon:
                      const Icon(Icons.delete_outline, color: AppColors.error),
                  tooltip: 'Delete worksheet',
                ),
              ],
              const SizedBox(width: 8),
            ],
          ),
          body: sheet == null
              ? (snap.connectionState == ConnectionState.waiting
                  ? const Center(child: CircularProgressIndicator())
                  : const EmptyState(
                      icon: Icons.description_outlined,
                      title: 'Worksheet removed',
                      subtitle: 'Its questions are no longer in the bank.',
                    ))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  children: [
                    _SheetHeader(sheet: sheet),
                    const SizedBox(height: 16),
                    for (final (i, item) in sheet.items.indexed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _QuestionRow(
                          index: i,
                          item: item,
                          onTap: () => _edit(context, item, sheet),
                          onMoveUp: i == 0
                              ? null
                              : () => _move(context, sheet, i, i - 1),
                          onMoveDown: i == sheet.items.length - 1
                              ? null
                              : () => _move(context, sheet, i, i + 1),
                          onDelete: () => _deleteQuestion(context, item),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () => _addQuestion(context, sheet),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add question'),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Future<void> _edit(
    BuildContext context,
    QuestionBankItem item,
    QuestionBankSheet sheet,
  ) {
    return showQuestionBankEditor(
      context,
      ownerId: ownerId,
      existing: item,
      sheet: sheet,
    );
  }

  Future<void> _addQuestion(BuildContext context, QuestionBankSheet sheet) {
    return showQuestionBankEditor(context, ownerId: ownerId, sheet: sheet);
  }

  /// Swaps two questions and stores the new order on the whole sheet.
  Future<void> _move(
    BuildContext context,
    QuestionBankSheet sheet,
    int from,
    int to,
  ) {
    final ids = sheet.items.map((i) => i.id).toList();
    final id = ids.removeAt(from);
    ids.insert(to, id);
    return context.read<FirestoreService>().reorderQuestionBankSheet(ids);
  }

  /// Title, type, level and skill of the whole worksheet. Applies to every
  /// question; the code stays.
  Future<void> _editSheet(BuildContext context, QuestionBankSheet sheet) async {
    final result = await showDialog<_SheetEdit>(
      context: context,
      builder: (_) => _SheetEditDialog(sheet: sheet),
    );
    if (result == null || !context.mounted) return;
    await context.read<FirestoreService>().updateQuestionBankSheet(
          sheet.items.map((i) => i.id),
          title: result.title == sheet.title ? null : result.title,
          level: result.level == sheet.level ? null : result.level,
          skillCategory:
              result.skill == sheet.first.skillCategory ? null : result.skill,
          type: result.type == sheet.type ? null : result.type,
        );
  }

  /// One exercise with just this worksheet, published, then the student
  /// picker. Assigning the same sheet again reuses that exercise.
  Future<void> _assignSheet(
      BuildContext context, QuestionBankSheet sheet) async {
    final firestore = context.read<FirestoreService>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final all = await firestore.watchAllExercises().first;
      var exercise = all
          .where((e) =>
              e.isPackage &&
              e.bankSheets.length == 1 &&
              e.bankQuestionIds.isEmpty &&
              e.bankSheets.first == sheet.key)
          .firstOrNull;
      if (exercise == null) {
        final id = await firestore.saveExercisePackage(
          teacherId: ownerId,
          title: sheet.title,
          instructions: '',
          level: sheet.level ?? '',
          skillCategory: sheet.first.skillCategory ??
              ExerciseSkillCategory.forExerciseType(sheet.type),
          bankSheets: [sheet.key!],
          bankQuestionIds: const [],
          isPublished: true,
        );
        exercise = await firestore.getExercise(id);
      }
      if (exercise == null || !context.mounted) return;
      await showExerciseAssignDialog(context, exercise: exercise);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not assign: $e')));
    }
  }

  Future<void> _deleteQuestion(
      BuildContext context, QuestionBankItem item) async {
    final ok = await _confirm(
      context,
      title: 'Remove this question?',
      body:
          'It leaves the worksheet and the bank. Exercises that already use it keep their copy.',
    );
    if (ok && context.mounted) {
      await context.read<FirestoreService>().deleteQuestionBankItem(item.id);
    }
  }

  Future<void> _deleteSheet(
      BuildContext context, QuestionBankSheet sheet) async {
    final ok = await _confirm(
      context,
      title: 'Delete worksheet ${sheet.code}?',
      body:
          'All ${QuestionBankText.questionCount(sheet.count)} leave the bank. '
          'Exercises that already use them keep their copies.',
    );
    if (!ok || !context.mounted) return;
    final navigator = Navigator.of(context);
    await context
        .read<FirestoreService>()
        .deleteQuestionBankItems(sheet.items.map((i) => i.id));
    if (navigator.canPop()) navigator.pop();
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String body,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
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
    return result ?? false;
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.sheet});
  final QuestionBankSheet sheet;

  @override
  Widget build(BuildContext context) {
    final facts = [
      sheet.code,
      sheet.type.label,
      if (sheet.level != null && sheet.level!.isNotEmpty) sheet.level!,
      QuestionBankText.questionCount(sheet.count),
      if (sheet.usageCount > 0) 'used ${sheet.usageCount}×',
    ];
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.description_outlined,
              color: AppColors.navy, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sheet.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  facts.join(' · '),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                if (sheet.tags.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    sheet.tags.map((t) => '#$t').join('  '),
                    style: const TextStyle(fontSize: 13, color: AppColors.navy),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionRow extends StatelessWidget {
  const _QuestionRow({
    required this.index,
    required this.item,
    required this.onTap,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onDelete,
  });

  final int index;
  final QuestionBankItem item;
  final VoidCallback onTap;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '${index + 1}.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                height: 1.6,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayText.isEmpty ? '(no prompt)' : item.displayText,
                  style: AppTextStyles.question.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  QuestionBankText.answerLine(item),
                  style: AppTextStyles.questionDetail,
                ),
                if (item.question.imageUrl.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.question.imageUrl,
                        height: 120,
                        fit: BoxFit.contain,
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_up),
                tooltip: 'Move up',
                visualDensity: VisualDensity.compact,
                onPressed: onMoveUp,
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down),
                tooltip: 'Move down',
                visualDensity: VisualDensity.compact,
                onPressed: onMoveDown,
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit question',
            onPressed: onTap,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            tooltip: 'Remove from worksheet',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _SheetEdit {
  const _SheetEdit({
    required this.title,
    required this.type,
    required this.level,
    required this.skill,
  });
  final String title;
  final ExerciseType type;
  final String? level;
  final ExerciseSkillCategory skill;
}

class _SheetEditDialog extends StatefulWidget {
  const _SheetEditDialog({required this.sheet});
  final QuestionBankSheet sheet;

  @override
  State<_SheetEditDialog> createState() => _SheetEditDialogState();
}

class _SheetEditDialogState extends State<_SheetEditDialog> {
  late final TextEditingController _title =
      TextEditingController(text: widget.sheet.title);
  late ExerciseType _type = widget.sheet.type;
  late String? _level = AppConstants.hskLevels.contains(widget.sheet.level)
      ? widget.sheet.level
      : null;
  late ExerciseSkillCategory _skill = widget.sheet.first.skillCategory ??
      ExerciseSkillCategory.forExerciseType(widget.sheet.type);

  /// Choice-style types keep the same answers; the others store answers in
  /// another shape, so switching between the groups needs a re-check.
  static const _choiceTypes = {
    ExerciseType.multipleChoice,
    ExerciseType.listening,
    ExerciseType.matching,
    ExerciseType.readingCloze,
  };

  bool get _typeChangesShape =>
      _type != widget.sheet.type &&
      !(_choiceTypes.contains(_type) &&
          _choiceTypes.contains(widget.sheet.type));

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit worksheet'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _title,
              autofocus: true,
              style: AppTextStyles.question,
              decoration: InputDecoration(
                labelText: 'Title',
                helperText: 'Code ${widget.sheet.code} stays the same.',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ExerciseType>(
              initialValue: _type,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Type',
                helperText: _typeChangesShape
                    ? 'This type stores answers differently: open each '
                        'question afterwards and check its answer.'
                    : 'Applies to every question on the sheet.',
                helperMaxLines: 3,
              ),
              items: [
                for (final t in ExerciseType.values)
                  DropdownMenuItem(value: t, child: Text(t.label)),
              ],
              onChanged: (t) => setState(() {
                _type = t ?? _type;
                _skill = ExerciseSkillCategory.forExerciseType(_type);
              }),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: _level,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Level'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('—')),
                      for (final l in AppConstants.hskLevels)
                        DropdownMenuItem(value: l, child: Text(l)),
                    ],
                    onChanged: (l) => setState(() => _level = l),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<ExerciseSkillCategory>(
                    initialValue: _skill,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Skill'),
                    items: [
                      for (final c in ExerciseSkillCategory.values)
                        DropdownMenuItem(value: c, child: Text(c.label)),
                    ],
                    onChanged: (c) => setState(() => _skill = c ?? _skill),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final title = _title.text.trim();
            if (title.isEmpty) return;
            Navigator.pop(
              context,
              _SheetEdit(
                title: title,
                type: _type,
                level: _level,
                skill: _skill,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
