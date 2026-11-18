import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/exercise_authoring_platform.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/file_download.dart' as file_download;
import '../../l10n/l10n.dart';
import '../../l10n/labels_exercises.dart';
import '../../models/exercise_category.dart';
import '../../models/exercise_skill_category.dart';
import '../../models/exercise_type.dart';
import '../../models/paper_proof_record.dart';
import '../../models/question_bank_item.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/hsk_paper/paper_truth.dart';
import '../../services/question_bank_media_service.dart';
import '../teacher/exercise_assign_dialog.dart';
import 'question_bank_editor.dart';
import 'question_bank_pictures.dart';
import 'question_bank_text.dart';
import 'sheet_answer_key.dart';
import 'sheet_transcript.dart';

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
    final l = context.l10n;
    final firestore = context.read<FirestoreService>();
    return StreamBuilder<List<QuestionBankItem>>(
      stream: firestore.watchQuestionBank(ownerId),
      builder: (context, snap) {
        final sheet = QuestionBankSheet.group(snap.data ?? const [])
            .where((s) => s.key == sheetKey)
            .firstOrNull;
        final user = context.watch<AuthService>().appUser;
        // Teachers open a worksheet to read it (and assign it); only admins
        // change the bank.
        final canManageBank = ExerciseAuthoringPlatform.canManageBank(user);

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            backgroundColor: AppColors.card,
            foregroundColor: AppColors.navy,
            elevation: 0,
            title: Text(sheet?.title ?? sheetKey),
            actions: [
              if (sheet != null) ...[
                // Supervised tests (Build 1): a scanned paper becomes a test
                // code; the form opens with this worksheet filled in.
                if (canManageBank && sheet.isSheet) ...[
                  OutlinedButton.icon(
                    onPressed: () => context.push(
                        '/admin/tests/codes/new?sheet=${Uri.encodeComponent(sheet.key!)}'),
                    icon: const Icon(Icons.qr_code_2_outlined, size: 18),
                    label: Text(l.testsCreateCode),
                  ),
                  const SizedBox(width: 8),
                ],
                // HSK simulations run only through test codes (2026-11-16).
                if (ExerciseAuthoringPlatform.canManageExercises(user) &&
                    sheet.category != ExerciseCategory.hskSimulation)
                  FilledButton.icon(
                    onPressed: () => _assignSheet(context, sheet),
                    icon: const Icon(Icons.assignment_ind_outlined, size: 18),
                    label: Text(l.bankSheetAssignThis),
                    style:
                        FilledButton.styleFrom(backgroundColor: AppColors.navy),
                  ),
                const SizedBox(width: 8),
                if (canManageBank) ...[
                  // Build 1C: the proofread worksheet as a truth file for
                  // measuring the paper reader (docs/PLAN.md §4, Must 1b).
                  if (sheet.isSheet)
                    IconButton(
                      onPressed: () => _downloadText(context, sheet),
                      icon: const Icon(Icons.file_download_outlined),
                      tooltip: l.bankSheetDownloadText,
                    ),
                  IconButton(
                    onPressed: () => _answerKey(context, sheet),
                    icon: const Icon(Icons.key_outlined),
                    tooltip: l.bankSheetAnswerKey,
                  ),
                  IconButton(
                    onPressed: () => _editSheet(context, sheet),
                    icon: const Icon(Icons.tune),
                    tooltip: l.bankSheetEditTooltip,
                  ),
                  IconButton(
                    onPressed: () => _deleteSheet(context, sheet),
                    icon: Icon(Icons.delete_outline, color: AppColors.error),
                    tooltip: l.bankSheetDeleteTooltip,
                  ),
                ],
              ],
              const SizedBox(width: 8),
            ],
          ),
          body: sheet == null
              ? (snap.connectionState == ConnectionState.waiting
                  ? const Center(child: CircularProgressIndicator())
                  : EmptyState(
                      icon: Icons.description_outlined,
                      title: l.bankSheetRemovedTitle,
                      subtitle: l.bankSheetRemovedSubtitle,
                    ))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  children: [
                    _SheetHeader(sheet: sheet),
                    const SizedBox(height: 12),
                    _ListeningAudioCard(
                      sheet: sheet,
                      readOnly: !canManageBank,
                      onUpload: () => _uploadAudio(context, sheet),
                      onRemove: () => _setAudio(context, sheet, null),
                    ),
                    const SizedBox(height: 12),
                    SheetTranscriptCard(
                      sheet: sheet,
                      readOnly: !canManageBank,
                    ),
                    if (canManageBank && sheet.paperRecord != null) ...[
                      const SizedBox(height: 12),
                      _PaperRecordCard(record: sheet.paperRecord!),
                    ],
                    const SizedBox(height: 16),
                    for (final (i, item) in sheet.items.indexed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _QuestionRow(
                          sectionHeading: _headingFor(sheet, i),
                          index: i,
                          item: item,
                          readOnly: !canManageBank,
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
                    if (canManageBank)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: () => _addQuestion(context, sheet),
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(l.bankSheetAddQuestion),
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }

  /// The part heading, on the first question of each part only.
  static String? _headingFor(QuestionBankSheet sheet, int i) {
    final section = sheet.items[i].section?.trim() ?? '';
    if (section.isEmpty) return null;
    if (i > 0 && sheet.items[i - 1].section?.trim() == section) return null;
    return section;
  }

  Future<void> _uploadAudio(BuildContext context, QuestionBankSheet sheet) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context, rootNavigator: true);
    // A paper's recording can be large (up to 60 MB): show the upload.
    final progress = ValueNotifier<double>(0);
    var dialogOpen = false;
    try {
      final url = await context.read<QuestionBankMediaService>().pickAndUploadAudio(
        ownerId,
        onPicked: () {
          dialogOpen = true;
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              title: Text(l.paperUploadingRecording),
              content: ValueListenableBuilder<double>(
                valueListenable: progress,
                builder: (_, v, __) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(value: v),
                    const SizedBox(height: 8),
                    Text('${(v * 100).round()}%'),
                  ],
                ),
              ),
            ),
          );
        },
        onProgress: (v) => progress.value = v,
      );
      if (dialogOpen) navigator.pop();
      dialogOpen = false;
      if (!context.mounted) return;
      await _setAudio(context, sheet, url);
    } on QuestionBankMediaCancelledException {
      // nothing picked
    } catch (e) {
      if (dialogOpen) navigator.pop();
      messenger.showSnackBar(
          SnackBar(content: Text(l.bankEditorUploadFailed('$e'))));
    } finally {
      progress.dispose();
    }
  }

  /// Stores (or clears) the recording on the listening questions of the
  /// sheet, and clears it from any other question that still carries it.
  Future<void> _setAudio(
    BuildContext context,
    QuestionBankSheet sheet,
    String? url,
  ) async {
    final firestore = context.read<FirestoreService>();
    final targets = sheet.listeningItems.map((i) => i.id).toSet();
    final others = [
      for (final i in sheet.items)
        if (!targets.contains(i.id) &&
            (i.sectionAudioUrl?.isNotEmpty ?? false))
          i.id,
    ];
    if (others.isNotEmpty) {
      await firestore.setQuestionBankSectionAudio(others, null);
    }
    await firestore.setQuestionBankSectionAudio(targets, url);
  }

  /// The admin types or pastes the printed key (choices, and since Build
  /// 1B the writing answers); see [showSheetAnswerKeyDialog].
  /// **Download text** (admin, web): the worksheet's questions as one JSON
  /// file in the reader's shape, `<code>.truth.json`.
  void _downloadText(BuildContext context, QuestionBankSheet sheet) {
    final l = context.l10n;
    final level = int.tryParse(
        RegExp(r'\d').firstMatch(sheet.first.level ?? '')?.group(0) ?? '');
    final truth = PaperTruth.fromWorksheet(sheet.items,
        code: sheet.code, level: level);
    file_download.downloadTextFile('${sheet.code}.truth.json', truth.encode());
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l.bankSheetTextDownloaded(truth.questions.length))));
  }

  Future<void> _answerKey(BuildContext context, QuestionBankSheet sheet) =>
      showSheetAnswerKeyDialog(context, sheet);

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
          category: result.category == sheet.category ? null : result.category,
        );
  }

  /// One exercise with just this worksheet, published, then the student
  /// picker. Assigning the same sheet again reuses that exercise.
  Future<void> _assignSheet(
      BuildContext context, QuestionBankSheet sheet) async {
    final l = context.l10n;
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
      messenger.showSnackBar(SnackBar(content: Text(l.assignCouldNot('$e'))));
    }
  }

  Future<void> _deleteQuestion(
      BuildContext context, QuestionBankItem item) async {
    final l = context.l10n;
    final ok = await _confirm(
      context,
      title: l.bankSheetRemoveQuestionTitle,
      body: l.bankSheetRemoveQuestionBody,
    );
    if (ok && context.mounted) {
      await context.read<FirestoreService>().deleteQuestionBankItem(item.id);
    }
  }

  Future<void> _deleteSheet(
      BuildContext context, QuestionBankSheet sheet) async {
    final l = context.l10n;
    final ok = await _confirm(
      context,
      title: l.bankSheetDeleteSheetTitle(sheet.code),
      body: l.bankSheetDeleteSheetBody(
        QuestionBankText.questionCount(l, sheet.count),
      ),
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
    final l = context.l10n;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
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
    return result ?? false;
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.sheet});
  final QuestionBankSheet sheet;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final facts = [
      sheet.code,
      sheet.category.localized(l),
      sheet.type.localized(l),
      if (sheet.level != null && sheet.level!.isNotEmpty) sheet.level!,
      QuestionBankText.questionCount(l, sheet.count),
      if (sheet.sections.isNotEmpty) l.bankSheetParts(sheet.sections.length),
      if (sheet.usageCount > 0) l.bankSheetUsedTimes(sheet.usageCount),
    ];
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.description_outlined, color: AppColors.navy, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sheet.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  facts.join(' · '),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                if (sheet.tags.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    sheet.tags.map((t) => '#$t').join('  '),
                    style: TextStyle(fontSize: 13, color: AppColors.navy),
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
    this.sectionHeading,
    required this.onTap,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onDelete,
    this.readOnly = false,
  });

  final int index;
  final QuestionBankItem item;

  /// Shown above the row when this question opens a new part of the paper.
  final String? sectionHeading;
  final VoidCallback onTap;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback onDelete;

  /// Teachers read the sheet: no edit, move or delete controls.
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final card = AppCard(
      onTap: readOnly ? null : onTap,
      padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '${index + 1}.',
              style: TextStyle(
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
                  item.displayText.isEmpty
                      ? l.bankSheetNoPrompt
                      : item.displayText,
                  style: AppTextStyles.question.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  QuestionBankText.answerLine(l, item),
                  style: AppTextStyles.questionDetail,
                ),
                if (item.question.imageUrl.isNotEmpty ||
                    item.question.optionImageUrls.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: QuestionPictures(question: item.question, height: 96),
                  ),
              ],
            ),
          ),
          if (!readOnly) ...[
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_up),
                  tooltip: l.packageFormMoveUp,
                  visualDensity: VisualDensity.compact,
                  onPressed: onMoveUp,
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down),
                  tooltip: l.packageFormMoveDown,
                  visualDensity: VisualDensity.compact,
                  onPressed: onMoveDown,
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: l.bankSheetEditQuestion,
              onPressed: onTap,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: AppColors.error),
              tooltip: l.bankSheetRemoveFromSheet,
              onPressed: onDelete,
            ),
          ],
        ],
      ),
    );
    final heading = sectionHeading;
    if (heading == null) return card;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
          child: Text(
            heading,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
              fontSize: 15,
            ),
          ),
        ),
        card,
      ],
    );
  }
}

