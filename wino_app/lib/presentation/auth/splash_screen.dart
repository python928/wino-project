import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/config/api_config.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/jwt_validator.dart';
import '../home/main_navigation_screen.dart';
import 'launch_screen.dart';
import 'login_screen.dart';
import 'phone_profile_setup_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  Timer? _flowTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
    _startFlow();
  }

  @override
  void dispose() {
    _flowTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startFlow() {
    _flowTimer?.cancel();
    _flowTimer = Timer(const Duration(milliseconds: 1200), () async {
      if (!mounted) return;

      if (StorageService.isFirstTime()) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LaunchScreen()),
        );
        return;
      }

      await _checkAuthenticationStatus();
    });
  }

  Future<void> _checkAuthenticationStatus() async {
    final isLoggedIn = StorageService.isLoggedIn();
    final accessToken = await StorageService.getAccessToken();

    if (!isLoggedIn || accessToken == null) {
      _navigateToLogin();
      return;
    }

    if (JWTValidator.isExpired(accessToken)) {
      final refreshSuccess = await _attemptTokenRefresh();
      if (!refreshSuccess) {
        await StorageService.logout();
        _navigateToLogin();
        return;
      }
    }

    try {
      final isValid = await _validateTokenWithBackend();
      if (isValid) {
        if (StorageService.isPhoneProfileSetupPending()) {
          _navigateToPhoneProfileSetup();
          return;
        }
        _navigateToHome();
      } else {
        await StorageService.logout();
        _navigateToLogin();
      }
    } catch (_) {
      final currentToken = await StorageService.getAccessToken();
      if (currentToken != null && !JWTValidator.isExpired(currentToken)) {
        if (StorageService.isPhoneProfileSetupPending()) {
          _navigateToPhoneProfileSetup();
          return;
        }
        _navigateToHomeOffline();
      } else {
        _navigateToLogin();
      }
    }
  }

  Future<bool> _attemptTokenRefresh() async {
    try {
      return await ApiService.refreshToken();
    } catch (_) {
      return false;
    }
  }

  Future<bool> _validateTokenWithBackend() async {
    try {
      await ApiService.get(ApiConfig.users);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _navigateToHomeOffline() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
    );
  }

  void _navigateToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
    );
  }

  void _navigateToPhoneProfileSetup() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PhoneProfileSetupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryLightShade.withValues(alpha: 0.55),
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 200,
                    height: 200,
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
