import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/paging/date_range.dart';
import '../../core/paging/paged_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../l10n/l10n.dart';
import '../../core/widgets/discard_guard.dart';

String _today() => DateFormat('yyyy-MM-dd').format(DateTime.now());

/// Owner 2026-11-23: an announcement students, parents and teachers see on
/// their home page (`announcements/{id}`). [kind] `closure` comes from
/// closing a day; `info` is typed by the admin on **News**. Shown until
/// [toDate].
class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.audience,
    required this.kind,
    required this.date,
    required this.toDate,
    this.fromDate = '',
    this.byName = '',
    this.createdAt,
  });

  final String id;
  final String title;
  final String body;

  /// `all`, `students` (students and parents) or `teachers`.
  final String audience;
  final String kind;

  /// The closed day for a closure ('' otherwise).
  final String date;
  final String fromDate;
  final String toDate;
  final String byName;
  final DateTime? createdAt;

  bool get isClosure => kind == 'closure';

  /// Owner 2026-11-24: a holiday on which classes run after all.
  bool get isOpened => kind == 'opened';

  /// Owner 2026-11-24: "shown until" is optional; no end date is stored as
  /// [noEnd] so the "still shown" query keeps working.
  static const noEnd = '9999-12-31';
  bool get hasEnd => toDate != noEnd;

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
      fromDate: m['fromDate'] as String? ?? '',
      toDate: m['toDate'] as String? ?? '',
      byName: m['createdByName'] as String? ?? '',
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class AnnouncementService {
  AnnouncementService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('announcements');

  /// Announcements still shown today, soonest end first.
  Stream<List<Announcement>> watchActive() => _col
      .where('toDate', isGreaterThanOrEqualTo: _today())
      .snapshots()
      .map((s) => s.docs.map(Announcement.fromDoc).toList()
        ..sort((a, b) => a.toDate.compareTo(b.toDate)));

  /// Build 9 Then list: every post, newest first, in [range], a page at a
  /// time (the admin's News page).
  PageSource<Announcement> allSource(DateRangeSel range) => FirestorePageSource(
      applyDateRange(_col.orderBy('createdAt', descending: true), 'createdAt', range),
      Announcement.fromDoc);

  /// The admin's News page: the latest [limit], newest first.
  Stream<List<Announcement>> watchRecent({int limit = 40}) => _col
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(Announcement.fromDoc).toList());

  /// [notify] also rings everyone's bell (the `onAnnouncementCreated`
  /// function sends the notices).
  Future<void> add({
    required String title,
    required String body,
    required String audience,
    required String toDate,
    required String byName,
    bool notify = false,
  }) =>
      _col.add({
        'title': title.trim(),
        'body': body.trim(),
        'audience': audience,
        'kind': 'info',
        'fromDate': _today(),
        'toDate': toDate,
        'notify': notify,
        'createdByName': byName,
        'createdAt': FieldValue.serverTimestamp(),
      });

  Future<void> update(
    String id, {
    required String title,
    required String body,
    required String audience,
    required String toDate,
  }) =>
      _col.doc(id).update({
        'title': title.trim(),
        'body': body.trim(),
        'audience': audience,
        'toDate': toDate,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> delete(String id) => _col.doc(id).delete();
}

IconData announcementIcon(Announcement a) => a.isClosure
    ? Icons.event_busy
    : a.isOpened
        ? Icons.event_available
        : Icons.campaign_outlined;

Color announcementColor(Announcement a) => a.isClosure ? AppColors.error : AppColors.teal;

String announcementAudienceLabel(AppLocalizations l, String audience) => switch (audience) {
      'students' => l.announcementForStudents,
      'teachers' => l.announcementForTeachers,
      _ => l.announcementForAll,
    };

/// New announcement, or edit [existing] (admin, News page).
class AnnouncementDialog extends StatefulWidget {
  const AnnouncementDialog({super.key, required this.byName, this.existing});

  final String byName;
  final Announcement? existing;

  static Future<void> show(BuildContext context,
          {required String byName, Announcement? existing}) =>
      showDialog<void>(
        context: context,
        builder: (_) => AnnouncementDialog(byName: byName, existing: existing),
      );

  @override
  State<AnnouncementDialog> createState() => _AnnouncementDialogState();
}

class _AnnouncementDialogState extends State<AnnouncementDialog> {
  late final _title = TextEditingController(text: widget.existing?.title ?? '');
  late final _body = TextEditingController(text: widget.existing?.body ?? '');
  late String _audience = widget.existing?.audience ?? 'all';
  // Owner 2026-11-24: no end date unless the admin picks one.
  late DateTime? _until = widget.existing == null || !widget.existing!.hasEnd
      ? null
      : DateTime.tryParse(widget.existing!.toDate);
  bool _notify = true;
  bool _saving = false;
  String? _error;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _startSig = _sig();
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  String _cut(String s, int max) => s.length <= max ? s : s.substring(0, max);

  Future<void> _save() async {
    final l = context.l10n;
    final title = _cut(_title.text.trim(), 120);
    final body = _cut(_body.text.trim(), 1000);
    if (title.isEmpty) {
      setState(() => _error = l.announcementTitleMissing);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final until = _until == null ? Announcement.noEnd : DateFormat('yyyy-MM-dd').format(_until!);
    try {
      final service = AnnouncementService();
      if (_editing) {
        await service.update(widget.existing!.id,
            title: title, body: body, audience: _audience, toDate: until);
      } else {
        await service.add(
          title: title,
          body: body,
          audience: _audience,
          toDate: until,
          byName: widget.byName,
          notify: _notify,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Owner 2026-11-24: what the editor held when it opened (or loaded).
  String? _startSig;
  String _sig() => [_title.text, _body.text, _audience, '$_until'].join('|');
  bool get _dirty => _startSig != null && _sig() != _startSig;

  @override
  Widget build(BuildContext context) =>
      DiscardGuard(isDirty: () => _dirty, child: _buildEditor(context));

  Widget _buildEditor(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(_editing ? l.announcementEdit : l.announcementNew),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _title,
                maxLength: 120,
                decoration: InputDecoration(labelText: l.announcementTitleLabel),
              ),
              TextField(
                controller: _body,
                maxLength: 1000,
                minLines: 4,
                maxLines: 8,
                decoration: InputDecoration(labelText: l.announcementBodyLabel),
              ),
              const SizedBox(height: 8),
              Text(l.announcementWhoSees,
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: 'all', label: Text(l.announcementForAll)),
                  ButtonSegment(value: 'students', label: Text(l.announcementForStudents)),
                  ButtonSegment(value: 'teachers', label: Text(l.announcementForTeachers)),
                ],
                selected: {_audience},
                onSelectionChanged: (v) => setState(() => _audience = v.first),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: Text(_until == null
                          ? l.announcementNoEnd
                          : l.announcementUntil(DateFormat('yyyy-MM-dd').format(_until!)))),
                  if (_until != null)
                    IconButton(
                      tooltip: l.announcementClearDate,
                      onPressed: () => setState(() => _until = null),
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  TextButton.icon(
                    onPressed: () async {
                      final now = DateTime.now();
                      final d = await showDatePicker(
                        context: context,
                        firstDate: now,
                        lastDate: DateTime(now.year + 2, 12, 31),
                        initialDate: _until == null || _until!.isBefore(now)
                            ? now.add(const Duration(days: 7))
                            : _until!,
                      );
                      if (d != null) setState(() => _until = d);
                    },
                    icon: const Icon(Icons.event, size: 18),
                    label: Text(_until == null ? l.announcementSetDate : l.announcementPickDate),
                  ),
                ],
              ),
              if (!_editing)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _notify,
                  onChanged: (v) => setState(() => _notify = v ?? true),
                  title: Text(l.announcementNotify),
                  subtitle: Text(l.announcementNotifyHelp),
                ),
              if (_error != null) Text(_error!, style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.maybePop(context), child: Text(l.commonCancel)),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_editing ? l.roomsSave : l.announcementPost),
        ),
      ],
    );
  }
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
                        Icon(announcementIcon(a), color: announcementColor(a)),
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
                              if (a.hasEnd) ...[
                                const SizedBox(height: 4),
                                Text(l.announcementUntil(a.toDate),
                                    style: TextStyle(
                                        fontSize: 11, color: AppColors.textSecondary)),
                              ],
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
