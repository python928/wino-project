import 'package:flutter/material.dart';

import '../../core/providers/home_provider.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class CategorySelectionScreen extends StatefulWidget {
  final List<Category> categories;
  final Set<int> initialSelectedCategoryIds;

  const CategorySelectionScreen({
    super.key,
    required this.categories,
    required this.initialSelectedCategoryIds,
  });

  @override
  State<CategorySelectionScreen> createState() => _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
  final TextEditingController _searchController = TextEditingController();

  late Set<int> _selectedIds;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selectedIds = {...widget.initialSelectedCategoryIds};
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Category> get _filteredCategories {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.categories;
    return widget.categories.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  void _toggle(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = _filteredCategories;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text('Categories', style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.blackColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() => _selectedIds.clear()),
            child: Text(
              'Clear',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: AppSearchField(
              controller: _searchController,
              hintText: 'Search categories...',
              onChanged: (v) => setState(() => _query = v),
              onClear: () => setState(() => _query = ''),
            ),
          ),
          Expanded(
            child: categories.isEmpty
                ? Center(
                    child: Text(
                      'No categories found',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: categories.map((category) {
                        final isSelected = _selectedIds.contains(category.id);
                        return _buildCategoryToggleChip(
                          name: category.name,
                          isSelected: isSelected,
                          onTap: () => _toggle(category.id),
                        );
                      }).toList(),
                    ),
                  ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: SafeArea(
              top: false,
              child: AppPrimaryButton(
                text: 'Confirm',
                icon: Icons.check_circle_outline_rounded,
                onPressed: () => Navigator.pop<Set<int>>(context, _selectedIds),
              ),
            ),
          ),
        ],
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : AppColors.neutral200,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? AppColors.primaryColor : AppColors.textPrimary,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_rounded, size: 18, color: AppColors.primaryColor),
            ],
          ],
        ),
      ),
    );
  }
}
