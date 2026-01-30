import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../network_image_with_loader.dart';

/// Primary vertical product card (140x220)
/// From lib design system
class PrimaryProductCard extends StatelessWidget {
  final String image;
  final String brandName;
  final String title;
  final double price;
  final double? priceAfterDiscount;
  final int? discountPercent;
  final VoidCallback press;

  const PrimaryProductCard({
    super.key,
    required this.image,
    required this.brandName,
    required this.title,
    required this.price,
    this.priceAfterDiscount,
    this.discountPercent,
    required this.press,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: press,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(
          AppConstants.productCardWidth,
          AppConstants.productCardHeight,
        ),
        maximumSize: const Size(
          AppConstants.productCardWidth,
          AppConstants.productCardHeight,
        ),
        padding: const EdgeInsets.all(8),
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1.15,
            child: Stack(
              children: [
                NetworkImageWithLoader(
                  image,
                  radius: AppConstants.defaultBorderRadius,
                ),
                if (discountPercent != null)
                  Positioned(
                    right: AppConstants.spacing8,
                    top: AppConstants.spacing8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacing8,
                      ),
                      height: 16,
                      decoration: const BoxDecoration(
                        color: AppColors.errorRed,
                        borderRadius: BorderRadius.all(
                          Radius.circular(AppConstants.defaultBorderRadius),
                        ),
                      ),
                      child: Text(
                        "$discountPercent% off",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacing8,
                vertical: AppConstants.spacing8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    brandName.toUpperCase(),
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 10,
                        ),
                  ),
                  const SizedBox(height: AppConstants.spacing8),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          fontSize: 12,
                        ),
                  ),
                  const Spacer(),
                  priceAfterDiscount != null
                      ? Row(
                          children: [
                            Text(
                              "\$${priceAfterDiscount!.toStringAsFixed(2)}",
                              style: const TextStyle(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: AppConstants.spacing4),
                            Text(
                              "\$${price.toStringAsFixed(2)}",
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .color,
                                fontSize: 10,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          "\$${price.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
