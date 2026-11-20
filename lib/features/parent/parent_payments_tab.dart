import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../l10n/l10n.dart';
import '../../models/app_user.dart';
import '../../models/invoice.dart';
import '../../models/org_settings.dart';
import '../../services/firestore_service.dart';
import '../../services/payment_service.dart';
import '../admin/admin_invoices_tab.dart' show InvoiceCard;
import '../payments/voucher_widgets.dart';

/// A child's invoices for a parent, with the same **Pay now** the student
/// has: the invoice stays on the student, whoever is linked may pay it.
class ParentPaymentsTab extends StatelessWidget {
  const ParentPaymentsTab({super.key, required this.child});

  final AppUser child;

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();

    return StreamBuilder<OrgSettings>(
      stream: firestore.watchOrgSettings(),
      builder: (context, settingsSnap) {
        final paymentsOn =
            (settingsSnap.data ?? OrgSettings.defaults).enablePayments;
        return StreamBuilder<List<Invoice>>(
          stream: firestore.watchStudentInvoices(child.uid),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final invoices = snap.data ?? [];
            // Build 5: the child's vouchers and Beli voucher come first.
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                VoucherSection(
                  key: ValueKey(child.uid),
                  studentId: child.uid,
                  canBuy: paymentsOn,
                ),
                const SizedBox(height: 20),
                if (invoices.isEmpty)
                  EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: context.l10n.parentPaymentsEmptyTitle,
                    subtitle: context.l10n.parentPaymentsEmptySubtitle,
                  )
                else
                  for (final invoice in invoices) ...[
                    InvoiceCard(
                      invoice: invoice,
                      onPay: paymentsOn ? () => _pay(context, invoice) : null,
                    ),
                    const SizedBox(height: 10),
                  ],
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _pay(BuildContext context, Invoice invoice) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<PaymentService>().openPayment(invoice.redirectUrl);
    } on PaymentException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
