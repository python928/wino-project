import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/post_provider.dart';
import '../shared_widgets/custom_app_bar.dart';
import '../home/widgets/hot_deal_card.dart';
import '../shared_widgets/empty_state_widget.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<PostProvider>(
      builder: (context, postProvider, child) {
        final hotDeals = postProvider.posts.where((post) => post.isHotDeal).toList();

        return Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          appBar: const CustomAppBar(
            title: 'Hot Deals',
            showBackButton: false,
          ),
          body: hotDeals.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.local_offer_outlined,
              title: 'No offers currently',
              message: 'We will notify you when new offers are available',
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timer Section
                  Container(
                    margin: const EdgeInsets.all(AppTheme.spacing20),
                    padding: const EdgeInsets.all(AppTheme.spacing20),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: AppTheme.largeRadius,
                      boxShadow: AppColors.primaryShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.local_fire_department,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacing16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Offers end in',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  _buildTimerBox('02'),
                                  _buildTimerSeparator(),
                                  _buildTimerBox('45'),
                                  _buildTimerSeparator(),
                                  _buildTimerBox('30'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Section Title
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing20,
                    ),
                    child: Text(
                      'All Offers',
                      style: AppTextStyles.h2,
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacing16),

                  // Offers Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing20,
                    ),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      mainAxisSpacing: AppTheme.spacing16,
                      crossAxisSpacing: AppTheme.spacing16,
                    ),
                    itemCount: hotDeals.length,
                    itemBuilder: (context, index) {
                      return HotDealCard(
                        product: hotDeals[index],
                        onTap: () {},
                      );
                    },
                  ),

                  const SizedBox(height: AppTheme.spacing32),
                ],
              ),
            ),
    );
      },
    );
  }

  Widget _buildTimerBox(String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        time,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildTimerSeparator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        ':',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }
}
