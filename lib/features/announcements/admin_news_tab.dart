import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../l10n/l10n.dart';
import '../../services/auth_service.dart';
import 'announcements.dart';

/// Admin **News** (owner 2026-11-24): announcements for everyone, students
/// and parents, or teachers. They show on the home pages until their end
/// date; a new one may also ring the bell. Closing a day (Timetable →
/// Holidays) posts its own announcement here too.
class AdminNewsTab extends StatefulWidget {
  const AdminNewsTab({super.key});

  @override
  State<AdminNewsTab> createState() => _AdminNewsTabState();
}

class _AdminNewsTabState extends State<AdminNewsTab> {
  late final Stream<List<Announcement>> _recent = AnnouncementService().watchRecent();
  bool _showPast = false;

  String get _byName => context.read<AuthService>().appUser?.name ?? '';

  Future<void> _delete(Announcement a) async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.announcementDeleteTitle),
        content: Text(a.title),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.commonCancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.timetableDelete),
          ),
        ],
      ),
    );
    if (ok == true) await AnnouncementService().delete(a.id);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return StreamBuilder<List<Announcement>>(
      stream: _recent,
      builder: (context, snap) {
        final all = snap.data ?? const <Announcement>[];
        final active = all.where((a) => a.activeOn(today)).toList();
        final past = all.where((a) => !a.activeOn(today)).toList();
        return ListView(
          padding: EdgeInsets.all(wide ? 32 : 16),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.newsTitle,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(l.newsIntro,
                          style: TextStyle(color: AppColors.textSecondary, height: 1.4)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => AnnouncementDialog.show(context, byName: _byName),
                  icon: const Icon(Icons.campaign_outlined, size: 18),
                  label: Text(l.announcementNew),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SectionLabel(text: l.newsActive(active.length)),
            const SizedBox(height: 8),
            if (!snap.hasData)
              const LinearProgressIndicator()
            else if (active.isEmpty)
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Text(l.announcementsNone,
                    style: TextStyle(color: AppColors.textSecondary)),
              )
            else
              for (final a in active)
                _NewsCard(
                  announcement: a,
                  onEdit: a.isClosure
                      ? null
                      : () => AnnouncementDialog.show(context, byName: _byName, existing: a),
                  onDelete: () => _delete(a),
                ),
            if (past.isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _showPast = !_showPast),
                  icon: Icon(_showPast ? Icons.expand_less : Icons.expand_more),
                  label: Text(l.newsPast(past.length)),
                ),
              ),
              if (_showPast)
                for (final a in past)
                  _NewsCard(announcement: a, faded: true, onDelete: () => _delete(a)),
            ],
          ],
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      );
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({
    required this.announcement,
    required this.onDelete,
    this.onEdit,
    this.faded = false,
  });

  final Announcement announcement;
  final VoidCallback? onEdit;
  final VoidCallback onDelete;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = announcement;
    final accent = a.isClosure ? AppColors.error : AppColors.teal;
    final posted = a.createdAt == null ? '' : DateFormat('d MMM yyyy').format(a.createdAt!);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        opacity: faded ? 0.6 : 1,
        child: AppCard(
          onTap: onEdit,
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(a.isClosure ? Icons.event_busy : Icons.campaign_outlined, color: accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    if (a.body.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(a.body, style: const TextStyle(height: 1.4)),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _Pill(text: announcementAudienceLabel(l, a.audience), color: accent),
                        if (a.isClosure) _Pill(text: l.newsClosure, color: AppColors.error),
                        Text(
                          [
                            l.announcementUntil(a.toDate),
                            if (posted.isNotEmpty) l.newsPosted(posted),
                            if (a.byName.isNotEmpty) a.byName,
                          ].join(' · '),
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                IconButton(
                  tooltip: l.announcementEdit,
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
              IconButton(
                tooltip: l.timetableDelete,
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(text,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
      );
}
