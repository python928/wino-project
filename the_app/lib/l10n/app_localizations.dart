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
