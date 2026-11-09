import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/worksheet_import_stage.dart';

/// Modal progress while a worksheet is uploaded and processed.
///
/// Shows the stage, what is happening right now, the time elapsed and a rough
/// "time left" so a slow scan (OCR, first-time downloads) never looks stuck.
class WorksheetImportProgressDialog extends StatefulWidget {
  const WorksheetImportProgressDialog({
    super.key,
    required this.fileName,
    required this.progress,
  });

  final String fileName;
  final ValueListenable<WorksheetImportStage> progress;

  @override
  State<WorksheetImportProgressDialog> createState() =>
      _WorksheetImportProgressDialogState();
}

class _WorksheetImportProgressDialogState
    extends State<WorksheetImportProgressDialog> {
  final _stopwatch = Stopwatch()..start();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<WorksheetImportStage>(
      valueListenable: widget.progress,
      builder: (context, stage, _) => _buildDialog(stage),
    );
  }

  Widget _buildDialog(WorksheetImportStage stage) {
    final activeStep =
        stage.stepIndex.clamp(0, WorksheetImportStage.steps.length - 1);
    final fraction = stage.progress.clamp(0.0, 1.0);
    final elapsed = _stopwatch.elapsed;
    final timing = _timingLine(fraction, elapsed);

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
                    widget.fileName,
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
                value: fraction,
                minHeight: 8,
                backgroundColor: AppColors.border,
                color: AppColors.teal,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    timing,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  '${(fraction * 100).round()}%',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              stage.label,
              style: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (stage.detail != null && stage.detail!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                stage.detail!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
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
            const SizedBox(height: 8),
            const Text(
              'Text PDFs and Word files take a few seconds. Scanned pages and '
              'photos take 20–40 seconds each; the first scan also downloads '
              'the Chinese OCR data (about 15 MB).',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  /// "Elapsed 0:14 · about 20 s left". The estimate assumes the remaining
  /// work runs at the average speed so far, so it is only shown once there is
  /// enough progress to go on.
  static String _timingLine(double fraction, Duration elapsed) {
    final buffer = StringBuffer('Elapsed ${_clock(elapsed)}');
    if (fraction >= 0.995) return buffer.toString();
    if (elapsed.inSeconds < 3 || fraction < 0.12) {
      buffer.write(' · estimating time left…');
      return buffer.toString();
    }
    final remaining = elapsed.inMilliseconds * (1 - fraction) / fraction;
    final seconds = (remaining / 1000).ceil();
    if (seconds <= 5) {
      buffer.write(' · almost done');
    } else if (seconds < 60) {
      buffer.write(' · about ${((seconds + 4) ~/ 5) * 5} s left');
    } else if (seconds < 180) {
      buffer.write(' · about ${(seconds / 60).ceil()} min left');
    } else {
      buffer.write(' · a few minutes left');
    }
    return buffer.toString();
  }

  static String _clock(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
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
    builder: (ctx) => WorksheetImportProgressDialog(
      fileName: fileName,
      progress: progress,
    ),
  );
}
