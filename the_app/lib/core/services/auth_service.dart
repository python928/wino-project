import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../config/api_config.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthService {
  // No longer needed: _secureStorage local instance
  // No longer needed: _keyAccessToken, _keyRefreshToken local keys
  static const String _keyTokenExpiry = 'token_expiry_timestamp';
  
  /// Save tokens securely
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      if (JwtDecoder.isExpired(accessToken)) {
        throw Exception('Access token is already expired');
      }
      
      final expiryDate = JwtDecoder.getExpirationDate(accessToken);
      final expiryTimestamp = expiryDate.millisecondsSinceEpoch;
      
      await StorageService.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyTokenExpiry, expiryTimestamp);
      
      debugPrint('✅ Tokens saved via StorageService');
    } catch (e) {
      debugPrint('❌ Error saving tokens: $e');
      rethrow;
    }
  }
  
  /// Get access token
  static Future<String?> getAccessToken() async {
    return await StorageService.getAccessToken();
  }
  
  /// Get refresh token
  static Future<String?> getRefreshToken() async {
    return await StorageService.getRefreshToken();
  }
  
  /// Clear all tokens
  static Future<void> clearTokens() async {
    await StorageService.clearTokens();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyTokenExpiry);
  }
  
  /// Check if access token is valid (locally)
  static Future<bool> isAccessTokenValid() async {
    try {
      final token = await getAccessToken();
      if (token == null || token.isEmpty) return false;
      
      if (JwtDecoder.isExpired(token)) {
        debugPrint('⚠️ Access token expired');
        return false;
      }
      
      final decoded = JwtDecoder.decode(token);
      if (decoded['user_id'] == null) {
        debugPrint('⚠️ Invalid token structure');
        return false;
      }
      
      return true;
    } catch (e) {
      debugPrint('❌ Token validation error: $e');
      return false;
    }
  }
  
  /// Check if we need to refresh (5 min before expiry)
  static Future<bool> shouldRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expiryTimestamp = prefs.getInt(_keyTokenExpiry);
      
      if (expiryTimestamp == null) return true;
      
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);
      final now = DateTime.now();
      
      final difference = expiryDate.difference(now);
      return difference.inMinutes < 5;
    } catch (e) {
      return true;
    }
  }
  
  /// Extract user data from token (offline)
  static Future<Map<String, dynamic>?> getUserDataFromToken() async {
    try {
      final token = await getAccessToken();
      if (token == null) return null;
      
      final decoded = JwtDecoder.decode(token);
      return {
        'user_id': decoded['user_id'],
        'email': decoded['email'],
        'user_type': decoded['user_type'],
        'name': decoded['name'],
      };
    } catch (e) {
      debugPrint('❌ Error extracting user data: $e');
      return null;
    }
  }
  
  /// Check if user is logged in (offline check)
  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    if (token == null) return false;
    return await isAccessTokenValid();
  }

  /// Logout - clear all tokens
  static Future<void> logout() async {
    await clearTokens();
    debugPrint('✅ User logged out');
  }
  
  /// Register a new user
  static Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final response = await ApiService.post(ApiConfig.register, {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone ?? '',
      });

      final accessToken = response['access'];
      final refreshToken = response['refresh'];
      if (accessToken == null || refreshToken == null) {
        throw Exception('Tokens not returned by server');
      }

      await saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      debugPrint('✅ Registration successful');
      return true;
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }
}
