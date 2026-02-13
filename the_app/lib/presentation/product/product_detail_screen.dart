import 'package:flutter/material.dart';
import '../../data/models/post_model.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';

class ProductDetailScreen extends StatelessWidget {
  final Post product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Product Details'),
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
            if (product.images.isNotEmpty)
              Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(product.images.first.url),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            
            SizedBox(height: 20),
            
            // Product name
            Text(
              product.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            SizedBox(height: 16),
            
            // Price information
            Text(
              '\$${product.price.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
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
                      arguments: product.storeId,
                    );
                  },
                  child: Text(
                    product.storeName,
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
            if (product.description.isNotEmpty) ...[
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                product.description,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
