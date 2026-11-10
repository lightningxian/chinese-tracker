import 'package:chinese_tracker/core/utils/csv_export.dart';
import 'package:chinese_tracker/core/utils/invoice_utils.dart';
import 'package:chinese_tracker/models/invoice.dart';
import 'package:flutter_test/flutter_test.dart';

Invoice _invoice(String id, int amount, InvoiceStatus status, DateTime? paid) =>
    Invoice(
      id: id,
      invoiceNumber: id,
      studentId: 's1',
      teacherId: 't1',
      packageSize: 8,
      amount: amount,
      status: status,
      dueDate: '2026-11-30',
      paidAt: paid,
    );

void main() {
  group('CsvExport', () {
    test('quotes commas, quotes and line breaks; null is empty', () {
      expect(CsvExport.cell('plain'), 'plain');
      expect(CsvExport.cell('a,b'), '"a,b"');
      expect(CsvExport.cell('say "hi"'), '"say ""hi"""');
      expect(CsvExport.cell('two\nlines'), '"two\nlines"');
      expect(CsvExport.cell(null), '');
      expect(CsvExport.cell(12), '12');
    });

    test('builds header and rows with CRLF line ends', () {
      final csv = CsvExport.build(
        header: ['Name', 'Level'],
        rows: [
          ['Ani', 'HSK 1'],
          ['Budi, Jr', null],
        ],
      );
      expect(csv, 'Name,Level\r\nAni,HSK 1\r\n"Budi, Jr",\r\n');
    });
  });

  group('InvoiceUtils', () {
    final now = DateTime(2026, 11, 10);
    final invoices = [
      _invoice('a', 1000, InvoiceStatus.paid, DateTime(2026, 11, 2)),
      _invoice('b', 500, InvoiceStatus.paid, DateTime(2026, 11, 9)),
      _invoice('c', 700, InvoiceStatus.paid, DateTime(2026, 10, 20)),
      _invoice('d', 900, InvoiceStatus.pending, null),
      _invoice('e', 300, InvoiceStatus.paid, DateTime(2025, 11, 5)),
    ];

    test('this month counts only invoices paid in it', () {
      expect(InvoiceUtils.paidTotalInMonth(invoices, now), 1500);
      expect(InvoiceUtils.paidTotalInMonth(const [], now), 0);
    });

    test('twelve months newest first, zero months kept', () {
      final months = InvoiceUtils.paidByMonth(invoices, now: now);
      expect(months.length, 12);
      expect(months.first.month, DateTime(2026, 11, 1));
      expect(months.first.total, 1500);
      expect(months.first.count, 2);
      expect(months[1].total, 700);
      expect(months[2].total, 0);
      expect(months[2].count, 0);
      expect(months.last.month, DateTime(2025, 12, 1));
      // November 2025 is thirteen months back and falls outside the window.
      expect(months.any((m) => m.total == 300), isFalse);
    });
  });
}
