import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_data_table.dart';
import '../../core/widgets/table_tools.dart';
import '../../core/widgets/status_pill.dart';
import '../../l10n/l10n.dart';
import '../../l10n/labels_admin.dart';
import '../../models/app_user.dart';
import '../../models/invoice.dart';
import '../../models/student_class_term.dart';
import '../../services/firestore_service.dart';

class AdminVouchersTab extends StatefulWidget {
  const AdminVouchersTab({super.key});

  @override
  State<AdminVouchersTab> createState() => _AdminVouchersTabState();
}

/// Payment state of a voucher, from its linked invoice.
enum _PaymentState { paid, pending, none }

class _AdminVouchersTabState extends State<AdminVouchersTab> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _sortColumnId;
  bool _sortAscending = true;

  /// null = all; otherwise only vouchers in that payment state.
  _PaymentState? _paymentFilter;
  Map<String, Invoice> _invoicesById = const {};

  _PaymentState _paymentState(StudentClassTerm term) {
    final inv = _invoicesById[term.sourceInvoiceId];
    if (inv == null) return _PaymentState.none;
    return inv.isPaid ? _PaymentState.paid : _PaymentState.pending;
  }

  (String label, Color color) _paymentLabel(
    AppLocalizations l,
    StudentClassTerm term,
  ) {
    final inv = _invoicesById[term.sourceInvoiceId];
    return switch (_paymentState(term)) {
      _PaymentState.paid => (
          '${l.adminInvoicesStatusPaid}${inv?.paidAt != null ? ' · ${DateFormat('d MMM').format(inv!.paidAt!)}' : ''}',
          AppColors.success,
        ),
      _PaymentState.pending => (
          l.adminVouchersPendingPayment,
          AppColors.brandYellow,
        ),
      _PaymentState.none => (l.adminVouchersNoPayment, AppColors.error),
    };
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  List<StudentClassTerm> _sorted(
    List<StudentClassTerm> terms,
    Map<String, String> usersById,
  ) {
    final columnId = _sortColumnId;
    if (columnId == null) return terms;

    final sorted = [...terms];
    sorted.sort((a, b) {
      final compare = switch (columnId) {
        'code' => (a.voucherCode ?? '').compareTo(b.voucherCode ?? ''),
        'student' => (usersById[a.studentId] ?? '')
            .toLowerCase()
            .compareTo((usersById[b.studentId] ?? '').toLowerCase()),
        'package' => a.packageSize.compareTo(b.packageSize),
        'remaining' => a.sessionsRemaining.compareTo(b.sessionsRemaining),
        'deadline' => a.deadlineDate.compareTo(b.deadlineDate),
        'status' => a.voucherStatusLabel.compareTo(b.voucherStatusLabel),
        'payment' => _paymentState(a).index.compareTo(_paymentState(b).index),
        _ => 0,
      };
      return _sortAscending ? compare : -compare;
    });
    return sorted;
  }

  Color _statusColor(String status) {
    return switch (status) {
      'depleted' => AppColors.textSecondary,
      'low' => AppColors.error,
      _ => AppColors.success,
    };
  }

  String _displayDate(String dateKey) {
    final parsed = DateTime.tryParse(dateKey);
    if (parsed == null) return dateKey.isEmpty ? '—' : dateKey;
    return DateFormat('d MMM yyyy').format(parsed);
  }

  List<StudentClassTerm> _filter(
    List<StudentClassTerm> terms,
    Map<String, String> usersById,
  ) {
    final q = _query.trim().toLowerCase();
    return terms.where((term) {
      if (_paymentFilter != null && _paymentState(term) != _paymentFilter) {
        return false;
      }
      if (q.isEmpty) return true;
      final studentName = (usersById[term.studentId] ?? '').toLowerCase();
      final code = (term.voucherCode ?? '').toLowerCase();
      return studentName.contains(q) || code.contains(q);
    }).toList();
  }

  static const _horizontalPadding = 20.0;

  List<String> _csvHeader(AppLocalizations l) => [
        l.adminVouchersColVoucher,
        l.commonStudent,
        l.adminVouchersColSessions,
        l.adminVouchersColUsed,
        l.adminVouchersColRemaining,
        l.adminVouchersColStart,
        l.adminVouchersColDeadline,
        l.profileWidgetStatus,
        l.adminVouchersColPayment,
      ];

  List<Object?> _csvRow(
    AppLocalizations l,
    StudentClassTerm t,
    Map<String, String> usersById,
  ) {
    final invoice = _invoicesById[t.sourceInvoiceId];
    return [
      t.voucherCode ?? '',
      usersById[t.studentId] ?? t.studentId,
      t.packageSize,
      t.sessionsUsed,
      t.sessionsRemaining,
      t.startDate,
      t.deadlineDate,
      t.voucherStatusLocalized(l),
      !t.hasPayment
          ? l.adminVouchersNoPayment
          : invoice == null
              ? l.adminVouchersInvoiceMissing
              : invoice.status.localized(l),
    ];
  }

  Widget _buildVoucherTable({
    required BuildContext context,
    required List<StudentClassTerm> terms,
    required Map<String, String> usersById,
  }) {
    final l = context.l10n;
    return AppDataTable<StudentClassTerm>(
      rows: _sorted(terms, usersById),
      columns: _buildColumns(context, usersById),
      sortColumnId: _sortColumnId,
      sortAscending: _sortAscending,
      onSort: _onSort,
      mobileCardBuilder: (term) => _VoucherCard(
        term: term,
        studentName: usersById[term.studentId] ?? l.adminVouchersUnknownStudent,
        payment: _paymentLabel(l, term),
        statusColor: _statusColor(term.voucherStatusLabel),
        displayDate: _displayDate,
        onEdit: () => context.push('/admin/vouchers/${term.id}/edit'),
        onDelete: () => _confirmDelete(
          context,
          term,
          usersById[term.studentId] ?? l.adminVouchersUnknownStudent,
        ),
      ),
    );
  }

  List<AppTableColumn<StudentClassTerm>> _buildColumns(
    BuildContext context,
    Map<String, String> usersById,
  ) {
    final l = context.l10n;
    final cellStyle = TextStyle(fontSize: 13, color: AppColors.textPrimary);
    final metaStyle = TextStyle(fontSize: 12, color: AppColors.textSecondary);

    return [
      AppTableColumn<StudentClassTerm>(
        id: 'code',
        label: l.adminVouchersVoucherCode,
        sortable: true,
        flex: 2,
        cell: (term) => Text(
          term.voucherCode ?? '—',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
            letterSpacing: 0.4,
          ),
        ),
      ),
      AppTableColumn<StudentClassTerm>(
        id: 'student',
        label: l.commonStudent,
        sortable: true,
        flex: 2,
        cell: (term) => Text(
          usersById[term.studentId] ?? l.adminVouchersUnknownStudent,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: cellStyle,
        ),
      ),
      AppTableColumn<StudentClassTerm>(
        id: 'package',
        label: l.adminVouchersColPackage,
        sortable: true,
        width: 96,
        cell: (term) => Text(
          l.termSessionsCount(term.packageSize),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: metaStyle,
        ),
      ),
      AppTableColumn<StudentClassTerm>(
        id: 'remaining',
        label: l.studentHomeSessionsLeft,
        sortable: true,
        width: 110,
        cell: (term) => Text(
          '${term.sessionsRemaining}/${term.packageSize}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: cellStyle,
        ),
      ),
      AppTableColumn<StudentClassTerm>(
        id: 'deadline',
        label: l.adminVouchersColDeadline,
        sortable: true,
        width: 120,
        cell: (term) => Text(
          _displayDate(term.deadlineDate),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: metaStyle,
        ),
      ),
      AppTableColumn<StudentClassTerm>(
        id: 'status',
        label: l.profileWidgetStatus,
        sortable: true,
        width: 100,
        cell: (term) => StatusPill(
          label: term.voucherStatusLocalized(l),
          color: _statusColor(term.voucherStatusLabel),
        ),
      ),
      AppTableColumn<StudentClassTerm>(
        id: 'payment',
        label: l.adminVouchersColPayment,
        sortable: true,
        width: 130,
        cell: (term) {
          final (label, color) = _paymentLabel(l, term);
          return StatusPill(label: label, color: color);
        },
      ),
      AppTableColumn<StudentClassTerm>(
        id: 'actions',
        label: l.adminUsersColActions,
        width: 100,
        alignment: Alignment.centerRight,
        cell: (term) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _VoucherIconAction(
              icon: Icons.edit_outlined,
              tooltip: l.adminVouchersEdit,
              onPressed: () => context.push('/admin/vouchers/${term.id}/edit'),
            ),
            const SizedBox(width: 10),
            _VoucherIconAction(
              icon: Icons.delete_outline,
              tooltip: l.adminVouchersDelete,
              color: AppColors.error,
              onPressed: () => _confirmDelete(
                context,
                term,
                usersById[term.studentId] ?? l.adminVouchersUnknownStudent,
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Future<void> _confirmDelete(
    BuildContext context,
    StudentClassTerm term,
    String studentName,
  ) async {
    final l = context.l10n;
    final code = term.voucherCode ?? l.adminVouchersThisVoucher;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.adminVouchersDeleteTitle),
        content: Text(l.adminVouchersDeleteBody(code, studentName)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.border),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l.termDelete),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    try {
      await context.read<FirestoreService>().deleteClassTerm(term.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.adminVouchersDeleted(code))),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();

    return StreamBuilder<List<StudentClassTerm>>(
      stream: firestore.watchAllClassTerms(),
      builder: (context, termsSnap) {
        return StreamBuilder<List<AppUser>>(
          stream: firestore.watchAllUsers(),
          builder: (context, usersSnap) {
            if (termsSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            return StreamBuilder<List<Invoice>>(
              stream: firestore.watchAllInvoices(),
              builder: (context, invSnap) {
                _invoicesById = {
                  for (final i in invSnap.data ?? const <Invoice>[]) i.id: i,
                };
                return _buildPage(context, termsSnap, usersSnap);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPage(
    BuildContext context,
    AsyncSnapshot<List<StudentClassTerm>> termsSnap,
    AsyncSnapshot<List<AppUser>> usersSnap,
  ) {
    {
      {
        final l = context.l10n;
        final usersById = <String, String>{
          for (final u in usersSnap.data ?? []) u.uid: u.name,
        };
        final terms = _filter(termsSnap.data ?? [], usersById);

        return ListView(
          padding: const EdgeInsets.all(_horizontalPadding),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                l.adminVouchersIntro,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: l.adminVouchersSearchHint,
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final (label, value) in <(String, _PaymentState?)>[
                  (l.adminVouchersFilterAll, null),
                  (l.adminVouchersPendingPayment, _PaymentState.pending),
                  (l.adminVouchersNoPayment, _PaymentState.none),
                  (l.adminInvoicesStatusPaid, _PaymentState.paid),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: _paymentFilter == value,
                    onSelected: (_) => setState(() => _paymentFilter = value),
                    selectedColor: AppColors.teal.withValues(alpha: 0.15),
                    checkmarkColor: AppColors.teal,
                  ),
                ExportCsvButton(
                  fileStem: 'vouchers',
                  header: _csvHeader(l),
                  rows: () => [
                    for (final t in _sorted(terms, usersById))
                      _csvRow(l, t, usersById),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (terms.isEmpty)
              AppCard(
                child: Column(
                  children: [
                    Icon(
                      Icons.confirmation_number_outlined,
                      size: 40,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      (termsSnap.data ?? []).isEmpty
                          ? l.adminVouchersEmptyTitle
                          : l.adminVouchersNoMatch,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l.adminVouchersEmptySubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    if ((termsSnap.data ?? []).isEmpty) ...[
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => context.push('/admin/vouchers/new'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.navy,
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(l.adminVouchersNewVoucher),
                      ),
                    ],
                  ],
                ),
              )
            else
              _buildVoucherTable(
                context: context,
                terms: terms,
                usersById: usersById,
              ),
          ],
        );
      }
    }
  }
}

class _VoucherCard extends StatelessWidget {
  const _VoucherCard({
    required this.term,
    required this.studentName,
    required this.payment,
    required this.statusColor,
    required this.displayDate,
    required this.onEdit,
    required this.onDelete,
  });

  final StudentClassTerm term;
  final String studentName;
  final (String, Color) payment;
  final Color statusColor;
  final String Function(String) displayDate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final code = term.voucherCode ?? '—';

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      code,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      studentName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l.adminVouchersCardSessions(
                        term.packageSize,
                        term.sessionsRemaining,
                      ),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${displayDate(term.startDate)} → '
                      '${displayDate(term.deadlineDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (term.notes != null && term.notes!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        term.notes!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusPill(
                    label: term.voucherStatusLocalized(l),
                    color: statusColor,
                  ),
                  const SizedBox(height: 6),
                  StatusPill(label: payment.$1, color: payment.$2),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _VoucherIconAction(
                icon: Icons.edit_outlined,
                tooltip: l.adminVouchersEdit,
                onPressed: onEdit,
              ),
              const SizedBox(width: 10),
              _VoucherIconAction(
                icon: Icons.delete_outline,
                tooltip: l.adminVouchersDelete,
                color: AppColors.error,
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VoucherIconAction extends StatelessWidget {
  _VoucherIconAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    Color? color,
  }) : color = color ?? AppColors.navy;

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withValues(alpha: 0.07),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withValues(alpha: 0.14)),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 17, color: color),
          ),
        ),
      ),
    );
  }
}
