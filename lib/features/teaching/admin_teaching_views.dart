import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/csv_export.dart';
import '../../core/widgets/app_card.dart';
import '../../l10n/l10n.dart';
import '../../models/class_session.dart';
import '../../services/firestore_service.dart';
import '../../services/teaching_day_service.dart';
import '../../services/timetable_service.dart';
import '../timetable/admin_timetable_screen.dart' show weekdayLabel;
import 'teacher_schedule_screen.dart';

String _dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

Widget _heading(String text) => Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
    );

/// Build 7: the admin's follow-up list on the Timetable — open change
/// requests, unconfirmed schedules, and sessions that need a hand (late
/// check-in, unclosed, no teacher) with Substitute / Cancel / Close.
class AdminFollowUpView extends StatefulWidget {
  const AdminFollowUpView({super.key, required this.schedules});

  final List<Schedule> schedules;

  @override
  State<AdminFollowUpView> createState() => _AdminFollowUpViewState();
}

class _AdminFollowUpViewState extends State<AdminFollowUpView> {
  final _service = TeachingDayService();
  late final Stream<List<ChangeRequest>> _requests = _service.watchChangeRequests();
  late final Stream<List<ClassSession>> _sessions =
      context.read<FirestoreService>().watchAllClassSessions();

  Future<void> _resolve(ChangeRequest r, bool accept) async {
    final l = context.l10n;
    final note = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(accept ? l.changeAcceptTitle : l.changeDeclineTitle),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${r.teacherName} · ${r.className}\n${r.reason}'
                  '${r.wanted.isNotEmpty ? '\n→ ${r.wanted}' : ''}'),
              if (accept) ...[
                const SizedBox(height: 8),
                Text(l.changeAcceptHint,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
              TextField(
                controller: note,
                maxLength: 500,
                decoration: InputDecoration(labelText: l.changeNote),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.commonCancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(accept ? l.changeAccept : l.changeDecline)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _service.resolveChange(r.id, accept: accept, note: note.text);
    } on TeachingDayException catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final unconfirmed = widget.schedules.where((s) => s.status != 'confirmed').toList();
    final now = DateTime.now();
    final from = _dateKey(now.subtract(const Duration(days: 14)));
    final to = _dateKey(now.add(const Duration(days: 14)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StreamBuilder<List<ChangeRequest>>(
          stream: _requests,
          builder: (context, snap) {
            final open = (snap.data ?? const <ChangeRequest>[]).where((r) => r.isOpen).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _heading(l.followUpRequests(open.length)),
                if (open.isEmpty)
                  Text(l.followUpNothing, style: TextStyle(color: AppColors.textSecondary)),
                for (final r in open)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      padding: const EdgeInsets.all(12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('${r.teacherName} · ${r.className}: ${r.reason}'
                              '${r.wanted.isNotEmpty ? ' → ${r.wanted}' : ''}'),
                          FilledButton(
                              onPressed: () => _resolve(r, true), child: Text(l.changeAccept)),
                          OutlinedButton(
                              onPressed: () => _resolve(r, false),
                              child: Text(l.changeDecline)),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        _heading(l.followUpUnconfirmed(unconfirmed.length)),
        if (unconfirmed.isEmpty)
          Text(l.followUpNothing, style: TextStyle(color: AppColors.textSecondary)),
        for (final s in unconfirmed)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('${weekdayLabel(l, s.weekday)} ${s.timeLabel} · ${s.className} · '
                '${s.teacherName}'),
          ),
        StreamBuilder<List<ClassSession>>(
          stream: _sessions,
          builder: (context, snap) {
            final list = (snap.data ?? const <ClassSession>[])
                .where((s) =>
                    s.sessionDate.compareTo(from) >= 0 &&
                    s.sessionDate.compareTo(to) <= 0 &&
                    !s.isClosedOrCancelled &&
                    (s.lateCheckIn || s.unclosed || s.lifeStatus == 'needs_teacher'))
                .toList()
              ..sort((a, b) => a.sessionDate != b.sessionDate
                  ? a.sessionDate.compareTo(b.sessionDate)
                  : a.startMinutes.compareTo(b.startMinutes));
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _heading(l.followUpSessions(list.length)),
                if (list.isEmpty)
                  Text(l.followUpNothing, style: TextStyle(color: AppColors.textSecondary)),
                for (final s in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SessionDayCard(session: s, showDate: true),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Build 7 (Must 7): the admin's **Teacher recap** for a month (data
/// only, no pay) with a CSV.
class TeacherRecapView extends StatefulWidget {
  const TeacherRecapView({super.key});

  @override
  State<TeacherRecapView> createState() => _TeacherRecapViewState();
}

class _TeacherRecapViewState extends State<TeacherRecapView> {
  final _service = TeachingDayService();
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  late Future<List<RecapRow>> _rows = _load();

  Future<List<RecapRow>> _load() => _service.recap(DateFormat('yyyyMM').format(_month));

  void _shift(int months) => setState(() {
        _month = DateTime(_month.year, _month.month + months);
        _rows = _load();
      });

  Future<void> _csv(List<RecapRow> rows) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final downloaded = await CsvExport.download(
      fileStem: 'teacher_recap_${DateFormat('yyyy_MM').format(_month)}',
      header: [
        l.recapTeacher, l.recapScheduled, l.recapHeld, l.recapCancelled,
        l.recapLate, l.recapHours,
      ],
      rows: [
        for (final r in rows)
          [r.teacherName, r.scheduled, r.held, r.cancelled, r.lateCheckIns, r.hours],
      ],
    );
    if (!downloaded) messenger.showSnackBar(SnackBar(content: Text(l.recapCopied)));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return FutureBuilder<List<RecapRow>>(
      future: _rows,
      builder: (context, snap) {
        final rows = snap.data ?? const <RecapRow>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                IconButton(
                    onPressed: () => _shift(-1), icon: const Icon(Icons.chevron_left)),
                Text(DateFormat('MMMM yyyy').format(_month),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                IconButton(
                    onPressed: () => _shift(1), icon: const Icon(Icons.chevron_right)),
                OutlinedButton.icon(
                  onPressed: rows.isEmpty ? null : () => _csv(rows),
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: const Text('CSV'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(l.recapHint, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            if (snap.hasError)
              Text('${snap.error}', style: TextStyle(color: AppColors.error))
            else if (!snap.hasData)
              const Center(child: CircularProgressIndicator())
            else if (rows.isEmpty)
              Text(l.recapEmpty, style: TextStyle(color: AppColors.textSecondary))
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text(l.recapTeacher)),
                    DataColumn(label: Text(l.recapScheduled), numeric: true),
                    DataColumn(label: Text(l.recapHeld), numeric: true),
                    DataColumn(label: Text(l.recapCancelled), numeric: true),
                    DataColumn(label: Text(l.recapLate), numeric: true),
                    DataColumn(label: Text(l.recapHours), numeric: true),
                  ],
                  rows: [
                    for (final r in rows)
                      DataRow(cells: [
                        DataCell(Text(r.teacherName.isEmpty ? r.teacherId : r.teacherName)),
                        DataCell(Text('${r.scheduled}')),
                        DataCell(Text('${r.held}')),
                        DataCell(Text('${r.cancelled}')),
                        DataCell(Text('${r.lateCheckIns}')),
                        DataCell(Text(r.hours.toStringAsFixed(1))),
                      ]),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Build 7 (Must 8): Org settings card — reconcile every voucher with the
/// ledger and the open bookings (VC-05).
class ReconcileVouchersCard extends StatefulWidget {
  const ReconcileVouchersCard({super.key});

  @override
  State<ReconcileVouchersCard> createState() => _ReconcileVouchersCardState();
}

class _ReconcileVouchersCardState extends State<ReconcileVouchersCard> {
  bool _busy = false;
  String? _result;
  bool _ok = true;

  Future<void> _run() async {
    final l = context.l10n;
    setState(() {
      _busy = true;
      _result = null;
    });
    try {
      final r = await TeachingDayService().reconcile();
      setState(() {
        _ok = r.mismatches.isEmpty;
        _result = r.mismatches.isEmpty
            ? l.reconcileOk(r.checked)
            : [
                l.reconcileMismatches(r.mismatches.length),
                for (final m in r.mismatches)
                  '• ${m.termId} (${m.studentId}): ${m.problems.join('; ')}',
              ].join('\n');
      });
    } catch (e) {
      setState(() {
        _ok = false;
        _result = '$e';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.reconcileTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(l.reconcileHint,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _busy ? null : _run,
            icon: _busy
                ? const SizedBox(
                    width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.fact_check_outlined, size: 18),
            label: Text(l.reconcileButton),
          ),
          if (_result != null) ...[
            const SizedBox(height: 10),
            SelectableText(_result!,
                style: TextStyle(
                    color: _ok ? AppColors.success : AppColors.error, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}
