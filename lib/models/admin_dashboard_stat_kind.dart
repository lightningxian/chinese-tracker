enum AdminDashboardStatKind {
  totalUsers('total-users'),
  activeMurid('active-murid'),
  exercises('exercises'),
  incomeMonthly('income-monthly'),
  newStudentsMonthly('new-students-monthly'),
  voucherAlerts('voucher-alerts');

  const AdminDashboardStatKind(this.routeSlug);

  final String routeSlug;

  static AdminDashboardStatKind? fromRouteSlug(String slug) {
    for (final kind in values) {
      if (kind.routeSlug == slug) return kind;
    }
    return null;
  }

  String get title => switch (this) {
        totalUsers => 'All users',
        activeMurid => 'Active murid',
        exercises => 'Published exercises',
        incomeMonthly => 'Monthly income',
        newStudentsMonthly => 'New student signups',
        voucherAlerts => 'Voucher alerts',
      };

  String get description => switch (this) {
        totalUsers =>
          'Every account on the platform — admin, guru, and murid.',
        activeMurid => 'Murid accounts that are currently active.',
        exercises =>
          'Practice worksheets that are published and visible to murid.',
        incomeMonthly =>
          'Revenue tracking is not connected yet. This view will show monthly income when billing is enabled.',
        newStudentsMonthly =>
          'Murid who registered in each of the last six months.',
        voucherAlerts =>
          'Class packages with two or fewer sessions remaining, or fully depleted.',
      };
}
