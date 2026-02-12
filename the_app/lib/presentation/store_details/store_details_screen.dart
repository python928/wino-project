import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../core/routing/routes.dart';
import '../../data/models/store_model.dart';
import 'package:provider/provider.dart';
import '../shared_widgets/gradient_button.dart';
import '../shared_widgets/cards/product_card.dart';
import '../../core/providers/store_provider.dart';
import '../../core/widgets/app_button.dart';
import '../common/constants/card_constants.dart';

class StoreDetailsScreen extends StatefulWidget {
  final Store store;

  const StoreDetailsScreen({super.key, required this.store});

  @override
  State<StoreDetailsScreen> createState() => _StoreDetailsScreenState();
}

class _StoreDetailsScreenState extends State<StoreDetailsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load store data from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoreProvider>().loadStore(widget.store.id);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) Helpers.showSnackBar(context, 'Cannot open phone app');
    }
  }

  void _launchWhatsApp(String phone) async {
    // Remove any non-digit characters and add country code if needed
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (!cleanPhone.startsWith('213')) {
      cleanPhone = '213$cleanPhone';
    }
    final uri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) Helpers.showSnackBar(context, 'Cannot open WhatsApp');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildHeaderSection()),
          _buildTabBar(),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProductsTab(),
                _buildAboutTab(),
                _buildReviewsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share, color: AppColors.textPrimary),
          onPressed: () => Helpers.showSnackBar(context, 'Share store'),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Image.network(
          widget.store.bannerUrl,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) => Container(color: Colors.grey[200]),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(widget.store.imageUrl),
                onBackgroundImageError: (_, __) {},
              ),
              const SizedBox(width: AppTheme.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.store.name, style: AppTextStyles.h1),
                    const SizedBox(height: AppTheme.spacing4),
                    Text(widget.store.category, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          Text(widget.store.description, style: AppTextStyles.bodyMedium, maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: AppTheme.spacing16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSmallStatCard('Products', widget.store.totalProducts.toString()),
              _buildSmallStatCard('Followers', widget.store.followers.toString()),
              _buildSmallStatCard('Rating', widget.store.rating.toStringAsFixed(1)),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildSmallStatCard(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(value, style: AppTextStyles.h2),
        const SizedBox(height: AppTheme.spacing4),
        Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Consumer<StoreProvider>(
      builder: (context, provider, _) {
        final isFollowing = provider.isFollowing;
        return Row(
          children: [
            Expanded(
              child: GradientButton(
                text: isFollowing ? 'Following' : 'Follow',
                icon: isFollowing ? Icons.check : Icons.add,
                onPressed: () {
                  provider.toggleFollow(widget.store.id);
                  Helpers.showSnackBar(
                    context,
                    isFollowing ? 'Unfollowed' : 'Following',
                  );
                },
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            // WhatsApp button
            if (widget.store.phone.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.chat, color: Colors.green),
                tooltip: 'WhatsApp',
                onPressed: () => _launchWhatsApp(widget.store.phone),
              ),
            // Call button
            if (widget.store.phone.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.call, color: AppColors.primaryPurple),
                tooltip: 'Call',
                onPressed: () => _launchPhone(widget.store.phone),
              ),
          ],
        );
      },
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatCard('Products', widget.store.totalProducts.toString(), Icons.store),
          _buildStatCard('Followers', widget.store.followers.toString(), Icons.people),
          _buildStatCard('Rating', widget.store.rating.toStringAsFixed(1), Icons.star),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.mediumRadius,
        boxShadow: [AppColors.softShadow],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryPurple),
          const SizedBox(height: AppTheme.spacing8),
          Text(value, style: AppTextStyles.h3.copyWith(color: AppColors.primaryPurple)),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryPurple,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.primaryPurple,
          labelStyle: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Products'),
            Tab(text: 'About Store'),
            Tab(text: 'Reviews'),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsTab() {
    return Consumer<StoreProvider>(
      builder: (context, storeProvider, _) {
        final products = storeProvider.products;
        final isLoading = storeProvider.isLoadingProducts;

        // Show loading state
        if (isLoading && products.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // Show empty state
        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No products currently available',
                  style: AppTextStyles.bodyLarge.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Products will be added soon',
                  style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[400]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => storeProvider.loadProducts(widget.store.id),
          child: NotificationListener<ScrollNotification>(
            onNotification: (scroll) {
              if (scroll.metrics.pixels >= scroll.metrics.maxScrollExtent - 100 &&
                  storeProvider.hasMore &&
                  !storeProvider.isLoadingMore) {
                storeProvider.loadMoreProducts(widget.store.id);
              }
              return false;
            },
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: CardConstants.gridHorizontalPadding,
                vertical: CardConstants.gridVerticalPadding,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: CardConstants.gridCrossAxisCount,
                crossAxisSpacing: CardConstants.gridCrossAxisSpacing,
                mainAxisSpacing: CardConstants.gridMainAxisSpacing,
                childAspectRatio: CardConstants.gridChildAspectRatio,
              ),
              itemCount: products.length + (storeProvider.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= products.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final product = products[index];
                return ProductCard(
                  product: product,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      Routes.productDetails,
                      arguments: product,
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About Store', style: AppTextStyles.h3),
          const SizedBox(height: AppTheme.spacing12),
          Text(widget.store.description, style: AppTextStyles.bodyMedium.copyWith(height: 1.6)),
          const SizedBox(height: AppTheme.spacing24),
          Text('Working Hours', style: AppTextStyles.h3),
          const SizedBox(height: AppTheme.spacing12),
          _buildWorkingHour('Saturday - Thursday', '09:00 - 21:00'),
          _buildWorkingHour('Friday', '14:00 - 21:00'),
        ],
      ),
    );
  }

  Widget _buildWorkingHour(String day, String hours) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(day, style: AppTextStyles.bodyMedium),
          Text(hours, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            itemCount: widget.store.reviews.length,
            itemBuilder: (context, index) {
              final review = widget.store.reviews[index];
              return Card(
                margin: const EdgeInsets.only(bottom: AppTheme.spacing16),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacing16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(review.userName, style: AppTextStyles.h3),
                          Text('${review.rating}/5', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacing8),
                      Text(review.comment, style: AppTextStyles.bodyMedium),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: AppPrimaryButton(
            text: 'Add Review',
            onPressed: () => Helpers.showSnackBar(context, 'Leave a Review'),
          ),
        ),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Colors.white, child: _tabBar);
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}
