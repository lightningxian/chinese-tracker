import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/worksheet_import_stage.dart';

/// Modal progress while a worksheet is uploaded and processed.
class WorksheetImportProgressDialog extends StatelessWidget {
  const WorksheetImportProgressDialog({
    super.key,
    required this.fileName,
    required this.stage,
  });

  final String fileName;
  final WorksheetImportStage stage;

  @override
  Widget build(BuildContext context) {
    final activeStep = stage.stepIndex.clamp(0, WorksheetImportStage.steps.length - 1);

    return AlertDialog(
      title: const Text('Importing worksheet'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.insert_drive_file_outlined, color: AppColors.teal),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fileName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: stage.progress.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: AppColors.border,
                color: AppColors.teal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(stage.progress.clamp(0.0, 1.0) * 100).round()}%',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 12),
            Text(
              stage.label,
              style: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(WorksheetImportStage.steps.length, (index) {
              final done = index < activeStep;
              final active = index == activeStep;
              final icon = done
                  ? Icons.check_circle
                  : active
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off;
              final color = done
                  ? AppColors.success
                  : active
                      ? AppColors.teal
                      : AppColors.textSecondary;

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(icon, size: 18, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        WorksheetImportStage.steps[index],
                        style: TextStyle(
                          color: color,
                          fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

Future<void> showWorksheetImportProgress({
  required BuildContext context,
  required String fileName,
  required ValueNotifier<WorksheetImportStage> progress,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => ValueListenableBuilder<WorksheetImportStage>(
      valueListenable: progress,
      builder: (ctx, stage, _) => WorksheetImportProgressDialog(
        fileName: fileName,
        stage: stage,
      ),
    ),
  );
}
