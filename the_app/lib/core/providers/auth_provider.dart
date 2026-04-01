import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _lastPhoneAuthIsNewUser = false;

  AuthProvider() {
    _loadUserFromStorage();
  }

  Future<void> _syncFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await ApiService.updateFcmToken(token);
      }
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        ApiService.updateFcmToken(newToken);
      });
    } catch (e) {
      debugPrint('Error syncing FCM token: $e');
    }
  }

  void _loadUserFromStorage() {
    if (!StorageService.isLoggedIn()) {
      _user = null;
      return;
    }
    final userData = StorageService.getUserData();
    if (userData != null) {
      try {
        _user = User.fromJson(userData);
      } catch (e) {
        print('AuthProvider: Error parsing user from storage: $e');
      }
    }
  }

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get lastPhoneAuthIsNewUser => _lastPhoneAuthIsNewUser;

  /// Reload user data from storage
  void reloadFromStorage() {
    if (!StorageService.isLoggedIn()) {
      _user = null;
      notifyListeners();
      return;
    }
    final userData = StorageService.getUserData();
    if (userData != null) {
      try {
        _user = User.fromJson(userData);
        notifyListeners();
      } catch (e) {
        print('AuthProvider: Error reloading user from storage: $e');
      }
    } else {
      _user = null;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('AuthProvider: Calling AuthRepository.login...');
      final response = await AuthRepository.login(email, password);
      print('AuthProvider: AuthRepository.login returned successfully.');

      final userObj = response['user'];

      if (userObj is User) {
        _user = userObj;
      } else {
        print(
            'AuthProvider: Warning - user object is not of type User, trying fromJson...');
        _user = User.fromJson(userObj);
      }

      print('AuthProvider: User parsed successfully: ${_user?.username}');

      await StorageService.saveUserData(_user!.toJson());
      _syncFcmToken();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      print('AuthProvider: Login Error: $e');
      print('AuthProvider: StackTrace: $stackTrace');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendPhoneOtp(String phone) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await AuthRepository.sendPhoneOtp(phone);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyPhoneOtp({
    required String phone,
    required String code,
    String? name,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await AuthRepository.verifyPhoneOtp(
        phone: phone,
        code: code,
        name: name,
      );
      _lastPhoneAuthIsNewUser = response['is_new_user'] == true;
      final userObj = response['user'];
      _user = userObj is User ? userObj : User.fromJson(userObj);
      await StorageService.saveUserData(_user!.toJson());
      await StorageService.setPhoneProfileSetupPending(
        _lastPhoneAuthIsNewUser,
      );
      _syncFcmToken();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> completePhoneProfile({
    required String fullName,
    required String gender,
    required DateTime birthday,
    required String address,
    List<int> preferredCategoryIds = const [],
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final updated = await AuthRepository.updateProfile({
        'name': fullName.trim(),
        'gender': gender,
        'birthday': birthday.toIso8601String().split('T').first,
        'address': address.trim(),
      });
      if (preferredCategoryIds.isNotEmpty) {
        await AuthRepository.updatePreferredCategories(preferredCategoryIds);
      }
      _user = updated;
      await StorageService.saveUserData(updated.toJson());
      await StorageService.setPhoneProfileSetupPending(false);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('AuthProvider: Calling AuthRepository.register...');
      final response = await AuthRepository.register(data);
      print('AuthProvider: AuthRepository.register returned successfully.');

      final userObj = response['user'];

      if (userObj is User) {
        _user = userObj;
      } else {
        _user = User.fromJson(userObj);
      }

      await StorageService.saveUserData(_user!.toJson());
      _syncFcmToken();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      print('AuthProvider: Register Error: $e');
      print('AuthProvider: StackTrace: $stackTrace');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadProfile() async {
    final accessToken = await StorageService.getAccessToken();
    if (accessToken == null) {
      if (_user != null) {
        _user = null;
        notifyListeners();
      }
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await AuthRepository.getProfile();
      await StorageService.saveUserData(_user!.toJson());
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await ApiService.logout();
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      _user = null;
      _lastPhoneAuthIsNewUser = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkAuthStatus() async {
    final accessToken = await AuthService.getAccessToken();
    if (accessToken != null) {
      try {
        await loadProfile();
        _syncFcmToken();
        return true;
      } catch (e) {
        debugPrint('--- FAILED TO PARSE USER FROM JSON (loadProfile) ---');
        debugPrint('Error: $e');
        // Note: profileJson is not available in this scope.
        // If you need to log the raw JSON, you would need to capture it in loadProfile()
        // and pass it or store it temporarily.
        debugPrint('------------------------------------');
        await logout();
        return false;
      }
    }
    return false;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
