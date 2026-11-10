import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import 'app_card.dart';
import '../../models/attendance_record.dart';

class AttendanceHistoryList extends StatelessWidget {
  const AttendanceHistoryList({
    super.key,
    required this.records,
    this.emptyMessage = 'No attendance recorded yet.',
  });

  final List<AttendanceRecord> records;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return AppCard(
        child: Text(
          emptyMessage,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      children: records.map((record) {
        final parsed = DateTime.tryParse(record.sessionDate);
        final dateLabel = parsed != null
            ? DateFormat('EEE, d MMM yyyy').format(parsed)
            : record.sessionDate;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  record.attended ? Icons.check_circle : Icons.cancel,
                  color: record.attended ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.sessionTitle.isNotEmpty
                            ? record.sessionTitle
                            : 'Class session',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          dateLabel,
                          if (record.startMinutes != 0 ||
                              record.endMinutes != 0)
                            record.timeRangeLabel,
                          if (record.joinedByStudent) 'Self join',
                        ].join(' · '),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  record.attended ? 'Present' : 'Absent',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color:
                        record.attended ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class AttendanceSummaryCard extends StatelessWidget {
  const AttendanceSummaryCard({super.key, required this.records});

  final List<AttendanceRecord> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return AppCard(
        child: Text(
          'No class attendance recorded yet.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final present = records.where((record) => record.attended).length;
    final rate =
        records.isEmpty ? 0 : ((present / records.length) * 100).round();

    return AppCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Tile(label: 'Sessions', value: '${records.length}'),
          _Tile(label: 'Present', value: '$present'),
          _Tile(label: 'Rate', value: '$rate%'),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
        ),
        Text(label, style: TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }
}
