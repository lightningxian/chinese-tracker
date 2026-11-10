import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/csv_export.dart';

/// Toolbar button that downloads the table as CSV. [rows] is called when the
/// button is pressed, so it always exports what the table shows right now.
class ExportCsvButton extends StatelessWidget {
  const ExportCsvButton({
    super.key,
    required this.fileStem,
    required this.header,
    required this.rows,
    this.label = 'Export CSV',
  });

  final String fileStem;
  final List<String> header;
  final List<List<Object?>> Function() rows;
  final String label;

  Future<void> _export(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final data = rows();
    // Say it first: the browser's download prompt can take the focus and
    // hold a snackbar shown afterwards until the page is active again.
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          kIsWeb
              ? 'Downloading ${data.length} rows as CSV…'
              : 'Copied ${data.length} rows as CSV to the clipboard.',
        ),
      ),
    );
    await CsvExport.download(fileStem: fileStem, header: header, rows: data);
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _export(context),
      icon: const Icon(Icons.download_outlined, size: 18),
      label: Text(label),
    );
  }
}

/// Bar shown above a table while rows are ticked: "3 selected", the bulk
/// actions, and Clear. Sits in place of nothing when [count] is 0.
class TableSelectionBar extends StatelessWidget {
  const TableSelectionBar({
    super.key,
    required this.count,
    required this.actions,
    required this.onClear,
    this.noun = 'selected',
  });

  final int count;
  final List<Widget> actions;
  final VoidCallback onClear;
  final String noun;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.navy.withValues(alpha: 0.18)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '$count $noun',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(width: 4),
          ...actions,
          TextButton(onPressed: onClear, child: const Text('Clear')),
        ],
      ),
    );
  }
}

/// Compact outlined button for [TableSelectionBar] actions.
class SelectionActionButton extends StatelessWidget {
  const SelectionActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.destructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.error : AppColors.navy;
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        backgroundColor: AppColors.card,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 36),
        visualDensity: VisualDensity.compact,
      ),
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
