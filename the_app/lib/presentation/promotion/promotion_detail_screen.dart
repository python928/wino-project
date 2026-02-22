import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routing/routes.dart';
import '../../data/models/offer_model.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/config/api_config.dart';
import '../../core/utils/helpers.dart';
import '../../core/services/favorites_change_notifier.dart';
import '../../core/services/follow_change_notifier.dart';
import '../../data/repositories/store_repository.dart';
import '../common/widgets/reviews_section.dart';

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

  @override
  void initState() {
    super.initState();
    _isFavorited = widget.promotion.product.isFavorited;
    _loadFollowState();
    _loadStoreImage();
  }

  Future<void> _loadStoreImage() async {
    final storeId = widget.promotion.product.storeId;
    if (storeId <= 0) return;

    final raw = widget.promotion.product.author.profileImage;
    if (raw != null && raw.trim().isNotEmpty) {
      if (!mounted) return;
      setState(() => _storeImageUrl = ApiConfig.getImageUrl(raw));
      return;
    }

    try {
      final store = await StoreRepository.getStore(storeId);
      final url = store?.profileImage ?? '';
      if (!mounted) return;
      if (url.trim().isNotEmpty) {
        setState(() => _storeImageUrl = url);
      }
    } catch (_) {
      // ignore
    }
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
      final resp = await ApiService.post(ApiConfig.favoritesToggle, {
        'product': widget.promotion.product.id,
      });

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
      final resp = await ApiService.post(ApiConfig.followersToggle, {
        'store': widget.promotion.product.storeId,
      });
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('Promotion Details'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Product image
            SizedBox(
              height: 250,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: widget.promotion.product.images.isNotEmpty
                          ? Image.network(
                              widget.promotion.product.images.first.url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[200],
                                alignment: Alignment.center,
                                child: const Icon(Icons.image),
                              ),
                            )
                          : Container(
                              color: Colors.grey[200],
                              alignment: Alignment.center,
                              child: const Icon(Icons.image),
                            ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
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
                                _isFavorited
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: Colors.red,
                                size: 20,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
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
            
            // Pricing information
            Row(
              children: [
                Text(
                  '\$${widget.promotion.product.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  '\$${widget.promotion.newPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
                SizedBox(width: 12),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${widget.promotion.discountPercentage.toInt()}% OFF',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 24),
            
            // Store information with follow and favorite buttons
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                  backgroundImage: (_storeImageUrl != null && _storeImageUrl!.trim().isNotEmpty)
                      ? NetworkImage(_storeImageUrl!)
                      : null,
                  onBackgroundImageError:
                      (_storeImageUrl != null && _storeImageUrl!.trim().isNotEmpty)
                          ? (_, __) {
                              if (mounted) setState(() => _storeImageUrl = null);
                            }
                          : null,
                  child: (_storeImageUrl == null || _storeImageUrl!.trim().isEmpty)
                      ? Icon(Icons.store, color: AppColors.primaryColor, size: 16)
                      : null,
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
                    child: Text(
                      widget.promotion.product.storeName,
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
                                _isFollowingStore ? Icons.done : Icons.add,
                                color: Colors.white,
                                size: 16,
                              ),
                        SizedBox(width: 4),
                        Text(
                          _isTogglingFollow
                              ? '...'
                              : (_isFollowingStore ? 'Following' : 'Follow'),
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
            ReviewsSection.product(productId: widget.promotion.product.id),
            ],
          ),
        ),
        ),
      ),
    );
  }
}