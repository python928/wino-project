import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../config/api_config.dart';
import '../utils/app_logger.dart';
import '../utils/jwt_validator.dart';
import 'storage_service.dart';

enum ApiErrorType { network, timeout, unauthorized, validation, server, unknown }

class ApiException implements Exception {
  final ApiErrorType type;
  final String message;
  final int? statusCode;

  ApiException(this.type, this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  static DateTime? _lastRefreshAttempt;
  static bool _refreshTokenInvalid = false;
  static int _consecutiveRefreshServerErrors = 0;
  static Future<bool>? _ongoingRefresh;

  // ==================== PUBLIC METHODS WITH AUTO-RETRY ====================

  static Future<dynamic> get(String endpoint) async {
    return await _requestWithRetry(() => _get(endpoint));
  }

  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    return await _requestWithRetry(() => _post(endpoint, data));
  }

  static Future<dynamic> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    return await _requestWithRetry(() => _put(endpoint, data));
  }

  static Future<dynamic> patch(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    return await _requestWithRetry(() => _patch(endpoint, data));
  }

  static Future<dynamic> delete(String endpoint) async {
    return await _requestWithRetry(() => _delete(endpoint));
  }

  // ==================== AUTHENTICATION METHODS (NO TOKEN) ====================

  static Future<Map<String, dynamic>> register(
      Map<String, dynamic> data) async {
    try {
      final uri = _buildUri(ApiConfig.register);

      final response = await http
          .post(
            uri,
            headers: ApiConfig.getHeaders(), // No token
            body: jsonEncode(data),
          )
          .timeout(ApiConfig.connectionTimeout);

      return _handleResponse(response, treat401AsSessionExpired: false);
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> login(
      String usernameOrEmail, String password) async {
    try {
      final data = {
        // SimpleJWT expects the username field. Backend accepts username and we
        // allow users to type either username or email in the same box.
        'username': usernameOrEmail,
        'password': password,
      };

      final uri = _buildUri(ApiConfig.authToken);

      final response = await http
          .post(
            uri,
            headers: ApiConfig.getHeaders(), // No token
            body: jsonEncode(data),
          )
          .timeout(ApiConfig.connectionTimeout);

      return _handleResponse(response, treat401AsSessionExpired: false);
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> sendPhoneOtp(String phone) async {
    try {
      final uri = _buildUri('/api/users/auth/phone/send-otp/');
      final response = await http
          .post(
            uri,
            headers: ApiConfig.getHeaders(),
            body: jsonEncode({'phone': phone}),
          )
          .timeout(ApiConfig.connectionTimeout);
      return _handleResponse(response, treat401AsSessionExpired: false);
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> verifyPhoneOtp({
    required String phone,
    required String code,
    String? name,
  }) async {
    try {
      final uri = _buildUri('/api/users/auth/phone/verify-otp/');
      final payload = <String, dynamic>{
        'phone': phone,
        'code': code,
      };
      if (name != null && name.trim().isNotEmpty) {
        payload['name'] = name.trim();
      }
      final response = await http
          .post(
            uri,
            headers: ApiConfig.getHeaders(),
            body: jsonEncode(payload),
          )
          .timeout(ApiConfig.connectionTimeout);
      return _handleResponse(response, treat401AsSessionExpired: false);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Change password for authenticated user
  static Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final token = await StorageService.getAccessToken();
      final uri = _buildUri(ApiConfig.authChangePassword);

      final response = await http
          .post(
            uri,
            headers: ApiConfig.getHeaders(token: token),
            body: jsonEncode({
              'old_password': oldPassword,
              'new_password': newPassword,
              'confirm_password': confirmPassword,
            }),
          )
          .timeout(ApiConfig.connectionTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Logout and invalidate refresh token
  static Future<void> logout() async {
    try {
      final token = await StorageService.getAccessToken();
      final refreshToken = await StorageService.getRefreshToken();

      if (token != null && refreshToken != null) {
        final uri = _buildUri(ApiConfig.authLogout);

        await http
            .post(
              uri,
              headers: ApiConfig.getHeaders(token: token),
              body: jsonEncode({'refresh': refreshToken}),
            )
            .timeout(ApiConfig.connectionTimeout);
      }
    } catch (e) {
      AppLogger.error('Logout API call failed', error: e);
      // Continue with local logout even if API fails
    } finally {
      await StorageService.logout();
      _refreshTokenInvalid = false;
    }
  }

  /// Get current user profile
  static Future<Map<String, dynamic>> getMe() async {
    return await get(ApiConfig.authMe);
  }

  /// Update current user profile
  static Future<Map<String, dynamic>> updateMe(
      Map<String, dynamic> data) async {
    return await patch(ApiConfig.authMe, data);
  }

  /// Send FCM token to backend
  static Future<void> updateFcmToken(String token) async {
    try {
      final uri = _buildUri(ApiConfig.devices);
      final accessToken = await StorageService.getAccessToken();
      if (accessToken == null) return;

      await http
          .post(
            uri,
            headers: ApiConfig.getHeaders(token: accessToken),
            body: jsonEncode({
              'registration_id': token,
              'type': kIsWeb
                  ? 'web'
                  : (defaultTargetPlatform == TargetPlatform.iOS
                      ? 'ios'
                      : 'android'),
            }),
          )
          .timeout(ApiConfig.connectionTimeout);
      AppLogger.success('FCM token sent to backend');
    } catch (e) {
      AppLogger.error('Failed to send FCM token to backend', error: e);
    }
  }

  // ==================== TOKEN REFRESH ====================

  static Future<bool> refreshToken() async {
    if (_ongoingRefresh != null) {
      return _ongoingRefresh!;
    }

    final future = _doRefreshToken();
    _ongoingRefresh = future;
    try {
      return await future;
    } finally {
      _ongoingRefresh = null;
    }
  }

  static Future<bool> _doRefreshToken() async {
    try {
      // Avoid spamming refresh endpoint
      final now = DateTime.now();
      if (_lastRefreshAttempt != null &&
          now.difference(_lastRefreshAttempt!) < const Duration(seconds: 30)) {
        return false;
      }
      _lastRefreshAttempt = now;

      // If refresh token already proved invalid, don't retry until user logs in again
      if (_refreshTokenInvalid) return false;

      final refreshToken = await StorageService.getRefreshToken();
      if (refreshToken == null) {
        _refreshTokenInvalid = true;
        return false;
      }

      final uri = _buildUri(ApiConfig.authRefresh);
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh': refreshToken}),
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        // Save new access token
        await StorageService.saveTokens(
          accessToken: data['access'],
          refreshToken: refreshToken, // Keep same refresh token
        );

        AppLogger.success('Token refreshed successfully');
        _refreshTokenInvalid = false;
        _consecutiveRefreshServerErrors = 0;
        return true;
      }

      AppLogger.error('Token refresh failed', error: response.statusCode);

      // If backend is erroring (e.g. migrations not applied yet), don't spam refresh.
      if (response.statusCode >= 500) {
        _consecutiveRefreshServerErrors += 1;
        if (_consecutiveRefreshServerErrors >= 3) {
          // Back off for a bit after repeated server failures.
          _lastRefreshAttempt = DateTime.now();
        }
        return false;
      }

      // If refresh token is invalid/expired, clear tokens to prevent infinite retries
      if (response.statusCode == 401 || response.statusCode == 400) {
        _refreshTokenInvalid = true;
        await StorageService.logout();
      }
      return false;
    } catch (e) {
      AppLogger.error('Token refresh error', error: e);
      return false;
    }
  }

  /// Proactively refresh token if it expires soon
  static Future<void> proactiveRefreshIfNeeded() async {
    final accessToken = await StorageService.getAccessToken();
    if (accessToken == null) return;

    // Check if token expires in next 5 minutes
    if (JWTValidator.expiresSoon(accessToken,
        buffer: const Duration(minutes: 5))) {
      AppLogger.info('Access token expires soon, proactively refreshing...');
      await refreshToken();
    }
  }

  // ==================== PRIVATE METHODS ====================

  /// Wrapper that handles token refresh automatically
  static Future<dynamic> _requestWithRetry(
    Future<dynamic> Function() request,
  ) async {
    try {
      // First attempt
      return await request();
    } catch (e) {
      // Check if it's a 401 Unauthorized error
        final isUnauthorized =
          (e is ApiException && e.type == ApiErrorType.unauthorized) ||
            e.toString().contains('401') ||
            e.toString().contains('Session expired') ||
            e.toString().contains('Unauthorized');
        if (isUnauthorized) {
        AppLogger.info('Token expired, attempting refresh...');

        // Try to refresh token
        final refreshed = await refreshToken();

        if (refreshed) {
          // Retry request with new token
          AppLogger.success('Retrying request with new token...');
          return await request();
        } else {
          // Refresh failed - logout
          AppLogger.error('Token refresh failed, logging out');
          await StorageService.logout();
          throw Exception('Session expired. Please login again.');
        }
      }
      rethrow;
    }
  }

  // ==================== HTTP METHODS (PRIVATE) ====================

  static Future<dynamic> _get(String endpoint) async {
    try {
      final token = await StorageService.getAccessToken();
      final uri = _buildUri(endpoint);

      final response = await http
          .get(
            uri,
            headers: ApiConfig.getHeaders(token: token),
          )
          .timeout(ApiConfig.connectionTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<dynamic> _post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final token = await StorageService.getAccessToken();
      final uri = _buildUri(endpoint);

      final response = await http
          .post(
            uri,
            headers: ApiConfig.getHeaders(token: token),
            body: jsonEncode(data),
          )
          .timeout(ApiConfig.connectionTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<dynamic> _put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final token = await StorageService.getAccessToken();
      final uri = _buildUri(endpoint);

      final response = await http
          .put(
            uri,
            headers: ApiConfig.getHeaders(token: token),
            body: jsonEncode(data),
          )
          .timeout(ApiConfig.connectionTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<dynamic> _patch(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final token = await StorageService.getAccessToken();
      final uri = _buildUri(endpoint);

      final response = await http
          .patch(
            uri,
            headers: ApiConfig.getHeaders(token: token),
            body: jsonEncode(data),
          )
          .timeout(ApiConfig.connectionTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<dynamic> _delete(String endpoint) async {
    try {
      final token = await StorageService.getAccessToken();
      final uri = _buildUri(endpoint);

      final response = await http
          .delete(
            uri,
            headers: ApiConfig.getHeaders(token: token),
          )
          .timeout(ApiConfig.connectionTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<dynamic> postMultipart(
    String endpoint,
    Map<String, String> fields,
    XFile? imageFile,
    String? imageFieldName,
  ) async {
    return await _requestWithRetry(
        () => _postMultipart(endpoint, fields, imageFile, imageFieldName));
  }

  static Future<dynamic> postMultipartMany(
    String endpoint,
    Map<String, String> fields,
    List<XFile> imageFiles, {
    String fieldName = 'images',
  }) async {
    return await _requestWithRetry(
        () => _postMultipartMany(endpoint, fields, imageFiles, fieldName));
  }

  // ==================== UPLOAD IMAGE ====================

  static Future<dynamic> uploadImage(
    String endpoint,
    XFile imageFile,
    String fieldName,
  ) async {
    try {
      final token = await StorageService.getAccessToken();
      final uri = _buildUri(endpoint);

      var request = http.MultipartRequest('POST', uri);
      request.headers.addAll(ApiConfig.getHeaders(token: token));

      final bytes = await imageFile.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          fieldName,
          bytes,
          filename: imageFile.name,
        ),
      );

      final streamedResponse =
          await request.send().timeout(ApiConfig.connectionTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<dynamic> _postMultipart(
    String endpoint,
    Map<String, String> fields,
    XFile? imageFile,
    String? imageFieldName,
  ) async {
    try {
      final token = await StorageService.getAccessToken();
      final uri = _buildUri(endpoint);
      AppLogger.info('ApiService: POST Multipart to $uri');

      var request = http.MultipartRequest('POST', uri);
      request.headers.addAll(ApiConfig.getMultipartHeaders(token: token));
      AppLogger.info('ApiService: Headers: ${request.headers}');

      request.fields.addAll(fields);
      AppLogger.info('ApiService: Fields: $fields');

      if (imageFile != null && imageFieldName != null) {
        AppLogger.info('ApiService: Adding image file: ${imageFile.name}');
        final bytes = await imageFile.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            imageFieldName,
            bytes,
            filename: imageFile.name,
          ),
        );
      }

      AppLogger.info('ApiService: Sending request...');
      final streamedResponse =
          await request.send().timeout(ApiConfig.connectionTimeout);
      final response = await http.Response.fromStream(streamedResponse);
      AppLogger.info('ApiService: Response status: ${response.statusCode}');
      AppLogger.info('ApiService: Response body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      AppLogger.error('ApiService: Error', error: e);
      throw _handleError(e);
    }
  }

  static Future<dynamic> _postMultipartMany(
    String endpoint,
    Map<String, String> fields,
    List<XFile> imageFiles,
    String fieldName,
  ) async {
    try {
      final token = await StorageService.getAccessToken();
      final uri = _buildUri(endpoint);
      AppLogger.info('ApiService: POST MultipartMany to $uri');

      var request = http.MultipartRequest('POST', uri);
      request.headers.addAll(ApiConfig.getMultipartHeaders(token: token));
      request.fields.addAll(fields);

      for (final imageFile in imageFiles) {
        final bytes = await imageFile.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            fieldName,
            bytes,
            filename: imageFile.name,
          ),
        );
      }

      final streamedResponse =
          await request.send().timeout(ApiConfig.connectionTimeout);
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      AppLogger.error('ApiService: MultipartMany Error', error: e);
      throw _handleError(e);
    }
  }

  static Future<dynamic> updateMultipart(
    String endpoint,
    Map<String, String> fields,
    XFile? imageFile,
    String? imageFieldName, {
    String method = 'PUT',
  }) async {
    return await _requestWithRetry(() => _updateMultipart(
        endpoint, fields, imageFile, imageFieldName,
        method: method));
  }

  static Future<dynamic> _updateMultipart(
    String endpoint,
    Map<String, String> fields,
    XFile? imageFile,
    String? imageFieldName, {
    String method = 'PUT',
  }) async {
    try {
      final token = await StorageService.getAccessToken();
      final uri = _buildUri(endpoint);
      AppLogger.info('ApiService: $method Multipart to $uri');

      var request = http.MultipartRequest(method, uri);
      request.headers.addAll(ApiConfig.getMultipartHeaders(token: token));

      request.fields.addAll(fields);

      if (imageFile != null && imageFieldName != null) {
        final bytes = await imageFile.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            imageFieldName,
            bytes,
            filename: imageFile.name,
          ),
        );
      }

      final streamedResponse =
          await request.send().timeout(ApiConfig.connectionTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== RESPONSE/ERROR HANDLING ====================

  static dynamic _handleResponse(
    http.Response response, {
    bool treat401AsSessionExpired = true,
  }) {
    final statusCode = response.statusCode;

    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isEmpty) {
        return {'success': true};
      }
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else if (statusCode == 401) {
      // For authenticated calls this usually means token expired/invalid.
      // For auth endpoints (login/register) we want to surface the backend message instead.
      if (treat401AsSessionExpired) {
        throw ApiException(
          ApiErrorType.unauthorized,
          'Session expired. Please login again.',
          statusCode: 401,
        );
      }
      final body = utf8.decode(response.bodyBytes);
      try {
        final error = jsonDecode(body);
        if (error is Map<String, dynamic>) {
          if (error.containsKey('detail')) {
            throw ApiException(ApiErrorType.unauthorized, '${error['detail']}', statusCode: 401);
          }
          if (error.containsKey('message')) {
            throw ApiException(ApiErrorType.unauthorized, '${error['message']}', statusCode: 401);
          }
          if (error.containsKey('error')) {
            throw ApiException(ApiErrorType.unauthorized, '${error['error']}', statusCode: 401);
          }
        }
        throw ApiException(ApiErrorType.unauthorized, body, statusCode: 401);
      } catch (e) {
        if (e is FormatException) {
          throw ApiException(ApiErrorType.unauthorized, 'Request failed: $body', statusCode: 401);
        }
        rethrow;
      }
    } else if (statusCode >= 400 && statusCode < 500) {
      final body = utf8.decode(response.bodyBytes);
      try {
        final error = jsonDecode(body);
        if (error is Map<String, dynamic>) {
          if (error.containsKey('error')) throw ApiException(ApiErrorType.validation, '${error['error']}', statusCode: statusCode);
          if (error.containsKey('message')) throw ApiException(ApiErrorType.validation, '${error['message']}', statusCode: statusCode);
          if (error.containsKey('detail')) throw ApiException(ApiErrorType.validation, '${error['detail']}', statusCode: statusCode);

          // If it's a list of errors (DRF standard)
          final buffer = StringBuffer();
          error.forEach((key, value) {
            final isNonField =
                key == 'non_field_errors' || key == '__all__' || key == 'non_field_error';
            if (value is List) {
              final line = value.map((v) => v.toString()).join(', ');
              buffer.writeln(isNonField ? line : '$key: $line');
            } else {
              final line = value.toString();
              buffer.writeln(isNonField ? line : '$key: $line');
            }
          });
          if (buffer.isNotEmpty) {
            throw ApiException(ApiErrorType.validation, buffer.toString().trim(), statusCode: statusCode);
          }
        }
        throw ApiException(ApiErrorType.validation, body, statusCode: statusCode);
      } catch (e) {
        if (e is FormatException) {
          throw ApiException(ApiErrorType.validation, 'Request failed: $body', statusCode: statusCode);
        }
        rethrow;
      }
    } else {
      throw ApiException(ApiErrorType.server, 'Server error. Please try again later.', statusCode: statusCode);
    }
  }

  static Exception _handleError(dynamic error) {
    AppLogger.error('ApiService error', error: error);
    if (error is ApiException) return error;
    final msg = error.toString();
    if (msg.contains('SocketException') ||
        msg.contains('Failed host lookup') ||
        msg.contains('Connection refused')) {
      return ApiException(ApiErrorType.network, 'No internet connection or server is unreachable');
    } else if (msg.contains('TimeoutException') || msg.contains('timed out')) {
      return ApiException(ApiErrorType.timeout, 'Connection timed out. Please try again.');
    } else if (msg.contains('FormatException')) {
      return ApiException(ApiErrorType.unknown, 'Invalid response format from server');
    }
    // Re-wrap anything else so it's always an Exception
    if (error is Exception) return error;
    return Exception(msg);
  }

  static Uri _buildUri(String endpoint) {
    if (endpoint.startsWith('http://') || endpoint.startsWith('https://')) {
      return Uri.parse(endpoint);
    }
    final base = ApiConfig.baseUrl;
    final baseTrim = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final endpointTrim =
        endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return Uri.parse('$baseTrim/$endpointTrim');
  }
}
