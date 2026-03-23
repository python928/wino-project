import 'package:flutter/material.dart';
import 'package:dzlocal_shop/core/extensions/l10n_extension.dart';
import 'package:provider/provider.dart';

import '../../core/config/api_config.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_input_decorations.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/app_button.dart';
import '../../data/models/category_model.dart';
import '../home/main_navigation_screen.dart';
import '../search/category_selection_screen.dart';

class PhoneProfileSetupScreen extends StatefulWidget {
  const PhoneProfileSetupScreen({super.key});

  @override
  State<PhoneProfileSetupScreen> createState() =>
      _PhoneProfileSetupScreenState();
}

class _PhoneProfileSetupScreenState extends State<PhoneProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dayController = TextEditingController();
  final _monthController = TextEditingController();
  final _yearController = TextEditingController();

  String _selectedGender = 'male';
  bool _isLoading = false;
  bool _loadingCategories = false;
  List<Category> _categories = [];
  Set<int> _selectedCategoryIds = {};

  DateTime? get _parsedBirthday {
    final day = int.tryParse(_dayController.text.trim());
    final month = int.tryParse(_monthController.text.trim());
    final year = int.tryParse(_yearController.text.trim());
    if (day == null || month == null || year == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    if (year < 1900 || year > DateTime.now().year) return null;
    try {
      final d = DateTime(year, month, day);
      if (d.day != day) return null;
      return d;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    if (_categories.isNotEmpty || _loadingCategories) return;
    setState(() => _loadingCategories = true);
    try {
      final response = await ApiService.get(ApiConfig.categories);
      final list = response is List ? response : (response['results'] ?? []);
      _categories = (list as List)
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      if (mounted) Helpers.showSnackBar(context, 'Failed to load categories');
    } finally {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _openCategories() async {
    FocusScope.of(context).unfocus();
    await _fetchCategories();
    if (!mounted || _categories.isEmpty) return;
    final result = await Navigator.push<Set<int>>(
      context,
      MaterialPageRoute(
        builder: (_) => CategorySelectionScreen(
          categories: _categories,
          initialSelectedCategoryIds: _selectedCategoryIds,
        ),
      ),
    );
    if (result != null) {
      setState(() => _selectedCategoryIds = result);
    }
    if (mounted) {
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final birthday = _parsedBirthday;
    if (birthday == null) {
      Helpers.showSnackBar(context, 'Enter a valid birthday');
      return;
    }
    if (_selectedCategoryIds.isEmpty) {
      Helpers.showSnackBar(context, 'Please select at least 1 category');
      return;
    }

    setState(() => _isLoading = true);
    final authProvider = context.read<AuthProvider>();
    final ok = await authProvider.completePhoneProfile(
      fullName: _nameController.text.trim(),
      gender: _selectedGender,
      birthday: birthday,
      preferredCategoryIds: _selectedCategoryIds.toList(),
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (!ok) {
      Helpers.showSnackBar(
          context, authProvider.error ?? 'Failed to save profile');
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FF),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildBlueCover(),
              Transform.translate(
                offset: const Offset(0, -24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: _buildFormCard(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlueCover() {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E5BFF), Color(0xFF4A7DFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.account_circle_rounded,
                  color: Colors.white, size: 42),
            ),
            const SizedBox(height: 14),
            const Text(
              'Complete Your Profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Name, birthday, gender and categories',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.06),
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.tr('Full Name'), style: _labelStyle),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: AppInputDecorations.form(
                  hintText: context.tr('Enter your full name'),
                  prefixIcon: Icons.person_outline,
                ),
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.length < 2) return 'Name is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(context.tr('Birthday'), style: _labelStyle),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _dateField(_dayController, 'DD', 2)),
                  const SizedBox(width: 10),
                  Expanded(child: _dateField(_monthController, 'MM', 2)),
                  const SizedBox(width: 10),
                  Expanded(child: _dateField(_yearController, 'YYYY', 4)),
                ],
              ),
              const SizedBox(height: 16),
              Text(context.tr('Gender'), style: _labelStyle),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                      child: _genderCard('male', 'Male', Icons.male_rounded)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _genderCard(
                          'female', 'Female', Icons.female_rounded)),
                ],
              ),
              const SizedBox(height: 16),
              Text(context.tr('Favorite Categories'), style: _labelStyle),
              const SizedBox(height: 8),
              InkWell(
                onTap: _loadingCategories ? null : _openCategories,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderPrimary),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.category_outlined),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedCategoryIds.isEmpty
                              ? 'Select categories'
                              : '${_selectedCategoryIds.length} selected',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                      if (_loadingCategories)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              AppPrimaryButton(
                text: 'Continue',
                onPressed: _submit,
                isLoading: _isLoading,
                height: 52,
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle get _labelStyle =>
      AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700);

  Widget _dateField(TextEditingController c, String hint, int maxLen) {
    return TextFormField(
      controller: c,
      keyboardType: TextInputType.number,
      maxLength: maxLen,
      textAlign: TextAlign.center,
      decoration: AppInputDecorations.form(hintText: hint, suffixText: ''),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Req' : null,
    );
  }

  Widget _genderCard(String value, String label, IconData icon) {
    final selected = _selectedGender == value;
    return InkWell(
      onTap: () => setState(() => _selectedGender = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.10) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderPrimary,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(height: 6),
            Text(label),
          ],
        ),
      ),
    );
  }
}
