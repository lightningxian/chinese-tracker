import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/score_summary.dart';
import '../../models/exercise.dart';
import '../../models/exercise_type.dart';
import '../../services/auth_service.dart';
import '../../services/exercise_play_service.dart';
import '../../services/firestore_service.dart';

/// Plays one exercise. Questions come from an [ExercisePlaySession]: for a
/// package the server sends them without answer keys and checks each
/// answer; for an older exercise the keys are still in the document and
/// the session checks locally. The screen itself never looks at a key.
class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  ExercisePlaySession? _session;
  bool _notAssigned = false;
  bool _loading = true;
  String? _loadError;

  int _currentIndex = 0;
  int? _selectedIndex;
  List<String> _composeOrder = [];
  List<String> _composeBank = [];

  /// Typed answers: hanzi for a pinyin hint, or a sentence with a keyword.
  final _typedController = TextEditingController();

  bool _checking = false;
  AnswerCheck? _check;
  int _correct = 0;
  bool _finished = false;
  bool _submitting = false;
  PlayResult? _result;

  Exercise? get _exercise => _session?.exercise;
  List<PlayQuestion> get _questions => _session?.questions ?? const [];
  PlayQuestion get _question => _questions[_currentIndex];
  bool get _answerSubmitted => _check != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final firestore = context.read<FirestoreService>();
    final student = context.read<AuthService>().appUser;
    if (student == null) return;

    try {
      final canAccess = await firestore.canStudentAccessExercise(
        exerciseId: widget.exerciseId,
        student: student,
      );
      if (!canAccess) {
        if (mounted) {
          setState(() {
            _notAssigned = true;
            _loading = false;
          });
        }
        return;
      }

      final exercise = await firestore.getExercise(widget.exerciseId);
      final session = exercise == null
          ? null
          : await ExercisePlayService(firestore: firestore)
              .start(exercise, student.uid);
      if (!mounted) return;
      setState(() {
        _session = session;
        _loading = false;
        _currentIndex = 0;
        _correct = 0;
        _resetQuestionState();
      });
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _notAssigned = e.code == 'permission-denied';
        _loadError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = '$e';
      });
    }
  }

  void _resetQuestionState() {
    if (_questions.isEmpty) return;
    final q = _question;
    if (q.isCompose) {
      _composeOrder = [];
      _composeBank = List<String>.from(q.segments);
    } else {
      _selectedIndex = null;
      _typedController.clear();
    }
    _check = null;
  }

  void _selectAnswer(int index) {
    if (_selectedIndex != null || _finished || _answerSubmitted) return;
    setState(() => _selectedIndex = index);
  }

  PlayAnswer? _currentAnswer() {
    final q = _question;
    if (q.isCompose) {
      return _composeOrder.isEmpty ? null : PlayAnswer.order(_composeOrder);
    }
    if (q.isTyped) {
      final typed = _typedController.text.trim();
      return typed.isEmpty ? null : PlayAnswer.text(typed);
    }
    return _selectedIndex == null ? null : PlayAnswer.index(_selectedIndex!);
  }

  Future<void> _checkAnswer() async {
    final answer = _currentAnswer();
    if (answer == null || _checking) return;
    setState(() => _checking = true);
    try {
      final check = await _session!.check(_question, answer);
      if (check.correct) _correct++;
      if (mounted) setState(() => _check = check);
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Could not check the answer.')),
      );
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _advanceQuestion() {
    if (_currentIndex + 1 >= _questions.length) {
      _finish();
    } else {
      setState(() {
        _currentIndex++;
        _resetQuestionState();
      });
    }
  }

  void _onPrimaryAction() {
    if (!_answerSubmitted) {
      _checkAnswer();
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

  Future<void> _finish() async {
    setState(() {
      _finished = true;
      _submitting = true;
    });
    try {
      // Grading notifications (teacher + student) are created server-side by
      // the onExerciseResultCreated Cloud Function — students can't write
      // notifications, so this must not block or fail the submission.
      final result = await _session!.finish();
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save the result: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _typedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              ? const EmptyState(
                  icon: Icons.lock_outline,
                  title: 'Exercise not available',
                  subtitle:
                      'This exercise has not been assigned to you. Ask your teacher.',
                )
              : _loadError != null
                  ? EmptyState(
                      icon: Icons.cloud_off_outlined,
                      title: 'Could not load the exercise',
                      subtitle: _loadError!,
                    )
                  : _session == null
                      ? const EmptyState(
                          icon: Icons.fitness_center_outlined,
                          title: 'Exercise not found',
                          subtitle: 'This exercise may have been removed.',
                        )
                      : _questions.isEmpty
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
    final total = _questions.length;
    final result = _result;
    final correct = result?.correct ?? _correct;
    final score = result?.score ?? (total == 0 ? 0 : ((correct / total) * 100).round());

    return ScoreSummary(
      scorePercent: score,
      correctCount: correct,
      totalCount: result?.total ?? total,
      primaryLabel: 'Done',
      loading: _submitting,
      subtitle: _exercise!.title,
      onPrimaryPressed: _submitting ? null : () => context.pop(),
    );
  }

  Widget _buildQuestion() {
    final exercise = _exercise!;
    final question = _question;
    final progress = (_currentIndex + 1) / _questions.length;
    final isCompose = question.isCompose;
    final isCloze = question.type == ExerciseType.readingCloze;
    final isTyped = question.isTyped;
    // Fill in the blank plays like matching: one shared bank, pick a letter.
    final isMatching = question.usesWordBank;
    final options = question.options;
    final isLast = _currentIndex + 1 >= _questions.length;
    final passage = _session!.passage;

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
        if (passage.isNotEmpty) ...[
          AppCard(
            child: SelectableText(
              passage,
              style: AppTextStyles.question.copyWith(height: 1.8),
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
              ? 'Sentence ${_currentIndex + 1} of ${_questions.length}'
              : isCloze
                  ? 'Blank ${_currentIndex + 1} of ${_questions.length}'
                  : isMatching
                      ? 'Match ${_currentIndex + 1} of ${_questions.length}'
                      : 'Question ${_currentIndex + 1} of ${_questions.length}',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        if (isMatching) ...[
          _buildMatchingQuestion(question, options),
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
          _buildComposeList(),
        ] else if (isTyped) ...[
          _buildTypedQuestion(question),
        ] else ...[
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
          ...List.generate(options.length, (i) {
            final selected = _selectedIndex == i;
            final isCorrect = _check?.correctIndex == i;
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
                          style: AppTextStyles.question.copyWith(fontSize: 20),
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
          onPressed: _checking || (!_answerSubmitted && _currentAnswer() == null)
              ? null
              : _onPrimaryAction,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.navy,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _checking
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  !_answerSubmitted
                      ? 'Check answer'
                      : isLast
                          ? 'Finish exercise'
                          : isCompose
                              ? 'Next sentence'
                              : isMatching
                                  ? 'Next match'
                                  : 'Next question',
                ),
        ),
      ],
    );
  }

  /// Type the hanzi: the sentence with a gap and its pinyin hint. Picture
  /// sentence: the picture (if any) and the keyword to use.
  Widget _buildTypedQuestion(PlayQuestion question) {
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
          isPicture
              ? 'Write a sentence that uses this word:'
              : question.prompt,
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
                style: const TextStyle(
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
          enabled: !_answerSubmitted,
          autofocus: true,
          maxLines: isPicture ? 3 : 1,
          style: AppTextStyles.question.copyWith(fontSize: 22),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _onPrimaryAction(),
          decoration: InputDecoration(
            hintText: isPicture ? '用这个词写一个句子…' : '写汉字…',
            border: const OutlineInputBorder(),
          ),
        ),
        if (_answerSubmitted && !isPicture && _check!.accepted.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'Answer: ${_check!.accepted.join(' / ')}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
          ),
        ],
      ],
    );
  }

  Widget _resultBanner() {
    final correct = _check?.correct == true;
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

  Widget _buildMatchingQuestion(PlayQuestion question, List<String> options) {
    final isWide = MediaQuery.sizeOf(context).width >= 640;

    Widget promptCard() => AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question.type == ExerciseType.readingCloze
                    ? 'Choose the word for the blank'
                    : 'Prompt',
                style: const TextStyle(
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
                final isCorrect = _check?.correctIndex == index;
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

  Widget _buildComposeList() {
    final check = _check;
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
                  ? (check!.correct ? AppColors.success : AppColors.error)
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
                      labelStyle: AppTextStyles.question,
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
              labelStyle: AppTextStyles.question,
              onPressed:
                  _answerSubmitted ? null : () => _addComposeSegment(segment),
              backgroundColor: AppColors.surface,
              side: const BorderSide(color: AppColors.border),
            );
          }).toList(),
        ),
        if (check != null && !check.correct && check.correctOrder.isNotEmpty) ...[
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
                  check.correctOrder.join(' '),
                  style: AppTextStyles.question,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
