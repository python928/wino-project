import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';

/// Custom bottom navigation bar with 5 items (lib design system)
/// Modern outline icons with purple theme
class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final int? notificationsBadgeCount;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    this.notificationsBadgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: AppConstants.spacing8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onItemTapped,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 12,
        selectedItemColor: AppColors.primaryColor,  // Purple
        unselectedItemColor: AppColors.greyColor,  // Grey (not transparent - so icons show)
        elevation: 0,
        showUnselectedLabels: true,
        items: [
          // Home - Index 0
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, size: 24, color: selectedIndex == 0 ? AppColors.primaryColor : AppColors.greyColor),
            label: 'Home',
          ),
          // Favorites - Index 1
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline, size: 24, color: selectedIndex == 1 ? AppColors.primaryColor : AppColors.greyColor),
            label: 'Saved',
          ),
          // My Stores (Followed) - Index 2
          BottomNavigationBarItem(
            icon: Icon(Icons.store_outlined, size: 24, color: selectedIndex == 2 ? AppColors.primaryColor : AppColors.greyColor),
            label: 'My Stores',
          ),
          // Profile - Index 3
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded, size: 24, color: selectedIndex == 3 ? AppColors.primaryColor : AppColors.greyColor),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

}
