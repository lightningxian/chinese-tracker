import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/shell_nested_page.dart';
import '../../l10n/l10n.dart';
import '../../models/app_user.dart';
import '../../services/firestore_service.dart';
import '../../services/rooms_service.dart';
import '../../services/timetable_service.dart';
import '../teaching/admin_teaching_views.dart';

String weekdayLabel(AppLocalizations l, int d) => switch (d) {
      1 => l.weekdayMon,
      2 => l.weekdayTue,
      3 => l.weekdayWed,
      4 => l.weekdayThu,
      5 => l.weekdayFri,
      6 => l.weekdaySat,
      _ => l.weekdaySun,
    };

/// Build 6 (Must 7): the admin **Timetable** — the week as a grid
/// (weekdays across, rooms down), a list, **New schedule** with the live
/// conflict check, and the teachers' availability.
class AdminTimetableScreen extends StatefulWidget {
  const AdminTimetableScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AdminTimetableScreen> createState() => _AdminTimetableScreenState();
}

class _AdminTimetableScreenState extends State<AdminTimetableScreen> {
  final _service = TimetableService();
  late final Stream<List<Schedule>> _schedules = _service.watchSchedules();
  late final Stream<List<AppUser>> _teachers =
      context.read<FirestoreService>().watchAllTeachers();
  late final Stream<List<String>> _rooms = RoomsService().watchRooms();
  int _view = 0;

  Future<void> _edit(List<AppUser> teachers, List<String> rooms, {Schedule? s}) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _ScheduleDialog(teachers: teachers, rooms: rooms, existing: s),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ShellNestedPage(
      embedded: widget.embedded,
      title: l.timetableTitle,
      child: StreamBuilder<List<AppUser>>(
        stream: _teachers,
        builder: (context, tSnap) => StreamBuilder<List<String>>(
          stream: _rooms,
          builder: (context, rSnap) => StreamBuilder<List<Schedule>>(
            stream: _schedules,
            builder: (context, snap) {
              final teachers = tSnap.data ?? const <AppUser>[];
              final rooms = rSnap.data ?? RoomsService.defaults;
              final all = (snap.data ?? const <Schedule>[]).where((s) => s.active).toList();
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SegmentedButton<int>(
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(value: 0, label: Text(l.timetableGrid)),
                          ButtonSegment(value: 1, label: Text(l.timetableList)),
                          ButtonSegment(value: 2, label: Text(l.timetableAvailability)),
                          ButtonSegment(value: 3, label: Text(l.timetableFollowUp)),
                          ButtonSegment(value: 4, label: Text(l.timetableRecap)),
                        ],
                        selected: {_view},
                        onSelectionChanged: (v) => setState(() => _view = v.first),
                      ),
                      FilledButton.icon(
                        onPressed: () => _edit(teachers, rooms),
                        style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
                        icon: const Icon(Icons.add),
                        label: Text(l.timetableNew),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_view == 0)
                    _Grid(schedules: all, rooms: rooms,
                        onTap: (s) => _edit(teachers, rooms, s: s))
                  else if (_view == 1)
                    for (final s in all)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppCard(
                          onTap: () => _edit(teachers, rooms, s: s),
                          child: Text(
                            '${weekdayLabel(l, s.weekday)} ${s.timeLabel} · ${s.className} · '
                            '${s.room} · ${s.teacherName} · '
                            '${s.level.isEmpty ? l.bookingAllLevels : s.level} · '
                            '${l.timetableSeats(s.capacity)}',
                          ),
                        ),
                      )
                  else if (_view == 2)
                    _Availability(teachers: teachers)
                  else if (_view == 3)
                    AdminFollowUpView(schedules: all)
                  else
                    const TeacherRecapView(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.schedules, required this.rooms, required this.onTap});

  final List<Schedule> schedules;
  final List<String> rooms;
  final ValueChanged<Schedule> onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final allRooms = {...rooms, ...schedules.map((s) => s.room)}.toList();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const FixedColumnWidth(150),
        border: TableBorder.all(color: AppColors.border),
        children: [
          TableRow(children: [
            const SizedBox(),
            for (final d in weekdayKeys)
              Padding(
                padding: const EdgeInsets.all(6),
                child: Text(weekdayLabel(l, d),
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
          ]),
          for (final room in allRooms)
            TableRow(children: [
              Padding(
                padding: const EdgeInsets.all(6),
                child: Text(room, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              for (final d in weekdayKeys)
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final s in schedules.where((x) => x.weekday == d && x.room == room))
                        InkWell(
                          onTap: () => onTap(s),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.teal.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${s.timeLabel}\n${s.className}\n${s.teacherName}\n'
                              '${s.level.isEmpty ? l.bookingAllLevels : s.level} · '
                              '${l.timetableSeats(s.capacity)}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ]),
        ],
      ),
    );
  }
}

class _Availability extends StatelessWidget {
  const _Availability({required this.teachers});

  final List<AppUser> teachers;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return StreamBuilder<List<({String id, String teacherId, String date, String reason})>>(
      stream: TimetableService().watchDaysOff(),
      builder: (context, snap) {
        final off = snap.data ?? const [];
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultColumnWidth: const FixedColumnWidth(120),
            border: TableBorder.all(color: AppColors.border),
            children: [
              TableRow(children: [
                const SizedBox(),
                for (final d in weekdayKeys)
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(weekdayLabel(l, d),
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
              ]),
              for (final t in teachers)
                TableRow(children: [
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.staffLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
                        for (final o in off.where((o) => o.teacherId == t.uid))
                          Text('${l.timetableDayOff} ${o.date}',
                              style: TextStyle(fontSize: 11, color: AppColors.error)),
                      ],
                    ),
                  ),
                  for (final d in weekdayKeys)
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(
                        [
                          for (final w in (t.availability[d] ?? const []))
                            '${clockOf(w.startMinutes)}–${clockOf(w.endMinutes)}',
                        ].join('\n'),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                ]),
            ],
          ),
        );
      },
    );
  }
}

class _ScheduleDialog extends StatefulWidget {
  const _ScheduleDialog({required this.teachers, required this.rooms, this.existing});

