// Build 9A (supervisor 2026-11-25): paged lists with a date range.
import 'dart:io';

import 'package:chinese_tracker/core/paging/date_range.dart';
import 'package:chinese_tracker/core/paging/paged_controller.dart';
import 'package:chinese_tracker/models/audit_log.dart';
import 'package:chinese_tracker/services/firestore_service.dart' show UserSearch;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('date range', () {
    final now = DateTime(2026, 3, 15);

    test('presets count Jakarta calendar days, both ends included', () {
      final m = DateRangeSel.preset(RangePreset.thisMonth, now: now);
      expect(m.from, DateTime(2026, 3, 1));
      expect(m.to, DateTime(2026, 3, 31));
      final last = DateRangeSel.preset(RangePreset.lastMonth, now: now);
      expect(last.from, DateTime(2026, 2, 1));
      expect(last.to, DateTime(2026, 2, 28));
      final seven = DateRangeSel.preset(RangePreset.last7, now: now);
      expect(seven.from, DateTime(2026, 3, 9));
      expect(seven.to, now);
      final jan = DateRangeSel.preset(RangePreset.lastMonth,
          now: DateTime(2026, 1, 10));
      expect(jan.from, DateTime(2025, 12, 1));
      expect(DateRangeSel.preset(RangePreset.all, now: now).isAll, isTrue);
    });

    test('bounds: Jakarta midnight as UTC, the day after as exclusive end', () {
      final r = DateRangeSel.custom(DateTime(2026, 3, 1), DateTime(2026, 3, 31));
      expect(r.startUtc, DateTime.utc(2026, 2, 28, 17));
      expect(r.endUtcExclusive, DateTime.utc(2026, 3, 31, 17));
      expect(r.fromIso, '2026-03-01');
      expect(r.toIsoExclusive, '2026-04-01');
      // 23:30 on 31 March in Jakarta is still inside; 00:10 on 1 April not.
      expect(r.containsInstant(DateTime.utc(2026, 3, 31, 16, 30)), isTrue);
      expect(r.containsInstant(DateTime.utc(2026, 3, 31, 17, 10)), isFalse);
      expect(r.containsInstant(DateTime.utc(2026, 2, 28, 16, 59)), isFalse);
    });

    test('a range picked backwards is turned round', () {
      final r = DateRangeSel.custom(DateTime(2026, 5, 9), DateTime(2026, 5, 2));
      expect(r.from, DateTime(2026, 5, 2));
      expect(r.to, DateTime(2026, 5, 9));
    });

    test('a month period lists its months, March to December', () {
      final p = MonthPeriod(DateTime(2026, 3), DateTime(2026, 12));
      expect(p.monthKeys.first, '202603');
      expect(p.monthKeys.last, '202612');
      expect(p.monthKeys.length, 10);
      expect(p.dayRange.to, DateTime(2026, 12, 31));
      expect(MonthPeriod.lastMonths(3, now: DateTime(2026, 2, 5)).monthKeys,
          ['202512', '202601', '202602']);
      expect(() => MonthPeriod(DateTime(2026, 5), DateTime(2026, 4)),
          throwsArgumentError);
    });
  });

  group('paged controller', () {
    Future<PagedController<int>> make(ListPageSource<int> src,
        {int size = 25}) async {
      final c = PagedController<int>(
          build: (_) => src, pageSize: size, autoLoad: false);
      await c.reload();
      return c;
    }

    test('reads one page (plus one row) at a time and steps through', () async {
      final src = ListPageSource([for (var i = 0; i < 60; i++) i]);
      final c = await make(src);
      expect(c.items, [for (var i = 0; i < 25; i++) i]);
      expect(c.total, 60);
      expect(c.firstRow, 1);
      expect(c.lastRow, 25);
      expect(c.hasNext, isTrue);
      expect(c.hasPrevious, isFalse);
      await c.next();
      expect(c.items.first, 25);
      expect(c.pageIndex, 1);
      await c.next();
      expect(c.items, [for (var i = 50; i < 60; i++) i]);
      expect(c.hasNext, isFalse);
      expect(c.lastRow, 60);
      await c.next(); // nothing after the last page
      expect(c.pageIndex, 2);
      await c.previous();
      expect(c.items.first, 25);
      await c.previous();
      expect(c.items.first, 0);
    });

    test('changing the page size or range goes back to page 1', () async {
      final src = ListPageSource([for (var i = 0; i < 30; i++) i]);
      final c = await make(src, size: 10);
      await c.next();
      expect(c.items.first, 10);
      await c.setPageSize(25);
      expect(c.pageIndex, 0);
      expect(c.items.length, 25);
      await c.next();
      await c.setRange(DateRangeSel.preset(RangePreset.all));
      expect(c.pageIndex, 0);
    });

    test('an empty list has no pages', () async {
      final c = await make(ListPageSource<int>([]));
      expect(c.items, isEmpty);
      expect(c.firstRow, 0);
      expect(c.hasNext, isFalse);
      expect(c.total, 0);
    });

    test('export reads the whole range in batches, up to the ceiling',
        () async {
      final src = ListPageSource([for (var i = 0; i < 1234; i++) i]);
      final c = await make(src);
      final all = await c.fetchAll(batch: 500);
      expect(all.rows.length, 1234);
      expect(all.capped, isFalse);
      final capped = await c.fetchAll(ceiling: 1000, batch: 500);
      expect(capped.rows.length, 1000);
      expect(capped.capped, isTrue);
      final exact = await PagedController<int>(
              build: (_) => ListPageSource([for (var i = 0; i < 1000; i++) i]),
              autoLoad: false)
          .fetchAll(ceiling: 1000, batch: 500);
      expect(exact.capped, isFalse);
    });
  });

  test('every audit action the functions write has a filter group', () {
    final src = File('functions/index.js').readAsStringSync();
    final written = <String>{
      for (final m in RegExp(r'"((?:invoice|test|promotion|registration|schedule|day|progress|leaderboard|users)\.[a-z.]+)"')
          .allMatches(src))
        m.group(1)!,
    }..removeWhere((a) => a.endsWith('.'));
    final grouped = {
      for (final g in AuditActionGroup.values) ...g.actions,
    };
    // Built from parts in the code: approve/decline + ".placement".
    expect(grouped, containsAll(written.where((a) => !a.endsWith('.placement'))));
    for (final g in AuditActionGroup.values) {
      expect(g.actions.length, lessThanOrEqualTo(30), reason: 'whereIn limit');
    }
  });

  test('the Users search box sends what functions/user_search.js indexes', () {
    expect(UserSearch.normalize('  Angeline   SAN '), 'angeline san');
    expect(UserSearch.normalize('陈美'), '陈美');
    expect(UserSearch.normalize('x' * 40).length, UserSearch.maxPrefix);
    expect(UserSearch.normalize('   '), '');
  });

  test('an inline paged list and the "all dates" range', () {
    expect(const DateRangeSel.all().isAll, isTrue);
    expect(const DateRangeSel.all().startUtc, isNull);
  });

  group('Build 9 part 2 sources', () {
    Future<List<int>> readAll(PagedController<int> c) async {
      final out = <int>[...c.items];
      while (c.hasNext) {
        await c.next();
        out.addAll(c.items);
      }
      return out;
    }

    test('a merged timeline reads each source a page at a time, newest first',
        () async {
      final a = ListPageSource<int>([50, 40, 30, 20, 10]);
      final b = ListPageSource<int>([45, 44, 43, 5]);
      final c = ListPageSource<int>(<int>[]);
      final merged = MergedPageSource<int>([a, b, c], newer: (x, y) => x > y);
      final pages = PagedController<int>(
          build: (_) => merged, pageSize: 3, autoLoad: false);
      await pages.reload();
      expect(pages.items, [50, 45, 44]);
      expect(pages.total, 9);
      final all = await readAll(pages);
      expect(all, [50, 45, 44, 43, 40, 30, 20, 10, 5]);
      // Back one page gives the same rows again.
      await pages.previous();
      expect(pages.items, [43, 40, 30]);
    });

    test('a filtered source fills its page across batches', () async {
      final inner = ListPageSource<int>([for (var i = 1; i <= 40; i++) i]);
      final odd = FilteredPageSource<int>(inner, (x) => x.isOdd && x > 10);
      final pages = PagedController<int>(
          build: (_) => odd, pageSize: 4, autoLoad: false);
      await pages.reload();
      expect(pages.items, [11, 13, 15, 17]);
      expect(pages.total, isNull);
      expect(await readAll(pages),
          [11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31, 33, 35, 37, 39]);
    });

    test('a mapped source joins each page with one call', () async {
      var calls = 0;
      final mapped = MappedPageSource<int, String>(
          ListPageSource<int>([1, 2, 3, 4, 5]), (page) async {
        calls++;
        return [for (final x in page) 'row $x'];
      });
      final pages = PagedController<String>(
          build: (_) => mapped, pageSize: 2, autoLoad: false);
      await pages.reload();
      expect(pages.items, ['row 1', 'row 2']);
      expect(pages.total, 5);
      await pages.next();
      expect(pages.items, ['row 3', 'row 4']);
      expect(calls, 2);
    });
  });
}
