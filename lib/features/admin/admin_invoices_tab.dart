import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_data_table.dart';
import '../../core/widgets/status_pill.dart';
import '../../models/app_user.dart';
import '../../models/invoice.dart';
import '../../models/pricing_settings.dart';
import '../../models/org_settings.dart';
import '../../services/firestore_service.dart';
import '../../services/payment_service.dart';

/// Admin view of all invoices, with a "Create invoice" action.
class AdminInvoicesTab extends StatefulWidget {
  const AdminInvoicesTab({super.key});

  @override
  State<AdminInvoicesTab> createState() => _AdminInvoicesTabState();
}

class _AdminInvoicesTabState extends State<AdminInvoicesTab> {
  String? _sortColumnId;
  bool _sortAscending = true;

  void _onSort(String columnId) {
    setState(() {
      if (_sortColumnId == columnId) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumnId = columnId;
        _sortAscending = true;
      }
    });
  }

  List<Invoice> _sorted(List<Invoice> invoices) {
    final columnId = _sortColumnId;
    if (columnId == null) return invoices;

    final sorted = [...invoices];
    sorted.sort((a, b) {
      final compare = switch (columnId) {
        'invoice' => a.invoiceNumber.compareTo(b.invoiceNumber),
        'student' => (a.studentName ?? '')
            .toLowerCase()
            .compareTo((b.studentName ?? '').toLowerCase()),
        'package' => a.packageSize.compareTo(b.packageSize),
        'amount' => a.amount.compareTo(b.amount),
        'due' => a.dueDate.compareTo(b.dueDate),
        'status' => a.status.index.compareTo(b.status.index),
        _ => 0,
      };
      return _sortAscending ? compare : -compare;
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();

    return StreamBuilder<OrgSettings>(
      stream: firestore.watchOrgSettings(),
      builder: (context, settingsSnap) {
        final paymentsOn =
            (settingsSnap.data ?? OrgSettings.defaults).enablePayments;
        if (!paymentsOn) {
          return const EmptyState(
            icon: Icons.money_off_outlined,
            title: 'Payments are disabled',
            subtitle: 'Enable payments in Settings to create invoices and bill '
                'students for session packages.',
          );
        }
        return _buildContent(context, firestore);
      },
    );
  }

  Widget _buildContent(BuildContext context, FirestoreService firestore) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Invoices',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: () => _openCreateInvoice(context),
                style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Create invoice'),
              ),
            ],
          ),
        ),
        if (!AppConstants.hasMidtransClientKey)
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: _InfoBanner(
              text:
                  'Payments run in code-only mode: add Midtrans keys and deploy '
                  'Cloud Functions (Blaze) to enable live checkout.',
            ),
          ),
        Expanded(
          child: StreamBuilder<List<Invoice>>(
            stream: firestore.watchAllInvoices(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final invoices = snap.data ?? [];
              if (invoices.isEmpty) {
                return const EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No invoices yet',
                  subtitle:
                      'Tap "Create invoice" to bill a student for a session package or the HSK book.',
                );
              }
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  AppDataTable<Invoice>(
                    rows: _sorted(invoices),
                    columns: _buildColumns(),
                    sortColumnId: _sortColumnId,
                    sortAscending: _sortAscending,
                    onSort: _onSort,
                    mobileCardBuilder: (invoice) =>
                        InvoiceCard(invoice: invoice),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  List<AppTableColumn<Invoice>> _buildColumns() {
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    const cellStyle = TextStyle(fontSize: 13, color: AppColors.textPrimary);
    const metaStyle = TextStyle(fontSize: 12, color: AppColors.textSecondary);

    return [
      AppTableColumn<Invoice>(
        id: 'invoice',
        label: 'Invoice #',
        sortable: true,
        flex: 2,
        cell: (invoice) => Text(
          invoice.invoiceNumber,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
          ),
        ),
      ),
      AppTableColumn<Invoice>(
        id: 'student',
        label: 'Student',
        sortable: true,
        flex: 2,
        cell: (invoice) => Text(
          invoice.studentName?.isNotEmpty == true ? invoice.studentName! : '—',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: cellStyle,
        ),
      ),
      AppTableColumn<Invoice>(
        id: 'package',
        label: 'Package',
        sortable: true,
        width: 110,
        cell: (invoice) => Text(
          invoice.itemLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: metaStyle,
        ),
      ),
      AppTableColumn<Invoice>(
        id: 'amount',
        label: 'Amount',
        sortable: true,
        width: 130,
        cell: (invoice) => Text(
          currency.format(invoice.amount),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: cellStyle,
        ),
      ),
      AppTableColumn<Invoice>(
        id: 'due',
        label: 'Due',
        sortable: true,
        width: 110,
        cell: (invoice) => Text(
          invoice.dueDate.isEmpty ? '—' : invoice.dueDate,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: metaStyle,
        ),
      ),
      AppTableColumn<Invoice>(
        id: 'status',
        label: 'Status',
        sortable: true,
        width: 96,
        cell: (invoice) => StatusPill(
          label: invoice.status.label,
          color: switch (invoice.status) {
            InvoiceStatus.paid => AppColors.success,
            InvoiceStatus.pending => AppColors.brandYellow,
            InvoiceStatus.failed => AppColors.error,
            InvoiceStatus.expired => AppColors.textSecondary,
          },
        ),
      ),
    ];
  }

  Future<void> _openCreateInvoice(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _CreateInvoiceSheet(),
    );
  }
}

