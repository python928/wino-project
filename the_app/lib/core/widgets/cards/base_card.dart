import 'package:flutter/material.dart';
import '../../theme/card_styles.dart';
import '../../theme/card_dimensions.dart';

/// Abstract base class for all card components
/// Provides consistent wrapper and common functionality
abstract class BaseCard extends StatelessWidget {
  /// Callback when card is tapped
  final VoidCallback? onTap;
  
  /// Custom decoration for the card (optional)
  final BoxDecoration? decoration;
  
  /// Padding inside the card
  final EdgeInsets? padding;
  
  /// Width of the card
  final double? width;
  
  /// Height of the card
  final double? height;

  const BaseCard({
    super.key,
    this.onTap,
    this.decoration,
    this.padding,
    this.width,
    this.height,
  });

  /// Build the card content - must be implemented by subclasses
  Widget buildContent(BuildContext context);

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      width: width,
      height: height,
      padding: padding ?? EdgeInsets.all(CardDimensions.cardPadding),
      decoration: decoration ?? CardStyles.standard(),
      child: buildContent(context),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}
