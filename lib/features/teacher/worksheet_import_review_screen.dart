import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/question_import_utils.dart';
import '../../core/utils/worksheet_answer_keys.dart';
import '../../core/widgets/app_card.dart';
import '../../l10n/l10n.dart';
import '../../l10n/labels_exercises.dart';
import '../../models/exercise_type.dart';

enum WorksheetImportReviewAction { cancel, instructionsOnly, importQuestions }

class WorksheetImportReviewResult {
  const WorksheetImportReviewResult({
    required this.action,
    this.instructions = '',
    this.selectedType,
    this.parseResult,
  });

  final WorksheetImportReviewAction action;
  final String instructions;
  final ExerciseType? selectedType;
  final WorksheetParseResult? parseResult;
}

/// Full-screen D3 import review aligned with Figma Make.
class WorksheetImportReviewScreen extends StatefulWidget {
  const WorksheetImportReviewScreen({
    super.key,
    required this.extractedText,
    this.fileName,
  });

  final String extractedText;
  final String? fileName;

  @override
  State<WorksheetImportReviewScreen> createState() =>
      _WorksheetImportReviewScreenState();
}

class _WorksheetImportReviewScreenState
    extends State<WorksheetImportReviewScreen> {
  late TextEditingController _textController;
  late TextEditingController _instructionsController;
  late WorksheetParseResult _parsed;
  late ExerciseType _selectedType;

  /// Keys for the centre's own sheets; null until the bundled set is loaded.
  WorksheetAnswerKeys? _keys;
  int _keyedAnswers = 0;

  @override
  void initState() {
    super.initState();
    _parsed = _parse(widget.extractedText);
    _selectedType = _parsed.suggestedType;
    _textController = TextEditingController(text: widget.extractedText);
    _instructionsController = TextEditingController(text: _parsed.instructions);
    WorksheetAnswerKeys.loadBundled().then((keys) {
      if (!mounted) return;
      setState(() {
        _keys = keys;
        _parsed = _parse(_textController.text);
      });
    }).catchError((_) {
      // Without the sample set the scan still works, just unkeyed.
    });
  }

  /// Parse the text and, when the sheet is one of the centre's keyed sheets,
  /// fill in its answers.
  WorksheetParseResult _parse(String text) {
    final parsed = QuestionImportUtils.parseWorksheet(text);
    final keys = _keys;
    if (keys == null) {
      _keyedAnswers = 0;
      return parsed;
    }
    final keyed = keys.apply(parsed);
    _keyedAnswers = keyed.applied;
    return keyed.result;
  }

  /// Whether the admin has to supply answers for this type of question.
  bool get _needsAnswers => _selectedType != ExerciseType.pictureSentence;

  String? _answerKeyNote(AppLocalizations l) {
    if (_previewCount == 0 || !_needsAnswers) return null;
    if (_keyedAnswers > 0) {
      final code = _parsed.sheetCode;
      return code == null
          ? l.worksheetAnswerKeyFilled(_keyedAnswers, _previewCount)
          : l.worksheetAnswerKeyFilledCode(_keyedAnswers, _previewCount, code);
    }
    return switch (_selectedType) {
      ExerciseType.composeSentences => l.worksheetNoKeyCompose,
      ExerciseType.typeHanzi => l.worksheetNoKeyTypeHanzi,
      _ => l.worksheetNoKeyDefault,
    };
  }

  @override
  void dispose() {
    _textController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _reanalyze() {
    setState(() {
      _parsed = _parse(_textController.text);
      _selectedType = _parsed.suggestedType;
      if (_instructionsController.text.trim().isEmpty &&
          _parsed.instructions.isNotEmpty) {
        _instructionsController.text = _parsed.instructions;
      }
    });
  }

  int get _previewCount => WorksheetParseResult.countFor(
        _selectedType,
        mc: _parsed.mcQuestions.length,
        compose: _parsed.composeQuestions.length,
        bank: _parsed.matchingQuestions.length,
      );

  bool get _canImport => _selectedType.isImplemented && _previewCount > 0;

  WorksheetParseResult _buildFinalParseResult() {
    final result = _parse(_textController.text.trim());
    final instructions = _instructionsController.text.trim();
    return result.copyWith(
      instructions:
          instructions.isNotEmpty ? instructions : result.instructions,
      suggestedType: _selectedType,
    );
  }

  void _pop(WorksheetImportReviewAction action) {
    Navigator.pop(
      context,
      WorksheetImportReviewResult(
        action: action,
        instructions: _instructionsController.text.trim(),
        selectedType: _selectedType,
        parseResult: action == WorksheetImportReviewAction.importQuestions
            ? _buildFinalParseResult()
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final isWide = MediaQuery.sizeOf(context).width >= 720;
    final answerKeyNote = _answerKeyNote(l);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(l.worksheetReviewTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _pop(WorksheetImportReviewAction.cancel),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              children: [
                if (widget.fileName != null) ...[
                  Text(
                    widget.fileName!,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.teal.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 18,
                            color: AppColors.teal,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l.worksheetDetectedFormat,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _parsed.detectionSummary,
                        style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                      if (_parsed.suggestedLevel != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          l.worksheetSuggestedLevel(_parsed.suggestedLevel!),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (answerKeyNote != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _keyedAnswers > 0
                                  ? Icons.check_circle_outline
                                  : Icons.info_outline,
                              size: 16,
                              color: _keyedAnswers > 0
                                  ? AppColors.success
                                  : AppColors.brandYellow,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                answerKeyNote,
                                style: TextStyle(
                                  color: _keyedAnswers > 0
                                      ? AppColors.navy
                                      : AppColors.textSecondary,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (!_selectedType.isImplemented)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: AppColors.error, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l.worksheetTypeNotSupported,
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildEditorColumn()),
                      const SizedBox(width: 20),
                      Expanded(child: _buildPreviewColumn()),
                    ],
                  )
                else ...[
                  _buildEditorColumn(),
                  const SizedBox(height: 20),
                  _buildPreviewColumn(),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  TextButton(
                    onPressed: () =>
                        _pop(WorksheetImportReviewAction.instructionsOnly),
                    child: Text(l.worksheetInstructionsOnly),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _pop(WorksheetImportReviewAction.cancel),
                    child: Text(l.commonCancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _canImport
                        ? () =>
                            _pop(WorksheetImportReviewAction.importQuestions)
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    child: Text(
                      _previewCount > 0
                          ? l.worksheetImportCount(_previewCount)
                          : l.worksheetImportQuestions,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorColumn() {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<ExerciseType>(
          value: _selectedType,
          decoration: InputDecoration(
            labelText: l.worksheetExerciseType,
            isDense: true,
          ),
          items: ExerciseType.values
              .map(
                (type) => DropdownMenuItem(
                  value: type,
                  child: Text(type.localized(l)),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() => _selectedType = value);
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _instructionsController,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: l.packageFormInstructionsOptional,
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _textController,
          minLines: 8,
          maxLines: 14,
          style: AppTextStyles.question.copyWith(fontSize: 16),
          decoration: InputDecoration(
            labelText: l.worksheetExtractedText,
            hintText: l.worksheetEditIfMisread,
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _reanalyze,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(l.worksheetReanalyze),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewColumn() {
    final l = context.l10n;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedType == ExerciseType.composeSentences
                ? l.worksheetSentencePreview
                : l.worksheetQuestionPreview,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 12),
          if (_previewCount == 0)
            Text(
              l.worksheetNoQuestionsDetected,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            )
          else
            ...List.generate(_previewCount.clamp(0, 5), _buildPreviewItem),
          if (_previewCount > 5)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l.worksheetAndMore(_previewCount - 5),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreviewItem(int index) {
    if (_selectedType == ExerciseType.composeSentences) {
      final question = _parsed.composeQuestions[index];
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          '${index + 1}. ${question.segments.join(' / ')}',
          style: AppTextStyles.question,
        ),
      );
    }
    if (_selectedType == ExerciseType.matching ||
        _selectedType == ExerciseType.readingCloze) {
      final question = _parsed.matchingQuestions[index];
      final letter = String.fromCharCode(65 + question.correctIndex);
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          '${index + 1}. ${question.prompt} → $letter',
          style: AppTextStyles.question,
        ),
      );
    }
    final l = context.l10n;
    final question = _parsed.mcQuestions[index];
    final optionPreview = switch (_selectedType) {
      ExerciseType.typeHanzi => l.worksheetPreviewPinyin(
          question.keyword,
          question.options.isEmpty
              ? l.worksheetPreviewTypeInEditor
              : question.options.join(' / '),
        ),
      ExerciseType.pictureSentence =>
        l.worksheetPreviewKeyword(question.keyword),
      _ => question.options.isEmpty
          ? l.worksheetPreviewAddOptions
          : question.options.take(3).join(' · '),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text.rich(
        TextSpan(
          text: '${index + 1}. ${question.prompt}\n',
          children: [
            TextSpan(
              text: '   $optionPreview',
              style: AppTextStyles.questionDetail,
            ),
          ],
        ),
        style: AppTextStyles.question,
      ),
    );
  }
}
