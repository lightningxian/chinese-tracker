import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';
import '../paging/date_range.dart';
import '../paging/paged_controller.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

/// Build 9A: the shared date range bar, pager bar and paged list body.
/// Every long list uses these; no page keeps its own paging code.

String rangePresetLabel(BuildContext context, RangePreset p) {
  final l = context.l10n;
  return switch (p) {
    RangePreset.today => l.rangeToday,
    RangePreset.last7 => l.rangeLast7,
    RangePreset.thisMonth => l.rangeThisMonth,
    RangePreset.lastMonth => l.rangeLastMonth,
    RangePreset.thisYear => l.rangeThisYear,
    RangePreset.all => l.rangeAll,
    RangePreset.custom => l.rangeCustom,
  };
}

/// Presets as chips plus "Custom…" (a date range picker). Dates are
/// Jakarta calendar days, both ends included.
class DateRangeBar extends StatelessWidget {
  const DateRangeBar({super.key, required this.value, required this.onChanged});

  final DateRangeSel value;
  final ValueChanged<DateRangeSel> onChanged;

  Future<void> _pickCustom(BuildContext context) async {
    final today = DateRangeSel.jakartaToday();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(today.year + 1, 12, 31),
      initialDateRange: value.from != null && value.to != null
          ? DateTimeRange(start: value.from!, end: value.to!)
          : null,
    );
    if (picked != null) onChanged(DateRangeSel.custom(picked.start, picked.end));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    const presets = [
      RangePreset.today,
      RangePreset.last7,
      RangePreset.thisMonth,
      RangePreset.lastMonth,
      RangePreset.thisYear,
      RangePreset.all,
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Icon(Icons.date_range_outlined, size: 20, color: AppColors.teal),
        for (final p in presets)
          ChoiceChip(
            label: Text(rangePresetLabel(context, p)),
            selected: value.preset == p,
            onSelected: (_) => onChanged(DateRangeSel.preset(p)),
          ),
        ChoiceChip(
          avatar: const Icon(Icons.edit_calendar_outlined, size: 16),
          label: Text(value.preset == RangePreset.custom
              ? value.describe(locale, allLabel: l.rangeAll)
              : l.rangeCustom),
          selected: value.preset == RangePreset.custom,
          onSelected: (_) => _pickCustom(context),
        ),
        if (value.preset != RangePreset.custom && !value.isAll)
          Text(
            value.describe(locale, allLabel: l.rangeAll),
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
          ),
      ],
    );
  }
}

/// "1–25 of 312", previous, page n, next, rows per page, refresh.
class PagerBar extends StatelessWidget {
  const PagerBar({super.key, required this.controller});

  final PagedController<dynamic> controller;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = controller;
    final total = c.total;
    final span = c.items.isEmpty
        ? l.pagingNone
        : total == null
            ? l.pagingSpan(c.firstRow, c.lastRow)
            : l.pagingSpanOf(c.firstRow, c.lastRow, total);
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 4,
      children: [
        Text(span, style: TextStyle(color: AppColors.textSecondary)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: l.pagingPrevious,
              onPressed: c.hasPrevious && !c.loading ? c.previous : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Text(l.pagingPage(c.pageIndex + 1),
                style: const TextStyle(fontWeight: FontWeight.w600)),
            IconButton(
              tooltip: l.pagingNext,
              onPressed: c.hasNext && !c.loading ? c.next : null,
              icon: const Icon(Icons.chevron_right),
            ),
            const SizedBox(width: 8),
            Text(l.pagingRowsPerPage,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
            const SizedBox(width: 6),
            DropdownButton<int>(
              value: c.pageSize,
              underline: const SizedBox.shrink(),
              items: [
                for (final n in PagedController.pageSizes)
                  DropdownMenuItem(value: n, child: Text('$n')),
              ],
              onChanged: (n) => n == null ? null : c.setPageSize(n),
            ),
            IconButton(
              tooltip: l.pagingRefresh,
              onPressed: c.loading ? null : c.refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ],
    );
  }
}

/// A paged list: optional header (filters), the rows, empty / error /
/// loading states and the pager bar under the rows.
class PagedListBody<T> extends StatelessWidget {
  const PagedListBody({
    super.key,
    required this.controller,
    required this.itemBuilder,
    this.header,
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyTitle,
    this.emptySubtitle,
    this.padding = const EdgeInsets.all(20),
    this.separator = 10,
    this.maxWidth,
    this.body,
    this.inline = false,
  });

