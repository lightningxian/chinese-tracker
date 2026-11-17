import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../l10n/l10n.dart';
import '../../models/test_track.dart';
import '../../services/exercise_play_service.dart';
import '../../services/test_service.dart';
import 'test_labels.dart';

/// The review of a finished test as learning material (owner decision
/// 2026-11-16): every question with the student's answer, the key and the
/// explanation; recordings can be replayed. Opens once the teacher has
/// ended the session. There is never a retake.
class TestReviewScreen extends StatefulWidget {
  const TestReviewScreen({super.key, required this.codeId});

  final String codeId;

  @override
  State<TestReviewScreen> createState() => _TestReviewScreenState();
}

class _TestReviewScreenState extends State<TestReviewScreen> {
  late final Future<TestReview> _review = TestService().review(widget.codeId);
  final _player = AudioPlayer();
  String? _loaded;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _play(String url) async {
    try {
      if (_loaded != url) {
        await _player.setUrl(url);
        _loaded = url;
      } else {
        await _player.seek(Duration.zero);
      }
      await _player.play();
    } catch (e) {
      debugPrint('review audio: $e');
    }
  }

  String _answerText(PlayQuestion q, PlayAnswer? a) {
    if (a == null) return '—';
    if (a.index != null) {
      final i = a.index!;
      final letter = String.fromCharCode(65 + i);
      // A picture choice is stored as its own letter: show it once.
      return i < q.options.length &&
              q.options[i].isNotEmpty &&
              q.options[i] != letter
          ? '$letter · ${q.options[i]}'
          : letter;
    }
    if (a.order != null) return a.order!.join(' ');
    return a.text ?? '—';
  }

  String _keyText(PlayQuestion q, AnswerCheck c) {
    if (c.correctIndex != null) {
      final i = c.correctIndex!;
      final letter = String.fromCharCode(65 + i);
      // A picture choice is stored as its own letter: show it once.
      return i < q.options.length &&
              q.options[i].isNotEmpty &&
              q.options[i] != letter
          ? '$letter · ${q.options[i]}'
          : letter;
    }
    if (c.correctOrder.isNotEmpty) return c.correctOrder.join(' ');
    if (c.accepted.isNotEmpty) return c.accepted.join(' / ');
    return c.keyword;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.navy,
        title: Text(l.testsReviewTitle),
      ),
      body: FutureBuilder<TestReview>(
        future: _review,
        builder: (context, snap) {
          if (snap.hasError) {
            return EmptyState(
              icon: Icons.lock_clock_outlined,
              title: l.testsReviewNotYet,
              subtitle: testErrorMessage(l, snap.error!),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final review = snap.data!;
          int? lastPart;
          final children = <Widget>[];
          for (var i = 0; i < review.items.length; i++) {
            final it = review.items[i];
            if (it.partIndex != lastPart) {
              lastPart = it.partIndex;
              final rec = review.recordings[it.partIndex];
              children.add(Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.testsPartNumber(it.partIndex + 1),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (rec != null)
                      OutlinedButton.icon(
                        onPressed: () => _play(rec),
                        icon: const Icon(Icons.replay),
                        label: Text(l.exercisePlayListeningRecording),
                      ),
                  ],
                ),
              ));
              // The transcript under the (first) recording (Build 1B).
              if (rec != null &&
                  review.transcript.isNotEmpty &&
                  review.recordings.keys.reduce((a, b) => a < b ? a : b) ==
                      it.partIndex) {
                children.add(Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text(
                        l.paperTranscript,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SelectableText(
                            review.transcript,
                            style: const TextStyle(height: 1.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ));
              }
            }
            final q = it.question;
            final c = it.check;
            // Build 2A: the teacher's mark, else the machine's credit.
            final marked = c.markedPoints;
            final ok = marked != null
                ? marked >= (c.maxPoints ?? 1)
                : c.correct;
            final partial = !ok &&
                ((marked != null && marked > 0) || c.isHalf || c.needsMarking);
            children.add(Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          ok
                              ? Icons.check_circle
                              : c.needsMarking
                                  ? Icons.hourglass_top
                                  : partial
                                      ? Icons.star_half
                                      : Icons.cancel,
                          color: ok
                              ? AppColors.success
                              : partial
                                  ? AppColors.chipAmberFg
                                  : AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${i + 1}. ${q.prompt.isEmpty ? q.section : q.prompt}',
                            style: AppTextStyles.question.copyWith(fontSize: 17),
                          ),
                        ),
                        if (q.audioUrl.isNotEmpty)
                          IconButton(
                            onPressed: () => _play(q.audioUrl),
                            icon: const Icon(Icons.volume_up_outlined),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('${l.testsYourAnswer}: ${_answerText(q, it.answer)}'),
                    if (marked != null)
                      Text(
                        l.testsMarkedPoints(_pts(marked), _pts(c.maxPoints ?? 1)),
                        style: TextStyle(color: AppColors.chipAmberFg),
                      )
                    else if (c.needsMarking)
                      Text(
                        c.isHalf ? l.playHalfWaiting : l.playWaitingForTeacher,
                        style: TextStyle(color: AppColors.chipAmberFg),
                      ),
                    if (c.keywords.isNotEmpty)
                      Text(l.bankTextKeywords(c.keywords.join(', ')),
                          style: TextStyle(color: AppColors.textSecondary)),
                    // Free writing has no key (a teacher marks it).
                    if (_keyText(q, it.check).isNotEmpty)
                    Text(
                      '${l.testsKey}: ${_keyText(q, it.check)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                    if (it.check.explanation.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        it.check.explanation,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
            ));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: children,
          );
        },
      ),
    );
  }
}

/// Keeps the [TestSkill] import used for the part headings' skill names.
String reviewPartLabel(AppLocalizations l, TestSkill skill) =>
    skill.localized(l);

String _pts(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
