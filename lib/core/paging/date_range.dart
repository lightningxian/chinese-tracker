import 'package:intl/intl.dart';

/// Build 9A (supervisor 2026-11-25): the date range of a long list.
///
/// The range is a pair of calendar days in Jakarta time, both included.
/// `from == null` / `to == null` means open on that side ("all").
enum RangePreset { today, last7, thisMonth, lastMonth, thisYear, all, custom }

class DateRangeSel {
  const DateRangeSel._(this.preset, this.from, this.to);

  /// A preset counted from [now] (Jakarta calendar day; defaults to the
  /// current Jakarta day).
  factory DateRangeSel.preset(RangePreset preset, {DateTime? now}) {
    final t = now ?? jakartaToday();
    final today = DateTime(t.year, t.month, t.day);
    switch (preset) {
      case RangePreset.today:
        return DateRangeSel._(preset, today, today);
      case RangePreset.last7:
        return DateRangeSel._(
            preset, DateTime(today.year, today.month, today.day - 6), today);
      case RangePreset.thisMonth:
        return DateRangeSel._(preset, DateTime(today.year, today.month, 1),
            DateTime(today.year, today.month + 1, 0));
      case RangePreset.lastMonth:
        return DateRangeSel._(preset, DateTime(today.year, today.month - 1, 1),
            DateTime(today.year, today.month, 0));
      case RangePreset.thisYear:
        return DateRangeSel._(
            preset, DateTime(today.year, 1, 1), DateTime(today.year, 12, 31));
      case RangePreset.all:
      case RangePreset.custom:
        return const DateRangeSel._(RangePreset.all, null, null);
    }
  }

  /// A range picked by hand; the ends are swapped when given backwards.
  factory DateRangeSel.custom(DateTime from, DateTime to) {
    var a = DateTime(from.year, from.month, from.day);
    var b = DateTime(to.year, to.month, to.day);
    if (b.isBefore(a)) (a, b) = (b, a);
    return DateRangeSel._(RangePreset.custom, a, b);
  }

  /// The default of every paged list: this month.
  static DateRangeSel get defaultRange =>
      DateRangeSel.preset(RangePreset.thisMonth);

  final RangePreset preset;
  final DateTime? from;
  final DateTime? to;

  bool get isAll => from == null && to == null;

  /// Start of [from] in Jakarta as a UTC instant (for Timestamp fields).
  DateTime? get startUtc => from == null
      ? null
      : DateTime.utc(from!.year, from!.month, from!.day)
          .subtract(jakartaOffset);

  /// The instant just after [to] ends in Jakarta (exclusive upper bound).
  DateTime? get endUtcExclusive => to == null
      ? null
      : DateTime.utc(to!.year, to!.month, to!.day + 1).subtract(jakartaOffset);

  /// `yyyy-MM-dd` of [from] (for fields stored as a date string).
  String? get fromIso => from == null ? null : isoDay(from!);

  /// `yyyy-MM-dd` of the day after [to] (exclusive upper bound).
  String? get toIsoExclusive => to == null
      ? null
      : isoDay(DateTime(to!.year, to!.month, to!.day + 1));

  /// Whether the Jakarta calendar day of [instant] falls in the range.
  bool containsInstant(DateTime instant) {
    final u = instant.toUtc();
    final s = startUtc, e = endUtcExclusive;
    if (s != null && u.isBefore(s)) return false;
    if (e != null && !u.isBefore(e)) return false;
    return true;
  }

  /// "1 Mar 2026 – 31 Dec 2026" (or one day when from == to).
  String describe(String locale, {required String allLabel}) {
    if (isAll) return allLabel;
    final f = DateFormat('d MMM yyyy', locale);
    if (from != null && to != null && from == to) return f.format(from!);
    return '${from == null ? '…' : f.format(from!)} – ${to == null ? '…' : f.format(to!)}';
  }

  @override
  bool operator ==(Object other) =>
      other is DateRangeSel &&
      other.preset == preset &&
      other.from == from &&
      other.to == to;

  @override
  int get hashCode => Object.hash(preset, from, to);

  static const jakartaOffset = Duration(hours: 7);

  /// Today's calendar day in Jakarta, whatever the device's zone.
  static DateTime jakartaToday() {
    final j = DateTime.now().toUtc().add(jakartaOffset);
    return DateTime(j.year, j.month, j.day);
  }

  static String isoDay(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Build 9B: a period of whole months, both ends included.
class MonthPeriod {
  MonthPeriod(DateTime from, DateTime to)
      : from = DateTime(from.year, from.month),
        to = DateTime(to.year, to.month) {
    if (this.to.isBefore(this.from)) {
      throw ArgumentError('The period ends before it starts.');
    }
  }

  factory MonthPeriod.thisMonth({DateTime? now}) {
    final t = now ?? DateRangeSel.jakartaToday();
    return MonthPeriod(t, t);
  }

  factory MonthPeriod.lastMonths(int count, {DateTime? now}) {
    final t = now ?? DateRangeSel.jakartaToday();
    return MonthPeriod(DateTime(t.year, t.month - count + 1), t);
  }

  factory MonthPeriod.thisYear({DateTime? now}) {
    final t = now ?? DateRangeSel.jakartaToday();
    return MonthPeriod(DateTime(t.year, 1), DateTime(t.year, 12));
  }

  final DateTime from;
  final DateTime to;

  /// Every month of the period as `yyyyMM`, oldest first.
  List<String> get monthKeys => [
        for (var d = from;
            !d.isAfter(to);
            d = DateTime(d.year, d.month + 1))
          '${d.year}${d.month.toString().padLeft(2, '0')}',
      ];

  bool get isSingleMonth => from == to;

  /// The whole period as a day range (first day to last day).
  DateRangeSel get dayRange =>
      DateRangeSel.custom(from, DateTime(to.year, to.month + 1, 0));

  /// "Maret 2026 – Desember 2026" in the given locale.
  String describe(String locale) {
    final f = DateFormat('MMMM yyyy', locale);
    return isSingleMonth ? f.format(from) : '${f.format(from)} – ${f.format(to)}';
  }

  @override
  bool operator ==(Object other) =>
      other is MonthPeriod && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}
