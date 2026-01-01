import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';

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
    this.hintText = 'ابحث عن المنتجات، المتاجر...',
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing20),
      child: Row(
        children: [
          // Filter Button
          Container(
            height: 55,
            width: 55,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: AppTheme.mediumRadius,
              boxShadow: AppColors.primaryShadow,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onFilterTap,
                borderRadius: AppTheme.mediumRadius,
                child: const Icon(
                  Icons.tune_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),

          const SizedBox(width: AppTheme.spacing12),

          // Search Field
          Expanded(
            child: isActive
                ? Container(
                    height: 55,
                    decoration: BoxDecoration(
                      color: AppColors.searchBarBackground,
                      borderRadius: AppTheme.mediumRadius,
                    ),
                    child: TextField(
                      controller: controller,
                      onChanged: onSearchChanged,
                      onSubmitted: (_) => onSearchSubmitted?.call(),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: hintText,
                        hintStyle: AppTextStyles.hintText,
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: AppColors.textHint,
                          size: 28,
                        ),
                        suffixIcon: controller != null && controller!.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: AppColors.textHint),
                                onPressed: () {
                                  controller!.clear();
                                  onSearchChanged?.call('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  )
                : GestureDetector(
                    onTap: onSearchTap,
                    child: Container(
                      height: 55,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing16,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.searchBarBackground,
                        borderRadius: AppTheme.mediumRadius,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: AppColors.textHint,
                            size: 28,
                          ),
                          const SizedBox(width: AppTheme.spacing12),
                          Expanded(
                            child: Text(
                              hintText,
                              style: AppTextStyles.hintText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
