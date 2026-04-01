import 'package:flutter/material.dart';
import 'package:dzlocal_shop/core/extensions/l10n_extension.dart';
import 'package:provider/provider.dart';

import '../../core/config/api_config.dart';
import '../../core/providers/wallet_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/services/subscription_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/app_compact_action_button.dart';
import '../../core/widgets/app_toggle_button.dart';
import '../../data/models/offer_model.dart';
import '../../data/models/post_model.dart';
import '../../data/repositories/post_repository.dart';
import 'add_ad_screen.dart';
import '../shared_widgets/empty_state_widget.dart';
import '../shared_widgets/error_state_widget.dart';
import '../shared_widgets/wino_coin_badge.dart';
import '../wallet/coin_store_screen.dart';

class AdsDashboardScreen extends StatefulWidget {
  const AdsDashboardScreen({super.key});

  @override
  State<AdsDashboardScreen> createState() => _AdsDashboardScreenState();
}

class _AdsDashboardScreenState extends State<AdsDashboardScreen> {
  static const List<ToggleOption> _periodOptions = [
    ToggleOption(label: 'All', value: 'all'),
    ToggleOption(label: 'Today', value: 'today'),
    ToggleOption(label: '7D', value: 'last_7_days'),
    ToggleOption(label: '14D', value: 'last_14_days'),
    ToggleOption(label: '30D', value: 'last_30_days'),
    ToggleOption(label: 'MTD', value: 'month_to_date'),
  ];

  late Future<Map<String, dynamic>> _future;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String? _selectedPeriod;

  static const List<ToggleOption> _productSortOptions = [
    ToggleOption(label: 'Advertised', value: 'advertised'),
    ToggleOption(label: 'Views', value: 'views'),
    ToggleOption(label: 'Ad Impr', value: 'ad_impressions'),
    ToggleOption(label: 'Clicks', value: 'clicks'),
  ];

  String _productQuery = '';
  String _productSort = 'advertised';
  int _visibleProductStatsCount = 5;

