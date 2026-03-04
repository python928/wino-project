import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/theme/app_colors.dart';
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

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String _statusMessage = 'جاري تهيئة التطبيق...';

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();

    _checkAuthenticationStatus();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkAuthenticationStatus() async {
    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;

    _setStatus('التحقق من الجلسة...');

    final isLoggedIn = StorageService.isLoggedIn();
    final accessToken = await StorageService.getAccessToken();

    if (!isLoggedIn || accessToken == null) {
      _setStatus('لا يوجد تسجيل دخول');
      debugPrint('❌ No token found - navigating to login');
      _navigateToLogin();
      return;
    }

    _setStatus('تم العثور على جلسة، جاري التحقق...');
    debugPrint('✅ Token found - validating...');

    if (JWTValidator.isExpired(accessToken)) {
      _setStatus('تحديث الجلسة...');
      debugPrint('⚠️ Access token expired - attempting refresh...');

      final refreshSuccess = await _attemptTokenRefresh();

      if (!refreshSuccess) {
        _setStatus('انتهت الجلسة');
        debugPrint('❌ Token refresh failed - logging out');
        await StorageService.logout();
        _navigateToLogin();
        return;
      }

      debugPrint('✅ Token refreshed successfully');
    }

    // Validate token with backend (if online)
    try {
      _setStatus('التحقق من الخادم...');
      final isValid = await _validateTokenWithBackend();

      if (isValid) {
        _setStatus('جاهز');
        debugPrint('✅ Token validated successfully');
        _navigateToHome();
      } else {
        _setStatus('جلسة غير صالحة');
        debugPrint('❌ Token validation failed');
        await StorageService.logout();
        _navigateToLogin();
      }
    } catch (e) {
      debugPrint('⚠️ Network error during validation: $e');

      // If there is no internet and the token is not expired locally - go offline
      final currentToken = await StorageService.getAccessToken();
      if (currentToken != null && !JWTValidator.isExpired(currentToken)) {
        _setStatus('وضع بدون إنترنت');
        debugPrint('ℹ️ Entering offline mode');
        _navigateToHomeOffline();
      } else {
        _setStatus('يتطلب تسجيل دخول');
        debugPrint('❌ No valid token for offline mode');
        _navigateToLogin();
      }
    }
  }

  void _setStatus(String value) {
    if (!mounted) return;
    setState(() => _statusMessage = value);
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

    // Show a message to the user that they are offline
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
    );

    // Show snackbar after navigation
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are offline - some features are unavailable'),
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryLightShade.withValues(alpha: 0.45),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                child: Column(
                  children: [
                    const Spacer(),
                    Container(
                      width: 108,
                      height: 108,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primaryColor,
                            AppColors.primaryDark
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.primaryColor.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        size: 54,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Topri',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDeep,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'تسوق محلي ذكي مع نتائج أقرب لك',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 26),
                    _FeatureTile(
                      icon: Icons.near_me_rounded,
                      title: 'بحث Nearby حي',
                      subtitle: 'يعتمد على موقعك الحالي وقت البحث',
                    ),
                    const SizedBox(height: 10),
                    _FeatureTile(
                      icon: Icons.shield_outlined,
                      title: 'خصوصية أفضل للمتاجر',
                      subtitle:
                          'إخفاء المتجر من نتائج القرب متاح من Edit Profile',
                    ),
                    const SizedBox(height: 10),
                    _FeatureTile(
                      icon: Icons.inventory_2_outlined,
                      title: 'منتجات وعروض وباقات',
                      subtitle: 'تصميم أوضح للأسعار والصور والتفاصيل',
                    ),
                    const Spacer(),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primaryColor.withValues(alpha: 0.20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _statusMessage,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const LinearProgressIndicator(
                            minHeight: 4,
                            borderRadius: BorderRadius.all(Radius.circular(3)),
                            color: AppColors.primaryColor,
                            backgroundColor: AppColors.neutral200,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primaryLightShade,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 18, color: AppColors.primaryColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
