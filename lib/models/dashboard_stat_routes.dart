class DashboardStatRoutes {
  const DashboardStatRoutes({
    required this.studentDetail,
    this.sessionDetail,
    this.exerciseEdit,
    this.userEdit,
    this.voucherEdit,
  });

  final String Function(String studentId) studentDetail;
  final String Function(String sessionId)? sessionDetail;
  final String Function(String exerciseId)? exerciseEdit;
  final String Function(String userId)? userEdit;
  final String Function(String voucherId)? voucherEdit;

  static const teacher = DashboardStatRoutes(
    studentDetail: _teacherStudent,
    sessionDetail: _teacherSession,
  );

  static const admin = DashboardStatRoutes(
    studentDetail: _adminUserEdit,
    sessionDetail: _adminSession,
    exerciseEdit: _adminExerciseEdit,
    userEdit: _adminUserEdit,
    voucherEdit: _adminVoucherEdit,
  );

  static String _teacherStudent(String id) => '/teacher/student/$id';
  static String _teacherSession(String id) => '/teacher/session/$id';
  static String _adminUserEdit(String id) => '/admin/users/$id/edit';
  static String _adminSession(String id) => '/admin/session/$id';
  static String _adminExerciseEdit(String id) => '/admin/exercise/$id/edit';
  static String _adminVoucherEdit(String id) => '/admin/vouchers/$id/edit';
}
