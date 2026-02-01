import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/app_button.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/api_service.dart';
import '../../core/config/api_config.dart';
import '../../core/utils/helpers.dart';
import '../../core/providers/auth_provider.dart';
import '../common/location_picker_screen.dart';

class EditMerchantProfileScreen extends StatefulWidget {
  final String initialName;
  final String initialEmail;
  final String initialPhone;
  final String? initialImage;
  final String? initialStoreDescription;
  final String? initialAddress;

  const EditMerchantProfileScreen({
    super.key,
    required this.initialName,
    required this.initialEmail,
    required this.initialPhone,
    this.initialImage,
    this.initialStoreDescription,
    this.initialAddress,
  });

  @override
  State<EditMerchantProfileScreen> createState() => _EditMerchantProfileScreenState();
}

class _EditMerchantProfileScreenState extends State<EditMerchantProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _descriptionController;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  String? _avatarUrl;
  int? _storeId;
  String? _selectedWilaya;
  String? _selectedBaladiya;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _descriptionController = TextEditingController(text: widget.initialStoreDescription ?? '');
    _avatarUrl = widget.initialImage;
    _loadAddress();
    _loadStoreId();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadAddress() {
    if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
      _parseAddressToWilayaBaladiya(widget.initialAddress!);
    } else {
      final userData = StorageService.getUserData();
      if (userData != null) {
        final address = userData['location'] ?? userData['address'] ?? '';
        _parseAddressToWilayaBaladiya(address);
      }
    }
  }

  void _parseAddressToWilayaBaladiya(String address) {
    if (address.contains(',')) {
      final parts = address.split(',').map((e) => e.trim()).toList();
      if (parts.length >= 2) {
        _selectedBaladiya = parts[0];
        _selectedWilaya = parts[1];
      }
    }
  }

  Future<void> _loadStoreId() async {
    try {
      final userData = StorageService.getUserData();
      final userId = userData?['id'];
      if (userId == null) return;

      final response = await ApiService.get('${ApiConfig.stores}?owner=$userId');
      final storesList = response is Map && response.containsKey('results')
          ? response['results'] as List
          : (response is List ? response : []);

      if (storesList.isNotEmpty) {
        setState(() {
          _storeId = storesList.first['id'];
        });
      }
    } catch (e) {
      debugPrint('Error loading store ID: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() => _isUploadingImage = true);

      try {
        final userData = StorageService.getUserData();
        final userId = userData?['id'];
        if (userId == null) throw Exception('Cannot identify user ID');

        final file = File(pickedFile.path);
        await ApiService.updateMultipart(
          '${ApiConfig.users}$userId/',
          {},
          file,
          'profile_image',
          method: 'PATCH'
        );

        final response = await ApiService.get('${ApiConfig.users}$userId/');
        await StorageService.saveUserData(response);

        setState(() {
          _avatarUrl = response['profile_image'] ?? response['avatar'];
        });

        if (mounted) Helpers.showSnackBar(context, 'Profile picture updated successfully');
      } catch (e) {
        if (mounted) Helpers.showSnackBar(context, 'Failed to update image: $e');
      } finally {
        if (mounted) setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      Helpers.showSnackBar(context, 'Please fill in all required fields');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userData = StorageService.getUserData();
      final userId = userData?['id'];
      if (userId == null) throw Exception('Cannot identify user ID');

      // Update user data (email, phone)
      final userUpdateData = {
        'email': _emailController.text,
        'phone': _phoneController.text,
      };
      await ApiService.patch(ApiConfig.userDetail(userId), userUpdateData);

      // Build address from wilaya/baladiya
      final address = (_selectedWilaya != null && _selectedBaladiya != null)
          ? '$_selectedBaladiya, $_selectedWilaya'
          : '';

      // Update store data (name, description, address, phone_number)
      if (_storeId != null) {
        final storeUpdateData = {
          'name': _nameController.text,
          'description': _descriptionController.text,
          'address': address,
          'phone_number': _phoneController.text,
        };

        await ApiService.patch(ApiConfig.storeDetail(_storeId!), storeUpdateData);
      }

      // Update local storage
      if (userData != null) {
        userData['email'] = _emailController.text;
        userData['phone'] = _phoneController.text;
        await StorageService.saveUserData(userData);
      }

      if (mounted) {
        Helpers.showSnackBar(context, 'Data saved successfully');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Error saving data: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.push<LocationResult>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialWilaya: _selectedWilaya,
          initialBaladiya: _selectedBaladiya,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedWilaya = result.wilaya;
        _selectedBaladiya = result.baladiya;
      });
    }
  }

  Future<void> _becomeCustomer() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_rounded, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Convert Account')),
          ],
        ),
        content: const Text('Do you really want to convert your account from seller to regular customer?'),
        actions: [
          AppTextButton(
            text: 'Cancel',
            onPressed: () => Navigator.pop(context),
          ),
          AppDangerButton(
            text: 'Yes, Convert',
            onPressed: () {
              Navigator.pop(context);
              _convertToCustomer();
            },
            width: 120,
          ),
        ],
      ),
    );
  }

  Future<void> _convertToCustomer() async {
    setState(() => _isLoading = true);
    try {
      final userData = StorageService.getUserData();
      final userId = userData?['id'];
      if (userId == null) throw Exception('Cannot identify user ID');

      await ApiService.patch(ApiConfig.userDetail(userId), {'role': 'USER'});

      if (userData != null) {
        userData['user_type'] = 'user';
        userData['role'] = 'USER';
        userData['is_merchant'] = false;
        await StorageService.saveUserData(userData);
      }

      if (mounted) {
        context.read<AuthProvider>().reloadFromStorage();
      }

      if (mounted) {
        Helpers.showSnackBar(context, 'Account converted successfully');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Error converting account: $e');
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
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textPrimary),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Edit Profile', style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700)),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Avatar Section
            Center(
              child: GestureDetector(
                onTap: _isUploadingImage ? null : _pickImage,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryColor.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: _isUploadingImage
                            ? const CircularProgressIndicator(strokeWidth: 2)
                            : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                                ? ClipOval(
                                    child: Image.network(
                                      _avatarUrl!,
                                      width: 96,
                                      height: 96,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(Icons.store, size: 40, color: AppColors.textSecondary),
                                    ),
                                  )
                                : Icon(Icons.store, size: 40, color: AppColors.textSecondary),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primaryColor, AppColors.primaryColor.withValues(alpha: 0.8)],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Form Fields
            AppTextField(
              controller: _nameController,
              label: 'Store Name',
              hint: 'Enter your store name',
              icon: Icons.store_rounded,
              style: AppTextFieldStyle.profile,
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: _phoneController,
              label: 'Phone Number',
              hint: '+213 XXX XXX XXX',
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              style: AppTextFieldStyle.profile,
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: _emailController,
              label: 'Email',
              hint: 'store@example.com',
              icon: Icons.email_rounded,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              style: AppTextFieldStyle.profile,
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: _descriptionController,
              label: 'Store Description',
              hint: 'Describe your store and products...',
              icon: Icons.description_rounded,
              maxLines: 3,
              style: AppTextFieldStyle.profile,
            ),

            // Location Section
            const SizedBox(height: 8),
            _buildLocationSection(),

            const SizedBox(height: 32),

            // Save Button
            AppPrimaryButton(
              text: 'Save Changes',
              onPressed: _saveProfile,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 12),

            // Convert Account Button
            AppSecondaryButton(
              text: 'Convert to Regular User',
              onPressed: _becomeCustomer,
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    final hasLocation = _selectedWilaya != null && _selectedBaladiya != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Store Location', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _openLocationPicker,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: hasLocation
                  ? Border.all(color: AppColors.successGreen.withValues(alpha: 0.5), width: 1.5)
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: hasLocation
                        ? AppColors.successGreen.withValues(alpha: 0.1)
                        : AppColors.neutral100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    hasLocation ? Icons.location_on : Icons.add_location_alt_outlined,
                    color: hasLocation ? AppColors.successGreen : AppColors.textSecondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: hasLocation
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedBaladiya!,
                              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedWilaya!,
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        )
                      : Text(
                          'Tap to select location',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
                        ),
                ),
                Icon(
                  Icons.chevron_left,
                  color: hasLocation ? AppColors.successGreen : AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
