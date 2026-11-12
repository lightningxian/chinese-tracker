import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/l10n.dart';
import '../../l10n/labels_exercises.dart';
import '../../models/exercise.dart';
import '../../models/exercise_category.dart';
import '../../models/exercise_skill_category.dart';
import '../../models/exercise_type.dart';
import '../../models/question_bank_item.dart';
import '../../services/firestore_service.dart';
import '../../services/question_bank_media_service.dart';

/// Opens the question editor as a bottom sheet. [existing] edits that
/// question; [sheet] adds a new question to that worksheet (type, level, skill
/// and tags start from the sheet and the question goes last).
Future<void> showQuestionBankEditor(
  BuildContext context, {
  required String ownerId,
  QuestionBankItem? existing,
  QuestionBankSheet? sheet,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.card,
    constraints: const BoxConstraints(maxWidth: 760),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => QuestionBankEditorSheet(
      ownerId: ownerId,
      existing: existing,
      sheet: sheet,
    ),
  );
}

/// Create or edit one bank question. The fields follow the type:
/// choices with one correct answer, a shared word bank for matching and fill
/// in the blank, sentence parts for compose, a pinyin hint with accepted
/// answers for type the hanzi, the required word for picture sentences.
class QuestionBankEditorSheet extends StatefulWidget {
  const QuestionBankEditorSheet({
    super.key,
    required this.ownerId,
    this.existing,
    this.sheet,
  });

  final String ownerId;
  final QuestionBankItem? existing;

  /// Worksheet a new question is added to (ignored when [existing] is set).
  final QuestionBankSheet? sheet;

  @override
  State<QuestionBankEditorSheet> createState() =>
      _QuestionBankEditorSheetState();
}

class _QuestionBankEditorSheetState extends State<QuestionBankEditorSheet> {
  static const _maxOptions = 6;

  final _formKey = GlobalKey<FormState>();
  final _promptController = TextEditingController();
  final _tagsController = TextEditingController();
  final _keywordController = TextEditingController();
  final _blankController = TextEditingController();
  final _explanationController = TextEditingController();

  /// Multiple choice / listening: one controller per choice.
  final List<TextEditingController> _optionControllers = [];

  /// One entry per line: word bank (matching, fill in the blank), accepted
  /// answers (type the hanzi) or sentence parts (compose).
  final _linesController = TextEditingController();

  ExerciseType _type = ExerciseType.multipleChoice;
  ExerciseSkillCategory _skill = ExerciseSkillCategory.reading;
  ExerciseCategory _category = ExerciseCategory.exercise;
  String _level = AppConstants.hskLevels.first;
  int _correctIndex = 0;
  String _imageUrl = '';
  String _audioUrl = '';
  bool _saving = false;
  bool _uploadingMedia = false;

