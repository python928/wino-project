import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../core/services/api_service.dart';
import '../../core/config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routing/routes.dart';
import '../../core/services/storage_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/providers/post_provider.dart'; // Import PostProvider
import '../../core/providers/pack_provider.dart'; // Import PackProvider
import '../../data/models/post_model.dart';
import '../../data/models/pack_model.dart';
import '../../data/models/offer_model.dart';
import '../auth/splash_screen.dart';
import 'edit_customer_profile_screen.dart';
import 'edit_merchant_profile_screen.dart';
import 'add_product_screen.dart';
import '../home/widgets/product_card.dart'; // Import ProductCard
import 'add_promotion_screen.dart'; // Import AddPromotionScreen
import 'edit_product_screen.dart'; // Import EditProductScreen
import 'add_pack_screen.dart'; // Import AddPackScreen

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  String _userName = 'Loading...';
  String _userType = 'user';
  String _location = 'Loading...';
  String _storeDescription = '';
  String? _avatarUrl;
  int? _userId;
  bool _isUploadingImage = false;
  
  // Store specific
  String? _storeCoverUrl;
  int? _storeId;
  bool _isUploadingCover = false;

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;

  String? _lastProfileType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if profile type changed and reload data
    final authProvider = context.read<AuthProvider>();
    if (_lastProfileType != null && _lastProfileType != authProvider.activeProfileType) {
      _loadUserData();
    }
    _lastProfileType = authProvider.activeProfileType;
  }

  Future<void> _fetchStoreData() async {
    if (_userId == null) return;
    try {
      final response = await ApiService.get('${ApiConfig.stores}?owner=$_userId');
      List stores = [];
      if (response is Map && response.containsKey('results')) {
        stores = response['results'];
      } else if (response is List) {
        stores = response;
      }

      if (stores.isNotEmpty) {
        final store = stores.first;
        if (mounted) {
          setState(() {
            _storeId = store['id'];
            _storeDescription = store['description'] ?? _storeDescription;
            _storeCoverUrl = store['cover_image'];
          });
        }
      }
    } catch (e) {
      print('Error fetching store data: $e');
    }
  }

  Future<void> _pickCoverImage() async {
    if (_storeId == null) return;
    
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() => _isUploadingCover = true);
      
      try {
        final file = File(pickedFile.path);
        // Update store cover image
        // Assuming endpoint is /api/stores/stores/{id}/
        await ApiService.updateMultipart(
          '${ApiConfig.stores}$_storeId/', 
          {}, 
          file, 
          'cover_image', 
          method: 'PATCH'
        );
        
        await _fetchStoreData();
        
        if (mounted) Helpers.showSnackBar(context, 'تم تحديث صورة الغلاف بنجاح');
      } catch (e) {
        if (mounted) Helpers.showSnackBar(context, 'فشل تحديث صورة الغلاف: $e');
      } finally {
        if (mounted) setState(() => _isUploadingCover = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null && _userId != null) {
      setState(() => _isUploadingImage = true);
      
      try {
        final file = File(pickedFile.path);
        await ApiService.updateMultipart(
          '${ApiConfig.users}$_userId/', 
          {}, 
          file, 
          'profile_image', 
          method: 'PATCH'
        );
        
        // Fetch updated profile and save to storage
        // We need to import AuthRepository for this
        // But wait, AuthRepository is not imported in this file yet?
        // Let's check imports.
        // It is not. I need to add it or use ApiService directly.
        // I'll use ApiService to get profile then save.
        
        final response = await ApiService.get('${ApiConfig.users}$_userId/');
        await StorageService.saveUserData(response);
        
        _loadUserData();
        
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
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final userData = StorageService.getUserData();
    if (userData != null) {
      // Get user type from AuthProvider to stay in sync
      final authProvider = context.read<AuthProvider>();
      final isMerchantFromAuth = authProvider.activeProfileType == 'STORE';

      setState(() {
        _userId = userData['id'];
        _userName = userData['display_name'] ?? userData['full_name'] ?? userData['first_name'] ?? 'مستخدم';
        _location = userData['location'] ?? 'الجزائر العاصمة';
        // Use AuthProvider's activeProfileType for consistency
        _userType = isMerchantFromAuth ? 'merchant' : 'user';
        _storeDescription = userData['store_description'] ?? '';
        _avatarUrl = userData['profile_image'] ?? userData['avatar'];
      });

      if (_userType == 'merchant' && _userId != null) {
        _fetchStoreData().then((_) {
          // Load offers after we have the store ID
          if (mounted && _storeId != null) {
            context.read<PostProvider>().loadMyOffers(_storeId.toString());
            context.read<PackProvider>().loadMyPacks(_storeId!);
          }
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            final provider = context.read<PostProvider>();
            provider.loadMyPosts(_userId.toString());
          }
        });
      }
    } else {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SplashScreen()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  void _handleLogout() async {
    await StorageService.clearAll();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const SplashScreen()),
        (Route<dynamic> route) => false,
      );
      Helpers.showSnackBar(context, 'تم تسجيل الخروج بنجاح!');
    }
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Title
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'الإعدادات',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Edit Profile
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.edit_outlined, color: AppColors.primaryBlue),
                    ),
                    title: const Text('تعديل الملف الشخصي'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToEditProfile();
                    },
                  ),
                  // Favorites
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite_outline, color: Colors.red),
                    ),
                    title: const Text('المفضلة'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, Routes.favorites);
                    },
                  ),
                  const Divider(height: 32),
                  // Logout
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.logout, color: Colors.red),
                    ),
                    title: const Text(
                      'تسجيل الخروج',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _handleLogout();
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMerchantHeader(Color primaryColor, Gradient primaryGradient) {
    return Consumer<PostProvider>(
      builder: (context, postProvider, child) {
        final productCount = postProvider.myPosts.length;
        final offerCount = postProvider.myOffers.length;

        return Column(
          children: [
            // Cover Image Section
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Cover Image
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primaryDeep.withValues(alpha: 0.1),
                  ),
                  child: (_storeCoverUrl != null && _storeCoverUrl!.isNotEmpty)
                      ? Image.network(
                          _storeCoverUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              decoration: BoxDecoration(gradient: primaryGradient),
                              alignment: Alignment.center,
                              child: const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(decoration: BoxDecoration(gradient: primaryGradient));
                          },
                        )
                      : Container(decoration: BoxDecoration(gradient: primaryGradient)),
                ),
                // Camera icon on cover (top-right)
                Positioned(
                  top: 40,
                  right: 16,
                  child: GestureDetector(
                    onTap: _isUploadingCover ? null : _pickCoverImage,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: _isUploadingCover
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 20),
                    ),
                  ),
                ),
                // Avatar positioned at bottom-center of cover
                Positioned(
                  bottom: -50,
                  left: 0,
                  right: 0,
                  child: Center(
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
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey.shade100,
                              child: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                                  ? ClipOval(
                                      child: Image.network(
                                        _avatarUrl!,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.store, size: 45, color: Colors.grey),
                                      ),
                                    )
                                  : const Icon(Icons.store, size: 45, color: Colors.grey),
                            ),
                          ),
                          // Camera icon for avatar
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey[300]!, width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: _isUploadingImage
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : Icon(Icons.camera_alt, size: 16, color: AppColors.primaryBlue),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 60),

            // Store name centered under avatar
            Text(
              _userName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Location - clickable link
            GestureDetector(
              onTap: () {
                // TODO: Open map or location screen
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on, size: 14, color: AppColors.primaryBlue),
                  const SizedBox(width: 4),
                  Text(
                    _location,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryBlue,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primaryBlue,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Store description
            if (_storeDescription.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _storeDescription,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Settings icon button
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _showSettingsMenu,
                icon: Icon(Icons.settings_outlined, color: Colors.grey[700]),
                tooltip: 'الإعدادات',
              ),
            ),

            const SizedBox(height: 20),

            // Stats Row - matching the reference image style
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.people_outline,
                        value: '12.5K',
                        label: 'المتابعين',
                      ),
                    ),
                    Container(width: 1, height: 40, color: Colors.grey[200]),
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.star_outline,
                        value: '4.8',
                        label: 'التقييم',
                      ),
                    ),
                    Container(width: 1, height: 40, color: Colors.grey[200]),
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.inventory_2_outlined,
                        value: productCount.toString(),
                        label: 'المنتجات',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons - Publish Post + Analytics
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Publish Post Button with Dropdown
                  Expanded(
                    flex: 2,
                    child: PopupMenuButton<String>(
                      onSelected: _handlePostMenuSelection,
                      offset: const Offset(0, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      elevation: 8,
                      itemBuilder: (context) => [
                        PopupMenuItem<String>(
                          value: 'product',
                          child: Row(
                            children: [
                              Icon(Icons.shopping_bag_outlined, color: Colors.grey[700], size: 20),
                              const SizedBox(width: 12),
                              const Text('منتج جديد', style: TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'discount',
                          child: Row(
                            children: [
                              Icon(Icons.percent, color: Colors.grey[700], size: 20),
                              const SizedBox(width: 12),
                              const Text('تخفيض', style: TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'pack',
                          child: Row(
                            children: [
                              Icon(Icons.inventory_2_outlined, color: Colors.grey[700], size: 20),
                              const SizedBox(width: 12),
                              const Text('حزمة', style: TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, size: 20, color: Colors.white),
                            SizedBox(width: 8),
                            Text('نشر منشور', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Analytics Button (Outlined)
                  Expanded(
                    flex: 1,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, Routes.statistics),
                      icon: Icon(Icons.bar_chart, size: 18, color: AppColors.primaryBlue),
                      label: Text('التحليلات', style: TextStyle(color: AppColors.primaryBlue)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.primaryBlue),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildStatItem({required IconData icon, required String value, required String label}) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.grey[600]),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildUserHeader(Color primaryColor, Gradient primaryGradient) {
    return Column(
      children: [
        const SizedBox(height: 40),
        // Avatar centered
        GestureDetector(
          onTap: _isUploadingImage ? null : _pickImage,
          child: Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade200,
                child: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                    ? ClipOval(
                        child: Image.network(
                          _avatarUrl!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 50, color: Colors.grey),
                        ),
                      )
                    : const Icon(Icons.person, size: 50, color: Colors.grey),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: _isUploadingImage
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // User name
        Text(
          _userName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              _location,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Edit profile button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ElevatedButton.icon(
            onPressed: _navigateToEditProfile,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('تعديل البيانات'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.textPrimary,
              elevation: 2,
              shadowColor: AppColors.shadowColor,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Stats card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [AppColors.softShadow],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, Routes.favorites),
                  child: _buildAnalysisItem(value: '♡', label: 'المفضلة', icon: Icons.favorite_rounded, color: Colors.red),
                ),
                _buildDivider(),
                _buildAnalysisItem(value: '12', label: 'المتابعين', icon: Icons.people_alt_rounded, color: Colors.blue),
                _buildDivider(),
                _buildAnalysisItem(value: '5', label: 'الطلبات', icon: Icons.shopping_bag_rounded, color: Colors.orange),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _navigateToEditProfile() {
    if (_userType == 'merchant') {
      final userData = StorageService.getUserData();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditMerchantProfileScreen(
            initialName: userData?['full_name'] ?? '',
            initialEmail: userData?['email'] ?? '',
            initialPhone: userData?['phone'] ?? '',
            initialImage: userData?['profile_image'] ?? userData?['store_image'] ?? userData?['avatar'],
            initialStoreDescription: userData?['store_description'],
            initialAddress: userData?['location'] ?? userData?['address'],
          ),
        ),
      ).then((result) {
        if (result == true) _loadUserData();
      });
    } else {
      final userData = StorageService.getUserData();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditCustomerProfileScreen(
            initialName: userData?['full_name'] ?? '',
            initialEmail: userData?['email'] ?? '',
            initialPhone: userData?['phone'] ?? '',
            initialImage: userData?['avatar'],
          ),
        ),
      ).then((result) {
        if (result == true) _loadUserData();
      });
    }
  }

  void _handlePostMenuSelection(String value) {
    switch (value) {
      case 'product':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const AddProductScreen())).then((result) {
          if (result == true && mounted) {
            if (_userId != null) {
              Provider.of<PostProvider>(context, listen: false).loadMyPosts(_userId.toString());
              Provider.of<PostProvider>(context, listen: false).loadMyOffers(_userId.toString());
            }
          }
        });
        break;
      case 'discount':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const AddPromotionScreen())).then((result) {
          if (result == true && mounted) {
            final provider = Provider.of<PostProvider>(context, listen: false);
            if (_userId != null) {
              provider.loadMyPosts(_userId.toString());
            }
            if (_storeId != null) {
              provider.loadMyOffers(_storeId.toString());
              context.read<PackProvider>().loadMyPacks(_storeId!);
            }
            provider.loadPosts();
            provider.loadOffers();
          }
        });
        break;
      case 'pack':
        Navigator.push(context, MaterialPageRoute(builder: (context) => AddPackScreen()));
        break;
    }
  }

  void _showEditOfferSheet(Offer offer) {
    final discountController = TextEditingController(text: offer.discountPercentage.toString());
    bool isAvailable = offer.isAvailable;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('تعديل العرض', style: AppTextStyles.h4),
                  const SizedBox(height: 12),
                  TextField(
                    controller: discountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'نسبة التخفيض (%)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('إظهار العرض'),
                      Switch(value: isAvailable, onChanged: (val) => setStateSheet(() => isAvailable = val)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final provider = context.read<PostProvider>();
                            final discount = int.tryParse(discountController.text);
                            try {
                              await provider.updateOffer(offerId: offer.id, discountPercentage: discount, isAvailable: isAvailable);
                              if (mounted) Navigator.pop(context);
                              Helpers.showSnackBar(context, 'تم تحديث العرض');
                            } catch (e) {
                              Helpers.showSnackBar(context, 'فشل تحديث العرض: $e');
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple, foregroundColor: Colors.white),
                          child: const Text('حفظ'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final provider = context.read<PostProvider>();
                            try {
                              await provider.deleteOffer(offer.id);
                              if (mounted) Navigator.pop(context);
                              Helpers.showSnackBar(context, 'تم حذف العرض');
                            } catch (e) {
                              Helpers.showSnackBar(context, 'فشل حذف العرض: $e');
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                          child: const Text('حذف'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final bool isMerchant = authProvider.activeProfileType == 'STORE';
    final Color primaryColor = isMerchant ? AppColors.primaryBlue : AppColors.primaryBlue;
    final Gradient primaryGradient = isMerchant ? AppColors.deepGradient : AppColors.goldGradient;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: DefaultTabController(
          length: 4,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: isMerchant ? _buildMerchantHeader(primaryColor, primaryGradient) : _buildUserHeader(primaryColor, primaryGradient),
                ),
                if (isMerchant)
                  SliverPersistentHeader(
                    delegate: _SliverAppBarDelegate(
                      Container(
                        color: Colors.white,
                        child: TabBar(
                          controller: _tabController,
                          labelColor: AppColors.primaryBlue,
                          unselectedLabelColor: Colors.grey[500],
                          indicatorColor: AppColors.primaryBlue,
                          indicatorWeight: 3,
                          indicatorSize: TabBarIndicatorSize.label,
                          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
                          tabs: const [
                            Tab(text: 'الكل'),
                            Tab(text: 'المنتجات'),
                            Tab(text: 'التخفيضات'),
                            Tab(text: 'الحزم'),
                          ],
                        ),
                      ),
                    ),
                    pinned: true,
                  ),
              ];
            },
            body: isMerchant
                ? TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMerchantPosts(type: 'all'),
                      _buildMerchantPosts(type: 'product'),
                      _buildMerchantPosts(type: 'promotion'),
                      _buildMerchantPosts(type: 'pack'),
                    ],
                  )
                : SingleChildScrollView(child: _buildUserMenu()),
          ),
        ),
      ),
    );
  }

  Widget _buildMerchantPosts({required String type}) {
    return Consumer2<PostProvider, PackProvider>(
      builder: (context, postProvider, packProvider, child) {
        List<dynamic> items = [];
        if (type == 'promotion') {
          items = postProvider.myOffers;
        } else if (type == 'pack') {
          items = packProvider.myPacks;
        } else if (type == 'all') {
          items = [...postProvider.myPosts, ...postProvider.myOffers, ...packProvider.myPacks];
        } else {
          items = postProvider.myPosts;
        }

        final filteredItems = items.where((item) {
          bool matchesType = false;
          String title = '';

          try {
            if (item is Offer) {
              title = item.product.title;
              matchesType = (type == 'promotion' || type == 'all');
            } else if (item is Pack) {
              title = item.name;
              matchesType = (type == 'pack' || type == 'all');
            } else if (item is Post) {
              title = item.title;
              if (type == 'all') {
                matchesType = true;
              } else if (type == 'product') {
                matchesType = true;
              } else if (type == 'pack') {
                matchesType = false;
              } else if (type == 'promotion') {
                matchesType = false;
              }
            } else {
              // Unknown type - skip it
              return false;
            }
          } catch (e) {
            // If any error occurs during filtering, skip this item
            debugPrint('Profile: Error filtering item: $e');
            return false;
          }

          final matchesSearch = _searchQuery.isEmpty || title.toLowerCase().contains(_searchQuery.toLowerCase());
          return matchesType && matchesSearch;
        }).toList();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacing20),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'بحث في ${type == 'all' ? 'الكل' : type == 'product' ? 'المنتجات' : type == 'pack' ? 'الحزم' : 'التخفيضات'}...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            Expanded(
              child: filteredItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.inventory_2_outlined, size: 60, color: AppColors.textHint),
                          SizedBox(height: 12),
                          Text('لا يوجد محتوى هنا بعد', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.65,
                      ),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        if (item is Post) {
                          return ProductCard(
                            product: item,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                Routes.productDetails,
                                arguments: item,
                              );
                            },
                            onEditTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => EditProductScreen(product: item))).then((result) {
                                if (result == true && _userId != null) {
                                  context.read<PostProvider>().loadMyPosts(_userId.toString());
                                }
                              });
                            },
                          );
                        } else if (item is Pack) {
                          return GestureDetector(
                            onTap: () {
                              // Navigate to pack details if needed
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Images section
                                      Expanded(
                                        flex: 3,
                                        child: Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                AppColors.primary.withOpacity(0.15),
                                                AppColors.primary.withOpacity(0.05),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(12),
                                              topRight: Radius.circular(12),
                                            ),
                                          ),
                                          child: _buildStackedProductImages(item.products),
                                        ),
                                      ),
                                      // Info section
                                      Expanded(
                                        flex: 2,
                                        child: Padding(
                                          padding: const EdgeInsets.all(8),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              item.name,
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _buildProductSummary(item.products),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary.withOpacity(0.8)),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  '${item.products.length} منتج',
                                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                                ),
                                                Text(
                                                  '${item.discountPrice.toStringAsFixed(0)} د.ج',
                                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Edit button
                                  Positioned(
                                    top: 4,
                                    left: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.pushNamed(context, Routes.addPack, arguments: item);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(Icons.edit, size: 12, color: AppColors.primary),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else if (item is Offer) {
                          try {
                            final product = item.product;
                            return GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  Routes.productDetails,
                                  arguments: product,
                                );
                              },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Image with badges
                                  Expanded(
                                    flex: 3,
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                          child: SizedBox(
                                            width: double.infinity,
                                            child: (product.image == null || product.image!.isEmpty)
                                                ? Container(
                                                    color: Colors.grey[200],
                                                    alignment: Alignment.center,
                                                    child: const Icon(Icons.image, size: 40, color: Colors.grey),
                                                  )
                                                : Image.network(
                                                    product.image!,
                                                    fit: BoxFit.cover,
                                                    loadingBuilder: (context, child, loadingProgress) {
                                                      if (loadingProgress == null) return child;
                                                      return Container(
                                                        color: Colors.grey[200],
                                                        alignment: Alignment.center,
                                                        child: const SizedBox(
                                                          width: 20,
                                                          height: 20,
                                                          child: CircularProgressIndicator(strokeWidth: 2),
                                                        ),
                                                      );
                                                    },
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Container(
                                                        color: Colors.grey[200],
                                                        alignment: Alignment.center,
                                                        child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                                      );
                                                    },
                                                  ),
                                          ),
                                        ),
                                        // Discount Badge
                                        Positioned(
                                          top: 8,
                                          left: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '-${item.discountPercentage}%',
                                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        // Edit Button
                                        Positioned(
                                          top: 6,
                                          right: 6,
                                          child: GestureDetector(
                                            onTap: () => _showEditOfferSheet(item),
                                            child: Container(
                                              padding: const EdgeInsets.all(3),
                                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                              child: const Icon(Icons.edit, size: 12, color: AppColors.primaryBlue),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Details
                                  Expanded(
                                    flex: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            product.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          const Spacer(),
                                          Row(
                                            children: [
                                              Text(
                                                Helpers.formatPrice(item.newPrice),
                                                style: const TextStyle(
                                                  color: AppColors.primaryBlue,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                Helpers.formatPrice(product.price),
                                                style: TextStyle(color: Colors.grey[500], fontSize: 9, decoration: TextDecoration.lineThrough),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              const Icon(Icons.star, size: 10, color: Colors.amber),
                                              const SizedBox(width: 2),
                                              Text(
                                                '4.5',
                                                style: TextStyle(color: Colors.grey[600], fontSize: 9),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                          } catch (e) {
                            debugPrint('Profile: Error displaying offer: $e');
                            return const SizedBox.shrink();
                          }
                        } else {
                          return const SizedBox.shrink();
                        }
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserMenu() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('الحساب', style: AppTextStyles.h4),
          const SizedBox(height: 12),
          _buildMenuContainer([
            _MenuItem(icon: Icons.favorite_outline, title: 'المفضلة', onTap: () => Navigator.pushNamed(context, Routes.favorites)),
            _MenuItem(icon: Icons.location_on_outlined, title: 'عناويني', subtitle: _location, onTap: () {}),
            _MenuItem(icon: Icons.notifications_none_rounded, title: 'الإشعارات', badge: '3', onTap: () {}),
            _MenuItem(icon: Icons.credit_card_outlined, title: 'طرق الدفع', onTap: () {}),
          ]),
          const SizedBox(height: 24),
          Text('عام', style: AppTextStyles.h4),
          const SizedBox(height: 12),
          _buildMenuContainer([
            _MenuItem(icon: Icons.language, title: 'اللغة', subtitle: 'العربية', onTap: () {}),
            _MenuItem(icon: Icons.help_outline_rounded, title: 'المساعدة والدعم', onTap: () {}),
          ]),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red.withValues(alpha: 0.1))),
            child: ListTile(
              leading: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.logout_rounded, color: Colors.red, size: 20)),
              title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
              onTap: _handleLogout,
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildAnalysisItem({required String value, required String label, required IconData icon, required Color color}) {
    return Column(
      children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(height: 40, width: 1, color: AppColors.borderLight);
  }

  Widget _buildMenuContainer(List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [AppColors.softShadow]),
      child: Column(
        children: items.map((item) {
          final isLast = items.last == item;
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: AppColors.scaffoldBackground, shape: BoxShape.circle), child: Icon(item.icon, color: AppColors.textPrimary, size: 20)),
                title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: item.subtitle != null ? Text(item.subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)) : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.badge != null)
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)), child: Text(item.badge!, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textHint),
                  ],
                ),
                onTap: item.onTap,
              ),
              if (!isLast)
                const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Divider(height: 1, color: AppColors.borderLight)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStackedProductImages(List<dynamic> products) {
    if (products.isEmpty) {
      return const Center(
        child: Icon(Icons.shopping_bag, size: 45, color: AppColors.primary),
      );
    }

    // Show up to 3 product images stacked
    final imagesToShow = products.take(3).toList();
    final imageCount = imagesToShow.length;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate image size based on available space
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;
        
        // Image size adapts to container - use 55% of height (smaller)
        final imageSize = (availableHeight * 0.55).clamp(35.0, 60.0);
        final overlap = imageSize * 0.4; // 40% overlap
        final totalWidth = imageSize + (imageCount - 1) * (imageSize - overlap);
        final startX = (availableWidth - totalWidth) / 2;
        
        return Stack(
          alignment: Alignment.center,
          children: [
            for (int i = 0; i < imageCount; i++)
              Positioned(
                left: startX + i * (imageSize - overlap),
                child: Container(
                  width: imageSize,
                  height: imageSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _getProductImage(imagesToShow[i]),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _getProductImage(dynamic product) {
    String? imageUrl;
    
    // Handle PackProduct object
    if (product is PackProduct) {
      imageUrl = product.productImage;
    } else if (product is Map<String, dynamic>) {
      imageUrl = product['product_image'] as String?;
    }

    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Icon(
          Icons.inventory_2,
          size: 18,
          color: Colors.grey,
        ),
      );
    }

    // Handle relative URLs from backend
    final fullImageUrl = imageUrl.startsWith('/') 
        ? 'http://127.0.0.1:8000$imageUrl' 
        : imageUrl;

    return Image.network(
      fullImageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey[200],
        child: const Icon(
          Icons.inventory_2,
          size: 18,
          color: Colors.grey,
        ),
      ),
    );
  }

  String _buildProductSummary(List<dynamic> products) {
    if (products.isEmpty) return 'حزمة فارغة';
    
    final maxItems = 3;
    final itemsToShow = products.take(maxItems).toList();
    
    final validItems = itemsToShow.map((product) {
      int quantity = 1;
      String name = '';
      
      // Handle PackProduct object
      if (product is PackProduct) {
        quantity = product.quantity;
        name = product.productName;
      } else if (product is Map<String, dynamic>) {
        quantity = product['quantity'] ?? 1;
        name = product['product_name']?.toString().trim() ?? '';
      }
      
      if (name.isNotEmpty && name != 'null') {
        return '$quantity $name';
      }
      return null;
    }).where((item) => item != null).toList();
    
    if (validItems.isEmpty) {
      return '${products.length} منتجات';
    }
    
    String summary = validItems.join(' + ');
    
    if (products.length > maxItems) {
      summary += ' ...';
    }
    
    return summary;
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._child);
  final Widget _child;

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return _child;
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? badge;
  final VoidCallback onTap;

  _MenuItem({required this.icon, required this.title, this.subtitle, this.badge, required this.onTap});
}
