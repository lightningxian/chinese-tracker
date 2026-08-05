import 'package:flutter/material.dart';

/// Wrap grid that grows from 1 column on narrow screens to [maxColumns].
class ResponsiveCardGrid extends StatelessWidget {
  const ResponsiveCardGrid({
    super.key,
    required this.children,
    this.minCardWidth = 300,
    this.maxColumns = 4,
    this.gap = 12,
    this.width,
  });

  final List<Widget> children;
  final double minCardWidth;
  final int maxColumns;
  final double gap;

  /// When set, uses this width instead of [LayoutBuilder] constraints.
  final double? width;

  static int columnCount(
    double totalWidth, {
    double minCardWidth = 300,
    int maxColumns = 4,
  }) {
    if (totalWidth <= 0) return 1;
    return (totalWidth / minCardWidth).floor().clamp(1, maxColumns);
  }

  static double cardWidth(
    double totalWidth,
    int columns, {
    double gap = 12,
  }) {
    return (totalWidth - (columns - 1) * gap) / columns;
  }

  @override
  Widget build(BuildContext context) {
    if (width != null) {
      return _build(width!);
    }
    return LayoutBuilder(
      builder: (context, constraints) => _build(constraints.maxWidth),
    );
  }

  Widget _build(double totalWidth) {
    final columns = columnCount(
      totalWidth,
      minCardWidth: minCardWidth,
      maxColumns: maxColumns,
    );
    final itemWidth = cardWidth(totalWidth, columns, gap: gap);

    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        for (final child in children)
          SizedBox(width: itemWidth, child: child),
      ],
    );
  }
}
