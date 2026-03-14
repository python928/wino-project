import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Base URL
  static String get baseUrl {
    if (kIsWeb) return 'http://192.168.164.21:8000/';
    if (Platform.isAndroid) return 'http://192.168.164.21:8000/';
    return 'http://192.168.164.21:8000/';
  }

  // API prefix
  static const String api = '/api';

  // Auth
  static const String authToken = '$api/auth/token/';
  static const String authRefresh = '$api/auth/token/refresh/';

  // Users API (backend: path('api/users/', include('users.urls')))
  static const String register = '$api/users/register/';
  static const String profile = '$api/users/me/';

  static const String authMe = profile;
  static const String authChangePassword = '$api/users/change-password/';
  static const String authLogout = '$api/users/logout/';
  static const String preferredCategories =
      '$api/users/preferences/categories/';

  // Users
  static const String users = '$api/users/users/';
  static String userDetail(int id) => '$users$id/';

  // Stores (alias: store == user)
  static const String stores = users;
  static String storeDetail(int id) => userDetail(id);

  // Followers (backend: /api/users/followers/ and /api/users/followers/toggle/)
  static const String followers = '$api/users/followers/';
  static String followersToggle = '$api/users/followers/toggle/';
  static String followersCheck(int userId) =>
      '$api/users/followers/?user=$userId';
  static const String storeReports = '$api/users/store-reports/';

  // Catalog
  static const String catalog = '$api/catalog';
  static const String categories = '$catalog/categories/';
  static const String products = '$catalog/products/';
  static String productDetail(int id) => '$catalog/products/$id/';
  static const String productImages = '$catalog/product-images/';
  static const String packs = '$catalog/packs/';
  static const String packProducts = '$catalog/pack-products/';
  static const String packImages = '$catalog/pack-images/';
  static const String reviews = '$catalog/reviews/';
  static const String reviewsRateStore = '$catalog/reviews/rate-store/';
  static String reviewsMyStoreRating(int storeId) =>
      '$catalog/reviews/my-store-rating/$storeId/';
  static const String favorites = '$catalog/favorites/';
  static const String favoritesToggle = '$catalog/favorites/toggle/';
  static String favoritesCheck(int productId) =>
      '$catalog/favorites/check/$productId/';

  // Promotions (now in catalog)
  static const String promotions = '$catalog/promotions/';
  static const String promotionImages = '$catalog/promotion-images/';
  static const String productReports = '$catalog/product-reports/';

  // Analytics
  static const String analyticsRecommendations = '$api/analytics/recommendations/';
  static const String analyticsEvents = '$api/analytics/events/';

  // Notifications
  // ✅ Use path-only constants (no baseUrl prefix) — ApiService prepends baseUrl
  static const String notifications = '/api/notifications/notifications/';
  static const String notificationsMarkAllRead =
      '/api/notifications/notifications/mark-all-read/';
  static const String notificationsUnreadCount =
      '/api/notifications/notifications/unread-count/';
  static const String notificationsTrigger =
      '$api/notifications/notifications/trigger/';
  static const String devices = '$api/notifications/devices/';

  // Subscriptions
  static const String subscriptionPlans = '$api/subscriptions/plans/';
  static const String subscriptionPublicData =
      '$api/subscriptions/plans/public-data/';
  static const String merchantSubscriptions =
      '$api/subscriptions/merchant-subscriptions/';
  static const String subscriptionPaymentRequests =
      '$api/subscriptions/payment-requests/';
  static const String subscriptionAccessStatus =
      '$merchantSubscriptions/access-status/';
  static const String subscriptionMerchantDashboard =
      '$merchantSubscriptions/merchant-dashboard/';

  // Media URL
  static String get mediaUrl => '$baseUrl/media';
  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;

    // Handle paths that might already start with /media/ or media/
    if (path.startsWith('/media/')) {
      return '$baseUrl$path';
    }
    if (path.startsWith('media/')) {
      return '$baseUrl/$path';
    }

    // Default case: assume it's a relative path inside media root
    // But wait, Django usually returns /media/xyz.jpg
    // If the path is just "products/image.jpg", we prepend mediaUrl
    return '$mediaUrl/$path';
  }

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Headers
  static Map<String, String> getHeaders({String? token}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  static Map<String, String> getMultipartHeaders({String? token}) {
    final headers = {
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }
}
