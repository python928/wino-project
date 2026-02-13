import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/card_styles.dart';
import '../../../data/models/post_model.dart';
import '../../../core/utils/helpers.dart';

class HotDealCard extends StatelessWidget {
  final Post product;
  final VoidCallback? onTap;

  const HotDealCard({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: CardStyles.standard(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with Discount Badge
            _buildImageSection(),
            
            // Product Info
            _buildInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Stack(
      children: [
        // Image
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: SizedBox(
            height: 120,
            width: double.infinity,
            child: (product.image == null || product.image!.isEmpty)
                ? Container(
                    color: Colors.grey[200],
                    alignment: Alignment.center,
                    child: const Icon(Icons.image, size: 40, color: Colors.grey),
                  )
                : Image.network(
                    product.image!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[200],
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                      );
                    },
                  ),
          ),
        ),
        
        // Discount Badge
        if (product.discountPercentage != null)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${product.discountPercentage}%',
                style: AppTextStyles.discountText,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Name
          Text(
            product.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          
          const SizedBox(height: 4),
          
          // Price Section
          Row(
            children: [
              Text(
                Helpers.formatPrice(product.price),
                style: AppTextStyles.priceText.copyWith(fontSize: 12),
              ),
              const SizedBox(width: 4),
              if (product.oldPrice != null)
                Text(
                  Helpers.formatPrice(product.oldPrice!),
                  style: AppTextStyles.oldPriceText,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
