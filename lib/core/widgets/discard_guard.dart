import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../theme/app_theme.dart';

/// Owner 2026-11-24: "when I open something and edit it, Cancel should ask
/// first". Asks before leaving with unsaved changes.
Future<bool> confirmDiscardChanges(BuildContext context) async {
  final l = context.l10n;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.discardTitle),
      content: Text(l.discardBody),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.discardKeepEditing)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l.discardConfirm),
        ),
      ],
    ),
  );
  return ok == true;
}

/// Wraps an editor (a page, a dialog or a sheet): the back button, a tap
/// outside a dialog and every **Cancel** that calls `Navigator.maybePop`
/// ask first when [isDirty] says something changed. Saving still closes at
/// once (`Navigator.pop` does not ask).
class DiscardGuard extends StatelessWidget {
  const DiscardGuard({super.key, required this.isDirty, required this.child});

  final bool Function() isDirty;
  final Widget child;

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final navigator = Navigator.of(context);
          if (!isDirty() || await confirmDiscardChanges(context)) {
            navigator.pop(result);
          }
        },
        child: child,
      );
}
