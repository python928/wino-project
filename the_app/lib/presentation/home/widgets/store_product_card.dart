import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/post_model.dart';

class StoreProductCard extends StatelessWidget {
  final Post product;
  final VoidCallback? onTap;

  const StoreProductCard({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.hardEdge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: (product.images.isEmpty)
                    ? Container(
                        color: Colors.grey[100],
                        alignment: Alignment.center,
                        child: const Icon(Icons.image, size: 40, color: Colors.grey),
                      )
                    : Image.network(product.images.first.url, fit: BoxFit.cover),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.h3),
                  const SizedBox(height: AppTheme.spacing4),
                  Text('\$${product.price.toStringAsFixed(2)}', style: AppTextStyles.priceText),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
