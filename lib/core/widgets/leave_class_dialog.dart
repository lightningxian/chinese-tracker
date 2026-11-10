import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// D8 leave-class confirmation aligned with Figma Make.
Future<bool?> showLeaveClassDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Leave this class?'),
      content: const Text(
        'You will be removed from the class roster. You can join again '
        'from Home if the class is still open and has space.',
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Stay in class'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          child: const Text('Leave class'),
        ),
      ],
    ),
  );
}
