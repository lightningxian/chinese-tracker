import '../../models/admin_dashboard_stat_kind.dart';
import '../../models/teacher_dashboard_stat_kind.dart';

abstract final class ShellRouteUtils {
  static bool isAdminRoot(String location) => location == '/admin';

  static bool isAdminNested(String location) =>
      location.startsWith('/admin/') && location != '/admin';

  static bool isTeacherRoot(String location) => location == '/teacher';

  static bool isTeacherNested(String location) =>
      location.startsWith('/teacher/') && location != '/teacher';

  static int? adminTabIndexForLocation(String location) {
    if (location.contains('/dashboard/')) return 0;
    if (location.contains('/users')) return 1;
    if (location.contains('/exercise')) return 2;
    if (location.contains('/question-bank')) return 3;
    if (location.contains('/levels')) return 2;
    if (location.contains('/session')) return 4;
    if (location.contains('/vouchers')) return 5;
    if (location.contains('/price-list')) return 6;
    return null;
  }

  static int? teacherTabIndexForLocation(String location) {
    if (location.contains('/dashboard/')) return 0;
    if (location.contains('/student/')) return 1;
    if (location.contains('/exercise')) return 2;
    if (location.contains('/session')) return 3;
    if (location.contains('/calendar')) return 3;
    if (location.contains('/grades')) return 4;
    if (location.contains('/question-bank')) return 2;
    if (location.contains('/levels')) return 2;
    return null;
  }

  static String adminTitleForLocation(String location) {
    if (location.contains('/dashboard/stat/')) {
      final slug = location.split('/dashboard/stat/').last;
      final adminKind = AdminDashboardStatKind.fromRouteSlug(slug);
      if (adminKind != null) return adminKind.title;
      final centreKind = TeacherDashboardStatKind.fromRouteSlug(slug);
      if (centreKind != null) return centreKind.title;
    }
    if (location.endsWith('/users/new')) return 'New user';
    if (location.contains('/users/') && location.endsWith('/edit')) {
      return 'Edit user';
    }
    if (location.contains('/users/')) return 'Student';
    if (location.endsWith('/vouchers/new')) return 'New voucher';
    if (location.contains('/vouchers/') && location.endsWith('/edit')) {
      return 'Edit voucher';
    }
    if (location.endsWith('/exercise/new')) return 'New exercise';
    if (location.contains('/exercise/') && location.endsWith('/edit')) {
      return 'Edit exercise';
    }
    if (location.endsWith('/session/new')) return 'New class';
    if (location.contains('/session/') && location.endsWith('/edit')) {
      return 'Edit class';
    }
    if (location.contains('/session/') && !location.endsWith('/edit')) {
      return 'Class details';
    }
    if (location.endsWith('/question-bank')) return 'Question bank';
    if (location.endsWith('/levels')) return 'Levels';
    if (location.endsWith('/levels/new')) return 'New level';
    if (location.contains('/levels/') && location.endsWith('/edit')) {
      return 'Edit level';
    }
    if (location.contains('/quizzes')) return 'Quizzes';
    if (location.endsWith('/settings')) return 'Settings';
    if (location.endsWith('/price-list')) return 'Price list';
    if (location.endsWith('/audit-logs')) return 'Audit logs';
    if (location.endsWith('/materials')) return 'Materials';
    return 'Admin';
  }

  static String teacherTitleForLocation(String location) {
    if (location.contains('/dashboard/stat/')) {
      final slug = location.split('/dashboard/stat/').last;
      final kind = TeacherDashboardStatKind.fromRouteSlug(slug);
      if (kind != null) return kind.title;
    }
    if (location.contains('/student/')) return 'Student profile';
    if (location.endsWith('/exercise/new')) return 'New exercise';
    if (location.contains('/exercise/') && location.endsWith('/edit')) {
      return 'Edit exercise';
    }
    if (location.endsWith('/session/new')) return 'New class';
    if (location.contains('/session/') && location.endsWith('/edit')) {
      return 'Edit class';
    }
    if (location.contains('/session/') && !location.endsWith('/edit')) {
      return 'Class details';
    }
    if (location.endsWith('/calendar')) return 'Calendar';
    if (location.endsWith('/grades')) return 'Grades';
    if (location.endsWith('/question-bank')) return 'Question bank';
    if (location.endsWith('/levels')) return 'Levels';
    if (location.endsWith('/levels/new')) return 'New level';
    if (location.contains('/levels/') && location.endsWith('/edit')) {
      return 'Edit level';
    }
    if (location.contains('/quizzes')) return 'Quizzes';
    if (location.endsWith('/materials')) return 'Materials';
    return 'Guru';
  }
}