  final List<AppUser> teachers;
  final List<String> rooms;
  final Schedule? existing;

  @override
  State<_ScheduleDialog> createState() => _ScheduleDialogState();
}

class _ScheduleDialogState extends State<_ScheduleDialog> {
  final _service = TimetableService();
  late final _name = TextEditingController(text: widget.existing?.className ?? '');
  late final _start = TextEditingController(
      text: widget.existing == null ? '16:00' : clockOf(widget.existing!.startMinutes));
  late final _end = TextEditingController(
      text: widget.existing == null ? '17:30' : clockOf(widget.existing!.endMinutes));
  late final _capacity = TextEditingController(text: '${widget.existing?.capacity ?? 8}');
  late final _from = TextEditingController(text: widget.existing?.validFrom ?? '');
  late final _to = TextEditingController(text: widget.existing?.validTo ?? '');
  late int _weekday = widget.existing?.weekday ?? 1;
  late String? _room = widget.existing?.room ?? widget.rooms.firstOrNull;
  late String? _teacher = widget.existing?.teacherId;
  late String _level = widget.existing?.level ?? '';
  ScheduleCheck? _check;
  Timer? _debounce;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [_name, _start, _end, _capacity, _from, _to]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic>? _input() {
    final s = minutesOf(_start.text);
    final e = minutesOf(_end.text);
    if (s == null || e == null || _teacher == null || _room == null) return null;
    return {
      if (widget.existing != null) 'id': widget.existing!.id,
      'className': _name.text.trim(),
      'weekday': _weekday,
      'startMinutes': s,
      'endMinutes': e,
      'room': _room,
      'teacherId': _teacher,
      'capacity': int.tryParse(_capacity.text.trim()) ?? 8,
      'level': _level,
      'validFrom': _from.text.trim(),
      'validTo': _to.text.trim(),
    };
  }

