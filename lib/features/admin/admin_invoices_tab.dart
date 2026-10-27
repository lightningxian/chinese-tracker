import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
import '../../services/auth_service.dart';
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
              OutlinedButton.icon(
                onPressed: () => context.push('/admin/price-list'),
                icon: const Icon(Icons.sell_outlined, size: 18),
                label: const Text('Price list'),
              ),
              const SizedBox(width: 8),
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
                    mobileCardBuilder: (invoice) => InvoiceCard(
                      invoice: invoice,
                      onRecordPayment: invoice.isPending
                          ? () => _recordPayment(context, invoice)
                          : null,
                    ),
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
        label: 'Item',
        sortable: true,
        width: 150,
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
        id: 'method',
        label: 'Method',
        width: 100,
        cell: (invoice) => Text(
          invoice.methodLabel,
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
          label: invoice.isOverdue ? 'Overdue' : invoice.status.label,
          color: switch (invoice.status) {
            InvoiceStatus.paid => AppColors.success,
            InvoiceStatus.pending =>
              invoice.isOverdue ? AppColors.error : AppColors.brandYellow,
            InvoiceStatus.failed => AppColors.error,
            InvoiceStatus.expired => AppColors.textSecondary,
          },
        ),
      ),
      AppTableColumn<Invoice>(
        id: 'actions',
        label: '',
        width: 56,
        alignment: Alignment.centerRight,
        cell: (invoice) => invoice.isPending
            ? PopupMenuButton<String>(
                tooltip: 'Actions',
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (action) {
                  switch (action) {
                    case 'paid':
                      _recordPayment(context, invoice);
                    case 'delete':
                      _deleteInvoice(context, invoice);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'paid',
                    child: Text('Mark as paid (cash / transfer)'),
                  ),
                  if (!invoice.isOnline)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete pending invoice'),
                    ),
                ],
              )
            : const SizedBox.shrink(),
      ),
    ];
  }

  /// Admin records money received by hand. The server flips the invoice to
  /// paid and credits the sessions or marks the linked voucher paid.
  Future<void> _recordPayment(BuildContext context, Invoice invoice) async {
    final result = await showDialog<({String method, String note})>(
      context: context,
      builder: (_) => _RecordPaymentDialog(invoice: invoice),
    );
    if (result == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<PaymentService>().markInvoicePaid(
            invoiceId: invoice.id,
            method: result.method,
            note: result.note,
          );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Recorded: ${invoice.studentName ?? 'student'} paid '
            '${invoice.itemLabel} by ${result.method}.',
          ),
        ),
      );
    } on PaymentException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _deleteInvoice(BuildContext context, Invoice invoice) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this pending invoice?'),
        content: Text(
          '${invoice.invoiceNumber} · ${invoice.itemLabel} for '
          '${invoice.studentName ?? invoice.studentId}. A voucher linked to it '
          'will show "No payment" again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await context.read<FirestoreService>().deleteInvoice(invoice.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete: $e')),
      );
    }
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
  const InvoiceCard({
    super.key,
    required this.invoice,
    this.onPay,
    this.onRecordPayment,
  });

  final Invoice invoice;

  /// Student side: open the online payment page (only when a link exists).
  final VoidCallback? onPay;

  /// Admin side: record a cash / transfer payment.
  final VoidCallback? onRecordPayment;

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
            '${invoice.dueDate.isNotEmpty ? ' · due ${invoice.dueDate}' : ''}'
            ' · ${invoice.methodLabel}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          if (onPay != null && invoice.isPayable && invoice.isOnline) ...[
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
          ] else if (onPay != null && invoice.isPayable) ...[
            const SizedBox(height: 10),
            const Text(
              'Pay at the centre by cash or bank transfer. The admin marks it '
              'paid and your sessions are added.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
            ),
          ],
          if (onRecordPayment != null && invoice.isPending) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRecordPayment,
                icon: const Icon(Icons.price_check, size: 18),
                label: const Text('Mark as paid'),
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
  PricingSettings _pricing = PricingSettings.defaults;
  PriceItem? _item;
  StreamSubscription<PricingSettings>? _pricingSub;

  /// false = paid at the centre (cash / transfer, admin marks it paid later);
  /// true = online payment link (Midtrans).
  bool _online = false;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pricingSub = context.read<FirestoreService>().watchPricing().listen((p) {
      if (!mounted) return;
      setState(() {
        _pricing = p;
        _item = p.itemById(_item?.id) ??
            (p.items.isNotEmpty ? p.sessionItems.firstOrNull ?? p.items.first : null);
      });
    });
  }

  @override
  void dispose() {
    _pricingSub?.cancel();
    super.dispose();
  }

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
            DropdownButtonFormField<String>(
              initialValue: _item?.id,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Item (from the Price list)',
                prefixIcon: Icon(Icons.sell_outlined),
              ),
              items: [
                for (final it in _pricing.items)
                  DropdownMenuItem(
                    value: it.id,
                    child: Text('${it.name} · ${currency.format(it.price)}'),
                  ),
              ],
              onChanged: (id) => setState(() => _item = _pricing.itemById(id)),
            ),
            if (_item != null) ...[
              const SizedBox(height: 6),
              Text(
                'Gives ${_item!.givesLabel}. '
                '${_item!.creditsSessions ? 'A voucher is opened when this is paid.' : ''}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                ),
              ),
            ],
            const SizedBox(height: 16),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.storefront_outlined, size: 18),
                  label: Text('Cash / transfer'),
                ),
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.link, size: 18),
                  label: Text('Online link'),
                ),
              ],
              selected: {_online},
              onSelectionChanged: (v) => setState(() => _online = v.first),
            ),
            const SizedBox(height: 6),
            Text(
              _online
                  ? 'The student gets a Midtrans payment link; the sessions '
                      'are added automatically when they pay.'
                  : 'Recorded as pending. When the money arrives, open the '
                      'invoice menu and choose Mark as paid.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
              ),
            ),
            if (_online && !AppConstants.hasMidtransClientKey) ...[
              const SizedBox(height: 8),
              const _InfoBanner(
                text: 'Online payments need Midtrans keys and the Cloud '
                    'Functions deployed.',
              ),
            ],
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
                  : Text(
                      _item == null
                          ? 'Create invoice'
                          : 'Create invoice · ${currency.format(_item!.price)}',
                    ),
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
    final student = _student;
    final item = _item;
    if (student == null) {
      setState(() => _error = 'Choose a student.');
      return;
    }
    if (item == null) {
      setState(() => _error = 'Choose an item from the Price list.');
      return;
    }
    final uid = context.read<AuthService>().appUser?.uid;
    if (uid == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_online) {
        await context.read<PaymentService>().createInvoice(
              studentId: student.uid,
              priceItemId: item.id,
              dueDate: DateFormat('yyyy-MM-dd').format(_dueDate),
            );
      } else {
        await context.read<FirestoreService>().createManualInvoice(
              student: student,
              item: item,
              createdBy: uid,
              dueDate: _dueDate,
            );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Invoice created for ${student.displayNameIndonesian}'
            '${_online ? '' : ' · pending until you mark it paid'}',
          ),
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

/// "Mark as paid": how the money came in, plus an optional note.
class _RecordPaymentDialog extends StatefulWidget {
  const _RecordPaymentDialog({required this.invoice});

  final Invoice invoice;

  @override
  State<_RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends State<_RecordPaymentDialog> {
  String _method = 'cash';
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.invoice;
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return AlertDialog(
      title: const Text('Mark as paid'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${inv.studentName ?? inv.studentId} · ${inv.itemLabel} · '
              '${currency.format(inv.amount)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'cash', label: Text('Cash')),
                ButtonSegment(value: 'transfer', label: Text('Bank transfer')),
              ],
              selected: {_method},
              onSelectionChanged: (v) => setState(() => _method = v.first),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _note,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'e.g. BCA transfer 27 Oct',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              inv.creditsSessions
                  ? (inv.classTermId != null
                      ? 'The linked voucher is marked paid.'
                      : 'A ${inv.sessions}-session voucher is opened for the student.')
                  : 'No sessions are added for this item.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            (method: _method, note: _note.text.trim()),
          ),
          child: const Text('Confirm payment'),
        ),
      ],
    );
  }
}
