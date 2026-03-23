import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class StorageService {
  static SharedPreferences? _prefs;
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Storage Keys (for SharedPreferences - non-sensitive data)
  static const String keyUserData = 'user_data';
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyUserType = 'user_type';
  static const String keyLanguage = 'language';
  static const String keyTheme = 'theme';
  static const String keyFirstTime = 'first_time';
  static const String keyLastCategories = 'last_categories';
  static const String keyLastNotifiedNotificationId =
      'last_notified_notification_id';
  static const String keySeenNearbyEducation = 'seen_nearby_education';
  static const String keySeenStoreGpsEducation = 'seen_store_gps_education';

  // Secure Storage Keys (for tokens - sensitive data)
  static const String _secureKeyAccessToken = 'secure_access_token';
  static const String _secureKeyRefreshToken = 'secure_refresh_token';

  // Initialize
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('StorageService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // ==================== TOKEN MANAGEMENT (SECURE) ====================

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _secureStorage.write(key: _secureKeyAccessToken, value: accessToken);
    await _secureStorage.write(
        key: _secureKeyRefreshToken, value: refreshToken);
  }

  static Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _secureKeyAccessToken);
  }

  static Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _secureKeyRefreshToken);
  }

  static Future<void> clearTokens() async {
    try {
      await _secureStorage.delete(key: _secureKeyAccessToken);
      await _secureStorage.delete(key: _secureKeyRefreshToken);
    } catch (e) {
      debugPrint('Error clearing tokens: $e');
    }
  }

  // ==================== USER DATA (SharedPreferences) ====================

  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    await prefs.setString(keyUserData, jsonEncode(userData));
    await prefs.setBool(keyIsLoggedIn, true);
    await prefs.setString(keyUserType, userData['user_type'] ?? 'user');
  }

  static Map<String, dynamic>? getUserData() {
    final data = prefs.getString(keyUserData);
    if (data != null) {
      return jsonDecode(data);
    }
    return null;
  }

  static int? getUserId() {
    final userData = getUserData();
    if (userData != null) {
      final id = userData['id'];
      if (id is int) return id;
      if (id is String) return int.tryParse(id);
    }
    return null;
  }

  static Future<void> clearUserData() async {
    await prefs.remove(keyUserData);
    await prefs.setBool(keyIsLoggedIn, false);
    await prefs.remove(keyUserType);
  }

  // ==================== LOGIN STATUS ====================

  static bool isLoggedIn() {
    return prefs.getBool(keyIsLoggedIn) ?? false;
  }

  static String getUserType() {
    return prefs.getString(keyUserType) ?? 'user';
  }

  static bool isMerchant() {
    return getUserType() == 'merchant';
  }

  // ==================== LANGUAGE ====================

  static Future<void> saveLanguage(String language) async {
    await prefs.setString(keyLanguage, language);
  }

  static String getLanguage() {
    return prefs.getString(keyLanguage) ?? 'ar';
  }

  // ==================== LAST CATEGORIES ====================

  /// Save user's last viewed categories for store recommendations
  static Future<void> saveLastCategories(List<String> categories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
          'last_categories', categories.take(10).toList());
    } catch (e) {
      debugPrint('Failed to save last categories: $e');
    }
  }

  /// Get user's last viewed categories
  static List<String> getLastCategories() {
    try {
      return prefs.getStringList('last_categories') ?? <String>[];
    } catch (e) {
      debugPrint('Failed to get last categories: $e');
      return <String>[];
    }
  }

  // Make getLastCategories synchronous for immediate use
  static List<String> getLastCategoriesSync() {
    try {
      // This is a simplified version - in practice you'd cache this
      return <String>[]; // Fallback for now
    } catch (e) {
      return <String>[];
    }
  }

  // ==================== NOTIFICATION SYNC ====================

  static int getLastNotifiedNotificationId() {
    return prefs.getInt(keyLastNotifiedNotificationId) ?? 0;
  }

  static Future<void> setLastNotifiedNotificationId(int id) async {
    await prefs.setInt(keyLastNotifiedNotificationId, id);
  }

  // ==================== FIRST TIME ====================

  static bool isFirstTime() {
    return prefs.getBool(keyFirstTime) ?? true;
  }

  static Future<void> setNotFirstTime() async {
    await prefs.setBool(keyFirstTime, false);
  }

  static bool hasSeenNearbyEducation() {
    return prefs.getBool(keySeenNearbyEducation) ?? false;
  }

  static Future<void> setSeenNearbyEducation() async {
    await prefs.setBool(keySeenNearbyEducation, true);
  }

  static bool hasSeenStoreGpsEducation() {
    return prefs.getBool(keySeenStoreGpsEducation) ?? false;
  }

  static Future<void> setSeenStoreGpsEducation() async {
    await prefs.setBool(keySeenStoreGpsEducation, true);
  }

  // ==================== CLEAR ALL ====================

  static Future<void> clearAll() async {
    await clearTokens();
    await prefs.clear();
  }

  // ==================== LOGOUT ====================

  static Future<void> logout() async {
    await clearTokens();
    await clearUserData();
  }
}
