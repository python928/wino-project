import 'package:wino/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/config/api_config.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/home_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/providers/pack_provider.dart';
import '../../core/providers/post_provider.dart';
import '../../core/providers/store_provider.dart';
import '../../core/providers/wallet_provider.dart';
import '../../core/routing/routes.dart';
import '../../core/services/api_service.dart';
import '../../core/services/follow_change_notifier.dart';
import '../../core/services/notification_badge_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/jwt_validator.dart';
import '../../data/models/offer_model.dart';
import '../../data/models/pack_model.dart';
import '../../data/models/post_model.dart';
import '../../data/models/user_model.dart';
import '../auth/splash_screen.dart';
import '../common/constants/card_constants.dart';
import '../notifications/notifications_screen.dart';
import '../shared_widgets/app_dropdown_menu.dart';
import '../shared_widgets/app_icon_action_button.dart';
import '../shared_widgets/cards/pack_card.dart';
import '../shared_widgets/cards/product_card.dart';
import '../shared_widgets/cards/promotion_card.dart';
import '../shared_widgets/directions_button.dart';
import '../shared_widgets/qr_payload_dialog.dart';
import '../shared_widgets/report_bottom_sheet.dart';
import '../shared_widgets/shimmer_loading.dart';
import '../shared_widgets/wino_coin_badge.dart';
import '../subscription/ads_dashboard_screen.dart';
import '../wallet/coin_store_screen.dart';
import 'add_pack_screen.dart';
import 'add_product_screen.dart';
import 'add_promotion_screen.dart';
import 'edit_merchant_profile_screen.dart';
import 'widgets/profile_merchant_header.dart';
import 'widgets/profile_post_filter.dart';

class ProfileScreen extends StatefulWidget {
  final int? storeId;
  final bool isActive;

  const ProfileScreen({
    super.key,
    this.storeId,
    this.isActive = true,
  });

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
  bool _isVerifiedStore = false;

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

  bool _isSubmittingReview = false;
  final TextEditingController _reviewController = TextEditingController();
  double _rating = 0.0;
  bool _showReviewForm = false;
  bool _isProfileContentLoading = true;
  int _profileLoadVersion = 0;

