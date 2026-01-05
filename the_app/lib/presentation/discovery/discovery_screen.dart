import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/post_provider.dart';
import '../../core/providers/home_provider.dart';
import '../../core/routing/routes.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/pack_model.dart';
import '../home/widgets/product_card.dart';
import '../shared_widgets/empty_state_widget.dart';
import '../shared_widgets/shimmer_loading.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'الكل';
  int? _selectedCategoryId;

  // Filters
  String _selectedSort = 'الأحدث';
  RangeValues _priceRange = const RangeValues(0, 100000);
  double _minRating = 0;

  final List<String> _sortOptions = [
    'الأحدث',
    'الأقدم',
    'الأعلى تقييماً',
    'الأقل سعراً',
    'الأعلى سعراً',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        if (args['categoryId'] != null) {
          _selectedCategoryId = args['categoryId'];
          _selectedCategory = args['categoryName'] ?? 'الكل';
          _loadProducts();
        }
        if (args['tab'] == 'packs') {
          _tabController.animateTo(2);
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadProducts() {
    final postProvider = context.read<PostProvider>();
    postProvider.loadPosts(
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
      categoryId: _selectedCategoryId,
    );
  }

  void _onSearch(String query) {
    context.read<PostProvider>().onSearchQueryChanged(query);
  }

  void _showCategoryDialog() {
    final homeProvider = context.read<HomeProvider>();
    final categories = homeProvider.categories;

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.category_outlined, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              const Text('اختر الفئة', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search in categories
                TextField(
                  decoration: InputDecoration(
                    hintText: 'ابحث في الفئات...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                // Categories list
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      // "All" option
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _selectedCategory == 'الكل'
                                ? AppColors.primaryBlue.withOpacity(0.1)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.apps,
                            color: _selectedCategory == 'الكل' ? AppColors.primaryBlue : Colors.grey,
                            size: 20,
                          ),
                        ),
                        title: const Text('الكل'),
                        trailing: _selectedCategory == 'الكل'
                            ? const Icon(Icons.check_circle, color: AppColors.primaryBlue)
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedCategory = 'الكل';
                            _selectedCategoryId = null;
                          });
                          Navigator.pop(context);
                          _loadProducts();
                        },
                      ),
                      ...categories.map((category) => ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _selectedCategory == category.name
                                ? AppColors.primaryBlue.withOpacity(0.1)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.category,
                            color: _selectedCategory == category.name ? AppColors.primaryBlue : Colors.grey,
                            size: 20,
                          ),
                        ),
                        title: Text(category.name),
                        trailing: _selectedCategory == category.name
                            ? const Icon(Icons.check_circle, color: AppColors.primaryBlue)
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedCategory = category.name;
                            _selectedCategoryId = category.id;
                          });
                          Navigator.pop(context);
                          _loadProducts();
                        },
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFiltersSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'الفلاتر',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            _selectedSort = 'الأحدث';
                            _priceRange = const RangeValues(0, 100000);
                            _minRating = 0;
                          });
                        },
                        child: const Text('إعادة تعيين'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Sort by
                  const Text('الترتيب حسب', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _sortOptions.map((option) {
                      final isSelected = _selectedSort == option;
                      return ChoiceChip(
                        label: Text(option),
                        selected: isSelected,
                        onSelected: (selected) {
                          setSheetState(() => _selectedSort = option);
                        },
                        selectedColor: AppColors.primaryBlue.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.primaryBlue : Colors.grey[700],
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Price Range
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('نطاق السعر', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        '${_priceRange.start.toInt()} - ${_priceRange.end.toInt()} د.ج',
                        style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: 100000,
                    divisions: 100,
                    activeColor: AppColors.primaryBlue,
                    labels: RangeLabels(
                      '${_priceRange.start.toInt()}',
                      '${_priceRange.end.toInt()}',
                    ),
                    onChanged: (values) {
                      setSheetState(() => _priceRange = values);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('الحد الأدنى للتقييم', style: TextStyle(fontWeight: FontWeight.w600)),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            _minRating.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Slider(
                    value: _minRating,
                    min: 0,
                    max: 5,
                    divisions: 10,
                    activeColor: Colors.amber,
                    label: _minRating.toStringAsFixed(1),
                    onChanged: (value) {
                      setSheetState(() => _minRating = value);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {});
                        // TODO: Apply filters to products
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'تطبيق الفلاتر',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: AppBar(
          title: const Text('استكشاف', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            // Filter button
            IconButton(
              onPressed: _showFiltersSheet,
              icon: const Icon(Icons.tune, color: AppColors.textPrimary),
              tooltip: 'الفلاتر',
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primaryBlue,
                unselectedLabelColor: AppColors.textHint,
                indicatorColor: AppColors.primaryBlue,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontSize: 13),
                tabs: const [
                  Tab(text: 'المنتجات'),
                  Tab(text: 'التخفيضات'),
                  Tab(text: 'الحزم'),
                  Tab(text: 'المتاجر'),
                ],
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            // Search Bar + Category Dropdown
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  // Search field
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearch,
                      decoration: InputDecoration(
                        hintText: 'ابحث...',
                        prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: AppColors.textHint),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearch('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.scaffoldBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Category dropdown button
                  GestureDetector(
                    onTap: _showCategoryDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.scaffoldBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.category_outlined, size: 20, color: AppColors.primaryBlue),
                          const SizedBox(width: 6),
                          Text(
                            _selectedCategory.length > 8
                                ? '${_selectedCategory.substring(0, 8)}...'
                                : _selectedCategory,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Active filters indicator
            if (_selectedCategory != 'الكل' || _minRating > 0 || _priceRange.start > 0 || _priceRange.end < 100000)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppColors.primaryBlue.withOpacity(0.05),
                child: Row(
                  children: [
                    const Icon(Icons.filter_list, size: 16, color: AppColors.primaryBlue),
                    const SizedBox(width: 8),
                    const Text(
                      'فلاتر نشطة',
                      style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w500, fontSize: 12),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = 'الكل';
                          _selectedCategoryId = null;
                          _selectedSort = 'الأحدث';
                          _priceRange = const RangeValues(0, 100000);
                          _minRating = 0;
                        });
                        _loadProducts();
                      },
                      child: const Text(
                        'مسح الكل',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildProductsTab(),
                  _buildDiscountsTab(),
                  _buildPacksTab(),
                  _buildStoresTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsTab() {
    return Consumer<PostProvider>(
      builder: (context, postProvider, child) {
        final products = postProvider.posts;

        if (postProvider.isLoadingPosts) {
          return _buildGridShimmer();
        }

        if (products.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.search_off,
            title: 'لا توجد منتجات',
            message: 'لم نجد أي منتجات تطابق بحثك',
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.65,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return ProductCard(
              product: products[index],
              onTap: () {
                Navigator.pushNamed(
                  context,
                  Routes.productDetails,
                  arguments: products[index],
                );
              },
              onFavoriteTap: () {},
            );
          },
        );
      },
    );
  }

  Widget _buildDiscountsTab() {
    return Consumer<PostProvider>(
      builder: (context, postProvider, child) {
        final offers = postProvider.offers;

        if (postProvider.isLoadingOffers) {
          return _buildGridShimmer();
        }

        if (offers.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.local_offer_outlined,
            title: 'لا توجد تخفيضات',
            message: 'لا توجد تخفيضات متاحة حالياً',
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.65,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: offers.length,
          itemBuilder: (context, index) {
            final offer = offers[index];
            final product = offer.product;
            return GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  Routes.productDetails,
                  arguments: product,
                );
              },
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
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: AspectRatio(
                            aspectRatio: 1.0,
                            child: (product.image == null || product.image!.isEmpty)
                                ? Container(
                                    color: Colors.grey[200],
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.image, size: 40, color: Colors.grey),
                                  )
                                : Image.network(
                                    product.image!,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: Colors.grey[200],
                                      alignment: Alignment.center,
                                      child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                    ),
                                  ),
                          ),
                        ),
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
                              '-${offer.discountPercentage}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
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
                                  style: const TextStyle(
                                    color: AppColors.primaryBlue,
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
            );
          },
        );
      },
    );
  }

  Widget _buildPacksTab() {
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, child) {
        final packs = homeProvider.packs;

        if (homeProvider.isLoadingPacks) {
          return _buildGridShimmer();
        }

        if (packs.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.inventory_2_outlined,
            title: 'لا توجد حزم',
            message: 'لا توجد حزم متاحة حالياً',
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: packs.length,
          itemBuilder: (context, index) {
            final pack = packs[index];
            final discountPercent = pack.totalPrice > 0
                ? ((pack.totalPrice - pack.discountPrice) / pack.totalPrice * 100).round()
                : 0;

            return GestureDetector(
              onTap: () {
                Helpers.showSnackBar(context, 'عرض تفاصيل الحزمة قريباً');
              },
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
                    Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primaryBlue, AppColors.primaryBlue.withValues(alpha: 0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Stack(
                        children: [
                          // Stacked product images
                          Center(
                            child: _buildStackedProductImages(pack.products),
                          ),
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
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _buildProductSummary(pack.products),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                Text(
                                  Helpers.formatPrice(pack.discountPrice),
                                  style: const TextStyle(
                                    color: AppColors.primaryBlue,
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
          },
        );
      },
    );
  }

  Widget _buildStoresTab() {
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, child) {
        final stores = homeProvider.featuredStores;

        if (homeProvider.isLoadingStores) {
          return const Center(child: CircularProgressIndicator());
        }

        if (stores.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.store_outlined,
            title: 'لا توجد متاجر',
            message: 'لا توجد متاجر متاحة حالياً',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: stores.length,
          itemBuilder: (context, index) {
            final store = stores[index];
            return GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, Routes.store, arguments: store.id);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
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
                child: Row(
                  children: [
                    // Store avatar
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: store.imageUrl.isNotEmpty
                            ? NetworkImage(store.imageUrl)
                            : null,
                        child: store.imageUrl.isEmpty
                            ? const Icon(Icons.store, color: Colors.grey, size: 24)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Store info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            store.description.isNotEmpty ? store.description : 'متجر محلي',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                store.rating.toStringAsFixed(1),
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Arrow
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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

  Widget _buildGridShimmer() {
    return ShimmerLoading(
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return const ProductCardSkeleton();
        },
      ),
    );
  }
}
