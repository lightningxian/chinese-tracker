import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/paging/date_range.dart';
import '../../core/paging/paged_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/paging_bars.dart';
import '../../core/widgets/shell_nested_page.dart';
import '../../l10n/l10n.dart';
import '../../models/app_user.dart';
import '../../models/test_track.dart';
import '../../services/auth_service.dart';
import '../../services/test_service.dart';
import 'test_labels.dart';
import 'test_result_card.dart';

/// Staff: results grouped by code, with **Mark invalid** / **Mark valid**.
/// Admins see every result; teachers the results of sessions they opened.
class TestResultsScreen extends StatefulWidget {
  const TestResultsScreen({
    super.key,
    required this.basePath,
    this.codeId,
    this.embedded = false,
  });

  final String basePath;
  final String? codeId;
  final bool embedded;

  @override
  State<TestResultsScreen> createState() => _TestResultsScreenState();
}

class _TestResultsScreenState extends State<TestResultsScreen> {
  late String? _codeId = widget.codeId;
  late final AppUser _user = context.read<AuthService>().appUser!;
  late final Stream<List<TestCode>> _codes = TestService().watchCodes();

  /// Build 9 Then list: 25 results a page in a date range (all dates by
  /// default: a code's results span months); the code is a query filter.
  late final PagedController<TestResult> _pages = PagedController<TestResult>(
    build: (range) => TestService().resultSource(range,
        codeId: _codeId, openedBy: _user.isAdmin ? null : _user.uid),
    range: const DateRangeSel.all(),
  );

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ShellNestedPage(
      embedded: widget.embedded,
      title: l.testsResultsTitle,
      child: StreamBuilder<List<TestCode>>(
        stream: _codes,
        builder: (context, codesSnap) {
          final codes = codesSnap.data ?? const <TestCode>[];
          return ListenableBuilder(
            listenable: _pages,
            builder: (context, _) => PagedListBody<TestResult>(
              controller: _pages,
              padding: const EdgeInsets.all(16),
              separator: 8,
              emptyIcon: Icons.fact_check_outlined,
              emptyTitle: l.testsResultsEmptyTitle,
              emptySubtitle: l.testsResultsEmptySubtitle,
              header: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 220,
                        child: DropdownButtonFormField<String?>(
                          initialValue: _codeId,
                          isExpanded: true,
                          decoration: InputDecoration(
                              labelText: l.testsAllCodes, isDense: true),
                          items: [
                            DropdownMenuItem<String?>(
                                value: null, child: Text(l.testsAllCodes)),
                            for (final c in codes)
                              DropdownMenuItem<String?>(value: c.id, child: Text(c.code)),
                          ],
                          onChanged: (v) {
                            setState(() => _codeId = v);
                            _pages.reload();
                          },
                        ),
                      ),
                      if (_codeId != null)
                        OutlinedButton.icon(
                          onPressed: () => context.push(
                              '${widget.basePath}/leaderboard/${Uri.encodeComponent(_codeId!)}'),
                          icon: const Icon(Icons.emoji_events_outlined),
                          label: Text(l.leaderboardShort),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DateRangeBar(value: _pages.range, onChanged: _pages.setRange),
                ],
              ),
              itemBuilder: (context, r) => _ResultRow(result: r, basePath: widget.basePath),
            ),
          );
        },
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.result, required this.basePath});

  final TestResult result;
  final String basePath;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = result;
    final date =
        r.finishedAt == null ? '' : DateFormat.yMMMd().format(r.finishedAt!);
    return AppCard(
      onTap: () => context.push('$basePath/result/${r.id}'),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 220,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppUser.staffLabelOf(r.studentNameChinese, r.studentName),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                Text(
                  [
                    r.code,
                    date,
                    if (sittingLabel(l, r.sittingNo, repeat: r.isRepeat).isNotEmpty)
                      sittingLabel(l, r.sittingNo, repeat: r.isRepeat),
                  ].join(' · '),
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            r.parts.map((p) => '${p.mark}').join(' / '),
            style: TextStyle(color: AppColors.textSecondary),
          ),
          Text(
            '${r.total} / ${r.max}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          Text(
            !r.valid
                ? l.testsInvalid
                : r.isPendingMarking
                    ? '待评分 · ${l.testsPendingMarking}'
                    : r.passed
                        ? '合格 · ${l.testsPassed}'
                        : '不合格 · ${l.testsNotPassed}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: r.isPendingMarking
                  ? AppColors.chipAmberFg
                  : r.valid && r.passed
                      ? AppColors.success
                      : AppColors.error,
            ),
          ),
          if (r.leftCount > 0)
            Text(
              l.testsLeftPageCount(r.leftCount),
              style: TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ValidityButton(result: r),
        ],
      ),
    );
  }
}

