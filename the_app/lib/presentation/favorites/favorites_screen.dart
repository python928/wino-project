import 'package:flutter/material.dart';
import 'package:dzlocal_shop/core/extensions/l10n_extension.dart';

import '../../core/theme/app_colors.dart';
import '../../core/routing/routes.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/config/api_config.dart';
import '../../core/utils/helpers.dart';
import '../../core/services/favorites_change_notifier.dart';
import '../../data/models/post_model.dart';
import '../shared_widgets/cards/product_card.dart';
import '../shared_widgets/empty_state_widget.dart';
import '../shared_widgets/error_state_widget.dart';
import '../shared_widgets/shimmer_loading.dart';
import '../shared_widgets/unified_app_bar.dart';
import '../common/constants/card_constants.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Post> _favorites = [];
  bool _isLoading = true;
  String? _error;
  double? _userLat;
  double? _userLng;

  late final VoidCallback _favoritesListener;

  @override
  void initState() {
    super.initState();
    // Load user coordinates for distance display
    final userData = StorageService.getUserData();
    if (userData != null) {
      _userLat = userData['latitude'] != null
          ? double.tryParse(userData['latitude'].toString())
          : null;
      _userLng = userData['longitude'] != null
          ? double.tryParse(userData['longitude'].toString())
          : null;
    }
    _favoritesListener = () {
      if (!mounted) return;
      _loadFavorites();
    };
    FavoritesChangeNotifier.version.addListener(_favoritesListener);
    _loadFavorites();
  }

  @override
  void dispose() {
    FavoritesChangeNotifier.version.removeListener(_favoritesListener);
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    if (!StorageService.isLoggedIn()) {
      setState(() {
        _isLoading = false;
        _error = 'login_required';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.get(ApiConfig.favorites);
      final list = response is Map && response.containsKey('results')
          ? response['results'] as List
          : (response is List ? response : []);

      final favorites = <Post>[];
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          final productData = item['product_detail'] ?? item['product'];
          if (productData is Map<String, dynamic>) {
            favorites.add(Post.fromJson(productData));
          }
        }
      }

      setState(() {
        _favorites = favorites;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading favorites: $e');
      setState(() {
        _isLoading = false;
        _error = context.tr('An error occurred while loading favorites');
      });
    }
  }

  Future<void> _removeFromFavorites(Post product) async {
    try {
      await ApiService.post(ApiConfig.favoritesToggle, {
        'product': product.id,
      });

      setState(() {
        _favorites.removeWhere((p) => p.id == product.id);
      });

      Helpers.showSnackBar(context, context.tr('Removed from favorites'));
    } catch (e) {
      Helpers.showSnackBar(context, context.tr('An error occurred'),
          isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: UnifiedAppBar(
        showLocation: false,
        showNotificationIcon: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const ProductGridSkeleton(itemCount: 6);
    }

    if (_error == 'login_required') {
      return _buildLoginRequired();
    }

    if (_error != null) {
      return ErrorStateWidget(
        message: context.tr('Failed to load favorites'),
        details: _error,
        onRetry: _loadFavorites,
      );
    }

    if (_favorites.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: CardConstants.gridHorizontalPadding,
          vertical: CardConstants.gridVerticalPadding,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: CardConstants.gridCrossAxisCount,
          childAspectRatio: CardConstants.gridChildAspectRatio,
          mainAxisSpacing: CardConstants.gridMainAxisSpacing,
          crossAxisSpacing: CardConstants.gridCrossAxisSpacing,
        ),
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final product = _favorites[index];
          return Align(
            alignment: Alignment.topCenter,
            child: Stack(
              children: [
                ProductCard(
                  product: product,
                  userLat: _userLat,
                  userLng: _userLng,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      Routes.productDetails,
                      arguments: product,
                    );
                  },
                ),

                // Remove from favorites button (pinned to the card)
                Positioned(
                  top: CardConstants.badgePosition.dy,
                  right: CardConstants.badgePosition.dx,
                  child: GestureDetector(
                    onTap: () => _removeFromFavorites(product),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite,
                        size: 16,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoginRequired() {
    return EmptyStateWidget(
      icon: Icons.login,
      title: context.tr('Log in to view your favorites'),
      message: context.tr('Log in to save your favorite products'),
      actionText: context.tr('Log In'),
      onActionPressed: () => Navigator.pushNamed(context, Routes.login),
    );
  }

  Widget _buildEmptyState() {
    return EmptyStateWidget(
      icon: Icons.favorite_border,
      title: context.tr('No favorite products'),
      message: context.tr('Add products to your favorites to find them here easily'),
      actionText: context.tr('Explore Products'),
      onActionPressed: () => Navigator.pushNamed(context, Routes.searchTab),
    );
  }
}
