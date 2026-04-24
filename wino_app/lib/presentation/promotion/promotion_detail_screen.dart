import 'package:wino/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';

import '../../core/config/api_config.dart';
import '../../core/routing/routes.dart';
import '../../core/services/api_service.dart';
import '../../core/services/favorites_change_notifier.dart';
import '../../core/services/follow_change_notifier.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/offer_model.dart';
import '../../data/repositories/store_repository.dart';
import '../common/widgets/reviews_section.dart';
import '../shared_widgets/app_dropdown_menu.dart';
import '../shared_widgets/contact_action_row.dart';
import '../shared_widgets/directions_button.dart';
import '../shared_widgets/image_carousel.dart';
import '../shared_widgets/report_bottom_sheet.dart';

class PromotionDetailScreen extends StatefulWidget {
  final Offer promotion;

  const PromotionDetailScreen({super.key, required this.promotion});

  @override
  State<PromotionDetailScreen> createState() => _PromotionDetailScreenState();
}

class _PromotionDetailScreenState extends State<PromotionDetailScreen> {
  late bool _isFavorited;
  bool _isTogglingFavorite = false;
  bool _isTogglingFollow = false;

  bool _isFollowingStore = false;
  bool _isLoadingFollowState = false;

  String? _storeImageUrl;
  String? _storePhone;
  String? _storeWhatsapp;
  double? _storeLatitude;
  double? _storeLongitude;
  bool _storeShowPhone = true;
  bool _storeShowSocial = true;

  List<String> get _galleryImages {
    final urls = widget.promotion.product.images
        .map((e) => e.url.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return urls.isEmpty ? const [''] : urls;
  }

  double get _regularPrice => widget.promotion.product.price;
  double get _newPrice => widget.promotion.newPrice;
  double get _savedAmount =>
      (_regularPrice - _newPrice).clamp(0, double.infinity);
  int get _savedPercentage =>
      _regularPrice > 0 ? ((_savedAmount / _regularPrice) * 100).round() : 0;

  @override
  void initState() {
    super.initState();
    _isFavorited = widget.promotion.product.isFavorited;
    final cachedFollow =
        FollowChangeNotifier.getFollowState(widget.promotion.product.storeId);
    if (cachedFollow != null) {
      _isFollowingStore = cachedFollow;
    }
    _loadFollowState();
    _loadStoreDetails();
  }

  Future<void> _loadStoreDetails() async {
    final storeId = widget.promotion.product.storeId;
    if (storeId <= 0) return;

    String? imageUrl;
    String? phone = widget.promotion.product.author.phone;
    String? whatsapp = widget.promotion.product.author.whatsapp;
    bool showPhone = widget.promotion.product.author.showPhonePublic;
    bool showSocial = widget.promotion.product.author.showSocialPublic;

    final raw = widget.promotion.product.author.profileImage;
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
        _storeLatitude = store.latitude;
        _storeLongitude = store.longitude;
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
    final storeId = widget.promotion.product.storeId;
    if (storeId <= 0) return;
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
          if (followed is int && followed == storeId) {
            isFollowing = true;
            break;
          }
          if (followed is Map && followed['id'] == storeId) {
            isFollowing = true;
            break;
          }
        }
      }

