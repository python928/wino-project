import 'dart:async';

import 'package:dzlocal_shop/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/app_button.dart';
import '../home/main_navigation_screen.dart';
import 'phone_profile_setup_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phone;
  const OtpVerificationScreen({super.key, required this.phone});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  bool _isLoading = false;
  late final List<TextEditingController> _otpControllers;
  late final List<FocusNode> _otpFocusNodes;
  Timer? _cooldownTimer;
  DateTime? _resendAvailableAt;
  static const String _prototypeOtp = '123456';

  String get _otpCode => _otpControllers.map((e) => e.text).join();
  int get _remainingSeconds {
    if (_resendAvailableAt == null) return 0;
    final sec = _resendAvailableAt!.difference(DateTime.now()).inSeconds;
    return sec > 0 ? sec : 0;
  }

  @override
  void initState() {
    super.initState();
    _otpControllers = List.generate(6, (_) => TextEditingController());
    _otpFocusNodes = List.generate(6, (_) => FocusNode());
    _startResendCooldown(60);
  }

  @override
  void dispose() {
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startResendCooldown(int seconds) {
    _resendAvailableAt = DateTime.now().add(Duration(seconds: seconds));
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds <= 0) {
        timer.cancel();
      }
      setState(() {});
    });
    setState(() {});
  }

  Future<void> _verifyOtp() async {
    if (_otpCode.length != 6) {
      Helpers.showSnackBar(context, context.tr('Enter the 6-digit code'),
          isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.verifyPhoneOtp(
        phone: widget.phone,
        code: _otpCode,
      );

      if (!mounted) return;
      if (success) {
        if (authProvider.lastPhoneAuthIsNewUser) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const PhoneProfileSetupScreen()),
            (_) => false,
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
            (_) => false,
          );
        }
      } else {
        Helpers.showSnackBar(context,
            authProvider.error ?? context.tr('OTP verification failed.'),
            isError: true);
      }
    } catch (_) {
      if (mounted) {
        Helpers.showSnackBar(
            context, context.tr('Server connection failed. Please try again.'),
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendCode() async {
    if (_remainingSeconds > 0) return;
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final ok = await authProvider.sendPhoneOtp(widget.phone);
      if (!mounted) return;
      if (ok) {
        _startResendCooldown(60);
        Helpers.showSnackBar(context, context.tr('Verification code resent'));
      } else {
        final msg = authProvider.error ?? context.tr('Failed to resend code');
        final match = RegExp(r'(\d+)').firstMatch(msg);
        if (match != null) {
          final sec = int.tryParse(match.group(1)!);
          if (sec != null && sec > 0) _startResendCooldown(sec);
        }
        Helpers.showSnackBar(context, msg, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _skipWithPrototypeCode() async {
    if (_isLoading) return;
    for (int i = 0;
        i < _otpControllers.length && i < _prototypeOtp.length;
        i++) {
      _otpControllers[i].text = _prototypeOtp[i];
    }
    _otpFocusNodes.last.requestFocus();
    await _verifyOtp();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('Verify Code')),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              24 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.tr('We sent a 6-digit code to'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.phone,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 26),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 46,
                      child: Focus(
                        onKeyEvent: (node, event) {
                          if (event is KeyDownEvent &&
                              event.logicalKey ==
                                  LogicalKeyboardKey.backspace &&
                              _otpControllers[index].text.isEmpty &&
                              index > 0) {
                            _otpControllers[index - 1].clear();
                            _otpFocusNodes[index - 1].requestFocus();
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        child: TextFormField(
                          controller: _otpControllers[index],
                          focusNode: _otpFocusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: AppTextStyles.h3.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 14),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.borderPrimary.withOpacity(0.8),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.6,
                              ),
                            ),
                          ),
                          onTap: () {
                            _otpControllers[index].selection = TextSelection(
                              baseOffset: 0,
                              extentOffset: _otpControllers[index].text.length,
                            );
                          },
                          onChanged: (value) {
                            if (value.isNotEmpty && index < 5) {
                              _otpFocusNodes[index + 1].requestFocus();
                            } else if (value.isEmpty && index > 0) {
                              _otpFocusNodes[index - 1].requestFocus();
                            }
                          },
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 26),
                AppPrimaryButton(
                  text: context.tr('Verify'),
                  onPressed: _verifyOtp,
                  isLoading: _isLoading,
                  height: 52,
                ),
                const SizedBox(height: 12),
                AppTextButton(
                  text: _remainingSeconds > 0
                      ? '${context.tr('Resend in')} ${_remainingSeconds}s'
                      : context.tr('Resend code'),
                  onPressed: (_remainingSeconds > 0 || _isLoading)
                      ? null
                      : _resendCode,
                ),
                const SizedBox(height: 6),
                AppTextButton(
                  text: context.tr('Skip (Prototype)'),
                  onPressed: _isLoading ? null : _skipWithPrototypeCode,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
