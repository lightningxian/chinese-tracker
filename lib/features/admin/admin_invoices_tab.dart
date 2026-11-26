import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Query;
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/paging/date_range.dart';
import '../../core/paging/paged_controller.dart';
import '../../core/utils/csv_export.dart';
import '../../core/utils/file_download.dart' as file_download;
import '../../core/widgets/paging_bars.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_data_table.dart';
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
import '../../services/promotion_service.dart';

/// Admin view of all invoices, with a "Create invoice" action.
class AdminInvoicesTab extends StatefulWidget {
  const AdminInvoicesTab({super.key});

  @override
  State<AdminInvoicesTab> createState() => _AdminInvoicesTabState();
}

class _AdminInvoicesTabState extends State<AdminInvoicesTab> {
  String? _sortColumnId;

  /// Build 9A session 2: staff labels of the students on the page only
  /// (PLAN.md §3), not the whole student list.
  Map<String, String> _labels = const {};

  /// `中文名 (Latin name)` from the profile, else the name on the invoice.
  String? _studentLabel(Invoice inv) {
    final label = _labels[inv.studentId];
    if (label != null && label.isNotEmpty) return label;
    final stored = inv.studentName ?? '';
    return stored.isEmpty ? null : stored;
  }

  late final FirestoreService _firestore = context.read<FirestoreService>();

  /// Build 9A session 2: one page of invoices at a time, in a date range.
  late final PagedController<Invoice> _pages = PagedController<Invoice>(
    build: (range) => _firestore.invoiceSource(_query(range)),
  )..addListener(_onPage);

  Query<Map<String, dynamic>> _query(DateRangeSel range,
          {bool? discarded}) =>
      _firestore.invoiceQuery(range,
          discarded: discarded ?? _showDiscarded,
          status: (discarded ?? _showDiscarded) ? null : _statusFilter,
          priceItemId: (discarded ?? _showDiscarded) ? null : _itemFilter);

  ({int count, int amount})? _totals;
  int? _discardedCount;
  int _totalsGen = 0;

  Future<void> _loadTotals() async {
    final gen = ++_totalsGen;
    final range = _pages.range;
    try {
      final totals = await _firestore.invoiceTotals(_query(range, discarded: false));
      final gone = await _firestore.invoiceTotals(_query(range, discarded: true));
      if (!mounted || gen != _totalsGen) return;
      setState(() {
        _totals = totals;
        _discardedCount = gone.count;
      });
    } catch (e) {
      debugPrint('invoice totals: $e');
    }
  }

  Future<void> _onPage() async {
    final missing = _pages.items
        .map((i) => i.studentId)
        .where((id) => id.isNotEmpty && !_labels.containsKey(id))
        .toSet();
    if (missing.isEmpty) return;
    try {
      final found = await PromotionService().staffLabels(missing);
      if (!mounted) return;
      setState(() => _labels = {
            ..._labels,
            for (final id in missing) id: found[id] ?? '',
          });
    } catch (e) {
      debugPrint('invoice labels: $e');
    }
  }

  /// After a filter, the range or one of the page's own writes.
  void _reload() {
    _pages.reload();
    _loadTotals();
  }

  @override
  void initState() {
    super.initState();
    _loadTotals();
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }
  bool _sortAscending = true;

  // Build 5: filters and the total of the filtered rows (screenshot 15).
  InvoiceStatus? _statusFilter;

  /// Owner 2026-11-24: show the Discarded invoices instead of the table.
  bool _showDiscarded = false;
  String? _itemFilter;

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

  /// Rows the table shows now (this page, sorted by the chosen column).
  List<Invoice> _visible = const [];

