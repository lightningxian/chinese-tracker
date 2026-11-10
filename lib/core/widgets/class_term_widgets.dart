import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../theme/app_theme.dart';
import '../../models/attendance_record.dart';
import '../../models/invoice.dart';
import '../../models/student_class_term.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../utils/money_format.dart';
import 'app_card.dart';

String _formatDateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

String _displayDate(String dateKey) {
  final parsed = DateTime.tryParse(dateKey);
  if (parsed == null) return dateKey.isEmpty ? '—' : dateKey;
  return DateFormat('d MMM yyyy').format(parsed);
}

Future<({DateTime start, DateTime deadline})?> _pickTermDates(
  BuildContext context, {
  required DateTime initialStart,
  required DateTime initialDeadline,
}) async {
  var start = initialStart;
  var deadline = initialDeadline;

  return showDialog<({DateTime start, DateTime deadline})>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) {
        Future<void> pickStart() async {
          final picked = await showDatePicker(
            context: context,
            initialDate: start,
            firstDate: DateTime(2020),
            lastDate: DateTime(2035),
          );
          if (picked != null) {
            setState(() {
              start = picked;
              if (deadline.isBefore(start)) deadline = start;
            });
          }
        }

        Future<void> pickDeadline() async {
          final picked = await showDatePicker(
            context: context,
            initialDate: deadline.isBefore(start) ? start : deadline,
            firstDate: start,
            lastDate: DateTime(2035),
          );
          if (picked != null) setState(() => deadline = picked);
        }

        return AlertDialog(
          title: const Text('Term dates'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Start date'),
                subtitle: Text(_formatDateKey(start)),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: pickStart,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Deadline date'),
                subtitle: Text(_formatDateKey(deadline)),
                trailing: const Icon(Icons.event_outlined),
                onTap: pickDeadline,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(ctx, (start: start, deadline: deadline)),
              child: const Text('Save'),
            ),
          ],
        );
      },
    ),
  );
}

class ClassTermBalanceCard extends StatelessWidget {
  const ClassTermBalanceCard({
    super.key,
    required this.terms,
    this.compact = false,
    this.emphasized = false,
  });

  final List<StudentClassTerm> terms;
  final bool compact;
  final bool emphasized;

  StudentClassTerm? _primaryActiveTerm(List<StudentClassTerm> active) {
    if (active.isEmpty) return null;
    final sorted = List<StudentClassTerm>.from(active)
      ..sort((a, b) => a.deadlineDate.compareTo(b.deadlineDate));
    return sorted.first;
  }

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final remaining = firestore.totalRemainingClassSessions(terms);
    final activeTerms =
        terms.where((t) => t.isActive && t.isWithinTermDates).toList();
    final activePackages = activeTerms.length;
    final primary = _primaryActiveTerm(activeTerms);

