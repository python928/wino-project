import 'package:flutter/material.dart';
import '../../../core/widgets/app_toggle_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/theme/app_colors.dart';

/// Filter widget for profile posts with toggle buttons
class ProfilePostFilter extends StatelessWidget {
  final int selectedIndex;
  final int postsCount;
  final ValueChanged<int> onFilterChanged;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;

  const ProfilePostFilter({
    super.key,
    required this.selectedIndex,
    required this.postsCount,
    required this.onFilterChanged,
    this.searchController,
    this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Posts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.blackColor5,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  postsCount.toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search field (if provided)
          if (searchController != null) ...[
            AppSearchField(
              controller: searchController!,
              hintText: 'Search my posts...',
              onChanged: onSearchChanged,
              compact: true,
            ),
            const SizedBox(height: 16),
          ],
          // Toggle buttons
          AppToggleButtonGroup(
            options: const [
              ToggleOption(
                label: 'All',
                value: 'all',
              ),
              ToggleOption(
                label: 'Products',
                value: 'product',
              ),
              ToggleOption(
                label: 'Discounts',
                value: 'promotion',
              ),
              ToggleOption(
                label: 'Packs',
                value: 'pack',
              ),
            ],
            selectedIndex: selectedIndex,
            onChanged: onFilterChanged,
            scrollable: true,
            compact: true,
            showBorder: false,
          ),
        ],
      ),
    );
  }
}
