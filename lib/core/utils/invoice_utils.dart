import '../../models/invoice.dart';

/// Paid invoices of one calendar month.
class MonthlyIncome {
  const MonthlyIncome({
    required this.month,
    required this.total,
    required this.count,
  });

  /// First day of the month.
  final DateTime month;
  final int total;
  final int count;
}

abstract final class InvoiceUtils {
  static bool _paidIn(Invoice inv, int year, int month) {
    final at = inv.paidAt;
    return inv.isPaid && at != null && at.year == year && at.month == month;
  }

  /// Rupiah received in [month] (by `paidAt`), 0 when nothing was paid.
  static int paidTotalInMonth(Iterable<Invoice> invoices, DateTime month) =>
      invoices
          .where((i) => _paidIn(i, month.year, month.month))
          .fold(0, (sum, i) => sum + i.amount);

  /// The last [months] months, newest first, each with its paid total and
  /// invoice count (months without payments included, at 0).
  static List<MonthlyIncome> paidByMonth(
    Iterable<Invoice> invoices, {
    int months = 12,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    return [
      for (var i = 0; i < months; i++)
        () {
          final month = DateTime(today.year, today.month - i, 1);
          final paid =
              invoices.where((inv) => _paidIn(inv, month.year, month.month));
          return MonthlyIncome(
            month: month,
            total: paid.fold(0, (sum, inv) => sum + inv.amount),
            count: paid.length,
          );
        }(),
    ];
  }
}
