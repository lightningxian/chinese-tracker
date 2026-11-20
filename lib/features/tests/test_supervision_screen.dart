import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/shell_nested_page.dart';
import '../../l10n/l10n.dart';
import '../../models/app_user.dart';
import '../../models/test_track.dart';
import '../../services/test_service.dart';
import 'test_labels.dart';
import 'test_player_screen.dart' show PlacementChip;

/// ViewModel of the supervision screen: the session, its attempts (live),
/// and a one-second tick for the countdowns.
class TestSupervisionViewModel extends ChangeNotifier {
  TestSupervisionViewModel(this._service, this.sessionId) {
    _sessionSub = _service.watchSession(sessionId).listen((s) {
      session = s;
      notifyListeners();
    });
    _attemptSub = _service.watchSessionAttempts(sessionId).listen((a) {
      attempts = a;
      notifyListeners();
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      now = DateTime.now();
      notifyListeners();
    });
  }

  final TestService _service;
  final String sessionId;
  late final StreamSubscription<TestSession?> _sessionSub;
  late final StreamSubscription<List<TestAttempt>> _attemptSub;
  late final Timer _ticker;

  TestSession? session;
  List<TestAttempt> attempts = const [];
  DateTime now = DateTime.now();
  bool busy = false;

  int get joinSecondsLeft {
    final until = session?.joinUntil;
    if (until == null) return 0;
    return until.difference(now).inSeconds.clamp(0, 24 * 3600);
  }

  int secondsLeft(TestAttempt a) {
    final end = a.partEndsAt;
    if (end == null || a.finished) return 0;
    return end.difference(now).inSeconds.clamp(0, 24 * 3600);
  }

  Future<void> newToken() async {
    busy = true;
    notifyListeners();
    try {
      await _service.newToken(sessionId);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<int> endForEveryone() async {
    busy = true;
    notifyListeners();
    try {
      return await _service.closeSession(sessionId);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sessionSub.cancel();
    _attemptSub.cancel();
    _ticker.cancel();
    super.dispose();
  }
}

/// Supervision: the token in very large type with the join countdown,
/// **New token**, one row per student (part, time left, left-page count,
/// status) and **End test for everyone**.
class TestSupervisionScreen extends StatelessWidget {
  const TestSupervisionScreen({
    super.key,
    required this.sessionId,
    required this.basePath,
    this.embedded = false,
  });

  final String sessionId;

  /// `/admin/tests` or `/teacher/tests`.
  final String basePath;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TestSupervisionViewModel(TestService(), sessionId),
      child: _SupervisionView(embedded: embedded, basePath: basePath),
    );
  }
}

class _SupervisionView extends StatelessWidget {
  const _SupervisionView({required this.embedded, required this.basePath});

  final bool embedded;
  final String basePath;

  Future<void> _end(BuildContext context) async {
    final l = context.l10n;
    final vm = context.read<TestSupervisionViewModel>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.testsEndForEveryone),
        content: Text(l.testsEndForEveryoneConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.testsEndForEveryone),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final n = await vm.endForEveryone();
      messenger.showSnackBar(SnackBar(content: Text(l.testsEnded(n))));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(testErrorMessage(l, e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final vm = context.watch<TestSupervisionViewModel>();
    final session = vm.session;
    if (session == null) {
      return ShellNestedPage(
        embedded: embedded,
        title: l.testsSupervisionTitle,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    final joinLeft = vm.joinSecondsLeft;
    final open = session.isOpen;
    return ShellNestedPage(
      embedded: embedded,
      title: '${l.testsSupervisionTitle} · ${session.code}',
      actions: [
        OutlinedButton.icon(
          onPressed: () => context.push(
              '$basePath/results?code=${Uri.encodeComponent(session.codeId)}'),
          icon: const Icon(Icons.fact_check_outlined, size: 18),
          label: Text(l.testsResultsTitle),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              children: [
                if (session.placement)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: PlacementChip(label: l.placementSessionLabel),
                  ),
                Text(
                  '${session.code} · ${session.level}',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  session.partClocks
                      ? l.testsPartClocksOn
                      : l.testsPartClocksOff,
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 12),
                if (open) ...[
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SelectableText(
                      session.token,
                      style: TextStyle(
                        fontSize: 96,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 12,
                        color: AppColors.navy,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    joinLeft > 0
                        ? l.testsJoinCountdown(clockText(joinLeft))
                        : l.testsJoinClosed,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: joinLeft > 0
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                  ),
                  if (joinLeft > 0) ...[
                    const SizedBox(height: 12),
                    // Build 2A: scanning opens the token page with the
                    // token filled in. White behind the code so phones read
                    // it in dark mode too.
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: QrImageView(
                        // Build 3: a placement code's QR opens the public
                        // placement page (visitors have no account).
                        data: session.visitorsAllowed
                            ? placementTokenLink(session.token)
                            : tokenLink(session.token),
                        size: 180,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                        session.visitorsAllowed
                            ? l.placementScanToJoin
                            : l.testsScanToJoin,
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ],
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: vm.busy ? null : vm.newToken,
                        icon: const Icon(Icons.refresh),
                        label: Text(l.testsNewToken),
                      ),
                      FilledButton.icon(
                        onPressed: vm.busy ? null : () => _end(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        icon: const Icon(Icons.stop_circle_outlined),
                        label: Text(l.testsEndForEveryone),
                      ),
                    ],
                  ),
                ] else
                  Text(
                    l.testsSessionClosed,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l.testsStudentsCount(vm.attempts.length),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          if (vm.attempts.isEmpty)
            EmptyState(
              icon: Icons.people_outline,
              title: l.testsNoStudentsYetTitle,
              subtitle: l.testsNoStudentsYetSubtitle,
            )
          else
            for (final a in vm.attempts)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _AttemptRow(attempt: a, secondsLeft: vm.secondsLeft(a)),
              ),
        ],
      ),
    );
  }
}

class _AttemptRow extends StatelessWidget {
  const _AttemptRow({required this.attempt, required this.secondsLeft});

  final TestAttempt attempt;
  final int secondsLeft;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = attempt;
    final left = a.leftCount;
    final status = a.finished
        ? l.testsStatusFinished
        : l.testsStatusSitting;
    final part = a.finished
        ? '—'
        : a.partClocks
            ? l.testsPartOf(a.partIndex + 1, a.partCount)
            : l.testsWholePaper;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Wrap(
        spacing: 16,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 220,
            child: Text(
              a.visitor
                  ? l.placementVisitorRow(a.studentName)
                  : AppUser.staffLabelOf(a.studentNameChinese, a.studentName),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
          ),
          Text(part),
          Text(
            a.finished ? '—' : clockText(secondsLeft),
            style: TextStyle(
              fontFeatures: const [FontFeature.tabularFigures()],
              fontWeight: FontWeight.w600,
              color: !a.finished && secondsLeft <= 60
                  ? AppColors.error
                  : AppColors.textPrimary,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: left >= 1 ? AppColors.error : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: left >= 1 ? AppColors.error : AppColors.border,
              ),
            ),
            child: Text(
              l.testsLeftPageCount(left),
              style: TextStyle(
                color: left >= 1 ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            status,
            style: TextStyle(
              color: a.finished ? AppColors.success : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// The address a phone opens from the token's QR code: the student's test
/// page with the token filled in (the same page the Tests tab opens).
/// Build 3: the public placement page with the token filled in.
String placementTokenLink(String token) =>
    '${Uri.base.origin}/placement?token=${Uri.encodeComponent(token)}';

String tokenLink(String token) =>
    '${Uri.base.origin}/student/test?token=${Uri.encodeComponent(token)}';
