import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../l10n/l10n.dart';
import '../../services/timetable_service.dart';

String holidayKindLabel(AppLocalizations l, String kind) => switch (kind) {
      'cuti_bersama' => l.holidayKindLeave,
      'centre' => l.holidayKindCentre,
      _ => l.holidayKindNational,
    };

String _pretty(String date) {
  final d = DateTime.tryParse(date);
  return d == null ? date : DateFormat('EEE, d MMM yyyy').format(d);
}

/// Asks, then opens or closes the centre on [date] (owner 2026-11-23).
/// Returns true when something changed.
Future<bool> confirmDayDecision(BuildContext context,
    {required String date, required bool close, String name = ''}) async {
  final l = context.l10n;
  final reason = TextEditingController(text: name);
  var announce = true;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        title: Text(close ? l.dayCloseTitle(_pretty(date)) : l.dayOpenTitle(_pretty(date))),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(close ? l.dayCloseBody : l.dayOpenBody,
                  style: const TextStyle(height: 1.4)),
              if (close) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: reason,
                  decoration: InputDecoration(labelText: l.dayCloseReason),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: announce,
                  onChanged: (v) => setLocal(() => announce = v ?? true),
                  title: Text(l.dayCloseAnnounce),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.commonCancel)),
          FilledButton(
            style: close ? FilledButton.styleFrom(backgroundColor: AppColors.error) : null,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(close ? l.dayCloseButton : l.dayOpenButton),
          ),
        ],
      ),
    ),
  );
  if (ok != true || !context.mounted) return false;
  final messenger = ScaffoldMessenger.of(context);
  try {
    // The announcement is written in the admin's language.
    final why = reason.text.trim();
    final n = await TimetableService().setDayClosed(date,
        closed: close,
        name: why,
        announce: announce,
        title: l.dayClosedAnnTitle(_pretty(date)),
        body: why.isEmpty ? l.dayClosedAnnBody(_pretty(date)) : '$why. ${l.dayClosedAnnBody(_pretty(date))}');
    messenger.showSnackBar(SnackBar(content: Text(close ? l.dayClosedDone(n) : l.dayOpenedDone(n))));
    return true;
  } on FirebaseFunctionsException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message ?? e.code)));
    return false;
  }
}

/// Admin Timetable → **Holidays**: the Indonesian holidays from today with
/// a decision per day, and closing any other day. Announcements live on the
/// admin **News** page (owner 2026-11-24).
class HolidaysView extends StatefulWidget {
  const HolidaysView({super.key});

  @override
  State<HolidaysView> createState() => _HolidaysViewState();
}

class _HolidaysViewState extends State<HolidaysView> {
  final _service = TimetableService();
  late final Stream<Map<String, Holiday>> _holidays = _service.watchHolidays();
  bool _importing = false;
  bool _triedImport = false;

  Future<void> _import() async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _importing = true);
    try {
      final n = await _service.importHolidays();
      messenger.showSnackBar(SnackBar(content: Text(l.holidaysImported(n))));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _closeOther() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 2, 12, 31),
      initialDate: now,
    );
    if (picked == null || !mounted) return;
    await confirmDayDecision(context,
        date: DateFormat('yyyy-MM-dd').format(picked), close: true);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _importing ? null : _import,
              icon: const Icon(Icons.download_outlined, size: 18),
              label: Text(l.holidaysImport),
            ),
            OutlinedButton.icon(
              onPressed: _closeOther,
              icon: const Icon(Icons.event_busy_outlined, size: 18),
              label: Text(l.holidaysCloseOther),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(l.holidaysTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 2),
        Text(l.holidaysHelp, style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
        const SizedBox(height: 8),
        StreamBuilder<Map<String, Holiday>>(
          stream: _holidays,
          builder: (context, snap) {
            if (!snap.hasData) return const LinearProgressIndicator();
            final list = snap.data!.values.where((h) => h.date.compareTo(today) >= 0).toList()
              ..sort((a, b) => a.date.compareTo(b.date));
            if (list.isEmpty && !_triedImport) {
              _triedImport = true;
              WidgetsBinding.instance.addPostFrameCallback((_) => _import());
            }
            if (list.isEmpty) {
              return Text(l.holidaysNone, style: TextStyle(color: AppColors.textSecondary));
            }
            return Column(
              children: [
                for (final h in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: 320,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_pretty(h.date),
                                    style: const TextStyle(fontWeight: FontWeight.w700)),
                                Text('${h.name} · ${holidayKindLabel(l, h.kind)}',
                                    style: TextStyle(
                                        fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          SegmentedButton<String>(
                            showSelectedIcon: false,
                            segments: [
                              ButtonSegment(value: '', label: Text(l.holidayUndecided)),
                              ButtonSegment(value: 'open', label: Text(l.holidayOpen)),
                              ButtonSegment(value: 'closed', label: Text(l.holidayClosed)),
                            ],
                            selected: {h.decision},
                            onSelectionChanged: (v) {
                              final pick = v.first;
                              if (pick == h.decision || pick.isEmpty) return;
                              confirmDayDecision(context,
                                  date: h.date, close: pick == 'closed', name: h.name);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