      if (!mounted) return;
      setState(() => _isFollowingStore = isFollowing);
      FollowChangeNotifier.setFollowState(storeId, isFollowing);
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _isLoadingFollowState = false);
    }
  }

  Future<void> _toggleFavorite() async {
    if (!StorageService.isLoggedIn()) {
      Helpers.showSnackBar(context, context.tr('Log in to save favorites'),
          isError: true);
      return;
    }
    if (_isTogglingFavorite) return;

    setState(() => _isTogglingFavorite = true);
    try {
      final resp = await ApiService.post(ApiConfig.favoritesToggle, {
        'product': widget.promotion.product.id,
      });

      final isFavorited = (resp is Map && resp['is_favorited'] == true);
      if (!mounted) return;
      setState(() => _isFavorited = isFavorited);
      FavoritesChangeNotifier.bump();
      Helpers.showSnackBar(
        context,
        isFavorited
            ? context.tr('Added to favorites')
            : context.tr('Removed from favorites'),
      );
    } catch (e) {
      if (!mounted) return;
      Helpers.showSnackBar(context, context.tr('Failed to update favorite'),
          isError: true);
    } finally {
      if (mounted) setState(() => _isTogglingFavorite = false);
    }
  }

  Future<void> _toggleFollow() async {
    if (!StorageService.isLoggedIn()) {
      Helpers.showSnackBar(context, context.tr('Log in to follow stores'),
          isError: true);
      return;
    }
    if (_isTogglingFollow) return;

    setState(() => _isTogglingFollow = true);
    try {
      final resp = await ApiService.post(ApiConfig.followersToggle, {
        'store': widget.promotion.product.storeId,
      });
      final isFollowing = (resp is Map && resp['is_following'] == true);
      if (!mounted) return;
      setState(() => _isFollowingStore = isFollowing);
      FollowChangeNotifier.setFollowState(
          widget.promotion.product.storeId, isFollowing);
      FollowChangeNotifier.bump();
      Helpers.showSnackBar(
        context,
        isFollowing
            ? context.tr('Followed store')
            : context.tr('Unfollowed store'),
      );
    } catch (e) {
      if (!mounted) return;
      Helpers.showSnackBar(context, context.tr('Failed to update follow'),
          isError: true);
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
      trailingAction: _buildDirectionsButton(),
      showTitle: true,
      buttonVerticalPadding: 12,
    );
  }

  double? get _destinationLatitude =>
      _storeLatitude ??
      widget.promotion.product.storeLatitude ??
      widget.promotion.product.author.latitude;

  double? get _destinationLongitude =>
      _storeLongitude ??
      widget.promotion.product.storeLongitude ??
      widget.promotion.product.author.longitude;

  Widget _buildDirectionsButton() {
    return DirectionsButton(
      destinationLat: _destinationLatitude,
      destinationLng: _destinationLongitude,
      label: context.l10n.mapLabel,
    );
  }

  Future<void> _showReportPromotionSheet() async {
    if (!StorageService.isLoggedIn()) {
      Helpers.showSnackBar(context, context.tr('Log in first to report offers'),
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
      title: context.tr('Report Offer'),
      reasons: reasons,
    );

    if (result == null) {
      return;
    }

    try {
      await ApiService.post(ApiConfig.productReports, {
        'product': widget.promotion.product.id,
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(context.tr('Promotion Details')),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          actions: [
            AppDropdownMenuButton<String>(
              onSelected: (value) {
                if (value == 'report') _showReportPromotionSheet();
              },
              actions: [
                AppDropdownAction(
                  value: 'report',
                  icon: Icons.flag_outlined,
                  label: context.tr('Report Offer'),
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
                    widget.promotion.product.title,
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
                      Stack(
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
                          if (widget.promotion.product.storeIsVerified)
                            const Positioned(
                              top: -2,
                              left: -2,
                              child: Icon(
                                Icons.verified,
                                color: Colors.green,
                                size: 14,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              Routes.store,
                              arguments: widget.promotion.product.storeId,
                            );
                          },
                          child: Row(
                            children: [
                              if (widget.promotion.product.storeIsVerified) ...[
                                const Icon(
                                  Icons.verified,
                                  color: Colors.green,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                              ],
                              Expanded(
                                child: Text(
                                  widget.promotion.product.storeName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primaryColor,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
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
                                        ? context.tr('Following')
                                        : context.tr('Follow')),
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

                  SizedBox(height: 16),

                  _buildContactButtons(),

                  SizedBox(height: 24),

                  // Description
                  if (widget.promotion.product.description.isNotEmpty) ...[
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      widget.promotion.product.description,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                  ReviewsSection.product(
                      productId: widget.promotion.product.id),
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
    final imageHeight = (MediaQuery.of(context).size.height * 0.50)
        .clamp(390.0, 540.0)
        .toDouble();

    return ImageCarousel(
      images: images,
      height: imageHeight,
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
              Text(context.tr('Regular Price:'),
                  style: const TextStyle(fontSize: 14)),
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
              Text(
                context.tr('New Price:'),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                Helpers.formatPrice(_newPrice),
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
