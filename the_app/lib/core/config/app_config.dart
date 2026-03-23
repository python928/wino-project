class AppConfig {
  // App Info
  static const String appName = 'Wino';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // Support Info
  static const String supportEmail = 'support@dzlocal.dz';
  static const String supportPhone = '+213 555 123 456';
  static const String websiteUrl = 'https://dzlocal.dz';

  // Social Media
  static const String facebookUrl = 'https://facebook.com/dzlocal';
  static const String instagramUrl = 'https://instagram.com/dzlocal';
  static const String twitterUrl = 'https://twitter.com/dzlocal';

  // Privacy & Terms
  static const String privacyPolicyUrl = 'https://dzlocal.dz/privacy';
  static const String termsUrl = 'https://dzlocal.dz/terms';

  // Default Values
  static const String defaultLocation = 'Algiers';
  static const String defaultCurrency = 'DZD';
  static const String defaultLanguage = 'ar';
  static const String defaultCountryCode = 'DZ';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;

  // Cache
  static const Duration cacheExpiration = Duration(hours: 1);

  // Location
  static const double defaultLatitude = 36.7538;
  static const double defaultLongitude = 3.0588;

  // Map
  static const double defaultZoom = 15.0;
  static const double maxDistance = 50.0; // km

  // Search
  static const int minSearchLength = 2;
  static const Duration searchDebounce = Duration(milliseconds: 500);

  // Image
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png'];

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;
  static const int minPhoneLength = 10;
  static const int maxPhoneLength = 15;

  // User Types
  static const String userTypeUser = 'user';
  static const String userTypeMerchant = 'merchant';

  // Post Types
  static const String postTypeProduct = 'product';
  static const String postTypeOffer = 'offer';
  static const String postTypeAnnouncement = 'announcement';

  // Categories
  static const List<String> categories = [
    'Electronics',
    'Fashion',
    'Home',
    'Sports',
    'Food',
    'Beauty',
  ];

  // Sort Options
  static const List<Map<String, String>> sortOptions = [
    {'key': 'newest', 'label': 'Newest'},
    {'key': 'price_low', 'label': 'Lowest Price'},
    {'key': 'price_high', 'label': 'Highest Price'},
    {'key': 'rating', 'label': 'Top Rated'},
  ];

  // Notification Settings
  static const bool defaultNotifications = true;
  static const bool defaultEmailNotifications = false;
  static const bool defaultSmsNotifications = false;

  // Debug Mode
  static const bool isDebugMode = true; // Set to false in production

  // Log Settings
  static const bool enableLogging = true;
  static const bool enableApiLogging = true;
  static const bool enableErrorLogging = true;
}
