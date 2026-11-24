import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_data_table.dart';
import '../../core/widgets/table_tools.dart';
import '../../core/utils/money_format.dart';
import '../../core/widgets/status_pill.dart';
import '../../l10n/l10n.dart';
import '../../l10n/labels_admin.dart';
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

  /// Live student profiles, so rows show the staff label (PLAN.md §3).
  late final Stream<List<AppUser>> _students =
      context.read<FirestoreService>().watchAllStudents();
  Map<String, AppUser> _studentsById = const {};

  /// `中文名 (Latin name)` from the profile, else the name on the invoice.
  String? _studentLabel(Invoice inv) {
    final student = _studentsById[inv.studentId];
    if (student != null) return student.staffLabel;
    final stored = inv.studentName ?? '';
    return stored.isEmpty ? null : stored;
  }
  bool _sortAscending = true;

  // Build 5: filters and the total of the filtered rows (screenshot 15).
  InvoiceStatus? _statusFilter;

  /// Owner 2026-11-24: show the Discarded invoices instead of the table.
  bool _showDiscarded = false;
  String? _itemFilter;
  String? _monthFilter;

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
        'student' => (_studentLabel(a) ?? '')
            .toLowerCase()
            .compareTo((_studentLabel(b) ?? '').toLowerCase()),
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

  /// Rows the table shows now, for the CSV export in the header.
  List<Invoice> _visible = const [];

  static List<String> _csvHeader(AppLocalizations l) => [
        l.adminInvoicesColInvoice,
        l.commonStudent,
        l.adminInvoicesColItem,
        l.adminInvoicesColAmount,
        l.profileWidgetStatus,
        l.adminInvoicesColMethod,
        l.adminInvoicesColDue,
        l.adminInvoicesColPaidOn,
        l.adminInvoicesColCreated,
      ];

  static List<Object?> _csvRow(AppLocalizations l, Invoice inv) => [
        inv.invoiceNumber,
        inv.studentName ?? inv.studentId,
        inv.itemLocalized(l),
        inv.amount,
        inv.status.localized(l),
        inv.methodLocalized(l),
        inv.dueDate,
        inv.paidAt == null ? '' : DateFormat('yyyy-MM-dd').format(inv.paidAt!),
        inv.createdAt == null
            ? ''
            : DateFormat('yyyy-MM-dd').format(inv.createdAt!),
      ];

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final l = context.l10n;

    return StreamBuilder<OrgSettings>(
      stream: firestore.watchOrgSettings(),
      builder: (context, settingsSnap) {
        final paymentsOn =
            (settingsSnap.data ?? OrgSettings.defaults).enablePayments;
        if (!paymentsOn) {
          return EmptyState(
            icon: Icons.money_off_outlined,
            title: l.studentPaymentsDisabledTitle,
            subtitle: l.adminInvoicesDisabledSubtitle,
          );
        }
        return _buildContent(context, firestore);
      },
    );
  }

  Widget _buildContent(BuildContext context, FirestoreService firestore) {
    final l = context.l10n;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l.studentPaymentsInvoices,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
              ),
              ExportCsvButton(
                fileStem: 'invoices',
                header: _csvHeader(l),
                rows: () => _visible.map((inv) => _csvRow(l, inv)).toList(),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => context.push('/admin/price-list'),
                icon: const Icon(Icons.sell_outlined, size: 18),
                label: Text(l.adminInvoicesPriceList),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => _openCreateInvoice(context),
                style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l.adminInvoicesCreate),
              ),
            ],
          ),
        ),
        if (!AppConstants.hasMidtransClientKey)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: _InfoBanner(text: l.adminInvoicesCodeOnlyBanner),
          ),
        Expanded(
          child: StreamBuilder<List<AppUser>>(
            stream: _students,
            builder: (context, studentsSnap) {
              _studentsById = {
                for (final s in studentsSnap.data ?? const <AppUser>[])
                  s.uid: s,
              };
              return StreamBuilder<List<Invoice>>(
                stream: firestore.watchAllInvoices(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final everything = snap.data ?? [];
                  final discarded = everything.where((i) => i.isDiscarded).toList()
                    ..sort((a, b) => (b.discardedAt ?? DateTime(0))
                        .compareTo(a.discardedAt ?? DateTime(0)));
                  final invoices = everything.where((i) => !i.isDiscarded).toList();
                  if (everything.isEmpty) {
                    return EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: l.adminInvoicesEmptyTitle,
                      subtitle: l.adminInvoicesEmptySubtitle,
                    );
                  }
                  _visible = _sorted(filterInvoices(
                    invoices,
                    status: _statusFilter,
                    priceItemId: _itemFilter,
                    month: _monthFilter,
                  ));
                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Row(
                        children: [
                          ChoiceChip(
                            label: Text(l.invoiceActiveList(invoices.length)),
                            selected: !_showDiscarded,
                            onSelected: (_) => setState(() => _showDiscarded = false),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            avatar: const Icon(Icons.delete_sweep_outlined, size: 18),
                            label: Text(l.invoiceDiscardedList(discarded.length)),
                            selected: _showDiscarded,
                            onSelected: (_) => setState(() => _showDiscarded = true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_showDiscarded)
                        _discardedList(context, l, discarded)
                      else ...[
                      _filters(l, invoices),
                      const SizedBox(height: 12),
                      AppDataTable<Invoice>(
                        rows: _visible,
                        columns: _buildColumns(l),
                        sortColumnId: _sortColumnId,
                        sortAscending: _sortAscending,
                        onSort: _onSort,
                        mobileCardBuilder: (invoice) => InvoiceCard(
                          invoice: invoice,
                          studentLabel: _studentLabel(invoice),
                          onRecordPayment: invoice.isPending
                              ? () => _recordPayment(context, invoice)
                              : null,
                        ),
                      ),
                      ],
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _filters(AppLocalizations l, List<Invoice> all) {
    final items = <String, String>{};
    for (final i in all) {
      final id = i.priceItemId;
      if (id == null || id.isEmpty) continue;
      items[id] = i.nameChinese.isNotEmpty ? i.nameChinese : i.itemLocalized(l);
    }
    final months = {
      for (final i in all)
        if (i.createdAt != null)
          '${i.createdAt!.year}-${i.createdAt!.month.toString().padLeft(2, '0')}',
    }.toList()
      ..sort((a, b) => b.compareTo(a));
    Widget drop<T>(String label, T? value, Map<T, String> options,
            ValueChanged<T?> onChanged) =>
        SizedBox(
          width: 200,
          child: DropdownButtonFormField<T?>(
            initialValue: value,
            isExpanded: true,
            decoration: InputDecoration(labelText: label, isDense: true),
            items: [
              DropdownMenuItem<T?>(value: null, child: Text(l.progressFilterAll)),
              for (final e in options.entries)
                DropdownMenuItem<T?>(value: e.key, child: Text(e.value)),
            ],
            onChanged: onChanged,
          ),
        );
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        drop<InvoiceStatus>(
          l.profileWidgetStatus,
          _statusFilter,
          {
            for (final s in InvoiceStatus.values)
              if (s != InvoiceStatus.discarded) s: s.localized(l)
          },
          (v) => setState(() => _statusFilter = v),
        ),
        drop<String>(l.adminInvoicesColItem, _itemFilter, items,
            (v) => setState(() => _itemFilter = v)),
        drop<String>(l.invoicesFilterMonth, _monthFilter,
            {for (final m in months) m: m},
            (v) => setState(() => _monthFilter = v)),
        Text(
          l.invoicesFilteredTotal(_visible.length, formatRupiah(invoiceTotal(_visible))),
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy),
        ),
      ],
    );
  }

  List<AppTableColumn<Invoice>> _buildColumns(AppLocalizations l) {
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final cellStyle = TextStyle(fontSize: 13, color: AppColors.textPrimary);
    final metaStyle = TextStyle(fontSize: 12, color: AppColors.textSecondary);

    return [
      AppTableColumn<Invoice>(
        id: 'invoice',
        label: l.adminInvoicesColInvoiceNumber,
        sortable: true,
        flex: 2,
        cell: (invoice) => Text(
          invoice.invoiceNumber,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
          ),
        ),
      ),
      AppTableColumn<Invoice>(
        id: 'student',
        label: l.commonStudent,
        sortable: true,
        flex: 2,
        cell: (invoice) => Text(
          _studentLabel(invoice) ?? '—',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: cellStyle,
        ),
      ),
      AppTableColumn<Invoice>(
        id: 'package',
        label: l.adminInvoicesColItem,
        sortable: true,
        width: 150,
        cell: (invoice) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              invoice.nameChinese.isNotEmpty
                  ? invoice.nameChinese
                  : invoice.itemLocalized(l),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: metaStyle,
            ),
            // Build 5: bought in the app by the student or the parent.
            if (invoice.selfPurchase)
              Text(
                l.invoicesBoughtInApp,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.teal),
              ),
          ],
        ),
      ),
      AppTableColumn<Invoice>(
        id: 'amount',
        label: l.adminInvoicesColAmount,
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
        label: l.adminInvoicesColDue,
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
        label: l.adminInvoicesColMethod,
        width: 100,
        cell: (invoice) => Text(
          invoice.methodLocalized(l),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: metaStyle,
        ),
      ),
      AppTableColumn<Invoice>(
        id: 'status',
        label: l.profileWidgetStatus,
        sortable: true,
        width: 96,
        cell: (invoice) => StatusPill(
          label: invoice.isOverdue
              ? l.adminInvoicesOverdue
              : invoice.status.localized(l),
          color: switch (invoice.status) {
            InvoiceStatus.paid => AppColors.success,
            InvoiceStatus.pending =>
              invoice.isOverdue ? AppColors.error : AppColors.brandYellow,
            InvoiceStatus.failed => AppColors.error,
            InvoiceStatus.expired => AppColors.textSecondary,
            InvoiceStatus.discarded => AppColors.textSecondary,
          },
        ),
      ),
      AppTableColumn<Invoice>(
        id: 'actions',
        label: '',
        width: 56,
        alignment: Alignment.centerRight,
        cell: (invoice) => !invoice.isPaid && !invoice.isDiscarded
            ? PopupMenuButton<String>(
                tooltip: l.adminUsersColActions,
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (action) {
                  switch (action) {
                    case 'paid':
                      _recordPayment(context, invoice);
                    case 'discard':
                      _discardInvoice(context, invoice);
                  }
                },
                itemBuilder: (_) => [
                  if (invoice.isPending)
                    PopupMenuItem(
                      value: 'paid',
                      child: Text(l.adminInvoicesMarkPaidMenu),
                    ),
                  // Owner 2026-11-24: remove with a reason (kept on the
                  // Discarded list) instead of deleting.
                  PopupMenuItem(
                    value: 'discard',
                    child: Text(l.invoiceDiscardMenu),
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
    final l = context.l10n;
    final result = await showDialog<({String method, String note})>(
      context: context,
      builder: (_) => _RecordPaymentDialog(
        invoice: invoice,
        studentLabel: _studentLabel(invoice),
      ),
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
            l.adminInvoicesRecorded(
              _studentLabel(invoice) ?? l.adminInvoicesStudentFallback,
              invoice.itemLocalized(l),
              localizedPaymentMethod(l, result.method).toLowerCase(),
            ),
          ),
        ),
      );
    } on PaymentException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    }
  }

  /// Owner 2026-11-24: discard with a reason (`discardInvoice`).
  Future<void> _discardInvoice(BuildContext context, Invoice invoice) async {
    final l = context.l10n;
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(l.invoiceDiscardTitle),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l.invoiceDiscardBody(
                  invoice.invoiceNumber,
                  _studentLabel(invoice) ?? invoice.studentId,
                  formatRupiah(invoice.amount),
                )),
                const SizedBox(height: 12),
                TextField(
                  controller: reason,
                  autofocus: true,
                  maxLength: 300,
                  maxLines: 3,
                  onChanged: (_) => setLocal(() {}),
                  decoration: InputDecoration(
                    labelText: l.invoiceDiscardReason,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.commonCancel)),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: reason.text.trim().isEmpty ? null : () => Navigator.pop(ctx, true),
              child: Text(l.invoiceDiscardConfirm),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<FirestoreService>().discardInvoice(invoice.id, reason: reason.text);
      messenger.showSnackBar(SnackBar(content: Text(l.invoiceDiscarded)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.adminInvoicesDeleteFailed('$e'))));
    }
  }

  Future<void> _restoreInvoice(BuildContext context, Invoice invoice) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<FirestoreService>().discardInvoice(invoice.id, restore: true);
      messenger.showSnackBar(SnackBar(content: Text(l.invoiceRestored)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.adminInvoicesDeleteFailed('$e'))));
    }
  }

  /// The Discarded invoices list: number, student, amount, reason, who.
  Widget _discardedList(BuildContext context, AppLocalizations l, List<Invoice> list) {
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(l.invoiceDiscardedNone,
            textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return Column(
      children: [
        for (final inv in list)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.delete_sweep_outlined, color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${inv.invoiceNumber} · ${_studentLabel(inv) ?? inv.studentId} · ${formatRupiah(inv.amount)}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(l.invoiceDiscardedWhy(inv.discardReason),
                            style: const TextStyle(height: 1.4)),
                        const SizedBox(height: 2),
                        Text(
                          [
                            inv.itemLocalized(l),
                            if (inv.discardedByName.isNotEmpty) inv.discardedByName,
                            if (inv.discardedAt != null)
                              DateFormat('d MMM yyyy HH:mm').format(inv.discardedAt!),
                          ].join(' · '),
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _restoreInvoice(context, inv),
                    child: Text(l.invoiceRestore),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
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
    this.studentLabel,
  });

  final Invoice invoice;

  /// Admin side: the staff label of the student (PLAN.md §3). The student
  /// and parent views leave it null and show the name on the invoice.
  final String? studentLabel;

  /// Student side: open the online payment page (only when a link exists).
  final VoidCallback? onPay;

  /// Admin side: record a cash / transfer payment.
  final VoidCallback? onRecordPayment;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
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
                  studentLabel ??
                      (invoice.studentName?.isNotEmpty == true
                          ? invoice.studentName!
                          : invoice.invoiceNumber),
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
            '${invoice.itemLocalized(l)} · ${currency.format(invoice.amount)}',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            '${l.adminInvoicesCardInvoice(invoice.invoiceNumber)}'
            '${invoice.dueDate.isNotEmpty ? ' · ${l.adminInvoicesCardDue(invoice.dueDate)}' : ''}'
            ' · ${invoice.methodLocalized(l)}',
            style: TextStyle(
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
                label: Text(l.adminInvoicesPayNow),
              ),
            ),
          ] else if (onPay != null && invoice.isPayable) ...[
            const SizedBox(height: 10),
            Text(
              l.adminInvoicesPayAtCentre,
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
                label: Text(l.adminInvoicesMarkPaid),
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
      InvoiceStatus.discarded => AppColors.textSecondary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.localized(context.l10n),
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
          Icon(Icons.info_outline, size: 18, color: AppColors.navy),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: AppColors.navy),
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
            (p.items.isNotEmpty
                ? p.sessionItems.firstOrNull ?? p.items.first
                : null);
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
    final l = context.l10n;
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
            Text(
              l.adminInvoicesCreate,
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
                child: Text(_error!, style: TextStyle(color: AppColors.error)),
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
                  decoration: InputDecoration(
                    labelText: l.commonStudent,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  items: [
                    for (final s in students)
                      DropdownMenuItem(
                        value: s,
                        child: Text(s.staffLabel),
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
              decoration: InputDecoration(
                labelText: l.adminInvoicesItemFromPriceList,
                prefixIcon: const Icon(Icons.sell_outlined),
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
                '${l.adminInvoicesGives(_item!.givesLocalized(l))} '
                '${_item!.creditsSessions ? l.adminInvoicesVoucherOpened : ''}',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                ),
              ),
            ],
            const SizedBox(height: 16),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  icon: const Icon(Icons.storefront_outlined, size: 18),
                  label: Text(l.adminInvoicesCashTransfer),
                ),
                ButtonSegment(
                  value: true,
                  icon: const Icon(Icons.link, size: 18),
                  label: Text(l.adminInvoicesOnlineLink),
                ),
              ],
              selected: {_online},
              onSelectionChanged: (v) => setState(() => _online = v.first),
            ),
            const SizedBox(height: 6),
            Text(
              _online ? l.adminInvoicesOnlineHint : l.adminInvoicesManualHint,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
              ),
            ),
            if (_online && !AppConstants.hasMidtransClientKey) ...[
              const SizedBox(height: 8),
              _InfoBanner(text: l.adminInvoicesOnlineNeedsKeys),
            ],
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: Text(l.adminInvoicesDueDate),
              subtitle: Text(DateFormat('EEE, d MMM yyyy').format(_dueDate)),
              trailing: TextButton(
                onPressed: _pickDueDate,
                child: Text(l.adminInvoicesChange),
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
                          ? l.adminInvoicesCreate
                          : l.adminInvoicesCreateWithPrice(
                              currency.format(_item!.price),
                            ),
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
    final l = context.l10n;
    final student = _student;
    final item = _item;
    if (student == null) {
      setState(() => _error = l.adminInvoicesChooseStudent);
      return;
    }
    if (item == null) {
      setState(() => _error = l.adminInvoicesChooseItem);
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
            _online
                ? l.adminInvoicesCreatedOnline(student.staffLabel)
                : l.adminInvoicesCreatedManual(student.staffLabel),
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
  const _RecordPaymentDialog({required this.invoice, this.studentLabel});

  final Invoice invoice;
  final String? studentLabel;

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
    final l = context.l10n;
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return AlertDialog(
      title: Text(l.adminInvoicesMarkPaid),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.studentLabel ?? inv.studentName ?? inv.studentId} · '
              '${inv.itemLocalized(l)} · '
              '${currency.format(inv.amount)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'cash',
                  label: Text(l.adminInvoicesMethodCash),
                ),
                ButtonSegment(
                  value: 'transfer',
                  label: Text(l.adminInvoicesBankTransfer),
                ),
              ],
              selected: {_method},
              onSelectionChanged: (v) => setState(() => _method = v.first),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _note,
              decoration: InputDecoration(
                labelText: l.adminInvoicesNoteOptional,
                hintText: l.adminInvoicesNoteHint,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              inv.creditsSessions
                  ? (inv.classTermId != null
                      ? l.adminInvoicesLinkedVoucherPaid
                      : l.adminInvoicesVoucherOpenedFor(inv.sessions))
                  : l.adminInvoicesNoSessionsAdded,
              style: TextStyle(
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
          child: Text(l.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            (method: _method, note: _note.text.trim()),
          ),
          child: Text(l.adminInvoicesConfirmPayment),
        ),
      ],
    );
  }
}
