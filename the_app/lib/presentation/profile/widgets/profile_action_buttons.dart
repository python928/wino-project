import 'package:flutter/material.dart';
import 'package:dzlocal_shop/core/extensions/l10n_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_constants.dart';


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
            child: PopupMenuButton<String>(
              onSelected: onPostMenuSelection,
              offset: const Offset(0, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.white,
              elevation: 8,
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'product',
                  child: Row(
                    children: [
                      Icon(Icons.shopping_bag_outlined, color: Colors.grey[700], size: 20),
                      const SizedBox(width: 12),
                      Text(context.tr('New Product'),
                          style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'discount',
                  child: Row(
                    children: [
                      Icon(Icons.percent, color: Colors.grey[700], size: 20),
                      const SizedBox(width: 12),
                      Text(context.tr('Discount'),
                          style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'pack',
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, color: Colors.grey[700], size: 20),
                      const SizedBox(width: 12),
                      Text(context.tr('Pack'),
                          style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppConstants.spacing14),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: AppConstants.spacing20, color: Colors.white),
                    SizedBox(width: AppConstants.spacing8),
                    Text(
                      'Publish Post',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
