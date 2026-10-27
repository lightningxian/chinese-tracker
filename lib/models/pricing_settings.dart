import 'package:cloud_firestore/cloud_firestore.dart';

/// What a price-list item gives the student when its invoice is paid.
enum PriceKind {
  sessions('sessions', 'Class sessions'),
  book('book', 'Book / materials'),
  registration('registration', 'Registration'),
  other('other', 'Other');

  const PriceKind(this.value, this.label);

  final String value;
  final String label;

  static PriceKind fromValue(String? value) => PriceKind.values.firstWhere(
        (k) => k.value == value,
        orElse: () => PriceKind.other,
      );
}

/// One row of the admin Price list: something a payment can be for.
class PriceItem {
  const PriceItem({
    required this.id,
    required this.name,
    required this.price,
    required this.kind,
    this.sessions = 0,
  });

  final String id;
  final String name;

  /// Whole rupiah.
  final int price;
  final PriceKind kind;

  /// Sessions credited when [kind] is [PriceKind.sessions]; 0 otherwise.
  final int sessions;

  bool get creditsSessions => kind == PriceKind.sessions && sessions > 0;

  String get givesLabel => switch (kind) {
        PriceKind.sessions => '$sessions sessions',
        PriceKind.book => 'book / materials, no sessions',
        PriceKind.registration => 'registration, no sessions',
        PriceKind.other => 'no sessions',
      };

  factory PriceItem.fromMap(Map<String, dynamic> m) {
    final kind = PriceKind.fromValue(m['kind'] as String?);
    return PriceItem(
      id: m['id'] as String? ?? '',
      name: m['name'] as String? ?? '',
      price: (m['price'] as num?)?.toInt() ?? 0,
      kind: kind,
      sessions: kind == PriceKind.sessions
          ? (m['sessions'] as num?)?.toInt() ?? 0
          : 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'price': price,
        'kind': kind.value,
        'sessions': sessions,
      };

  PriceItem copyWith({
    String? name,
    int? price,
    PriceKind? kind,
    int? sessions,
  }) =>
      PriceItem(
        id: id,
        name: name ?? this.name,
        price: price ?? this.price,
        kind: kind ?? this.kind,
        sessions: sessions ?? this.sessions,
      );
}

/// The Price list and term validity, stored at `settings/pricing`.
///
/// Readable by everyone (the public landing page shows the prices); only
/// admins write. The server (`functions/index.js`) reads the same document
/// when it creates or settles an invoice, so the amount charged always
/// matches what the admin set here. Defaults are the course flyer (Oct 2026).
///
/// `items` is the source of truth. The legacy fields (`package8`,
/// `package16`, `book`, `registration`) are still written for older builds
/// and read when `items` is missing.
class PricingSettings {
  const PricingSettings({
    this.items = defaultItems,
    this.termValidDays = 60,
    this.updatedAt,
    this.updatedBy,
  });

  static const defaultItems = [
    PriceItem(
      id: 'registration',
      name: 'Registration (one-time)',
      price: 100000,
      kind: PriceKind.registration,
    ),
    PriceItem(
      id: 'package8',
      name: '8 class sessions',
      price: 2450000,
      kind: PriceKind.sessions,
      sessions: 8,
    ),
    PriceItem(
      id: 'package16',
      name: '16 class sessions',
      price: 3950000,
      kind: PriceKind.sessions,
      sessions: 16,
    ),
    PriceItem(
      id: 'book',
      name: 'HSK materials & book',
      price: 250000,
      kind: PriceKind.book,
    ),
  ];

  static const defaults = PricingSettings();

  final List<PriceItem> items;

  /// How long a paid term stays valid after purchase (flyer: 2 months).
  final int termValidDays;
  final DateTime? updatedAt;
  final String? updatedBy;

  PriceItem? itemById(String? id) {
    if (id == null) return null;
    for (final it in items) {
      if (it.id == id) return it;
    }
    return null;
  }

  PriceItem? itemForSessions(int sessions) {
    for (final it in items) {
      if (it.kind == PriceKind.sessions && it.sessions == sessions) return it;
    }
    return null;
  }

  PriceItem? _firstOfKind(PriceKind kind) {
    for (final it in items) {
      if (it.kind == kind) return it;
    }
    return null;
  }

  List<PriceItem> get sessionItems =>
      items.where((i) => i.creditsSessions).toList();

  // Legacy views used by the landing page and older screens.
  int get package8 => itemForSessions(8)?.price ?? 2450000;
  int get package16 => itemForSessions(16)?.price ?? 3950000;
  int get book => _firstOfKind(PriceKind.book)?.price ?? 250000;
  int get registration =>
      _firstOfKind(PriceKind.registration)?.price ?? 100000;

  int priceForPackage(int packageSize) =>
      itemForSessions(packageSize)?.price ?? 0;

  factory PricingSettings.fromMap(Map<String, dynamic>? data) {
    final m = data ?? const {};
    int read(String key, int fallback) {
      final v = m[key];
      return v is num && v > 0 ? v.toInt() : fallback;
    }

    final rawItems = (m['items'] as List?)
            ?.whereType<Map>()
            .map((e) => PriceItem.fromMap(Map<String, dynamic>.from(e)))
            .where((i) => i.id.isNotEmpty && i.price > 0)
            .toList() ??
        const <PriceItem>[];

    final items = rawItems.isNotEmpty
        ? rawItems
        // Older document: rebuild the list from the four legacy prices.
        : [
            for (final d in defaultItems)
              d.copyWith(
                price: switch (d.id) {
                  'package8' => read('package8', d.price),
                  'package16' => read('package16', d.price),
                  'book' => read('book', d.price),
                  'registration' => read('registration', d.price),
                  _ => d.price,
                },
              ),
          ];

    return PricingSettings(
      items: items,
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
        'items': items.map((i) => i.toMap()).toList(),
        'package8': package8,
        'package16': package16,
        'book': book,
        'registration': registration,
        'termValidDays': termValidDays,
      };

  PricingSettings copyWith({
    List<PriceItem>? items,
    int? termValidDays,
  }) =>
      PricingSettings(
        items: items ?? this.items,
        termValidDays: termValidDays ?? this.termValidDays,
        updatedAt: updatedAt,
        updatedBy: updatedBy,
      );
}
