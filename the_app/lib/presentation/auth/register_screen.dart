import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/routing/routes.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthdayController = TextEditingController();
  String _selectedGender = 'male';
  DateTime? _selectedBirthday;
  int _currentStep = 0;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  bool _validateStep(int step) {
    switch (step) {
      case 0:
        return _firstNameController.text.isNotEmpty &&
            _lastNameController.text.isNotEmpty &&
            _selectedBirthday != null;
      case 1:
        return _phoneController.text.isNotEmpty &&
            _emailController.text.isNotEmpty &&
            _passwordController.text.isNotEmpty &&
            _confirmPasswordController.text.isNotEmpty &&
            _passwordController.text == _confirmPasswordController.text;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_validateStep(_currentStep)) {
      setState(() {
        _currentStep++;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _selectBirthday() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthday ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)), // Must be at least 13 years old
    );
    if (picked != null && picked != _selectedBirthday) {
      setState(() {
        _selectedBirthday = picked;
        _birthdayController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate() || !_validateStep(1)) {
      return;
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.register({
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'name': '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        'phone': _phoneController.text.trim(),
        'gender': _selectedGender,
        'birthday': _selectedBirthday?.toIso8601String().split('T').first,
      });

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(Routes.home);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Row(
        children: [
          for (int i = 0; i < 2; i++) ...[
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: i <= _currentStep 
                      ? AppColors.primaryColor 
                      : AppColors.textHint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (i < 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Information',
          style: AppTextStyles.h2.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Let\'s start with your basic information',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _firstNameController,
                label: 'First Name',
                hint: 'Enter your first name',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'First name is required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AppTextField(
                controller: _lastNameController,
                label: 'Last Name',
                hint: 'Enter your last name',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Last name is required';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _selectBirthday,
          child: AbsorbPointer(
            child: AppTextField(
              controller: _birthdayController,
              label: 'Birthday',
              hint: 'Select your birthday',
              icon: Icons.calendar_today,
              validator: (value) {
                if (_selectedBirthday == null) {
                  return 'Birthday is required';
                }
                return null;
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Gender',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Male'),
                value: 'male',
                groupValue: _selectedGender,
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value!;
                  });
                },
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Female'),
                value: 'female',
                groupValue: _selectedGender,
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value!;
                  });
                },
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Information',
          style: AppTextStyles.h2.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your contact details and create a secure password',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 32),
        AppTextField(
          controller: _phoneController,
          label: 'Phone Number',
          hint: 'Enter your phone number',
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Phone number is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _emailController,
          label: 'Email',
          hint: 'Enter your email address',
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Email is required';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _passwordController,
          label: 'Password',
          hint: 'Enter your password',
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Password is required';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _confirmPasswordController,
          label: 'Confirm Password',
          hint: 'Confirm your password',
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            if (value != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildPersonalInfoStep();
      case 1:
        return _buildContactInfoStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNavigationButtons() {
    return Column(
      children: [
        if (_currentStep < 1)
          SizedBox(
            width: double.infinity,
            child: AppPrimaryButton(
              text: 'Next',
              onPressed: _nextStep,
            ),
          ),
        if (_currentStep == 1)
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return SizedBox(
                width: double.infinity,
                child: AppPrimaryButton(
                  text: 'Create Account',
                  onPressed: authProvider.isLoading ? null : _handleRegister,
                  isLoading: authProvider.isLoading,
                ),
              );
            },
          ),
        const SizedBox(height: 16),
        if (_currentStep > 0)
          SizedBox(
            width: double.infinity,
            child: AppSecondaryButton(
              text: 'Previous',
              onPressed: _previousStep,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: WillPopScope(
        onWillPop: () async {
          if (_currentStep > 0) {
            _previousStep();
            return false; // Prevent default back navigation
          }
          return true; // Allow back navigation on first step
        },
        child: Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () {
                if (_currentStep > 0) {
                  // Go back to previous step
                  _previousStep();
                } else {
                  // Go back to previous screen
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStepIndicator(),
                    const SizedBox(height: 24),
                    _buildStepContent(),
                    const SizedBox(height: 48),
                    _buildNavigationButtons(),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacementNamed(Routes.login);
                          },
                          child: Text(
                            'Sign In',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
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