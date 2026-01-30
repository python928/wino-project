import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_constants.dart';
import '../../../core/theme/app_decorations.dart';
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
    this.hintText = 'Search for products, stores...',
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing20),
      child: Row(
        children: [
          // Search Field (outlined style like screenshots - full width)
          Expanded(
            child: isActive
                ? Container(
                    height: 55,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(27.5),  // Pill shape
                      border: Border.all(
                        color: AppColors.primaryColor,
                        width: 1.5,
                      ),
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
                          color: AppColors.greyColor,
                          size: 24,
                        ),
                        suffixIcon: controller != null && controller!.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: AppColors.textHint),
                                onPressed: () {
                                  controller!.clear();
                                  onSearchChanged?.call('');
                                },
                              )
                            : IconButton(
                                icon: Icon(Icons.tune_rounded, color: AppColors.greyColor),
                                onPressed: onFilterTap,
                              ),
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(27.5),  // Pill shape
                        border: Border.all(
                          color: AppColors.primaryColor,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: AppColors.greyColor,
                            size: 24,
                          ),
                          const SizedBox(width: AppTheme.spacing12),
                          Expanded(
                            child: Text(
                              hintText,
                              style: AppTextStyles.hintText,
                            ),
                          ),
                          Icon(
                            Icons.tune_rounded,
                            color: AppColors.greyColor,
                            size: 24,
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
