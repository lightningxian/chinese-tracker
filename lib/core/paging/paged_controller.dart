import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'date_range.dart';

/// Build 9A (supervisor 2026-11-25): one paging ViewModel for every long
/// list. It reads only the page on screen (cursor paging, never a full
/// download sliced in memory) and the total from a count aggregation.

/// One fetched page: the rows and, for each row, the cursor to start after.
class PageChunk<T> {
  const PageChunk(this.items, this.cursors);

  final List<T> items;
  final List<Object?> cursors;
}

/// Where a paged list reads from. Firestore in the app; a list in tests.
abstract class PageSource<T> {
  /// Up to [limit] rows after [after] (null = from the start).
  Future<PageChunk<T>> fetch({Object? after, required int limit});

  /// The number of rows the query matches, or null when unknown.
  Future<int?> count();
}

/// How a date range is put on a Firestore field.
enum DateFieldKind {
  /// A `Timestamp` field (createdAt, finishedAt, paidAt …).
  timestamp,

  /// A `yyyy-MM-dd` string (sessionDate, date).
  isoDay,
}

/// Puts [range] on [field] of [query]. The query must be ordered by
/// [field] first (Firestore's rule for a range filter).
Query<Map<String, dynamic>> applyDateRange(
  Query<Map<String, dynamic>> query,
  String field,
  DateRangeSel range, {
  DateFieldKind kind = DateFieldKind.timestamp,
}) {
  var q = query;
  switch (kind) {
    case DateFieldKind.timestamp:
      final s = range.startUtc, e = range.endUtcExclusive;
      if (s != null) {
        q = q.where(field, isGreaterThanOrEqualTo: Timestamp.fromDate(s));
      }
      if (e != null) q = q.where(field, isLessThan: Timestamp.fromDate(e));
    case DateFieldKind.isoDay:
      final s = range.fromIso, e = range.toIsoExclusive;
      if (s != null) q = q.where(field, isGreaterThanOrEqualTo: s);
      if (e != null) q = q.where(field, isLessThan: e);
  }
  return q;
}

/// A Firestore query as a [PageSource].
class FirestorePageSource<T> implements PageSource<T> {
  FirestorePageSource(this.query, this.map);

  final Query<Map<String, dynamic>> query;
  final T Function(DocumentSnapshot<Map<String, dynamic>> doc) map;

  @override
  Future<PageChunk<T>> fetch({Object? after, required int limit}) async {
    var q = query;
    if (after is DocumentSnapshot) q = q.startAfterDocument(after);
    final snap = await q.limit(limit).get();
    return PageChunk(
      [for (final d in snap.docs) map(d)],
      List<Object?>.of(snap.docs),
    );
  }

  @override
  Future<int?> count() async {
    try {
      return (await query.count().get()).count;
    } catch (e) {
      debugPrint('Page count failed: $e');
      return null;
    }
  }
}

/// The paging ViewModel. [build] makes the source for the current range
/// (and whatever filters the page keeps); call [reload] after a filter
/// changes.
class PagedController<T> extends ChangeNotifier {
  PagedController({
    required PageSource<T> Function(DateRangeSel range) build,
    DateRangeSel? range,
    int pageSize = 25,
    bool autoLoad = true,
  })  : _build = build,
        _range = range ?? DateRangeSel.defaultRange,
        _pageSize = pageSize {
    if (autoLoad) reload();
  }

  static const pageSizes = [10, 25, 50];

  /// An export never reads more than this many rows.
  static const exportCeiling = 5000;

  final PageSource<T> Function(DateRangeSel range) _build;

  DateRangeSel _range;
  int _pageSize;
  int _pageIndex = 0;
  int? _total;
  bool _hasNext = false;
  bool _loading = false;
  Object? _error;
  List<T> _items = const [];
  // _starts[i] = the cursor page i starts after (null for page 0).
  final List<Object?> _starts = [null];
  Object? _nextStart;
  int _generation = 0;
  bool _disposed = false;

  DateRangeSel get range => _range;
  int get pageSize => _pageSize;
  int get pageIndex => _pageIndex;
  int? get total => _total;
  bool get hasNext => _hasNext;
  bool get hasPrevious => _pageIndex > 0;
  bool get loading => _loading;
  Object? get error => _error;
  List<T> get items => _items;

