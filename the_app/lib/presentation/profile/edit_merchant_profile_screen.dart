import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/api_service.dart';
import '../../core/config/api_config.dart';
import '../../core/utils/helpers.dart';

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
  late TextEditingController _addressController;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _descriptionController = TextEditingController(text: widget.initialStoreDescription ?? '');
    _addressController = TextEditingController();
    _avatarUrl = widget.initialImage;
    _loadAddress();
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() => _isUploadingImage = true);

      try {
        final userData = StorageService.getUserData();
        final userId = userData?['id'];
        if (userId == null) throw Exception('لا يمكن تحديد معرف المستخدم');

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

        if (mounted) Helpers.showSnackBar(context, 'تم تحديث الصورة الشخصية بنجاح');
      } catch (e) {
        if (mounted) Helpers.showSnackBar(context, 'فشل تحديث الصورة: $e');
      } finally {
        if (mounted) setState(() => _isUploadingImage = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
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
        'store_description': _descriptionController.text,
        'location': _addressController.text,
      };

      final userData = StorageService.getUserData();
      final userId = userData?['id'];
      if (userId == null) throw Exception('لا يمكن تحديد معرف المستخدم');

      await ApiService.patch(ApiConfig.userDetail(userId), updateData);

      if (userData != null) {
        userData['full_name'] = _nameController.text;
        userData['email'] = _emailController.text;
        userData['phone'] = _phoneController.text;
        userData['store_description'] = _descriptionController.text;
        userData['location'] = _addressController.text;
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

  Future<void> _becomeCustomer() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تحويل الحساب'),
        content: const Text('هل تريد حقاً تحويل حسابك من بائع إلى عميل عادي؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _convertToCustomer();
            },
            child: const Text('نعم', style: TextStyle(color: Colors.red)),
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
      if (userId == null) throw Exception('لا يمكن تحديد معرف المستخدم');

      await ApiService.patch(ApiConfig.userDetail(userId), {'role': 'USER'});

      // Update storage
      if (userData != null) {
        userData['user_type'] = 'user';
        userData['role'] = 'USER';
        userData['is_merchant'] = false;
        await StorageService.saveUserData(userData);
      }

      if (mounted) {
        Helpers.showSnackBar(context, 'تم تحويل حسابك بنجاح');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'خطأ في تحويل الحساب: $e');
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
            'تعديل الملف الشخصي',
            style: AppTextStyles.h3,
          ),
          centerTitle: true,
        ),
        body: ListView(
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
            Text('اسم المتجر', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppTheme.spacing8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'متجر الأناقة',
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
            Text('العنوان', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppTheme.spacing8),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                hintText: 'الرياض، المملكة العربية السعودية',
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
            Text('رقم الهاتف', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
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
            Text('البريد الإلكتروني', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
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
            Text('وصف المتجر', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppTheme.spacing8),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'متجر متخصص في الأزياء والموضة العصرية',
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
            Text('موقع المتجر', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppTheme.spacing8),
            InkWell(
              onTap: () {
                // TODO: Open map picker
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppTheme.mediumRadius,
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'تعيين الموقع على الخريطة',
                      style: TextStyle(color: Colors.grey[600]),
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
                  : Text('حفظ التغييرات', style: AppTextStyles.bodyLarge.copyWith(color: Colors.white)),
            ),
            const SizedBox(height: AppTheme.spacing16),

            // Become Customer Button
            OutlinedButton.icon(
              onPressed: _becomeCustomer,
              icon: const Icon(Icons.person_outline, color: Colors.red),
              label: Text(
                'التحويل إلى حساب مستخدم عادي',
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
        ),
      ),
    );
  }
}
