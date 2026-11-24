import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../l10n/l10n.dart';
import '../../models/class_session.dart';
import '../announcements/announcements.dart';

/// Owner 2026-11-24: the date with a live clock on the admin dashboard.
class DashboardClock extends StatefulWidget {
  const DashboardClock({super.key});

  @override
  State<DashboardClock> createState() => _DashboardClockState();
}

class _DashboardClockState extends State<DashboardClock> {
  late final Timer _timer =
      Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(DateFormat('EEEE, d MMMM yyyy').format(now),
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(width: 10),
        Icon(Icons.schedule, size: 14, color: AppColors.teal),
        const SizedBox(width: 4),
        Text(DateFormat('HH:mm:ss').format(now),
            style: TextStyle(
              color: AppColors.teal,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            )),
      ],
    );
  }
}

/// "Next class 15:00 Kelas B · in 25 min" (or "going on now"), ticking
/// every 30 seconds. Nothing when no class is left today.
class NextClassCountdown extends StatefulWidget {
  const NextClassCountdown({super.key, required this.sessions});

  /// Today's sessions that are not cancelled.
  final List<ClassSession> sessions;

  @override
  State<NextClassCountdown> createState() => _NextClassCountdownState();
}

class _NextClassCountdownState extends State<NextClassCountdown> {
  late final Timer _timer =
      Timer.periodic(const Duration(seconds: 30), (_) => setState(() {}));

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final now = DateTime.now();
    ClassSession? going;
    ClassSession? next;
    for (final s in widget.sessions) {
      final start = s.startsAt;
      if (start == null || s.isClosedOrCancelled) continue;
      final end = DateTime.tryParse(s.sessionDate)!.add(Duration(minutes: s.endMinutes));
      if (!now.isBefore(start) && now.isBefore(end)) {
        going ??= s;
      } else if (now.isBefore(start) && (next == null || start.isBefore(next.startsAt!))) {
        next = s;
      }
    }
    final String text;
    if (next != null) {
      final mins = next.startsAt!.difference(now).inMinutes + 1;
      final inText = mins >= 60 ? l.dashInHours(mins ~/ 60, mins % 60) : l.dashInMinutes(mins);
      final m = next.startMinutes;
      final hhmm = '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
      text = l.dashNextClass(hhmm, next.sessionTitle, inText);
    } else if (going != null) {
      text = l.dashClassGoingOn(going.sessionTitle);
    } else {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, size: 16, color: AppColors.teal),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

/// The last five announcements on the dashboard (owner 2026-11-24).
class DashboardNewsCard extends StatefulWidget {
  const DashboardNewsCard({super.key, required this.onOpenNews});

  final VoidCallback onOpenNews;

  @override
  State<DashboardNewsCard> createState() => _DashboardNewsCardState();
}

class _DashboardNewsCardState extends State<DashboardNewsCard> {
  late final Stream<List<Announcement>> _news = AnnouncementService().watchRecent(limit: 5);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 14, 8, 10),
      child: StreamBuilder<List<Announcement>>(
        stream: _news,
        builder: (context, snap) {
          final list = snap.data ?? const <Announcement>[];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(l.dashNewsTitle,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                  TextButton(onPressed: widget.onOpenNews, child: Text(l.dashNewsAll)),
                ],
              ),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(l.announcementsNone,
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
              for (final a in list)
                InkWell(
                  onTap: widget.onOpenNews,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
                    child: Row(
                      children: [
                        Icon(announcementIcon(a), size: 18, color: announcementColor(a)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(a.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: a.activeOn(today) ? null : AppColors.textSecondary,
                              )),
                        ),
                        if (a.createdAt != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(DateFormat('d MMM').format(a.createdAt!),
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
