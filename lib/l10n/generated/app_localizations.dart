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
