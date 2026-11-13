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
  String get pushRowLabel => 'Push notifications';

  @override
  String get pushRowHint =>
      'Reminders on this device when something is due or graded.';

  @override
  String get pushRowBlocked =>
      'Notifications are blocked in the browser or phone settings.';

  @override
  String get pushEnableFailed => 'Could not turn on notifications. Try again.';

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
  String get themeSystem => 'System';

  @override
  String get themeSystemHint =>
      'System: follows your phone or computer setting.';

  @override
  String get textSizeRowLabel => 'Text size';

  @override
  String get textSizeNormal => 'Normal';

  @override
  String get textSizeBig => 'Big';

  @override
  String get textSizeBigger => 'Bigger';

  @override
  String get appearanceMenuTooltip => 'Appearance: dark mode and text size';

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
  String get studentNavMyClasses => 'History';

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
  String get studentHomeSessionsLeft => 'Sessions left';

  @override
  String get studentHomeExercisesDone => 'Exercises done';

  @override
  String get studentHomeAvgScore => 'Avg. score';

  @override
  String studentHomeStreak(int days) {
    return '$days-day streak';
  }

  @override
  String studentHomeBest(int score) {
    return 'best $score%';
  }

  @override
  String studentHomeUntil(String date) {
    return 'until $date';
  }

  @override
  String get studentHomeNoVoucher => 'no voucher yet';

  @override
  String studentHomeSeeAll(int count) {
    return 'See all ($count)';
  }

  @override
  String studentHomeSeeScores(int count) {
    return '$count done · see your scores';
  }

  @override
  String get studentHomeQuickCalendar => 'Calendar';

  @override
  String get studentHomeQuickGrades => 'Grades';

  @override
  String get studentHomeQuickMaterials => 'Materials';

  @override
  String get studentHomeQuickHistory => 'History';

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
  String get historyVouchersTitle => 'Your vouchers';

  @override
  String get historyNoVouchers =>
      'No voucher yet. After you pay for a package the admin adds it here.';

  @override
  String historyVoucherTitle(int sessions) {
    return '$sessions-session voucher';
  }

  @override
  String historyValid(String start, String end) {
    return 'Valid $start – $end';
  }

  @override
  String get historyStatusActive => 'Active';

  @override
  String get historyStatusUsedUp => 'Used up';

  @override
  String get historyStatusExpired => 'Expired';

  @override
  String historySessionsUsed(int used, int total) {
    return '$used of $total sessions used';
  }

  @override
  String historyRemaining(int count) {
    return '$count left';
  }

  @override
  String historyShowSessions(int count) {
    return 'Show classes ($count)';
  }

  @override
  String get historyHideSessions => 'Hide classes';

  @override
  String get historyNoSessionsYet =>
      'No class has been charged to this voucher yet.';

  @override
  String get historyAllClasses => 'All classes';

  @override
  String historyClassesCount(int count) {
    return '$count classes';
  }

  @override
  String get attendancePresent => 'Present';

  @override
  String get attendanceExcused => 'Excused';

  @override
  String get attendanceAbsent => 'Absent';

  @override
  String get attendanceJoined => 'Joined';

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
  String studentPaymentsParentHandles(String name) {
    return 'Payments are handled by $name.';
  }

  @override
  String get studentPaymentsParentHandlesHint =>
      'Your parent sees the same invoices and can pay them. You can still pay one yourself below if needed.';

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
  String get studentProgressLessons => 'Lessons';

  @override
  String get studentProgressExercises => 'Exercises';

  @override
  String get studentProgressAttempts => 'Attempts';

  @override
  String get studentProgressAvgScore => 'Avg. score';

  @override
  String get studentProgressBestScore => 'Best score';

  @override
  String get studentProgressNoExercisesTitle => 'No exercises finished yet';

  @override
  String get studentProgressNoExercisesSubtitle =>
      'Finish an exercise from Home or Lessons and your scores will appear here.';

  @override
  String resultCorrectOf(int correct, int total) {
    return '$correct/$total correct';
  }

  @override
  String get commonExerciseFallback => 'Exercise';

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
  String get parentOverviewClassHistory => 'Classes and vouchers';

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

  @override
  String get exercisePlayNotAvailableTitle => 'Exercise not available';

  @override
  String get exercisePlayNotAvailableSubtitle =>
      'This exercise has not been assigned to you. Ask your teacher.';

  @override
  String get exercisePlayLegacyTitle => 'Old exercise format';

  @override
  String get exercisePlayLegacySubtitle =>
      'This exercise was made before the question bank and can no longer be played. Ask your teacher for a new one.';

  @override
  String get exercisePlayLoadFailedTitle => 'Could not load the exercise';

  @override
  String get exercisePlayNotFoundTitle => 'Exercise not found';

  @override
  String get exercisePlayNotFoundSubtitle =>
      'This exercise may have been removed.';

  @override
  String get exercisePlayNoQuestionsTitle => 'No questions yet';

  @override
  String get exercisePlayNoQuestionsSubtitle =>
      'Your teacher has not added questions to this exercise.';

  @override
  String get exercisePlayChecking => 'Checking your answers…';

  @override
  String get exercisePlayCouldNotSubmitTitle => 'Could not submit';

  @override
  String get exercisePlayCouldNotSubmitMessage => 'Could not submit.';

  @override
  String get exercisePlayCheckConnection =>
      'Check your connection and try again.';

  @override
  String get exercisePlayTryAgain => 'Try again';

  @override
  String get exercisePlayDone => 'Done';

  @override
  String get exercisePlayTimeUpSubtitle =>
      'Time\'s up. The answers you gave were submitted.';

  @override
  String get exercisePlayReview => 'Review';

  @override
  String get exercisePlaySubmitNowTitle => 'Submit now?';

  @override
  String exercisePlayUnansweredWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count questions have no answer yet. They will count as wrong.',
      one: '1 question has no answer yet. It will count as wrong.',
    );
    return '$_temp0';
  }

  @override
  String get exercisePlayKeepAnswering => 'Keep answering';

  @override
  String get exercisePlaySubmit => 'Submit';

  @override
  String exercisePlaySentenceOf(int current, int total) {
    return 'Sentence $current of $total';
  }

  @override
  String exercisePlayBlankOf(int current, int total) {
    return 'Blank $current of $total';
  }

  @override
  String exercisePlayMatchOf(int current, int total) {
    return 'Match $current of $total';
  }

  @override
  String exercisePlayQuestionOf(int current, int total) {
    return 'Question $current of $total';
  }

  @override
  String exercisePlayAnsweredOf(int answered, int total) {
    return '$answered of $total answered';
  }

  @override
  String get exercisePlayComposePrompt =>
      'Arrange the words to form a correct sentence';

  @override
  String get exercisePlayComposeHint =>
      'Tap words below to build your sentence';

  @override
  String get exercisePlayComposeEmpty => 'Your sentence appears here…';

  @override
  String get exercisePlayWordBank => 'Word bank';

  @override
  String get exercisePlayPictureSentencePrompt =>
      'Write a sentence that uses this word:';

  @override
  String get exercisePlayClozeLabel => 'Choose the word for the blank';

  @override
  String get exercisePlayPromptLabel => 'Prompt';

  @override
  String get exercisePlayChooseResponse => 'Choose the best response';

  @override
  String get exercisePlayBack => 'Back';

  @override
  String get exercisePlaySubmitAnswers => 'Submit answers';

  @override
  String get exercisePlayNextSentence => 'Next sentence';

  @override
  String get exercisePlayNextMatch => 'Next match';

  @override
  String get exercisePlayNextQuestion => 'Next question';

  @override
  String get exercisePlaySubmitAllNow => 'Submit all answers now';

  @override
  String exercisePlayReviewPictureSentence(String keyword) {
    return 'Write a sentence with \"$keyword\"';
  }

  @override
  String get exercisePlayReviewCompose => 'Arrange the words into a sentence';

  @override
  String exercisePlayReviewQuestionNumber(int number) {
    return 'Question $number';
  }

  @override
  String exercisePlayReviewKeywordKey(String keyword) {
    return 'A sentence that uses \"$keyword\"';
  }

  @override
  String get exercisePlayNotAnswered => 'Not answered';

  @override
  String exercisePlayYourAnswer(String answer) {
    return 'Your answer: $answer';
  }

  @override
  String exercisePlayCorrectAnswer(String answer) {
    return 'Correct answer: $answer';
  }

  @override
  String get materialsTitle => 'Materials';

  @override
  String get materialsAdd => 'Add material';

  @override
  String get materialsEmptyTitle => 'No materials yet';

  @override
  String get materialsEmptyStudentSubtitle =>
      'Published materials from your teacher will appear here.';

  @override
  String get materialsEmptyStaffSubtitle =>
      'Tap \"Add material\" to upload a file or add a resource.';

  @override
  String get materialsOpenFailed => 'Could not open the file.';

  @override
  String get materialsEdit => 'Edit';

  @override
  String get materialsStatusPublished => 'Published';

  @override
  String get materialsStatusDraft => 'Draft';

  @override
  String get materialsEditTitle => 'Edit material';

  @override
  String get materialsFieldTitle => 'Title';

  @override
  String get materialsTitleRequired => 'Enter a title';

  @override
  String get materialsFieldLevel => 'Level (optional)';

  @override
  String get materialsFieldSkill => 'Skill (optional)';

  @override
  String get materialsFieldTags => 'Tags (comma-separated)';

  @override
  String get materialsReplaceFile => 'Replace file';

  @override
  String get materialsUploadFile => 'Upload file (optional)';

  @override
  String get materialsPublishedHint => 'Visible to students and parents.';

  @override
  String get materialsSaveChanges => 'Save changes';

  @override
  String get materialsDelete => 'Delete';

  @override
  String get materialsDeleteTitle => 'Delete material?';

  @override
  String materialsDeleteBody(String title) {
    return 'Delete \"$title\"? This cannot be undone.';
  }

  @override
  String scoreSummaryCorrectOf(int correct, int total) {
    return '$correct of $total correct';
  }

  @override
  String get scoreSummaryPassed => 'Great work!';

  @override
  String get scoreSummaryKeepPracticing =>
      'Keep practicing — you\'re improving.';

  @override
  String get statusPillOpen => 'Open';

  @override
  String get statusPillClosed => 'Closed';

  @override
  String get statusPillConcluded => 'Concluded';

  @override
  String get tableToolsExportCsv => 'Export CSV';

  @override
  String tableToolsDownloadingRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Downloading $count rows as CSV…',
      one: 'Downloading 1 row as CSV…',
    );
    return '$_temp0';
  }

  @override
  String tableToolsCopiedRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Copied $count rows as CSV to the clipboard.',
      one: 'Copied 1 row as CSV to the clipboard.',
    );
    return '$_temp0';
  }

  @override
  String tableToolsSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
      one: '1 selected',
    );
    return '$_temp0';
  }

  @override
  String get tableToolsClear => 'Clear';

  @override
  String get adminDashTotalUsers => 'Total users';

  @override
  String adminDashUsersBreakdown(int students, int teachers) {
    return '$students murid · $teachers guru';
  }

  @override
  String get adminDashActiveMurid => 'Active murid';

  @override
  String get adminDashIncomePerMonth => 'Income / mo';

  @override
  String adminDashNoPaymentsInMonth(String month) {
    return 'No payments in $month';
  }

  @override
  String adminDashPaymentsInMonth(int count, String month) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments in $month',
      one: '1 payment in $month',
    );
    return '$_temp0';
  }

  @override
  String get adminDashNeedsAttention => 'Needs attention';

  @override
  String get adminDashAllCaughtUpNoAlerts =>
      'All caught up — no voucher alerts right now.';

  @override
  String get adminDashFinancialSummary => 'Financial summary';

  @override
  String get adminDashRevenueThisMonth => 'Revenue this month';

  @override
  String get adminDashPendingPayments => 'Pending payments';

  @override
  String get adminDashVouchersWithoutPayment => 'Vouchers without payment';

  @override
  String get adminDashActiveVouchersNoInvoice =>
      'Active vouchers with no invoice';

  @override
  String get adminDashPendingToChase => 'Pending payments to chase';

  @override
  String get adminDashOverdue => 'overdue';

  @override
  String adminDashDue(String date) {
    return 'due $date';
  }

  @override
  String get adminDashNoPaymentsYet => 'No payments recorded yet.';

  @override
  String get adminDashRecentPayments => 'Recent payments';

  @override
  String get adminDashNewStudentsPerMonth => 'New students / month';

  @override
  String get adminDashQuickActions => 'Quick actions';

  @override
  String get adminDashNewExercise => 'New exercise';

  @override
  String get adminDashNewClass => 'New class';

  @override
  String adminDashVoucherDepleted(String name) {
    return '$name — voucher depleted';
  }

  @override
  String adminDashVoucherLowBalance(String name) {
    return '$name — low balance';
  }

  @override
  String get adminDashStatAllUsersTitle => 'All users';

  @override
  String get adminDashStatAllUsersDesc =>
      'Every account on the platform — admin, guru, and murid.';

  @override
  String get adminDashStatActiveMuridDesc =>
      'Murid accounts that are currently active.';

  @override
  String get adminDashStatExercisesTitle => 'Published exercises';

  @override
  String get adminDashStatExercisesDesc =>
      'Practice worksheets that are published and visible to murid.';

  @override
  String get adminDashStatIncomeTitle => 'Monthly income';

  @override
  String get adminDashStatIncomeDesc =>
      'Payments received each month (invoices marked paid, by the date they were paid), for the last twelve months.';

  @override
  String get adminDashStatSignupsTitle => 'New student signups';

  @override
  String get adminDashStatSignupsDesc =>
      'Murid who registered in each of the last six months.';

  @override
  String get adminDashStatVoucherAlertsTitle => 'Voucher alerts';

  @override
  String get adminDashStatVoucherAlertsDesc =>
      'Class packages with two or fewer sessions remaining, or fully depleted.';

  @override
  String get adminDashNoActiveMurid => 'No active murid';

  @override
  String get adminDashActiveAccountsAppear =>
      'Active student accounts will appear here.';

  @override
  String adminDashMuridCount(int count) {
    return '$count murid';
  }

  @override
  String adminDashGuruCount(int count) {
    return '$count guru';
  }

  @override
  String adminDashAdminCount(int count) {
    return '$count admin';
  }

  @override
  String adminDashInactiveCount(int count) {
    return '$count inactive';
  }

  @override
  String get adminDashNoUsers => 'No users';

  @override
  String get adminDashUsersAppear =>
      'Users will appear here after registration.';

  @override
  String get adminDashInactive => 'Inactive';

  @override
  String get adminDashNoPublishedExercises => 'No published exercises';

  @override
  String get adminDashPublishFromTab =>
      'Publish exercises from the Exercises tab.';

  @override
  String adminDashQuestionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count questions',
      one: '1 question',
    );
    return '$_temp0';
  }

  @override
  String get adminDashPublished => 'Published';

  @override
  String get adminDashNoSignups => 'No student signups yet';

  @override
  String get adminDashSignupsAppear =>
      'New murid registrations will appear here.';

  @override
  String get adminDashAllCaughtUp => 'All caught up';

  @override
  String get adminDashNoVoucherAlerts => 'No voucher alerts right now.';

  @override
  String get adminDashNoPaymentsTwelveMonths =>
      'No payments in the last twelve months';

  @override
  String get adminDashPaymentsShowHint =>
      'Payments show here once an invoice is marked paid in Payments.';

  @override
  String adminDashPaymentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments',
      one: '1 payment',
    );
    return '$_temp0';
  }

  @override
  String get adminReportsTitle => 'Reports';

  @override
  String adminReportsLoadFailed(String error) {
    return 'Could not load report data: $error';
  }

  @override
  String adminReportsSubtitle(String month) {
    return 'Live numbers for $month. Each PDF covers the last 6 months.';
  }

  @override
  String get adminReportsSectionClasses => 'Classes & teachers';

  @override
  String get adminReportsSectionMoney => 'Money';

  @override
  String get adminReportsSectionPlatform => 'Platform exports';

  @override
  String get adminReportsPdf => 'PDF';

  @override
  String get adminReportsAttendanceTitle => 'Attendance per student';

  @override
  String get adminReportsAttendanceDesc =>
      'Hadir / Izin / Alpa for every student, month by month.';

  @override
  String get adminReportsAlpa => 'Alpa';

  @override
  String get adminReportsRetentionTitle => 'New students & retention';

  @override
  String get adminReportsRetentionDesc =>
      'Sign-ups per month and how many are still active today.';

  @override
  String get adminReportsNewThisMonth => 'New this month';

  @override
  String get adminReportsRetention => 'Retention';

  @override
  String get adminReportsProgressTitle => 'Progress per HSK level';

  @override
  String get adminReportsProgressDesc =>
      'Exercises assigned and done, average best score, no activity.';

  @override
  String get adminReportsDone => 'Done';

  @override
  String get adminReportsNoActivity => 'No activity';

  @override
  String get adminReportsOverdueHomeworkTitle => 'Overdue homework';

  @override
  String get adminReportsOverdueHomeworkDesc =>
      'Past-due assignments without a submission, per teacher.';

  @override
  String get adminReportsOpen => 'Open';

  @override
  String get adminReportsTeachers => 'Teachers';

  @override
  String get adminReportsFillRateTitle => 'Class fill rate';

  @override
  String get adminReportsFillRateDesc =>
      'Seats taken against capacity, per month and per class.';

  @override
  String get adminReportsClasses => 'Classes';

  @override
  String get adminReportsEmpty => 'Empty';

  @override
  String get adminReportsTeacherRecapTitle => 'Teacher recap';

  @override
  String get adminReportsTeacherRecapDesc =>
      'Classes, teaching hours, students taught and attendance per teacher.';

  @override
  String get adminReportsClassesHeld => 'Classes held';

  @override
  String get adminReportsHours => 'Hours';

  @override
  String get adminReportsTermAlertsTitle => 'Term balance alerts';

  @override
  String get adminReportsTermAlertsDesc =>
      'Who to call: 2 or fewer sessions left, expiring within 7 days, expired.';

  @override
  String get adminReportsLowBalance => 'Low balance';

  @override
  String get adminReportsExpiring => 'Expiring';

  @override
  String get adminReportsRevenueTitle => 'Revenue per month';

  @override
  String get adminReportsRevenueDesc =>
      'Paid invoices by item, plus every unpaid invoice and how overdue it is.';

  @override
  String get adminReportsThisMonth => 'This month';

  @override
  String get adminReportsUnpaid => 'Unpaid';

  @override
  String get adminReportsUserRosterTitle => 'User roster';

  @override
  String get adminReportsUserRosterDesc =>
      'Every account with role, join date and status.';

  @override
  String get adminReportsUsers => 'Users';

  @override
  String get adminReportsGrowthTitle => 'Registration & growth';

  @override
  String get adminReportsGrowthDesc =>
      'New murid per month and current HSK level bands.';

  @override
  String get adminReportsLastSixMonths => 'Last 6 months';

  @override
  String get adminReportsVouchersTitle => 'Vouchers & packages';

  @override
  String get adminReportsVouchersDesc =>
      'All session packages with codes and balance.';

  @override
  String get adminReportsPackages => 'Packages';

  @override
  String get adminReportsIssuedThisMonth => 'Issued this month';

  @override
  String get adminReportsWorksheetInventoryTitle => 'Worksheet inventory';

  @override
  String get adminReportsWorksheetInventoryDesc =>
      'Practice worksheets by HSK level and skill section.';

  @override
  String get adminReportsWorksheets => 'Worksheets';

  @override
  String get adminReportsDraft => 'Draft';

  @override
  String get adminPriceTitle => 'Price list';

  @override
  String get adminPriceSaved => 'Price list saved';

  @override
  String adminPriceSaveFailed(String error) {
    return 'Could not save: $error';
  }

  @override
  String adminPriceRemoveTitle(String name) {
    return 'Remove \"$name\"?';
  }

  @override
  String get adminPriceRemoveBody =>
      'Invoices already created keep their price. New invoices can no longer pick this item.';

  @override
  String get adminPriceVoucherValidity => 'Voucher validity';

  @override
  String get adminPriceValidityDaysLabel => 'Days a paid voucher stays valid';

  @override
  String get adminPriceValidityHelper => 'Flyer: 2 months = 60 days';

  @override
  String get adminPriceSave => 'Save';

  @override
  String get adminPriceIntro =>
      'Everything a payment can be for. Create invoice picks a row from this list and the server charges exactly this price. Rows that give class sessions become vouchers when paid.';

  @override
  String get adminPriceItems => 'Items';

  @override
  String get adminPriceAddItem => 'Add item';

  @override
  String adminPriceGives(String what) {
    return 'Gives $what';
  }

  @override
  String get adminPriceEdit => 'Edit';

  @override
  String adminPriceValiditySummary(int days, String months) {
    return '$days days from payment ($months months)';
  }

  @override
  String adminPriceLastSaved(String date) {
    return 'Last saved $date';
  }

  @override
  String get adminPriceNewItem => 'New item';

  @override
  String get adminPriceEditItem => 'Edit item';

  @override
  String get adminPriceName => 'Name';

  @override
  String get adminPriceNameHint => 'e.g. 8 class sessions';

  @override
  String get adminPriceNameRequired => 'Enter a name';

  @override
  String get adminPricePriceLabel => 'Price (Rp, whole number)';

  @override
  String get adminPricePriceInvalid => 'Enter a price above 0';

  @override
  String get adminPriceWhatItGives => 'What it gives';

  @override
  String get adminPriceSessionsLabel => 'Number of class sessions';

  @override
  String get adminPriceSessionsInvalid => 'Enter 1 or more';

  @override
  String get adminPriceKindSessions => 'Class sessions';

  @override
  String get adminPriceKindBook => 'Book / materials';

  @override
  String get adminPriceKindRegistration => 'Registration';

  @override
  String get adminPriceKindOther => 'Other';

  @override
  String get orgSettingsTitle => 'Settings';

  @override
  String get orgSettingsFeatures => 'Features';

  @override
  String get orgSettingsPaymentsHint =>
      'Show invoices and the pay/checkout UI for students and admins. Turn off to hide billing entirely.';

  @override
  String get orgSettingsEvalOpen => 'Evaluation forms open';

  @override
  String get orgSettingsEvalOpenHint =>
      'Allow teachers to create or edit semester evaluations. Close between terms to freeze the forms.';

  @override
  String get orgSettingsTeacherReschedule => 'Teachers can reschedule';

  @override
  String get orgSettingsTeacherRescheduleHint =>
      'Let teachers edit their own class sessions. Turn off so only admins can reschedule.';

  @override
  String get orgSettingsAccounts => 'Accounts';

  @override
  String get orgSettingsRequireEmailVerification =>
      'Require email verification';

  @override
  String get orgSettingsRequireEmailVerificationHint =>
      'Stored preference for future sign-up flows. Not enforced automatically yet.';

  @override
  String get orgSettingsAutoPasswords => 'Auto-generate staff passwords';

  @override
  String get orgSettingsAutoPasswordsHint =>
      'Stored preference for future staff creation. Not enforced automatically yet.';

  @override
  String get orgSettingsPrices => 'Prices';

  @override
  String get orgSettingsPriceListHint =>
      'What a payment can be for: sessions, book, registration. Invoices pick from this list.';

  @override
  String get orgSettingsAdministration => 'Administration';

  @override
  String get orgSettingsAuditLogsHint =>
      'Money and permission events, newest first.';

  @override
  String get orgSettingsMaterialsHint =>
      'Shared files for students and parents.';

  @override
  String orgSettingsLastUpdated(String date) {
    return 'Last updated $date';
  }

  @override
  String get auditLogTitle => 'Audit logs';

  @override
  String get auditLogEmptyTitle => 'No activity yet';

  @override
  String get auditLogEmptySubtitle =>
      'Money movements and permission changes will be recorded here automatically.';

  @override
  String get cohortNoStudentsTitle => 'No students yet';

  @override
  String get cohortNoStudentsSubtitle =>
      'Students appear here after they register in the app.';

  @override
  String get cohortNoMatch => 'No students match this search.';

  @override
  String get cohortLevel => 'Level';

  @override
  String get cohortThisTerm => 'This term';

  @override
  String get cohortHomework => 'Homework';

  @override
  String get cohortQuizAvg => 'Quiz avg';

  @override
  String get cohortSessionsLeft => 'Sessions left';

  @override
  String get cohortLastActive => 'Last active';

  @override
  String cohortStudentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count students',
      one: '1 student',
    );
    return '$_temp0';
  }

  @override
  String cohortShownCount(int count) {
    return '$count shown';
  }

  @override
  String cohortNeedAttentionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count need attention',
      one: '1 needs attention',
    );
    return '$_temp0';
  }

  @override
  String get cohortSearchStudents => 'Search students';

  @override
  String get cohortAllLevels => 'All levels';

  @override
  String cohortQuizPercent(int score) {
    return 'Quiz $score%';
  }

  @override
  String get cohortCentreStatistics => 'Centre statistics';

  @override
  String get cohortHomeworkDone => 'Homework done';

  @override
  String get cohortOverdue => 'Overdue';

  @override
  String get cohortAvgQuiz => 'Avg quiz';

  @override
  String get cohortAvgPractice => 'Avg practice';

  @override
  String get cohortClassesThisWeek => 'Classes this week';

  @override
  String get cohortNeedAttention => 'Need attention';

  @override
  String get cohortStudents => 'Students';

  @override
  String get cohortRosterCsvDownloaded => 'Roster CSV downloaded';

  @override
  String get cohortRosterCsvCopied => 'Roster CSV copied to clipboard';

  @override
  String get cohortReportsSubtitle =>
      'Export centre summaries and worksheet inventory for your records.';

  @override
  String get cohortCentreSummary => 'Centre summary';

  @override
  String get cohortCentreSummaryDesc =>
      'Homework completion, quiz averages, sessions remaining, and students needing attention.';

  @override
  String cohortStudentsTracked(int count) {
    return 'Students tracked: $count';
  }

  @override
  String cohortWorksheetsPublished(int count) {
    return 'Worksheets published: $count';
  }

  @override
  String get cohortStudentRoster => 'Student roster';

  @override
  String get cohortStudentRosterDesc =>
      'Full student list with progress, homework, and session balance. Spreadsheet export.';

  @override
  String cohortStudentsPreview(int count) {
    return 'Students: $count';
  }

  @override
  String get cohortColumnsPreview => 'Columns: level, homework, quiz, sessions';

  @override
  String get cohortWorksheetInventoryDesc =>
      'All practice worksheets produced, grouped by HSK level and skill section (Reading, Listening, etc.).';

  @override
  String cohortTotalWorksheets(int count) {
    return 'Total worksheets: $count';
  }

  @override
  String get teacherActivityThisWeek => 'Activity this week';

  @override
  String get teacherActivityThisWeekSubtitle =>
      'Lesson completions and practice submissions';

  @override
  String get teacherActivityHomeworkOverview => 'Homework overview';

  @override
  String get teacherActivityQuickView => 'Quick view';

  @override
  String get teacherActivityNoHomeworkAssign =>
      'No homework assigned yet. Assign practice from the Exercises tab.';

  @override
  String teacherActivityToDo(int count) {
    return '$count to do';
  }

  @override
  String teacherActivityOverdueCount(int count) {
    return '$count overdue';
  }

  @override
  String teacherActivityDoneCount(int count) {
    return '$count done';
  }

  @override
  String teacherActivityAssignmentsCompleted(int done, int total) {
    return '$done/$total assignments completed';
  }

  @override
  String get teacherActivityNoHomework => 'No homework assigned yet.';

  @override
  String teacherActivityCompletedOf(int done, int total) {
    return '$done/$total completed';
  }

  @override
  String get teacherActivityPending => 'Pending';

  @override
  String get teacherActivityClose => 'Close';

  @override
  String get teacherActivityRecent => 'Recent activity';

  @override
  String get teacherActivityNoRecent => 'No recent activity for this filter.';

  @override
  String get teacherActivityFilterAll => 'All';

  @override
  String get teacherActivityJustNow => 'Just now';

  @override
  String teacherActivityMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String teacherActivityHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String teacherActivityDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get adminShellNavDashboard => 'Dashboard';

  @override
  String get adminShellNavUsers => 'Users';

  @override
  String get adminShellNavExercises => 'Exercises';

  @override
  String get adminShellNavQuestionBank => 'Question bank';

  @override
  String get adminShellNavClasses => 'Classes';

  @override
  String get adminShellNavVouchers => 'Vouchers';

  @override
  String get adminShellNavReports => 'Reports';

  @override
  String get adminShellNavAccount => 'Account';

  @override
  String get adminShellScanWorksheet => 'Scan worksheet';

  @override
  String get adminShellNewClass => 'New class';

  @override
  String get adminProfileSubtitle => 'Platform administrator';

  @override
  String get adminProfileIntro =>
      'Manage users, vouchers, reports, and notifications from the admin tabs. Teaching workflows use the Guru role.';

  @override
  String get adminProfileCentreSettings => 'Centre settings';

  @override
  String get adminProfileCentreSettingsHint =>
      'Payments, evaluations, materials, audit logs.';

  @override
  String get adminProfilePersonalSubtitle =>
      'Indonesian and Chinese names plus WhatsApp contact.';

  @override
  String get profileWidgetPhotoUpdated => 'Profile photo updated';

  @override
  String get profileWidgetEmailHelper => 'Contact support to change your email';

  @override
  String get profileWidgetParentHint =>
      'Used by staff to contact family when needed.';

  @override
  String get profileWidgetAccountTitle => 'Account';

  @override
  String get profileWidgetMemberSince => 'Member since';

  @override
  String get profileWidgetStatus => 'Status';

  @override
  String get profileWidgetInactive => 'Inactive';

  @override
  String get profileWidgetSaveChanges => 'Save changes';

  @override
  String get linkCardCopied => 'Link code copied';

  @override
  String get linkCardTitle => 'Student linking';

  @override
  String get linkCardBody =>
      'Share this code when a murid registers. It refreshes every 15 minutes.';

  @override
  String get linkCardCopyTooltip => 'Copy code';

  @override
  String linkCardRefreshesIn(String time) {
    return 'Refreshes in $time';
  }

  @override
  String get termDatesTitle => 'Term dates';

  @override
  String get termStartDate => 'Start date';

  @override
  String get termDeadlineDate => 'Deadline date';

  @override
  String get termSave => 'Save';

  @override
  String get termDelete => 'Delete';

  @override
  String termMeetingsLeftTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Class meetings left this term',
      one: 'Class meeting left this term',
    );
    return '$_temp0';
  }

  @override
  String get termNoPaidSessions =>
      'No paid sessions left. Ask your teacher to add a new term.';

  @override
  String termUsedRemaining(int used, int remaining, int total) {
    return '$used used · $remaining remaining of $total';
  }

  @override
  String termValidUntil(String date) {
    return 'Valid until $date';
  }

  @override
  String get termNoActiveInRange => 'No active term in the current date range.';

  @override
  String termActivePackages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count active packages',
      one: '1 active package',
    );
    return '$_temp0';
  }

  @override
  String get termChargedOnConclude =>
      'One session is charged when your teacher concludes each class.';

  @override
  String termSessionsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count class sessions left',
      one: '1 class session left',
    );
    return '$_temp0';
  }

  @override
  String get termNoActiveInRangeShort => 'No active term in date range';

  @override
  String get termDeductOnConclude =>
      'Sessions deduct when the teacher concludes a class.';

  @override
  String termRowLabel(int sessions, String start, String end) {
    return '$sessions-session · $start – $end';
  }

  @override
  String get termNoPaymentRecorded => 'No payment recorded';

  @override
  String termPaidLine(String amount, String method) {
    return 'Paid $amount ($method)';
  }

  @override
  String termPendingPayment(String amount) {
    return 'Pending payment · $amount';
  }

  @override
  String get termUpdated => 'Term updated';

  @override
  String get termDeleteTitle => 'Delete this term?';

  @override
  String termDeleteBody(int sessions, int remaining) {
    return 'Delete the $sessions-session term ($remaining left)? Past class charges linked to this term are kept in history. This cannot be undone.';
  }

  @override
  String get termDeleted => 'Term deleted';

  @override
  String get termNoPackages =>
      'No paid term packages yet. Add an 8 or 16 session term when the student pays.';

  @override
  String termPackageTitle(int sessions) {
    return '$sessions-session term';
  }

  @override
  String get termEdit => 'Edit term';

  @override
  String get termDeleteTooltip => 'Delete term';

  @override
  String termStartDeadline(String start, String deadline) {
    return 'Start: $start · Deadline: $deadline';
  }

  @override
  String get termOutsideDates => 'Outside term dates today';

  @override
  String termRemainingOf(int remaining, int total) {
    return '$remaining / $total left';
  }

  @override
  String termClassesAttended(int count) {
    return 'Classes attended ($count)';
  }

  @override
  String get termNoClassesCharged => 'No classes charged to this term yet.';

  @override
  String get termNoConcludedVisits => 'No concluded class visits yet.';

  @override
  String get termClassFallback => 'Class';

  @override
  String get termMinusOneSession => '−1 session';

  @override
  String termRemainingRangeError(int max) {
    return 'Enter sessions remaining between 0 and $max';
  }

  @override
  String termEditTitle(int sessions) {
    return 'Edit $sessions-session term';
  }

  @override
  String get termSessionsRemaining => 'Sessions remaining';

  @override
  String termOutOfPackage(int total) {
    return 'Out of $total in this package';
  }

  @override
  String get termAddTitle => 'Add paid term';

  @override
  String get termAddBody =>
      'Choose how many class sessions the student paid for. Sessions are deducted when you conclude each class.';

  @override
  String termSessionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions',
      one: '1 session',
    );
    return '$_temp0';
  }

  @override
  String termPaymentNoteRecorded(String amount) {
    return 'Pending payment of $amount recorded for the admin.';
  }

  @override
  String termPaymentNoteNoItem(int count) {
    return 'No price-list item for $count sessions: the admin must add the payment by hand.';
  }

  @override
  String termPaymentNoteFailed(String error) {
    return 'Could not record the payment ($error); the admin must add it in Payments.';
  }

  @override
  String termAdded(int sessions) {
    return 'Added $sessions-session term.';
  }

  @override
  String get termAddButton => 'Add term';

  @override
  String get termPaidTermsTitle => 'Paid class terms';

  @override
  String get termPackagesTitle => 'Term packages';

  @override
  String termOtherVisits(int count) {
    return 'Other concluded visits ($count)';
  }

  @override
  String get adminUsersRoleAdmin => 'Admin';

  @override
  String get adminUsersRoleTeacher => 'Guru';

  @override
  String get adminUsersRoleStudent => 'Murid';

  @override
  String get adminUsersRoleParent => 'Orang Tua';

  @override
  String get adminUsersAllRoles => 'All roles';

  @override
  String get adminUsersAllStatus => 'All status';

  @override
  String get adminUsersColName => 'Name';

  @override
  String get adminUsersColRole => 'Role';

  @override
  String get adminUsersColHsk => 'HSK';

  @override
  String get adminUsersColWhatsapp => 'WhatsApp';

  @override
  String get adminUsersColParentPhone => 'Parent phone';

  @override
  String get adminUsersColActions => 'Actions';

  @override
  String adminUsersActivated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count accounts activated.',
      one: '1 account activated.',
    );
    return '$_temp0';
  }

  @override
  String adminUsersDeactivated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count accounts deactivated.',
      one: '1 account deactivated.',
    );
    return '$_temp0';
  }

  @override
  String adminUsersHskDialogTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'HSK level for $count students',
      one: 'HSK level for 1 student',
    );
    return '$_temp0';
  }

  @override
  String get adminUsersApply => 'Apply';

  @override
  String adminUsersLevelSet(int count, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count students set to $level.',
      one: '1 student set to $level.',
    );
    return '$_temp0';
  }

  @override
  String get adminUsersActivate => 'Activate';

  @override
  String get adminUsersDeactivate => 'Deactivate';

  @override
  String get adminUsersSetHskLevel => 'Set HSK level';

  @override
  String adminUsersSetHskLevelCount(int count) {
    return 'Set HSK level ($count)';
  }

  @override
  String get adminUsersNoChildLinked => 'No child linked yet';

  @override
  String adminUsersChildrenMore(String names, int more) {
    return 'Children: $names +$more';
  }

  @override
  String adminUsersChildren(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Children: $names',
      one: 'Child: $names',
    );
    return '$_temp0';
  }

  @override
  String adminUsersParentOf(String name) {
    return 'Parent: $name';
  }

  @override
  String adminUsersDeleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String adminUsersDeleteBody(String email) {
    return '$email will no longer be able to sign in and the profile is removed. This cannot be undone. Exercise results, invoices and attendance stay as the centre\'s records.';
  }

  @override
  String get adminUsersDeleteAccount => 'Delete account';

  @override
  String adminUsersDeleted(String email) {
    return 'Deleted $email.';
  }

  @override
  String get adminUsersDeleteFailed => 'Could not delete the account.';

  @override
  String adminUsersLoadFailed(String error) {
    return 'Could not load users: $error';
  }

  @override
  String get adminUsersEmpty =>
      'No users found. Run scripts/seed_test_accounts.sh or check that your admin account has role: admin in Firestore.';

  @override
  String get adminUsersNoMatch => 'No users match your search.';

  @override
  String get adminUsersNewUser => 'New user';

  @override
  String get adminUsersSearchHint => 'Search users…';

  @override
  String get adminUsersSortBy => 'Sort by';

  @override
  String get adminUsersEditProfile => 'Edit profile';

  @override
  String get adminUsersEdit => 'Edit';

  @override
  String get adminUserFormTitle => 'Register new user';

  @override
  String get adminUserFormHeading => 'Create a Murid or Guru account';

  @override
  String get adminUserFormIntro =>
      'The new user can sign in with the email and password you set. You stay signed in as admin.';

  @override
  String get adminUserFormRoleParentShort => 'Ortu';

  @override
  String get adminUserFormSelectChild =>
      'Select at least one child for this parent.';

  @override
  String adminUserFormCreated(String role, String name) {
    return '$role account created for $name';
  }

  @override
  String get adminUserFormErrorEmailInUse =>
      'This email is already registered.';

  @override
  String adminUserFormSubmit(String role) {
    return 'Create $role account';
  }

  @override
  String get adminUserFormChildHint =>
      'Choose which students this parent can follow (read-only).';

  @override
  String get adminUserFormNoStudents => 'No students to link yet.';

  @override
  String get adminUserFormSearchHint => 'Search by name, email or HSK level';

  @override
  String adminUserFormSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get adminUserFormNoMatch => 'No students match this search.';

  @override
  String get adminUserFormNotFound => 'User not found';

  @override
  String adminUserFormUpdated(String name) {
    return '$name updated';
  }

  @override
  String get adminUserFormEditTitle => 'Edit user';

  @override
  String adminUserFormEditRole(String role) {
    return 'Edit $role';
  }

  @override
  String get adminUserFormProfileDetails => 'Profile details';

  @override
  String get adminUserFormHskHint =>
      'Change HSK level to control which practice exercises this murid can access.';

  @override
  String get adminInvoicesStatusPending => 'Pending';

  @override
  String get adminInvoicesStatusPaid => 'Paid';

  @override
  String get adminInvoicesStatusFailed => 'Failed';

  @override
  String get adminInvoicesMethodOnline => 'Online';

  @override
  String get adminInvoicesMethodCash => 'Cash';

  @override
  String get adminInvoicesMethodTransfer => 'Transfer';

  @override
  String get adminInvoicesMethodAtCentre => 'At the centre';

  @override
  String get adminInvoicesMethodManual => 'Manual';

  @override
  String get adminInvoicesItemBook => 'HSK materials & book';

  @override
  String get adminInvoicesGivesBook => 'book / materials, no sessions';

  @override
  String get adminInvoicesGivesRegistration => 'registration, no sessions';

  @override
  String get adminInvoicesGivesNone => 'no sessions';

  @override
  String get adminInvoicesColInvoice => 'Invoice';

  @override
  String get adminInvoicesColInvoiceNumber => 'Invoice #';

  @override
  String get adminInvoicesColItem => 'Item';

  @override
  String get adminInvoicesColAmount => 'Amount';

  @override
  String get adminInvoicesColMethod => 'Method';

  @override
  String get adminInvoicesColDue => 'Due';

  @override
  String get adminInvoicesColPaidOn => 'Paid on';

  @override
  String get adminInvoicesColCreated => 'Created';

  @override
  String get adminInvoicesDisabledSubtitle =>
      'Enable payments in Settings to create invoices and bill students for session packages.';

  @override
  String get adminInvoicesPriceList => 'Price list';

  @override
  String get adminInvoicesCreate => 'Create invoice';

  @override
  String get adminInvoicesCodeOnlyBanner =>
      'Payments run in code-only mode: add Midtrans keys and deploy Cloud Functions (Blaze) to enable live checkout.';

  @override
  String get adminInvoicesEmptyTitle => 'No invoices yet';

  @override
  String get adminInvoicesEmptySubtitle =>
      'Tap \"Create invoice\" to bill a student for a session package or the HSK book.';

  @override
  String get adminInvoicesOverdue => 'Overdue';

  @override
  String get adminInvoicesMarkPaidMenu => 'Mark as paid (cash / transfer)';

  @override
  String get adminInvoicesDeletePending => 'Delete pending invoice';

  @override
  String get adminInvoicesStudentFallback => 'student';

  @override
  String adminInvoicesRecorded(String name, String item, String method) {
    return 'Recorded: $name paid $item by $method.';
  }

  @override
  String get adminInvoicesDeleteTitle => 'Delete this pending invoice?';

  @override
  String adminInvoicesDeleteBody(String number, String item, String name) {
    return '$number · $item for $name. A voucher linked to it will show \"No payment\" again.';
  }

  @override
  String adminInvoicesDeleteFailed(String error) {
    return 'Could not delete: $error';
  }

  @override
  String adminInvoicesCardInvoice(String number) {
    return 'Invoice $number';
  }

  @override
  String adminInvoicesCardDue(String date) {
    return 'due $date';
  }

  @override
  String get adminInvoicesPayNow => 'Pay now';

  @override
  String get adminInvoicesPayAtCentre =>
      'Pay at the centre by cash or bank transfer. The admin marks it paid and your sessions are added.';

  @override
  String get adminInvoicesMarkPaid => 'Mark as paid';

  @override
  String get adminInvoicesItemFromPriceList => 'Item (from the Price list)';

  @override
  String adminInvoicesGives(String gives) {
    return 'Gives $gives.';
  }

  @override
  String get adminInvoicesVoucherOpened =>
      'A voucher is opened when this is paid.';

  @override
  String get adminInvoicesCashTransfer => 'Cash / transfer';

  @override
  String get adminInvoicesOnlineLink => 'Online link';

  @override
  String get adminInvoicesOnlineHint =>
      'The student gets a Midtrans payment link; the sessions are added automatically when they pay.';

  @override
  String get adminInvoicesManualHint =>
      'Recorded as pending. When the money arrives, open the invoice menu and choose Mark as paid.';

  @override
  String get adminInvoicesOnlineNeedsKeys =>
      'Online payments need Midtrans keys and the Cloud Functions deployed.';

  @override
  String get adminInvoicesDueDate => 'Due date';

  @override
  String get adminInvoicesChange => 'Change';

  @override
  String adminInvoicesCreateWithPrice(String price) {
    return 'Create invoice · $price';
  }

  @override
  String get adminInvoicesChooseStudent => 'Choose a student.';

  @override
  String get adminInvoicesChooseItem => 'Choose an item from the Price list.';

  @override
  String adminInvoicesCreatedOnline(String name) {
    return 'Invoice created for $name';
  }

  @override
  String adminInvoicesCreatedManual(String name) {
    return 'Invoice created for $name · pending until you mark it paid';
  }

  @override
  String get adminInvoicesBankTransfer => 'Bank transfer';

  @override
  String get adminInvoicesNoteOptional => 'Note (optional)';

  @override
  String get adminInvoicesNoteHint => 'e.g. BCA transfer 27 Oct';

  @override
  String get adminInvoicesLinkedVoucherPaid =>
      'The linked voucher is marked paid.';

  @override
  String adminInvoicesVoucherOpenedFor(int sessions) {
    return 'A $sessions-session voucher is opened for the student.';
  }

  @override
  String get adminInvoicesNoSessionsAdded =>
      'No sessions are added for this item.';

  @override
  String get adminInvoicesConfirmPayment => 'Confirm payment';

  @override
  String get adminVouchersNewVoucher => 'New voucher';

  @override
  String get adminVouchersPendingPayment => 'Pending payment';

  @override
  String get adminVouchersNoPayment => 'No payment';

  @override
  String get adminVouchersInvoiceMissing => 'Invoice missing';

  @override
  String get adminVouchersStatusActive => 'active';

  @override
  String get adminVouchersStatusLow => 'low';

  @override
  String get adminVouchersStatusDepleted => 'depleted';

  @override
  String get adminVouchersColVoucher => 'Voucher';

  @override
  String get adminVouchersColSessions => 'Sessions';

  @override
  String get adminVouchersColUsed => 'Used';

  @override
  String get adminVouchersColRemaining => 'Remaining';

  @override
  String get adminVouchersColStart => 'Start';

  @override
  String get adminVouchersColDeadline => 'Deadline';

  @override
  String get adminVouchersColPayment => 'Payment';

  @override
  String get adminVouchersColPackage => 'Package';

  @override
  String get adminVouchersVoucherCode => 'Voucher code';

  @override
  String get adminVouchersUnknownStudent => 'Unknown student';

  @override
  String get adminVouchersEdit => 'Edit voucher';

  @override
  String get adminVouchersDelete => 'Delete voucher';

  @override
  String get adminVouchersThisVoucher => 'this voucher';

  @override
  String get adminVouchersDeleteTitle => 'Delete voucher?';

  @override
  String adminVouchersDeleteBody(String code, String name) {
    return 'Delete $code for $name? This cannot be undone.';
  }

  @override
  String adminVouchersDeleted(String code) {
    return 'Deleted $code';
  }

  @override
  String get adminVouchersIntro =>
      'A voucher is a student\'s paid term: 8 or 16 class sessions with a start date and a deadline, always linked to a payment (Payments tab). \"Pending payment\" means the invoice is not settled yet; \"No payment\" is an older voucher created before payments were linked. One session is deducted each time a class is concluded.';

  @override
  String get adminVouchersSearchHint => 'Search by code or student…';

  @override
  String get adminVouchersFilterAll => 'All';

  @override
  String get adminVouchersEmptyTitle => 'No vouchers yet';

  @override
  String get adminVouchersNoMatch => 'No vouchers match your search';

  @override
  String get adminVouchersEmptySubtitle =>
      'Create a voucher to issue session packages with trackable codes like 2026_07_001.';

  @override
  String adminVouchersCardSessions(int sessions, int remaining) {
    return '$sessions sessions · $remaining remaining';
  }

  @override
  String get adminVoucherFormAddPriceItem =>
      'Add a sessions item to the Price list first.';

  @override
  String get adminVoucherFormRecordPaymentFor => 'Record a payment for';

  @override
  String adminVoucherFormRecordFailed(String error) {
    return 'Could not record the payment: $error';
  }

  @override
  String get adminVoucherFormNotFound => 'Voucher not found';

  @override
  String get adminVoucherFormChoosePayment =>
      'Choose the payment this voucher belongs to, or record a new one.';

  @override
  String get adminVoucherFormUpdated => 'Voucher updated';

  @override
  String get adminVoucherFormCreated => 'Voucher created';

  @override
  String get adminVoucherFormIntro =>
      'Every voucher belongs to a payment. Pick the student, then the invoice that pays for it (or record a cash / transfer payment here). A unique code is generated automatically (e.g. 2026_07_001).';

  @override
  String get adminVoucherFormNoHsk => 'No HSK';

  @override
  String get adminVoucherFormSelectStudent => 'Select a student';

  @override
  String get adminVoucherFormPackageSize => 'Package size';

  @override
  String get adminVoucherFormPackageSizeFromPayment =>
      'Package size (from the payment)';

  @override
  String adminVoucherFormOfTotal(int total) {
    return 'Of $total total in this package';
  }

  @override
  String get adminVoucherFormEnterNumber => 'Enter a number';

  @override
  String adminVoucherFormRange(int max) {
    return 'Must be between 0 and $max';
  }

  @override
  String adminVoucherFormStart(String date) {
    return 'Start: $date';
  }

  @override
  String adminVoucherFormDeadline(String date) {
    return 'Deadline: $date';
  }

  @override
  String get adminVoucherFormNotesOptional => 'Notes (optional)';

  @override
  String get adminVoucherFormCreate => 'Create voucher';

  @override
  String get adminVoucherFormPaymentHelper =>
      'Paid or pending session invoices without a voucher yet';

  @override
  String get adminVoucherFormChoosePaymentShort =>
      'Choose a payment or record a new one';

  @override
  String get adminVoucherFormRecordPayment =>
      'Record a cash / transfer payment';

  @override
  String get adminVoucherFormNoPaymentOlder =>
      'No payment recorded (older voucher)';

  @override
  String get teacherShellNavDashboard => 'Dashboard';

  @override
  String get teacherShellNavStudents => 'Students';

  @override
  String get teacherShellNavExercises => 'Exercises';

  @override
  String get teacherShellNavClasses => 'Classes';

  @override
  String get teacherShellNavGrades => 'Grades';

  @override
  String get teacherShellNewClass => 'New class';

  @override
  String get teacherProfileRoleSubtitle => 'Guru · Centre teacher';

  @override
  String get teacherProfilePersonalSubtitle =>
      'Indonesian and Chinese names plus WhatsApp contact.';

  @override
  String get teacherDashNoDemoTitle => 'No demo data yet';

  @override
  String get teacherDashNoDemoSubtitle =>
      'Run scripts/seed_test_accounts.sh then python3 scripts/seed_report_demo_data.py';

  @override
  String get teacherDashGradebook => 'Gradebook';

  @override
  String teacherDashPendingCount(int count) {
    return '$count pending';
  }

  @override
  String get teacherDashActiveThisWeek => 'Active this week';

  @override
  String get teacherDashNeedsAttention => 'Needs attention';

  @override
  String get teacherDashAllCaughtUp => 'All caught up';

  @override
  String get teacherDashNoFollowUp => 'No students need follow-up right now.';

  @override
  String get teacherDashRecentStudents => 'Recent students';

  @override
  String get teacherDashNoStudentsTitle => 'No students yet';

  @override
  String get teacherDashNoStudentsSubtitle =>
      'Students appear here after they register.';

  @override
  String get teacherDashNoCompletedHomeworkTitle => 'No completed homework yet';

  @override
  String get teacherDashNoCompletedHomeworkSubtitle =>
      'Completed practice will appear here once murid submit scores.';

  @override
  String get teacherDashNoOverdueTitle => 'No overdue practice';

  @override
  String get teacherDashNoOverdueSubtitle =>
      'All assigned homework is on track.';

  @override
  String get teacherDashNoQuizScoresTitle => 'No quiz scores yet';

  @override
  String get teacherDashNoQuizScoresSubtitle =>
      'Quiz averages appear after murid complete lesson quizzes.';

  @override
  String get teacherDashNoPracticeScoresTitle => 'No practice scores yet';

  @override
  String get teacherDashNoPracticeScoresSubtitle =>
      'Practice averages appear after murid complete assigned exercises.';

  @override
  String get teacherDashNoHomeworkTitle => 'No homework assigned yet';

  @override
  String get teacherDashNoHomeworkSubtitle =>
      'Assign practice from the Exercises tab to track completion here.';

  @override
  String teacherDashExerciseCountLevel(int count, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises',
      one: '1 exercise',
    );
    return '$_temp0 · $level';
  }

  @override
  String get teacherDashNoStudentsToShowTitle => 'No students to show';

  @override
  String get teacherDashNoStudentsToShowSubtitle =>
      'Try again later or check your student roster.';

  @override
  String teacherDashHomeworkDone(int count) {
    return '$count done';
  }

  @override
  String teacherDashHomeworkToDo(int count) {
    return '$count to do';
  }

  @override
  String teacherDashHomeworkOverdue(int count) {
    return '$count overdue';
  }

  @override
  String get teacherDashOverdue => 'Overdue';

  @override
  String get teacherDashPending => 'Pending';

  @override
  String get teacherDashNoSessionPackagesTitle => 'No session packages';

  @override
  String get teacherDashNoSessionPackagesSubtitle =>
      'Add class terms on a student profile to track sessions.';

  @override
  String teacherDashSessionsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions left',
      one: '1 session left',
    );
    return '$_temp0';
  }

  @override
  String get teacherDashNoClassesThisWeekTitle => 'No classes this week';

  @override
  String get teacherDashNoClassesThisWeekSubtitle =>
      'Create a class session from the Classes tab.';

  @override
  String get teacherDashConcluded => 'Concluded';

  @override
  String get teacherDashNoActivityTitle => 'No activity this week';

  @override
  String get teacherDashNoActivitySubtitle =>
      'Lesson and practice activity will show up here.';

  @override
  String get teacherDashStatStudentsTitle => 'All students';

  @override
  String get teacherDashStatStudentsDescription =>
      'Every registered murid with progress, homework, and session balance.';

  @override
  String get teacherDashStatActiveThisWeekDescription =>
      'Murid who completed a lesson or submitted practice in the last 7 days.';

  @override
  String get teacherDashStatHomeworkDoneTitle => 'Homework completed';

  @override
  String get teacherDashStatHomeworkDoneDescription =>
      'Assigned practice that murid have finished.';

  @override
  String get teacherDashStatOverdueTitle => 'Overdue practice';

  @override
  String get teacherDashStatOverdueDescription =>
      'Assigned practice past the due date and not yet completed.';

  @override
  String get teacherDashStatAvgQuizTitle => 'Quiz averages';

  @override
  String get teacherDashStatAvgQuizDescription =>
      'Average quiz score per murid across completed lessons.';

  @override
  String get teacherDashStatAvgPracticeTitle => 'Practice averages';

  @override
  String get teacherDashStatAvgPracticeDescription =>
      'Best practice score per murid across assigned exercises.';

  @override
  String get teacherDashStatSessionsLeftTitle => 'Class sessions remaining';

  @override
  String get teacherDashStatSessionsLeftDescription =>
      'Remaining live-class sessions on active voucher packages.';

  @override
  String get teacherDashStatClassesThisWeekTitle => 'Classes this week';

  @override
  String get teacherDashStatClassesThisWeekDescription =>
      'Scheduled class sessions in the current calendar week.';

  @override
  String get teacherDashStatNeedAttentionTitle => 'Students needing attention';

  @override
  String get teacherDashStatNeedAttentionDescription =>
      'Overdue homework, stale assignments, inactive murid, and low session balance.';

  @override
  String get teacherDashStatWeeklyActivityTitle => 'Weekly activity';

  @override
  String get teacherDashStatWeeklyActivityDescription =>
      'Lesson completions and practice submissions day by day.';

  @override
  String get teacherDashStatHomeworkOverviewTitle => 'Homework overview';

  @override
  String get teacherDashStatHomeworkOverviewDescription =>
      'Every assigned exercise with status, due date, and best score.';

  @override
  String teacherAttClassCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count classes',
      one: '1 class',
    );
    return '$_temp0';
  }

  @override
  String teacherAttConcludedCount(int count) {
    return '$count concluded';
  }

  @override
  String get teacherAttNewClassThisDay => 'New class this day';

  @override
  String get teacherAttEmptyDayHint =>
      'Pick another day, or create a class on this date. Dots on the calendar mark days with classes: teal = open, grey = concluded.';

  @override
  String get teacherAttClassConcludedTitle => 'Class concluded';

  @override
  String teacherAttClassConcludedBody(String title, String summary) {
    return '$title concluded. $summary.';
  }

  @override
  String teacherAttConcludeSummary(int charged, int excused) {
    String _temp0 = intl.Intl.pluralLogic(
      excused,
      locale: localeName,
      other: '$charged charged, $excused excused',
      zero: '$charged charged',
    );
    return '$_temp0';
  }

  @override
  String teacherAttConcludedSnack(String summary) {
    return 'Class concluded. $summary.';
  }

  @override
  String teacherAttConcludedWithFailures(int charged, String names) {
    return 'Class concluded. $charged charged; could not charge: $names';
  }

  @override
  String teacherAttStudentAdded(String name) {
    return '$name added to class';
  }

  @override
  String get teacherAttRemoveStudentTitle => 'Remove student?';

  @override
  String teacherAttRemoveStudentBody(String name, String title) {
    return 'Remove $name from \"$title\"?';
  }

  @override
  String teacherAttStudentRemoved(String name) {
    return '$name removed from class';
  }

  @override
  String get teacherAttAllStudentsInClass =>
      'All students are already in this class';

  @override
  String get teacherAttAddStudent => 'Add student';

  @override
  String get teacherAttClose => 'Close';

  @override
  String get teacherAttDeleteClassTitle => 'Delete this class?';

  @override
  String teacherAttDeleteClassBody(String title) {
    return 'Delete \"$title\"? All student join records for this class will be removed. This cannot be undone.';
  }

  @override
  String get teacherAttDelete => 'Delete';

  @override
  String get teacherAttClassDeleted => 'Class deleted';

  @override
  String get teacherAttThisStudent => 'This student';

  @override
  String teacherAttNoCreditsFor(String name) {
    return '$name has no class sessions left. Add an 8 or 16 session term from their profile.';
  }

  @override
  String get teacherAttDeletePermissionDenied =>
      'Could not delete: permission denied.';

  @override
  String teacherAttDeleteFailed(String code) {
    return 'Could not delete class ($code)';
  }

  @override
  String teacherAttStatsConcluded(int joined, int charged) {
    return '$joined joined · $charged charged';
  }

  @override
  String teacherAttStatsOpen(int joined, int capacity, int pending) {
    return '$joined/$capacity joined · $pending pending';
  }

  @override
  String teacherAttConcludedAt(String date) {
    return 'Concluded $date';
  }

  @override
  String get teacherAttConclude => 'Conclude';

  @override
  String get teacherAttEdit => 'Edit';

  @override
  String get teacherAttAdd => 'Add';

  @override
  String get teacherAttAtCapacity => 'Class is at capacity.';

  @override
  String teacherAttStudentsCount(int count) {
    return 'Students ($count)';
  }

  @override
  String get teacherAttNoStudentsJoined => 'No students joined yet.';

  @override
  String get teacherAttChipCharged => 'Charged';

  @override
  String get teacherAttChipNotCharged => 'Not charged';

  @override
  String get teacherAttChipAdded => 'Added';

  @override
  String get teacherAttNoAttendanceYet => 'No attendance recorded yet.';

  @override
  String get teacherAttNoClassAttendanceYet =>
      'No class attendance recorded yet.';

  @override
  String get teacherAttSessions => 'Sessions';

  @override
  String get teacherAttRate => 'Rate';

  @override
  String get teacherSessionPermissionDenied =>
      'Could not complete action: permission denied.';

  @override
  String teacherSessionActionFailed(String code) {
    return 'Could not complete action ($code)';
  }

  @override
  String teacherSessionTimeAndDuration(String time, int minutes) {
    return '$time · $minutes min';
  }

  @override
  String get teacherSessionStudentsJoined => 'Students who joined';

  @override
  String get teacherSessionSelfJoin => 'Self join';

  @override
  String get teacherSessionDeleteClass => 'Delete class';

  @override
  String get teacherSessionEndAfterStart =>
      'End time must be after start time.';

  @override
  String get teacherSessionEditTitle => 'Edit class';

  @override
  String get teacherSessionClassTitle => 'Class title';

  @override
  String get teacherSessionClassTitleHint => 'e.g. HSK 3 — Speaking practice';

  @override
  String get teacherSessionClassTitleRequired => 'Enter a class title';

  @override
  String get teacherSessionDate => 'Date';

  @override
  String get teacherSessionStart => 'Start';

  @override
  String get teacherSessionEnd => 'End';

  @override
  String get teacherSessionDuration => 'Duration';

  @override
  String teacherSessionMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get teacherSessionCapacity => 'Capacity';

  @override
  String get teacherSessionCapacityHint => 'Max students who can join';

  @override
  String get teacherSessionCapacityMin => 'Enter a capacity of at least 1';

  @override
  String get teacherSessionOpenToJoin => 'Open for students to join';

  @override
  String get teacherSessionOpenToJoinHint =>
      'Students can join from Home while the class is open.';

  @override
  String get teacherSessionSaveChanges => 'Save changes';

  @override
  String get teacherSessionCreate => 'Create class';

  @override
  String get teacherSessionModeOffline => 'In-person';

  @override
  String get teacherSessionModeOnline => 'Online';

  @override
  String get teacherSessionModeHybrid => 'Hybrid';

  @override
  String get teacherSessionRegDraft => 'Draft';

  @override
  String get teacherSessionRegOpen => 'Open for registration';

  @override
  String get teacherSessionRegActive => 'Active';

  @override
  String get teacherSessionRegClosed => 'Closed';

  @override
  String teacherStudentsLoadFailed(String error) {
    return 'Could not load students: $error';
  }

  @override
  String get studentDetailNotFound => 'Student not found';

  @override
  String get studentDetailEditProfile => 'Edit profile';

  @override
  String get studentDetailExportReport => 'Export progress report';

  @override
  String studentDetailLessonsPerTerm(int count) {
    return '$count lessons/term';
  }

  @override
  String get studentDetailContact => 'Contact';

  @override
  String get studentDetailExportReportPdf => 'Export progress report (PDF)';

  @override
  String get studentDetailAttendance => 'Attendance';

  @override
  String get studentDetailPracticeResults => 'Practice results';

  @override
  String get studentDetailLessonProgressByTerm => 'Lesson progress by term';

  @override
  String get studentDetailNoLessonProgress => 'No lesson progress yet.';

  @override
  String get studentDetailNoInvoices => 'No invoices yet.';

  @override
  String studentDetailPaidTotal(String amount) {
    return 'Paid $amount';
  }

  @override
  String studentDetailPendingTotal(String amount) {
    return 'Pending $amount';
  }

  @override
  String studentDetailPaidOn(String date) {
    return 'paid $date';
  }

  @override
  String studentDetailDueOn(String date) {
    return 'due $date';
  }

  @override
  String studentDetailMoreInPayments(int count) {
    return 'and $count more in Payments';
  }

  @override
  String studentDetailPresentCount(int count) {
    return '$count present';
  }

  @override
  String studentDetailExcusedCount(int count) {
    return '$count excused';
  }

  @override
  String studentDetailAbsentCount(int count) {
    return '$count absent';
  }

  @override
  String get studentDetailNotMarked => 'Not marked';

  @override
  String get teacherGradesNew => 'New grade';

  @override
  String get teacherGradesEmptyTitle => 'No grades yet';

  @override
  String get teacherGradesEmptySubtitle =>
      'Record an assessment score, or schedule a pending grade to fill in later.';

  @override
  String teacherGradesPendingHeader(int count) {
    return 'Grades pending ($count)';
  }

  @override
  String get teacherGradesRecorded => 'Recorded';

  @override
  String get teacherGradesNoRecorded => 'No recorded grades yet.';

  @override
  String get teacherGradesColAssessment => 'Assessment';

  @override
  String get teacherGradesColCategory => 'Category';

  @override
  String get teacherGradesColScore => 'Score';

  @override
  String get teacherGradesColLetter => 'Letter';

  @override
  String get teacherGradesColStatus => 'Status';

  @override
  String get teacherGradesColActions => 'Actions';

  @override
  String get teacherGradesAddScore => 'Add score';

  @override
  String get teacherGradesEdit => 'Edit grade';

  @override
  String get teacherGradesDelete => 'Delete grade';

  @override
  String get teacherGradesDeleteTitle => 'Delete grade?';

  @override
  String get teacherGradesDeleteBody =>
      'This removes the grade for this student.';

  @override
  String get teacherGradesPickStudent => 'Pick a student';

  @override
  String get teacherGradesPickStudentError => 'Pick a student.';

  @override
  String teacherGradesSaveFailed(String error) {
    return 'Could not save grade: $error';
  }

  @override
  String get teacherGradesTitleLabel => 'Title';

  @override
  String get teacherGradesTitleHint => 'e.g. Speaking Test, Midterm';

  @override
  String get teacherGradesTitleRequired => 'Enter a title';

  @override
  String get teacherGradesScoreLabel => 'Score (0–100)';

  @override
  String get teacherGradesScoreLabelOptional =>
      'Score (0–100) — leave blank to schedule';

  @override
  String get teacherGradesScoreRange => 'Enter a number 0–100';

  @override
  String get teacherGradesSave => 'Save';

  @override
  String get teacherGradesCreate => 'Create grade';

  @override
  String teacherGradesLetterHint(String letter) {
    return 'Letter grade: $letter';
  }

  @override
  String get teacherGradesCategoryQuiz => 'Quiz';

  @override
  String get teacherGradesCategoryExercise => 'Exercise';

  @override
  String get teacherGradesCategorySpeaking => 'Speaking';

  @override
  String get teacherGradesCategoryWriting => 'Writing';

  @override
  String get teacherGradesCategoryExam => 'Exam';

  @override
  String get teacherGradesCategoryOther => 'Other';

  @override
  String get teacherGradesStatusPending => 'Pending';

  @override
  String get teacherGradesStatusGraded => 'Graded';

  @override
  String get concludeTitle => 'Conclude class';

  @override
  String get concludeHint =>
      'Mark who came. Present and Absent charge 1 session from the student\'s term; Excused (before class) is not charged.';

  @override
  String get concludeNoStudents =>
      'No students to charge. Concluding only closes the class.';

  @override
  String concludeChargeSummary(int charged, int total) {
    return '$charged of $total will be charged. This cannot be undone.';
  }

  @override
  String get leaveClassTitle => 'Leave this class?';

  @override
  String get leaveClassBody =>
      'You will be removed from the class roster. You can join again from Home if the class is still open and has space.';

  @override
  String get leaveClassStay => 'Stay in class';

  @override
  String get appShellBack => 'Back';

  @override
  String get evaluationsTitle => 'Evaluations';

  @override
  String get evaluationsNew => 'New';

  @override
  String get evaluationsFormsClosed =>
      'Evaluation forms are closed. An admin can open them in Settings.';

  @override
  String get evaluationsEmpty => 'No evaluations yet.';

  @override
  String get evaluationsFallbackTitle => 'Evaluation';

  @override
  String get evaluationsPublished => 'Published';

  @override
  String get evaluationsDraft => 'Draft';

  @override
  String get evaluationsEditTitle => 'Edit evaluation';

  @override
  String get evaluationsNewTitle => 'New evaluation';

  @override
  String get evaluationsTermLabel => 'Term';

  @override
  String get evaluationsTermHint => 'e.g. Semester 1 2026';

  @override
  String get evaluationsTermRequired => 'Enter a term';

  @override
  String get evaluationsRating => 'Rating';

  @override
  String get evaluationsStrengths => 'Strengths';

  @override
  String get evaluationsImprovements => 'Areas to improve';

  @override
  String get evaluationsComment => 'Comment';

  @override
  String get evaluationsSaveDraft => 'Save draft';

  @override
  String get evaluationsPublish => 'Publish';

  @override
  String get transcriptEmptySubtitle =>
      'Assessment results and practice scores will appear here as they are recorded.';

  @override
  String get transcriptPendingHeader => 'Upcoming / pending';

  @override
  String get transcriptTeacherEvaluations => 'Teacher evaluations';

  @override
  String get transcriptTitle => 'Transcript';

  @override
  String get transcriptPracticeExercise => 'Practice exercise';

  @override
  String get transcriptLessonQuiz => 'Lesson quiz';

  @override
  String get transcriptToImprove => 'To improve';

  @override
  String transcriptAwaitingScore(String category) {
    return '$category · awaiting score';
  }

  @override
  String get calendarFormatMonth => 'Month';

  @override
  String get calendarFormatTwoWeeks => '2 weeks';

  @override
  String get calendarFormatWeek => 'Week';

  @override
  String get calendarNoClasses => 'No classes';

  @override
  String calendarNoSessionsOn(String date) {
    return 'No class sessions on $date.';
  }

  @override
  String calendarCapacity(int count) {
    return 'Cap $count';
  }

  @override
  String get calendarConcluded => 'concluded';

  @override
  String get exerciseTypeMultipleChoice => 'Multiple choice';

  @override
  String get exerciseTypeComposeSentences => 'Compose sentences (组词成句)';

  @override
  String get exerciseTypeMatching => 'Matching (对话配对)';

  @override
  String get exerciseTypeListening => 'Listening (听力)';

  @override
  String get exerciseTypeReadingCloze => 'Fill in the blank (选词填空)';

  @override
  String get exerciseTypePictureSentence => 'Picture + keyword sentence';

  @override
  String get exerciseTypeTypeHanzi => 'Type the hanzi (写汉字)';

  @override
  String get exerciseCategoryExercise => 'Exercise';

  @override
  String get exerciseCategoryQuiz => 'Quiz';

  @override
  String get exerciseCategoryExam => 'Exam';

  @override
  String get exerciseCategoryHskSimulation => 'HSK Simulation';

  @override
  String get skillCategoryReading => 'Reading';

  @override
  String get skillCategoryListening => 'Listening';

  @override
  String get skillCategoryTyping => 'Typing (Writing)';

  @override
  String get skillCategorySpeaking => 'Speaking';

  @override
  String bankTextOrder(String segments) {
    return 'Order: $segments';
  }

  @override
  String bankTextAnswer(String answer) {
    return 'Answer: $answer';
  }

  @override
  String bankTextPinyin(String pinyin, String answers) {
    return 'Pinyin $pinyin → $answers';
  }

  @override
  String get bankTextTypeHanziInEditor => 'type the hanzi in the editor';

  @override
  String bankTextKeyword(String keyword) {
    return 'Keyword: $keyword';
  }

  @override
  String get bankTextNoOptionsYet => 'No answer options read yet';

  @override
  String bankTextQuestionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count questions',
      one: '1 question',
    );
    return '$_temp0';
  }

  @override
  String exerciseCardToDoCount(int count) {
    return '$count to do';
  }

  @override
  String exerciseCardOverdueCount(int count) {
    return '$count overdue';
  }

  @override
  String exerciseCardDoneCount(int count) {
    return '$count done';
  }

  @override
  String exerciseCardWorksheets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count worksheets',
      one: '1 worksheet',
    );
    return '$_temp0';
  }

  @override
  String get exerciseCardNotStarted => 'Not started';

  @override
  String get exerciseCardOverdueLower => 'overdue';

  @override
  String exerciseCardBest(int score) {
    return 'Best $score%';
  }

  @override
  String exerciseCardAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attempts',
      one: '1 attempt',
    );
    return '$_temp0';
  }

  @override
  String get exerciseCardTapToRetry => 'Tap to retry';

  @override
  String exerciseCardLast(String date) {
    return 'Last $date';
  }

  @override
  String get exerciseCardStatusToDo => 'To do';

  @override
  String get exerciseCardStatusOverdue => 'Overdue';

  @override
  String get exerciseCardStatusDone => 'Done';

  @override
  String exerciseCardDue(String date) {
    return 'Due $date';
  }

  @override
  String exerciseCardOverdueOn(String date) {
    return 'Overdue · $date';
  }

  @override
  String get exerciseCardUnknownStudent => 'Unknown student';

  @override
  String get exerciseCardThisLevel => 'this level';

  @override
  String get exerciseCardStudentProgress => 'Student progress';

  @override
  String exerciseCardNoStudentsRegistered(String level) {
    return 'No $level students registered yet.';
  }

  @override
  String exerciseCardCompletedOpenTo(int completed, int total, String level) {
    return '$completed/$total completed · open to $level';
  }

  @override
  String get exerciseCardPending => 'Pending';

  @override
  String get exerciseCardClose => 'Close';

  @override
  String get exerciseCardNoPracticeTitle => 'No practice assigned';

  @override
  String get exerciseCardNoPracticeSubtitle =>
      'Assigned exercises will appear here.';

  @override
  String exerciseCardBestScoreRetry(int score) {
    return 'Best score: $score% · Tap to retry';
  }

  @override
  String get bankFiltersSearchHint => 'Search worksheet or question';

  @override
  String get bankFiltersTypeOfExercise => 'Type of exercise';

  @override
  String get bankFiltersQuestionType => 'Question type';

  @override
  String get bankFiltersLevel => 'Level';

  @override
  String get bankFiltersAll => 'All';

  @override
  String get bankTitle => 'Question bank';

  @override
  String get bankCsvWorksheetOrQuestion => 'Worksheet / question';

  @override
  String get bankCsvCode => 'Code';

  @override
  String get bankQuestions => 'Questions';

  @override
  String get bankUsed => 'Used';

  @override
  String get bankActions => 'Actions';

  @override
  String bankTypeOfExerciseFor(String what) {
    return 'Type of exercise for $what';
  }

  @override
  String bankLevelFor(String what) {
    return 'Level for $what';
  }

  @override
  String bankSetTo(String what, String value) {
    return '$what set to $value.';
  }

  @override
  String bankDeleteWhat(String what) {
    return 'Delete $what?';
  }

  @override
  String bankDeleteBulkBody(String questions) {
    return 'All $questions leave the bank. Exercises that already use them keep their copies. This cannot be undone.';
  }

  @override
  String bankDeleted(String what) {
    return '$what deleted.';
  }

  @override
  String bankCountJoin(String a, String b) {
    return '$a and $b';
  }

  @override
  String get bankApply => 'Apply';

  @override
  String bankNewExerciseWithSheets(String worksheets) {
    return 'New exercise ($worksheets)';
  }

  @override
  String get bankSetTypeOfExercise => 'Set type of exercise';

  @override
  String get bankSetLevel => 'Set level';

  @override
  String get bankDelete => 'Delete';

  @override
  String get bankEdit => 'Edit';

  @override
  String get bankView => 'View';

  @override
  String get bankTypeAQuestion => 'Type a question';

  @override
  String get bankLoadSamples =>
      'Load the centre\'s sample sheets (10 worksheets)';

  @override
  String get bankBulkPaste => 'Bulk import — paste';

  @override
  String get bankScanWorksheet => 'Scan worksheet';

  @override
  String get bankNoWorksheetsTitle => 'No worksheets yet';

  @override
  String get bankNoWorksheetsSubtitle =>
      'Scan a worksheet to add it whole, or type a single question. Exercises pull from here.';

  @override
  String get bankNoMatchesTitle => 'No matches';

  @override
  String get bankAdjustFilters => 'Adjust the filters.';

  @override
  String bankUsedCount(int count) {
    return 'Used $count';
  }

  @override
  String bankAddFromBankType(String type) {
    return 'Add from bank — $type';
  }

  @override
  String bankAddCount(int count) {
    return 'Add ($count)';
  }

  @override
  String get bankFilterHint => 'Filter worksheets and questions…';

  @override
  String bankSelectAllFiltered(int count) {
    return 'Select all ($count filtered)';
  }

  @override
  String get bankNoMatchingTitle => 'No matching bank questions';

  @override
  String get bankNoMatchingSubtitle =>
      'Add questions of this type to the bank first.';

  @override
  String get bankSheetAssignThis => 'Assign this worksheet';

  @override
  String get bankSheetEditTooltip => 'Edit worksheet (title, type, level)';

  @override
  String get bankSheetDeleteTooltip => 'Delete worksheet';

  @override
  String get bankSheetRemovedTitle => 'Worksheet removed';

  @override
  String get bankSheetRemovedSubtitle =>
      'Its questions are no longer in the bank.';

  @override
  String get bankSheetAddQuestion => 'Add question';

  @override
  String get bankSheetRemoveQuestionTitle => 'Remove this question?';

  @override
  String get bankSheetRemoveQuestionBody =>
      'It leaves the worksheet and the bank. Exercises that already use it keep their copy.';

  @override
  String bankSheetDeleteSheetTitle(String code) {
    return 'Delete worksheet $code?';
  }

  @override
  String bankSheetDeleteSheetBody(String questions) {
    return 'All $questions leave the bank. Exercises that already use them keep their copies.';
  }

  @override
  String bankSheetUsedTimes(int count) {
    return 'used $count×';
  }

  @override
  String get bankSheetNoPrompt => '(no prompt)';

  @override
  String get bankSheetEditQuestion => 'Edit question';

  @override
  String get bankSheetRemoveFromSheet => 'Remove from worksheet';

  @override
  String get bankSheetEditSheet => 'Edit worksheet';

  @override
  String bankSheetCodeStays(String code) {
    return 'Code $code stays the same.';
  }

  @override
  String get bankSheetCategoryHelper =>
      'Exercise, quiz, exam or HSK simulation.';

  @override
  String get bankSheetTypeChangesShape =>
      'This type stores answers differently: open each question afterwards and check its answer.';

  @override
  String get bankSheetTypeAppliesAll =>
      'Applies to every question on the sheet.';

  @override
  String get bankEditorNeedTwoParts => 'Enter at least two sentence parts.';

  @override
  String get bankEditorEnterQuestion => 'Enter the question.';

  @override
  String get bankEditorNeedTwoWords =>
      'Enter at least two words in the word bank.';

  @override
  String get bankEditorEnterPinyin => 'Enter the pinyin hint.';

  @override
  String get bankEditorNeedAccepted => 'Enter at least one accepted answer.';

  @override
  String get bankEditorEnterKeyword => 'Enter the word the sentence must use.';

  @override
  String get bankEditorNeedTwoChoices => 'Enter at least two choices.';

  @override
  String get bankEditorCorrectEmpty => 'The correct choice is empty.';

  @override
  String bankEditorUploadFailed(String error) {
    return 'Upload failed: $error';
  }

  @override
  String bankEditorCouldNotSave(String error) {
    return 'Could not save: $error';
  }

  @override
  String bankEditorAddToSheetTitle(String title) {
    return 'Add a question to $title';
  }

  @override
  String get bankEditorNewQuestion => 'New question';

  @override
  String get bankEditorExplanationOptional => 'Explanation (optional)';

  @override
  String get bankEditorExplanationHelper =>
      'Why the answer is right. Students see it on the result page after they submit, never while answering.';

  @override
  String get bankEditorSkill => 'Skill';

  @override
  String get bankEditorSave => 'Save';

  @override
  String get bankEditorAddToWorksheet => 'Add to worksheet';

  @override
  String get bankEditorAddToBank => 'Add to bank';

  @override
  String bankEditorOptionalSuffix(String label) {
    return '$label (optional)';
  }

  @override
  String get bankEditorQuestion => 'Question';

  @override
  String get bankEditorListeningHelper =>
      'Add the audio below; the student hears it and picks a choice.';

  @override
  String get bankEditorChoicesTick => 'Choices (tick the correct one)';

  @override
  String get bankEditorSentenceWithBlank => 'Sentence with the blank';

  @override
  String get bankEditorQuestionOrLine => 'Question or line';

  @override
  String get bankEditorClozeHelper =>
      'Write the blank as ____ ; the student picks the word from the bank.';

  @override
  String get bankEditorMatchingHelper =>
      'The student matches it to one word or reply from the bank.';

  @override
  String get bankEditorWordBank => 'Word bank (one per line)';

  @override
  String get bankEditorWordBankHelper =>
      'Shared by the whole worksheet: the same list on every question of this sheet.';

  @override
  String get bankEditorCorrectAnswer => 'Correct answer';

  @override
  String get bankEditorBlankNumber => 'Blank #';

  @override
  String get bankEditorSentenceParts =>
      'Sentence parts in the right order (one per line)';

  @override
  String get bankEditorSentencePartsHelper =>
      'The student sees them shuffled and puts them back in order.';

  @override
  String get bankEditorInstruction => 'Instruction';

  @override
  String get bankEditorPinyinHint => 'Pinyin hint';

  @override
  String get bankEditorPinyinHelper => 'What the student sees, e.g. nǐ hǎo.';

  @override
  String get bankEditorAcceptedAnswers => 'Accepted answers (one per line)';

  @override
  String get bankEditorAcceptedHelper =>
      'Hanzi that count as correct, e.g. 你好.';

  @override
  String get bankEditorKeywordLabel => 'Word the sentence must use';

  @override
  String get bankEditorKeywordHelper =>
      'The student writes a sentence with this word about the picture.';

  @override
  String bankEditorChoice(String letter) {
    return 'Choice $letter';
  }

  @override
  String get bankEditorRemoveChoice => 'Remove choice';

  @override
  String get bankEditorAddChoice => 'Add choice';

  @override
  String get bankEditorMediaOptional => 'Media (optional)';

  @override
  String get bankEditorAddImage => 'Add image';

  @override
  String get bankEditorImageAttached => 'Image attached';

  @override
  String get bankEditorAddAudio => 'Add audio';

  @override
  String get bankEditorAudioAttached => 'Audio attached';

  @override
  String get bankImportPasteTitle => 'Paste questions';

  @override
  String get bankImportPasteHint =>
      'Paste worksheet text (numbered questions + A/B/C/D options).';

  @override
  String get bankImportPasteExample => '1. 你好 means…\nA. hello\nB. goodbye';

  @override
  String get bankImportType => 'Type';

  @override
  String get bankImportImport => 'Import';

  @override
  String get bankImportNoneParsed => 'No questions could be parsed.';

  @override
  String get bankImportAllSamplesPresent =>
      'All sample questions are already in the bank.';

  @override
  String bankImportSampleSummary(String name, int count, String skippedNote) {
    return '$name: $count questions from 10 sheets with answer keys$skippedNote. Pictures for the 看图写句子 keywords are added in the editor.';
  }

  @override
  String bankImportSampleSkipped(int count) {
    return ', $count already in the bank';
  }

  @override
  String get bankImportNothingToImport => 'No questions to import.';

  @override
  String bankImportParsedFromPaste(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count questions parsed from the pasted text.',
      one: '1 question parsed from the pasted text.',
    );
    return '$_temp0';
  }

  @override
  String bankImportReplacedSheet(String code, String questions) {
    return 'Replaced worksheet $code ($questions) in the bank.';
  }

  @override
  String bankImportAddedSheet(String code, String questions) {
    return 'Added worksheet $code ($questions) in the bank.';
  }

  @override
  String bankImportReplacedQuestions(String questions) {
    return 'Replaced $questions in the bank.';
  }

  @override
  String bankImportAddedQuestions(String questions) {
    return 'Added $questions in the bank.';
  }

  @override
  String bankImportCouldNotImport(String error) {
    return 'Could not import: $error';
  }

  @override
  String get bankImportReviewTitle => 'Check before adding';

  @override
  String bankImportReviewWorksheet(String code) {
    return 'Worksheet $code';
  }

  @override
  String get bankImportReviewAddedAsOne =>
      'Added to the bank as one worksheet. Untick a question to leave it out.';

  @override
  String bankImportReviewAlreadyInBank(String questions) {
    return 'This worksheet is already in the bank with $questions.';
  }

  @override
  String get bankImportReviewReplaceIt => 'Replace it';

  @override
  String get bankImportReviewKeepBoth => 'Keep both';

  @override
  String bankImportReviewReplaceWorksheet(String questions) {
    return 'Replace worksheet ($questions)';
  }

  @override
  String bankImportReviewAddWorksheet(String questions) {
    return 'Add worksheet ($questions)';
  }

  @override
  String bankImportReviewAddToBank(int count) {
    return 'Add $count to bank';
  }

  @override
  String bankHarvestCouldNotLoad(String error) {
    return 'Could not load exercises: $error';
  }

  @override
  String bankHarvestNoNew(int skipped) {
    return 'No new questions — $skipped already in the bank.';
  }

  @override
  String get bankHarvestTitle => 'Import from exercises';

  @override
  String bankHarvestFound(int count, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Found $count new questions.',
      one: 'Found 1 new question.',
    );
    return '$_temp0\n$skipped already in the bank (skipped).';
  }

  @override
  String bankHarvestImportCount(int count) {
    return 'Import $count';
  }

  @override
  String bankHarvestImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Imported $count questions from exercises.',
      one: 'Imported 1 question from exercises.',
    );
    return '$_temp0';
  }

  @override
  String get worksheetCouldNotReadFile => 'Could not read the selected file.';

  @override
  String worksheetImportFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String get worksheetImporting => 'Importing worksheet';

  @override
  String get worksheetTimingNote =>
      'Text PDFs and Word files take a few seconds. Scanned pages and photos take 20–40 seconds each; the first scan also downloads the Chinese OCR data (about 15 MB).';

  @override
  String worksheetElapsed(String time) {
    return 'Elapsed $time';
  }

  @override
  String get worksheetEstimating => 'estimating time left…';

  @override
  String get worksheetAlmostDone => 'almost done';

  @override
  String worksheetAboutSecondsLeft(int seconds) {
    return 'about $seconds s left';
  }

  @override
  String worksheetAboutMinutesLeft(int minutes) {
    return 'about $minutes min left';
  }

  @override
  String get worksheetFewMinutesLeft => 'a few minutes left';

  @override
  String worksheetAnswerKeyFilled(int filled, int total) {
    return 'Answer key: $filled of $total answers filled from the centre\'s sample set.';
  }

  @override
  String worksheetAnswerKeyFilledCode(int filled, int total, String code) {
    return 'Answer key: $filled of $total answers filled from the centre\'s sample set ($code).';
  }

  @override
  String get worksheetNoKeyCompose =>
      'No answer key on this sheet: the sentences keep the order shown on the sheet. Put the words in the correct order in the question bank.';

  @override
  String get worksheetNoKeyTypeHanzi =>
      'No answer key on this sheet: add the accepted hanzi for each item in the question bank.';

  @override
  String get worksheetNoKeyDefault =>
      'No answer key on this sheet: every answer is set to A (the first option). Correct them in the question bank.';

  @override
  String get worksheetReviewTitle => 'Review import';

  @override
  String get worksheetDetectedFormat => 'Detected format';

  @override
  String worksheetSuggestedLevel(String level) {
    return 'Suggested level: $level';
  }

  @override
  String get worksheetTypeNotSupported =>
      'This exercise type is not fully supported yet. You can still copy instructions or edit the text.';

  @override
  String get worksheetInstructionsOnly => 'Instructions only';

  @override
  String worksheetImportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Import $count questions',
      one: 'Import 1 question',
    );
    return '$_temp0';
  }

  @override
  String get worksheetImportQuestions => 'Import questions';

  @override
  String get worksheetExerciseType => 'Exercise type';

  @override
  String get worksheetExtractedText => 'Extracted text';

  @override
  String get worksheetEditIfMisread => 'Edit if OCR misread anything…';

  @override
  String get worksheetReanalyze => 'Re-analyze';

  @override
  String get worksheetSentencePreview => 'Sentence preview';

  @override
  String get worksheetQuestionPreview => 'Question preview';

  @override
  String get worksheetNoQuestionsDetected =>
      'No questions detected yet. Edit the text and tap Re-analyze.';

  @override
  String worksheetAndMore(int count) {
    return '…and $count more';
  }

  @override
  String worksheetPreviewPinyin(String pinyin, String answers) {
    return 'pinyin: $pinyin → $answers';
  }

  @override
  String get worksheetPreviewTypeInEditor => '(type the hanzi in the editor)';

  @override
  String worksheetPreviewKeyword(String keyword) {
    return 'keyword: $keyword';
  }

  @override
  String get worksheetPreviewAddOptions => '(add options)';

  @override
  String assignAssignedTo(int count, String removed) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Assigned to $count students',
      one: 'Assigned to 1 student',
    );
    return '$_temp0$removed.';
  }

  @override
  String assignRemovedFrom(int count) {
    return ', removed from $count';
  }

  @override
  String assignCouldNot(String error) {
    return 'Could not assign: $error';
  }

  @override
  String assignTitle(String title) {
    return 'Assign \"$title\"';
  }

  @override
  String get assignOnlyTicked =>
      'Only the students you tick can open this exercise.';

  @override
  String get assignSearchStudents => 'Search students';

  @override
  String assignSelectAllShown(int count) {
    return 'Select all shown ($count)';
  }

  @override
  String get assignClear => 'Clear';

  @override
  String get assignNoDueDate => 'No due date';

  @override
  String get assignNoStudentsTitle => 'No students match';

  @override
  String get assignNoStudentsSubtitle => 'Change the level or the search.';

  @override
  String get assignAlreadyAssigned => 'assigned';

  @override
  String get assignSaving => 'Saving…';

  @override
  String assignSaveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Save ($count students)',
      one: 'Save (1 student)',
    );
    return '$_temp0';
  }

  @override
  String get packageFormAddAtLeastOne =>
      'Add at least one worksheet or question.';

  @override
  String get packageFormSaved => 'Exercise saved.';

  @override
  String get packageFormCreated => 'Exercise created.';

  @override
  String get packageFormEditTitle => 'Edit exercise';

  @override
  String get packageFormTitle => 'Title';

  @override
  String get packageFormEnterTitle => 'Enter a title';

  @override
  String get packageFormSkillSection => 'Skill section';

  @override
  String get packageFormInstructionsOptional => 'Instructions (optional)';

  @override
  String get packageFormTimeLimit => 'Time limit in minutes (optional)';

  @override
  String get packageFormTimeLimitHelper =>
      'Leave empty for no limit. With a limit the clock counts down and the exercise submits itself at zero.';

  @override
  String get packageFormEnterMinutes => 'Enter a whole number of minutes';

  @override
  String get packageFormPublishedSubtitle =>
      'Assigned students can open it. Drafts stay hidden.';

  @override
  String packageFormContents(String questions) {
    return 'Contents · $questions';
  }

  @override
  String get packageFormAddFromBank => 'Add from bank';

  @override
  String get packageFormNothingYet =>
      'Nothing yet. Add worksheets from the question bank; the students get them in this order. Edit a worksheet in the bank later and this exercise follows.';

  @override
  String get packageFormNotInBank => 'Not in the bank any more';

  @override
  String get packageFormQuestionRemoved => '(question removed)';

  @override
  String get packageFormSaveDraftOrPublish => 'Save as draft or publish';

  @override
  String get packageFormSaveAndAssign => 'Save and assign';

  @override
  String get packageFormMoveUp => 'Move up';

  @override
  String get packageFormMoveDown => 'Move down';

  @override
  String get packageFormRemove => 'Remove';

  @override
  String get packageFormAddFromQuestionBank => 'Add from the question bank';

  @override
  String packageFormDoneCount(int count) {
    return 'Done ($count)';
  }

  @override
  String get packageFormSearchHint => 'Search worksheets and questions…';

  @override
  String get packageFormBankEmptyTitle => 'The bank is empty';

  @override
  String get packageFormNoMatchTitle => 'Nothing in the bank matches';

  @override
  String get packageFormBankEmptySubtitle =>
      'Scan a worksheet to add the first one.';

  @override
  String get packageFormNoMatchSubtitle => 'Change the search or the filters.';

  @override
  String get packageFormOpenEditSheet => 'Open and edit this worksheet';

  @override
  String get packageFormEditQuestion => 'Edit this question';

  @override
  String get teacherExExercise => 'Exercise';

  @override
  String get teacherExContents => 'Contents';

  @override
  String get teacherExStudents => 'Students';

  @override
  String get teacherExDone => 'Done';

  @override
  String get teacherExNextDue => 'Next due';

  @override
  String get teacherExStatus => 'Status';

  @override
  String get teacherExExportCsv => 'Export CSV';

  @override
  String get teacherExSelected => 'selected';

  @override
  String teacherExBulkPublished(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises published.',
      one: '1 exercise published.',
    );
    return '$_temp0';
  }

  @override
  String teacherExBulkDraft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises set to draft.',
      one: '1 exercise set to draft.',
    );
    return '$_temp0';
  }

  @override
  String teacherExDeleteCountTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $count exercises?',
      one: 'Delete 1 exercise?',
    );
    return '$_temp0';
  }

  @override
  String get teacherExDeleteBulkBody =>
      'Students lose these assignments. Their past results stay. This cannot be undone.';

  @override
  String teacherExBulkDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises deleted.',
      one: '1 exercise deleted.',
    );
    return '$_temp0';
  }

  @override
  String get teacherExPublish => 'Publish';

  @override
  String get teacherExSetToDraft => 'Set to draft';

  @override
  String get teacherExViewOnly => 'View only';

  @override
  String get teacherExAdminRequired => 'Admin access required';

  @override
  String get teacherExDeleteTitle => 'Delete exercise?';

  @override
  String teacherExDeleteBody(String title) {
    return 'Delete \"$title\"? This cannot be undone.';
  }

  @override
  String get teacherExDeleted => 'Exercise deleted';

  @override
  String teacherExSingleQuestions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count single questions',
      one: '1 single question',
    );
    return '$_temp0';
  }

  @override
  String teacherExSentences(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sentences',
      one: '1 sentence',
    );
    return '$_temp0';
  }

  @override
  String get teacherExSearchExercises => 'Search exercises';

  @override
  String get teacherExNewExercise => 'New exercise';

  @override
  String get teacherExFromBank => 'From the question bank';

  @override
  String get teacherExOldFormat => 'Old format, students cannot play it';

  @override
  String get teacherExNone => 'None';

  @override
  String teacherExStudentsFinished(int completed, int total) {
    return '$completed of $total students finished';
  }

  @override
  String get teacherExDue => 'Due';

  @override
  String get teacherExNoExercisesTitle => 'No exercises yet';

  @override
  String get teacherExNoExercisesSubtitle =>
      'An exercise bundles worksheets from the question bank; students see it once it is assigned to them.';

  @override
  String get teacherExNoExercisesSubtitleReadOnly =>
      'An exercise bundles worksheets from the question bank; students see it once it is assigned to them. Exercises are built on web.';

  @override
  String get teacherExPublished => 'Published';

  @override
  String get teacherExDraft => 'Draft';

  @override
  String get teacherExAssign => 'Assign';

  @override
  String get teacherExDraftHidden => 'Draft — not visible to students';

  @override
  String get teacherExNotAssigned => 'Not assigned yet';

  @override
  String teacherExStudentsDone(int completed, int total) {
    return '$completed/$total students done';
  }

  @override
  String teacherExDueLower(String date) {
    return 'due $date';
  }

  @override
  String get routeTitleNewUser => 'New user';

  @override
  String get routeTitleEditUser => 'Edit user';

  @override
  String get routeTitleStudent => 'Student';

  @override
  String get routeTitleNewVoucher => 'New voucher';

  @override
  String get routeTitleEditVoucher => 'Edit voucher';

  @override
  String get routeTitleNewExercise => 'New exercise';

  @override
  String get routeTitleEditExercise => 'Edit exercise';

  @override
  String get routeTitleNewClass => 'New class';

  @override
  String get routeTitleEditClass => 'Edit class';

  @override
  String get routeTitleClassDetails => 'Class details';

  @override
  String get routeTitleQuestionBank => 'Question bank';

  @override
  String get routeTitleLevels => 'Levels';

  @override
  String get routeTitleNewLevel => 'New level';

  @override
  String get routeTitleEditLevel => 'Edit level';

  @override
  String get routeTitleQuizzes => 'Quizzes';

  @override
  String get routeTitleSettings => 'Settings';

  @override
  String get routeTitlePriceList => 'Price list';

  @override
  String get routeTitleAuditLogs => 'Audit logs';

  @override
  String get routeTitleMaterials => 'Materials';

  @override
  String get routeTitleAdmin => 'Admin';

  @override
  String get routeTitleStudentProfile => 'Student profile';

  @override
  String get routeTitleCalendar => 'Calendar';

  @override
  String get routeTitleGrades => 'Grades';

  @override
  String get routeTitleTeacher => 'Guru';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty => 'No notifications yet.';

  @override
  String get teacherExAuthoringUnsupported =>
      'Creating and editing exercises is only available on web. Open Easy Study in a browser on desktop to manage exercises.';

  @override
  String get teacherExAuthoringAdminOnly =>
      'Creating and editing exercises is only available to admins on web.';

  @override
  String get teacherExAuthoringReadOnly =>
      'View only — browse published practice and assign it to murid. Creating and editing exercises is done on web.';

  @override
  String get worksheetUploadUnsupported =>
      'Worksheet upload is only available to admins on web. Open Easy Study in a browser on desktop to import worksheets.';

  @override
  String get worksheetStepPrepare => 'Prepare file';

  @override
  String get worksheetStepRead => 'Read file';

  @override
  String get worksheetStepDetect => 'Detect questions';

  @override
  String get worksheetStagePreparing => 'Preparing file…';

  @override
  String get worksheetStageReading => 'Reading your worksheet…';

  @override
  String get worksheetStageDetecting => 'Detecting question type…';

  @override
  String get worksheetStageDone => 'Done';

  @override
  String get cohortNoActivity => 'No activity';

  @override
  String get cohortToday => 'Today';

  @override
  String cohortDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get cohortNoHomework => 'No homework';

  @override
  String cohortHomeworkOverdueOf(int done, int assigned, int overdue) {
    return '$done/$assigned · $overdue overdue';
  }

  @override
  String cohortHomeworkDoneOf(int done, int assigned) {
    return '$done/$assigned done';
  }

  @override
  String attentionOverdue(String name) {
    return '$name has overdue practice';
  }

  @override
  String attentionStale(String name, int count) {
    return '$name has assigned practice not started (${count}d)';
  }

  @override
  String attentionInactive(String name, int count) {
    return '$name inactive for $count+ days';
  }

  @override
  String attentionNoSessions(String name) {
    return '$name has no class sessions left';
  }

  @override
  String attentionSessionsLeft(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count class sessions',
      one: '1 class session',
    );
    return '$name has $_temp0 left';
  }

  @override
  String activityScored(String name, int score) {
    return '$name scored $score%';
  }

  @override
  String activitySubmitted(int score) {
    return 'Practice submitted · $score%';
  }

  @override
  String get activityExerciseFallback => 'Exercise';

  @override
  String activityLessonCompletedBy(String name) {
    return '$name completed a lesson';
  }

  @override
  String get activityLessonCompleted => 'Lesson completed';

  @override
  String activityLessonFallback(String id) {
    return 'Lesson $id';
  }

  @override
  String activityAssignedTo(String name) {
    return 'Assigned practice to $name';
  }

  @override
  String get activityAssigned => 'Practice assigned';

  @override
  String get activityStudentFallback => 'Student';

  @override
  String activityJoined(String name) {
    return '$name joined a class';
  }

  @override
  String activityAdded(String name) {
    return 'You added $name to a class';
  }

  @override
  String get activityClassConcluded => 'Class concluded';

  @override
  String activityTermAddedFor(String name) {
    return 'Term package added for $name';
  }

  @override
  String get activityTermAdded => 'Term package added';

  @override
  String activityTermSubtitle(int count, String start, String end) {
    return '$count sessions · $start → $end';
  }

  @override
  String get commonNoHskLevel => 'No HSK level';

  @override
  String get exercisePlayExamIntroTitle => 'Before you start';

  @override
  String get exercisePlayOneAttempt =>
      'You get one attempt. Once you submit, you cannot take it again.';

  @override
  String exercisePlayTimeLimit(int minutes) {
    return 'Time limit: $minutes minutes. The clock keeps running if you close the page.';
  }

  @override
  String exercisePlayQuestionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count questions',
      one: '1 question',
    );
    return '$_temp0';
  }

  @override
  String get exercisePlayStart => 'Start';

  @override
  String get exercisePlayAttemptUsedTitle => 'Already submitted';

  @override
  String get exercisePlayAttemptUsedSubtitle =>
      'This exam allows one attempt. Your score is under Progress.';

  @override
  String get exercisePlayLateSubtitle =>
      'Submitted after the time limit, so it was not scored.';

  @override
  String get resultLate => 'Late';

  @override
  String get bankAiScanWorksheet => 'Scan paper with AI';

  @override
  String get bankScanWithoutAi => 'Scan without AI (on this device)';

  @override
  String get aiImportSending => 'Sending the file to the AI reader…';

  @override
  String get aiImportReading => 'The AI is reading the paper (about a minute)…';

  @override
  String aiImportCropping(int n, int total) {
    return 'Cutting out picture $n of $total…';
  }

  @override
  String aiImportSummary(
      String level, int questions, int sections, int pictures, int missing) {
    return 'AI reading · $level · $questions questions in $sections parts · $pictures pictures · $missing without an answer key (listening: add it later with Answer key on the worksheet)';
  }

  @override
  String aiImportFailed(String error) {
    return 'AI reading failed: $error';
  }

  @override
  String get aiImportNothingFound =>
      'The AI reader found no questions in this file.';

  @override
  String get bankSheetListeningAudio => 'Listening recording';

  @override
  String get bankSheetListeningAudioHelp =>
      'One recording for the whole listening part. Students hear it while they answer those questions.';

  @override
  String get bankSheetUploadAudio => 'Upload recording';

  @override
  String get bankSheetReplaceAudio => 'Replace';

  @override
  String get bankSheetRemoveAudio => 'Remove recording';

  @override
  String get bankSheetAudioAttached =>
      'Recording attached. Students get one player for the listening questions.';

  @override
  String get bankSheetAnswerKey => 'Answer key';

  @override
  String get bankSheetAnswerKeyHint =>
      'Type the key as printed: 1 D 2 A 3 C · 11 √ 12 × · 41-45 ECBAD. Numbers follow the order on this worksheet.';

  @override
  String get bankSheetAnswerKeyApply => 'Apply key';

  @override
  String bankSheetAnswerKeyApplied(int n) {
    return 'Answer key applied to $n questions.';
  }

  @override
  String get bankSheetAnswerKeyNone => 'No answers found in the text.';

  @override
  String bankSheetParts(int n) {
    return '$n parts';
  }

  @override
  String get bankEditorChoicePicture => 'Picture for this choice';

  @override
  String get exercisePlayListeningRecording => 'Listening recording';

  @override
  String get exercisePlayQuestionAudio => 'Audio for this question';

  @override
  String get exercisePlayPickPicture => 'Choose the picture';

  @override
  String get exercisePlayHskMarks => 'HSK marks';

  @override
  String get exercisePlayHskListening => 'Listening';

  @override
  String get exercisePlayHskReading => 'Reading';

  @override
  String get exercisePlayHskWriting => 'Writing';

  @override
  String exercisePlayHskTotal(int total, int max, int pass) {
    return 'Total $total of $max · pass mark $pass';
  }

  @override
  String get exercisePlayHskPassed => 'Passed';

  @override
  String get exercisePlayHskNotPassed => 'Not passed yet';
}
