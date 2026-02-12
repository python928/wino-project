import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../common/constants/card_constants.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/app_toggle_button.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/providers/post_provider.dart';
import '../../core/providers/home_provider.dart';
import '../../core/routing/routes.dart';
import '../shared_widgets/cards/product_card.dart';
import '../shared_widgets/cards/promotion_card.dart';
import '../shared_widgets/cards/pack_card.dart';
import '../shared_widgets/shimmer_loading.dart';
import '../../data/repositories/store_repository.dart';
import '../../data/models/backend_store_model.dart';
import '../../data/models/post_model.dart';
import '../common/location_filter_picker.dart';
import '../../core/widgets/app_button.dart';
import '../common/location_picker_screen.dart';
import 'category_selection_screen.dart';

class SearchTabScreen extends StatefulWidget {
  final String? initialQuery;
  final String? initialType;

  const SearchTabScreen({
    super.key,
    this.initialQuery,
    this.initialType,
  });

  @override
  State<SearchTabScreen> createState() => _SearchTabScreenState();
}

class _SearchTabScreenState extends State<SearchTabScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  bool _hasSearched = false;

  // Selected type
  String _selectedType = 'All';
  final List<ToggleOption> _typeOptions = const [
    ToggleOption(label: 'All', icon: Icons.grid_view_rounded, value: 'All'),
    ToggleOption(label: 'Products', icon: Icons.shopping_bag_rounded, value: 'Products'),
    ToggleOption(label: 'Discounts', icon: Icons.percent_rounded, value: 'Discounts'),
    ToggleOption(label: 'Packs', icon: Icons.inventory_2_rounded, value: 'Packs'),
  ];

  // Filters
  Set<int> _selectedCategoryIds = {};
  String _selectedSort = 'Newest';
  RangeValues _priceRange = const RangeValues(0, 100000);
  double _minRating = 0;

  // Location filter
  LocationFilterResult? _locationFilter;
  String _selectedLocation = 'All Algeria';
  String? _selectedWilaya;
  String? _selectedBaladiya;

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
    // Initialize selected type from widget parameter
    if (widget.initialType != null && widget.initialType!.isNotEmpty) {
      final type = widget.initialType!;
      _selectedType = _typeOptions.any((o) => o.value == type) ? type : 'All';
    }
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
    }
  }

  @override
  void didUpdateWidget(covariant SearchTabScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuery != oldWidget.initialQuery &&
        widget.initialQuery != null &&
        widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _performSearch() {
    _searchFocus.unfocus();

    if (!_hasSearched) {
      setState(() => _hasSearched = true);
    }

    final postProvider = context.read<PostProvider>();
    postProvider.loadPosts(
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
      categoryId: _selectedCategoryIds.length == 1 ? _selectedCategoryIds.first : null,
    );
    postProvider.loadOffers();
    context.read<HomeProvider>().loadFeaturedPacks();
    _searchStores();
  }

  Widget _buildPreSearchState() {
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
                Icons.search_rounded,
                size: 48,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Ready to search',
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose type and categories, then tap Search',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
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

  Future<void> _openCategoryPicker() async {
    final categories = context.read<HomeProvider>().categories;
    if (categories.isEmpty) return;

    final result = await Navigator.push<Set<int>>(
      context,
      MaterialPageRoute(
        builder: (context) => CategorySelectionScreen(
          categories: categories,
          initialSelectedCategoryIds: _selectedCategoryIds,
        ),
      ),
    );

    if (result != null) {
      setState(() => _selectedCategoryIds = result);
    }
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
      _selectedCategoryIds = {};
      _selectedSort = 'Newest';
      _priceRange = const RangeValues(0, 100000);
      _minRating = 0;
      _locationFilter = null;
    });
  }

  bool get _hasActiveFilters =>
      _selectedCategoryIds.isNotEmpty ||
      _minRating > 0 ||
      _priceRange.start > 0 ||
      _priceRange.end < 100000 ||
      _locationFilter?.hasFilters == true;

  Map<int, String> _categoriesById(HomeProvider homeProvider) {
    return {for (final c in homeProvider.categories) c.id: c.name};
  }

  bool _postMatchesSelectedCategories(Post post, Map<int, String> categoriesById) {
    if (_selectedCategoryIds.isEmpty) return true;

    final categoryId = post.categoryId;
    if (categoryId != null) {
      return _selectedCategoryIds.contains(categoryId);
    }

    // Fallback: match by name if API didn't provide categoryId
    final selectedNames = _selectedCategoryIds
        .map((id) => categoriesById[id])
        .whereType<String>()
        .map((e) => e.toLowerCase())
        .toSet();
    if (selectedNames.isEmpty) return true;
    return selectedNames.contains(post.category.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
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
            top: false,
            child: AppPrimaryButton(
              text: 'Search',
              icon: Icons.search_rounded,
              onPressed: _performSearch,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Location Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                child: Row(
                  children: [
                    // Back button
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: AppColors.blackColor, size: 24),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    // Location
                    GestureDetector(
                      onTap: _showLocationPicker,
                      child: Row(
                        children: [
                          Icon(Icons.location_on, color: AppColors.primaryColor, size: 24),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Location',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.greyColor,
                                ),
                              ),
                              Text(
                                _selectedLocation,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.blackColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Modern Header
              _buildHeader(),

              // Type Toggle Buttons
              _buildTypeToggleButtons(),

              // Categories
              _buildCategoriesSection(),

              // Active Filters
              if (_hasActiveFilters) _buildActiveFilters(),

              // Content
              Expanded(child: _buildContent()),
            ],
          ),
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
                child: SizedBox(
                  height: 52,
                  child: AppSearchField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    hintText: 'Search products, stores...',
                    onChanged: (_) => setState(() {}),
                    onSubmitted: () => _searchFocus.unfocus(),
                    onClear: () => setState(() {}),
                  ),
                ),
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

  Widget _buildTypeToggleButtons() {
    final selectedIndex = _typeOptions.indexWhere((o) => o.value == _selectedType);
    final safeSelectedIndex = selectedIndex >= 0 ? selectedIndex : 0;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: AppToggleButtonGroup(
        options: _typeOptions,
        selectedIndex: safeSelectedIndex,
        onChanged: (i) => setState(() => _selectedType = _typeOptions[i].value),
        scrollable: true,
        compact: true,
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

        const int previewCount = 10;
        final previewCategories = categories.take(previewCount).toList();

        final categoriesById = _categoriesById(homeProvider);
        final selectedNames = _selectedCategoryIds
          .map((id) => categoriesById[id])
          .whereType<String>()
          .toList();

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Categories',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: _openCategoryPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'See all',
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.primaryColor),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: previewCategories.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final isSelected = _selectedCategoryIds.isEmpty;
                      return _buildCategoryToggleChip(
                        name: 'All',
                        isSelected: isSelected,
                        onTap: () => setState(() => _selectedCategoryIds = {}),
                      );
                    }

                    final category = previewCategories[index - 1];
                    final isSelected = _selectedCategoryIds.contains(category.id);
                    return _buildCategoryToggleChip(
                      name: category.name,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedCategoryIds.remove(category.id);
                          } else {
                            _selectedCategoryIds.add(category.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              if (selectedNames.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: selectedNames.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final name = selectedNames[index];
                      final id = _selectedCategoryIds.firstWhere(
                        (x) => categoriesById[x] == name,
                        orElse: () => -1,
                      );
                      return _buildSelectedCategoryChip(
                        name: name,
                        onRemove: id > 0
                            ? () => setState(() => _selectedCategoryIds.remove(id))
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryToggleChip({
    required String name,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : AppColors.neutral200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? AppColors.primaryColor : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildNonRemovableCategoryChip({required String name}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.neutral200, width: 1),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSelectedCategoryChip({
    required String name,
    required VoidCallback? onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryColor, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 18, color: AppColors.primaryColor),
          ),
        ],
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
                  if (_selectedCategoryIds.isNotEmpty)
                    _buildFilterTag(
                      'Categories: ${_selectedCategoryIds.length}',
                      Icons.category_rounded,
                    ),
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
                    AppTextButton(
                      text: 'Reset',
                      onPressed: () {
                        setSheetState(() {
                          _selectedSort = 'Newest';
                          _priceRange = const RangeValues(0, 100000);
                          _minRating = 0;
                        });
                      },
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
                  child: AppPrimaryButton(
                    text: 'Apply Filters',
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {});
                    },
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
    if (!_hasSearched) {
      return _buildPreSearchState();
    }
    switch (_selectedType) {
      case 'All':
        return _buildAllContent();
      case 'Products':
        return _buildProductsContent();
      case 'Discounts':
        return _buildDiscountsContent();
      case 'Packs':
        return _buildPacksContent();
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

        final categoriesById = _categoriesById(homeProvider);

        final isLoading = postProvider.isLoadingPosts ||
            postProvider.isLoadingOffers ||
            homeProvider.isLoadingPacks ||
            _isLoadingStores;

        if (isLoading && products.isEmpty && offers.isEmpty && packs.isEmpty && _searchedStores.isEmpty) {
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

        filteredProducts = filteredProducts
            .where((p) => _postMatchesSelectedCategories(p, categoriesById))
            .toList();

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

        filteredOffers = filteredOffers
            .where((o) => _postMatchesSelectedCategories(o.product, categoriesById))
            .toList();

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
                Row(
                  children: [
                    Text(
                      'Stores',
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
                        '${filteredStores.length}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
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
        if (!_hasSearched) {
          return _buildPreSearchState();
        }
        if (postProvider.isLoadingPosts) {
          return _buildGridShimmer();
        }

        final categoriesById = _categoriesById(context.read<HomeProvider>());
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

        products = products
          .where((p) => _postMatchesSelectedCategories(p, categoriesById))
          .toList();

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
        if (!_hasSearched) {
          return _buildPreSearchState();
        }
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

        final categoriesById = _categoriesById(context.read<HomeProvider>());
        offers = offers
            .where((o) => _postMatchesSelectedCategories(o.product, categoriesById))
            .toList();

        if (offers.isEmpty) {
          return _buildEmptyState();
        }

        return GridView.builder(
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
        if (!_hasSearched) {
          return _buildPreSearchState();
        }
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
        itemCount: 6,
        itemBuilder: (context, index) {
          return const ProductCardSkeleton();
        },
      ),
    );
  }

  void _showLocationPicker() async {
    final result = await Navigator.push<LocationResult>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialWilaya: _selectedWilaya,
          initialBaladiya: _selectedBaladiya,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedWilaya = result.wilaya;
        _selectedBaladiya = result.baladiya;
        _selectedLocation = result.address;
      });
    }
  }
}
