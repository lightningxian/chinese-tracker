import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../l10n/l10n.dart';
import '../../models/exercise_category.dart';
import '../../models/question_bank_item.dart';
import '../../services/firestore_service.dart';

/// Standard Course (owner 2026-11-25): the **Lesson text** of a worksheet,
/// the textbook dialogues and new words that **Scan paper** read from the
/// lesson's textbook pages. Students open it while answering. Shown on a
/// Standard Course worksheet, or on any worksheet that has one.
class SheetContextCard extends StatelessWidget {
  const SheetContextCard({
    super.key,
    required this.sheet,
    required this.readOnly,
  });

  final QuestionBankSheet sheet;
  final bool readOnly;

  static bool shows(QuestionBankSheet sheet) =>
      sheet.isSheet &&
      (sheet.context != null ||
          sheet.first.category == ExerciseCategory.standardCourse);

  Future<void> _edit(BuildContext context) async {
    final l = context.l10n;
    final controller = TextEditingController(text: sheet.context ?? '');
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.bankContextEdit),
        content: SizedBox(
          width: 560,
          child: TextField(
            controller: controller,
            minLines: 10,
            maxLines: 22,
            decoration: InputDecoration(
              helperText: l.paperContextHint,
              helperMaxLines: 3,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.maybePop(ctx),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(l.bankEditorSave),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text == null || !context.mounted) return;
    await context.read<FirestoreService>().setQuestionBankContext(
          sheet.items.map((i) => i.id),
          text,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.bankContextSaved)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = sheet.context;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_outlined, color: AppColors.navy),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l.bankContextTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
              ),
              if (!readOnly)
                TextButton.icon(
                  onPressed: () => _edit(context),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(l.bankContextEdit),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (text == null)
            Text(
              l.bankContextNone,
              style: TextStyle(color: AppColors.textSecondary),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: SingleChildScrollView(
                child: SelectableText(
                  text,
                  style: const TextStyle(height: 1.7),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
