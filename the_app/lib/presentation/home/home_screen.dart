import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routing/routes.dart';
import '../../core/utils/helpers.dart';
import '../../core/providers/home_provider.dart';
import '../../core/providers/post_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../data/models/post_model.dart';
import '../../data/models/pack_model.dart';
import '../profile/edit_product_screen.dart';
import '../shared_widgets/shimmer_loading.dart';
import '../shared_widgets/error_state_widget.dart';
import 'widgets/header_location_widget.dart';
import 'widgets/search_bar_widget.dart';
import 'widgets/category_item.dart';
import 'widgets/promo_banner.dart';
import 'widgets/hot_deal_card.dart';
import 'widgets/product_card.dart';
import 'widgets/featured_store_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    final homeProvider = context.read<HomeProvider>();
    final postProvider = context.read<PostProvider>();

    homeProvider.loadHomeData();
    postProvider.loadPosts();
    postProvider.loadOffers();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              _loadData();
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  // Header
                  HeaderLocationWidget(
                    currentLocation: 'الجزائر العاصمة',
                    notificationCount: 3,
                    onLocationTap: () => _showLocationPicker(),
                    onNotificationTap: () => _showNotifications(),
                  ),

                  const SizedBox(height: AppTheme.spacing20),

                  // Search Bar
                  SearchBarWidget(
                    isActive: true,
                    controller: _searchController,
                    onSearchChanged: (query) {
                      if (query.isNotEmpty) {
                        context.read<PostProvider>().onSearchQueryChanged(query);
                      }
                    },
                    onSearchSubmitted: () {
                      if (_searchController.text.isNotEmpty) {
                        Navigator.pushNamed(
                          context,
                          Routes.searchResults,
                          arguments: {'query': _searchController.text},
                        );
                      }
                    },
                    onFilterTap: () => _showFilters(),
                  ),

                  const SizedBox(height: AppTheme.spacing24),

                  // Categories Section
                  _buildSectionHeader('الفئات', 'عرض الكل', () {}),
                  const SizedBox(height: AppTheme.spacing16),
                  _buildCategoriesSection(),

                  const SizedBox(height: AppTheme.spacing24),

                  // Promo Banner
                  PromoBanner(
                    title: 'عرض المستخدم\nالجديد!',
                    subtitle: 'احصل على خصم 15% على\nطلبك الأول',
                    icon: Icons.percent,
                    onTap: () => _showPromoDetails(),
                  ),

                  const SizedBox(height: AppTheme.spacing24),

                  // Featured Stores Section
                  _buildSectionHeader('المتاجر المميزة', 'عرض الكل', () {
                    Navigator.pushNamed(context, Routes.discovery);
                  }),
                  const SizedBox(height: AppTheme.spacing16),
                  _buildFeaturedStoresSection(),

                  const SizedBox(height: AppTheme.spacing24),

                  // Hot Deals Section
                  _buildHotDealsHeader(),
                  const SizedBox(height: AppTheme.spacing16),
                  _buildHotDealsSection(),

                  const SizedBox(height: AppTheme.spacing24),

                  // Offers/Discounts Section
                  _buildSectionHeader('التخفيضات', 'عرض الكل', () {
                    Navigator.pushNamed(context, Routes.offers);
                  }),
                  const SizedBox(height: AppTheme.spacing16),
                  _buildOffersSection(),

                  const SizedBox(height: AppTheme.spacing24),

                  // Recent Products Section
                  _buildSectionHeader('أحدث المنتجات', 'عرض الكل', () {
                    Navigator.pushNamed(context, Routes.discovery);
                  }),
                  const SizedBox(height: AppTheme.spacing16),
                  _buildRecentProductsSection(),

                  const SizedBox(height: AppTheme.spacing24),

                  // Packages Section
                  _buildSectionHeader('الحزم المميزة', 'عرض الكل', () {
                    Navigator.pushNamed(context, Routes.discovery, arguments: {'tab': 'packs'});
                  }),
                  const SizedBox(height: AppTheme.spacing16),
                  _buildPacksSection(),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== Section Headers ====================

  Widget _buildSectionHeader(String title, String action, VoidCallback onActionTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.h2),
          GestureDetector(
            onTap: onActionTap,
            child: Row(
              children: [
                Text(
                  action,
                  style: AppTextStyles.linkText,
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: AppColors.primaryPurple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Categories Section ====================

  Widget _buildCategoriesSection() {
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, child) {
        if (homeProvider.isLoadingCategories && homeProvider.categories.isEmpty) {
          return _buildCategoriesShimmer();
        }

        final categories = homeProvider.categories;
        if (categories.isEmpty) {
          return _buildCategoriesShimmer();
        }

        return SizedBox(
          height: 110,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing20),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppTheme.spacing12),
            itemBuilder: (context, index) {
              final category = categories[index];
              return CategoryItem(
                icon: category.iconData,
                label: category.name,
                color: _getCategoryColor(index),
                onTap: () => _navigateToCategory(category.id, category.name),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoriesShimmer() {
    return ShimmerLoading(
      child: SizedBox(
        height: 110,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing20),
          scrollDirection: Axis.horizontal,
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(width: AppTheme.spacing12),
          itemBuilder: (context, index) {
            return Column(
              children: [
                const ShimmerBox(width: 70, height: 70, borderRadius: 16),
                const SizedBox(height: 8),
                const ShimmerBox(width: 50, height: 14),
              ],
            );
          },
        ),
      ),
    );
  }

  Color _getCategoryColor(int index) {
    final colors = [
      AppColors.categoryElectronics,
      AppColors.categoryFashion,
      AppColors.categoryHome,
      AppColors.categorySports,
      const Color(0xFFE91E63),
      const Color(0xFFFF9800),
    ];
    return colors[index % colors.length];
  }

  // ==================== Featured Stores Section ====================

  Widget _buildFeaturedStoresSection() {
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, child) {
        if (homeProvider.isLoadingStores && homeProvider.featuredStores.isEmpty) {
          return const StoreListSkeleton(itemCount: 3);
        }

        if (homeProvider.storesError != null && homeProvider.featuredStores.isEmpty) {
          return SizedBox(
            height: 160,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.store_outlined, size: 40, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'تعذر تحميل المتاجر',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  TextButton(
                    onPressed: () => homeProvider.loadFeaturedStores(),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          );
        }

        final stores = homeProvider.featuredStores;
        if (stores.isEmpty) {
          return SizedBox(
            height: 160,
            child: Center(
              child: Text(
                'لا توجد متاجر مميزة حالياً',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          );
        }

        return SizedBox(
          height: 170,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing20),
            scrollDirection: Axis.horizontal,
            itemCount: stores.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppTheme.spacing12),
            itemBuilder: (context, index) {
              return FeaturedStoreCard(
                store: stores[index],
                onTap: () => Navigator.pushNamed(
                  context,
                  Routes.store,
                  arguments: stores[index].id,
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ==================== Hot Deals Section ====================

  Widget _buildHotDealsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing20),
      child: Row(
        children: [
          // Fire Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.hotDealRed,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: Colors.white,
              size: 20,
            ),
          ),

          const SizedBox(width: AppTheme.spacing8),

          // Title
          const Text(
            'عروض\nساخنة',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              height: 1.1,
              fontSize: 14,
            ),
          ),

          const Spacer(),

          // Timer
          _buildTimerBox('02'),
          _buildTimerSeparator(),
          _buildTimerBox('45'),
          _buildTimerSeparator(),
          _buildTimerBox('30'),
        ],
      ),
    );
  }

  Widget _buildTimerBox(String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        time,
        style: AppTextStyles.timerText,
      ),
    );
  }

  Widget _buildTimerSeparator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        ':',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildHotDealsSection() {
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, child) {
        if (homeProvider.isLoadingHotDeals && homeProvider.hotDeals.isEmpty) {
          return _buildProductsShimmer();
        }

        final hotDeals = homeProvider.hotDeals;
        if (hotDeals.isEmpty) {
          return SizedBox(
            height: 220,
            child: Center(
              child: Text(
                'لا توجد عروض ساخنة حالياً',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          );
        }

        return SizedBox(
          height: 280,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing20),
            scrollDirection: Axis.horizontal,
            itemCount: hotDeals.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppTheme.spacing12),
            itemBuilder: (context, index) {
              return SizedBox(
                width: 180,
                child: ProductCard(
                  product: hotDeals[index],
                  onTap: () => _navigateToProductDetails(hotDeals[index]),
                  onFavoriteTap: () => _toggleFavorite(hotDeals[index]),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ==================== Packs Section ====================

  Widget _buildPacksSection() {
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, child) {
        if (homeProvider.isLoadingPacks && homeProvider.packs.isEmpty) {
          return _buildProductsShimmer();
        }

        if (homeProvider.packsError != null && homeProvider.packs.isEmpty) {
          return SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 40, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'تعذر تحميل الحزم',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  TextButton(
                    onPressed: () => homeProvider.loadFeaturedPacks(),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          );
        }

        final packs = homeProvider.packs;
        if (packs.isEmpty) {
          return SizedBox(
            height: 200,
            child: Center(
              child: Text(
                'لا توجد حزم متوفرة حالياً',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          );
        }

        return SizedBox(
          height: 220,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing20),
            scrollDirection: Axis.horizontal,
            itemCount: packs.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppTheme.spacing12),
            itemBuilder: (context, index) {
              final pack = packs[index];
              return _buildPackCard(pack);
            },
          ),
        );
      },
    );
  }

  Widget _buildPackCard(Pack pack) {
    final discountPercent = pack.totalPrice > 0
        ? ((pack.totalPrice - pack.discountPrice) / pack.totalPrice * 100).round()
        : 0;

    return GestureDetector(
      onTap: () {
        // Navigate to pack details
        Helpers.showSnackBar(context, 'عرض تفاصيل الحزمة قريباً');
      },
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pack Header with gradient
            Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryPurple, AppColors.primaryPurple.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Stack(
                children: [
                  // Pack Images/Icon
                  Center(
                    child: _buildStackedProductImages(pack.products),
                  ),
                  // Discount badge
                  if (discountPercent > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'وفر $discountPercent%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  // Product count badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${pack.products.length} منتجات',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Pack Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pack.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _buildProductSummary(pack.products),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.2,
                      ),
                    ),
                    const Spacer(),
                    // Price Row
                    Row(
                      children: [
                        Text(
                          Helpers.formatPrice(pack.discountPrice),
                          style: TextStyle(
                            color: AppColors.primaryPurple,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (pack.totalPrice > pack.discountPrice)
                          Text(
                            Helpers.formatPrice(pack.totalPrice),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                            ),
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
  }

  // ==================== Recent Products Section ====================

  Widget _buildRecentProductsSection() {
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, child) {
        if (homeProvider.isLoadingProducts && homeProvider.recentProducts.isEmpty) {
          return _buildProductsShimmer();
        }

        if (homeProvider.productsError != null && homeProvider.recentProducts.isEmpty) {
          return SizedBox(
            height: 280,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 40, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'تعذر تحميل المنتجات',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  TextButton(
                    onPressed: () => homeProvider.loadRecentProducts(),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          );
        }

        final products = homeProvider.recentProducts;
        if (products.isEmpty) {
          return SizedBox(
            height: 220,
            child: Center(
              child: Text(
                'لا توجد منتجات حالياً',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          );
        }

        return SizedBox(
          height: 280,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing20),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppTheme.spacing12),
            itemBuilder: (context, index) {
              return SizedBox(
                width: 180,
                child: ProductCard(
                  product: products[index],
                  onTap: () => _navigateToProductDetails(products[index]),
                  onFavoriteTap: () => _toggleFavorite(products[index]),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProductsShimmer() {
    return ShimmerLoading(
      child: SizedBox(
        height: 280,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing20),
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(width: AppTheme.spacing12),
          itemBuilder: (context, index) {
            return const SizedBox(
              width: 180,
              child: ProductCardSkeleton(),
            );
          },
        ),
      ),
    );
  }

  // ==================== Offers Section ====================

  Widget _buildOffersSection() {
    return Consumer<PostProvider>(
      builder: (context, postProvider, child) {
        final offers = postProvider.offers;

        if (postProvider.isLoadingOffers && offers.isEmpty) {
          return _buildProductsShimmer();
        }

        if (postProvider.offersError != null && offers.isEmpty) {
          return SizedBox(
            height: 280,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_offer_outlined, size: 40, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'تعذر تحميل التخفيضات',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  TextButton(
                    onPressed: () => postProvider.loadOffers(),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          );
        }

        if (offers.isEmpty) {
          return SizedBox(
            height: 220,
            child: Center(
              child: Text(
                'لا توجد تخفيضات حالياً',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          );
        }

        return SizedBox(
          height: 280,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing20),
            scrollDirection: Axis.horizontal,
            itemCount: offers.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppTheme.spacing12),
            itemBuilder: (context, index) {
              final offer = offers[index];
              final product = offer.product;
              return SizedBox(
                width: 180,
                child: GestureDetector(
                  onTap: () => _navigateToProductDetails(product),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image + badge
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              child: SizedBox(
                                height: 130,
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
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '-${offer.discountPercentage}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    Text(
                                      Helpers.formatPrice(offer.newPrice),
                                      style: TextStyle(
                                        color: AppColors.primaryPurple,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      Helpers.formatPrice(product.price),
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 11,
                                        decoration: TextDecoration.lineThrough,
                                      ),
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
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ==================== Navigation Methods ====================

  void _showLocationPicker() {
    Helpers.showSnackBar(context, 'اختيار الموقع قريباً');
  }

  void _showNotifications() {
    Navigator.pushNamed(context, Routes.notifications);
  }

  void _navigateToSearch() {
    Navigator.pushNamed(context, Routes.discovery);
  }

  void _showFilters() {
    Helpers.showSnackBar(context, 'الفلاتر قريباً');
  }

  void _navigateToCategory(int categoryId, String categoryName) {
    Navigator.pushNamed(
      context,
      Routes.discovery,
      arguments: {'categoryId': categoryId, 'categoryName': categoryName},
    );
  }

  void _showPromoDetails() {
    Helpers.showSnackBar(context, 'عرض المستخدم الجديد');
  }

  void _navigateToProductDetails(Post product) {
    Navigator.pushNamed(
      context,
      Routes.productDetails,
      arguments: product,
    );
  }

  void _toggleFavorite(Post product) {
    Helpers.showSnackBar(context, 'تمت الإضافة إلى المفضلة');
  }

  Widget _buildStackedProductImages(List<dynamic> products) {
    if (products.isEmpty) {
      return Icon(
        Icons.inventory_2_rounded,
        size: 50,
        color: Colors.white.withValues(alpha: 0.9),
      );
    }

    // Show up to 3 product images stacked
    final imagesToShow = products.take(3).toList();
    final imageCount = imagesToShow.length;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;
        
        // Image size adapts to container
        final imageSize = (availableHeight * 0.65).clamp(45.0, 70.0);
        final overlap = imageSize * 0.4;
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
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
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
