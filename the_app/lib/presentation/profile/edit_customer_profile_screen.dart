import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/config/api_config.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/app_text_field.dart';
import '../common/location_picker_screen.dart';

class EditCustomerProfileScreen extends StatefulWidget {
  final String initialName;
  final String initialPhone;
  final String? initialImage;
  final String? initialAddress;

  const EditCustomerProfileScreen({
    super.key,
    required this.initialName,
    required this.initialPhone,
    this.initialImage,
    this.initialAddress,
  });

  @override
  State<EditCustomerProfileScreen> createState() =>
      _EditCustomerProfileScreenState();
}

class _EditCustomerProfileScreenState extends State<EditCustomerProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  bool _isLoading = false;
  bool _isUploadingImage = false;

  String? _avatarUrl;
  String? _selectedWilaya;
  String? _selectedBaladiya;
  String _selectedAddress = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _avatarUrl = widget.initialImage;

    _selectedAddress = widget.initialAddress ?? '';
    if (_selectedAddress.isEmpty) {
      final userData = StorageService.getUserData();
      _selectedAddress = userData?['address']?.toString() ?? '';
    }
    _parseAddressToWilayaBaladiya(_selectedAddress);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _parseAddressToWilayaBaladiya(String address) {
    if (!address.contains(',')) return;
    final parts = address.split(',').map((e) => e.trim()).toList();
    if (parts.length < 2) return;
    _selectedBaladiya = parts[0];
    _selectedWilaya = parts[1];
  }

  Future<ImageSource?> _showImageSourcePicker() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose image source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(Icons.camera_alt, color: AppColors.primaryColor),
              title: const Text('Camera'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library,
                  color: AppColors.primaryColor),
              title: const Text('Gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final source = await _showImageSourcePicker();
    if (source == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) {
      if (mounted) {
        Helpers.showSnackBar(context, 'No image selected');
      }
      return;
    }

    setState(() => _isUploadingImage = true);
    try {
      final userData = StorageService.getUserData();
      final userId = userData?['id'];
      if (userId == null) throw Exception('Cannot determine user ID');

      await ApiService.updateMultipart(
        ApiConfig.userDetail(userId),
        {},
        pickedFile,
        'profile_image',
        method: 'PATCH',
      );

      final response = await ApiService.get(ApiConfig.userDetail(userId));
      await StorageService.saveUserData(response);

      setState(() {
        _avatarUrl = (response is Map)
            ? (response['profile_image'] ?? response['avatar'])?.toString()
            : _avatarUrl;
      });

      if (mounted) {
        Helpers.showSnackBar(context, 'Profile picture updated successfully');
      }
    } catch (e) {
      if (mounted) Helpers.showSnackBar(context, 'Failed to update image: $e');
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _deleteImage() async {
    if (_isUploadingImage) return;
    final userData = StorageService.getUserData();
    final userId = userData?['id'];
    if (userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete profile image?'),
        content: const Text('This will remove your current profile image.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isUploadingImage = true);
    try {
      await ApiService.patch(
          ApiConfig.userDetail(userId), {'profile_image': null});
      final response = await ApiService.get(ApiConfig.userDetail(userId));
      await StorageService.saveUserData(response);
      setState(() => _avatarUrl = null);
      if (mounted) {
        Helpers.showSnackBar(context, 'Profile image deleted successfully');
      }
    } catch (e) {
      if (mounted) Helpers.showSnackBar(context, 'Failed to delete image: $e');
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _selectLocation() async {
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
        _selectedAddress = result.address;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      Helpers.showSnackBar(context, 'Please fill in all required fields');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userData = StorageService.getUserData();
      final userId = userData?['id'];
      if (userId == null) throw Exception('Cannot determine user ID');

      final updateData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _selectedAddress.trim(),
      };

      await ApiService.patch(ApiConfig.userDetail(userId), updateData);

      if (userData != null) {
        userData['name'] = updateData['name'];
        userData['phone'] = updateData['phone'];
        userData['address'] = updateData['address'];
        await StorageService.saveUserData(userData);
      }

      if (mounted) {
        Helpers.showSnackBar(context, 'Data saved successfully');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) Helpers.showSnackBar(context, 'Error saving data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = _selectedWilaya != null && _selectedBaladiya != null;

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
              child: const Icon(Icons.arrow_forward_ios,
                  size: 16, color: AppColors.textPrimary),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Edit Profile',
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700)),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: SizedBox(
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveProfile,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(0, 40),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: GestureDetector(
                onTap: _isUploadingImage ? null : _pickImage,
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryColor,
                            AppColors.primaryColor.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 56,
                        backgroundColor: Colors.white,
                        child: _isUploadingImage
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                                ? ClipOval(
                                    child: Image.network(
                                      _avatarUrl!,
                                      width: 112,
                                      height: 112,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(
                                        Icons.person_rounded,
                                        size: 48,
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                  )
                                : Icon(Icons.person_rounded,
                                    size: 48, color: AppColors.primaryColor),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: const Icon(Icons.camera_alt,
                                size: 16, color: Colors.white),
                          ),
                          if ((_avatarUrl ?? '').isNotEmpty) ...[
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: _isUploadingImage ? null : _deleteImage,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.red.shade100, width: 2),
                                ),
                                child: Icon(Icons.delete_outline,
                                    size: 16, color: Colors.red.shade500),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            AppTextField(
              controller: _nameController,
              label: 'Full Name',
              hint: 'Enter your full name',
              icon: Icons.person_rounded,
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
            const SizedBox(height: 8),
            Text('Location',
                style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            InkWell(
              onTap: _selectLocation,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: hasLocation
                      ? AppColors.successGreen.withValues(alpha: 0.08)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: hasLocation
                        ? AppColors.successGreen.withValues(alpha: 0.3)
                        : AppColors.neutral200,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowLight,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: hasLocation
                            ? AppColors.successGreen.withValues(alpha: 0.1)
                            : AppColors.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        hasLocation
                            ? Icons.check_circle
                            : Icons.add_location_rounded,
                        color: hasLocation
                            ? AppColors.successGreen
                            : AppColors.primaryColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasLocation
                                ? '$_selectedBaladiya, $_selectedWilaya'
                                : 'Select your location',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: hasLocation
                                  ? AppColors.textPrimary
                                  : AppColors.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            hasLocation
                                ? 'Tap to change'
                                : 'Tap to choose location',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: hasLocation
                          ? AppColors.successGreen
                          : AppColors.primaryColor,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}
