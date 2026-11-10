// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonOk => 'OK';

  @override
  String get commonEmail => 'Email';

  @override
  String get commonPassword => 'Password';

  @override
  String get commonSignIn => 'Sign in';

  @override
  String get commonSignOut => 'Sign out';

  @override
  String get commonCreateNewAccount => 'Create new account';

  @override
  String get commonRememberDevice => 'Remember on this device';

  @override
  String get commonClassSession => 'Class session';

  @override
  String get commonViewClassCalendar => 'View class calendar';

  @override
  String get commonViewGrades => 'View grades & transcript';

  @override
  String get commonLearningMaterials => 'Learning materials';

  @override
  String get commonYourLevel => 'Your level';

  @override
  String get commonCodeHint => '6-character code';

  @override
  String get commonHskLevel => 'HSK level';

  @override
  String get commonLessonsPerTerm => 'Lessons per term';

  @override
  String commonLessonsPerTermOption(int count) {
    return '$count lessons per term';
  }

  @override
  String get commonCompleted => 'Completed';

  @override
  String get commonFull => 'Full';

  @override
  String commonSpotsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count spots left',
      one: '1 spot left',
    );
    return '$_temp0';
  }

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonStudent => 'Student';

  @override
  String get commonParent => 'Parent';

  @override
  String get languageRowLabel => 'Bahasa / Language';

  @override
  String get languageToggleIndonesian => 'Bahasa Indonesia';

  @override
  String get languageToggleEnglish => 'English';

  @override
  String get themeRowLabel => 'Appearance';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'Device';

  @override
  String get themeSystemHint =>
      'Device: follows your phone or computer setting.';

  @override
  String get authBrandHeadline => 'Learn Chinese,\nthe easy way.';

  @override
  String get teacherLinkCodeLabel => 'Teacher link code';

  @override
  String get teacherLinkCodeHelper =>
      'Ask your teacher for the current code (refreshes every 15 min)';

  @override
  String get teacherLinkCodeRequired => 'Enter your teacher link code';

  @override
  String get loginSubtitle => 'Tap an account to sign in';

  @override
  String get loginFailed => 'Sign in failed';

  @override
  String loginProfileLoadFailed(String code) {
    return 'Signed in, but your profile could not be loaded ($code). Check your connection and try again.';
  }

  @override
  String get loginRemoveAccountTitle => 'Remove account?';

  @override
  String loginRemoveAccountBody(String name) {
    return 'Remove $name from this device? You can sign in again later.';
  }

  @override
  String get loginRemove => 'Remove';

  @override
  String get loginResetTitle => 'Reset your password';

  @override
  String get loginResetBody =>
      'Enter your account email. We\'ll send a link to set a new password.';

  @override
  String get loginSendResetLink => 'Send reset link';

  @override
  String loginResetSent(String email) {
    return 'If $email has an account, a reset link is on its way. Check your inbox and spam folder.';
  }

  @override
  String get loginResetInvalidEmail =>
      'That email address doesn\'t look right. Check it and try again.';

  @override
  String get loginResetTooManyRequests =>
      'Too many attempts. Wait a few minutes and try again.';

  @override
  String get loginResetFailed => 'Couldn\'t send the reset link. Try again.';

  @override
  String get loginWithAnotherEmail => 'Sign in with another email';

  @override
  String get loginAnotherAccount => 'Another account';

  @override
  String get loginForgotPassword => 'Forgot password?';

  @override
  String get loginBackToAccountList => 'Back to account list';

  @override
  String get loginBackToTestLogin => 'Back to test login';

  @override
  String get loginNoSavedAccounts => 'No saved accounts yet';

  @override
  String get loginNoSavedAccountsHint =>
      'Sign in once and your account will appear here for quick access next time.';

  @override
  String get registerTitle => 'Create account';

  @override
  String get registerSubtitle => 'Join Easy Study as a student or parent';

  @override
  String get registerErrorEmailInUse =>
      'This email is already registered. Try Sign in instead.';

  @override
  String get registerErrorWeakPassword =>
      'Password is too weak. Use at least 6 characters.';

  @override
  String get registerErrorInvalidEmail => 'Invalid email address.';

  @override
  String get registerErrorOperationNotAllowed =>
      'Email/password sign-in is disabled in Firebase.';

  @override
  String registerErrorGeneric(String code) {
    return 'Registration failed ($code)';
  }

  @override
  String get registerErrorPermissionDenied =>
      'Firestore blocked this action. Publish firestore.rules from the project.';

  @override
  String registerErrorFirebase(String code) {
    return 'Firebase error ($code)';
  }

  @override
  String get registerEmailInvalid => 'Enter a valid email';

  @override
  String get registerPasswordTooShort => 'Minimum 6 characters';

  @override
  String get registerChildCodeLabel => 'Child access code';

  @override
  String get registerChildCodeHelper =>
      'Find this in your child\'s Profile under \'Parent access\'.';

  @override
  String get registerChildCodeRequired => 'Enter your child access code';

  @override
  String get registerSubmitParent => 'Register as parent';

  @override
  String get identityNameIndonesian => 'Indonesian name';

  @override
  String get identityNameIndonesianRequired => 'Indonesian name is required';

  @override
  String get identityNameChinese => 'Chinese name';

  @override
  String get identityNameChineseOptional => 'Chinese name (optional)';

  @override
  String get identityNameChineseRequired => 'Chinese name is required';

  @override
  String get identityWhatsapp => 'WhatsApp number';

  @override
  String get identityWhatsappOptional => 'WhatsApp number (optional)';

  @override
  String get identityWhatsappRequired => 'WhatsApp number is required';

  @override
  String get identityParentSection => 'Parent / guardian';

  @override
  String get identityParentSectionHint =>
      'Contact details for the student family.';

  @override
  String get identityParentName => 'Parent name';

  @override
  String get identityParentNameOptional => 'Parent name (optional)';

  @override
  String get identityParentNameRequired => 'Parent name is required';

  @override
  String get identityParentPhone => 'Parent telephone';

  @override
  String get identityParentPhoneOptional => 'Parent telephone (optional)';

  @override
  String get identityParentPhoneRequired => 'Parent telephone is required';

  @override
  String get completeProfileTitle => 'Complete your profile';

  @override
  String get completeProfileMissing =>
      'We found your login, but your profile data is missing.';

  @override
  String get completeProfileFailed => 'Could not complete profile';

  @override
  String get completeProfileSave => 'Save profile';

  @override
  String get studentNavHome => 'Home';

  @override
  String get studentNavMyClasses => 'My Classes';

  @override
  String get studentNavLessons => 'Lessons';

  @override
  String get studentNavProgress => 'Progress';

  @override
  String get navPayments => 'Payments';

  @override
  String get navProfile => 'Profile';

  @override
  String studentHomeGreeting(String name) {
    return 'Hello, $name';
  }

  @override
  String get studentHomeContinueLearning => 'Continue learning';

  @override
  String get studentHomeNoPracticeTitle => 'No practice yet';

  @override
  String get studentHomeNoPracticeSubtitle =>
      'Set your HSK level in Profile to unlock exercises, or wait for new practice to be published.';

  @override
  String studentHomeLevelPractice(String level) {
    return '$level practice';
  }

  @override
  String get studentHomeNextLesson => 'Next lesson';

  @override
  String studentHomeLessonMeta(String term, int order) {
    return '$term · Lesson $order';
  }

  @override
  String get studentHomeAllDoneTitle => 'All lessons done';

  @override
  String get studentHomeAllDoneSubtitle =>
      'Great work — you completed every available lesson.';

  @override
  String get studentHomeCompletedPractice => 'Completed practice';

  @override
  String get studentJoinTitle => 'Join class session';

  @override
  String get studentJoinHint =>
      'Pick an open class below. You stay joined until the teacher concludes it.';

  @override
  String get studentJoinNoSessionsTitle => 'No open sessions';

  @override
  String get studentJoinNoSessionsSubtitle =>
      'No class sessions are open right now. Check back later.';

  @override
  String get studentJoinPermissionDenied =>
      'Could not join: permission denied.';

  @override
  String studentJoinFailed(String code) {
    return 'Could not join ($code)';
  }

  @override
  String get studentJoinClassFullTitle => 'Class is full';

  @override
  String studentJoinClassFullBody(int capacity, int joined) {
    String _temp0 = intl.Intl.pluralLogic(
      capacity,
      locale: localeName,
      other: '$capacity students',
      one: '1 student',
    );
    return 'This class has reached its capacity of $_temp0 ($joined/$capacity joined). Try another session or check back later.';
  }

  @override
  String get studentJoinJoined => 'You joined this session';

  @override
  String get studentJoinLeftClass => 'You left this class';

  @override
  String studentJoinCount(int joined, int capacity) {
    return '$joined / $capacity joined';
  }

  @override
  String get studentJoinView => 'View';

  @override
  String get studentJoinLeave => 'Leave';

  @override
  String get studentJoinNoSessionsLeft => 'No sessions';

  @override
  String get studentJoinJoin => 'Join';

  @override
  String get studentLessonsNoContentTitle => 'No content yet';

  @override
  String get studentLessonsNoDemoData =>
      'No demo data yet — run scripts/seed_test_accounts.sh then python3 scripts/seed_report_demo_data.py';

  @override
  String get studentLessonsSetLevel =>
      'Set your HSK level in Profile to unlock practice and lessons.';

  @override
  String studentLessonsWillAppear(String level) {
    return 'Published $level exercises and lessons will appear here.';
  }

  @override
  String studentLessonsExercisesHeader(String level, int count) {
    return '$level exercises ($count)';
  }

  @override
  String get studentLessonsNoExercisesTitle => 'No exercises yet';

  @override
  String get studentLessonsNoExercisesSetLevel =>
      'Set your HSK level in Profile to see practice exercises.';

  @override
  String studentLessonsNoPublishedExercises(String level) {
    return 'No published $level exercises yet.';
  }

  @override
  String studentLessonsLevelTermInfo(String level, int count) {
    return '$level · $count lessons per term';
  }

  @override
  String studentLessonsTermHeader(String term, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lessons',
      one: '1 lesson',
    );
    return 'Term $term ($_temp0)';
  }

  @override
  String studentLessonsQuizScore(String score) {
    return 'Quiz: $score%';
  }

  @override
  String get studentMyClassesEmptyTitle => 'No classes joined yet';

  @override
  String get studentMyClassesEmptySubtitle =>
      'Go to Home and tap Join on an open class session.';

  @override
  String get studentMyClassesTapToSee => 'Tap to see who joined';

  @override
  String get studentPaymentsDisabledTitle => 'Payments are disabled';

  @override
  String get studentPaymentsDisabledSubtitle =>
      'Your centre is not collecting payments through the app right now. Contact your teacher about session packages.';

  @override
  String get studentPaymentsInvoices => 'Invoices';

  @override
  String get studentPaymentsNoInvoices =>
      'No invoices yet. Your teacher will bill you for session packages here.';

  @override
  String studentPaymentsSessionsRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions remaining',
      one: '1 session remaining',
    );
    return '$_temp0';
  }

  @override
  String get studentPaymentsQuotaHint =>
      'Sessions are added automatically when a payment is confirmed.';

  @override
  String get studentProgressNoProgressTitle => 'No progress yet';

  @override
  String get studentProgressNoProgressSubtitle =>
      'Complete a lesson or quiz to see your history here.';

  @override
  String get studentProgressNoLessonsTitle => 'No lessons yet';

  @override
  String studentProgressNoLessonsSubtitle(String level) {
    return 'No lessons for $level yet.';
  }

  @override
  String get studentProgressYourHskLevel => 'your HSK level';

  @override
  String get studentProgressTermSize => 'Term size';

  @override
  String get studentProgressStartFirst =>
      'Start your first lesson to track progress';

  @override
  String get studentProgressTermPlan => 'Your term plan';

  @override
  String get studentProgressCurrentTerm => 'Current term';

  @override
  String get studentProfileUpdated => 'Profile updated';

  @override
  String get studentProfilePersonalTitle => 'Personal information';

  @override
  String get studentProfilePersonalSubtitle =>
      'Indonesian and Chinese names, WhatsApp, and parent contacts.';

  @override
  String get studentProfileLearningTitle => 'Learning';

  @override
  String get studentProfileLearningSubtitle =>
      'Your HSK level controls which practice exercises you see.';

  @override
  String studentProfileCodeFailed(String error) {
    return 'Could not generate code: $error';
  }

  @override
  String get studentProfileParentAccessTitle => 'Parent access';

  @override
  String get studentProfileParentAccessBody =>
      'Share this code with a parent so they can register and follow your progress (read-only).';

  @override
  String get studentProfileCodeCopied => 'Code copied';

  @override
  String get studentProfileShowParentCode => 'Show parent access code';

  @override
  String studentClassLeaveFailed(String code) {
    return 'Could not leave class ($code)';
  }

  @override
  String get studentClassNotFound => 'Class not found';

  @override
  String get studentClassYourTeacher => 'Your teacher';

  @override
  String studentClassTimeAndTeacher(String time, String teacher) {
    return '$time · Teacher: $teacher';
  }

  @override
  String studentClassStudentsJoined(int joined, int capacity) {
    return '$joined/$capacity students joined';
  }

  @override
  String get studentClassLeaveClass => 'Leave class';

  @override
  String studentClassWhoJoined(int count) {
    return 'Who joined ($count)';
  }

  @override
  String get studentClassNoneJoined => 'No students have joined yet.';

  @override
  String studentClassYou(String name) {
    return '$name (you)';
  }

  @override
  String get studentClassJoinedFromApp => 'Joined from app';

  @override
  String get studentClassAddedByTeacher => 'Added by teacher';

  @override
  String get lessonDetailTitle => 'Lesson';

  @override
  String get lessonDetailNotFoundTitle => 'Lesson not found';

  @override
  String get lessonDetailNotFoundSubtitle =>
      'This lesson may have been removed.';

  @override
  String get lessonDetailVocabulary => 'Vocabulary & notes';

  @override
  String get lessonDetailStartQuiz => 'Start quiz';

  @override
  String get parentNavOverview => 'Overview';

  @override
  String get parentNavCalendar => 'Calendar';

  @override
  String get parentNoChildrenTitle => 'No children linked';

  @override
  String get parentNoChildrenSubtitle =>
      'Ask your centre admin to link your account to your child, or register again with your child access code.';

  @override
  String get parentChildLabel => 'Child';

  @override
  String get parentOverviewSessionsRemaining => 'Sessions remaining';

  @override
  String get parentOverviewLessonsDone => 'Lessons done';

  @override
  String get parentOverviewAvgScore => 'Avg score';

  @override
  String get parentOverviewRecentGrades => 'Recent grades';

  @override
  String get parentOverviewNoGrades => 'No graded practice yet.';

  @override
  String get parentOverviewPractice => 'Practice';

  @override
  String get parentOverviewRecentClasses => 'Recent classes';

  @override
  String get parentOverviewNoClasses => 'No classes attended yet.';

  @override
  String get parentPaymentsEmptyTitle => 'No invoices';

  @override
  String get parentPaymentsEmptySubtitle =>
      'Invoices for your child will appear here.';

  @override
  String get parentProfileRole => 'Orang Tua (Parent)';

  @override
  String get parentProfileLinkedChildren => 'Linked children';

  @override
  String get parentProfileNoChildren =>
      'No children linked yet. Ask your admin to link your account.';
}
