import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_card.dart';

class ExportReportCard extends StatelessWidget {
  const ExportReportCard({
    super.key,
    required this.title,
    required this.description,
    required this.preview,
    required this.onExport,
    this.exportLabel = 'Export PDF',
    this.exportIcon = Icons.picture_as_pdf_outlined,
  });

  final String title;
  final String description;
  final List<String> preview;
  final VoidCallback onExport;
  final String exportLabel;
  final IconData exportIcon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          if (preview.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...preview.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '· $line',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onExport,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.navy,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: Icon(exportIcon, size: 18),
            label: Text(exportLabel),
          ),
        ],
      ),
    );
  }
}
