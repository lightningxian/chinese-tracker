/// How a scanned paper became a worksheet (docs/PLAN.md, Build 1C, Must 6):
/// the number for the thesis test chapter. Saved on every question of the
/// worksheet when the proofreading screen saves; shown on the worksheet
/// screen to admins.
class PaperProofRecord {
  const PaperProofRecord({
    required this.slots,
    required this.flagged,
    required this.changed,
    required this.proofSeconds,
    required this.readSeconds,
    this.engine = '',
    this.savedAt,
  });

  /// Questions the format expects (80 on HSK 3).
  final int slots;

  /// Questions the reader flagged when the screen opened.
  final int flagged;

  /// Questions the admin changed before saving.
  final int changed;

  /// Time on the proofreading screen.
  final int proofSeconds;

  /// Time the reader took for the whole file.
  final int readSeconds;

  /// `paddle` or `tesseract`.
  final String engine;
  final DateTime? savedAt;

  int get untouched => slots - changed;

  factory PaperProofRecord.fromMap(Map<String, dynamic> m) => PaperProofRecord(
        slots: (m['slots'] as num?)?.toInt() ?? 0,
        flagged: (m['flagged'] as num?)?.toInt() ?? 0,
        changed: (m['changed'] as num?)?.toInt() ?? 0,
        proofSeconds: (m['proofSeconds'] as num?)?.toInt() ?? 0,
        readSeconds: (m['readSeconds'] as num?)?.toInt() ?? 0,
        engine: m['engine'] as String? ?? '',
        savedAt: DateTime.tryParse(m['savedAt'] as String? ?? ''),
      );

  Map<String, dynamic> toMap() => {
        'slots': slots,
        'flagged': flagged,
        'changed': changed,
        'proofSeconds': proofSeconds,
        'readSeconds': readSeconds,
        if (engine.isNotEmpty) 'engine': engine,
        if (savedAt != null) 'savedAt': savedAt!.toUtc().toIso8601String(),
      };
}
