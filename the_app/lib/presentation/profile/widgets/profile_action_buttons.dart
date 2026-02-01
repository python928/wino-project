import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_constants.dart';
import '../../../core/routing/routes.dart';

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
                      const Text('New Product', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'discount',
                  child: Row(
                    children: [
                      Icon(Icons.percent, color: Colors.grey[700], size: 20),
                      const SizedBox(width: 12),
                      const Text('Discount', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'pack',
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, color: Colors.grey[700], size: 20),
                      const SizedBox(width: 12),
                      const Text('Pack', style: TextStyle(fontSize: 14)),
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
          const SizedBox(width: AppConstants.spacing12),
          // Analytics Button (Outlined)
          Expanded(
            flex: 1,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, Routes.statistics),
              icon: Icon(
                Icons.bar_chart,
                size: AppConstants.spacing18,
                color: AppColors.primaryColor,
              ),
              label: Text(
                'Analytics',
                style: TextStyle(color: AppColors.primaryColor),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.primaryColor),
                padding: const EdgeInsets.symmetric(vertical: AppConstants.spacing14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
