import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/post_provider.dart';
import '../../core/providers/home_provider.dart';
import '../../core/routing/routes.dart';
import '../../core/utils/helpers.dart';
import '../home/widgets/product_card.dart';
import '../home/widgets/promotion_card.dart';
import '../home/widgets/pack_card.dart';
import '../shared_widgets/shimmer_loading.dart';
import '../shared_widgets/empty_state_widget.dart';
import '../../data/repositories/store_repository.dart';
import '../../data/models/backend_store_model.dart';

class SearchResultsScreen extends StatefulWidget {
  final String? initialQuery;
  final int? initialCategoryId;
  final String? initialCategoryName;

  const SearchResultsScreen({
    super.key,
    this.initialQuery,
    this.initialCategoryId,
    this.initialCategoryName,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // Filters
  String _selectedCategory = 'All';
  int? _selectedCategoryId;
  String _selectedSort = 'Newest';
  RangeValues _priceRange = const RangeValues(0, 100000);
  double _minRating = 0;

  // Stores search
  List<BackendStore> _searchedStores = [];
  bool _isLoadingStores = false;

  final List<String> _sortOptions = [
    'Newest',
    'Oldest',
    'Highest Rated',
    'Lowest Price',
    'Highest Price',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _searchController.text = widget.initialQuery ?? '';
    _selectedCategoryId = widget.initialCategoryId;
    _selectedCategory = widget.initialCategoryName ?? 'All';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performSearch();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final postProvider = context.read<PostProvider>();
    postProvider.loadPosts(
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
      categoryId: _selectedCategoryId,
    );
    _searchStores();
  }

  Future<void> _searchStores() async {
    setState(() => _isLoadingStores = true);
    try {
      final stores = await StoreRepository.searchStores(
        query: _searchController.text.isNotEmpty ? _searchController.text : null,
      );
      if (mounted) {
        setState(() {
          _searchedStores = stores;
          _isLoadingStores = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingStores = false);
      }
    }
  }

  void _showCategoryDialog() {
    final homeProvider = context.read<HomeProvider>();
    final categories = homeProvider.categories;
    String searchQuery = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final filteredCategories = searchQuery.isEmpty
              ? categories
              : categories.where((c) => c.name.contains(searchQuery)).toList();

          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.category_outlined, color: AppColors.primaryBlue),
                  const SizedBox(width: 8),
                  const Text('Select Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search in categories
                    TextField(
                      onChanged: (value) {
                        setDialogState(() => searchQuery = value);
                      },
                      decoration: InputDecoration(
                        hintText: 'Search in categories...',
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
                    Expanded(
                      child: ListView(
                        children: [
                          // "All" option
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _selectedCategory == 'All'
                                    ? AppColors.primaryBlue.withOpacity(0.1)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.apps,
                                color: _selectedCategory == 'All' ? AppColors.primaryBlue : Colors.grey,
                                size: 20,
                              ),
                            ),
                            title: const Text('All'),
                            trailing: _selectedCategory == 'All'
                                ? const Icon(Icons.check_circle, color: AppColors.primaryBlue)
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedCategory = 'All';
                                _selectedCategoryId = null;
                              });
                              Navigator.pop(context);
                              _performSearch();
                            },
                          ),
                          ...filteredCategories.map((category) => ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _selectedCategory == category.name
                                        ? AppColors.primaryBlue.withOpacity(0.1)
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    category.iconData,
                                    color: _selectedCategory == category.name
                                        ? AppColors.primaryBlue
                                        : Colors.grey,
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
                                  _performSearch();
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
                  child: const Text('Cancel'),
                ),
              ],
            ),
          );
        },
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
                        'Filters',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            _selectedSort = 'Newest';
                            _priceRange = const RangeValues(0, 100000);
                            _minRating = 0;
                          });
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Sort by
                  const Text('Sort by', style: TextStyle(fontWeight: FontWeight.w600)),
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
                      const Text('Price Range', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        '${_priceRange.start.toInt()} - ${_priceRange.end.toInt()} DZD',
                        style: const TextStyle(
                            color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
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
                      const Text('Minimum Rating',
                          style: TextStyle(fontWeight: FontWeight.w600)),
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
                        _performSearch();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Apply Filters',
                        style:
                            TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
          backgroundColor: Colors.white,
          elevation: 0,
          titleSpacing: 0,
          title: Container(
            margin: const EdgeInsets.only(left: 16),
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.scaffoldBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              autofocus: widget.initialQuery?.isEmpty ?? true,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _performSearch(),
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 22),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[500], size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                          _performSearch();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          actions: [
            // Filter button
            IconButton(
              onPressed: _showFiltersSheet,
              icon: const Icon(Icons.tune, color: AppColors.textPrimary),
              tooltip: 'Filters',
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
                  Tab(text: 'Products'),
                  Tab(text: 'Discounts'),
                  Tab(text: 'Packs'),
                  Tab(text: 'Stores'),
                ],
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            // Category Dropdown Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  // Category dropdown button
                  Expanded(
                    child: GestureDetector(
                      onTap: _showCategoryDialog,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.scaffoldBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.category_outlined,
                                size: 20, color: AppColors.primaryBlue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedCategory,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, size: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Active filters indicator
            if (_selectedCategory != 'All' ||
                _minRating > 0 ||
                _priceRange.start > 0 ||
                _priceRange.end < 100000)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppColors.primaryBlue.withOpacity(0.05),
                child: Row(
                  children: [
                    const Icon(Icons.filter_list, size: 16, color: AppColors.primaryBlue),
                    const SizedBox(width: 8),
                    const Text(
                      'Active Filters',
                      style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w500,
                          fontSize: 12),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = 'All';
                          _selectedCategoryId = null;
                          _selectedSort = 'Newest';
                          _priceRange = const RangeValues(0, 100000);
                          _minRating = 0;
                        });
                        _performSearch();
                      },
                      child: const Text(
                        'Clear All',
                        style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                            fontSize: 12),
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
        if (postProvider.isLoadingPosts) {
          return _buildGridShimmer();
        }

        var products = postProvider.posts;

        // Apply local filters
        if (_minRating > 0) {
          products = products.where((p) => p.rating >= _minRating).toList();
        }
        if (_priceRange.start > 0 || _priceRange.end < 100000) {
          products = products
              .where(
                  (p) => p.price >= _priceRange.start && p.price <= _priceRange.end)
              .toList();
        }

        // Apply sorting
        switch (_selectedSort) {
          case 'Oldest':
            products = List.from(products)..sort((a, b) => a.id.compareTo(b.id));
            break;
          case 'Highest Rated':
            products =
                List.from(products)..sort((a, b) => b.rating.compareTo(a.rating));
            break;
          case 'Lowest Price':
            products =
                List.from(products)..sort((a, b) => a.price.compareTo(b.price));
            break;
          case 'Highest Price':
            products =
                List.from(products)..sort((a, b) => b.price.compareTo(a.price));
            break;
        }

        if (products.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.search_off,
            title: 'No products found',
            message: 'We couldn\'t find any products matching your search',
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
            title: 'No discounts found',
            message: 'No discounts available at the moment',
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
          itemCount: offers.length,
          itemBuilder: (context, index) {
            return PromotionCard(offer: offers[index]);
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
            title: 'No packs found',
            message: 'No packs available at the moment',
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
          itemCount: packs.length,
          itemBuilder: (context, index) {
            return PackCard(pack: packs[index]);
          },
        );
      },
    );
  }

  Widget _buildStoresTab() {
    if (_isLoadingStores) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchedStores.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.store_outlined,
        title: 'No stores found',
        message: 'We couldn\'t find any stores matching your search',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchedStores.length,
      itemBuilder: (context, index) {
        final store = _searchedStores[index];
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
                // Store Avatar
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
                    backgroundImage: store.profileImageUrl.isNotEmpty
                        ? NetworkImage(store.profileImageUrl)
                        : null,
                    child: store.profileImageUrl.isEmpty
                        ? const Icon(Icons.store, color: Colors.grey, size: 24)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                // Store Info
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
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        store.description.isNotEmpty
                            ? store.description
                            : 'Local store',
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
                          Icon(Icons.location_on_outlined,
                              color: Colors.grey[500], size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              store.address.isNotEmpty ? store.address : 'Algeria',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Arrow
                Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
              ],
            ),
          ),
        );
      },
    );
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
