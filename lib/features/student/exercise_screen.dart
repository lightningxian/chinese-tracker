import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/score_summary.dart';
import '../../models/exercise.dart';
import '../../models/exercise_type.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  Exercise? _exercise;
  bool _notAssigned = false;
  int _currentIndex = 0;
  int? _selectedIndex;
  List<String> _composeOrder = [];
  List<String> _composeBank = [];
  bool _answerSubmitted = false;
  bool? _lastAnswerCorrect;
  int _correct = 0;
  bool _loading = true;
  bool _finished = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadExercise();
  }

  Future<void> _loadExercise() async {
    final firestore = context.read<FirestoreService>();
    final student = context.read<AuthService>().appUser;
    if (student == null) return;

    final canAccess = await firestore.canStudentAccessExercise(
      exerciseId: widget.exerciseId,
      student: student,
    );

    if (!canAccess) {
      if (mounted) {
        setState(() {
          _exercise = null;
          _notAssigned = true;
          _loading = false;
        });
      }
      return;
    }

    final exercise = await firestore.getExercise(widget.exerciseId);
    if (mounted) {
      setState(() {
        _exercise = exercise;
        _loading = false;
        _currentIndex = 0;
        _correct = 0;
        _resetQuestionState();
      });
    }
  }

  void _resetQuestionState() {
    final exercise = _exercise;
    if (exercise == null || exercise.questions.isEmpty) return;

    if (exercise.type == ExerciseType.composeSentences) {
      final segments = exercise.questions[_currentIndex].segments;
      _composeOrder = [];
      _composeBank = List<String>.from(segments)..shuffle(Random());
    } else {
      _selectedIndex = null;
    }
    _answerSubmitted = false;
    _lastAnswerCorrect = null;
  }

  List<String> _currentOptions(Exercise exercise) {
    if (exercise.type == ExerciseType.matching) {
      return exercise.matchingOptions;
    }
    return exercise.questions[_currentIndex].options;
  }

  void _selectAnswer(int index) {
    if (_selectedIndex != null || _finished || _answerSubmitted) return;
    setState(() => _selectedIndex = index);
  }

  void _checkComposeAnswer() {
    final question = _exercise!.questions[_currentIndex];
    final isCorrect = question.isCorrectComposeOrder(_composeOrder);
    if (isCorrect) _correct++;
    setState(() {
      _answerSubmitted = true;
      _lastAnswerCorrect = isCorrect;
    });
  }

  void _advanceQuestion() {
    final exercise = _exercise!;
    if (_currentIndex + 1 >= exercise.questions.length) {
      _submitResults();
    } else {
      setState(() {
        _currentIndex++;
        _resetQuestionState();
      });
    }
  }

  void _onPrimaryAction() {
    final exercise = _exercise!;
    if (exercise.type == ExerciseType.composeSentences) {
      if (!_answerSubmitted) {
        _checkComposeAnswer();
        return;
      }
      _advanceQuestion();
      return;
    }

    if (_selectedIndex == null) return;

    if (!_answerSubmitted) {
      final isCorrect =
          _selectedIndex == exercise.questions[_currentIndex].correctIndex;
      if (isCorrect) _correct++;
      setState(() {
        _answerSubmitted = true;
        _lastAnswerCorrect = isCorrect;
      });
      return;
    }

    _advanceQuestion();
  }

  void _addComposeSegment(String segment) {
    if (_answerSubmitted) return;
    setState(() {
      _composeBank.remove(segment);
      _composeOrder.add(segment);
    });
  }

  void _removeComposeSegment(int index) {
    if (_answerSubmitted) return;
    setState(() {
      final segment = _composeOrder.removeAt(index);
      _composeBank.add(segment);
    });
  }

  Future<void> _submitResults() async {
    final exercise = _exercise!;
    final total = exercise.questions.length;
    final score = total == 0 ? 0 : ((_correct / total) * 100).round();

    setState(() {
      _finished = true;
      _submitting = true;
    });

    final student = context.read<AuthService>().appUser!;
    final firestore = context.read<FirestoreService>();
    await firestore.saveExerciseResult(
          studentId: student.uid,
          exerciseId: exercise.id,
          score: score,
        );
    // Grading notifications (teacher + student) are created server-side by the
    // onExerciseResultCreated Cloud Function — students can't write
    // notifications, so this must not block or fail the submission.

    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final student = context.watch<AuthService>().appUser;
    return Scaffold(
      appBar: AppBar(
        title: Text(_exercise?.title ?? 'Exercise'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notAssigned
              ? EmptyState(
                  icon: Icons.lock_outline,
                  title: 'Exercise not available',
                  subtitle: student?.level == null
                      ? 'Set your HSK level in Profile to access practice exercises.'
                      : 'This exercise is not published for ${student!.level}.',
                )
              : _exercise == null
                  ? const EmptyState(
                      icon: Icons.fitness_center_outlined,
                      title: 'Exercise not found',
                      subtitle: 'This exercise may have been removed.',
                    )
                  : !_exercise!.type.isImplemented
                  ? const EmptyState(
                      icon: Icons.construction_outlined,
                      title: 'Exercise type coming soon',
                      subtitle:
                          'This worksheet type is not available for students yet.',
                    )
                  : _exercise!.questions.isEmpty
                      ? const EmptyState(
                          icon: Icons.fitness_center_outlined,
                          title: 'No questions yet',
                          subtitle:
                              'Your teacher has not added questions to this exercise.',
                        )
                      : _finished
                          ? _buildResult()
                          : _buildQuestion(),
    );
  }

  Widget _buildResult() {
    final total = _exercise!.questions.length;
    final score = total == 0 ? 0 : ((_correct / total) * 100).round();

    return ScoreSummary(
      scorePercent: score,
      correctCount: _correct,
      totalCount: total,
      primaryLabel: 'Done',
      loading: _submitting,
      subtitle: _exercise!.title,
      onPrimaryPressed: _submitting ? null : () => context.pop(),
    );
  }

  Widget _buildQuestion() {
    final exercise = _exercise!;
    final question = exercise.questions[_currentIndex];
    final progress = (_currentIndex + 1) / exercise.questions.length;
    final isCompose = exercise.type == ExerciseType.composeSentences;
    final isMatching = exercise.type == ExerciseType.matching;
    final options = _currentOptions(exercise);
    final isLast = _currentIndex + 1 >= exercise.questions.length;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (exercise.instructions.isNotEmpty) ...[
          AppCard(
            child: Text(
              exercise.instructions,
              style: const TextStyle(height: 1.5),
            ),
          ),
          const SizedBox(height: 16),
        ],
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.border,
          color: AppColors.teal,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
        const SizedBox(height: 8),
        Text(
          isCompose
              ? 'Sentence ${_currentIndex + 1} of ${exercise.questions.length}'
              : isMatching
                  ? 'Match ${_currentIndex + 1} of ${exercise.questions.length}'
                  : 'Question ${_currentIndex + 1} of ${exercise.questions.length}',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        if (isMatching) ...[
          _buildMatchingQuestion(exercise, question, options),
        ] else if (isCompose) ...[
          Text(
            question.prompt.isNotEmpty
                ? question.prompt
                : 'Arrange the words to form a correct sentence',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap words below to build your sentence',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          _buildComposeList(question),
        ] else ...[
          Text(
            question.prompt,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
          ),
          const SizedBox(height: 20),
          ...List.generate(options.length, (i) {
          final selected = _selectedIndex == i;
          final isCorrect = i == question.correctIndex;
          Color? borderColor;
          Color? fillColor;
          IconData? resultIcon;
          Color? resultIconColor;
          if (_answerSubmitted) {
            if (isCorrect) {
              // Always mark the correct answer strongly, whether or not the
              // student picked it — a clear green fill + check.
              borderColor = AppColors.success;
              fillColor = AppColors.success.withValues(alpha: 0.14);
              resultIcon = Icons.check_circle;
              resultIconColor = AppColors.success;
            } else if (selected) {
              borderColor = AppColors.error;
              fillColor = AppColors.error.withValues(alpha: 0.10);
              resultIcon = Icons.cancel;
              resultIconColor = AppColors.error;
            }
          }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                onTap: () => _selectAnswer(i),
                child: Container(
                  decoration: BoxDecoration(
                    color: fillColor,
                    borderRadius: BorderRadius.circular(8),
                    border: borderColor != null
                        ? Border.all(color: borderColor, width: 2)
                        : null,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
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
                          String.fromCharCode(65 + i),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: selected ? AppColors.teal : AppColors.textSecondary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          options[i],
                          style: const TextStyle(fontSize: 18, height: 1.4),
                        ),
                      ),
                      if (resultIcon != null) ...[
                        const SizedBox(width: 8),
                        Icon(resultIcon, color: resultIconColor, size: 26),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
        if (_answerSubmitted) ...[
          const SizedBox(height: 20),
          _resultBanner(),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: isCompose
              ? (_answerSubmitted
                  ? _onPrimaryAction
                  : _composeOrder.isNotEmpty
                      ? _onPrimaryAction
                      : null)
              : _selectedIndex == null
                  ? null
                  : _onPrimaryAction,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.navy,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(
            isCompose
                ? (!_answerSubmitted
                    ? 'Check answer'
                    : isLast
                        ? 'Finish exercise'
                        : 'Next sentence')
                : !_answerSubmitted
                    ? 'Check answer'
                    : isLast
                        ? 'Finish exercise'
                        : isMatching
                            ? 'Next match'
                            : 'Next question',
          ),
        ),
      ],
    );
  }

  Widget _resultBanner() {
    final correct = _lastAnswerCorrect == true;
    final color = correct ? AppColors.success : AppColors.error;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(
            correct ? Icons.check_circle : Icons.cancel,
            color: color,
            size: 30,
          ),
          const SizedBox(width: 12),
          Text(
            correct ? 'Correct!' : 'Not quite',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchingQuestion(
    Exercise exercise,
    ExerciseQuestion question,
    List<String> options,
  ) {
    final isWide = MediaQuery.sizeOf(context).width >= 640;

    Widget promptCard() => AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Prompt',
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
              const Text(
                'Choose the best response',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(options.length, (index) {
                final selected = _selectedIndex == index;
                final isCorrect = index == question.correctIndex;
                Color? borderColor;
                if (_answerSubmitted) {
                  if (selected && isCorrect) {
                    borderColor = AppColors.success;
                  } else if (selected && !isCorrect) {
                    borderColor = AppColors.error;
                  } else if (isCorrect) {
                    borderColor = AppColors.success.withValues(alpha: 0.5);
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    onTap: _answerSubmitted ? null : () => _selectAnswer(index),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: borderColor != null
                            ? Border.all(color: borderColor, width: 2)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.teal.withValues(alpha: 0.15)
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: selected
                                    ? AppColors.teal
                                    : AppColors.border,
                              ),
                            ),
                            child: Text(
                              String.fromCharCode(65 + index),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? AppColors.teal
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              options[index],
                              style: const TextStyle(height: 1.4),
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

  Widget _buildComposeList(ExerciseQuestion question) {
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
            border: Border.all(
              color: _answerSubmitted
                  ? (_lastAnswerCorrect == true
                      ? AppColors.success
                      : AppColors.error)
                  : AppColors.border,
              width: _answerSubmitted ? 2 : 1.5,
            ),
          ),
          child: _composeOrder.isEmpty
              ? const Text(
                  'Your sentence appears here…',
                  style: TextStyle(color: AppColors.textSecondary),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_composeOrder.length, (index) {
                    return InputChip(
                      label: Text(_composeOrder[index]),
                      onPressed: _answerSubmitted
                          ? null
                          : () => _removeComposeSegment(index),
                      onDeleted: _answerSubmitted
                          ? null
                          : () => _removeComposeSegment(index),
                      deleteIconColor: AppColors.teal,
                      backgroundColor: AppColors.teal.withValues(alpha: 0.08),
                      side: const BorderSide(color: AppColors.border),
                    );
                  }),
                ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Word bank',
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
              onPressed:
                  _answerSubmitted ? null : () => _addComposeSegment(segment),
              backgroundColor: AppColors.surface,
              side: const BorderSide(color: AppColors.border),
            );
          }).toList(),
        ),
        if (_answerSubmitted && _lastAnswerCorrect == false) ...[
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Correct sentence',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  question.segments.join(' '),
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
