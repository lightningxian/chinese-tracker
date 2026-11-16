import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../l10n/l10n.dart';
import '../../../models/exercise_type.dart';
import '../../../services/exercise_play_service.dart';

/// The answer area of one question, shared by the package player
/// (`ExerciseScreen`) and the supervised test player (`TestPlayerScreen`):
/// choices, picture choices, the word bank (matching / fill in the blank),
/// compose sentences and typed answers.
///
/// The view holds no answer of its own: it shows [answer] and reports every
/// change through [onChanged] (`null` = no answer). Give it a key per
/// question (`ValueKey(question.id)`) so a typed answer starts fresh on the
/// next question.
class QuestionAnswerView extends StatefulWidget {
  const QuestionAnswerView({
    super.key,
    required this.question,
    required this.answer,
    required this.onChanged,
    this.onSubmitted,
    this.enabled = true,
  });

  final PlayQuestion question;
  final PlayAnswer? answer;
  final ValueChanged<PlayAnswer?> onChanged;

  /// Enter in a typed answer (the package player moves on).
  final VoidCallback? onSubmitted;
  final bool enabled;

  @override
  State<QuestionAnswerView> createState() => _QuestionAnswerViewState();
}

class _QuestionAnswerViewState extends State<QuestionAnswerView> {
  late final TextEditingController _typedController =
      TextEditingController(text: widget.answer?.text ?? '');

  PlayQuestion get _question => widget.question;
  int? get _selectedIndex => widget.answer?.index;
  List<String> get _composeOrder => widget.answer?.order ?? const [];

  /// The segments not used yet, in their shuffled order.
  List<String> get _composeBank {
    final bank = List<String>.from(_question.segments);
    for (final segment in _composeOrder) {
      bank.remove(segment);
    }
    return bank;
  }

  @override
  void dispose() {
    _typedController.dispose();
    super.dispose();
  }

  void _selectAnswer(int index) {
    if (!widget.enabled) return;
    widget.onChanged(PlayAnswer.index(index));
  }

  void _addComposeSegment(String segment) {
    if (!widget.enabled) return;
    widget.onChanged(PlayAnswer.order([..._composeOrder, segment]));
  }

  void _removeComposeSegment(int index) {
    if (!widget.enabled) return;
    final order = List<String>.from(_composeOrder)..removeAt(index);
    widget.onChanged(order.isEmpty ? null : PlayAnswer.order(order));
  }

