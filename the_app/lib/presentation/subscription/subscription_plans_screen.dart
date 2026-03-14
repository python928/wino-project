import 'package:flutter/material.dart';
import '../../core/services/subscription_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/subscription_plan_model.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() =>
      _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  bool _isLoading = true;
  String? _error;
  List<SubscriptionPlanModel> _plans = const [];
  String _rib = '';
  String _instructions = '';

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final catalog = await SubscriptionService.fetchCatalogData();
      if (!mounted) return;
      setState(() {
        _plans = catalog.plans;
        _rib = catalog.rib;
        _instructions = catalog.instructions;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Plans'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? RefreshIndicator(
                  onRefresh: _loadPlans,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 140),
                      Center(child: Text('Failed to load plans: $_error')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPlans,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: _plans.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildHeader();
                      }
                      final p = _plans[index - 1];
                      final highlight = _plans.isNotEmpty &&
                          p.id == _plans.last.id;
                      return _PlanCard(
                        plan: p,
                        isHighlighted: highlight,
                        onSelect: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SubscriptionPaymentScreen(
                              plan: p,
                              rib: _rib,
                              instructions: _instructions,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEEF1FF), Color(0xFFDCE2FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Boost your store visibility',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 6),
          Text(
            'Unlock ads, more posts, and higher recommendation priority.',
            style: TextStyle(color: Colors.black54, height: 1.3),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlanModel plan;
  final VoidCallback onSelect;
  final bool isHighlighted;

  const _PlanCard({
    required this.plan,
    required this.onSelect,
    required this.isHighlighted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlighted ? const Color(0xFFFFF8ED) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHighlighted
              ? const Color(0xFFFFC684)
              : AppColors.primaryColor.withOpacity(0.25),
          width: isHighlighted ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${plan.price.toStringAsFixed(0)} DZD',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          if (isHighlighted)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Most popular',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text('Up to ${plan.maxProducts} posts • ${plan.durationDays} days'),
          const SizedBox(height: 8),
          Text(
            plan.benefits.isNotEmpty
                ? plan.benefits
                : 'Priority publishing and better exposure.',
            style: TextStyle(color: Colors.grey.shade700, height: 1.35),
          ),
          const SizedBox(height: 10),
          if (plan.planFeatures.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _featureChip(
                    'Ads: ${plan.planFeatures['ad_max_active'] ?? '-'}'),
                _featureChip(
                    'Ad Impr: ${plan.planFeatures['ad_max_impressions'] ?? '-'}'),
                _featureChip(
                    'Boost: ${plan.planFeatures['ad_priority_boost'] ?? '-'}'),
              ],
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSelect,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Select This Plan'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class SubscriptionPaymentScreen extends StatefulWidget {
  final SubscriptionPlanModel plan;
  final String rib;
  final String instructions;

  const SubscriptionPaymentScreen({
    super.key,
    required this.plan,
    required this.rib,
    required this.instructions,
  });

  @override
  State<SubscriptionPaymentScreen> createState() =>
      _SubscriptionPaymentScreenState();
}

class _SubscriptionPaymentScreenState extends State<SubscriptionPaymentScreen> {
  final _noteController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() => _submitting = true);
    try {
      await SubscriptionService.submitPaymentRequest(
        planId: widget.plan.id,
        paymentNote: _noteController.text.trim(),
      );
      if (!mounted) return;
      Helpers.showSnackBar(
          context, 'Request sent. We will review your payment.');
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      Helpers.showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.plan.name,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('Our RIB: ${widget.rib.isNotEmpty ? widget.rib : 'N/A'}'),
                const SizedBox(height: 4),
                Text('Price: ${widget.plan.price.toStringAsFixed(0)} DZD'),
                const SizedBox(height: 8),
                Text(
                  widget.instructions.isNotEmpty
                      ? widget.instructions
                      : 'Send money to this RIB, then press confirm.\n'
                          'We will review and activate your Subscription Plan.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _noteController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Payment note / transfer reference (optional)',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _submitting ? null : _confirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(46),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Confirm Subscription Request'),
          ),
        ],
      ),
    );
  }
}
