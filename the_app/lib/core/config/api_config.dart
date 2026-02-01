import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Base URL
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://127.0.0.1:8000';
  }

  // API prefix
  static const String api = '/api';

  // Auth
  static const String authToken = '$api/auth/token/';
  static const String authRefresh = '$api/auth/token/refresh/';
  static const String authRegister = '$api/users/register/';
  static const String authMe = '$api/users/me/';
  static const String authChangePassword = '$api/users/change-password/';
  static const String authLogout = '$api/users/logout/';

  // Users
  static const String users = '$api/users/users/';
  static String userDetail(int id) => '$users$id/';

  // Stores
  static const String stores = '$api/stores/stores/';
  static String storeDetail(int id) => '$stores$id/';
  static const String followers = '$api/stores/followers/';
  static const String followersToggle = '$api/stores/followers/toggle/';
  static String followersCheck(int storeId) => '$api/stores/followers/check/$storeId/';

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
  static String reviewsMyStoreRating(int storeId) => '$catalog/reviews/my-store-rating/$storeId/';
  static const String favorites = '$catalog/favorites/';
  static const String favoritesToggle = '$catalog/favorites/toggle/';

  // Promotions
  static const String promotions = '$api/promotions/promotions/';
  static const String promotionImages = '$api/promotions/promotion-images/';

  // Messaging & Notifications
  static const String messages = '$api/messaging/messages/';
  static const String notifications = '$api/notifications/notifications/';
  static const String devices = '$api/notifications/devices/';

  // Subscriptions
  static const String subscriptionPlans = '$api/subscriptions/plans/';
  static const String merchantSubscriptions = '$api/subscriptions/merchant-subscriptions/';

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
