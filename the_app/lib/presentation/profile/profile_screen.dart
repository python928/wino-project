import 'package:image_picker/image_picker.dart';
import '../../core/services/api_service.dart';
import '../../core/config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routing/routes.dart';
import '../../core/services/storage_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/services/follow_change_notifier.dart';
import '../../core/services/notification_badge_service.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/post_provider.dart';
import '../../core/providers/pack_provider.dart';
import '../../core/providers/home_provider.dart';
import '../../core/providers/store_provider.dart';
import '../../data/models/post_model.dart';
import '../../data/models/pack_model.dart';
import '../../data/models/offer_model.dart';
import '../../data/models/user_model.dart';
import '../auth/splash_screen.dart';
import '../notifications/notifications_screen.dart';
import 'edit_merchant_profile_screen.dart';
import 'add_product_screen.dart';
import '../shared_widgets/cards/product_card.dart';
import 'add_promotion_screen.dart';
import 'add_pack_screen.dart';
import '../shared_widgets/cards/pack_card.dart';
import '../shared_widgets/cards/promotion_card.dart';

import '../common/constants/card_constants.dart';
import 'widgets/profile_merchant_header.dart';
import 'widgets/profile_post_filter.dart';

class ProfileScreen extends StatefulWidget {
  final int? storeId;
  const ProfileScreen({super.key, this.storeId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'Loading...';
  String _location = 'Loading...';
  String _storeDescription = '';
  String? _avatarUrl;
  String _phoneNumber = '';
  int? _userId;
  int? _currentUserId;
  bool _isUploadingImage = false;

  // Social Links
  String? _facebook;
  String? _instagram;
  String? _whatsapp;
  String? _tiktok;
  String? _youtube;
  bool _showPhonePublic = true;
  bool _showSocialPublic = true;

  double? _latitude;
  double? _longitude;

  int _followersCount = 0;
  double _averageRating = 0.0;

  bool _isFollowingStore = false;
  bool _isLoadingFollowState = false;

  String? _storeCoverUrl;
  bool _isUploadingCover = false;

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Filter state for toggle buttons (replaces dropdown)
  int _selectedFilterIndex = 0; // 0=all, 1=product, 2=promotion, 3=pack
  int _profileVisibleCount = 12;

  int? _storeId; // keep, but storeId == userId now
  String? _lastProfileType; // remove usage (kept field is harmless but unused)

  bool _isSubmittingReview = false;
  final TextEditingController _reviewController = TextEditingController();
  double _rating = 0.0;
  bool _showReviewForm = false;
  bool _isProfileContentLoading = true;

  void _showPublishMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.inventory_2_outlined,
                        color: AppColors.primaryColor, size: 20),
                  ),
                  title: const Text('Add Product',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    _handlePostMenuSelection('product');
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.local_offer_outlined,
                        color: AppColors.primaryColor, size: 20),
                  ),
                  title: const Text('Add Discount',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    _handlePostMenuSelection('discount');
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.all_inbox_outlined,
                        color: AppColors.primaryColor, size: 20),
                  ),
                  title: const Text('Add Pack',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    _handlePostMenuSelection('pack');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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
    // no profile-type switching anymore
  }

  Future<void> _fetchStoreData() async {
    if (_userId == null) return;
    try {
      final resp = await ApiService.get('${ApiConfig.users}$_userId/');
      if (resp is! Map) return;

      final u = User.fromJson(Map<String, dynamic>.from(resp));

      if (!mounted) return;
      setState(() {
        _storeId = u.id; // userId == storeId
        _userName = u.fullName;
        _avatarUrl = u.profileImage;
        _storeDescription = u.storeDescription;
        _storeCoverUrl = u.coverImage;
        _phoneNumber = (u.phone ?? '').toString();
        _followersCount = u.followersCount;
        _averageRating = u.averageRating;
        _location = u.address.isNotEmpty ? u.address : 'Select Location';

        _facebook = u.facebook;
        _instagram = u.instagram;
        _whatsapp = u.whatsapp;
        _tiktok = u.tiktok;
        _youtube = u.youtube;
        _showPhonePublic = u.showPhonePublic;
        _showSocialPublic = u.showSocialPublic;
      });
    } catch (e) {
      debugPrint('Error fetching unified profile: $e');
    }
  }

  bool get _isOwnerView {
    if (_currentUserId == null || _userId == null) return false;
    return _currentUserId == _userId;
  }

  Future<ImageSource?> _showImageSourcePicker() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
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
        );
      },
    );
  }

  Future<void> _pickCoverImage() async {
    if (_userId == null) return;

    final source = await _showImageSourcePicker();
    if (source == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    setState(() => _isUploadingCover = true);

    try {
      await ApiService.updateMultipart(
        '${ApiConfig.users}$_userId/',
        {},
        pickedFile,
        'cover_image',
        method: 'PATCH',
      );

      await _fetchStoreData();

      if (mounted) {
        Helpers.showSnackBar(context, 'Cover image updated successfully');
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Failed to update cover image: $e');
      }
    } finally {
      if (mounted) setState(() => _isUploadingCover = false);
    }
  }

  Future<void> _deleteCoverImage() async {
    if (_userId == null || _isUploadingCover) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete cover image?'),
        content: const Text('This will remove your current cover image.'),
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

    setState(() => _isUploadingCover = true);
    try {
      await ApiService.patch('${ApiConfig.users}$_userId/', {
        'cover_image': null,
      });
      await _fetchStoreData();
      if (mounted) {
        Helpers.showSnackBar(context, 'Cover image deleted successfully');
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Failed to delete cover image: $e');
      }
    } finally {
      if (mounted) setState(() => _isUploadingCover = false);
    }
  }

  Future<void> _pickImage() async {
    final ImageSource? source = await _showImageSourcePicker();

    if (source == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null && _userId != null) {
      setState(() => _isUploadingImage = true);

      try {
        await ApiService.updateMultipart(
            '${ApiConfig.users}$_userId/', {}, pickedFile, 'profile_image',
            method: 'PATCH');

        // Fetch updated profile and save to storage
        // We need to import AuthRepository for this
        // But wait, AuthRepository is not imported in this file yet?
        // Let's check imports.
        // It is not. I need to add it or use ApiService directly.
        // I'll use ApiService to get profile then save.

        final response = await ApiService.get('${ApiConfig.users}$_userId/');
        await StorageService.saveUserData(response);

        _loadUserData();

        if (mounted) {
          Helpers.showSnackBar(context, 'Profile image updated successfully');
        }
      } catch (e) {
        if (mounted) {
          Helpers.showSnackBar(context, 'Failed to update image: $e');
        }
      } finally {
        if (mounted) setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _deleteProfileImage() async {
    if (_userId == null || _isUploadingImage) return;
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
      await ApiService.patch('${ApiConfig.users}$_userId/', {
        'profile_image': null,
      });
      final response = await ApiService.get('${ApiConfig.users}$_userId/');
      await StorageService.saveUserData(response);
      _loadUserData();

      if (mounted) {
        Helpers.showSnackBar(context, 'Profile image deleted successfully');
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Failed to delete profile image: $e');
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  // Helper method to convert filter index to type string
  String _getFilterType(int index) {
    const types = ['all', 'product', 'promotion', 'pack'];
    return types[index];
  }

  Future<void> _loadUserData() async {
    if (mounted) {
      setState(() {
        _isProfileContentLoading = true;
      });
    }

    // Clear previous store/profile lists to avoid flashing stale data
    try {
      context.read<PostProvider>().clearMyData(notify: false);
      context.read<PackProvider>().clearAllData(notify: false);
    } catch (_) {
      // best-effort
    }

    final userData = StorageService.getUserData();
    if (userData == null) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const SplashScreen()),
        (Route<dynamic> route) => false,
      );
      return;
    }

    _currentUserId = userData['id'];
    final targetUserId = widget.storeId ?? _currentUserId;
    if (targetUserId == null) return;

    String locationDisplay = 'Select Location';
    final address =
        (userData['address'] ?? userData['location'] ?? '').toString();
    if (address.isNotEmpty && address != 'Algeria') locationDisplay = address;

    if (targetUserId == _currentUserId) {
      setState(() {
        _userId = targetUserId;
        _storeId = targetUserId; // unified
        _userName = userData['name'] ?? userData['username'] ?? 'User';
        _location = locationDisplay;
        _phoneNumber = (userData['phone'] ?? '').toString();
        _storeDescription = (userData['store_description'] ?? '').toString();
        _avatarUrl = userData['profile_image'] ?? userData['avatar'];
        _storeCoverUrl = userData['cover_image'];

        _facebook = userData['facebook'];
        _instagram = userData['instagram'];
        _whatsapp = userData['whatsapp'];
        _tiktok = userData['tiktok'];
        _youtube = userData['youtube'];
        _showPhonePublic = userData['show_phone_public'] as bool? ?? true;
        _showSocialPublic = userData['show_social_public'] as bool? ?? true;

        if (userData['latitude'] != null) {
          _latitude = double.tryParse(userData['latitude'].toString());
        }
        if (userData['longitude'] != null) {
          _longitude = double.tryParse(userData['longitude'].toString());
        }
      });
    } else {
      setState(() {
        _userId = targetUserId;
        _storeId = targetUserId;
        _userName = 'Loading...';
        _location = 'Loading...';
        _phoneNumber = '';
        _storeDescription = '';
        _avatarUrl = null;
        _storeCoverUrl = null;
        _followersCount = 0;
        _averageRating = 0.0;

        _facebook = null;
        _instagram = null;
        _whatsapp = null;
        _tiktok = null;
        _youtube = null;
        _showPhonePublic = true;
        _showSocialPublic = true;
      });
    }

    await _fetchStoreData();

    if (!_isOwnerView) {
      await _loadFollowState();
    }

    if (!mounted || _userId == null) return;

    try {
      if (_isOwnerView) {
        await Future.wait([
          context.read<PostProvider>().loadMyPosts(_userId.toString()),
          context.read<PostProvider>().loadMyOffers(_userId.toString()),
          context.read<PackProvider>().loadMyPacks(_userId!),
        ]);
      } else {
        await Future.wait([
          context.read<PostProvider>().loadStorePosts(_userId!),
          context.read<PostProvider>().loadStoreOffers(_userId!),
          context.read<PackProvider>().loadStorePacks(_userId!),
        ]);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProfileContentLoading = false;
        });
      }
    }
  }

  Future<void> _refreshProfile() async {
    await _loadUserData();
  }

  void _handleLogout() async {
    try {
      await context.read<AuthProvider>().logout();
    } catch (_) {
      // best-effort
    }
    context.read<PostProvider>().clearAllData(notify: false);
    context.read<PackProvider>().clearAllData(notify: false);
    context.read<HomeProvider>().clearAllData(notify: false);
    context.read<StoreProvider>().clear();
    NotificationBadgeService.instance.clear();
    await StorageService.clearAll();
    await StorageService.setNotFirstTime(); // preserve onboarding flag so launcher screen doesn't re-appear
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
    // This method is no longer used since we switched to PopupMenuButton
  }

  void _onSettingsMenuSelected(String value) {
    switch (value) {
      case 'edit':
        _navigateToEditProfile();
        break;
      case 'logout':
        _handleLogout();
        break;
    }
  }

  void _handleFollow() {
    if (_storeId == null) return;
    if (!StorageService.isLoggedIn()) {
      Helpers.showSnackBar(context, 'Log in to follow stores', isError: true);
      return;
    }

    ApiService.post(ApiConfig.followersToggle, {'store': _storeId})
        .then((resp) {
      final isFollowing = (resp is Map && resp['is_following'] == true);
      if (!mounted) return;
      setState(() {
        _isFollowingStore = isFollowing;
        if (isFollowing) {
          _followersCount = (_followersCount + 1);
        } else {
          _followersCount = (_followersCount - 1);
          if (_followersCount < 0) _followersCount = 0;
        }
      });
      FollowChangeNotifier.bump();
      Helpers.showSnackBar(
        context,
        isFollowing ? 'Followed store' : 'Unfollowed store',
      );
    }).catchError((_) {
      if (!mounted) return;
      Helpers.showSnackBar(context, 'Failed to update follow', isError: true);
    });
  }

  Future<void> _loadFollowState() async {
    if (_storeId == null || _isOwnerView) return;
    if (!StorageService.isLoggedIn()) return;
    if (_isLoadingFollowState) return;

    setState(() => _isLoadingFollowState = true);
    try {
      final data = await ApiService.get(ApiConfig.followers);
      final list = (data is Map && data['results'] is List)
          ? (data['results'] as List)
          : (data is List ? data : const []);

      bool isFollowing = false;
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          final followed = item['followed_user'];
          if (followed is int && followed == _storeId) {
            isFollowing = true;
            break;
          }
          if (followed is Map && followed['id'] == _storeId) {
            isFollowing = true;
            break;
          }
        }
      }

      if (!mounted) return;
      setState(() => _isFollowingStore = isFollowing);
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _isLoadingFollowState = false);
    }
  }

  void _handleFavorite() {
    // TODO: Implement favorite functionality
    print('Favorite store: $_storeId');
  }

  Future<void> _showReportStoreSheet() async {
    if (_storeId == null) return;
    const reasons = <Map<String, String>>[
      {'value': 'spam', 'label': 'Spam'},
      {'value': 'fake', 'label': 'Fake store'},
      {'value': 'fraud', 'label': 'Fraud / scam'},
      {'value': 'offensive', 'label': 'Offensive content'},
      {'value': 'other', 'label': 'Other'},
    ];
    String selectedReason = 'spam';
    final detailsController = TextEditingController();

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Report Store',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: reasons.map((r) {
                    final selected = selectedReason == r['value'];
                    return GestureDetector(
                      onTap: () =>
                          setModalState(() => selectedReason = r['value']!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.red.withOpacity(0.1)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? Colors.red.shade300
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          r['label']!,
                          style: TextStyle(
                            color:
                                selected ? Colors.red.shade700 : Colors.black87,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: detailsController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Add details (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade500,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Send Report'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (ok != true) {
      detailsController.dispose();
      return;
    }
    try {
      await ApiService.post(ApiConfig.storeReports, {
        'store': _storeId,
        'reason': selectedReason,
        'details': detailsController.text.trim(),
      });
      if (!mounted) return;
      Helpers.showSnackBar(context, 'Report submitted. Thank you.');
    } catch (e) {
      if (!mounted) return;
      Helpers.showSnackBar(context, 'Failed to send report: $e', isError: true);
    } finally {
      detailsController.dispose();
    }
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
      onDeleteImage: _deleteProfileImage,
      onDeleteCoverImage: _deleteCoverImage,
      onSettingsTap: null,
      onSettingsMenuSelected: null,
      isOwnerView: _isOwnerView,
      isFollowing: _isFollowingStore,
      onFollowTap: !_isOwnerView ? _handleFollow : null,
      onFavoriteTap: !_isOwnerView ? _handleFavorite : null,
      onReportTap: !_isOwnerView ? _showReportStoreSheet : null,
      primaryGradient: primaryGradient,
      phoneNumber: (_isOwnerView || _showPhonePublic) ? _phoneNumber : '',
      facebook: (_isOwnerView || _showSocialPublic) ? _facebook : null,
      instagram: (_isOwnerView || _showSocialPublic) ? _instagram : null,
      whatsapp: (_isOwnerView || _showSocialPublic) ? _whatsapp : null,
      tiktok: (_isOwnerView || _showSocialPublic) ? _tiktok : null,
      youtube: (_isOwnerView || _showSocialPublic) ? _youtube : null,
    );
  }

  void _navigateToEditProfile() {
    final userData = StorageService.getUserData();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditMerchantProfileScreen(
          initialName: _userName,
          initialPhone: _phoneNumber,
          initialImage: _avatarUrl ??
              userData?['profile_image'] ??
              userData?['store_image'] ??
              userData?['avatar'],
          initialCoverImage: _storeCoverUrl,
          initialStoreDescription: _storeDescription,
          initialAddress: _location,
          initialFacebook: _facebook,
          initialInstagram: _instagram,
          initialWhatsapp: _whatsapp,
          initialTiktok: _tiktok,
          initialYoutube: _youtube,
          initialLatitude: _latitude,
          initialLongitude: _longitude,
        ),
      ),
    ).then((result) {
      if (result == true) _loadUserData();
    });
  }

  void _handlePostMenuSelection(String value) {
    switch (value) {
      case 'product':
        if (!_hasProfileLocation()) {
          Helpers.showSnackBar(
            context,
            'Set your location area or GPS in Edit Profile before posting.',
            isError: true,
          );
          return;
        }
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const AddProductScreen())).then((result) {
          if (result == true && mounted) {
            if (_userId != null) {
              Provider.of<PostProvider>(context, listen: false)
                  .loadMyPosts(_userId.toString());
              Provider.of<PostProvider>(context, listen: false)
                  .loadMyOffers(_userId.toString());
            }
          }
        });
        break;
      case 'discount':
        Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AddPromotionScreen()))
            .then((result) {
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
        if (!_hasProfileLocation()) {
          Helpers.showSnackBar(
            context,
            'Set your location area or GPS in Edit Profile before posting.',
            isError: true,
          );
          return;
        }
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => AddPackScreen()));
        break;
    }
  }

  // Offer editing now uses AddPromotionScreen in edit mode.

  bool _hasProfileLocation() {
    final userData = StorageService.getUserData();
    final address = (userData?['address'] ?? userData?['location'] ?? '')
        .toString()
        .trim();
    final latRaw = userData?['latitude'];
    final lngRaw = userData?['longitude'];
    final lat = double.tryParse(latRaw?.toString() ?? '');
    final lng = double.tryParse(lngRaw?.toString() ?? '');
    final hasGps = lat != null && lng != null;
    return address.isNotEmpty || hasGps;
  }

  Future<void> _submitReview() async {
    if (_userId == null || _rating == 0) return;

    setState(() => _isSubmittingReview = true);

    try {
      final resp = await ApiService.post(ApiConfig.reviews, {
        'store': _userId,
        'rating': _rating,
        'comment': _reviewController.text.trim(),
      });

      // If ApiService doesn't throw on non-2xx, guard here.
      if (resp is Map && (resp['error'] != null || resp['detail'] != null)) {
        throw Exception(resp['error'] ?? resp['detail']);
      }

      if (!mounted) return;

      _reviewController.clear();
      setState(() {
        _rating = 0.0;
        _showReviewForm = false;
      });

      await _fetchStoreData();
      if (mounted) {
        Helpers.showSnackBar(context, 'Review submitted successfully');
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Failed to submit review: $e',
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSubmittingReview = false);
    }
  }

  Widget _buildReviewSection() {
    if (_isOwnerView) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Rate this store',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _showReviewForm = !_showReviewForm;
                    if (!_showReviewForm) {
                      _reviewController.clear();
                      _rating = 0.0;
                    }
                  });
                },
                child: Text(_showReviewForm ? 'Cancel' : 'Write Review'),
              ),
            ],
          ),
          if (_showReviewForm) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Rating: '),
                ...List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() => _rating = (index + 1).toDouble());
                    },
                    child: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 28,
                    ),
                  );
                }),
                const SizedBox(width: 8),
                Text('${_rating.toInt()}/5'),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reviewController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Write your review...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _isSubmittingReview || _rating == 0 ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isSubmittingReview
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit Review'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = AppColors.primaryColor;
    const Gradient primaryGradient = AppColors.deepGradient;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: _isOwnerView
            ? AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                centerTitle: true,
                title: const Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                actions: [
                  ValueListenableBuilder<int>(
                    valueListenable:
                        NotificationBadgeService.instance.unreadCount,
                    builder: (context, unread, _) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            tooltip: 'Notifications',
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const NotificationsScreen(),
                                ),
                              );
                              NotificationBadgeService.instance.refresh();
                            },
                            icon: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0EEFF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.notifications_outlined,
                                color: AppColors.primaryColor,
                                size: 20,
                              ),
                            ),
                          ),
                          if (unread > 0)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: const BoxConstraints(minWidth: 16),
                                child: Text(
                                  unread > 99 ? '99+' : '$unread',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: _onSettingsMenuSelected,
                    offset: const Offset(0, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined,
                                color: AppColors.primaryColor, size: 20),
                            const SizedBox(width: 12),
                            const Text('Edit Information'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, color: Colors.red, size: 20),
                            SizedBox(width: 12),
                            Text('Logout', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      width: 38,
                      height: 38,
                      margin: const EdgeInsets.only(right: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0EEFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.settings_outlined,
                        color: AppColors.primaryColor,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              )
            : AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      size: 20,
                      color: Colors.black,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  _userName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                centerTitle: true,
              ),
        floatingActionButton: _isOwnerView
            ? FloatingActionButton(
                onPressed: _showPublishMenu,
                backgroundColor: AppColors.primaryColor,
                child: const Icon(Icons.add, color: Colors.white),
              )
            : null,
        body: RefreshIndicator(
          onRefresh: _refreshProfile,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _buildMerchantHeader(primaryColor, primaryGradient),
              ),
              SliverToBoxAdapter(
                child: Consumer2<PostProvider, PackProvider>(
                  builder: (context, postProvider, packProvider, _) {
                    final productsCount = _isOwnerView
                        ? postProvider.myPosts.length
                        : postProvider.storePosts.length;
                    final offersCount = _isOwnerView
                        ? postProvider.myOffers.length
                        : postProvider.storeOffers.length;
                    final packsCount = _isOwnerView
                        ? packProvider.myPacks.length
                        : packProvider.storePacks.length;

                    final postsCount = productsCount + offersCount + packsCount;

                    return ProfilePostFilter(
                      selectedIndex: _selectedFilterIndex,
                      postsCount: postsCount,
                      onFilterChanged: (index) {
                        setState(() {
                          _selectedFilterIndex = index;
                          _profileVisibleCount = 12;
                        });
                      },
                      searchController: _searchController,
                      onSearchChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          _profileVisibleCount = 12;
                        });
                      },
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: _buildMerchantPosts(
                    type: _getFilterType(_selectedFilterIndex)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMerchantPosts({required String type}) {
    return Consumer2<PostProvider, PackProvider>(
      builder: (context, postProvider, packProvider, child) {
        if (_isProfileContentLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final products =
            _isOwnerView ? postProvider.myPosts : postProvider.storePosts;
        final offers =
            _isOwnerView ? postProvider.myOffers : postProvider.storeOffers;
        final packs =
            _isOwnerView ? packProvider.myPacks : packProvider.storePacks;

        List<dynamic> items = [];
        if (type == 'promotion') {
          items = offers;
        } else if (type == 'pack') {
          items = packs;
        } else if (type == 'all') {
          items = [...products, ...offers, ...packs];
        } else {
          items = products;
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

          final matchesSearch = _searchQuery.isEmpty ||
              title.toLowerCase().contains(_searchQuery.toLowerCase());
          return matchesType && matchesSearch;
        }).toList();

        if (filteredItems.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.inventory_2_outlined,
                      size: 60, color: AppColors.textHint),
                  SizedBox(height: 12),
                  Text('No content here yet',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          );
        }

        final displayedItems =
            filteredItems.take(_profileVisibleCount).toList();
        final hasMore = filteredItems.length > displayedItems.length;

        return Column(
          children: [
            GridView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: CardConstants.gridHorizontalPadding,
                vertical: CardConstants.gridVerticalPadding,
              ),
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: CardConstants.gridCrossAxisCount,
                crossAxisSpacing: CardConstants.gridCrossAxisSpacing,
                mainAxisSpacing: CardConstants.gridMainAxisSpacing,
                childAspectRatio: CardConstants.gridChildAspectRatio,
              ),
              itemCount: displayedItems.length,
              itemBuilder: (context, index) {
                final item = displayedItems[index];
                if (item is Post) {
                  return ProductCard(
                    product: item,
                    showUnavailableOverlay: true,
                    showStoreName: false,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        Routes.productDetails,
                        arguments: item,
                      );
                    },
                    onEditTap: _isOwnerView
                        ? () {
                            Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            AddProductScreen(product: item)))
                                .then((result) {
                              if (result == true && _userId != null) {
                                context
                                    .read<PostProvider>()
                                    .loadMyPosts(_userId.toString());
                              }
                            });
                          }
                        : null,
                  );
                } else if (item is Pack) {
                  return PackCard(
                    pack: item,
                    isUnavailable: !item.isAvailable,
                    showUnavailableOverlay: true,
                    onTap: () {
                      Navigator.pushNamed(context, Routes.packDetails,
                          arguments: item);
                    },
                    onEditTap: _isOwnerView
                        ? () {
                            Navigator.pushNamed(context, Routes.addPack,
                                    arguments: item)
                                .then((result) {
                              if (result == true && mounted) {
                                final storeId = _storeId;
                                if (storeId != null) {
                                  context
                                      .read<PackProvider>()
                                      .loadMyPacks(storeId);
                                }
                              }
                            });
                          }
                        : null,
                  );
                } else if (item is Offer) {
                  try {
                    return PromotionCard(
                      offer: item,
                      showUnavailableOverlay: true,
                      showStoreName: false,
                      onTap: () {
                        final product = item.product;
                        final productWithPromotion = product.copyWith(
                          price: item.newPrice,
                          oldPrice: product.price,
                          discountPercentage: item.discountPercentage,
                        );
                        Navigator.pushNamed(
                          context,
                          Routes.productDetails,
                          arguments: productWithPromotion,
                        );
                      },
                      onEditTap: _isOwnerView
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AddPromotionScreen(offer: item),
                                ),
                              ).then((result) {
                                if (result == true && mounted) {
                                  final provider = Provider.of<PostProvider>(
                                      context,
                                      listen: false);
                                  if (_userId != null) {
                                    provider.loadMyPosts(_userId.toString());
                                  }
                                  if (_storeId != null) {
                                    provider.loadMyOffers(_storeId.toString());
                                    context
                                        .read<PackProvider>()
                                        .loadMyPacks(_storeId!);
                                  }
                                  provider.loadOffers();
                                }
                              });
                            }
                          : null,
                    );
                  } catch (e) {
                    debugPrint('Profile: Error displaying offer: $e');
                    return const SizedBox.shrink();
                  }
                }
                return const SizedBox.shrink();
              },
            ),
            if (hasMore)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _profileVisibleCount += 12;
                    });
                  },
                  icon: const Icon(Icons.expand_more_rounded),
                  label: const Text('Load more'),
                ),
              ),
          ],
        );
      },
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
    final fullImageUrl =
        imageUrl.startsWith('/') ? 'http://127.0.0.1:8000$imageUrl' : imageUrl;

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
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._child);
  final Widget _child;

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return _child;
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