  bool get _isEditing => widget.existing != null;
  bool get _usesWordBank =>
      _type == ExerciseType.matching || _type == ExerciseType.readingCloze;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final sheetFirst = widget.sheet?.first;
    if (e != null) {
      _loadQuestion(e);
    } else if (sheetFirst != null) {
      _type = sheetFirst.type;
      _skill = sheetFirst.skillCategory ??
          ExerciseSkillCategory.forExerciseType(_type);
      _level = sheetFirst.level ?? AppConstants.hskLevels.first;
      _category = sheetFirst.category;
      _tagsController.text = widget.sheet!.tags.join(', ');
      // Matching and fill in the blank share one word bank per sheet.
      if (_usesWordBank) {
        _linesController.text = sheetFirst.question.options.join('\n');
      }
    }
    _ensureOptionControllers();
  }

  void _loadQuestion(QuestionBankItem e) {
    _type = e.type;
    _skill = e.skillCategory ?? ExerciseSkillCategory.forExerciseType(e.type);
    _level = e.level ?? AppConstants.hskLevels.first;
    _category = e.category;
    _tagsController.text = e.tags.join(', ');
    _promptController.text = e.question.prompt;
    _correctIndex = e.question.correctIndex;
    _imageUrl = e.question.imageUrl;
    _audioUrl = e.question.audioUrl;
    _keywordController.text = e.question.keyword;
    _blankController.text = e.question.blankNumber?.toString() ?? '';
    _explanationController.text = e.question.explanation;
    switch (e.type) {
      case ExerciseType.composeSentences:
        _linesController.text = e.question.segments.join('\n');
      case ExerciseType.matching:
      case ExerciseType.readingCloze:
      case ExerciseType.typeHanzi:
        _linesController.text = e.question.options.join('\n');
      case ExerciseType.multipleChoice:
      case ExerciseType.listening:
        for (final o in e.question.options) {
          _optionControllers.add(TextEditingController(text: o));
        }
      case ExerciseType.pictureSentence:
        break;
    }
  }

  /// Choice questions start with four empty choices, never fewer than two.
  void _ensureOptionControllers() {
    final target = _optionControllers.isEmpty ? 4 : 2;
    while (_optionControllers.length < target) {
      _optionControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    _tagsController.dispose();
    _keywordController.dispose();
    _blankController.dispose();
    _explanationController.dispose();
    _linesController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _lines => _linesController.text
      .split('\n')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  static bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  ExerciseQuestion _buildQuestion() {
    final prompt = _promptController.text.trim();
    final keyword = _keywordController.text.trim();
    final explanation = _explanationController.text.trim();
    switch (_type) {
      case ExerciseType.composeSentences:
        return ExerciseQuestion(
          prompt: prompt,
          explanation: explanation,
          segments: _lines,
          imageUrl: _imageUrl,
          audioUrl: _audioUrl,
        );
      case ExerciseType.matching:
      case ExerciseType.readingCloze:
        final bank = _lines;
        return ExerciseQuestion(
          prompt: prompt,
          explanation: explanation,
          options: bank,
          correctIndex:
              bank.isEmpty ? 0 : _correctIndex.clamp(0, bank.length - 1),
          blankNumber: _type == ExerciseType.readingCloze
              ? int.tryParse(_blankController.text.trim())
              : null,
          imageUrl: _imageUrl,
          audioUrl: _audioUrl,
        );
      case ExerciseType.typeHanzi:
        return ExerciseQuestion(
          prompt: prompt,
          explanation: explanation,
          keyword: keyword,
          options: _lines,
          imageUrl: _imageUrl,
          audioUrl: _audioUrl,
        );
      case ExerciseType.pictureSentence:
        return ExerciseQuestion(
          prompt: prompt,
          explanation: explanation,
          keyword: keyword,
          imageUrl: _imageUrl,
          audioUrl: _audioUrl,
        );
      case ExerciseType.multipleChoice:
      case ExerciseType.listening:
        final options = _optionControllers
            .map((c) => c.text.trim())
            .where((o) => o.isNotEmpty)
            .toList();
        return ExerciseQuestion(
          prompt: prompt,
          explanation: explanation,
          options: options,
          correctIndex:
              options.isEmpty ? 0 : _correctIndex.clamp(0, options.length - 1),
          imageUrl: _imageUrl,
          audioUrl: _audioUrl,
        );
    }
  }

  /// Null when the question is complete, else what is missing.
  String? _validate(AppLocalizations l, ExerciseQuestion q) {
    switch (_type) {
      case ExerciseType.composeSentences:
        if (q.segments.length < 2) return l.bankEditorNeedTwoParts;
      case ExerciseType.matching:
      case ExerciseType.readingCloze:
        if (q.prompt.isEmpty) return l.bankEditorEnterQuestion;
        if (q.options.length < 2) return l.bankEditorNeedTwoWords;
      case ExerciseType.typeHanzi:
        if (q.keyword.isEmpty) return l.bankEditorEnterPinyin;
        if (q.acceptedAnswers.isEmpty) return l.bankEditorNeedAccepted;
      case ExerciseType.pictureSentence:
        if (q.keyword.isEmpty) return l.bankEditorEnterKeyword;
      case ExerciseType.multipleChoice:
      case ExerciseType.listening:
        if (q.prompt.isEmpty) return l.bankEditorEnterQuestion;
        if (q.options.length < 2) return l.bankEditorNeedTwoChoices;
        if (_optionControllers[_correctIndex].text.trim().isEmpty) {
          return l.bankEditorCorrectEmpty;
        }
    }
    return null;
  }

  Future<void> _uploadMedia({required bool image}) async {
    setState(() => _uploadingMedia = true);
    try {
      final service = context.read<QuestionBankMediaService>();
      final url = image
          ? await service.pickAndUploadImage(widget.ownerId)
          : await service.pickAndUploadAudio(widget.ownerId);
      setState(() {
        if (image) {
          _imageUrl = url;
        } else {
          _audioUrl = url;
        }
      });
    } on QuestionBankMediaCancelledException {
      // user cancelled
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.bankEditorUploadFailed('$e'))),
      );
    } finally {
      if (mounted) setState(() => _uploadingMedia = false);
    }
  }

  Future<void> _save() async {
    final l = context.l10n;
    final question = _buildQuestion();
    final problem = _validate(l, question);
    if (problem != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(problem)));
      return;
    }
    setState(() => _saving = true);

    final firestore = context.read<FirestoreService>();
    final navigator = Navigator.of(context);
    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final existing = widget.existing;
    final sheet = widget.sheet;
    final nextIndex = sheet == null
        ? null
        : sheet.items
                .map((i) => i.sheetIndex ?? -1)
                .fold(-1, (a, b) => a > b ? a : b) +
            1;

    final item = QuestionBankItem(
      id: existing?.id ?? '',
      ownerId: widget.ownerId,
      type: _type,
      question: question,
      skillCategory: _skill,
      level: _level,
      category: _category,
      tags: tags,
      sheetCode: existing?.sheetCode ?? sheet?.key,
      sheetTitle: existing?.sheetTitle ?? sheet?.title,
      sheetIndex: existing?.sheetIndex ?? nextIndex,
      usageCount: existing?.usageCount ?? 0,
      lastUsedAt: existing?.lastUsedAt,
      sourceExerciseId: existing?.sourceExerciseId,
    );

    try {
      if (_isEditing) {
        await firestore.updateQuestionBankItem(item);
      } else {
        await firestore.createQuestionBankItem(item);
      }
      // The word bank is one list per worksheet: copy it to the siblings
      // that still hold an older version.
      if (_usesWordBank && sheet != null) {
        final stale = [
          for (final s in sheet.items)
            if (s.id != existing?.id &&
                !_sameList(s.question.options, question.options))
              s.id,
        ];
        if (stale.isNotEmpty) {
          await firestore.updateQuestionBankSheet(stale,
              wordBank: question.options);
        }
      }
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.bankEditorCouldNotSave('$e'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final sheet = widget.sheet;
    final heading = _isEditing
        ? l.bankSheetEditQuestion
        : sheet != null
            ? l.bankEditorAddToSheetTitle(sheet.title)
            : l.bankEditorNewQuestion;
    return Padding(
      padding: EdgeInsets.only(
          left: 20, right: 20, top: 20, bottom: 20 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                heading,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ExerciseType>(
                initialValue: _type,
                isExpanded: true,
                decoration: InputDecoration(labelText: l.bankImportType),
                items: [
                  for (final t in ExerciseType.values)
                    DropdownMenuItem(value: t, child: Text(t.localized(l))),
                ],
                onChanged: (t) => setState(() {
                  _type = t ?? ExerciseType.multipleChoice;
                  _skill = ExerciseSkillCategory.forExerciseType(_type);
                  _ensureOptionControllers();
                }),
              ),
              const SizedBox(height: 12),
              ..._buildTypeFields(),
              const SizedBox(height: 12),
              TextFormField(
                controller: _explanationController,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: l.bankEditorExplanationOptional,
                  helperText: l.bankEditorExplanationHelper,
                  helperMaxLines: 2,
                ),
              ),
              const SizedBox(height: 12),
              _MediaRow(
                imageUrl: _imageUrl,
                audioUrl: _audioUrl,
                uploading: _uploadingMedia,
                onUploadImage: () => _uploadMedia(image: true),
                onUploadAudio: () => _uploadMedia(image: false),
                onClearImage: () => setState(() => _imageUrl = ''),
                onClearAudio: () => setState(() => _audioUrl = ''),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _level,
                      isExpanded: true,
                      decoration:
                          InputDecoration(labelText: l.bankFiltersLevel),
                      items: [
                        for (final level in AppConstants.hskLevels)
                          DropdownMenuItem(value: level, child: Text(level)),
                      ],
                      onChanged: (level) => setState(
                          () => _level = level ?? AppConstants.hskLevels.first),
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
                          DropdownMenuItem(
                              value: c, child: Text(c.localized(l))),
                      ],
                      onChanged: (c) => setState(
                          () => _skill = c ?? ExerciseSkillCategory.reading),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ExerciseCategory>(
                initialValue: _category,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l.bankFiltersTypeOfExercise,
                ),
                items: [
                  for (final c in ExerciseCategory.values)
                    DropdownMenuItem(value: c, child: Text(c.localized(l))),
                ],
                onChanged: (c) => setState(() => _category = c ?? _category),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isEditing
                          ? l.bankEditorSave
                          : sheet != null
                              ? l.bankEditorAddToWorksheet
                              : l.bankEditorAddToBank),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _prompt(
      {required String label, String? helper, bool optional = false}) {
    return TextFormField(
      controller: _promptController,
      style: AppTextStyles.question,
      minLines: 1,
      maxLines: 4,
      decoration: InputDecoration(
        labelText:
            optional ? context.l10n.bankEditorOptionalSuffix(label) : label,
        helperText: helper,
        helperMaxLines: 2,
      ),
    );
  }

  Widget _linesField({required String label, required String helper}) {
    return TextFormField(
      controller: _linesController,
      style: AppTextStyles.question,
      minLines: 3,
      maxLines: 10,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        helperMaxLines: 3,
        alignLabelWithHint: true,
      ),
    );
  }

  List<Widget> _buildTypeFields() {
    final l = context.l10n;
    switch (_type) {
      case ExerciseType.multipleChoice:
      case ExerciseType.listening:
        return [
          _prompt(
            label: l.bankEditorQuestion,
            helper: _type == ExerciseType.listening
                ? l.bankEditorListeningHelper
                : null,
          ),
          const SizedBox(height: 12),
          Text(l.bankEditorChoicesTick,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          ..._buildChoiceFields(),
        ];
      case ExerciseType.matching:
      case ExerciseType.readingCloze:
        final bank = _lines;
        final isCloze = _type == ExerciseType.readingCloze;
        return [
          _prompt(
            label: isCloze
                ? l.bankEditorSentenceWithBlank
                : l.bankEditorQuestionOrLine,
            helper:
                isCloze ? l.bankEditorClozeHelper : l.bankEditorMatchingHelper,
          ),
          const SizedBox(height: 12),
          _linesField(
            label: l.bankEditorWordBank,
            helper: l.bankEditorWordBankHelper,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  // Rebuilds when the bank changes so the key stays valid.
                  key: ValueKey('correct-${bank.length}'),
                  initialValue: bank.isEmpty
                      ? null
                      : _correctIndex.clamp(0, bank.length - 1),
                  isExpanded: true,
                  decoration:
                      InputDecoration(labelText: l.bankEditorCorrectAnswer),
                  items: [
                    for (final (i, w) in bank.indexed)
                      DropdownMenuItem(
                        value: i,
                        child: Text(
                          '${String.fromCharCode(65 + i)}. $w',
                          style: const TextStyle(
                            fontFamilyFallback: [AppTextStyles.chineseFamily],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => _correctIndex = v ?? 0),
                ),
              ),
              if (isCloze) ...[
                const SizedBox(width: 10),
                SizedBox(
                  width: 110,
                  child: TextFormField(
                    controller: _blankController,
                    keyboardType: TextInputType.number,
                    decoration:
                        InputDecoration(labelText: l.bankEditorBlankNumber),
                  ),
                ),
              ],
            ],
          ),
        ];
      case ExerciseType.composeSentences:
        return [
          _linesField(
            label: l.bankEditorSentenceParts,
            helper: l.bankEditorSentencePartsHelper,
          ),
          const SizedBox(height: 12),
          _prompt(label: l.bankEditorInstruction, optional: true),
        ];
      case ExerciseType.typeHanzi:
        return [
          TextFormField(
            controller: _keywordController,
            style: AppTextStyles.question,
            decoration: InputDecoration(
              labelText: l.bankEditorPinyinHint,
              helperText: l.bankEditorPinyinHelper,
            ),
          ),
          const SizedBox(height: 12),
          _linesField(
            label: l.bankEditorAcceptedAnswers,
            helper: l.bankEditorAcceptedHelper,
          ),
          const SizedBox(height: 12),
          _prompt(label: l.bankEditorInstruction, optional: true),
        ];
      case ExerciseType.pictureSentence:
        return [
          TextFormField(
            controller: _keywordController,
            style: AppTextStyles.question,
            decoration: InputDecoration(
              labelText: l.bankEditorKeywordLabel,
              helperText: l.bankEditorKeywordHelper,
            ),
          ),
          const SizedBox(height: 12),
          _prompt(label: l.bankEditorInstruction, optional: true),
        ];
    }
  }

  List<Widget> _buildChoiceFields() {
    final l = context.l10n;
    return [
      for (var i = 0; i < _optionControllers.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Radio<int>(
                value: i,
                groupValue: _correctIndex,
                onChanged: (v) => setState(() => _correctIndex = v ?? 0),
              ),
              Expanded(
                child: TextFormField(
                  controller: _optionControllers[i],
                  style: AppTextStyles.question,
                  decoration: InputDecoration(
                    labelText: l.bankEditorChoice(String.fromCharCode(65 + i)),
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                tooltip: l.bankEditorRemoveChoice,
                icon: const Icon(Icons.close, size: 18),
                onPressed: _optionControllers.length <= 2
                    ? null
                    : () => setState(() {
                          _optionControllers.removeAt(i).dispose();
                          if (_correctIndex >= _optionControllers.length) {
                            _correctIndex = _optionControllers.length - 1;
                          }
                        }),
              ),
            ],
          ),
        ),
      if (_optionControllers.length < _maxOptions)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () =>
                setState(() => _optionControllers.add(TextEditingController())),
            icon: const Icon(Icons.add, size: 18),
            label: Text(l.bankEditorAddChoice),
          ),
        ),
    ];
  }
}

