import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../l10n/l10n.dart';
import '../../models/app_user.dart';
import '../../models/test_track.dart';
import '../../services/test_service.dart';

/// The student's **Tests** place: type the token from the teacher, continue
/// a test after a reload, and the list of the student's own results.
class StudentTestsTab extends StatefulWidget {
  const StudentTestsTab({super.key, required this.student});

  final AppUser student;

  @override
  State<StudentTestsTab> createState() => _StudentTestsTabState();
}

class _StudentTestsTabState extends State<StudentTestsTab> {
  final _token = TextEditingController();
  final _service = TestService();

  @override
  void dispose() {
    _token.dispose();
    super.dispose();
  }

  void _enter() {
    final t = _token.text.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    if (t.length != 6) return;
    _token.clear();
    context.push('/student/test?token=${Uri.encodeComponent(t)}');
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.testsEnterToken,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l.testsEnterTokenHint,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _token,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 6,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[A-Za-z0-9]')),
                      ],
                      style: const TextStyle(
                        fontSize: 24,
                        letterSpacing: 6,
                        fontWeight: FontWeight.w800,
                      ),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        counterText: '',
                        hintText: 'ABC234',
                      ),
                      onSubmitted: (_) => _enter(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _enter,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 18),
                    ),
                    child: Text(l.testsGo),
                  ),
                ],
              ),
            ],
          ),
        ),
        StreamBuilder<List<TestAttempt>>(
          stream: _service.watchMyOpenAttempts(widget.student.uid),
          builder: (context, snap) {
            final open = snap.data ?? const <TestAttempt>[];
            if (open.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                children: [
                  for (final a in open)
                    AppCard(
                      onTap: () => context.push(
                          '/student/test?code=${Uri.encodeComponent(a.codeId)}'),
                      child: Row(
                        children: [
                          Icon(Icons.play_circle_fill, color: AppColors.teal),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l.testsContinueTest(a.codeId),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        Text(
          l.testsMyResults,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<TestResult>>(
          stream: _service.watchMyResults(widget.student.uid),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final results = snap.data!;
            if (results.isEmpty) {
              return EmptyState(
                icon: Icons.emoji_events_outlined,
                title: l.testsMyResultsEmptyTitle,
                subtitle: l.testsMyResultsEmptySubtitle,
              );
            }
            return Column(
              children: [
                for (final r in results)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      onTap: () => context.push('/student/test-result/${r.id}'),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${r.examTypeChinese} · ${r.code}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.navy,
                                  ),
                                ),
                                if (r.finishedAt != null)
                                  Text(
                                    DateFormat.yMMMd().format(r.finishedAt!),
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            '${r.total} / ${r.max}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            !r.valid
                                ? l.testsInvalid
                                : r.isPendingMarking
                                    ? l.testsPendingMarking
                                    : r.passed
                                        ? '合格'
                                        : '不合格',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: r.isPendingMarking
                                  ? AppColors.chipAmberFg
                                  : r.valid && r.passed
                                      ? AppColors.success
                                      : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
