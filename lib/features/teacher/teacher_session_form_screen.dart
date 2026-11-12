import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/shell_nested_page.dart';
import '../../l10n/l10n.dart';
import '../../models/class_session.dart';
import '../../services/firestore_service.dart';

class TeacherSessionFormScreen extends StatefulWidget {
  const TeacherSessionFormScreen({
    super.key,
    required this.teacherId,
    this.session,
    this.embedded = false,
    this.initialDate,
  });

  final String teacherId;
  final ClassSession? session;
  final bool embedded;

  /// Pre-selects the date when opened from the calendar (`?date=yyyy-MM-dd`).
  final DateTime? initialDate;

  bool get isEditing => session != null;

  @override
  State<TeacherSessionFormScreen> createState() =>
      _TeacherSessionFormScreenState();
}

class _TeacherSessionFormScreenState extends State<TeacherSessionFormScreen> {
  static const _durationPresets = [60, 90, 120];

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _capacityController = TextEditingController();
  final _roomController = TextEditingController();
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late bool _isOpen;
  SessionMode? _mode;
  RegistrationState? _registrationState;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final session = widget.session;
    _selectedDate = session != null
        ? DateTime.tryParse(session.sessionDate) ?? DateTime.now()
        : widget.initialDate ?? DateTime.now();
    _titleController.text = session?.sessionTitle ?? '';
    final startMinutes = session?.startMinutes ?? (15 * 60);
    final endMinutes = session?.endMinutes ?? (16 * 60 + 30);
    _startTime = TimeOfDay(hour: startMinutes ~/ 60, minute: startMinutes % 60);
    _endTime = TimeOfDay(hour: endMinutes ~/ 60, minute: endMinutes % 60);
    _capacityController.text = '${session?.capacity ?? 20}';
    _isOpen = session?.isOpen ?? true;
    _mode = session?.mode;
    _roomController.text = session?.room ?? '';
    _registrationState = session?.registrationState;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _capacityController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickStartTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: _startTime);
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: _endTime);
    if (picked != null) setState(() => _endTime = picked);
  }

  void _applyDurationPreset(int minutes) {
    final start = FirestoreService.minutesOfDay(_startTime);
    final endMinutes = start + minutes;
    if (endMinutes >= 24 * 60) return;
    setState(() {
      _endTime = TimeOfDay(
        hour: endMinutes ~/ 60,
        minute: endMinutes % 60,
      );
    });
  }

  int get _selectedDurationMinutes {
    final diff = FirestoreService.minutesOfDay(_endTime) -
        FirestoreService.minutesOfDay(_startTime);
    return diff > 0 ? diff : 0;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final startMinutes = FirestoreService.minutesOfDay(_startTime);
    final endMinutes = FirestoreService.minutesOfDay(_endTime);
    if (endMinutes <= startMinutes) {
      setState(() => _error = context.l10n.teacherSessionEndAfterStart);
      return;
    }

    final capacity = int.tryParse(_capacityController.text.trim()) ?? 20;
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final firestore = context.read<FirestoreService>();
      if (widget.isEditing) {
        await firestore.updateClassSession(
          sessionId: widget.session!.id,
          date: _selectedDate,
          sessionTitle: _titleController.text,
          startMinutes: startMinutes,
          endMinutes: endMinutes,
          capacity: capacity,
          isOpen: _isOpen,
          mode: _mode,
          room: _roomController.text,
          registrationState: _registrationState,
        );
      } else {
        await firestore.createClassSession(
          teacherId: widget.teacherId,
          date: _selectedDate,
          sessionTitle: _titleController.text,
          startMinutes: startMinutes,
          endMinutes: endMinutes,
          capacity: capacity,
          isOpen: _isOpen,
          mode: _mode,
          room: _roomController.text,
          registrationState: _registrationState,
        );
      }
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final dateLabel = DateFormat('EEE, d MMM yyyy').format(_selectedDate);

    return ShellNestedPage(
      embedded: widget.embedded,
      title: widget.isEditing
          ? l.teacherSessionEditTitle
          : l.teacherShellNewClass,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: l.teacherSessionClassTitle,
                  hintText: l.teacherSessionClassTitleHint,
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? l.teacherSessionClassTitleRequired
                    : null,
              ),
              const SizedBox(height: 16),
              AppCard(
                onTap: _pickDate,
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, color: AppColors.teal),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.teacherSessionDate,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            dateLabel,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.navy,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: AppColors.textSecondary),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppCard(
                      onTap: _pickStartTime,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.teacherSessionStart,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            _startTime.format(context),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.navy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppCard(
                      onTap: _pickEndTime,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.teacherSessionEnd,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            _endTime.format(context),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.navy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                l.teacherSessionDuration,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _durationPresets.map((minutes) {
                  final selected = _selectedDurationMinutes == minutes;
                  return ChoiceChip(
                    label: Text(l.teacherSessionMinutes(minutes)),
                    selected: selected,
                    onSelected: (_) => _applyDurationPreset(minutes),
                    selectedColor: AppColors.teal.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color:
                          selected ? AppColors.teal : AppColors.textSecondary,
                    ),
                    side: BorderSide(
                      color: selected ? AppColors.teal : AppColors.border,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _capacityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l.teacherSessionCapacity,
                  hintText: l.teacherSessionCapacityHint,
                ),
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  if (n == null || n < 1) return l.teacherSessionCapacityMin;
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Mode, room and registration state are not shown: the centre
              // has one location and no rooms yet, and registration state was
              // a label only. Existing values are kept on save untouched.
              // Thesis Phase 2 brings rooms and real session statuses.
              AppCard(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.teacherSessionOpenToJoin),
                  subtitle: Text(l.teacherSessionOpenToJoinHint),
                  value: _isOpen,
                  onChanged: (v) => setState(() => _isOpen = v),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        widget.isEditing
                            ? l.teacherSessionSaveChanges
                            : l.teacherSessionCreate,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
