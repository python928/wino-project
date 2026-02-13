import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routing/routes.dart';
import '../../data/models/offer_model.dart';

class PromotionDetailScreen extends StatelessWidget {
  final Offer promotion;

  const PromotionDetailScreen({super.key, required this.promotion});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Promotion Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            if (promotion.product.images.isNotEmpty)
              Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(promotion.product.images.first.url),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            
            SizedBox(height: 20),
            
            // Product name
            Text(
              promotion.product.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            SizedBox(height: 16),
            
            // Pricing information
            Row(
              children: [
                Text(
                  '\$${promotion.product.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  '\$${promotion.newPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
                SizedBox(width: 12),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${promotion.discountPercentage.toInt()}% OFF',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 24),
            
            // Store information
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                  child: Icon(Icons.store, color: AppColors.primaryColor, size: 16),
                ),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      Routes.store,
                      arguments: promotion.product.storeId,
                    );
                  },
                  child: Text(
                    promotion.product.storeName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryColor,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 24),
            
            // Description
            if (promotion.product.description.isNotEmpty) ...[
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                promotion.product.description,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}