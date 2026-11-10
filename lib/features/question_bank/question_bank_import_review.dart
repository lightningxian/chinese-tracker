import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../models/exercise_category.dart';
import '../../models/question_bank_item.dart';
import 'question_bank_text.dart';

/// What the admin decided on the review screen: the questions to add and,
/// when the same worksheet was already in the bank and they chose to replace
/// it, the ids of the old questions to delete first.
class QuestionBankImportDecision {
  const QuestionBankImportDecision({
    required this.items,
    this.replaceIds = const [],
  });

  final List<QuestionBankItem> items;
  final List<String> replaceIds;
}

/// Last check before questions enter the bank: every detected question with
/// its type and the answer the scanner read. Untick anything wrong, set the
/// level for the whole batch, then add. A scanned worksheet is added as one
/// sheet (its questions keep the sheet code and order); if that sheet is
/// already in the bank the admin can replace it instead of adding a copy.
class QuestionBankImportReviewScreen extends StatefulWidget {
  const QuestionBankImportReviewScreen({
    super.key,
    required this.items,
    required this.summary,
    this.existingBank = const [],
  });

  final List<QuestionBankItem> items;

  /// The scanner's one-line verdict, e.g. "Detected R1 fill in the blank …".
  final String summary;

  /// What is in the bank now, to spot a worksheet being imported twice.
  final List<QuestionBankItem> existingBank;

  @override
  State<QuestionBankImportReviewScreen> createState() =>
      _QuestionBankImportReviewScreenState();
}

class _QuestionBankImportReviewScreenState
    extends State<QuestionBankImportReviewScreen> {
  late final List<bool> _keep = List.filled(widget.items.length, true);
  late String _level =
      widget.items.firstOrNull?.level ?? AppConstants.hskLevels.first;

  int get _kept => _keep.where((k) => k).length;

  /// Several sheets of different levels in one batch (the sample set): each
  /// keeps its own level and the level picker is hidden.
  bool get _mixedLevels => widget.items.map((i) => i.level).toSet().length > 1;

  /// The one worksheet these questions come from, if they all share it.
  late final QuestionBankSheet? _sheet = () {
    final sheets = QuestionBankSheet.group(widget.items);
    return sheets.length == 1 && sheets.first.isSheet ? sheets.first : null;
  }();

  /// Questions of the same worksheet already in the bank.
  late final List<QuestionBankItem> _existingSame = switch (_sheet) {
    null => const [],
    final sheet =>
      widget.existingBank.where((i) => i.sheetKey == sheet.key).toList(),
  };

  bool _replaceExisting = true;
  ExerciseCategory _category = ExerciseCategory.exercise;

  QuestionBankImportDecision _result() => QuestionBankImportDecision(
        items: [
          for (var i = 0; i < widget.items.length; i++)
            if (_keep[i])
              (_mixedLevels
                      ? widget.items[i]
                      : widget.items[i].copyWith(level: _level))
                  .copyWith(category: _category),
        ],
        replaceIds:
            _replaceExisting ? [for (final i in _existingSame) i.id] : const [],
      );

  @override
  Widget build(BuildContext context) {
    final sheet = _sheet;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Check before adding'),
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.navy,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (sheet != null) ...[
                    Row(
                      children: [
                        Icon(Icons.description_outlined,
                            color: AppColors.navy, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Worksheet ${sheet.code}'
                            '${sheet.title != sheet.code ? ' · ${sheet.title}' : ''}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppColors.navy,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Added to the bank as one worksheet. Untick a question '
                      'to leave it out.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    if (_existingSame.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
                        decoration: BoxDecoration(
                          color: AppColors.accentSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 20, color: AppColors.chipAmberFg),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'This worksheet is already in the bank with '
                                '${QuestionBankText.questionCount(_existingSame.length)}.',
                                style: const TextStyle(height: 1.4),
                              ),
                            ),
                            Switch(
                              value: _replaceExisting,
                              onChanged: (v) =>
                                  setState(() => _replaceExisting = v),
                            ),
                            Text(
                              _replaceExisting ? 'Replace it' : 'Keep both',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                  ],
                  Text(
                    widget.summary,
                    style: const TextStyle(height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      if (!_mixedLevels)
                        SizedBox(
                          width: 220,
                          child: DropdownButtonFormField<String>(
                            initialValue: _level,
                            decoration: const InputDecoration(
                              labelText: 'HSK level',
                              isDense: true,
                            ),
                            items: [
                              for (final l in AppConstants.hskLevels)
                                DropdownMenuItem(value: l, child: Text(l)),
                            ],
                            onChanged: (v) =>
                                setState(() => _level = v ?? _level),
                          ),
                        ),
                      SizedBox(
                        width: 220,
                        child: DropdownButtonFormField<ExerciseCategory>(
                          initialValue: _category,
                          decoration: const InputDecoration(
                            labelText: 'Type of exercise',
                            isDense: true,
                          ),
                          items: [
                            for (final c in ExerciseCategory.values)
                              DropdownMenuItem(value: c, child: Text(c.label)),
                          ],
                          onChanged: (v) =>
                              setState(() => _category = v ?? _category),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              itemCount: widget.items.length,
              itemBuilder: (context, i) {
                final item = widget.items[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    padding: const EdgeInsets.fromLTRB(8, 12, 20, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _keep[i],
                          onChanged: (v) =>
                              setState(() => _keep[i] = v ?? true),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '${i + 1}.',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentSoft,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item.type.label,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.navy,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.displayText,
                                style: AppTextStyles.question.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: _keep[i]
                                      ? AppColors.navy
                                      : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                QuestionBankText.answerLine(item),
                                style: AppTextStyles.questionDetail,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed:
                    _kept == 0 ? null : () => Navigator.pop(context, _result()),
                icon: const Icon(Icons.library_add_outlined, size: 18),
                label: Text(
                  sheet != null
                      ? '${_existingSame.isNotEmpty && _replaceExisting ? 'Replace' : 'Add'} '
                          'worksheet (${QuestionBankText.questionCount(_kept)})'
                      : 'Add $_kept to bank',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
