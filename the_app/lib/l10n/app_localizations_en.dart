// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Wino';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get commonSave => 'Save';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonLanguage => 'Language';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonNext => 'Next';

  @override
  String get commonStart => 'Start';

  @override
  String get commonSkip => 'Skip';

  @override
  String get commonOpenSettings => 'Open Settings';

  @override
  String get commonBackToHome => 'Back to home';

  @override
  String get commonNotNow => 'Not now';

  @override
  String commonItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: 'No items',
    );
    return '$_temp0';
  }

  @override
  String get profileSettingsEdit => 'Edit Information';

  @override
  String get profileSettingsScanQr => 'Scan QR';

  @override
  String get profileSettingsSendFeedback => 'Send Feedback';

  @override
  String get profileSettingsLanguage => 'Language';

  @override
  String get profileSettingsLogout => 'Logout';

  @override
  String get profileShareTitle => 'Share Profile';

  @override
  String get profileShareShowQr => 'Show Profile QR';

  @override
  String get profileShareCopyLink => 'Copy link';

  @override
  String get profileShareShare => 'Share';

  @override
  String get profileShareLinkCopied => 'Profile link copied';

  @override
  String get productMenuFavoriteAdd => 'Add Favorite';

  @override
  String get productMenuFavoriteRemove => 'Remove Favorite';

  @override
  String get productMenuShare => 'Share Product';

  @override
  String get productMenuReport => 'Report Product';

  @override
  String get productShareQr => 'Show Product QR';

  @override
  String get productShareCopyLink => 'Copy link';

  @override
  String get productShareShare => 'Share';

  @override
  String get productShareLinkCopied => 'Product link copied';

  @override
  String get feedbackTitleSend => 'Send Feedback';

  @override
  String get feedbackTitleMy => 'My Feedback';

  @override
  String get feedbackSubmitSuccess => 'Feedback sent successfully.';

  @override
  String get feedbackSubmitError => 'Failed to send feedback';

  @override
  String get feedbackEmpty => 'No feedback submitted yet.';

  @override
  String get locationDisabled =>
      'Location services are disabled. Please enable GPS to use nearby search.';

  @override
  String get locationPermissionDeniedForever =>
      'Location permission is permanently denied. Please allow it from app settings.';

  @override
  String get settingsOpenLocation => 'Open Location Settings';

  @override
  String get settingsOpenApp => 'Open App Settings';

  @override
  String get errorGenericTitle => 'Something went wrong';

  @override
  String get networkErrorDetails =>
      'Please check your connection and try again.';

  @override
  String get serverErrorDetails =>
      'Sorry, something went wrong. Please try again later.';

  @override
  String get launchEyebrow => 'Welcome';

  @override
  String get launchTitle => 'Start in your language';

  @override
  String get launchSubtitle =>
      'Pick the language you want for browsing, search, and merchant tools. You can change it later from the profile screen.';

  @override
  String get launchSearchTitle => 'Search smarter';

  @override
  String get launchSearchDescription =>
      'Find products, discounts, and packs faster in one local marketplace.';

  @override
  String get launchNearbyTitle => 'Nearby discovery';

  @override
  String get launchNearbyDescription =>
      'Use GPS only when you want distance-based results and nearby deals.';

  @override
  String get launchPrivacyTitle => 'Store visibility control';

  @override
  String get launchPrivacyDescription =>
      'Merchants decide whether their store appears in nearby results.';

  @override
  String get locationEducationNearbyTitle => 'Use GPS for nearby results';

  @override
  String get locationEducationNearbyDescription =>
      'We use your location only when you choose nearby search. It helps calculate distance to stores and packs around you.';

  @override
  String get locationEducationStoreTitle => 'Set your store GPS location';

  @override
  String get locationEducationStoreDescription =>
      'Your store coordinates help nearby search show your products and packs to the right customers.';

  @override
  String get locationEducationPrivacyNote =>
      'You stay in control. Nearby visibility can be turned off later from your store profile.';

  @override
  String get locationEducationRadiusHint =>
      'Nearby search needs GPS once so we can measure distance accurately.';

  @override
  String get locationEducationAddressHint =>
      'City filters use your saved address, while nearby filters use GPS.';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileTooltipShare => 'Share Profile';

  @override
  String get profileTooltipAds => 'Ads Dashboard';

  @override
  String get profileTooltipNotifications => 'Notifications';

  @override
  String get profileShareQrTitle => 'Store QR';

  @override
  String get profileSettingsChooseImageSource => 'Choose image source';

  @override
  String get profileSettingsCamera => 'Camera';

  @override
  String get profileSettingsGallery => 'Gallery';

  @override
  String get feedbackTypeLabel => 'Feedback Type';

  @override
  String get feedbackTypeProblem => 'Problem';

  @override
  String get feedbackTypeSuggestion => 'Suggestion';

  @override
  String get feedbackMessageLabel => 'Message';

  @override
  String get feedbackMessageHint => 'Describe the issue or your suggestion.';

  @override
  String get feedbackAppVersionOptional => 'App Version (optional)';

  @override
  String get feedbackDeviceInfoOptional => 'Device Info (optional)';

  @override
  String get feedbackAttachScreenshotOptional => 'Attach Screenshot (optional)';

  @override
  String get feedbackScreenshotSelected => 'Screenshot selected';

  @override
  String get feedbackSending => 'Sending...';

  @override
  String get feedbackWriteMessageRequired =>
      'Please write your feedback message.';

  @override
  String get feedbackLoadHistoryFailed => 'Failed to load feedback history.';

  @override
  String feedbackAdminNotePrefix(String note) {
    return 'Admin note: $note';
  }

  @override
  String get feedbackStatusOpen => 'Open';

  @override
  String get feedbackStatusResolved => 'Resolved';

  @override
  String get feedbackStatusInReview => 'In review';

  @override
  String get feedbackStatusRejected => 'Rejected';

  @override
  String get feedbackTypeDefault => 'Feedback';

  @override
  String get qrLinkOpened => 'QR link opened.';
}
