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
  String _activeProfileType = 'USER'; // 'USER' or 'STORE'

  AuthProvider() {
    _loadUserFromStorage();
  }

  void _loadUserFromStorage() {
    final userData = StorageService.getUserData();
    if (userData != null) {
      try {
        _user = User.fromJson(userData);
        // If user is merchant, default to STORE view? Or keep last state?
        // For now, let's default to USER unless we save the active profile type too.
        // But the user wants to switch.
        // Let's just load the user.
        // _activeProfileType = _user?.role == 'STORE' ? 'STORE' : 'USER'; 
        // Actually, if I am a store owner, I probably want to see my store dashboard first?
        // The previous logic in login was:
        // _activeProfileType = _user?.role == 'STORE' ? 'STORE' : 'USER';
        // Let's replicate that.
        if (_user?.role == 'STORE') {
           _activeProfileType = 'STORE';
        }
      } catch (e) {
        print('AuthProvider: Error parsing user from storage: $e');
      }
    }
  }

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  String get activeProfileType => _activeProfileType;

  bool get isStoreProfileActive => _activeProfileType == 'STORE';

  void switchProfileType() {
    if (_user?.isMerchant == true) {
      _activeProfileType = _activeProfileType == 'USER' ? 'STORE' : 'USER';
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
      // final tokens = response['tokens']; // Tokens are already saved by AuthRepository

      if (userObj is User) {
         _user = userObj;
      } else {
         // Fallback if it somehow returns a Map (should not happen with current repo code)
         print('AuthProvider: Warning - user object is not of type User, trying fromJson...');
         _user = User.fromJson(userObj);
      }

      // Set initial profile type
      _activeProfileType = _user?.role == 'STORE' ? 'STORE' : 'USER';

      print('AuthProvider: User parsed successfully: ${_user?.username}');

      await StorageService.saveUserData(_user!.toJson());

      // Tokens are already saved in AuthRepository, so we don't strictly need to save them again here,
      // but if AuthService.saveTokens does something extra, we can keep it. 
      // However, to avoid race conditions or double-writes, it's safer to rely on the Repo.
      // If AuthService is just a wrapper around StorageService, we can skip it or keep it.
      // Let's keep it commented out or remove it if we trust the Repo.
      // For now, I will comment it out to avoid redundancy, as the Repo explicitly saves them.
      /*
      await AuthService.saveTokens(
        accessToken: tokens['access'],
        refreshToken: tokens['refresh'],
      );
      */

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
      // final tokens = response['tokens'];

      if (userObj is User) {
         _user = userObj;
      } else {
         _user = User.fromJson(userObj);
      }

      await StorageService.saveUserData(_user!.toJson());

      // Tokens are already saved in AuthRepository
      /*
      await AuthService.saveTokens(
        accessToken: tokens['access'],
        refreshToken: tokens['refresh'],
      );
      */

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
      _activeProfileType = 'USER';
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