class InvoiceCard extends StatelessWidget {
  const InvoiceCard({super.key, required this.invoice, this.onPay});

  final Invoice invoice;
  final VoidCallback? onPay;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  invoice.studentName?.isNotEmpty == true
                      ? invoice.studentName!
                      : invoice.invoiceNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              _StatusChip(status: invoice.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${invoice.itemLabel} · ${currency.format(invoice.amount)}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            'Invoice ${invoice.invoiceNumber}'
            '${invoice.dueDate.isNotEmpty ? ' · due ${invoice.dueDate}' : ''}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          if (onPay != null && invoice.isPayable) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onPay,
                style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
                icon: const Icon(Icons.payment, size: 18),
                label: const Text('Pay now'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final InvoiceStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      InvoiceStatus.paid => AppColors.teal,
      InvoiceStatus.pending => AppColors.navy,
      InvoiceStatus.expired => AppColors.textSecondary,
      InvoiceStatus.failed => AppColors.error,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.navy),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: AppColors.navy),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateInvoiceSheet extends StatefulWidget {
  const _CreateInvoiceSheet();

  @override
  State<_CreateInvoiceSheet> createState() => _CreateInvoiceSheetState();
}

class _CreateInvoiceSheetState extends State<_CreateInvoiceSheet> {
  AppUser? _student;
  int _packageSize = AppConstants.termSizes.first;
  PricingSettings _pricing = PricingSettings.defaults;
  late int _amount = _pricing.priceForPackage(_packageSize);
  StreamSubscription<PricingSettings>? _pricingSub;

  @override
  void initState() {
    super.initState();
    _pricingSub = context.read<FirestoreService>().watchPricing().listen((p) {
      if (!mounted) return;
      setState(() {
        _pricing = p;
        _amount = _packageSize == 0 ? p.book : p.priceForPackage(_packageSize);
      });
    });
  }

  @override
  void dispose() {
    _pricingSub?.cancel();
    super.dispose();
  }

  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Create invoice',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!,
                    style: const TextStyle(color: AppColors.error)),
              ),
              const SizedBox(height: 12),
            ],
            StreamBuilder<List<AppUser>>(
              stream: firestore.watchAllStudents(),
              builder: (context, snap) {
                final students = snap.data ?? [];
                return DropdownButtonFormField<AppUser>(
                  initialValue: _student,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Student',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: [
                    for (final s in students)
                      DropdownMenuItem(
                        value: s,
                        child: Text(s.displayNameIndonesian),
                      ),
                  ],
                  onChanged: (v) => setState(() => _student = v),
                );
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _packageSize,
              decoration: const InputDecoration(
                labelText: 'Package',
                prefixIcon: Icon(Icons.card_membership_outlined),
              ),
              items: [
                for (final size in AppConstants.termSizes)
                  DropdownMenuItem(
                    value: size,
                    child: Text(
                      '$size sessions · '
                      '${currency.format(_pricing.priceForPackage(size))}',
                    ),
                  ),
                // 0 = book / materials item: no sessions are credited.
                DropdownMenuItem(
                  value: 0,
                  child: Text(
                    '${AppConstants.bookItemLabel} · '
                    '${currency.format(_pricing.book)}',
                  ),
                ),
              ],
              onChanged: (v) => setState(() {
                _packageSize = v ?? _packageSize;
                _amount = _packageSize == 0
                    ? _pricing.book
                    : _pricing.priceForPackage(_packageSize);
              }),
            ),
            const SizedBox(height: 16),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Amount (IDR)',
                prefixIcon: Icon(Icons.payments_outlined),
                helperText: 'Set by the item chosen (server-authoritative)',
              ),
              child: Text('Rp $_amount'),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: const Text('Due date'),
              subtitle: Text(DateFormat('EEE, d MMM yyyy').format(_dueDate)),
              trailing: TextButton(
                onPressed: _pickDueDate,
                child: const Text('Change'),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.navy,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create invoice'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _submit() async {
    if (_student == null) {
      setState(() => _error = 'Choose a student.');
      return;
    }
    if (_amount <= 0) {
      setState(() => _error = 'Enter a valid amount.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<PaymentService>().createInvoice(
            studentId: _student!.uid,
            packageSize: _packageSize,
            item: _packageSize == 0 ? AppConstants.bookItem : 'package',
            amount: _amount,
            dueDate: DateFormat('yyyy-MM-dd').format(_dueDate),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Invoice created for ${_student!.displayNameIndonesian}'),
        ),
      );
    } on PaymentException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
