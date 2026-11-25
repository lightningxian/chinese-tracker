import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../l10n/l10n.dart';
import '../../models/placement.dart';
import '../../models/test_track.dart';
import '../../services/exercise_play_service.dart';
import '../../services/test_service.dart';
import '../student/widgets/question_answer_view.dart';
import 'test_labels.dart';

enum TestPlayerPhase { loading, start, playing, submitting, finished, error }

/// ViewModel of the supervised test player. The server owns every clock:
/// each step from `startTest` / `submitTestPart` says how many seconds are
/// left in the open part and how far its recording is. Answers of the open
/// part are kept on the device so a reload does not lose them.
class TestPlayerViewModel extends ChangeNotifier {
  TestPlayerViewModel(this._service, {this.token, this.codeId}) {
    unawaited(_init());
  }

  final TestPlayBackend _service;
  final String? token;
  String? codeId;

  /// Build 3: a visitor's public placement test (no result card).
  bool get isVisitor => _service.isVisitor;

  /// A visitor's marks and result code at the finish.
  VisitorResult? visitorResult;

  TestPlayerPhase phase = TestPlayerPhase.loading;
  TestFacts? facts;
  TestStep? step;
  Object? error;
  String? resultId;

  /// Answers of the open part.
  final Map<String, PlayAnswer> answers = {};
  int current = 0;
  int secondsLeft = 0;
  DateTime? _deadline;
  Timer? _ticker;
  StreamSubscription<TestAttempt?>? _attemptSub;

  final AudioPlayer player = AudioPlayer();
  bool recordingPlaying = false;
  bool recordingFinished = false;

  /// After a reload the browser needs one tap before the recording can
  /// continue from where the part clock says it is.
  bool needsTapToResume = false;
  StreamSubscription<PlayerState>? _playerSub;

  bool leftNoticeShown = false;
  int leftCount = 0;

  /// A question's own clip may be played at most [maxClipPlays] times in a
  /// test (proposal Table 9); the count is kept on the device.
  static const maxClipPlays = 2;
  final AudioPlayer clipPlayer = AudioPlayer();
  Map<String, int> clipPlays = {};
  String? playingClip;

  int clipPlaysLeft(PlayQuestion q) =>
      (maxClipPlays - (clipPlays[q.id] ?? 0)).clamp(0, maxClipPlays);

  Future<void> playClip(PlayQuestion q) async {
    if (q.audioUrl.isEmpty || clipPlaysLeft(q) <= 0 || playingClip != null) {
      return;
    }
    clipPlays = {...clipPlays, q.id: (clipPlays[q.id] ?? 0) + 1};
    playingClip = q.id;
    notifyListeners();
    unawaited(TestService.keepClipPlays(codeId!, clipPlays));
    try {
      await clipPlayer.setUrl(q.audioUrl);
      await clipPlayer.play();
      await clipPlayer.processingStateStream
          .firstWhere((s) => s == ProcessingState.completed);
    } catch (e) {
      debugPrint('test clip: $e');
    } finally {
      playingClip = null;
      notifyListeners();
    }
  }

  bool get partClocks => facts?.partClocks ?? true;
  List<PlayQuestion> get questions => step?.questions ?? const [];
  bool get hasRecording => (step?.recordingUrl ?? '').isNotEmpty;

  /// Part clocks: the next part cannot start while the recording plays.
  bool get canMoveOn =>
      phase == TestPlayerPhase.playing &&
      !(partClocks && hasRecording && recordingPlaying);

  int get answeredCount => questions.where((q) => answers.containsKey(q.id)).length;

  Future<void> _init() async {
    try {
      if (token != null) {
        facts = await _service.peek(token!);
        codeId = facts!.codeId;
        if (facts!.started) {
          await begin();
          return;
        }
        phase = TestPlayerPhase.start;
        notifyListeners();
      } else {
        await begin();
      }
    } catch (e) {
      error = e;
      phase = TestPlayerPhase.error;
      notifyListeners();
    }
  }

