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
  /// **'Add'**
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
  /// **'Text PDFs and Word files take a few seconds. Scanned pages and photos take 20–40 seconds each; the first scan also downloads the Chinese OCR data (about 15 MB).'**
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
  /// **'An exercise bundles worksheets from the question bank; students see it once it is assigned to them. Admins create exercises on web.'**
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
  /// **'View only — browse published practice and assign it to murid. Creating and editing exercises is done by admins on web.'**
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
