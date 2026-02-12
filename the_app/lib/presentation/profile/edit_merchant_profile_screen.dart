import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/api_service.dart';
import '../../core/config/api_config.dart';
import '../../core/utils/helpers.dart';
import '../common/location_picker_screen.dart';

class EditMerchantProfileScreen extends StatefulWidget {
  final String initialName;
  final String initialPhone;
  final String? initialImage;
  final String? initialCoverImage;
  final String? initialStoreDescription;
  final String? initialAddress;

  const EditMerchantProfileScreen({
    super.key,
    required this.initialName,
    required this.initialPhone,
    this.initialImage,
    this.initialCoverImage,
    this.initialStoreDescription,
    this.initialAddress,
  });

  @override
  State<EditMerchantProfileScreen> createState() =>
      _EditMerchantProfileScreenState();
}

class _EditMerchantProfileScreenState extends State<EditMerchantProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _descriptionController;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  bool _isUploadingCover = false;
  String? _avatarUrl;
  String? _coverUrl;
  int? _storeId;
  String? _selectedWilaya;
  String? _selectedBaladiya;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _descriptionController =
        TextEditingController(text: widget.initialStoreDescription ?? '');
    _avatarUrl = widget.initialImage;
    _coverUrl = widget.initialCoverImage;
    _loadAddress();
    _loadStoreId();
  }

  @override
  void dispose() {
    _nameController.dispose();
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

      final response =
          await ApiService.get('${ApiConfig.stores}?owner=$userId');
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

    if (pickedFile == null) {
      if (mounted) Helpers.showSnackBar(context, 'No image selected');
      return;
    }

    {
      setState(() => _isUploadingImage = true);

      try {
        final userData = StorageService.getUserData();
        final userId = userData?['id'];
        if (userId == null) throw Exception('Cannot identify user ID');

        final file = File(pickedFile.path);
        await ApiService.updateMultipart(
            '${ApiConfig.users}$userId/', {}, file, 'profile_image',
            method: 'PATCH');

        final response = await ApiService.get('${ApiConfig.users}$userId/');
        await StorageService.saveUserData(response);

        setState(() {
          _avatarUrl = response['profile_image'] ?? response['avatar'];
        });

        if (mounted)
          Helpers.showSnackBar(context, 'Profile picture updated successfully');
      } catch (e) {
        if (mounted)
          Helpers.showSnackBar(context, 'Failed to update image: $e');
      } finally {
        if (mounted) setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _pickCoverImage() async {
    if (_storeId == null) return;
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) {
      if (mounted) Helpers.showSnackBar(context, 'No image selected');
      return;
    }

    setState(() => _isUploadingCover = true);
    try {
      final file = File(pickedFile.path);
      await ApiService.updateMultipart(
        ApiConfig.storeDetail(_storeId!),
        {},
        file,
        'cover_image',
        method: 'PATCH',
      );

      final store = await ApiService.get(ApiConfig.storeDetail(_storeId!));
      setState(() {
        _coverUrl = store is Map ? store['cover_image']?.toString() : _coverUrl;
      });

      if (mounted) {
        Helpers.showSnackBar(context, 'Cover image updated successfully');
      }
    } catch (e) {
      if (mounted) Helpers.showSnackBar(context, 'Failed to update cover: $e');
    } finally {
      if (mounted) setState(() => _isUploadingCover = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty) {
      Helpers.showSnackBar(context, 'Please fill in all required fields');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userData = StorageService.getUserData();
      final userId = userData?['id'];
      if (userId == null) throw Exception('Cannot identify user ID');

      // Update user data (name, phone)
      final userUpdateData = {
        'name': _nameController.text,
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

        await ApiService.patch(
            ApiConfig.storeDetail(_storeId!), storeUpdateData);
      }

      // Update local storage
      if (userData != null) {
        userData['name'] = _nameController.text;
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
    // Intentionally removed from this screen per requested scope.
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
          padding: EdgeInsets.zero,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
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
                    controller: _descriptionController,
                    label: 'Description',
                    hint: 'Describe your store...',
                    icon: Icons.description_rounded,
                    maxLines: 3,
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
                  _buildLocationSection(),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 190,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primaryDeep.withValues(alpha: 0.08),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: (_coverUrl != null && _coverUrl!.isNotEmpty)
              ? ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  child: Image.network(
                    _coverUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.primaryDeep.withValues(alpha: 0.08),
                    ),
                  ),
                )
              : Container(
                  color: AppColors.primaryDeep.withValues(alpha: 0.08),
                ),
        ),
        Positioned.fill(
          child: Center(
            child: GestureDetector(
              onTap: _isUploadingCover ? null : _pickCoverImage,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: _isUploadingCover
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.camera_alt_outlined,
                        size: 24, color: AppColors.textPrimary),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -34,
          left: 20,
          child: GestureDetector(
            onTap: _isUploadingImage ? null : _pickImage,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 34,
                    backgroundColor: Colors.grey.shade100,
                    child: _isUploadingImage
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                            ? ClipOval(
                                child: Image.network(
                                  _avatarUrl!,
                                  width: 68,
                                  height: 68,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                      Icons.store,
                                      size: 30,
                                      color: Colors.grey),
                                ),
                              )
                            : const Icon(Icons.store,
                                size: 30, color: Colors.grey),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Icon(Icons.camera_alt,
                        size: 14, color: AppColors.primaryColor),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 46),
      ],
    );
  }

  Widget _buildLocationSection() {
    final hasLocation = _selectedWilaya != null && _selectedBaladiya != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Store Location',
            style:
                AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
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
                  ? Border.all(
                      color: AppColors.successGreen.withValues(alpha: 0.5),
                      width: 1.5)
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
                    hasLocation
                        ? Icons.location_on
                        : Icons.add_location_alt_outlined,
                    color: hasLocation
                        ? AppColors.successGreen
                        : AppColors.textSecondary,
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
                              style: AppTextStyles.bodyMedium
                                  .copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedWilaya!,
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        )
                      : Text(
                          'Tap to select location',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textTertiary),
                        ),
                ),
                Icon(
                  Icons.chevron_left,
                  color: hasLocation
                      ? AppColors.successGreen
                      : AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
