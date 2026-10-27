import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../models/exercise_type.dart';
import '../../models/question_bank_item.dart';
import '../../models/question_difficulty.dart';

/// Last check before questions enter the bank: every detected question with
/// its type and the answer the scanner read. Untick anything wrong, set the
/// level and difficulty for the whole batch, then add.
class QuestionBankImportReviewScreen extends StatefulWidget {
  const QuestionBankImportReviewScreen({
    super.key,
    required this.items,
    required this.summary,
  });

  final List<QuestionBankItem> items;

  /// The scanner's one-line verdict, e.g. "Detected R1 fill in the blank …".
  final String summary;

  @override
  State<QuestionBankImportReviewScreen> createState() =>
      _QuestionBankImportReviewScreenState();
}

class _QuestionBankImportReviewScreenState
    extends State<QuestionBankImportReviewScreen> {
  late final List<bool> _keep = List.filled(widget.items.length, true);
  late String _level = widget.items.firstOrNull?.level ??
      AppConstants.hskLevels.first;
  QuestionDifficulty _difficulty = QuestionDifficulty.medium;

  int get _kept => _keep.where((k) => k).length;

  List<QuestionBankItem> _result() => [
        for (var i = 0; i < widget.items.length; i++)
          if (_keep[i])
            QuestionBankItem(
              id: '',
              ownerId: widget.items[i].ownerId,
              type: widget.items[i].type,
              question: widget.items[i].question,
              skillCategory: widget.items[i].skillCategory,
              level: _level,
              tags: widget.items[i].tags,
              difficulty: _difficulty,
            ),
      ];

  /// What the student will have to get right, as the scanner read it.
  static String answerLine(QuestionBankItem item) {
    final q = item.question;
    switch (item.type) {
      case ExerciseType.composeSentences:
        return 'Order: ${q.segments.join(' / ')}';
      case ExerciseType.matching:
      case ExerciseType.readingCloze:
        final letter = String.fromCharCode(65 + q.correctIndex);
        final word = q.correctIndex < q.options.length
            ? ' ${q.options[q.correctIndex]}'
            : '';
        return 'Answer: $letter$word';
      case ExerciseType.multipleChoice:
      case ExerciseType.listening:
      case ExerciseType.pictureSentence:
        if (q.options.isEmpty) return 'No answer options read yet';
        return [
          for (var i = 0; i < q.options.length; i++)
            '${i == q.correctIndex ? '✓ ' : ''}${String.fromCharCode(65 + i)}. ${q.options[i]}',
        ].join('   ');
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  Text(
                    widget.summary,
                    style: const TextStyle(height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<QuestionDifficulty>(
                          initialValue: _difficulty,
                          decoration: const InputDecoration(
                            labelText: 'Difficulty',
                            isDense: true,
                          ),
                          items: [
                            for (final d in QuestionDifficulty.values)
                              DropdownMenuItem(value: d, child: Text(d.label)),
                          ],
                          onChanged: (v) =>
                              setState(() => _difficulty = v ?? _difficulty),
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
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
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
                                    style: const TextStyle(
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
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.navy,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.prompt,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _keep[i]
                                      ? AppColors.navy
                                      : AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                answerLine(item),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
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
                onPressed: _kept == 0
                    ? null
                    : () => Navigator.pop(context, _result()),
                icon: const Icon(Icons.library_add_outlined, size: 18),
                label: Text('Add $_kept to bank'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
