import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../core/services/subscription_service.dart';
import '../../data/models/post_model.dart';
import '../../data/models/user_model.dart';
import '../profile/add_promotion_screen.dart';
import 'subscription_plans_screen.dart';

class AdsDashboardScreen extends StatefulWidget {
  const AdsDashboardScreen({super.key});

  @override
  State<AdsDashboardScreen> createState() => _AdsDashboardScreenState();
}

class _AdsDashboardScreenState extends State<AdsDashboardScreen> {
  late Future<Map<String, dynamic>> _future;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = SubscriptionService.fetchMerchantDashboard(
      dateFrom: _dateFrom,
      dateTo: _dateTo,
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateFrom != null && _dateTo != null
          ? DateTimeRange(start: _dateFrom!, end: _dateTo!)
          : null,
    );
    if (picked == null) return;
    setState(() {
      _dateFrom = picked.start;
      _dateTo = picked.end;
      _reload();
    });
  }

  void _clearDateRange() {
    setState(() {
      _dateFrom = null;
      _dateTo = null;
      _reload();
    });
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  Future<void> _openCreateAd({Post? product}) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddPromotionScreen(
          initialKind: 'advertising',
          initialProduct: product,
        ),
      ),
    );
    if (changed == true && mounted) {
      setState(_reload);
    }
  }

  Post _postFromEligible(Map<String, dynamic> json) {
    final name = (json['name'] ?? 'Product').toString();
    final image = (json['image'] ?? '').toString();
    final price = double.tryParse((json['price'] ?? '0').toString()) ?? 0.0;
    return Post(
      id: int.tryParse((json['id'] ?? '0').toString()) ?? 0,
      title: name,
      description: '',
      category: 'Product',
      categoryId: null,
      storeId: 0,
      storeName: '',
      author: User(
        id: 0,
        username: '',
        email: '',
        name: '',
        profileImage: null,
        dateJoined: DateTime.now(),
      ),
      price: price,
      isAvailable: true,
      rating: 0,
      isHotDeal: false,
      isFeatured: false,
      createdAt: DateTime.now(),
      images: image.isEmpty
          ? const []
          : [ProductImageData(id: 0, url: image, isMain: true)],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text('Ads & Promotions'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Filter by date',
            onPressed: _pickDateRange,
            icon: const Icon(Icons.date_range_outlined),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load dashboard: ${snapshot.error}'),
            );
          }

          final data = snapshot.data ?? {};
          final subscription = data['active_subscription'] as Map<String, dynamic>?;
          final latestRequest = data['latest_payment_request'] as Map<String, dynamic>?;
          final planFeatures =
              (data['plan_features'] as Map?)?.cast<String, dynamic>() ??
                  const <String, dynamic>{};
          final adInventory =
              (data['ad_inventory'] as Map?)?.cast<String, dynamic>() ??
                  const <String, dynamic>{};
          final daysRemaining = data['days_remaining'];
          final promotions = (data['promotions'] as List?) ?? const [];
          final productStats = (data['product_stats'] as List?) ?? const [];
          final eligibleProducts =
              (data['eligible_products'] as List?) ?? const [];

          final totalImpressions = promotions.fold<int>(
            0,
            (sum, item) => sum + ((item as Map)['impressions_count'] as int? ?? 0),
          );
          final totalClicks = promotions.fold<int>(
            0,
            (sum, item) => sum + ((item as Map)['clicks_count'] as int? ?? 0),
          );
          final ctr = totalImpressions > 0
              ? ((totalClicks / totalImpressions) * 100).toStringAsFixed(2)
              : '0.00';

          return RefreshIndicator(
            onRefresh: () async {
              setState(_reload);
              await _future;
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _buildHeroHeader(
                  subscription: subscription,
                  latestRequest: latestRequest,
                  daysRemaining: daysRemaining,
                ),
                const SizedBox(height: 12),
                _buildDateFilterBar(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        label: 'Impressions',
                        value: '$totalImpressions',
                        icon: Icons.visibility_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        label: 'Clicks',
                        value: '$totalClicks',
                        icon: Icons.ads_click_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        label: 'CTR',
                        value: '$ctr%',
                        icon: Icons.trending_up_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        label: 'Active Ads',
                        value: '${adInventory['ad_active_count'] ?? 0}',
                        icon: Icons.campaign_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInventoryCard(planFeatures, adInventory),
                const SizedBox(height: 16),
                _buildEligibleProductsSection(eligibleProducts),
                const SizedBox(height: 16),
                _sectionCard(
                  title: 'Promotions & Ads',
                  child: promotions.isEmpty
                      ? const Text('No campaigns found in this period.')
                      : Column(
                          children: promotions.map<Widget>((item) {
                            final promo = (item as Map).cast<String, dynamic>();
                            final name = (promo['name'] ?? 'Campaign').toString();
                            final kind = (promo['kind'] ?? 'promotion').toString();
                            final impressions = promo['impressions_count'] ?? 0;
                            final clicks = promo['clicks_count'] ?? 0;
                            final unique = promo['unique_viewers_count'] ?? 0;
                            final remaining = promo['remaining_impressions'];
                            final campaignCtr = impressions > 0
                                ? ((clicks / impressions) * 100).toStringAsFixed(1)
                                : '0.0';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: kind == 'advertising'
                                              ? const Color(0xFFFFE5D0)
                                              : const Color(0xFFEAF3FF),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          kind == 'advertising' ? 'AD' : 'PROMO',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        'CTR $campaignCtr%',
                                        style: TextStyle(
                                          color: AppColors.primaryColor,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _metricPill('Impressions', '$impressions'),
                                      _metricPill('Clicks', '$clicks'),
                                      _metricPill('Unique', '$unique'),
                                      if (remaining != null)
                                        _metricPill('Remaining', '$remaining'),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ),
                const SizedBox(height: 16),
                _sectionCard(
                  title: 'Product Performance',
                  child: productStats.isEmpty
                      ? const Text('No product performance data for this period.')
                      : Column(
                          children: productStats.map<Widget>((row) {
                            final item = (row as Map).cast<String, dynamic>();
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBFCFF),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (item['product_name'] ?? 'Product').toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _metricPill('Views', '${item['views'] ?? 0}'),
                                      _metricPill('Clicks', '${item['clicks'] ?? 0}'),
                                      _metricPill('Favorites', '${item['favorites'] ?? 0}'),
                                      _metricPill('Ad Impressions', '${item['ad_impressions'] ?? 0}'),
                                      _metricPill('Ad Clicks', '${item['ad_clicks'] ?? 0}'),
                                      _metricPill('Ad CTR', '${item['ad_ctr'] ?? 0}%'),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ),
                const SizedBox(height: 16),
                _sectionCard(
                  title: 'Tips',
                  child: const Text(
                    'Choose high-demand products, reserve impression budget for fast movers, and keep the home-top placement for your most visual campaigns.',
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateAd(),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.campaign_outlined),
        label: const Text('Create Ad'),
      ),
    );
  }

  Widget _buildHeroHeader({
    required Map<String, dynamic>? subscription,
    required Map<String, dynamic>? latestRequest,
    required dynamic daysRemaining,
  }) {
    final label = subscription != null
        ? (subscription['plan_detail']?['name'] ?? 'Active Plan').toString()
        : latestRequest != null
            ? 'Payment Under Review'
            : 'No Active Subscription';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF172033), Color(0xFF2D4470)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Ad Control Center',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(
                width: 92,
                child: OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SubscriptionPlansScreen(),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.4)),
                  ),
                  child: const Text('Plans'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.88),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Days remaining: ${daysRemaining ?? '-'}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.74),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilterBar() {
    final hasRange = _dateFrom != null && _dateTo != null;
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_outlined, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasRange
                        ? '${_formatDate(_dateFrom!)}  ->  ${_formatDate(_dateTo!)}'
                        : 'All dates',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 90,
          child: OutlinedButton(
            onPressed: _pickDateRange,
            child: const Text('Filter'),
          ),
        ),
        if (hasRange) ...[
          const SizedBox(width: 8),
          TextButton(
            onPressed: _clearDateRange,
            child: const Text('Clear'),
          ),
        ],
      ],
    );
  }

  Widget _buildInventoryCard(
    Map<String, dynamic> planFeatures,
    Map<String, dynamic> adInventory,
  ) {
    final slots = adInventory['remaining_ad_slots'] ?? 0;
    final maxImpressions = adInventory['ad_max_impressions'] ?? 0;
    final boost = adInventory['ad_priority_boost'] ?? 0;
    return _sectionCard(
      title: 'Advertising Capacity',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metricPill('Remaining Slots', '$slots'),
              _metricPill('Plan Impressions', '$maxImpressions'),
              _metricPill('Boost Limit', '$boost'),
              _metricPill(
                'Max Active',
                '${adInventory['ad_max_active'] ?? planFeatures['ad_max_active'] ?? 0}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Use the plan impressions as the ceiling when selecting how many times an ad should be shown.',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildEligibleProductsSection(List eligibleProducts) {
    return _sectionCard(
      title: 'Select Product to Advertise',
      child: eligibleProducts.isEmpty
          ? const Text('No products available for advertising.')
          : Column(
              children: eligibleProducts.take(8).map<Widget>((item) {
                final product = (item as Map).cast<String, dynamic>();
                final image = (product['image'] ?? '').toString();
                final hasActiveAd = product['has_active_ad'] as bool? ?? false;
                final post = _postFromEligible(product);
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: image.isNotEmpty
                              ? Image.network(image, fit: BoxFit.cover)
                              : Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.inventory_2_outlined),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (product['name'] ?? 'Product').toString(),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              Helpers.formatPrice(
                                double.tryParse((product['price'] ?? '0').toString()) ?? 0,
                              ),
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              hasActiveAd ? 'Already has an active ad' : 'Ready for promotion',
                              style: TextStyle(
                                color: hasActiveAd ? Colors.orange.shade800 : Colors.green.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => _openCreateAd(product: post),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(hasActiveAd ? 'Edit Ad' : 'Advertise'),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                Text(label, style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}