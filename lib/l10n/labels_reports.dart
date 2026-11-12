import 'package:intl/intl.dart';

import '../models/admin_dashboard_stat_kind.dart';
import '../models/cohort_report_models.dart';
import '../models/pricing_settings.dart';
import 'generated/app_localizations.dart';

/// Localized labels for model values shown on the admin dashboard, reports
/// and settings screens. The models stay language-free (their own `label` /
/// `title` getters are English); screens pass `context.l10n` in here instead.

extension AdminDashboardStatKindLabels on AdminDashboardStatKind {
  String localizedTitle(AppLocalizations l) => switch (this) {
        AdminDashboardStatKind.totalUsers => l.adminDashStatAllUsersTitle,
        AdminDashboardStatKind.activeMurid => l.adminDashActiveMurid,
        AdminDashboardStatKind.exercises => l.adminDashStatExercisesTitle,
        AdminDashboardStatKind.incomeMonthly => l.adminDashStatIncomeTitle,
        AdminDashboardStatKind.newStudentsMonthly =>
          l.adminDashStatSignupsTitle,
        AdminDashboardStatKind.voucherAlerts =>
          l.adminDashStatVoucherAlertsTitle,
      };

  String localizedDescription(AppLocalizations l) => switch (this) {
        AdminDashboardStatKind.totalUsers => l.adminDashStatAllUsersDesc,
        AdminDashboardStatKind.activeMurid => l.adminDashStatActiveMuridDesc,
        AdminDashboardStatKind.exercises => l.adminDashStatExercisesDesc,
        AdminDashboardStatKind.incomeMonthly => l.adminDashStatIncomeDesc,
        AdminDashboardStatKind.newStudentsMonthly => l.adminDashStatSignupsDesc,
        AdminDashboardStatKind.voucherAlerts =>
          l.adminDashStatVoucherAlertsDesc,
      };
}

extension PriceKindLabels on PriceKind {
  String localized(AppLocalizations l) => switch (this) {
        PriceKind.sessions => l.adminPriceKindSessions,
        PriceKind.book => l.adminPriceKindBook,
        PriceKind.registration => l.adminPriceKindRegistration,
        PriceKind.other => l.adminPriceKindOther,
      };
}

extension StudentRosterSummaryLabels on StudentRosterSummary {
  /// Localized version of [StudentRosterSummary.lastActivityLabel].
  String lastActivityLocalized(AppLocalizations l) {
    final at = lastActivityAt;
    if (at == null) return l.cohortNoActivity;
    final days = DateTime.now().difference(at).inDays;
    if (days < 1) return l.cohortToday;
    if (days < 7) return l.cohortDaysAgo(days);
    return DateFormat('d MMM').format(at);
  }

  /// Localized version of [StudentRosterSummary.homeworkLabel].
  String homeworkLocalized(AppLocalizations l) {
    if (homeworkAssigned == 0) return l.cohortNoHomework;
    if (homeworkOverdue > 0) {
      return l.cohortHomeworkOverdueOf(
          homeworkCompleted, homeworkAssigned, homeworkOverdue);
    }
    return l.cohortHomeworkDoneOf(homeworkCompleted, homeworkAssigned);
  }
}