  /// Draws a plain column (inside a caller's own scrolling list).
  final bool inline;

  /// Draws the whole page at once (a table) instead of [itemBuilder] rows.
  final Widget? body;

  final PagedController<T> controller;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final Widget? header;
  final IconData emptyIcon;
  final String? emptyTitle;
  final String? emptySubtitle;
  final EdgeInsets padding;
  final double separator;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final c = controller;
        final rows = c.items;
        final children = <Widget>[
          if (header != null) ...[header!, const SizedBox(height: 12)],
          if (c.loading) const LinearProgressIndicator(minHeight: 2),
          if (c.error != null)
            AppCard(
              padding: const EdgeInsets.all(14),
              child: Text(l.pagingError('${c.error}'),
                  style: TextStyle(color: AppColors.error)),
            )
          else if (rows.isEmpty && !c.loading)
            EmptyState(
              icon: emptyIcon,
              title: emptyTitle ?? l.pagingEmptyTitle,
              subtitle: emptySubtitle ?? l.pagingEmptySubtitle,
            )
          else if (body != null)
            body!
          else
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) SizedBox(height: separator),
              itemBuilder(context, rows[i]),
            ],
          const SizedBox(height: 8),
          PagerBar(controller: c),
        ];
        if (inline) {
          return Padding(
            padding: padding,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
          );
        }
        final list = ListView(padding: padding, children: children);
        if (maxWidth == null) return list;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth!),
            child: list,
          ),
        );
      },
    );
  }
}

/// Runs [controller.fetchAll] and tells the user when the ceiling cut the
/// export short. Returns the rows (null on an error, already shown).
Future<List<T>?> fetchRowsForExport<T>(
    BuildContext context, PagedController<T> controller) async {
  final l = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  try {
    final out = await controller.fetchAll();
    if (out.capped) {
      messenger.showSnackBar(SnackBar(
          content: Text(l.pagingExportCapped(PagedController.exportCeiling))));
    }
    return out.rows;
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(l.pagingError('$e'))));
    return null;
  }
}

/// Build 9B: from month to month, with presets (this month, last 3 months,
/// this year). One bar for the whole Reports tab.
class MonthPeriodBar extends StatelessWidget {
  const MonthPeriodBar({super.key, required this.value, required this.onChanged});

  final MonthPeriod value;
  final ValueChanged<MonthPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final today = DateRangeSel.jakartaToday();
    final months = [
      for (var d = DateTime(today.year - 2, 1);
          !d.isAfter(DateTime(today.year, 12));
          d = DateTime(d.year, d.month + 1))
        d,
    ];
    final f = DateFormat('MMM yyyy', locale);
    final presets = <(String, MonthPeriod)>[
      (l.rangeThisMonth, MonthPeriod.thisMonth()),
      (l.periodLast3Months, MonthPeriod.lastMonths(3)),
      (l.rangeThisYear, MonthPeriod.thisYear()),
    ];
    DropdownButton<DateTime> pick(DateTime v, ValueChanged<DateTime> set) =>
        DropdownButton<DateTime>(
          value: months.contains(v) ? v : null,
          items: [
            for (final m in months)
              DropdownMenuItem(value: m, child: Text(f.format(m))),
          ],
          onChanged: (m) => m == null ? null : set(m),
        );
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Icon(Icons.date_range_outlined, size: 20, color: AppColors.teal),
        for (final p in presets)
          ChoiceChip(
            label: Text(p.$1),
            selected: value == p.$2,
            onSelected: (_) => onChanged(p.$2),
          ),
        const SizedBox(width: 8),
        Text(l.periodFrom, style: TextStyle(color: AppColors.textSecondary)),
        pick(value.from, (m) => onChanged(MonthPeriod(m, m.isAfter(value.to) ? m : value.to))),
        Text(l.periodTo, style: TextStyle(color: AppColors.textSecondary)),
        pick(value.to, (m) => onChanged(MonthPeriod(m.isBefore(value.from) ? m : value.from, m))),
      ],
    );
  }
}
