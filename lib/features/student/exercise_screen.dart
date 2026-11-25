import 'dart:async';
import 'dart:math' show max;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/exercise_utils.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/confetti_burst.dart';
import '../../core/widgets/exercise_category_chip.dart';
import '../../core/widgets/score_summary.dart';
import '../../l10n/l10n.dart';
import '../../models/exercise.dart';
import '../../models/exercise_category.dart';
import '../../models/exercise_type.dart';
import '../../services/auth_service.dart';
import '../../services/exercise_play_service.dart';
import '../../services/firestore_service.dart';
import 'widgets/question_answer_view.dart';

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
  bool _legacy = false;
  bool _loading = true;
  String? _loadError;

  /// One-attempt exam: the attempt is over (opened again, or submitted twice).
  bool _attemptUsed = false;

  /// One-attempt exam not started yet: the start screen is showing.
  ExercisePeek? _peek;
  Exercise? _pendingExercise;

  int _currentIndex = 0;

  /// Listening: one player for the recording of the whole part (it keeps
  /// playing while the student moves between its questions) and one for a
  /// question's own clip.
  final _sectionPlayer = AudioPlayer();
  final _questionPlayer = AudioPlayer();
  String _sectionAudioLoaded = '';
  String _questionAudioLoaded = '';

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
    // One-attempt exams: the server clock (survives a reload).
    final remaining = _session?.remainingSeconds;
    if (remaining != null) return remaining;
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
      if (exercise == null) {
        if (!mounted) return;
        setState(() {
          _session = null;
          _loading = false;
        });
        return;
      }
      if (exercise.isPackage) {
        final peek = await ExercisePlayService().peek(exercise);
        if (!mounted) return;
        if (peek.oneAttempt && peek.finished) {
          setState(() {
            _attemptUsed = true;
            _loading = false;
          });
          return;
        }
        if (peek.oneAttempt && !peek.started) {
          // Exams start on the student's go, so the clock does not run
          // while they read the start screen.
          setState(() {
            _peek = peek;
            _pendingExercise = exercise;
            _loading = false;
          });
          return;
        }
      }
      await _openSession(exercise);
    } on LegacyExerciseException {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _legacy = true;
      });
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      _showLoadFailure(e);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = '$e';
      });
    }
  }

  /// Fetches the questions and starts the clock.
  Future<void> _openSession(Exercise exercise) async {
    final session = await ExercisePlayService().start(exercise);
    if (!mounted) return;
    setState(() {
      _session = session;
      _peek = null;
      _loading = false;
      _currentIndex = 0;
    });
    if (session.questions.isNotEmpty) _startClock();
    unawaited(_syncAudio());
  }

  /// Points the two players at the current question's recording(s). The
  /// part recording is left alone while the URL stays the same, so it keeps
  /// playing across the questions of that part.
  Future<void> _syncAudio() async {
    if (_questions.isEmpty) return;
    final q = _question;
    if (q.sectionAudioUrl != _sectionAudioLoaded) {
      _sectionAudioLoaded = q.sectionAudioUrl;
      await _loadInto(_sectionPlayer, q.sectionAudioUrl);
    }
    if (q.audioUrl != _questionAudioLoaded) {
      _questionAudioLoaded = q.audioUrl;
      await _loadInto(_questionPlayer, q.audioUrl);
    }
  }

  Future<void> _loadInto(AudioPlayer player, String url) async {
    try {
      await player.stop();
      if (url.isNotEmpty) await player.setUrl(url);
    } catch (e) {
      debugPrint('exercise audio: $e');
    }
  }

  /// Start button of the exam start screen.
  Future<void> _startExam() async {
    final exercise = _pendingExercise;
    if (exercise == null || _loading) return;
    setState(() => _loading = true);
    try {
      await _openSession(exercise);
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      _showLoadFailure(e);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = '$e';
      });
    }
  }

  void _showLoadFailure(FirebaseFunctionsException e) {
    final details = e.details;
    final used = details is Map && details['reason'] == 'already-attempted';
    // HSK simulations are taken in Tests with a token (2026-11-16).
    final inTests =
        details is Map && details['reason'] == 'hsk-simulation-in-tests';
    setState(() {
      _loading = false;
      _attemptUsed = used;
      _notAssigned = e.code == 'permission-denied';
      _loadError = used
          ? null
          : inTests
              ? context.l10n.testsHskSimulationInTests
              : e.message;
    });
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

  /// Every change in the answer area is stored at once (the shared
  /// [QuestionAnswerView] holds no answer of its own).
  void _onAnswer(PlayAnswer? answer) {
    if (_questions.isEmpty || _finished) return;
    setState(() => _session!.answer(_question, answer));
  }

  void _goTo(int index) {
    setState(() => _currentIndex = index);
    unawaited(_syncAudio());
  }

  void _back() {
    if (_currentIndex > 0) _goTo(_currentIndex - 1);
  }

  /// Standard Course (owner 2026-11-25): the textbook text of the lesson,
  /// read while answering; closing it keeps the answers as they are.
  void _showContext(String text) {
    final l = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        builder: (ctx, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Text(
              l.exercisePlayLessonText,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              text,
              style: AppTextStyles.question.copyWith(height: 1.8),
            ),
          ],
        ),
      ),
    );
  }

  void _next() {
    if (_currentIndex + 1 < _questions.length) {
      _goTo(_currentIndex + 1);
    } else {
      _confirmSubmit();
    }
  }

  Future<void> _confirmSubmit() async {
    final missing = _questions.length - _answeredCount;
    if (missing > 0) {
      final l = context.l10n;
      final submit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l.exercisePlaySubmitNowTitle),
          content: Text(l.exercisePlayUnansweredWarning(missing)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l.exercisePlayKeepAnswering),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l.exercisePlaySubmit),
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
    _ticker?.cancel();
    _clock.stop();
    unawaited(_sectionPlayer.stop());
    unawaited(_questionPlayer.stop());
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
        final l = context.l10n;
        setState(
          () => _submitError = e.message ?? l.exercisePlayCouldNotSubmitMessage,
        );
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
    _sectionPlayer.dispose();
    _questionPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final showClock = _session != null && _questions.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(_exercise?.title ??
            _pendingExercise?.title ??
            l.commonExerciseFallback),
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
              ? EmptyState(
                  icon: Icons.lock_outline,
                  title: l.exercisePlayNotAvailableTitle,
                  subtitle: l.exercisePlayNotAvailableSubtitle,
                )
              : _legacy
                  ? EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: l.exercisePlayLegacyTitle,
                      subtitle: l.exercisePlayLegacySubtitle,
                    )
                  : _attemptUsed
                      ? EmptyState(
                          icon: Icons.task_alt,
                          title: l.exercisePlayAttemptUsedTitle,
                          subtitle: l.exercisePlayAttemptUsedSubtitle,
                        )
                      : _peek != null && _session == null
                          ? _buildIntro()
                          : _loadError != null
                              ? EmptyState(
                                  icon: Icons.cloud_off_outlined,
                                  title: l.exercisePlayLoadFailedTitle,
                                  subtitle: _loadError!,
                                )
                              : _session == null
                                  ? EmptyState(
                                      icon: Icons.fitness_center_outlined,
                                      title: l.exercisePlayNotFoundTitle,
                                      subtitle: l.exercisePlayNotFoundSubtitle,
                                    )
                                  : _questions.isEmpty
                                      ? EmptyState(
                                          icon: Icons.fitness_center_outlined,
                                          title: l.exercisePlayNoQuestionsTitle,
                                          subtitle:
                                              l.exercisePlayNoQuestionsSubtitle,
                                        )
                                      : _finished
                                          ? _buildResult()
                                          : _buildQuestion(),
    );
  }

  /// Start screen of a one-attempt exam: what it is, how long, one go.
  Widget _buildIntro() {
    final l = context.l10n;
    final peek = _peek!;
    final exercise = _pendingExercise!;
    final minutes = peek.timeLimitMinutes;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExerciseCategoryChip(category: peek.category),
                const SizedBox(height: 10),
                Text(
                  exercise.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l.exercisePlayExamIntroTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                _IntroLine(
                  icon: Icons.looks_one_outlined,
                  text: l.exercisePlayOneAttempt,
                ),
                if (minutes != null)
                  _IntroLine(
                    icon: Icons.timer_outlined,
                    text: l.exercisePlayTimeLimit(minutes),
                  ),
                _IntroLine(
                  icon: Icons.list_alt_outlined,
                  text: l.exercisePlayQuestionCount(peek.questionCount),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _startExam,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(l.exercisePlayStart),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResult() {
    final l = context.l10n;
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
                l.exercisePlayChecking,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        );
      }
      return EmptyState(
        icon: Icons.cloud_off_outlined,
        title: l.exercisePlayCouldNotSubmitTitle,
        subtitle: _submitError ?? l.exercisePlayCheckConnection,
        action: FilledButton.icon(
          onPressed: () => _submit(),
          icon: const Icon(Icons.refresh),
          label: Text(l.exercisePlayTryAgain),
        ),
      );
    }

    final answers = _session!.answers;
    final summary = ScoreSummary(
      scorePercent: result.score,
      correctCount: result.correct,
      totalCount: result.total,
      primaryLabel: l.exercisePlayDone,
      subtitle: result.late
          ? l.exercisePlayLateSubtitle
          : result.pendingMarking
              ? l.playPendingSubtitle
              : _timeUp
              ? l.exercisePlayTimeUpSubtitle
              : _exercise!.title,
      timeLabel: ExerciseUtils.formatClock(result.durationSeconds),
      onPrimaryPressed: () => context.pop(),
      // No review when the server did not send one (older function build).
      details: result.review.isEmpty
          ? _hskMarks(result)
          : [
              ..._hskMarks(result),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l.exercisePlayReview,
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
    if (result.score < 70 || result.pendingMarking) return summary;
    return Stack(
      children: [
        summary,
        const Positioned.fill(child: ConfettiBurst()),
      ],
    );
  }

  Widget _buildQuestion() {
    final l = context.l10n;
    final exercise = _exercise!;
    final question = _question;
    final progress = (_currentIndex + 1) / _questions.length;
    final isCompose = question.isCompose;
    final isCloze = question.type == ExerciseType.readingCloze;
    // Fill in the blank plays like matching: one shared bank, pick a letter.
    final isMatching = question.usesWordBank;
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
        if (question.context.isNotEmpty) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => _showContext(question.context),
              icon: const Icon(Icons.menu_book_outlined, size: 18),
              label: Text(l.exercisePlayLessonText),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (question.section.isNotEmpty) ...[
          Text(
            question.section,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (question.sectionAudioUrl.isNotEmpty) ...[
          _AudioBar(
            player: _sectionPlayer,
            label: l.exercisePlayListeningRecording,
          ),
          const SizedBox(height: 12),
        ],
        if (question.audioUrl.isNotEmpty) ...[
          _AudioBar(
            player: _questionPlayer,
            label: l.exercisePlayQuestionAudio,
          ),
          const SizedBox(height: 12),
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
                    ? l.exercisePlaySentenceOf(
                        _currentIndex + 1, _questions.length)
                    : isCloze
                        ? l.exercisePlayBlankOf(
                            _currentIndex + 1, _questions.length)
                        : isMatching
                            ? l.exercisePlayMatchOf(
                                _currentIndex + 1, _questions.length)
                            : l.exercisePlayQuestionOf(
                                _currentIndex + 1, _questions.length),
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            Text(
              l.exercisePlayAnsweredOf(answered, _questions.length),
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
        QuestionAnswerView(
          key: ValueKey(question.id),
          question: question,
          answer: _session!.answers[question.id],
          onChanged: _onAnswer,
          onSubmitted: _next,
          enabled: !_finished,
        ),
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
              label: Text(l.exercisePlayBack),
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
                      ? l.exercisePlaySubmitAnswers
                      : isCompose
                          ? l.exercisePlayNextSentence
                          : isMatching
                              ? l.exercisePlayNextMatch
                              : l.exercisePlayNextQuestion,
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
                l.exercisePlaySubmitAllNow,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// HSK marks per part (listening / reading / writing, each 0–100, pass
  /// at 60% of the total), for an HSK simulation only.
  List<Widget> _hskMarks(PlayResult result) {
    final l = context.l10n;
    if (_session?.category != ExerciseCategory.hskSimulation ||
        result.bySkill.isEmpty) {
      return const [];
    }
    final parts = <(String, SkillScore)>[
      if (result.bySkill['listening'] case final s?)
        (l.exercisePlayHskListening, s),
      if (result.bySkill['reading'] case final s?)
        (l.exercisePlayHskReading, s),
      if (result.bySkill['typing'] case final s?)
        (l.exercisePlayHskWriting, s),
    ];
    if (parts.isEmpty) return const [];
    final total = parts.fold<int>(0, (n, p) => n + p.$2.scaled);
    final maxTotal = parts.length * 100;
    final pass = (maxTotal * 0.6).round();
    final passed = total >= pass;
    return [
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.exercisePlayHskMarks,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            for (final (name, s) in parts)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(name)),
                    Text(
                      '${s.scaled}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '  (${s.correct}/${s.total})',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.exercisePlayHskTotal(total, maxTotal, pass),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  passed ? l.exercisePlayHskPassed : l.exercisePlayHskNotPassed,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: passed ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
    ];
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

  String _prompt(AppLocalizations l) {
    if (question.type == ExerciseType.pictureSentence) {
      return l.exercisePlayReviewPictureSentence(question.keyword);
    }
    if (question.prompt.isNotEmpty) return question.prompt;
    if (question.isCompose) return l.exercisePlayReviewCompose;
    return l.exercisePlayReviewQuestionNumber(number);
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

  String? _correctAnswer(AppLocalizations l) {
    final c = check;
    if (c == null) return null;
    final index = c.correctIndex;
    if (index != null && !question.isCompose && !question.isTyped) {
      return _option(index);
    }
    if (c.correctOrder.isNotEmpty) return c.correctOrder.join(' ');
    if (c.accepted.isNotEmpty) return c.accepted.join(' / ');
    if (c.keyword.isNotEmpty) return l.exercisePlayReviewKeywordKey(c.keyword);
    return null;
  }

  String _option(int index) {
    final options = question.options;
    final letter = String.fromCharCode(65 + index);
    if (question.hasPictureOptions) return letter;
    return index >= 0 && index < options.length
        ? '$letter. ${options[index]}'
        : letter;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = check;
    final correct = c?.correct == true;
    final skipped = given == null;
    // Build 2A: half credit, or waiting for the teacher (free writing).
    final waiting = c?.needsMarking == true;
    final half = c?.isHalf == true;
    final color = correct
        ? AppColors.success
        : skipped
            ? AppColors.textSecondary
            : (waiting || half)
                ? AppColors.chipAmberFg
                : AppColors.error;
    final yours = _yourAnswer;
    final key = correct ? null : _correctAnswer(l);
    final explanation = c?.explanation.trim() ?? '';

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
                      : waiting
                          ? Icons.hourglass_top
                          : half
                              ? Icons.star_half
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
                  '$number. ${_prompt(l)}',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.question.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  yours == null
                      ? l.exercisePlayNotAnswered
                      : l.exercisePlayYourAnswer(yours),
                  style: TextStyle(color: color, fontSize: 14),
                ),
                if (waiting || half)
                  Text(
                    waiting && !half
                        ? l.playWaitingForTeacher
                        : l.playHalfWaiting,
                    style: TextStyle(color: AppColors.chipAmberFg, fontSize: 13),
                  ),
                if ((c?.keywords ?? const []).isNotEmpty)
                  Text(
                    l.bankTextKeywords(c!.keywords.join(', ')),
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                if (key != null)
                  Text(
                    l.exercisePlayCorrectAnswer(key),
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (explanation.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      explanation,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
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

/// Play / pause and the time of one recording.
class _AudioBar extends StatelessWidget {
  const _AudioBar({required this.player, required this.label});

  final AudioPlayer player;
  final String label;

  static String _clock(Duration? d) {
    if (d == null) return '--:--';
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: StreamBuilder<PlayerState>(
        stream: player.playerStateStream,
        builder: (context, snap) {
          final state = snap.data;
          final playing = state?.playing == true &&
              state?.processingState != ProcessingState.completed;
          final loading = state?.processingState == ProcessingState.loading ||
              state?.processingState == ProcessingState.buffering;
          return Row(
            children: [
              IconButton.filled(
                onPressed: loading
                    ? null
                    : () async {
                        if (playing) {
                          await player.pause();
                        } else {
                          if (state?.processingState ==
                              ProcessingState.completed) {
                            await player.seek(Duration.zero);
                          }
                          await player.play();
                        }
                      },
                icon: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(playing ? Icons.pause : Icons.play_arrow),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                    ),
                    StreamBuilder<Duration>(
                      stream: player.positionStream,
                      builder: (context, pos) => Text(
                        '${_clock(pos.data)} / ${_clock(player.duration)}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '0:00',
                onPressed: () => player.seek(Duration.zero),
                icon: const Icon(Icons.replay),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _IntroLine extends StatelessWidget {
  const _IntroLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.teal),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(height: 1.4))),
        ],
      ),
    );
  }
}