class _MediaRow extends StatelessWidget {
  const _MediaRow({
    required this.imageUrl,
    required this.audioUrl,
    required this.uploading,
    required this.onUploadImage,
    required this.onUploadAudio,
    required this.onClearImage,
    required this.onClearAudio,
  });

  final String imageUrl;
  final String audioUrl;
  final bool uploading;
  final VoidCallback onUploadImage;
  final VoidCallback onUploadAudio;
  final VoidCallback onClearImage;
  final VoidCallback onClearAudio;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.bankEditorMediaOptional,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: uploading ? null : onUploadImage,
              icon: const Icon(Icons.image_outlined, size: 18),
              label: Text(imageUrl.isEmpty
                  ? l.bankEditorAddImage
                  : l.bankEditorImageAttached),
            ),
            if (imageUrl.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onClearImage,
              ),
            OutlinedButton.icon(
              onPressed: uploading ? null : onUploadAudio,
              icon: const Icon(Icons.audiotrack_outlined, size: 18),
              label: Text(audioUrl.isEmpty
                  ? l.bankEditorAddAudio
                  : l.bankEditorAudioAttached),
            ),
            if (audioUrl.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onClearAudio,
              ),
          ],
        ),
        if (imageUrl.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Image.network(imageUrl, height: 80, fit: BoxFit.contain),
          ),
      ],
    );
  }
}
