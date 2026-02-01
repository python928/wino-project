import 'package:flutter/material.dart';
import '../../../core/widgets/app_toggle_button.dart';
import '../../../core/widgets/app_text_field.dart';

/// Filter widget for profile posts with toggle buttons
class ProfilePostFilter extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onFilterChanged;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;

  const ProfilePostFilter({
    super.key,
    required this.selectedIndex,
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
          const Text(
            'My Posts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
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
                icon: Icons.grid_view_rounded,
                value: 'all',
              ),
              ToggleOption(
                label: 'Products',
                icon: Icons.shopping_bag_outlined,
                value: 'product',
              ),
              ToggleOption(
                label: 'Discounts',
                icon: Icons.percent,
                value: 'promotion',
              ),
              ToggleOption(
                label: 'Packs',
                icon: Icons.inventory_2_outlined,
                value: 'pack',
              ),
            ],
            selectedIndex: selectedIndex,
            onChanged: onFilterChanged,
            scrollable: true,
            compact: true,
          ),
        ],
      ),
    );
  }
}
