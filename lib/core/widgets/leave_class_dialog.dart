import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../theme/app_theme.dart';

/// D8 leave-class confirmation aligned with Figma Make.
Future<bool?> showLeaveClassDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) {
      final l = ctx.l10n;
      return AlertDialog(
        title: Text(l.leaveClassTitle),
        content: Text(l.leaveClassBody),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.border),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.leaveClassStay),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l.studentClassLeaveClass),
          ),
        ],
      );
    },
  );
}