  /// The student's go on the start screen (or a resume).
  Future<void> begin() async {
    phase = TestPlayerPhase.loading;
    notifyListeners();
    try {
      final s = token != null && (facts == null || !facts!.started)
          ? await _service.start(token: token)
          : await _service.start(codeId: codeId);
      await _apply(s, fresh: true);
      _watchAttempt();
    } catch (e) {
      error = e;
      phase = TestPlayerPhase.error;
      notifyListeners();
    }
  }

  /// The teacher may end the test for everyone: follow the attempt.
  void _watchAttempt() {
    final id = _attemptId;
    if (id == null || _attemptSub != null) return;
    // The attempt id is `{codeId}_{uid}`; the result has the same id.
    _attemptSub = _service.watchAttempt(id).listen((a) {
      if (a == null) return;
      leftCount = a.leftCount;
      if (a.finished && phase != TestPlayerPhase.finished) {
        _finish(_attemptId);
      } else if (a.submitRequested && phase == TestPlayerPhase.playing) {
        // Build 2A: the teacher ended the test for everyone; send what is
        // typed now (the server finishes the attempt after this part).
        endedByTeacher = true;
        unawaited(submitPart(timeUp: true));
      } else {
        notifyListeners();
      }
    });
  }

  String? _attemptId;

  /// The teacher ended the session while this student was sitting.
  bool endedByTeacher = false;

  Future<void> _apply(TestStep s, {required bool fresh}) async {
    step = s;
    // Keep what we know when a reply carries no facts (older server).
    if (s.facts.codeId.isNotEmpty) {
      facts = s.facts;
      codeId = s.facts.codeId;
    }
    if (s.finished) {
      visitorResult = s.visitorResult ?? visitorResult;
      _finish(s.resultId);
      return;
    }
    _attemptId = s.attemptId ?? _attemptId;
    answers
      ..clear()
      ..addAll(await TestService.keptAnswers(codeId!, s.partIndex));
    clipPlays = await TestService.keptClipPlays(codeId!);
    current = 0;
    _deadline = DateTime.now().add(Duration(seconds: s.secondsLeft));
    secondsLeft = s.secondsLeft;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    phase = TestPlayerPhase.playing;
    await _loadRecording(s);
    notifyListeners();
  }

  Future<void> _loadRecording(TestStep s) async {
    await _playerSub?.cancel();
    recordingPlaying = false;
    recordingFinished = false;
    needsTapToResume = false;
    try {
      await player.stop();
      if (s.recordingUrl.isEmpty) return;
      final duration = await player.setUrl(s.recordingUrl);
      _playerSub = player.playerStateStream.listen((st) {
        final playing =
            st.playing && st.processingState != ProcessingState.completed;
        final done = st.processingState == ProcessingState.completed;
        if (playing != recordingPlaying || done != recordingFinished) {
          recordingPlaying = playing;
          recordingFinished = done;
          notifyListeners();
        }
      });
      if (!partClocks) return; // free player: the student presses play
      final elapsed = s.elapsedSeconds;
      if (duration != null && elapsed >= duration.inSeconds) {
        recordingFinished = true;
        return;
      }
      if (elapsed <= 3) {
        unawaited(player.play());
      } else {
        needsTapToResume = true;
      }
    } catch (e) {
      debugPrint('test recording: $e');
    }
  }

  /// One tap after a reload: the recording continues where the clock is.
  Future<void> resumeRecording() async {
    final s = step;
    if (s == null) return;
    final started = _deadline!.subtract(Duration(seconds: s.partSeconds));
    final at = DateTime.now().difference(started);
    needsTapToResume = false;
    notifyListeners();
    await player.seek(at);
    unawaited(player.play());
  }

  void _tick() {
    final d = _deadline;
    if (d == null || phase != TestPlayerPhase.playing) return;
    final left = d.difference(DateTime.now()).inSeconds;
    secondsLeft = left < 0 ? 0 : left;
    notifyListeners();
    if (left <= 0) unawaited(submitPart(timeUp: true));
  }

  void answer(PlayQuestion q, PlayAnswer? a) {
    if (phase != TestPlayerPhase.playing) return;
    if (a == null) {
      answers.remove(q.id);
    } else {
      answers[q.id] = a;
    }
    unawaited(TestService.keepAnswers(codeId!, step!.partIndex, answers));
    notifyListeners();
  }

