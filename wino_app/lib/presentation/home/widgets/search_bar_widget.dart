import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_text_field.dart';

class SearchBarWidget extends StatelessWidget {
  final VoidCallback? onSearchTap;
  final VoidCallback? onFilterTap;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchSubmitted;
  final TextEditingController? controller;
  final String hintText;
  final bool isActive;

  const SearchBarWidget({
    super.key,
    this.onSearchTap,
    this.onFilterTap,
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.controller,
    this.hintText = 'Search for products, stores...',
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing20),
      child: Row(
        children: [
          Expanded(
            child: isActive && controller != null
                ? AppSearchField(
                    controller: controller!,
                    hintText: hintText,
                    onChanged: onSearchChanged,
                    onSubmitted: onSearchSubmitted,
                    onFilterTap: onFilterTap,
                    showFilterButton: true,
                  )
                : _buildReadOnlySearchBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlySearchBar() {
    return GestureDetector(
      onTap: onSearchTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.searchBarBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.search, color: AppColors.textSecondary.withOpacity(0.5), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hintText,
                style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.6),
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onFilterTap != null)
              GestureDetector(
                onTap: onFilterTap,
                child: Icon(Icons.tune_rounded, color: AppColors.textSecondary.withOpacity(0.3), size: 20),
              ),
          ],
        ),
      ),
    );
  }
}
