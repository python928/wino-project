import 'package:flutter/material.dart';
import 'package:wino/core/extensions/l10n_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_constants.dart';
import '../../shared_widgets/app_dropdown_menu.dart';

/// Action buttons for merchant profile (Publish Post + Analytics)
class ProfileActionButtons extends StatelessWidget {
  final Function(String) onPostMenuSelection;

  const ProfileActionButtons({
    super.key,
    required this.onPostMenuSelection,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Publish Post Button with Dropdown
          Expanded(
            flex: 2,
            child: AppDropdownMenuButton<String>(
              onSelected: onPostMenuSelection,
              offset: const Offset(0, 50),
              actions: [
                AppDropdownAction(
                  value: 'product',
                  icon: Icons.shopping_bag_outlined,
                  label: context.tr('New Product'),
                ),
                AppDropdownAction(
                  value: 'discount',
                  icon: Icons.percent,
                  label: context.tr('Discount'),
                ),
                AppDropdownAction(
                  value: 'pack',
                  icon: Icons.inventory_2_outlined,
                  label: context.tr('Pack'),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: AppConstants.spacing14),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMedium),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add,
                        size: AppConstants.spacing20, color: Colors.white),
                    SizedBox(width: AppConstants.spacing8),
                    Text(
                      'Publish Post',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
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
