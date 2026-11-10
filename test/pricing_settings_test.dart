import 'package:chinese_tracker/models/pricing_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('old document without items still yields the four flyer rows', () {
    final p = PricingSettings.fromMap({
      'package8': 2000000,
      'package16': 3500000,
      'book': 200000,
      'registration': 50000,
      'termValidDays': 90,
    });
    expect(p.items, hasLength(4));
    expect(p.package8, 2000000);
    expect(p.package16, 3500000);
    expect(p.book, 200000);
    expect(p.registration, 50000);
    expect(p.termValidDays, 90);
    expect(p.itemForSessions(8)!.id, 'package8');
  });

  test('items are the source of truth and legacy fields are derived', () {
    final p = PricingSettings.fromMap({
      'items': [
        {
          'id': 'trial',
          'name': 'Trial class',
          'price': 150000,
          'kind': 'sessions',
          'sessions': 1
        },
        {
          'id': 'package8',
          'name': '8 sessions',
          'price': 2450000,
          'kind': 'sessions',
          'sessions': 8
        },
        {'id': 'book', 'name': 'Book', 'price': 250000, 'kind': 'book'},
      ],
      'package8': 1, // ignored when items exist
    });
    expect(p.items, hasLength(3));
    expect(p.package8, 2450000);
    expect(p.package16, 3950000); // default when no 16-session row
    expect(p.book, 250000);
    expect(p.sessionItems.map((i) => i.id), ['trial', 'package8']);
    expect(p.itemById('book')!.creditsSessions, isFalse);
    final map = p.toMap();
    expect((map['items'] as List), hasLength(3));
    expect(map['package8'], 2450000);
  });

  test('rows with no id or price are dropped', () {
    final p = PricingSettings.fromMap({
      'items': [
        {'id': '', 'name': 'x', 'price': 10, 'kind': 'other'},
        {'id': 'ok', 'name': 'ok', 'price': 0, 'kind': 'other'},
      ],
    });
    // Nothing valid → falls back to the flyer defaults.
    expect(p.items, hasLength(4));
  });
}
