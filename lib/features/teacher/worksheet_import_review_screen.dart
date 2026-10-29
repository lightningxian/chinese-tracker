import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/question_import_utils.dart';
import '../../core/widgets/app_card.dart';
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

  @override
  void initState() {
    super.initState();
    _parsed = QuestionImportUtils.parseWorksheet(widget.extractedText);
    _selectedType = _parsed.suggestedType;
    _textController = TextEditingController(text: widget.extractedText);
    _instructionsController =
        TextEditingController(text: _parsed.instructions);
  }

  @override
  void dispose() {
    _textController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _reanalyze() {
    setState(() {
      _parsed = QuestionImportUtils.parseWorksheet(_textController.text);
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
    final result =
        QuestionImportUtils.parseWorksheet(_textController.text.trim());
    final instructions = _instructionsController.text.trim();
    return WorksheetParseResult(
      instructions:
          instructions.isNotEmpty ? instructions : result.instructions,
      suggestedType: _selectedType,
      suggestedLevel: result.suggestedLevel,
      detectionSummary: result.detectionSummary,
      mcQuestions: result.mcQuestions,
      composeQuestions: result.composeQuestions,
      matchingOptions: result.matchingOptions,
      matchingQuestions: result.matchingQuestions,
      passage: result.passage,
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
    final isWide = MediaQuery.sizeOf(context).width >= 720;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Review import'),
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
                    style: const TextStyle(
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
                          const Icon(
                            Icons.auto_awesome,
                            size: 18,
                            color: AppColors.teal,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Detected format',
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
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                      if (_parsed.suggestedLevel != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Suggested level: ${_parsed.suggestedLevel}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
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
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: AppColors.error, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'This exercise type is not fully supported yet. '
                            'You can still copy instructions or edit the text.',
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
            decoration: const BoxDecoration(
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
                    child: const Text('Instructions only'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () =>
                        _pop(WorksheetImportReviewAction.cancel),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed:
                        _canImport ? () => _pop(WorksheetImportReviewAction.importQuestions) : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    child: Text(
                      _previewCount > 0
                          ? 'Import $_previewCount question${_previewCount == 1 ? '' : 's'}'
                          : 'Import questions',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<ExerciseType>(
          value: _selectedType,
          decoration: const InputDecoration(
            labelText: 'Exercise type',
            isDense: true,
          ),
          items: ExerciseType.values
              .map(
                (type) => DropdownMenuItem(
                  value: type,
                  child: Text(type.label),
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
          decoration: const InputDecoration(
            labelText: 'Instructions (optional)',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _textController,
          minLines: 8,
          maxLines: 14,
          decoration: const InputDecoration(
            labelText: 'Extracted text',
            hintText: 'Edit if OCR misread anything…',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _reanalyze,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Re-analyze'),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewColumn() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedType == ExerciseType.composeSentences
                ? 'Sentence preview'
                : 'Question preview',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 12),
          if (_previewCount == 0)
            const Text(
              'No questions detected yet. Edit the text and tap Re-analyze.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            )
          else
            ...List.generate(_previewCount.clamp(0, 5), _buildPreviewItem),
          if (_previewCount > 5)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '…and ${_previewCount - 5} more',
                style: const TextStyle(
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
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          '${index + 1}. ${question.segments.join(' / ')}',
          style: const TextStyle(fontSize: 13, height: 1.35),
        ),
      );
    }
    if (_selectedType == ExerciseType.matching ||
        _selectedType == ExerciseType.readingCloze) {
      final question = _parsed.matchingQuestions[index];
      final letter = String.fromCharCode(65 + question.correctIndex);
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          '${index + 1}. ${question.prompt} → $letter',
          style: const TextStyle(fontSize: 13, height: 1.35),
        ),
      );
    }
    final question = _parsed.mcQuestions[index];
    final optionPreview = switch (_selectedType) {
      ExerciseType.typeHanzi =>
        'pinyin: ${question.keyword} → ${question.options.isEmpty ? '(type the hanzi in the editor)' : question.options.join(' / ')}',
      ExerciseType.pictureSentence => 'keyword: ${question.keyword}',
      _ => question.options.isEmpty
          ? '(add options)'
          : question.options.take(3).join(' · '),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        '${index + 1}. ${question.prompt}\n   $optionPreview',
        style: const TextStyle(fontSize: 13, height: 1.35),
      ),
    );
  }
}