/// **Mark invalid** (asks for a reason) or **Mark valid**.
class ValidityButton extends StatelessWidget {
  const ValidityButton({super.key, required this.result});

  final TestResult result;

  Future<void> _toggle(BuildContext context) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    var reason = '';
    if (result.valid) {
      final controller = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l.testsMarkInvalid),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l.testsInvalidReason,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l.testsMarkInvalid),
            ),
          ],
        ),
      );
      reason = controller.text.trim();
      controller.dispose();
      if (ok != true) return;
      if (reason.isEmpty) {
        messenger.showSnackBar(
            SnackBar(content: Text(l.testsErrorReasonRequired)));
        return;
      }
    }
    try {
      await TestService()
          .setValidity(result.id, valid: !result.valid, reason: reason);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(testErrorMessage(l, e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return OutlinedButton.icon(
      onPressed: () => _toggle(context),
      style: OutlinedButton.styleFrom(
        foregroundColor: result.valid ? AppColors.error : AppColors.success,
      ),
      icon: Icon(result.valid ? Icons.block : Icons.check_circle_outline,
          size: 18),
      label: Text(result.valid ? l.testsMarkInvalid : l.testsMarkValid),
    );
  }
}

/// Admin: **Reset attempt** (a power cut, a broken device). Deletes the
/// attempt and the result so the student can sit the code again; the
/// function writes the audit log.
class ResetAttemptButton extends StatelessWidget {
  const ResetAttemptButton({super.key, required this.result});

  final TestResult result;

  Future<void> _reset(BuildContext context) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.testsResetAttempt),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.testsResetAttemptBody(result.studentName, result.code)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l.testsResetReason,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l.testsResetAttempt),
          ),
        ],
      ),
    );
    final reason = controller.text.trim();
    controller.dispose();
    if (ok != true) return;
    try {
      await TestService().resetAttempt(result.id, reason: reason);
      messenger.showSnackBar(SnackBar(content: Text(l.testsResetDone)));
      if (router.canPop()) router.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(testErrorMessage(l, e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return OutlinedButton.icon(
      onPressed: () => _reset(context),
      style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
      icon: const Icon(Icons.restart_alt, size: 18),
      label: Text(l.testsResetAttempt),
    );
  }
}

/// One result card on screen with **Print / PDF**; staff also get the
/// validity button, the student a **Review** link once allowed.
class TestResultScreen extends StatelessWidget {
  const TestResultScreen({
    super.key,
    required this.resultId,
    this.embedded = false,
    this.staff = false,
  });

  final String resultId;
  final bool embedded;
  final bool staff;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return StreamBuilder<TestResult?>(
      stream: TestService().watchResult(resultId),
      builder: (context, snap) {
        final r = snap.data;
        return ShellNestedPage(
          embedded: embedded,
          title: l.testsCardTitle,
          actions: [
            if (r != null)
              OutlinedButton.icon(
                onPressed: () => printTestResultCard(r, l),
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: Text(l.testsPrintPdf),
              ),
          ],
          child: r == null
              ? Center(
                  child: snap.connectionState == ConnectionState.waiting
                      ? const CircularProgressIndicator()
                      : Text(l.testsResultNotFound),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Center(child: TestResultCard(result: r)),
                    const SizedBox(height: 16),
                    Center(
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: [
                          if (staff) ValidityButton(result: r),
                          // Build 2B: the board of this code.
                          if (r.valid && !r.isPendingMarking)
                            OutlinedButton.icon(
                              onPressed: () => context.push(staff
                                  ? '${context.read<AuthService>().appUser?.isAdmin == true ? '/admin' : '/teacher'}/tests/leaderboard/${Uri.encodeComponent(r.codeId)}'
                                  : '/student/test-leaderboard/${Uri.encodeComponent(r.codeId)}'),
                              icon: const Icon(Icons.emoji_events_outlined),
                              label: Text(l.leaderboardShort),
                            ),
                          if (staff &&
                              context.read<AuthService>().appUser?.isAdmin ==
                                  true)
                            ResetAttemptButton(result: r),
                          if (!staff)
                            OutlinedButton.icon(
                              onPressed: () => context.push(
                                  '/student/test-review/${Uri.encodeComponent(r.codeId)}'
                                  '?result=${Uri.encodeComponent(r.id)}'),
                              icon: const Icon(Icons.menu_book_outlined),
                              label: Text(l.testsOpenReview),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
