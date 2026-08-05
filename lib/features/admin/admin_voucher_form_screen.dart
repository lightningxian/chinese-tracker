import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/shell_nested_page.dart';
import '../../models/app_user.dart';
import '../../models/student_class_term.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class AdminVoucherFormScreen extends StatefulWidget {
  const AdminVoucherFormScreen({
    super.key,
    this.termId,
    this.embedded = false,
  });

  final String? termId;
  final bool embedded;

  bool get isEditing => termId != null;

  @override
  State<AdminVoucherFormScreen> createState() => _AdminVoucherFormScreenState();
}

class _AdminVoucherFormScreenState extends State<AdminVoucherFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  StudentClassTerm? _term;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  String? _studentId;
  String _studentName = '—';
  int _packageSize = AppConstants.defaultTermSize;
  int _sessionsRemaining = AppConstants.defaultTermSize;
  late DateTime _startDate;
  late DateTime _deadlineDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = now;
    _deadlineDate = now.add(const Duration(days: 90));
    _load();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!widget.isEditing) {
      setState(() => _loading = false);
      return;
    }

    final firestore = context.read<FirestoreService>();
    final term = await firestore.getClassTerm(widget.termId!);
    final student =
        term == null ? null : await firestore.getUser(term.studentId);
    if (!mounted) return;

    if (term == null) {
      setState(() {
        _loading = false;
        _error = 'Voucher not found';
      });
      return;
    }

    _notesController.text = term.notes ?? '';
    setState(() {
      _term = term;
      _studentId = term.studentId;
      _studentName = student?.name ?? 'Unknown student';
      _packageSize = term.packageSize;
      _sessionsRemaining = term.sessionsRemaining;
      _startDate = DateTime.tryParse(term.startDate) ?? DateTime.now();
      _deadlineDate =
          DateTime.tryParse(term.deadlineDate) ?? _startDate.add(const Duration(days: 90));
      _loading = false;
    });
  }

  Future<void> _pickDate({required bool start}) async {
    final initial = start ? _startDate : _deadlineDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;

    setState(() {
      if (start) {
        _startDate = picked;
        if (_deadlineDate.isBefore(_startDate)) {
          _deadlineDate = _startDate;
        }
      } else {
        _deadlineDate = picked;
      }
    });
  }

  String _formatDate(DateTime date) => DateFormat('d MMM yyyy').format(date);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final staffId = context.read<AuthService>().appUser?.uid;
    if (staffId == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final firestore = context.read<FirestoreService>();
      if (widget.isEditing) {
        await firestore.updateClassTerm(
          termId: widget.termId!,
          startDate: _startDate,
          deadlineDate: _deadlineDate,
          sessionsRemaining: _sessionsRemaining,
          notes: _notesController.text,
        );
      } else {
        await firestore.createClassTermPackage(
          studentId: _studentId!,
          packageSize: _packageSize,
          createdByTeacherId: staffId,
          startDate: _startDate,
          deadlineDate: _deadlineDate,
          notes: _notesController.text,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing ? 'Voucher updated' : 'Voucher created',
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShellNestedPage(
      embedded: widget.embedded,
      title: widget.isEditing ? 'Edit voucher' : 'New voucher',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : widget.isEditing && _term == null
              ? Center(
                  child: Text(
                    _error ?? 'Voucher not found',
                    style: const TextStyle(color: AppColors.error),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (widget.isEditing && _term?.voucherCode != null) ...[
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Voucher code',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SelectableText(
                              _term!.voucherCode!,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navy,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (!widget.isEditing)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          'A unique code is generated automatically '
                          '(e.g. 2026_07_001).',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    if (_error != null) ...[
                      Text(_error!, style: const TextStyle(color: AppColors.error)),
                      const SizedBox(height: 12),
                    ],
                    AppCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (widget.isEditing)
                              _ReadOnlyField(
                                label: 'Student',
                                value: _studentName,
                              )
                            else
                              StreamBuilder<List<AppUser>>(
                                stream: context
                                    .read<FirestoreService>()
                                    .watchAllStudents(),
                                builder: (context, snapshot) {
                                  final students = snapshot.data ?? [];
                                  return DropdownButtonFormField<String>(
                                    initialValue: _studentId,
                                    decoration: const InputDecoration(
                                      labelText: 'Student',
                                      prefixIcon: Icon(Icons.person_outline),
                                    ),
                                    items: students
                                        .map(
                                          (student) => DropdownMenuItem(
                                            value: student.uid,
                                            child: Text(
                                              '${student.name} · ${student.level ?? 'No HSK'}',
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: _saving
                                        ? null
                                        : (value) =>
                                            setState(() => _studentId = value),
                                    validator: (value) => value == null
                                        ? 'Select a student'
                                        : null,
                                  );
                                },
                              ),
                            const SizedBox(height: 16),
                            if (widget.isEditing)
                              _ReadOnlyField(
                                label: 'Package size',
                                value: '$_packageSize sessions',
                              )
                            else
                              DropdownButtonFormField<int>(
                                initialValue: _packageSize,
                                decoration: const InputDecoration(
                                  labelText: 'Package size',
                                  prefixIcon:
                                      Icon(Icons.confirmation_number_outlined),
                                ),
                                items: AppConstants.termSizes
                                    .map(
                                      (size) => DropdownMenuItem(
                                        value: size,
                                        child: Text('$size sessions'),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _saving
                                    ? null
                                    : (value) => setState(() {
                                          _packageSize =
                                              value ?? _packageSize;
                                          _sessionsRemaining = _packageSize;
                                        }),
                              ),
                            if (widget.isEditing) ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                initialValue: '$_sessionsRemaining',
                                enabled: !_saving,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Sessions remaining',
                                  prefixIcon: const Icon(Icons.event_available_outlined),
                                  helperText:
                                      'Of $_packageSize total in this package',
                                ),
                                validator: (value) {
                                  final n = int.tryParse(value ?? '');
                                  if (n == null) return 'Enter a number';
                                  if (n < 0 || n > _packageSize) {
                                    return 'Must be between 0 and $_packageSize';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  _sessionsRemaining =
                                      int.tryParse(value?.trim() ?? '') ?? 0;
                                },
                              ),
                            ],
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed:
                                  _saving ? null : () => _pickDate(start: true),
                              icon: const Icon(Icons.calendar_today_outlined, size: 18),
                              label: Text('Start: ${_formatDate(_startDate)}'),
                              style: OutlinedButton.styleFrom(
                                alignment: Alignment.centerLeft,
                                minimumSize: const Size.fromHeight(44),
                              ),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: _saving
                                  ? null
                                  : () => _pickDate(start: false),
                              icon: const Icon(Icons.event_outlined, size: 18),
                              label:
                                  Text('Deadline: ${_formatDate(_deadlineDate)}'),
                              style: OutlinedButton.styleFrom(
                                alignment: Alignment.centerLeft,
                                minimumSize: const Size.fromHeight(44),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _notesController,
                              enabled: !_saving,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Notes (optional)',
                                prefixIcon: Icon(Icons.notes_outlined),
                                alignLabelWithHint: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _saving
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                _formKey.currentState!.save();
                                _save();
                              }
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(widget.isEditing ? 'Save changes' : 'Create voucher'),
                    ),
                  ],
                ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline, size: 18),
      ),
      child: Text(value),
    );
  }
}
