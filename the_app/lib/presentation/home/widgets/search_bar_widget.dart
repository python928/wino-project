import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
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
                : GestureDetector(
                    onTap: onSearchTap,
                    behavior: HitTestBehavior.opaque,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.neutral50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              color: AppColors.textSecondary,
                              size: 26,
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
                              color: AppColors.textSecondary,
                              size: 26,
                            ),
                        ],
                      ),
                    ),
                  ),
                  ),
          ),
        ],
      ),
    );
  }
}