  /// The CSV follows the date range and filters, not the visible page.
  Future<void> _exportCsv() async {
    final l = context.l10n;
    final rows = await fetchRowsForExport(context, _pages);
    if (rows == null || !mounted) return;
    await CsvExport.download(
      fileStem: 'invoices_${DateRangeSel.isoDay(DateRangeSel.jakartaToday())}',
      header: _csvHeader(l),
      rows: [for (final inv in rows) _csvRow(l, inv)],
    );
  }

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
              OutlinedButton.icon(
                onPressed: _exportCsv,
                icon: const Icon(Icons.download_outlined, size: 18),
                label: Text(l.pagingExportCsv),
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
          child: ListenableBuilder(
            listenable: _pages,
            builder: (context, _) {
              _visible = _sorted(_pages.items);
              return PagedListBody<Invoice>(
                controller: _pages,
                emptyIcon: Icons.receipt_long_outlined,
                emptyTitle: l.adminInvoicesEmptyTitle,
                header: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ChoiceChip(
                          label: Text(l.invoiceActiveList(_totals?.count ?? 0)),
                          selected: !_showDiscarded,
                          onSelected: (_) {
                            setState(() => _showDiscarded = false);
                            _pages.reload();
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          avatar: const Icon(Icons.delete_sweep_outlined, size: 18),
                          label: Text(l.invoiceDiscardedList(_discardedCount ?? 0)),
                          selected: _showDiscarded,
                          onSelected: (_) {
                            setState(() => _showDiscarded = true);
                            _pages.reload();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DateRangeBar(
                      value: _pages.range,
                      onChanged: (r) {
                        _pages.setRange(r);
                        _loadTotals();
                      },
                    ),
                    if (!_showDiscarded) ...[
                      const SizedBox(height: 12),
                      _filters(l),
                    ],
                  ],
                ),
                // The table is one item: the rows of this page.
                itemBuilder: (context, _) => const SizedBox.shrink(),
                body: _showDiscarded
                    ? _discardedList(context, l, _pages.items)
                    : AppDataTable<Invoice>(
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
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _filters(AppLocalizations l) {
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
    return StreamBuilder<PricingSettings>(
      stream: _firestore.watchPricing(),
      builder: (context, snap) {
        final items = <String, String>{
          for (final i in snap.data?.items ?? const <PriceItem>[])
            i.id: i.nameChinese.isNotEmpty ? i.nameChinese : i.name,
        };
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
              (v) {
                setState(() => _statusFilter = v);
                _reload();
              },
            ),
            drop<String>(l.adminInvoicesColItem, _itemFilter, items, (v) {
              setState(() => _itemFilter = v);
              _reload();
            }),
            if (_totals != null)
              Text(
                l.invoicesFilteredTotal(_totals!.count, formatRupiah(_totals!.amount)),
                style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy),
              ),
          ],
        );
      },
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
        cell: (invoice) => invoice.isPaid
            ? (invoice.proofPath == null
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: l.invoiceProofView,
                    icon: const Icon(Icons.receipt_outlined, size: 20),
                    onPressed: () => _showProof(context, invoice),
                  ))
            : !invoice.isDiscarded
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
    final result = await showDialog<
        ({String method, String note, Uint8List photo, String photoName})>(
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
            proofBytes: result.photo,
            proofName: result.photoName,
          );
      _reload();
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

  /// Owner 2026-11-26: the photo kept when the invoice was marked paid.
  Future<void> _showProof(BuildContext context, Invoice invoice) async {
    final l = context.l10n;
    final future = context.read<PaymentService>().paymentProofUrl(invoice.proofPath!);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.invoiceProofTitle(invoice.invoiceNumber)),
        content: SizedBox(
          width: 520,
          child: FutureBuilder<String>(
            future: future,
            builder: (ctx, snap) {
              if (snap.hasError) {
                return Text(l.invoiceProofLoadFailed,
                    style: TextStyle(color: AppColors.error));
              }
              if (!snap.hasData) {
                return const SizedBox(
                    height: 160, child: Center(child: CircularProgressIndicator()));
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 520),
                    child: InteractiveViewer(
                      child: Image.network(snap.data!, fit: BoxFit.contain),
                    ),
                  ),
                  if ((invoice.note ?? '').isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(invoice.note!,
                        style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ],
              );
            },
          ),
        ),
        actions: [
          // Owner 2026-11-26: keep a copy of the photo on the computer.
          TextButton.icon(
            onPressed: () => _downloadProof(ctx, invoice),
            icon: const Icon(Icons.download_outlined, size: 18),
            label: Text(l.invoiceProofDownload),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.commonOk),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadProof(BuildContext context, Invoice invoice) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final path = invoice.proofPath!;
    final dot = path.lastIndexOf('.');
    final ext = dot < 0 ? 'jpg' : path.substring(dot + 1).toLowerCase();
    final mime = ext == 'png'
        ? 'image/png'
        : ext == 'webp'
            ? 'image/webp'
            : 'image/jpeg';
    final name = 'payment_${invoice.invoiceNumber}'
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    try {
      final bytes =
          await context.read<PaymentService>().paymentProofBytes(path);
      file_download.downloadBytesFile('$name.$ext', bytes, mime);
    } catch (_) {
      messenger.showSnackBar(
          SnackBar(content: Text(l.invoiceProofDownloadFailed)));
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
      _reload();
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
      _reload();
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
    if (mounted) _reload();
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

/// "Mark as paid": how the money came in, a photo of the payment (owner
/// 2026-11-26, required for cash and transfer alike) and an optional note.
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
  Uint8List? _photo;
  String _photoName = '';
  bool _missingPhoto = false;

  Future<void> _pickPhoto() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    final file = picked?.files.firstOrNull;
    if (file?.bytes == null) return;
    setState(() {
      _photo = file!.bytes;
      _photoName = file.name;
      _missingPhoto = false;
    });
  }

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
            Text(
              _method == 'transfer'
                  ? l.invoiceProofHintTransfer
                  : l.invoiceProofHintCash,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
            ),
            const SizedBox(height: 8),
            if (_photo != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: Image.memory(_photo!, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 6),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _pickPhoto,
                icon: Icon(
                    _photo == null ? Icons.add_a_photo_outlined : Icons.swap_horiz,
                    size: 18),
                label: Text(_photo == null
                    ? l.invoiceProofAdd
                    : l.invoiceProofChange(_photoName)),
              ),
            ),
            if (_missingPhoto)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(l.invoiceProofRequired,
                    style: TextStyle(color: AppColors.error, fontSize: 12.5)),
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
          onPressed: () {
            final photo = _photo;
            if (photo == null) {
              setState(() => _missingPhoto = true);
              return;
            }
            Navigator.pop(
              context,
              (
                method: _method,
                note: _note.text.trim(),
                photo: photo,
                photoName: _photoName,
              ),
            );
          },
          child: Text(l.adminInvoicesConfirmPayment),
        ),
      ],
    );
  }
}
