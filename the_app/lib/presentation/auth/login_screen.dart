import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../core/providers/auth_provider.dart';
import 'register_screen.dart';
import '../home/main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<bool> _isNetworkConnected() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return true;
  }

  Future<void> _loginUser() async {
    print('LoginScreen: Login button pressed');
    if (!_formKey.currentState!.validate()) {
      print('LoginScreen: Form validation failed');
      Helpers.showSnackBar(context, 'Please enter correct login credentials.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    bool isConnected = await _isNetworkConnected();
    if (!isConnected) {
      print('LoginScreen: No network connection');
      if (mounted) {
        Helpers.showSnackBar(
            context, 'Network connection failed. Please check your internet connection.');
      }
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      print('LoginScreen: Calling authProvider.login');
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      print('LoginScreen: authProvider.login returned: $success');

      if (success && mounted) {
        print(
            'LoginScreen: Login successful, navigating to MainNavigationScreen');
        Helpers.showSnackBar(context, 'Login successful!');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      } else if (!success && mounted) {
        print('LoginScreen: Login failed');
        final errorMsg =
            authProvider.error ?? 'Login failed, check your credentials.';
        Helpers.showSnackBar(context, errorMsg);
      }
    } catch (e) {
      print('LoginScreen: Exception caught: $e');
      debugPrint('❌ Login Error: $e');
      if (mounted) {
        Helpers.showSnackBar(
            context, 'Server connection failed. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildLuxuryTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textAlign: TextAlign.right,
        style: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.neutralDarkest,
        ),
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: Icon(
            icon,
            color: AppColors.primaryGold,
            size: 22,
          ),
          labelStyle: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.neutralMedium,
          ),
          filled: true,
          fillColor: AppColors.surfacePrimary.withOpacity(0.9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppColors.borderSecondary,
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppColors.borderSecondary,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppColors.primaryGold,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppColors.errorRed,
              width: 1,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildLuxuryPasswordField({
    required TextEditingController controller,
    required String labelText,
    required bool isVisible,
    required VoidCallback toggleVisibility,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: !isVisible,
        textAlign: TextAlign.right,
        style: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.neutralDarkest,
        ),
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: Icon(
            Icons.lock_outline,
            color: AppColors.primaryGold,
            size: 22,
          ),
          suffixIcon: GestureDetector(
            onTap: toggleVisibility,
            child: Icon(
              isVisible
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppColors.neutralMedium,
              size: 22,
            ),
          ),
          labelStyle: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.neutralMedium,
          ),
          filled: true,
          fillColor: AppColors.surfacePrimary.withOpacity(0.9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppColors.borderSecondary,
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppColors.borderSecondary,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppColors.primaryGold,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppColors.errorRed,
              width: 1,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSecondary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Column(
                  children: [
                    Text(
                      'DZ Local',
                      style: GoogleFonts.cairo(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryGold,
                      ),
                    ),
                    Text(
                      'Premium Local Marketplace',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: AppColors.neutralMedium,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 48),

                // Login Form
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surfacePrimary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppColors.primaryShadow,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Login',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: AppColors.neutralDarkest,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Email Field
                        _buildLuxuryTextField(
                          controller: _emailController,
                          labelText: 'Email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter email address';
                            }
                            if (!value.contains('@')) {
                              return 'Invalid email format';
                            }
                            return null;
                          },
                        ),

                        // Password Field
                        _buildLuxuryPasswordField(
                          controller: _passwordController,
                          labelText: 'Password',
                          isVisible: _isPasswordVisible,
                          toggleVisibility: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter password';
                            }
                            return null;
                          },
                        ),

                        // Forgot password link
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () {
                              Helpers.showSnackBar(
                                context,
                                'Will navigate to password reset screen',
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              child: Text(
                                'Forgot Password?',
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primaryGold,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Login Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _loginUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGold,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  'Login',
                                  style: GoogleFonts.cairo(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),

                        const SizedBox(height: 24),

                        // Register Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                'Don\'t have an account yet?',
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.neutralMedium,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (context) => const RegisterScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Create Account',
                                  style: GoogleFonts.cairo(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryGold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
