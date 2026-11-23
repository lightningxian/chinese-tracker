import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../l10n/l10n.dart';

String _today() => DateFormat('yyyy-MM-dd').format(DateTime.now());

/// Owner 2026-11-23: an announcement students, parents and teachers see on
/// their home page (`announcements/{id}`). [kind] `closure` comes from
/// closing a day; `info` is typed by the admin. Shown until [toDate].
class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.audience,
    required this.kind,
    required this.date,
    required this.toDate,
  });

  final String id;
  final String title;
  final String body;

  /// `all`, `students` (students and parents) or `teachers`.
  final String audience;
  final String kind;

  /// The closed day for a closure ('' otherwise).
  final String date;
  final String toDate;

  bool get isClosure => kind == 'closure';

  /// Whether a user with [role] sees it ([role] as in `users.role`).
  bool shownTo(String role) => switch (audience) {
        'students' => role == 'student' || role == 'parent' || role == 'admin',
        'teachers' => role == 'teacher' || role == 'admin',
        _ => true,
      };

  bool activeOn(String day) => toDate.compareTo(day) >= 0;

  factory Announcement.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const <String, dynamic>{};
    return Announcement(
      id: d.id,
      title: m['title'] as String? ?? '',
      body: m['body'] as String? ?? '',
      audience: m['audience'] as String? ?? 'all',
      kind: m['kind'] as String? ?? 'info',
      date: m['date'] as String? ?? '',
      toDate: m['toDate'] as String? ?? '',
    );
  }
}

class AnnouncementService {
  AnnouncementService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('announcements');

  /// Announcements still shown today, newest first.
  Stream<List<Announcement>> watchActive() => _col
      .where('toDate', isGreaterThanOrEqualTo: _today())
      .snapshots()
      .map((s) => s.docs.map(Announcement.fromDoc).toList()
        ..sort((a, b) => a.toDate.compareTo(b.toDate)));

  Future<void> add({
    required String title,
    required String body,
    required String audience,
    required String toDate,
    required String byName,
  }) =>
      _col.add({
        'title': title.trim(),
        'body': body.trim(),
        'audience': audience,
        'kind': 'info',
        'fromDate': _today(),
        'toDate': toDate,
        'createdByName': byName,
        'createdAt': FieldValue.serverTimestamp(),
      });

  Future<void> delete(String id) => _col.doc(id).delete();
}

/// The home-page banner: every active announcement for [role].
class AnnouncementBanner extends StatefulWidget {
  const AnnouncementBanner({super.key, required this.role});

  final String role;

  @override
  State<AnnouncementBanner> createState() => _AnnouncementBannerState();
}

class _AnnouncementBannerState extends State<AnnouncementBanner> {
  late final Stream<List<Announcement>> _stream = AnnouncementService().watchActive();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return StreamBuilder<List<Announcement>>(
      stream: _stream,
      builder: (context, snap) {
        final list = (snap.data ?? const <Announcement>[])
            .where((a) => a.shownTo(widget.role))
            .toList();
        if (list.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              for (final a in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(a.isClosure ? Icons.event_busy : Icons.campaign_outlined,
                            color: a.isClosure ? AppColors.error : AppColors.teal),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.title,
                                  style: const TextStyle(fontWeight: FontWeight.w800)),
                              if (a.body.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(a.body, style: const TextStyle(height: 1.4)),
                              ],
                              const SizedBox(height: 4),
                              Text(l.announcementUntil(a.toDate),
                                  style: TextStyle(
                                      fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
