import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/app_button.dart';
import '../../core/utils/helpers.dart';
import '../../core/providers/auth_provider.dart';
import '../home/main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _phoneFocusNode = FocusNode();

  bool _isLoading = false;
  bool _otpSent = false;
  String _otpCode = '';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final success =
          await authProvider.sendPhoneOtp(_phoneController.text.trim());

      if (success && mounted) {
        setState(() {
          _otpSent = true;
        });
        Helpers.showSnackBar(context, 'Verification code sent');
      } else if (!success && mounted) {
        final errorMsg =
            authProvider.error ?? 'Failed to send verification code.';
        Helpers.showSnackBar(context, errorMsg);
      }
    } catch (_) {
      if (mounted) {
        Helpers.showSnackBar(
            context, 'Server connection failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpCode.length != 6) {
      Helpers.showSnackBar(context, 'Enter the 6-digit code');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.verifyPhoneOtp(
        phone: _phoneController.text.trim(),
        code: _otpCode,
      );

      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      } else if (!success && mounted) {
        final errorMsg = authProvider.error ?? 'OTP verification failed.';
        Helpers.showSnackBar(context, errorMsg);
      }
    } catch (_) {
      if (mounted) {
        Helpers.showSnackBar(
            context, 'Server connection failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 32, 32, 32),
                  child: _buildBody(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        Container(
          height: 280,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: AppColors.purpleGradient,
          ),
        ),
        Positioned(
          top: -60,
          right: -60,
          child: _CircleDecoration(200, 0.08),
        ),
        Positioned(
          top: -20,
          right: -20,
          child: _CircleDecoration(140, 0.10),
        ),
        Positioned(
          top: 20,
          right: 20,
          child: _CircleDecoration(80, 0.12),
        ),
        Positioned.fill(
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.phone_android_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Topri',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Phone Verification Login',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _otpSent ? 'Enter Verification Code' : 'Sign In With Phone',
            textAlign: TextAlign.center,
            style: AppTextStyles.h3.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _otpSent
                ? 'We sent a 6-digit code to your number'
                : 'Use your phone number to receive an OTP',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          AppTextField(
            controller: _phoneController,
            focusNode: _phoneFocusNode,
            label: 'Phone Number',
            hint: '+213XXXXXXXXX',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            validator: (value) {
              final text = (value ?? '').trim();
              if (text.isEmpty) return 'Please enter your phone number';
              if (text.length < 8) return 'Please enter a valid phone number';
              return null;
            },
          ),
          const SizedBox(height: 24),
          if (_otpSent) ...[
            OtpTextField(
              numberOfFields: 6,
              borderColor: AppColors.primary,
              focusedBorderColor: AppColors.primary,
              showFieldAsBox: true,
              borderRadius: BorderRadius.circular(10),
              fieldWidth: 42,
              onCodeChanged: (_) {},
              onSubmit: (verificationCode) {
                _otpCode = verificationCode;
              },
            ),
            const SizedBox(height: 24),
          ],
          AppPrimaryButton(
            text: _otpSent ? 'Verify Code' : 'Send Code',
            onPressed: _otpSent ? _verifyOtp : _sendOtp,
            isLoading: _isLoading,
            height: 52,
          ),
          if (_otpSent) ...[
            const SizedBox(height: 14),
            AppTextButton(
              text: 'Resend code',
              onPressed: _sendOtp,
            ),
          ],
        ],
      ),
    );
  }
}

class _CircleDecoration extends StatelessWidget {
  final double size;
  final double opacity;
  const _CircleDecoration(this.size, this.opacity);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }
}
