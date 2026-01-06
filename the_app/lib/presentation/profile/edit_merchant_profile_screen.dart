import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
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

class _EditMerchantProfileScreenState extends State<EditMerchantProfileScreen> 
    with SingleTickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _descriptionController;
  late TextEditingController _addressController;
  late TabController _tabController;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  String? _avatarUrl;
  int? _storeId;
  LatLng? _selectedLocation;
  String _selectedLocationText = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _descriptionController = TextEditingController(text: widget.initialStoreDescription ?? '');
    _addressController = TextEditingController();
    _avatarUrl = widget.initialImage;
    _loadAddress();
    _loadStoreId();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _loadAddress() {
    if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
      _addressController.text = widget.initialAddress!;
    } else {
      final userData = StorageService.getUserData();
      if (userData != null) {
        _addressController.text = userData['location'] ?? userData['address'] ?? '';
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

      // Update store data (name, description, address, phone_number)
      if (_storeId != null) {
        final storeUpdateData = {
          'name': _nameController.text,
          'description': _descriptionController.text,
          'address': _addressController.text,
          'phone_number': _phoneController.text,
        };
        
        // Add location coordinates if selected
        if (_selectedLocation != null) {
          storeUpdateData['latitude'] = _selectedLocation!.latitude.toString();
          storeUpdateData['longitude'] = _selectedLocation!.longitude.toString();
        }
        
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
          initialLocation: _selectedLocation,
          initialAddress: _selectedLocationText,
        ),
      ),
    );
    
    if (result != null) {
      setState(() {
        _selectedLocation = result.coordinates;
        _selectedLocationText = result.address;
        _addressController.text = result.address;
      });
    }
  }

  Future<void> _becomeCustomer() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Convert Account'),
        content: const Text('Do you really want to convert your account from seller to regular customer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _convertToCustomer();
            },
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
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

      // Update storage
      if (userData != null) {
        userData['user_type'] = 'user';
        userData['role'] = 'USER';
        userData['is_merchant'] = false;
        await StorageService.saveUserData(userData);
      }

      // Update AuthProvider to reflect new role
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
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Edit Profile',
            style: AppTextStyles.h3,
          ),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primaryBlue,
            labelColor: AppColors.primaryBlue,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: const [
              Tab(
                icon: Icon(Icons.store),
                text: 'Information',
              ),
              Tab(
                icon: Icon(Icons.location_on),
                text: 'Location',
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildInformationTab(),
            _buildLocationTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildInformationTab() {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      children: [
            // Avatar Section - Aligned to the RIGHT
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: _isUploadingImage ? null : _pickImage,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey[300]!, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.grey.shade100,
                        child: _isUploadingImage
                            ? const CircularProgressIndicator(strokeWidth: 2)
                            : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                                ? ClipOval(
                                    child: Image.network(
                                      _avatarUrl!,
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 45, color: Colors.grey),
                                    ),
                                  )
                                : const Icon(Icons.person, size: 45, color: Colors.grey),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey[600],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing24),

            // Store Name Field
            Text('Store Name', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppTheme.spacing8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Elegant Store',
                border: OutlineInputBorder(
                  borderRadius: AppTheme.mediumRadius,
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppTheme.mediumRadius,
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: AppTheme.spacing20),

            // Address Field
            Text('Address', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppTheme.spacing8),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                hintText: 'Algeria, Algiers',
                border: OutlineInputBorder(
                  borderRadius: AppTheme.mediumRadius,
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppTheme.mediumRadius,
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: AppTheme.spacing20),

            // Phone Field
            Text('Phone Number', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppTheme.spacing8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.left,
              decoration: InputDecoration(
                hintText: '+966 50 123 4567',
                hintTextDirection: TextDirection.ltr,
                border: OutlineInputBorder(
                  borderRadius: AppTheme.mediumRadius,
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppTheme.mediumRadius,
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: AppTheme.spacing20),

            // Email Field
            Text('Email', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppTheme.spacing8),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.left,
              decoration: InputDecoration(
                hintText: 'store@example.com',
                hintTextDirection: TextDirection.ltr,
                border: OutlineInputBorder(
                  borderRadius: AppTheme.mediumRadius,
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppTheme.mediumRadius,
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: AppTheme.spacing20),

            // Store Description Field
            Text('Store Description', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppTheme.spacing8),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Store specialized in fashion and modern style',
                border: OutlineInputBorder(
                  borderRadius: AppTheme.mediumRadius,
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppTheme.mediumRadius,
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: AppTheme.spacing20),

            // Store Location Field
            Text('Store Location', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppTheme.spacing8),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                hintText: 'Algeria, Algiers',
                border: OutlineInputBorder(
                  borderRadius: AppTheme.mediumRadius,
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppTheme.mediumRadius,
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            InkWell(
              onTap: _openLocationPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: AppTheme.mediumRadius,
                  border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: AppColors.primaryBlue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedLocationText.isNotEmpty 
                          ? 'Location: $_selectedLocationText'
                          : 'Set Location on Map',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.primaryBlue,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing32),

            // Save Button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
                shape: RoundedRectangleBorder(borderRadius: AppTheme.mediumRadius),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text('Save Changes', style: AppTextStyles.bodyLarge.copyWith(color: Colors.white)),
            ),
            const SizedBox(height: AppTheme.spacing16),

            // Become Customer Button
            OutlinedButton.icon(
              onPressed: _becomeCustomer,
              icon: const Icon(Icons.person_outline, color: Colors.red),
              label: Text(
                'Convert to Regular User Account',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red, width: 1),
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
                shape: RoundedRectangleBorder(borderRadius: AppTheme.mediumRadius),
              ),
            ),
            const SizedBox(height: AppTheme.spacing20),
          ],
        );
  }

  Widget _buildLocationTab() {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      children: [
        Text(
          'Store Location',
          style: AppTextStyles.h4.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.spacing16),
        
        Text(
          'Current Address',
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppTheme.spacing8),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_on,
                color: AppColors.primaryBlue,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedLocationText.isEmpty 
                      ? (_addressController.text.isEmpty ? 'No location selected' : _addressController.text)
                      : _selectedLocationText,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: (_selectedLocationText.isEmpty && _addressController.text.isEmpty)
                        ? AppColors.textSecondary 
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacing16),
        
        ElevatedButton.icon(
          onPressed: _openLocationPicker,
          icon: const Icon(Icons.edit_location),
          label: Text(
            (_selectedLocationText.isEmpty && _addressController.text.isEmpty) 
                ? 'Select Location' 
                : 'Change Location',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        
        if (_selectedLocation != null) ...[
          const SizedBox(height: AppTheme.spacing16),
          Text(
            'Coordinates',
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.explore,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Latitude: ${_selectedLocation!.latitude.toStringAsFixed(6)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.explore_off,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Longitude: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        
        const SizedBox(height: AppTheme.spacing32),
        
        // Save Button for location tab
        ElevatedButton(
          onPressed: _isLoading ? null : _saveProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
            shape: RoundedRectangleBorder(borderRadius: AppTheme.mediumRadius),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text('Save Location', style: AppTextStyles.bodyLarge.copyWith(color: Colors.white)),
        ),
      ],
    );
  }
}
