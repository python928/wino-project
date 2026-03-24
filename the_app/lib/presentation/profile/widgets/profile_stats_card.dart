import 'package:dzlocal_shop/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_constants.dart';
import '../../../core/theme/card_styles.dart';

/// Stats card widget showing followers, rating, and products count
class ProfileStatsCard extends StatelessWidget {
  final int followersCount;
  final double averageRating;
  final int productsCount;

  const ProfileStatsCard({
    super.key,
    required this.followersCount,
    required this.averageRating,
    required this.productsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacing20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppConstants.spacing16),
        decoration: CardStyles.standard(),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                icon: Icons.people_outline,
                value: _formatCount(followersCount),
                label: context.tr('Followers'),
              ),
            ),
            Container(width: 1, height: 40, color: Colors.grey[200]),
            Expanded(
              child: _buildStatItem(
                icon: Icons.star_outline,
                value: averageRating > 0
                    ? averageRating.toStringAsFixed(1)
                    : '0.0',
                label: context.tr('Rating'),
              ),
            ),
            Container(width: 1, height: 40, color: Colors.grey[200]),
            Expanded(
              child: _buildStatItem(
                icon: Icons.inventory_2_outlined,
                value: productsCount.toString(),
                label: context.tr('Products'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, size: AppConstants.iconMedium, color: Colors.grey[600]),
        const SizedBox(height: AppConstants.spacing8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
