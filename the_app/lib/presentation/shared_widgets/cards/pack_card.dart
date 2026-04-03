import 'package:flutter/material.dart';
import '../../../core/config/api_config.dart';
import '../../../core/routing/routes.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/pack_model.dart';
import '../../../core/widgets/cards/base_item_card.dart';
import '../../common/widgets/stacked_product_images.dart';

/// Pack Card inheriting from BaseItemCard
/// Displays packs with custom image widget and specialized content
class PackCard extends BaseItemCard {
  final Pack pack;
  final double? userLat;
  final double? userLng;
  final bool showStoreName;

  PackCard({
    super.key,
    required this.pack,
    this.userLat,
    this.userLng,
    this.showStoreName = true,
    VoidCallback? onTap,
    VoidCallback? onEditTap,
    bool isUnavailable = false,
    bool showUnavailableOverlay = false,
  }) : super(
          title: pack.name,
          imageUrl: _pickImage(pack),
          customImageWidget: pack.products.isNotEmpty
              ? StackedProductImages(products: pack.products)
              : null,
          price: pack.discountPrice,
          oldPrice:
              pack.totalPrice > pack.discountPrice ? pack.totalPrice : null,
          discountPercentage: _calculateDiscountPercent(pack),
          customBadge: _buildBadge(pack),
          rating: pack.merchantId > 0 ? pack.merchantRating : null,
          reviewCount:
              pack.merchantReviewCount > 0 ? pack.merchantReviewCount : null,
          bottomLeftText:
              _buildLocationText(pack, showStoreName, userLat, userLng),
          bottomLeftIcon: showStoreName ? Icons.location_on_outlined : null,
          isUnavailable: isUnavailable,
          showUnavailableOverlay: showUnavailableOverlay,
          onTap: onTap,
          onEditTap: onEditTap,
        );

  static String? _pickImage(Pack pack) {
    if (pack.products.isEmpty) return null;
    final image = pack.products.first.productImage;
    if (image.trim().isEmpty || image == 'null') return null;

    final fullImageUrl = ApiConfig.getImageUrl(image);
    if (fullImageUrl.isEmpty) return null;
    return fullImageUrl;
  }

  static int? _calculateDiscountPercent(Pack pack) {
    if (pack.totalPrice <= 0 || pack.discountPrice >= pack.totalPrice) {
      return null;
    }
    return ((pack.totalPrice - pack.discountPrice) / pack.totalPrice * 100)
        .round();
  }

  static String? _buildBadge(Pack pack) {
    final discountPercent = _calculateDiscountPercent(pack);
    if (discountPercent != null && discountPercent > 0) {
      return 'Pack -$discountPercent%';
    }
    return 'Pack';
  }

  static String? _buildLocationText(
    Pack pack,
    bool showStoreName,
    double? userLat,
    double? userLng,
  ) {
    if (!showStoreName) return null;

    final dist = Helpers.haversineDistance(
      userLat,
      userLng,
      pack.merchantLatitude,
      pack.merchantLongitude,
    );
    if (dist != null) return Helpers.formatDistance(dist);

    if (pack.merchantAddress.trim().isNotEmpty) return pack.merchantAddress;
    if (pack.merchantName.trim().isNotEmpty) return pack.merchantName;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BaseItemCard(
      title: title,
      imageUrl: imageUrl,
      customImageWidget: customImageWidget,
      price: price,
      oldPrice: oldPrice,
      discountPercentage: discountPercentage,
      customBadge: customBadge,
      rating: rating,
      reviewCount: reviewCount,
      bottomLeftText: bottomLeftText,
      bottomLeftIcon: bottomLeftIcon,
      isUnavailable: isUnavailable,
      showUnavailableOverlay: showUnavailableOverlay,
      onTap: onTap ??
          () {
            Navigator.pushNamed(context, Routes.packDetails, arguments: pack);
          },
      onEditTap: onEditTap,
      onBottomLeftTap: pack.merchantId > 0
          ? () {
              Navigator.pushNamed(context, Routes.store,
                  arguments: pack.merchantId);
            }
          : null,
    );
  }
}
