import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_card.dart';
import 'responsive_card_grid.dart';

/// Column spec for [AppDataTable]. `width` fixes the column; when null the
/// column flexes with [flex]. The parent owns sort state and receives the
/// column [id] via `onSort`.
class AppTableColumn<T> {
  const AppTableColumn({
    required this.id,
    required this.label,
    required this.cell,
    this.width,
    this.flex = 1,
    this.sortable = false,
    this.alignment = Alignment.centerLeft,
  });

  final String id;
  final String label;
  final double? width;
  final int flex;
  final bool sortable;
  final Alignment alignment;
  final Widget Function(T row) cell;
}

/// Shared data table extracted from the admin Users tab: navy-tinted header
/// with sortable cells, striped rows with bottom borders, wrapped in a
/// zero-padding [AppCard]. Below [mobileBreakpoint] (based on **available**
/// width, not the full window — important with the sidebar) it renders
/// [mobileCardBuilder] cards in a [ResponsiveCardGrid] instead.
class AppDataTable<T> extends StatelessWidget {
  const AppDataTable({
    super.key,
    required this.rows,
    required this.columns,
    required this.mobileCardBuilder,
    this.sortColumnId,
    this.sortAscending = true,
    this.onSort,
    this.onRowTap,
    this.mobileBreakpoint = 720,
  });

  final List<T> rows;
  final List<AppTableColumn<T>> columns;
  final String? sortColumnId;
  final bool sortAscending;
  final void Function(String columnId)? onSort;
  final void Function(T row)? onRowTap;
  final Widget Function(T row) mobileCardBuilder;
  final double mobileBreakpoint;

  /// Minimum width reserved for flex columns when computing horizontal scroll.
  static const _flexColumnMinWidth = 160.0;

  double get _minTableWidth {
    var total = 0.0;
    for (final column in columns) {
      total += column.width ?? _flexColumnMinWidth;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Prefer the parent's max width (content pane). Fall back to the
        // window only when the parent gives an unbounded constraint.
        final available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final isWide = available >= mobileBreakpoint;

        if (!isWide) {
          return ResponsiveCardGrid(
            width: available,
            children: [for (final row in rows) mobileCardBuilder(row)],
          );
        }

        final table = _desktopTable();
        final minWidth = _minTableWidth;
        if (available < minWidth) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(width: minWidth, child: table),
          );
        }
        return table;
      },
    );
  }

  Widget _desktopTable() {
    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            _headerRow(),
            ...rows.asMap().entries.map(
                  (entry) => _dataRow(entry.value, striped: entry.key.isOdd),
                ),
          ],
        ),
      ),
    );
  }

  Widget _headerRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.navy.withValues(alpha: 0.05),
      child: Row(
        children: [
          for (final column in columns) _wrapCell(column, _headerCell(column)),
        ],
      ),
    );
  }

  Widget _headerCell(AppTableColumn<T> column) {
    if (!column.sortable || onSort == null) {
      return _aligned(
        column.alignment,
        Text(
          column.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    final active = column.id == sortColumnId;
    return InkWell(
      onTap: () => onSort!(column.id),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          children: [
            Expanded(
              child: Align(
                alignment: column.alignment,
                child: Text(
                  column.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: active ? AppColors.navy : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            Icon(
              active
                  ? (sortAscending
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded)
                  : Icons.unfold_more_rounded,
              size: 14,
              color: active ? AppColors.navy : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _dataRow(T row, {required bool striped}) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: striped
            ? AppColors.surface.withValues(alpha: 0.55)
            : AppColors.card,
        border: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (final column in columns)
            _wrapCell(
              column,
              // Avoid wrapping every cell in [Align] — that loosens width
              // constraints and breaks cells that use [Expanded] (e.g. Name).
              _aligned(column.alignment, column.cell(row)),
            ),
        ],
      ),
    );

    if (onRowTap == null) return content;
    return InkWell(onTap: () => onRowTap!(row), child: content);
  }

  /// Only apply [Align] when the cell shouldn't stretch (right/center).
  /// Left-aligned cells keep tight width so [Expanded] inside them works.
  Widget _aligned(Alignment alignment, Widget child) {
    if (alignment == Alignment.centerLeft) return child;
    return Align(alignment: alignment, child: child);
  }

  Widget _wrapCell(AppTableColumn<T> column, Widget child) {
    if (column.width != null) {
      return SizedBox(width: column.width, child: child);
    }
    return Expanded(flex: column.flex, child: child);
  }
}