  List<AppDropdownAction<String>> _buildSettingsActions(BuildContext context) {
    return [
      AppDropdownAction(
        value: 'edit',
        icon: Icons.edit_outlined,
        label: context.l10n.profileSettingsEdit,
      ),
      AppDropdownAction(
        value: 'ads',
        icon: Icons.campaign_outlined,
        label: context.l10n.profileTooltipAds,
      ),
      AppDropdownAction(
        value: 'share',
        icon: Icons.share_outlined,
        label: context.l10n.profileTooltipShare,
      ),
      AppDropdownAction(
        value: 'feedback_send',
        icon: Icons.feedback_outlined,
        label: context.l10n.profileSettingsSendFeedback,
      ),
      AppDropdownAction(
        value: 'language',
        icon: Icons.language_outlined,
        label: context.l10n.profileSettingsLanguage,
      ),
      AppDropdownAction(
        value: 'logout',
        icon: Icons.logout,
        label: context.l10n.profileSettingsLogout,
        destructive: true,
        showDividerAbove: true,
      ),
    ];
  }

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
                  title: Text(context.tr('Add Product'),
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
                  title: Text(context.tr('Add Discount'),
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
                  title: Text(context.tr('Add Pack'),
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    _handlePostMenuSelection('pack');
                  },
                ),
                const Divider(height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.analytics_outlined,
                        color: AppColors.primaryColor, size: 20),
                  ),
                  title: Text(context.tr('Ads'),
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdsDashboardScreen(),
                      ),
                    );
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
    _primeProfileShell();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
    if (widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.isActive) {
          _loadUserData();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final becameActive = !oldWidget.isActive && widget.isActive;
    if (oldWidget.storeId != widget.storeId || becameActive) {
      _loadUserData();
    }
  }

  int? _parseUserId(dynamic rawId) {
    if (rawId is int) return rawId;
    return int.tryParse(rawId?.toString() ?? '');
  }

  bool get _isOwnProfileRoute => widget.storeId == null;

  bool _isActiveProfileLoad(int loadVersion) {
    return mounted && loadVersion == _profileLoadVersion;
  }

  String _trOrFallback(String key, String fallback) {
    try {
      return context.tr(key);
    } catch (_) {
      return fallback;
    }
  }

  Future<void> _runSafeProfileLoadStep(
    String label,
    Future<void> Function() task,
  ) async {
    try {
      await task();
    } catch (e, st) {
      debugPrint('Profile load step failed ($label): $e');
      debugPrint('$st');
    }
  }

  User? _getCachedUser({
    required AuthProvider authProvider,
    Map<String, dynamic>? userData,
  }) {
    final providerUser = authProvider.user;
    if (providerUser != null) {
      return providerUser;
    }

    final raw = userData ?? StorageService.getUserData();
    if (raw == null) return null;

    try {
      return User.fromJson(Map<String, dynamic>.from(raw));
    } catch (_) {
      return null;
    }
  }

  void _applyUserSnapshot(User user, {bool updateIdentity = false}) {
    if (updateIdentity) {
      _currentUserId = user.id;
      _userId = user.id;
      _storeId = user.id;
    }

    _userName = user.fullName;
    _location = user.address.isNotEmpty ? user.address : _location;
    _avatarUrl = user.profileImage;
    _storeDescription = user.storeDescription;
    _storeCoverUrl = user.coverImage;
    _phoneNumber = (user.phone ?? '').toString();
    _followersCount = user.followersCount;
    _averageRating = user.averageRating;
    _isVerifiedStore = user.isVerified;
    _facebook = user.facebook;
    _instagram = user.instagram;
    _whatsapp = user.whatsapp;
    _tiktok = user.tiktok;
    _youtube = user.youtube;
    _showPhonePublic = user.showPhonePublic;
    _showSocialPublic = user.showSocialPublic;
    _latitude = user.latitude;
    _longitude = user.longitude;
  }

  void _primeProfileShell() {
    final authProvider = context.read<AuthProvider>();
    final cachedUser = _getCachedUser(authProvider: authProvider);
    final currentUserId = cachedUser?.id ??
        _parseUserId(StorageService.getUserData()?['id']) ??
        authProvider.user?.id;

    _currentUserId = currentUserId;
    _userId = _isOwnProfileRoute ? currentUserId : widget.storeId;
    _storeId = _userId;

    if (cachedUser != null &&
        (_isOwnProfileRoute || cachedUser.id == widget.storeId)) {
      _applyUserSnapshot(cachedUser, updateIdentity: _isOwnProfileRoute);
    }
  }

  Future<int?> _resolveCurrentUserId(
    AuthProvider authProvider, {
    Map<String, dynamic>? userData,
  }) async {
    final fromStorage = _parseUserId(userData?['id']);
    if (fromStorage != null) return fromStorage;

    final fromProvider = authProvider.user?.id;
    if (fromProvider != null) return fromProvider;

    final accessToken = await StorageService.getAccessToken();
    final fromToken = _parseUserId(
        accessToken == null ? null : JWTValidator.getUserId(accessToken));
    if (fromToken != null) return fromToken;

    try {
      await authProvider.loadProfile();
    } catch (_) {
      // best-effort: the caller will handle unresolved identity.
    }

    return authProvider.user?.id;
  }

  Future<void> _fetchStoreData({int? userId, int? loadVersion}) async {
    final requestedUserId = userId ?? _userId;
    final expectedLoadVersion = loadVersion ?? _profileLoadVersion;
    if (requestedUserId == null) return;
    try {
      final resp = await ApiService.get('${ApiConfig.users}$requestedUserId/');
      if (resp is! Map) return;

      final u = User.fromJson(Map<String, dynamic>.from(resp));

      if (!_isActiveProfileLoad(expectedLoadVersion) ||
          _userId != requestedUserId) {
        return;
      }
      setState(() {
        _storeId = u.id; // userId == storeId
        _userName = u.fullName;
        _avatarUrl = u.profileImage;
        _storeDescription = u.storeDescription;
        _storeCoverUrl = u.coverImage;
        _phoneNumber = (u.phone ?? '').toString();
        _followersCount = u.followersCount;
        _averageRating = u.averageRating;
        _isVerifiedStore = u.isVerified;
        _location = u.address.isNotEmpty ? u.address : 'Select Location';

        _facebook = u.facebook;
        _instagram = u.instagram;
        _whatsapp = u.whatsapp;
        _tiktok = u.tiktok;
        _youtube = u.youtube;
        _showPhonePublic = u.showPhonePublic;
        _showSocialPublic = u.showSocialPublic;
        _latitude = u.latitude;
        _longitude = u.longitude;
      });
    } catch (e) {
      debugPrint('Error fetching unified profile: $e');
    }
  }

  bool get _isOwnerView {
    if (_isOwnProfileRoute) return true;
    if (_currentUserId == null || _userId == null) return false;
    return _currentUserId == _userId;
  }

  String get _storeShareLink => '${ApiConfig.baseUrl}s/${_userId ?? 0}/';

  Future<void> _shareStore() async {
    if (_userId == null) return;
    await Share.share('${_userName.trim()}\n$_storeShareLink');
  }

  Future<void> _showStoreQr() async {
    if (_userId == null || !mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => QrPayloadDialog(
        payload: _storeShareLink,
        title: context.l10n.profileShareQrTitle,
        showPayloadText: false,
      ),
    );
  }

  Future<void> _copyStoreLink() async {
    if (_userId == null || !mounted) return;
    await Clipboard.setData(ClipboardData(text: _storeShareLink));
    if (!mounted) return;
    Helpers.showSnackBar(context, context.l10n.profileShareLinkCopied);
  }

  Future<void> _showShareProfileOptions() async {
    if (_userId == null || !mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        final l10n = sheetContext.l10n;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.qr_code_2_outlined),
                title: Text(l10n.profileShareShowQr),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showStoreQr();
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_outlined),
                title: Text(l10n.profileShareCopyLink),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _copyStoreLink();
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: Text(l10n.profileShareShare),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _shareStore();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<ImageSource?> _showImageSourcePicker() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        final l10n = context.l10n;
        return AlertDialog(
          title: Text(l10n.profileSettingsChooseImageSource),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading:
                    const Icon(Icons.camera_alt, color: AppColors.primaryColor),
                title: Text(l10n.profileSettingsCamera),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library,
                    color: AppColors.primaryColor),
                title: Text(l10n.profileSettingsGallery),
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
        Helpers.showSnackBar(
            context, context.tr('Cover image updated successfully'));
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          '${context.tr('Failed to update cover image')}: $e',
        );
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
        title: Text(context.tr('Delete cover image?')),
        content: Text(context.tr('This will remove your current cover image.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr('Delete')),
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
        Helpers.showSnackBar(
            context, context.tr('Cover image deleted successfully'));
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          '${context.tr('Failed to delete cover image')}: $e',
        );
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
          Helpers.showSnackBar(
              context, context.tr('Profile image updated successfully'));
        }
      } catch (e) {
        if (mounted) {
          Helpers.showSnackBar(
            context,
            '${context.tr('Failed to update image')}: $e',
          );
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
        title: Text(context.tr('Delete profile image?')),
        content:
            Text(context.tr('This will remove your current profile image.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr('Delete')),
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
        Helpers.showSnackBar(
            context, context.tr('Profile image deleted successfully'));
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          '${context.tr('Failed to delete profile image')}: $e',
        );
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
    final loadVersion = ++_profileLoadVersion;
    final authProvider = context.read<AuthProvider>();
    final postProvider = context.read<PostProvider>();
    final packProvider = context.read<PackProvider>();
    final selectLocationLabel =
        _trOrFallback('Select Location', 'Select Location');
    final loadingLabel = _trOrFallback('Loading...', 'Loading...');

    try {
      final userData = StorageService.getUserData();
      final accessToken = await StorageService.getAccessToken();
      if (userData == null && accessToken == null) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SplashScreen()),
          (Route<dynamic> route) => false,
        );
        return;
      }

      final currentUserId =
          await _resolveCurrentUserId(authProvider, userData: userData);
      final targetUserId = widget.storeId ?? currentUserId;
      if (targetUserId == null) {
        if (_isActiveProfileLoad(loadVersion)) {
          setState(() {
            _isProfileContentLoading = false;
          });
        }
        return;
      }
      final isOwnerTarget =
          currentUserId != null && currentUserId == targetUserId;
      final cachedUser = _getCachedUser(
        authProvider: authProvider,
        userData: userData,
      );

      if (mounted) {
        setState(() {
          _isProfileContentLoading = true;
          _currentUserId = currentUserId;
          _userId = targetUserId;
          _storeId = targetUserId;
          _isFollowingStore = false;
          _isLoadingFollowState = false;
          if (cachedUser != null &&
              (_isOwnProfileRoute || cachedUser.id == targetUserId)) {
            _applyUserSnapshot(cachedUser, updateIdentity: _isOwnProfileRoute);
          } else {
            _userName = loadingLabel;
            _location = loadingLabel;
            _storeDescription = '';
            _avatarUrl = null;
            _storeCoverUrl = null;
            _phoneNumber = '';
            _followersCount = 0;
            _averageRating = 0.0;
            _isVerifiedStore = false;
            _facebook = null;
            _instagram = null;
            _whatsapp = null;
            _tiktok = null;
            _youtube = null;
            _showPhonePublic = true;
            _showSocialPublic = true;
            _latitude = null;
            _longitude = null;
          }
        });
      }

      // Clear previous store/profile lists to avoid flashing stale data
      try {
        postProvider.clearMyData(notify: false);
        packProvider.clearAllData(notify: false);
      } catch (_) {
        // best-effort
      }

      if (isOwnerTarget) {
        try {
          await authProvider.loadProfile();
        } catch (_) {
          // If refresh fails, continue with cached data but do not block the UI.
        }

        if (!_isActiveProfileLoad(loadVersion) || _userId != targetUserId) {
          return;
        }
        final freshUser = authProvider.user;
        if (freshUser != null && freshUser.id == targetUserId) {
          final locationDisplay = freshUser.address.isNotEmpty
              ? freshUser.address
              : selectLocationLabel;
          setState(() {
            _currentUserId = freshUser.id;
            _userId = freshUser.id;
            _storeId = freshUser.id;
            _userName = freshUser.fullName;
            _location = locationDisplay;
            _phoneNumber = (freshUser.phone ?? '').toString();
            _storeDescription = freshUser.storeDescription;
            _avatarUrl = freshUser.profileImage;
            _storeCoverUrl = freshUser.coverImage;
            _followersCount = freshUser.followersCount;
            _averageRating = freshUser.averageRating;
            _isVerifiedStore = freshUser.isVerified;
            _facebook = freshUser.facebook;
            _instagram = freshUser.instagram;
            _whatsapp = freshUser.whatsapp;
            _tiktok = freshUser.tiktok;
            _youtube = freshUser.youtube;
            _showPhonePublic = freshUser.showPhonePublic;
            _showSocialPublic = freshUser.showSocialPublic;
            _latitude = freshUser.latitude;
            _longitude = freshUser.longitude;
          });
        }
      }

      await _fetchStoreData(userId: targetUserId, loadVersion: loadVersion);

      if (!_isActiveProfileLoad(loadVersion) || _userId != targetUserId) return;

      if (!isOwnerTarget) {
        await _loadFollowState(storeId: targetUserId, loadVersion: loadVersion);
      }

      if (!_isActiveProfileLoad(loadVersion) || _userId == null) return;

      if (isOwnerTarget) {
        await Future.wait([
          _runSafeProfileLoadStep(
            'my-posts',
            () => postProvider.loadMyPosts(_userId.toString()),
          ),
          _runSafeProfileLoadStep(
            'my-offers',
            () => postProvider.loadMyOffers(_userId.toString()),
          ),
          _runSafeProfileLoadStep(
            'my-packs',
            () => packProvider.loadMyPacks(_userId!),
          ),
        ]);
      } else {
        await Future.wait([
          _runSafeProfileLoadStep(
            'store-posts',
            () => postProvider.loadStorePosts(_userId!),
          ),
          _runSafeProfileLoadStep(
            'store-offers',
            () => postProvider.loadStoreOffers(_userId!),
          ),
          _runSafeProfileLoadStep(
            'store-packs',
            () => packProvider.loadStorePacks(_userId!),
          ),
        ]);
      }
    } catch (e, st) {
      debugPrint('Error loading profile data: $e');
      debugPrint('$st');
    } finally {
      if (_isActiveProfileLoad(loadVersion)) {
        setState(() {
          _isProfileContentLoading = false;
        });
      }
    }
  }

  Future<void> _refreshProfile() async {
    final walletProvider = context.read<WalletProvider>();
    await _loadUserData();
    if (_isOwnerView && mounted) {
      await walletProvider.fetchWallet(notifyStart: false);
    }
  }

  void _handleLogout() async {
    final authProvider = context.read<AuthProvider>();
    final postProvider = context.read<PostProvider>();
    final packProvider = context.read<PackProvider>();
    final homeProvider = context.read<HomeProvider>();
    final storeProvider = context.read<StoreProvider>();
    try {
      await authProvider.logout();
    } catch (_) {
      // best-effort
    }
    postProvider.clearAllData(notify: false);
    packProvider.clearAllData(notify: false);
    homeProvider.clearAllData(notify: false);
    storeProvider.clear();
    NotificationBadgeService.instance.clear();
    await StorageService.clearAll();
    await StorageService
        .setNotFirstTime(); // preserve onboarding flag so launcher screen doesn't re-appear
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const SplashScreen()),
        (Route<dynamic> route) => false,
      );
      Helpers.showSnackBar(context, context.tr('Logged out successfully!'));
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
      case 'store':
        if (_userId != null) {
          Navigator.pushNamed(context, Routes.store, arguments: _userId);
        }
        break;
      case 'ads':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AdsDashboardScreen(),
          ),
        );
        break;
      case 'share':
        _showShareProfileOptions();
        break;
      case 'feedback_send':
        Navigator.pushNamed(context, Routes.feedbackSend);
        break;
      case 'language':
        _showLanguagePicker();
        break;
      case 'logout':
        _handleLogout();
        break;
    }
  }

  Future<void> _showLanguagePicker() async {
    if (!mounted) return;
    final localeProvider = context.read<LocaleProvider>();
    final current = localeProvider.languageCode;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  current == 'ar'
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                ),
                title: Text(context.tr('العربية')),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await localeProvider.setLanguage('ar');
                },
              ),
              ListTile(
                leading: Icon(
                  current == 'en'
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                ),
                title: Text(context.tr('English')),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await localeProvider.setLanguage('en');
                },
              ),
              ListTile(
                leading: Icon(
                  current == 'fr'
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                ),
                title: Text(context.tr('Français')),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await localeProvider.setLanguage('fr');
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _handleFollow() {
    if (_storeId == null) return;
    if (!StorageService.isLoggedIn()) {
      Helpers.showSnackBar(context, context.tr('Log in to follow stores'),
          isError: true);
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
      FollowChangeNotifier.setFollowState(_storeId!, isFollowing);
      FollowChangeNotifier.bump();
      Helpers.showSnackBar(
        context,
        isFollowing
            ? context.tr('Followed store')
            : context.tr('Unfollowed store'),
      );
    }).catchError((_) {
      if (!mounted) return;
      Helpers.showSnackBar(context, context.tr('Failed to update follow'),
          isError: true);
    });
  }

  Future<void> _loadFollowState({int? storeId, int? loadVersion}) async {
    final targetStoreId = storeId ?? _storeId;
    final expectedLoadVersion = loadVersion ?? _profileLoadVersion;
    if (targetStoreId == null) return;
    if (_isOwnProfileRoute) return;
    if (_currentUserId != null && _currentUserId == targetStoreId) return;
    if (!StorageService.isLoggedIn()) return;
    if (_isLoadingFollowState) return;

    final cached = FollowChangeNotifier.getFollowState(targetStoreId);
    if (cached != null &&
        _isActiveProfileLoad(expectedLoadVersion) &&
        _storeId == targetStoreId) {
      setState(() => _isFollowingStore = cached);
    }

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
          if (followed is int && followed == targetStoreId) {
            isFollowing = true;
            break;
          }
          if (followed is Map && followed['id'] == targetStoreId) {
            isFollowing = true;
            break;
          }
        }
      }

      if (!_isActiveProfileLoad(expectedLoadVersion) ||
          _storeId != targetStoreId) {
        return;
      }
      setState(() => _isFollowingStore = isFollowing);
      FollowChangeNotifier.setFollowState(targetStoreId, isFollowing);
    } catch (_) {
      // ignore
    } finally {
      if (_isActiveProfileLoad(expectedLoadVersion) &&
          _storeId == targetStoreId) {
        setState(() => _isLoadingFollowState = false);
      }
    }
  }

  void _handleFavorite() {
    // TODO: Implement favorite functionality
    print('Favorite store: $_storeId');
  }

  Future<void> _showReportStoreSheet() async {
    if (_storeId == null) return;
    const reasons = [
      ReportReason('spam', 'Duplicate / spam store'),
      ReportReason('fake', 'Fake store / no real location'),
      ReportReason('fraud', 'Scam / asked for prepayment'),
      ReportReason('offensive', 'Offensive / prohibited content'),
      ReportReason('other', 'Other (wrong info, bad service)'),
    ];

    final result = await ReportBottomSheet.show(
      context: context,
      title: context.tr('Report Store'),
      reasons: reasons,
    );

    if (result == null) {
      return;
    }
    try {
      await ApiService.post(ApiConfig.storeReports, {
        'store': _storeId,
        'reason': result.reason,
        'details': result.details,
      });
      if (!mounted) return;
      Helpers.showSnackBar(context, context.tr('Report submitted. Thank you.'));
    } catch (e) {
      if (!mounted) return;
      Helpers.showSnackBar(
        context,
        '${context.tr('Failed to send report')}: $e',
        isError: true,
      );
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
      onSettingsMenuSelected: _isOwnerView ? _onSettingsMenuSelected : null,
      isOwnerView: _isOwnerView,
      isFollowing: _isFollowingStore,
      onFollowTap: !_isOwnerView ? _handleFollow : null,
      onFavoriteTap: !_isOwnerView ? _handleFavorite : null,
      onReportTap: !_isOwnerView ? _showReportStoreSheet : null,
      isVerified: _isVerifiedStore,
      primaryGradient: primaryGradient,
      directionsButton: DirectionsButton(
        destinationLat: _latitude,
        destinationLng: _longitude,
        label: context.l10n.mapLabel,
      ),
      settingsActions: _isOwnerView ? _buildSettingsActions(context) : const [],
      showImageEditActions: false,
      showCoverSettingsAction: false,
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
    final address =
        (userData?['address'] ?? userData?['location'] ?? '').toString().trim();
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
        Helpers.showSnackBar(
            context, context.tr('Review submitted successfully'));
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          '${context.tr('Failed to submit review')}: $e',
          isError: true,
        );
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
              Text(
                context.tr('Rate this store'),
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
                child: Text(_showReviewForm
                    ? context.tr('Cancel')
                    : context.tr('Write Review')),
              ),
            ],
          ),
          if (_showReviewForm) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(context.tr('Rating: ')),
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
                hintText: context.tr('Write your review...'),
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
                    : Text(context.tr('Submit Review')),
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

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: _isOwnerView
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              centerTitle: true,
              leadingWidth: 80,
              leading: Consumer<WalletProvider>(
                builder: (context, wallet, _) => Align(
                  alignment: Alignment.centerLeft,
                  child: WinoCoinBadge(
                    coins: wallet.coinsBalance,
                    margin: const EdgeInsetsDirectional.only(start: 4),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CoinStoreScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ),
              title: Text(
                context.l10n.profileTitle,
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
                    child: AppIconActionButton(
                      icon: Icons.notifications_outlined,
                      badgeCount: unread > 0 ? unread : null,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        );
                        NotificationBadgeService.instance.refresh();
                      },
                    ),
                  ),
                ),
                AppDropdownMenuButton<String>(
                  onSelected: _onSettingsMenuSelected,
                  offset: const Offset(0, 40),
                  actions: _buildSettingsActions(context),
                  child: Container(
                    margin: const EdgeInsets.only(right: 14),
                    child: const AppIconActionButton(
                      icon: Icons.settings_outlined,
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
              actions: [
                IconButton(
                  tooltip: context.tr('Share Store'),
                  onPressed: _showShareProfileOptions,
                  icon: const Icon(Icons.share_outlined),
                ),
              ],
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
    );
  }

  Widget _buildMerchantPosts({required String type}) {
    return Consumer2<PostProvider, PackProvider>(
      builder: (context, postProvider, packProvider, child) {
        if (_isProfileContentLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: ProductGridSkeleton(itemCount: 6),
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
                children: [
                  const Icon(Icons.inventory_2_outlined,
                      size: 60, color: AppColors.textHint),
                  const SizedBox(height: 12),
                  Text(context.tr('No content here yet'),
                      style: const TextStyle(color: AppColors.textSecondary)),
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
                  label: Text(context.tr('Load more')),
                ),
              ),
          ],
        );
      },
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