  void goTo(int index) {
    if (index < 0 || index >= questions.length) return;
    current = index;
    notifyListeners();
  }

  /// Submits the open part (the student's confirmation, or the clock at 0).
  Future<void> submitPart({bool timeUp = false}) async {
    final s = step;
    if (s == null || phase != TestPlayerPhase.playing) return;
    if (!timeUp && !canMoveOn) return;
    phase = TestPlayerPhase.submitting;
    _ticker?.cancel();
    notifyListeners();
    try {
      final next = await _service.submitPart(
          codeId!, s.partIndex, Map.of(answers));
      await TestService.forgetAnswers(codeId!, s.partIndex);
      await player.stop();
      if (next.finished) {
        visitorResult = next.visitorResult ?? visitorResult;
        _finish(next.resultId);
      } else {
        await _apply(next, fresh: true);
      }
    } catch (e) {
      // A part closed by the server (clock, teacher): reload the open one.
      try {
        final again = await _service.start(codeId: codeId);
        await _apply(again, fresh: false);
      } catch (e2) {
        error = e2;
        phase = TestPlayerPhase.error;
        notifyListeners();
      }
    }
  }

  void _finish(String? id) {
    _ticker?.cancel();
    unawaited(player.stop());
    resultId = id ?? _attemptId;
    phase = TestPlayerPhase.finished;
    notifyListeners();
  }

  /// The tab or window lost focus / came back.
  void pageVisibility({required bool visible}) {
    if (phase != TestPlayerPhase.playing || codeId == null) return;
    unawaited(_service.reportEvent(codeId!, left: !visible));
    if (!visible) {
      leftNoticeShown = true;
      notifyListeners();
    }
  }

  void dismissLeftNotice() {
    leftNoticeShown = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _attemptSub?.cancel();
    _playerSub?.cancel();
    player.dispose();
    clipPlayer.dispose();
    super.dispose();
  }
}

/// The supervised test: start screen, then part by part under the server
/// clock, then the result card.
class TestPlayerScreen extends StatelessWidget {
  const TestPlayerScreen({super.key, this.token, this.codeId, this.backend});

  final String? token;
  final String? codeId;

  /// Build 3: a visitor's backend (public placement test); the signed-in
  /// student's functions when null.
  final TestPlayBackend? backend;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TestPlayerViewModel(backend ?? TestService(),
          token: token, codeId: codeId),
      child: const _PlayerView(),
    );
  }
}

class _PlayerView extends StatefulWidget {
  const _PlayerView();

  @override
  State<_PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<_PlayerView> {
  late final AppLifecycleListener _lifecycle;
  AppLifecycleState _last = AppLifecycleState.resumed;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    // On the web, leaving the tab or the window changes the lifecycle state.
    _lifecycle = AppLifecycleListener(onStateChange: (state) {
      final vm = context.read<TestPlayerViewModel>();
      final wasVisible = _last == AppLifecycleState.resumed;
      final visible = state == AppLifecycleState.resumed;
      _last = state;
      if (wasVisible != visible) vm.pageVisibility(visible: visible);
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _confirmNext(TestPlayerViewModel vm) async {
    final l = context.l10n;
    final last = !vm.partClocks || (vm.step?.isLastPart ?? true);
    final missing = vm.questions.length - vm.answeredCount;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(last ? l.testsFinishTitle : l.testsNextPartTitle),
        content: Text([
          if (missing > 0) l.exercisePlayUnansweredWarning(missing),
          last ? l.testsFinishBody : l.testsNextPartBody,
        ].join('\n\n')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.exercisePlayKeepAnswering),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(last ? l.testsFinish : l.testsNextPart),
          ),
        ],
      ),
    );
    if (ok == true) await vm.submitPart();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final vm = context.watch<TestPlayerViewModel>();
    if (vm.phase == TestPlayerPhase.finished && !_navigated) {
      _navigated = true;
      final id = vm.resultId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (vm.isVisitor) {
          context.go('/placement/result', extra: vm.visitorResult);
        } else if (id != null) {
          context.pushReplacement('/student/test-result/$id');
        } else {
          context.pop();
        }
      });
    }
    final facts = vm.facts;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.navy,
        // No way out while a part runs; elsewhere an explicit back arrow
        // (the implied one does not show on this pushed route on the web).
        automaticallyImplyLeading: false,
        leading: vm.phase == TestPlayerPhase.playing ||
                vm.phase == TestPlayerPhase.submitting
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go(vm.isVisitor ? '/placement' : '/student'),
              ),
        title: Text(
          facts == null ? l.testsTitle : '${facts.code} · ${facts.level}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (vm.phase == TestPlayerPhase.playing ||
              vm.phase == TestPlayerPhase.submitting)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: vm.secondsLeft <= 60
                        ? AppColors.error
                        : AppColors.navy,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    clockText(vm.secondsLeft),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: switch (vm.phase) {
        TestPlayerPhase.loading ||
        TestPlayerPhase.finished =>
          const Center(child: CircularProgressIndicator()),
        TestPlayerPhase.error => EmptyState(
            icon: Icons.error_outline,
            title: l.testsCouldNotOpen,
            subtitle: testErrorMessage(l, vm.error ?? ''),
          ),
        TestPlayerPhase.start => _StartScreen(vm: vm),
        TestPlayerPhase.playing ||
        TestPlayerPhase.submitting =>
          _PartView(vm: vm, onNext: () => _confirmNext(vm)),
      },
    );
  }
}