  void _typed(String value) {
    final typed = value.trim();
    widget.onChanged(typed.isEmpty ? null : PlayAnswer.text(typed));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final question = _question;
    if (question.usesWordBank) {
      // Fill in the blank plays like matching: one shared bank, pick a letter.
      return _buildMatchingQuestion(question, question.options);
    }
    if (question.isCompose) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            question.prompt.isNotEmpty
                ? question.prompt
                : l.exercisePlayComposePrompt,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l.exercisePlayComposeHint,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          _buildComposeList(),
        ],
      );
    }
    if (question.isTyped) return _buildTypedQuestion(question);
    final options = question.options;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (question.imageUrl.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              question.imageUrl,
              height: 220,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          question.prompt,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
        ),
        const SizedBox(height: 20),
        if (question.hasPictureOptions)
          _buildPictureOptions(question)
        else
          ...List.generate(options.length, (i) {
            final selected = _selectedIndex == i;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                onTap: () => _selectAnswer(i),
                child: Container(
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.teal.withValues(alpha: 0.08)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    border: selected
                        ? Border.all(color: AppColors.teal, width: 2)
                        : null,
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Row(
                    children: [
                      OptionLetter(index: i, selected: selected, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          options[i],
                          style: AppTextStyles.question.copyWith(fontSize: 20),
                        ),
                      ),
                      if (selected) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.check_circle, color: AppColors.teal),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  /// Type the hanzi: the sentence with a gap and its pinyin hint. Picture
  /// sentence: the picture (if any) and the keyword to use.
  Widget _buildTypedQuestion(PlayQuestion question) {
    final l = context.l10n;
    final isPicture = question.type == ExerciseType.pictureSentence;
    final hint = question.keyword;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isPicture && question.imageUrl.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              question.imageUrl,
              height: 220,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          isPicture ? l.exercisePlayPictureSentencePrompt : question.prompt,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
                height: 1.5,
              ),
        ),
        if (hint.isNotEmpty) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                hint,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.teal,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        TextField(
          controller: _typedController,
          autofocus: true,
          enabled: widget.enabled,
          maxLines: isPicture ? 3 : 1,
          style: AppTextStyles.question.copyWith(fontSize: 22),
          onChanged: _typed,
          onSubmitted: (_) => widget.onSubmitted?.call(),
          decoration: InputDecoration(
            hintText: isPicture ? '用这个词写一个句子…' : '写汉字…',
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildMatchingQuestion(PlayQuestion question, List<String> options) {
    final l = context.l10n;
    final isWide = MediaQuery.sizeOf(context).width >= 640;

    Widget promptCard() => AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question.type == ExerciseType.readingCloze
                    ? l.exercisePlayClozeLabel
                    : l.exercisePlayPromptLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                question.prompt,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                      height: 1.4,
                    ),
              ),
            ],
          ),
        );

    Widget answersCard() => AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.exercisePlayChooseResponse,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              if (question.hasPictureOptions)
                _buildPictureOptions(question)
              else
                ...List.generate(options.length, (index) {
                  final selected = _selectedIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      onTap: () => _selectAnswer(index),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: selected
                              ? Border.all(color: AppColors.teal, width: 2)
                              : null,
                        ),
                        child: Row(
                          children: [
                            OptionLetter(
                              index: index,
                              selected: selected,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                options[index],
                                style: AppTextStyles.question,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: promptCard()),
          const SizedBox(width: 16),
          Expanded(child: answersCard()),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        promptCard(),
        const SizedBox(height: 16),
        answersCard(),
      ],
    );
  }

  /// Picture choices (HSK listening part 1): lettered pictures, tap one.
  Widget _buildPictureOptions(PlayQuestion question) {
    final l = context.l10n;
    final urls = question.optionImageUrls;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.exercisePlayPickPicture,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(question.options.length, (i) {
            final selected = _selectedIndex == i;
            final url = i < urls.length ? urls[i] : '';
            return SizedBox(
              width: 168,
              child: AppCard(
                onTap: () => _selectAnswer(i),
                padding: const EdgeInsets.all(8),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected ? AppColors.teal : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    children: [
                      if (url.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            url,
                            height: 120,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => SizedBox(
                              height: 120,
                              child: Icon(Icons.broken_image_outlined,
                                  color: AppColors.textSecondary),
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 120),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OptionLetter(index: i, selected: selected, size: 28),
                          if (selected) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.check_circle,
                                color: AppColors.teal, size: 20),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildComposeList() {
    final l = context.l10n;
    final order = _composeOrder;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: order.isEmpty
              ? Text(
                  l.exercisePlayComposeEmpty,
                  style: TextStyle(color: AppColors.textSecondary),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(order.length, (index) {
                    return InputChip(
                      label: Text(order[index]),
                      labelStyle: AppTextStyles.question,
                      onPressed: () => _removeComposeSegment(index),
                      onDeleted: () => _removeComposeSegment(index),
                      deleteIconColor: AppColors.teal,
                      backgroundColor: AppColors.teal.withValues(alpha: 0.08),
                      side: BorderSide(color: AppColors.border),
                    );
                  }),
                ),
        ),
        const SizedBox(height: 16),
        Text(
          l.exercisePlayWordBank,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _composeBank.map((segment) {
            return ActionChip(
              label: Text(segment),
              labelStyle: AppTextStyles.question,
              onPressed: () => _addComposeSegment(segment),
              backgroundColor: AppColors.surface,
              side: BorderSide(color: AppColors.border),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// "A", "B"… box in front of a choice.
class OptionLetter extends StatelessWidget {
  const OptionLetter({
    super.key,
    required this.index,
    required this.selected,
    required this.size,
  });

  final int index;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected
            ? AppColors.teal.withValues(alpha: 0.15)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: selected ? AppColors.teal : AppColors.border,
        ),
      ),
      child: Text(
        String.fromCharCode(65 + index),
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: selected ? AppColors.teal : AppColors.textSecondary,
          fontSize: size >= 32 ? 15 : 14,
        ),
      ),
    );
  }
}
