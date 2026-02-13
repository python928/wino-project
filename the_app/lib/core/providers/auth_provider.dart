import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  AuthProvider() {
    _loadUserFromStorage();
  }

  void _loadUserFromStorage() {
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

  /// Reload user data from storage
  void reloadFromStorage() {
    final userData = StorageService.getUserData();
    if (userData != null) {
      try {
        _user = User.fromJson(userData);
        notifyListeners();
      } catch (e) {
        print('AuthProvider: Error reloading user from storage: $e');
      }
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
         print('AuthProvider: Warning - user object is not of type User, trying fromJson...');
         _user = User.fromJson(userObj);
      }

      print('AuthProvider: User parsed successfully: ${_user?.username}');

      await StorageService.saveUserData(_user!.toJson());

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
    if (!isAuthenticated) return;

    _isLoading = true;
    notifyListeners();

    try {
      _user = await AuthRepository.getProfile();
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
        return true;
      } catch (e) {
        // Token invalid, logout
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
