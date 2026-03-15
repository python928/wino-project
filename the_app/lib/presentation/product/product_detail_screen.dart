import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import '../../data/models/post_model.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/config/api_config.dart';
import '../../core/utils/helpers.dart';
import '../../core/services/analytics_api_service.dart';
import '../../core/services/favorites_change_notifier.dart';
import '../../core/services/follow_change_notifier.dart';
import '../../data/repositories/store_repository.dart';
import '../common/widgets/reviews_section.dart';
import '../shared_widgets/contact_action_row.dart';
import '../shared_widgets/image_carousel.dart';
import '../shared_widgets/report_bottom_sheet.dart';

class ProductDetailsArgs {
  final Post product;
  final String sourceSurface; // home | search | other
  final String discoveryMode;
  final double? distanceKm;
  final String? wilayaCode;
  final String? searchQuery;
  final Map<String, dynamic>? searchContext;

  const ProductDetailsArgs({
    required this.product,
    this.sourceSurface = 'other',
    this.discoveryMode = 'none',
    this.distanceKm,
    this.wilayaCode,
    this.searchQuery,
    this.searchContext,
  });
}

class ProductDetailScreen extends StatefulWidget {
  final Post product;
  final String sourceSurface;
  final String discoveryMode;
  final double? distanceKm;
  final String? wilayaCode;
  final String? searchQuery;
  final Map<String, dynamic>? searchContext;

