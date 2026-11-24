import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/money_format.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/profile_widgets.dart';
import '../../core/widgets/shell_nested_page.dart';
import '../../core/widgets/status_pill.dart';
import '../../l10n/l10n.dart';
import '../../l10n/labels_admin.dart';
import '../../models/app_user.dart';
import '../../models/class_session.dart';
import '../../models/invoice.dart';
import '../../services/firestore_service.dart';
import '../../services/timetable_service.dart';
import '../teacher/student_detail_screen.dart';

/// Owner 2026-11-24: Users → any person opens a profile page. Students keep
/// their own page; teachers and admins get [StaffProfilePage]; parents
/// [ParentProfilePage].
class UserProfileRoute extends StatefulWidget {
  const UserProfileRoute({super.key, required this.userId, this.embedded = false});

  final String userId;
  final bool embedded;

  @override
  State<UserProfileRoute> createState() => _UserProfileRouteState();
}

class _UserProfileRouteState extends State<UserProfileRoute> {
  late Future<AppUser?> _user = context.read<FirestoreService>().getUser(widget.userId);

  void _reload() =>
      setState(() => _user = context.read<FirestoreService>().getUser(widget.userId));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: _user,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snap.data;
        if (user == null || user.isStudent) {
          return StudentDetailScreen(studentId: widget.userId, embedded: widget.embedded);
        }
        if (user.isParent) {
          return ParentProfilePage(user: user, embedded: widget.embedded, onPhoto: _reload);
        }
        return StaffProfilePage(user: user, embedded: widget.embedded, onPhoto: _reload);
      },
    );
  }
}

/// The card on the left (or on top): photo, name, role, contact, edit.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user, required this.onPhoto, this.extra = const []});

  final AppUser user;
  final VoidCallback onPhoto;
  final List<Widget> extra;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ProfilePhotoAvatar(
              user: user,
              size: 84,
              backgroundColor: user.isParent ? AppColors.chipAmberFg : AppColors.navy,
              canEdit: true,
              onPhotoChanged: (_) => onPhoto(),
            ),
          ),
          const SizedBox(height: 12),
          Text(user.displayNameIndonesian,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          if (user.displayNameChinese != null)
            Text(user.displayNameChinese!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              StatusPill(label: user.roleLocalized(l), color: AppColors.teal),
              for (final lv in user.levels) HskBadge(label: lv),
              if (!user.active) StatusPill(label: l.studentInactive, color: AppColors.error),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 10),
          ProfileInfoRow(label: l.commonEmail, value: user.email, icon: Icons.mail_outline),
          if (user.displayWhatsapp != null)
            ProfileInfoRow(label: 'WhatsApp', value: user.displayWhatsapp!, icon: Icons.chat_outlined),
          if ((user.phone ?? '').isNotEmpty)
            ProfileInfoRow(label: l.staffPhone, value: user.phone!, icon: Icons.phone_outlined),
          if (user.createdAt != null)
            ProfileInfoRow(
              label: l.studentMemberSince,
              value: DateFormat('d MMM yyyy').format(user.createdAt!),
              icon: Icons.calendar_today_outlined,
            ),
          const SizedBox(height: 12),
          ...extra,
          if (!user.isAdmin)
            OutlinedButton.icon(
              onPressed: () => context.push('/admin/users/${user.uid}/edit'),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(l.studentDetailEditProfile),
            ),
        ],
      ),
    );
  }
}

/// Card beside the tabs on a wide screen, above them on a narrow one.
Widget _layout(BuildContext context, Widget card, Widget tabBar, List<Widget> section) {
  final wide = MediaQuery.sizeOf(context).width >= 1100;
  if (wide) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 340,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 0, 20),
            child: card,
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [tabBar, const SizedBox(height: 16), ...section],
          ),
        ),
      ],
    );
  }
  return ListView(
    padding: const EdgeInsets.all(16),
    children: [card, const SizedBox(height: 16), tabBar, const SizedBox(height: 16), ...section],
  );
}

Widget _tabs(List<String> names, int selected, ValueChanged<int> onChanged) =>
    SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<int>(
        showSelectedIcon: false,
        segments: [
          for (var i = 0; i < names.length; i++) ButtonSegment(value: i, label: Text(names[i])),
        ],
        selected: {selected},
        onSelectionChanged: (v) => onChanged(v.first),
      ),
    );

