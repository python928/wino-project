import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../core/services/api_service.dart';
import '../../core/config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/app_button.dart';
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
import '../home/widgets/product_card.dart';
import 'add_promotion_screen.dart';
import 'edit_product_screen.dart';
import 'add_pack_screen.dart';
import '../../core/widgets/cards/unified_item_card.dart';
import '../common/widgets/stacked_product_images.dart';
import '../common/constants/card_constants.dart';
import 'widgets/profile_merchant_header.dart';
import 'widgets/profile_user_header.dart';
import 'widgets/profile_post_filter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'Loading...';
  String _userType = 'user';
  String _location = 'Loading...';
  String _storeDescription = '';
  String? _avatarUrl;
  int? _userId;
  bool _isUploadingImage = false;
  
  // Real data from backend
  int _followersCount = 0;
  double _averageRating = 0.0;
  
  // Store specific
  String? _storeCoverUrl;
  int? _storeId;
  bool _isUploadingCover = false;

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Filter state for toggle buttons (replaces dropdown)
  int _selectedFilterIndex = 0; // 0=all, 1=product, 2=promotion, 3=pack

  String? _lastProfileType;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This is called when dependencies change, but we handle profile type
    // changes in the build method where we watch AuthProvider
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
          // Parse store address
          String storeLocation = 'Select Location';
          final storeAddress = store['address']?.toString() ?? '';
          if (storeAddress.isNotEmpty && storeAddress != 'Algeria') {
            storeLocation = storeAddress;
          }

          setState(() {
            _storeId = store['id'];
            _storeDescription = store['description'] ?? _storeDescription;
            _storeCoverUrl = store['cover_image'];
            _followersCount = store['followers_count'] ?? 0;
            _averageRating = (store['average_rating'] as num?)?.toDouble() ?? 0.0;
            _location = storeLocation;
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
        
        if (mounted) Helpers.showSnackBar(context, 'Cover image updated successfully');
      } catch (e) {
        if (mounted) Helpers.showSnackBar(context, 'Failed to update cover image: $e');
      } finally {
        if (mounted) setState(() => _isUploadingCover = false);
      }
    }
  }

  Future<void> _pickImage() async {
    // Show dialog to choose between camera and gallery
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose image source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: AppColors.primaryColor),
                title: Text('Camera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: AppColors.primaryColor),
                title: Text('Gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

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
        
        if (mounted) Helpers.showSnackBar(context, 'Profile image updated successfully');
      } catch (e) {
        if (mounted) Helpers.showSnackBar(context, 'Failed to update image: $e');
      } finally {
        if (mounted) setState(() => _isUploadingImage = false);
      }
    }
  }


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Helper method to convert filter index to type string
  String _getFilterType(int index) {
    const types = ['all', 'product', 'promotion', 'pack'];
    return types[index];
  }

  Future<void> _loadUserData() async {
    final userData = StorageService.getUserData();
    if (userData != null) {
      // Get user type from AuthProvider to stay in sync
      final authProvider = context.read<AuthProvider>();
      final isMerchantFromAuth = authProvider.activeProfileType == 'STORE';

      // Parse address to show wilaya/baladiya
      String locationDisplay = 'Select Location';
      final address = userData['address']?.toString() ?? userData['location']?.toString() ?? '';
      if (address.isNotEmpty && address != 'Algeria') {
        locationDisplay = address;
      }

      setState(() {
        _userId = userData['id'];
        _userName = userData['name'] ?? userData['username'] ?? 'User';
        _location = locationDisplay;
        // Use AuthProvider's activeProfileType for consistency
        _userType = isMerchantFromAuth ? 'merchant' : 'user';
        _storeDescription = userData['store_description'] ?? '';
        _avatarUrl = userData['profile_image'] ?? userData['avatar'];
      });

      if (_userType == 'merchant' && _userId != null) {
        // Clear existing data and load merchant data
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
      } else {
        // For regular users, fetch user stats (followers)
        _fetchUserStats();
        // Switching to user mode - clear merchant data
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // Clear the store-specific data
            setState(() {
              _storeId = null;
              _storeCoverUrl = null;
              _storeDescription = '';
            });
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
      Helpers.showSnackBar(context, 'Logged out successfully!');
    }
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }

  Future<void> _fetchUserStats() async {
    if (_userId == null) return;
    try {
      // Fetch user follower count from backend
      final response = await ApiService.get('${ApiConfig.users}$_userId/');
      if (response != null && mounted) {
        setState(() {
          _followersCount = response['followers_count'] ?? 0;
        });
      }
    } catch (e) {
      print('Error fetching user stats: $e');
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
          textDirection: TextDirection.ltr,
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
                      'Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacing16),
                  // Edit Profile
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.edit_outlined, color: AppColors.primaryColor),
                    ),
                    title: const Text('Edit Profile'),
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
                    title: const Text('Favorites'),
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
                      'Logout',
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
    return ProfileMerchantHeader(
      userName: _userName,
      location: _location,
      storeDescription: _storeDescription,
      avatarUrl: _avatarUrl,
      storeCoverUrl: _storeCoverUrl,
      isUploadingImage: _isUploadingImage,
      isUploadingCover: _isUploadingCover,
      followersCount: _followersCount,
      averageRating: _averageRating,
      onPickImage: _pickImage,
      onPickCoverImage: _pickCoverImage,
      onSettingsTap: _showSettingsMenu,
      onPostMenuSelection: _handlePostMenuSelection,
      primaryGradient: primaryGradient,
    );
  }

  Widget _buildUserHeader(Color primaryColor, Gradient primaryGradient) {
    return ProfileUserHeader(
      userName: _userName,
      location: _location,
      avatarUrl: _avatarUrl,
      isUploadingImage: _isUploadingImage,
      onPickImage: _pickImage,
      primaryColor: primaryColor,
    );
  }

  void _navigateToEditProfile() {
    if (_userType == 'merchant') {
      final userData = StorageService.getUserData();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditMerchantProfileScreen(
            initialName: userData?['name'] ?? '',
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
            initialName: userData?['name'] ?? '',
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
            // Removed provider.loadPosts() - only load user's own data
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
                  Text('Edit Offer', style: AppTextStyles.h4),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: discountController,
                    label: 'Discount Percentage (%)',
                    hint: '0',
                    icon: Icons.percent,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Show Offer'),
                      Switch(value: isAvailable, onChanged: (val) => setStateSheet(() => isAvailable = val)),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacing16),
                  Row(
                    children: [
                      Expanded(
                        child: AppPrimaryButton(
                          text: 'Save',
                          onPressed: () async {
                            final provider = context.read<PostProvider>();
                            final discount = int.tryParse(discountController.text);
                            try {
                              await provider.updateOffer(offerId: offer.id, discountPercentage: discount, isAvailable: isAvailable);
                              if (mounted) Navigator.pop(context);
                              Helpers.showSnackBar(context, 'Offer updated');
                            } catch (e) {
                              Helpers.showSnackBar(context, 'Failed to update offer: $e');
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppDangerButton(
                          text: 'Delete',
                          onPressed: () async {
                            final provider = context.read<PostProvider>();
                            try {
                              await provider.deleteOffer(offer.id);
                              if (mounted) Navigator.pop(context);
                              Helpers.showSnackBar(context, 'Offer deleted');
                            } catch (e) {
                              Helpers.showSnackBar(context, 'Failed to delete offer: $e');
                            }
                          },
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
    final Color primaryColor = isMerchant ? AppColors.primaryColor : AppColors.primaryColor;
    final Gradient primaryGradient = isMerchant ? AppColors.deepGradient : AppColors.purpleGradient;

    // Detect profile type change and reload data
    if (_lastProfileType != null && _lastProfileType != authProvider.activeProfileType) {
      // Profile type changed - reload data after current frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadUserData();
        }
      });
    }
    _lastProfileType = authProvider.activeProfileType;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: isMerchant
                  ? _buildMerchantHeader(primaryColor, primaryGradient)
                  : _buildUserHeader(primaryColor, primaryGradient),
            ),
            if (isMerchant)
              SliverToBoxAdapter(
                child: ProfilePostFilter(
                  selectedIndex: _selectedFilterIndex,
                  onFilterChanged: (index) {
                    setState(() => _selectedFilterIndex = index);
                  },
                  searchController: _searchController,
                  onSearchChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),
            if (isMerchant)
              SliverToBoxAdapter(
                child: _buildMerchantPosts(type: _getFilterType(_selectedFilterIndex)),
              )
            else
              SliverToBoxAdapter(
                child: _buildUserMenu(),
              ),
          ],
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
              child: AppSearchField(
                controller: _searchController,
                hintText: 'Search in ${type == 'all' ? 'All' : type == 'product' ? 'Products' : type == 'pack' ? 'Packs' : 'Discounts'}...',
                onChanged: (_) => setState(() {}),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height - 500, // Adjust based on header height
              child: filteredItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.inventory_2_outlined, size: 60, color: AppColors.textHint),
                          SizedBox(height: 12),
                          Text('No content here yet', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: CardConstants.gridHorizontalPadding,
                        vertical: CardConstants.gridVerticalPadding,
                      ),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: CardConstants.gridCrossAxisCount,
                        crossAxisSpacing: CardConstants.gridCrossAxisSpacing,
                        mainAxisSpacing: CardConstants.gridMainAxisSpacing,
                        childAspectRatio: CardConstants.gridChildAspectRatio,
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
                          return UnifiedItemCard(
                            title: '${item.name}\n${_buildProductSummary(item.products)}',
                            price: item.discountPrice,
                            customImageWidget: StackedProductImages(products: item.products),
                            bottomLeftText: '${item.products.length} products',
                            bottomLeftIcon: Icons.inventory_2_outlined,
                            onTap: () {
                              // Navigate to pack details
                              Navigator.pushNamed(context, Routes.packDetails, arguments: item);
                            },
                            onEditTap: () {
                              Navigator.pushNamed(context, Routes.addPack, arguments: item);
                            },
                          );
                        } else if (item is Offer) {
                          try {
                            final product = item.product;
                            // Create modified product with promotion pricing
                            final productWithPromotion = product.copyWith(
                              price: item.newPrice,
                              oldPrice: product.price,
                              discountPercentage: item.discountPercentage,
                            );
                            return UnifiedItemCard(
                              title: product.title,
                              imageUrl: product.image,
                              price: item.newPrice,
                              oldPrice: product.price,
                              discountPercentage: item.discountPercentage,
                              rating: product.rating,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  Routes.productDetails,
                                  arguments: productWithPromotion,
                                );
                              },
                              onEditTap: () => _showEditOfferSheet(item),
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
          // Account Section
          _buildMenuContainer([
            _MenuItem(
              icon: Icons.person_outline,
              title: 'Information',
              subtitle: 'Edit your profile',
              onTap: _navigateToEditProfile,
            ),
            _MenuItem(
              icon: Icons.favorite_outline,
              title: 'Favorites',
              onTap: () => Navigator.pushNamed(context, Routes.favorites),
            ),
          ]),
          const SizedBox(height: 16),

          // General Section
          _buildMenuContainer([
            _MenuItem(
              icon: Icons.language,
              title: 'Language',
              subtitle: 'Arabic',
              onTap: () {},
            ),
            _MenuItem(
              icon: Icons.help_outline_rounded,
              title: 'Help & Support',
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 16),

          // Logout
          Container(
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppConstants.cardRadius),
              border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(AppConstants.spacing8),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.logout_rounded, color: Colors.red, size: AppConstants.spacing20),
              ),
              title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: AppConstants.fontSizeSubtitle)),
              trailing: const Icon(Icons.arrow_forward_ios, size: AppConstants.iconSmall, color: Colors.red),
              onTap: _handleLogout,
            ),
          ),
          const SizedBox(height: AppConstants.spacing40),
        ],
      ),
    );
  }

  Widget _buildAnalysisItem({required String value, required String label, required IconData icon, required Color color}) {
    return Column(
      children: [
        Container(padding: const EdgeInsets.all(AppConstants.spacing10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: AppConstants.iconMedium)),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppConstants.cardRadius), boxShadow: [AppColors.softShadow]),
      child: Column(
        children: items.map((item) {
          final isLast = items.last == item;
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: AppConstants.spacing16, vertical: AppConstants.spacing4),
                leading: Container(padding: const EdgeInsets.all(AppConstants.spacing8), decoration: const BoxDecoration(color: AppColors.scaffoldBackground, shape: BoxShape.circle), child: Icon(item.icon, color: AppColors.textPrimary, size: AppConstants.spacing20)),
                title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: item.subtitle != null ? Text(item.subtitle!, style: const TextStyle(fontSize: AppConstants.fontSizeCaption, color: AppColors.textSecondary)) : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.badge != null)
                      Container(padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacing8, vertical: AppConstants.spacing2), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(AppConstants.spacing10)), child: Text(item.badge!, style: const TextStyle(color: Colors.white, fontSize: AppConstants.fontSizeSmall, fontWeight: FontWeight.bold))),
                    const SizedBox(width: AppConstants.spacing8),
                    const Icon(Icons.arrow_forward_ios, size: AppConstants.spacing14, color: AppColors.textHint),
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

        // Image size adapts to container - use 70% of height for better visibility
        final imageSize = (availableHeight * 0.70).clamp(50.0, 90.0);
        final overlap = imageSize * 0.35; // 35% overlap for better spacing
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
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
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
        color: Colors.grey[100],
        alignment: Alignment.center,
        child: const Icon(
          Icons.inventory_2,
          size: 28,
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
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey[100],
          alignment: Alignment.center,
          child: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey[100],
        alignment: Alignment.center,
        child: const Icon(
          Icons.inventory_2,
          size: 28,
          color: Colors.grey,
        ),
      ),
    );
  }

  String _buildProductSummary(List<dynamic> products) {
    if (products.isEmpty) return 'Empty pack';
    
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
      return '${products.length} products';
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
