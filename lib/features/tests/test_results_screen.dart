import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
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

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final user = context.read<AuthService>().appUser!;
    final service = TestService();
    return ShellNestedPage(
      embedded: widget.embedded,
      title: l.testsResultsTitle,
      child: StreamBuilder<List<TestResult>>(
        stream: service.watchResults(openedBy: user.isAdmin ? null : user.uid),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snap.data!;
          final codes = {for (final r in all) r.codeId: r.code}.entries.toList()
            ..sort((a, b) => a.value.compareTo(b.value));
          final shown =
              _codeId == null ? all : all.where((r) => r.codeId == _codeId);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (codes.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(l.testsAllCodes),
                      selected: _codeId == null,
                      onSelected: (_) => setState(() => _codeId = null),
                    ),
                    for (final c in codes)
                      ChoiceChip(
                        label: Text(c.value),
                        selected: _codeId == c.key,
                        onSelected: (_) => setState(() => _codeId = c.key),
                      ),
                  ],
                ),
              const SizedBox(height: 12),
              if (shown.isEmpty)
                EmptyState(
                  icon: Icons.fact_check_outlined,
                  title: l.testsResultsEmptyTitle,
                  subtitle: l.testsResultsEmptySubtitle,
                )
              else
                for (final r in shown)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ResultRow(result: r, basePath: widget.basePath),
                  ),
            ],
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
                  '${r.code} · $date',
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
                : r.passed
                    ? '合格 · ${l.testsPassed}'
                    : '不合格 · ${l.testsNotPassed}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: r.valid && r.passed ? AppColors.success : AppColors.error,
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
                          if (!staff)
                            OutlinedButton.icon(
                              onPressed: () => context.push(
                                  '/student/test-review/${Uri.encodeComponent(r.codeId)}'),
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
