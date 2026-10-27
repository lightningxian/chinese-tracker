import '../../models/app_user.dart';

abstract final class AppConstants {
  /// User-facing product name (Figma, login, app title).
  static const brandName = 'Easy Study';

  /// Chinese centre name on official logo artwork.
  static const brandNameChinese = '易华文教中心';

  static const brandTagline =
      'Mandarin Education Center & China Education Consultant';

  /// Legacy internal / repo name — prefer [brandName] in UI.
  static const appName = brandName;

  static const usersCollection = 'users';
  static const lessonsCollection = 'lessons';
  static const exercisesCollection = 'exercises';
  static const exerciseAssignmentsCollection = 'exercise_assignments';
  static const exerciseLevelsCollection = 'exercise_levels';
  static const progressCollection = 'student_progress';
  static const quizzesCollection = 'quizzes';
  static const quizResultsCollection = 'quiz_results';
  static const exerciseResultsCollection = 'exercise_results';
  static const attendanceCollection = 'attendance';
  static const classSessionsCollection = 'class_sessions';
  static const studentClassTermsCollection = 'student_class_terms';
  static const notificationsCollection = 'notifications';
  static const teacherLinkCodesCollection = 'teacher_link_codes';
  static const teacherLinkStateCollection = 'teacher_link_state';
  static const invoicesCollection = 'invoices';
  static const gradesCollection = 'grades';
  static const questionBankCollection = 'question_bank';
  static const settingsCollection = 'settings';
  static const orgSettingsDoc = 'org';
  static const pricingSettingsDoc = 'pricing';
  static const auditLogsCollection = 'audit_logs';
  static const materialsCollection = 'materials';
  static const evaluationsCollection = 'evaluations';

  static const roleTeacher = 'teacher';
  static const roleStudent = 'student';
  static const roleAdmin = 'admin';
  static const roleParent = 'parent';

  /// Midtrans **Client** key (safe to ship in the app). The Server Key must
  /// live only in Cloud Functions secrets — never here. Pass at build time:
  /// `--dart-define=MIDTRANS_CLIENT_KEY=SB-Mid-client-...`.
  static const midtransClientKey = String.fromEnvironment(
    'MIDTRANS_CLIENT_KEY',
    defaultValue: '',
  );

  static bool get hasMidtransClientKey => midtransClientKey.isNotEmpty;

  /// Price (in whole IDR) for each sellable session package. Aligns with
  /// [termSizes]; adjust to your real pricing before going live.
  /// Fallback only: live prices come from `settings/pricing`
  /// (PricingSettings); admins edit them in Settings → Prices.
  static const packagePricesIdr = <int, int>{
    8: 2450000,
    16: 3950000,
  };

  static int priceForPackage(int packageSize) =>
      packagePricesIdr[packageSize] ?? 0;

  /// Non-session invoice item: HSK materials and textbook (course flyer).
  /// Mirrors BOOK_PRICE in functions/index.js (server-authoritative).
  static const bookItem = 'book';
  static const bookPriceIdr = 250000;
  static const bookItemLabel = 'HSK materials & book';

  /// Optional override for who owns content when an **admin** creates it.
  /// Demo teacher/student flows do **not** need this — they use per-teacher ids.
  static const contentOwnerId = String.fromEnvironment(
    'CONTENT_OWNER_ID',
    defaultValue: '',
  );

  /// Public URL of the downloadable Android APK, shown on the landing page.
  /// Fill this in once the APK is hosted (Firebase Hosting, GitHub Releases,
  /// etc.), or pass it at build time with
  /// `--dart-define=ANDROID_APK_URL=https://...`.
  static const androidApkUrl = String.fromEnvironment(
    'ANDROID_APK_URL',
    defaultValue: '',
  );

  /// Whether an Android APK download link is configured.
  static bool get hasAndroidApk => androidApkUrl.isNotEmpty;

  /// Single resolver for whose lessons/exercises a user should **read**.
  ///
  /// Chosen model: **per-teacher content libraries** (not one global library).
  /// - Student → linked [AppUser.teacherId]
  /// - Teacher → their own uid
  /// - Admin → [contentOwnerId] if set, else their uid (UI that spans the
  ///   whole centre should aggregate via each student's teacher instead)
  static String contentOwnerFor(AppUser user) {
    if (user.isStudent) {
      final tid = user.teacherId?.trim() ?? '';
      if (tid.isNotEmpty) return tid;
      return contentOwnerId;
    }
    if (user.isTeacher) return user.uid;
    return contentOwnerId.isNotEmpty ? contentOwnerId : user.uid;
  }

  /// Alias of [contentOwnerFor] for students (kept for call-site clarity).
  static String lessonsOwnerId(AppUser? user) {
    if (user == null) return contentOwnerId;
    return contentOwnerFor(user);
  }

  /// UID used when staff **create** lessons, exercises, or classes.
  /// Teachers use their own uid; admins may use [contentOwnerId] when set.
  static String contentTeacherId(AppUser user) {
    if (user.isTeacher) return user.uid;
    if (contentOwnerId.isNotEmpty) return contentOwnerId;
    return user.uid;
  }

  static String roleLabel(String? role) {
    return switch (role) {
      roleAdmin => 'Admin',
      roleTeacher => 'Guru',
      roleStudent => 'Murid',
      roleParent => 'Orang Tua',
      _ => 'User',
    };
  }

  static const hskLevels = [
    'HSK 1',
    'HSK 2',
    'HSK 3',
    'HSK 4',
    'HSK 5',
    'HSK 6',
  ];

  static const exerciseSkillCategories = [
    'Reading',
    'Listening',
    'Typing (Writing)',
    'Speaking',
  ];

  static const termSizes = [8, 16];

  static const defaultTermSize = 8;
}
