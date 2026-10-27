import 'package:cloud_firestore/cloud_firestore.dart';

/// Prices and term validity, stored at `settings/pricing`.
///
/// Readable by everyone (the public landing page shows them); only admins
/// write. The server (`functions/index.js`) reads the same document when it
/// creates an invoice, so the amount a student pays always matches what the
/// admin set here. Defaults are the course flyer (Oct 2026).
class PricingSettings {
  const PricingSettings({
    this.package8 = 2450000,
    this.package16 = 3950000,
    this.book = 250000,
    this.registration = 100000,
    this.termValidDays = 60,
    this.updatedAt,
    this.updatedBy,
  });

  /// Whole rupiah.
  final int package8;
  final int package16;
  final int book;
  final int registration;

  /// How long a paid term stays valid after purchase (flyer: 2 months).
  final int termValidDays;
  final DateTime? updatedAt;
  final String? updatedBy;

  static const defaults = PricingSettings();

  int priceForPackage(int packageSize) => switch (packageSize) {
        8 => package8,
        16 => package16,
        _ => 0,
      };

  factory PricingSettings.fromMap(Map<String, dynamic>? data) {
    final m = data ?? const {};
    int read(String key, int fallback) {
      final v = m[key];
      return v is num && v > 0 ? v.toInt() : fallback;
    }

    return PricingSettings(
      package8: read('package8', defaults.package8),
      package16: read('package16', defaults.package16),
      book: read('book', defaults.book),
      registration: read('registration', defaults.registration),
      termValidDays: read('termValidDays', defaults.termValidDays),
      updatedAt: (m['updatedAt'] as Timestamp?)?.toDate(),
      updatedBy: m['updatedBy'] as String?,
    );
  }

  factory PricingSettings.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) =>
      PricingSettings.fromMap(doc.data());

  Map<String, dynamic> toMap() => {
        'package8': package8,
        'package16': package16,
        'book': book,
        'registration': registration,
        'termValidDays': termValidDays,
      };

  PricingSettings copyWith({
    int? package8,
    int? package16,
    int? book,
    int? registration,
    int? termValidDays,
  }) =>
      PricingSettings(
        package8: package8 ?? this.package8,
        package16: package16 ?? this.package16,
        book: book ?? this.book,
        registration: registration ?? this.registration,
        termValidDays: termValidDays ?? this.termValidDays,
        updatedAt: updatedAt,
        updatedBy: updatedBy,
      );
}