    if (emphasized) {
      final isEmpty = remaining <= 0;
      final isLow = remaining > 0 && remaining <= 2;
      final accent = isEmpty
          ? AppColors.error
          : isLow
              ? AppColors.brandYellow
              : AppColors.teal;

      return AppCard(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withValues(alpha: 0.35)),
                ),
                child: Text(
                  '$remaining',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: isEmpty ? AppColors.error : AppColors.navy,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      remaining == 1
                          ? 'Class meeting left this term'
                          : 'Class meetings left this term',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.navy,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (isEmpty)
                      Text(
                        'No paid sessions left. Ask your teacher to add a new term.',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      )
                    else if (primary != null) ...[
                      Text(
                        '${primary.sessionsUsed} used · '
                        '${primary.sessionsRemaining} remaining of ${primary.packageSize}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Valid until ${_displayDate(primary.deadlineDate)}',
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ] else
                      Text(
                        activePackages == 0
                            ? 'No active term in the current date range.'
                            : '$activePackages active package${activePackages == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      'One session is charged when your teacher concludes each class.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.navy.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.card_membership, color: AppColors.navy),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$remaining class session${remaining == 1 ? '' : 's'} left',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      activePackages == 0
                          ? 'No active term in date range'
                          : '$activePackages active package${activePackages == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sessions deduct when the teacher concludes a class.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!compact && terms.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...terms.take(3).map((term) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${term.packageSize}-session · '
                        '${_displayDate(term.startDate)} – ${_displayDate(term.deadlineDate)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      '${term.sessionsRemaining} left',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: term.isActive && term.isWithinTermDates
                            ? AppColors.teal
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class ClassTermPackagesList extends StatelessWidget {
  const ClassTermPackagesList({
    super.key,
    required this.terms,
    this.visitsByTermId = const {},
    this.invoicesById = const {},
    this.allowManage = false,
  });

  final List<StudentClassTerm> terms;
  final Map<String, List<AttendanceRecord>> visitsByTermId;

  /// The student's invoices, to show whether each term is paid.
  final Map<String, Invoice> invoicesById;
  final bool allowManage;

  (String, Color) _paymentLine(StudentClassTerm term) {
    final inv = invoicesById[term.sourceInvoiceId];
    if (inv == null) {
      return ('No payment recorded', AppColors.textSecondary);
    }
    if (inv.isPaid) {
      final when = inv.paidAt == null
          ? ''
          : ' · ${_displayDate(inv.paidAt!.toIso8601String())}';
      return (
        'Paid ${formatRupiah(inv.amount)} (${inv.methodLabel.toLowerCase()})$when',
        AppColors.success
      );
    }
    return ('Pending payment · ${formatRupiah(inv.amount)}', AppColors.error);
  }

  Future<void> _editTerm(BuildContext context, StudentClassTerm term) async {
    final result = await showDialog<
        ({
          DateTime start,
          DateTime deadline,
          int sessionsRemaining,
        })>(
      context: context,
      builder: (ctx) => _EditClassTermDialog(term: term),
    );

    if (result == null || !context.mounted) return;

    try {
      await context.read<FirestoreService>().updateClassTerm(
            termId: term.id,
            startDate: result.start,
            deadlineDate: result.deadline,
            sessionsRemaining: result.sessionsRemaining,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Term updated')),
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

  Future<void> _deleteTerm(BuildContext context, StudentClassTerm term) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this term?'),
        content: Text(
          'Delete the ${term.packageSize}-session term '
          '(${term.sessionsRemaining} left)? Past class charges linked to '
          'this term are kept in history. This cannot be undone.',
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
          const SnackBar(content: Text('Term deleted')),
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
    if (terms.isEmpty) {
      return AppCard(
        child: Text(
          'No paid term packages yet. Add an 8 or 16 session term when the student pays.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
      );
    }

    return Column(
      children: terms.map((term) {
        final inRange = term.isWithinTermDates;
        final visits = visitsByTermId[term.id] ?? const <AttendanceRecord>[];
        final usedFromHistory = visits.length;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AppCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${term.packageSize}-session term',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (allowManage) ...[
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        tooltip: 'Edit term',
                        onPressed: () => _editTerm(context, term),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        color: AppColors.error,
                        tooltip: 'Delete term',
                        onPressed: () => _deleteTerm(context, term),
                      ),
                    ],
                  ],
                ),
                Text(
                  'Start: ${_displayDate(term.startDate)} · '
                  'Deadline: ${_displayDate(term.deadlineDate)}',
                  style: TextStyle(
                    color: inRange ? AppColors.textSecondary : AppColors.error,
                    fontSize: 12,
                  ),
                ),
                if (!inRange)
                  Text(
                    'Outside term dates today',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                Builder(builder: (context) {
                  final (label, color) = _paymentLine(term);
                  return Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${term.sessionsRemaining} / ${term.packageSize} left',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: term.isActive && inRange
                            ? AppColors.teal
                            : AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      term.isActive ? 'Active' : 'Used up',
                      style: TextStyle(
                        fontSize: 12,
                        color: term.isActive
                            ? AppColors.success
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _TermVisitHistory(visits: visits, usedCount: usedFromHistory),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TermVisitHistory extends StatelessWidget {
  const _TermVisitHistory({
    required this.visits,
    required this.usedCount,
  });

  final List<AttendanceRecord> visits;
  final int usedCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Classes attended ($usedCount)',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        if (visits.isEmpty)
          Text(
            'No classes charged to this term yet.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          )
        else
          ...visits.map((record) {
            final parsed = DateTime.tryParse(record.sessionDate);
            final dateLabel = parsed != null
                ? DateFormat('EEE, d MMM yyyy').format(parsed)
                : record.sessionDate;

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.check_circle_outline,
                      color: AppColors.success,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          [
                            if (record.sessionTitle.isNotEmpty)
                              record.sessionTitle,
                            record.timeRangeLabel,
                          ].join(' · '),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '−1',
                    style: TextStyle(
                      color: AppColors.teal,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class ClassAttendanceHistoryList extends StatelessWidget {
  const ClassAttendanceHistoryList({super.key, required this.records});

  final List<AttendanceRecord> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return AppCard(
        child: Text(
          'No concluded class visits yet.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      children: records.map((record) {
        final parsed = DateTime.tryParse(record.sessionDate);
        final dateLabel = parsed != null
            ? DateFormat('EEE, d MMM yyyy').format(parsed)
            : record.sessionDate;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: AppColors.success,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.sessionTitle.isNotEmpty
                            ? record.sessionTitle
                            : 'Class',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '$dateLabel · ${record.timeRangeLabel}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '−1 session',
                  style: TextStyle(
                    color: AppColors.teal,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _EditClassTermDialog extends StatefulWidget {
  const _EditClassTermDialog({required this.term});

  final StudentClassTerm term;

  @override
  State<_EditClassTermDialog> createState() => _EditClassTermDialogState();
}

class _EditClassTermDialogState extends State<_EditClassTermDialog> {
  late DateTime _start;
  late DateTime _deadline;
  late final TextEditingController _remainingController;

  @override
  void initState() {
    super.initState();
    _start = DateTime.tryParse(widget.term.startDate) ?? DateTime.now();
    _deadline = DateTime.tryParse(widget.term.deadlineDate) ??
        _start.add(const Duration(days: 90));
    _remainingController = TextEditingController(
      text: '${widget.term.sessionsRemaining}',
    );
  }

  @override
  void dispose() {
    _remainingController.dispose();
    super.dispose();
  }

  void _save() {
    final remaining = int.tryParse(_remainingController.text.trim());
    if (remaining == null ||
        remaining < 0 ||
        remaining > widget.term.packageSize) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Enter sessions remaining between 0 and ${widget.term.packageSize}',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    Navigator.pop(context, (
      start: _start,
      deadline: _deadline,
      sessionsRemaining: remaining,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.term.packageSize}-session term'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Start date'),
              subtitle: Text(_formatDateKey(_start)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _start,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (picked != null) {
                  setState(() {
                    _start = picked;
                    if (_deadline.isBefore(_start)) _deadline = _start;
                  });
                }
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Deadline date'),
              subtitle: Text(_formatDateKey(_deadline)),
              trailing: const Icon(Icons.event_outlined),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _deadline.isBefore(_start) ? _start : _deadline,
                  firstDate: _start,
                  lastDate: DateTime(2035),
                );
                if (picked != null) setState(() => _deadline = picked);
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _remainingController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Sessions remaining',
                helperText: 'Out of ${widget.term.packageSize} in this package',
                border: const OutlineInputBorder(),
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
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class AddClassTermButton extends StatelessWidget {
  const AddClassTermButton({
    super.key,
    required this.studentId,
    this.onAdded,
  });

  final String studentId;
  final VoidCallback? onAdded;

  Future<void> _showAddDialog(BuildContext context) async {
    final teacherId = context.read<AuthService>().appUser?.uid;
    if (teacherId == null) return;

    final packageSize = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add paid term'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Choose how many class sessions the student paid for. '
              'Sessions are deducted when you conclude each class.',
            ),
            const SizedBox(height: 16),
            for (final size in AppConstants.termSizes)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx, size),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                  ),
                  child: Text('$size sessions'),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (packageSize == null || !context.mounted) return;

    final now = DateTime.now();
    final defaultDeadline = now.add(
      Duration(days: packageSize == 16 ? 180 : 90),
    );
    final dates = await _pickTermDates(
      context,
      initialStart: now,
      initialDeadline: defaultDeadline,
    );
    if (dates == null || !context.mounted) return;

    try {
      final firestore = context.read<FirestoreService>();
      final termId = await firestore.createClassTermPackage(
        studentId: studentId,
        packageSize: packageSize,
        createdByTeacherId: teacherId,
        startDate: dates.start,
        deadlineDate: dates.deadline,
      );
      // Every voucher needs a payment: record a pending cash/transfer
      // invoice for the admin to settle (Payments → Mark as paid).
      String paymentNote = '';
      try {
        final pricing = await firestore.watchPricing().first;
        final item = pricing.itemForSessions(packageSize);
        final student = await firestore.getUser(studentId);
        if (item != null && student != null) {
          final invoiceId = await firestore.createManualInvoice(
            student: student,
            item: item,
            createdBy: teacherId,
            dueDate: DateTime.now().add(const Duration(days: 7)),
            classTermId: termId,
          );
          await firestore.linkClassTermToInvoice(
            termId: termId,
            invoiceId: invoiceId,
          );
          paymentNote = ' Pending payment of ${formatRupiah(item.price)} '
              'recorded for the admin.';
        } else {
          paymentNote = ' No price-list item for $packageSize sessions: the '
              'admin must add the payment by hand.';
        }
      } catch (e) {
        paymentNote = ' Could not record the payment ($e); the admin must add '
            'it in Payments.';
      }
      onAdded?.call();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added $packageSize-session term.$paymentNote'),
          ),
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
    return FilledButton.icon(
      onPressed: () => _showAddDialog(context),
      icon: const Icon(Icons.add),
      label: const Text('Add term'),
      style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
    );
  }
}

class StudentHomeTermBalance extends StatelessWidget {
  const StudentHomeTermBalance({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();

    return StreamBuilder<List<StudentClassTerm>>(
      stream: firestore.watchStudentClassTerms(studentId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const AppCard(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          );
        }

        if (snap.hasError) {
          return AppCard(
            child: Text(
              snap.error.toString(),
              style: TextStyle(color: AppColors.error),
            ),
          );
        }

        return ClassTermBalanceCard(
          terms: snap.data ?? [],
          emphasized: true,
        );
      },
    );
  }
}

class StudentClassTermSection extends StatelessWidget {
  const StudentClassTermSection({
    super.key,
    required this.studentId,
    this.showAddButton = false,
    this.allowManage = false,
  });

  final String studentId;
  final bool showAddButton;
  final bool allowManage;

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();

    return StreamBuilder<List<StudentClassTerm>>(
      stream: firestore.watchStudentClassTerms(studentId),
      builder: (context, termsSnap) {
        final terms = termsSnap.data ?? [];

        return StreamBuilder<List<AttendanceRecord>>(
          stream: firestore.watchCreditedClassHistory(studentId),
          builder: (context, historySnap) {
            final history = historySnap.data ?? [];
            final visitsByTermId = firestore.visitsByTermId(history);
            return StreamBuilder<List<Invoice>>(
              stream: firestore.watchStudentInvoices(studentId),
              builder: (context, invSnap) {
                final invoicesById = {
                  for (final i in invSnap.data ?? const <Invoice>[]) i.id: i,
                };
                return _body(
                  context,
                  termsSnap: termsSnap,
                  terms: terms,
                  history: history,
                  visitsByTermId: visitsByTermId,
                  invoicesById: invoicesById,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _body(
    BuildContext context, {
    required AsyncSnapshot<List<StudentClassTerm>> termsSnap,
    required List<StudentClassTerm> terms,
    required List<AttendanceRecord> history,
    required Map<String, List<AttendanceRecord>> visitsByTermId,
    required Map<String, Invoice> invoicesById,
  }) {
    {
      {
        {
          {
            final unlinkedVisits = history
                .where(
                  (r) => r.classTermId == null || r.classTermId!.isEmpty,
                )
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'Paid class terms',
                  action: showAddButton
                      ? AddClassTermButton(studentId: studentId)
                      : null,
                ),
                if (termsSnap.connectionState == ConnectionState.waiting)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  ClassTermBalanceCard(terms: terms),
                  const SizedBox(height: 16),
                  Text(
                    'Term packages',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClassTermPackagesList(
                    terms: terms,
                    visitsByTermId: visitsByTermId,
                    invoicesById: invoicesById,
                    allowManage: allowManage,
                  ),
                  if (unlinkedVisits.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    SectionHeader(
                      title:
                          'Other concluded visits (${unlinkedVisits.length})',
                    ),
                    ClassAttendanceHistoryList(records: unlinkedVisits),
                  ],
                ],
              ],
            );
          }
        }
      }
    }
  }
}
