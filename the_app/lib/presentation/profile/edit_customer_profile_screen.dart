import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/api_service.dart';
import '../../core/config/api_config.dart';
import '../../core/utils/helpers.dart';

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
        'full_name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
      };

      final userData = StorageService.getUserData();
      final userId = userData?['id'];
      if (userId == null) throw Exception('لا يمكن تحديد معرف المستخدم');

      await ApiService.patch(ApiConfig.userDetail(userId), updateData);
      
      // Update local storage
      if (userData != null) {
        userData['full_name'] = _nameController.text;
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

// Placeholder for Become Merchant Screen
class BecomeMerchantScreen extends StatefulWidget {
  const BecomeMerchantScreen({super.key});

  @override
  State<BecomeMerchantScreen> createState() => _BecomeMerchantScreenState();
}

class _BecomeMerchantScreenState extends State<BecomeMerchantScreen> {
  bool _isLoading = false;

  Future<void> _convertToMerchant() async {
    setState(() => _isLoading = true);
    
    try {
      final userData = StorageService.getUserData();
      final userId = userData?['id'];
      if (userId == null) throw Exception('لا يمكن تحديد معرف المستخدم');

      await ApiService.patch(ApiConfig.userDetail(userId), {'role': 'STORE'});

      // Update local storage
      if (userData != null) {
        userData['role'] = 'STORE';
        userData['user_type'] = 'merchant';
        userData['is_merchant'] = true;
        await StorageService.saveUserData(userData);
      }

      if (mounted) {
        Helpers.showSnackBar(context, 'تهانينا! أصبحت بائعاً الآن 🎉');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'فشل التحويل: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('أصبح بائعاً'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Hero Section
            Container(
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
                    color: AppColors.primaryPurple.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.store_rounded, size: 60, color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    'ابدأ رحلتك في البيع!',
                    style: AppTextStyles.h3.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'حوّل حسابك إلى حساب بائع وابدأ ببيع منتجاتك',
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Benefits
            _buildBenefitItem(Icons.inventory_2_rounded, 'إضافة منتجات غير محدودة'),
            _buildBenefitItem(Icons.local_offer_rounded, 'إنشاء عروض ترويجية'),
            _buildBenefitItem(Icons.analytics_rounded, 'متابعة إحصائيات المبيعات'),
            _buildBenefitItem(Icons.message_rounded, 'التواصل مع العملاء'),
            
            const SizedBox(height: 32),

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
                        'تحويل الحساب إلى بائع',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryPurple, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(text, style: AppTextStyles.bodyMedium),
          ),
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
        ],
      ),
    );
  }
}