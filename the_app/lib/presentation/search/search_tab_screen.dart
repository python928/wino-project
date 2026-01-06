import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/providers/post_provider.dart';
import '../../core/providers/home_provider.dart';
import '../../core/routing/routes.dart';
import '../home/widgets/product_card.dart';
import '../home/widgets/promotion_card.dart';
import '../home/widgets/pack_card.dart';
import '../shared_widgets/shimmer_loading.dart';
import '../shared_widgets/empty_state_widget.dart';
import '../../data/repositories/store_repository.dart';
import '../../data/models/backend_store_model.dart';

class SearchTabScreen extends StatefulWidget {
  final String? initialQuery;

  const SearchTabScreen({super.key, this.initialQuery});

  @override
  State<SearchTabScreen> createState() => _SearchTabScreenState();
}

class _SearchTabScreenState extends State<SearchTabScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Selected type dropdown
  String _selectedType = 'الكل';
  final List<Map<String, dynamic>> _typeOptions = [
    {'label': 'الكل', 'icon': Icons.apps},
    {'label': 'المنتجات', 'icon': Icons.shopping_bag_outlined},
    {'label': 'التخفيضات', 'icon': Icons.local_offer_outlined},
    {'label': 'الحزم', 'icon': Icons.inventory_2_outlined},
    {'label': 'المتاجر', 'icon': Icons.store_outlined},
  ];

  // Filters
  String _selectedCategory = 'الكل';
  int? _selectedCategoryId;
  String _selectedSort = 'الأحدث';
  RangeValues _priceRange = const RangeValues(0, 100000);
  double _minRating = 0;

  // Stores search
  List<BackendStore> _searchedStores = [];
  bool _isLoadingStores = false;

  // How many categories to show before "show all"
  static const int _maxVisibleCategories = 10;

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
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performSearch();
    });
  }

  @override
  void didUpdateWidget(covariant SearchTabScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuery != oldWidget.initialQuery &&
        widget.initialQuery != null &&
        widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _performSearch();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final postProvider = context.read<PostProvider>();
    postProvider.loadPosts(
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
      categoryId: _selectedCategoryId,
    );
    postProvider.loadOffers();
    context.read<HomeProvider>().loadFeaturedPacks();
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

  void _selectCategory(int? categoryId, String categoryName) {
    setState(() {
      _selectedCategory = categoryName;
      _selectedCategoryId = categoryId;
    });
    _performSearch();
  }

  void _showAllCategoriesDialog() {
    final homeProvider = context.read<HomeProvider>();
    final categories = homeProvider.categories;
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final filteredCategories = searchQuery.isEmpty
              ? categories
              : categories.where((c) => c.name.contains(searchQuery)).toList();

          return Directionality(
            textDirection: TextDirection.rtl,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Row(
                      children: [
                        const Icon(Icons.category_outlined, color: AppColors.primaryBlue),
                        const SizedBox(width: 10),
                        const Text(
                          'اختر الفئة',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Search field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      onChanged: (value) {
                        setDialogState(() => searchQuery = value);
                      },
                      decoration: InputDecoration(
                        hintText: 'ابحث في الفئات...',
                        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                        prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey[500]),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Categories as chips
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 10,
                        children: [
                          // "All" category chip
                          _buildDialogCategoryChip(
                            name: 'الكل',
                            isSelected: _selectedCategory == 'الكل',
                            onTap: () {
                              _selectCategory(null, 'الكل');
                              Navigator.pop(context);
                            },
                          ),
                          // Category chips
                          ...filteredCategories.map((category) {
                            return _buildDialogCategoryChip(
                              name: category.name,
                              isSelected: _selectedCategory == category.name,
                              onTap: () {
                                _selectCategory(category.id, category.name);
                                Navigator.pop(context);
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDialogCategoryChip({
    required String name,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : Colors.grey[100],
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          name,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('نطاق السعر', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        '${_priceRange.start.toInt()} - ${_priceRange.end.toInt()} د.ج',
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('الحد الأدنى للتقييم',
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
                        'تطبيق الفلاتر',
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
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header with search
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  // Search field
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.scaffoldBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _performSearch(),
                        decoration: InputDecoration(
                          hintText: 'ابحث عن منتجات، متاجر...',
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
                  ),
                  const SizedBox(width: 12),
                  // Filter button
                  GestureDetector(
                    onTap: _showFiltersSheet,
                    child: Container(
                      height: 46,
                      width: 46,
                      decoration: BoxDecoration(
                        color: AppColors.scaffoldBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.tune, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),

            // Type dropdown and categories
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.scaffoldBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedType,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        items: _typeOptions.map((option) {
                          return DropdownMenuItem<String>(
                            value: option['label'] as String,
                            child: Row(
                              children: [
                                Icon(option['icon'] as IconData, size: 20, color: AppColors.primaryBlue),
                                const SizedBox(width: 10),
                                Text(option['label'] as String),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedType = value);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Categories section
            _buildCategoriesSection(),

            // Active filters indicator
            if (_selectedCategory != 'الكل' ||
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
                      'فلاتر نشطة',
                      style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w500,
                          fontSize: 12),
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
                        _performSearch();
                      },
                      child: const Text(
                        'مسح الكل',
                        style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                            fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            // Content based on selected type
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, child) {
        final categories = homeProvider.categories;

        if (categories.isEmpty) {
          return const SizedBox.shrink();
        }

        // Show limited categories + "show all" button
        final visibleCategories = categories.take(_maxVisibleCategories).toList();
        final hasMore = categories.length > _maxVisibleCategories;

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
          child: SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: visibleCategories.length + 1 + (hasMore ? 1 : 0), // +1 for "All", +1 for "Show more"
              itemBuilder: (context, index) {
                // First item is "All"
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _buildCategoryChip(
                      name: 'الكل',
                      isSelected: _selectedCategory == 'الكل',
                      onTap: () => _selectCategory(null, 'الكل'),
                    ),
                  );
                }

                // Last item is "Show more" if there are more categories
                if (hasMore && index == visibleCategories.length + 1) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _buildShowMoreChip(),
                  );
                }

                final category = visibleCategories[index - 1];
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _buildCategoryChip(
                    name: category.name,
                    isSelected: _selectedCategory == category.name,
                    onTap: () => _selectCategory(category.id, category.name),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip({
    required String name,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : Colors.grey[100],
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          name,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildShowMoreChip() {
    return GestureDetector(
      onTap: _showAllCategoriesDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          'المزيد +',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryBlue,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedType) {
      case 'الكل':
        return _buildAllContent();
      case 'المنتجات':
        return _buildProductsContent();
      case 'التخفيضات':
        return _buildDiscountsContent();
      case 'الحزم':
        return _buildPacksContent();
      case 'المتاجر':
        return _buildStoresContent();
      default:
        return _buildAllContent();
    }
  }

  Widget _buildAllContent() {
    return Consumer2<PostProvider, HomeProvider>(
      builder: (context, postProvider, homeProvider, child) {
        final products = postProvider.posts;
        final offers = postProvider.offers;
        final packs = homeProvider.packs;

        final isLoading = postProvider.isLoadingPosts ||
                          postProvider.isLoadingOffers ||
                          homeProvider.isLoadingPacks ||
                          _isLoadingStores;

        if (isLoading && products.isEmpty && offers.isEmpty && packs.isEmpty && _searchedStores.isEmpty) {
          return _buildGridShimmer();
        }

        // Filter products
        var filteredProducts = products.toList();
        if (_minRating > 0) {
          filteredProducts = filteredProducts.where((p) => p.rating >= _minRating).toList();
        }
        if (_priceRange.start > 0 || _priceRange.end < 100000) {
          filteredProducts = filteredProducts
              .where((p) => p.price >= _priceRange.start && p.price <= _priceRange.end)
              .toList();
        }

        final hasProducts = filteredProducts.isNotEmpty;
        final hasOffers = offers.isNotEmpty;
        final hasPacks = packs.isNotEmpty;
        final hasStores = _searchedStores.isNotEmpty;

        if (!hasProducts && !hasOffers && !hasPacks && !hasStores) {
          return const EmptyStateWidget(
            icon: Icons.search_off,
            title: 'لا توجد نتائج',
            message: 'لم نجد أي نتائج تطابق بحثك',
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Products section
              if (hasProducts) ...[
                _buildSectionHeader('المنتجات', filteredProducts.length, () {
                  setState(() => _selectedType = 'المنتجات');
                }),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: filteredProducts.take(6).length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(left: index < 5 ? 12 : 0),
                        child: SizedBox(
                          width: 160,
                          child: ProductCard(
                            product: filteredProducts[index],
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                Routes.productDetails,
                                arguments: filteredProducts[index],
                              );
                            },
                            onFavoriteTap: () {},
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Offers section
              if (hasOffers) ...[
                _buildSectionHeader('التخفيضات', offers.length, () {
                  setState(() => _selectedType = 'التخفيضات');
                }),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: offers.take(6).length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(left: index < 5 ? 12 : 0),
                        child: SizedBox(
                          width: 160,
                          child: PromotionCard(offer: offers[index]),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Packs section
              if (hasPacks) ...[
                _buildSectionHeader('الحزم', packs.length, () {
                  setState(() => _selectedType = 'الحزم');
                }),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: packs.take(6).length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(left: index < 5 ? 12 : 0),
                        child: SizedBox(
                          width: 160,
                          child: PackCard(pack: packs[index]),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Stores section
              if (hasStores) ...[
                _buildSectionHeader('المتاجر', _searchedStores.length, () {
                  setState(() => _selectedType = 'المتاجر');
                }),
                const SizedBox(height: 12),
                ...(_searchedStores.take(3).map((store) => _buildStoreCard(store))),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, int count, VoidCallback onViewAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: onViewAll,
          child: const Text(
            'عرض الكل',
            style: TextStyle(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStoreCard(BackendStore store) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, Routes.store, arguments: store.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[200],
              backgroundImage: store.profileImageUrl.isNotEmpty
                  ? NetworkImage(store.profileImageUrl)
                  : null,
              child: store.profileImageUrl.isEmpty
                  ? const Icon(Icons.store, color: Colors.grey, size: 20)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    store.address.isNotEmpty ? store.address : 'الجزائر',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsContent() {
    return Consumer<PostProvider>(
      builder: (context, postProvider, child) {
        if (postProvider.isLoadingPosts) {
          return _buildGridShimmer();
        }

        var products = postProvider.posts;

        if (_minRating > 0) {
          products = products.where((p) => p.rating >= _minRating).toList();
        }
        if (_priceRange.start > 0 || _priceRange.end < 100000) {
          products = products
              .where(
                  (p) => p.price >= _priceRange.start && p.price <= _priceRange.end)
              .toList();
        }

        switch (_selectedSort) {
          case 'الأقدم':
            products = List.from(products)..sort((a, b) => a.id.compareTo(b.id));
            break;
          case 'الأعلى تقييماً':
            products =
                List.from(products)..sort((a, b) => b.rating.compareTo(a.rating));
            break;
          case 'الأقل سعراً':
            products =
                List.from(products)..sort((a, b) => a.price.compareTo(b.price));
            break;
          case 'الأعلى سعراً':
            products =
                List.from(products)..sort((a, b) => b.price.compareTo(a.price));
            break;
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

  Widget _buildDiscountsContent() {
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

  Widget _buildPacksContent() {
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

  Widget _buildStoresContent() {
    if (_isLoadingStores) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchedStores.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.store_outlined,
        title: 'لا توجد متاجر',
        message: 'لم نجد أي متاجر تطابق بحثك',
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
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
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
                            : 'متجر محلي',
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
                              store.address.isNotEmpty ? store.address : 'الجزائر',
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
