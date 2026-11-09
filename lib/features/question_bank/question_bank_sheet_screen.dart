import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../models/question_bank_item.dart';
import '../../services/firestore_service.dart';
import 'question_bank_screen.dart' show QuestionBankEditorSheet;
import 'question_bank_text.dart';

/// One worksheet in the bank: its questions in sheet order with the stored
/// answer. Tap a question to edit it; the trash icon removes it from the
/// sheet; the app-bar action deletes the whole sheet.
class QuestionBankSheetScreen extends StatelessWidget {
  const QuestionBankSheetScreen({
    super.key,
    required this.ownerId,
    required this.sheetKey,
  });

  final String ownerId;

  /// [QuestionBankItem.sheetKey] of the worksheet to show.
  final String sheetKey;

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    return StreamBuilder<List<QuestionBankItem>>(
      stream: firestore.watchQuestionBank(ownerId),
      builder: (context, snap) {
        final sheet = QuestionBankSheet.group(snap.data ?? const [])
            .where((s) => s.key == sheetKey)
            .firstOrNull;

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            backgroundColor: AppColors.card,
            foregroundColor: AppColors.navy,
            elevation: 0,
            title: Text(sheet?.title ?? sheetKey),
            actions: [
              if (sheet != null)
                TextButton.icon(
                  onPressed: () => _deleteSheet(context, sheet),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete worksheet'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: sheet == null
              ? (snap.connectionState == ConnectionState.waiting
                  ? const Center(child: CircularProgressIndicator())
                  : const EmptyState(
                      icon: Icons.description_outlined,
                      title: 'Worksheet removed',
                      subtitle: 'Its questions are no longer in the bank.',
                    ))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  children: [
                    _SheetHeader(sheet: sheet),
                    const SizedBox(height: 16),
                    for (final (i, item) in sheet.items.indexed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _QuestionRow(
                          index: i,
                          item: item,
                          onTap: () => _edit(context, item),
                          onDelete: () => _deleteQuestion(context, item),
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }

  Future<void> _edit(BuildContext context, QuestionBankItem item) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => QuestionBankEditorSheet(ownerId: ownerId, existing: item),
    );
  }

  Future<void> _deleteQuestion(
      BuildContext context, QuestionBankItem item) async {
    final ok = await _confirm(
      context,
      title: 'Remove this question?',
      body:
          'It leaves the worksheet and the bank. Exercises that already use it keep their copy.',
    );
    if (ok && context.mounted) {
      await context.read<FirestoreService>().deleteQuestionBankItem(item.id);
    }
  }

  Future<void> _deleteSheet(
      BuildContext context, QuestionBankSheet sheet) async {
    final ok = await _confirm(
      context,
      title: 'Delete worksheet ${sheet.code}?',
      body:
          'All ${QuestionBankText.questionCount(sheet.count)} leave the bank. '
          'Exercises that already use them keep their copies.',
    );
    if (!ok || !context.mounted) return;
    final navigator = Navigator.of(context);
    await context
        .read<FirestoreService>()
        .deleteQuestionBankItems(sheet.items.map((i) => i.id));
    if (navigator.canPop()) navigator.pop();
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String body,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.sheet});
  final QuestionBankSheet sheet;

  @override
  Widget build(BuildContext context) {
    final facts = [
      sheet.code,
      sheet.type.label,
      if (sheet.level != null && sheet.level!.isNotEmpty) sheet.level!,
      QuestionBankText.questionCount(sheet.count),
      if (sheet.usageCount > 0) 'used ${sheet.usageCount}×',
    ];
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.description_outlined,
              color: AppColors.navy, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sheet.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  facts.join(' · '),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                if (sheet.tags.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    sheet.tags.map((t) => '#$t').join('  '),
                    style: const TextStyle(fontSize: 13, color: AppColors.navy),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionRow extends StatelessWidget {
  const _QuestionRow({
    required this.index,
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  final int index;
  final QuestionBankItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '${index + 1}.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                height: 1.6,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayText.isEmpty ? '(no prompt)' : item.displayText,
                  style: AppTextStyles.question.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  QuestionBankText.answerLine(item),
                  style: AppTextStyles.questionDetail,
                ),
                if (item.question.imageUrl.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.question.imageUrl,
                        height: 120,
                        fit: BoxFit.contain,
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            tooltip: 'Remove from worksheet',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
