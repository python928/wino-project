import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../home/main_navigation_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) {
      Helpers.showSnackBar(context, 'Please fill in all required fields correctly.');
      return;
    }

    setState(() => _isLoading = true);

    final emailPart = _emailController.text.trim().split('@').first;
    final username = emailPart.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');

    final registrationData = {
      'username': username,
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
      'phone': _phoneController.text.trim(),
      'role': 'USER',
    };

    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.register(registrationData);

      if (success && mounted) {
        Helpers.showSnackBar(context, 'Registration successful! Welcome');
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
          (route) => false,
        );
      } else if (!success && mounted) {
        final errorMsg = authProvider.error ?? 'Unable to complete registration, try again';
        Helpers.showSnackBar(context, errorMsg);
      }
    } catch (e) {
      debugPrint('Registration Error: $e');
      if (mounted) {
        Helpers.showSnackBar(context, 'Failed to connect to server. Please try again.');
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField({
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
          prefixIcon: Icon(icon, color: AppColors.primaryGold, size: 22),
          labelStyle: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.neutralMedium,
          ),
          filled: true,
          fillColor: AppColors.surfacePrimary.withOpacity(0.9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.borderSecondary, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.borderSecondary, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.primaryGold, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.errorRed, width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildPasswordField({
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
          prefixIcon: Icon(Icons.lock_outline, color: AppColors.primaryGold, size: 22),
          suffixIcon: GestureDetector(
            onTap: toggleVisibility,
            child: Icon(
              isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
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
            borderSide: BorderSide(color: AppColors.borderSecondary, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.borderSecondary, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.primaryGold, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.errorRed, width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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

                const SizedBox(height: 40),

                // Register Form
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
                          'Create New Account',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: AppColors.neutralDarkest,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Name Field
                        _buildTextField(
                          controller: _nameController,
                          labelText: 'Name',
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value!.isEmpty) return 'Please enter name';
                            return null;
                          },
                        ),

                        // Email Field
                        _buildTextField(
                          controller: _emailController,
                          labelText: 'Email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value!.isEmpty) return 'Please enter email address';
                            if (!value.contains('@')) return 'Invalid email format';
                            return null;
                          },
                        ),

                        // Phone Field
                        _buildTextField(
                          controller: _phoneController,
                          labelText: 'Phone Number',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value!.isEmpty) return 'Please enter phone number';
                            return null;
                          },
                        ),

                        // Password Field
                        _buildPasswordField(
                          controller: _passwordController,
                          labelText: 'Password',
                          isVisible: _isPasswordVisible,
                          toggleVisibility: () {
                            setState(() => _isPasswordVisible = !_isPasswordVisible);
                          },
                          validator: (value) {
                            if (value!.isEmpty) return 'Please enter password';
                            if (value.length < 6) return 'Password must be at least 6 characters';
                            return null;
                          },
                        ),

                        const SizedBox(height: 8),

                        // Register Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _registerUser,
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
                                  'Create Account',
                                  style: GoogleFonts.cairo(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),

                        const SizedBox(height: 20),

                        // Login Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account?',
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: AppColors.neutralMedium,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                                );
                              },
                              child: Text(
                                'Login',
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryGold,
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
