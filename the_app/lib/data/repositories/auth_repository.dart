import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter/foundation.dart';
import '../../core/config/api_config.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  static Future<Map<String, dynamic>> login(
      String usernameOrEmail, String password) async {
    try {
      final tokenResponse = await ApiService.login(usernameOrEmail, password);

      final access = tokenResponse['access'];
      final refresh = tokenResponse['refresh'];

      if (access == null || refresh == null) {
        throw Exception('Tokens not received from server');
      }

      // IMPORTANT: Save tokens BEFORE making any authenticated requests
      await StorageService.saveTokens(
        accessToken: access,
        refreshToken: refresh,
      );

      final decoded = JwtDecoder.decode(access);
      final userId = decoded['user_id'];
      if (userId == null) {
        throw Exception('user_id not found in token');
      }

      // Now fetch profile (token is saved, so ApiService can use it)
      final profileJson = await ApiService.get('${ApiConfig.users}$userId/');

      late final User user;
      try {
        user = User.fromJson(profileJson);
      } catch (e) {
        print('--- FAILED TO PARSE USER FROM JSON ---');
        print('Error: $e');
        print('Received JSON: $profileJson');
        print('------------------------------------');
        throw Exception('Error parsing user data.');
      }

      return {
        'user': user,
        'tokens': {
          'access': access,
          'refresh': refresh,
        },
      };
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  static Future<Map<String, dynamic>> register(
      Map<String, dynamic> data) async {
    try {
      final registrationData = Map<String, dynamic>.from(data)..remove('role');

      final response =
          await ApiService.post(ApiConfig.register, registrationData);

      final access = response['access'];
      final refresh = response['refresh'];
      if (access != null && refresh != null) {
        await StorageService.saveTokens(
            accessToken: access, refreshToken: refresh);
      }

      // Prefer embedded user; otherwise fetch /me/
      final userData = (response['user'] is Map<String, dynamic>)
          ? response['user'] as Map<String, dynamic>
          : (await ApiService.get(ApiConfig.profile) as Map<String, dynamic>);

      final user = User.fromJson(userData);

      return {
        'user': user,
        'tokens': {'access': access, 'refresh': refresh},
      };
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  static Future<void> sendPhoneOtp(String phone) async {
    try {
      await ApiService.sendPhoneOtp(phone);
    } catch (e) {
      throw Exception('Failed to send OTP: $e');
    }
  }

  static Future<Map<String, dynamic>> verifyPhoneOtp({
    required String phone,
    required String code,
    String? name,
  }) async {
    try {
      final response = await ApiService.verifyPhoneOtp(
        phone: phone,
        code: code,
        name: name,
      );

      final access = response['access'];
      final refresh = response['refresh'];
      if (access == null || refresh == null) {
        throw Exception('Tokens not received from server');
      }

      await StorageService.saveTokens(
        accessToken: access,
        refreshToken: refresh,
      );

      final userData = (response['user'] is Map<String, dynamic>)
          ? response['user'] as Map<String, dynamic>
          : (await ApiService.get(ApiConfig.profile) as Map<String, dynamic>);
      final user = User.fromJson(userData);

      return {
        'user': user,
        'tokens': {'access': access, 'refresh': refresh},
        'is_new_user': response['is_new_user'] == true,
      };
    } catch (e) {
      throw Exception('OTP verification failed: $e');
    }
  }

  static Future<User> getProfile() async {
    try {
      // Decode current access token to find the user id, then fetch the profile
      final accessToken = await StorageService.getAccessToken();
      if (accessToken == null) throw Exception('Access token not found');
      final decoded = JwtDecoder.decode(accessToken);
      final userId = decoded['user_id'];
      final response = await ApiService.get('${ApiConfig.users}$userId/');

      try {
        return User.fromJson(response);
      } catch (e) {
        debugPrint('--- FAILED TO PARSE USER FROM JSON (getProfile) ---');
        debugPrint('Error: $e');
        debugPrint('Received JSON: $response');
        debugPrint('------------------------------------');
        throw Exception('Error parsing user data.');
      }
    } catch (e) {
      throw Exception('Failed to load profile: $e');
    }
  }

  static Future<User> updateProfile(Map<String, dynamic> data) async {
    try {
      final accessToken = await StorageService.getAccessToken();
      if (accessToken == null) throw Exception('Access token not found');
      final decoded = JwtDecoder.decode(accessToken);
      final userId = decoded['user_id'];

      final response =
          await ApiService.patch('${ApiConfig.users}$userId/', data);
      return User.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }
}
