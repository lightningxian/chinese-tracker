import 'dart:async';
import 'dart:math' show max;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/exercise_utils.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/score_summary.dart';
import '../../models/exercise.dart';
import '../../models/exercise_type.dart';
import '../../services/auth_service.dart';
import '../../services/exercise_play_service.dart';
import '../../services/firestore_service.dart';

/// Plays one exercise. Questions come from an [ExercisePlaySession]: for a
/// package the server sends them without answer keys; for an older exercise
/// the keys are still in the document. Either way the student answers every
/// question first (moving back and forth freely) and submits once at the
/// end; the session scores the attempt and returns the review shown on the
/// result page. The screen never looks at a key before submit.
///
/// A clock runs from the moment the questions appear. With a time limit on
/// the exercise it counts down and submits by itself at zero.
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

  final _clock = Stopwatch();
  Timer? _ticker;
  int _elapsedSeconds = 0;
  bool _timeUp = false;

  bool _finished = false;
  bool _submitting = false;
  String? _submitError;
  PlayResult? _result;

  Exercise? get _exercise => _session?.exercise;
  List<PlayQuestion> get _questions => _session?.questions ?? const [];
  PlayQuestion get _question => _questions[_currentIndex];

  int? get _limitSeconds {
    final minutes = _exercise?.timeLimitMinutes;
    return minutes == null || minutes <= 0 ? null : minutes * 60;
  }

  int get _answeredCount {
    final answers = _session?.answers ?? const {};
    return _questions.where((q) => answers.containsKey(q.id)).length;
  }

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
        _loadQuestionState();
      });
      if (session != null && session.questions.isNotEmpty) _startClock();
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

  void _startClock() {
    _clock
      ..reset()
      ..start();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted || _finished) return;
    final elapsed = _clock.elapsed.inSeconds;
    if (elapsed != _elapsedSeconds) {
      setState(() => _elapsedSeconds = elapsed);
    }
    final limit = _limitSeconds;
    if (limit != null && elapsed >= limit) _submit(timeUp: true);
  }

  /// Shows the answer already given to the current question, if any.
  void _loadQuestionState() {
    if (_questions.isEmpty) return;
    final q = _question;
    final given = _session!.answers[q.id];
    if (q.isCompose) {
      _composeOrder = List<String>.from(given?.order ?? const []);
      final bank = List<String>.from(q.segments);
      for (final segment in _composeOrder) {
        bank.remove(segment);
      }
      _composeBank = bank;
    } else if (q.isTyped) {
      _typedController.text = given?.text ?? '';
    } else {
      _selectedIndex = given?.index;
    }
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

  void _storeAnswer() {
    if (_questions.isEmpty || _finished) return;
    _session!.answer(_question, _currentAnswer());
  }

  void _selectAnswer(int index) {
    if (_finished) return;
    setState(() {
      _selectedIndex = index;
      _storeAnswer();
    });
  }

  void _addComposeSegment(String segment) {
    if (_finished) return;
    setState(() {
      _composeBank.remove(segment);
      _composeOrder.add(segment);
      _storeAnswer();
    });
  }

  void _removeComposeSegment(int index) {
    if (_finished) return;
    setState(() {
      final segment = _composeOrder.removeAt(index);
      _composeBank.add(segment);
      _storeAnswer();
    });
  }

  void _goTo(int index) {
    _storeAnswer();
    setState(() {
      _currentIndex = index;
      _loadQuestionState();
    });
  }

  void _back() {
    if (_currentIndex > 0) _goTo(_currentIndex - 1);
  }

  void _next() {
    if (_currentIndex + 1 < _questions.length) {
      _goTo(_currentIndex + 1);
    } else {
      _confirmSubmit();
    }
  }

  Future<void> _confirmSubmit() async {
    _storeAnswer();
    final missing = _questions.length - _answeredCount;
    if (missing > 0) {
      final submit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Submit now?'),
          content: Text(
            missing == 1
                ? '1 question has no answer yet. It will count as wrong.'
                : '$missing questions have no answer yet. They will count as wrong.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep answering'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Submit'),
            ),
          ],
        ),
      );
      if (submit != true || !mounted) return;
    }
    await _submit();
  }

  Future<void> _submit({bool timeUp = false}) async {
    if (_submitting || _result != null) return;
    _storeAnswer();
    _ticker?.cancel();
    _clock.stop();
    setState(() {
      _finished = true;
      _submitting = true;
      _submitError = null;
      _timeUp = _timeUp || timeUp;
      _elapsedSeconds = _clock.elapsed.inSeconds;
    });
    try {
      // Grading notifications (teacher + student) are created server-side by
      // the onExerciseResultCreated Cloud Function — students can't write
      // notifications, so this must not block or fail the submission.
      final result =
          await _session!.finish(durationSeconds: _clock.elapsed.inSeconds);
      if (mounted) setState(() => _result = result);
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        setState(() => _submitError = e.message ?? 'Could not submit.');
      }
    } catch (e) {
      if (mounted) setState(() => _submitError = '$e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _typedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showClock = _session != null && _questions.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(_exercise?.title ?? 'Exercise'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (showClock)
            _ClockChip(
              elapsedSeconds: _elapsedSeconds,
              limitSeconds: _limitSeconds,
              stopped: _finished,
            ),
        ],
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
    final result = _result;
    if (result == null) {
      if (_submitting) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Checking your answers…',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        );
      }
      return EmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Could not submit',
        subtitle: _submitError ?? 'Check your connection and try again.',
        action: FilledButton.icon(
          onPressed: () => _submit(),
          icon: const Icon(Icons.refresh),
          label: const Text('Try again'),
        ),
      );
    }

    final answers = _session!.answers;
    return ScoreSummary(
      scorePercent: result.score,
      correctCount: result.correct,
      totalCount: result.total,
      primaryLabel: 'Done',
      subtitle: _timeUp
          ? "Time's up. The answers you gave were submitted."
          : _exercise!.title,
      timeLabel: ExerciseUtils.formatClock(result.durationSeconds),
      onPrimaryPressed: () => context.pop(),
      details: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Review',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
              fontSize: 16,
            ),
          ),
        ),
        for (final (i, question) in _questions.indexed)
          _ReviewTile(
            number: i + 1,
            question: question,
            check: result.review[question.id],
            given: answers[question.id],
          ),
      ],
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
    final answered = _answeredCount;

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
        Row(
          children: [
            Expanded(
              child: Text(
                isCompose
                    ? 'Sentence ${_currentIndex + 1} of ${_questions.length}'
                    : isCloze
                        ? 'Blank ${_currentIndex + 1} of ${_questions.length}'
                        : isMatching
                            ? 'Match ${_currentIndex + 1} of ${_questions.length}'
                            : 'Question ${_currentIndex + 1} of ${_questions.length}',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            Text(
              '$answered of ${_questions.length} answered',
              style: TextStyle(
                color: answered == _questions.length
                    ? AppColors.success
                    : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
          Text(
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
                      _OptionLetter(index: i, selected: selected, size: 32),
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
        const SizedBox(height: 24),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _currentIndex == 0 ? null : _back,
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
              ),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _next,
                style: FilledButton.styleFrom(
                  backgroundColor: isLast ? AppColors.success : AppColors.navy,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: Icon(
                  isLast ? Icons.check : Icons.arrow_forward,
                  size: 18,
                ),
                label: Text(
                  isLast
                      ? 'Submit answers'
                      : isCompose
                          ? 'Next sentence'
                          : isMatching
                              ? 'Next match'
                              : 'Next question',
                ),
              ),
            ),
          ],
        ),
        if (!isLast) ...[
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: _confirmSubmit,
              child: Text(
                'Submit all answers now',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
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
          isPicture ? 'Write a sentence that uses this word:' : question.prompt,
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
          maxLines: isPicture ? 3 : 1,
          style: AppTextStyles.question.copyWith(fontSize: 22),
          onChanged: (_) => setState(_storeAnswer),
          onSubmitted: (_) => _next(),
          decoration: InputDecoration(
            hintText: isPicture ? '用这个词写一个句子…' : '写汉字…',
            border: const OutlineInputBorder(),
          ),
        ),
      ],
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
                          _OptionLetter(
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

  Widget _buildComposeList() {
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
          child: _composeOrder.isEmpty
              ? Text(
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
class _OptionLetter extends StatelessWidget {
  const _OptionLetter({
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

/// Elapsed time, or the time left when the exercise has a limit (red in the
/// last minute). Freezes once the attempt is submitted.
class _ClockChip extends StatelessWidget {
  const _ClockChip({
    required this.elapsedSeconds,
    required this.limitSeconds,
    required this.stopped,
  });

  final int elapsedSeconds;
  final int? limitSeconds;
  final bool stopped;

  @override
  Widget build(BuildContext context) {
    final limit = limitSeconds;
    final remaining = limit == null ? null : max(0, limit - elapsedSeconds);
    final urgent = !stopped && remaining != null && remaining <= 60;
    final color = urgent ? AppColors.error : AppColors.navy;
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: urgent ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            remaining == null ? Icons.timer_outlined : Icons.hourglass_bottom,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            ExerciseUtils.formatClock(remaining ?? elapsedSeconds),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// One question on the result page: what the student answered and, when it
/// was wrong or skipped, the right answer.
class _ReviewTile extends StatelessWidget {
  const _ReviewTile({
    required this.number,
    required this.question,
    required this.check,
    required this.given,
  });

  final int number;
  final PlayQuestion question;
  final AnswerCheck? check;
  final PlayAnswer? given;

  String get _prompt {
    if (question.type == ExerciseType.pictureSentence) {
      return 'Write a sentence with "${question.keyword}"';
    }
    if (question.prompt.isNotEmpty) return question.prompt;
    if (question.isCompose) return 'Arrange the words into a sentence';
    return 'Question $number';
  }

  String? get _yourAnswer {
    final a = given;
    if (a == null) return null;
    final index = a.index;
    if (index != null) return _option(index);
    final order = a.order;
    if (order != null) return order.join(' ');
    return a.text;
  }

  String? get _correctAnswer {
    final c = check;
    if (c == null) return null;
    final index = c.correctIndex;
    if (index != null && !question.isCompose && !question.isTyped) {
      return _option(index);
    }
    if (c.correctOrder.isNotEmpty) return c.correctOrder.join(' ');
    if (c.accepted.isNotEmpty) return c.accepted.join(' / ');
    if (c.keyword.isNotEmpty) return 'A sentence that uses "${c.keyword}"';
    return null;
  }

  String _option(int index) {
    final options = question.options;
    final letter = String.fromCharCode(65 + index);
    return index >= 0 && index < options.length
        ? '$letter. ${options[index]}'
        : letter;
  }

  @override
  Widget build(BuildContext context) {
    final c = check;
    final correct = c?.correct == true;
    final skipped = given == null;
    final color = correct
        ? AppColors.success
        : skipped
            ? AppColors.textSecondary
            : AppColors.error;
    final yours = _yourAnswer;
    final key = correct ? null : _correctAnswer;

    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              correct
                  ? Icons.check
                  : skipped
                      ? Icons.remove
                      : Icons.close,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$number. $_prompt',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.question.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  yours == null ? 'Not answered' : 'Your answer: $yours',
                  style: TextStyle(color: color, fontSize: 14),
                ),
                if (key != null)
                  Text(
                    'Correct answer: $key',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
