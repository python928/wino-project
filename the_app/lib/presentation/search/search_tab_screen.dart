import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/providers/post_provider.dart';
import '../../core/providers/home_provider.dart';
import '../../core/routing/routes.dart';
import '../home/widgets/product_card.dart';
import '../home/widgets/promotion_card.dart';
import '../home/widgets/pack_card.dart';
import '../shared_widgets/shimmer_loading.dart';
import '../../data/repositories/store_repository.dart';
import '../../data/models/backend_store_model.dart';
import '../common/location_filter_picker.dart';

class SearchTabScreen extends StatefulWidget {
  final String? initialQuery;

  const SearchTabScreen({super.key, this.initialQuery});

  @override
  State<SearchTabScreen> createState() => _SearchTabScreenState();
}

class _SearchTabScreenState extends State<SearchTabScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  // Selected type
  String _selectedType = 'All';
  final List<Map<String, dynamic>> _typeOptions = [
    {'label': 'All', 'icon': Icons.grid_view_rounded},
    {'label': 'Products', 'icon': Icons.shopping_bag_rounded},
    {'label': 'Discounts', 'icon': Icons.percent_rounded},
    {'label': 'Packs', 'icon': Icons.inventory_2_rounded},
    {'label': 'Stores', 'icon': Icons.storefront_rounded},
  ];

  // Filters
  String _selectedCategory = 'All';
  int? _selectedCategoryId;
  String _selectedSort = 'Newest';
  RangeValues _priceRange = const RangeValues(0, 100000);
  double _minRating = 0;

  // Location filter
  LocationFilterResult? _locationFilter;

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
    _searchFocus.dispose();
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

  void _showLocationFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationFilterPicker(
        initialFilter: _locationFilter,
      ),
    ).then((result) {
      if (result != null && result is LocationFilterResult) {
        setState(() => _locationFilter = result);
        _performSearch();
      }
    });
  }

  void _showFiltersSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFiltersBottomSheet(),
    );
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCategory = 'All';
      _selectedCategoryId = null;
      _selectedSort = 'Newest';
      _priceRange = const RangeValues(0, 100000);
      _minRating = 0;
      _locationFilter = null;
    });
    _performSearch();
  }

  bool get _hasActiveFilters =>
      _selectedCategory != 'All' ||
      _minRating > 0 ||
      _priceRange.start > 0 ||
      _priceRange.end < 100000 ||
      _locationFilter?.hasFilters == true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header
            _buildHeader(),

            // Type Tabs
            _buildTypeTabs(),

            // Categories
            _buildCategoriesSection(),

            // Active Filters
            if (_hasActiveFilters) _buildActiveFilters(),

            // Content
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Row
          Row(
            children: [
              // Search Field
              Expanded(
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6F8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _performSearch(),
                    style: AppTextStyles.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Search products, stores...',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textTertiary,
                      ),
                      prefixIcon: Container(
                        padding: const EdgeInsets.all(14),
                        child: Icon(
                          Icons.search_rounded,
                          color: AppColors.textSecondary,
                          size: 24,
                        ),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.neutral300,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                                _performSearch();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Location Button
              _buildHeaderButton(
                icon: Icons.location_on_rounded,
                isActive: _locationFilter?.hasFilters == true,
                badge: _locationFilter?.hasFilters == true
                    ? _getLocationBadgeCount()
                    : null,
                onTap: _showLocationFilter,
              ),
              const SizedBox(width: 8),

              // Filter Button
              _buildHeaderButton(
                icon: Icons.tune_rounded,
                isActive: _minRating > 0 || _priceRange.start > 0 || _priceRange.end < 100000,
                onTap: _showFiltersSheet,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryColor.withOpacity(0.1)
              : const Color(0xFFF5F6F8),
          borderRadius: BorderRadius.circular(16),
          border: isActive
              ? Border.all(color: AppColors.primaryColor, width: 1.5)
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.primaryColor : AppColors.textSecondary,
              size: 24,
            ),
            if (badge != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badge,
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
    );
  }

  Widget _buildTypeTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        height: 44,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _typeOptions.length,
          itemBuilder: (context, index) {
            final option = _typeOptions[index];
            final isSelected = _selectedType == option['label'];

            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () => setState(() => _selectedType = option['label']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              AppColors.primaryColor,
                              AppColors.primaryColor.withOpacity(0.85),
                            ],
                          )
                        : null,
                    color: isSelected ? null : const Color(0xFFF5F6F8),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        option['icon'] as IconData,
                        size: 18,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        option['label'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.only(bottom: 12),
          child: SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildCategoryChip(
                      name: 'All',
                      isSelected: _selectedCategory == 'All',
                      onTap: () => _selectCategory(null, 'All'),
                    ),
                  );
                }

                final category = categories[index - 1];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : AppColors.neutral200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          name,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppColors.primaryColor : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(color: AppColors.primaryColor.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.filter_list_rounded,
              size: 16,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (_locationFilter?.hasFilters == true)
                    _buildFilterTag(
                      _locationFilter!.displayText,
                      Icons.location_on_rounded,
                    ),
                  if (_selectedCategory != 'All')
                    _buildFilterTag(_selectedCategory, Icons.category_rounded),
                  if (_minRating > 0)
                    _buildFilterTag(
                      '${_minRating.toStringAsFixed(1)}+',
                      Icons.star_rounded,
                    ),
                  if (_priceRange.start > 0 || _priceRange.end < 100000)
                    _buildFilterTag(
                      '${_priceRange.start.toInt()}-${_priceRange.end.toInt()}',
                      Icons.attach_money_rounded,
                    ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: _clearAllFilters,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Clear',
                style: TextStyle(
                  color: AppColors.errorRed,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTag(String label, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primaryColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersBottomSheet() {
    return StatefulBuilder(
      builder: (context, setSheetState) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neutral300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filters',
                      style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
                    ),
                    TextButton(
                      onPressed: () {
                        setSheetState(() {
                          _selectedSort = 'Newest';
                          _priceRange = const RangeValues(0, 100000);
                          _minRating = 0;
                        });
                      },
                      child: Text(
                        'Reset',
                        style: TextStyle(
                          color: AppColors.errorRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sort By
                      Text(
                        'Sort By',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _sortOptions.map((option) {
                          final isSelected = _selectedSort == option;
                          return GestureDetector(
                            onTap: () => setSheetState(() => _selectedSort = option),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryColor
                                    : AppColors.neutral100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight:
                                      isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color:
                                      isSelected ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Price Range
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Price Range',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_priceRange.start.toInt()} - ${_priceRange.end.toInt()} DZD',
                              style: TextStyle(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: AppColors.primaryColor,
                          inactiveTrackColor: AppColors.neutral200,
                          thumbColor: AppColors.primaryColor,
                          overlayColor: AppColors.primaryColor.withOpacity(0.1),
                          trackHeight: 4,
                        ),
                        child: RangeSlider(
                          values: _priceRange,
                          min: 0,
                          max: 100000,
                          divisions: 100,
                          onChanged: (values) {
                            setSheetState(() => _priceRange = values);
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Rating
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Minimum Rating',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  _minRating.toStringAsFixed(1),
                                  style: TextStyle(
                                    color: Colors.amber[800],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: Colors.amber,
                          inactiveTrackColor: AppColors.neutral200,
                          thumbColor: Colors.amber,
                          overlayColor: Colors.amber.withOpacity(0.1),
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: _minRating,
                          min: 0,
                          max: 5,
                          divisions: 10,
                          onChanged: (value) {
                            setSheetState(() => _minRating = value);
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Apply Button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {});
                        _performSearch();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Apply Filters',
                        style: AppTextStyles.buttonText.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    switch (_selectedType) {
      case 'All':
        return _buildAllContent();
      case 'Products':
        return _buildProductsContent();
      case 'Discounts':
        return _buildDiscountsContent();
      case 'Packs':
        return _buildPacksContent();
      case 'Stores':
        return _buildStoresContent();
      default:
        return _buildAllContent();
    }
  }

  // Location filter helpers
  bool _storeMatchesLocationFilter(String address) {
    if (_locationFilter == null || !_locationFilter!.hasFilters) return true;
    if (_locationFilter!.allAlgeria) return true;
    if (address.isEmpty) return false;

    final addressLower = address.toLowerCase();

    for (final wilaya in _locationFilter!.selectedWilayas) {
      if (addressLower.contains(wilaya.toLowerCase())) {
        // Check if there are specific baladiyat selected for this wilaya
        final wilayaBaladiyat = _locationFilter!.selectedBaladiyat[wilaya];
        if (wilayaBaladiyat != null && wilayaBaladiyat.isNotEmpty) {
          // Only match if one of the specific baladiyat matches
          for (final baladiya in wilayaBaladiyat) {
            if (addressLower.contains(baladiya.toLowerCase())) {
              return true;
            }
          }
        } else {
          // No specific baladiyat = all baladiyat in this wilaya
          return true;
        }
      }
    }

    return false;
  }

  String? _getLocationBadgeCount() {
    if (_locationFilter == null || !_locationFilter!.hasFilters) return null;
    if (_locationFilter!.allAlgeria) return null;

    // Count total baladiyat selected
    int totalBaladiyat = 0;
    for (final list in _locationFilter!.selectedBaladiyat.values) {
      totalBaladiyat += list.length;
    }

    if (totalBaladiyat > 0) {
      return totalBaladiyat.toString();
    }
    return _locationFilter!.selectedWilayas.length.toString();
  }

  List<BackendStore> _getLocationFilteredStores() {
    if (_locationFilter == null || !_locationFilter!.hasFilters) {
      return _searchedStores;
    }
    return _searchedStores
        .where((store) => _storeMatchesLocationFilter(store.address))
        .toList();
  }

  Set<int> _getValidStoreIds() {
    if (_locationFilter == null || !_locationFilter!.hasFilters) {
      return {};
    }
    return _getLocationFilteredStores().map((s) => s.id).toSet();
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

        if (isLoading &&
            products.isEmpty &&
            offers.isEmpty &&
            packs.isEmpty &&
            _searchedStores.isEmpty) {
          return _buildGridShimmer();
        }

        final validStoreIds = _getValidStoreIds();
        final hasLocationFilter = _locationFilter?.hasFilters == true;

        var filteredProducts = products.toList();
        if (hasLocationFilter && validStoreIds.isNotEmpty) {
          filteredProducts = filteredProducts
              .where((p) => validStoreIds.contains(p.storeId))
              .toList();
        } else if (hasLocationFilter && validStoreIds.isEmpty) {
          filteredProducts = [];
        }

        if (_minRating > 0) {
          filteredProducts =
              filteredProducts.where((p) => p.rating >= _minRating).toList();
        }
        if (_priceRange.start > 0 || _priceRange.end < 100000) {
          filteredProducts = filteredProducts
              .where((p) =>
                  p.price >= _priceRange.start && p.price <= _priceRange.end)
              .toList();
        }

        var filteredOffers = offers.toList();
        if (hasLocationFilter && validStoreIds.isNotEmpty) {
          filteredOffers = filteredOffers
              .where((o) => validStoreIds.contains(o.product.storeId))
              .toList();
        } else if (hasLocationFilter && validStoreIds.isEmpty) {
          filteredOffers = [];
        }

        var filteredPacks = packs.toList();
        if (hasLocationFilter && validStoreIds.isNotEmpty) {
          filteredPacks = filteredPacks
              .where((p) => validStoreIds.contains(p.merchantId))
              .toList();
        } else if (hasLocationFilter && validStoreIds.isEmpty) {
          filteredPacks = [];
        }

        final filteredStores = _getLocationFilteredStores();

        final hasProducts = filteredProducts.isNotEmpty;
        final hasOffers = filteredOffers.isNotEmpty;
        final hasPacks = filteredPacks.isNotEmpty;
        final hasStores = filteredStores.isNotEmpty;

        if (!hasProducts && !hasOffers && !hasPacks && !hasStores) {
          return _buildEmptyState();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasProducts) ...[
                _buildSectionHeader('Products', filteredProducts.length, () {
                  setState(() => _selectedType = 'Products');
                }),
                const SizedBox(height: 16),
                SizedBox(
                  height: 230,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: filteredProducts.take(6).length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(right: index < 5 ? 12 : 0),
                        child: SizedBox(
                          width: 165,
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
                const SizedBox(height: 28),
              ],

              if (hasOffers) ...[
                _buildSectionHeader('Discounts', filteredOffers.length, () {
                  setState(() => _selectedType = 'Discounts');
                }),
                const SizedBox(height: 16),
                SizedBox(
                  height: 230,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: filteredOffers.take(6).length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(right: index < 5 ? 12 : 0),
                        child: SizedBox(
                          width: 165,
                          child: PromotionCard(offer: filteredOffers[index]),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 28),
              ],

              if (hasPacks) ...[
                _buildSectionHeader('Packs', filteredPacks.length, () {
                  setState(() => _selectedType = 'Packs');
                }),
                const SizedBox(height: 16),
                SizedBox(
                  height: 230,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: filteredPacks.take(6).length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(right: index < 5 ? 12 : 0),
                        child: SizedBox(
                          width: 165,
                          child: PackCard(pack: filteredPacks[index]),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 28),
              ],

              if (hasStores) ...[
                _buildSectionHeader('Stores', filteredStores.length, () {
                  setState(() => _selectedType = 'Stores');
                }),
                const SizedBox(height: 16),
                ...filteredStores.take(3).map((store) => _buildStoreCard(store)),
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
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: onViewAll,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(
                  'View All',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: AppColors.primaryColor,
                ),
              ],
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Store Avatar
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryColor.withOpacity(0.1),
                    AppColors.primaryColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: store.profileImageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        store.profileImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.storefront_rounded,
                          color: AppColors.primaryColor,
                          size: 28,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.storefront_rounded,
                      color: AppColors.primaryColor,
                      size: 28,
                    ),
            ),
            const SizedBox(width: 14),

            // Store Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (store.description.isNotEmpty)
                    Text(
                      store.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          store.address.isNotEmpty ? store.address : 'Algeria',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                      if (store.averageRating > 0) ...[
                        Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          store.averageRating.toStringAsFixed(1),
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Arrow
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 48,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Results Found',
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters\nto find what you\'re looking for',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            if (_hasActiveFilters)
              TextButton.icon(
                onPressed: _clearAllFilters,
                icon: Icon(Icons.filter_alt_off_rounded, size: 18),
                label: Text('Clear Filters'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryColor,
                ),
              ),
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

        var products = postProvider.posts.toList();

        final validStoreIds = _getValidStoreIds();
        final hasLocationFilter = _locationFilter?.hasFilters == true;
        if (hasLocationFilter && validStoreIds.isNotEmpty) {
          products =
              products.where((p) => validStoreIds.contains(p.storeId)).toList();
        } else if (hasLocationFilter && validStoreIds.isEmpty) {
          products = [];
        }

        if (_minRating > 0) {
          products = products.where((p) => p.rating >= _minRating).toList();
        }
        if (_priceRange.start > 0 || _priceRange.end < 100000) {
          products = products
              .where((p) =>
                  p.price >= _priceRange.start && p.price <= _priceRange.end)
              .toList();
        }

        switch (_selectedSort) {
          case 'Oldest':
            products = List.from(products)..sort((a, b) => a.id.compareTo(b.id));
            break;
          case 'Highest Rated':
            products = List.from(products)
              ..sort((a, b) => b.rating.compareTo(a.rating));
            break;
          case 'Lowest Price':
            products = List.from(products)
              ..sort((a, b) => a.price.compareTo(b.price));
            break;
          case 'Highest Price':
            products = List.from(products)
              ..sort((a, b) => b.price.compareTo(a.price));
            break;
        }

        if (products.isEmpty) {
          return _buildEmptyState();
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.65,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
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
        var offers = postProvider.offers.toList();

        if (postProvider.isLoadingOffers) {
          return _buildGridShimmer();
        }

        final validStoreIds = _getValidStoreIds();
        final hasLocationFilter = _locationFilter?.hasFilters == true;
        if (hasLocationFilter && validStoreIds.isNotEmpty) {
          offers = offers
              .where((o) => validStoreIds.contains(o.product.storeId))
              .toList();
        } else if (hasLocationFilter && validStoreIds.isEmpty) {
          offers = [];
        }

        if (offers.isEmpty) {
          return _buildEmptyState();
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
        var packs = homeProvider.packs.toList();

        if (homeProvider.isLoadingPacks) {
          return _buildGridShimmer();
        }

        final validStoreIds = _getValidStoreIds();
        final hasLocationFilter = _locationFilter?.hasFilters == true;
        if (hasLocationFilter && validStoreIds.isNotEmpty) {
          packs =
              packs.where((p) => validStoreIds.contains(p.merchantId)).toList();
        } else if (hasLocationFilter && validStoreIds.isEmpty) {
          packs = [];
        }

        if (packs.isEmpty) {
          return _buildEmptyState();
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
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryColor),
      );
    }

    final filteredStores = _getLocationFilteredStores();

    if (filteredStores.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredStores.length,
      itemBuilder: (context, index) {
        return _buildStoreCard(filteredStores[index]);
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
