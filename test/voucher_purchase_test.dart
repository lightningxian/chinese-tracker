import 'package:chinese_tracker/features/payments/voucher_widgets.dart';
import 'package:chinese_tracker/models/invoice.dart';
import 'package:chinese_tracker/models/pricing_settings.dart';
import 'package:flutter_test/flutter_test.dart';

// Build 5: the buy sheet's packages, the terms gate, the invoice filters.
Invoice _inv(String id, InvoiceStatus status, String item, DateTime created, int amount) =>
    Invoice(
      id: id,
      invoiceNumber: id,
      studentId: 's',
      teacherId: 't',
      packageSize: 8,
      amount: amount,
      status: status,
      dueDate: '',
      priceItemId: item,
      createdAt: created,
    );

void main() {
  test('the flyer packages with Chinese names, cheapest first; one-time items left out', () {
    final offers = VoucherOffer.fromPricing(PricingSettings.defaults);
    expect(offers.map((o) => o.item.id), ['package8', 'package16']);
    expect(offers.first.title, '8次课程 · 8 class sessions');
    expect(offers.first.validDays, 60);
    expect(offers.first.item.sessions, 8);
  });

  test('a package without validity uses the Price list fallback; a switched-off one is not sold', () {
    const p = PricingSettings(termValidDays: 45, items: [
      PriceItem(id: 'a', name: 'A', price: 10, kind: PriceKind.sessions, sessions: 4),
      PriceItem(
          id: 'b', name: 'B', price: 5, kind: PriceKind.sessions, sessions: 2, active: false),
    ]);
    final offers = VoucherOffer.fromPricing(p);
    expect(offers.single.item.id, 'a');
    expect(offers.single.validDays, 45);
    expect(offers.single.title, 'A', reason: 'no Chinese name: the name alone');
  });

  test('Pay is enabled only with a package picked and the terms ticked', () {
    final offer = VoucherOffer.fromPricing(PricingSettings.defaults).first;
    expect(VoucherOffer.canPay(picked: null, accepted: true), isFalse);
    expect(VoucherOffer.canPay(picked: offer, accepted: false), isFalse);
    expect(VoucherOffer.canPay(picked: offer, accepted: true), isTrue);
  });

  test('invoice filters by status, item and month, and the total follows', () {
    final all = [
      _inv('1', InvoiceStatus.paid, 'package8', DateTime(2026, 11, 3), 2450000),
      _inv('2', InvoiceStatus.pending, 'package16', DateTime(2026, 11, 9), 3950000),
      _inv('3', InvoiceStatus.paid, 'package16', DateTime(2026, 10, 30), 3950000),
      _inv('4', InvoiceStatus.expired, 'package8', DateTime(2026, 11, 12), 2450000),
    ];
    expect(invoiceTotal(all), 12800000);
    final paid = filterInvoices(all, status: InvoiceStatus.paid);
    expect(paid.map((i) => i.id), ['1', '3']);
    expect(invoiceTotal(paid), 6400000);
    expect(filterInvoices(all, month: '2026-11').map((i) => i.id), ['1', '2', '4']);
    expect(filterInvoices(all, priceItemId: 'package16', month: '2026-11').single.id, '2');
  });
}
