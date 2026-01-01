import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/theme/app_text_styles.dart';
import '../../core/config/api_config.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/jwt_validator.dart';
import '../home/main_navigation_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    
    _controller.forward();
    
    // Check authentication after animation
    _checkAuthenticationStatus();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  Future<void> _checkAuthenticationStatus() async {
    // Wait for animation to complete
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    // Check if user is logged in
    final isLoggedIn = StorageService.isLoggedIn();
    final accessToken = await StorageService.getAccessToken();
    
    if (!isLoggedIn || accessToken == null) {
      // Not logged in - go to login
      debugPrint('❌ No token found - navigating to login');
      _navigateToLogin();
      return;
    }
    
    debugPrint('✅ Token found - validating...');
    
    // Check local token expiration first
    if (JWTValidator.isExpired(accessToken)) {
      debugPrint('⚠️ Access token expired - attempting refresh...');
      
      // Try to refresh token
      final refreshSuccess = await _attemptTokenRefresh();
      
      if (!refreshSuccess) {
        debugPrint('❌ Token refresh failed - logging out');
        await StorageService.logout();
        _navigateToLogin();
        return;
      }
      
      debugPrint('✅ Token refreshed successfully');
    }
    
    // Validate token with backend (if online)
    try {
      final isValid = await _validateTokenWithBackend();
      
      if (isValid) {
        debugPrint('✅ Token validated successfully');
        _navigateToHome();
      } else {
        debugPrint('❌ Token validation failed');
        await StorageService.logout();
        _navigateToLogin();
      }
    } catch (e) {
      debugPrint('⚠️ Network error during validation: $e');
      
      // إذا لا يوجد إنترنت والتوكن غير منتهي محلياً - ادخل أوفلاين
      final currentToken = await StorageService.getAccessToken();
      if (currentToken != null && !JWTValidator.isExpired(currentToken)) {
        debugPrint('ℹ️ Entering offline mode');
        _navigateToHomeOffline();
      } else {
        debugPrint('❌ No valid token for offline mode');
        _navigateToLogin();
      }
    }
  }
  
  Future<bool> _attemptTokenRefresh() async {
    try {
      return await ApiService.refreshToken();
    } catch (e) {
      debugPrint('❌ Token refresh error: $e');
      return false;
    }
  }
  
  Future<bool> _validateTokenWithBackend() async {
    try {
      // Call a protected endpoint to validate token
      await ApiService.get(ApiConfig.users);
      return true;
    } catch (e) {
      debugPrint('Backend validation failed: $e');
      return false;
    }
  }
  
  void _navigateToHomeOffline() {
    if (!mounted) return;
    
    // عرض رسالة للمستخدم بأنه في وضع عدم الاتصال
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
    );
    
    // عرض snackbar بعد التنقل
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('أنت في وضع عدم الاتصال - بعض الميزات غير متاحة'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.orange,
          ),
        );
      }
    });
  }
  
  void _navigateToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }
  
  void _navigateToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF8C42),
              Color(0xFFFF6B35),
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shopping_bag_rounded,
                      size: 80,
                      color: Color(0xFFFF8C42),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'DZ Local',
                    style: AppTextStyles.h1.copyWith(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'تسوق محلي، اكتشف جديد',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
