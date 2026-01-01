class AppConstants {
  // App Info
  static const String appName = 'DzLocal Shop';
  static const String appVersion = '1.0.0';
  
  // Locales
  static const String arabicLanguageCode = 'ar';
  static const String englishLanguageCode = 'en';
  static const String algeriaCountryCode = 'DZ';
  static const String usCountryCode = 'US';
  
  // Default Values
  static const String defaultLocation = 'الجزائر العاصمة';
  static const String defaultCurrency = 'دج';
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;
  
  // Timer Values (for Hot Deals)
  static const int hotDealTimerHours = 2;
  static const int hotDealTimerMinutes = 45;
  static const int hotDealTimerSeconds = 30;
  
  // Filters
  static const String filterRecommended = 'recommended';
  static const String filterNearby = 'nearby';
  static const String filterTopRated = 'top_rated';
  
  // Category IDs
  static const String categoryElectronics = 'electronics';
  static const String categoryFashion = 'fashion';
  static const String categoryHome = 'home';
  static const String categorySports = 'sports';
  
  // Product Status
  static const String statusAvailable = 'available';
  static const String statusOutOfStock = 'out_of_stock';
  static const String statusComingSoon = 'coming_soon';
  
  // Store Status
  static const String storeOpen = 'open';
  static const String storeClosed = 'closed';
  
  // Navigation Indices
  static const int navExplore = 0;
  static const int navOffers = 1;
  static const int navHome = 2;
  static const int navMessages = 3;
  static const int navProfile = 4;
  
  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;
  static const int minPhoneLength = 10;
  static const int maxPhoneLength = 15;
  
  // Network
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000;
  
  // Cache
  static const int cacheMaxAge = 3600; // 1 hour in seconds
  
  // Messages
  static const String errorGeneric = 'حدث خطأ ما، يرجى المحاولة مرة أخرى';
  static const String errorNetwork = 'تحقق من اتصالك بالإنترنت';
  static const String errorNotFound = 'لم يتم العثور على النتائج';
  static const String successGeneric = 'تمت العملية بنجاح';
  
  // Search
  static const String searchHint = 'ابحث عن المنتجات، المتاجر...';
  static const int minSearchLength = 2;
  static const int searchDebounceMilliseconds = 500;
}