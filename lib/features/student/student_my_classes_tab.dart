import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/responsive_card_grid.dart';
import '../../l10n/l10n.dart';
import '../../models/app_user.dart';
import '../../services/firestore_service.dart';

class StudentMyClassesTab extends StatelessWidget {
  const StudentMyClassesTab({super.key, required this.student});

  final AppUser student;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: context
          .read<FirestoreService>()
          .watchStudentJoinedSessions(student.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                snapshot.error.toString(),
                style: const TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final records = snapshot.data ?? [];

        if (records.isEmpty) {
          return EmptyState(
            icon: Icons.event_available_outlined,
            title: context.l10n.studentMyClassesEmptyTitle,
            subtitle: context.l10n.studentMyClassesEmptySubtitle,
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            const padding = 20.0;
            final gridWidth = constraints.maxWidth - padding * 2;

            return ListView(
              padding: const EdgeInsets.all(padding),
              children: [
                ResponsiveCardGrid(
                  width: gridWidth,
                  children: [
                    for (final record in records)
                      Builder(
                        builder: (context) {
                          final l = context.l10n;
                          final parsed = DateTime.tryParse(record.sessionDate);
                          final dateLabel = parsed != null
                              ? DateFormat('EEE, d MMM yyyy', l.localeName)
                                  .format(parsed)
                              : record.sessionDate;

                          return AppCard(
                            onTap: () => context.push(
                              '/student/class/${record.sessionId}',
                            ),
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.teal
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.event_available_outlined,
                                    color: AppColors.teal,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        record.sessionTitle.isNotEmpty
                                            ? record.sessionTitle
                                            : l.commonClassSession,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        [
                                          dateLabel,
                                          if (record.startMinutes != 0 ||
                                              record.endMinutes != 0)
                                            record.timeRangeLabel,
                                        ].join(' · '),
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        l.studentMyClassesTapToSee,
                                        style: const TextStyle(
                                          color: AppColors.teal,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}
