import 'package:wino/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/api_config.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/category_model.dart';
import '../home/main_navigation_screen.dart';
import '../common/location_picker_screen.dart';
import '../search/category_selection_screen.dart';
import 'widgets/auth_flow_components.dart';

class PhoneProfileSetupScreen extends StatefulWidget {
  const PhoneProfileSetupScreen({super.key});

  @override
  State<PhoneProfileSetupScreen> createState() =>
      _PhoneProfileSetupScreenState();
}

class _PhoneProfileSetupScreenState extends State<PhoneProfileSetupScreen> {
  static const int _maxCategorySelection = 6;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dayController = TextEditingController();
  final _monthController = TextEditingController();
  final _yearController = TextEditingController();

  final _dayFocusNode = FocusNode();
  final _monthFocusNode = FocusNode();
  final _yearFocusNode = FocusNode();

  String _selectedGender = 'male';
  String? _selectedWilaya;
  String? _selectedBaladiya;
  String _selectedAddress = '';
  bool _showValidation = false;
  bool _loadingCategories = false;
  List<Category> _categories = [];
  Set<int> _selectedCategoryIds = {};
  String? _categoriesLoadError;

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

  bool get _hasSelectedLocation {
    return _selectedWilaya != null && _selectedBaladiya != null;
  }

  List<Category> get _selectedCategories {
    return _categories
        .where((category) => _selectedCategoryIds.contains(category.id))
        .toList(growable: false);
  }

  @override
  void dispose() {
    _nameController.dispose();
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

    if (!_showValidation && !_hasStartedBirthday) {
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
    if (_showValidation && _selectedCategoryIds.isEmpty) {
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

  Future<void> _openLocationPicker() async {
    FocusScope.of(context).unfocus();

    final result = await Navigator.push<LocationResult>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialWilaya: _selectedWilaya,
          initialBaladiya: _selectedBaladiya,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedWilaya = result.wilaya;
        _selectedBaladiya = result.baladiya;
        _selectedAddress = result.address;
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

  Future<void> _submit() async {
    setState(() => _showValidation = true);

    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_birthdayError(context) != null || _categoriesError(context) != null) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.completePhoneProfile(
      fullName: _nameController.text.trim(),
      gender: _selectedGender,
      birthday: _parsedBirthday!,
      address: _selectedAddress,
      preferredCategoryIds: _selectedCategoryIds.toList(),
    );

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (_) => false,
      );
      return;
    }

    Helpers.showSnackBar(
      context,
      authProvider.error ?? context.l10n.authProfileSaveError,
      isError: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selectedLabels =
        _selectedCategories.map((category) => category.name).toList();

    return AuthFlowScaffold(
      title: l10n.authProfileSetupHeaderTitle,
      subtitle: l10n.authProfileSetupHeaderSubtitle,
      icon: Icons.verified_user_outlined,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppConstants.spacing12),
            AppTextField(
              controller: _nameController,
              label: l10n.authFieldFullName,
              hint: l10n.authFieldFullNameHint,
              textInputAction: TextInputAction.next,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              autofillHints: const [AutofillHints.name],
              validator: (value) {
                if ((value ?? '').trim().length < 2) {
                  return l10n.authErrorNameRequired;
                }
                return null;
              },
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
            const SizedBox(height: AppConstants.spacing20),
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
            const SizedBox(height: AppConstants.spacing20),
            AuthSelectionField(
              label: context.tr('Store location (optional)'),
              hint: context.tr('Select wilaya and baladiya (optional)'),
              value: _hasSelectedLocation
                  ? '${context.tr(_selectedBaladiya!)}, ${context.tr(_selectedWilaya!)}'
                  : null,
              helperText: _hasSelectedLocation
                  ? context.tr(
                      'People searching in that baladiya will see your posts unless you enable delivery.')
                  : context.tr(
                      'You can skip this step for now. Add your wilaya and baladiya later if you want better local search visibility.',
                    ),
              icon: Icons.location_on_outlined,
              onTap: _openLocationPicker,
            ),
            const SizedBox(height: AppConstants.spacing12),
            AuthInlineMessage(
              text: context.tr(
                'Location is optional. If you add it, your posts can appear more accurately to people searching in that wilaya or baladiya.',
              ),
            ),
            const SizedBox(height: AppConstants.spacing28),
            Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                return AppPrimaryButton(
                  text: l10n.commonContinue,
                  onPressed: authProvider.isLoading ? null : _submit,
                  isLoading: authProvider.isLoading,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
