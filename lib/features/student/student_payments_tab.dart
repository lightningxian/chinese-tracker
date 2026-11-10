import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../l10n/l10n.dart';
import '../../models/app_user.dart';
import '../../models/invoice.dart';
import '../../models/org_settings.dart';
import '../../models/student_class_term.dart';
import '../../services/firestore_service.dart';
import '../../services/payment_service.dart';
import '../admin/admin_invoices_tab.dart' show InvoiceCard;

/// Student view of their session quota + invoices, with a "Pay now" action.
class StudentPaymentsTab extends StatelessWidget {
  const StudentPaymentsTab({super.key, required this.student});

  final AppUser student;

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();

    return StreamBuilder<OrgSettings>(
      stream: firestore.watchOrgSettings(),
      builder: (context, settingsSnap) {
        final paymentsOn =
            (settingsSnap.data ?? OrgSettings.defaults).enablePayments;
        if (!paymentsOn) {
          return EmptyState(
            icon: Icons.money_off_outlined,
            title: context.l10n.studentPaymentsDisabledTitle,
            subtitle: context.l10n.studentPaymentsDisabledSubtitle,
          );
        }
        return _buildContent(context, firestore);
      },
    );
  }

  Widget _buildContent(BuildContext context, FirestoreService firestore) {
    return StreamBuilder<List<StudentClassTerm>>(
      stream: firestore.watchStudentClassTerms(student.uid),
      builder: (context, termSnap) {
        final terms = termSnap.data ?? [];
        final remaining = firestore.totalRemainingClassSessions(terms);

        return StreamBuilder<List<Invoice>>(
          stream: firestore.watchStudentInvoices(student.uid),
          builder: (context, invSnap) {
            if (invSnap.connectionState == ConnectionState.waiting &&
                termSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final invoices = invSnap.data ?? [];

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _QuotaCard(remaining: remaining),
                const SizedBox(height: 20),
                SectionHeader(title: context.l10n.studentPaymentsInvoices),
                if (invoices.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      context.l10n.studentPaymentsNoInvoices,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                else
                  for (final invoice in invoices) ...[
                    InvoiceCard(
                      invoice: invoice,
                      onPay: () => _pay(context, invoice),
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

class _QuotaCard extends StatelessWidget {
  const _QuotaCard({required this.remaining});

  final int remaining;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                Icon(Icons.confirmation_number_outlined, color: AppColors.teal),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.studentPaymentsSessionsRemaining(remaining),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.studentPaymentsQuotaHint,
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
    );
  }
}
