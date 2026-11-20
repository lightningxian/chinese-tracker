import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../l10n/l10n.dart';
import '../../models/app_user.dart';
import '../../services/timetable_service.dart';
import 'admin_timetable_screen.dart' show weekdayLabel;

/// `15:00-18:00, 19:00-20:30` → windows; null when a part is not a range.
List<({int startMinutes, int endMinutes})>? parseWindows(String text) {
  final out = <({int startMinutes, int endMinutes})>[];
  for (final part in text.split(',')) {
    final t = part.trim();
    if (t.isEmpty) continue;
    final bits = t.split(RegExp(r'\s*[-–]\s*'));
    if (bits.length != 2) return null;
    final a = minutesOf(bits[0]);
    final b = minutesOf(bits[1]);
    if (a == null || b == null || b <= a) return null;
    out.add((startMinutes: a, endMinutes: b));
  }
  return out;
}

String windowsText(List<({int startMinutes, int endMinutes})> w) =>
    w.map((x) => '${clockOf(x.startMinutes)}-${clockOf(x.endMinutes)}').join(', ');

/// Build 6 (Must 2): a teacher's weekly availability and days off, edited
/// by the teacher on the profile tab.
class TeacherAvailabilityCard extends StatefulWidget {
  const TeacherAvailabilityCard({super.key, required this.teacher});

  final AppUser teacher;

  @override
  State<TeacherAvailabilityCard> createState() => _TeacherAvailabilityCardState();
}

class _TeacherAvailabilityCardState extends State<TeacherAvailabilityCard> {
  final _service = TimetableService();
  late final Map<int, TextEditingController> _days = {
    for (final d in weekdayKeys)
      d: TextEditingController(text: windowsText(widget.teacher.availability[d] ?? const [])),
  };
  final _offDate = TextEditingController();
  final _offReason = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in _days.values) {
      c.dispose();
    }
    _offDate.dispose();
    _offReason.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = context.l10n;
    final out = <int, List<({int startMinutes, int endMinutes})>>{};
    for (final e in _days.entries) {
      final w = parseWindows(e.value.text);
      if (w == null) {
        setState(() => _error = l.availabilityInvalid(weekdayLabel(l, e.key)));
        return;
      }
      if (w.isNotEmpty) out[e.key] = w;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _service.saveAvailability(widget.teacher.uid, out);
      messenger.showSnackBar(SnackBar(content: Text(l.availabilitySaved)));
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.availabilityTitle,
              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy)),
          Text(l.availabilityHint,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          for (final d in weekdayKeys)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(width: 56, child: Text(weekdayLabel(l, d))),
                  Expanded(
                    child: TextField(
                      controller: _days[d],
                      decoration: const InputDecoration(
                          isDense: true, hintText: '15:00-18:00'),
                    ),
                  ),
                ],
              ),
            ),
          if (_error != null) Text(_error!, style: TextStyle(color: AppColors.error)),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(l.roomsSave),
            ),
          ),
          const Divider(height: 24),
          Text(l.timetableDaysOff, style: const TextStyle(fontWeight: FontWeight.w700)),
          StreamBuilder<List<({String id, String teacherId, String date, String reason})>>(
            stream: _service.watchDaysOff(teacherId: widget.teacher.uid),
            builder: (context, snap) => Column(
              children: [
                for (final o in snap.data ?? const [])
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(o.date),
                    subtitle: o.reason.isEmpty ? null : Text(o.reason),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _service.deleteDayOff(o.id),
                    ),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              SizedBox(
                width: 130,
                child: TextField(
                  controller: _offDate,
                  decoration: const InputDecoration(isDense: true, hintText: '2026-12-24'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _offReason,
                  decoration: InputDecoration(isDense: true, hintText: l.timetableReason),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  final date = _offDate.text.trim();
                  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) return;
                  _service.addDayOff(widget.teacher.uid, date, _offReason.text);
                  _offDate.clear();
                  _offReason.clear();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