  /// The check runs as the admin types (Build 6, screenshot 11).
  void _changed() {
    setState(() => _error = null);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final input = _input();
      if (input == null) return;
      try {
        final c = await _service.check(input);
        if (mounted) setState(() => _check = c);
      } catch (e) {
        if (mounted) setState(() => _error = '$e');
      }
    });
  }

  Future<void> _save() async {
    final input = _input();
    if (input == null) return;
    setState(() => _saving = true);
    try {
      await _service.save(input);
      if (mounted) Navigator.pop(context);
    } on FirebaseFunctionsException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = _check;
    return AlertDialog(
      title: Text(widget.existing == null ? l.timetableNew : l.timetableEdit),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _name,
                decoration: InputDecoration(labelText: l.timetableClassName),
                onChanged: (_) => _changed(),
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<int>(
                    initialValue: _weekday,
                    decoration: InputDecoration(labelText: l.timetableWeekday),
                    items: [
                      for (final d in weekdayKeys)
                        DropdownMenuItem(value: d, child: Text(weekdayLabel(l, d))),
                    ],
                    onChanged: (v) {
                      _weekday = v ?? 1;
                      _changed();
                    },
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _start,
                    decoration: InputDecoration(labelText: l.timetableStart),
                    onChanged: (_) => _changed(),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _end,
                    decoration: InputDecoration(labelText: l.timetableEnd),
                    onChanged: (_) => _changed(),
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _capacity,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: l.timetableCapacity),
                    onChanged: (_) => _changed(),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _teacher,
                isExpanded: true,
                decoration: InputDecoration(labelText: l.approvalTeacher),
                items: [
                  for (final t in widget.teachers.where((t) => t.active))
                    DropdownMenuItem(value: t.uid, child: Text(t.staffLabel)),
                ],
                onChanged: (v) {
                  _teacher = v;
                  _changed();
                },
              ),
              DropdownButtonFormField<String>(
                initialValue: _room,
                decoration: InputDecoration(labelText: l.roomsLabel),
                items: [
                  for (final r in RoomsService.choices(widget.rooms, widget.existing?.room))
                    DropdownMenuItem(value: r, child: Text(r)),
                ],
                onChanged: (v) {
                  _room = v;
                  _changed();
                },
              ),
              DropdownButtonFormField<String>(
                initialValue: _level,
                decoration: InputDecoration(labelText: l.commonHskLevel),
                items: [
                  DropdownMenuItem(value: '', child: Text(l.bookingAllLevels)),
                  for (final lv in AppConstants.hskLevels)
                    DropdownMenuItem(value: lv, child: Text(lv)),
                ],
                onChanged: (v) {
                  _level = v ?? '';
                  _changed();
                },
              ),
              Wrap(spacing: 8, children: [
                SizedBox(
                  width: 150,
                  child: TextField(
                    controller: _from,
                    decoration: InputDecoration(
                        labelText: l.timetableFrom, hintText: '2026-12-01'),
                    onChanged: (_) => _changed(),
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: TextField(
                    controller: _to,
                    decoration: InputDecoration(
                        labelText: l.timetableTo, hintText: '2027-03-31'),
                    onChanged: (_) => _changed(),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              if (c != null && c.ok)
                Text(l.timetableNoClash,
                    style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700)),
              if (c != null)
                for (final r in c.reasons)
                  Text('• $r', style: TextStyle(color: AppColors.error)),
              if (c != null)
                for (final w in c.warnings)
                  Text('• $w', style: TextStyle(color: AppColors.chipAmberFg)),
              if (c != null && c.suggestions.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(l.timetableSuggestions,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final sg in c.suggestions)
                      ActionChip(
                        label: Text('${weekdayLabel(l, sg.weekday)} '
                            '${clockOf(sg.startMinutes)}–${clockOf(sg.endMinutes)}'),
                        onPressed: () {
                          _weekday = sg.weekday;
                          _start.text = clockOf(sg.startMinutes);
                          _end.text = clockOf(sg.endMinutes);
                          _changed();
                        },
                      ),
                  ],
                ),
              ],
              if (_error != null) Text(_error!, style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.commonCancel)),
        FilledButton(
          onPressed: _saving || (c != null && !c.ok) ? null : _save,
          child: Text(l.roomsSave),
        ),
      ],
    );
  }
}
