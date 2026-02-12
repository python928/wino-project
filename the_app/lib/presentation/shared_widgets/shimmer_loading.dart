import 'package:flutter/material.dart';
import '../common/constants/card_constants.dart';

/// Shimmer effect widget for loading states
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.isLoading = true,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) return widget.child;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0xFFEBEBEB),
                Color(0xFFF5F5F5),
                Color(0xFFEBEBEB),
              ],
              stops: [
                (_animation.value - 1).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 1).clamp(0.0, 1.0),
              ],
              transform: GradientRotation(_animation.value),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

/// Shimmer placeholder box
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Product card skeleton for loading state
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.hasBoundedWidth ? constraints.maxWidth : 160.0;
        final isSmall = w < 100;

        final padding = isSmall ? 6.0 : 12.0;
        final titleHeight = isSmall ? 10.0 : 16.0;
        final priceHeight = isSmall ? 9.0 : 14.0;
        final ratingHeight = isSmall ? 8.0 : 12.0;
        final gap = isSmall ? 4.0 : 8.0;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder (square)
              ShimmerBox(height: w, borderRadius: 16),
              Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(height: titleHeight, width: isSmall ? w * 0.7 : 100),
                    SizedBox(height: gap),
                    ShimmerBox(height: priceHeight, width: isSmall ? w * 0.45 : 60),
                    SizedBox(height: gap),
                    Row(
                      children: [
                        ShimmerBox(height: ratingHeight, width: isSmall ? w * 0.35 : 40),
                        SizedBox(width: isSmall ? 4 : 8),
                        ShimmerBox(height: ratingHeight, width: isSmall ? w * 0.25 : 30),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Store card skeleton for loading state
class StoreCardSkeleton extends StatelessWidget {
  const StoreCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cover image placeholder
          const ShimmerBox(height: 60, borderRadius: 0),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar placeholder
                const ShimmerBox(height: 40, width: 40, borderRadius: 20),
                const SizedBox(height: 6),
                // Name placeholder
                const ShimmerBox(height: 12, width: 70),
                const SizedBox(height: 4),
                // Category placeholder
                const ShimmerBox(height: 10, width: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Grid of product skeletons
class ProductGridSkeleton extends StatelessWidget {
  final int itemCount;

  const ProductGridSkeleton({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: CardConstants.gridHorizontalPadding,
          vertical: CardConstants.gridVerticalPadding,
        ),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: CardConstants.gridCrossAxisCount,
          crossAxisSpacing: CardConstants.gridCrossAxisSpacing,
          mainAxisSpacing: CardConstants.gridMainAxisSpacing,
          childAspectRatio: CardConstants.gridChildAspectRatio,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) => const ProductCardSkeleton(),
      ),
    );
  }
}

/// Horizontal list of store skeletons
class StoreListSkeleton extends StatelessWidget {
  final int itemCount;

  const StoreListSkeleton({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: SizedBox(
        height: 150,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: itemCount,
          itemBuilder: (context, index) => const StoreCardSkeleton(),
        ),
      ),
    );
  }
}