  const ProductDetailScreen({
    super.key,
    required this.product,
    this.sourceSurface = 'other',
    this.discoveryMode = 'none',
    this.distanceKm,
    this.wilayaCode,
    this.searchQuery,
    this.searchContext,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final AnalyticsApiService _analyticsApiService = AnalyticsApiService();
  late final String _analyticsSessionId;
  late final DateTime _enteredAt;
  bool _viewEventSent = false;
  late bool _isFavorited;
  bool _isTogglingFavorite = false;
  bool _isTogglingFollow = false;

  bool _isFollowingStore = false;
  bool _isLoadingFollowState = false;

  String? _storeImageUrl;
  String? _storePhone;
  String? _storeWhatsapp;
  bool _storeShowPhone = true;
  bool _storeShowSocial = true;

  List<String> get _galleryImages {
    final urls = widget.product.images
        .map((e) => e.url.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return urls.isEmpty ? const [''] : urls;
  }

  bool get _hasDiscount {
    return widget.product.oldPrice != null &&
        widget.product.oldPrice! > widget.product.price;
  }

  double get _regularPrice =>
      _hasDiscount ? widget.product.oldPrice! : widget.product.price;
  double get _currentPrice => widget.product.price;
  double get _savedAmount =>
      (_regularPrice - _currentPrice).clamp(0, double.infinity);
  int get _savedPercentage => _hasDiscount && _regularPrice > 0
      ? ((_savedAmount / _regularPrice) * 100).round()
      : 0;

  @override
  void initState() {
    super.initState();
    _enteredAt = DateTime.now();
    _analyticsSessionId =
        'pd_${widget.product.id}_${DateTime.now().millisecondsSinceEpoch}';
    if (kDebugMode) {
      debugPrint(
        'ProductDetail init: source=${widget.sourceSurface} mode=${widget.discoveryMode} distance=${widget.distanceKm} wilaya=${widget.wilayaCode} search=${widget.searchQuery}',
      );
    }
    _isFavorited = widget.product.isFavorited;
    _loadFollowState();
    _loadStoreDetails();
  }

  Map<String, dynamic> _analyticsMetadata() {
    final metadata = <String, dynamic>{
      'source_surface': widget.sourceSurface,
      'discovery_mode': widget.discoveryMode,
    };
    if (widget.distanceKm != null) {
      metadata['distance_km'] = widget.distanceKm;
    }
    if (widget.wilayaCode != null && widget.wilayaCode!.trim().isNotEmpty) {
      metadata['wilaya_code'] = widget.wilayaCode!.trim();
    }
    if (widget.sourceSurface == 'search' &&
        widget.searchQuery != null &&
        widget.searchQuery!.trim().isNotEmpty) {
      metadata['search_query'] = widget.searchQuery!.trim().toLowerCase();
    }
    if (widget.sourceSurface == 'search' &&
        widget.searchContext != null &&
        widget.searchContext!.isNotEmpty) {
      metadata['search_context'] = widget.searchContext;
    }
    return metadata;
  }

  Map<String, dynamic> _buildDiscoveryFields({
    bool includeSearchContext = false,
  }) {
    final payload = <String, dynamic>{
      'discovery_mode': widget.discoveryMode,
    };
    if (widget.distanceKm != null) {
      payload['distance_km'] = widget.distanceKm;
    }
    if (widget.wilayaCode != null && widget.wilayaCode!.trim().isNotEmpty) {
      payload['wilaya_code'] = widget.wilayaCode!.trim();
    }
    if (widget.sourceSurface == 'search' &&
        widget.searchQuery != null &&
        widget.searchQuery!.trim().isNotEmpty) {
      payload['search_query'] = widget.searchQuery!.trim().toLowerCase();
    }
    if (includeSearchContext &&
        widget.sourceSurface == 'search' &&
        widget.searchContext != null &&
        widget.searchContext!.isNotEmpty) {
      payload['search_context'] = widget.searchContext;
    }
    return payload;
  }

  Future<void> _flushViewEvent() async {
    if (_viewEventSent) return;
    _viewEventSent = true;
    if (!StorageService.isLoggedIn()) return;
    final durationSec = DateTime.now().difference(_enteredAt).inSeconds;
    final metadata = _analyticsMetadata();
    metadata['view_duration_sec'] = durationSec < 0 ? 0 : durationSec;
    await _analyticsApiService.logInteraction(
      action: 'view',
      productId: widget.product.id,
      storeId: widget.product.storeId > 0 ? widget.product.storeId : null,
      categoryId: widget.product.categoryId,
      metadata: metadata,
      sessionId: _analyticsSessionId,
      flushNow: true,
    );
  }

  @override
  void dispose() {
    _flushViewEvent();
    super.dispose();
  }

  Future<void> _loadStoreDetails() async {
    final storeId = widget.product.storeId;
    if (storeId <= 0) return;

    String? imageUrl;
    String? phone = widget.product.author.phone;
    String? whatsapp = widget.product.author.whatsapp;
    bool showPhone = widget.product.author.showPhonePublic;
    bool showSocial = widget.product.author.showSocialPublic;

    final raw = widget.product.author.profileImage;
    if (raw != null && raw.trim().isNotEmpty) {
      imageUrl = ApiConfig.getImageUrl(raw);
    }

    try {
      final store = await StoreRepository.getStore(storeId);
      if (store != null) {
        final url = store.profileImage ?? '';
        if (url.trim().isNotEmpty) imageUrl = url;
        if (store.phone != null && store.phone!.trim().isNotEmpty) {
          phone = store.phone;
        }
        if (store.whatsapp != null && store.whatsapp!.trim().isNotEmpty) {
          whatsapp = store.whatsapp;
        }
        showPhone = store.showPhonePublic;
        showSocial = store.showSocialPublic;
      }
    } catch (_) {
      // ignore
    }

    if (!mounted) return;
    setState(() {
      _storeImageUrl = imageUrl;
      _storePhone = phone;
      _storeWhatsapp = whatsapp;
      _storeShowPhone = showPhone;
      _storeShowSocial = showSocial;
    });
  }

  Future<void> _loadFollowState() async {
    if (!StorageService.isLoggedIn()) return;
    if (widget.product.storeId <= 0) return;
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
          if (followed is int && followed == widget.product.storeId) {
            isFollowing = true;
            break;
          }
          if (followed is Map && followed['id'] == widget.product.storeId) {
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

  Future<void> _toggleFavorite() async {
    if (!StorageService.isLoggedIn()) {
      Helpers.showSnackBar(context, 'Log in to save favorites', isError: true);
      return;
    }
    if (_isTogglingFavorite) return;

    setState(() => _isTogglingFavorite = true);
    try {
      final payload = <String, dynamic>{
        'product': widget.product.id,
        'session_id': _analyticsSessionId,
      };
      payload.addAll(_buildDiscoveryFields());
      final resp = await ApiService.post(ApiConfig.favoritesToggle, payload);

      final isFavorited = (resp is Map && resp['is_favorited'] == true);
      if (!mounted) return;
      setState(() => _isFavorited = isFavorited);
      FavoritesChangeNotifier.bump();
      Helpers.showSnackBar(
        context,
        isFavorited ? 'Added to favorites' : 'Removed from favorites',
      );
    } catch (e) {
      if (!mounted) return;
      Helpers.showSnackBar(context, 'Failed to update favorite', isError: true);
    } finally {
      if (mounted) setState(() => _isTogglingFavorite = false);
    }
  }

  Future<void> _toggleFollow() async {
    if (!StorageService.isLoggedIn()) {
      Helpers.showSnackBar(context, 'Log in to follow stores', isError: true);
      return;
    }
    if (_isTogglingFollow) return;

    setState(() => _isTogglingFollow = true);
    try {
      final payload = <String, dynamic>{
        'store': widget.product.storeId,
        'category_id': widget.product.categoryId,
        'session_id': _analyticsSessionId,
      };
      payload.addAll(_buildDiscoveryFields());
      final resp = await ApiService.post(ApiConfig.followersToggle, payload);
      final isFollowing = (resp is Map && resp['is_following'] == true);
      if (!mounted) return;
      setState(() => _isFollowingStore = isFollowing);
      FollowChangeNotifier.bump();
      Helpers.showSnackBar(
        context,
        isFollowing ? 'Followed store' : 'Unfollowed store',
      );
    } catch (e) {
      if (!mounted) return;
      Helpers.showSnackBar(context, 'Failed to update follow', isError: true);
    } finally {
      if (mounted) setState(() => _isTogglingFollow = false);
    }
  }

  Future<void> _refreshDetails() async {
    await Future.wait([
      _loadFollowState(),
      _loadStoreDetails(),
    ]);
  }

  Widget _buildContactButtons() {
    final phone = (_storeShowPhone ? _storePhone : null) ?? '';
    final whatsapp = (_storeShowSocial ? _storeWhatsapp : null) ?? '';

    return ContactActionRow(
      phone: phone,
      whatsapp: whatsapp,
      showTitle: true,
      buttonVerticalPadding: 12,
    );
  }

  Future<void> _showReportProductSheet() async {
    if (!StorageService.isLoggedIn()) {
      Helpers.showSnackBar(context, 'Log in first to report products',
          isError: true);
      return;
    }

    const reasons = [
      ReportReason('spam', 'Duplicate / spam listing'),
      ReportReason('fake', 'Fake / counterfeit product'),
      ReportReason('fraud', 'Scam / asked for prepayment'),
      ReportReason('offensive', 'Offensive / prohibited content'),
      ReportReason('other', 'Other (price mismatch, wrong info)'),
    ];

    final result = await ReportBottomSheet.show(
      context: context,
      title: 'Report Product',
      reasons: reasons,
    );

    if (result == null) {
      return;
    }

    try {
      await ApiService.post(ApiConfig.productReports, {
        'product': widget.product.id,
        'reason': result.reason,
        'details': result.details,
      });
      if (!mounted) return;
      Helpers.showSnackBar(context, 'Report submitted. Thank you.');
    } catch (e) {
      if (!mounted) return;
      Helpers.showSnackBar(context, 'Failed to send report: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('Product Details'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'report') _showReportProductSheet();
              },
              itemBuilder: (context) => const [
                PopupMenuItem<String>(
                  value: 'report',
                  child: Text('Report Product'),
                ),
              ],
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refreshDetails,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageSection(),

                  SizedBox(height: 20),

                  // Product name
                  Text(
                    widget.product.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 16),

                  _buildPricingSummary(),

                  SizedBox(height: 24),

                  // Store information with follow and favorite buttons
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            AppColors.primaryColor.withOpacity(0.1),
                        backgroundImage: (_storeImageUrl != null &&
                                _storeImageUrl!.trim().isNotEmpty)
                            ? NetworkImage(_storeImageUrl!)
                            : null,
                        onBackgroundImageError: (_storeImageUrl != null &&
                                _storeImageUrl!.trim().isNotEmpty)
                            ? (_, __) {
                                if (mounted) {
                                  setState(() => _storeImageUrl = null);
                                }
                              }
                            : null,
                        child: (_storeImageUrl == null ||
                                _storeImageUrl!.trim().isEmpty)
                            ? Icon(Icons.store,
                                color: AppColors.primaryColor, size: 16)
                            : null,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              Routes.store,
                              arguments: widget.product.storeId,
                            );
                          },
                          child: Text(
                            widget.product.storeName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryColor,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      // Follow button
                      GestureDetector(
                        onTap: _toggleFollow,
                        child: Container(
                          height: 32,
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _isLoadingFollowState
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(
                                      _isFollowingStore
                                          ? Icons.done
                                          : Icons.add,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                              SizedBox(width: 4),
                              Text(
                                _isTogglingFollow
                                    ? '...'
                                    : (_isFollowingStore
                                        ? 'Following'
                                        : 'Follow'),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24),

                  _buildContactButtons(),

                  SizedBox(height: 24),

                  // Description
                  if (widget.product.description.isNotEmpty) ...[
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      widget.product.description,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                  ReviewsSection.product(
                    productId: widget.product.id,
                    analyticsContext: {
                      'source_surface': widget.sourceSurface,
                      'session_id': _analyticsSessionId,
                      ..._buildDiscoveryFields(
                        includeSearchContext: true,
                      ),
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    final images = _galleryImages;

    return ImageCarousel(
      images: images,
      height: 250,
      borderRadius: 12,
      topRightOverlay: GestureDetector(
        onTap: _toggleFavorite,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _isTogglingFavorite
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  _isFavorited ? Icons.favorite : Icons.favorite_border,
                  color: Colors.red,
                  size: 20,
                ),
        ),
      ),
    );
  }

  Widget _buildPricingSummary() {
    if (widget.product.hidePrice) {
      return const Text(
        'Call for price',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryColor,
        ),
      );
    }

    if (!_hasDiscount) {
      return Text(
        Helpers.formatPrice(_currentPrice),
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryColor,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Regular Price:', style: TextStyle(fontSize: 14)),
              Text(
                Helpers.formatPrice(_regularPrice),
                style: const TextStyle(
                  fontSize: 14,
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'New Price:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                Helpers.formatPrice(_currentPrice),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'You Save:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${Helpers.formatPrice(_savedAmount)} ($_savedPercentage%)',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
