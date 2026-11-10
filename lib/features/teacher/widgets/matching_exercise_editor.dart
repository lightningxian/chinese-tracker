import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../models/exercise.dart';

class MatchingQuestionDraft {
  MatchingQuestionDraft({
    String prompt = '',
    this.correctIndex = 0,
  }) : promptController = TextEditingController(text: prompt);

  final TextEditingController promptController;
  int correctIndex;

  void dispose() {
    promptController.dispose();
  }

  ExerciseQuestion? toQuestion() {
    final prompt = promptController.text.trim();
    if (prompt.isEmpty) return null;
    return ExerciseQuestion(
      prompt: prompt,
      correctIndex: correctIndex,
    );
  }
}

class MatchingExerciseEditor extends StatelessWidget {
  const MatchingExerciseEditor({
    super.key,
    required this.optionControllers,
    required this.questions,
    required this.onAddQuestion,
    required this.onRemoveQuestion,
    required this.onChanged,
  });

  final List<TextEditingController> optionControllers;
  final List<MatchingQuestionDraft> questions;
  final VoidCallback onAddQuestion;
  final ValueChanged<int> onRemoveQuestion;
  final VoidCallback onChanged;

  static List<TextEditingController> createOptionControllers([
    List<String>? initial,
  ]) {
    return List.generate(6, (index) {
      return TextEditingController(text: initial?[index] ?? '');
    });
  }

  static void disposeOptionControllers(
      List<TextEditingController> controllers) {
    for (final controller in controllers) {
      controller.dispose();
    }
  }

  List<String> collectOptions() {
    return optionControllers
        .map((controller) => controller.text.trim())
        .where((option) => option.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Answer bank (A–F)',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Shared options that students match to each prompt.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(optionControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: optionControllers[index],
                    onChanged: (_) => onChanged(),
                    decoration: InputDecoration(
                      labelText: 'Option ${String.fromCharCode(65 + index)}',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                'Prompts',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppColors.navy,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onAddQuestion,
              icon: const Icon(Icons.add),
              label: const Text('Add prompt'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(questions.length, (index) {
          final draft = questions[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Prompt ${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      if (questions.length > 1)
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: AppColors.error,
                          ),
                          onPressed: () => onRemoveQuestion(index),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: draft.promptController,
                    onChanged: (_) => onChanged(),
                    decoration: const InputDecoration(
                      labelText: 'Sentence to match',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: draft.correctIndex.clamp(
                      0,
                      optionControllers.length - 1,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Correct answer',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items:
                        List.generate(optionControllers.length, (optionIndex) {
                      final label = String.fromCharCode(65 + optionIndex);
                      final preview =
                          optionControllers[optionIndex].text.trim();
                      return DropdownMenuItem(
                        value: optionIndex,
                        child: Text(
                          preview.isEmpty ? label : '$label. $preview',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                    onChanged: (value) {
                      if (value == null) return;
                      draft.correctIndex = value;
                      onChanged();
                    },
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
