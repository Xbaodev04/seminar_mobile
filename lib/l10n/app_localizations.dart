import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('vi'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Street Food Go'**
  String get appTitle;

  /// No description provided for @menuTitle.
  ///
  /// In en, this message translates to:
  /// **'Street Food Go — Menu'**
  String get menuTitle;

  /// No description provided for @mapTitle.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapTitle;

  /// No description provided for @poiListTitle.
  ///
  /// In en, this message translates to:
  /// **'POI list'**
  String get poiListTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @statsTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal stats'**
  String get statsTitle;

  /// No description provided for @narrationStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Narration status'**
  String get narrationStatusTitle;

  /// No description provided for @recentLabel.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recentLabel;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get versionLabel;

  /// No description provided for @playNow.
  ///
  /// In en, this message translates to:
  /// **'Play now'**
  String get playNow;

  /// No description provided for @backToMap.
  ///
  /// In en, this message translates to:
  /// **'Back to map'**
  String get backToMap;

  /// No description provided for @locationInfo.
  ///
  /// In en, this message translates to:
  /// **'Location information:'**
  String get locationInfo;

  /// No description provided for @noNarration.
  ///
  /// In en, this message translates to:
  /// **'No narration is running.'**
  String get noNarration;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @autoPlayTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto play when arriving at POI'**
  String get autoPlayTitle;

  /// No description provided for @allowNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get allowNotificationsTitle;

  /// No description provided for @splashSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Play audio when you enter a POI area'**
  String get splashSubtitle;

  /// No description provided for @permissionEnableMsg.
  ///
  /// In en, this message translates to:
  /// **'Please enable location services to use the map.'**
  String get permissionEnableMsg;

  /// No description provided for @permissionDeniedMsg.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied.'**
  String get permissionDeniedMsg;

  /// No description provided for @permissionDeniedForeverMsg.
  ///
  /// In en, this message translates to:
  /// **'Location permission is permanently denied. Open settings to grant permission.'**
  String get permissionDeniedForeverMsg;

  /// No description provided for @locationErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error getting location: {error}'**
  String locationErrorPrefix(Object error);

  /// No description provided for @noUserPositionMsg.
  ///
  /// In en, this message translates to:
  /// **'No current location available. Tap to request permission.'**
  String get noUserPositionMsg;

  /// No description provided for @suggestionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Suggestions:'**
  String get suggestionsLabel;

  /// No description provided for @suggestion_keep_gps.
  ///
  /// In en, this message translates to:
  /// **'- Keep GPS on to receive automatic narration'**
  String get suggestion_keep_gps;

  /// No description provided for @visitedCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Visited POIs: {count}'**
  String visitedCountLabel(Object count);

  /// No description provided for @totalListenLabel.
  ///
  /// In en, this message translates to:
  /// **'Total listening time: {minutes} minutes'**
  String totalListenLabel(Object minutes);

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @language_system.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get language_system;

  /// No description provided for @language_en_label.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get language_en_label;

  /// No description provided for @language_vi_label.
  ///
  /// In en, this message translates to:
  /// **'Tiếng Việt'**
  String get language_vi_label;

  /// No description provided for @language_zh_label.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get language_zh_label;

  /// No description provided for @language_ko_label.
  ///
  /// In en, this message translates to:
  /// **'한국어'**
  String get language_ko_label;

  /// No description provided for @language_ja_label.
  ///
  /// In en, this message translates to:
  /// **'日本語'**
  String get language_ja_label;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get loginButton;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @createAccountNew.
  ///
  /// In en, this message translates to:
  /// **'Create new account'**
  String get createAccountNew;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullNameLabel;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordLabel;

  /// No description provided for @confirmPasswordRequiredMsg.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get confirmPasswordRequiredMsg;

  /// No description provided for @passwordMismatchMsg.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordMismatchMsg;

  /// No description provided for @enterNameMsg.
  ///
  /// In en, this message translates to:
  /// **'Enter full name'**
  String get enterNameMsg;

  /// No description provided for @enterEmailMsg.
  ///
  /// In en, this message translates to:
  /// **'Enter email'**
  String get enterEmailMsg;

  /// No description provided for @enterPasswordMsg.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get enterPasswordMsg;

  /// No description provided for @passwordMinLengthMsg.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLengthMsg;

  /// No description provided for @loginSuccessMsg.
  ///
  /// In en, this message translates to:
  /// **'Login successful'**
  String get loginSuccessMsg;

  /// No description provided for @registerSuccessMsg.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully'**
  String get registerSuccessMsg;

  /// No description provided for @loginGoogleSuccessMsg.
  ///
  /// In en, this message translates to:
  /// **'Signed in with Google successfully'**
  String get loginGoogleSuccessMsg;

  /// No description provided for @loginDemoSuccessMsg.
  ///
  /// In en, this message translates to:
  /// **'Demo login successful'**
  String get loginDemoSuccessMsg;

  /// No description provided for @loginWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get loginWithGoogle;

  /// No description provided for @quickLoginDemo.
  ///
  /// In en, this message translates to:
  /// **'Quick login (Demo)'**
  String get quickLoginDemo;

  /// No description provided for @logoutLabel.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get logoutLabel;

  /// No description provided for @loggedOutMsg.
  ///
  /// In en, this message translates to:
  /// **'Signed out'**
  String get loggedOutMsg;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get backToLogin;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get forgotPassword;

  /// No description provided for @buyPackageTitle.
  ///
  /// In en, this message translates to:
  /// **'Buy package'**
  String get buyPackageTitle;

  /// No description provided for @noActivePackageMsg.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have an active package. Please purchase a package to continue.'**
  String get noActivePackageMsg;

  /// No description provided for @buyNowToast.
  ///
  /// In en, this message translates to:
  /// **'Purchase flow will be implemented soon'**
  String get buyNowToast;

  /// No description provided for @buyNowButton.
  ///
  /// In en, this message translates to:
  /// **'Buy now'**
  String get buyNowButton;

  /// No description provided for @skipPurchase.
  ///
  /// In en, this message translates to:
  /// **'Skip (trial)'**
  String get skipPurchase;

  /// No description provided for @forgotPasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to receive a reset code.'**
  String get forgotPasswordDesc;

  /// No description provided for @resetSentMsg.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent'**
  String get resetSentMsg;

  /// No description provided for @sendResetButton.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendResetButton;

  /// No description provided for @resetSuccessMsg.
  ///
  /// In en, this message translates to:
  /// **'Password reset successful'**
  String get resetSuccessMsg;

  /// No description provided for @resendOtpText.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resendOtpText;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter the code sent to your email and choose a new password'**
  String get resetPasswordDesc;

  /// No description provided for @codeSentTo.
  ///
  /// In en, this message translates to:
  /// **'Code sent to:'**
  String get codeSentTo;

  /// No description provided for @otpLabel.
  ///
  /// In en, this message translates to:
  /// **'OTP'**
  String get otpLabel;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPasswordLabel;

  /// No description provided for @resetButton.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetButton;

  /// No description provided for @emailVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Email verification'**
  String get emailVerificationTitle;

  /// No description provided for @emailVerificationDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter the code sent to your email'**
  String get emailVerificationDesc;

  /// No description provided for @verifyButtonText.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyButtonText;

  /// No description provided for @backToRegister.
  ///
  /// In en, this message translates to:
  /// **'Back to register'**
  String get backToRegister;

  /// No description provided for @bottom_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get bottom_home;

  /// No description provided for @bottom_notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get bottom_notifications;

  /// No description provided for @bottom_profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get bottom_profile;

  /// No description provided for @bottom_calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get bottom_calendar;

  /// No description provided for @bottom_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get bottom_settings;

  /// No description provided for @searchPoiHint.
  ///
  /// In en, this message translates to:
  /// **'Search stalls, locations...'**
  String get searchPoiHint;

  /// No description provided for @ownerLabel.
  ///
  /// In en, this message translates to:
  /// **'Owner:'**
  String get ownerLabel;

  /// No description provided for @descriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionTitle;

  /// No description provided for @contactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contactTitle;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// No description provided for @websiteLabel.
  ///
  /// In en, this message translates to:
  /// **'Website:'**
  String get websiteLabel;

  /// No description provided for @infoTitle.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get infoTitle;

  /// No description provided for @openingHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Opening Hours:'**
  String get openingHoursLabel;

  /// No description provided for @priceRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Price Range:'**
  String get priceRangeLabel;

  /// No description provided for @searchHintText.
  ///
  /// In en, this message translates to:
  /// **'Search stalls...'**
  String get searchHintText;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: '**
  String get errorPrefix;

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// No description provided for @noStallsMessage.
  ///
  /// In en, this message translates to:
  /// **'No stalls available'**
  String get noStallsMessage;

  /// No description provided for @noSearchResultsMessage.
  ///
  /// In en, this message translates to:
  /// **'No stalls match your search'**
  String get noSearchResultsMessage;

  /// No description provided for @profilePageTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profilePageTitle;

  /// No description provided for @userLabel.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get userLabel;

  /// No description provided for @editProfileLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileLabel;

  /// No description provided for @changePasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordLabel;

  /// No description provided for @updateProfileSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get updateProfileSuccess;

  /// No description provided for @invalidEmailMsg.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get invalidEmailMsg;

  /// No description provided for @avatarUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Avatar URL'**
  String get avatarUrlLabel;

  /// No description provided for @saveButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButtonLabel;

  /// No description provided for @loginDeviceSuccessMsg.
  ///
  /// In en, this message translates to:
  /// **'Signed in with device successfully'**
  String get loginDeviceSuccessMsg;

  /// No description provided for @loginWithDevice.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Device'**
  String get loginWithDevice;

  /// No description provided for @loadPoiError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load POI: {error}'**
  String loadPoiError(Object error);

  /// No description provided for @audioQueue.
  ///
  /// In en, this message translates to:
  /// **'Audio queue: {queueInfo}'**
  String audioQueue(Object queueInfo);

  /// No description provided for @alreadyListenedRecently.
  ///
  /// In en, this message translates to:
  /// **'You\'ve already listened to {count} stall(s) recently, please try again in 2 minutes.'**
  String alreadyListenedRecently(Object count);

  /// No description provided for @pointNotInPoiZone.
  ///
  /// In en, this message translates to:
  /// **'Selected point is not in any POI zone'**
  String get pointNotInPoiZone;

  /// No description provided for @audioQueueFinished.
  ///
  /// In en, this message translates to:
  /// **'Audio queue finished'**
  String get audioQueueFinished;

  /// No description provided for @nowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now playing: {poiName}'**
  String nowPlaying(Object poiName);

  /// No description provided for @pleaseLoginFirst.
  ///
  /// In en, this message translates to:
  /// **'Please login first'**
  String get pleaseLoginFirst;

  /// No description provided for @scanQrCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get scanQrCode;

  /// No description provided for @stallNotFound.
  ///
  /// In en, this message translates to:
  /// **'Stall not found'**
  String get stallNotFound;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String error(Object error);

  /// No description provided for @enableLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable location services'**
  String get enableLocationTitle;

  /// No description provided for @enableLocationDesc.
  ///
  /// In en, this message translates to:
  /// **'Please enable location to see nearby stalls'**
  String get enableLocationDesc;

  /// No description provided for @enableLocationButton.
  ///
  /// In en, this message translates to:
  /// **'Enable Location'**
  String get enableLocationButton;

  /// No description provided for @enableLocationToSeeStalls.
  ///
  /// In en, this message translates to:
  /// **'Enable location to see stalls'**
  String get enableLocationToSeeStalls;

  /// No description provided for @noStallsFound.
  ///
  /// In en, this message translates to:
  /// **'No stalls found nearby'**
  String get noStallsFound;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @exitButton.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exitButton;

  /// No description provided for @exitAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Exit Application'**
  String get exitAppTitle;

  /// No description provided for @exitAppConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit?'**
  String get exitAppConfirm;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Listening History'**
  String get historyTitle;

  /// No description provided for @noHistoryMessage.
  ///
  /// In en, this message translates to:
  /// **'You have no listening history yet.'**
  String get noHistoryMessage;

  /// No description provided for @listenedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Listened at'**
  String get listenedAtLabel;

  /// No description provided for @unknownStall.
  ///
  /// In en, this message translates to:
  /// **'Unknown stall'**
  String get unknownStall;

  /// No description provided for @loadHistoryError.
  ///
  /// In en, this message translates to:
  /// **'Error loading listening history'**
  String get loadHistoryError;

  /// No description provided for @surveyTitle.
  ///
  /// In en, this message translates to:
  /// **'Survey'**
  String get surveyTitle;

  /// No description provided for @surveyQuestion.
  ///
  /// In en, this message translates to:
  /// **'How was your listening experience?'**
  String get surveyQuestion;

  /// No description provided for @surveyRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get surveyRatingLabel;

  /// No description provided for @surveyCommentLabel.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get surveyCommentLabel;

  /// No description provided for @surveySubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get surveySubmit;

  /// No description provided for @surveyThankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your feedback!'**
  String get surveyThankYou;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred.'**
  String get genericError;

  /// No description provided for @selectPoiTitle.
  ///
  /// In en, this message translates to:
  /// **'Select a stall'**
  String get selectPoiTitle;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ja', 'ko', 'vi', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ja': return AppLocalizationsJa();
    case 'ko': return AppLocalizationsKo();
    case 'vi': return AppLocalizationsVi();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