const _weekdays = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// A teacher (or admin): weekly classes, coming and recent classes, hours
/// this month and last month, their students.
class StaffProfilePage extends StatefulWidget {
  const StaffProfilePage({super.key, required this.user, required this.onPhoto, this.embedded = false});

  final AppUser user;
  final VoidCallback onPhoto;
  final bool embedded;

  @override
  State<StaffProfilePage> createState() => _StaffProfilePageState();
}

class _StaffProfilePageState extends State<StaffProfilePage> {
  int _tab = 0;
  late final Stream<List<Schedule>> _schedules = TimetableService().watchSchedules();
  late final Stream<List<ClassSession>> _sessions =
      context.read<FirestoreService>().watchMyTeachingSessions(widget.user.uid);
  late final Stream<List<AppUser>> _students = context.read<FirestoreService>().watchAllStudents();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final u = widget.user;
    return ShellNestedPage(
      embedded: widget.embedded,
      title: u.displayNameIndonesian,
      child: StreamBuilder<List<ClassSession>>(
        stream: _sessions,
        builder: (context, sessSnap) {
          final sessions = (sessSnap.data ?? const <ClassSession>[])
              .where((s) => !s.isCancelled)
              .toList();
          final now = DateTime.now();
          final thisMonth = DateFormat('yyyy-MM').format(now);
          final lastMonth = DateFormat('yyyy-MM').format(DateTime(now.year, now.month - 1));
          double hours(String month) => sessions
              .where((s) => s.sessionDate.startsWith(month) && s.isClosedOrCancelled)
              .fold(0.0, (t, s) => t + (s.endMinutes - s.startMinutes) / 60);
          final card = _ProfileCard(
            user: u,
            onPhoto: widget.onPhoto,
            extra: [
              Row(
                children: [
                  Expanded(child: _Stat(label: l.staffHoursThisMonth, value: _h(hours(thisMonth)))),
                  Expanded(child: _Stat(label: l.staffHoursLastMonth, value: _h(hours(lastMonth)))),
                ],
              ),
              const SizedBox(height: 12),
            ],
          );
          final section = <Widget>[
            if (_tab == 0)
              StreamBuilder<List<Schedule>>(
                stream: _schedules,
                builder: (context, snap) {
                  final mine = (snap.data ?? const <Schedule>[])
                      .where((s) => s.active && (s.teacherId == u.uid || s.coTeacherIds.contains(u.uid)))
                      .toList()
                    ..sort((a, b) => a.weekday != b.weekday
                        ? a.weekday.compareTo(b.weekday)
                        : a.startMinutes.compareTo(b.startMinutes));
                  if (mine.isEmpty) return _empty(l.staffNoWeekly);
                  return AppCard(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                    child: Column(
                      children: [
                        for (final s in mine)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: AppColors.teal.withValues(alpha: 0.12),
                              child: Text(_weekdays[s.weekday.clamp(1, 7)],
                                  style: TextStyle(
                                      fontSize: 11, color: AppColors.teal, fontWeight: FontWeight.w700)),
                            ),
                            title: Text(s.className, style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text([
                              s.timeLabel,
                              if (s.room.isNotEmpty) s.room,
                              if (s.teacherId != u.uid) l.staffAsHelper,
                            ].join(' · ')),
                          ),
                      ],
                    ),
                  );
                },
              ),
            if (_tab == 1) ...[
              SectionHeader(title: l.staffComing),
              _sessionList(
                  context,
                  sessions.where((s) => !s.isClosedOrCancelled && !s.hasEnded).toList()
                    ..sort((a, b) => '${a.sessionDate}${a.startMinutes}'
                        .compareTo('${b.sessionDate}${b.startMinutes}')),
                  limit: 20),
              const SizedBox(height: 20),
              SectionHeader(title: l.staffRecent),
              _sessionList(
                  context,
                  sessions.where((s) => s.isClosedOrCancelled || s.hasEnded).toList()
                    ..sort((a, b) => '${b.sessionDate}${b.startMinutes}'
                        .compareTo('${a.sessionDate}${a.startMinutes}')),
                  limit: 20),
            ],
            if (_tab == 2)
              StreamBuilder<List<AppUser>>(
                stream: _students,
                builder: (context, snap) {
                  final mine = (snap.data ?? const <AppUser>[])
                      .where((s) => s.teacherId == u.uid)
                      .toList()
                    ..sort((a, b) => a.staffLabel.compareTo(b.staffLabel));
                  if (mine.isEmpty) return _empty(l.staffNoStudents);
                  return _peopleList(context, mine);
                },
              ),
          ];
          final names = u.isAdmin
              ? [l.staffTabWeekly, l.staffTabClasses]
              : [l.staffTabWeekly, l.staffTabClasses, l.staffTabStudents];
          return _layout(context, card, _tabs(names, _tab, (v) => setState(() => _tab = v)), section);
        },
      ),
    );
  }
}

