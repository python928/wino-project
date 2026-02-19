import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/recommendation_item.dart';
import '../providers/analytics_provider.dart';

/// Displays the "Recommended for you" horizontal section.
///
/// Add to home screen:
///   const RecommendationsList()
///
/// - Fetches recommendations on first build (post-frame).
/// - Hides completely when empty or loading fails.
/// - Tapping a card navigates to the store page.
class RecommendationsList extends StatefulWidget {
  const RecommendationsList({super.key});

  @override
  State<RecommendationsList> createState() => _RecommendationsListState();
}

class _RecommendationsListState extends State<RecommendationsList> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AnalyticsProvider>().fetchRecommendations();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalyticsProvider>(
      builder: (context, analytics, _) {
        if (analytics.isLoading) {
          return const SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        if (analytics.recommendations.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recommended for you',
                    style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: analytics.recommendations.length,
                itemBuilder: (context, index) {
                  final raw = analytics.recommendations[index];
                  if (raw is! Map<String, dynamic>) return const SizedBox.shrink();
                  return _RecommendationCard(
                      item: RecommendationItem.fromJson(raw));
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Card widget — horizontal layout: image left, content right
// ---------------------------------------------------------------------------
class _RecommendationCard extends StatelessWidget {
  final RecommendationItem item;
  const _RecommendationCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (item.storeId != null) {
          Navigator.pushNamed(context, Routes.store, arguments: item.storeId);
        }
      },
      child: Container(
        width: 260,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x12000000),
                blurRadius: 8,
                offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            // Image on left
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(16)),
              child: SizedBox(
                width: 90,
                height: 120,
                child: item.imageUrl != null
                    ? Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
              ),
            ),
            // Content on right
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Match reason chip (purple)
                    if (item.matchReasons.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.matchReasons.first,
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 5),
                    // Product name
                    Text(
                      item.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Store name
                    if (item.storeName.isNotEmpty)
                      Text(
                        item.storeName,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const Spacer(),
                    // Price
                    if (!item.hidePrice && item.price != null)
                      Text(
                        '${item.price!.toStringAsFixed(0)} DZD',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.primaryColor,
                        ),
                      )
                    else if (item.hidePrice)
                      Text(
                        'Price on request',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFFF3F4F6),
      alignment: Alignment.center,
      child: Icon(Icons.image_outlined,
          color: Colors.grey.shade400, size: 28),
    );
  }
}
