import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/pack_model.dart';
import '../../core/config/api_config.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/helpers.dart';
import '../shared_widgets/gradient_button.dart';

class PackDetailScreen extends StatefulWidget {
  final Pack pack;
  const PackDetailScreen({super.key, required this.pack});

  @override
  State<PackDetailScreen> createState() => _PackDetailScreenState();
}

class _PackDetailScreenState extends State<PackDetailScreen> {
  bool _isDescriptionExpanded = false;

  @override
  Widget build(BuildContext context) {
    final discountPercent = widget.pack.totalPrice > widget.pack.discountPrice
        ? (((widget.pack.totalPrice - widget.pack.discountPrice) / widget.pack.totalPrice) * 100).round()
        : 0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              title: Text(widget.pack.name),
              backgroundColor: Colors.white,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
              pinned: true,
              floating: false,
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Products Images Section
                  _buildProductsImagesSection(),

                  // Pack Info Card
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pack Name
                        Text(
                          widget.pack.name,
                          style: AppTextStyles.h2.copyWith(fontSize: 22),
                        ),
                        const SizedBox(height: 12),

                        // Price Section
                        Row(
                          children: [
                            // Discount Price
                                Text(
                                  '${widget.pack.discountPrice.toStringAsFixed(0)} DZD',
                              style: AppTextStyles.h2.copyWith(
                                color: AppColors.primaryOrange,
                                fontSize: 24,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Original Price
                            if (discountPercent > 0) ...[
                                  Text(
                                    '${widget.pack.totalPrice.toStringAsFixed(0)} DZD',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color: AppColors.textHint,
                                  fontSize: 16,
                                ),
                              ),
                            ],

                            const Spacer(),

                            // Discount Badge
                            if (discountPercent > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryOrange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                      'Save $discountPercent%',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.primaryOrange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Products Count
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.scaffoldBackground,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.inventory_2_outlined, color: AppColors.primaryBlue),
                              const SizedBox(width: 8),
                                  Text(
                                    'Contains ${widget.pack.products.length} products',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Products List
                  _buildProductsList(),

                  const SizedBox(height: 8),

                  // Description
                  if (widget.pack.description.isNotEmpty) _buildDescriptionSection(),

                  const SizedBox(height: 8),

                  // Merchant Info
                  _buildMerchantSection(),

                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ],
        ),

        // Bottom Action Bar
        bottomNavigationBar: _buildBottomBar(discountPercent),
      ),
    );
  }

  Widget _buildProductsImagesSection() {
    final images = widget.pack.products
        .where((p) => p.productImage.isNotEmpty)
        .map((p) => ApiConfig.getImageUrl(p.productImage))
        .where((url) => url.isNotEmpty)
        .take(4)
        .toList();

    if (images.isEmpty) {
      return Container(
        height: 250,
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.inventory_2, size: 80, color: Colors.grey),
        ),
      );
    }

    return Container(
      height: 250,
      color: Colors.white,
      child: images.length == 1
          ? Image.network(
              images[0],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.image, size: 60, color: Colors.grey),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.2,
              ),
              itemCount: images.length > 4 ? 4 : images.length,
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    images[index],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, size: 40, color: Colors.grey),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildProductsList() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              Text(
                'Included Products',
            style: AppTextStyles.h3.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 16),
          ...widget.pack.products.map((product) => _buildProductItem(product)),
        ],
      ),
    );
  }

  Widget _buildProductItem(PackProduct product) {
    final imageUrl = ApiConfig.getImageUrl(product.productImage);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 60,
              height: 60,
              color: Colors.grey[200],
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.image, color: Colors.grey),
                    )
                  : const Icon(Icons.image, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 12),

          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${product.productPrice.toStringAsFixed(0)} DZD',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          // Quantity
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'x${product.quantity}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              Text(
                'Description',
            style: AppTextStyles.h3.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 12),
          Text(
            widget.pack.description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            maxLines: _isDescriptionExpanded ? null : 3,
            overflow: _isDescriptionExpanded ? null : TextOverflow.ellipsis,
          ),
          if (widget.pack.description.length > 100)
            TextButton(
              onPressed: () {
                setState(() {
                  _isDescriptionExpanded = !_isDescriptionExpanded;
                });
              },
                  child: Text(_isDescriptionExpanded ? 'Show less' : 'Show more'),
            ),
        ],
      ),
    );
  }

  Widget _buildMerchantSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              Text(
                'Merchant Info',
            style: AppTextStyles.h3.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () {
              Navigator.pushNamed(
                context,
                Routes.store,
                arguments: widget.pack.merchantId,
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.scaffoldBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.store, color: AppColors.primaryBlue, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.pack.merchantName,
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Icon(Icons.arrow_back_ios, size: 16, color: AppColors.textHint),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(int discountPercent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Price Summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                        Text(
                          'Total Price',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                              '${widget.pack.discountPrice.toStringAsFixed(0)} DZD',
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.primaryOrange,
                            fontSize: 20,
                          ),
                        ),
                        if (discountPercent > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                                '${widget.pack.totalPrice.toStringAsFixed(0)} DZD',
                            style: AppTextStyles.bodySmall.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                    text: 'Contact Merchant',
                onPressed: () {
                      Helpers.showSnackBar(context, 'You can contact the merchant to purchase this pack');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