String _h(double v) => v == v.roundToDouble() ? '${v.round()} h' : '${v.toStringAsFixed(1)} h';

Widget _empty(String text) => AppCard(
      child: Text(text, style: TextStyle(color: AppColors.textSecondary)),
    );

Widget _sessionList(BuildContext context, List<ClassSession> list, {int limit = 20}) {
  final l = context.l10n;
  if (list.isEmpty) return _empty(l.staffNoClasses);
  return AppCard(
    padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
    child: Column(
      children: [
        for (final s in list.take(limit))
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              s.isClosedOrCancelled ? Icons.check_circle_outline : Icons.event_outlined,
              color: s.isClosedOrCancelled ? AppColors.success : AppColors.teal,
            ),
            title: Text(s.sessionTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
                '${DateTime.tryParse(s.sessionDate) == null ? s.sessionDate : DateFormat('EEE d MMM').format(DateTime.parse(s.sessionDate))} · ${s.timeRangeLabel} · ${l.classInfoSeatsValue(s.bookedCount, s.capacity)}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/admin/session/${s.id}'),
          ),
      ],
    ),
  );
}

Widget _peopleList(BuildContext context, List<AppUser> people) => AppCard(
      padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
      child: Column(
        children: [
          for (final s in people)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: AppUserAvatar(
                initials: userInitials(s.displayNameIndonesian),
                size: 36,
                backgroundColor: AppColors.teal,
                photoUrl: s.photoUrl,
              ),
              title: Text(s.staffLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text([if (s.level != null) s.level!, s.email].join(' · ')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/admin/users/${s.uid}'),
            ),
        ],
      ),
    );

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.teal)),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
        ],
      );
}

/// A parent: their children and the children's invoices.
class ParentProfilePage extends StatefulWidget {
  const ParentProfilePage({super.key, required this.user, required this.onPhoto, this.embedded = false});

  final AppUser user;
  final VoidCallback onPhoto;
  final bool embedded;

  @override
  State<ParentProfilePage> createState() => _ParentProfilePageState();
}

class _ParentProfilePageState extends State<ParentProfilePage> {
  int _tab = 0;
  late final Stream<List<AppUser>> _students = context.read<FirestoreService>().watchAllStudents();
  late final Stream<List<Invoice>> _invoices = context.read<FirestoreService>().watchAllInvoices();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final u = widget.user;
    final ids = u.studentIds.toSet();
    final card = _ProfileCard(user: u, onPhoto: widget.onPhoto);
    final section = <Widget>[
      if (_tab == 0)
        StreamBuilder<List<AppUser>>(
          stream: _students,
          builder: (context, snap) {
            final kids = (snap.data ?? const <AppUser>[])
                .where((s) => ids.contains(s.uid) || s.linkedParentUid == u.uid)
                .toList();
            if (kids.isEmpty) return _empty(l.parentNoChildren);
            return _peopleList(context, kids);
          },
        ),
      if (_tab == 1)
        StreamBuilder<List<Invoice>>(
          stream: _invoices,
          builder: (context, snap) {
            final list = (snap.data ?? const <Invoice>[])
                .where((i) => ids.contains(i.studentId) && !i.isDiscarded)
                .toList()
              ..sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
            if (list.isEmpty) return _empty(l.studentDetailNoInvoices);
            return AppCard(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              child: Column(
                children: [
                  for (final i in list)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${i.invoiceNumber} · ${i.studentName ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(i.itemLocalized(l)),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(formatRupiah(i.amount), style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(i.status.localized(l),
                              style: TextStyle(
                                  fontSize: 12,
                                  color: i.isPaid ? AppColors.success : AppColors.chipAmberFg)),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
    ];
    return ShellNestedPage(
      embedded: widget.embedded,
      title: u.displayNameIndonesian,
      child: _layout(
        context,
        card,
        _tabs([l.parentTabChildren, l.navPayments], _tab, (v) => setState(() => _tab = v)),
        section,
      ),
    );
  }
}
