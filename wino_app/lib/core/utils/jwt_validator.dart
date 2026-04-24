import 'dart:convert';
import 'package:flutter/foundation.dart';

class JWTValidator {
  /// Decode JWT payload WITHOUT signature verification
  /// This is SAFE for reading claims but NOT for security validation
  static Map<String, dynamic>? decodePayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      
      return jsonDecode(decoded);
    } catch (e) {
      debugPrint('JWT decode error: $e');
      return null;
    }
  }
  
  /// Check if token is expired based on 'exp' claim
  static bool isExpired(String token) {
    final payload = decodePayload(token);
    if (payload == null) return true;
    
    final exp = payload['exp'] as int?;
    if (exp == null) return true;
    
    final expirationDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    final now = DateTime.now();
    
    return expirationDate.isBefore(now);
  }
  
  /// Check if token expires soon (within specified duration)
  static bool expiresSoon(String token, {Duration buffer = const Duration(minutes: 5)}) {
    final payload = decodePayload(token);
    if (payload == null) return true;
    
    final exp = payload['exp'] as int?;
    if (exp == null) return true;
    
    final expirationDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    final now = DateTime.now();
    
    return expirationDate.isBefore(now.add(buffer));
  }
  
  /// Extract user ID from token
  static String? getUserId(String token) {
    final payload = decodePayload(token);
    return payload?['user_id']?.toString();
  }
  
  /// Extract user email from token
  static String? getUserEmail(String token) {
    final payload = decodePayload(token);
    return payload?['email']?.toString();
  }
  
  /// Get token expiration date
  static DateTime? getExpirationDate(String token) {
    final payload = decodePayload(token);
    if (payload == null) return null;
    
    final exp = payload['exp'] as int?;
    if (exp == null) return null;
    
    return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
  }
  
  /// Get issued at date
  static DateTime? getIssuedAt(String token) {
    final payload = decodePayload(token);
    if (payload == null) return null;
    
    final iat = payload['iat'] as int?;
    if (iat == null) return null;
    
    return DateTime.fromMillisecondsSinceEpoch(iat * 1000);
  }
}
