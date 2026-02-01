/// Standardized card dimensions for consistent UI across all screens
/// All cards should use these dimensions instead of hardcoded values
class CardDimensions {
  CardDimensions._();

  // ===== ITEM CARDS (Products, Packs, Promotions) =====
  /// Standard width for vertical item cards (products, packs, promotions)
  static const double itemCardWidth = 160.0;
  
  /// Standard height for vertical item cards
  static const double itemCardHeight = 240.0;
  
  /// Image aspect ratio for item cards
  static const double itemImageAspectRatio = 1.0;

  // ===== STORE CARDS =====
  /// Width for vertical store cards
  static const double storeCardVerticalWidth = 160.0;
  
  /// Height for vertical store cards
  static const double storeCardVerticalHeight = 200.0;
  
  /// Height for horizontal store cards
  static const double storeCardHorizontalHeight = 100.0;
  
  /// Store logo/image size
  static const double storeLogoSize = 60.0;

  // ===== INFO/STATS CARDS =====
  /// Height for statistics and info cards
  static const double statsCardHeight = 80.0;
  
  /// Minimum width for stats cards
  static const double statsCardMinWidth = 100.0;

  // ===== COMMON CARD PROPERTIES =====
  /// Standard padding inside cards
  static const double cardPadding = 12.0;
  
  /// Standard border radius for cards
  static const double cardRadius = 12.0;
  
  /// Spacing between card elements
  static const double cardElementSpacing = 8.0;
  
  /// Small spacing for tight layouts
  static const double cardElementSpacingSmall = 4.0;

  // ===== BADGE/OVERLAY SIZES =====
  /// Size for discount badges
  static const double badgeHeight = 24.0;
  
  /// Padding for badges
  static const double badgePadding = 8.0;
  
  /// Font size for badge text
  static const double badgeFontSize = 11.0;

  // ===== ICON SIZES IN CARDS =====
  /// Small icon size (for rating stars, etc.)
  static const double iconSmall = 14.0;
  
  /// Medium icon size
  static const double iconMedium = 18.0;
  
  /// Large icon size
  static const double iconLarge = 24.0;
}
