import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haptic_feedback/haptic_feedback.dart';

import '../theme/app_colors.dart';

/// Premium UI Components Collection for DZ Local
/// Luxury shopping experience with advanced animations and interactions
class PremiumUIComponents {
  // ===== PREMIUM BUTTONS =====

  /// Luxury Gold Button with glow effect and haptic feedback
  static Widget luxuryGoldButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
    IconData? icon,
    double? width,
  }) {
    return GestureDetector(
      onTap: () async {
        await Haptics.vibrate(HapticsType.medium);
        onPressed();
      },
      child: Container(
        width: width ?? double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: AppColors.purpleGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.purpleShadow,
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.neutralLightest,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        color: AppColors.neutralLightest,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      text,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutralLightest,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  /// Neumorphic Button with premium feel
  static Widget neumorphicButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    Color? color,
  }) {
    return NeumorphicButton(
      onPressed: () async {
        await Haptics.vibrate(HapticsType.light);
        onPressed();
      },
      style: NeumorphicStyle(
        shape: NeumorphicShape.flat,
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(16)),
        depth: 4,
        intensity: 0.8,
        surfaceIntensity: 0.1,
        lightSource: LightSource.topLeft,
        color: color ?? AppColors.surfacePrimary,
        shadowLightColor: AppColors.neutralLightest,
        shadowDarkColor: AppColors.neutralMedium.withOpacity(0.3),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: AppColors.neutralDarkest,
              size: 20,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.neutralDarkest,
            ),
          ),
        ],
      ),
    );
  }

  // ===== PREMIUM CARDS =====

  /// Luxury Product Card with advanced animations
  static Widget luxuryProductCard({
    required String title,
    required String price,
    required String imageUrl,
    String? originalPrice,
    String? discount,
    required VoidCallback onTap,
    bool isFavorite = false,
    VoidCallback? onFavoriteToggle,
    int animationIndex = 0,
  }) {
    return AnimationConfiguration.staggeredList(
      position: animationIndex,
      duration: const Duration(milliseconds: 600),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: GestureDetector(
            onTap: () async {
              await Haptics.vibrate(HapticsType.selection);
              onTap();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfacePrimary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppColors.elevatedShadow,
                border: Border.all(
                  color: AppColors.borderSecondary,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Section with favorite button
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: AppColors.surfaceTertiary,
                              child: const Icon(
                                Icons.image_not_supported,
                                color: AppColors.neutralMedium,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Favorite Button
                      Positioned(
                        top: 12,
                        right: 12,
                        child: GestureDetector(
                          onTap: () async {
                            await Haptics.vibrate(HapticsType.light);
                            onFavoriteToggle?.call();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.surfacePrimary.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: AppColors.primaryShadow,
                            ),
                            child: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite
                                  ? AppColors.errorRed
                                  : AppColors.neutralMedium,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      // Discount Badge
                      if (discount != null)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.errorRed,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              discount,
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.neutralLightest,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Content Section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.neutralDarkest,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              price,
                              style: GoogleFonts.cairo(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryGold,
                              ),
                            ),
                            if (originalPrice != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                originalPrice,
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.neutralMedium,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

    );
  }

  /// Glassmorphic Card with backdrop blur
  static Widget glassmorphicCard({
    required Widget child,
    double? width,
    double? height,
    EdgeInsets? padding,
    EdgeInsets? margin,
  }) {
    return Container(
      width: width,
      height: height,
      margin: margin ?? const EdgeInsets.all(16),
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.glassPrimary,
            AppColors.glassSecondary,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.neutralLightest.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: AppColors.elevatedShadow,
      ),
      child: child,
    );
  }

  // ===== PREMIUM LOADING ANIMATIONS =====

  /// Loading Animation
  static Widget lottieLoading({
    String? assetPath,
    double size = 100,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation<Color>(
          AppColors.primaryGold,
        ),
      ),
    );
  }

  /// Animated Icon Placeholder
  static Widget riveAnimation({
    required String assetPath,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.animation,
        color: AppColors.primaryGold,
        size: 48,
      ),
    );
  }

  // ===== PREMIUM SEARCH BAR =====

  /// Luxury Search Bar with animations
  static Widget luxurySearchBar({
    required String hintText,
    required Function(String) onChanged,
    VoidCallback? onFilterTap,
    TextEditingController? controller,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.primaryShadow,
        border: Border.all(
          color: AppColors.borderSecondary,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: AppColors.neutralDarkest,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: GoogleFonts.cairo(
                  fontSize: 16,
                  color: AppColors.neutralMedium,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.neutralMedium,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ),
          if (onFilterTap != null)
            GestureDetector(
              onTap: () async {
                await Haptics.vibrate(HapticsType.light);
                onFilterTap();
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.tune,
                  color: AppColors.primaryGold,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ===== PREMIUM BOTTOM SHEET =====

  /// Luxury Bottom Sheet with custom design
  static Future<T?> showLuxuryBottomSheet<T>({
    required BuildContext context,
    required Widget child,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surfacePrimary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: AppColors.elevatedShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutralMedium,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }

  /// Featured Product Card with gradient background
  static Widget featuredProductCard({
    required String imageUrl,
    required String title,
    required String price,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          gradient: AppColors.featuredGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    price,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: AppColors.primaryLightShade,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
