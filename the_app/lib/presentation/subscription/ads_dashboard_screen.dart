import 'package:flutter/material.dart';
import '../../core/services/subscription_service.dart';
import '../../core/theme/app_colors.dart';

class AdsDashboardScreen extends StatefulWidget {
  const AdsDashboardScreen({super.key});

  @override
  State<AdsDashboardScreen> createState() => _AdsDashboardScreenState();
}

class _AdsDashboardScreenState extends State<AdsDashboardScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = SubscriptionService.fetchMerchantDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ads & Promotions'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load dashboard: ${snapshot.error}'));
          }
          final data = snapshot.data ?? {};
          final subscription = data['active_subscription'] as Map<String, dynamic>?;
          final daysRemaining = data['days_remaining'];
          final promotions = (data['promotions'] as List?) ?? const [];
          final productStats = (data['product_stats'] as List?) ?? const [];

          final totalImpressions = promotions.fold<int>(
              0, (sum, p) => sum + (p['impressions_count'] ?? 0) as int);
          final totalClicks = promotions.fold<int>(
              0, (sum, p) => sum + (p['clicks_count'] ?? 0) as int);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _sectionCard(
                title: 'Subscription Status',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription != null
                          ? (subscription['plan_detail']?['name'] ?? 'Active')
                              .toString()
                          : 'No active subscription',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('Days remaining: ${daysRemaining ?? '-'}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      label: 'Impressions',
                      value: totalImpressions.toString(),
                      icon: Icons.visibility_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      label: 'Clicks',
                      value: totalClicks.toString(),
                      icon: Icons.touch_app_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _sectionCard(
                title: 'Promotions & Ads',
                child: promotions.isEmpty
                    ? const Text('No promotions yet.')
                    : Column(
                        children: promotions.map<Widget>((p) {
                          final name = (p['name'] ?? '').toString();
                          final kind = (p['kind'] ?? 'promotion').toString();
                          final impressions = p['impressions_count'] ?? 0;
                          final unique = p['unique_viewers_count'] ?? 0;
                          final clicks = p['clicks_count'] ?? 0;
                          final remaining = p['remaining_impressions'];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: kind == 'advertising'
                                            ? const Color(0xFFFFE3C2)
                                            : const Color(0xFFE9F3FF),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        kind == 'advertising'
                                            ? 'AD'
                                            : 'PROMO',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        name.isEmpty ? 'Promotion' : name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Impr: $impressions • Unique: $unique • Clicks: $clicks'
                                  '${remaining != null ? ' • Remaining: $remaining' : ''}',
                                  style:
                                      TextStyle(color: Colors.grey.shade700),
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
                    ? const Text('No product stats yet.')
                    : Column(
                        children: productStats.map<Widget>((row) {
                          final name = (row['product__name'] ?? '').toString();
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(name.isEmpty ? 'Product' : name),
                            subtitle: Text(
                              'Views: ${row['views'] ?? 0} • Clicks: ${row['clicks'] ?? 0} • Fav: ${row['favorites'] ?? 0} • Promo Clicks: ${row['promotion_clicks'] ?? 0}',
                            ),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 16),
              _sectionCard(
                title: 'Tips',
                child: const Text(
                  'Use ads for time-sensitive products. Combine strong visuals with limited impressions and higher boost for better reach.',
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
