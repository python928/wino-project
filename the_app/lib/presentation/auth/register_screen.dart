import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/routing/routes.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/services/api_service.dart';
import '../../core/config/api_config.dart';
import '../../core/providers/home_provider.dart';
import '../search/category_selection_screen.dart';

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

  // Birthday — 3 separate fields (Google-style)
  final _dayController = TextEditingController();
  final _monthController = TextEditingController();
  final _yearController = TextEditingController();

  String _selectedGender = 'male';
  int _currentStep = 0;

  // Step 2: category selection
  List<Map<String, dynamic>> _categories = [];
  Set<int> _selectedCategoryIds = {};
  bool _loadingCategories = false;

  // ---------------------------------------------------------------------------
  // Birthday helpers
  // ---------------------------------------------------------------------------
  DateTime? get _parsedBirthday {
    final day = int.tryParse(_dayController.text.trim());
    final month = int.tryParse(_monthController.text.trim());
    final year = int.tryParse(_yearController.text.trim());
    if (day == null || month == null || year == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    if (year < 1900 || year > DateTime.now().year) return null;
    try {
      final d = DateTime(year, month, day);
      // Validate day didn't overflow (e.g. Feb 30)
      if (d.day != day) return null;
      return d;
    } catch (_) {
      return null;
    }
  }

  bool get _birthdayValid {
    final b = _parsedBirthday;
    if (b == null) return false;
    final minAge = DateTime.now().subtract(const Duration(days: 365 * 13));
    return b.isBefore(minAge);
  }

  // ---------------------------------------------------------------------------
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  bool _validateStep(int step) {
    switch (step) {
      case 0:
        return _firstNameController.text.trim().isNotEmpty &&
            _lastNameController.text.trim().isNotEmpty &&
            _birthdayValid;
      case 1:
        return _phoneController.text.trim().isNotEmpty &&
            _emailController.text.trim().isNotEmpty &&
            _passwordController.text.isNotEmpty &&
            _confirmPasswordController.text.isNotEmpty &&
            _passwordController.text == _confirmPasswordController.text;
      case 2:
        return _selectedCategoryIds.isNotEmpty;
      default:
        return false;
    }
  }

  Future<void> _openAllCategoriesPicker() async {
    final cats = _categories
        .map((e) => Category.fromJson(e))
        .toList();
    if (cats.isEmpty) return;
    final result = await Navigator.push<Set<int>>(
      context,
      MaterialPageRoute(
        builder: (_) => CategorySelectionScreen(
          categories: cats,
          initialSelectedCategoryIds: _selectedCategoryIds,
        ),
      ),
    );
    if (result != null) {
      setState(() => _selectedCategoryIds = result);
    }
  }

  Future<void> _fetchCategories() async {
    if (_categories.isNotEmpty) return;
    setState(() => _loadingCategories = true);
    try {
      final response = await ApiService.get(ApiConfig.categories);
      final list = response is List ? response : (response['results'] ?? []);
      if (mounted) {
        setState(() {
          _categories =
              (list as List).map((e) => e as Map<String, dynamic>).toList();
          _loadingCategories = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  void _nextStep() {
    if (_validateStep(_currentStep)) {
      if (_currentStep == 1) _fetchCategories();
      setState(() => _currentStep++);
    } else {
      String msg = 'Please fill in all required fields';
      if (_currentStep == 0 && !_birthdayValid &&
          _dayController.text.isNotEmpty) {
        msg = 'Please enter a valid date of birth (must be 13+)';
      } else if (_currentStep == 1 &&
          _passwordController.text != _confirmPasswordController.text) {
        msg = 'Passwords do not match';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  Future<void> _handleRegister() async {
    if (!_validateStep(1)) return;
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.register({
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'name':
            '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        'phone': _phoneController.text.trim(),
        'gender': _selectedGender,
        'birthday': _parsedBirthday?.toIso8601String().split('T').first,
        'preferred_categories': _selectedCategoryIds.toList(),
      });
      if (mounted) Navigator.of(context).pushReplacementNamed(Routes.home);
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

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------
  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          for (int i = 0; i < 3; i++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 4,
                decoration: BoxDecoration(
                  color: i <= _currentStep
                      ? Colors.white
                      : Colors.white.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (i < 2) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 0 — Personal info
  // ---------------------------------------------------------------------------
  Widget _buildPersonalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Information',
          style: AppTextStyles.h2
              .copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          "Let's start with your basic information",
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 28),

        // First / Last name row
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _firstNameController,
                label: 'First Name',
                hint: 'First name',
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: AppTextField(
                controller: _lastNameController,
                label: 'Last Name',
                hint: 'Last name',
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Birthday — Google-style 3-field
        _buildBirthdayField(),
        const SizedBox(height: 28),

        // Gender selector
        Text(
          'Gender',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildGenderSelector(),
      ],
    );
  }

  // ── Birthday ────────────────────────────────────────────────────────────────
  Widget _buildBirthdayField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date of birth',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // Day
            _DatePartField(
              controller: _dayController,
              label: 'Day',
              hint: 'DD',
              maxLength: 2,
              maxValue: 31,
              flex: 2,
            ),
            const SizedBox(width: 10),
            // Month
            _DatePartField(
              controller: _monthController,
              label: 'Month',
              hint: 'MM',
              maxLength: 2,
              maxValue: 12,
              flex: 2,
            ),
            const SizedBox(width: 10),
            // Year
            _DatePartField(
              controller: _yearController,
              label: 'Year',
              hint: 'YYYY',
              maxLength: 4,
              maxValue: DateTime.now().year,
              flex: 3,
              onComplete: () => setState(() {}),
            ),
          ],
        ),
        // Inline validation hint
        ValueListenableBuilder(
          valueListenable: _yearController,
          builder: (_, __, ___) {
            if (_yearController.text.length == 4) {
              final b = _parsedBirthday;
              if (b == null) {
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Please enter a valid date',
                    style: TextStyle(
                        fontSize: 12, color: Colors.red.shade400),
                  ),
                );
              }
              final minAge = DateTime.now()
                  .subtract(const Duration(days: 365 * 13));
              if (!b.isBefore(minAge)) {
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'You must be at least 13 years old',
                    style: TextStyle(
                        fontSize: 12, color: Colors.red.shade400),
                  ),
                );
              }
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  // ── Gender selector ─────────────────────────────────────────────────────────
  Widget _buildGenderSelector() {
    return Row(
      children: [
        Expanded(
          child: _GenderCard(
            label: 'Male',
            icon: Icons.male_rounded,
            selected: _selectedGender == 'male',
            onTap: () => setState(() => _selectedGender = 'male'),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _GenderCard(
            label: 'Female',
            icon: Icons.female_rounded,
            selected: _selectedGender == 'female',
            onTap: () => setState(() => _selectedGender = 'female'),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step 1 — Account info
  // ---------------------------------------------------------------------------
  Widget _buildContactInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Information',
          style: AppTextStyles.h2
              .copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          'Enter your contact details and create a secure password',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 28),
        AppTextField(
          controller: _phoneController,
          label: 'Phone Number',
          hint: 'Enter your phone number',
          keyboardType: TextInputType.phone,
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Phone number is required' : null,
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _emailController,
          label: 'Email',
          hint: 'Enter your email address',
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Email is required';
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
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
          validator: (v) {
            if (v == null || v.isEmpty) return 'Password is required';
            if (v.length < 6) return 'Minimum 6 characters';
            return null;
          },
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _confirmPasswordController,
          label: 'Confirm Password',
          hint: 'Confirm your password',
          obscureText: true,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Please confirm your password';
            if (v != _passwordController.text) return 'Passwords do not match';
            return null;
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step 2 — Interests
  // ---------------------------------------------------------------------------
  Widget _buildCategoryStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Interests',
          style: AppTextStyles.h2
              .copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          'Pick categories you care about — choose up to 6',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        if (_loadingCategories)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_categories.isEmpty)
          Center(
            child: Text(
              'No categories available',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
          )
        else ...[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              // Show first 8 categories
              ..._categories.take(8).map((cat) {
                final id = cat['id'] as int;
                final name = cat['name']?.toString() ?? '';
                final isSelected = _selectedCategoryIds.contains(id);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (isSelected) {
                      _selectedCategoryIds.remove(id);
                    } else if (_selectedCategoryIds.length < 6) {
                      _selectedCategoryIds.add(id);
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryColor
                          : const Color(0xFFF0F0F5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      name,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }),
              // "See All" chip
              if (_categories.length > 8)
                GestureDetector(
                  onTap: _openAllCategoriesPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: _selectedCategoryIds.isNotEmpty
                          ? AppColors.primaryColor.withOpacity(0.10)
                          : const Color(0xFFF0F0F5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _selectedCategoryIds.isNotEmpty
                            ? AppColors.primaryColor
                            : Colors.transparent,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedCategoryIds.isNotEmpty
                              ? 'See All (${_selectedCategoryIds.length} selected)'
                              : 'See All',
                          style: TextStyle(
                            color: _selectedCategoryIds.isNotEmpty
                                ? AppColors.primaryColor
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_right_rounded,
                          size: 18,
                          color: _selectedCategoryIds.isNotEmpty
                              ? AppColors.primaryColor
                              : AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (_selectedCategoryIds.length >= 6)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Maximum 6 categories selected',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.primaryColor),
              ),
            ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Navigation buttons
  // ---------------------------------------------------------------------------
  Widget _buildNavigationButtons() {
    return Column(
      children: [
        if (_currentStep < 2)
          SizedBox(
            width: double.infinity,
            child: AppPrimaryButton(text: 'Next', onPressed: _nextStep),
          ),
        if (_currentStep == 2)
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) => SizedBox(
              width: double.infinity,
              child: AppPrimaryButton(
                text: 'Create Account',
                onPressed:
                    authProvider.isLoading ? null : _handleRegister,
                isLoading: authProvider.isLoading,
              ),
            ),
          ),
        const SizedBox(height: 14),
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

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: WillPopScope(
        onWillPop: () async {
          if (_currentStep > 0) {
            _previousStep();
            return false;
          }
          return true;
        },
        child: Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          body: Column(
            children: [
              // ── Purple gradient header ──────────────────────────────────
              Stack(
                children: [
                  Container(
                    height: 140,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                        gradient: AppColors.purpleGradient),
                  ),
                  // Concentric circles
                  Positioned(
                      top: -50,
                      right: -50,
                      child: _CircleDecoration(180, 0.08)),
                  Positioned(
                      top: -10,
                      right: -10,
                      child: _CircleDecoration(120, 0.10)),
                  Positioned(
                      top: 30,
                      right: 30,
                      child: _CircleDecoration(60, 0.13)),
                  // Back + step indicator
                  Positioned.fill(
                    child: SafeArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios,
                                color: Colors.white),
                            onPressed: () {
                              if (_currentStep > 0) {
                                _previousStep();
                              } else {
                                Navigator.of(context).pop();
                              }
                            },
                          ),
                          const Spacer(),
                          _buildStepIndicator(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // ── Scrollable form ─────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: KeyedSubtree(
                            key: ValueKey(_currentStep),
                            child: _buildStepContent(),
                          ),
                        ),
                        const SizedBox(height: 40),
                        _buildNavigationButtons(),
                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context)
                                  .pushReplacementNamed(Routes.login),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildPersonalInfoStep();
      case 1:
        return _buildContactInfoStep();
      case 2:
        return _buildCategoryStep();
      default:
        return const SizedBox.shrink();
    }
  }
}

// =============================================================================
// Gender card
// =============================================================================
class _GenderCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _GenderCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF9C88FF), AppColors.primaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.primaryColor
                : const Color(0xFFE5E7EB),
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.30),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              color: selected ? Colors.white : const Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Date part field (Day / Month / Year)
// =============================================================================
class _DatePartField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLength;
  final int maxValue;
  final int flex;
  final VoidCallback? onComplete;

  const _DatePartField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.maxLength,
    required this.maxValue,
    this.flex = 1,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: maxLength,
            onChanged: (v) {
              if (v.length == maxLength) {
                final parsed = int.tryParse(v);
                if (parsed != null && parsed > maxValue) {
                  controller.text = maxValue.toString();
                  controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: controller.text.length),
                  );
                }
                onComplete?.call();
                FocusScope.of(context).nextFocus();
              }
            },
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(maxLength),
            ],
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w500,
              ),
              counterText: '',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: Color(0xFFE5E7EB), width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: AppColors.primaryColor, width: 1.5),
              ),
            ),
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Circle decoration (header)
// =============================================================================
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
