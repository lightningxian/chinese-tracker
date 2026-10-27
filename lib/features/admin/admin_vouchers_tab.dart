import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_data_table.dart';
import '../../core/widgets/status_pill.dart';
import '../../models/app_user.dart';
import '../../models/student_class_term.dart';
import '../../services/firestore_service.dart';

class AdminVouchersTab extends StatefulWidget {
  const AdminVouchersTab({super.key});

  @override
  State<AdminVouchersTab> createState() => _AdminVouchersTabState();
}

class _AdminVouchersTabState extends State<AdminVouchersTab> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _sortColumnId;
  bool _sortAscending = true;

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
    if (q.isEmpty) return terms;

    return terms.where((term) {
      final studentName = (usersById[term.studentId] ?? '').toLowerCase();
      final code = (term.voucherCode ?? '').toLowerCase();
      return studentName.contains(q) || code.contains(q);
    }).toList();
  }

  static const _horizontalPadding = 20.0;

  Widget _buildVoucherTable({
    required BuildContext context,
    required List<StudentClassTerm> terms,
    required Map<String, String> usersById,
  }) {
    return AppDataTable<StudentClassTerm>(
      rows: _sorted(terms, usersById),
      columns: _buildColumns(context, usersById),
      sortColumnId: _sortColumnId,
      sortAscending: _sortAscending,
      onSort: _onSort,
      mobileCardBuilder: (term) => _VoucherCard(
        term: term,
        studentName: usersById[term.studentId] ?? 'Unknown student',
        statusColor: _statusColor(term.voucherStatusLabel),
        displayDate: _displayDate,
        onEdit: () => context.push('/admin/vouchers/${term.id}/edit'),
        onDelete: () => _confirmDelete(
          context,
          term,
          usersById[term.studentId] ?? 'Unknown student',
        ),
      ),
    );
  }

  List<AppTableColumn<StudentClassTerm>> _buildColumns(
    BuildContext context,
    Map<String, String> usersById,
  ) {
    const cellStyle = TextStyle(fontSize: 13, color: AppColors.textPrimary);
    const metaStyle = TextStyle(fontSize: 12, color: AppColors.textSecondary);

    return [
      AppTableColumn<StudentClassTerm>(
        id: 'code',
        label: 'Voucher code',
        sortable: true,
        flex: 2,
        cell: (term) => Text(
          term.voucherCode ?? '—',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
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
        label: 'Student',
        sortable: true,
        flex: 2,
        cell: (term) => Text(
          usersById[term.studentId] ?? 'Unknown student',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: cellStyle,
        ),
      ),
      AppTableColumn<StudentClassTerm>(
        id: 'package',
        label: 'Package',
        sortable: true,
        width: 96,
        cell: (term) => Text(
          '${term.packageSize} sessions',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: metaStyle,
        ),
      ),
      AppTableColumn<StudentClassTerm>(
        id: 'remaining',
        label: 'Sessions left',
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
        label: 'Deadline',
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
        label: 'Status',
        sortable: true,
        width: 100,
        cell: (term) => StatusPill(
          label: term.voucherStatusLabel,
          color: _statusColor(term.voucherStatusLabel),
        ),
      ),
      AppTableColumn<StudentClassTerm>(
        id: 'actions',
        label: 'Actions',
        width: 100,
        alignment: Alignment.centerRight,
        cell: (term) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _VoucherIconAction(
              icon: Icons.edit_outlined,
              tooltip: 'Edit voucher',
              onPressed: () => context.push('/admin/vouchers/${term.id}/edit'),
            ),
            const SizedBox(width: 10),
            _VoucherIconAction(
              icon: Icons.delete_outline,
              tooltip: 'Delete voucher',
              color: AppColors.error,
              onPressed: () => _confirmDelete(
                context,
                term,
                usersById[term.studentId] ?? 'Unknown student',
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
    final code = term.voucherCode ?? 'this voucher';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete voucher?'),
        content: Text(
          'Delete $code for $studentName? This cannot be undone.',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
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

    if (confirm != true || !context.mounted) return;

    try {
      await context.read<FirestoreService>().deleteClassTerm(term.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted $code')),
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

            final usersById = <String, String>{
              for (final u in usersSnap.data ?? []) u.uid: u.name,
            };
            final terms = _filter(termsSnap.data ?? [], usersById);

            return ListView(
              padding: const EdgeInsets.all(_horizontalPadding),
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    "A voucher is a student's paid term: 8 or 16 class sessions "
                    'with a start date and a deadline. The same packages appear '
                    'under "Term packages" on the student\'s page, and one session '
                    'is deducted each time a class is concluded. Codes are '
                    'optional labels you can set when editing.',
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
                    hintText: 'Search by code or student…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: AppColors.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (terms.isEmpty)
                  AppCard(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.confirmation_number_outlined,
                          size: 40,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          (termsSnap.data ?? []).isEmpty
                              ? 'No vouchers yet'
                              : 'No vouchers match your search',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Create a voucher to issue session packages with '
                          'trackable codes like 2026_07_001.',
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
                            onPressed: () =>
                                context.push('/admin/vouchers/new'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.navy,
                            ),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('New voucher'),
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
          },
        );
      },
    );
  }
}

class _VoucherCard extends StatelessWidget {
  const _VoucherCard({
    required this.term,
    required this.studentName,
    required this.statusColor,
    required this.displayDate,
    required this.onEdit,
    required this.onDelete,
  });

  final StudentClassTerm term;
  final String studentName;
  final Color statusColor;
  final String Function(String) displayDate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
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
                      style: const TextStyle(
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
                      '${term.packageSize} sessions · '
                      '${term.sessionsRemaining} remaining',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${displayDate(term.startDate)} → '
                      '${displayDate(term.deadlineDate)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (term.notes != null && term.notes!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        term.notes!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              StatusPill(
                label: term.voucherStatusLabel,
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _VoucherIconAction(
                icon: Icons.edit_outlined,
                tooltip: 'Edit voucher',
                onPressed: onEdit,
              ),
              const SizedBox(width: 10),
              _VoucherIconAction(
                icon: Icons.delete_outline,
                tooltip: 'Delete voucher',
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
  const _VoucherIconAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color = AppColors.navy,
  });

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
