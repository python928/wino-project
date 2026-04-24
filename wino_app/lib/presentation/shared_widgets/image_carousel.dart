import 'package:flutter/material.dart';

class ImageCarousel extends StatefulWidget {
  final List<String> images;
  final double height;
  final double borderRadius;
  final Widget? topRightOverlay;
  final Widget? topLeftOverlay;
  final bool showIndicators;
  final BoxFit fit;

  const ImageCarousel({
    super.key,
    required this.images,
    required this.height,
    this.borderRadius = 12,
    this.topRightOverlay,
    this.topLeftOverlay,
    this.showIndicators = true,
    this.fit = BoxFit.cover,
  });

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    final hasImages = images.isNotEmpty && images.first.isNotEmpty;
    final showDots =
        widget.showIndicators && hasImages && images.length > 1;

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: hasImages
                  ? PageView.builder(
                      itemCount: images.length,
                      onPageChanged: (index) {
                        setState(() => _currentIndex = index);
                      },
                      itemBuilder: (context, index) => Image.network(
                        images[index],
                        fit: widget.fit,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      ),
                    )
                  : _buildPlaceholder(),
            ),
          ),
          if (showDots)
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentIndex == index ? 18 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentIndex == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          if (widget.topRightOverlay != null)
            Positioned(top: 12, right: 12, child: widget.topRightOverlay!),
          if (widget.topLeftOverlay != null)
            Positioned(top: 12, left: 12, child: widget.topLeftOverlay!),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      alignment: Alignment.center,
      child: const Icon(Icons.image),
    );
  }
}
