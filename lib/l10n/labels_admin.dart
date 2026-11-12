import '../models/app_user.dart';
import '../models/invoice.dart';
import '../models/pricing_settings.dart';
import '../models/student_class_term.dart';
import 'generated/app_localizations.dart';

/// Localised labels for model enums and derived labels used by the admin
/// people and money screens. The models keep their English `label` getters
/// (used in logs and CSV fixtures); the UI reads these instead.

extension InvoiceStatusLabels on InvoiceStatus {
  String localized(AppLocalizations l) => switch (this) {
        InvoiceStatus.pending => l.adminInvoicesStatusPending,
        InvoiceStatus.paid => l.adminInvoicesStatusPaid,
        InvoiceStatus.expired => l.historyStatusExpired,
        InvoiceStatus.failed => l.adminInvoicesStatusFailed,
      };
}

/// `cash` / `transfer` / `midtrans` → label. [pending] picks the fallback
/// for unknown methods, like [Invoice.methodLabel].
String localizedPaymentMethod(
  AppLocalizations l,
  String method, {
  bool pending = false,
}) =>
    switch (method) {
      'midtrans' => l.adminInvoicesMethodOnline,
      'cash' => l.adminInvoicesMethodCash,
      'transfer' => l.adminInvoicesMethodTransfer,
      _ =>
        pending ? l.adminInvoicesMethodAtCentre : l.adminInvoicesMethodManual,
    };

extension InvoiceLabels on Invoice {
  /// Same cases as [methodLabel].
  String methodLocalized(AppLocalizations l) =>
      localizedPaymentMethod(l, paymentMethod, pending: isPending);

  /// Same cases as [itemLabel].
  String itemLocalized(AppLocalizations l) {
    if (description != null && description!.isNotEmpty) return description!;
    if (isBook) return l.adminInvoicesItemBook;
    if (creditsSessions) return l.termSessionsCount(sessions);
    return kind;
  }
}

extension PriceItemLabels on PriceItem {
  /// Same cases as [givesLabel].
  String givesLocalized(AppLocalizations l) => switch (kind) {
        PriceKind.sessions => l.termSessionsCount(sessions),
        PriceKind.book => l.adminInvoicesGivesBook,
        PriceKind.registration => l.adminInvoicesGivesRegistration,
        PriceKind.other => l.adminInvoicesGivesNone,
      };
}

extension StudentClassTermLabels on StudentClassTerm {
  /// Same cases as [voucherStatusLabel]; an unknown raw status is shown as is.
  String voucherStatusLocalized(AppLocalizations l) =>
      switch (voucherStatusLabel) {
        'active' => l.adminVouchersStatusActive,
        'low' => l.adminVouchersStatusLow,
        'depleted' => l.adminVouchersStatusDepleted,
        final other => other,
      };
}

extension AppUserRoleLabels on AppUser {
  /// Same cases as [roleDisplayLabel].
  String roleLocalized(AppLocalizations l) {
    if (isAdmin) return l.adminUsersRoleAdmin;
    if (isTeacher) return l.adminUsersRoleTeacher;
    if (isParent) return l.adminUsersRoleParent;
    return l.adminUsersRoleStudent;
  }
}