  @override
  void initState() {
    super.initState();
    _reload();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<WalletProvider>().fetchWallet(notifyStart: false);
      }
    });
  }

  void _reload() {
    _visibleProductStatsCount = 5;
    _future = SubscriptionService.fetchMerchantDashboard(
      dateFrom: _dateFrom,
      dateTo: _dateTo,
      period: _selectedPeriod,
    );
  }

  void _applyQuickPeriod(String period) {
    setState(() {
      _selectedPeriod = period;
      _dateFrom = null;
      _dateTo = null;
      _reload();
    });
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
      _selectedPeriod = null;
      _dateFrom = picked.start;
      _dateTo = picked.end;
      _reload();
    });
  }

  void _clearDateRange() {
    setState(() {
      _selectedPeriod = null;
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

  int get _selectedPeriodIndex {
    final index = _periodOptions.indexWhere(
      (option) => option.value == _selectedPeriod,
    );
    return index >= 0 ? index : 0;
  }

  int get _selectedProductSortIndex {
    final index = _productSortOptions.indexWhere(
      (option) => option.value == _productSort,
    );
    return index >= 0 ? index : 0;
  }

  int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  double _asDouble(dynamic value, [double fallback = 0.0]) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  Widget _buildProductPerformanceSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: context.tr('Search products…'),
              ),
              onChanged: (value) {
                setState(() {
                  _productQuery = value;
                  _visibleProductStatsCount = 5;
                });
              },
            ),
          ),
          IconButton(
            onPressed: () {
              FocusScope.of(context).unfocus();
            },
            icon: const Icon(Icons.search, size: 20),
            splashRadius: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildProductPerformanceRow(
    Map<String, dynamic> stats,
    Map<String, dynamic>? productInfo,
    VoidCallback? onEditAd,
  ) {
    final name = (stats['product_name'] ?? context.tr('Product')).toString();
    final views = _asInt(stats['ad_impressions']);
    final clicks = _asInt(stats['ad_clicks']);
    final favorites = _asInt(stats['ad_favorites']);
    final adStaySec = _asDouble(stats['ad_stay_time_sec']);
    final followsFromAds = _asInt(stats['follows_from_ads']);
    final storeClicksFromAds = _asInt(stats['store_clicks_from_ads']);

    final image = (productInfo?['image'] ?? '').toString();
    final price = _asDouble(productInfo?['price']);
    final hasActiveAd = productInfo?['has_active_ad'] == true;
    final activeAdCount = _asInt(productInfo?['active_ad_count']);

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
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 46,
                  height: 46,
                  child: image.isNotEmpty
                      ? Image.network(image, fit: BoxFit.cover)
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.inventory_2_outlined),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (productInfo != null)
                      Text(
                        Helpers.formatPrice(price),
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (hasActiveAd)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    activeAdCount > 1
                        ? '${context.tr('Advertising')} ($activeAdCount)'
                        : context.tr('Advertising'),
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              if (hasActiveAd)
                IconButton(
                  onPressed: onEditAd,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: context.tr('Edit Ad'),
                  splashRadius: 18,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metricPill('Views', '$views'),
              _metricPill('Clicks', '$clicks'),
              _metricPill('Favorites', '$favorites'),
              if (adStaySec > 0)
                _metricPill('Stay', _formatDurationCompact(adStaySec)),
              if (storeClicksFromAds > 0)
                _metricPill('Store', '$storeClicksFromAds'),
              if (followsFromAds > 0)
                _metricPill('Follows (Ad)', '$followsFromAds'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsCard({
    required int activeAds,
    required int totalImpressions,
    required int totalClicks,
    required double ctrValue,
  }) {
    final insights = <String>[
      if (activeAds <= 0)
        'You have no active ads right now. Start with one clear product or pack.'
      else if (totalImpressions <= 0)
        'Your ads are active, but they still need reach. Review dates, placement, and budget.'
      else if (ctrValue < 1)
        'People are seeing your ads, but clicks are still low. Improve the image, title, or offer.'
      else
        'Your ads are getting both views and clicks. Keep budget on the products that move fastest.',
      'Nearby performance improves when both your store GPS and address are complete.',
    ];

    return _sectionCard(
      title: context.tr('What these numbers mean'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: insights
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        size: 16,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.tr(item),
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  String _formatDurationCompact(double seconds) {
    final total = seconds.isFinite ? seconds.round() : 0;
    if (total <= 0) return '0s';
    if (total >= 3600) {
      final h = total ~/ 3600;
      final m = (total % 3600) ~/ 60;
      return m > 0 ? '${h}h ${m}m' : '${h}h';
    }
    if (total >= 60) {
      final m = total ~/ 60;
      final s = total % 60;
      return s > 0 ? '${m}m ${s}s' : '${m}m';
    }
    return '${total}s';
  }

  DateTime? _parseDateTimeToLocal(dynamic raw) {
    if (raw == null) return null;
    final parsed = DateTime.tryParse(raw.toString());
    return parsed?.toLocal();
  }

  int _parsePercentage(dynamic raw) {
    if (raw == null) return 0;
    if (raw is int) return raw;
    if (raw is double) return raw.round();
    final text = raw.toString().trim();
    final asDouble = double.tryParse(text);
    if (asDouble != null) return asDouble.round();
    return int.tryParse(text) ?? 0;
  }

  Future<void> _openEditAdForProduct({
    required int productId,
    required int campaignId,
  }) async {
    try {
      final campaignRaw =
          await ApiService.get('${ApiConfig.adsCampaigns}$campaignId/');
      final product = await PostRepository.getPost(productId);
      if (!mounted) return;

      final pct = _parsePercentage(campaignRaw['percentage']);
      final offer = Offer(
        id: campaignId,
        product: product,
        discountPercentage: pct,
        newPrice: (product.price * (1 - (pct / 100))).toDouble(),
        isAvailable: campaignRaw['is_active'] == true,
        createdAt:
            DateTime.tryParse((campaignRaw['created_at'] ?? '').toString()) ??
                DateTime.now(),
        startDate: _parseDateTimeToLocal(campaignRaw['start_date']),
        endDate: _parseDateTimeToLocal(campaignRaw['end_date']),
        maxImpressions:
            int.tryParse((campaignRaw['max_impressions'] ?? '').toString()),
        uniqueViewersCount: int.tryParse(
            (campaignRaw['unique_viewers_count'] ?? '').toString()),
        remainingImpressions: int.tryParse(
            (campaignRaw['remaining_impressions'] ?? '').toString()),
        kind: 'advertising',
        placement: (campaignRaw['placement'] ?? 'home_top').toString(),
        audienceMode: (campaignRaw['audience_mode'] ?? 'all').toString(),
        impressionsCount:
            int.tryParse((campaignRaw['impressions_count'] ?? '').toString()) ??
                0,
        clicksCount:
            int.tryParse((campaignRaw['clicks_count'] ?? '').toString()) ?? 0,
        geoMode: (campaignRaw['geo_mode'] ?? 'all').toString(),
        targetRadiusKm:
            int.tryParse((campaignRaw['target_radius_km'] ?? '').toString()),
        ageFrom: int.tryParse((campaignRaw['age_from'] ?? '').toString()),
        ageTo: int.tryParse((campaignRaw['age_to'] ?? '').toString()),
        targetWilayas: (campaignRaw['target_wilayas'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        targetCategories: (campaignRaw['target_categories'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        targetType: (campaignRaw['target_type'] ?? 'product').toString(),
      );

      final changed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => AddAdScreen(offer: offer, initialProduct: product),
        ),
      );
      if (changed == true && mounted) {
        setState(_reload);
      }
    } catch (e) {
      if (!mounted) return;
      Helpers.showSnackBar(
        context,
        '${context.tr('Failed to open ad editor')}: $e',
        isError: true,
      );
    }
  }

  Future<void> _openCreateAd({
    Post? product,
    int? packId,
    String? packName,
  }) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddAdScreen(
          initialProduct: product,
          initialPackId: packId,
          initialPackName: packName,
        ),
      ),
    );
    if (changed == true && mounted) {
      setState(_reload);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FC),
        appBar: AppBar(
          title: Text(context.tr('Ads')),
          actions: [
            Consumer<WalletProvider>(
              builder: (context, wallet, _) => WinoCoinBadge(
                coins: wallet.coinsBalance,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CoinStoreScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return RefreshIndicator(
                onRefresh: () async {
                  setState(_reload);
                  await _future;
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 80),
                    SizedBox(
                      height: 420,
                      child: ErrorStateWidget(
                        message: context.tr('Failed to load dashboard'),
                        details: '${snapshot.error}',
                        onRetry: () => setState(_reload),
                      ),
                    ),
                  ],
                ),
              );
            }

            final data = snapshot.data ?? {};
            final adInventory =
                (data['ad_inventory'] as Map?)?.cast<String, dynamic>() ??
                    const <String, dynamic>{};
            final ads = (data['ads'] as List?) ?? const [];
            final productStats = (data['product_stats'] as List?) ?? const [];
            final eligibleProducts =
                (data['eligible_products'] as List?) ?? const [];
            final eligiblePacks = (data['eligible_packs'] as List?) ?? const [];

            final Map<int, Map<String, dynamic>> productInfoById = {};
            for (final row in eligibleProducts) {
              if (row is! Map) continue;
              final item = row.cast<String, dynamic>();
              final id = _asInt(item['id']);
              if (id > 0) productInfoById[id] = item;
            }

            final totalImpressions = ads.fold<int>(
              0,
              (sum, item) => sum + _asInt((item as Map)['impressions_count']),
            );
            final totalClicks = ads.fold<int>(
              0,
              (sum, item) => sum + _asInt((item as Map)['clicks_count']),
            );
            final ctr = totalImpressions > 0
                ? ((totalClicks / totalImpressions) * 100).toStringAsFixed(2)
                : '0.00';
            final ctrValue = double.tryParse(ctr) ?? 0;
            final activeAdsCount = _asInt(adInventory['ad_active_count']);

            return RefreshIndicator(
              onRefresh: () async {
                setState(_reload);
                await _future;
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
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
                  _buildInsightsCard(
                    activeAds: activeAdsCount,
                    totalImpressions: totalImpressions,
                    totalClicks: totalClicks,
                    ctrValue: ctrValue,
                  ),
                  const SizedBox(height: 16),
                  _buildEligiblePacksSection(eligiblePacks),
                  const SizedBox(height: 16),
                  _sectionCard(
                    title: context.tr('Ads'),
                    child: ads.isEmpty
                        ? EmptyStateWidget(
                            icon: Icons.campaign_outlined,
                            title: context.tr('No ads found in this period.'),
                            message: context.tr(
                              'Change the dates or create a new ad to start collecting results.',
                            ),
                            compact: true,
                          )
                        : Column(
                            children: ads.map<Widget>((item) {
                              final promo =
                                  (item as Map).cast<String, dynamic>();
                              final adProductId = _asInt(promo['product']);
                              final mappedProductName =
                                  (productInfoById[adProductId]?['name'] ?? '')
                                      .toString()
                                      .trim();
                              final apiProductName =
                                  (promo['product_name'] ?? '')
                                      .toString()
                                      .trim();
                              final campaignName =
                                  (promo['name'] ?? context.tr('Campaign'))
                                      .toString();
                              final name = apiProductName.isNotEmpty
                                  ? apiProductName
                                  : (mappedProductName.isNotEmpty
                                      ? mappedProductName
                                      : campaignName);
                              final kind =
                                  (promo['kind'] ?? 'promotion').toString();
                              final impressions =
                                  _asInt(promo['impressions_count']);
                              final clicks = _asInt(promo['clicks_count']);
                              final unique =
                                  _asInt(promo['unique_viewers_count']);
                              final remaining =
                                  promo['remaining_impressions'] == null
                                      ? null
                                      : _asInt(promo['remaining_impressions']);
                              final displayHour = int.tryParse(
                                  (promo['display_hour'] ?? '').toString());
                              final campaignCtr = impressions > 0
                                  ? ((clicks / impressions) * 100)
                                      .toStringAsFixed(1)
                                  : '0.0';
                              String? hourLabel;
                              if (displayHour != null &&
                                  displayHour >= 0 &&
                                  displayHour <= 23) {
                                final h12 = displayHour == 0
                                    ? 12
                                    : (displayHour > 12
                                        ? displayHour - 12
                                        : displayHour);
                                final suffix = displayHour < 12 ? 'AM' : 'PM';
                                hourLabel = '$h12$suffix';
                              }
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border:
                                      Border.all(color: Colors.grey.shade200),
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
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            context.tr('AD'),
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
                                        _metricPill(
                                            'Impressions', '$impressions'),
                                        _metricPill('Clicks', '$clicks'),
                                        _metricPill('Unique', '$unique'),
                                        if (hourLabel != null)
                                          _metricPill('Hour', hourLabel),
                                        if (remaining != null)
                                          _metricPill(
                                              'Remaining', '$remaining'),
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
                    title: context.tr('Product Performance'),
                    child: productStats.isEmpty
                        ? EmptyStateWidget(
                            icon: Icons.insights_outlined,
                            title: context.tr(
                                'No product performance data for this period.'),
                            message: context.tr(
                              'Once ads collect views and clicks, product-level insights will appear here.',
                            ),
                            compact: true,
                          )
                        : Builder(
                            builder: (context) {
                              final query = _productQuery.trim().toLowerCase();
                              final queryId = int.tryParse(query);
                              final items = productStats
                                  .whereType<Map>()
                                  .map((row) => row.cast<String, dynamic>())
                                  .where((row) {
                                if (query.isEmpty) return true;
                                final name =
                                    (row['product_name'] ?? '').toString();
                                final pid = _asInt(row['product_id']);
                                if (queryId != null && pid == queryId) {
                                  return true;
                                }
                                return name.toLowerCase().contains(query);
                              }).toList();

                              int sortValue(
                                  Map<String, dynamic> row, String key) {
                                final v = row[key];
                                if (v is int) return v;
                                return int.tryParse(v?.toString() ?? '') ?? 0;
                              }

                              items.sort((a, b) {
                                final aId = _asInt(a['product_id']);
                                final bId = _asInt(b['product_id']);
                                final aInfo = productInfoById[aId];
                                final bInfo = productInfoById[bId];
                                final aActive = aInfo?['has_active_ad'] == true;
                                final bActive = bInfo?['has_active_ad'] == true;
                                final aActiveCount =
                                    _asInt(aInfo?['active_ad_count']);
                                final bActiveCount =
                                    _asInt(bInfo?['active_ad_count']);

                                if (_productSort == 'advertised') {
                                  if (aActive != bActive) {
                                    return (bActive ? 1 : 0) -
                                        (aActive ? 1 : 0);
                                  }
                                  if (aActiveCount != bActiveCount) {
                                    return bActiveCount - aActiveCount;
                                  }
                                  final aAdImp = sortValue(a, 'ad_impressions');
                                  final bAdImp = sortValue(b, 'ad_impressions');
                                  if (aAdImp != bAdImp) return bAdImp - aAdImp;
                                  final aAdClicks = sortValue(a, 'ad_clicks');
                                  final bAdClicks = sortValue(b, 'ad_clicks');
                                  return bAdClicks - aAdClicks;
                                }

                                if (_productSort == 'views') {
                                  return sortValue(b, 'ad_impressions') -
                                      sortValue(a, 'ad_impressions');
                                }
                                if (_productSort == 'clicks') {
                                  return sortValue(b, 'ad_clicks') -
                                      sortValue(a, 'ad_clicks');
                                }
                                if (_productSort == 'ad_impressions') {
                                  return sortValue(b, 'ad_impressions') -
                                      sortValue(a, 'ad_impressions');
                                }
                                return 0;
                              });

                              final visible = items
                                  .take(_visibleProductStatsCount)
                                  .toList();

                              return Column(
                                children: [
                                  _buildProductPerformanceSearchBar(),
                                  const SizedBox(height: 10),
                                  AppToggleButtonGroup(
                                    options: _productSortOptions,
                                    selectedIndex: _selectedProductSortIndex,
                                    onChanged: (index) {
                                      setState(() {
                                        _productSort =
                                            _productSortOptions[index].value;
                                        _visibleProductStatsCount = 5;
                                      });
                                    },
                                    scrollable: true,
                                    compact: true,
                                  ),
                                  const SizedBox(height: 12),
                                  ...visible.map((item) {
                                    final pid = _asInt(item['product_id']);
                                    final info = productInfoById[pid];
                                    final campaignId =
                                        _asInt(info?['active_ad_campaign_id']);
                                    return _buildProductPerformanceRow(
                                      item,
                                      info,
                                      (campaignId > 0 && pid > 0)
                                          ? () => _openEditAdForProduct(
                                                productId: pid,
                                                campaignId: campaignId,
                                              )
                                          : null,
                                    );
                                  }),
                                  if (items.length > _visibleProductStatsCount)
                                    AppCompactActionButton(
                                      label: context.tr('Show more'),
                                      onTap: () {
                                        setState(() {
                                          _visibleProductStatsCount += 5;
                                        });
                                      },
                                    ),
                                ],
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                  _sectionCard(
                    title: context.tr('Tips'),
                    child: Text(
                      context.tr(
                        'Choose high-demand products, reserve impression budget for fast movers, and keep the home-top placement for your most visual campaigns.',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openCreateAd(),
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          tooltip: context.tr('Create Sponsored Ad'),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildDateFilterBar() {
    final hasRange = _dateFrom != null && _dateTo != null;
    final hasActiveFilter = hasRange || _selectedPeriod != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                            : (_selectedPeriod != null
                                ? '${context.tr('Preset')}: ${context.tr(_selectedPeriod!.replaceAll('_', ' '))}'
                                : context.tr('All dates')),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            AppCompactActionButton(
              label: context.tr('Custom'),
              onTap: _pickDateRange,
            ),
            if (hasActiveFilter) ...[
              const SizedBox(width: 8),
              AppCompactActionButton(
                label: context.tr('Clear'),
                onTap: _clearDateRange,
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        AppToggleButtonGroup(
          options: _periodOptions,
          selectedIndex: _selectedPeriodIndex,
          onChanged: (index) {
            final value = _periodOptions[index].value;
            if (value == 'all') {
              _clearDateRange();
              return;
            }
            _applyQuickPeriod(value);
          },
          scrollable: true,
          compact: true,
        ),
      ],
    );
  }

  Widget _buildEligiblePacksSection(List eligiblePacks) {
    return _sectionCard(
      title: context.tr('Select Pack to Advertise'),
      child: eligiblePacks.isEmpty
          ? Text(context.tr('No packs available for advertising.'))
          : Column(
              children: eligiblePacks.take(8).map<Widget>((item) {
                final pack = (item as Map).cast<String, dynamic>();
                final image = (pack['image'] ?? '').toString();
                final hasActiveAd = pack['has_active_ad'] as bool? ?? false;
                final packId =
                    int.tryParse((pack['id'] ?? '0').toString()) ?? 0;
                final packName =
                    (pack['name'] ?? context.tr('Pack')).toString();

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
                              packName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              Helpers.formatPrice(
                                double.tryParse(
                                        (pack['price'] ?? '0').toString()) ??
                                    0,
                              ),
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              hasActiveAd
                                  ? context.tr('Already has an active ad')
                                  : context.tr('Ready for advertising'),
                              style: TextStyle(
                                color: hasActiveAd
                                    ? Colors.orange.shade800
                                    : Colors.green.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => _openCreateAd(
                          packId: packId,
                          packName: packName,
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          hasActiveAd
                              ? context.tr('Edit Ad')
                              : context.tr('Advertise'),
                        ),
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
            context.tr(title),
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
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800),
                ),
                Text(
                  context.tr(label),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
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
        '${context.tr(label)}: $value',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
