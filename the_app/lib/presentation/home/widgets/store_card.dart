import 'package:flutter/material.dart';
// carousel import removed - not used
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/card_styles.dart';
import '../../../data/dummy/store_model.dart';
import '../../../core/utils/helpers.dart';

class StoreCard extends StatelessWidget {
  final Store store;
  final VoidCallback? onTap;

  const StoreCard({
    super.key,
    required this.store,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: CardStyles.standard(),
        child: Row(
          children: [
            // Arrow Icon
            Icon(
              Icons.arrow_back_ios_new,
              size: 16,
              color: AppColors.textHint,
            ),
            
            const Spacer(),
            
            // Store Info
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Store Name
                  Text(
                    store.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // Category
                  Text(
                    store.category,
                    style: AppTextStyles.bodySmall,
                  ),
                  
                  const SizedBox(height: AppTheme.spacing8),
                  
                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Rating
                      Icon(
                        Icons.star,
                        size: 14,
                        color: AppColors.ratingYellow,
                      ),
                      Text(
                        ' ${Helpers.formatRating(store.rating)} ',
                        style: AppTextStyles.ratingText,
                      ),
                      
                      const SizedBox(width: AppTheme.spacing8),
                      
                      // Followers
                      Icon(
                        Icons.people_outline,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      Text(
                        ' ${Helpers.formatLargeNumber(store.followers)} ',
                        style: AppTextStyles.bodySmall,
                      ),
                      
                      const SizedBox(width: AppTheme.spacing8),
                      
                      // Distance
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      Text(
                        ' ${Helpers.formatDistance(store.distance)}',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: AppTheme.spacing12),
            
            // Store Image with Status Indicator
            Stack(
              children: [
                ClipRRect(
                  borderRadius: AppTheme.mediumRadius,
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: Image.network(
                      store.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[200],
                          alignment: Alignment.center,
                          child: const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          alignment: Alignment.center,
                          child: const Icon(Icons.store, size: 26, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                ),
                
                // Online Status Indicator
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: store.isOpen 
                          ? AppColors.successGreen 
                          : AppColors.textHint,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
