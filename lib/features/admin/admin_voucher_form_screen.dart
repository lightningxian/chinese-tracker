import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/shell_nested_page.dart';
import '../../core/utils/money_format.dart';
import '../../l10n/l10n.dart';
import '../../l10n/labels_admin.dart';
import '../../models/app_user.dart';
import '../../models/invoice.dart';
import '../../models/pricing_settings.dart';
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

  /// The payment this voucher belongs to. Required for new vouchers: a
  /// voucher is always backed by a paid or pending invoice.
  Invoice? _invoice;
  PricingSettings _pricing = PricingSettings.defaults;
  StreamSubscription<PricingSettings>? _pricingSub;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = now;
    _deadlineDate = now.add(const Duration(days: 60));
    _pricingSub = context.read<FirestoreService>().watchPricing().listen((p) {
      if (!mounted) return;
      setState(() {
        _pricing = p;
        if (!widget.isEditing && _invoice == null) {
          _deadlineDate = _startDate.add(Duration(days: p.termValidDays));
        }
      });
    });
    _load();
  }

  @override
  void dispose() {
    _pricingSub?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  void _selectInvoice(Invoice? invoice) {
    setState(() {
      _invoice = invoice;
      if (invoice != null && invoice.sessions > 0) {
        _packageSize = invoice.sessions;
        _sessionsRemaining = invoice.sessions;
      }
    });
  }

  /// Record a cash / transfer payment now and use it for this voucher.
  Future<void> _recordNewPayment(AppUser student) async {
    final l = context.l10n;
    final items = _pricing.sessionItems;
    if (items.isEmpty) {
      setState(() => _error = l.adminVoucherFormAddPriceItem);
      return;
    }
    final item = await showDialog<PriceItem>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.adminVoucherFormRecordPaymentFor),
        children: [
          for (final it in items)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, it),
              child: Text('${it.name} · ${formatRupiah(it.price)}'),
            ),
        ],
      ),
    );
    if (item == null || !mounted) return;
    final staffId = context.read<AuthService>().appUser?.uid;
    if (staffId == null) return;
    try {
      final firestore = context.read<FirestoreService>();
      final id = await firestore.createManualInvoice(
        student: student,
        item: item,
        createdBy: staffId,
        dueDate: DateTime.now().add(const Duration(days: 7)),
      );
      final created = await firestore.watchStudentInvoices(student.uid).first;
      Invoice? match;
      for (final inv in created) {
        if (inv.id == id) match = inv;
      }
      if (!mounted) return;
      _selectInvoice(match);
    } catch (e) {
      if (mounted) {
        setState(() => _error = l.adminVoucherFormRecordFailed('$e'));
      }
    }
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
    final l = context.l10n;

    if (term == null) {
      setState(() {
        _loading = false;
        _error = l.adminVoucherFormNotFound;
      });
      return;
    }

    _notesController.text = term.notes ?? '';
    setState(() {
      _term = term;
      _studentId = term.studentId;
      _studentName = student?.name ?? l.adminVouchersUnknownStudent;
      _packageSize = term.packageSize;
      _sessionsRemaining = term.sessionsRemaining;
      _startDate = DateTime.tryParse(term.startDate) ?? DateTime.now();
      _deadlineDate = DateTime.tryParse(term.deadlineDate) ??
          _startDate.add(const Duration(days: 90));
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
    final l = context.l10n;

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
        final invoice = _invoice;
        if (invoice == null) {
          setState(() {
            _error = l.adminVoucherFormChoosePayment;
            _saving = false;
          });
          return;
        }
        await firestore.createClassTermPackage(
          studentId: _studentId!,
          packageSize: _packageSize,
          createdByTeacherId: staffId,
          startDate: _startDate,
          deadlineDate: _deadlineDate,
          notes: _notesController.text,
          sourceInvoiceId: invoice.id,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing
                  ? l.adminVoucherFormUpdated
                  : l.adminVoucherFormCreated,
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
    final l = context.l10n;
    return ShellNestedPage(
      embedded: widget.embedded,
      title: widget.isEditing ? l.adminVouchersEdit : l.adminVouchersNewVoucher,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : widget.isEditing && _term == null
              ? Center(
                  child: Text(
                    _error ?? l.adminVoucherFormNotFound,
                    style: TextStyle(color: AppColors.error),
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
                            Text(
                              l.adminVouchersVoucherCode,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SelectableText(
                              _term!.voucherCode!,
                              style: TextStyle(
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
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          l.adminVoucherFormIntro,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    if (_error != null) ...[
                      Text(_error!, style: TextStyle(color: AppColors.error)),
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
                                label: l.commonStudent,
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
                                    decoration: InputDecoration(
                                      labelText: l.commonStudent,
                                      prefixIcon:
                                          const Icon(Icons.person_outline),
                                    ),
                                    items: students
                                        .map(
                                          (student) => DropdownMenuItem(
                                            value: student.uid,
                                            child: Text(
                                              '${student.name} · ${student.level ?? l.adminVoucherFormNoHsk}',
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: _saving
                                        ? null
                                        : (value) =>
                                            setState(() => _studentId = value),
                                    validator: (value) => value == null
                                        ? l.adminVoucherFormSelectStudent
                                        : null,
                                  );
                                },
                              ),
                            const SizedBox(height: 16),
                            if (widget.isEditing)
                              _PaymentStatusField(term: _term!)
                            else if (_studentId != null)
                              _PaymentPicker(
                                studentId: _studentId!,
                                selected: _invoice,
                                onChanged: _saving ? null : _selectInvoice,
                                onRecordNew: _saving
                                    ? null
                                    : (student) => _recordNewPayment(student),
                              ),
                            const SizedBox(height: 16),
                            if (widget.isEditing)
                              _ReadOnlyField(
                                label: l.adminVoucherFormPackageSize,
                                value: l.termSessionsCount(_packageSize),
                              )
                            else if (_invoice != null && _invoice!.sessions > 0)
                              _ReadOnlyField(
                                label: l.adminVoucherFormPackageSizeFromPayment,
                                value: l.termSessionsCount(_packageSize),
                              )
                            else
                              DropdownButtonFormField<int>(
                                initialValue: _packageSize,
                                decoration: InputDecoration(
                                  labelText: l.adminVoucherFormPackageSize,
                                  prefixIcon: const Icon(
                                      Icons.confirmation_number_outlined),
                                ),
                                items: AppConstants.termSizes
                                    .map(
                                      (size) => DropdownMenuItem(
                                        value: size,
                                        child: Text(l.termSessionsCount(size)),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _saving
                                    ? null
                                    : (value) => setState(() {
                                          _packageSize = value ?? _packageSize;
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
                                  labelText: l.termSessionsRemaining,
                                  prefixIcon: const Icon(
                                      Icons.event_available_outlined),
                                  helperText:
                                      l.adminVoucherFormOfTotal(_packageSize),
                                ),
                                validator: (value) {
                                  final n = int.tryParse(value ?? '');
                                  if (n == null) {
                                    return l.adminVoucherFormEnterNumber;
                                  }
                                  if (n < 0 || n > _packageSize) {
                                    return l
                                        .adminVoucherFormRange(_packageSize);
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
                              icon: const Icon(Icons.calendar_today_outlined,
                                  size: 18),
                              label: Text(
                                l.adminVoucherFormStart(
                                    _formatDate(_startDate)),
                              ),
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
                              label: Text(
                                l.adminVoucherFormDeadline(
                                  _formatDate(_deadlineDate),
                                ),
                              ),
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
                              decoration: InputDecoration(
                                labelText: l.adminVoucherFormNotesOptional,
                                prefixIcon: const Icon(Icons.notes_outlined),
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
                          : Text(widget.isEditing
                              ? l.profileWidgetSaveChanges
                              : l.adminVoucherFormCreate),
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

/// Create mode: the student's session invoices that no voucher uses yet.
class _PaymentPicker extends StatelessWidget {
  const _PaymentPicker({
    required this.studentId,
    required this.selected,
    required this.onChanged,
    required this.onRecordNew,
  });

  final String studentId;
  final Invoice? selected;
  final ValueChanged<Invoice?>? onChanged;
  final ValueChanged<AppUser>? onRecordNew;

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final l = context.l10n;
    return StreamBuilder<List<Invoice>>(
      stream: firestore.watchStudentInvoices(studentId),
      builder: (context, invSnap) {
        return StreamBuilder<List<StudentClassTerm>>(
          stream: firestore.watchStudentClassTerms(studentId),
          builder: (context, termSnap) {
            final used = {
              for (final t in termSnap.data ?? const <StudentClassTerm>[])
                if (t.sourceInvoiceId != null) t.sourceInvoiceId!,
            };
            final candidates = (invSnap.data ?? const <Invoice>[])
                .where((i) =>
                    i.creditsSessions &&
                    (i.isPending || i.isPaid) &&
                    i.classTermId == null &&
                    !used.contains(i.id))
                .toList();
            final selectedId = candidates.any((i) => i.id == selected?.id)
                ? selected!.id
                : null;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  key: ValueKey('payment-$selectedId-${candidates.length}'),
                  initialValue: selectedId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l.adminVouchersColPayment,
                    prefixIcon: const Icon(Icons.receipt_long_outlined),
                    helperText: l.adminVoucherFormPaymentHelper,
                  ),
                  items: [
                    for (final inv in candidates)
                      DropdownMenuItem(
                        value: inv.id,
                        child: Text(
                          '${inv.itemLocalized(l)} · ${formatRupiah(inv.amount)} · '
                          '${inv.isPaid ? l.adminInvoicesStatusPaid : l.adminInvoicesStatusPending} · '
                          '${inv.invoiceNumber}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: onChanged == null
                      ? null
                      : (id) {
                          Invoice? match;
                          for (final inv in candidates) {
                            if (inv.id == id) match = inv;
                          }
                          onChanged!(match);
                        },
                  validator: (v) =>
                      v == null ? l.adminVoucherFormChoosePaymentShort : null,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FutureBuilder<AppUser?>(
                    future: firestore.getUser(studentId),
                    builder: (context, userSnap) => TextButton.icon(
                      onPressed: onRecordNew == null || userSnap.data == null
                          ? null
                          : () => onRecordNew!(userSnap.data!),
                      icon: const Icon(Icons.add_card_outlined, size: 18),
                      label: Text(l.adminVoucherFormRecordPayment),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Edit mode: which payment this voucher has, and whether it is settled.
class _PaymentStatusField extends StatelessWidget {
  const _PaymentStatusField({required this.term});

  final StudentClassTerm term;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (!term.hasPayment) {
      return _ReadOnlyField(
        label: l.adminVouchersColPayment,
        value: l.adminVoucherFormNoPaymentOlder,
      );
    }
    return StreamBuilder<List<Invoice>>(
      stream:
          context.read<FirestoreService>().watchStudentInvoices(term.studentId),
      builder: (context, snap) {
        Invoice? inv;
        for (final i in snap.data ?? const <Invoice>[]) {
          if (i.id == term.sourceInvoiceId) inv = i;
        }
        final value = inv == null
            ? l.adminInvoicesCardInvoice('${term.sourceInvoiceId}')
            : '${inv.invoiceNumber} · ${formatRupiah(inv.amount)} · '
                '${inv.status.localized(l)}'
                '${inv.paidAt != null ? ' ${DateFormat('d MMM yyyy').format(inv.paidAt!)}' : ''}';
        return _ReadOnlyField(label: l.adminVouchersColPayment, value: value);
      },
    );
  }
}
