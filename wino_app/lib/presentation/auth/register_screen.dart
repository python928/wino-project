import 'package:wino/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/api_config.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/routing/routes.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/category_model.dart';
import '../search/category_selection_screen.dart';
import 'widgets/auth_flow_components.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const int _totalSteps = 3;
  static const int _maxCategorySelection = 6;

  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dayController = TextEditingController();
  final _monthController = TextEditingController();
  final _yearController = TextEditingController();

  final _dayFocusNode = FocusNode();
  final _monthFocusNode = FocusNode();
  final _yearFocusNode = FocusNode();

  int _currentStep = 0;
  String _selectedGender = 'male';
  List<Category> _categories = [];
  Set<int> _selectedCategoryIds = {};
  bool _loadingCategories = false;
  bool _showStepValidation = false;
  String? _categoriesLoadError;

  String _normalizeDigits(String input) {
    const arabicIndic = '٠١٢٣٤٥٦٧٨٩';
    const easternArabicIndic = '۰۱۲۳۴۵۶۷۸۹';
    var out = input;
    for (var i = 0; i < 10; i++) {
      out = out.replaceAll(arabicIndic[i], '$i');
      out = out.replaceAll(easternArabicIndic[i], '$i');
    }
    return out;
  }

  DateTime? get _parsedBirthday {
    final day = int.tryParse(_dayController.text.trim());
    final month = int.tryParse(_monthController.text.trim());
    final year = int.tryParse(_yearController.text.trim());

    if (day == null || month == null || year == null) {
      return null;
    }
    if (month < 1 || month > 12 || day < 1 || day > 31) {
      return null;
    }
    if (year < 1900 || year > DateTime.now().year) {
      return null;
    }

    try {
      final parsed = DateTime(year, month, day);
      if (parsed.day != day || parsed.month != month || parsed.year != year) {
        return null;
      }
      return parsed;
    } catch (_) {
      return null;
    }
  }

  bool get _hasStartedBirthday {
    return _dayController.text.trim().isNotEmpty ||
        _monthController.text.trim().isNotEmpty ||
        _yearController.text.trim().isNotEmpty;
  }

  List<Category> get _selectedCategories {
    return _categories
        .where((category) => _selectedCategoryIds.contains(category.id))
        .toList(growable: false);
  }

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
    _dayFocusNode.dispose();
    _monthFocusNode.dispose();
    _yearFocusNode.dispose();
    super.dispose();
  }

  String? _birthdayError(BuildContext context) {
    final l10n = context.l10n;

    if (!_showStepValidation && !_hasStartedBirthday) {
      return null;
    }

    if (_dayController.text.trim().isEmpty ||
        _monthController.text.trim().isEmpty ||
        _yearController.text.trim().isEmpty) {
      return l10n.authErrorBirthdayRequired;
    }

    final birthday = _parsedBirthday;
    if (birthday == null) {
      return l10n.authErrorBirthdayInvalid;
    }

    final minAgeDate = DateTime.now().subtract(const Duration(days: 365 * 13));
    if (!birthday.isBefore(minAgeDate)) {
      return l10n.authErrorMustBe13;
    }

    return null;
  }

  String? _categoriesError(BuildContext context) {
    if (_categoriesLoadError != null) {
      return _categoriesLoadError;
    }
    if (_currentStep == 2 &&
        _showStepValidation &&
        _selectedCategoryIds.isEmpty) {
      return context.l10n.authErrorCategoriesRequired;
    }
    return null;
  }

  Future<void> _fetchCategories() async {
    if (_categories.isNotEmpty || _loadingCategories) {
      return;
    }

    setState(() {
      _loadingCategories = true;
      _categoriesLoadError = null;
    });

    try {
      final response = await ApiService.get(ApiConfig.categories);
      final list = response is List ? response : (response['results'] ?? []);
      final categories = (list as List)
          .map((item) => Category.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);

      if (!mounted) {
        return;
      }

      setState(() {
        _categories = categories;
        _loadingCategories = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingCategories = false;
        _categoriesLoadError = context.l10n.authCategoriesLoadError;
      });
    }
  }

  Future<void> _openCategoriesPicker() async {
    FocusScope.of(context).unfocus();
    await _fetchCategories();

    if (!mounted || _categories.isEmpty) {
      return;
    }

    final result = await Navigator.push<Set<int>>(
      context,
      MaterialPageRoute(
        builder: (_) => CategorySelectionScreen(
          categories: _categories,
          initialSelectedCategoryIds: _selectedCategoryIds,
          title: context.l10n.authFieldCategories,
          subtitle: context.l10n.authFieldCategoriesHint,
          minSelection: 1,
          maxSelection: _maxCategorySelection,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedCategoryIds = result;
        _categoriesLoadError = null;
      });
    }
  }

  void _removeSelectedCategoryAt(int index) {
    final selectedCategories = _selectedCategories;
    if (index < 0 || index >= selectedCategories.length) {
      return;
    }

    final categoryId = selectedCategories[index].id;
    setState(() {
      _selectedCategoryIds.remove(categoryId);
      _categoriesLoadError = null;
    });
  }

  bool _validateCurrentStep() {
    setState(() => _showStepValidation = true);

    final formValid = _formKey.currentState?.validate() ?? false;

    switch (_currentStep) {
      case 0:
        return formValid && _birthdayError(context) == null;
      case 1:
        return formValid;
      case 2:
        return _categoriesError(context) == null;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (!_validateCurrentStep()) {
      return;
    }

    if (_currentStep == 1) {
      _fetchCategories();
    }

    setState(() {
      _currentStep += 1;
      _showStepValidation = false;
    });
  }

  void _previousStep() {
    if (_currentStep == 0) {
      return;
    }

    setState(() {
      _currentStep -= 1;
      _showStepValidation = false;
    });
  }

  Future<void> _handleRegister() async {
    if (!_validateCurrentStep()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final payload = {
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
      'name':
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
      'phone': _normalizeDigits(_phoneController.text.trim()),
      'gender': _selectedGender,
      'birthday': _parsedBirthday?.toIso8601String().split('T').first,
      'preferred_categories': _selectedCategoryIds.toList(),
    };

    final success = await authProvider.register(payload);
    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).pushReplacementNamed(Routes.home);
      return;
    }

    Helpers.showSnackBar(
      context,
      authProvider.error ?? context.l10n.authRegistrationFailed,
      isError: true,
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildPersonalStep();
      case 1:
        return _buildAccountStep();
      case 2:
        return _buildInterestsStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPersonalStep() {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthSectionIntro(
          eyebrow: l10n.authStepProgress(_currentStep + 1, _totalSteps),
          title: l10n.authStepPersonalTitle,
          subtitle: l10n.authStepPersonalSubtitle,
        ),
        const SizedBox(height: AppConstants.spacing28),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _firstNameController,
                label: l10n.authFieldFirstName,
                hint: l10n.authFieldFirstNameHint,
                textInputAction: TextInputAction.next,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                autofillHints: const [AutofillHints.givenName],
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return l10n.authErrorRequired;
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: AppConstants.spacing12),
            Expanded(
              child: AppTextField(
                controller: _lastNameController,
                label: l10n.authFieldLastName,
                hint: l10n.authFieldLastNameHint,
                textInputAction: TextInputAction.next,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                autofillHints: const [AutofillHints.familyName],
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return l10n.authErrorRequired;
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacing20),
        AuthDateFieldGroup(
          label: l10n.authFieldBirthday,
          dayLabel: l10n.authFieldDay,
          monthLabel: l10n.authFieldMonth,
          yearLabel: l10n.authFieldYear,
          dayHint: l10n.authFieldDayHint,
          monthHint: l10n.authFieldMonthHint,
          yearHint: l10n.authFieldYearHint,
          dayController: _dayController,
          monthController: _monthController,
          yearController: _yearController,
          dayFocusNode: _dayFocusNode,
          monthFocusNode: _monthFocusNode,
          yearFocusNode: _yearFocusNode,
          helperText: l10n.authFieldBirthdayHint,
          errorText: _birthdayError(context),
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: AppConstants.spacing20),
        Text(
          l10n.authFieldGender,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppConstants.spacing10),
        Row(
          children: [
            Expanded(
              child: AuthChoiceCard(
                label: l10n.authGenderMale,
                icon: Icons.male_rounded,
                selected: _selectedGender == 'male',
                onTap: () => setState(() => _selectedGender = 'male'),
              ),
            ),
            const SizedBox(width: AppConstants.spacing12),
            Expanded(
              child: AuthChoiceCard(
                label: l10n.authGenderFemale,
                icon: Icons.female_rounded,
                selected: _selectedGender == 'female',
                onTap: () => setState(() => _selectedGender = 'female'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccountStep() {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthSectionIntro(
          eyebrow: l10n.authStepProgress(_currentStep + 1, _totalSteps),
          title: l10n.authStepAccountTitle,
          subtitle: l10n.authStepAccountSubtitle,
        ),
        const SizedBox(height: AppConstants.spacing28),
        AppTextField(
          controller: _phoneController,
          label: l10n.authFieldPhone,
          hint: l10n.authFieldPhoneHint,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          autofillHints: const [AutofillHints.telephoneNumber],
          validator: (value) {
            final phone = _normalizeDigits((value ?? '').trim());
            if (phone.isEmpty) {
              return l10n.authErrorPhoneRequired;
            }
            if (!RegExp(r'^0[567]\d{8}$').hasMatch(phone)) {
              return l10n.authErrorPhoneInvalid;
            }
            return null;
          },
        ),
        const SizedBox(height: AppConstants.spacing16),
        AppTextField(
          controller: _emailController,
          label: l10n.authFieldEmail,
          hint: l10n.authFieldEmailHint,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          autofillHints: const [AutofillHints.email],
          validator: (value) {
            final email = (value ?? '').trim();
            if (email.isEmpty) {
              return l10n.authErrorEmailRequired;
            }
            if (!RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
              return l10n.authErrorEmailInvalid;
            }
            return null;
          },
        ),
        const SizedBox(height: AppConstants.spacing16),
        AppTextField(
          controller: _passwordController,
          label: l10n.authFieldPassword,
          hint: l10n.authFieldPasswordHint,
          obscureText: true,
          textInputAction: TextInputAction.next,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          autofillHints: const [AutofillHints.newPassword],
          validator: (value) {
            if ((value ?? '').isEmpty) {
              return l10n.authErrorPasswordRequired;
            }
            if ((value ?? '').length < 6) {
              return l10n.authErrorPasswordMin;
            }
            return null;
          },
        ),
        const SizedBox(height: AppConstants.spacing16),
        AppTextField(
          controller: _confirmPasswordController,
          label: l10n.authFieldConfirmPassword,
          hint: l10n.authFieldConfirmPasswordHint,
          obscureText: true,
          textInputAction: TextInputAction.done,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          autofillHints: const [AutofillHints.newPassword],
          validator: (value) {
            if ((value ?? '').isEmpty) {
              return l10n.authErrorConfirmPasswordRequired;
            }
            if (value != _passwordController.text) {
              return l10n.authErrorPasswordsDoNotMatch;
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildInterestsStep() {
    final l10n = context.l10n;
    final selectedLabels =
        _selectedCategories.map((category) => category.name).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthSectionIntro(
          eyebrow: l10n.authStepProgress(_currentStep + 1, _totalSteps),
          title: l10n.authStepInterestsTitle,
          subtitle: l10n.authStepInterestsSubtitle,
        ),
        const SizedBox(height: AppConstants.spacing24),
        AuthSelectionField(
          label: l10n.authFieldCategories,
          hint: l10n.authCategoriesCta,
          value: _selectedCategoryIds.isEmpty
              ? null
              : l10n.categoriesPickerSelectionCount(
                  _selectedCategoryIds.length,
                  _maxCategorySelection,
                ),
          helperText: _categoriesError(context) == null
              ? l10n.authFieldCategoriesHint
              : null,
          errorText: _categoriesError(context),
          icon: Icons.category_outlined,
          isLoading: _loadingCategories,
          onTap: _loadingCategories ? null : _openCategoriesPicker,
        ),
        if (_categoriesLoadError != null) ...[
          const SizedBox(height: AppConstants.spacing12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: _fetchCategories,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.authCategoriesRetry),
            ),
          ),
        ],
        if (selectedLabels.isNotEmpty) ...[
          const SizedBox(height: AppConstants.spacing16),
          AuthSelectionPreviewChips(
            labels: selectedLabels,
            onRemoveAt: _removeSelectedCategoryAt,
          ),
        ],
      ],
    );
  }

  Widget _buildFooter() {
    final l10n = context.l10n;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            l10n.authRegisterFooterPrompt,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pushReplacementNamed(Routes.login),
          child: Text(
            l10n.authRegisterFooterAction,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final l10n = context.l10n;

    return Column(
      children: [
        if (_currentStep < _totalSteps - 1)
          AppPrimaryButton(
            text: l10n.commonNext,
            onPressed: _nextStep,
          )
        else
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return AppPrimaryButton(
                text: l10n.authActionCreateAccount,
                onPressed: authProvider.isLoading ? null : _handleRegister,
                isLoading: authProvider.isLoading,
              );
            },
          ),
        if (_currentStep > 0) ...[
          const SizedBox(height: AppConstants.spacing12),
          AppSecondaryButton(
            text: l10n.authActionPrevious,
            onPressed: _previousStep,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return PopScope<void>(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _currentStep == 0) {
          return;
        }
        _previousStep();
      },
      child: AuthFlowScaffold(
        title: l10n.authRegisterHeaderTitle,
        subtitle: l10n.authRegisterHeaderSubtitle,
        icon: Icons.person_add_alt_1_rounded,
        currentStep: _currentStep + 1,
        totalSteps: _totalSteps,
        progressLabel: l10n.authStepProgress(_currentStep + 1, _totalSteps),
        onBack: () {
          if (_currentStep > 0) {
            _previousStep();
          } else {
            Navigator.of(context).maybePop();
          }
        },
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSwitcher(
                duration: AppConstants.shortDuration,
                child: KeyedSubtree(
                  key: ValueKey(_currentStep),
                  child: _buildStepContent(),
                ),
              ),
              const SizedBox(height: AppConstants.spacing32),
              _buildActionButtons(),
              const SizedBox(height: AppConstants.spacing20),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
