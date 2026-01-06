import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/routing/routes.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/config/api_config.dart';
import '../../data/models/backend_store_model.dart';
import '../../data/models/post_model.dart';
import '../../data/models/offer_model.dart';
import '../../data/models/pack_model.dart';
import '../../data/repositories/post_repository.dart';
import '../../data/repositories/store_repository.dart';
import '../home/widgets/product_card.dart';
import '../home/widgets/promotion_card.dart';
import '../home/widgets/pack_card.dart';
import '../shared_widgets/empty_state_widget.dart';
import '../shared_widgets/shimmer_loading.dart';
import '../home/main_navigation_screen.dart';

/// Enhanced Store Visit Page with complete information and tabs
/// Shows: Store info (name, description, address, phone, location) + Tabs (Products, Promotions, Packs)
class EnhancedStoreScreen extends StatefulWidget {
  final int storeId;

  const EnhancedStoreScreen({
    super.key,
    required this.storeId,
  });

  @override
  State<EnhancedStoreScreen> createState() => _EnhancedStoreScreenState();
}

class _EnhancedStoreScreenState extends State<EnhancedStoreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoadingStore = false;
  bool _isLoadingProducts = false;
  bool _isLoadingOffers = false;
  bool _isLoadingPacks = false;

  String? _error;
  BackendStore? _store;
  List<Post> _products = [];
  List<Offer> _offers = [];
  List<Pack> _packs = [];

  // Follow and Rating state
  bool _isFollowing = false;
  bool _isLoadingFollow = false;
  double _userRating = 0;
  int _followersCount = 0;
  double _storeRating = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkIfOwnStore();
  }

  Future<void> _checkIfOwnStore() async {
    // Check if this is the current user's store
    try {
      final userData = StorageService.getUserData();
      final userId = userData?['id'];

      if (userId != null) {
        // Get user's store if they have one
        final storesResp = await ApiService.get(ApiConfig.stores);
        final storesList = storesResp is Map && storesResp.containsKey('results')
            ? storesResp['results'] as List
            : (storesResp is List ? storesResp : []);

        for (final item in storesList) {
          if (item is Map<String, dynamic>) {
            if (item['owner'] == userId && item['id'] == widget.storeId) {
              // This is the user's own store - redirect to profile
              if (mounted) {
                // Navigate to main navigation with profile tab selected (index 3)
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const MainNavigationScreen(initialIndex: 3),
                  ),
                );
              }
              return;
            }
          }
        }
      }
    } catch (e) {
      // If check fails, just continue to show store page
      debugPrint('Error checking store ownership: $e');
    }

    // Not own store or check failed - load store data
    _loadStoreData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStoreData() async {
    await _loadStoreInfo();
    await Future.wait([
      _loadProducts(),
      _loadOffers(),
      _loadPacks(),
      _loadFollowStatus(),
      _loadUserRating(),
    ]);
  }

  Future<void> _loadFollowStatus() async {
    try {
      final response = await ApiService.get(ApiConfig.followersCheck(widget.storeId));
      if (mounted && response is Map) {
        setState(() {
          _isFollowing = response['is_following'] == true;
        });
      }
    } catch (e) {
      debugPrint('Error loading follow status: $e');
    }
  }

  Future<void> _loadUserRating() async {
    try {
      final response = await ApiService.get(ApiConfig.reviewsMyStoreRating(widget.storeId));
      if (mounted && response is Map) {
        setState(() {
          _userRating = (response['rating'] as num?)?.toDouble() ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error loading user rating: $e');
    }
  }

  Future<void> _loadStoreInfo() async {
    setState(() {
      _isLoadingStore = true;
      _error = null;
    });

    try {
      final store = await StoreRepository.getStore(widget.storeId);
      if (mounted && store != null) {
        setState(() {
          _store = store;
          _followersCount = store.followersCount;
          _storeRating = store.averageRating;
          _isLoadingStore = false;
        });
      } else if (mounted) {
        setState(() => _isLoadingStore = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoadingStore = false;
        });
      }
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      final products = await PostRepository.getPosts(storeId: widget.storeId);
      if (mounted) {
        setState(() {
          _products = products;
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProducts = false);
      }
    }
  }

  Future<void> _loadOffers() async {
    setState(() => _isLoadingOffers = true);
    try {
      // Get all offers and filter by store
      final allOffers = await PostRepository.getOffers();
      final storeOffers = allOffers
          .where((offer) => offer.product.storeId == widget.storeId)
          .toList();

      if (mounted) {
        setState(() {
          _offers = storeOffers;
          _isLoadingOffers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingOffers = false);
      }
    }
  }

  Future<void> _loadPacks() async {
    setState(() => _isLoadingPacks = true);
    try {
      // Load stores for name enrichment
      Map<int, String> storesById = {};
      try {
        final storesResp = await ApiService.get('/api/stores/stores/');
        final storesList = storesResp is Map && storesResp.containsKey('results')
            ? storesResp['results'] as List
            : (storesResp is List ? storesResp : []);
        for (final item in storesList) {
          if (item is Map<String, dynamic>) {
            storesById[item['id']] = item['name'] ?? 'متجر';
          }
        }
      } catch (e) {
        // If stores loading fails, continue without enrichment
      }

      // Load packs from API and filter by store
      final response = await ApiService.get('/api/catalog/packs/');
      List<dynamic> packsList = [];

      if (response is Map<String, dynamic> && response['results'] != null) {
        packsList = response['results'] as List;
      } else if (response is List) {
        packsList = response;
      }

      final allPacks = packsList
          .map((json) => Pack.fromJson(json as Map<String, dynamic>, storesById: storesById))
          .toList();

      // Filter packs by store/merchant
      final storePacks = allPacks
          .where((pack) => pack.merchantId == widget.storeId)
          .toList();

      if (mounted) {
        setState(() {
          _packs = storePacks;
          _isLoadingPacks = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPacks = false);
      }
    }
  }

  Future<void> _toggleFollow() async {
    if (_isLoadingFollow) return;

    setState(() => _isLoadingFollow = true);

    try {
      final response = await ApiService.post(
        ApiConfig.followersToggle,
        {'store': widget.storeId},
      );

      if (mounted && response is Map) {
        final isFollowing = response['is_following'] == true;
        setState(() {
          _isFollowing = isFollowing;
          _followersCount += isFollowing ? 1 : -1;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isFollowing ? 'تم متابعة المتجر' : 'تم إلغاء المتابعة'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingFollow = false);
    }
  }

  void _showRatingDialog() {
    double tempRating = _userRating > 0 ? _userRating : 0;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('تقييم المتجر', textAlign: TextAlign.center),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('كيف تقيم تجربتك مع هذا المتجر؟'),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() => tempRating = index + 1.0);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            index < tempRating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 36,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting || tempRating == 0
                      ? null
                      : () async {
                          setDialogState(() => isSubmitting = true);
                          try {
                            await ApiService.post(
                              ApiConfig.reviewsRateStore,
                              {
                                'store': widget.storeId,
                                'rating': tempRating.toInt(),
                              },
                            );

                            if (mounted) {
                              setState(() => _userRating = tempRating);
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(content: Text('شكراً على تقييمك!')),
                              );
                              // Reload store info to get updated average rating
                              _loadStoreInfo();
                            }
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            if (mounted) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(content: Text('حدث خطأ: $e')),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('تأكيد', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openMap() async {
    if (_store?.latitude == null || _store?.longitude == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('موقع المتجر غير متوفر')),
        );
      }
      return;
    }

    final lat = _store!.latitude!;
    final lng = _store!.longitude!;

    // Try Google Maps first, fallback to web maps
    final googleMapsUrl = Uri.parse('geo:$lat,$lng?q=$lat,$lng(${_store!.name})');
    final webMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webMapsUrl)) {
        await launchUrl(webMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not open maps';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح الخريطة')),
        );
      }
    }
  }

  Future<void> _makePhoneCall() async {
    if (_store?.phoneNumber == null || _store!.phoneNumber.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('رقم الهاتف غير متوفر')),
        );
      }
      return;
    }

    final phoneUrl = Uri.parse('tel:${_store!.phoneNumber}');
    try {
      if (await canLaunchUrl(phoneUrl)) {
        await launchUrl(phoneUrl);
      } else {
        throw 'Could not launch phone';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر الاتصال')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // App Bar with store name
              SliverAppBar(
                title: Text(_store?.name ?? 'متجر #${widget.storeId}'),
                backgroundColor: Colors.white,
                foregroundColor: AppColors.textPrimary,
                elevation: 0,
                pinned: true,
                floating: false,
              ),

              // Store Information Section
              SliverToBoxAdapter(
                child: _buildStoreInfoSection(),
              ),

              // Tabs
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primaryBlue,
                    unselectedLabelColor: AppColors.textHint,
                    indicatorColor: AppColors.primaryBlue,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    unselectedLabelStyle: const TextStyle(fontSize: 14),
                    tabs: const [
                      Tab(text: 'المنتجات'),
                      Tab(text: 'التخفيضات'),
                      Tab(text: 'الحزم'),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: _isLoadingStore
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _buildErrorState()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildProductsTab(),
                        _buildOffersTab(),
                        _buildPacksTab(),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildStoreInfoSection() {
    if (_isLoadingStore) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_store == null) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Image
          if (_store!.coverImageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  _store!.coverImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, size: 40, color: Colors.grey),
                  ),
                ),
              ),
            ),

          if (_store!.coverImageUrl.isNotEmpty) const SizedBox(height: 16),

          // Profile Image + Store Name + Description
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Image
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  image: _store!.profileImageUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(_store!.profileImageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _store!.profileImageUrl.isEmpty
                    ? const Icon(Icons.store, size: 35, color: Colors.grey)
                    : null,
              ),

              const SizedBox(width: 16),

              // Store Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Store Name
                    Text(
                      _store!.name,
                      style: AppTextStyles.h2.copyWith(fontSize: 20),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Description
                    if (_store!.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        _store!.description,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Store Stats Row (Rating + Followers)
          Row(
            children: [
              // Store Average Rating
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      _storeRating > 0 ? _storeRating.toStringAsFixed(1) : 'جديد',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.amber,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Followers Count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people, color: AppColors.primaryBlue, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '$_followersCount متابع',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Rating and Follow Buttons
          Row(
            children: [
              // Rating Button
              Expanded(
                child: GestureDetector(
                  onTap: _showRatingDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _userRating > 0 ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _userRating > 0 ? 'تقييمك: ${_userRating.toStringAsFixed(0)}' : 'قيّم المتجر',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.amber[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Follow Button
              Expanded(
                child: GestureDetector(
                  onTap: _isLoadingFollow ? null : _toggleFollow,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _isFollowing
                          ? AppColors.primaryBlue
                          : AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _isLoadingFollow
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isFollowing ? Icons.check : Icons.add,
                                color: _isFollowing ? Colors.white : AppColors.primaryBlue,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isFollowing ? 'متابَع' : 'متابعة',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _isFollowing ? Colors.white : AppColors.primaryBlue,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Contact Information
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.scaffoldBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Phone
                if (_store!.phoneNumber.isNotEmpty)
                  GestureDetector(
                    onTap: _makePhoneCall,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.phone, color: Colors.green, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'رقم الهاتف',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _store!.phoneNumber,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.call, color: Colors.green, size: 20),
                      ],
                    ),
                  ),

                // Address
                if (_store!.address.isNotEmpty) ...[
                  if (_store!.phoneNumber.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, color: Colors.grey[300]),
                    ),
                  GestureDetector(
                    onTap: _store!.latitude != null && _store!.longitude != null
                        ? _openMap
                        : null,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.location_on, color: AppColors.primaryBlue, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'العنوان',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _store!.address,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (_store!.latitude != null && _store!.longitude != null)
                          Icon(Icons.map, color: AppColors.primaryBlue, size: 20),
                      ],
                    ),
                  ),
                ],

                // No info message
                if (_store!.phoneNumber.isEmpty && _store!.address.isEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey[400], size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'لا توجد معلومات اتصال',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String text,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.scaffoldBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primaryBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey[400],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsTab() {
    if (_isLoadingProducts) {
      return _buildGridShimmer();
    }

    if (_products.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.inventory_2_outlined,
        title: 'لا توجد منتجات',
        message: 'لم ينشر هذا المتجر أي منتجات بعد',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        return ProductCard(
          product: _products[index],
          onTap: () {
            Navigator.pushNamed(
              context,
              Routes.productDetails,
              arguments: _products[index],
            );
          },
        );
      },
    );
  }

  Widget _buildOffersTab() {
    if (_isLoadingOffers) {
      return _buildGridShimmer();
    }

    if (_offers.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.local_offer_outlined,
        title: 'لا توجد تخفيضات',
        message: 'لا توجد تخفيضات نشطة حالياً في هذا المتجر',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
      ),
      itemCount: _offers.length,
      itemBuilder: (context, index) {
        return PromotionCard(offer: _offers[index]);
      },
    );
  }

  Widget _buildPacksTab() {
    if (_isLoadingPacks) {
      return _buildGridShimmer();
    }

    if (_packs.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.inventory_2_outlined,
        title: 'لا توجد حزم',
        message: 'لا توجد حزم متاحة حالياً في هذا المتجر',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
      ),
      itemCount: _packs.length,
      itemBuilder: (context, index) {
        return PackCard(pack: _packs[index]);
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'حدث خطأ أثناء تحميل بيانات المتجر',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadStoreData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridShimmer() {
    return ShimmerLoading(
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.68,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return const ProductCardSkeleton();
        },
      ),
    );
  }
}

/// Custom SliverPersistentHeaderDelegate for sticky tabs
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}