/// The recording of the listening part: upload, replace or remove. Shown
/// for every sheet (a plain worksheet can carry one too).
class _ListeningAudioCard extends StatelessWidget {
  const _ListeningAudioCard({
    required this.sheet,
    required this.readOnly,
    required this.onUpload,
    required this.onRemove,
  });

  final QuestionBankSheet sheet;

  /// Teachers see whether a recording is attached but cannot change it.
  final bool readOnly;
  final VoidCallback onUpload;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final url = sheet.sectionAudioUrl;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Row(
        children: [
          Icon(Icons.headphones_outlined, color: AppColors.navy),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.bankSheetListeningAudio,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  url == null
                      ? l.bankSheetListeningAudioHelp
                      : l.bankSheetAudioAttached,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (!readOnly) ...[
            OutlinedButton.icon(
              onPressed: onUpload,
              icon: const Icon(Icons.upload_file_outlined, size: 18),
              label: Text(url == null
                  ? l.bankSheetUploadAudio
                  : l.bankSheetReplaceAudio),
            ),
            if (url != null)
              IconButton(
                tooltip: l.bankSheetRemoveAudio,
                onPressed: onRemove,
                icon: Icon(Icons.close, color: AppColors.error),
              ),
          ],
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
    required this.category,
  });
  final String title;
  final ExerciseType type;
  final String? level;
  final ExerciseSkillCategory skill;
  final ExerciseCategory category;
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
  late ExerciseCategory _category = widget.sheet.category;

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
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.bankSheetEditSheet),
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
                labelText: l.packageFormTitle,
                helperText: l.bankSheetCodeStays(widget.sheet.code),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ExerciseCategory>(
              initialValue: _category,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l.bankFiltersTypeOfExercise,
                helperText: l.bankSheetCategoryHelper,
              ),
              items: [
                for (final c in ExerciseCategory.values)
                  DropdownMenuItem(value: c, child: Text(c.localized(l))),
              ],
              onChanged: (c) => setState(() => _category = c ?? _category),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ExerciseType>(
              initialValue: _type,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l.bankFiltersQuestionType,
                helperText: _typeChangesShape
                    ? l.bankSheetTypeChangesShape
                    : l.bankSheetTypeAppliesAll,
                helperMaxLines: 3,
              ),
              items: [
                for (final t in ExerciseType.values)
                  DropdownMenuItem(value: t, child: Text(t.localized(l))),
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
                    decoration: InputDecoration(labelText: l.bankFiltersLevel),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('—')),
                      for (final level in AppConstants.hskLevels)
                        DropdownMenuItem(value: level, child: Text(level)),
                    ],
                    onChanged: (level) => setState(() => _level = level),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<ExerciseSkillCategory>(
                    initialValue: _skill,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: l.bankEditorSkill),
                    items: [
                      for (final c in ExerciseSkillCategory.values)
                        DropdownMenuItem(value: c, child: Text(c.localized(l))),
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
          child: Text(l.commonCancel),
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
                category: _category,
              ),
            );
          },
          child: Text(l.bankEditorSave),
        ),
      ],
    );
  }
}

/// How the paper was read and proofread (Build 1C, Must 6): the number for
/// the thesis test chapter. Admins only.
class _PaperRecordCard extends StatelessWidget {
  const _PaperRecordCard({required this.record});

  final PaperProofRecord record;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = record;
    final engine = switch (r.engine) {
      'paddle' => 'PaddleOCR',
      'tesseract' => 'Tesseract',
      _ => r.engine,
    };
    final minutes = (r.proofSeconds / 60).toStringAsFixed(1);
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.fact_check_outlined, color: AppColors.navy),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.paperRecordTitle,
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy)),
                const SizedBox(height: 4),
                Text(l.paperRecordLine(r.slots, r.flagged, r.changed, r.untouched, minutes)),
                Text(
                  l.paperRecordRead(engine.isEmpty ? '—' : engine, r.readSeconds),
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
