import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

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
    Locale('ar'),
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Wino'**
  String get appTitle;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @commonLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get commonLanguage;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get commonLoading;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @commonStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get commonStart;

  /// No description provided for @commonSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get commonSkip;

  /// No description provided for @commonOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get commonOpenSettings;

  /// No description provided for @commonBackToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get commonBackToHome;

  /// No description provided for @commonNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get commonNotNow;

  /// No description provided for @commonItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No items} one{1 item} other{{count} items}}'**
  String commonItemsCount(int count);

  /// No description provided for @profileSettingsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Information'**
  String get profileSettingsEdit;

  /// No description provided for @profileSettingsScanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get profileSettingsScanQr;

  /// No description provided for @profileSettingsSendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get profileSettingsSendFeedback;

  /// No description provided for @profileSettingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileSettingsLanguage;

  /// No description provided for @profileSettingsLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get profileSettingsLogout;

  /// No description provided for @profileShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share Profile'**
  String get profileShareTitle;

  /// No description provided for @profileShareShowQr.
  ///
  /// In en, this message translates to:
  /// **'Show Profile QR'**
  String get profileShareShowQr;

  /// No description provided for @profileShareCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get profileShareCopyLink;

  /// No description provided for @profileShareShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get profileShareShare;

  /// No description provided for @profileShareLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Profile link copied'**
  String get profileShareLinkCopied;

  /// No description provided for @productMenuFavoriteAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Favorite'**
  String get productMenuFavoriteAdd;

  /// No description provided for @productMenuFavoriteRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove Favorite'**
  String get productMenuFavoriteRemove;

  /// No description provided for @productMenuShare.
  ///
  /// In en, this message translates to:
  /// **'Share Product'**
  String get productMenuShare;

  /// No description provided for @productMenuReport.
  ///
  /// In en, this message translates to:
  /// **'Report Product'**
  String get productMenuReport;

  /// No description provided for @productShareQr.
  ///
  /// In en, this message translates to:
  /// **'Show Product QR'**
  String get productShareQr;

  /// No description provided for @productShareCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get productShareCopyLink;

  /// No description provided for @productShareShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get productShareShare;

  /// No description provided for @productShareLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Product link copied'**
  String get productShareLinkCopied;

  /// No description provided for @feedbackTitleSend.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get feedbackTitleSend;

  /// No description provided for @feedbackTitleMy.
  ///
  /// In en, this message translates to:
  /// **'My Feedback'**
  String get feedbackTitleMy;

  /// No description provided for @feedbackSubmitSuccess.
  ///
  /// In en, this message translates to:
  /// **'Feedback sent successfully.'**
  String get feedbackSubmitSuccess;

  /// No description provided for @feedbackSubmitError.
  ///
  /// In en, this message translates to:
  /// **'Failed to send feedback'**
  String get feedbackSubmitError;

  /// No description provided for @feedbackEmpty.
  ///
  /// In en, this message translates to:
  /// **'No feedback submitted yet.'**
  String get feedbackEmpty;

  /// No description provided for @directionsToStore.
  ///
  /// In en, this message translates to:
  /// **'Directions to store'**
  String get directionsToStore;

  /// No description provided for @mapLabel.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapLabel;

  /// No description provided for @openInGoogleMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Google Maps'**
  String get openInGoogleMaps;

  /// No description provided for @locationDisabledTitle.
  ///
  /// In en, this message translates to:
  /// **'Location is disabled'**
  String get locationDisabledTitle;

  /// No description provided for @locationDisabledMessage.
  ///
  /// In en, this message translates to:
  /// **'Enable location service (GPS) from settings to use directions.'**
  String get locationDisabledMessage;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No location available'**
  String get locationUnavailable;

  /// No description provided for @unableToOpenGoogleMaps.
  ///
  /// In en, this message translates to:
  /// **'Unable to open Google Maps'**
  String get unableToOpenGoogleMaps;

  /// No description provided for @locationDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled. Please enable GPS to use nearby search.'**
  String get locationDisabled;

  /// No description provided for @locationPermissionDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location permission is permanently denied. Please allow it from app settings.'**
  String get locationPermissionDeniedForever;

  /// No description provided for @settingsOpenLocation.
  ///
  /// In en, this message translates to:
  /// **'Open Location Settings'**
  String get settingsOpenLocation;

  /// No description provided for @settingsOpenApp.
  ///
  /// In en, this message translates to:
  /// **'Open App Settings'**
  String get settingsOpenApp;

  /// No description provided for @errorGenericTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorGenericTitle;

  /// No description provided for @networkErrorDetails.
  ///
  /// In en, this message translates to:
  /// **'Please check your connection and try again.'**
  String get networkErrorDetails;

  /// No description provided for @serverErrorDetails.
  ///
  /// In en, this message translates to:
  /// **'Sorry, something went wrong. Please try again later.'**
  String get serverErrorDetails;

  /// No description provided for @launchEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get launchEyebrow;

  /// No description provided for @launchTitle.
  ///
  /// In en, this message translates to:
  /// **'Start in your language'**
  String get launchTitle;

  /// No description provided for @launchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick the language you want for browsing, search, and merchant tools. You can change it later from the profile screen.'**
  String get launchSubtitle;

  /// No description provided for @launchSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search smarter'**
  String get launchSearchTitle;

  /// No description provided for @launchSearchDescription.
  ///
  /// In en, this message translates to:
  /// **'Find products, discounts, and packs faster in one local marketplace.'**
  String get launchSearchDescription;

  /// No description provided for @launchNearbyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby discovery'**
  String get launchNearbyTitle;

  /// No description provided for @launchNearbyDescription.
  ///
  /// In en, this message translates to:
  /// **'Use GPS only when you want distance-based results and nearby deals.'**
  String get launchNearbyDescription;

  /// No description provided for @launchPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Store visibility control'**
  String get launchPrivacyTitle;

  /// No description provided for @launchPrivacyDescription.
  ///
  /// In en, this message translates to:
  /// **'Merchants decide whether their store appears in nearby results.'**
  String get launchPrivacyDescription;

  /// No description provided for @locationEducationNearbyTitle.
  ///
  /// In en, this message translates to:
  /// **'Use GPS for nearby results'**
  String get locationEducationNearbyTitle;

  /// No description provided for @locationEducationNearbyDescription.
  ///
  /// In en, this message translates to:
  /// **'We use your location only when you choose nearby search. It helps calculate distance to stores and packs around you.'**
  String get locationEducationNearbyDescription;

  /// No description provided for @locationEducationStoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Set your store GPS location'**
  String get locationEducationStoreTitle;

  /// No description provided for @locationEducationStoreDescription.
  ///
  /// In en, this message translates to:
  /// **'Your store coordinates help nearby search show your products and packs to the right customers.'**
  String get locationEducationStoreDescription;

  /// No description provided for @locationEducationPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'You stay in control. Nearby visibility can be turned off later from your store profile.'**
  String get locationEducationPrivacyNote;

  /// No description provided for @locationEducationRadiusHint.
  ///
  /// In en, this message translates to:
  /// **'Nearby search needs GPS once so we can measure distance accurately.'**
  String get locationEducationRadiusHint;

  /// No description provided for @locationEducationAddressHint.
  ///
  /// In en, this message translates to:
  /// **'City filters use your saved address, while nearby filters use GPS.'**
  String get locationEducationAddressHint;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileTooltipShare.
  ///
  /// In en, this message translates to:
  /// **'Share Profile'**
  String get profileTooltipShare;

  /// No description provided for @profileTooltipAds.
  ///
  /// In en, this message translates to:
  /// **'Ads Dashboard'**
  String get profileTooltipAds;

  /// No description provided for @profileTooltipNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get profileTooltipNotifications;

  /// No description provided for @profileShareQrTitle.
  ///
  /// In en, this message translates to:
  /// **'Store QR'**
  String get profileShareQrTitle;

  /// No description provided for @profileSettingsChooseImageSource.
  ///
  /// In en, this message translates to:
  /// **'Choose image source'**
  String get profileSettingsChooseImageSource;

  /// No description provided for @profileSettingsCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get profileSettingsCamera;

  /// No description provided for @profileSettingsGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get profileSettingsGallery;

  /// No description provided for @feedbackTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Feedback Type'**
  String get feedbackTypeLabel;

  /// No description provided for @feedbackTypeProblem.
  ///
  /// In en, this message translates to:
  /// **'Problem'**
  String get feedbackTypeProblem;

  /// No description provided for @feedbackTypeSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Suggestion'**
  String get feedbackTypeSuggestion;

  /// No description provided for @feedbackMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get feedbackMessageLabel;

  /// No description provided for @feedbackMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the issue or your suggestion.'**
  String get feedbackMessageHint;

  /// No description provided for @feedbackAppVersionOptional.
  ///
  /// In en, this message translates to:
  /// **'App Version (optional)'**
  String get feedbackAppVersionOptional;

  /// No description provided for @feedbackDeviceInfoOptional.
  ///
  /// In en, this message translates to:
  /// **'Device Info (optional)'**
  String get feedbackDeviceInfoOptional;

  /// No description provided for @feedbackAttachScreenshotOptional.
  ///
  /// In en, this message translates to:
  /// **'Attach Screenshot (optional)'**
  String get feedbackAttachScreenshotOptional;

  /// No description provided for @feedbackScreenshotSelected.
  ///
  /// In en, this message translates to:
  /// **'Screenshot selected'**
  String get feedbackScreenshotSelected;

  /// No description provided for @feedbackSending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get feedbackSending;

  /// No description provided for @feedbackWriteMessageRequired.
  ///
  /// In en, this message translates to:
  /// **'Please write your feedback message.'**
  String get feedbackWriteMessageRequired;

  /// No description provided for @feedbackLoadHistoryFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load feedback history.'**
  String get feedbackLoadHistoryFailed;

  /// No description provided for @feedbackAdminNotePrefix.
  ///
  /// In en, this message translates to:
  /// **'Admin note: {note}'**
  String feedbackAdminNotePrefix(String note);

  /// No description provided for @feedbackStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get feedbackStatusOpen;

  /// No description provided for @feedbackStatusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get feedbackStatusResolved;

  /// No description provided for @feedbackStatusInReview.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get feedbackStatusInReview;

  /// No description provided for @feedbackStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get feedbackStatusRejected;

  /// No description provided for @feedbackTypeDefault.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedbackTypeDefault;

  /// No description provided for @qrLinkOpened.
  ///
  /// In en, this message translates to:
  /// **'QR link opened.'**
  String get qrLinkOpened;

  /// No description provided for @authRegisterHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get authRegisterHeaderTitle;

  /// No description provided for @authRegisterHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Three quick steps to personalize shopping and nearby offers.'**
  String get authRegisterHeaderSubtitle;

  /// No description provided for @authRegisterFooterPrompt.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authRegisterFooterPrompt;

  /// No description provided for @authRegisterFooterAction.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authRegisterFooterAction;

  /// No description provided for @authProfileSetupHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get authProfileSetupHeaderTitle;

  /// No description provided for @authProfileSetupHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save a few details so we can personalize results for you.'**
  String get authProfileSetupHeaderSubtitle;

  /// No description provided for @authProfileSetupBodySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your name, birthday, and interests help us tailor products, stores, and nearby offers.'**
  String get authProfileSetupBodySubtitle;

  /// No description provided for @authStepPersonalTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal details'**
  String get authStepPersonalTitle;

  /// No description provided for @authStepPersonalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start with the basics so your account feels complete from day one.'**
  String get authStepPersonalSubtitle;

  /// No description provided for @authStepAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account details'**
  String get authStepAccountTitle;

  /// No description provided for @authStepAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use a reachable phone number and a secure password.'**
  String get authStepAccountSubtitle;

  /// No description provided for @authStepInterestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Shopping interests'**
  String get authStepInterestsTitle;

  /// No description provided for @authStepInterestsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose up to 6 categories to improve recommendations and nearby discovery.'**
  String get authStepInterestsSubtitle;

  /// No description provided for @authFieldFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get authFieldFirstName;

  /// No description provided for @authFieldFirstNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your first name'**
  String get authFieldFirstNameHint;

  /// No description provided for @authFieldLastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get authFieldLastName;

  /// No description provided for @authFieldLastNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your last name'**
  String get authFieldLastNameHint;

  /// No description provided for @authFieldFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get authFieldFullName;

  /// No description provided for @authFieldFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get authFieldFullNameHint;

  /// No description provided for @authFieldBirthday.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get authFieldBirthday;

  /// No description provided for @authFieldBirthdayHint.
  ///
  /// In en, this message translates to:
  /// **'Use day, month, and year as shown on your official documents.'**
  String get authFieldBirthdayHint;

  /// No description provided for @authFieldDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get authFieldDay;

  /// No description provided for @authFieldDayHint.
  ///
  /// In en, this message translates to:
  /// **'DD'**
  String get authFieldDayHint;

  /// No description provided for @authFieldMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get authFieldMonth;

  /// No description provided for @authFieldMonthHint.
  ///
  /// In en, this message translates to:
  /// **'MM'**
  String get authFieldMonthHint;

  /// No description provided for @authFieldYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get authFieldYear;

  /// No description provided for @authFieldYearHint.
  ///
  /// In en, this message translates to:
  /// **'YYYY'**
  String get authFieldYearHint;

  /// No description provided for @authFieldGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get authFieldGender;

  /// No description provided for @authGenderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get authGenderMale;

  /// No description provided for @authGenderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get authGenderFemale;

  /// No description provided for @authFieldPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get authFieldPhone;

  /// No description provided for @authFieldPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'0XXXXXXXXX'**
  String get authFieldPhoneHint;

  /// No description provided for @authFieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authFieldEmail;

  /// No description provided for @authFieldEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get authFieldEmailHint;

  /// No description provided for @authFieldPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authFieldPassword;

  /// No description provided for @authFieldPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get authFieldPasswordHint;

  /// No description provided for @authFieldConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authFieldConfirmPassword;

  /// No description provided for @authFieldConfirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get authFieldConfirmPasswordHint;

  /// No description provided for @authFieldCategories.
  ///
  /// In en, this message translates to:
  /// **'Favorite categories'**
  String get authFieldCategories;

  /// No description provided for @authFieldCategoriesHint.
  ///
  /// In en, this message translates to:
  /// **'Choose up to 6 categories. You can change them later.'**
  String get authFieldCategoriesHint;

  /// No description provided for @authCategoriesCta.
  ///
  /// In en, this message translates to:
  /// **'Select your favorite categories'**
  String get authCategoriesCta;

  /// No description provided for @authCategoriesRetry.
  ///
  /// In en, this message translates to:
  /// **'Try loading categories again'**
  String get authCategoriesRetry;

  /// No description provided for @authCategoriesLoadError.
  ///
  /// In en, this message translates to:
  /// **'We could not load categories right now. Please try again.'**
  String get authCategoriesLoadError;

  /// No description provided for @authActionCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authActionCreateAccount;

  /// No description provided for @authActionPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get authActionPrevious;

  /// No description provided for @authRegistrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed. Please try again.'**
  String get authRegistrationFailed;

  /// No description provided for @authProfileSaveError.
  ///
  /// In en, this message translates to:
  /// **'We could not save your profile. Please try again.'**
  String get authProfileSaveError;

  /// No description provided for @authErrorRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get authErrorRequired;

  /// No description provided for @authErrorNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get authErrorNameRequired;

  /// No description provided for @authErrorBirthdayRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your birth date'**
  String get authErrorBirthdayRequired;

  /// No description provided for @authErrorBirthdayInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid date'**
  String get authErrorBirthdayInvalid;

  /// No description provided for @authErrorMustBe13.
  ///
  /// In en, this message translates to:
  /// **'You must be at least 13 years old'**
  String get authErrorMustBe13;

  /// No description provided for @authErrorPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get authErrorPhoneRequired;

  /// No description provided for @authErrorPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use format 05XXXXXXXX / 06XXXXXXXX / 07XXXXXXXX'**
  String get authErrorPhoneInvalid;

  /// No description provided for @authErrorEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get authErrorEmailRequired;

  /// No description provided for @authErrorEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get authErrorEmailInvalid;

  /// No description provided for @authErrorPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a password'**
  String get authErrorPasswordRequired;

  /// No description provided for @authErrorPasswordMin.
  ///
  /// In en, this message translates to:
  /// **'Use at least 6 characters'**
  String get authErrorPasswordMin;

  /// No description provided for @authErrorConfirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get authErrorConfirmPasswordRequired;

  /// No description provided for @authErrorPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get authErrorPasswordsDoNotMatch;

  /// No description provided for @authErrorCategoriesRequired.
  ///
  /// In en, this message translates to:
  /// **'Select at least 1 category'**
  String get authErrorCategoriesRequired;

  /// No description provided for @authStepProgress.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String authStepProgress(int current, int total);

  /// No description provided for @categoriesPickerSelectionCount.
  ///
  /// In en, this message translates to:
  /// **'{selected} of {max} selected'**
  String categoriesPickerSelectionCount(int selected, int max);

  /// No description provided for @categoriesPickerMaxReached.
  ///
  /// In en, this message translates to:
  /// **'You can select up to {max} categories.'**
  String categoriesPickerMaxReached(int max);

  /// No description provided for @categoriesPickerMinRequired.
  ///
  /// In en, this message translates to:
  /// **'Select at least {min} categories to continue.'**
  String categoriesPickerMinRequired(int min);

  /// No description provided for @categoriesPickerMaxHint.
  ///
  /// In en, this message translates to:
  /// **'Choose up to {max} categories.'**
  String categoriesPickerMaxHint(int max);

  /// No description provided for @categoryPickerSearchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose categories to narrow results, or leave them empty to keep your search broad.'**
  String get categoryPickerSearchSubtitle;

  /// No description provided for @categoryPickerProductSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick the one category that best matches this product.'**
  String get categoryPickerProductSubtitle;
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
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
