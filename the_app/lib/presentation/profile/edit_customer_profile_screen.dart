import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
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

class _EditCustomerProfileScreenState extends State<EditCustomerProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  bool _isLoading = false;

  // Location data
  String? _selectedWilaya;
  String? _selectedBaladiya;
  String _selectedAddress = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _loadUserLocation();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserLocation() async {
    final userData = StorageService.getUserData();
    if (userData != null) {
      final address = userData['address']?.toString() ?? '';
      setState(() {
        _selectedAddress = address;
        _parseAddressToWilayaBaladiya(address);
      });
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

  Future<void> _becomeSeller() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BecomeMerchantScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = _selectedWilaya != null && _selectedBaladiya != null;

    return Directionality(
      textDirection: TextDirection.rtl,
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
            // User Avatar Header
            Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.primaryColor, AppColors.primaryColor.withValues(alpha: 0.6)],
                  ),
                ),
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person_rounded, size: 48, color: AppColors.primaryColor),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Form Fields
            _buildFormField(
              label: 'Full Name',
              controller: _nameController,
              hint: 'Enter your full name',
              icon: Icons.person_rounded,
            ),
            _buildFormField(
              label: 'Email',
              controller: _emailController,
              hint: 'email@example.com',
              icon: Icons.email_rounded,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
            ),
            _buildFormField(
              label: 'Phone Number',
              controller: _phoneController,
              hint: '+213 XXX XXX XXX',
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
            ),

            const SizedBox(height: 8),

            // Location Section
            Text('Location', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
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
                        hasLocation ? Icons.check_circle : Icons.add_location_rounded,
                        color: hasLocation ? AppColors.successGreen : AppColors.primaryColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasLocation ? '$_selectedBaladiya, $_selectedWilaya' : 'Select your location',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: hasLocation ? AppColors.textPrimary : AppColors.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (!hasLocation)
                            Text(
                              'Tap to choose wilaya and baladiya',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          if (hasLocation)
                            Text(
                              'Tap to change',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: hasLocation ? AppColors.successGreen : AppColors.primaryColor,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Save Button
            _buildPrimaryButton(
              label: 'Save Changes',
              onPressed: _isLoading ? null : _saveProfile,
              isLoading: _isLoading,
              color: AppColors.primaryColor,
            ),
            const SizedBox(height: 16),

            // Become Seller Button
            _buildSecondaryButton(
              label: 'Become a Seller',
              onPressed: _becomeSeller,
              icon: Icons.store_rounded,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextDirection? textDirection,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
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
            ),
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              textDirection: textDirection,
              textAlign: textDirection == TextDirection.ltr ? TextAlign.left : TextAlign.start,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
                prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onPressed,
    required Color color,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Text(label, style: AppTextStyles.buttonText.copyWith(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String label,
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: AppColors.primaryPurple),
        label: Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryPurple, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.primaryPurple, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
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
  String? _selectedWilaya;
  String? _selectedBaladiya;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final userData = StorageService.getUserData();
    if (userData != null) {
      _storePhoneController.text = userData['phone'] ?? '';
      final userName = userData['name']?.toString() ?? '';
      if (userName.isNotEmpty) {
        _storeNameController.text = '$userName Store';
        _storeDescriptionController.text =
            'Welcome to $userName Store! We offer quality products with excellent service.';
      }
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
          initialWilaya: _selectedWilaya,
          initialBaladiya: _selectedBaladiya,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedWilaya = result.wilaya;
        _selectedBaladiya = result.baladiya;
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
    final hasLocation = _selectedWilaya != null && _selectedBaladiya != null;

    return Directionality(
      textDirection: TextDirection.rtl,
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
          title: Text('Create Your Store', style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700)),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryPurple, AppColors.primaryPurple.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPurple.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.store_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start Selling Today',
                          style: AppTextStyles.h4.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enter your store details to start selling',
                          style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormField(
                      label: 'Store Name *',
                      controller: _storeNameController,
                      hint: 'Example: Elegant Store',
                      icon: Icons.store_rounded,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter store name';
                        }
                        return null;
                      },
                    ),
                    _buildFormField(
                      label: 'Store Description',
                      controller: _storeDescriptionController,
                      hint: 'Describe your store and products...',
                      icon: Icons.description_rounded,
                      maxLines: 3,
                    ),
                    _buildFormField(
                      label: 'Phone Number',
                      controller: _storePhoneController,
                      hint: '+213 XXX XXX XXX',
                      icon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr,
                    ),

                    // Location Section
                    Text('Store Location', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _openLocationPicker,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: hasLocation
                              ? AppColors.successGreen.withValues(alpha: 0.08)
                              : AppColors.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: hasLocation
                                ? AppColors.successGreen.withValues(alpha: 0.3)
                                : AppColors.primaryColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              hasLocation ? Icons.check_circle : Icons.add_location_rounded,
                              color: hasLocation ? AppColors.successGreen : AppColors.primaryColor,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    hasLocation ? '$_selectedBaladiya, $_selectedWilaya' : 'Select store location',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: hasLocation ? AppColors.successGreen : AppColors.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (!hasLocation)
                                    Text(
                                      'Tap to choose wilaya and baladiya',
                                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                                    ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: hasLocation ? AppColors.successGreen : AppColors.primaryColor,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Benefits Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Seller Benefits', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  _buildBenefitItem(Icons.inventory_2_rounded, 'Add products and packs'),
                  _buildBenefitItem(Icons.local_offer_rounded, 'Create promotional offers'),
                  _buildBenefitItem(Icons.message_rounded, 'Communicate with customers'),
                  _buildBenefitItem(Icons.analytics_rounded, 'View store statistics'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Create Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _convertToMerchant,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        'Create Store and Start Selling',
                        style: AppTextStyles.buttonText.copyWith(fontWeight: FontWeight.w600),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextDirection? textDirection,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            textDirection: textDirection,
            textAlign: textDirection == TextDirection.ltr ? TextAlign.left : TextAlign.start,
            maxLines: maxLines,
            validator: validator,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
              prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 22),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.neutral200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.neutral200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.primaryPurple, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.errorRed),
              ),
              filled: true,
              fillColor: AppColors.neutral50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ],
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
              color: AppColors.primaryPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryPurple, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: AppTextStyles.bodyMedium),
          ),
          Icon(Icons.check_circle, color: AppColors.successGreen, size: 20),
        ],
      ),
    );
  }
}
