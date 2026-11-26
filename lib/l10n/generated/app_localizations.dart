import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id')
  ];

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get commonEmail;

  /// No description provided for @commonPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get commonPassword;

  /// No description provided for @commonSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get commonSignIn;

  /// No description provided for @commonSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get commonSignOut;

  /// No description provided for @commonCreateNewAccount.
  ///
  /// In en, this message translates to:
  /// **'Create new account'**
  String get commonCreateNewAccount;

  /// No description provided for @commonRememberDevice.
  ///
  /// In en, this message translates to:
  /// **'Remember on this device'**
  String get commonRememberDevice;

  /// No description provided for @commonClassSession.
  ///
  /// In en, this message translates to:
  /// **'Class session'**
  String get commonClassSession;

  /// No description provided for @commonViewClassCalendar.
  ///
  /// In en, this message translates to:
  /// **'View class calendar'**
  String get commonViewClassCalendar;

  /// No description provided for @commonViewGrades.
  ///
  /// In en, this message translates to:
  /// **'View grades & transcript'**
  String get commonViewGrades;

  /// No description provided for @commonLearningMaterials.
  ///
  /// In en, this message translates to:
  /// **'Learning materials'**
  String get commonLearningMaterials;

  /// No description provided for @commonYourLevel.
  ///
  /// In en, this message translates to:
  /// **'Your level'**
  String get commonYourLevel;

  /// No description provided for @commonCodeHint.
  ///
  /// In en, this message translates to:
  /// **'6-character code'**
  String get commonCodeHint;

  /// No description provided for @commonHskLevel.
  ///
  /// In en, this message translates to:
  /// **'HSK level'**
  String get commonHskLevel;

  /// No description provided for @commonLessonsPerTerm.
  ///
  /// In en, this message translates to:
  /// **'Lessons per term'**
  String get commonLessonsPerTerm;

  /// No description provided for @commonLessonsPerTermOption.
  ///
  /// In en, this message translates to:
  /// **'{count} lessons per term'**
  String commonLessonsPerTermOption(int count);

  /// No description provided for @commonCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get commonCompleted;

  /// No description provided for @commonFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get commonFull;

  /// No description provided for @commonSpotsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 spot left} other{{count} spots left}}'**
  String commonSpotsLeft(int count);

  /// No description provided for @commonCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get commonCopy;

  /// No description provided for @commonStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get commonStudent;

  /// No description provided for @commonParent.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get commonParent;

  /// No description provided for @pushRowLabel.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get pushRowLabel;

  /// No description provided for @pushRowHint.
  ///
  /// In en, this message translates to:
  /// **'Reminders on this device when something is due or graded.'**
  String get pushRowHint;

  /// No description provided for @pushRowBlocked.
  ///
  /// In en, this message translates to:
  /// **'Notifications are blocked in the browser or phone settings.'**
  String get pushRowBlocked;

  /// No description provided for @pushEnableFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not turn on notifications. Try again.'**
  String get pushEnableFailed;

  /// No description provided for @languageRowLabel.
  ///
  /// In en, this message translates to:
  /// **'Bahasa / Language'**
  String get languageRowLabel;

  /// No description provided for @languageToggleIndonesian.
  ///
  /// In en, this message translates to:
  /// **'Bahasa Indonesia'**
  String get languageToggleIndonesian;

  /// No description provided for @languageToggleEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageToggleEnglish;

  /// No description provided for @themeRowLabel.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get themeRowLabel;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeSystemHint.
  ///
  /// In en, this message translates to:
  /// **'System: follows your phone or computer setting.'**
  String get themeSystemHint;

  /// No description provided for @textSizeRowLabel.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get textSizeRowLabel;

  /// No description provided for @textSizeNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get textSizeNormal;

  /// No description provided for @textSizeBig.
  ///
  /// In en, this message translates to:
  /// **'Big'**
  String get textSizeBig;

  /// No description provided for @textSizeBigger.
  ///
  /// In en, this message translates to:
  /// **'Bigger'**
  String get textSizeBigger;

  /// No description provided for @appearanceMenuTooltip.
  ///
  /// In en, this message translates to:
  /// **'Appearance: dark mode and text size'**
  String get appearanceMenuTooltip;

  /// No description provided for @authBrandHeadline.
  ///
  /// In en, this message translates to:
  /// **'Learn Chinese,\nthe easy way.'**
  String get authBrandHeadline;

  /// No description provided for @teacherLinkCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Teacher link code'**
  String get teacherLinkCodeLabel;

  /// No description provided for @teacherLinkCodeHelper.
  ///
  /// In en, this message translates to:
  /// **'Ask your teacher for the current code (refreshes every 15 min)'**
  String get teacherLinkCodeHelper;

  /// No description provided for @teacherLinkCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your teacher link code'**
  String get teacherLinkCodeRequired;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap an account to sign in'**
  String get loginSubtitle;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign in failed'**
  String get loginFailed;

  /// No description provided for @loginProfileLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Signed in, but your profile could not be loaded ({code}). Check your connection and try again.'**
  String loginProfileLoadFailed(String code);

  /// No description provided for @loginRemoveAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove account?'**
  String get loginRemoveAccountTitle;

  /// No description provided for @loginRemoveAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from this device? You can sign in again later.'**
  String loginRemoveAccountBody(String name);

  /// No description provided for @loginRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get loginRemove;

  /// No description provided for @loginResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get loginResetTitle;

  /// No description provided for @loginResetBody.
  ///
  /// In en, this message translates to:
  /// **'Enter your account email. We\'ll send a link to set a new password.'**
  String get loginResetBody;

  /// No description provided for @loginSendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get loginSendResetLink;

  /// No description provided for @loginResetSent.
  ///
  /// In en, this message translates to:
  /// **'If {email} has an account, a reset link is on its way. Check your inbox and spam folder.'**
  String loginResetSent(String email);

  /// No description provided for @loginResetInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'That email address doesn\'t look right. Check it and try again.'**
  String get loginResetInvalidEmail;

  /// No description provided for @loginResetTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a few minutes and try again.'**
  String get loginResetTooManyRequests;

  /// No description provided for @loginResetFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send the reset link. Try again.'**
  String get loginResetFailed;

  /// No description provided for @loginWithAnotherEmail.
  ///
  /// In en, this message translates to:
  /// **'Sign in with another email'**
  String get loginWithAnotherEmail;

  /// No description provided for @loginAnotherAccount.
  ///
  /// In en, this message translates to:
  /// **'Another account'**
  String get loginAnotherAccount;

  /// No description provided for @loginForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get loginForgotPassword;

  /// No description provided for @loginBackToAccountList.
  ///
  /// In en, this message translates to:
  /// **'Back to account list'**
  String get loginBackToAccountList;

  /// No description provided for @loginBackToTestLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to test login'**
  String get loginBackToTestLogin;

  /// No description provided for @loginNoSavedAccounts.
  ///
  /// In en, this message translates to:
  /// **'No saved accounts yet'**
  String get loginNoSavedAccounts;

  /// No description provided for @loginNoSavedAccountsHint.
  ///
  /// In en, this message translates to:
  /// **'Sign in once and your account will appear here for quick access next time.'**
  String get loginNoSavedAccountsHint;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join Easy Study as a student or parent'**
  String get registerSubtitle;

  /// No description provided for @registerErrorEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered. Try Sign in instead.'**
  String get registerErrorEmailInUse;

  /// No description provided for @registerErrorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak. Use at least 6 characters.'**
  String get registerErrorWeakPassword;

  /// No description provided for @registerErrorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address.'**
  String get registerErrorInvalidEmail;

  /// No description provided for @registerErrorOperationNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Email/password sign-in is disabled in Firebase.'**
  String get registerErrorOperationNotAllowed;

  /// No description provided for @registerErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Registration failed ({code})'**
  String registerErrorGeneric(String code);

  /// No description provided for @registerErrorPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Firestore blocked this action. Publish firestore.rules from the project.'**
  String get registerErrorPermissionDenied;

  /// No description provided for @registerErrorFirebase.
  ///
  /// In en, this message translates to:
  /// **'Firebase error ({code})'**
  String registerErrorFirebase(String code);

  /// No description provided for @registerEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get registerEmailInvalid;

  /// No description provided for @registerPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Minimum 6 characters'**
  String get registerPasswordTooShort;

  /// No description provided for @registerChildCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Child access code'**
  String get registerChildCodeLabel;

  /// No description provided for @registerChildCodeHelper.
  ///
  /// In en, this message translates to:
  /// **'Find this in your child\'s Profile under \'Parent access\'.'**
  String get registerChildCodeHelper;

  /// No description provided for @registerChildCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your child access code'**
  String get registerChildCodeRequired;

  /// No description provided for @registerSubmitParent.
  ///
  /// In en, this message translates to:
  /// **'Register as parent'**
  String get registerSubmitParent;

  /// No description provided for @identityNameIndonesian.
  ///
  /// In en, this message translates to:
  /// **'Indonesian name'**
  String get identityNameIndonesian;

  /// No description provided for @identityNameIndonesianRequired.
  ///
  /// In en, this message translates to:
  /// **'Indonesian name is required'**
  String get identityNameIndonesianRequired;

  /// No description provided for @identityNameChinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese name'**
  String get identityNameChinese;

  /// No description provided for @identityNameChineseOptional.
  ///
  /// In en, this message translates to:
  /// **'Chinese name (optional)'**
  String get identityNameChineseOptional;

  /// No description provided for @identityNameChineseRequired.
  ///
  /// In en, this message translates to:
  /// **'Chinese name is required'**
  String get identityNameChineseRequired;

  /// No description provided for @identityWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp number'**
  String get identityWhatsapp;

  /// No description provided for @identityWhatsappOptional.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp number (optional)'**
  String get identityWhatsappOptional;

  /// No description provided for @identityWhatsappRequired.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp number is required'**
  String get identityWhatsappRequired;

  /// No description provided for @identityParentSection.
  ///
  /// In en, this message translates to:
  /// **'Parent / guardian'**
  String get identityParentSection;

  /// No description provided for @identityParentSectionHint.
  ///
  /// In en, this message translates to:
  /// **'Contact details for the student family.'**
  String get identityParentSectionHint;

  /// No description provided for @identityParentName.
  ///
  /// In en, this message translates to:
  /// **'Parent name'**
  String get identityParentName;

  /// No description provided for @identityParentNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Parent name (optional)'**
  String get identityParentNameOptional;

  /// No description provided for @identityParentNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Parent name is required'**
  String get identityParentNameRequired;

  /// No description provided for @identityParentPhone.
  ///
  /// In en, this message translates to:
  /// **'Parent telephone'**
  String get identityParentPhone;

  /// No description provided for @identityParentPhoneOptional.
  ///
  /// In en, this message translates to:
  /// **'Parent telephone (optional)'**
  String get identityParentPhoneOptional;

  /// No description provided for @identityParentPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Parent telephone is required'**
  String get identityParentPhoneRequired;

  /// No description provided for @completeProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get completeProfileTitle;

  /// No description provided for @completeProfileMissing.
  ///
  /// In en, this message translates to:
  /// **'We found your login, but your profile data is missing.'**
  String get completeProfileMissing;

  /// No description provided for @completeProfileFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not complete profile'**
  String get completeProfileFailed;

  /// No description provided for @completeProfileSave.
  ///
  /// In en, this message translates to:
  /// **'Save profile'**
  String get completeProfileSave;

  /// No description provided for @studentNavHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get studentNavHome;

  /// No description provided for @studentNavMyClasses.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get studentNavMyClasses;

  /// No description provided for @studentNavLessons.
  ///
  /// In en, this message translates to:
  /// **'Lessons'**
  String get studentNavLessons;

  /// No description provided for @studentNavProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get studentNavProgress;

  /// No description provided for @navPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get navPayments;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @studentHomeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String studentHomeGreeting(String name);

  /// No description provided for @studentHomeContinueLearning.
  ///
  /// In en, this message translates to:
  /// **'Continue learning'**
  String get studentHomeContinueLearning;

  /// No description provided for @studentHomeNoPracticeTitle.
  ///
  /// In en, this message translates to:
  /// **'No practice yet'**
  String get studentHomeNoPracticeTitle;

  /// No description provided for @studentHomeNoPracticeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set your HSK level in Profile to unlock exercises, or wait for new practice to be published.'**
  String get studentHomeNoPracticeSubtitle;

  /// No description provided for @studentHomeLevelPractice.
  ///
  /// In en, this message translates to:
  /// **'{level} practice'**
  String studentHomeLevelPractice(String level);

  /// No description provided for @studentHomeNextLesson.
  ///
  /// In en, this message translates to:
  /// **'Next lesson'**
  String get studentHomeNextLesson;

  /// No description provided for @studentHomeLessonMeta.
  ///
  /// In en, this message translates to:
  /// **'{term} · Lesson {order}'**
  String studentHomeLessonMeta(String term, int order);

  /// No description provided for @studentHomeAllDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'All lessons done'**
  String get studentHomeAllDoneTitle;

  /// No description provided for @studentHomeAllDoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Great work — you completed every available lesson.'**
  String get studentHomeAllDoneSubtitle;

  /// No description provided for @studentHomeCompletedPractice.
  ///
  /// In en, this message translates to:
  /// **'Completed practice'**
  String get studentHomeCompletedPractice;

  /// No description provided for @studentHomeSessionsLeft.
  ///
  /// In en, this message translates to:
  /// **'Sessions left'**
  String get studentHomeSessionsLeft;

  /// No description provided for @studentHomeExercisesDone.
  ///
  /// In en, this message translates to:
  /// **'Exercises done'**
  String get studentHomeExercisesDone;

  /// No description provided for @studentHomeAvgScore.
  ///
  /// In en, this message translates to:
  /// **'Avg. score'**
  String get studentHomeAvgScore;

  /// No description provided for @studentHomeStreak.
  ///
  /// In en, this message translates to:
  /// **'{days}-day streak'**
  String studentHomeStreak(int days);

  /// No description provided for @studentHomeBest.
  ///
  /// In en, this message translates to:
  /// **'best {score}%'**
  String studentHomeBest(int score);

  /// No description provided for @studentHomeUntil.
  ///
  /// In en, this message translates to:
  /// **'until {date}'**
  String studentHomeUntil(String date);

  /// No description provided for @studentHomeNoVoucher.
  ///
  /// In en, this message translates to:
  /// **'no voucher yet'**
  String get studentHomeNoVoucher;

  /// No description provided for @studentHomeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all ({count})'**
  String studentHomeSeeAll(int count);

  /// No description provided for @studentHomeSeeScores.
  ///
  /// In en, this message translates to:
  /// **'{count} done · see your scores'**
  String studentHomeSeeScores(int count);

  /// No description provided for @studentHomeQuickCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get studentHomeQuickCalendar;

  /// No description provided for @studentHomeQuickGrades.
  ///
  /// In en, this message translates to:
  /// **'Grades'**
  String get studentHomeQuickGrades;

  /// No description provided for @studentHomeQuickMaterials.
  ///
  /// In en, this message translates to:
  /// **'Materials'**
  String get studentHomeQuickMaterials;

  /// No description provided for @studentHomeQuickHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get studentHomeQuickHistory;

  /// No description provided for @studentJoinTitle.
  ///
  /// In en, this message translates to:
  /// **'Join class session'**
  String get studentJoinTitle;

  /// No description provided for @studentJoinHint.
  ///
  /// In en, this message translates to:
  /// **'Pick an open class below. You stay joined until the teacher concludes it.'**
  String get studentJoinHint;

  /// No description provided for @studentJoinNoSessionsTitle.
  ///
  /// In en, this message translates to:
  /// **'No open sessions'**
  String get studentJoinNoSessionsTitle;

  /// No description provided for @studentJoinNoSessionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No class sessions are open right now. Check back later.'**
  String get studentJoinNoSessionsSubtitle;

  /// No description provided for @studentJoinPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Could not join: permission denied.'**
  String get studentJoinPermissionDenied;

  /// No description provided for @studentJoinFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not join ({code})'**
  String studentJoinFailed(String code);

  /// No description provided for @studentJoinClassFullTitle.
  ///
  /// In en, this message translates to:
  /// **'Class is full'**
  String get studentJoinClassFullTitle;

  /// No description provided for @studentJoinClassFullBody.
  ///
  /// In en, this message translates to:
  /// **'This class has reached its capacity of {capacity, plural, =1{1 student} other{{capacity} students}} ({joined}/{capacity} joined). Try another session or check back later.'**
  String studentJoinClassFullBody(int capacity, int joined);

  /// No description provided for @studentJoinJoined.
  ///
  /// In en, this message translates to:
  /// **'You joined this session'**
  String get studentJoinJoined;

  /// No description provided for @studentJoinLeftClass.
  ///
  /// In en, this message translates to:
  /// **'You left this class'**
  String get studentJoinLeftClass;

  /// No description provided for @studentJoinCount.
  ///
  /// In en, this message translates to:
  /// **'{joined} / {capacity} joined'**
  String studentJoinCount(int joined, int capacity);

  /// No description provided for @studentJoinView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get studentJoinView;

  /// No description provided for @studentJoinLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get studentJoinLeave;

  /// No description provided for @studentJoinNoSessionsLeft.
  ///
  /// In en, this message translates to:
  /// **'No sessions'**
  String get studentJoinNoSessionsLeft;

  /// No description provided for @studentJoinJoin.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get studentJoinJoin;

  /// No description provided for @studentLessonsNoContentTitle.
  ///
  /// In en, this message translates to:
  /// **'No content yet'**
  String get studentLessonsNoContentTitle;

  /// No description provided for @studentLessonsNoDemoData.
  ///
  /// In en, this message translates to:
  /// **'No demo data yet — run scripts/seed_test_accounts.sh then python3 scripts/seed_report_demo_data.py'**
  String get studentLessonsNoDemoData;

  /// No description provided for @studentLessonsSetLevel.
  ///
  /// In en, this message translates to:
  /// **'Set your HSK level in Profile to unlock practice and lessons.'**
  String get studentLessonsSetLevel;

  /// No description provided for @studentLessonsWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Published {level} exercises and lessons will appear here.'**
  String studentLessonsWillAppear(String level);

  /// No description provided for @studentLessonsExercisesHeader.
  ///
  /// In en, this message translates to:
  /// **'{level} exercises ({count})'**
  String studentLessonsExercisesHeader(String level, int count);

  /// No description provided for @studentLessonsNoExercisesTitle.
  ///
  /// In en, this message translates to:
  /// **'No exercises yet'**
  String get studentLessonsNoExercisesTitle;

  /// No description provided for @studentLessonsNoExercisesSetLevel.
  ///
  /// In en, this message translates to:
  /// **'Set your HSK level in Profile to see practice exercises.'**
  String get studentLessonsNoExercisesSetLevel;

  /// No description provided for @studentLessonsNoPublishedExercises.
  ///
  /// In en, this message translates to:
  /// **'No published {level} exercises yet.'**
  String studentLessonsNoPublishedExercises(String level);

  /// No description provided for @studentLessonsLevelTermInfo.
  ///
  /// In en, this message translates to:
  /// **'{level} · {count} lessons per term'**
  String studentLessonsLevelTermInfo(String level, int count);

  /// No description provided for @studentLessonsTermHeader.
  ///
  /// In en, this message translates to:
  /// **'Term {term} ({count, plural, =1{1 lesson} other{{count} lessons}})'**
  String studentLessonsTermHeader(String term, int count);

  /// No description provided for @studentLessonsQuizScore.
  ///
  /// In en, this message translates to:
  /// **'Quiz: {score}%'**
  String studentLessonsQuizScore(String score);

  /// No description provided for @studentMyClassesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No classes joined yet'**
  String get studentMyClassesEmptyTitle;

  /// No description provided for @studentMyClassesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Go to Home and tap Join on an open class session.'**
  String get studentMyClassesEmptySubtitle;

  /// No description provided for @studentMyClassesTapToSee.
  ///
  /// In en, this message translates to:
  /// **'Tap to see who joined'**
  String get studentMyClassesTapToSee;

  /// No description provided for @historyVouchersTitle.
  ///
  /// In en, this message translates to:
  /// **'Your vouchers'**
  String get historyVouchersTitle;

  /// No description provided for @historyNoVouchers.
  ///
  /// In en, this message translates to:
  /// **'No voucher yet. After you pay for a package the admin adds it here.'**
  String get historyNoVouchers;

  /// No description provided for @historyVoucherTitle.
  ///
  /// In en, this message translates to:
  /// **'{sessions}-session voucher'**
  String historyVoucherTitle(int sessions);

  /// No description provided for @historyValid.
  ///
  /// In en, this message translates to:
  /// **'Valid {start} – {end}'**
  String historyValid(String start, String end);

  /// No description provided for @historyStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get historyStatusActive;

  /// No description provided for @historyStatusUsedUp.
  ///
  /// In en, this message translates to:
  /// **'Used up'**
  String get historyStatusUsedUp;

  /// No description provided for @historyStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get historyStatusExpired;

  /// No description provided for @historySessionsUsed.
  ///
  /// In en, this message translates to:
  /// **'{used} of {total} sessions used'**
  String historySessionsUsed(int used, int total);

  /// No description provided for @historyRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} left'**
  String historyRemaining(int count);

  /// No description provided for @historyShowSessions.
  ///
  /// In en, this message translates to:
  /// **'Show classes ({count})'**
  String historyShowSessions(int count);

  /// No description provided for @historyHideSessions.
  ///
  /// In en, this message translates to:
  /// **'Hide classes'**
  String get historyHideSessions;

  /// No description provided for @historyNoSessionsYet.
  ///
  /// In en, this message translates to:
  /// **'No class has been charged to this voucher yet.'**
  String get historyNoSessionsYet;

  /// No description provided for @historyAllClasses.
  ///
  /// In en, this message translates to:
  /// **'All classes'**
  String get historyAllClasses;

  /// No description provided for @historyClassesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} classes'**
  String historyClassesCount(int count);

  /// No description provided for @attendancePresent.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get attendancePresent;

  /// No description provided for @attendanceExcused.
  ///
  /// In en, this message translates to:
  /// **'Excused'**
  String get attendanceExcused;

  /// No description provided for @attendanceAbsent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get attendanceAbsent;

  /// No description provided for @attendanceJoined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get attendanceJoined;

  /// No description provided for @studentPaymentsDisabledTitle.
  ///
  /// In en, this message translates to:
  /// **'Payments are disabled'**
  String get studentPaymentsDisabledTitle;

  /// No description provided for @studentPaymentsDisabledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your centre is not collecting payments through the app right now. Contact your teacher about session packages.'**
  String get studentPaymentsDisabledSubtitle;

  /// No description provided for @studentPaymentsInvoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get studentPaymentsInvoices;

  /// No description provided for @studentPaymentsNoInvoices.
  ///
  /// In en, this message translates to:
  /// **'No invoices yet. Your teacher will bill you for session packages here.'**
  String get studentPaymentsNoInvoices;

  /// No description provided for @studentPaymentsSessionsRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 session remaining} other{{count} sessions remaining}}'**
  String studentPaymentsSessionsRemaining(int count);

  /// No description provided for @studentPaymentsQuotaHint.
  ///
  /// In en, this message translates to:
  /// **'Sessions are added automatically when a payment is confirmed.'**
  String get studentPaymentsQuotaHint;

  /// No description provided for @studentPaymentsParentHandles.
  ///
  /// In en, this message translates to:
  /// **'Payments are handled by {name}.'**
  String studentPaymentsParentHandles(String name);

  /// No description provided for @studentPaymentsParentHandlesHint.
  ///
  /// In en, this message translates to:
  /// **'Your parent sees the same invoices and can pay them. You can still pay one yourself below if needed.'**
  String get studentPaymentsParentHandlesHint;

  /// No description provided for @studentProgressNoProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'No progress yet'**
  String get studentProgressNoProgressTitle;

  /// No description provided for @studentProgressNoProgressSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Complete a lesson or quiz to see your history here.'**
  String get studentProgressNoProgressSubtitle;

  /// No description provided for @studentProgressNoLessonsTitle.
  ///
  /// In en, this message translates to:
  /// **'No lessons yet'**
  String get studentProgressNoLessonsTitle;

  /// No description provided for @studentProgressNoLessonsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No lessons for {level} yet.'**
  String studentProgressNoLessonsSubtitle(String level);

  /// No description provided for @studentProgressYourHskLevel.
  ///
  /// In en, this message translates to:
  /// **'your HSK level'**
  String get studentProgressYourHskLevel;

  /// No description provided for @studentProgressTermSize.
  ///
  /// In en, this message translates to:
  /// **'Term size'**
  String get studentProgressTermSize;

  /// No description provided for @studentProgressStartFirst.
  ///
  /// In en, this message translates to:
  /// **'Start your first lesson to track progress'**
  String get studentProgressStartFirst;

  /// No description provided for @studentProgressTermPlan.
  ///
  /// In en, this message translates to:
  /// **'Your term plan'**
  String get studentProgressTermPlan;

  /// No description provided for @studentProgressCurrentTerm.
  ///
  /// In en, this message translates to:
  /// **'Current term'**
  String get studentProgressCurrentTerm;

  /// No description provided for @studentProgressLessons.
  ///
  /// In en, this message translates to:
  /// **'Lessons'**
  String get studentProgressLessons;

  /// No description provided for @studentProgressExercises.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get studentProgressExercises;

  /// No description provided for @studentProgressAttempts.
  ///
  /// In en, this message translates to:
  /// **'Attempts'**
  String get studentProgressAttempts;

  /// No description provided for @studentProgressAvgScore.
  ///
  /// In en, this message translates to:
  /// **'Avg. score'**
  String get studentProgressAvgScore;

  /// No description provided for @studentProgressBestScore.
  ///
  /// In en, this message translates to:
  /// **'Best score'**
  String get studentProgressBestScore;

  /// No description provided for @studentProgressNoExercisesTitle.
  ///
  /// In en, this message translates to:
  /// **'No exercises finished yet'**
  String get studentProgressNoExercisesTitle;

  /// No description provided for @studentProgressNoExercisesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Finish an exercise from Home or Lessons and your scores will appear here.'**
  String get studentProgressNoExercisesSubtitle;

  /// No description provided for @resultCorrectOf.
  ///
  /// In en, this message translates to:
  /// **'{correct}/{total} correct'**
  String resultCorrectOf(int correct, int total);

  /// No description provided for @commonExerciseFallback.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get commonExerciseFallback;

  /// No description provided for @studentProfileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get studentProfileUpdated;

  /// No description provided for @studentProfilePersonalTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal information'**
  String get studentProfilePersonalTitle;

  /// No description provided for @studentProfilePersonalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Indonesian and Chinese names, WhatsApp, and parent contacts.'**
  String get studentProfilePersonalSubtitle;

  /// No description provided for @studentProfileLearningTitle.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get studentProfileLearningTitle;

  /// No description provided for @studentProfileLearningSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your HSK level controls which practice exercises you see.'**
  String get studentProfileLearningSubtitle;

  /// No description provided for @studentProfileLevelSetByCentre.
  ///
  /// In en, this message translates to:
  /// **'Your HSK level is set by the centre and decides which practice you see. Ask your teacher if it looks wrong.'**
  String get studentProfileLevelSetByCentre;

  /// No description provided for @studentProfileCodeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not generate code: {error}'**
  String studentProfileCodeFailed(String error);

  /// No description provided for @studentProfileParentAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Parent access'**
  String get studentProfileParentAccessTitle;

  /// No description provided for @studentProfileParentAccessBody.
  ///
  /// In en, this message translates to:
  /// **'Share this code with a parent so they can register and follow your progress (read-only).'**
  String get studentProfileParentAccessBody;

  /// No description provided for @studentProfileCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get studentProfileCodeCopied;

  /// No description provided for @studentProfileShowParentCode.
  ///
  /// In en, this message translates to:
  /// **'Show parent access code'**
  String get studentProfileShowParentCode;

  /// No description provided for @studentClassLeaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not leave class ({code})'**
  String studentClassLeaveFailed(String code);

  /// No description provided for @studentClassNotFound.
  ///
  /// In en, this message translates to:
  /// **'Class not found'**
  String get studentClassNotFound;

  /// No description provided for @studentClassYourTeacher.
  ///
  /// In en, this message translates to:
  /// **'Your teacher'**
  String get studentClassYourTeacher;

  /// No description provided for @studentClassTimeAndTeacher.
  ///
  /// In en, this message translates to:
  /// **'{time} · Teacher: {teacher}'**
  String studentClassTimeAndTeacher(String time, String teacher);

  /// No description provided for @studentClassStudentsJoined.
  ///
  /// In en, this message translates to:
  /// **'{joined}/{capacity} students joined'**
  String studentClassStudentsJoined(int joined, int capacity);

  /// No description provided for @studentClassLeaveClass.
  ///
  /// In en, this message translates to:
  /// **'Leave class'**
  String get studentClassLeaveClass;

  /// No description provided for @studentClassWhoJoined.
  ///
  /// In en, this message translates to:
  /// **'Who joined ({count})'**
  String studentClassWhoJoined(int count);

  /// No description provided for @studentClassNoneJoined.
  ///
  /// In en, this message translates to:
  /// **'No students have joined yet.'**
  String get studentClassNoneJoined;

  /// No description provided for @studentClassYou.
  ///
  /// In en, this message translates to:
  /// **'{name} (you)'**
  String studentClassYou(String name);

  /// No description provided for @studentClassJoinedFromApp.
  ///
  /// In en, this message translates to:
  /// **'Joined from app'**
  String get studentClassJoinedFromApp;

  /// No description provided for @studentClassAddedByTeacher.
  ///
  /// In en, this message translates to:
  /// **'Added by teacher'**
  String get studentClassAddedByTeacher;

  /// No description provided for @lessonDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Lesson'**
  String get lessonDetailTitle;

  /// No description provided for @lessonDetailNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Lesson not found'**
  String get lessonDetailNotFoundTitle;

  /// No description provided for @lessonDetailNotFoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This lesson may have been removed.'**
  String get lessonDetailNotFoundSubtitle;

  /// No description provided for @lessonDetailVocabulary.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary & notes'**
  String get lessonDetailVocabulary;

  /// No description provided for @lessonDetailStartQuiz.
  ///
  /// In en, this message translates to:
  /// **'Start quiz'**
  String get lessonDetailStartQuiz;

  /// No description provided for @parentNavOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get parentNavOverview;

  /// No description provided for @parentNavCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get parentNavCalendar;

  /// No description provided for @parentNoChildrenTitle.
  ///
  /// In en, this message translates to:
  /// **'No children linked'**
  String get parentNoChildrenTitle;

  /// No description provided for @parentNoChildrenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ask your centre admin to link your account to your child, or register again with your child access code.'**
  String get parentNoChildrenSubtitle;

  /// No description provided for @parentChildLabel.
  ///
  /// In en, this message translates to:
  /// **'Child'**
  String get parentChildLabel;

  /// No description provided for @parentOverviewSessionsRemaining.
  ///
  /// In en, this message translates to:
  /// **'Sessions remaining'**
  String get parentOverviewSessionsRemaining;

  /// No description provided for @parentOverviewLessonsDone.
  ///
  /// In en, this message translates to:
  /// **'Lessons done'**
  String get parentOverviewLessonsDone;

  /// No description provided for @parentOverviewAvgScore.
  ///
  /// In en, this message translates to:
  /// **'Avg score'**
  String get parentOverviewAvgScore;

  /// No description provided for @parentOverviewRecentGrades.
  ///
  /// In en, this message translates to:
  /// **'Recent grades'**
  String get parentOverviewRecentGrades;

  /// No description provided for @parentOverviewNoGrades.
  ///
  /// In en, this message translates to:
  /// **'No graded practice yet.'**
  String get parentOverviewNoGrades;

  /// No description provided for @parentOverviewPractice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get parentOverviewPractice;

  /// No description provided for @parentOverviewRecentClasses.
  ///
  /// In en, this message translates to:
  /// **'Recent classes'**
  String get parentOverviewRecentClasses;

  /// No description provided for @parentOverviewClassHistory.
  ///
  /// In en, this message translates to:
  /// **'Classes and vouchers'**
  String get parentOverviewClassHistory;

  /// No description provided for @parentOverviewNoClasses.
  ///
  /// In en, this message translates to:
  /// **'No classes attended yet.'**
  String get parentOverviewNoClasses;

  /// No description provided for @parentPaymentsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No invoices'**
  String get parentPaymentsEmptyTitle;

  /// No description provided for @parentPaymentsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Invoices for your child will appear here.'**
  String get parentPaymentsEmptySubtitle;

  /// No description provided for @parentProfileRole.
  ///
  /// In en, this message translates to:
  /// **'Orang Tua (Parent)'**
  String get parentProfileRole;

  /// No description provided for @parentProfileLinkedChildren.
  ///
  /// In en, this message translates to:
  /// **'Linked children'**
  String get parentProfileLinkedChildren;

  /// No description provided for @parentProfileNoChildren.
  ///
  /// In en, this message translates to:
  /// **'No children linked yet. Ask your admin to link your account.'**
  String get parentProfileNoChildren;

  /// No description provided for @exercisePlayNotAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Exercise not available'**
  String get exercisePlayNotAvailableTitle;

  /// No description provided for @exercisePlayNotAvailableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This exercise has not been assigned to you. Ask your teacher.'**
  String get exercisePlayNotAvailableSubtitle;

  /// No description provided for @exercisePlayLegacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Old exercise format'**
  String get exercisePlayLegacyTitle;

  /// No description provided for @exercisePlayLegacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'This exercise was made before the question bank and can no longer be played. Ask your teacher for a new one.'**
  String get exercisePlayLegacySubtitle;

  /// No description provided for @exercisePlayLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load the exercise'**
  String get exercisePlayLoadFailedTitle;

  /// No description provided for @exercisePlayNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Exercise not found'**
  String get exercisePlayNotFoundTitle;

  /// No description provided for @exercisePlayNotFoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This exercise may have been removed.'**
  String get exercisePlayNotFoundSubtitle;

  /// No description provided for @exercisePlayNoQuestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'No questions yet'**
  String get exercisePlayNoQuestionsTitle;

  /// No description provided for @exercisePlayNoQuestionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your teacher has not added questions to this exercise.'**
  String get exercisePlayNoQuestionsSubtitle;

  /// No description provided for @exercisePlayChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking your answers…'**
  String get exercisePlayChecking;

  /// No description provided for @exercisePlayCouldNotSubmitTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not submit'**
  String get exercisePlayCouldNotSubmitTitle;

  /// No description provided for @exercisePlayCouldNotSubmitMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not submit.'**
  String get exercisePlayCouldNotSubmitMessage;

  /// No description provided for @exercisePlayCheckConnection.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get exercisePlayCheckConnection;

  /// No description provided for @exercisePlayTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get exercisePlayTryAgain;

  /// No description provided for @exercisePlayDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get exercisePlayDone;

  /// No description provided for @exercisePlayTimeUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Time\'s up. The answers you gave were submitted.'**
  String get exercisePlayTimeUpSubtitle;

  /// No description provided for @exercisePlayReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get exercisePlayReview;

  /// No description provided for @exercisePlaySubmitNowTitle.
  ///
  /// In en, this message translates to:
  /// **'Submit now?'**
  String get exercisePlaySubmitNowTitle;

  /// No description provided for @exercisePlayUnansweredWarning.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 question has no answer yet. It will count as wrong.} other{{count} questions have no answer yet. They will count as wrong.}}'**
  String exercisePlayUnansweredWarning(int count);

  /// No description provided for @exercisePlayKeepAnswering.
  ///
  /// In en, this message translates to:
  /// **'Keep answering'**
  String get exercisePlayKeepAnswering;

  /// No description provided for @exercisePlaySubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get exercisePlaySubmit;

  /// No description provided for @exercisePlaySentenceOf.
  ///
  /// In en, this message translates to:
  /// **'Sentence {current} of {total}'**
  String exercisePlaySentenceOf(int current, int total);

  /// No description provided for @exercisePlayBlankOf.
  ///
  /// In en, this message translates to:
  /// **'Blank {current} of {total}'**
  String exercisePlayBlankOf(int current, int total);

  /// No description provided for @exercisePlayMatchOf.
  ///
  /// In en, this message translates to:
  /// **'Match {current} of {total}'**
  String exercisePlayMatchOf(int current, int total);

  /// No description provided for @exercisePlayQuestionOf.
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}'**
  String exercisePlayQuestionOf(int current, int total);

  /// No description provided for @exercisePlayAnsweredOf.
  ///
  /// In en, this message translates to:
  /// **'{answered} of {total} answered'**
  String exercisePlayAnsweredOf(int answered, int total);

  /// No description provided for @exercisePlayComposePrompt.
  ///
  /// In en, this message translates to:
  /// **'Arrange the words to form a correct sentence'**
  String get exercisePlayComposePrompt;

  /// No description provided for @exercisePlayComposeHint.
  ///
  /// In en, this message translates to:
  /// **'Tap words below to build your sentence'**
  String get exercisePlayComposeHint;

  /// No description provided for @exercisePlayComposeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your sentence appears here…'**
  String get exercisePlayComposeEmpty;

  /// No description provided for @exercisePlayWordBank.
  ///
  /// In en, this message translates to:
  /// **'Word bank'**
  String get exercisePlayWordBank;

  /// No description provided for @exercisePlayPictureSentencePrompt.
  ///
  /// In en, this message translates to:
  /// **'Write a sentence that uses this word:'**
  String get exercisePlayPictureSentencePrompt;

  /// No description provided for @exercisePlayClozeLabel.
  ///
  /// In en, this message translates to:
  /// **'Choose the word for the blank'**
  String get exercisePlayClozeLabel;

  /// No description provided for @exercisePlayPromptLabel.
  ///
  /// In en, this message translates to:
  /// **'Prompt'**
  String get exercisePlayPromptLabel;

  /// No description provided for @exercisePlayChooseResponse.
  ///
  /// In en, this message translates to:
  /// **'Choose the best response'**
  String get exercisePlayChooseResponse;

  /// No description provided for @exercisePlayBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get exercisePlayBack;

  /// No description provided for @exercisePlaySubmitAnswers.
  ///
  /// In en, this message translates to:
  /// **'Submit answers'**
  String get exercisePlaySubmitAnswers;

  /// No description provided for @exercisePlayNextSentence.
  ///
  /// In en, this message translates to:
  /// **'Next sentence'**
  String get exercisePlayNextSentence;

  /// No description provided for @exercisePlayNextMatch.
  ///
  /// In en, this message translates to:
  /// **'Next match'**
  String get exercisePlayNextMatch;

  /// No description provided for @exercisePlayNextQuestion.
  ///
  /// In en, this message translates to:
  /// **'Next question'**
  String get exercisePlayNextQuestion;

  /// No description provided for @exercisePlaySubmitAllNow.
  ///
  /// In en, this message translates to:
  /// **'Submit all answers now'**
  String get exercisePlaySubmitAllNow;

  /// No description provided for @exercisePlayReviewPictureSentence.
  ///
  /// In en, this message translates to:
  /// **'Write a sentence with \"{keyword}\"'**
  String exercisePlayReviewPictureSentence(String keyword);

  /// No description provided for @exercisePlayReviewCompose.
  ///
  /// In en, this message translates to:
  /// **'Arrange the words into a sentence'**
  String get exercisePlayReviewCompose;

  /// No description provided for @exercisePlayReviewQuestionNumber.
  ///
  /// In en, this message translates to:
  /// **'Question {number}'**
  String exercisePlayReviewQuestionNumber(int number);

  /// No description provided for @exercisePlayReviewKeywordKey.
  ///
  /// In en, this message translates to:
  /// **'A sentence that uses \"{keyword}\"'**
  String exercisePlayReviewKeywordKey(String keyword);

  /// No description provided for @exercisePlayNotAnswered.
  ///
  /// In en, this message translates to:
  /// **'Not answered'**
  String get exercisePlayNotAnswered;

  /// No description provided for @exercisePlayYourAnswer.
  ///
  /// In en, this message translates to:
  /// **'Your answer: {answer}'**
  String exercisePlayYourAnswer(String answer);

  /// No description provided for @exercisePlayCorrectAnswer.
  ///
  /// In en, this message translates to:
  /// **'Correct answer: {answer}'**
  String exercisePlayCorrectAnswer(String answer);

  /// No description provided for @materialsTitle.
  ///
  /// In en, this message translates to:
  /// **'Materials'**
  String get materialsTitle;

  /// No description provided for @materialsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add material'**
  String get materialsAdd;

  /// No description provided for @materialsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No materials yet'**
  String get materialsEmptyTitle;

  /// No description provided for @materialsEmptyStudentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Published materials from your teacher will appear here.'**
  String get materialsEmptyStudentSubtitle;

  /// No description provided for @materialsEmptyStaffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Add material\" to upload a file or add a resource.'**
  String get materialsEmptyStaffSubtitle;

  /// No description provided for @materialsOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the file.'**
  String get materialsOpenFailed;

  /// No description provided for @materialsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get materialsEdit;

  /// No description provided for @materialsStatusPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get materialsStatusPublished;

  /// No description provided for @materialsStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get materialsStatusDraft;

  /// No description provided for @materialsEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit material'**
  String get materialsEditTitle;

  /// No description provided for @materialsFieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get materialsFieldTitle;

  /// No description provided for @materialsTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a title'**
  String get materialsTitleRequired;

  /// No description provided for @materialsFieldLevel.
  ///
  /// In en, this message translates to:
  /// **'Level (optional)'**
  String get materialsFieldLevel;

  /// No description provided for @materialsFieldSkill.
  ///
  /// In en, this message translates to:
  /// **'Skill (optional)'**
  String get materialsFieldSkill;

  /// No description provided for @materialsFieldTags.
  ///
  /// In en, this message translates to:
  /// **'Tags (comma-separated)'**
  String get materialsFieldTags;

  /// No description provided for @materialsReplaceFile.
  ///
  /// In en, this message translates to:
  /// **'Replace file'**
  String get materialsReplaceFile;

  /// No description provided for @materialsUploadFile.
  ///
  /// In en, this message translates to:
  /// **'Upload file (optional)'**
  String get materialsUploadFile;

  /// No description provided for @materialsPublishedHint.
  ///
  /// In en, this message translates to:
  /// **'Visible to students and parents.'**
  String get materialsPublishedHint;

  /// No description provided for @materialsSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get materialsSaveChanges;

  /// No description provided for @materialsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get materialsDelete;

  /// No description provided for @materialsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete material?'**
  String get materialsDeleteTitle;

  /// No description provided for @materialsDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\"? This cannot be undone.'**
  String materialsDeleteBody(String title);

  /// No description provided for @scoreSummaryCorrectOf.
  ///
  /// In en, this message translates to:
  /// **'{correct} of {total} correct'**
  String scoreSummaryCorrectOf(int correct, int total);

  /// No description provided for @scoreSummaryPassed.
  ///
  /// In en, this message translates to:
  /// **'Great work!'**
  String get scoreSummaryPassed;

  /// No description provided for @scoreSummaryKeepPracticing.
  ///
  /// In en, this message translates to:
  /// **'Keep practicing — you\'re improving.'**
  String get scoreSummaryKeepPracticing;

  /// No description provided for @statusPillOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get statusPillOpen;

  /// No description provided for @statusPillClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get statusPillClosed;

  /// No description provided for @statusPillConcluded.
  ///
  /// In en, this message translates to:
  /// **'Concluded'**
  String get statusPillConcluded;

  /// No description provided for @tableToolsExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get tableToolsExportCsv;

  /// No description provided for @tableToolsDownloadingRows.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Downloading 1 row as CSV…} other{Downloading {count} rows as CSV…}}'**
  String tableToolsDownloadingRows(int count);

  /// No description provided for @tableToolsCopiedRows.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Copied 1 row as CSV to the clipboard.} other{Copied {count} rows as CSV to the clipboard.}}'**
  String tableToolsCopiedRows(int count);

  /// No description provided for @tableToolsSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 selected} other{{count} selected}}'**
  String tableToolsSelectedCount(int count);

  /// No description provided for @tableToolsClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get tableToolsClear;

  /// No description provided for @adminDashTotalUsers.
  ///
  /// In en, this message translates to:
  /// **'Total users'**
  String get adminDashTotalUsers;

  /// No description provided for @adminDashUsersBreakdown.
  ///
  /// In en, this message translates to:
  /// **'{students} murid · {teachers} guru'**
  String adminDashUsersBreakdown(int students, int teachers);

  /// No description provided for @adminDashActiveMurid.
  ///
  /// In en, this message translates to:
  /// **'Active murid'**
  String get adminDashActiveMurid;

  /// No description provided for @adminDashIncomePerMonth.
  ///
  /// In en, this message translates to:
  /// **'Income / mo'**
  String get adminDashIncomePerMonth;

  /// No description provided for @adminDashNoPaymentsInMonth.
  ///
  /// In en, this message translates to:
  /// **'No payments in {month}'**
  String adminDashNoPaymentsInMonth(String month);

  /// No description provided for @adminDashPaymentsInMonth.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 payment in {month}} other{{count} payments in {month}}}'**
  String adminDashPaymentsInMonth(int count, String month);

  /// No description provided for @adminDashNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get adminDashNeedsAttention;

  /// No description provided for @adminDashAllCaughtUpNoAlerts.
  ///
  /// In en, this message translates to:
  /// **'All caught up — no voucher alerts right now.'**
  String get adminDashAllCaughtUpNoAlerts;

  /// No description provided for @adminDashFinancialSummary.
  ///
  /// In en, this message translates to:
  /// **'Financial summary'**
  String get adminDashFinancialSummary;

  /// No description provided for @adminDashRevenueThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Revenue this month'**
  String get adminDashRevenueThisMonth;

  /// No description provided for @adminDashPendingPayments.
  ///
  /// In en, this message translates to:
  /// **'Pending payments'**
  String get adminDashPendingPayments;

  /// No description provided for @adminDashVouchersWithoutPayment.
  ///
  /// In en, this message translates to:
  /// **'Vouchers without payment'**
  String get adminDashVouchersWithoutPayment;

  /// No description provided for @adminDashActiveVouchersNoInvoice.
  ///
  /// In en, this message translates to:
  /// **'Active vouchers with no invoice'**
  String get adminDashActiveVouchersNoInvoice;

  /// No description provided for @adminDashPendingToChase.
  ///
  /// In en, this message translates to:
  /// **'Pending payments to chase'**
  String get adminDashPendingToChase;

  /// No description provided for @adminDashOverdue.
  ///
  /// In en, this message translates to:
  /// **'overdue'**
  String get adminDashOverdue;

  /// No description provided for @adminDashDue.
  ///
  /// In en, this message translates to:
  /// **'due {date}'**
  String adminDashDue(String date);

  /// No description provided for @adminDashNoPaymentsYet.
  ///
  /// In en, this message translates to:
  /// **'No payments recorded yet.'**
  String get adminDashNoPaymentsYet;

  /// No description provided for @adminDashRecentPayments.
  ///
  /// In en, this message translates to:
  /// **'Recent payments'**
  String get adminDashRecentPayments;

  /// No description provided for @adminDashNewStudentsPerMonth.
  ///
  /// In en, this message translates to:
  /// **'New students / month'**
  String get adminDashNewStudentsPerMonth;

  /// No description provided for @adminDashQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get adminDashQuickActions;

  /// No description provided for @adminDashNewExercise.
  ///
  /// In en, this message translates to:
  /// **'New exercise'**
  String get adminDashNewExercise;

  /// No description provided for @adminDashNewClass.
  ///
  /// In en, this message translates to:
  /// **'New class'**
  String get adminDashNewClass;

  /// No description provided for @adminDashVoucherDepleted.
  ///
  /// In en, this message translates to:
  /// **'{name} — voucher depleted'**
  String adminDashVoucherDepleted(String name);

  /// No description provided for @adminDashVoucherLowBalance.
  ///
  /// In en, this message translates to:
  /// **'{name} — low balance'**
  String adminDashVoucherLowBalance(String name);

  /// No description provided for @adminDashStatAllUsersTitle.
  ///
  /// In en, this message translates to:
  /// **'All users'**
  String get adminDashStatAllUsersTitle;

  /// No description provided for @adminDashStatAllUsersDesc.
  ///
  /// In en, this message translates to:
  /// **'Every account on the platform — admin, guru, and murid.'**
  String get adminDashStatAllUsersDesc;

  /// No description provided for @adminDashStatActiveMuridDesc.
  ///
  /// In en, this message translates to:
  /// **'Murid accounts that are currently active.'**
  String get adminDashStatActiveMuridDesc;

  /// No description provided for @adminDashStatExercisesTitle.
  ///
  /// In en, this message translates to:
  /// **'Published exercises'**
  String get adminDashStatExercisesTitle;

  /// No description provided for @adminDashStatExercisesDesc.
  ///
  /// In en, this message translates to:
  /// **'Practice worksheets that are published and visible to murid.'**
  String get adminDashStatExercisesDesc;

  /// No description provided for @adminDashStatIncomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly income'**
  String get adminDashStatIncomeTitle;

  /// No description provided for @adminDashStatIncomeDesc.
  ///
  /// In en, this message translates to:
  /// **'Payments received each month (invoices marked paid, by the date they were paid), for the last twelve months.'**
  String get adminDashStatIncomeDesc;

  /// No description provided for @adminDashStatSignupsTitle.
  ///
  /// In en, this message translates to:
  /// **'New student signups'**
  String get adminDashStatSignupsTitle;

  /// No description provided for @adminDashStatSignupsDesc.
  ///
  /// In en, this message translates to:
  /// **'Murid who registered in each of the last six months.'**
  String get adminDashStatSignupsDesc;

  /// No description provided for @adminDashStatVoucherAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Voucher alerts'**
  String get adminDashStatVoucherAlertsTitle;

  /// No description provided for @adminDashStatVoucherAlertsDesc.
  ///
  /// In en, this message translates to:
  /// **'Class packages with two or fewer sessions remaining, or fully depleted.'**
  String get adminDashStatVoucherAlertsDesc;

  /// No description provided for @adminDashNoActiveMurid.
  ///
  /// In en, this message translates to:
  /// **'No active murid'**
  String get adminDashNoActiveMurid;

  /// No description provided for @adminDashActiveAccountsAppear.
  ///
  /// In en, this message translates to:
  /// **'Active student accounts will appear here.'**
  String get adminDashActiveAccountsAppear;

  /// No description provided for @adminDashMuridCount.
  ///
  /// In en, this message translates to:
  /// **'{count} murid'**
  String adminDashMuridCount(int count);

  /// No description provided for @adminDashGuruCount.
  ///
  /// In en, this message translates to:
  /// **'{count} guru'**
  String adminDashGuruCount(int count);

  /// No description provided for @adminDashAdminCount.
  ///
  /// In en, this message translates to:
  /// **'{count} admin'**
  String adminDashAdminCount(int count);

  /// No description provided for @adminDashInactiveCount.
  ///
  /// In en, this message translates to:
  /// **'{count} inactive'**
  String adminDashInactiveCount(int count);

  /// No description provided for @adminDashNoUsers.
  ///
  /// In en, this message translates to:
  /// **'No users'**
  String get adminDashNoUsers;

  /// No description provided for @adminDashUsersAppear.
  ///
  /// In en, this message translates to:
  /// **'Users will appear here after registration.'**
  String get adminDashUsersAppear;

  /// No description provided for @adminDashInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get adminDashInactive;

  /// No description provided for @adminDashNoPublishedExercises.
  ///
  /// In en, this message translates to:
  /// **'No published exercises'**
  String get adminDashNoPublishedExercises;

  /// No description provided for @adminDashPublishFromTab.
  ///
  /// In en, this message translates to:
  /// **'Publish exercises from the Exercises tab.'**
  String get adminDashPublishFromTab;

  /// No description provided for @adminDashQuestionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 question} other{{count} questions}}'**
  String adminDashQuestionCount(int count);

  /// No description provided for @adminDashPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get adminDashPublished;

  /// No description provided for @adminDashNoSignups.
  ///
  /// In en, this message translates to:
  /// **'No student signups yet'**
  String get adminDashNoSignups;

  /// No description provided for @adminDashSignupsAppear.
  ///
  /// In en, this message translates to:
  /// **'New murid registrations will appear here.'**
  String get adminDashSignupsAppear;

  /// No description provided for @adminDashAllCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up'**
  String get adminDashAllCaughtUp;

  /// No description provided for @adminDashNoVoucherAlerts.
  ///
  /// In en, this message translates to:
  /// **'No voucher alerts right now.'**
  String get adminDashNoVoucherAlerts;

  /// No description provided for @adminDashNoPaymentsTwelveMonths.
  ///
  /// In en, this message translates to:
  /// **'No payments in the last twelve months'**
  String get adminDashNoPaymentsTwelveMonths;

  /// No description provided for @adminDashPaymentsShowHint.
  ///
  /// In en, this message translates to:
  /// **'Payments show here once an invoice is marked paid in Payments.'**
  String get adminDashPaymentsShowHint;

  /// No description provided for @adminDashPaymentCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 payment} other{{count} payments}}'**
  String adminDashPaymentCount(int count);

  /// No description provided for @adminReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get adminReportsTitle;

  /// No description provided for @adminReportsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load report data: {error}'**
  String adminReportsLoadFailed(String error);

  /// No description provided for @adminReportsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Live numbers for {month}. Each PDF covers the last 6 months.'**
  String adminReportsSubtitle(String month);

  /// No description provided for @adminReportsSectionClasses.
  ///
  /// In en, this message translates to:
  /// **'Classes & teachers'**
  String get adminReportsSectionClasses;

  /// No description provided for @adminReportsSectionMoney.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get adminReportsSectionMoney;

  /// No description provided for @adminReportsSectionPlatform.
  ///
  /// In en, this message translates to:
  /// **'Platform exports'**
  String get adminReportsSectionPlatform;

  /// No description provided for @adminReportsPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get adminReportsPdf;

  /// No description provided for @adminReportsAttendanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Attendance per student'**
  String get adminReportsAttendanceTitle;

  /// No description provided for @adminReportsAttendanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Hadir / Izin / Alpa for every student, month by month.'**
  String get adminReportsAttendanceDesc;

  /// No description provided for @adminReportsAlpa.
  ///
  /// In en, this message translates to:
  /// **'Alpa'**
  String get adminReportsAlpa;

  /// No description provided for @adminReportsRetentionTitle.
  ///
  /// In en, this message translates to:
  /// **'New students & retention'**
  String get adminReportsRetentionTitle;

  /// No description provided for @adminReportsRetentionDesc.
  ///
  /// In en, this message translates to:
  /// **'Sign-ups per month and how many are still active today.'**
  String get adminReportsRetentionDesc;

  /// No description provided for @adminReportsNewThisMonth.
  ///
  /// In en, this message translates to:
  /// **'New this month'**
  String get adminReportsNewThisMonth;

  /// No description provided for @adminReportsRetention.
  ///
  /// In en, this message translates to:
  /// **'Retention'**
  String get adminReportsRetention;

  /// No description provided for @adminReportsProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress per HSK level'**
  String get adminReportsProgressTitle;

  /// No description provided for @adminReportsProgressDesc.
  ///
  /// In en, this message translates to:
  /// **'Exercises assigned and done, average best score, no activity.'**
  String get adminReportsProgressDesc;

  /// No description provided for @adminReportsDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get adminReportsDone;

  /// No description provided for @adminReportsNoActivity.
  ///
  /// In en, this message translates to:
  /// **'No activity'**
  String get adminReportsNoActivity;

  /// No description provided for @adminReportsOverdueHomeworkTitle.
  ///
  /// In en, this message translates to:
  /// **'Overdue homework'**
  String get adminReportsOverdueHomeworkTitle;

  /// No description provided for @adminReportsOverdueHomeworkDesc.
  ///
  /// In en, this message translates to:
  /// **'Past-due assignments without a submission, per teacher.'**
  String get adminReportsOverdueHomeworkDesc;

  /// No description provided for @adminReportsOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get adminReportsOpen;

  /// No description provided for @adminReportsTeachers.
  ///
  /// In en, this message translates to:
  /// **'Teachers'**
  String get adminReportsTeachers;

  /// No description provided for @adminReportsFillRateTitle.
  ///
  /// In en, this message translates to:
  /// **'Class fill rate'**
  String get adminReportsFillRateTitle;

  /// No description provided for @adminReportsFillRateDesc.
  ///
  /// In en, this message translates to:
  /// **'Seats taken against capacity, per month and per class.'**
  String get adminReportsFillRateDesc;

  /// No description provided for @adminReportsClasses.
  ///
  /// In en, this message translates to:
  /// **'Classes'**
  String get adminReportsClasses;

  /// No description provided for @adminReportsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get adminReportsEmpty;

  /// No description provided for @adminReportsTeacherRecapTitle.
  ///
  /// In en, this message translates to:
  /// **'Teacher recap'**
  String get adminReportsTeacherRecapTitle;

  /// No description provided for @adminReportsTeacherRecapDesc.
  ///
  /// In en, this message translates to:
  /// **'Classes, teaching hours, students taught and attendance per teacher.'**
  String get adminReportsTeacherRecapDesc;

  /// No description provided for @adminReportsClassesHeld.
  ///
  /// In en, this message translates to:
  /// **'Classes held'**
  String get adminReportsClassesHeld;

  /// No description provided for @adminReportsHours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get adminReportsHours;

  /// No description provided for @adminReportsTermAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Term balance alerts'**
  String get adminReportsTermAlertsTitle;

  /// No description provided for @adminReportsTermAlertsDesc.
  ///
  /// In en, this message translates to:
  /// **'Who to call: 2 or fewer sessions left, expiring within 7 days, expired.'**
  String get adminReportsTermAlertsDesc;

  /// No description provided for @adminReportsLowBalance.
  ///
  /// In en, this message translates to:
  /// **'Low balance'**
  String get adminReportsLowBalance;

  /// No description provided for @adminReportsExpiring.
  ///
  /// In en, this message translates to:
  /// **'Expiring'**
  String get adminReportsExpiring;

  /// No description provided for @adminReportsRevenueTitle.
  ///
  /// In en, this message translates to:
  /// **'Revenue per month'**
  String get adminReportsRevenueTitle;

  /// No description provided for @adminReportsRevenueDesc.
  ///
  /// In en, this message translates to:
  /// **'Paid invoices by item, plus every unpaid invoice and how overdue it is.'**
  String get adminReportsRevenueDesc;

  /// No description provided for @adminReportsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get adminReportsThisMonth;

  /// No description provided for @adminReportsUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get adminReportsUnpaid;

  /// No description provided for @adminReportsUserRosterTitle.
  ///
  /// In en, this message translates to:
  /// **'User roster'**
  String get adminReportsUserRosterTitle;

  /// No description provided for @adminReportsUserRosterDesc.
  ///
  /// In en, this message translates to:
  /// **'Every account with role, join date and status.'**
  String get adminReportsUserRosterDesc;

  /// No description provided for @adminReportsUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get adminReportsUsers;

  /// No description provided for @adminReportsGrowthTitle.
  ///
  /// In en, this message translates to:
  /// **'Registration & growth'**
  String get adminReportsGrowthTitle;

  /// No description provided for @adminReportsGrowthDesc.
  ///
  /// In en, this message translates to:
  /// **'New murid per month and current HSK level bands.'**
  String get adminReportsGrowthDesc;

  /// No description provided for @adminReportsLastSixMonths.
  ///
  /// In en, this message translates to:
  /// **'Last 6 months'**
  String get adminReportsLastSixMonths;

  /// No description provided for @adminReportsVouchersTitle.
  ///
  /// In en, this message translates to:
  /// **'Vouchers & packages'**
  String get adminReportsVouchersTitle;

  /// No description provided for @adminReportsVouchersDesc.
  ///
  /// In en, this message translates to:
  /// **'All session packages with codes and balance.'**
  String get adminReportsVouchersDesc;

  /// No description provided for @adminReportsPackages.
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get adminReportsPackages;

  /// No description provided for @adminReportsIssuedThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Issued this month'**
  String get adminReportsIssuedThisMonth;

  /// No description provided for @adminReportsWorksheetInventoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Worksheet inventory'**
  String get adminReportsWorksheetInventoryTitle;

  /// No description provided for @adminReportsWorksheetInventoryDesc.
  ///
  /// In en, this message translates to:
  /// **'Practice worksheets by HSK level and skill section.'**
  String get adminReportsWorksheetInventoryDesc;

  /// No description provided for @adminReportsWorksheets.
  ///
  /// In en, this message translates to:
  /// **'Worksheets'**
  String get adminReportsWorksheets;

  /// No description provided for @adminReportsDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get adminReportsDraft;

  /// No description provided for @adminPriceTitle.
  ///
  /// In en, this message translates to:
  /// **'Price list'**
  String get adminPriceTitle;

  /// No description provided for @adminPriceSaved.
  ///
  /// In en, this message translates to:
  /// **'Price list saved'**
  String get adminPriceSaved;

  /// No description provided for @adminPriceSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save: {error}'**
  String adminPriceSaveFailed(String error);

  /// No description provided for @adminPriceRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\"?'**
  String adminPriceRemoveTitle(String name);

  /// No description provided for @adminPriceRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'Invoices already created keep their price. New invoices can no longer pick this item.'**
  String get adminPriceRemoveBody;

  /// No description provided for @adminPriceVoucherValidity.
  ///
  /// In en, this message translates to:
  /// **'Voucher validity'**
  String get adminPriceVoucherValidity;

  /// No description provided for @adminPriceValidityDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Days a paid voucher stays valid'**
  String get adminPriceValidityDaysLabel;

  /// No description provided for @adminPriceValidityHelper.
  ///
  /// In en, this message translates to:
  /// **'Flyer: 2 months = 60 days'**
  String get adminPriceValidityHelper;

  /// No description provided for @adminPriceSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get adminPriceSave;

  /// No description provided for @adminPriceIntro.
  ///
  /// In en, this message translates to:
  /// **'Everything a payment can be for. Create invoice picks a row from this list and the server charges exactly this price. Rows that give class sessions become vouchers when paid.'**
  String get adminPriceIntro;

  /// No description provided for @adminPriceItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get adminPriceItems;

  /// No description provided for @adminPriceAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get adminPriceAddItem;

  /// No description provided for @adminPriceGives.
  ///
  /// In en, this message translates to:
  /// **'Gives {what}'**
  String adminPriceGives(String what);

  /// No description provided for @adminPriceEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get adminPriceEdit;

  /// No description provided for @adminPriceValiditySummary.
  ///
  /// In en, this message translates to:
  /// **'{days} days from payment ({months} months)'**
  String adminPriceValiditySummary(int days, String months);

  /// No description provided for @adminPriceLastSaved.
  ///
  /// In en, this message translates to:
  /// **'Last saved {date}'**
  String adminPriceLastSaved(String date);

  /// No description provided for @adminPriceNewItem.
  ///
  /// In en, this message translates to:
  /// **'New item'**
  String get adminPriceNewItem;

  /// No description provided for @adminPriceEditItem.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get adminPriceEditItem;

  /// No description provided for @adminPriceName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get adminPriceName;

  /// No description provided for @adminPriceNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 8 class sessions'**
  String get adminPriceNameHint;

  /// No description provided for @adminPriceNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get adminPriceNameRequired;

  /// No description provided for @adminPricePriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price (Rp, whole number)'**
  String get adminPricePriceLabel;

  /// No description provided for @adminPricePriceInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a price above 0'**
  String get adminPricePriceInvalid;

  /// No description provided for @adminPriceWhatItGives.
  ///
  /// In en, this message translates to:
  /// **'What it gives'**
  String get adminPriceWhatItGives;

  /// No description provided for @adminPriceSessionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Number of class sessions'**
  String get adminPriceSessionsLabel;

  /// No description provided for @adminPriceSessionsInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter 1 or more'**
  String get adminPriceSessionsInvalid;

  /// No description provided for @adminPriceKindSessions.
  ///
  /// In en, this message translates to:
  /// **'Class sessions'**
  String get adminPriceKindSessions;

  /// No description provided for @adminPriceKindBook.
  ///
  /// In en, this message translates to:
  /// **'Book / materials'**
  String get adminPriceKindBook;

  /// No description provided for @adminPriceKindRegistration.
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get adminPriceKindRegistration;

  /// No description provided for @adminPriceKindOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get adminPriceKindOther;

  /// No description provided for @orgSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get orgSettingsTitle;

  /// No description provided for @orgSettingsFeatures.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get orgSettingsFeatures;

  /// No description provided for @orgSettingsPaymentsHint.
  ///
  /// In en, this message translates to:
  /// **'Show invoices and the pay/checkout UI for students and admins. Turn off to hide billing entirely.'**
  String get orgSettingsPaymentsHint;

  /// No description provided for @orgSettingsEvalOpen.
  ///
  /// In en, this message translates to:
  /// **'Evaluation forms open'**
  String get orgSettingsEvalOpen;

  /// No description provided for @orgSettingsEvalOpenHint.
  ///
  /// In en, this message translates to:
  /// **'Allow teachers to create or edit semester evaluations. Close between terms to freeze the forms.'**
  String get orgSettingsEvalOpenHint;

  /// No description provided for @orgSettingsTeacherReschedule.
  ///
  /// In en, this message translates to:
  /// **'Teachers can reschedule'**
  String get orgSettingsTeacherReschedule;

  /// No description provided for @orgSettingsTeacherRescheduleHint.
  ///
  /// In en, this message translates to:
  /// **'Let teachers edit their own class sessions. Turn off so only admins can reschedule.'**
  String get orgSettingsTeacherRescheduleHint;

  /// No description provided for @orgSettingsAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get orgSettingsAccounts;

  /// No description provided for @orgSettingsRequireEmailVerification.
  ///
  /// In en, this message translates to:
  /// **'Require email verification'**
  String get orgSettingsRequireEmailVerification;

  /// No description provided for @orgSettingsRequireEmailVerificationHint.
  ///
  /// In en, this message translates to:
  /// **'Stored preference for future sign-up flows. Not enforced automatically yet.'**
  String get orgSettingsRequireEmailVerificationHint;

  /// No description provided for @orgSettingsAutoPasswords.
  ///
  /// In en, this message translates to:
  /// **'Auto-generate staff passwords'**
  String get orgSettingsAutoPasswords;

  /// No description provided for @orgSettingsAutoPasswordsHint.
  ///
  /// In en, this message translates to:
  /// **'Stored preference for future staff creation. Not enforced automatically yet.'**
  String get orgSettingsAutoPasswordsHint;

  /// No description provided for @orgSettingsPrices.
  ///
  /// In en, this message translates to:
  /// **'Prices'**
  String get orgSettingsPrices;

  /// No description provided for @orgSettingsPriceListHint.
  ///
  /// In en, this message translates to:
  /// **'What a payment can be for: sessions, book, registration. Invoices pick from this list.'**
  String get orgSettingsPriceListHint;

  /// No description provided for @orgSettingsAdministration.
  ///
  /// In en, this message translates to:
  /// **'Administration'**
  String get orgSettingsAdministration;

  /// No description provided for @orgSettingsAuditLogsHint.
  ///
  /// In en, this message translates to:
  /// **'Money and permission events, newest first.'**
  String get orgSettingsAuditLogsHint;

  /// No description provided for @orgSettingsMaterialsHint.
  ///
  /// In en, this message translates to:
  /// **'Shared files for students and parents.'**
  String get orgSettingsMaterialsHint;

  /// No description provided for @orgSettingsLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated {date}'**
  String orgSettingsLastUpdated(String date);

  /// No description provided for @auditLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Audit logs'**
  String get auditLogTitle;

  /// No description provided for @auditLogEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No activity yet'**
  String get auditLogEmptyTitle;

  /// No description provided for @auditLogEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Money movements and permission changes will be recorded here automatically.'**
  String get auditLogEmptySubtitle;

  /// No description provided for @cohortNoStudentsTitle.
  ///
  /// In en, this message translates to:
  /// **'No students yet'**
  String get cohortNoStudentsTitle;

  /// No description provided for @cohortNoStudentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Students appear here after they register in the app.'**
  String get cohortNoStudentsSubtitle;

  /// No description provided for @cohortNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No students match this search.'**
  String get cohortNoMatch;

  /// No description provided for @cohortLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get cohortLevel;

  /// No description provided for @cohortThisTerm.
  ///
  /// In en, this message translates to:
  /// **'This term'**
  String get cohortThisTerm;

  /// No description provided for @cohortHomework.
  ///
  /// In en, this message translates to:
  /// **'Homework'**
  String get cohortHomework;

  /// No description provided for @cohortQuizAvg.
  ///
  /// In en, this message translates to:
  /// **'Quiz avg'**
  String get cohortQuizAvg;

  /// No description provided for @cohortSessionsLeft.
  ///
  /// In en, this message translates to:
  /// **'Sessions left'**
  String get cohortSessionsLeft;

  /// No description provided for @cohortLastActive.
  ///
  /// In en, this message translates to:
  /// **'Last active'**
  String get cohortLastActive;

  /// No description provided for @cohortStudentCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 student} other{{count} students}}'**
  String cohortStudentCount(int count);

  /// No description provided for @cohortShownCount.
  ///
  /// In en, this message translates to:
  /// **'{count} shown'**
  String cohortShownCount(int count);

  /// No description provided for @cohortNeedAttentionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 needs attention} other{{count} need attention}}'**
  String cohortNeedAttentionCount(int count);

  /// No description provided for @cohortSearchStudents.
  ///
  /// In en, this message translates to:
  /// **'Search students'**
  String get cohortSearchStudents;

  /// No description provided for @cohortAllLevels.
  ///
  /// In en, this message translates to:
  /// **'All levels'**
  String get cohortAllLevels;

  /// No description provided for @cohortQuizPercent.
  ///
  /// In en, this message translates to:
  /// **'Quiz {score}%'**
  String cohortQuizPercent(int score);

  /// No description provided for @cohortCentreStatistics.
  ///
  /// In en, this message translates to:
  /// **'Centre statistics'**
  String get cohortCentreStatistics;

  /// No description provided for @cohortHomeworkDone.
  ///
  /// In en, this message translates to:
  /// **'Homework done'**
  String get cohortHomeworkDone;

  /// No description provided for @cohortOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get cohortOverdue;

  /// No description provided for @cohortAvgQuiz.
  ///
  /// In en, this message translates to:
  /// **'Avg quiz'**
  String get cohortAvgQuiz;

  /// No description provided for @cohortAvgPractice.
  ///
  /// In en, this message translates to:
  /// **'Avg practice'**
  String get cohortAvgPractice;

  /// No description provided for @cohortClassesThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Classes this week'**
  String get cohortClassesThisWeek;

  /// No description provided for @cohortNeedAttention.
  ///
  /// In en, this message translates to:
  /// **'Need attention'**
  String get cohortNeedAttention;

  /// No description provided for @cohortStudents.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get cohortStudents;

  /// No description provided for @cohortRosterCsvDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Roster CSV downloaded'**
  String get cohortRosterCsvDownloaded;

  /// No description provided for @cohortRosterCsvCopied.
  ///
  /// In en, this message translates to:
  /// **'Roster CSV copied to clipboard'**
  String get cohortRosterCsvCopied;

  /// No description provided for @cohortReportsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Export centre summaries and worksheet inventory for your records.'**
  String get cohortReportsSubtitle;

  /// No description provided for @cohortCentreSummary.
  ///
  /// In en, this message translates to:
  /// **'Centre summary'**
  String get cohortCentreSummary;

  /// No description provided for @cohortCentreSummaryDesc.
  ///
  /// In en, this message translates to:
  /// **'Homework completion, quiz averages, sessions remaining, and students needing attention.'**
  String get cohortCentreSummaryDesc;

  /// No description provided for @cohortStudentsTracked.
  ///
  /// In en, this message translates to:
  /// **'Students tracked: {count}'**
  String cohortStudentsTracked(int count);

  /// No description provided for @cohortWorksheetsPublished.
  ///
  /// In en, this message translates to:
  /// **'Worksheets published: {count}'**
  String cohortWorksheetsPublished(int count);

  /// No description provided for @cohortStudentRoster.
  ///
  /// In en, this message translates to:
  /// **'Student roster'**
  String get cohortStudentRoster;

  /// No description provided for @cohortStudentRosterDesc.
  ///
  /// In en, this message translates to:
  /// **'Full student list with progress, homework, and session balance. Spreadsheet export.'**
  String get cohortStudentRosterDesc;

  /// No description provided for @cohortStudentsPreview.
  ///
  /// In en, this message translates to:
  /// **'Students: {count}'**
  String cohortStudentsPreview(int count);

  /// No description provided for @cohortColumnsPreview.
  ///
  /// In en, this message translates to:
  /// **'Columns: level, homework, quiz, sessions'**
  String get cohortColumnsPreview;

  /// No description provided for @cohortWorksheetInventoryDesc.
  ///
  /// In en, this message translates to:
  /// **'All practice worksheets produced, grouped by HSK level and skill section (Reading, Listening, etc.).'**
  String get cohortWorksheetInventoryDesc;

  /// No description provided for @cohortTotalWorksheets.
  ///
  /// In en, this message translates to:
  /// **'Total worksheets: {count}'**
  String cohortTotalWorksheets(int count);

  /// No description provided for @teacherActivityThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Activity this week'**
  String get teacherActivityThisWeek;

  /// No description provided for @teacherActivityThisWeekSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Lesson completions and practice submissions'**
  String get teacherActivityThisWeekSubtitle;

  /// No description provided for @teacherActivityHomeworkOverview.
  ///
  /// In en, this message translates to:
  /// **'Homework overview'**
  String get teacherActivityHomeworkOverview;

  /// No description provided for @teacherActivityQuickView.
  ///
  /// In en, this message translates to:
  /// **'Quick view'**
  String get teacherActivityQuickView;

  /// No description provided for @teacherActivityNoHomeworkAssign.
  ///
  /// In en, this message translates to:
  /// **'No homework assigned yet. Assign practice from the Exercises tab.'**
  String get teacherActivityNoHomeworkAssign;

  /// No description provided for @teacherActivityToDo.
  ///
  /// In en, this message translates to:
  /// **'{count} to do'**
  String teacherActivityToDo(int count);

  /// No description provided for @teacherActivityOverdueCount.
  ///
  /// In en, this message translates to:
  /// **'{count} overdue'**
  String teacherActivityOverdueCount(int count);

  /// No description provided for @teacherActivityDoneCount.
  ///
  /// In en, this message translates to:
  /// **'{count} done'**
  String teacherActivityDoneCount(int count);

  /// No description provided for @teacherActivityAssignmentsCompleted.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total} assignments completed'**
  String teacherActivityAssignmentsCompleted(int done, int total);

  /// No description provided for @teacherActivityNoHomework.
  ///
  /// In en, this message translates to:
  /// **'No homework assigned yet.'**
  String get teacherActivityNoHomework;

  /// No description provided for @teacherActivityCompletedOf.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total} completed'**
  String teacherActivityCompletedOf(int done, int total);

  /// No description provided for @teacherActivityPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get teacherActivityPending;

  /// No description provided for @teacherActivityClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get teacherActivityClose;

  /// No description provided for @teacherActivityRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get teacherActivityRecent;

  /// No description provided for @teacherActivityNoRecent.
  ///
  /// In en, this message translates to:
  /// **'No recent activity for this filter.'**
  String get teacherActivityNoRecent;

  /// No description provided for @teacherActivityFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get teacherActivityFilterAll;

  /// No description provided for @teacherActivityJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get teacherActivityJustNow;

  /// No description provided for @teacherActivityMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String teacherActivityMinutesAgo(int count);

  /// No description provided for @teacherActivityHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String teacherActivityHoursAgo(int count);

  /// No description provided for @teacherActivityDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String teacherActivityDaysAgo(int count);

  /// No description provided for @adminShellNavDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get adminShellNavDashboard;

  /// No description provided for @adminShellNavUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get adminShellNavUsers;

  /// No description provided for @adminShellNavExercises.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get adminShellNavExercises;

  /// No description provided for @adminShellNavQuestionBank.
  ///
  /// In en, this message translates to:
  /// **'Question bank'**
  String get adminShellNavQuestionBank;

  /// No description provided for @adminShellNavClasses.
  ///
  /// In en, this message translates to:
  /// **'Classes'**
  String get adminShellNavClasses;

  /// No description provided for @adminShellNavVouchers.
  ///
  /// In en, this message translates to:
  /// **'Vouchers'**
  String get adminShellNavVouchers;

  /// No description provided for @adminShellNavReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get adminShellNavReports;

  /// No description provided for @adminShellNavAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get adminShellNavAccount;

  /// No description provided for @adminShellScanWorksheet.
  ///
  /// In en, this message translates to:
  /// **'Scan worksheet'**
  String get adminShellScanWorksheet;

  /// No description provided for @adminShellNewClass.
  ///
  /// In en, this message translates to:
  /// **'New class'**
  String get adminShellNewClass;

  /// No description provided for @adminProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Platform administrator'**
  String get adminProfileSubtitle;

  /// No description provided for @adminProfileIntro.
  ///
  /// In en, this message translates to:
  /// **'Manage users, vouchers, reports, and notifications from the admin tabs. Teaching workflows use the Guru role.'**
  String get adminProfileIntro;

  /// No description provided for @adminProfileCentreSettings.
  ///
  /// In en, this message translates to:
  /// **'Centre settings'**
  String get adminProfileCentreSettings;

  /// No description provided for @adminProfileCentreSettingsHint.
  ///
  /// In en, this message translates to:
  /// **'Payments, evaluations, materials, audit logs.'**
  String get adminProfileCentreSettingsHint;

  /// No description provided for @adminProfilePersonalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Indonesian and Chinese names plus WhatsApp contact.'**
  String get adminProfilePersonalSubtitle;

  /// No description provided for @profileWidgetPhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated'**
  String get profileWidgetPhotoUpdated;

  /// No description provided for @profileWidgetEmailHelper.
  ///
  /// In en, this message translates to:
  /// **'Contact support to change your email'**
  String get profileWidgetEmailHelper;

  /// No description provided for @profileWidgetParentHint.
  ///
  /// In en, this message translates to:
  /// **'Used by staff to contact family when needed.'**
  String get profileWidgetParentHint;

  /// No description provided for @profileWidgetAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileWidgetAccountTitle;

  /// No description provided for @profileWidgetMemberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since'**
  String get profileWidgetMemberSince;

  /// No description provided for @profileWidgetStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get profileWidgetStatus;

  /// No description provided for @profileWidgetInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get profileWidgetInactive;

  /// No description provided for @profileWidgetSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get profileWidgetSaveChanges;

  /// No description provided for @linkCardCopied.
  ///
  /// In en, this message translates to:
  /// **'Link code copied'**
  String get linkCardCopied;

  /// No description provided for @linkCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Student linking'**
  String get linkCardTitle;

  /// No description provided for @linkCardBody.
  ///
  /// In en, this message translates to:
  /// **'Share this code when a murid registers. It refreshes every 15 minutes.'**
  String get linkCardBody;

  /// No description provided for @linkCardCopyTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get linkCardCopyTooltip;

  /// No description provided for @linkCardRefreshesIn.
  ///
  /// In en, this message translates to:
  /// **'Refreshes in {time}'**
  String linkCardRefreshesIn(String time);

  /// No description provided for @termDatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Term dates'**
  String get termDatesTitle;

  /// No description provided for @termStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get termStartDate;

  /// No description provided for @termDeadlineDate.
  ///
  /// In en, this message translates to:
  /// **'Deadline date'**
  String get termDeadlineDate;

  /// No description provided for @termSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get termSave;

  /// No description provided for @termDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get termDelete;

  /// No description provided for @termMeetingsLeftTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Class meeting left this term} other{Class meetings left this term}}'**
  String termMeetingsLeftTitle(int count);

  /// No description provided for @termNoPaidSessions.
  ///
  /// In en, this message translates to:
  /// **'No paid sessions left. Ask your teacher to add a new term.'**
  String get termNoPaidSessions;

  /// No description provided for @termUsedRemaining.
  ///
  /// In en, this message translates to:
  /// **'{used} used · {remaining} remaining of {total}'**
  String termUsedRemaining(int used, int remaining, int total);

  /// No description provided for @termValidUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until {date}'**
  String termValidUntil(String date);

  /// No description provided for @termNoActiveInRange.
  ///
  /// In en, this message translates to:
  /// **'No active term in the current date range.'**
  String get termNoActiveInRange;

  /// No description provided for @termActivePackages.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 active package} other{{count} active packages}}'**
  String termActivePackages(int count);

  /// No description provided for @termChargedOnConclude.
  ///
  /// In en, this message translates to:
  /// **'One session is charged when your teacher concludes each class.'**
  String get termChargedOnConclude;

  /// No description provided for @termSessionsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 class session left} other{{count} class sessions left}}'**
  String termSessionsLeft(int count);

  /// No description provided for @termNoActiveInRangeShort.
  ///
  /// In en, this message translates to:
  /// **'No active term in date range'**
  String get termNoActiveInRangeShort;

  /// No description provided for @termDeductOnConclude.
  ///
  /// In en, this message translates to:
  /// **'Sessions deduct when the teacher concludes a class.'**
  String get termDeductOnConclude;

  /// No description provided for @termRowLabel.
  ///
  /// In en, this message translates to:
  /// **'{sessions}-session · {start} – {end}'**
  String termRowLabel(int sessions, String start, String end);

  /// No description provided for @termNoPaymentRecorded.
  ///
  /// In en, this message translates to:
  /// **'No payment recorded'**
  String get termNoPaymentRecorded;

  /// No description provided for @termPaidLine.
  ///
  /// In en, this message translates to:
  /// **'Paid {amount} ({method})'**
  String termPaidLine(String amount, String method);

  /// No description provided for @termPendingPayment.
  ///
  /// In en, this message translates to:
  /// **'Pending payment · {amount}'**
  String termPendingPayment(String amount);

  /// No description provided for @termUpdated.
  ///
  /// In en, this message translates to:
  /// **'Term updated'**
  String get termUpdated;

  /// No description provided for @termDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this term?'**
  String get termDeleteTitle;

  /// No description provided for @termDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Delete the {sessions}-session term ({remaining} left)? Past class charges linked to this term are kept in history. This cannot be undone.'**
  String termDeleteBody(int sessions, int remaining);

  /// No description provided for @termDeleted.
  ///
  /// In en, this message translates to:
  /// **'Term deleted'**
  String get termDeleted;

  /// No description provided for @termNoPackages.
  ///
  /// In en, this message translates to:
  /// **'No paid term packages yet. Add an 8 or 16 session term when the student pays.'**
  String get termNoPackages;

  /// No description provided for @termPackageTitle.
  ///
  /// In en, this message translates to:
  /// **'{sessions}-session term'**
  String termPackageTitle(int sessions);

  /// No description provided for @termEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit term'**
  String get termEdit;

  /// No description provided for @termDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete term'**
  String get termDeleteTooltip;

  /// No description provided for @termStartDeadline.
  ///
  /// In en, this message translates to:
  /// **'Start: {start} · Deadline: {deadline}'**
  String termStartDeadline(String start, String deadline);

  /// No description provided for @termOutsideDates.
  ///
  /// In en, this message translates to:
  /// **'Outside term dates today'**
  String get termOutsideDates;

  /// No description provided for @termRemainingOf.
  ///
  /// In en, this message translates to:
  /// **'{remaining} / {total} left'**
  String termRemainingOf(int remaining, int total);

  /// No description provided for @termClassesAttended.
  ///
  /// In en, this message translates to:
  /// **'Classes attended ({count})'**
  String termClassesAttended(int count);

  /// No description provided for @termNoClassesCharged.
  ///
  /// In en, this message translates to:
  /// **'No classes charged to this term yet.'**
  String get termNoClassesCharged;

  /// No description provided for @termNoConcludedVisits.
  ///
  /// In en, this message translates to:
  /// **'No concluded class visits yet.'**
  String get termNoConcludedVisits;

  /// No description provided for @termClassFallback.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get termClassFallback;

  /// No description provided for @termMinusOneSession.
  ///
  /// In en, this message translates to:
  /// **'−1 session'**
  String get termMinusOneSession;

  /// No description provided for @termRemainingRangeError.
  ///
  /// In en, this message translates to:
  /// **'Enter sessions remaining between 0 and {max}'**
  String termRemainingRangeError(int max);

  /// No description provided for @termEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit {sessions}-session term'**
  String termEditTitle(int sessions);

  /// No description provided for @termSessionsRemaining.
  ///
  /// In en, this message translates to:
  /// **'Sessions remaining'**
  String get termSessionsRemaining;

  /// No description provided for @termOutOfPackage.
  ///
  /// In en, this message translates to:
  /// **'Out of {total} in this package'**
  String termOutOfPackage(int total);

  /// No description provided for @termAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add paid term'**
  String get termAddTitle;

  /// No description provided for @termAddBody.
  ///
  /// In en, this message translates to:
  /// **'Choose how many class sessions the student paid for. Sessions are deducted when you conclude each class.'**
  String get termAddBody;

  /// No description provided for @termSessionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 session} other{{count} sessions}}'**
  String termSessionsCount(int count);

  /// No description provided for @termPaymentNoteRecorded.
  ///
  /// In en, this message translates to:
  /// **'Pending payment of {amount} recorded for the admin.'**
  String termPaymentNoteRecorded(String amount);

  /// No description provided for @termPaymentNoteNoItem.
  ///
  /// In en, this message translates to:
  /// **'No price-list item for {count} sessions: the admin must add the payment by hand.'**
  String termPaymentNoteNoItem(int count);

  /// No description provided for @termPaymentNoteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not record the payment ({error}); the admin must add it in Payments.'**
  String termPaymentNoteFailed(String error);

  /// No description provided for @termAdded.
  ///
  /// In en, this message translates to:
  /// **'Added {sessions}-session term.'**
  String termAdded(int sessions);

  /// No description provided for @termAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add term'**
  String get termAddButton;

  /// No description provided for @termPaidTermsTitle.
  ///
  /// In en, this message translates to:
  /// **'Paid class terms'**
  String get termPaidTermsTitle;

  /// No description provided for @termPackagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Term packages'**
  String get termPackagesTitle;

  /// No description provided for @termOtherVisits.
  ///
  /// In en, this message translates to:
  /// **'Other concluded visits ({count})'**
  String termOtherVisits(int count);

  /// No description provided for @adminUsersRoleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminUsersRoleAdmin;

  /// No description provided for @adminUsersRoleTeacher.
  ///
  /// In en, this message translates to:
  /// **'Guru'**
  String get adminUsersRoleTeacher;

  /// No description provided for @adminUsersRoleStudent.
  ///
  /// In en, this message translates to:
  /// **'Murid'**
  String get adminUsersRoleStudent;

  /// No description provided for @adminUsersRoleParent.
  ///
  /// In en, this message translates to:
  /// **'Orang Tua'**
  String get adminUsersRoleParent;

  /// No description provided for @adminUsersAllRoles.
  ///
  /// In en, this message translates to:
  /// **'All roles'**
  String get adminUsersAllRoles;

  /// No description provided for @adminUsersAllStatus.
  ///
  /// In en, this message translates to:
  /// **'All status'**
  String get adminUsersAllStatus;

  /// No description provided for @adminUsersColName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get adminUsersColName;

  /// No description provided for @adminUsersColRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get adminUsersColRole;

  /// No description provided for @adminUsersColHsk.
  ///
  /// In en, this message translates to:
  /// **'HSK'**
  String get adminUsersColHsk;

  /// No description provided for @adminUsersColWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get adminUsersColWhatsapp;

  /// No description provided for @adminUsersColParentPhone.
  ///
  /// In en, this message translates to:
  /// **'Parent phone'**
  String get adminUsersColParentPhone;

  /// No description provided for @adminUsersColActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get adminUsersColActions;

  /// No description provided for @adminUsersActivated.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 account activated.} other{{count} accounts activated.}}'**
  String adminUsersActivated(int count);

  /// No description provided for @adminUsersDeactivated.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 account deactivated.} other{{count} accounts deactivated.}}'**
  String adminUsersDeactivated(int count);

  /// No description provided for @adminUsersHskDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{HSK level for 1 student} other{HSK level for {count} students}}'**
  String adminUsersHskDialogTitle(int count);

  /// No description provided for @adminUsersApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get adminUsersApply;

  /// No description provided for @adminUsersLevelSet.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 student set to {level}.} other{{count} students set to {level}.}}'**
  String adminUsersLevelSet(int count, String level);

  /// No description provided for @adminUsersActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get adminUsersActivate;

  /// No description provided for @adminUsersDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get adminUsersDeactivate;

  /// No description provided for @adminUsersSetHskLevel.
  ///
  /// In en, this message translates to:
  /// **'Set HSK level'**
  String get adminUsersSetHskLevel;

  /// No description provided for @adminUsersSetHskLevelCount.
  ///
  /// In en, this message translates to:
  /// **'Set HSK level ({count})'**
  String adminUsersSetHskLevelCount(int count);

  /// No description provided for @adminUsersNoChildLinked.
  ///
  /// In en, this message translates to:
  /// **'No child linked yet'**
  String get adminUsersNoChildLinked;

  /// No description provided for @adminUsersChildrenMore.
  ///
  /// In en, this message translates to:
  /// **'Children: {names} +{more}'**
  String adminUsersChildrenMore(String names, int more);

  /// No description provided for @adminUsersChildren.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Child: {names}} other{Children: {names}}}'**
  String adminUsersChildren(int count, String names);

  /// No description provided for @adminUsersParentOf.
  ///
  /// In en, this message translates to:
  /// **'Parent: {name}'**
  String adminUsersParentOf(String name);

  /// No description provided for @adminUsersDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String adminUsersDeleteTitle(String name);

  /// No description provided for @adminUsersDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'{email} will no longer be able to sign in and the profile is removed. This cannot be undone. Exercise results, invoices and attendance stay as the centre\'s records.'**
  String adminUsersDeleteBody(String email);

  /// No description provided for @adminUsersDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get adminUsersDeleteAccount;

  /// No description provided for @adminUsersDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted {email}.'**
  String adminUsersDeleted(String email);

  /// No description provided for @adminUsersDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the account.'**
  String get adminUsersDeleteFailed;

  /// No description provided for @adminUsersLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load users: {error}'**
  String adminUsersLoadFailed(String error);

  /// No description provided for @adminUsersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No users found. Run scripts/seed_test_accounts.sh or check that your admin account has role: admin in Firestore.'**
  String get adminUsersEmpty;

  /// No description provided for @adminUsersNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No users match your search.'**
  String get adminUsersNoMatch;

  /// No description provided for @adminUsersNewUser.
  ///
  /// In en, this message translates to:
  /// **'New user'**
  String get adminUsersNewUser;

  /// No description provided for @adminUsersSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search users…'**
  String get adminUsersSearchHint;

  /// No description provided for @adminUsersSortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get adminUsersSortBy;

  /// No description provided for @adminUsersEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get adminUsersEditProfile;

  /// No description provided for @adminUsersEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get adminUsersEdit;

  /// No description provided for @adminUserFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Register new user'**
  String get adminUserFormTitle;

  /// No description provided for @adminUserFormHeading.
  ///
  /// In en, this message translates to:
  /// **'Create a Murid or Guru account'**
  String get adminUserFormHeading;

  /// No description provided for @adminUserFormIntro.
  ///
  /// In en, this message translates to:
  /// **'The new user can sign in with the email and password you set. You stay signed in as admin.'**
  String get adminUserFormIntro;

  /// No description provided for @adminUserFormRoleParentShort.
  ///
  /// In en, this message translates to:
  /// **'Ortu'**
  String get adminUserFormRoleParentShort;

  /// No description provided for @adminUserFormSelectChild.
  ///
  /// In en, this message translates to:
  /// **'Select at least one child for this parent.'**
  String get adminUserFormSelectChild;

  /// No description provided for @adminUserFormCreated.
  ///
  /// In en, this message translates to:
  /// **'{role} account created for {name}'**
  String adminUserFormCreated(String role, String name);

  /// No description provided for @adminUserFormErrorEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered.'**
  String get adminUserFormErrorEmailInUse;

  /// No description provided for @adminUserFormSubmit.
  ///
  /// In en, this message translates to:
  /// **'Create {role} account'**
  String adminUserFormSubmit(String role);

  /// No description provided for @adminUserFormChildHint.
  ///
  /// In en, this message translates to:
  /// **'Choose which students this parent can follow (read-only).'**
  String get adminUserFormChildHint;

  /// No description provided for @adminUserFormNoStudents.
  ///
  /// In en, this message translates to:
  /// **'No students to link yet.'**
  String get adminUserFormNoStudents;

  /// No description provided for @adminUserFormSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, email or HSK level'**
  String get adminUserFormSearchHint;

  /// No description provided for @adminUserFormSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String adminUserFormSelectedCount(int count);

  /// No description provided for @adminUserFormNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No students match this search.'**
  String get adminUserFormNoMatch;

  /// No description provided for @adminUserFormNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get adminUserFormNotFound;

  /// No description provided for @adminUserFormUpdated.
  ///
  /// In en, this message translates to:
  /// **'{name} updated'**
  String adminUserFormUpdated(String name);

  /// No description provided for @adminUserFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit user'**
  String get adminUserFormEditTitle;

  /// No description provided for @adminUserFormEditRole.
  ///
  /// In en, this message translates to:
  /// **'Edit {role}'**
  String adminUserFormEditRole(String role);

  /// No description provided for @adminUserFormProfileDetails.
  ///
  /// In en, this message translates to:
  /// **'Profile details'**
  String get adminUserFormProfileDetails;

  /// No description provided for @adminUserFormHskHint.
  ///
  /// In en, this message translates to:
  /// **'Change HSK level to control which practice exercises this murid can access.'**
  String get adminUserFormHskHint;

  /// No description provided for @adminInvoicesStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get adminInvoicesStatusPending;

  /// No description provided for @adminInvoicesStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get adminInvoicesStatusPaid;

  /// No description provided for @adminInvoicesStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get adminInvoicesStatusFailed;

  /// No description provided for @adminInvoicesMethodOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get adminInvoicesMethodOnline;

  /// No description provided for @adminInvoicesMethodCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get adminInvoicesMethodCash;

  /// No description provided for @adminInvoicesMethodTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get adminInvoicesMethodTransfer;

  /// No description provided for @adminInvoicesMethodAtCentre.
  ///
  /// In en, this message translates to:
  /// **'At the centre'**
  String get adminInvoicesMethodAtCentre;

  /// No description provided for @adminInvoicesMethodManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get adminInvoicesMethodManual;

  /// No description provided for @adminInvoicesItemBook.
  ///
  /// In en, this message translates to:
  /// **'HSK materials & book'**
  String get adminInvoicesItemBook;

  /// No description provided for @adminInvoicesGivesBook.
  ///
  /// In en, this message translates to:
  /// **'book / materials, no sessions'**
  String get adminInvoicesGivesBook;

  /// No description provided for @adminInvoicesGivesRegistration.
  ///
  /// In en, this message translates to:
  /// **'registration, no sessions'**
  String get adminInvoicesGivesRegistration;

  /// No description provided for @adminInvoicesGivesNone.
  ///
  /// In en, this message translates to:
  /// **'no sessions'**
  String get adminInvoicesGivesNone;

  /// No description provided for @adminInvoicesColInvoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get adminInvoicesColInvoice;

  /// No description provided for @adminInvoicesColInvoiceNumber.
  ///
  /// In en, this message translates to:
  /// **'Invoice #'**
  String get adminInvoicesColInvoiceNumber;

  /// No description provided for @adminInvoicesColItem.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get adminInvoicesColItem;

  /// No description provided for @adminInvoicesColAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get adminInvoicesColAmount;

  /// No description provided for @adminInvoicesColMethod.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get adminInvoicesColMethod;

  /// No description provided for @adminInvoicesColDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get adminInvoicesColDue;

  /// No description provided for @adminInvoicesColPaidOn.
  ///
  /// In en, this message translates to:
  /// **'Paid on'**
  String get adminInvoicesColPaidOn;

  /// No description provided for @adminInvoicesColCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get adminInvoicesColCreated;

  /// No description provided for @adminInvoicesDisabledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable payments in Settings to create invoices and bill students for session packages.'**
  String get adminInvoicesDisabledSubtitle;

  /// No description provided for @adminInvoicesPriceList.
  ///
  /// In en, this message translates to:
  /// **'Price list'**
  String get adminInvoicesPriceList;

  /// No description provided for @adminInvoicesCreate.
  ///
  /// In en, this message translates to:
  /// **'Create invoice'**
  String get adminInvoicesCreate;

  /// No description provided for @adminInvoicesCodeOnlyBanner.
  ///
  /// In en, this message translates to:
  /// **'Payments run in code-only mode: add Midtrans keys and deploy Cloud Functions (Blaze) to enable live checkout.'**
  String get adminInvoicesCodeOnlyBanner;

  /// No description provided for @adminInvoicesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No invoices yet'**
  String get adminInvoicesEmptyTitle;

  /// No description provided for @adminInvoicesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Create invoice\" to bill a student for a session package or the HSK book.'**
  String get adminInvoicesEmptySubtitle;

  /// No description provided for @adminInvoicesOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get adminInvoicesOverdue;

  /// No description provided for @adminInvoicesMarkPaidMenu.
  ///
  /// In en, this message translates to:
  /// **'Mark as paid (cash / transfer)'**
  String get adminInvoicesMarkPaidMenu;

  /// No description provided for @adminInvoicesDeletePending.
  ///
  /// In en, this message translates to:
  /// **'Delete pending invoice'**
  String get adminInvoicesDeletePending;

  /// No description provided for @adminInvoicesStudentFallback.
  ///
  /// In en, this message translates to:
  /// **'student'**
  String get adminInvoicesStudentFallback;

  /// No description provided for @adminInvoicesRecorded.
  ///
  /// In en, this message translates to:
  /// **'Recorded: {name} paid {item} by {method}.'**
  String adminInvoicesRecorded(String name, String item, String method);

  /// No description provided for @adminInvoicesDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this pending invoice?'**
  String get adminInvoicesDeleteTitle;

  /// No description provided for @adminInvoicesDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'{number} · {item} for {name}. A voucher linked to it will show \"No payment\" again.'**
  String adminInvoicesDeleteBody(String number, String item, String name);

  /// No description provided for @adminInvoicesDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete: {error}'**
  String adminInvoicesDeleteFailed(String error);

  /// No description provided for @adminInvoicesCardInvoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice {number}'**
  String adminInvoicesCardInvoice(String number);

  /// No description provided for @adminInvoicesCardDue.
  ///
  /// In en, this message translates to:
  /// **'due {date}'**
  String adminInvoicesCardDue(String date);

  /// No description provided for @adminInvoicesPayNow.
  ///
  /// In en, this message translates to:
  /// **'Pay now'**
  String get adminInvoicesPayNow;

  /// No description provided for @adminInvoicesPayAtCentre.
  ///
  /// In en, this message translates to:
  /// **'Pay at the centre by cash or bank transfer. The admin marks it paid and your sessions are added.'**
  String get adminInvoicesPayAtCentre;

  /// No description provided for @adminInvoicesMarkPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as paid'**
  String get adminInvoicesMarkPaid;

  /// No description provided for @adminInvoicesItemFromPriceList.
  ///
  /// In en, this message translates to:
  /// **'Item (from the Price list)'**
  String get adminInvoicesItemFromPriceList;

  /// No description provided for @adminInvoicesGives.
  ///
  /// In en, this message translates to:
  /// **'Gives {gives}.'**
  String adminInvoicesGives(String gives);

  /// No description provided for @adminInvoicesVoucherOpened.
  ///
  /// In en, this message translates to:
  /// **'A voucher is opened when this is paid.'**
  String get adminInvoicesVoucherOpened;

  /// No description provided for @adminInvoicesCashTransfer.
  ///
  /// In en, this message translates to:
  /// **'Cash / transfer'**
  String get adminInvoicesCashTransfer;

  /// No description provided for @adminInvoicesOnlineLink.
  ///
  /// In en, this message translates to:
  /// **'Online link'**
  String get adminInvoicesOnlineLink;

  /// No description provided for @adminInvoicesOnlineHint.
  ///
  /// In en, this message translates to:
  /// **'The student gets a Midtrans payment link; the sessions are added automatically when they pay.'**
  String get adminInvoicesOnlineHint;

  /// No description provided for @adminInvoicesManualHint.
  ///
  /// In en, this message translates to:
  /// **'Recorded as pending. When the money arrives, open the invoice menu and choose Mark as paid.'**
  String get adminInvoicesManualHint;

  /// No description provided for @adminInvoicesOnlineNeedsKeys.
  ///
  /// In en, this message translates to:
  /// **'Online payments need Midtrans keys and the Cloud Functions deployed.'**
  String get adminInvoicesOnlineNeedsKeys;

  /// No description provided for @adminInvoicesDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get adminInvoicesDueDate;

  /// No description provided for @adminInvoicesChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get adminInvoicesChange;

  /// No description provided for @adminInvoicesCreateWithPrice.
  ///
  /// In en, this message translates to:
  /// **'Create invoice · {price}'**
  String adminInvoicesCreateWithPrice(String price);

  /// No description provided for @adminInvoicesChooseStudent.
  ///
  /// In en, this message translates to:
  /// **'Choose a student.'**
  String get adminInvoicesChooseStudent;

  /// No description provided for @adminInvoicesChooseItem.
  ///
  /// In en, this message translates to:
  /// **'Choose an item from the Price list.'**
  String get adminInvoicesChooseItem;

  /// No description provided for @adminInvoicesCreatedOnline.
  ///
  /// In en, this message translates to:
  /// **'Invoice created for {name}'**
  String adminInvoicesCreatedOnline(String name);

  /// No description provided for @adminInvoicesCreatedManual.
  ///
  /// In en, this message translates to:
  /// **'Invoice created for {name} · pending until you mark it paid'**
  String adminInvoicesCreatedManual(String name);

  /// No description provided for @adminInvoicesBankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank transfer'**
  String get adminInvoicesBankTransfer;

  /// No description provided for @adminInvoicesNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get adminInvoicesNoteOptional;

  /// No description provided for @adminInvoicesNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. BCA transfer 27 Oct'**
  String get adminInvoicesNoteHint;

  /// No description provided for @adminInvoicesLinkedVoucherPaid.
  ///
  /// In en, this message translates to:
  /// **'The linked voucher is marked paid.'**
  String get adminInvoicesLinkedVoucherPaid;

  /// No description provided for @adminInvoicesVoucherOpenedFor.
  ///
  /// In en, this message translates to:
  /// **'A {sessions}-session voucher is opened for the student.'**
  String adminInvoicesVoucherOpenedFor(int sessions);

  /// No description provided for @adminInvoicesNoSessionsAdded.
  ///
  /// In en, this message translates to:
  /// **'No sessions are added for this item.'**
  String get adminInvoicesNoSessionsAdded;

  /// No description provided for @adminInvoicesConfirmPayment.
  ///
  /// In en, this message translates to:
  /// **'Confirm payment'**
  String get adminInvoicesConfirmPayment;

  /// No description provided for @adminVouchersNewVoucher.
  ///
  /// In en, this message translates to:
  /// **'New voucher'**
  String get adminVouchersNewVoucher;

  /// No description provided for @adminVouchersPendingPayment.
  ///
  /// In en, this message translates to:
  /// **'Pending payment'**
  String get adminVouchersPendingPayment;

  /// No description provided for @adminVouchersNoPayment.
  ///
  /// In en, this message translates to:
  /// **'No payment'**
  String get adminVouchersNoPayment;

  /// No description provided for @adminVouchersInvoiceMissing.
  ///
  /// In en, this message translates to:
  /// **'Invoice missing'**
  String get adminVouchersInvoiceMissing;

  /// No description provided for @adminVouchersStatusActive.
  ///
  /// In en, this message translates to:
  /// **'active'**
  String get adminVouchersStatusActive;

  /// No description provided for @adminVouchersStatusLow.
  ///
  /// In en, this message translates to:
  /// **'low'**
  String get adminVouchersStatusLow;

  /// No description provided for @adminVouchersStatusDepleted.
  ///
  /// In en, this message translates to:
  /// **'depleted'**
  String get adminVouchersStatusDepleted;

  /// No description provided for @adminVouchersColVoucher.
  ///
  /// In en, this message translates to:
  /// **'Voucher'**
  String get adminVouchersColVoucher;

  /// No description provided for @adminVouchersColSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get adminVouchersColSessions;

  /// No description provided for @adminVouchersColUsed.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get adminVouchersColUsed;

  /// No description provided for @adminVouchersColRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get adminVouchersColRemaining;

  /// No description provided for @adminVouchersColStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get adminVouchersColStart;

  /// No description provided for @adminVouchersColDeadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get adminVouchersColDeadline;

  /// No description provided for @adminVouchersColPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get adminVouchersColPayment;

  /// No description provided for @adminVouchersColPackage.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get adminVouchersColPackage;

  /// No description provided for @adminVouchersVoucherCode.
  ///
  /// In en, this message translates to:
  /// **'Voucher code'**
  String get adminVouchersVoucherCode;

  /// No description provided for @adminVouchersUnknownStudent.
  ///
  /// In en, this message translates to:
  /// **'Unknown student'**
  String get adminVouchersUnknownStudent;

  /// No description provided for @adminVouchersEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit voucher'**
  String get adminVouchersEdit;

  /// No description provided for @adminVouchersDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete voucher'**
  String get adminVouchersDelete;

  /// No description provided for @adminVouchersThisVoucher.
  ///
  /// In en, this message translates to:
  /// **'this voucher'**
  String get adminVouchersThisVoucher;

  /// No description provided for @adminVouchersDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete voucher?'**
  String get adminVouchersDeleteTitle;

  /// No description provided for @adminVouchersDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Delete {code} for {name}? This cannot be undone.'**
  String adminVouchersDeleteBody(String code, String name);

  /// No description provided for @adminVouchersDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted {code}'**
  String adminVouchersDeleted(String code);

  /// No description provided for @adminVouchersIntro.
  ///
  /// In en, this message translates to:
  /// **'A voucher is a student\'s paid term: 8 or 16 class sessions with a start date and a deadline, always linked to a payment (Payments tab). \"Pending payment\" means the invoice is not settled yet; \"No payment\" is an older voucher created before payments were linked. One session is deducted each time a class is concluded.'**
  String get adminVouchersIntro;

  /// No description provided for @adminVouchersSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by code or student…'**
  String get adminVouchersSearchHint;

  /// No description provided for @adminVouchersFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get adminVouchersFilterAll;

  /// No description provided for @adminVouchersEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No vouchers yet'**
  String get adminVouchersEmptyTitle;

  /// No description provided for @adminVouchersNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No vouchers match your search'**
  String get adminVouchersNoMatch;

  /// No description provided for @adminVouchersEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a voucher to issue session packages with trackable codes like 2026_07_001.'**
  String get adminVouchersEmptySubtitle;

  /// No description provided for @adminVouchersCardSessions.
  ///
  /// In en, this message translates to:
  /// **'{sessions} sessions · {remaining} remaining'**
  String adminVouchersCardSessions(int sessions, int remaining);

  /// No description provided for @adminVoucherFormAddPriceItem.
  ///
  /// In en, this message translates to:
  /// **'Add a sessions item to the Price list first.'**
  String get adminVoucherFormAddPriceItem;

  /// No description provided for @adminVoucherFormRecordPaymentFor.
  ///
  /// In en, this message translates to:
  /// **'Record a payment for'**
  String get adminVoucherFormRecordPaymentFor;

  /// No description provided for @adminVoucherFormRecordFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not record the payment: {error}'**
  String adminVoucherFormRecordFailed(String error);

  /// No description provided for @adminVoucherFormNotFound.
  ///
  /// In en, this message translates to:
  /// **'Voucher not found'**
  String get adminVoucherFormNotFound;

  /// No description provided for @adminVoucherFormChoosePayment.
  ///
  /// In en, this message translates to:
  /// **'Choose the payment this voucher belongs to, or record a new one.'**
  String get adminVoucherFormChoosePayment;

  /// No description provided for @adminVoucherFormUpdated.
  ///
  /// In en, this message translates to:
  /// **'Voucher updated'**
  String get adminVoucherFormUpdated;

  /// No description provided for @adminVoucherFormCreated.
  ///
  /// In en, this message translates to:
  /// **'Voucher created'**
  String get adminVoucherFormCreated;

  /// No description provided for @adminVoucherFormIntro.
  ///
  /// In en, this message translates to:
  /// **'Every voucher belongs to a payment. Pick the student, then the invoice that pays for it (or record a cash / transfer payment here). A unique code is generated automatically (e.g. 2026_07_001).'**
  String get adminVoucherFormIntro;

  /// No description provided for @adminVoucherFormNoHsk.
  ///
  /// In en, this message translates to:
  /// **'No HSK'**
  String get adminVoucherFormNoHsk;

  /// No description provided for @adminVoucherFormSelectStudent.
  ///
  /// In en, this message translates to:
  /// **'Select a student'**
  String get adminVoucherFormSelectStudent;

  /// No description provided for @adminVoucherFormPackageSize.
  ///
  /// In en, this message translates to:
  /// **'Package size'**
  String get adminVoucherFormPackageSize;

  /// No description provided for @adminVoucherFormPackageSizeFromPayment.
  ///
  /// In en, this message translates to:
  /// **'Package size (from the payment)'**
  String get adminVoucherFormPackageSizeFromPayment;

  /// No description provided for @adminVoucherFormOfTotal.
  ///
  /// In en, this message translates to:
  /// **'Of {total} total in this package'**
  String adminVoucherFormOfTotal(int total);

  /// No description provided for @adminVoucherFormEnterNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a number'**
  String get adminVoucherFormEnterNumber;

  /// No description provided for @adminVoucherFormRange.
  ///
  /// In en, this message translates to:
  /// **'Must be between 0 and {max}'**
  String adminVoucherFormRange(int max);

  /// No description provided for @adminVoucherFormStart.
  ///
  /// In en, this message translates to:
  /// **'Start: {date}'**
  String adminVoucherFormStart(String date);

  /// No description provided for @adminVoucherFormDeadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline: {date}'**
  String adminVoucherFormDeadline(String date);

  /// No description provided for @adminVoucherFormNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get adminVoucherFormNotesOptional;

  /// No description provided for @adminVoucherFormCreate.
  ///
  /// In en, this message translates to:
  /// **'Create voucher'**
  String get adminVoucherFormCreate;

  /// No description provided for @adminVoucherFormPaymentHelper.
  ///
  /// In en, this message translates to:
  /// **'Paid or pending session invoices without a voucher yet'**
  String get adminVoucherFormPaymentHelper;

  /// No description provided for @adminVoucherFormChoosePaymentShort.
  ///
  /// In en, this message translates to:
  /// **'Choose a payment or record a new one'**
  String get adminVoucherFormChoosePaymentShort;

  /// No description provided for @adminVoucherFormRecordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record a cash / transfer payment'**
  String get adminVoucherFormRecordPayment;

  /// No description provided for @adminVoucherFormNoPaymentOlder.
  ///
  /// In en, this message translates to:
  /// **'No payment recorded (older voucher)'**
  String get adminVoucherFormNoPaymentOlder;

  /// No description provided for @teacherShellNavDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get teacherShellNavDashboard;

  /// No description provided for @teacherShellNavStudents.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get teacherShellNavStudents;

  /// No description provided for @teacherShellNavExercises.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get teacherShellNavExercises;

  /// No description provided for @teacherShellNavClasses.
  ///
  /// In en, this message translates to:
  /// **'Classes'**
  String get teacherShellNavClasses;

  /// No description provided for @teacherShellNavGrades.
  ///
  /// In en, this message translates to:
  /// **'Grades'**
  String get teacherShellNavGrades;

  /// No description provided for @teacherShellNewClass.
  ///
  /// In en, this message translates to:
  /// **'New class'**
  String get teacherShellNewClass;

  /// No description provided for @teacherProfileRoleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Guru · Centre teacher'**
  String get teacherProfileRoleSubtitle;

  /// No description provided for @teacherProfilePersonalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Indonesian and Chinese names plus WhatsApp contact.'**
  String get teacherProfilePersonalSubtitle;

  /// No description provided for @teacherDashNoDemoTitle.
  ///
  /// In en, this message translates to:
  /// **'No demo data yet'**
  String get teacherDashNoDemoTitle;

  /// No description provided for @teacherDashNoDemoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Run scripts/seed_test_accounts.sh then python3 scripts/seed_report_demo_data.py'**
  String get teacherDashNoDemoSubtitle;

  /// No description provided for @teacherDashGradebook.
  ///
  /// In en, this message translates to:
  /// **'Gradebook'**
  String get teacherDashGradebook;

  /// No description provided for @teacherDashPendingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} pending'**
  String teacherDashPendingCount(int count);

  /// No description provided for @teacherDashActiveThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Active this week'**
  String get teacherDashActiveThisWeek;

  /// No description provided for @teacherDashNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get teacherDashNeedsAttention;

  /// No description provided for @teacherDashAllCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up'**
  String get teacherDashAllCaughtUp;

  /// No description provided for @teacherDashNoFollowUp.
  ///
  /// In en, this message translates to:
  /// **'No students need follow-up right now.'**
  String get teacherDashNoFollowUp;

  /// No description provided for @teacherDashRecentStudents.
  ///
  /// In en, this message translates to:
  /// **'Recent students'**
  String get teacherDashRecentStudents;

  /// No description provided for @teacherDashNoStudentsTitle.
  ///
  /// In en, this message translates to:
  /// **'No students yet'**
  String get teacherDashNoStudentsTitle;

  /// No description provided for @teacherDashNoStudentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Students appear here after they register.'**
  String get teacherDashNoStudentsSubtitle;

  /// No description provided for @teacherDashNoCompletedHomeworkTitle.
  ///
  /// In en, this message translates to:
  /// **'No completed homework yet'**
  String get teacherDashNoCompletedHomeworkTitle;

  /// No description provided for @teacherDashNoCompletedHomeworkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Completed practice will appear here once murid submit scores.'**
  String get teacherDashNoCompletedHomeworkSubtitle;

  /// No description provided for @teacherDashNoOverdueTitle.
  ///
  /// In en, this message translates to:
  /// **'No overdue practice'**
  String get teacherDashNoOverdueTitle;

  /// No description provided for @teacherDashNoOverdueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'All assigned homework is on track.'**
  String get teacherDashNoOverdueSubtitle;

  /// No description provided for @teacherDashNoQuizScoresTitle.
  ///
  /// In en, this message translates to:
  /// **'No quiz scores yet'**
  String get teacherDashNoQuizScoresTitle;

  /// No description provided for @teacherDashNoQuizScoresSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Quiz averages appear after murid complete lesson quizzes.'**
  String get teacherDashNoQuizScoresSubtitle;

  /// No description provided for @teacherDashNoPracticeScoresTitle.
  ///
  /// In en, this message translates to:
  /// **'No practice scores yet'**
  String get teacherDashNoPracticeScoresTitle;

  /// No description provided for @teacherDashNoPracticeScoresSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Practice averages appear after murid complete assigned exercises.'**
  String get teacherDashNoPracticeScoresSubtitle;

  /// No description provided for @teacherDashNoHomeworkTitle.
  ///
  /// In en, this message translates to:
  /// **'No homework assigned yet'**
  String get teacherDashNoHomeworkTitle;

  /// No description provided for @teacherDashNoHomeworkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Assign practice from the Exercises tab to track completion here.'**
  String get teacherDashNoHomeworkSubtitle;

  /// No description provided for @teacherDashExerciseCountLevel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 exercise} other{{count} exercises}} · {level}'**
  String teacherDashExerciseCountLevel(int count, String level);

  /// No description provided for @teacherDashNoStudentsToShowTitle.
  ///
  /// In en, this message translates to:
  /// **'No students to show'**
  String get teacherDashNoStudentsToShowTitle;

  /// No description provided for @teacherDashNoStudentsToShowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try again later or check your student roster.'**
  String get teacherDashNoStudentsToShowSubtitle;

  /// No description provided for @teacherDashHomeworkDone.
  ///
  /// In en, this message translates to:
  /// **'{count} done'**
  String teacherDashHomeworkDone(int count);

  /// No description provided for @teacherDashHomeworkToDo.
  ///
  /// In en, this message translates to:
  /// **'{count} to do'**
  String teacherDashHomeworkToDo(int count);

  /// No description provided for @teacherDashHomeworkOverdue.
  ///
  /// In en, this message translates to:
  /// **'{count} overdue'**
  String teacherDashHomeworkOverdue(int count);

  /// No description provided for @teacherDashOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get teacherDashOverdue;

  /// No description provided for @teacherDashPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get teacherDashPending;

  /// No description provided for @teacherDashNoSessionPackagesTitle.
  ///
  /// In en, this message translates to:
  /// **'No session packages'**
  String get teacherDashNoSessionPackagesTitle;

  /// No description provided for @teacherDashNoSessionPackagesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add class terms on a student profile to track sessions.'**
  String get teacherDashNoSessionPackagesSubtitle;

  /// No description provided for @teacherDashSessionsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 session left} other{{count} sessions left}}'**
  String teacherDashSessionsLeft(int count);

  /// No description provided for @teacherDashNoClassesThisWeekTitle.
  ///
  /// In en, this message translates to:
  /// **'No classes this week'**
  String get teacherDashNoClassesThisWeekTitle;

  /// No description provided for @teacherDashNoClassesThisWeekSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a class session from the Classes tab.'**
  String get teacherDashNoClassesThisWeekSubtitle;

  /// No description provided for @teacherDashConcluded.
  ///
  /// In en, this message translates to:
  /// **'Concluded'**
  String get teacherDashConcluded;

  /// No description provided for @teacherDashNoActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'No activity this week'**
  String get teacherDashNoActivityTitle;

  /// No description provided for @teacherDashNoActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Lesson and practice activity will show up here.'**
  String get teacherDashNoActivitySubtitle;

  /// No description provided for @teacherDashStatStudentsTitle.
  ///
  /// In en, this message translates to:
  /// **'All students'**
  String get teacherDashStatStudentsTitle;

  /// No description provided for @teacherDashStatStudentsDescription.
  ///
  /// In en, this message translates to:
  /// **'Every registered murid with progress, homework, and session balance.'**
  String get teacherDashStatStudentsDescription;

  /// No description provided for @teacherDashStatActiveThisWeekDescription.
  ///
  /// In en, this message translates to:
  /// **'Murid who completed a lesson or submitted practice in the last 7 days.'**
  String get teacherDashStatActiveThisWeekDescription;

  /// No description provided for @teacherDashStatHomeworkDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Homework completed'**
  String get teacherDashStatHomeworkDoneTitle;

  /// No description provided for @teacherDashStatHomeworkDoneDescription.
  ///
  /// In en, this message translates to:
  /// **'Assigned practice that murid have finished.'**
  String get teacherDashStatHomeworkDoneDescription;

  /// No description provided for @teacherDashStatOverdueTitle.
  ///
  /// In en, this message translates to:
  /// **'Overdue practice'**
  String get teacherDashStatOverdueTitle;

  /// No description provided for @teacherDashStatOverdueDescription.
  ///
  /// In en, this message translates to:
  /// **'Assigned practice past the due date and not yet completed.'**
  String get teacherDashStatOverdueDescription;

  /// No description provided for @teacherDashStatAvgQuizTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiz averages'**
  String get teacherDashStatAvgQuizTitle;

  /// No description provided for @teacherDashStatAvgQuizDescription.
  ///
  /// In en, this message translates to:
  /// **'Average quiz score per murid across completed lessons.'**
  String get teacherDashStatAvgQuizDescription;

  /// No description provided for @teacherDashStatAvgPracticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Practice averages'**
  String get teacherDashStatAvgPracticeTitle;

  /// No description provided for @teacherDashStatAvgPracticeDescription.
  ///
  /// In en, this message translates to:
  /// **'Best practice score per murid across assigned exercises.'**
  String get teacherDashStatAvgPracticeDescription;

  /// No description provided for @teacherDashStatSessionsLeftTitle.
  ///
  /// In en, this message translates to:
  /// **'Class sessions remaining'**
  String get teacherDashStatSessionsLeftTitle;

  /// No description provided for @teacherDashStatSessionsLeftDescription.
  ///
  /// In en, this message translates to:
  /// **'Remaining live-class sessions on active voucher packages.'**
  String get teacherDashStatSessionsLeftDescription;

  /// No description provided for @teacherDashStatClassesThisWeekTitle.
  ///
  /// In en, this message translates to:
  /// **'Classes this week'**
  String get teacherDashStatClassesThisWeekTitle;

  /// No description provided for @teacherDashStatClassesThisWeekDescription.
  ///
  /// In en, this message translates to:
  /// **'Scheduled class sessions in the current calendar week.'**
  String get teacherDashStatClassesThisWeekDescription;

  /// No description provided for @teacherDashStatNeedAttentionTitle.
  ///
  /// In en, this message translates to:
  /// **'Students needing attention'**
  String get teacherDashStatNeedAttentionTitle;

  /// No description provided for @teacherDashStatNeedAttentionDescription.
  ///
  /// In en, this message translates to:
  /// **'Overdue homework, stale assignments, inactive murid, and low session balance.'**
  String get teacherDashStatNeedAttentionDescription;

  /// No description provided for @teacherDashStatWeeklyActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly activity'**
  String get teacherDashStatWeeklyActivityTitle;

  /// No description provided for @teacherDashStatWeeklyActivityDescription.
  ///
  /// In en, this message translates to:
  /// **'Lesson completions and practice submissions day by day.'**
  String get teacherDashStatWeeklyActivityDescription;

  /// No description provided for @teacherDashStatHomeworkOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Homework overview'**
  String get teacherDashStatHomeworkOverviewTitle;

  /// No description provided for @teacherDashStatHomeworkOverviewDescription.
  ///
  /// In en, this message translates to:
  /// **'Every assigned exercise with status, due date, and best score.'**
  String get teacherDashStatHomeworkOverviewDescription;

  /// No description provided for @teacherAttClassCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 class} other{{count} classes}}'**
  String teacherAttClassCount(int count);

  /// No description provided for @teacherAttConcludedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} concluded'**
  String teacherAttConcludedCount(int count);

  /// No description provided for @teacherAttNewClassThisDay.
  ///
  /// In en, this message translates to:
  /// **'New class this day'**
  String get teacherAttNewClassThisDay;

  /// No description provided for @teacherAttEmptyDayHint.
  ///
  /// In en, this message translates to:
  /// **'Pick another day, or create a class on this date. Dots on the calendar mark days with classes: teal = open, grey = concluded.'**
  String get teacherAttEmptyDayHint;

  /// No description provided for @teacherAttClassConcludedTitle.
  ///
  /// In en, this message translates to:
  /// **'Class concluded'**
  String get teacherAttClassConcludedTitle;

  /// No description provided for @teacherAttClassConcludedBody.
  ///
  /// In en, this message translates to:
  /// **'{title} concluded. {summary}.'**
  String teacherAttClassConcludedBody(String title, String summary);

  /// No description provided for @teacherAttConcludeSummary.
  ///
  /// In en, this message translates to:
  /// **'{excused, plural, =0{{charged} charged} other{{charged} charged, {excused} excused}}'**
  String teacherAttConcludeSummary(int charged, int excused);

  /// No description provided for @teacherAttConcludedSnack.
  ///
  /// In en, this message translates to:
  /// **'Class concluded. {summary}.'**
  String teacherAttConcludedSnack(String summary);

  /// No description provided for @teacherAttConcludedWithFailures.
  ///
  /// In en, this message translates to:
  /// **'Class concluded. {charged} charged; could not charge: {names}'**
  String teacherAttConcludedWithFailures(int charged, String names);

  /// No description provided for @teacherAttStudentAdded.
  ///
  /// In en, this message translates to:
  /// **'{name} added to class'**
  String teacherAttStudentAdded(String name);

  /// No description provided for @teacherAttRemoveStudentTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove student?'**
  String get teacherAttRemoveStudentTitle;

  /// No description provided for @teacherAttRemoveStudentBody.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from \"{title}\"?'**
  String teacherAttRemoveStudentBody(String name, String title);

  /// No description provided for @teacherAttStudentRemoved.
  ///
  /// In en, this message translates to:
  /// **'{name} removed from class'**
  String teacherAttStudentRemoved(String name);

  /// No description provided for @teacherAttAllStudentsInClass.
  ///
  /// In en, this message translates to:
  /// **'All students are already in this class'**
  String get teacherAttAllStudentsInClass;

  /// No description provided for @teacherAttAddStudent.
  ///
  /// In en, this message translates to:
  /// **'Add student'**
  String get teacherAttAddStudent;

  /// No description provided for @teacherAttClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get teacherAttClose;

  /// No description provided for @teacherAttDeleteClassTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this class?'**
  String get teacherAttDeleteClassTitle;

  /// No description provided for @teacherAttDeleteClassBody.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\"? All student join records for this class will be removed. This cannot be undone.'**
  String teacherAttDeleteClassBody(String title);

  /// No description provided for @teacherAttDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get teacherAttDelete;

  /// No description provided for @teacherAttClassDeleted.
  ///
  /// In en, this message translates to:
  /// **'Class deleted'**
  String get teacherAttClassDeleted;

  /// No description provided for @teacherAttThisStudent.
  ///
  /// In en, this message translates to:
  /// **'This student'**
  String get teacherAttThisStudent;

  /// No description provided for @teacherAttNoCreditsFor.
  ///
  /// In en, this message translates to:
  /// **'{name} has no class sessions left. Add an 8 or 16 session term from their profile.'**
  String teacherAttNoCreditsFor(String name);

  /// No description provided for @teacherAttDeletePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Could not delete: permission denied.'**
  String get teacherAttDeletePermissionDenied;

  /// No description provided for @teacherAttDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete class ({code})'**
  String teacherAttDeleteFailed(String code);

  /// No description provided for @teacherAttStatsConcluded.
  ///
  /// In en, this message translates to:
  /// **'{joined} joined · {charged} charged'**
  String teacherAttStatsConcluded(int joined, int charged);

  /// No description provided for @teacherAttStatsOpen.
  ///
  /// In en, this message translates to:
  /// **'{joined}/{capacity} joined · {pending} pending'**
  String teacherAttStatsOpen(int joined, int capacity, int pending);

  /// No description provided for @teacherAttConcludedAt.
  ///
  /// In en, this message translates to:
  /// **'Concluded {date}'**
  String teacherAttConcludedAt(String date);

  /// No description provided for @teacherAttConclude.
  ///
  /// In en, this message translates to:
  /// **'Conclude'**
  String get teacherAttConclude;

  /// No description provided for @teacherAttEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get teacherAttEdit;

  /// No description provided for @teacherAttAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a student'**
  String get teacherAttAdd;

  /// No description provided for @teacherAttAtCapacity.
  ///
  /// In en, this message translates to:
  /// **'Class is at capacity.'**
  String get teacherAttAtCapacity;

  /// No description provided for @teacherAttStudentsCount.
  ///
  /// In en, this message translates to:
  /// **'Students ({count})'**
  String teacherAttStudentsCount(int count);

  /// No description provided for @teacherAttNoStudentsJoined.
  ///
  /// In en, this message translates to:
  /// **'No students joined yet.'**
  String get teacherAttNoStudentsJoined;

  /// No description provided for @teacherAttChipCharged.
  ///
  /// In en, this message translates to:
  /// **'Charged'**
  String get teacherAttChipCharged;

  /// No description provided for @teacherAttChipNotCharged.
  ///
  /// In en, this message translates to:
  /// **'Not charged'**
  String get teacherAttChipNotCharged;

  /// No description provided for @teacherAttChipAdded.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get teacherAttChipAdded;

  /// No description provided for @teacherAttNoAttendanceYet.
  ///
  /// In en, this message translates to:
  /// **'No attendance recorded yet.'**
  String get teacherAttNoAttendanceYet;

  /// No description provided for @teacherAttNoClassAttendanceYet.
  ///
  /// In en, this message translates to:
  /// **'No class attendance recorded yet.'**
  String get teacherAttNoClassAttendanceYet;

  /// No description provided for @teacherAttSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get teacherAttSessions;

  /// No description provided for @teacherAttRate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get teacherAttRate;

  /// No description provided for @teacherSessionPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Could not complete action: permission denied.'**
  String get teacherSessionPermissionDenied;

  /// No description provided for @teacherSessionActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not complete action ({code})'**
  String teacherSessionActionFailed(String code);

  /// No description provided for @teacherSessionTimeAndDuration.
  ///
  /// In en, this message translates to:
  /// **'{time} · {minutes} min'**
  String teacherSessionTimeAndDuration(String time, int minutes);

  /// No description provided for @teacherSessionStudentsJoined.
  ///
  /// In en, this message translates to:
  /// **'Students who joined'**
  String get teacherSessionStudentsJoined;

  /// No description provided for @teacherSessionSelfJoin.
  ///
  /// In en, this message translates to:
  /// **'Self join'**
  String get teacherSessionSelfJoin;

  /// No description provided for @teacherSessionDeleteClass.
  ///
  /// In en, this message translates to:
  /// **'Delete class'**
  String get teacherSessionDeleteClass;

  /// No description provided for @teacherSessionEndAfterStart.
  ///
  /// In en, this message translates to:
  /// **'End time must be after start time.'**
  String get teacherSessionEndAfterStart;

  /// No description provided for @teacherSessionEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit class'**
  String get teacherSessionEditTitle;

  /// No description provided for @teacherSessionClassTitle.
  ///
  /// In en, this message translates to:
  /// **'Class title'**
  String get teacherSessionClassTitle;

  /// No description provided for @teacherSessionClassTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. HSK 3 — Speaking practice'**
  String get teacherSessionClassTitleHint;

  /// No description provided for @teacherSessionClassTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a class title'**
  String get teacherSessionClassTitleRequired;

  /// No description provided for @teacherSessionDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get teacherSessionDate;

  /// No description provided for @teacherSessionStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get teacherSessionStart;

  /// No description provided for @teacherSessionEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get teacherSessionEnd;

  /// No description provided for @teacherSessionDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get teacherSessionDuration;

  /// No description provided for @teacherSessionMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String teacherSessionMinutes(int minutes);

  /// No description provided for @teacherSessionCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get teacherSessionCapacity;

  /// No description provided for @teacherSessionCapacityHint.
  ///
  /// In en, this message translates to:
  /// **'Max students who can join'**
  String get teacherSessionCapacityHint;

  /// No description provided for @teacherSessionCapacityMin.
  ///
  /// In en, this message translates to:
  /// **'Enter a capacity of at least 1'**
  String get teacherSessionCapacityMin;

  /// No description provided for @teacherSessionOpenToJoin.
  ///
  /// In en, this message translates to:
  /// **'Open for students to join'**
  String get teacherSessionOpenToJoin;

  /// No description provided for @teacherSessionOpenToJoinHint.
  ///
  /// In en, this message translates to:
  /// **'Students can join from Home while the class is open.'**
  String get teacherSessionOpenToJoinHint;

  /// No description provided for @teacherSessionSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get teacherSessionSaveChanges;

  /// No description provided for @teacherSessionCreate.
  ///
  /// In en, this message translates to:
  /// **'Create class'**
  String get teacherSessionCreate;

  /// No description provided for @teacherSessionModeOffline.
  ///
  /// In en, this message translates to:
  /// **'In-person'**
  String get teacherSessionModeOffline;

  /// No description provided for @teacherSessionModeOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get teacherSessionModeOnline;

  /// No description provided for @teacherSessionModeHybrid.
  ///
  /// In en, this message translates to:
  /// **'Hybrid'**
  String get teacherSessionModeHybrid;

  /// No description provided for @teacherSessionRegDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get teacherSessionRegDraft;

  /// No description provided for @teacherSessionRegOpen.
  ///
  /// In en, this message translates to:
  /// **'Open for registration'**
  String get teacherSessionRegOpen;

  /// No description provided for @teacherSessionRegActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get teacherSessionRegActive;

  /// No description provided for @teacherSessionRegClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get teacherSessionRegClosed;

  /// No description provided for @teacherStudentsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load students: {error}'**
  String teacherStudentsLoadFailed(String error);

  /// No description provided for @studentDetailNotFound.
  ///
  /// In en, this message translates to:
  /// **'Student not found'**
  String get studentDetailNotFound;

  /// No description provided for @studentDetailEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get studentDetailEditProfile;

  /// No description provided for @studentDetailExportReport.
  ///
  /// In en, this message translates to:
  /// **'Export progress report'**
  String get studentDetailExportReport;

  /// No description provided for @studentDetailLessonsPerTerm.
  ///
  /// In en, this message translates to:
  /// **'{count} lessons/term'**
  String studentDetailLessonsPerTerm(int count);

  /// No description provided for @studentDetailContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get studentDetailContact;

  /// No description provided for @studentDetailExportReportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export progress report (PDF)'**
  String get studentDetailExportReportPdf;

  /// No description provided for @studentDetailAttendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get studentDetailAttendance;

  /// No description provided for @studentDetailPracticeResults.
  ///
  /// In en, this message translates to:
  /// **'Practice results'**
  String get studentDetailPracticeResults;

  /// No description provided for @studentDetailLessonProgressByTerm.
  ///
  /// In en, this message translates to:
  /// **'Lesson progress by term'**
  String get studentDetailLessonProgressByTerm;

  /// No description provided for @studentDetailNoLessonProgress.
  ///
  /// In en, this message translates to:
  /// **'No lesson progress yet.'**
  String get studentDetailNoLessonProgress;

  /// No description provided for @studentDetailNoInvoices.
  ///
  /// In en, this message translates to:
  /// **'No invoices yet.'**
  String get studentDetailNoInvoices;

  /// No description provided for @studentDetailPaidTotal.
  ///
  /// In en, this message translates to:
  /// **'Paid {amount}'**
  String studentDetailPaidTotal(String amount);

  /// No description provided for @studentDetailPendingTotal.
  ///
  /// In en, this message translates to:
  /// **'Pending {amount}'**
  String studentDetailPendingTotal(String amount);

  /// No description provided for @studentDetailPaidOn.
  ///
  /// In en, this message translates to:
  /// **'paid {date}'**
  String studentDetailPaidOn(String date);

  /// No description provided for @studentDetailDueOn.
  ///
  /// In en, this message translates to:
  /// **'due {date}'**
  String studentDetailDueOn(String date);

  /// No description provided for @studentDetailMoreInPayments.
  ///
  /// In en, this message translates to:
  /// **'and {count} more in Payments'**
  String studentDetailMoreInPayments(int count);

  /// No description provided for @studentDetailPresentCount.
  ///
  /// In en, this message translates to:
  /// **'{count} present'**
  String studentDetailPresentCount(int count);

  /// No description provided for @studentDetailExcusedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} excused'**
  String studentDetailExcusedCount(int count);

  /// No description provided for @studentDetailAbsentCount.
  ///
  /// In en, this message translates to:
  /// **'{count} absent'**
  String studentDetailAbsentCount(int count);

  /// No description provided for @studentDetailNotMarked.
  ///
  /// In en, this message translates to:
  /// **'Not marked'**
  String get studentDetailNotMarked;

  /// No description provided for @teacherGradesNew.
  ///
  /// In en, this message translates to:
  /// **'New grade'**
  String get teacherGradesNew;

  /// No description provided for @teacherGradesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No grades yet'**
  String get teacherGradesEmptyTitle;

  /// No description provided for @teacherGradesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Record an assessment score, or schedule a pending grade to fill in later.'**
  String get teacherGradesEmptySubtitle;

  /// No description provided for @teacherGradesPendingHeader.
  ///
  /// In en, this message translates to:
  /// **'Grades pending ({count})'**
  String teacherGradesPendingHeader(int count);

  /// No description provided for @teacherGradesRecorded.
  ///
  /// In en, this message translates to:
  /// **'Recorded'**
  String get teacherGradesRecorded;

  /// No description provided for @teacherGradesNoRecorded.
  ///
  /// In en, this message translates to:
  /// **'No recorded grades yet.'**
  String get teacherGradesNoRecorded;

  /// No description provided for @teacherGradesColAssessment.
  ///
  /// In en, this message translates to:
  /// **'Assessment'**
  String get teacherGradesColAssessment;

  /// No description provided for @teacherGradesColCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get teacherGradesColCategory;

  /// No description provided for @teacherGradesColScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get teacherGradesColScore;

  /// No description provided for @teacherGradesColLetter.
  ///
  /// In en, this message translates to:
  /// **'Letter'**
  String get teacherGradesColLetter;

  /// No description provided for @teacherGradesColStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get teacherGradesColStatus;

  /// No description provided for @teacherGradesColActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get teacherGradesColActions;

  /// No description provided for @teacherGradesAddScore.
  ///
  /// In en, this message translates to:
  /// **'Add score'**
  String get teacherGradesAddScore;

  /// No description provided for @teacherGradesEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit grade'**
  String get teacherGradesEdit;

  /// No description provided for @teacherGradesDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete grade'**
  String get teacherGradesDelete;

  /// No description provided for @teacherGradesDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete grade?'**
  String get teacherGradesDeleteTitle;

  /// No description provided for @teacherGradesDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This removes the grade for this student.'**
  String get teacherGradesDeleteBody;

  /// No description provided for @teacherGradesPickStudent.
  ///
  /// In en, this message translates to:
  /// **'Pick a student'**
  String get teacherGradesPickStudent;

  /// No description provided for @teacherGradesPickStudentError.
  ///
  /// In en, this message translates to:
  /// **'Pick a student.'**
  String get teacherGradesPickStudentError;

  /// No description provided for @teacherGradesSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save grade: {error}'**
  String teacherGradesSaveFailed(String error);

  /// No description provided for @teacherGradesTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get teacherGradesTitleLabel;

  /// No description provided for @teacherGradesTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Speaking Test, Midterm'**
  String get teacherGradesTitleHint;

  /// No description provided for @teacherGradesTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a title'**
  String get teacherGradesTitleRequired;

  /// No description provided for @teacherGradesScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Score (0–100)'**
  String get teacherGradesScoreLabel;

  /// No description provided for @teacherGradesScoreLabelOptional.
  ///
  /// In en, this message translates to:
  /// **'Score (0–100) — leave blank to schedule'**
  String get teacherGradesScoreLabelOptional;

  /// No description provided for @teacherGradesScoreRange.
  ///
  /// In en, this message translates to:
  /// **'Enter a number 0–100'**
  String get teacherGradesScoreRange;

  /// No description provided for @teacherGradesSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get teacherGradesSave;

  /// No description provided for @teacherGradesCreate.
  ///
  /// In en, this message translates to:
  /// **'Create grade'**
  String get teacherGradesCreate;

  /// No description provided for @teacherGradesLetterHint.
  ///
  /// In en, this message translates to:
  /// **'Letter grade: {letter}'**
  String teacherGradesLetterHint(String letter);

  /// No description provided for @teacherGradesCategoryQuiz.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get teacherGradesCategoryQuiz;

  /// No description provided for @teacherGradesCategoryExercise.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get teacherGradesCategoryExercise;

  /// No description provided for @teacherGradesCategorySpeaking.
  ///
  /// In en, this message translates to:
  /// **'Speaking'**
  String get teacherGradesCategorySpeaking;

  /// No description provided for @teacherGradesCategoryWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing'**
  String get teacherGradesCategoryWriting;

  /// No description provided for @teacherGradesCategoryExam.
  ///
  /// In en, this message translates to:
  /// **'Exam'**
  String get teacherGradesCategoryExam;

  /// No description provided for @teacherGradesCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get teacherGradesCategoryOther;

  /// No description provided for @teacherGradesStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get teacherGradesStatusPending;

  /// No description provided for @teacherGradesStatusGraded.
  ///
  /// In en, this message translates to:
  /// **'Graded'**
  String get teacherGradesStatusGraded;

  /// No description provided for @concludeTitle.
  ///
  /// In en, this message translates to:
  /// **'Conclude class'**
  String get concludeTitle;

  /// No description provided for @concludeHint.
  ///
  /// In en, this message translates to:
  /// **'Mark who came. Present and Absent charge 1 session from the student\'s term; Excused (before class) is not charged.'**
  String get concludeHint;

  /// No description provided for @concludeNoStudents.
  ///
  /// In en, this message translates to:
  /// **'No students to charge. Concluding only closes the class.'**
  String get concludeNoStudents;

  /// No description provided for @concludeChargeSummary.
  ///
  /// In en, this message translates to:
  /// **'{charged} of {total} will be charged. This cannot be undone.'**
  String concludeChargeSummary(int charged, int total);

  /// No description provided for @leaveClassTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave this class?'**
  String get leaveClassTitle;

  /// No description provided for @leaveClassBody.
  ///
  /// In en, this message translates to:
  /// **'You will be removed from the class roster. You can join again from Home if the class is still open and has space.'**
  String get leaveClassBody;

  /// No description provided for @leaveClassStay.
  ///
  /// In en, this message translates to:
  /// **'Stay in class'**
  String get leaveClassStay;

  /// No description provided for @appShellBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get appShellBack;

  /// No description provided for @evaluationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Evaluations'**
  String get evaluationsTitle;

  /// No description provided for @evaluationsNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get evaluationsNew;

  /// No description provided for @evaluationsFormsClosed.
  ///
  /// In en, this message translates to:
  /// **'Evaluation forms are closed. An admin can open them in Settings.'**
  String get evaluationsFormsClosed;

  /// No description provided for @evaluationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No evaluations yet.'**
  String get evaluationsEmpty;

  /// No description provided for @evaluationsFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Evaluation'**
  String get evaluationsFallbackTitle;

  /// No description provided for @evaluationsPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get evaluationsPublished;

  /// No description provided for @evaluationsDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get evaluationsDraft;

  /// No description provided for @evaluationsEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit evaluation'**
  String get evaluationsEditTitle;

  /// No description provided for @evaluationsNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New evaluation'**
  String get evaluationsNewTitle;

  /// No description provided for @evaluationsTermLabel.
  ///
  /// In en, this message translates to:
  /// **'Term'**
  String get evaluationsTermLabel;

  /// No description provided for @evaluationsTermHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Semester 1 2026'**
  String get evaluationsTermHint;

  /// No description provided for @evaluationsTermRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a term'**
  String get evaluationsTermRequired;

  /// No description provided for @evaluationsRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get evaluationsRating;

  /// No description provided for @evaluationsStrengths.
  ///
  /// In en, this message translates to:
  /// **'Strengths'**
  String get evaluationsStrengths;

  /// No description provided for @evaluationsImprovements.
  ///
  /// In en, this message translates to:
  /// **'Areas to improve'**
  String get evaluationsImprovements;

  /// No description provided for @evaluationsComment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get evaluationsComment;

  /// No description provided for @evaluationsSaveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get evaluationsSaveDraft;

  /// No description provided for @evaluationsPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get evaluationsPublish;

  /// No description provided for @transcriptEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Assessment results and practice scores will appear here as they are recorded.'**
  String get transcriptEmptySubtitle;

  /// No description provided for @transcriptPendingHeader.
  ///
  /// In en, this message translates to:
  /// **'Upcoming / pending'**
  String get transcriptPendingHeader;

  /// No description provided for @transcriptTeacherEvaluations.
  ///
  /// In en, this message translates to:
  /// **'Teacher evaluations'**
  String get transcriptTeacherEvaluations;

  /// No description provided for @transcriptTitle.
  ///
  /// In en, this message translates to:
  /// **'Transcript'**
  String get transcriptTitle;

  /// No description provided for @transcriptPracticeExercise.
  ///
  /// In en, this message translates to:
  /// **'Practice exercise'**
  String get transcriptPracticeExercise;

  /// No description provided for @transcriptLessonQuiz.
  ///
  /// In en, this message translates to:
  /// **'Lesson quiz'**
  String get transcriptLessonQuiz;

  /// No description provided for @transcriptToImprove.
  ///
  /// In en, this message translates to:
  /// **'To improve'**
  String get transcriptToImprove;

  /// No description provided for @transcriptAwaitingScore.
  ///
  /// In en, this message translates to:
  /// **'{category} · awaiting score'**
  String transcriptAwaitingScore(String category);

  /// No description provided for @calendarFormatMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get calendarFormatMonth;

  /// No description provided for @calendarFormatTwoWeeks.
  ///
  /// In en, this message translates to:
  /// **'2 weeks'**
  String get calendarFormatTwoWeeks;

  /// No description provided for @calendarFormatWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get calendarFormatWeek;

  /// No description provided for @calendarNoClasses.
  ///
  /// In en, this message translates to:
  /// **'No classes'**
  String get calendarNoClasses;

  /// No description provided for @calendarNoSessionsOn.
  ///
  /// In en, this message translates to:
  /// **'No class sessions on {date}.'**
  String calendarNoSessionsOn(String date);

  /// No description provided for @calendarCapacity.
  ///
  /// In en, this message translates to:
  /// **'Cap {count}'**
  String calendarCapacity(int count);

  /// No description provided for @calendarConcluded.
  ///
  /// In en, this message translates to:
  /// **'concluded'**
  String get calendarConcluded;

  /// No description provided for @exerciseTypeMultipleChoice.
  ///
  /// In en, this message translates to:
  /// **'Multiple choice'**
  String get exerciseTypeMultipleChoice;

  /// No description provided for @exerciseTypeComposeSentences.
  ///
  /// In en, this message translates to:
  /// **'Compose sentences (组词成句)'**
  String get exerciseTypeComposeSentences;

  /// No description provided for @exerciseTypeMatching.
  ///
  /// In en, this message translates to:
  /// **'Matching (对话配对)'**
  String get exerciseTypeMatching;

  /// No description provided for @exerciseTypeListening.
  ///
  /// In en, this message translates to:
  /// **'Listening (听力)'**
  String get exerciseTypeListening;

  /// No description provided for @exerciseTypeReadingCloze.
  ///
  /// In en, this message translates to:
  /// **'Fill in the blank (选词填空)'**
  String get exerciseTypeReadingCloze;

  /// No description provided for @exerciseTypePictureSentence.
  ///
  /// In en, this message translates to:
  /// **'Picture + keyword sentence'**
  String get exerciseTypePictureSentence;

  /// No description provided for @exerciseTypeTypeHanzi.
  ///
  /// In en, this message translates to:
  /// **'Type the hanzi (写汉字)'**
  String get exerciseTypeTypeHanzi;

  /// No description provided for @exerciseCategoryExercise.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get exerciseCategoryExercise;

  /// No description provided for @exerciseCategoryQuiz.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get exerciseCategoryQuiz;

  /// No description provided for @exerciseCategoryExam.
  ///
  /// In en, this message translates to:
  /// **'Exam'**
  String get exerciseCategoryExam;

  /// No description provided for @exerciseCategoryHskSimulation.
  ///
  /// In en, this message translates to:
  /// **'HSK Simulation'**
  String get exerciseCategoryHskSimulation;

  /// No description provided for @skillCategoryReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get skillCategoryReading;

  /// No description provided for @skillCategoryListening.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get skillCategoryListening;

  /// No description provided for @skillCategoryTyping.
  ///
  /// In en, this message translates to:
  /// **'Typing (Writing)'**
  String get skillCategoryTyping;

  /// No description provided for @skillCategorySpeaking.
  ///
  /// In en, this message translates to:
  /// **'Speaking'**
  String get skillCategorySpeaking;

  /// No description provided for @bankTextOrder.
  ///
  /// In en, this message translates to:
  /// **'Order: {segments}'**
  String bankTextOrder(String segments);

  /// No description provided for @bankTextAnswer.
  ///
  /// In en, this message translates to:
  /// **'Answer: {answer}'**
  String bankTextAnswer(String answer);

  /// No description provided for @bankTextPinyin.
  ///
  /// In en, this message translates to:
  /// **'Pinyin {pinyin} → {answers}'**
  String bankTextPinyin(String pinyin, String answers);

  /// No description provided for @bankTextTypeHanziInEditor.
  ///
  /// In en, this message translates to:
  /// **'type the hanzi in the editor'**
  String get bankTextTypeHanziInEditor;

  /// No description provided for @bankTextKeyword.
  ///
  /// In en, this message translates to:
  /// **'Keyword: {keyword}'**
  String bankTextKeyword(String keyword);

  /// No description provided for @bankTextNoOptionsYet.
  ///
  /// In en, this message translates to:
  /// **'No answer options read yet'**
  String get bankTextNoOptionsYet;

  /// No description provided for @bankTextQuestionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 question} other{{count} questions}}'**
  String bankTextQuestionCount(int count);

  /// No description provided for @exerciseCardToDoCount.
  ///
  /// In en, this message translates to:
  /// **'{count} to do'**
  String exerciseCardToDoCount(int count);

  /// No description provided for @exerciseCardOverdueCount.
  ///
  /// In en, this message translates to:
  /// **'{count} overdue'**
  String exerciseCardOverdueCount(int count);

  /// No description provided for @exerciseCardDoneCount.
  ///
  /// In en, this message translates to:
  /// **'{count} done'**
  String exerciseCardDoneCount(int count);

  /// No description provided for @exerciseCardWorksheets.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 worksheet} other{{count} worksheets}}'**
  String exerciseCardWorksheets(int count);

  /// No description provided for @exerciseCardNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get exerciseCardNotStarted;

  /// No description provided for @exerciseCardOverdueLower.
  ///
  /// In en, this message translates to:
  /// **'overdue'**
  String get exerciseCardOverdueLower;

  /// No description provided for @exerciseCardBest.
  ///
  /// In en, this message translates to:
  /// **'Best {score}%'**
  String exerciseCardBest(int score);

  /// No description provided for @exerciseCardAttempts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 attempt} other{{count} attempts}}'**
  String exerciseCardAttempts(int count);

  /// No description provided for @exerciseCardTapToRetry.
  ///
  /// In en, this message translates to:
  /// **'Tap to retry'**
  String get exerciseCardTapToRetry;

  /// No description provided for @exerciseCardLast.
  ///
  /// In en, this message translates to:
  /// **'Last {date}'**
  String exerciseCardLast(String date);

  /// No description provided for @exerciseCardStatusToDo.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get exerciseCardStatusToDo;

  /// No description provided for @exerciseCardStatusOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get exerciseCardStatusOverdue;

  /// No description provided for @exerciseCardStatusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get exerciseCardStatusDone;

  /// No description provided for @exerciseCardDue.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String exerciseCardDue(String date);

  /// No description provided for @exerciseCardOverdueOn.
  ///
  /// In en, this message translates to:
  /// **'Overdue · {date}'**
  String exerciseCardOverdueOn(String date);

  /// No description provided for @exerciseCardUnknownStudent.
  ///
  /// In en, this message translates to:
  /// **'Unknown student'**
  String get exerciseCardUnknownStudent;

  /// No description provided for @exerciseCardThisLevel.
  ///
  /// In en, this message translates to:
  /// **'this level'**
  String get exerciseCardThisLevel;

  /// No description provided for @exerciseCardStudentProgress.
  ///
  /// In en, this message translates to:
  /// **'Student progress'**
  String get exerciseCardStudentProgress;

  /// No description provided for @exerciseCardNoStudentsRegistered.
  ///
  /// In en, this message translates to:
  /// **'No {level} students registered yet.'**
  String exerciseCardNoStudentsRegistered(String level);

  /// No description provided for @exerciseCardCompletedOpenTo.
  ///
  /// In en, this message translates to:
  /// **'{completed}/{total} completed · open to {level}'**
  String exerciseCardCompletedOpenTo(int completed, int total, String level);

  /// No description provided for @exerciseCardPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get exerciseCardPending;

  /// No description provided for @exerciseCardClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get exerciseCardClose;

  /// No description provided for @exerciseCardNoPracticeTitle.
  ///
  /// In en, this message translates to:
  /// **'No practice assigned'**
  String get exerciseCardNoPracticeTitle;

  /// No description provided for @exerciseCardNoPracticeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Assigned exercises will appear here.'**
  String get exerciseCardNoPracticeSubtitle;

  /// No description provided for @exerciseCardBestScoreRetry.
  ///
  /// In en, this message translates to:
  /// **'Best score: {score}% · Tap to retry'**
  String exerciseCardBestScoreRetry(int score);

  /// No description provided for @bankFiltersSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search worksheet or question'**
  String get bankFiltersSearchHint;

  /// No description provided for @bankFiltersTypeOfExercise.
  ///
  /// In en, this message translates to:
  /// **'Type of exercise'**
  String get bankFiltersTypeOfExercise;

  /// No description provided for @bankFiltersQuestionType.
  ///
  /// In en, this message translates to:
  /// **'Question type'**
  String get bankFiltersQuestionType;

  /// No description provided for @bankFiltersLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get bankFiltersLevel;

  /// No description provided for @bankFiltersAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get bankFiltersAll;

  /// No description provided for @bankTitle.
  ///
  /// In en, this message translates to:
  /// **'Question bank'**
  String get bankTitle;

  /// No description provided for @bankCsvWorksheetOrQuestion.
  ///
  /// In en, this message translates to:
  /// **'Worksheet / question'**
  String get bankCsvWorksheetOrQuestion;

  /// No description provided for @bankCsvCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get bankCsvCode;

  /// No description provided for @bankQuestions.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get bankQuestions;

  /// No description provided for @bankUsed.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get bankUsed;

  /// No description provided for @bankActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get bankActions;

  /// No description provided for @bankTypeOfExerciseFor.
  ///
  /// In en, this message translates to:
  /// **'Type of exercise for {what}'**
  String bankTypeOfExerciseFor(String what);

  /// No description provided for @bankLevelFor.
  ///
  /// In en, this message translates to:
  /// **'Level for {what}'**
  String bankLevelFor(String what);

  /// No description provided for @bankSetTo.
  ///
  /// In en, this message translates to:
  /// **'{what} set to {value}.'**
  String bankSetTo(String what, String value);

  /// No description provided for @bankDeleteWhat.
  ///
  /// In en, this message translates to:
  /// **'Delete {what}?'**
  String bankDeleteWhat(String what);

  /// No description provided for @bankDeleteBulkBody.
  ///
  /// In en, this message translates to:
  /// **'All {questions} leave the bank. Exercises that already use them keep their copies. This cannot be undone.'**
  String bankDeleteBulkBody(String questions);

  /// No description provided for @bankDeleted.
  ///
  /// In en, this message translates to:
  /// **'{what} deleted.'**
  String bankDeleted(String what);

  /// No description provided for @bankCountJoin.
  ///
  /// In en, this message translates to:
  /// **'{a} and {b}'**
  String bankCountJoin(String a, String b);

  /// No description provided for @bankApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get bankApply;

  /// No description provided for @bankNewExerciseWithSheets.
  ///
  /// In en, this message translates to:
  /// **'New exercise ({worksheets})'**
  String bankNewExerciseWithSheets(String worksheets);

  /// No description provided for @bankSetTypeOfExercise.
  ///
  /// In en, this message translates to:
  /// **'Set type of exercise'**
  String get bankSetTypeOfExercise;

  /// No description provided for @bankSetLevel.
  ///
  /// In en, this message translates to:
  /// **'Set level'**
  String get bankSetLevel;

  /// No description provided for @bankDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get bankDelete;

  /// No description provided for @bankEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get bankEdit;

  /// No description provided for @bankView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get bankView;

  /// No description provided for @bankTypeAQuestion.
  ///
  /// In en, this message translates to:
  /// **'Type a question'**
  String get bankTypeAQuestion;

  /// No description provided for @bankLoadSamples.
  ///
  /// In en, this message translates to:
  /// **'Load the centre\'s sample sheets (10 worksheets)'**
  String get bankLoadSamples;

  /// No description provided for @bankBulkPaste.
  ///
  /// In en, this message translates to:
  /// **'Bulk import — paste'**
  String get bankBulkPaste;

  /// No description provided for @bankScanWorksheet.
  ///
  /// In en, this message translates to:
  /// **'Scan worksheet'**
  String get bankScanWorksheet;

  /// No description provided for @bankNoWorksheetsTitle.
  ///
  /// In en, this message translates to:
  /// **'No worksheets yet'**
  String get bankNoWorksheetsTitle;

  /// No description provided for @bankNoWorksheetsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan a worksheet to add it whole, or type a single question. Exercises pull from here.'**
  String get bankNoWorksheetsSubtitle;

  /// No description provided for @bankNoMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get bankNoMatchesTitle;

  /// No description provided for @bankAdjustFilters.
  ///
  /// In en, this message translates to:
  /// **'Adjust the filters.'**
  String get bankAdjustFilters;

  /// No description provided for @bankUsedCount.
  ///
  /// In en, this message translates to:
  /// **'Used {count}'**
  String bankUsedCount(int count);

  /// No description provided for @bankAddFromBankType.
  ///
  /// In en, this message translates to:
  /// **'Add from bank — {type}'**
  String bankAddFromBankType(String type);

  /// No description provided for @bankAddCount.
  ///
  /// In en, this message translates to:
  /// **'Add ({count})'**
  String bankAddCount(int count);

  /// No description provided for @bankFilterHint.
  ///
  /// In en, this message translates to:
  /// **'Filter worksheets and questions…'**
  String get bankFilterHint;

  /// No description provided for @bankSelectAllFiltered.
  ///
  /// In en, this message translates to:
  /// **'Select all ({count} filtered)'**
  String bankSelectAllFiltered(int count);

  /// No description provided for @bankNoMatchingTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching bank questions'**
  String get bankNoMatchingTitle;

  /// No description provided for @bankNoMatchingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add questions of this type to the bank first.'**
  String get bankNoMatchingSubtitle;

  /// No description provided for @bankSheetAssignThis.
  ///
  /// In en, this message translates to:
  /// **'Assign this worksheet'**
  String get bankSheetAssignThis;

  /// No description provided for @bankSheetEditTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit worksheet (title, type, level)'**
  String get bankSheetEditTooltip;

  /// No description provided for @bankSheetDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete worksheet'**
  String get bankSheetDeleteTooltip;

  /// No description provided for @bankSheetRemovedTitle.
  ///
  /// In en, this message translates to:
  /// **'Worksheet removed'**
  String get bankSheetRemovedTitle;

  /// No description provided for @bankSheetRemovedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Its questions are no longer in the bank.'**
  String get bankSheetRemovedSubtitle;

  /// No description provided for @bankSheetAddQuestion.
  ///
  /// In en, this message translates to:
  /// **'Add question'**
  String get bankSheetAddQuestion;

  /// No description provided for @bankSheetRemoveQuestionTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this question?'**
  String get bankSheetRemoveQuestionTitle;

  /// No description provided for @bankSheetRemoveQuestionBody.
  ///
  /// In en, this message translates to:
  /// **'It leaves the worksheet and the bank. Exercises that already use it keep their copy.'**
  String get bankSheetRemoveQuestionBody;

  /// No description provided for @bankSheetDeleteSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete worksheet {code}?'**
  String bankSheetDeleteSheetTitle(String code);

  /// No description provided for @bankSheetDeleteSheetBody.
  ///
  /// In en, this message translates to:
  /// **'All {questions} leave the bank. Exercises that already use them keep their copies.'**
  String bankSheetDeleteSheetBody(String questions);

  /// No description provided for @bankSheetUsedTimes.
  ///
  /// In en, this message translates to:
  /// **'used {count}×'**
  String bankSheetUsedTimes(int count);

  /// No description provided for @bankSheetNoPrompt.
  ///
  /// In en, this message translates to:
  /// **'(no prompt)'**
  String get bankSheetNoPrompt;

  /// No description provided for @bankSheetEditQuestion.
  ///
  /// In en, this message translates to:
  /// **'Edit question'**
  String get bankSheetEditQuestion;

  /// No description provided for @bankSheetRemoveFromSheet.
  ///
  /// In en, this message translates to:
  /// **'Remove from worksheet'**
  String get bankSheetRemoveFromSheet;

  /// No description provided for @bankSheetEditSheet.
  ///
  /// In en, this message translates to:
  /// **'Edit worksheet'**
  String get bankSheetEditSheet;

  /// No description provided for @bankSheetCodeStays.
  ///
  /// In en, this message translates to:
  /// **'Code {code} stays the same.'**
  String bankSheetCodeStays(String code);

  /// No description provided for @bankSheetCategoryHelper.
  ///
  /// In en, this message translates to:
  /// **'Exercise, quiz, exam or HSK simulation.'**
  String get bankSheetCategoryHelper;

  /// No description provided for @bankSheetTypeChangesShape.
  ///
  /// In en, this message translates to:
  /// **'This type stores answers differently: open each question afterwards and check its answer.'**
  String get bankSheetTypeChangesShape;

  /// No description provided for @bankSheetTypeAppliesAll.
  ///
  /// In en, this message translates to:
  /// **'Applies to every question on the sheet.'**
  String get bankSheetTypeAppliesAll;

  /// No description provided for @bankEditorNeedTwoParts.
  ///
  /// In en, this message translates to:
  /// **'Enter at least two sentence parts.'**
  String get bankEditorNeedTwoParts;

  /// No description provided for @bankEditorEnterQuestion.
  ///
  /// In en, this message translates to:
  /// **'Enter the question.'**
  String get bankEditorEnterQuestion;

  /// No description provided for @bankEditorNeedTwoWords.
  ///
  /// In en, this message translates to:
  /// **'Enter at least two words in the word bank.'**
  String get bankEditorNeedTwoWords;

  /// No description provided for @bankEditorEnterPinyin.
  ///
  /// In en, this message translates to:
  /// **'Enter the pinyin hint.'**
  String get bankEditorEnterPinyin;

  /// No description provided for @bankEditorNeedAccepted.
  ///
  /// In en, this message translates to:
  /// **'Enter at least one accepted answer.'**
  String get bankEditorNeedAccepted;

  /// No description provided for @bankEditorEnterKeyword.
  ///
  /// In en, this message translates to:
  /// **'Enter the word the sentence must use.'**
  String get bankEditorEnterKeyword;

  /// No description provided for @bankEditorNeedTwoChoices.
  ///
  /// In en, this message translates to:
  /// **'Enter at least two choices.'**
  String get bankEditorNeedTwoChoices;

  /// No description provided for @bankEditorCorrectEmpty.
  ///
  /// In en, this message translates to:
  /// **'The correct choice is empty.'**
  String get bankEditorCorrectEmpty;

  /// No description provided for @bankEditorUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {error}'**
  String bankEditorUploadFailed(String error);

  /// No description provided for @bankEditorCouldNotSave.
  ///
  /// In en, this message translates to:
  /// **'Could not save: {error}'**
  String bankEditorCouldNotSave(String error);

  /// No description provided for @bankEditorAddToSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a question to {title}'**
  String bankEditorAddToSheetTitle(String title);

  /// No description provided for @bankEditorNewQuestion.
  ///
  /// In en, this message translates to:
  /// **'New question'**
  String get bankEditorNewQuestion;

  /// No description provided for @bankEditorExplanationOptional.
  ///
  /// In en, this message translates to:
  /// **'Explanation (optional)'**
  String get bankEditorExplanationOptional;

  /// No description provided for @bankEditorExplanationHelper.
  ///
  /// In en, this message translates to:
  /// **'Why the answer is right. Students see it on the result page after they submit, never while answering.'**
  String get bankEditorExplanationHelper;

  /// No description provided for @bankEditorSkill.
  ///
  /// In en, this message translates to:
  /// **'Skill'**
  String get bankEditorSkill;

  /// No description provided for @bankEditorSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get bankEditorSave;

  /// No description provided for @bankEditorAddToWorksheet.
  ///
  /// In en, this message translates to:
  /// **'Add to worksheet'**
  String get bankEditorAddToWorksheet;

  /// No description provided for @bankEditorAddToBank.
  ///
  /// In en, this message translates to:
  /// **'Add to bank'**
  String get bankEditorAddToBank;

  /// No description provided for @bankEditorOptionalSuffix.
  ///
  /// In en, this message translates to:
  /// **'{label} (optional)'**
  String bankEditorOptionalSuffix(String label);

  /// No description provided for @bankEditorQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get bankEditorQuestion;

  /// No description provided for @bankEditorListeningHelper.
  ///
  /// In en, this message translates to:
  /// **'Add the audio below; the student hears it and picks a choice.'**
  String get bankEditorListeningHelper;

  /// No description provided for @bankEditorChoicesTick.
  ///
  /// In en, this message translates to:
  /// **'Choices (tick the correct one)'**
  String get bankEditorChoicesTick;

  /// No description provided for @bankEditorSentenceWithBlank.
  ///
  /// In en, this message translates to:
  /// **'Sentence with the blank'**
  String get bankEditorSentenceWithBlank;

  /// No description provided for @bankEditorQuestionOrLine.
  ///
  /// In en, this message translates to:
  /// **'Question or line'**
  String get bankEditorQuestionOrLine;

  /// No description provided for @bankEditorClozeHelper.
  ///
  /// In en, this message translates to:
  /// **'Write the blank as ____ ; the student picks the word from the bank.'**
  String get bankEditorClozeHelper;

  /// No description provided for @bankEditorMatchingHelper.
  ///
  /// In en, this message translates to:
  /// **'The student matches it to one word or reply from the bank.'**
  String get bankEditorMatchingHelper;

  /// No description provided for @bankEditorWordBank.
  ///
  /// In en, this message translates to:
  /// **'Word bank (one per line)'**
  String get bankEditorWordBank;

  /// No description provided for @bankEditorWordBankHelper.
  ///
  /// In en, this message translates to:
  /// **'Shared by the whole worksheet: the same list on every question of this sheet.'**
  String get bankEditorWordBankHelper;

  /// No description provided for @bankEditorCorrectAnswer.
  ///
  /// In en, this message translates to:
  /// **'Correct answer'**
  String get bankEditorCorrectAnswer;

  /// No description provided for @bankEditorBlankNumber.
  ///
  /// In en, this message translates to:
  /// **'Blank #'**
  String get bankEditorBlankNumber;

  /// No description provided for @bankEditorSentenceParts.
  ///
  /// In en, this message translates to:
  /// **'Sentence parts in the right order (one per line)'**
  String get bankEditorSentenceParts;

  /// No description provided for @bankEditorSentencePartsHelper.
  ///
  /// In en, this message translates to:
  /// **'The student sees them shuffled and puts them back in order.'**
  String get bankEditorSentencePartsHelper;

  /// No description provided for @bankEditorInstruction.
  ///
  /// In en, this message translates to:
  /// **'Instruction'**
  String get bankEditorInstruction;

  /// No description provided for @bankEditorPinyinHint.
  ///
  /// In en, this message translates to:
  /// **'Pinyin hint'**
  String get bankEditorPinyinHint;

  /// No description provided for @bankEditorPinyinHelper.
  ///
  /// In en, this message translates to:
  /// **'What the student sees, e.g. nǐ hǎo.'**
  String get bankEditorPinyinHelper;

  /// No description provided for @bankEditorAcceptedAnswers.
  ///
  /// In en, this message translates to:
  /// **'Accepted answers (one per line)'**
  String get bankEditorAcceptedAnswers;

  /// No description provided for @bankEditorAcceptedHelper.
  ///
  /// In en, this message translates to:
  /// **'Hanzi that count as correct, e.g. 你好.'**
  String get bankEditorAcceptedHelper;

  /// No description provided for @bankEditorKeywordLabel.
  ///
  /// In en, this message translates to:
  /// **'Word the sentence must use'**
  String get bankEditorKeywordLabel;

  /// No description provided for @bankEditorKeywordHelper.
  ///
  /// In en, this message translates to:
  /// **'The student writes a sentence with this word about the picture.'**
  String get bankEditorKeywordHelper;

  /// No description provided for @bankEditorChoice.
  ///
  /// In en, this message translates to:
  /// **'Choice {letter}'**
  String bankEditorChoice(String letter);

  /// No description provided for @bankEditorRemoveChoice.
  ///
  /// In en, this message translates to:
  /// **'Remove choice'**
  String get bankEditorRemoveChoice;

  /// No description provided for @bankEditorAddChoice.
  ///
  /// In en, this message translates to:
  /// **'Add choice'**
  String get bankEditorAddChoice;

  /// No description provided for @bankEditorMediaOptional.
  ///
  /// In en, this message translates to:
  /// **'Media (optional)'**
  String get bankEditorMediaOptional;

  /// No description provided for @bankEditorAddImage.
  ///
  /// In en, this message translates to:
  /// **'Add image'**
  String get bankEditorAddImage;

  /// No description provided for @bankEditorImageAttached.
  ///
  /// In en, this message translates to:
  /// **'Image attached'**
  String get bankEditorImageAttached;

  /// No description provided for @bankEditorAddAudio.
  ///
  /// In en, this message translates to:
  /// **'Add audio'**
  String get bankEditorAddAudio;

  /// No description provided for @bankEditorAudioAttached.
  ///
  /// In en, this message translates to:
  /// **'Audio attached'**
  String get bankEditorAudioAttached;

  /// No description provided for @bankImportPasteTitle.
  ///
  /// In en, this message translates to:
  /// **'Paste questions'**
  String get bankImportPasteTitle;

  /// No description provided for @bankImportPasteHint.
  ///
  /// In en, this message translates to:
  /// **'Paste worksheet text (numbered questions + A/B/C/D options).'**
  String get bankImportPasteHint;

  /// No description provided for @bankImportPasteExample.
  ///
  /// In en, this message translates to:
  /// **'1. 你好 means…\nA. hello\nB. goodbye'**
  String get bankImportPasteExample;

  /// No description provided for @bankImportType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get bankImportType;

  /// No description provided for @bankImportImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get bankImportImport;

  /// No description provided for @bankImportNoneParsed.
  ///
  /// In en, this message translates to:
  /// **'No questions could be parsed.'**
  String get bankImportNoneParsed;

  /// No description provided for @bankImportAllSamplesPresent.
  ///
  /// In en, this message translates to:
  /// **'All sample questions are already in the bank.'**
  String get bankImportAllSamplesPresent;

  /// No description provided for @bankImportSampleSummary.
  ///
  /// In en, this message translates to:
  /// **'{name}: {count} questions from 10 sheets with answer keys{skippedNote}. Pictures for the 看图写句子 keywords are added in the editor.'**
  String bankImportSampleSummary(String name, int count, String skippedNote);

  /// No description provided for @bankImportSampleSkipped.
  ///
  /// In en, this message translates to:
  /// **', {count} already in the bank'**
  String bankImportSampleSkipped(int count);

  /// No description provided for @bankImportNothingToImport.
  ///
  /// In en, this message translates to:
  /// **'No questions to import.'**
  String get bankImportNothingToImport;

  /// No description provided for @bankImportParsedFromPaste.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 question parsed from the pasted text.} other{{count} questions parsed from the pasted text.}}'**
  String bankImportParsedFromPaste(int count);

  /// No description provided for @bankImportReplacedSheet.
  ///
  /// In en, this message translates to:
  /// **'Replaced worksheet {code} ({questions}) in the bank.'**
  String bankImportReplacedSheet(String code, String questions);

  /// No description provided for @bankImportAddedSheet.
  ///
  /// In en, this message translates to:
  /// **'Added worksheet {code} ({questions}) in the bank.'**
  String bankImportAddedSheet(String code, String questions);

  /// No description provided for @bankImportReplacedQuestions.
  ///
  /// In en, this message translates to:
  /// **'Replaced {questions} in the bank.'**
  String bankImportReplacedQuestions(String questions);

  /// No description provided for @bankImportAddedQuestions.
  ///
  /// In en, this message translates to:
  /// **'Added {questions} in the bank.'**
  String bankImportAddedQuestions(String questions);

  /// No description provided for @bankImportCouldNotImport.
  ///
  /// In en, this message translates to:
  /// **'Could not import: {error}'**
  String bankImportCouldNotImport(String error);

  /// No description provided for @bankImportReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Check before adding'**
  String get bankImportReviewTitle;

  /// No description provided for @bankImportReviewWorksheet.
  ///
  /// In en, this message translates to:
  /// **'Worksheet {code}'**
  String bankImportReviewWorksheet(String code);

  /// No description provided for @bankImportReviewAddedAsOne.
  ///
  /// In en, this message translates to:
  /// **'Added to the bank as one worksheet. Untick a question to leave it out.'**
  String get bankImportReviewAddedAsOne;

  /// No description provided for @bankImportReviewAlreadyInBank.
  ///
  /// In en, this message translates to:
  /// **'This worksheet is already in the bank with {questions}.'**
  String bankImportReviewAlreadyInBank(String questions);

  /// No description provided for @bankImportReviewReplaceIt.
  ///
  /// In en, this message translates to:
  /// **'Replace it'**
  String get bankImportReviewReplaceIt;

  /// No description provided for @bankImportReviewKeepBoth.
  ///
  /// In en, this message translates to:
  /// **'Keep both'**
  String get bankImportReviewKeepBoth;

  /// No description provided for @bankImportReviewReplaceWorksheet.
  ///
  /// In en, this message translates to:
  /// **'Replace worksheet ({questions})'**
  String bankImportReviewReplaceWorksheet(String questions);

  /// No description provided for @bankImportReviewAddWorksheet.
  ///
  /// In en, this message translates to:
  /// **'Add worksheet ({questions})'**
  String bankImportReviewAddWorksheet(String questions);

  /// No description provided for @bankImportReviewAddToBank.
  ///
  /// In en, this message translates to:
  /// **'Add {count} to bank'**
  String bankImportReviewAddToBank(int count);

  /// No description provided for @bankHarvestCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load exercises: {error}'**
  String bankHarvestCouldNotLoad(String error);

  /// No description provided for @bankHarvestNoNew.
  ///
  /// In en, this message translates to:
  /// **'No new questions — {skipped} already in the bank.'**
  String bankHarvestNoNew(int skipped);

  /// No description provided for @bankHarvestTitle.
  ///
  /// In en, this message translates to:
  /// **'Import from exercises'**
  String get bankHarvestTitle;

  /// No description provided for @bankHarvestFound.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Found 1 new question.} other{Found {count} new questions.}}\n{skipped} already in the bank (skipped).'**
  String bankHarvestFound(int count, int skipped);

  /// No description provided for @bankHarvestImportCount.
  ///
  /// In en, this message translates to:
  /// **'Import {count}'**
  String bankHarvestImportCount(int count);

  /// No description provided for @bankHarvestImported.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Imported 1 question from exercises.} other{Imported {count} questions from exercises.}}'**
  String bankHarvestImported(int count);

  /// No description provided for @worksheetCouldNotReadFile.
  ///
  /// In en, this message translates to:
  /// **'Could not read the selected file.'**
  String get worksheetCouldNotReadFile;

  /// No description provided for @worksheetImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String worksheetImportFailed(String error);

  /// No description provided for @worksheetImporting.
  ///
  /// In en, this message translates to:
  /// **'Importing worksheet'**
  String get worksheetImporting;

  /// No description provided for @worksheetTimingNote.
  ///
  /// In en, this message translates to:
  /// **'Text PDFs and Word files take a few seconds. Scanned pages and photos take 20–40 seconds each (Scan paper: about 5); the first scan also downloads the Chinese OCR data (about 15 MB; about 45 MB for Scan paper).'**
  String get worksheetTimingNote;

  /// No description provided for @worksheetElapsed.
  ///
  /// In en, this message translates to:
  /// **'Elapsed {time}'**
  String worksheetElapsed(String time);

  /// No description provided for @worksheetEstimating.
  ///
  /// In en, this message translates to:
  /// **'estimating time left…'**
  String get worksheetEstimating;

  /// No description provided for @worksheetAlmostDone.
  ///
  /// In en, this message translates to:
  /// **'almost done'**
  String get worksheetAlmostDone;

  /// No description provided for @worksheetAboutSecondsLeft.
  ///
  /// In en, this message translates to:
  /// **'about {seconds} s left'**
  String worksheetAboutSecondsLeft(int seconds);

  /// No description provided for @worksheetAboutMinutesLeft.
  ///
  /// In en, this message translates to:
  /// **'about {minutes} min left'**
  String worksheetAboutMinutesLeft(int minutes);

  /// No description provided for @worksheetFewMinutesLeft.
  ///
  /// In en, this message translates to:
  /// **'a few minutes left'**
  String get worksheetFewMinutesLeft;

  /// No description provided for @worksheetAnswerKeyFilled.
  ///
  /// In en, this message translates to:
  /// **'Answer key: {filled} of {total} answers filled from the centre\'s sample set.'**
  String worksheetAnswerKeyFilled(int filled, int total);

  /// No description provided for @worksheetAnswerKeyFilledCode.
  ///
  /// In en, this message translates to:
  /// **'Answer key: {filled} of {total} answers filled from the centre\'s sample set ({code}).'**
  String worksheetAnswerKeyFilledCode(int filled, int total, String code);

  /// No description provided for @worksheetNoKeyCompose.
  ///
  /// In en, this message translates to:
  /// **'No answer key on this sheet: the sentences keep the order shown on the sheet. Put the words in the correct order in the question bank.'**
  String get worksheetNoKeyCompose;

  /// No description provided for @worksheetNoKeyTypeHanzi.
  ///
  /// In en, this message translates to:
  /// **'No answer key on this sheet: add the accepted hanzi for each item in the question bank.'**
  String get worksheetNoKeyTypeHanzi;

  /// No description provided for @worksheetNoKeyDefault.
  ///
  /// In en, this message translates to:
  /// **'No answer key on this sheet: every answer is set to A (the first option). Correct them in the question bank.'**
  String get worksheetNoKeyDefault;

  /// No description provided for @worksheetReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review import'**
  String get worksheetReviewTitle;

  /// No description provided for @worksheetDetectedFormat.
  ///
  /// In en, this message translates to:
  /// **'Detected format'**
  String get worksheetDetectedFormat;

  /// No description provided for @worksheetSuggestedLevel.
  ///
  /// In en, this message translates to:
  /// **'Suggested level: {level}'**
  String worksheetSuggestedLevel(String level);

  /// No description provided for @worksheetTypeNotSupported.
  ///
  /// In en, this message translates to:
  /// **'This exercise type is not fully supported yet. You can still copy instructions or edit the text.'**
  String get worksheetTypeNotSupported;

  /// No description provided for @worksheetInstructionsOnly.
  ///
  /// In en, this message translates to:
  /// **'Instructions only'**
  String get worksheetInstructionsOnly;

  /// No description provided for @worksheetImportCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Import 1 question} other{Import {count} questions}}'**
  String worksheetImportCount(int count);

  /// No description provided for @worksheetImportQuestions.
  ///
  /// In en, this message translates to:
  /// **'Import questions'**
  String get worksheetImportQuestions;

  /// No description provided for @worksheetExerciseType.
  ///
  /// In en, this message translates to:
  /// **'Exercise type'**
  String get worksheetExerciseType;

  /// No description provided for @worksheetExtractedText.
  ///
  /// In en, this message translates to:
  /// **'Extracted text'**
  String get worksheetExtractedText;

  /// No description provided for @worksheetEditIfMisread.
  ///
  /// In en, this message translates to:
  /// **'Edit if OCR misread anything…'**
  String get worksheetEditIfMisread;

  /// No description provided for @worksheetReanalyze.
  ///
  /// In en, this message translates to:
  /// **'Re-analyze'**
  String get worksheetReanalyze;

  /// No description provided for @worksheetSentencePreview.
  ///
  /// In en, this message translates to:
  /// **'Sentence preview'**
  String get worksheetSentencePreview;

  /// No description provided for @worksheetQuestionPreview.
  ///
  /// In en, this message translates to:
  /// **'Question preview'**
  String get worksheetQuestionPreview;

  /// No description provided for @worksheetNoQuestionsDetected.
  ///
  /// In en, this message translates to:
  /// **'No questions detected yet. Edit the text and tap Re-analyze.'**
  String get worksheetNoQuestionsDetected;

  /// No description provided for @worksheetAndMore.
  ///
  /// In en, this message translates to:
  /// **'…and {count} more'**
  String worksheetAndMore(int count);

  /// No description provided for @worksheetPreviewPinyin.
  ///
  /// In en, this message translates to:
  /// **'pinyin: {pinyin} → {answers}'**
  String worksheetPreviewPinyin(String pinyin, String answers);

  /// No description provided for @worksheetPreviewTypeInEditor.
  ///
  /// In en, this message translates to:
  /// **'(type the hanzi in the editor)'**
  String get worksheetPreviewTypeInEditor;

  /// No description provided for @worksheetPreviewKeyword.
  ///
  /// In en, this message translates to:
  /// **'keyword: {keyword}'**
  String worksheetPreviewKeyword(String keyword);

  /// No description provided for @worksheetPreviewAddOptions.
  ///
  /// In en, this message translates to:
  /// **'(add options)'**
  String get worksheetPreviewAddOptions;

  /// No description provided for @assignAssignedTo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Assigned to 1 student} other{Assigned to {count} students}}{removed}.'**
  String assignAssignedTo(int count, String removed);

  /// No description provided for @assignRemovedFrom.
  ///
  /// In en, this message translates to:
  /// **', removed from {count}'**
  String assignRemovedFrom(int count);

  /// No description provided for @assignCouldNot.
  ///
  /// In en, this message translates to:
  /// **'Could not assign: {error}'**
  String assignCouldNot(String error);

  /// No description provided for @assignTitle.
  ///
  /// In en, this message translates to:
  /// **'Assign \"{title}\"'**
  String assignTitle(String title);

  /// No description provided for @assignOnlyTicked.
  ///
  /// In en, this message translates to:
  /// **'Only the students you tick can open this exercise.'**
  String get assignOnlyTicked;

  /// No description provided for @assignSearchStudents.
  ///
  /// In en, this message translates to:
  /// **'Search students'**
  String get assignSearchStudents;

  /// No description provided for @assignSelectAllShown.
  ///
  /// In en, this message translates to:
  /// **'Select all shown ({count})'**
  String assignSelectAllShown(int count);

  /// No description provided for @assignClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get assignClear;

  /// No description provided for @assignNoDueDate.
  ///
  /// In en, this message translates to:
  /// **'No due date'**
  String get assignNoDueDate;

  /// No description provided for @assignNoStudentsTitle.
  ///
  /// In en, this message translates to:
  /// **'No students match'**
  String get assignNoStudentsTitle;

  /// No description provided for @assignNoStudentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Change the level or the search.'**
  String get assignNoStudentsSubtitle;

  /// No description provided for @assignAlreadyAssigned.
  ///
  /// In en, this message translates to:
  /// **'assigned'**
  String get assignAlreadyAssigned;

  /// No description provided for @assignSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get assignSaving;

  /// No description provided for @assignSaveCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Save (1 student)} other{Save ({count} students)}}'**
  String assignSaveCount(int count);

  /// No description provided for @packageFormAddAtLeastOne.
  ///
  /// In en, this message translates to:
  /// **'Add at least one worksheet or question.'**
  String get packageFormAddAtLeastOne;

  /// No description provided for @packageFormSaved.
  ///
  /// In en, this message translates to:
  /// **'Exercise saved.'**
  String get packageFormSaved;

  /// No description provided for @packageFormCreated.
  ///
  /// In en, this message translates to:
  /// **'Exercise created.'**
  String get packageFormCreated;

  /// No description provided for @packageFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit exercise'**
  String get packageFormEditTitle;

  /// No description provided for @packageFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get packageFormTitle;

  /// No description provided for @packageFormEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a title'**
  String get packageFormEnterTitle;

  /// No description provided for @packageFormSkillSection.
  ///
  /// In en, this message translates to:
  /// **'Skill section'**
  String get packageFormSkillSection;

  /// No description provided for @packageFormInstructionsOptional.
  ///
  /// In en, this message translates to:
  /// **'Instructions (optional)'**
  String get packageFormInstructionsOptional;

  /// No description provided for @packageFormTimeLimit.
  ///
  /// In en, this message translates to:
  /// **'Time limit in minutes (optional)'**
  String get packageFormTimeLimit;

  /// No description provided for @packageFormTimeLimitHelper.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for no limit. With a limit the clock counts down and the exercise submits itself at zero.'**
  String get packageFormTimeLimitHelper;

  /// No description provided for @packageFormEnterMinutes.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number of minutes'**
  String get packageFormEnterMinutes;

  /// No description provided for @packageFormPublishedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Assigned students can open it. Drafts stay hidden.'**
  String get packageFormPublishedSubtitle;

  /// No description provided for @packageFormContents.
  ///
  /// In en, this message translates to:
  /// **'Contents · {questions}'**
  String packageFormContents(String questions);

  /// No description provided for @packageFormAddFromBank.
  ///
  /// In en, this message translates to:
  /// **'Add from bank'**
  String get packageFormAddFromBank;

  /// No description provided for @packageFormNothingYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet. Add worksheets from the question bank; the students get them in this order. Edit a worksheet in the bank later and this exercise follows.'**
  String get packageFormNothingYet;

  /// No description provided for @packageFormNotInBank.
  ///
  /// In en, this message translates to:
  /// **'Not in the bank any more'**
  String get packageFormNotInBank;

  /// No description provided for @packageFormQuestionRemoved.
  ///
  /// In en, this message translates to:
  /// **'(question removed)'**
  String get packageFormQuestionRemoved;

  /// No description provided for @packageFormSaveDraftOrPublish.
  ///
  /// In en, this message translates to:
  /// **'Save as draft or publish'**
  String get packageFormSaveDraftOrPublish;

  /// No description provided for @packageFormSaveAndAssign.
  ///
  /// In en, this message translates to:
  /// **'Save and assign'**
  String get packageFormSaveAndAssign;

  /// No description provided for @packageFormMoveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get packageFormMoveUp;

  /// No description provided for @packageFormMoveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get packageFormMoveDown;

  /// No description provided for @packageFormRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get packageFormRemove;

  /// No description provided for @packageFormAddFromQuestionBank.
  ///
  /// In en, this message translates to:
  /// **'Add from the question bank'**
  String get packageFormAddFromQuestionBank;

  /// No description provided for @packageFormDoneCount.
  ///
  /// In en, this message translates to:
  /// **'Done ({count})'**
  String packageFormDoneCount(int count);

  /// No description provided for @packageFormSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search worksheets and questions…'**
  String get packageFormSearchHint;

  /// No description provided for @packageFormBankEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'The bank is empty'**
  String get packageFormBankEmptyTitle;

  /// No description provided for @packageFormNoMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing in the bank matches'**
  String get packageFormNoMatchTitle;

  /// No description provided for @packageFormBankEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan a worksheet to add the first one.'**
  String get packageFormBankEmptySubtitle;

  /// No description provided for @packageFormNoMatchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Change the search or the filters.'**
  String get packageFormNoMatchSubtitle;

  /// No description provided for @packageFormOpenEditSheet.
  ///
  /// In en, this message translates to:
  /// **'Open and edit this worksheet'**
  String get packageFormOpenEditSheet;

  /// No description provided for @packageFormEditQuestion.
  ///
  /// In en, this message translates to:
  /// **'Edit this question'**
  String get packageFormEditQuestion;

  /// No description provided for @teacherExExercise.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get teacherExExercise;

  /// No description provided for @teacherExContents.
  ///
  /// In en, this message translates to:
  /// **'Contents'**
  String get teacherExContents;

  /// No description provided for @teacherExStudents.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get teacherExStudents;

  /// No description provided for @teacherExDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get teacherExDone;

  /// No description provided for @teacherExNextDue.
  ///
  /// In en, this message translates to:
  /// **'Next due'**
  String get teacherExNextDue;

  /// No description provided for @teacherExStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get teacherExStatus;

  /// No description provided for @teacherExExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get teacherExExportCsv;

  /// No description provided for @teacherExSelected.
  ///
  /// In en, this message translates to:
  /// **'selected'**
  String get teacherExSelected;

  /// No description provided for @teacherExBulkPublished.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 exercise published.} other{{count} exercises published.}}'**
  String teacherExBulkPublished(int count);

  /// No description provided for @teacherExBulkDraft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 exercise set to draft.} other{{count} exercises set to draft.}}'**
  String teacherExBulkDraft(int count);

  /// No description provided for @teacherExDeleteCountTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Delete 1 exercise?} other{Delete {count} exercises?}}'**
  String teacherExDeleteCountTitle(int count);

  /// No description provided for @teacherExDeleteBulkBody.
  ///
  /// In en, this message translates to:
  /// **'Students lose these assignments. Their past results stay. This cannot be undone.'**
  String get teacherExDeleteBulkBody;

  /// No description provided for @teacherExBulkDeleted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 exercise deleted.} other{{count} exercises deleted.}}'**
  String teacherExBulkDeleted(int count);

  /// No description provided for @teacherExPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get teacherExPublish;

  /// No description provided for @teacherExSetToDraft.
  ///
  /// In en, this message translates to:
  /// **'Set to draft'**
  String get teacherExSetToDraft;

  /// No description provided for @teacherExViewOnly.
  ///
  /// In en, this message translates to:
  /// **'View only'**
  String get teacherExViewOnly;

  /// No description provided for @teacherExAdminRequired.
  ///
  /// In en, this message translates to:
  /// **'Admin access required'**
  String get teacherExAdminRequired;

  /// No description provided for @teacherExDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete exercise?'**
  String get teacherExDeleteTitle;

  /// No description provided for @teacherExDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\"? This cannot be undone.'**
  String teacherExDeleteBody(String title);

  /// No description provided for @teacherExDeleted.
  ///
  /// In en, this message translates to:
  /// **'Exercise deleted'**
  String get teacherExDeleted;

  /// No description provided for @teacherExSingleQuestions.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 single question} other{{count} single questions}}'**
  String teacherExSingleQuestions(int count);

  /// No description provided for @teacherExSentences.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 sentence} other{{count} sentences}}'**
  String teacherExSentences(int count);

  /// No description provided for @teacherExSearchExercises.
  ///
  /// In en, this message translates to:
  /// **'Search exercises'**
  String get teacherExSearchExercises;

  /// No description provided for @teacherExNewExercise.
  ///
  /// In en, this message translates to:
  /// **'New exercise'**
  String get teacherExNewExercise;

  /// No description provided for @teacherExFromBank.
  ///
  /// In en, this message translates to:
  /// **'From the question bank'**
  String get teacherExFromBank;

  /// No description provided for @teacherExOldFormat.
  ///
  /// In en, this message translates to:
  /// **'Old format, students cannot play it'**
  String get teacherExOldFormat;

  /// No description provided for @teacherExNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get teacherExNone;

  /// No description provided for @teacherExStudentsFinished.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} students finished'**
  String teacherExStudentsFinished(int completed, int total);

  /// No description provided for @teacherExDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get teacherExDue;

  /// No description provided for @teacherExNoExercisesTitle.
  ///
  /// In en, this message translates to:
  /// **'No exercises yet'**
  String get teacherExNoExercisesTitle;

  /// No description provided for @teacherExNoExercisesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'An exercise bundles worksheets from the question bank; students see it once it is assigned to them.'**
  String get teacherExNoExercisesSubtitle;

  /// No description provided for @teacherExNoExercisesSubtitleReadOnly.
  ///
  /// In en, this message translates to:
  /// **'An exercise bundles worksheets from the question bank; students see it once it is assigned to them. Exercises are built on web.'**
  String get teacherExNoExercisesSubtitleReadOnly;

  /// No description provided for @teacherExPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get teacherExPublished;

  /// No description provided for @teacherExDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get teacherExDraft;

  /// No description provided for @teacherExAssign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get teacherExAssign;

  /// No description provided for @teacherExDraftHidden.
  ///
  /// In en, this message translates to:
  /// **'Draft — not visible to students'**
  String get teacherExDraftHidden;

  /// No description provided for @teacherExNotAssigned.
  ///
  /// In en, this message translates to:
  /// **'Not assigned yet'**
  String get teacherExNotAssigned;

  /// No description provided for @teacherExStudentsDone.
  ///
  /// In en, this message translates to:
  /// **'{completed}/{total} students done'**
  String teacherExStudentsDone(int completed, int total);

  /// No description provided for @teacherExDueLower.
  ///
  /// In en, this message translates to:
  /// **'due {date}'**
  String teacherExDueLower(String date);

  /// No description provided for @routeTitleNewUser.
  ///
  /// In en, this message translates to:
  /// **'New user'**
  String get routeTitleNewUser;

  /// No description provided for @routeTitleEditUser.
  ///
  /// In en, this message translates to:
  /// **'Edit user'**
  String get routeTitleEditUser;

  /// No description provided for @routeTitleStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get routeTitleStudent;

  /// No description provided for @routeTitleNewVoucher.
  ///
  /// In en, this message translates to:
  /// **'New voucher'**
  String get routeTitleNewVoucher;

  /// No description provided for @routeTitleEditVoucher.
  ///
  /// In en, this message translates to:
  /// **'Edit voucher'**
  String get routeTitleEditVoucher;

  /// No description provided for @routeTitleNewExercise.
  ///
  /// In en, this message translates to:
  /// **'New exercise'**
  String get routeTitleNewExercise;

  /// No description provided for @routeTitleEditExercise.
  ///
  /// In en, this message translates to:
  /// **'Edit exercise'**
  String get routeTitleEditExercise;

  /// No description provided for @routeTitleNewClass.
  ///
  /// In en, this message translates to:
  /// **'New class'**
  String get routeTitleNewClass;

  /// No description provided for @routeTitleEditClass.
  ///
  /// In en, this message translates to:
  /// **'Edit class'**
  String get routeTitleEditClass;

  /// No description provided for @routeTitleClassDetails.
  ///
  /// In en, this message translates to:
  /// **'Class details'**
  String get routeTitleClassDetails;

  /// No description provided for @routeTitleQuestionBank.
  ///
  /// In en, this message translates to:
  /// **'Question bank'**
  String get routeTitleQuestionBank;

  /// No description provided for @routeTitleLevels.
  ///
  /// In en, this message translates to:
  /// **'Levels'**
  String get routeTitleLevels;

  /// No description provided for @routeTitleNewLevel.
  ///
  /// In en, this message translates to:
  /// **'New level'**
  String get routeTitleNewLevel;

  /// No description provided for @routeTitleEditLevel.
  ///
  /// In en, this message translates to:
  /// **'Edit level'**
  String get routeTitleEditLevel;

  /// No description provided for @routeTitleQuizzes.
  ///
  /// In en, this message translates to:
  /// **'Quizzes'**
  String get routeTitleQuizzes;

  /// No description provided for @routeTitleSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get routeTitleSettings;

  /// No description provided for @routeTitlePriceList.
  ///
  /// In en, this message translates to:
  /// **'Price list'**
  String get routeTitlePriceList;

  /// No description provided for @routeTitleAuditLogs.
  ///
  /// In en, this message translates to:
  /// **'Audit logs'**
  String get routeTitleAuditLogs;

  /// No description provided for @routeTitleMaterials.
  ///
  /// In en, this message translates to:
  /// **'Materials'**
  String get routeTitleMaterials;

  /// No description provided for @routeTitleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get routeTitleAdmin;

  /// No description provided for @routeTitleStudentProfile.
  ///
  /// In en, this message translates to:
  /// **'Student profile'**
  String get routeTitleStudentProfile;

  /// No description provided for @routeTitleCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get routeTitleCalendar;

  /// No description provided for @routeTitleGrades.
  ///
  /// In en, this message translates to:
  /// **'Grades'**
  String get routeTitleGrades;

  /// No description provided for @routeTitleTeacher.
  ///
  /// In en, this message translates to:
  /// **'Guru'**
  String get routeTitleTeacher;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet.'**
  String get notificationsEmpty;

  /// No description provided for @teacherExAuthoringUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Creating and editing exercises is only available on web. Open Easy Study in a browser on desktop to manage exercises.'**
  String get teacherExAuthoringUnsupported;

  /// No description provided for @teacherExAuthoringAdminOnly.
  ///
  /// In en, this message translates to:
  /// **'Creating and editing exercises is only available to admins on web.'**
  String get teacherExAuthoringAdminOnly;

  /// No description provided for @teacherExAuthoringReadOnly.
  ///
  /// In en, this message translates to:
  /// **'View only — browse published practice and assign it to murid. Creating and editing exercises is done on web.'**
  String get teacherExAuthoringReadOnly;

  /// No description provided for @worksheetUploadUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Worksheet upload is only available to admins on web. Open Easy Study in a browser on desktop to import worksheets.'**
  String get worksheetUploadUnsupported;

  /// No description provided for @worksheetStepPrepare.
  ///
  /// In en, this message translates to:
  /// **'Prepare file'**
  String get worksheetStepPrepare;

  /// No description provided for @worksheetStepRead.
  ///
  /// In en, this message translates to:
  /// **'Read file'**
  String get worksheetStepRead;

  /// No description provided for @worksheetStepDetect.
  ///
  /// In en, this message translates to:
  /// **'Detect questions'**
  String get worksheetStepDetect;

  /// No description provided for @worksheetStagePreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing file…'**
  String get worksheetStagePreparing;

  /// No description provided for @worksheetStageReading.
  ///
  /// In en, this message translates to:
  /// **'Reading your worksheet…'**
  String get worksheetStageReading;

  /// No description provided for @worksheetStageDetecting.
  ///
  /// In en, this message translates to:
  /// **'Detecting question type…'**
  String get worksheetStageDetecting;

  /// No description provided for @worksheetStageDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get worksheetStageDone;

  /// No description provided for @cohortNoActivity.
  ///
  /// In en, this message translates to:
  /// **'No activity'**
  String get cohortNoActivity;

  /// No description provided for @cohortToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get cohortToday;

  /// No description provided for @cohortDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String cohortDaysAgo(int count);

  /// No description provided for @cohortNoHomework.
  ///
  /// In en, this message translates to:
  /// **'No homework'**
  String get cohortNoHomework;

  /// No description provided for @cohortHomeworkOverdueOf.
  ///
  /// In en, this message translates to:
  /// **'{done}/{assigned} · {overdue} overdue'**
  String cohortHomeworkOverdueOf(int done, int assigned, int overdue);

  /// No description provided for @cohortHomeworkDoneOf.
  ///
  /// In en, this message translates to:
  /// **'{done}/{assigned} done'**
  String cohortHomeworkDoneOf(int done, int assigned);

  /// No description provided for @attentionOverdue.
  ///
  /// In en, this message translates to:
  /// **'{name} has overdue practice'**
  String attentionOverdue(String name);

  /// No description provided for @attentionStale.
  ///
  /// In en, this message translates to:
  /// **'{name} has assigned practice not started ({count}d)'**
  String attentionStale(String name, int count);

  /// No description provided for @attentionInactive.
  ///
  /// In en, this message translates to:
  /// **'{name} inactive for {count}+ days'**
  String attentionInactive(String name, int count);

  /// No description provided for @attentionNoSessions.
  ///
  /// In en, this message translates to:
  /// **'{name} has no class sessions left'**
  String attentionNoSessions(String name);

  /// No description provided for @attentionSessionsLeft.
  ///
  /// In en, this message translates to:
  /// **'{name} has {count, plural, =1{1 class session} other{{count} class sessions}} left'**
  String attentionSessionsLeft(String name, int count);

  /// No description provided for @activityScored.
  ///
  /// In en, this message translates to:
  /// **'{name} scored {score}%'**
  String activityScored(String name, int score);

  /// No description provided for @activitySubmitted.
  ///
  /// In en, this message translates to:
  /// **'Practice submitted · {score}%'**
  String activitySubmitted(int score);

  /// No description provided for @activityExerciseFallback.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get activityExerciseFallback;

  /// No description provided for @activityLessonCompletedBy.
  ///
  /// In en, this message translates to:
  /// **'{name} completed a lesson'**
  String activityLessonCompletedBy(String name);

  /// No description provided for @activityLessonCompleted.
  ///
  /// In en, this message translates to:
  /// **'Lesson completed'**
  String get activityLessonCompleted;

  /// No description provided for @activityLessonFallback.
  ///
  /// In en, this message translates to:
  /// **'Lesson {id}'**
  String activityLessonFallback(String id);

  /// No description provided for @activityAssignedTo.
  ///
  /// In en, this message translates to:
  /// **'Assigned practice to {name}'**
  String activityAssignedTo(String name);

  /// No description provided for @activityAssigned.
  ///
  /// In en, this message translates to:
  /// **'Practice assigned'**
  String get activityAssigned;

  /// No description provided for @activityStudentFallback.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get activityStudentFallback;

  /// No description provided for @activityJoined.
  ///
  /// In en, this message translates to:
  /// **'{name} joined a class'**
  String activityJoined(String name);

  /// No description provided for @activityAdded.
  ///
  /// In en, this message translates to:
  /// **'You added {name} to a class'**
  String activityAdded(String name);

  /// No description provided for @activityClassConcluded.
  ///
  /// In en, this message translates to:
  /// **'Class concluded'**
  String get activityClassConcluded;

  /// No description provided for @activityTermAddedFor.
  ///
  /// In en, this message translates to:
  /// **'Term package added for {name}'**
  String activityTermAddedFor(String name);

  /// No description provided for @activityTermAdded.
  ///
  /// In en, this message translates to:
  /// **'Term package added'**
  String get activityTermAdded;

  /// No description provided for @activityTermSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} sessions · {start} → {end}'**
  String activityTermSubtitle(int count, String start, String end);

  /// No description provided for @commonNoHskLevel.
  ///
  /// In en, this message translates to:
  /// **'No HSK level'**
  String get commonNoHskLevel;

  /// No description provided for @exercisePlayExamIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Before you start'**
  String get exercisePlayExamIntroTitle;

  /// No description provided for @exercisePlayOneAttempt.
  ///
  /// In en, this message translates to:
  /// **'You get one attempt. Once you submit, you cannot take it again.'**
  String get exercisePlayOneAttempt;

  /// No description provided for @exercisePlayTimeLimit.
  ///
  /// In en, this message translates to:
  /// **'Time limit: {minutes} minutes. The clock keeps running if you close the page.'**
  String exercisePlayTimeLimit(int minutes);

  /// No description provided for @exercisePlayQuestionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 question} other{{count} questions}}'**
  String exercisePlayQuestionCount(int count);

  /// No description provided for @exercisePlayStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get exercisePlayStart;

  /// No description provided for @exercisePlayAttemptUsedTitle.
  ///
  /// In en, this message translates to:
  /// **'Already submitted'**
  String get exercisePlayAttemptUsedTitle;

  /// No description provided for @exercisePlayAttemptUsedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This exam allows one attempt. Your score is under Progress.'**
  String get exercisePlayAttemptUsedSubtitle;

  /// No description provided for @exercisePlayLateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Submitted after the time limit, so it was not scored.'**
  String get exercisePlayLateSubtitle;

  /// No description provided for @resultLate.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get resultLate;

  /// No description provided for @bankAiScanWorksheet.
  ///
  /// In en, this message translates to:
  /// **'Scan paper with AI'**
  String get bankAiScanWorksheet;

  /// No description provided for @bankScanWithoutAi.
  ///
  /// In en, this message translates to:
  /// **'Scan without AI (on this device)'**
  String get bankScanWithoutAi;

  /// No description provided for @aiImportSending.
  ///
  /// In en, this message translates to:
  /// **'Sending the file to the AI reader…'**
  String get aiImportSending;

  /// No description provided for @aiImportReading.
  ///
  /// In en, this message translates to:
  /// **'The AI is reading the paper (about a minute)…'**
  String get aiImportReading;

  /// No description provided for @aiImportCropping.
  ///
  /// In en, this message translates to:
  /// **'Cutting out picture {n} of {total}…'**
  String aiImportCropping(int n, int total);

  /// No description provided for @aiImportSummary.
  ///
  /// In en, this message translates to:
  /// **'AI reading · {level} · {questions} questions in {sections} parts · {pictures} pictures · {missing} without an answer key (listening: add it later with Answer key on the worksheet)'**
  String aiImportSummary(
      String level, int questions, int sections, int pictures, int missing);

  /// No description provided for @aiImportFailed.
  ///
  /// In en, this message translates to:
  /// **'AI reading failed: {error}'**
  String aiImportFailed(String error);

  /// No description provided for @aiImportNothingFound.
  ///
  /// In en, this message translates to:
  /// **'The AI reader found no questions in this file.'**
  String get aiImportNothingFound;

  /// No description provided for @bankSheetListeningAudio.
  ///
  /// In en, this message translates to:
  /// **'Listening recording'**
  String get bankSheetListeningAudio;

  /// No description provided for @bankSheetListeningAudioHelp.
  ///
  /// In en, this message translates to:
  /// **'One recording for the whole listening part. Students hear it while they answer those questions.'**
  String get bankSheetListeningAudioHelp;

  /// No description provided for @bankSheetUploadAudio.
  ///
  /// In en, this message translates to:
  /// **'Upload recording'**
  String get bankSheetUploadAudio;

  /// No description provided for @bankSheetReplaceAudio.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get bankSheetReplaceAudio;

  /// No description provided for @bankSheetRemoveAudio.
  ///
  /// In en, this message translates to:
  /// **'Remove recording'**
  String get bankSheetRemoveAudio;

  /// No description provided for @bankSheetAudioAttached.
  ///
  /// In en, this message translates to:
  /// **'Recording attached. Students get one player for the listening questions.'**
  String get bankSheetAudioAttached;

  /// No description provided for @bankSheetAnswerKey.
  ///
  /// In en, this message translates to:
  /// **'Answer key'**
  String get bankSheetAnswerKey;

  /// No description provided for @bankSheetAnswerKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Type the key as printed: 1 D 2 A 3 C · 11 √ 12 × · 41-45 ECBAD. Numbers follow the order on this worksheet.'**
  String get bankSheetAnswerKeyHint;

  /// No description provided for @bankSheetAnswerKeyApply.
  ///
  /// In en, this message translates to:
  /// **'Apply key'**
  String get bankSheetAnswerKeyApply;

  /// No description provided for @bankSheetAnswerKeyApplied.
  ///
  /// In en, this message translates to:
  /// **'Answer key applied to {n} questions.'**
  String bankSheetAnswerKeyApplied(int n);

  /// No description provided for @bankSheetAnswerKeyNone.
  ///
  /// In en, this message translates to:
  /// **'No answers found in the text.'**
  String get bankSheetAnswerKeyNone;

  /// No description provided for @bankSheetParts.
  ///
  /// In en, this message translates to:
  /// **'{n} parts'**
  String bankSheetParts(int n);

  /// No description provided for @bankEditorChoicePicture.
  ///
  /// In en, this message translates to:
  /// **'Picture for this choice'**
  String get bankEditorChoicePicture;

  /// No description provided for @exercisePlayListeningRecording.
  ///
  /// In en, this message translates to:
  /// **'Listening recording'**
  String get exercisePlayListeningRecording;

  /// No description provided for @exercisePlayQuestionAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio for this question'**
  String get exercisePlayQuestionAudio;

  /// No description provided for @exercisePlayPickPicture.
  ///
  /// In en, this message translates to:
  /// **'Choose the picture'**
  String get exercisePlayPickPicture;

  /// No description provided for @exercisePlayHskMarks.
  ///
  /// In en, this message translates to:
  /// **'HSK marks'**
  String get exercisePlayHskMarks;

  /// No description provided for @exercisePlayHskListening.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get exercisePlayHskListening;

  /// No description provided for @exercisePlayHskReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get exercisePlayHskReading;

  /// No description provided for @exercisePlayHskWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing'**
  String get exercisePlayHskWriting;

  /// No description provided for @exercisePlayHskTotal.
  ///
  /// In en, this message translates to:
  /// **'Total {total} of {max} · pass mark {pass}'**
  String exercisePlayHskTotal(int total, int max, int pass);

  /// No description provided for @exercisePlayHskPassed.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get exercisePlayHskPassed;

  /// No description provided for @exercisePlayHskNotPassed.
  ///
  /// In en, this message translates to:
  /// **'Not passed yet'**
  String get exercisePlayHskNotPassed;

  /// No description provided for @testsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tests'**
  String get testsTitle;

  /// No description provided for @testsSkillListening.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get testsSkillListening;

  /// No description provided for @testsSkillReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get testsSkillReading;

  /// No description provided for @testsSkillWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing'**
  String get testsSkillWriting;

  /// No description provided for @testsSkillSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Speaking'**
  String get testsSkillSpeaking;

  /// No description provided for @testsErrorBadToken.
  ///
  /// In en, this message translates to:
  /// **'This token is not valid. Check it with your teacher.'**
  String get testsErrorBadToken;

  /// No description provided for @testsErrorTokenBlocked.
  ///
  /// In en, this message translates to:
  /// **'Too many wrong tokens. Wait a few minutes and try again.'**
  String get testsErrorTokenBlocked;

  /// No description provided for @testsErrorJoinClosed.
  ///
  /// In en, this message translates to:
  /// **'The time to join has ended. Ask your teacher for a new token.'**
  String get testsErrorJoinClosed;

  /// No description provided for @testsErrorAlreadyAttempted.
  ///
  /// In en, this message translates to:
  /// **'You have already sat this test. Each code can be taken once.'**
  String get testsErrorAlreadyAttempted;

  /// No description provided for @testsErrorPartClosed.
  ///
  /// In en, this message translates to:
  /// **'This part is already closed.'**
  String get testsErrorPartClosed;

  /// No description provided for @testsErrorReviewSessionOpen.
  ///
  /// In en, this message translates to:
  /// **'The review opens when your teacher ends the session.'**
  String get testsErrorReviewSessionOpen;

  /// No description provided for @testsErrorReviewNotFinished.
  ///
  /// In en, this message translates to:
  /// **'Finish the test first.'**
  String get testsErrorReviewNotFinished;

  /// No description provided for @testsErrorReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Write a reason.'**
  String get testsErrorReasonRequired;

  /// No description provided for @testsErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get testsErrorGeneric;

  /// No description provided for @testsHskSimulationInTests.
  ///
  /// In en, this message translates to:
  /// **'HSK simulations are taken in Tests: ask your teacher for a token.'**
  String get testsHskSimulationInTests;

  /// No description provided for @testsAddPart.
  ///
  /// In en, this message translates to:
  /// **'Add part'**
  String get testsAddPart;

  /// No description provided for @testsRemovePart.
  ///
  /// In en, this message translates to:
  /// **'Remove part'**
  String get testsRemovePart;

  /// No description provided for @testsPassMark.
  ///
  /// In en, this message translates to:
  /// **'Pass mark'**
  String get testsPassMark;

  /// No description provided for @testsTotalsLine.
  ///
  /// In en, this message translates to:
  /// **'Max {max} · {minutes} minutes'**
  String testsTotalsLine(int max, int minutes);

  /// No description provided for @testsPartNumber.
  ///
  /// In en, this message translates to:
  /// **'Part {n}'**
  String testsPartNumber(int n);

  /// No description provided for @testsQuestions.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get testsQuestions;

  /// No description provided for @testsMinutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get testsMinutes;

  /// No description provided for @testsMaxMark.
  ///
  /// In en, this message translates to:
  /// **'Marks'**
  String get testsMaxMark;

  /// No description provided for @testsFoundMatch.
  ///
  /// In en, this message translates to:
  /// **'The worksheet has {found} questions for this part.'**
  String testsFoundMatch(int found);

  /// No description provided for @testsFoundMismatch.
  ///
  /// In en, this message translates to:
  /// **'Expected {expected}, the worksheet has {found}.'**
  String testsFoundMismatch(int expected, int found);

  /// No description provided for @testsFormatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Test formats'**
  String get testsFormatsTitle;

  /// No description provided for @testsLoadStandardFormats.
  ///
  /// In en, this message translates to:
  /// **'Load standard formats'**
  String get testsLoadStandardFormats;

  /// No description provided for @testsFormatsAdded.
  ///
  /// In en, this message translates to:
  /// **'{count} formats added.'**
  String testsFormatsAdded(int count);

  /// No description provided for @testsFormatsNothingAdded.
  ///
  /// In en, this message translates to:
  /// **'Every standard format is already there. Nothing changed.'**
  String get testsFormatsNothingAdded;

  /// No description provided for @testsFormatsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No formats yet'**
  String get testsFormatsEmptyTitle;

  /// No description provided for @testsFormatsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Load the standard formats, then edit them against your papers.'**
  String get testsFormatsEmptySubtitle;

  /// No description provided for @testsDraft.
  ///
  /// In en, this message translates to:
  /// **'draft'**
  String get testsDraft;

  /// No description provided for @testsMaxPassLine.
  ///
  /// In en, this message translates to:
  /// **'Max {max} · pass {pass}'**
  String testsMaxPassLine(int max, int pass);

  /// No description provided for @testsDraftSwitch.
  ///
  /// In en, this message translates to:
  /// **'Draft (not confirmed from a paper)'**
  String get testsDraftSwitch;

  /// No description provided for @testsDraftSwitchHint.
  ///
  /// In en, this message translates to:
  /// **'Switch off once the timing matches a real paper.'**
  String get testsDraftSwitchHint;

  /// No description provided for @testsSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get testsSave;

  /// No description provided for @testsCodesTitle.
  ///
  /// In en, this message translates to:
  /// **'Test codes'**
  String get testsCodesTitle;

  /// No description provided for @testsNewCode.
  ///
  /// In en, this message translates to:
  /// **'New test code'**
  String get testsNewCode;

  /// No description provided for @testsEditCode.
  ///
  /// In en, this message translates to:
  /// **'Edit test code'**
  String get testsEditCode;

  /// No description provided for @testsCreateCode.
  ///
  /// In en, this message translates to:
  /// **'Create test code'**
  String get testsCreateCode;

  /// No description provided for @testsCodesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No test codes yet'**
  String get testsCodesEmptyTitle;

  /// No description provided for @testsCodesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan a paper into the question bank, then make a code from the worksheet.'**
  String get testsCodesEmptySubtitle;

  /// No description provided for @testsMinutesTotal.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String testsMinutesTotal(int minutes);

  /// No description provided for @testsInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get testsInactive;

  /// No description provided for @testsCodeSaved.
  ///
  /// In en, this message translates to:
  /// **'Test code saved.'**
  String get testsCodeSaved;

  /// No description provided for @testsCodeDuplicate.
  ///
  /// In en, this message translates to:
  /// **'The code {code} already exists.'**
  String testsCodeDuplicate(String code);

  /// No description provided for @testsWorksheet.
  ///
  /// In en, this message translates to:
  /// **'Worksheet (question bank)'**
  String get testsWorksheet;

  /// No description provided for @testsCode.
  ///
  /// In en, this message translates to:
  /// **'Test code'**
  String get testsCode;

  /// No description provided for @testsCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Letters and digits as printed on the paper, e.g. H31005'**
  String get testsCodeHint;

  /// No description provided for @testsFormat.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get testsFormat;

  /// No description provided for @testsReleaseYear.
  ///
  /// In en, this message translates to:
  /// **'Release year'**
  String get testsReleaseYear;

  /// No description provided for @testsNoFormatsYet.
  ///
  /// In en, this message translates to:
  /// **'No formats yet: load the standard formats first (Tests → Test formats).'**
  String get testsNoFormatsYet;

  /// No description provided for @testsTimingTitle.
  ///
  /// In en, this message translates to:
  /// **'Timing and marks of this code'**
  String get testsTimingTitle;

  /// No description provided for @testsTimingHint.
  ///
  /// In en, this message translates to:
  /// **'Copied from the format. Correct it against the paper\'s cover page.'**
  String get testsTimingHint;

  /// No description provided for @testsCountWarning.
  ///
  /// In en, this message translates to:
  /// **'The worksheet and the format do not have the same number of questions in every part. You can still save.'**
  String get testsCountWarning;

  /// No description provided for @testsActive.
  ///
  /// In en, this message translates to:
  /// **'Active (can be opened in a session)'**
  String get testsActive;

  /// No description provided for @testsCountsForPromotion.
  ///
  /// In en, this message translates to:
  /// **'Counts for promotion'**
  String get testsCountsForPromotion;

  /// No description provided for @testsOpenSession.
  ///
  /// In en, this message translates to:
  /// **'Open session'**
  String get testsOpenSession;

  /// No description provided for @testsResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Test results'**
  String get testsResultsTitle;

  /// No description provided for @testsSessionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get testsSessionsTitle;

  /// No description provided for @testsSessionsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No sessions yet'**
  String get testsSessionsEmptyTitle;

  /// No description provided for @testsSessionsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open a session to give your students a token.'**
  String get testsSessionsEmptySubtitle;

  /// No description provided for @testsSessionOpen.
  ///
  /// In en, this message translates to:
  /// **'open'**
  String get testsSessionOpen;

  /// No description provided for @testsSessionClosed.
  ///
  /// In en, this message translates to:
  /// **'Session closed'**
  String get testsSessionClosed;

  /// No description provided for @testsNoActiveCodes.
  ///
  /// In en, this message translates to:
  /// **'There is no active test code yet. An admin creates codes in Tests → Test codes.'**
  String get testsNoActiveCodes;

  /// No description provided for @testsPartClocks.
  ///
  /// In en, this message translates to:
  /// **'A clock per part'**
  String get testsPartClocks;

  /// No description provided for @testsPartClocksOn.
  ///
  /// In en, this message translates to:
  /// **'Each part has its own clock; the recording plays once; no way back to a closed part.'**
  String get testsPartClocksOn;

  /// No description provided for @testsPartClocksOff.
  ///
  /// In en, this message translates to:
  /// **'One clock for the whole paper; students move freely between parts and may replay the recording; one submit at the end.'**
  String get testsPartClocksOff;

  /// No description provided for @testsOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get testsOpen;

  /// No description provided for @testsSupervisionTitle.
  ///
  /// In en, this message translates to:
  /// **'Supervision'**
  String get testsSupervisionTitle;

  /// No description provided for @testsEndForEveryone.
  ///
  /// In en, this message translates to:
  /// **'End test for everyone'**
  String get testsEndForEveryone;

  /// No description provided for @testsEndForEveryoneConfirm.
  ///
  /// In en, this message translates to:
  /// **'Every student still sitting is finished now. Their app first sends what they have typed (about 15 seconds); anything not sent counts as empty. This cannot be undone.'**
  String get testsEndForEveryoneConfirm;

  /// No description provided for @testsEnded.
  ///
  /// In en, this message translates to:
  /// **'Session closed · {count} tests finished.'**
  String testsEnded(int count);

  /// No description provided for @testsJoinCountdown.
  ///
  /// In en, this message translates to:
  /// **'Students can join for {time}'**
  String testsJoinCountdown(String time);

  /// No description provided for @testsJoinClosed.
  ///
  /// In en, this message translates to:
  /// **'Joining is closed. Give a new token to let someone in.'**
  String get testsJoinClosed;

  /// No description provided for @testsNewToken.
  ///
  /// In en, this message translates to:
  /// **'New token'**
  String get testsNewToken;

  /// No description provided for @testsStudentsCount.
  ///
  /// In en, this message translates to:
  /// **'Students ({count})'**
  String testsStudentsCount(int count);

  /// No description provided for @testsNoStudentsYetTitle.
  ///
  /// In en, this message translates to:
  /// **'Nobody has joined yet'**
  String get testsNoStudentsYetTitle;

  /// No description provided for @testsNoStudentsYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Students type the token in their Tests page.'**
  String get testsNoStudentsYetSubtitle;

  /// No description provided for @testsStatusFinished.
  ///
  /// In en, this message translates to:
  /// **'finished'**
  String get testsStatusFinished;

  /// No description provided for @testsStatusSitting.
  ///
  /// In en, this message translates to:
  /// **'sitting'**
  String get testsStatusSitting;

  /// No description provided for @testsPartOf.
  ///
  /// In en, this message translates to:
  /// **'Part {n} of {total}'**
  String testsPartOf(int n, int total);

  /// No description provided for @testsWholePaper.
  ///
  /// In en, this message translates to:
  /// **'Whole paper'**
  String get testsWholePaper;

  /// No description provided for @testsLeftPageCount.
  ///
  /// In en, this message translates to:
  /// **'Left the page: {count}'**
  String testsLeftPageCount(int count);

  /// No description provided for @testsCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Result card'**
  String get testsCardTitle;

  /// No description provided for @testsCardName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get testsCardName;

  /// No description provided for @testsCardChineseName.
  ///
  /// In en, this message translates to:
  /// **'Chinese name'**
  String get testsCardChineseName;

  /// No description provided for @testsCardExamType.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get testsCardExamType;

  /// No description provided for @testsCardTestCode.
  ///
  /// In en, this message translates to:
  /// **'Test code'**
  String get testsCardTestCode;

  /// No description provided for @testsCardResultNumber.
  ///
  /// In en, this message translates to:
  /// **'Result number'**
  String get testsCardResultNumber;

  /// No description provided for @testsCardDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get testsCardDate;

  /// No description provided for @testsCardSupervisor.
  ///
  /// In en, this message translates to:
  /// **'Supervising teacher'**
  String get testsCardSupervisor;

  /// No description provided for @testsCardTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get testsCardTotal;

  /// No description provided for @testsCardOutcome.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get testsCardOutcome;

  /// No description provided for @testsCardPassMark.
  ///
  /// In en, this message translates to:
  /// **'Pass mark {pass}'**
  String testsCardPassMark(int pass);

  /// No description provided for @testsPassed.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get testsPassed;

  /// No description provided for @testsNotPassed.
  ///
  /// In en, this message translates to:
  /// **'Not passed'**
  String get testsNotPassed;

  /// No description provided for @testsInvalid.
  ///
  /// In en, this message translates to:
  /// **'Not valid'**
  String get testsInvalid;

  /// No description provided for @testsAllCodes.
  ///
  /// In en, this message translates to:
  /// **'All codes'**
  String get testsAllCodes;

  /// No description provided for @testsResultsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No results yet'**
  String get testsResultsEmptyTitle;

  /// No description provided for @testsResultsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Results appear when students finish a supervised test.'**
  String get testsResultsEmptySubtitle;

  /// No description provided for @testsMarkInvalid.
  ///
  /// In en, this message translates to:
  /// **'Mark invalid'**
  String get testsMarkInvalid;

  /// No description provided for @testsMarkValid.
  ///
  /// In en, this message translates to:
  /// **'Mark valid'**
  String get testsMarkValid;

  /// No description provided for @testsInvalidReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get testsInvalidReason;

  /// No description provided for @testsPrintPdf.
  ///
  /// In en, this message translates to:
  /// **'Print / PDF'**
  String get testsPrintPdf;

  /// No description provided for @testsResultNotFound.
  ///
  /// In en, this message translates to:
  /// **'Result not found.'**
  String get testsResultNotFound;

  /// No description provided for @testsOpenReview.
  ///
  /// In en, this message translates to:
  /// **'Review answers'**
  String get testsOpenReview;

  /// No description provided for @testsCouldNotOpen.
  ///
  /// In en, this message translates to:
  /// **'The test could not be opened'**
  String get testsCouldNotOpen;

  /// No description provided for @testsFinishTitle.
  ///
  /// In en, this message translates to:
  /// **'Finish the test?'**
  String get testsFinishTitle;

  /// No description provided for @testsFinishBody.
  ///
  /// In en, this message translates to:
  /// **'Your answers are sent and the test is closed. You cannot change them afterwards.'**
  String get testsFinishBody;

  /// No description provided for @testsNextPartTitle.
  ///
  /// In en, this message translates to:
  /// **'Go to the next part?'**
  String get testsNextPartTitle;

  /// No description provided for @testsNextPartBody.
  ///
  /// In en, this message translates to:
  /// **'This part is closed and sent. There is no way back to it.'**
  String get testsNextPartBody;

  /// No description provided for @testsFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish test'**
  String get testsFinish;

  /// No description provided for @testsNextPart.
  ///
  /// In en, this message translates to:
  /// **'Next part'**
  String get testsNextPart;

  /// No description provided for @testsQuestionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 question} other{{count} questions}}'**
  String testsQuestionsCount(int count);

  /// No description provided for @testsRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get testsRulesTitle;

  /// No description provided for @testsRulePartClocks.
  ///
  /// In en, this message translates to:
  /// **'Each part has its own clock. When it reaches zero, the part is sent by itself.'**
  String get testsRulePartClocks;

  /// No description provided for @testsRuleOneClock.
  ///
  /// In en, this message translates to:
  /// **'One clock for the whole paper. When it reaches zero, your answers are sent.'**
  String get testsRuleOneClock;

  /// No description provided for @testsRuleRecording.
  ///
  /// In en, this message translates to:
  /// **'The listening recording starts with the part and plays once. It cannot be paused or replayed.'**
  String get testsRuleRecording;

  /// No description provided for @testsRuleNoBack.
  ///
  /// In en, this message translates to:
  /// **'A part you have sent cannot be opened again.'**
  String get testsRuleNoBack;

  /// No description provided for @testsRuleLeaving.
  ///
  /// In en, this message translates to:
  /// **'Leaving this page or window is recorded and shown to your teacher.'**
  String get testsRuleLeaving;

  /// No description provided for @testsRuleOnce.
  ///
  /// In en, this message translates to:
  /// **'Each test code can be taken once.'**
  String get testsRuleOnce;

  /// No description provided for @testsStart.
  ///
  /// In en, this message translates to:
  /// **'Start the test'**
  String get testsStart;

  /// No description provided for @testsLeftNotice.
  ///
  /// In en, this message translates to:
  /// **'You left the test page. This was recorded and your teacher can see it.'**
  String get testsLeftNotice;

  /// No description provided for @testsPartEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No questions in this part'**
  String get testsPartEmptyTitle;

  /// No description provided for @testsPartEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Go on to the next part.'**
  String get testsPartEmptySubtitle;

  /// No description provided for @testsWaitForRecording.
  ///
  /// In en, this message translates to:
  /// **'Wait until the recording has finished.'**
  String get testsWaitForRecording;

  /// No description provided for @testsRecordingDone.
  ///
  /// In en, this message translates to:
  /// **'Recording finished'**
  String get testsRecordingDone;

  /// No description provided for @testsContinueRecording.
  ///
  /// In en, this message translates to:
  /// **'Continue recording'**
  String get testsContinueRecording;

  /// No description provided for @testsClipPlaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No plays left} =1{1 play left} other{{count} plays left}}'**
  String testsClipPlaysLeft(int count);

  /// No description provided for @testsEnterToken.
  ///
  /// In en, this message translates to:
  /// **'Enter token'**
  String get testsEnterToken;

  /// No description provided for @testsEnterTokenHint.
  ///
  /// In en, this message translates to:
  /// **'Type the 6-character token your teacher shows.'**
  String get testsEnterTokenHint;

  /// No description provided for @testsGo.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get testsGo;

  /// No description provided for @testsContinueTest.
  ///
  /// In en, this message translates to:
  /// **'Continue test {code}'**
  String testsContinueTest(String code);

  /// No description provided for @testsMyResults.
  ///
  /// In en, this message translates to:
  /// **'My results'**
  String get testsMyResults;

  /// No description provided for @testsMyResultsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No results yet'**
  String get testsMyResultsEmptyTitle;

  /// No description provided for @testsMyResultsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your supervised tests appear here.'**
  String get testsMyResultsEmptySubtitle;

  /// No description provided for @testsReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get testsReviewTitle;

  /// No description provided for @testsReviewNotYet.
  ///
  /// In en, this message translates to:
  /// **'Review not open yet'**
  String get testsReviewNotYet;

  /// No description provided for @testsYourAnswer.
  ///
  /// In en, this message translates to:
  /// **'Your answer'**
  String get testsYourAnswer;

  /// No description provided for @testsKey.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get testsKey;

  /// No description provided for @paperScan.
  ///
  /// In en, this message translates to:
  /// **'Scan paper'**
  String get paperScan;

  /// No description provided for @paperOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening the paper…'**
  String get paperOpening;

  /// No description provided for @paperReadingPage.
  ///
  /// In en, this message translates to:
  /// **'Reading page {page} of {count}'**
  String paperReadingPage(int page, int count);

  /// No description provided for @paperReadFailed.
  ///
  /// In en, this message translates to:
  /// **'The paper could not be read: {error}'**
  String paperReadFailed(String error);

  /// No description provided for @paperNothingFound.
  ///
  /// In en, this message translates to:
  /// **'No questions were found in this file.'**
  String get paperNothingFound;

  /// No description provided for @paperReadAsWorksheet.
  ///
  /// In en, this message translates to:
  /// **'This is not an HSK paper: reading it as a worksheet.'**
  String get paperReadAsWorksheet;

  /// No description provided for @paperFormOpen.
  ///
  /// In en, this message translates to:
  /// **'Open answer (a teacher marks it)'**
  String get paperFormOpen;

  /// No description provided for @paperFormFillBlanks.
  ///
  /// In en, this message translates to:
  /// **'Fill in the blanks'**
  String get paperFormFillBlanks;

  /// No description provided for @paperBlankAnswers.
  ///
  /// In en, this message translates to:
  /// **'Answers, one line per blank ({count} blanks)'**
  String paperBlankAnswers(int count);

  /// No description provided for @paperBlankAnswersHint.
  ///
  /// In en, this message translates to:
  /// **'In the order of the blanks. Two right answers for one blank: write them on one line as a/b.'**
  String get paperBlankAnswersHint;

  /// No description provided for @exerciseTypeFillBlanks.
  ///
  /// In en, this message translates to:
  /// **'Fill in the blanks (填空)'**
  String get exerciseTypeFillBlanks;

  /// No description provided for @playBlankHint.
  ///
  /// In en, this message translates to:
  /// **'Blank {n}'**
  String playBlankHint(int n);

  /// No description provided for @bankEditorBlankAnswers.
  ///
  /// In en, this message translates to:
  /// **'Answers, one line per blank'**
  String get bankEditorBlankAnswers;

  /// No description provided for @bankEditorBlankAnswersHelper.
  ///
  /// In en, this message translates to:
  /// **'Write ____ in the sentence for each blank; here the answers in the same order (a/b = either is right).'**
  String get bankEditorBlankAnswersHelper;

  /// No description provided for @bankEditorNeedBlanks.
  ///
  /// In en, this message translates to:
  /// **'Write ____ in the sentence for each blank.'**
  String get bankEditorNeedBlanks;

  /// No description provided for @bankEditorBlankCountMismatch.
  ///
  /// In en, this message translates to:
  /// **'The sentence has {count} blanks: give one answer per blank.'**
  String bankEditorBlankCountMismatch(int count);

  /// No description provided for @paperContextTitle.
  ///
  /// In en, this message translates to:
  /// **'Lesson text for the students'**
  String get paperContextTitle;

  /// No description provided for @paperContextEmpty.
  ///
  /// In en, this message translates to:
  /// **'No textbook text was found. Type or paste it here, or leave it empty.'**
  String get paperContextEmpty;

  /// No description provided for @paperContextLines.
  ///
  /// In en, this message translates to:
  /// **'{count} lines · open to correct'**
  String paperContextLines(int count);

  /// No description provided for @paperContextHint.
  ///
  /// In en, this message translates to:
  /// **'The textbook dialogues and new words. Students can open this text while they answer. Correct what the reader got wrong before saving.'**
  String get paperContextHint;

  /// No description provided for @exercisePlayLessonText.
  ///
  /// In en, this message translates to:
  /// **'Lesson text'**
  String get exercisePlayLessonText;

  /// No description provided for @bankContextTitle.
  ///
  /// In en, this message translates to:
  /// **'Lesson text'**
  String get bankContextTitle;

  /// No description provided for @bankContextNone.
  ///
  /// In en, this message translates to:
  /// **'No lesson text. Students only see the questions.'**
  String get bankContextNone;

  /// No description provided for @bankContextEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit lesson text'**
  String get bankContextEdit;

  /// No description provided for @bankContextSaved.
  ///
  /// In en, this message translates to:
  /// **'Lesson text saved.'**
  String get bankContextSaved;

  /// No description provided for @paperProofreadTitle.
  ///
  /// In en, this message translates to:
  /// **'Check the reading · {code}'**
  String paperProofreadTitle(String code);

  /// No description provided for @paperSaveWorksheet.
  ///
  /// In en, this message translates to:
  /// **'Save worksheet'**
  String get paperSaveWorksheet;

  /// No description provided for @paperUnsavableTitle.
  ///
  /// In en, this message translates to:
  /// **'Some questions cannot be saved yet'**
  String get paperUnsavableTitle;

  /// No description provided for @paperUnsavableBody.
  ///
  /// In en, this message translates to:
  /// **'These numbers are not complete and would be left out: {numbers}. Check them first, or save without them.'**
  String paperUnsavableBody(String numbers);

  /// No description provided for @paperKeepChecking.
  ///
  /// In en, this message translates to:
  /// **'Keep checking'**
  String get paperKeepChecking;

  /// No description provided for @paperSaveAnyway.
  ///
  /// In en, this message translates to:
  /// **'Save anyway'**
  String get paperSaveAnyway;

  /// No description provided for @paperUploadingPicture.
  ///
  /// In en, this message translates to:
  /// **'Picture {done} of {total}'**
  String paperUploadingPicture(int done, int total);

  /// No description provided for @paperUnplaced.
  ///
  /// In en, this message translates to:
  /// **'Not found on any page: {numbers}. Use Only to check to see them.'**
  String paperUnplaced(String numbers);

  /// No description provided for @paperNothingOnPage.
  ///
  /// In en, this message translates to:
  /// **'No questions were read from this page.'**
  String get paperNothingOnPage;

  /// No description provided for @paperCountOf.
  ///
  /// In en, this message translates to:
  /// **'{skill} {count} of {expected}'**
  String paperCountOf(String skill, int count, int expected);

  /// No description provided for @paperToCheck.
  ///
  /// In en, this message translates to:
  /// **'To check: {count}'**
  String paperToCheck(int count);

  /// No description provided for @paperNotRead.
  ///
  /// In en, this message translates to:
  /// **'Not read: {numbers}'**
  String paperNotRead(String numbers);

  /// No description provided for @paperPageShort.
  ///
  /// In en, this message translates to:
  /// **'p. {page}'**
  String paperPageShort(int page);

  /// No description provided for @paperFormPicture.
  ///
  /// In en, this message translates to:
  /// **'Picture choice'**
  String get paperFormPicture;

  /// No description provided for @paperFormTrueFalse.
  ///
  /// In en, this message translates to:
  /// **'★ true / false'**
  String get paperFormTrueFalse;

  /// No description provided for @paperFormChoice.
  ///
  /// In en, this message translates to:
  /// **'Choices'**
  String get paperFormChoice;

  /// No description provided for @paperFormMatching.
  ///
  /// In en, this message translates to:
  /// **'Match a sentence'**
  String get paperFormMatching;

  /// No description provided for @paperFormWordBank.
  ///
  /// In en, this message translates to:
  /// **'Word bank'**
  String get paperFormWordBank;

  /// No description provided for @paperFormReorder.
  ///
  /// In en, this message translates to:
  /// **'Word order'**
  String get paperFormReorder;

  /// No description provided for @paperFormPinyinChar.
  ///
  /// In en, this message translates to:
  /// **'Character for pinyin'**
  String get paperFormPinyinChar;

  /// No description provided for @paperFormSentenceWithWord.
  ///
  /// In en, this message translates to:
  /// **'Sentence with a word'**
  String get paperFormSentenceWithWord;

  /// No description provided for @paperFlagMissing.
  ///
  /// In en, this message translates to:
  /// **'not read: type it'**
  String get paperFlagMissing;

  /// No description provided for @paperFlagUnsure.
  ///
  /// In en, this message translates to:
  /// **'number misread'**
  String get paperFlagUnsure;

  /// No description provided for @paperFlagOptions.
  ///
  /// In en, this message translates to:
  /// **'a choice is missing'**
  String get paperFlagOptions;

  /// No description provided for @paperFlagIncomplete.
  ///
  /// In en, this message translates to:
  /// **'incomplete'**
  String get paperFlagIncomplete;

  /// No description provided for @paperLooksRight.
  ///
  /// In en, this message translates to:
  /// **'Looks right'**
  String get paperLooksRight;

  /// No description provided for @paperPictures.
  ///
  /// In en, this message translates to:
  /// **'{count} pictures (page {page})'**
  String paperPictures(int count, int page);

  /// No description provided for @paperEditBoxes.
  ///
  /// In en, this message translates to:
  /// **'Picture boxes'**
  String get paperEditBoxes;

  /// No description provided for @paperEditBoxesTitle.
  ///
  /// In en, this message translates to:
  /// **'Picture boxes · page {page}'**
  String paperEditBoxesTitle(int page);

  /// No description provided for @paperEditBoxesHint.
  ///
  /// In en, this message translates to:
  /// **'Drag on the page to draw a box. Tap a box to select it; drawing then replaces it. Letters follow the reading order.'**
  String get paperEditBoxesHint;

  /// No description provided for @paperDeleteBox.
  ///
  /// In en, this message translates to:
  /// **'Delete box'**
  String get paperDeleteBox;

  /// No description provided for @paperUseBoxes.
  ///
  /// In en, this message translates to:
  /// **'Use {count} boxes'**
  String paperUseBoxes(int count);

  /// No description provided for @paperPrompt.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get paperPrompt;

  /// No description provided for @paperOptions.
  ///
  /// In en, this message translates to:
  /// **'Choices'**
  String get paperOptions;

  /// No description provided for @paperOptionsHint.
  ///
  /// In en, this message translates to:
  /// **'One per line, in letter order (A, B, C…).'**
  String get paperOptionsHint;

  /// No description provided for @paperSegments.
  ///
  /// In en, this message translates to:
  /// **'Words to order'**
  String get paperSegments;

  /// No description provided for @paperSegmentsHint.
  ///
  /// In en, this message translates to:
  /// **'Separate the words with /'**
  String get paperSegmentsHint;

  /// No description provided for @paperPinyin.
  ///
  /// In en, this message translates to:
  /// **'Pinyin'**
  String get paperPinyin;

  /// No description provided for @paperPinyinHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the tone of each syllable, or type the number after it (guan1 becomes guān).'**
  String get paperPinyinHint;

  /// No description provided for @paperKeyword.
  ///
  /// In en, this message translates to:
  /// **'Word to use'**
  String get paperKeyword;

  /// No description provided for @paperSaved.
  ///
  /// In en, this message translates to:
  /// **'{count} questions saved · {untouched} of {total} needed no correction · checked in {minutes} min · read in {seconds} s'**
  String paperSaved(
      int count, int untouched, int total, int minutes, int seconds);

  /// No description provided for @paperKeyNowTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the answer key now?'**
  String get paperKeyNowTitle;

  /// No description provided for @paperKeyNowBody.
  ///
  /// In en, this message translates to:
  /// **'The paper prints no key. Type it once (choices and the writing answers) and the worksheet is ready for a test code.'**
  String get paperKeyNowBody;

  /// No description provided for @paperLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get paperLater;

  /// No description provided for @paperAnswerKeyWrittenHint.
  ///
  /// In en, this message translates to:
  /// **'Writing: “71 the sentence” orders that question\'s words; “76 长” sets the character.'**
  String get paperAnswerKeyWrittenHint;

  /// No description provided for @paperAnswerKeyNotMatched.
  ///
  /// In en, this message translates to:
  /// **'These sentences do not use exactly the question\'s words: {numbers}.'**
  String paperAnswerKeyNotMatched(String numbers);

  /// No description provided for @paperUploadingRecording.
  ///
  /// In en, this message translates to:
  /// **'Uploading the recording…'**
  String get paperUploadingRecording;

  /// No description provided for @paperTranscript.
  ///
  /// In en, this message translates to:
  /// **'Transcript'**
  String get paperTranscript;

  /// No description provided for @paperTranscriptAdd.
  ///
  /// In en, this message translates to:
  /// **'Add transcript'**
  String get paperTranscriptAdd;

  /// No description provided for @paperTranscriptEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit transcript'**
  String get paperTranscriptEdit;

  /// No description provided for @paperTranscriptNone.
  ///
  /// In en, this message translates to:
  /// **'No transcript yet. Students see it in their review after the session.'**
  String get paperTranscriptNone;

  /// No description provided for @paperTranscriptHint.
  ///
  /// In en, this message translates to:
  /// **'Write it from the recording, type or paste it, or read the official listening script (PDF or picture). Students see it only in their review after the session.'**
  String get paperTranscriptHint;

  /// No description provided for @paperTranscriptReadFile.
  ///
  /// In en, this message translates to:
  /// **'Read from a file'**
  String get paperTranscriptReadFile;

  /// No description provided for @paperTranscriptSaved.
  ///
  /// In en, this message translates to:
  /// **'Transcript saved.'**
  String get paperTranscriptSaved;

  /// No description provided for @paperFlagGarbled.
  ///
  /// In en, this message translates to:
  /// **'a choice looks misread'**
  String get paperFlagGarbled;

  /// No description provided for @paperFlagGap.
  ///
  /// In en, this message translates to:
  /// **'no gap for the pinyin'**
  String get paperFlagGap;

  /// No description provided for @paperFlagForm.
  ///
  /// In en, this message translates to:
  /// **'form differs from its block'**
  String get paperFlagForm;

  /// No description provided for @paperFlagMarks.
  ///
  /// In en, this message translates to:
  /// **'stray marks'**
  String get paperFlagMarks;

  /// No description provided for @paperFlagLevel.
  ///
  /// In en, this message translates to:
  /// **'above HSK {level}: {characters}'**
  String paperFlagLevel(int level, String characters);

  /// No description provided for @paperFlagTones.
  ///
  /// In en, this message translates to:
  /// **'type the tone marks'**
  String get paperFlagTones;

  /// No description provided for @paperFlagSplit.
  ///
  /// In en, this message translates to:
  /// **'check the word split'**
  String get paperFlagSplit;

  /// No description provided for @exerciseTypeTypePinyin.
  ///
  /// In en, this message translates to:
  /// **'Type the pinyin (写拼音)'**
  String get exerciseTypeTypePinyin;

  /// No description provided for @exerciseTypeEssay.
  ///
  /// In en, this message translates to:
  /// **'Free writing (写作)'**
  String get exerciseTypeEssay;

  /// No description provided for @bankTextPinyinKeys.
  ///
  /// In en, this message translates to:
  /// **'Pinyin: {answers}'**
  String bankTextPinyinKeys(String answers);

  /// No description provided for @bankTextKeywords.
  ///
  /// In en, this message translates to:
  /// **'Words to use: {words}'**
  String bankTextKeywords(String words);

  /// No description provided for @bankEditorPinyinWord.
  ///
  /// In en, this message translates to:
  /// **'Hanzi to write in pinyin'**
  String get bankEditorPinyinWord;

  /// No description provided for @bankEditorPinyinWordHelper.
  ///
  /// In en, this message translates to:
  /// **'The student sees this and types its pinyin.'**
  String get bankEditorPinyinWordHelper;

  /// No description provided for @bankEditorAcceptedPinyin.
  ///
  /// In en, this message translates to:
  /// **'Accepted pinyin'**
  String get bankEditorAcceptedPinyin;

  /// No description provided for @bankEditorAcceptedPinyinHelper.
  ///
  /// In en, this message translates to:
  /// **'One per line, with tone marks or numbers (nǐ hǎo or ni3 hao3). Right letters with a wrong or missing tone get half and go to the teacher.'**
  String get bankEditorAcceptedPinyinHelper;

  /// No description provided for @bankEditorEssayTask.
  ///
  /// In en, this message translates to:
  /// **'Writing task'**
  String get bankEditorEssayTask;

  /// No description provided for @bankEditorEssayKeywords.
  ///
  /// In en, this message translates to:
  /// **'Words to use'**
  String get bankEditorEssayKeywords;

  /// No description provided for @bankEditorEssayKeywordsHelper.
  ///
  /// In en, this message translates to:
  /// **'Separate with commas. The teacher sees which ones the answer uses.'**
  String get bankEditorEssayKeywordsHelper;

  /// No description provided for @bankEditorEssaySource.
  ///
  /// In en, this message translates to:
  /// **'Text to read first (optional)'**
  String get bankEditorEssaySource;

  /// No description provided for @bankEditorEssaySourceHelper.
  ///
  /// In en, this message translates to:
  /// **'Shown at the start for the minutes below, then hidden (HSK 6).'**
  String get bankEditorEssaySourceHelper;

  /// No description provided for @bankEditorEssaySourceMinutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes the text is shown'**
  String get bankEditorEssaySourceMinutes;

  /// No description provided for @playEssayUseWords.
  ///
  /// In en, this message translates to:
  /// **'Use these words:'**
  String get playEssayUseWords;

  /// No description provided for @playEssaySourceShown.
  ///
  /// In en, this message translates to:
  /// **'Read this text. It hides after the set time.'**
  String get playEssaySourceShown;

  /// No description provided for @playEssaySourceHidden.
  ///
  /// In en, this message translates to:
  /// **'The text is hidden now. Write from memory.'**
  String get playEssaySourceHidden;

  /// No description provided for @playEssayHint.
  ///
  /// In en, this message translates to:
  /// **'Write here…'**
  String get playEssayHint;

  /// No description provided for @playEssayCount.
  ///
  /// In en, this message translates to:
  /// **'{count} characters'**
  String playEssayCount(int count);

  /// No description provided for @playPinyinPrompt.
  ///
  /// In en, this message translates to:
  /// **'Write the pinyin of:'**
  String get playPinyinPrompt;

  /// No description provided for @playPinyinHelper.
  ///
  /// In en, this message translates to:
  /// **'Tone marks or tone numbers both count. Without tones you get half.'**
  String get playPinyinHelper;

  /// No description provided for @playWaitingForTeacher.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your teacher\'s marking'**
  String get playWaitingForTeacher;

  /// No description provided for @playHalfWaiting.
  ///
  /// In en, this message translates to:
  /// **'Half marks for now; your teacher will check it'**
  String get playHalfWaiting;

  /// No description provided for @playPartRight.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of the blanks right'**
  String playPartRight(int percent);

  /// No description provided for @playPendingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Some answers wait for your teacher. The score can still change.'**
  String get playPendingSubtitle;

  /// No description provided for @testsPendingMarking.
  ///
  /// In en, this message translates to:
  /// **'Waiting for marking'**
  String get testsPendingMarking;

  /// No description provided for @markingTitle.
  ///
  /// In en, this message translates to:
  /// **'Marking'**
  String get markingTitle;

  /// No description provided for @markingEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to mark'**
  String get markingEmptyTitle;

  /// No description provided for @markingEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Typed answers that are nearly right and free writing appear here.'**
  String get markingEmptySubtitle;

  /// No description provided for @markingIntro.
  ///
  /// In en, this message translates to:
  /// **'Open an answer to mark it. The student\'s score is updated and they are told when nothing is left to mark.'**
  String get markingIntro;

  /// No description provided for @markingReasonOneCharacter.
  ///
  /// In en, this message translates to:
  /// **'one character off'**
  String get markingReasonOneCharacter;

  /// No description provided for @markingReasonTone.
  ///
  /// In en, this message translates to:
  /// **'tone wrong or missing'**
  String get markingReasonTone;

  /// No description provided for @markingReasonFreeWriting.
  ///
  /// In en, this message translates to:
  /// **'free writing'**
  String get markingReasonFreeWriting;

  /// No description provided for @markingQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get markingQuestion;

  /// No description provided for @markingAnswer.
  ///
  /// In en, this message translates to:
  /// **'Student\'s answer'**
  String get markingAnswer;

  /// No description provided for @markingKeys.
  ///
  /// In en, this message translates to:
  /// **'Key: {keys}'**
  String markingKeys(String keys);

  /// No description provided for @markingKeywordsFound.
  ///
  /// In en, this message translates to:
  /// **'{found} of {total} required words used'**
  String markingKeywordsFound(int found, int total);

  /// No description provided for @markingMachineGave.
  ///
  /// In en, this message translates to:
  /// **'The machine gave {points} / {max}.'**
  String markingMachineGave(String points, String max);

  /// No description provided for @markingFull.
  ///
  /// In en, this message translates to:
  /// **'Full marks'**
  String get markingFull;

  /// No description provided for @markingKeepHalf.
  ///
  /// In en, this message translates to:
  /// **'Keep half'**
  String get markingKeepHalf;

  /// No description provided for @markingZero.
  ///
  /// In en, this message translates to:
  /// **'Zero'**
  String get markingZero;

  /// No description provided for @markingGrammar.
  ///
  /// In en, this message translates to:
  /// **'Grammar'**
  String get markingGrammar;

  /// No description provided for @markingVocabulary.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary'**
  String get markingVocabulary;

  /// No description provided for @markingContent.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get markingContent;

  /// No description provided for @markingRubricTotal.
  ///
  /// In en, this message translates to:
  /// **'Rubric {total} / 100 = {points} of {max} points'**
  String markingRubricTotal(int total, String points, String max);

  /// No description provided for @markingSave.
  ///
  /// In en, this message translates to:
  /// **'Save mark'**
  String get markingSave;

  /// No description provided for @markingSaved.
  ///
  /// In en, this message translates to:
  /// **'Mark saved.'**
  String get markingSaved;

  /// No description provided for @testsScanToJoin.
  ///
  /// In en, this message translates to:
  /// **'Students can scan this to join'**
  String get testsScanToJoin;

  /// No description provided for @testsResetAttempt.
  ///
  /// In en, this message translates to:
  /// **'Reset attempt'**
  String get testsResetAttempt;

  /// No description provided for @testsResetAttemptBody.
  ///
  /// In en, this message translates to:
  /// **'This deletes {student}\'s answers and result of {code}, so they can sit it again. Use it after a power cut or a broken device. The audit log keeps a record.'**
  String testsResetAttemptBody(String student, String code);

  /// No description provided for @testsResetReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get testsResetReason;

  /// No description provided for @testsResetDone.
  ///
  /// In en, this message translates to:
  /// **'Attempt reset. The student can sit the code again.'**
  String get testsResetDone;

  /// No description provided for @testsMarkedPoints.
  ///
  /// In en, this message translates to:
  /// **'Your teacher gave {points} of {max} points'**
  String testsMarkedPoints(String points, String max);

  /// No description provided for @bankSheetDownloadText.
  ///
  /// In en, this message translates to:
  /// **'Download text'**
  String get bankSheetDownloadText;

  /// No description provided for @bankSheetTextDownloaded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 question saved as a truth file.} other{{count} questions saved as a truth file.}}'**
  String bankSheetTextDownloaded(int count);

  /// No description provided for @paperRecordTitle.
  ///
  /// In en, this message translates to:
  /// **'Proofreading record'**
  String get paperRecordTitle;

  /// No description provided for @paperRecordLine.
  ///
  /// In en, this message translates to:
  /// **'{slots} questions · {flagged} flagged by the reader · {changed} changed by the admin ({untouched} kept as read) · {minutes} min proofreading'**
  String paperRecordLine(
      int slots, int flagged, int changed, int untouched, String minutes);

  /// No description provided for @paperRecordRead.
  ///
  /// In en, this message translates to:
  /// **'Read by {engine} in {seconds} s'**
  String paperRecordRead(String engine, int seconds);

  /// No description provided for @paperCompareTruth.
  ///
  /// In en, this message translates to:
  /// **'Compare with a truth file'**
  String get paperCompareTruth;

  /// No description provided for @paperCompareSummary.
  ///
  /// In en, this message translates to:
  /// **'{right} of {total} right as read · {flagged} flagged · {wrongNotFlagged} wrong and not flagged · read in {seconds} s'**
  String paperCompareSummary(
      int right, int total, int flagged, int wrongNotFlagged, int seconds);

  /// No description provided for @paperCompareWrong.
  ///
  /// In en, this message translates to:
  /// **'Not right as read (! = not flagged): {numbers}'**
  String paperCompareWrong(String numbers);

  /// No description provided for @paperCompareFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not compare: {error}'**
  String paperCompareFailed(String error);

  /// No description provided for @leaderboardShort.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboardShort;

  /// No description provided for @leaderboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard · {code}'**
  String leaderboardTitle(String code);

  /// No description provided for @leaderboardLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Not open for you'**
  String get leaderboardLockedTitle;

  /// No description provided for @leaderboardLockedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A code\'s leaderboard opens after you have sat that code.'**
  String get leaderboardLockedSubtitle;

  /// No description provided for @leaderboardEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No results on the board yet'**
  String get leaderboardEmptyTitle;

  /// No description provided for @leaderboardEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Final, valid results appear here. Results waiting for marking come when they are marked.'**
  String get leaderboardEmptySubtitle;

  /// No description provided for @leaderboardIntroStaff.
  ///
  /// In en, this message translates to:
  /// **'Highest total first; with equal totals, the faster student first. Invalid and pending results are not on the board.'**
  String get leaderboardIntroStaff;

  /// No description provided for @leaderboardIntroStudent.
  ///
  /// In en, this message translates to:
  /// **'Highest total first; with equal totals, the faster student first. Your row is highlighted.'**
  String get leaderboardIntroStudent;

  /// No description provided for @leaderboardYou.
  ///
  /// In en, this message translates to:
  /// **'{name} (you)'**
  String leaderboardYou(String name);

  /// No description provided for @leaderboardRankOf.
  ///
  /// In en, this message translates to:
  /// **'Rank {rank} of {total}'**
  String leaderboardRankOf(int rank, int total);

  /// No description provided for @promotionTitle.
  ///
  /// In en, this message translates to:
  /// **'Promotion'**
  String get promotionTitle;

  /// No description provided for @promotionRule.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{A student is recommended after passing 1 code at their level.} other{A student is recommended after passing {count} different codes at their level.}}'**
  String promotionRule(int count);

  /// No description provided for @promotionChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get promotionChange;

  /// No description provided for @promotionMinCodesTitle.
  ///
  /// In en, this message translates to:
  /// **'Codes needed for promotion'**
  String get promotionMinCodesTitle;

  /// No description provided for @promotionMinCodesValue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 code} other{{count} codes}}'**
  String promotionMinCodesValue(int count);

  /// No description provided for @promotionEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No one is waiting'**
  String get promotionEmptyTitle;

  /// No description provided for @promotionEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'When a student passes enough codes at their level, they appear here.'**
  String get promotionEmptySubtitle;

  /// No description provided for @promotionCodesPassed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 code passed} other{{count} codes passed}}'**
  String promotionCodesPassed(int count);

  /// No description provided for @promotionApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve: {level}'**
  String promotionApprove(String level);

  /// No description provided for @promotionApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved. The student is now {level}.'**
  String promotionApproved(String level);

  /// No description provided for @promotionDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get promotionDecline;

  /// No description provided for @promotionDeclineTitle.
  ///
  /// In en, this message translates to:
  /// **'Decline the promotion'**
  String get promotionDeclineTitle;

  /// No description provided for @promotionDeclineReason.
  ///
  /// In en, this message translates to:
  /// **'Reason (the student keeps their level)'**
  String get promotionDeclineReason;

  /// No description provided for @promotionDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined.'**
  String get promotionDeclined;

  /// No description provided for @promotionProgress.
  ///
  /// In en, this message translates to:
  /// **'{count} of {min} codes passed'**
  String promotionProgress(int count, int min);

  /// No description provided for @promotionTowards.
  ///
  /// In en, this message translates to:
  /// **'Toward {level}. Each code counts once; it must be passed, valid and final.'**
  String promotionTowards(String level);

  /// No description provided for @promotionWaitingForAdmin.
  ///
  /// In en, this message translates to:
  /// **'Enough codes passed: waiting for the admin to confirm {level}.'**
  String promotionWaitingForAdmin(String level);

  /// No description provided for @promotionTopLevel.
  ///
  /// In en, this message translates to:
  /// **'HSK 6 is the highest level.'**
  String get promotionTopLevel;

  /// No description provided for @promotionErrNotWaiting.
  ///
  /// In en, this message translates to:
  /// **'This recommendation was already decided or withdrawn.'**
  String get promotionErrNotWaiting;

  /// No description provided for @promotionErrLevelChanged.
  ///
  /// In en, this message translates to:
  /// **'The student\'s level has changed since this recommendation.'**
  String get promotionErrLevelChanged;

  /// No description provided for @levelGroupBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get levelGroupBeginner;

  /// No description provided for @levelGroupIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get levelGroupIntermediate;

  /// No description provided for @levelGroupAdvance.
  ///
  /// In en, this message translates to:
  /// **'Advance'**
  String get levelGroupAdvance;

  /// No description provided for @promotionNotYetStudent.
  ///
  /// In en, this message translates to:
  /// **'Not moved up to {next} yet. Your teacher will talk with you about the next step.'**
  String promotionNotYetStudent(String next);

  /// No description provided for @placementTestLabel.
  ///
  /// In en, this message translates to:
  /// **'Placement test'**
  String get placementTestLabel;

  /// No description provided for @placementSessionLabel.
  ///
  /// In en, this message translates to:
  /// **'Placement session'**
  String get placementSessionLabel;

  /// No description provided for @placementRuleNoReview.
  ///
  /// In en, this message translates to:
  /// **'You see your marks at the end. The questions are not shown again.'**
  String get placementRuleNoReview;

  /// No description provided for @placementErrNotApproved.
  ///
  /// In en, this message translates to:
  /// **'Your registration is waiting for the admin\'s approval.'**
  String get placementErrNotApproved;

  /// No description provided for @placementErrBadKey.
  ///
  /// In en, this message translates to:
  /// **'This test link is no longer valid. Ask your teacher for a new token.'**
  String get placementErrBadKey;

  /// No description provided for @placementErrVisitorDetails.
  ///
  /// In en, this message translates to:
  /// **'Type your name and a WhatsApp number (8 to 15 digits).'**
  String get placementErrVisitorDetails;

  /// No description provided for @placementErrNotPlacement.
  ///
  /// In en, this message translates to:
  /// **'This token is not for a placement test.'**
  String get placementErrNotPlacement;

  /// No description provided for @placementErrBadResultCode.
  ///
  /// In en, this message translates to:
  /// **'This result code is not valid. It has 6 letters and digits.'**
  String get placementErrBadResultCode;

  /// No description provided for @placementErrClaimed.
  ///
  /// In en, this message translates to:
  /// **'This result code was already used by another student.'**
  String get placementErrClaimed;

  /// No description provided for @placementErrTokenShort.
  ///
  /// In en, this message translates to:
  /// **'The token has 6 letters and digits.'**
  String get placementErrTokenShort;

  /// No description provided for @approvalErrNotPending.
  ///
  /// In en, this message translates to:
  /// **'This registration is already decided.'**
  String get approvalErrNotPending;

  /// No description provided for @approvalErrTeacher.
  ///
  /// In en, this message translates to:
  /// **'Pick an active teacher.'**
  String get approvalErrTeacher;

  /// No description provided for @approvalErrLevel.
  ///
  /// In en, this message translates to:
  /// **'Pick a starting level.'**
  String get approvalErrLevel;

  /// No description provided for @registerStartLevelTitle.
  ///
  /// In en, this message translates to:
  /// **'Where do you start?'**
  String get registerStartLevelTitle;

  /// No description provided for @registerChoiceHsk1.
  ///
  /// In en, this message translates to:
  /// **'Start from HSK 1'**
  String get registerChoiceHsk1;

  /// No description provided for @registerChoiceHsk1Help.
  ///
  /// In en, this message translates to:
  /// **'For beginners. The admin approves you at HSK 1.'**
  String get registerChoiceHsk1Help;

  /// No description provided for @registerChoiceTest.
  ///
  /// In en, this message translates to:
  /// **'Take a placement test'**
  String get registerChoiceTest;

  /// No description provided for @registerChoiceTestHelp.
  ///
  /// In en, this message translates to:
  /// **'You already know some Mandarin. A short test finds your level.'**
  String get registerChoiceTestHelp;

  /// No description provided for @registerTargetLevel.
  ///
  /// In en, this message translates to:
  /// **'Level you aim for'**
  String get registerTargetLevel;

  /// No description provided for @registerTargetLevelRequired.
  ///
  /// In en, this message translates to:
  /// **'Pick the level you aim for.'**
  String get registerTargetLevelRequired;

  /// No description provided for @registerResultCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Placement result code (optional)'**
  String get registerResultCodeLabel;

  /// No description provided for @registerResultCodeHelper.
  ///
  /// In en, this message translates to:
  /// **'From a placement test you took at the centre. Press Check.'**
  String get registerResultCodeHelper;

  /// No description provided for @registerResultCodeCheck.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get registerResultCodeCheck;

  /// No description provided for @registerResultCodeCheckFirst.
  ///
  /// In en, this message translates to:
  /// **'Press Check next to the result code first.'**
  String get registerResultCodeCheckFirst;

  /// No description provided for @placementSummaryLine.
  ///
  /// In en, this message translates to:
  /// **'{level} paper: {total} of {max}'**
  String placementSummaryLine(String level, int total, int max);

  /// No description provided for @placementPassed.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get placementPassed;

  /// No description provided for @placementNotPassed.
  ///
  /// In en, this message translates to:
  /// **'Not passed'**
  String get placementNotPassed;

  /// No description provided for @placementRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended level: {level}'**
  String placementRecommended(String level);

  /// No description provided for @teacherLinkCodeOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Teacher\'s link code (optional)'**
  String get teacherLinkCodeOptionalLabel;

  /// No description provided for @teacherLinkCodeOptionalHelper.
  ///
  /// In en, this message translates to:
  /// **'Leave it empty if you have none: the admin chooses your teacher.'**
  String get teacherLinkCodeOptionalHelper;

  /// No description provided for @waitingTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for approval'**
  String get waitingTitle;

  /// No description provided for @waitingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your account is made. The admin checks it and sets your teacher and level.'**
  String get waitingSubtitle;

  /// No description provided for @waitingRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Registration not approved'**
  String get waitingRejectedTitle;

  /// No description provided for @waitingRejectedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The admin did not approve this registration. Contact the centre.'**
  String get waitingRejectedSubtitle;

  /// No description provided for @waitingYourChoice.
  ///
  /// In en, this message translates to:
  /// **'Your choice:'**
  String get waitingYourChoice;

  /// No description provided for @waitingChoiceTest.
  ///
  /// In en, this message translates to:
  /// **'Placement test, aiming for {target}'**
  String waitingChoiceTest(String target);

  /// No description provided for @waitingResultCode.
  ///
  /// In en, this message translates to:
  /// **'Result code {code}'**
  String waitingResultCode(String code);

  /// No description provided for @waitingForAdmin.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the admin. This page opens the app by itself once you are approved.'**
  String get waitingForAdmin;

  /// No description provided for @waitingReason.
  ///
  /// In en, this message translates to:
  /// **'Reason:'**
  String get waitingReason;

  /// No description provided for @waitingWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp the centre ({number})'**
  String waitingWhatsApp(String number);

  /// No description provided for @approvalChip.
  ///
  /// In en, this message translates to:
  /// **'Approval'**
  String get approvalChip;

  /// No description provided for @approvalTitle.
  ///
  /// In en, this message translates to:
  /// **'Registrations to approve'**
  String get approvalTitle;

  /// No description provided for @approvalIntro.
  ///
  /// In en, this message translates to:
  /// **'New students wait here. Pick their teacher and starting level, then approve or reject.'**
  String get approvalIntro;

  /// No description provided for @approvalEmpty.
  ///
  /// In en, this message translates to:
  /// **'No registration is waiting.'**
  String get approvalEmpty;

  /// No description provided for @approvalRejectedList.
  ///
  /// In en, this message translates to:
  /// **'Rejected ({count})'**
  String approvalRejectedList(int count);

  /// No description provided for @approvalTeacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get approvalTeacher;

  /// No description provided for @approvalStartLevel.
  ///
  /// In en, this message translates to:
  /// **'Starting level'**
  String get approvalStartLevel;

  /// No description provided for @approvalApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approvalApprove;

  /// No description provided for @approvalReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get approvalReject;

  /// No description provided for @approvalApproved.
  ///
  /// In en, this message translates to:
  /// **'{name} approved at {level}.'**
  String approvalApproved(String name, String level);

  /// No description provided for @approvalRejected.
  ///
  /// In en, this message translates to:
  /// **'Registration rejected.'**
  String get approvalRejected;

  /// No description provided for @approvalRejectTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject {name}?'**
  String approvalRejectTitle(String name);

  /// No description provided for @approvalRejectReason.
  ///
  /// In en, this message translates to:
  /// **'Reason (the student sees it)'**
  String get approvalRejectReason;

  /// No description provided for @approvalRejectedBecause.
  ///
  /// In en, this message translates to:
  /// **'Rejected: {reason}'**
  String approvalRejectedBecause(String reason);

  /// No description provided for @placementScanToJoin.
  ///
  /// In en, this message translates to:
  /// **'Visitors scan to open the placement test'**
  String get placementScanToJoin;

  /// No description provided for @placementVisitorRow.
  ///
  /// In en, this message translates to:
  /// **'Visitor · {name}'**
  String placementVisitorRow(String name);

  /// No description provided for @placementSessionTick.
  ///
  /// In en, this message translates to:
  /// **'Placement session'**
  String get placementSessionTick;

  /// No description provided for @placementSessionTickHelp.
  ///
  /// In en, this message translates to:
  /// **'Results stay off the leaderboard and the promotion count.'**
  String get placementSessionTickHelp;

  /// No description provided for @placementCodeTick.
  ///
  /// In en, this message translates to:
  /// **'Placement code'**
  String get placementCodeTick;

  /// No description provided for @placementCodeTickHelp.
  ///
  /// In en, this message translates to:
  /// **'Visitors may sit it from the landing page. It never counts toward promotion.'**
  String get placementCodeTickHelp;

  /// No description provided for @placementPaperPassed.
  ///
  /// In en, this message translates to:
  /// **'Placement paper passed'**
  String get placementPaperPassed;

  /// No description provided for @placementPaperFailed.
  ///
  /// In en, this message translates to:
  /// **'Placement paper not passed'**
  String get placementPaperFailed;

  /// No description provided for @placementStudentWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the admin (recommended: {level}).'**
  String placementStudentWaiting(String level);

  /// No description provided for @placementStudentApproved.
  ///
  /// In en, this message translates to:
  /// **'You start at {level}.'**
  String placementStudentApproved(String level);

  /// No description provided for @placementStudentDeclined.
  ///
  /// In en, this message translates to:
  /// **'Your teacher will talk with you about your level.'**
  String get placementStudentDeclined;

  /// No description provided for @placementHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Find your level'**
  String get placementHomeTitle;

  /// No description provided for @placementHomeIntro.
  ///
  /// In en, this message translates to:
  /// **'Sit a short placement test at the centre. Your teacher gives you a token. At the end you see your marks and get a result code to register with.'**
  String get placementHomeIntro;

  /// No description provided for @placementResumeBody.
  ///
  /// In en, this message translates to:
  /// **'You have a placement test in progress in this tab.'**
  String get placementResumeBody;

  /// No description provided for @placementResume.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get placementResume;

  /// No description provided for @placementMenuEmpty.
  ///
  /// In en, this message translates to:
  /// **'No placement test is open right now.'**
  String get placementMenuEmpty;

  /// No description provided for @placementFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Start with your token'**
  String get placementFormTitle;

  /// No description provided for @placementToken.
  ///
  /// In en, this message translates to:
  /// **'Token'**
  String get placementToken;

  /// No description provided for @placementName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get placementName;

  /// No description provided for @placementWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp number'**
  String get placementWhatsapp;

  /// No description provided for @placementKeptNote.
  ///
  /// In en, this message translates to:
  /// **'Your name and number are kept by the centre for your registration.'**
  String get placementKeptNote;

  /// No description provided for @placementContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get placementContinue;

  /// No description provided for @placementNoResult.
  ///
  /// In en, this message translates to:
  /// **'No result in this tab.'**
  String get placementNoResult;

  /// No description provided for @placementResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Your placement result'**
  String get placementResultTitle;

  /// No description provided for @placementTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get placementTotal;

  /// No description provided for @placementYourCode.
  ///
  /// In en, this message translates to:
  /// **'Your result code'**
  String get placementYourCode;

  /// No description provided for @placementCodeHelp.
  ///
  /// In en, this message translates to:
  /// **'Type it when you register, or show it at the centre.'**
  String get placementCodeHelp;

  /// No description provided for @placementCopied.
  ///
  /// In en, this message translates to:
  /// **'Result code copied.'**
  String get placementCopied;

  /// No description provided for @placementRegisterNow.
  ///
  /// In en, this message translates to:
  /// **'Register now'**
  String get placementRegisterNow;

  /// No description provided for @roomsTitle.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get roomsTitle;

  /// No description provided for @roomsLabel.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get roomsLabel;

  /// No description provided for @roomsHint.
  ///
  /// In en, this message translates to:
  /// **'The rooms the class form offers.'**
  String get roomsHint;

  /// No description provided for @roomsName.
  ///
  /// In en, this message translates to:
  /// **'Room name'**
  String get roomsName;

  /// No description provided for @roomsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add room'**
  String get roomsAdd;

  /// No description provided for @roomsRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get roomsRename;

  /// No description provided for @roomsRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get roomsRemove;

  /// No description provided for @roomsSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get roomsSave;

  /// No description provided for @teacherLevelsTitle.
  ///
  /// In en, this message translates to:
  /// **'Levels taught'**
  String get teacherLevelsTitle;

  /// No description provided for @teacherLevelsHint.
  ///
  /// In en, this message translates to:
  /// **'The levels this teacher teaches (used by the weekly timetable).'**
  String get teacherLevelsHint;

  /// No description provided for @teacherLevelsNone.
  ///
  /// In en, this message translates to:
  /// **'The admin has not set your levels yet.'**
  String get teacherLevelsNone;

  /// No description provided for @progressReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress report'**
  String get progressReportTitle;

  /// No description provided for @progressReportTab.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get progressReportTab;

  /// No description provided for @progressPrint.
  ///
  /// In en, this message translates to:
  /// **'Print report'**
  String get progressPrint;

  /// No description provided for @progressPrintFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not make the PDF: {error}'**
  String progressPrintFailed(String error);

  /// No description provided for @progressReportUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This report cannot be opened.'**
  String get progressReportUnavailable;

  /// No description provided for @progressReportEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No report yet'**
  String get progressReportEmptyTitle;

  /// No description provided for @progressReportEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'The report fills in after the first practice, class or test.'**
  String get progressReportEmptySubtitle;

  /// No description provided for @progressStatusGood.
  ///
  /// In en, this message translates to:
  /// **'Progres Baik'**
  String get progressStatusGood;

  /// No description provided for @progressStatusAttention.
  ///
  /// In en, this message translates to:
  /// **'Perlu Perhatian'**
  String get progressStatusAttention;

  /// No description provided for @progressStatusFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Perlu Tindak Lanjut'**
  String get progressStatusFollowUp;

  /// No description provided for @progressCodesToward.
  ///
  /// In en, this message translates to:
  /// **'{count} of {min} codes passed toward {next}'**
  String progressCodesToward(int count, int min, String next);

  /// No description provided for @progressKpiAttendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance (30 days)'**
  String get progressKpiAttendance;

  /// No description provided for @progressKpiAttendanceNote.
  ///
  /// In en, this message translates to:
  /// **'Present {hadir} · absent {alpa} · excused {izin}'**
  String progressKpiAttendanceNote(int hadir, int alpa, int izin);

  /// No description provided for @progressKpiPractice.
  ///
  /// In en, this message translates to:
  /// **'Practice average (14 days)'**
  String get progressKpiPractice;

  /// No description provided for @progressKpiPracticeNote.
  ///
  /// In en, this message translates to:
  /// **'{n} attempts'**
  String progressKpiPracticeNote(int n);

  /// No description provided for @progressKpiPracticeChange.
  ///
  /// In en, this message translates to:
  /// **'{change} against the 14 days before'**
  String progressKpiPracticeChange(String change);

  /// No description provided for @progressKpiTests.
  ///
  /// In en, this message translates to:
  /// **'Tests passed at this level'**
  String get progressKpiTests;

  /// No description provided for @progressKpiTestsNote.
  ///
  /// In en, this message translates to:
  /// **'Codes passed at {level}'**
  String progressKpiTestsNote(String level);

  /// No description provided for @progressKpiVoucher.
  ///
  /// In en, this message translates to:
  /// **'Voucher sessions left'**
  String get progressKpiVoucher;

  /// No description provided for @progressKpiVoucherNote.
  ///
  /// In en, this message translates to:
  /// **'{days} days to the deadline'**
  String progressKpiVoucherNote(int days);

  /// No description provided for @progressKpiNoVoucher.
  ///
  /// In en, this message translates to:
  /// **'No active voucher'**
  String get progressKpiNoVoucher;

  /// No description provided for @progressWarnings.
  ///
  /// In en, this message translates to:
  /// **'Warnings'**
  String get progressWarnings;

  /// No description provided for @progressWarn1.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get progressWarn1;

  /// No description provided for @progressWarn2.
  ///
  /// In en, this message translates to:
  /// **'Score drop'**
  String get progressWarn2;

  /// No description provided for @progressWarn3.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get progressWarn3;

  /// No description provided for @progressWarn4.
  ///
  /// In en, this message translates to:
  /// **'Voucher'**
  String get progressWarn4;

  /// No description provided for @progressWarn5.
  ///
  /// In en, this message translates to:
  /// **'Tests failed'**
  String get progressWarn5;

  /// No description provided for @progressWarn1Rule.
  ///
  /// In en, this message translates to:
  /// **'Attendance under 75% in the last 30 days.'**
  String get progressWarn1Rule;

  /// No description provided for @progressWarn2Rule.
  ///
  /// In en, this message translates to:
  /// **'Practice average under 60 in the last 2 weeks, or 10 points lower than before.'**
  String get progressWarn2Rule;

  /// No description provided for @progressWarn3Rule.
  ///
  /// In en, this message translates to:
  /// **'No practice for 14 days.'**
  String get progressWarn3Rule;

  /// No description provided for @progressWarn4Rule.
  ///
  /// In en, this message translates to:
  /// **'2 or fewer sessions left, or the voucher ends within 7 days.'**
  String get progressWarn4Rule;

  /// No description provided for @progressWarn5Rule.
  ///
  /// In en, this message translates to:
  /// **'The last two tests were not passed.'**
  String get progressWarn5Rule;

  /// No description provided for @progressPracticeChart.
  ///
  /// In en, this message translates to:
  /// **'Weekly practice (last 12 weeks)'**
  String get progressPracticeChart;

  /// No description provided for @progressPracticeEmpty.
  ///
  /// In en, this message translates to:
  /// **'No practice in the last 12 weeks.'**
  String get progressPracticeEmpty;

  /// No description provided for @progressAttempts.
  ///
  /// In en, this message translates to:
  /// **'{n} attempts'**
  String progressAttempts(int n);

  /// No description provided for @progressSkills.
  ///
  /// In en, this message translates to:
  /// **'Average per skill (90 days)'**
  String get progressSkills;

  /// No description provided for @progressSkillsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No practice to measure yet.'**
  String get progressSkillsEmpty;

  /// No description provided for @progressTeacherNote.
  ///
  /// In en, this message translates to:
  /// **'Teacher\'s note'**
  String get progressTeacherNote;

  /// No description provided for @progressNoteEmpty.
  ///
  /// In en, this message translates to:
  /// **'No note yet.'**
  String get progressNoteEmpty;

  /// No description provided for @progressAddNote.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get progressAddNote;

  /// No description provided for @progressEditNote.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get progressEditNote;

  /// No description provided for @progressNoteHint.
  ///
  /// In en, this message translates to:
  /// **'What should the student and the parent know?'**
  String get progressNoteHint;

  /// No description provided for @progressTestHistory.
  ///
  /// In en, this message translates to:
  /// **'Test history'**
  String get progressTestHistory;

  /// No description provided for @progressTestsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No test yet.'**
  String get progressTestsEmpty;

  /// No description provided for @progressRank.
  ///
  /// In en, this message translates to:
  /// **'Rank {rank} of {size}'**
  String progressRank(int rank, int size);

  /// No description provided for @progressTagInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get progressTagInvalid;

  /// No description provided for @progressAttendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance (last 10)'**
  String get progressAttendance;

  /// No description provided for @progressAttendanceEmpty.
  ///
  /// In en, this message translates to:
  /// **'No attendance recorded yet.'**
  String get progressAttendanceEmpty;

  /// No description provided for @progressLevelHistory.
  ///
  /// In en, this message translates to:
  /// **'Level history'**
  String get progressLevelHistory;

  /// No description provided for @progressLevelHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No level change yet.'**
  String get progressLevelHistoryEmpty;

  /// No description provided for @progressAttentionTitle.
  ///
  /// In en, this message translates to:
  /// **'Students needing attention ({n})'**
  String progressAttentionTitle(int n);

  /// No description provided for @progressAttentionEmpty.
  ///
  /// In en, this message translates to:
  /// **'Every student is on track.'**
  String get progressAttentionEmpty;

  /// No description provided for @progressFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get progressFilterAll;

  /// No description provided for @progressShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all {n}'**
  String progressShowAll(int n);

  /// No description provided for @progressRebuildTitle.
  ///
  /// In en, this message translates to:
  /// **'Rebuild progress summaries'**
  String get progressRebuildTitle;

  /// No description provided for @progressRebuildHint.
  ///
  /// In en, this message translates to:
  /// **'Once after an update: recounts every student\'s report.'**
  String get progressRebuildHint;

  /// No description provided for @progressRebuilt.
  ///
  /// In en, this message translates to:
  /// **'{n} reports rebuilt.'**
  String progressRebuilt(int n);

  /// No description provided for @voucherNameChinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese name'**
  String get voucherNameChinese;

  /// No description provided for @voucherValidDays.
  ///
  /// In en, this message translates to:
  /// **'Valid for (days)'**
  String get voucherValidDays;

  /// No description provided for @voucherSoldInApp.
  ///
  /// In en, this message translates to:
  /// **'Sold in the app'**
  String get voucherSoldInApp;

  /// No description provided for @voucherValidFor.
  ///
  /// In en, this message translates to:
  /// **'valid {days} days'**
  String voucherValidFor(int days);

  /// No description provided for @voucherNotSoldInApp.
  ///
  /// In en, this message translates to:
  /// **'not sold in the app'**
  String get voucherNotSoldInApp;

  /// No description provided for @voucherTerm1.
  ///
  /// In en, this message translates to:
  /// **'Meetings not used within the validity (2 months) are forfeited.'**
  String get voucherTerm1;

  /// No description provided for @voucherTerm2.
  ///
  /// In en, this message translates to:
  /// **'Remaining meetings cannot be moved to another student.'**
  String get voucherTerm2;

  /// No description provided for @voucherTerm3.
  ///
  /// In en, this message translates to:
  /// **'Payment in full before the first class.'**
  String get voucherTerm3;

  /// No description provided for @voucherTerm4.
  ///
  /// In en, this message translates to:
  /// **'No refunds.'**
  String get voucherTerm4;

  /// No description provided for @voucherBuyTitle.
  ///
  /// In en, this message translates to:
  /// **'Buy a voucher'**
  String get voucherBuyTitle;

  /// No description provided for @voucherBuyIntro.
  ///
  /// In en, this message translates to:
  /// **'Pick a package. One meeting is 1.5 hours; 6 to 8 students per class.'**
  String get voucherBuyIntro;

  /// No description provided for @voucherNoPackages.
  ///
  /// In en, this message translates to:
  /// **'No package is on sale right now.'**
  String get voucherNoPackages;

  /// No description provided for @voucherTermsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get voucherTermsTitle;

  /// No description provided for @voucherAgree.
  ///
  /// In en, this message translates to:
  /// **'I agree to the terms above'**
  String get voucherAgree;

  /// No description provided for @voucherPay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get voucherPay;

  /// No description provided for @voucherPayNote.
  ///
  /// In en, this message translates to:
  /// **'The payment page (Midtrans) opens in a new tab. The voucher appears here once the payment is confirmed.'**
  String get voucherPayNote;

  /// No description provided for @voucherOfferLine.
  ///
  /// In en, this message translates to:
  /// **'{sessions} meetings · valid {days} days'**
  String voucherOfferLine(int sessions, int days);

  /// No description provided for @voucherMyVouchers.
  ///
  /// In en, this message translates to:
  /// **'Vouchers'**
  String get voucherMyVouchers;

  /// No description provided for @voucherBuy.
  ///
  /// In en, this message translates to:
  /// **'Buy voucher'**
  String get voucherBuy;

  /// No description provided for @voucherNone.
  ///
  /// In en, this message translates to:
  /// **'No voucher yet.'**
  String get voucherNone;

  /// No description provided for @voucherHistory.
  ///
  /// In en, this message translates to:
  /// **'Voucher history'**
  String get voucherHistory;

  /// No description provided for @voucherHistoryPurchase.
  ///
  /// In en, this message translates to:
  /// **'+{n} sessions bought'**
  String voucherHistoryPurchase(int n);

  /// No description provided for @voucherHistoryExpiry.
  ///
  /// In en, this message translates to:
  /// **'{n} sessions expired'**
  String voucherHistoryExpiry(int n);

  /// No description provided for @voucherStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get voucherStatusActive;

  /// No description provided for @voucherStatusUsedUp.
  ///
  /// In en, this message translates to:
  /// **'Used up'**
  String get voucherStatusUsedUp;

  /// No description provided for @voucherStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get voucherStatusExpired;

  /// No description provided for @voucherSessionsPackage.
  ///
  /// In en, this message translates to:
  /// **'{n} sessions'**
  String voucherSessionsPackage(int n);

  /// No description provided for @voucherLeft.
  ///
  /// In en, this message translates to:
  /// **'{left} of {total} left'**
  String voucherLeft(int left, int total);

  /// No description provided for @voucherBooked.
  ///
  /// In en, this message translates to:
  /// **'{n} booked'**
  String voucherBooked(int n);

  /// No description provided for @voucherUntil.
  ///
  /// In en, this message translates to:
  /// **'until {date} ({days} days)'**
  String voucherUntil(String date, int days);

  /// No description provided for @voucherEnded.
  ///
  /// In en, this message translates to:
  /// **'ended {date}'**
  String voucherEnded(String date);

  /// No description provided for @voucherForfeited.
  ///
  /// In en, this message translates to:
  /// **'{n} forfeited'**
  String voucherForfeited(int n);

  /// No description provided for @voucherSourceCash.
  ///
  /// In en, this message translates to:
  /// **'cash'**
  String get voucherSourceCash;

  /// No description provided for @voucherSourceTransfer.
  ///
  /// In en, this message translates to:
  /// **'transfer'**
  String get voucherSourceTransfer;

  /// No description provided for @voucherSourceOnline.
  ///
  /// In en, this message translates to:
  /// **'online'**
  String get voucherSourceOnline;

  /// No description provided for @invoicesBoughtInApp.
  ///
  /// In en, this message translates to:
  /// **'bought in the app'**
  String get invoicesBoughtInApp;

  /// No description provided for @invoicesFilterMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get invoicesFilterMonth;

  /// No description provided for @invoicesFilteredTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} invoices · {total}'**
  String invoicesFilteredTotal(int count, String total);

  /// No description provided for @bookingTitle.
  ///
  /// In en, this message translates to:
  /// **'Class sessions (next 14 days)'**
  String get bookingTitle;

  /// No description provided for @bookingMyLevel.
  ///
  /// In en, this message translates to:
  /// **'My level'**
  String get bookingMyLevel;

  /// No description provided for @bookingNone.
  ///
  /// In en, this message translates to:
  /// **'No session in the next 14 days.'**
  String get bookingNone;

  /// No description provided for @bookingAllLevels.
  ///
  /// In en, this message translates to:
  /// **'All levels'**
  String get bookingAllLevels;

  /// No description provided for @bookingSeatsLeft.
  ///
  /// In en, this message translates to:
  /// **'{left} of {total} seats left'**
  String bookingSeatsLeft(int left, int total);

  /// No description provided for @bookingBook.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get bookingBook;

  /// No description provided for @bookingCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get bookingCancel;

  /// No description provided for @bookingFullShort.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get bookingFullShort;

  /// No description provided for @bookingDone.
  ///
  /// In en, this message translates to:
  /// **'Booked.'**
  String get bookingDone;

  /// No description provided for @bookingCancelled.
  ///
  /// In en, this message translates to:
  /// **'Booking cancelled.'**
  String get bookingCancelled;

  /// No description provided for @bookingFull.
  ///
  /// In en, this message translates to:
  /// **'This class is full.'**
  String get bookingFull;

  /// No description provided for @bookingNoSessions.
  ///
  /// In en, this message translates to:
  /// **'No voucher session left to book. Buy a voucher first.'**
  String get bookingNoSessions;

  /// No description provided for @bookingExpired.
  ///
  /// In en, this message translates to:
  /// **'Your voucher ends before this class.'**
  String get bookingExpired;

  /// No description provided for @bookingOverlap.
  ///
  /// In en, this message translates to:
  /// **'You already booked a class at this time.'**
  String get bookingOverlap;

  /// No description provided for @bookingTooLate.
  ///
  /// In en, this message translates to:
  /// **'This class has already started.'**
  String get bookingTooLate;

  /// No description provided for @bookingNeedsTeacher.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a teacher'**
  String get bookingNeedsTeacher;

  /// No description provided for @bookingLevel.
  ///
  /// In en, this message translates to:
  /// **'This class is for another level.'**
  String get bookingLevel;

  /// No description provided for @bookingNotYours.
  ///
  /// In en, this message translates to:
  /// **'You can only book for yourself or your child.'**
  String get bookingNotYours;

  /// No description provided for @bookingFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not book. Try again.'**
  String get bookingFailed;

  /// No description provided for @timetableTitle.
  ///
  /// In en, this message translates to:
  /// **'Timetable'**
  String get timetableTitle;

  /// No description provided for @timetableGrid.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get timetableGrid;

  /// No description provided for @timetableList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get timetableList;

  /// No description provided for @timetableAvailability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get timetableAvailability;

  /// No description provided for @timetableNew.
  ///
  /// In en, this message translates to:
  /// **'New schedule'**
  String get timetableNew;

  /// No description provided for @timetableEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit schedule'**
  String get timetableEdit;

  /// No description provided for @timetableSeats.
  ///
  /// In en, this message translates to:
  /// **'{n} seats'**
  String timetableSeats(int n);

  /// No description provided for @timetableClassName.
  ///
  /// In en, this message translates to:
  /// **'Class name'**
  String get timetableClassName;

  /// No description provided for @timetableWeekday.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get timetableWeekday;

  /// No description provided for @timetableStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get timetableStart;

  /// No description provided for @timetableEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get timetableEnd;

  /// No description provided for @timetableCapacity.
  ///
  /// In en, this message translates to:
  /// **'Seats'**
  String get timetableCapacity;

  /// No description provided for @timetableFrom.
  ///
  /// In en, this message translates to:
  /// **'Valid from'**
  String get timetableFrom;

  /// No description provided for @timetableTo.
  ///
  /// In en, this message translates to:
  /// **'Valid to'**
  String get timetableTo;

  /// No description provided for @timetableNoClash.
  ///
  /// In en, this message translates to:
  /// **'No clash.'**
  String get timetableNoClash;

  /// No description provided for @timetableSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Free times'**
  String get timetableSuggestions;

  /// No description provided for @timetableDayOff.
  ///
  /// In en, this message translates to:
  /// **'Day off'**
  String get timetableDayOff;

  /// No description provided for @timetableDaysOff.
  ///
  /// In en, this message translates to:
  /// **'Days off'**
  String get timetableDaysOff;

  /// No description provided for @timetableReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get timetableReason;

  /// No description provided for @availabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'My availability'**
  String get availabilityTitle;

  /// No description provided for @availabilityHint.
  ///
  /// In en, this message translates to:
  /// **'Times you can teach each week, e.g. 15:00-18:00, 19:00-20:30.'**
  String get availabilityHint;

  /// No description provided for @availabilityInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check the times on {day}.'**
  String availabilityInvalid(String day);

  /// No description provided for @availabilitySaved.
  ///
  /// In en, this message translates to:
  /// **'Availability saved.'**
  String get availabilitySaved;

  /// No description provided for @weekdayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get weekdaySun;

  /// No description provided for @voucherClassDay.
  ///
  /// In en, this message translates to:
  /// **'Class day (books each week)'**
  String get voucherClassDay;

  /// No description provided for @voucherNoClassDay.
  ///
  /// In en, this message translates to:
  /// **'No fixed class day'**
  String get voucherNoClassDay;

  /// No description provided for @cancelAdminOnly.
  ///
  /// In en, this message translates to:
  /// **'Ask the admin to cancel a timetable session.'**
  String get cancelAdminOnly;

  /// No description provided for @cancelSessionBody.
  ///
  /// In en, this message translates to:
  /// **'Cancel {title} on {date}? Every booking comes back to its voucher and the students are told.'**
  String cancelSessionBody(Object title, Object date);

  /// No description provided for @cancelSessionButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel session'**
  String get cancelSessionButton;

  /// No description provided for @cancelSessionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Cancel session'**
  String get cancelSessionConfirm;

  /// No description provided for @cancelSessionDone.
  ///
  /// In en, this message translates to:
  /// **'Session cancelled. Bookings returned.'**
  String get cancelSessionDone;

  /// No description provided for @cancelSessionKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get cancelSessionKeep;

  /// No description provided for @cancelSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this session?'**
  String get cancelSessionTitle;

  /// No description provided for @changeAccept.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get changeAccept;

  /// No description provided for @changeAcceptHint.
  ///
  /// In en, this message translates to:
  /// **'Make the change on the schedule (New schedule / edit), then mark it done.'**
  String get changeAcceptHint;

  /// No description provided for @changeAcceptTitle.
  ///
  /// In en, this message translates to:
  /// **'Mark the change as done'**
  String get changeAcceptTitle;

  /// No description provided for @changeDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get changeDecline;

  /// No description provided for @changeDeclineTitle.
  ///
  /// In en, this message translates to:
  /// **'Decline the request'**
  String get changeDeclineTitle;

  /// No description provided for @changeNote.
  ///
  /// In en, this message translates to:
  /// **'Note for the teacher'**
  String get changeNote;

  /// No description provided for @changeStatusDeclined.
  ///
  /// In en, this message translates to:
  /// **'declined'**
  String get changeStatusDeclined;

  /// No description provided for @changeStatusDone.
  ///
  /// In en, this message translates to:
  /// **'done'**
  String get changeStatusDone;

  /// No description provided for @changeStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'waiting'**
  String get changeStatusOpen;

  /// No description provided for @checkInButton.
  ///
  /// In en, this message translates to:
  /// **'Teacher check-in'**
  String get checkInButton;

  /// No description provided for @checkInDone.
  ///
  /// In en, this message translates to:
  /// **'Checked in.'**
  String get checkInDone;

  /// No description provided for @checkInDoneLate.
  ///
  /// In en, this message translates to:
  /// **'Checked in, {minutes} minutes late.'**
  String checkInDoneLate(int minutes);

  /// No description provided for @checkInTooEarly.
  ///
  /// In en, this message translates to:
  /// **'Too early: you can check in 30 minutes before the class.'**
  String get checkInTooEarly;

  /// No description provided for @checkInTooLate.
  ///
  /// In en, this message translates to:
  /// **'The class time is over; ask the admin to close it.'**
  String get checkInTooLate;

  /// No description provided for @closeAlreadyDone.
  ///
  /// In en, this message translates to:
  /// **'This session was already closed. Nothing changed.'**
  String get closeAlreadyDone;

  /// No description provided for @closeDone.
  ///
  /// In en, this message translates to:
  /// **'Session closed: {credited} charged, {excused} excused.'**
  String closeDone(int credited, int excused);

  /// No description provided for @closeDoneWithFailures.
  ///
  /// In en, this message translates to:
  /// **'Session closed: {credited} charged. No voucher for: {names}.'**
  String closeDoneWithFailures(int credited, Object names);

  /// No description provided for @closeNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Start the session first.'**
  String get closeNotStarted;

  /// No description provided for @closeSessionButton.
  ///
  /// In en, this message translates to:
  /// **'Close session'**
  String get closeSessionButton;

  /// No description provided for @followUpNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing to follow up.'**
  String get followUpNothing;

  /// No description provided for @followUpRequests.
  ///
  /// In en, this message translates to:
  /// **'Change requests ({count})'**
  String followUpRequests(int count);

  /// No description provided for @followUpSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions to check ({count})'**
  String followUpSessions(int count);

  /// No description provided for @followUpUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'Not confirmed by the teacher ({count})'**
  String followUpUnconfirmed(int count);

  /// No description provided for @recapCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get recapCancelled;

  /// No description provided for @recapCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied as CSV.'**
  String get recapCopied;

  /// No description provided for @recapEmpty.
  ///
  /// In en, this message translates to:
  /// **'No sessions this month.'**
  String get recapEmpty;

  /// No description provided for @recapHeld.
  ///
  /// In en, this message translates to:
  /// **'Held'**
  String get recapHeld;

  /// No description provided for @recapHint.
  ///
  /// In en, this message translates to:
  /// **'Data only, no pay. Held and hours count closed sessions.'**
  String get recapHint;

  /// No description provided for @recapHours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get recapHours;

  /// No description provided for @recapLate.
  ///
  /// In en, this message translates to:
  /// **'Late check-ins'**
  String get recapLate;

  /// No description provided for @recapScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get recapScheduled;

  /// No description provided for @recapTeacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get recapTeacher;

  /// No description provided for @reconcileButton.
  ///
  /// In en, this message translates to:
  /// **'Check vouchers'**
  String get reconcileButton;

  /// No description provided for @reconcileHint.
  ///
  /// In en, this message translates to:
  /// **'Compares every voucher\'s used and booked sessions with the voucher history and the open bookings.'**
  String get reconcileHint;

  /// No description provided for @reconcileMismatches.
  ///
  /// In en, this message translates to:
  /// **'{count} vouchers do not match:'**
  String reconcileMismatches(int count);

  /// No description provided for @reconcileOk.
  ///
  /// In en, this message translates to:
  /// **'All {count} vouchers match.'**
  String reconcileOk(int count);

  /// No description provided for @reconcileTitle.
  ///
  /// In en, this message translates to:
  /// **'Voucher check'**
  String get reconcileTitle;

  /// No description provided for @scheduleAskChange.
  ///
  /// In en, this message translates to:
  /// **'Ask for a change'**
  String get scheduleAskChange;

  /// No description provided for @scheduleChangeReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get scheduleChangeReason;

  /// No description provided for @scheduleChangeReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Give a reason.'**
  String get scheduleChangeReasonRequired;

  /// No description provided for @scheduleChangeSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get scheduleChangeSend;

  /// No description provided for @scheduleChangeSent.
  ///
  /// In en, this message translates to:
  /// **'Sent to the admin.'**
  String get scheduleChangeSent;

  /// No description provided for @scheduleChangeWanted.
  ///
  /// In en, this message translates to:
  /// **'What should change (day, time, room)'**
  String get scheduleChangeWanted;

  /// No description provided for @scheduleConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get scheduleConfirm;

  /// No description provided for @scheduleConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Schedule confirmed.'**
  String get scheduleConfirmed;

  /// No description provided for @scheduleEntryHint.
  ///
  /// In en, this message translates to:
  /// **'Today\'s sessions, the week, availability'**
  String get scheduleEntryHint;

  /// No description provided for @scheduleMyRequests.
  ///
  /// In en, this message translates to:
  /// **'My change requests'**
  String get scheduleMyRequests;

  /// No description provided for @scheduleMySchedules.
  ///
  /// In en, this message translates to:
  /// **'My weekly classes'**
  String get scheduleMySchedules;

  /// No description provided for @scheduleNextSevenDays.
  ///
  /// In en, this message translates to:
  /// **'Next 7 days'**
  String get scheduleNextSevenDays;

  /// No description provided for @scheduleNoSchedules.
  ///
  /// In en, this message translates to:
  /// **'No weekly classes yet.'**
  String get scheduleNoSchedules;

  /// No description provided for @scheduleNoSessionsToday.
  ///
  /// In en, this message translates to:
  /// **'No sessions today.'**
  String get scheduleNoSessionsToday;

  /// No description provided for @scheduleNoSessionsWeek.
  ///
  /// In en, this message translates to:
  /// **'No sessions in the next 7 days.'**
  String get scheduleNoSessionsWeek;

  /// No description provided for @scheduleNoStudents.
  ///
  /// In en, this message translates to:
  /// **'No students booked yet.'**
  String get scheduleNoStudents;

  /// No description provided for @scheduleStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get scheduleStatusConfirmed;

  /// No description provided for @scheduleStatusUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'Not confirmed'**
  String get scheduleStatusUnconfirmed;

  /// No description provided for @scheduleStudents.
  ///
  /// In en, this message translates to:
  /// **'{count} students'**
  String scheduleStudents(int count);

  /// No description provided for @scheduleTabToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get scheduleTabToday;

  /// No description provided for @scheduleTabWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get scheduleTabWeek;

  /// No description provided for @scheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get scheduleTitle;

  /// No description provided for @sessionAlreadyClosed.
  ///
  /// In en, this message translates to:
  /// **'This session is closed.'**
  String get sessionAlreadyClosed;

  /// No description provided for @sessionLateCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Not started on time'**
  String get sessionLateCheckIn;

  /// No description provided for @sessionLateMinutes.
  ///
  /// In en, this message translates to:
  /// **'Late {minutes} min'**
  String sessionLateMinutes(int minutes);

  /// No description provided for @sessionNotYours.
  ///
  /// In en, this message translates to:
  /// **'This is another teacher\'s session.'**
  String get sessionNotYours;

  /// No description provided for @sessionStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get sessionStatusCancelled;

  /// No description provided for @sessionStatusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get sessionStatusDone;

  /// No description provided for @sessionStatusNeedsTeacher.
  ///
  /// In en, this message translates to:
  /// **'Needs a teacher'**
  String get sessionStatusNeedsTeacher;

  /// No description provided for @sessionStatusOngoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get sessionStatusOngoing;

  /// No description provided for @sessionStatusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get sessionStatusScheduled;

  /// No description provided for @sessionSubstitute.
  ///
  /// In en, this message translates to:
  /// **'Substitute'**
  String get sessionSubstitute;

  /// No description provided for @sessionUnclosed.
  ///
  /// In en, this message translates to:
  /// **'Not closed'**
  String get sessionUnclosed;

  /// No description provided for @substituteButton.
  ///
  /// In en, this message translates to:
  /// **'Substitute'**
  String get substituteButton;

  /// No description provided for @substituteDone.
  ///
  /// In en, this message translates to:
  /// **'Substitute assigned. Everyone was told.'**
  String get substituteDone;

  /// No description provided for @substituteHint.
  ///
  /// In en, this message translates to:
  /// **'Free at that time, can teach the level, no clash.'**
  String get substituteHint;

  /// No description provided for @substituteNone.
  ///
  /// In en, this message translates to:
  /// **'No teacher is free at that time.'**
  String get substituteNone;

  /// No description provided for @substituteTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a substitute teacher'**
  String get substituteTitle;

  /// No description provided for @timetableFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Follow-up'**
  String get timetableFollowUp;

  /// No description provided for @timetableRecap.
  ///
  /// In en, this message translates to:
  /// **'Teacher recap'**
  String get timetableRecap;

  /// No description provided for @dutyPending.
  ///
  /// In en, this message translates to:
  /// **'Pending registrations'**
  String get dutyPending;

  /// No description provided for @dutyUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'Unconfirmed schedules'**
  String get dutyUnconfirmed;

  /// No description provided for @dutyLate.
  ///
  /// In en, this message translates to:
  /// **'Late check-ins today'**
  String get dutyLate;

  /// No description provided for @dutyLateWeek.
  ///
  /// In en, this message translates to:
  /// **'{count} this week'**
  String dutyLateWeek(int count);

  /// No description provided for @dutyUnclosed.
  ///
  /// In en, this message translates to:
  /// **'Unclosed sessions'**
  String get dutyUnclosed;

  /// No description provided for @dutyAttention.
  ///
  /// In en, this message translates to:
  /// **'Students needing attention'**
  String get dutyAttention;

  /// No description provided for @dutyToday.
  ///
  /// In en, this message translates to:
  /// **'Today\'s sessions'**
  String get dutyToday;

  /// No description provided for @monthlyReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly report'**
  String get monthlyReportTitle;

  /// No description provided for @monthlyRebuild.
  ///
  /// In en, this message translates to:
  /// **'Rebuild'**
  String get monthlyRebuild;

  /// No description provided for @monthlyReportRebuilt.
  ///
  /// In en, this message translates to:
  /// **'Report rebuilt.'**
  String get monthlyReportRebuilt;

  /// No description provided for @monthlyNotBuilt.
  ///
  /// In en, this message translates to:
  /// **'Not built yet. Press Rebuild.'**
  String get monthlyNotBuilt;

  /// No description provided for @monthlyNewStudents.
  ///
  /// In en, this message translates to:
  /// **'New students'**
  String get monthlyNewStudents;

  /// No description provided for @monthlyRevenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue (paid invoices)'**
  String get monthlyRevenue;

  /// No description provided for @monthlyActive.
  ///
  /// In en, this message translates to:
  /// **'Active students'**
  String get monthlyActive;

  /// No description provided for @monthlyAttendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get monthlyAttendance;

  /// No description provided for @monthlyHours.
  ///
  /// In en, this message translates to:
  /// **'Teaching hours'**
  String get monthlyHours;

  /// No description provided for @monthlyLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get monthlyLevel;

  /// No description provided for @monthlyTeacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get monthlyTeacher;

  /// No description provided for @monthlyItem.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get monthlyItem;

  /// No description provided for @monthlyValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get monthlyValue;

  /// No description provided for @passwordChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get passwordChangeTitle;

  /// No description provided for @passwordChangeButton.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get passwordChangeButton;

  /// No description provided for @passwordCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get passwordCurrent;

  /// No description provided for @passwordNew.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get passwordNew;

  /// No description provided for @passwordNewAgain.
  ///
  /// In en, this message translates to:
  /// **'New password again'**
  String get passwordNewAgain;

  /// No description provided for @passwordRule.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters. You stay signed in on this device.'**
  String get passwordRule;

  /// No description provided for @passwordCurrentMissing.
  ///
  /// In en, this message translates to:
  /// **'Type your current password.'**
  String get passwordCurrentMissing;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'The new password needs at least 8 characters.'**
  String get passwordTooShort;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'The two new passwords are not the same.'**
  String get passwordMismatch;

  /// No description provided for @passwordSameAsOld.
  ///
  /// In en, this message translates to:
  /// **'The new password is the same as the old one.'**
  String get passwordSameAsOld;

  /// No description provided for @passwordCurrentWrong.
  ///
  /// In en, this message translates to:
  /// **'The current password is wrong.'**
  String get passwordCurrentWrong;

  /// No description provided for @passwordTooManyTries.
  ///
  /// In en, this message translates to:
  /// **'Too many tries. Wait a few minutes and try again.'**
  String get passwordTooManyTries;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed.'**
  String get passwordChanged;

  /// No description provided for @timetableRecheck.
  ///
  /// In en, this message translates to:
  /// **'Recheck'**
  String get timetableRecheck;

  /// No description provided for @timetableFillTimes.
  ///
  /// In en, this message translates to:
  /// **'Pick a teacher and a room, and type the times as 16:30, to check.'**
  String get timetableFillTimes;

  /// No description provided for @timetableDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get timetableDelete;

  /// No description provided for @timetableDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this schedule?'**
  String get timetableDeleteTitle;

  /// No description provided for @timetableDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'{what}\n\nIts future sessions are cancelled: bookings and voucher sessions go back to the students, who are told. Past sessions stay in the reports. This cannot be undone.'**
  String timetableDeleteBody(String what);

  /// No description provided for @timetableDeleted.
  ///
  /// In en, this message translates to:
  /// **'Schedule deleted, {n} future sessions cancelled.'**
  String timetableDeleted(int n);

  /// No description provided for @timetableRules.
  ///
  /// In en, this message translates to:
  /// **'Timetable rules'**
  String get timetableRules;

  /// No description provided for @timetableGapLabel.
  ///
  /// In en, this message translates to:
  /// **'Minutes needed between two classes'**
  String get timetableGapLabel;

  /// No description provided for @timetableGapHelp.
  ///
  /// In en, this message translates to:
  /// **'For one teacher and for one room. 0 = a class may start right when the previous one ends.'**
  String get timetableGapHelp;

  /// No description provided for @timetableHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Warn when a teacher teaches more than (hours a week)'**
  String get timetableHoursLabel;

  /// No description provided for @timetableRulesInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use 0 to 180 minutes and 1 to 80 hours.'**
  String get timetableRulesInvalid;

  /// No description provided for @bookingGoingOn.
  ///
  /// In en, this message translates to:
  /// **'Going on now: you can still join'**
  String get bookingGoingOn;

  /// No description provided for @bookingGoingOnBooked.
  ///
  /// In en, this message translates to:
  /// **'Going on now: you are in'**
  String get bookingGoingOnBooked;

  /// No description provided for @bookingJoinNow.
  ///
  /// In en, this message translates to:
  /// **'Join now'**
  String get bookingJoinNow;

  /// No description provided for @scheduleDaySheet.
  ///
  /// In en, this message translates to:
  /// **'Print day sheet'**
  String get scheduleDaySheet;

  /// No description provided for @voucherClassDayHelp.
  ///
  /// In en, this message translates to:
  /// **'Your weekly class: you are booked into it every week. Leave empty to book each class yourself.'**
  String get voucherClassDayHelp;

  /// No description provided for @rulesIntro.
  ///
  /// In en, this message translates to:
  /// **'These rules apply to every weekly schedule and to the automatic checks.'**
  String get rulesIntro;

  /// No description provided for @rulesGapTitle.
  ///
  /// In en, this message translates to:
  /// **'Break between two classes'**
  String get rulesGapTitle;

  /// No description provided for @rulesGapHelp.
  ///
  /// In en, this message translates to:
  /// **'For one teacher and for one room. 0 means a class may start right when the previous one ends.'**
  String get rulesGapHelp;

  /// No description provided for @rulesUnitMinutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get rulesUnitMinutes;

  /// No description provided for @rulesMinTitle.
  ///
  /// In en, this message translates to:
  /// **'Minimum students per class'**
  String get rulesMinTitle;

  /// No description provided for @rulesMinHelp.
  ///
  /// In en, this message translates to:
  /// **'A timetable class with fewer booked students closes by itself; the students get their session back and everyone is told. 0 switches this off.'**
  String get rulesMinHelp;

  /// No description provided for @rulesUnitStudents.
  ///
  /// In en, this message translates to:
  /// **'students'**
  String get rulesUnitStudents;

  /// No description provided for @rulesCheckedBefore.
  ///
  /// In en, this message translates to:
  /// **'checked'**
  String get rulesCheckedBefore;

  /// No description provided for @rulesUnitHours.
  ///
  /// In en, this message translates to:
  /// **'hours before'**
  String get rulesUnitHours;

  /// No description provided for @rulesHoursTitle.
  ///
  /// In en, this message translates to:
  /// **'Teaching load warning'**
  String get rulesHoursTitle;

  /// No description provided for @rulesHoursHelp.
  ///
  /// In en, this message translates to:
  /// **'Show a warning when a new schedule gives a teacher more hours a week than this.'**
  String get rulesHoursHelp;

  /// No description provided for @rulesUnitHoursWeek.
  ///
  /// In en, this message translates to:
  /// **'hours / week'**
  String get rulesUnitHoursWeek;

  /// No description provided for @rulesReadinessTitle.
  ///
  /// In en, this message translates to:
  /// **'Teacher availability, confirmation and recap'**
  String get rulesReadinessTitle;

  /// No description provided for @rulesReadinessHelp.
  ///
  /// In en, this message translates to:
  /// **'Off: teachers are taken as ready all the time (no availability check, no confirmation, no late check-in, no recap). On: the thesis features come back.'**
  String get rulesReadinessHelp;

  /// No description provided for @rulesReadinessOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get rulesReadinessOn;

  /// No description provided for @rulesReadinessOff.
  ///
  /// In en, this message translates to:
  /// **'Off: teachers are always ready'**
  String get rulesReadinessOff;

  /// No description provided for @rulesGapInvalid.
  ///
  /// In en, this message translates to:
  /// **'The break must be 0 to 180 minutes.'**
  String get rulesGapInvalid;

  /// No description provided for @rulesHoursInvalid.
  ///
  /// In en, this message translates to:
  /// **'The teaching load must be 1 to 80 hours.'**
  String get rulesHoursInvalid;

  /// No description provided for @rulesMinInvalid.
  ///
  /// In en, this message translates to:
  /// **'The minimum must be 0 to 30 students.'**
  String get rulesMinInvalid;

  /// No description provided for @rulesCheckInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check 1 to 48 hours before the class.'**
  String get rulesCheckInvalid;

  /// No description provided for @holidaysTab.
  ///
  /// In en, this message translates to:
  /// **'Holidays'**
  String get holidaysTab;

  /// No description provided for @timetableHelpers.
  ///
  /// In en, this message translates to:
  /// **'Helper teachers (up to 3)'**
  String get timetableHelpers;

  /// No description provided for @timetableHelperOf.
  ///
  /// In en, this message translates to:
  /// **'You help {name}'**
  String timetableHelperOf(String name);

  /// No description provided for @holidayKindNational.
  ///
  /// In en, this message translates to:
  /// **'National holiday'**
  String get holidayKindNational;

  /// No description provided for @holidayKindLeave.
  ///
  /// In en, this message translates to:
  /// **'Joint leave'**
  String get holidayKindLeave;

  /// No description provided for @holidayKindCentre.
  ///
  /// In en, this message translates to:
  /// **'Centre day off'**
  String get holidayKindCentre;

  /// No description provided for @holidayUndecided.
  ///
  /// In en, this message translates to:
  /// **'Not decided'**
  String get holidayUndecided;

  /// No description provided for @holidayOpen.
  ///
  /// In en, this message translates to:
  /// **'Classes run'**
  String get holidayOpen;

  /// No description provided for @holidayClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get holidayClosed;

  /// No description provided for @dayCloseTitle.
  ///
  /// In en, this message translates to:
  /// **'Close the centre on {date}?'**
  String dayCloseTitle(String date);

  /// No description provided for @dayOpenTitle.
  ///
  /// In en, this message translates to:
  /// **'Open the centre on {date}?'**
  String dayOpenTitle(String date);

  /// No description provided for @dayCloseBody.
  ///
  /// In en, this message translates to:
  /// **'Every class of that day that has not started is cancelled. Bookings and voucher sessions go back to the students, and they are told.'**
  String get dayCloseBody;

  /// No description provided for @dayOpenBody.
  ///
  /// In en, this message translates to:
  /// **'Classes run on this day. Timetable classes cancelled by an earlier closing come back (students book again).'**
  String get dayOpenBody;

  /// No description provided for @dayCloseReason.
  ///
  /// In en, this message translates to:
  /// **'Reason (e.g. holiday, vacation)'**
  String get dayCloseReason;

  /// No description provided for @dayCloseAnnounce.
  ///
  /// In en, this message translates to:
  /// **'Post an announcement for students, parents and teachers'**
  String get dayCloseAnnounce;

  /// No description provided for @dayCloseButton.
  ///
  /// In en, this message translates to:
  /// **'Close this day'**
  String get dayCloseButton;

  /// No description provided for @dayOpenButton.
  ///
  /// In en, this message translates to:
  /// **'Classes run'**
  String get dayOpenButton;

  /// No description provided for @dayClosedDone.
  ///
  /// In en, this message translates to:
  /// **'Day closed, {n} classes cancelled.'**
  String dayClosedDone(int n);

  /// No description provided for @dayOpenedDone.
  ///
  /// In en, this message translates to:
  /// **'Day open, {n} classes back.'**
  String dayOpenedDone(int n);

  /// No description provided for @holidaysImport.
  ///
  /// In en, this message translates to:
  /// **'Load Indonesian holidays'**
  String get holidaysImport;

  /// No description provided for @holidaysImported.
  ///
  /// In en, this message translates to:
  /// **'{n} holidays added.'**
  String holidaysImported(int n);

  /// No description provided for @holidaysCloseOther.
  ///
  /// In en, this message translates to:
  /// **'Close another day'**
  String get holidaysCloseOther;

  /// No description provided for @holidaysCloseThisDay.
  ///
  /// In en, this message translates to:
  /// **'Close the centre on this day'**
  String get holidaysCloseThisDay;

  /// No description provided for @holidaysTitle.
  ///
  /// In en, this message translates to:
  /// **'Holidays'**
  String get holidaysTitle;

  /// No description provided for @holidaysHelp.
  ///
  /// In en, this message translates to:
  /// **'National holidays and joint leave (SKB 3 Menteri). Decide for each day whether classes run.'**
  String get holidaysHelp;

  /// No description provided for @holidaysNone.
  ///
  /// In en, this message translates to:
  /// **'No holidays ahead.'**
  String get holidaysNone;

  /// No description provided for @announcementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get announcementsTitle;

  /// No description provided for @announcementsNone.
  ///
  /// In en, this message translates to:
  /// **'No announcements right now.'**
  String get announcementsNone;

  /// No description provided for @announcementNew.
  ///
  /// In en, this message translates to:
  /// **'New announcement'**
  String get announcementNew;

  /// No description provided for @announcementTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get announcementTitleLabel;

  /// No description provided for @announcementBodyLabel.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get announcementBodyLabel;

  /// No description provided for @announcementTitleMissing.
  ///
  /// In en, this message translates to:
  /// **'Give the announcement a title.'**
  String get announcementTitleMissing;

  /// No description provided for @announcementForAll.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get announcementForAll;

  /// No description provided for @announcementForStudents.
  ///
  /// In en, this message translates to:
  /// **'Students & parents'**
  String get announcementForStudents;

  /// No description provided for @announcementForTeachers.
  ///
  /// In en, this message translates to:
  /// **'Teachers'**
  String get announcementForTeachers;

  /// No description provided for @announcementUntil.
  ///
  /// In en, this message translates to:
  /// **'Shown until {date}'**
  String announcementUntil(String date);

  /// No description provided for @announcementPickDate.
  ///
  /// In en, this message translates to:
  /// **'Change date'**
  String get announcementPickDate;

  /// No description provided for @announcementPost.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get announcementPost;

  /// No description provided for @boardSigned.
  ///
  /// In en, this message translates to:
  /// **'Signed the board'**
  String get boardSigned;

  /// No description provided for @boardTitle.
  ///
  /// In en, this message translates to:
  /// **'Attendance board'**
  String get boardTitle;

  /// No description provided for @boardHelp.
  ///
  /// In en, this message translates to:
  /// **'Tick each student whose name is on the board in the room. Names on the board that are not in this list go below.'**
  String get boardHelp;

  /// No description provided for @boardExtrasLabel.
  ///
  /// In en, this message translates to:
  /// **'Names on the board, not in the app'**
  String get boardExtrasLabel;

  /// No description provided for @boardExtrasHint.
  ///
  /// In en, this message translates to:
  /// **'Separate with commas'**
  String get boardExtrasHint;

  /// No description provided for @boardMatches.
  ///
  /// In en, this message translates to:
  /// **'The board and the app match.'**
  String get boardMatches;

  /// No description provided for @boardDifferences.
  ///
  /// In en, this message translates to:
  /// **'{n} differences between the board and the app'**
  String boardDifferences(int n);

  /// No description provided for @boardPresentNotSigned.
  ///
  /// In en, this message translates to:
  /// **'Present here, not on the board'**
  String get boardPresentNotSigned;

  /// No description provided for @boardSignedNotPresent.
  ///
  /// In en, this message translates to:
  /// **'On the board, not marked present'**
  String get boardSignedNotPresent;

  /// No description provided for @boardNotBooked.
  ///
  /// In en, this message translates to:
  /// **'On the board, not booked in the app'**
  String get boardNotBooked;

  /// No description provided for @dayClosedAnnTitle.
  ///
  /// In en, this message translates to:
  /// **'No classes on {date}'**
  String dayClosedAnnTitle(String date);

  /// No description provided for @dayClosedAnnBody.
  ///
  /// In en, this message translates to:
  /// **'The centre is closed on {date}. Booked sessions go back to your voucher.'**
  String dayClosedAnnBody(String date);

  /// No description provided for @newsTitle.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get newsTitle;

  /// No description provided for @newsIntro.
  ///
  /// In en, this message translates to:
  /// **'Announcements show on the home page of everyone you choose until their end date. Closing a day on the Timetable posts one here too.'**
  String get newsIntro;

  /// No description provided for @newsActive.
  ///
  /// In en, this message translates to:
  /// **'Showing now ({n})'**
  String newsActive(int n);

  /// No description provided for @newsPast.
  ///
  /// In en, this message translates to:
  /// **'Ended ({n})'**
  String newsPast(int n);

  /// No description provided for @newsPosted.
  ///
  /// In en, this message translates to:
  /// **'posted {date}'**
  String newsPosted(String date);

  /// No description provided for @newsClosure.
  ///
  /// In en, this message translates to:
  /// **'Centre closed'**
  String get newsClosure;

  /// No description provided for @announcementEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit announcement'**
  String get announcementEdit;

  /// No description provided for @announcementDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this announcement?'**
  String get announcementDeleteTitle;

  /// No description provided for @announcementWhoSees.
  ///
  /// In en, this message translates to:
  /// **'Who sees it'**
  String get announcementWhoSees;

  /// No description provided for @announcementNotify.
  ///
  /// In en, this message translates to:
  /// **'Also send a notification'**
  String get announcementNotify;

  /// No description provided for @announcementNotifyHelp.
  ///
  /// In en, this message translates to:
  /// **'It rings the bell of everyone who sees it.'**
  String get announcementNotifyHelp;

  /// No description provided for @promoteManualHint.
  ///
  /// In en, this message translates to:
  /// **'A capable student may move up without waiting for passed codes.'**
  String get promoteManualHint;

  /// No description provided for @promoteManualButton.
  ///
  /// In en, this message translates to:
  /// **'Promote a student'**
  String get promoteManualButton;

  /// No description provided for @promoteManualHelp.
  ///
  /// In en, this message translates to:
  /// **'The level goes up at once. The student and a linked parent are told, the reason is kept in the level history, and the code count starts again.'**
  String get promoteManualHelp;

  /// No description provided for @promoteStudentLabel.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get promoteStudentLabel;

  /// No description provided for @promoteLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'New level'**
  String get promoteLevelLabel;

  /// No description provided for @promoteLevelFrom.
  ///
  /// In en, this message translates to:
  /// **'New level (now {level})'**
  String promoteLevelFrom(String level);

  /// No description provided for @promoteTopLevel.
  ///
  /// In en, this message translates to:
  /// **'This student is already at the highest level.'**
  String get promoteTopLevel;

  /// No description provided for @promoteReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason (required)'**
  String get promoteReasonLabel;

  /// No description provided for @promoteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Promote to {level}'**
  String promoteConfirm(String level);

  /// No description provided for @promoteAnyway.
  ///
  /// In en, this message translates to:
  /// **'Promote anyway'**
  String get promoteAnyway;

  /// No description provided for @promotionDeclinedList.
  ///
  /// In en, this message translates to:
  /// **'Declined recommendations ({n})'**
  String promotionDeclinedList(int n);

  /// No description provided for @dashHello.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String dashHello(String name);

  /// No description provided for @dashTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dashTodayTitle;

  /// No description provided for @dashAllClear.
  ///
  /// In en, this message translates to:
  /// **'Nothing needs your action.'**
  String get dashAllClear;

  /// No description provided for @dashOpenTasks.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 thing needs your action} other{{n} things need your action}}'**
  String dashOpenTasks(int n);

  /// No description provided for @dashClassesToday.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{No classes today} =1{1 class today} other{{n} classes today}}'**
  String dashClassesToday(int n);

  /// No description provided for @dashMoreFigures.
  ///
  /// In en, this message translates to:
  /// **'More figures'**
  String get dashMoreFigures;

  /// No description provided for @dashMoreFiguresHint.
  ///
  /// In en, this message translates to:
  /// **'Payments, vouchers and centre numbers'**
  String get dashMoreFiguresHint;

  /// No description provided for @transcribeFromRecording.
  ///
  /// In en, this message translates to:
  /// **'Write from the recording'**
  String get transcribeFromRecording;

  /// No description provided for @transcribeFromFile.
  ///
  /// In en, this message translates to:
  /// **'Write from an audio file'**
  String get transcribeFromFile;

  /// No description provided for @transcribeLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading the speech reader… {pct}% (once per computer, about 250 MB)'**
  String transcribeLoading(int pct);

  /// No description provided for @transcribeWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing the script… {pct}%'**
  String transcribeWriting(int pct);

  /// No description provided for @transcribeDone.
  ///
  /// In en, this message translates to:
  /// **'Script written. Read it through and correct it before saving.'**
  String get transcribeDone;

  /// No description provided for @transcribeNote.
  ///
  /// In en, this message translates to:
  /// **'The script is written on this computer from the recording; it can mishear names and numbers, so check it against the recording.'**
  String get transcribeNote;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Removes your sign-in and profile for good.'**
  String get deleteAccountSubtitle;

  /// No description provided for @deleteAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccountButton;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Your sign-in and your profile are deleted and cannot be brought back. Sessions left on your vouchers are lost. The centre keeps the records it needs (invoices, test results and attendance). Type your password to confirm.'**
  String get deleteAccountBody;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'I understand this cannot be undone.'**
  String get deleteAccountConfirm;

  /// No description provided for @deleteAccountDone.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted.'**
  String get deleteAccountDone;

  /// No description provided for @skillCategoryMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get skillCategoryMixed;

  /// No description provided for @sessionStatusEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get sessionStatusEnded;

  /// No description provided for @announcementNoEnd.
  ///
  /// In en, this message translates to:
  /// **'No end date (shown until you delete it)'**
  String get announcementNoEnd;

  /// No description provided for @announcementSetDate.
  ///
  /// In en, this message translates to:
  /// **'Set an end date'**
  String get announcementSetDate;

  /// No description provided for @announcementClearDate.
  ///
  /// In en, this message translates to:
  /// **'No end date'**
  String get announcementClearDate;

  /// No description provided for @newsOpened.
  ///
  /// In en, this message translates to:
  /// **'Classes run'**
  String get newsOpened;

  /// No description provided for @dayOpenAnnounce.
  ///
  /// In en, this message translates to:
  /// **'Tell students, parents and teachers that classes run'**
  String get dayOpenAnnounce;

  /// No description provided for @dayOpenedAnnTitle.
  ///
  /// In en, this message translates to:
  /// **'Classes run on {date}'**
  String dayOpenedAnnTitle(String date);

  /// No description provided for @dayOpenedAnnBody.
  ///
  /// In en, this message translates to:
  /// **'the centre is open on {date} and classes run as usual.'**
  String dayOpenedAnnBody(String date);

  /// No description provided for @dashNewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Latest news'**
  String get dashNewsTitle;

  /// No description provided for @dashNewsAll.
  ///
  /// In en, this message translates to:
  /// **'All news'**
  String get dashNewsAll;

  /// No description provided for @dashNextClass.
  ///
  /// In en, this message translates to:
  /// **'Next class {time} {title} · {inText}'**
  String dashNextClass(String time, String title, String inText);

  /// No description provided for @dashInMinutes.
  ///
  /// In en, this message translates to:
  /// **'in {n} min'**
  String dashInMinutes(int n);

  /// No description provided for @dashInHours.
  ///
  /// In en, this message translates to:
  /// **'in {h} h {m} min'**
  String dashInHours(int h, int m);

  /// No description provided for @dashClassGoingOn.
  ///
  /// In en, this message translates to:
  /// **'{title} is going on now'**
  String dashClassGoingOn(String title);

  /// No description provided for @paperPrevPage.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get paperPrevPage;

  /// No description provided for @paperNextPage.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get paperNextPage;

  /// No description provided for @paperPageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {count}'**
  String paperPageOf(int page, int count);

  /// No description provided for @discardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard your changes?'**
  String get discardTitle;

  /// No description provided for @discardBody.
  ///
  /// In en, this message translates to:
  /// **'You changed something here and have not saved it. If you leave now, the changes are lost.'**
  String get discardBody;

  /// No description provided for @discardKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get discardKeepEditing;

  /// No description provided for @discardConfirm.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discardConfirm;

  /// No description provided for @invoiceStatusDiscarded.
  ///
  /// In en, this message translates to:
  /// **'Discarded'**
  String get invoiceStatusDiscarded;

  /// No description provided for @invoiceDiscardMenu.
  ///
  /// In en, this message translates to:
  /// **'Discard…'**
  String get invoiceDiscardMenu;

  /// No description provided for @invoiceDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard this invoice?'**
  String get invoiceDiscardTitle;

  /// No description provided for @invoiceDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'{number} for {student}, {amount}. It leaves the list and the student no longer sees it. It is kept with your reason under Discarded invoices, where you can restore it.'**
  String invoiceDiscardBody(String number, String student, String amount);

  /// No description provided for @invoiceDiscardReason.
  ///
  /// In en, this message translates to:
  /// **'Reason (required)'**
  String get invoiceDiscardReason;

  /// No description provided for @invoiceDiscarded.
  ///
  /// In en, this message translates to:
  /// **'Invoice discarded.'**
  String get invoiceDiscarded;

  /// No description provided for @invoiceRestored.
  ///
  /// In en, this message translates to:
  /// **'Invoice restored.'**
  String get invoiceRestored;

  /// No description provided for @invoiceRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get invoiceRestore;

  /// No description provided for @invoiceActiveList.
  ///
  /// In en, this message translates to:
  /// **'Invoices ({n})'**
  String invoiceActiveList(int n);

  /// No description provided for @invoiceDiscardedList.
  ///
  /// In en, this message translates to:
  /// **'Discarded invoices ({n})'**
  String invoiceDiscardedList(int n);

  /// No description provided for @invoiceDiscardedNone.
  ///
  /// In en, this message translates to:
  /// **'No discarded invoices.'**
  String get invoiceDiscardedNone;

  /// No description provided for @invoiceDiscardedWhy.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String invoiceDiscardedWhy(String reason);

  /// No description provided for @classOpenDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get classOpenDetails;

  /// No description provided for @classDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get classDetailTitle;

  /// No description provided for @classInfoRoom.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get classInfoRoom;

  /// No description provided for @classInfoTeachers.
  ///
  /// In en, this message translates to:
  /// **'Teachers'**
  String get classInfoTeachers;

  /// No description provided for @classInfoLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get classInfoLevel;

  /// No description provided for @classInfoSeats.
  ///
  /// In en, this message translates to:
  /// **'Seats'**
  String get classInfoSeats;

  /// No description provided for @classInfoSeatsValue.
  ///
  /// In en, this message translates to:
  /// **'{booked} of {capacity} booked'**
  String classInfoSeatsValue(int booked, int capacity);

  /// No description provided for @classInfoKind.
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get classInfoKind;

  /// No description provided for @classKindTimetable.
  ///
  /// In en, this message translates to:
  /// **'Weekly timetable'**
  String get classKindTimetable;

  /// No description provided for @classKindOneOff.
  ///
  /// In en, this message translates to:
  /// **'One-off class'**
  String get classKindOneOff;

  /// No description provided for @classInfoHoliday.
  ///
  /// In en, this message translates to:
  /// **'Holiday'**
  String get classInfoHoliday;

  /// No description provided for @classAllLevels.
  ///
  /// In en, this message translates to:
  /// **'All levels'**
  String get classAllLevels;

  /// No description provided for @studentTabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get studentTabOverview;

  /// No description provided for @studentTabClasses.
  ///
  /// In en, this message translates to:
  /// **'Classes'**
  String get studentTabClasses;

  /// No description provided for @studentTabHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get studentTabHistory;

  /// No description provided for @studentTabLearning.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get studentTabLearning;

  /// No description provided for @studentUpcomingClasses.
  ///
  /// In en, this message translates to:
  /// **'Booked classes'**
  String get studentUpcomingClasses;

  /// No description provided for @studentInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get studentInactive;

  /// No description provided for @studentMemberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since'**
  String get studentMemberSince;

  /// No description provided for @studentReportPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF report'**
  String get studentReportPdf;

  /// No description provided for @activityAttended.
  ///
  /// In en, this message translates to:
  /// **'Attended'**
  String get activityAttended;

  /// No description provided for @activityExcused.
  ///
  /// In en, this message translates to:
  /// **'Excused'**
  String get activityExcused;

  /// No description provided for @activityAbsent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get activityAbsent;

  /// No description provided for @activityBooked.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get activityBooked;

  /// No description provided for @activityCancelled.
  ///
  /// In en, this message translates to:
  /// **'Class cancelled'**
  String get activityCancelled;

  /// No description provided for @activityPractice.
  ///
  /// In en, this message translates to:
  /// **'Practice: {title} · {score}%'**
  String activityPractice(String title, int score);

  /// No description provided for @activityTest.
  ///
  /// In en, this message translates to:
  /// **'Test {code}: {total} of {max}'**
  String activityTest(String code, int total, int max);

  /// No description provided for @activityPassed.
  ///
  /// In en, this message translates to:
  /// **'passed'**
  String get activityPassed;

  /// No description provided for @activityNotPassed.
  ///
  /// In en, this message translates to:
  /// **'not passed'**
  String get activityNotPassed;

  /// No description provided for @activityPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid {amount}'**
  String activityPaid(String amount);

  /// No description provided for @activityLevel.
  ///
  /// In en, this message translates to:
  /// **'Level {from} → {to}'**
  String activityLevel(String from, String to);

  /// No description provided for @activityNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet.'**
  String get activityNone;

  /// No description provided for @activityNoUpcoming.
  ///
  /// In en, this message translates to:
  /// **'No booked classes ahead.'**
  String get activityNoUpcoming;

  /// No description provided for @activityShowMore.
  ///
  /// In en, this message translates to:
  /// **'Show more ({n} left)'**
  String activityShowMore(int n);

  /// No description provided for @invoiceDiscardConfirm.
  ///
  /// In en, this message translates to:
  /// **'Discard invoice'**
  String get invoiceDiscardConfirm;

  /// No description provided for @staffPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get staffPhone;

  /// No description provided for @staffHoursThisMonth.
  ///
  /// In en, this message translates to:
  /// **'hours taught this month'**
  String get staffHoursThisMonth;

  /// No description provided for @staffHoursLastMonth.
  ///
  /// In en, this message translates to:
  /// **'hours taught last month'**
  String get staffHoursLastMonth;

  /// No description provided for @staffTabWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly classes'**
  String get staffTabWeekly;

  /// No description provided for @staffTabClasses.
  ///
  /// In en, this message translates to:
  /// **'Classes'**
  String get staffTabClasses;

  /// No description provided for @staffTabStudents.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get staffTabStudents;

  /// No description provided for @staffNoWeekly.
  ///
  /// In en, this message translates to:
  /// **'No weekly classes.'**
  String get staffNoWeekly;

  /// No description provided for @staffAsHelper.
  ///
  /// In en, this message translates to:
  /// **'helper teacher'**
  String get staffAsHelper;

  /// No description provided for @staffComing.
  ///
  /// In en, this message translates to:
  /// **'Coming classes'**
  String get staffComing;

  /// No description provided for @staffRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent classes'**
  String get staffRecent;

  /// No description provided for @staffNoClasses.
  ///
  /// In en, this message translates to:
  /// **'No classes.'**
  String get staffNoClasses;

  /// No description provided for @staffNoStudents.
  ///
  /// In en, this message translates to:
  /// **'No students linked to this teacher.'**
  String get staffNoStudents;

  /// No description provided for @parentTabChildren.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get parentTabChildren;

  /// No description provided for @parentNoChildren.
  ///
  /// In en, this message translates to:
  /// **'No child linked yet.'**
  String get parentNoChildren;

  /// No description provided for @waitlistJoin.
  ///
  /// In en, this message translates to:
  /// **'Join waiting list'**
  String get waitlistJoin;

  /// No description provided for @waitlistLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave list'**
  String get waitlistLeave;

  /// No description provided for @waitlistOn.
  ///
  /// In en, this message translates to:
  /// **'On the waiting list: you are booked when a seat opens'**
  String get waitlistOn;

  /// No description provided for @waitlistJoined.
  ///
  /// In en, this message translates to:
  /// **'You are on the waiting list.'**
  String get waitlistJoined;

  /// No description provided for @waitlistLeft.
  ///
  /// In en, this message translates to:
  /// **'You left the waiting list.'**
  String get waitlistLeft;

  /// No description provided for @waitlistNotFull.
  ///
  /// In en, this message translates to:
  /// **'There is a free seat: book it.'**
  String get waitlistNotFull;

  /// No description provided for @waitlistAlready.
  ///
  /// In en, this message translates to:
  /// **'Already booked.'**
  String get waitlistAlready;

  /// No description provided for @routeTitleProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get routeTitleProfile;

  /// No description provided for @paperNoAnswer.
  ///
  /// In en, this message translates to:
  /// **'No answer yet'**
  String get paperNoAnswer;

  /// No description provided for @paperAnswerIs.
  ///
  /// In en, this message translates to:
  /// **'Answer: {letter}'**
  String paperAnswerIs(String letter);

  /// No description provided for @paperChoicesTick.
  ///
  /// In en, this message translates to:
  /// **'Choices: tick the right one'**
  String get paperChoicesTick;

  /// No description provided for @paperAddChoice.
  ///
  /// In en, this message translates to:
  /// **'Add a choice'**
  String get paperAddChoice;

  /// No description provided for @paperRemoveChoice.
  ///
  /// In en, this message translates to:
  /// **'Remove this choice'**
  String get paperRemoveChoice;

  /// No description provided for @paperSharedChoices.
  ///
  /// In en, this message translates to:
  /// **'Choices for this part (A, B, C…)'**
  String get paperSharedChoices;

  /// No description provided for @paperRightAnswer.
  ///
  /// In en, this message translates to:
  /// **'Right answer'**
  String get paperRightAnswer;

  /// No description provided for @paperLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave this scan?'**
  String get paperLeaveTitle;

  /// No description provided for @paperLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'The questions are not in the bank yet. Save the scan as a draft to finish it later, or discard it.'**
  String get paperLeaveBody;

  /// No description provided for @paperSaveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get paperSaveDraft;

  /// No description provided for @paperDraftSaved.
  ///
  /// In en, this message translates to:
  /// **'Draft saved. Open it again from Unfinished scans in the question bank.'**
  String get paperDraftSaved;

  /// No description provided for @paperDraftFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the draft: {error}'**
  String paperDraftFailed(String error);

  /// No description provided for @paperDraftsTitle.
  ///
  /// In en, this message translates to:
  /// **'Unfinished scans'**
  String get paperDraftsTitle;

  /// No description provided for @paperDraftsNone.
  ///
  /// In en, this message translates to:
  /// **'No unfinished scans.'**
  String get paperDraftsNone;

  /// No description provided for @paperDraftsButton.
  ///
  /// In en, this message translates to:
  /// **'Unfinished scans ({n})'**
  String paperDraftsButton(int n);

  /// No description provided for @paperDraftLine.
  ///
  /// In en, this message translates to:
  /// **'{questions} questions · {toCheck} to check · {answered} answered · {date}'**
  String paperDraftLine(int questions, int toCheck, int answered, String date);

  /// No description provided for @paperDraftOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get paperDraftOpen;

  /// No description provided for @paperDraftDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this unfinished scan?'**
  String get paperDraftDeleteTitle;

  /// No description provided for @paperBankSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The question bank refused the save: {error}'**
  String paperBankSaveFailed(String error);

  /// No description provided for @levelPathsTitle.
  ///
  /// In en, this message translates to:
  /// **'Level checklists'**
  String get levelPathsTitle;

  /// No description provided for @levelPathsHelp.
  ///
  /// In en, this message translates to:
  /// **'What a student must finish to move up. A level with a checklist uses it instead of the test-code count; when everything is done, the student appears here for you to approve.'**
  String get levelPathsHelp;

  /// No description provided for @levelPathNone.
  ///
  /// In en, this message translates to:
  /// **'No checklist: the test-code count is used'**
  String get levelPathNone;

  /// No description provided for @levelPathCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 item} other{{n} items}}'**
  String levelPathCount(int n);

  /// No description provided for @levelPathEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get levelPathEdit;

  /// No description provided for @levelPathEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'From {from} to {to}'**
  String levelPathEditorTitle(String from, String to);

  /// No description provided for @levelPathEditorHelp.
  ///
  /// In en, this message translates to:
  /// **'Add the exercises and tests a student must finish. For an exercise you may ask for a minimum score.'**
  String get levelPathEditorHelp;

  /// No description provided for @levelPathEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet.'**
  String get levelPathEmpty;

  /// No description provided for @levelPathAddExercise.
  ///
  /// In en, this message translates to:
  /// **'Add an exercise'**
  String get levelPathAddExercise;

  /// No description provided for @levelPathAddTest.
  ///
  /// In en, this message translates to:
  /// **'Add a test code'**
  String get levelPathAddTest;

  /// No description provided for @levelPathMinScore.
  ///
  /// In en, this message translates to:
  /// **'Needs'**
  String get levelPathMinScore;

  /// No description provided for @levelPathJustFinish.
  ///
  /// In en, this message translates to:
  /// **'just finish'**
  String get levelPathJustFinish;

  /// No description provided for @levelPathPassTest.
  ///
  /// In en, this message translates to:
  /// **'pass the test'**
  String get levelPathPassTest;

  /// No description provided for @levelPathUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get levelPathUp;

  /// No description provided for @levelPathProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'{from} → {to}: {done} of {total} done'**
  String levelPathProgressTitle(String from, String to, int done, int total);

  /// No description provided for @levelPathPassed.
  ///
  /// In en, this message translates to:
  /// **'passed'**
  String get levelPathPassed;

  /// No description provided for @levelPathScoreNeeded.
  ///
  /// In en, this message translates to:
  /// **'best {best}% · needs {min}%'**
  String levelPathScoreNeeded(int best, int min);

  /// No description provided for @levelPathFinished.
  ///
  /// In en, this message translates to:
  /// **'finished'**
  String get levelPathFinished;

  /// No description provided for @levelPathToDo.
  ///
  /// In en, this message translates to:
  /// **'to do'**
  String get levelPathToDo;

  /// No description provided for @paperSaveFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'The worksheet could not be saved'**
  String get paperSaveFailedTitle;

  /// No description provided for @paperSaveFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing is lost: keep editing, or save the scan as a draft. Please send this message to the developer:'**
  String get paperSaveFailedBody;

  /// No description provided for @paperRightOrder.
  ///
  /// In en, this message translates to:
  /// **'Right order'**
  String get paperRightOrder;

  /// No description provided for @paperOrderHint.
  ///
  /// In en, this message translates to:
  /// **'tap the words in the order of the right sentence'**
  String get paperOrderHint;

  /// No description provided for @paperOrderDone.
  ///
  /// In en, this message translates to:
  /// **'set (tap again to change)'**
  String get paperOrderDone;

  /// No description provided for @paperOrderReset.
  ///
  /// In en, this message translates to:
  /// **'Start again'**
  String get paperOrderReset;

  /// No description provided for @paperCharAnswer.
  ///
  /// In en, this message translates to:
  /// **'Answer (the character)'**
  String get paperCharAnswer;

  /// No description provided for @paperCharAnswerHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 长. More than one accepted? Separate them with /'**
  String get paperCharAnswerHint;

  /// No description provided for @exerciseCategoryStandardCourse.
  ///
  /// In en, this message translates to:
  /// **'Standard Course'**
  String get exerciseCategoryStandardCourse;

  /// No description provided for @bankAudioPlay.
  ///
  /// In en, this message translates to:
  /// **'Play the recording'**
  String get bankAudioPlay;

  /// No description provided for @bankAudioStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get bankAudioStop;

  /// No description provided for @bankAudioFailed.
  ///
  /// In en, this message translates to:
  /// **'The recording could not be played: {error}'**
  String bankAudioFailed(String error);

  /// No description provided for @bankTypeHsk.
  ///
  /// In en, this message translates to:
  /// **'HSK'**
  String get bankTypeHsk;

  /// No description provided for @bankNeedsRecording.
  ///
  /// In en, this message translates to:
  /// **'No listening recording yet'**
  String get bankNeedsRecording;

  /// No description provided for @bankRecordingRequired.
  ///
  /// In en, this message translates to:
  /// **'Required: HSK and Standard Course worksheets need their listening recording before a test code or an assignment.'**
  String get bankRecordingRequired;

  /// No description provided for @testsRemoveCode.
  ///
  /// In en, this message translates to:
  /// **'Remove code'**
  String get testsRemoveCode;

  /// No description provided for @testsRemoveCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {code}?'**
  String testsRemoveCodeTitle(String code);

  /// No description provided for @testsRemoveCodeBody.
  ///
  /// In en, this message translates to:
  /// **'Students can no longer use this code. An unused code is deleted. A code that was already used is hidden and switched off; its results stay and its name stays taken.'**
  String get testsRemoveCodeBody;

  /// No description provided for @testsRemoveCodeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get testsRemoveCodeConfirm;

  /// No description provided for @testsCodeRemoved.
  ///
  /// In en, this message translates to:
  /// **'{code} removed.'**
  String testsCodeRemoved(String code);

  /// No description provided for @testsCodeRemovedKept.
  ///
  /// In en, this message translates to:
  /// **'{code} removed. It was already used, so its results are kept and the name stays taken.'**
  String testsCodeRemovedKept(String code);

  /// No description provided for @rangeToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get rangeToday;

  /// No description provided for @rangeLast7.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get rangeLast7;

  /// No description provided for @rangeThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get rangeThisMonth;

  /// No description provided for @rangeLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get rangeLastMonth;

  /// No description provided for @rangeThisYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get rangeThisYear;

  /// No description provided for @rangeAll.
  ///
  /// In en, this message translates to:
  /// **'All dates'**
  String get rangeAll;

  /// No description provided for @rangeCustom.
  ///
  /// In en, this message translates to:
  /// **'Choose dates…'**
  String get rangeCustom;

  /// No description provided for @pagingNone.
  ///
  /// In en, this message translates to:
  /// **'No rows'**
  String get pagingNone;

  /// No description provided for @pagingSpan.
  ///
  /// In en, this message translates to:
  /// **'{from}–{to}'**
  String pagingSpan(int from, int to);

  /// No description provided for @pagingSpanOf.
  ///
  /// In en, this message translates to:
  /// **'{from}–{to} of {total}'**
  String pagingSpanOf(int from, int to, int total);

  /// No description provided for @pagingPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get pagingPrevious;

  /// No description provided for @pagingNext.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get pagingNext;

  /// No description provided for @pagingPage.
  ///
  /// In en, this message translates to:
  /// **'Page {n}'**
  String pagingPage(int n);

  /// No description provided for @pagingRowsPerPage.
  ///
  /// In en, this message translates to:
  /// **'Rows per page'**
  String get pagingRowsPerPage;

  /// No description provided for @pagingRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get pagingRefresh;

  /// No description provided for @pagingError.
  ///
  /// In en, this message translates to:
  /// **'Could not load this list: {error}'**
  String pagingError(String error);

  /// No description provided for @pagingEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing in this period'**
  String get pagingEmptyTitle;

  /// No description provided for @pagingEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose another date range or filter.'**
  String get pagingEmptySubtitle;

  /// No description provided for @pagingExportCapped.
  ///
  /// In en, this message translates to:
  /// **'Only the first {count} rows were exported. Choose a shorter date range for the rest.'**
  String pagingExportCapped(int count);

  /// No description provided for @pagingExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV (date range)'**
  String get pagingExportCsv;

  /// No description provided for @auditFilterAction.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get auditFilterAction;

  /// No description provided for @auditGroupAll.
  ///
  /// In en, this message translates to:
  /// **'All actions'**
  String get auditGroupAll;

  /// No description provided for @auditGroupInvoice.
  ///
  /// In en, this message translates to:
  /// **'Invoices and payments'**
  String get auditGroupInvoice;

  /// No description provided for @auditGroupTest.
  ///
  /// In en, this message translates to:
  /// **'Tests'**
  String get auditGroupTest;

  /// No description provided for @auditGroupPromotion.
  ///
  /// In en, this message translates to:
  /// **'Promotions'**
  String get auditGroupPromotion;

  /// No description provided for @auditGroupRegistration.
  ///
  /// In en, this message translates to:
  /// **'Registrations'**
  String get auditGroupRegistration;

  /// No description provided for @auditGroupSchedule.
  ///
  /// In en, this message translates to:
  /// **'Timetable'**
  String get auditGroupSchedule;

  /// No description provided for @auditGroupDay.
  ///
  /// In en, this message translates to:
  /// **'Days closed or opened'**
  String get auditGroupDay;

  /// No description provided for @auditGroupProgress.
  ///
  /// In en, this message translates to:
  /// **'Rebuilds (progress, leaderboards)'**
  String get auditGroupProgress;

  /// No description provided for @monthlyActiveEnd.
  ///
  /// In en, this message translates to:
  /// **'Active students (last month of the period)'**
  String get monthlyActiveEnd;

  /// No description provided for @monthlyMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get monthlyMonth;

  /// No description provided for @monthlyRevenueShort.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get monthlyRevenueShort;

  /// No description provided for @monthlyPaidShort.
  ///
  /// In en, this message translates to:
  /// **'Paid invoices'**
  String get monthlyPaidShort;

  /// No description provided for @monthlyNotBuiltShort.
  ///
  /// In en, this message translates to:
  /// **'Not built'**
  String get monthlyNotBuiltShort;

  /// No description provided for @monthlyPeriodLine.
  ///
  /// In en, this message translates to:
  /// **'Period: {period}'**
  String monthlyPeriodLine(String period);

  /// No description provided for @monthlyTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get monthlyTotal;

  /// No description provided for @monthlyMissingMonths.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 month has no report yet. Press its Rebuild button; it is left out of the total.} other{{count} months have no report yet. Press their Rebuild buttons; they are left out of the total.}}'**
  String monthlyMissingMonths(int count);

  /// No description provided for @periodLast3Months.
  ///
  /// In en, this message translates to:
  /// **'Last 3 months'**
  String get periodLast3Months;

  /// No description provided for @periodFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get periodFrom;

  /// No description provided for @periodTo.
  ///
  /// In en, this message translates to:
  /// **'to'**
  String get periodTo;

  /// No description provided for @adminReportsPeriodSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Figures for {period}. Every PDF covers the same period.'**
  String adminReportsPeriodSubtitle(String period);

  /// No description provided for @adminReportsNewInPeriod.
  ///
  /// In en, this message translates to:
  /// **'New in period'**
  String get adminReportsNewInPeriod;

  /// No description provided for @adminReportsInPeriod.
  ///
  /// In en, this message translates to:
  /// **'In period'**
  String get adminReportsInPeriod;

  /// No description provided for @adminReportsMonths.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get adminReportsMonths;

  /// No description provided for @adminReportsIssuedInPeriod.
  ///
  /// In en, this message translates to:
  /// **'Issued in period'**
  String get adminReportsIssuedInPeriod;

  /// No description provided for @leaderboardShare.
  ///
  /// In en, this message translates to:
  /// **'Share PDF'**
  String get leaderboardShare;

  /// No description provided for @leaderboardShareMine.
  ///
  /// In en, this message translates to:
  /// **'Share my result'**
  String get leaderboardShareMine;

  /// No description provided for @leaderboardYourPlace.
  ///
  /// In en, this message translates to:
  /// **'Your place'**
  String get leaderboardYourPlace;

  /// No description provided for @orgRebuildLeaderboards.
  ///
  /// In en, this message translates to:
  /// **'Rebuild leaderboards'**
  String get orgRebuildLeaderboards;

  /// No description provided for @orgRebuildLeaderboardsHint.
  ///
  /// In en, this message translates to:
  /// **'Writes every board row again from the test results (needed once after the Build 9 update, so the boards can be paged).'**
  String get orgRebuildLeaderboardsHint;

  /// No description provided for @orgRebuildLeaderboardsDone.
  ///
  /// In en, this message translates to:
  /// **'{count} results written to the boards again.'**
  String orgRebuildLeaderboardsDone(int count);

  /// No description provided for @exercisePlayAttemptsInfo.
  ///
  /// In en, this message translates to:
  /// **'Each attempt has its own clock. When you have finished, you may start a new attempt; every attempt is kept with its number.'**
  String get exercisePlayAttemptsInfo;

  /// No description provided for @exercisePlayEarlierAttempts.
  ///
  /// In en, this message translates to:
  /// **'Your earlier attempts'**
  String get exercisePlayEarlierAttempts;

  /// No description provided for @exercisePlayStartAttempt.
  ///
  /// In en, this message translates to:
  /// **'Start attempt {n}'**
  String exercisePlayStartAttempt(int n);

  /// No description provided for @resultAttemptNo.
  ///
  /// In en, this message translates to:
  /// **'Attempt {n}'**
  String resultAttemptNo(int n);

  /// No description provided for @testsSitting.
  ///
  /// In en, this message translates to:
  /// **'Sitting {n}'**
  String testsSitting(int n);

  /// No description provided for @testsSittingRepeat.
  ///
  /// In en, this message translates to:
  /// **'Sitting {n} · practice'**
  String testsSittingRepeat(int n);

  /// No description provided for @testsRepeatIntro.
  ///
  /// In en, this message translates to:
  /// **'This is your sitting {n} of this test. Your first sitting is the one that counts for the leaderboard and promotion; this one is practice.'**
  String testsRepeatIntro(int n);

  /// No description provided for @usersNotIndexed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 account is not in this list yet.} other{{count} accounts are not in this list yet.}} An admin presses Org settings → Rebuild user search once.'**
  String usersNotIndexed(int count);

  /// No description provided for @orgRebuildUserSearch.
  ///
  /// In en, this message translates to:
  /// **'Rebuild user search'**
  String get orgRebuildUserSearch;

  /// No description provided for @orgRebuildUserSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Writes the search index on every account (needed once after the Build 9 update, so the Users list can be paged and searched).'**
  String get orgRebuildUserSearchHint;

  /// No description provided for @orgRebuildUserSearchDone.
  ///
  /// In en, this message translates to:
  /// **'{count} accounts written to the search index.'**
  String orgRebuildUserSearchDone(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
