import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/l10n.dart';
import '../../services/timetable_service.dart';
import '../../core/widgets/discard_guard.dart';

/// Owner 2026-11-23: the timetable's rules in one dialog — the gap between
/// two classes, the weekly-hours warning, the minimum of students (and when
/// it is checked) and the teacher-readiness switch. Read by the conflict
/// check, the 5-minute job and the screens.
class TimetableRulesDialog extends StatefulWidget {
  const TimetableRulesDialog({super.key});

  static Future<void> show(BuildContext context) =>
      showDialog<void>(context: context, builder: (_) => const TimetableRulesDialog());

  @override
  State<TimetableRulesDialog> createState() => _TimetableRulesDialogState();
}

class _TimetableRulesDialogState extends State<TimetableRulesDialog> {
  final _service = TimetableService();
  final _gap = TextEditingController();
  final _hours = TextEditingController();
  final _min = TextEditingController();
  final _check = TextEditingController();
  bool _readiness = false;
  bool _loaded = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service.watchSettings().first.then((v) {
      if (!mounted) return;
      setState(() {
        _gap.text = '${v.minGapMinutes}';
        _hours.text = '${v.weeklyHoursWarning}';
        _min.text = '${v.minStudents}';
        _check.text = '${v.minStudentsHours}';
        _readiness = v.teacherReadiness;
        _loaded = true;
      });
      _startSig = _sig();
    });
  }

  @override
  void dispose() {
    for (final c in [_gap, _hours, _min, _check]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final l = context.l10n;
    int? n(TextEditingController c) => int.tryParse(c.text.trim());
    final bad = SchedulingRules.invalid(
        gap: n(_gap), hours: n(_hours), minStudents: n(_min), checkHours: n(_check));
    if (bad != null) {
      setState(() => _error = switch (bad) {
            'gap' => l.rulesGapInvalid,
            'hours' => l.rulesHoursInvalid,
            'min' => l.rulesMinInvalid,
            _ => l.rulesCheckInvalid,
          });
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _service.saveSettings(SchedulingRules(
        minGapMinutes: n(_gap)!,
        weeklyHoursWarning: n(_hours)!,
        minStudents: n(_min)!,
        minStudentsHours: n(_check)!,
        teacherReadiness: _readiness,
      ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Owner 2026-11-24: what the editor held when it opened (or loaded).
  String? _startSig;
  String _sig() => [_gap.text, _hours.text, _min.text, _check.text, '$_readiness'].join('|');
  bool get _dirty => _startSig != null && _sig() != _startSig;

  @override
  Widget build(BuildContext context) =>
      DiscardGuard(isDirty: () => _dirty, child: _buildEditor(context));

  Widget _buildEditor(BuildContext context) {
    final l = context.l10n;
    final width = MediaQuery.sizeOf(context).width;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width < 700 ? width : 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 12, 4),
              child: Row(
                children: [
                  Icon(Icons.tune, color: AppColors.teal),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(l.timetableRules,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  ),
                  IconButton(
                    tooltip: l.commonCancel,
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(l.rulesIntro,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
            ),
            const Divider(height: 1),
            Flexible(
              child: !_loaded
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Section(
                            icon: Icons.schedule,
                            title: l.rulesGapTitle,
                            help: l.rulesGapHelp,
                            child: _NumberField(controller: _gap, suffix: l.rulesUnitMinutes),
                          ),
                          _Section(
                            icon: Icons.groups_outlined,
                            title: l.rulesMinTitle,
                            help: l.rulesMinHelp,
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _NumberField(controller: _min, suffix: l.rulesUnitStudents),
                                Text(l.rulesCheckedBefore),
                                _NumberField(controller: _check, suffix: l.rulesUnitHours),
                              ],
                            ),
                          ),
                          _Section(
                            icon: Icons.work_history_outlined,
                            title: l.rulesHoursTitle,
                            help: l.rulesHoursHelp,
                            child: _NumberField(controller: _hours, suffix: l.rulesUnitHoursWeek),
                          ),
                          _Section(
                            icon: Icons.verified_user_outlined,
                            title: l.rulesReadinessTitle,
                            help: l.rulesReadinessHelp,
                            child: SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              value: _readiness,
                              onChanged: _saving ? null : (v) => setState(() => _readiness = v),
                              title: Text(_readiness ? l.rulesReadinessOn : l.rulesReadinessOff),
                            ),
                          ),
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(_error!, style: TextStyle(color: AppColors.error)),
                            ),
                        ],
                      ),
                    ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () => Navigator.maybePop(context), child: Text(l.commonCancel)),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _saving || !_loaded ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.check, size: 18),
                    label: Text(l.roomsSave),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.help,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String help;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, size: 20, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(help,
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12.5, height: 1.4)),
                  const SizedBox(height: 8),
                  child,
                ],
              ),
            ),
          ],
        ),
      );
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, required this.suffix});

  final TextEditingController controller;
  final String suffix;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 84,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(suffix, style: TextStyle(color: AppColors.textSecondary)),
        ],
      );
}