  /// 1-based number of the first row on screen (0 when empty).
  int get firstRow => _items.isEmpty ? 0 : _pageIndex * _pageSize + 1;

  /// 1-based number of the last row on screen.
  int get lastRow => _pageIndex * _pageSize + _items.length;

  /// Back to page 1 with a fresh source (after a filter or the range
  /// changed, or after the page's own writes).
  Future<void> reload() {
    _pageIndex = 0;
    _starts
      ..clear()
      ..add(null);
    _total = null;
    return _load(withCount: true);
  }

  /// Reads the current page again (keeps the page number).
  Future<void> refresh() => _load(withCount: true);

  Future<void> setRange(DateRangeSel range) {
    if (range == _range) return Future.value();
    _range = range;
    return reload();
  }

  Future<void> setPageSize(int size) {
    if (size == _pageSize) return Future.value();
    _pageSize = size;
    return reload();
  }

  Future<void> next() {
    if (!_hasNext || _loading) return Future.value();
    _pageIndex++;
    if (_starts.length <= _pageIndex) {
      _starts.add(_nextStart);
    } else {
      _starts[_pageIndex] = _nextStart;
    }
    return _load(withCount: false);
  }

  Future<void> previous() {
    if (!hasPrevious || _loading) return Future.value();
    _pageIndex--;
    return _load(withCount: false);
  }

  Future<void> _load({required bool withCount}) async {
    final gen = ++_generation;
    _loading = true;
    _error = null;
    _notify();
    final source = _build(_range);
    try {
      final after = _starts[_pageIndex];
      // One row more than the page tells whether a next page exists
      // without waiting for the count.
      final pageF = source.fetch(after: after, limit: _pageSize + 1);
      final countF = withCount ? source.count() : Future.value(_total);
      final chunk = await pageF;
      final total = await countF;
      if (gen != _generation || _disposed) return;
      final more = chunk.items.length > _pageSize;
      _items = more ? chunk.items.sublist(0, _pageSize) : chunk.items;
      _nextStart = _items.isEmpty ? null : chunk.cursors[_items.length - 1];
      _hasNext = more;
      _total = total;
      // A page emptied by deletes elsewhere: step back once.
      if (_items.isEmpty && _pageIndex > 0) {
        _pageIndex--;
        _loading = false;
        await _load(withCount: false);
        return;
      }
    } catch (e) {
      if (gen != _generation || _disposed) return;
      _error = e;
      _items = const [];
      _hasNext = false;
    }
    _loading = false;
    _notify();
  }

  /// Every row of the current range for an export, in batches of 500, up to
  /// [ceiling]. `capped` is true when the ceiling stopped the read.
  Future<({List<T> rows, bool capped})> fetchAll({
    int ceiling = exportCeiling,
    int batch = 500,
  }) async {
    final source = _build(_range);
    final rows = <T>[];
    Object? after;
    while (rows.length < ceiling) {
      final want = (ceiling - rows.length).clamp(1, batch);
      final chunk = await source.fetch(after: after, limit: want);
      rows.addAll(chunk.items);
      if (chunk.items.length < want) return (rows: rows, capped: false);
      after = chunk.cursors.last;
    }
    // Exactly at the ceiling: one more read says whether rows were left out.
    final rest = await source.fetch(after: after, limit: 1);
    return (rows: rows, capped: rest.items.isNotEmpty);
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// A list in memory as a [PageSource] (tests, and lists already loaded).
class ListPageSource<T> implements PageSource<T> {
  ListPageSource(this.rows);

  final List<T> rows;
  int fetches = 0;

  @override
  Future<PageChunk<T>> fetch({Object? after, required int limit}) async {
    fetches++;
    final start = after is int ? after + 1 : 0;
    final end = (start + limit).clamp(0, rows.length);
    final slice = start >= rows.length ? <T>[] : rows.sublist(start, end);
    return PageChunk(slice, [for (var i = start; i < end; i++) i]);
  }

  @override
  Future<int?> count() async => rows.length;
}
