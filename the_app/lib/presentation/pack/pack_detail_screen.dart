import 'package:flutter/material.dart';
import '../../data/models/pack_model.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/config/api_config.dart';
import '../../core/utils/helpers.dart';
import '../../core/services/favorites_change_notifier.dart';
import '../../core/services/follow_change_notifier.dart';
import '../../data/repositories/store_repository.dart';
import '../common/widgets/reviews_section.dart';

class PackDetailScreen extends StatefulWidget {
  final Pack pack;
  const PackDetailScreen({super.key, required this.pack});

  @override
  State<PackDetailScreen> createState() => _PackDetailScreenState();
}

class _PackDetailScreenState extends State<PackDetailScreen> {
  bool _isAllFavorited = false;
  bool _isLoadingFavoriteState = false;
  bool _isTogglingFavorite = false;
  bool _isTogglingFollow = false;

  bool _isFollowingStore = false;
  bool _isLoadingFollowState = false;

  String? _storeImageUrl;

  @override
  void initState() {
    super.initState();
    _loadFavoriteState();
    _loadFollowState();
    _loadStoreImage();
  }

  Future<void> _loadStoreImage() async {
    final storeId = widget.pack.merchantId;
    if (storeId <= 0) return;

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
    final storeId = widget.pack.merchantId;
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

  Future<void> _loadFavoriteState() async {
    if (!StorageService.isLoggedIn()) return;
    if (widget.pack.products.isEmpty) return;

    setState(() => _isLoadingFavoriteState = true);
    try {
      final checks = await Future.wait(
        widget.pack.products.map((p) => ApiService.get(ApiConfig.favoritesCheck(p.productId))),
      );
      final all = checks.every((resp) => resp is Map && resp['is_favorited'] == true);
      if (!mounted) return;
      setState(() => _isAllFavorited = all);
    } catch (_) {
      // Ignore silently; default false
    } finally {
      if (mounted) setState(() => _isLoadingFavoriteState = false);
    }
  }

  Future<void> _togglePackFavorites() async {
    if (!StorageService.isLoggedIn()) {
      Helpers.showSnackBar(context, 'Log in to save favorites', isError: true);
      return;
    }
    if (widget.pack.products.isEmpty) return;
    if (_isTogglingFavorite) return;

    setState(() => _isTogglingFavorite = true);
    try {
      // Re-check current state so we apply a consistent action (add all / remove all)
      final checks = await Future.wait(
        widget.pack.products.map((p) => ApiService.get(ApiConfig.favoritesCheck(p.productId))),
      );
      final isFavoritedById = <int, bool>{};
      for (int i = 0; i < widget.pack.products.length; i++) {
        final productId = widget.pack.products[i].productId;
        final resp = checks[i];
        isFavoritedById[productId] = (resp is Map && resp['is_favorited'] == true);
      }

      final allFavorited = isFavoritedById.values.every((v) => v == true);

      if (allFavorited) {
        // Remove all (toggle each favorite)
        await Future.wait(
          widget.pack.products.map(
            (p) => ApiService.post(ApiConfig.favoritesToggle, {'product': p.productId}),
          ),
        );
        if (!mounted) return;
        setState(() => _isAllFavorited = false);
        FavoritesChangeNotifier.bump();
        Helpers.showSnackBar(context, 'Removed pack products from favorites');
      } else {
        // Add missing ones only
        final toAdd = widget.pack.products
            .where((p) => (isFavoritedById[p.productId] ?? false) == false)
            .toList();
        await Future.wait(
          toAdd.map(
            (p) => ApiService.post(ApiConfig.favoritesToggle, {'product': p.productId}),
          ),
        );
        if (!mounted) return;
        setState(() => _isAllFavorited = true);
        FavoritesChangeNotifier.bump();
        Helpers.showSnackBar(context, 'Added pack products to favorites');
      }
    } catch (e) {
      if (!mounted) return;
      Helpers.showSnackBar(context, 'Failed to update favorites', isError: true);
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
        'store': widget.pack.merchantId,
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
          title: Text('Pack Details'),
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
            // Pack image from first product
            SizedBox(
              height: 200,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: (widget.pack.products.isNotEmpty &&
                              widget.pack.products.first.productImage.isNotEmpty)
                          ? Image.network(
                              widget.pack.products.first.productImage,
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
                      onTap: _togglePackFavorites,
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
                        child: (_isLoadingFavoriteState || _isTogglingFavorite)
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                _isAllFavorited
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
            
            // Pack name
            Text(
              widget.pack.name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            SizedBox(height: 20),
            
            // Products table
            Text(
              'Pack Contents',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            
            // Table header
            Container(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Product',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Qty',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Price',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 8),
            
            // Products list
            Column(
              children: widget.pack.products.map((product) {
                return Container(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  margin: EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            // Product image
                            if (product.productImage.isNotEmpty)
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  image: DecorationImage(
                                    image: NetworkImage(product.productImage),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                product.productName,
                                style: TextStyle(fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          '${product.quantity}',
                          style: TextStyle(fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '\$${product.productPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            
            SizedBox(height: 20),
            
            // Pricing summary
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Regular Total:', style: TextStyle(fontSize: 14)),
                      Text(
                        '\$${widget.pack.totalPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pack Price:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${widget.pack.discountPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
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
                        '\$${(widget.pack.totalPrice - widget.pack.discountPrice).toStringAsFixed(2)} (${(((widget.pack.totalPrice - widget.pack.discountPrice) / widget.pack.totalPrice) * 100).round()}%)',
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
                        arguments: widget.pack.merchantId,
                      );
                    },
                    child: Text(
                      widget.pack.merchantName,
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
            if (widget.pack.description.isNotEmpty) ...[
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                widget.pack.description,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
            ReviewsSection.store(storeId: widget.pack.merchantId),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
