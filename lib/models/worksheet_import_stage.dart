/// Stages shown while importing a worksheet.
class WorksheetImportStage {
  const WorksheetImportStage({
    required this.label,
    required this.progress,
    this.stepIndex = 0,
    this.detail,
  });

  final String label;
  /// Overall progress from 0.0 to 1.0.
  final double progress;
  final int stepIndex;
  /// What is happening right now, e.g. "Page 2 of 3 · recognising text 45%".
  final String? detail;

  static const steps = [
    'Prepare file',
    'Read file',
    'Detect questions',
  ];

  factory WorksheetImportStage.prepare() =>
      const WorksheetImportStage(label: 'Preparing file…', progress: 0.05, stepIndex: 0);

  factory WorksheetImportStage.reading(double fraction, {String? detail}) =>
      WorksheetImportStage(
        label: 'Reading your worksheet…',
        progress: 0.1 + (fraction.clamp(0.0, 1.0) * 0.7),
        stepIndex: 1,
        detail: detail,
      );

  factory WorksheetImportStage.analyze() =>
      const WorksheetImportStage(label: 'Detecting question type…', progress: 0.88, stepIndex: 2);

  factory WorksheetImportStage.done() =>
      const WorksheetImportStage(label: 'Done', progress: 1.0, stepIndex: 3);
}