class _StartScreen extends StatelessWidget {
  const _StartScreen({required this.vm});

  final TestPlayerViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = vm.facts!;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (f.placement)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: PlacementChip(label: l.placementTestLabel),
                    ),
                  ),
                // Build 9D: a second sitting of the same code is practice.
                if (f.sittingNo > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      l.testsRepeatIntro(f.sittingNo),
                      style: TextStyle(
                          color: AppColors.chipAmberFg, fontWeight: FontWeight.w600),
                    ),
                  ),
                Text(
                  chineseExamType(f.family, f.levelKey),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                Text(
                  [
                    f.code,
                    f.level,
                    if (f.releaseYear != null) '${f.releaseYear}',
                  ].join(' · '),
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < f.parts.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${i + 1}. ${f.parts[i].skill.localized(l)} · '
                            '${l.testsQuestionsCount(f.parts[i].questions)}',
                          ),
                        ),
                        Text(
                          l.testsMinutesTotal(f.parts[i].minutes),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                const Divider(height: 24),
                Text(
                  l.testsRulesTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 6),
                for (final rule in [
                  if (f.partClocks) l.testsRulePartClocks else l.testsRuleOneClock,
                  if (f.partClocks) l.testsRuleRecording,
                  l.testsRuleNoBack,
                  l.testsRuleLeaving,
                  if (vm.isVisitor) l.placementRuleNoReview else l.testsRuleOnce,
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 18, color: AppColors.teal),
                        const SizedBox(width: 8),
                        Expanded(child: Text(rule)),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: vm.begin,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l.testsStart),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PartView extends StatelessWidget {
  const _PartView({required this.vm, required this.onNext});

  final TestPlayerViewModel vm;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = vm.step!;
    final qs = vm.questions;
    final q = qs.isEmpty ? null : qs[vm.current.clamp(0, qs.length - 1)];
    final last = !vm.partClocks || s.isLastPart;
    final heading = vm.partClocks
        ? '${l.testsPartOf(s.partIndex + 1, s.partCount)} · ${s.skill.localized(l)}'
        : l.testsWholePaper;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (vm.leftNoticeShown)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MaterialBanner(
              backgroundColor: AppColors.chipAmberBg,
              leading: Icon(Icons.visibility_off_outlined,
                  color: AppColors.chipAmberFg),
              content: Text(
                l.testsLeftNotice,
                style: TextStyle(color: AppColors.chipAmberFg),
              ),
              actions: [
                TextButton(
                  onPressed: vm.dismissLeftNotice,
                  child: Text(l.commonOk),
                ),
              ],
            ),
          ),
        Text(
          heading,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 10),
        if (vm.hasRecording) ...[
          _RecordingBar(vm: vm),
          const SizedBox(height: 12),
        ],
        if (qs.isEmpty)
          EmptyState(
            icon: Icons.inbox_outlined,
            title: l.testsPartEmptyTitle,
            subtitle: l.testsPartEmptySubtitle,
          )
        else ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < qs.length; i++)
                SizedBox(
                  width: 40,
                  height: 36,
                  child: OutlinedButton(
                    onPressed: () => vm.goTo(i),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: i == vm.current
                          ? AppColors.navy
                          : vm.answers.containsKey(qs[i].id)
                              ? AppColors.teal.withValues(alpha: 0.15)
                              : null,
                      foregroundColor:
                          i == vm.current ? Colors.white : AppColors.navy,
                    ),
                    child: Text('${i + 1}'),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l.exercisePlayAnsweredOf(vm.answeredCount, qs.length),
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          if (q!.section.isNotEmpty) ...[
            Text(
              q.section,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (q.audioUrl.isNotEmpty) ...[
            AppCard(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.volume_up_outlined, color: AppColors.teal),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.testsClipPlaysLeft(vm.clipPlaysLeft(q)),
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: vm.clipPlaysLeft(q) > 0 &&
                            vm.playingClip == null &&
                            !(vm.partClocks && vm.recordingPlaying)
                        ? () => vm.playClip(q)
                        : null,
                    icon: Icon(vm.playingClip == q.id
                        ? Icons.graphic_eq
                        : Icons.play_arrow),
                    label: Text(l.exercisePlayQuestionAudio),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          QuestionAnswerView(
            key: ValueKey('${s.partIndex}-${q.id}'),
            question: q,
            answer: vm.answers[q.id],
            onChanged: (a) => vm.answer(q, a),
            onSubmitted: () => vm.goTo(vm.current + 1),
            enabled: vm.phase == TestPlayerPhase.playing,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed:
                    vm.current == 0 ? null : () => vm.goTo(vm.current - 1),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: Text(l.exercisePlayBack),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: vm.current + 1 >= qs.length
                      ? null
                      : () => vm.goTo(vm.current + 1),
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: Text(l.exercisePlayNextQuestion),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: vm.canMoveOn ? onNext : null,
          style: FilledButton.styleFrom(
            backgroundColor: last ? AppColors.success : AppColors.navy,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          icon: vm.phase == TestPlayerPhase.submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(last ? Icons.check : Icons.skip_next),
          label: Text(last ? l.testsFinish : l.testsNextPart),
        ),
        if (vm.partClocks && vm.hasRecording && vm.recordingPlaying)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              l.testsWaitForRecording,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}

/// The part's recording. Part clocks: it starts with the part and has no
/// pause, seek or replay. One clock for the whole paper: play and replay.
class _RecordingBar extends StatelessWidget {
  const _RecordingBar({required this.vm});

  final TestPlayerViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final free = !vm.partClocks;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(
            vm.recordingPlaying ? Icons.graphic_eq : Icons.headphones,
            color: AppColors.teal,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.exercisePlayListeningRecording,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                StreamBuilder<Duration>(
                  stream: vm.player.positionStream,
                  builder: (context, pos) => Text(
                    vm.recordingFinished
                        ? l.testsRecordingDone
                        : '${clockText(pos.data?.inSeconds ?? 0)} / '
                            '${clockText(vm.player.duration?.inSeconds ?? 0)}',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          if (!free && vm.needsTapToResume)
            FilledButton.icon(
              onPressed: vm.resumeRecording,
              icon: const Icon(Icons.play_arrow),
              label: Text(l.testsContinueRecording),
            ),
          if (free)
            IconButton.filled(
              onPressed: () async {
                if (vm.recordingPlaying) {
                  await vm.player.pause();
                } else {
                  if (vm.recordingFinished) {
                    await vm.player.seek(Duration.zero);
                  }
                  await vm.player.play();
                }
              },
              icon: Icon(vm.recordingPlaying ? Icons.pause : Icons.play_arrow),
            ),
        ],
      ),
    );
  }
}

/// "Placement test" label (start screen, result card, supervision, the
/// Promotion screen).
class PlacementChip extends StatelessWidget {
  const PlacementChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.explore_outlined, size: 14, color: AppColors.teal),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.teal,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
