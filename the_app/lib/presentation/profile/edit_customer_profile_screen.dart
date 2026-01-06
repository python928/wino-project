import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/api_service.dart';
import '../../core/config/api_config.dart';
import '../../core/utils/helpers.dart';
import '../../core/providers/auth_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
    _phoneController = TextEditingController(text: widget.initialPhone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      Helpers.showSnackBar(context, 'الرجاء ملء جميع الحقول المطلوبة');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final updateData = {
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
      };

      final userData = StorageService.getUserData();
      final userId = userData?['id'];
      if (userId == null) throw Exception('لا يمكن تحديد معرف المستخدم');

      await ApiService.patch(ApiConfig.userDetail(userId), updateData);

      // Update local storage
      if (userData != null) {
        userData['name'] = _nameController.text;
        userData['email'] = _emailController.text;
        userData['phone'] = _phoneController.text;
        await StorageService.saveUserData(userData);
      }

      if (mounted) {
        Helpers.showSnackBar(context, 'تم حفظ البيانات بنجاح');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'خطأ في حفظ البيانات: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          'تعديل الملف الشخصي',
          style: AppTextStyles.h3,
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacing20),
        children: [
          // Form Fields
          Text('الاسم', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppTheme.spacing8),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'أدخل اسمك الكامل',
              prefixIcon: const Icon(Icons.person, color: AppColors.textHint),
              border: OutlineInputBorder(borderRadius: AppTheme.mediumRadius),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: AppTheme.spacing20),

          Text('البريد الإلكتروني', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppTheme.spacing8),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'أدخل بريدك الإلكتروني',
              prefixIcon: const Icon(Icons.email, color: AppColors.textHint),
              border: OutlineInputBorder(borderRadius: AppTheme.mediumRadius),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: AppTheme.spacing20),

          Text('رقم الهاتف', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppTheme.spacing8),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'أدخل رقم هاتفك',
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
                : Text('حفظ التغييرات', style: AppTextStyles.bodyLarge.copyWith(color: Colors.white)),
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
              'أصبح بائعاً',
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.primaryPurple),
            ),
          ),
        ],
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

  @override
  void initState() {
    super.initState();
    // Pre-fill phone from user data
    final userData = StorageService.getUserData();
    if (userData != null) {
      _storePhoneController.text = userData['phone'] ?? '';
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
      if (userId == null) throw Exception('لا يمكن تحديد معرف المستخدم');

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
        Helpers.showSnackBar(context, 'تهانينا! تم إنشاء متجرك بنجاح');
        // Pop twice to go back to profile screen
        Navigator.pop(context);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'فشل إنشاء المتجر: $e');
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
          title: const Text('إنشاء متجرك'),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryPurple, Color(0xFF9C27B0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryPurple.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.store_rounded, size: 50, color: Colors.white),
                      const SizedBox(height: 12),
                      Text(
                        'ابدأ رحلتك في البيع!',
                        style: AppTextStyles.h3.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'أدخل بيانات متجرك لبدء البيع',
                        style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Store Name
                Text('اسم المتجر *', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _storeNameController,
                  decoration: InputDecoration(
                    hintText: 'مثال: متجر الأناقة',
                    prefixIcon: const Icon(Icons.store, color: AppColors.textHint),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال اسم المتجر';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Store Description
                Text('وصف المتجر', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _storeDescriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'صف متجرك ومنتجاتك...',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 50),
                      child: Icon(Icons.description, color: AppColors.textHint),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // Store Address
                Text('العنوان', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _storeAddressController,
                  decoration: InputDecoration(
                    hintText: 'مثال: الجزائر، وهران',
                    prefixIcon: const Icon(Icons.location_on, color: AppColors.textHint),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // Store Phone
                Text('رقم الهاتف', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _storePhoneController,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    hintText: '+213 XXX XXX XXX',
                    hintTextDirection: TextDirection.ltr,
                    prefixIcon: const Icon(Icons.phone, color: AppColors.textHint),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),

                // Benefits
                Text('مميزات البائع:', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildBenefitItem(Icons.inventory_2_rounded, 'إضافة منتجات وحزم'),
                _buildBenefitItem(Icons.local_offer_rounded, 'إنشاء عروض ترويجية'),
                _buildBenefitItem(Icons.message_rounded, 'التواصل مع العملاء'),

                const SizedBox(height: 24),

                // Convert Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _convertToMerchant,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            'إنشاء المتجر وبدء البيع',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryPurple, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: AppTextStyles.bodyMedium),
          ),
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
        ],
      ),
    );
  }
}