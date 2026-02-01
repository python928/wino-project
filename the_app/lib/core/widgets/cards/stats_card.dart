import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/card_styles.dart';
import '../../theme/card_dimensions.dart';

/// Unified card for displaying statistics and info metrics
/// Used in profile screen, store screen, statistics screen, etc.
class StatsCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final Color? valueColor;
  final VoidCallback? onTap;
  final bool isCompact;

  const StatsCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
    this.valueColor,
    this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      height: isCompact ? 70 : CardDimensions.statsCardHeight,
      padding: EdgeInsets.all(CardDimensions.cardPadding),
      decoration: CardStyles.standard(),
      child: isCompact ? _buildCompactLayout() : _buildStandardLayout(),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }

  Widget _buildStandardLayout() {
    return Row(
      children: [
        // Icon
        if (icon != null) ...[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (iconColor ?? AppColors.primaryColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: iconColor ?? AppColors.primaryColor,
              size: CardDimensions.iconLarge,
            ),
          ),
          SizedBox(width: CardDimensions.cardElementSpacing),
        ],

        // Value and Label
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // Arrow icon if tappable
        if (onTap != null)
          Icon(
            Icons.arrow_forward_ios,
            size: CardDimensions.iconSmall,
            color: Colors.grey[400],
          ),
      ],
    );
  }

  Widget _buildCompactLayout() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Icon
        if (icon != null) ...[
          Icon(
            icon,
            color: iconColor ?? AppColors.primaryColor,
            size: CardDimensions.iconMedium,
          ),
          const SizedBox(height: 4),
        ],

        // Value
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 2),

        // Label
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
