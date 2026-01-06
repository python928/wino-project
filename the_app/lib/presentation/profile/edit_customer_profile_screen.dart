import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/api_service.dart';
import '../../core/config/api_config.dart';
import '../../core/utils/helpers.dart';
import '../../core/providers/auth_provider.dart';
import '../common/location_picker_screen.dart';

class EditCustomerProfileScreen extends StatefulWidget {
  final String initialName;
  final String initialEmail;
  final String initialPhone;
  final String? initialImage;

  const EditCustomerProfileScreen({
    super.key,
    required this.initialName,
    required this.initialEmail,
    required this.initialPhone,
    this.initialImage,
  });

  @override
  State<EditCustomerProfileScreen> createState() => _EditCustomerProfileScreenState();
}

class _EditCustomerProfileScreenState extends State<EditCustomerProfileScreen> 
    with SingleTickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TabController _tabController;
  bool _isLoading = false;
  
  // Location data
  String _selectedAddress = '';
  double? _selectedLatitude;
  double? _selectedLongitude;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _loadUserLocation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserLocation() async {
    final userData = StorageService.getUserData();
    if (userData != null) {
      setState(() {
        _selectedAddress = userData['address'] ?? '';
        _selectedLatitude = userData['latitude'] != null 
            ? double.tryParse(userData['latitude'].toString()) : null;
        _selectedLongitude = userData['longitude'] != null 
            ? double.tryParse(userData['longitude'].toString()) : null;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      Helpers.showSnackBar(context, 'Please fill in all required fields');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final updateData = {
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'address': _selectedAddress,
        'latitude': _selectedLatitude,
        'longitude': _selectedLongitude,
      };

      final userData = StorageService.getUserData();
      final userId = userData?['id'];
      if (userId == null) throw Exception('Cannot determine user ID');

      await ApiService.patch(ApiConfig.userDetail(userId), updateData);

      // Update local storage
      if (userData != null) {
        userData['name'] = _nameController.text;
        userData['email'] = _emailController.text;
        userData['phone'] = _phoneController.text;
        userData['address'] = _selectedAddress;
        userData['latitude'] = _selectedLatitude;
        userData['longitude'] = _selectedLongitude;
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

  Future<void> _selectLocation() async {
    final result = await Navigator.push<LocationResult>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialLocation: _selectedLatitude != null && _selectedLongitude != null
              ? LatLng(_selectedLatitude!, _selectedLongitude!)
              : null,
          initialAddress: _selectedAddress,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedAddress = result.address;
        _selectedLatitude = result.coordinates.latitude;
        _selectedLongitude = result.coordinates.longitude;
      });
    }
  }

  Future<void> _becomeSeller() async {
    // Navigate to Become Seller screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BecomeMerchantScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
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
              icon: Icon(Icons.person),
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
    );
  }

  Widget _buildInformationTab() {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      children: [
          // Form Fields
          Text('Name', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppTheme.spacing8),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Enter your full name',
              prefixIcon: const Icon(Icons.person, color: AppColors.textHint),
              border: OutlineInputBorder(borderRadius: AppTheme.mediumRadius),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: AppTheme.spacing20),

          Text('Email', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppTheme.spacing8),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'Enter your email address',
              prefixIcon: const Icon(Icons.email, color: AppColors.textHint),
              border: OutlineInputBorder(borderRadius: AppTheme.mediumRadius),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: AppTheme.spacing20),

          Text('Phone Number', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppTheme.spacing8),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'Enter your phone number',
              prefixIcon: const Icon(Icons.phone, color: AppColors.textHint),
              border: OutlineInputBorder(borderRadius: AppTheme.mediumRadius),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: AppTheme.spacing32),

          // Save Button
          ElevatedButton(
            onPressed: _isLoading ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
              shape: RoundedRectangleBorder(borderRadius: AppTheme.mediumRadius),
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

          // Become Seller Button
          OutlinedButton(
            onPressed: _becomeSeller,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primaryPurple, width: 2),
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
              shape: RoundedRectangleBorder(borderRadius: AppTheme.mediumRadius),
            ),
            child: Text(
              'Become Seller',
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.primaryPurple),
            ),
          ),
        ],
      );
  }

  Widget _buildLocationTab() {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      children: [
        Text(
          'Location Information',
          style: AppTextStyles.h4.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.spacing16),
        
        Text(
          'Current Location',
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
                  _selectedAddress.isEmpty 
                      ? 'No location selected' 
                      : _selectedAddress,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: _selectedAddress.isEmpty 
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
          onPressed: _selectLocation,
          icon: const Icon(Icons.edit_location),
          label: Text(
            _selectedAddress.isEmpty ? 'Select Location' : 'Change Location',
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
        
        if (_selectedLatitude != null && _selectedLongitude != null) ...[
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
                      'Latitude: ${_selectedLatitude!.toStringAsFixed(6)}',
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
                      'Longitude: ${_selectedLongitude!.toStringAsFixed(6)}',
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
            backgroundColor: AppColors.primaryOrange,
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
            shape: RoundedRectangleBorder(borderRadius: AppTheme.mediumRadius),
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

// Become Merchant Screen - Creates store and converts user to merchant
class BecomeMerchantScreen extends StatefulWidget {
  const BecomeMerchantScreen({super.key});

  @override
  State<BecomeMerchantScreen> createState() => _BecomeMerchantScreenState();
}

class _BecomeMerchantScreenState extends State<BecomeMerchantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final _storeDescriptionController = TextEditingController();
  final _storeAddressController = TextEditingController();
  final _storePhoneController = TextEditingController();
  bool _isLoading = false;
  LatLng? _selectedLocation;
  String _selectedLocationText = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  void _loadUserData() {
    // Pre-fill available data from user data
    final userData = StorageService.getUserData();
    if (userData != null) {
      // Auto-fill phone number
      _storePhoneController.text = userData['phone'] ?? '';
      
      // Auto-generate store name from user name if available
      final userName = userData['name']?.toString() ?? '';
      if (userName.isNotEmpty) {
        _storeNameController.text = '$userName Store';
      }
      
      // Add sample description if user name is available
      if (userName.isNotEmpty) {
        _storeDescriptionController.text = 
          'Welcome to $userName Store! We offer quality products with excellent service.';
      }
      
      // Set default address if not available
      if (_storeAddressController.text.isEmpty) {
        _storeAddressController.text = 'Algeria';
      }
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
        _storeAddressController.text = result.address;
      });
    }
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _storeDescriptionController.dispose();
    _storeAddressController.dispose();
    _storePhoneController.dispose();
    super.dispose();
  }

  Future<void> _convertToMerchant() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userData = StorageService.getUserData();
      final userId = userData?['id'];
      if (userId == null) throw Exception('Cannot identify user ID');

      // 1. Create store first
      final storeData = {
        'name': _storeNameController.text.trim(),
        'description': _storeDescriptionController.text.trim(),
        'address': _storeAddressController.text.trim(),
        'phone_number': _storePhoneController.text.trim(),
        'type': 'physical',
      };
      
      // Add location coordinates if selected
      if (_selectedLocation != null) {
        storeData['latitude'] = _selectedLocation!.latitude.toString();
        storeData['longitude'] = _selectedLocation!.longitude.toString();
      }

      await ApiService.post(ApiConfig.stores, storeData);

      // 2. Update user role to STORE
      await ApiService.patch(ApiConfig.userDetail(userId), {'role': 'STORE'});

      // 3. Update local storage
      if (userData != null) {
        userData['role'] = 'STORE';
        userData['user_type'] = 'merchant';
        userData['is_merchant'] = true;
        await StorageService.saveUserData(userData);
      }

      // 4. Update AuthProvider to reflect new role
      if (mounted) {
        context.read<AuthProvider>().reloadFromStorage();
      }

      if (mounted) {
        Helpers.showSnackBar(context, 'Congratulations! Your store has been created successfully');
        // Pop twice to go back to profile screen
        Navigator.pop(context);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Failed to create store: $e');
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
            'Create Your Store',
            style: AppTextStyles.h3,
          ),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppTheme.spacing20),
          children: [
            // Simple header section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.store_rounded, 
                      color: AppColors.primaryPurple, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Your Store',
                          style: AppTextStyles.h3,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enter your store details to start selling',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing24),
            
            // Form section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Store Name
                    Text('Store Name *', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: AppTheme.spacing8),
                    TextFormField(
                      controller: _storeNameController,
                      decoration: InputDecoration(
                        hintText: 'Example: Elegant Store',
                        border: OutlineInputBorder(
                          borderRadius: AppTheme.mediumRadius,
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppTheme.mediumRadius,
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter store name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.spacing20),

                    // Store Description
                    Text('Store Description', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: AppTheme.spacing8),
                    TextFormField(
                      controller: _storeDescriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Describe your store and products...',
                        border: OutlineInputBorder(
                          borderRadius: AppTheme.mediumRadius,
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppTheme.mediumRadius,
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing20),

                    // Store Address
                    Text('Address', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: AppTheme.spacing8),
                    TextFormField(
                      controller: _storeAddressController,
                      decoration: InputDecoration(
                        hintText: 'Example: Algeria, Oran',
                        border: OutlineInputBorder(
                          borderRadius: AppTheme.mediumRadius,
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppTheme.mediumRadius,
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing8),
                    
                    // Location picker button
                    InkWell(
                      onTap: _openLocationPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primaryBlue.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: AppColors.primaryBlue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedLocationText.isNotEmpty 
                                  ? 'Location: $_selectedLocationText'
                                  : 'Choose location on map',
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
                    const SizedBox(height: AppTheme.spacing20),

                    // Store Phone
                    Text('Phone Number', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: AppTheme.spacing8),
                    TextFormField(
                      controller: _storePhoneController,
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        hintText: '+213 XXX XXX XXX',
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
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing24),

                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing20),
            
            // Benefits section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Seller Benefits:', 
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildBenefitItem(Icons.inventory_2_rounded, 'Add products and packs'),
                  _buildBenefitItem(Icons.local_offer_rounded, 'Create promotional offers'),
                  _buildBenefitItem(Icons.message_rounded, 'Communicate with customers'),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing24),
            
            // Create button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _convertToMerchant,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white, 
                          strokeWidth: 2
                        ),
                      )
                    : Text(
                        'Create Store and Start Selling',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing20),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primaryPurple, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text, 
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Icon(Icons.check_circle_outline, 
            color: Colors.green[600], size: 18),
        ],
      ),
    );
  }
}