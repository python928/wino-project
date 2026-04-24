import 'package:flutter/material.dart';

import '../theme/app_constants.dart';

/// Skeleton loading placeholder (rectangular)
/// From lib design system
class Skeleton extends StatelessWidget {
  final double? height;
  final double? width;
  final int layer;
  final double radius;

  const Skeleton({
    super.key,
    this.height,
    this.width,
    this.layer = 1,
    this.radius = AppConstants.defaultBorderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      padding: const EdgeInsets.all(AppConstants.defaultPadding / 2),
      decoration: BoxDecoration(
        color: Theme.of(context).iconTheme.color!.withOpacity(0.04 * layer),
        borderRadius: BorderRadius.all(Radius.circular(radius)),
      ),
    );
  }
}

/// Circular skeleton loading placeholder
/// From lib design system
class CircleSkeleton extends StatelessWidget {
  final double size;

  const CircleSkeleton({
    super.key,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: Theme.of(context).iconTheme.color!.withOpacity(0.04),
        shape: BoxShape.circle,
      ),
    );
  }
}
