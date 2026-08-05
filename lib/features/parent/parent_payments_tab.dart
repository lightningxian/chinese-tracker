import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/app_card.dart';
import '../../models/app_user.dart';
import '../../models/invoice.dart';
import '../../services/firestore_service.dart';
import '../admin/admin_invoices_tab.dart' show InvoiceCard;

/// Read-only view of a child's invoices for a parent.
class ParentPaymentsTab extends StatelessWidget {
  const ParentPaymentsTab({super.key, required this.child});

  final AppUser child;

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();

    return StreamBuilder<List<Invoice>>(
      stream: firestore.watchStudentInvoices(child.uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final invoices = snap.data ?? [];
        if (invoices.isEmpty) {
          return const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No invoices',
            subtitle: 'Invoices for your child will appear here.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: invoices.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => InvoiceCard(invoice: invoices[i]),
        );
      },
    );
  }
}
