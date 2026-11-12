import '../../l10n/generated/app_localizations.dart';
import '../../l10n/labels_classes.dart';
import '../../l10n/labels_reports.dart';
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

  static String adminTitleForLocation(AppLocalizations l, String location) {
    if (location.contains('/dashboard/stat/')) {
      final slug = location.split('/dashboard/stat/').last;
      final adminKind = AdminDashboardStatKind.fromRouteSlug(slug);
      if (adminKind != null) return adminKind.localizedTitle(l);
      final centreKind = TeacherDashboardStatKind.fromRouteSlug(slug);
      if (centreKind != null) return centreKind.localizedTitle(l);
    }
    if (location.endsWith('/users/new')) return l.routeTitleNewUser;
    if (location.contains('/users/') && location.endsWith('/edit')) {
      return l.routeTitleEditUser;
    }
    if (location.contains('/users/')) return l.routeTitleStudent;
    if (location.endsWith('/vouchers/new')) return l.routeTitleNewVoucher;
    if (location.contains('/vouchers/') && location.endsWith('/edit')) {
      return l.routeTitleEditVoucher;
    }
    if (location.endsWith('/exercise/new')) return l.routeTitleNewExercise;
    if (location.contains('/exercise/') && location.endsWith('/edit')) {
      return l.routeTitleEditExercise;
    }
    if (location.endsWith('/session/new')) return l.routeTitleNewClass;
    if (location.contains('/session/') && location.endsWith('/edit')) {
      return l.routeTitleEditClass;
    }
    if (location.contains('/session/') && !location.endsWith('/edit')) {
      return l.routeTitleClassDetails;
    }
    if (location.endsWith('/question-bank')) return l.routeTitleQuestionBank;
    if (location.endsWith('/levels')) return l.routeTitleLevels;
    if (location.endsWith('/levels/new')) return l.routeTitleNewLevel;
    if (location.contains('/levels/') && location.endsWith('/edit')) {
      return l.routeTitleEditLevel;
    }
    if (location.contains('/quizzes')) return l.routeTitleQuizzes;
    if (location.endsWith('/settings')) return l.routeTitleSettings;
    if (location.endsWith('/price-list')) return l.routeTitlePriceList;
    if (location.endsWith('/audit-logs')) return l.routeTitleAuditLogs;
    if (location.endsWith('/materials')) return l.routeTitleMaterials;
    return l.routeTitleAdmin;
  }

  static String teacherTitleForLocation(AppLocalizations l, String location) {
    if (location.contains('/dashboard/stat/')) {
      final slug = location.split('/dashboard/stat/').last;
      final kind = TeacherDashboardStatKind.fromRouteSlug(slug);
      if (kind != null) return kind.localizedTitle(l);
    }
    if (location.contains('/student/')) return l.routeTitleStudentProfile;
    if (location.endsWith('/exercise/new')) return l.routeTitleNewExercise;
    if (location.contains('/exercise/') && location.endsWith('/edit')) {
      return l.routeTitleEditExercise;
    }
    if (location.endsWith('/session/new')) return l.routeTitleNewClass;
    if (location.contains('/session/') && location.endsWith('/edit')) {
      return l.routeTitleEditClass;
    }
    if (location.contains('/session/') && !location.endsWith('/edit')) {
      return l.routeTitleClassDetails;
    }
    if (location.endsWith('/calendar')) return l.routeTitleCalendar;
    if (location.endsWith('/grades')) return l.routeTitleGrades;
    if (location.endsWith('/question-bank')) return l.routeTitleQuestionBank;
    if (location.endsWith('/levels')) return l.routeTitleLevels;
    if (location.endsWith('/levels/new')) return l.routeTitleNewLevel;
    if (location.contains('/levels/') && location.endsWith('/edit')) {
      return l.routeTitleEditLevel;
    }
    if (location.contains('/quizzes')) return l.routeTitleQuizzes;
    if (location.endsWith('/materials')) return l.routeTitleMaterials;
    return l.routeTitleTeacher;
  }
}
