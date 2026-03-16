import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
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
  Map<String, dynamic>? _accessStatus;
  bool _showAllPlans = false;

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
      Map<String, dynamic>? accessStatus;
      try {
        accessStatus = await SubscriptionService.fetchAccessStatus();
      } catch (_) {
        accessStatus = <String, dynamic>{};
      }
      if (!mounted) return;
      setState(() {
        _plans = catalog.plans;
        _rib = catalog.rib;
        _instructions = catalog.instructions;
        _accessStatus = accessStatus;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  int? get _usedPosts => _parseInt(_accessStatus?['used_posts']);

  int? get _postLimit => _parseInt(_accessStatus?['post_limit']);

  int? get _activePlanId {
    final active = _accessStatus?['active_subscription'];
    if (active is Map) return _parseInt(active['plan']);
    return null;
  }

  double? get _usageProgress {
    final used = _usedPosts;
    final limit = _postLimit;
    if (used == null || limit == null || limit <= 0) return null;
    final raw = used / limit;
    return raw.clamp(0, 1).toDouble();
  }

  List<SubscriptionPlanModel> _visiblePlans() {
    if (_showAllPlans || _plans.length <= 2) return _plans;
    SubscriptionPlanModel? freePlan;
    for (final plan in _plans) {
      if (plan.price == 0) {
        freePlan = plan;
        break;
      }
    }
    final highlightPlan = _plans.isNotEmpty ? _plans.last : null;
    final out = <SubscriptionPlanModel>[];
    if (freePlan != null) out.add(freePlan);
    if (highlightPlan != null && highlightPlan != freePlan) {
      out.add(highlightPlan);
    }
    if (out.isEmpty) {
      out.addAll(_plans.take(2));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final visiblePlans = _visiblePlans();
    final highlightPlanId = _plans.isNotEmpty ? _plans.last.id : null;
    final activePlanId = _activePlanId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Plans'),
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
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 12),
                      ...visiblePlans.map(
                        (plan) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _PlanCard(
                            plan: plan,
                            isHighlighted:
                                highlightPlanId != null && plan.id == highlightPlanId,
                            isCurrentPlan: activePlanId != null
                                ? plan.id == activePlanId
                                : plan.price == 0,
                            onSelect: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SubscriptionPaymentScreen(
                                  plan: plan,
                                  rib: _rib,
                                  instructions: _instructions,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_plans.length > 2)
                        Align(
                          alignment: Alignment.center,
                          child: TextButton(
                            onPressed: () => setState(() {
                              _showAllPlans = !_showAllPlans;
                            }),
                            child: Text(
                              _showAllPlans
                                  ? 'Hide plans'
                                  : 'Show more plans',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    final used = _usedPosts;
    final limit = _postLimit;
    final progress = _usageProgress;
    final usageText =
        used != null && limit != null ? '$used of $limit products used' : null;

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
        children: [
          if (_accessStatus == null) ...[
            const Text(
              'Loading usage status...',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 6,
                backgroundColor: Colors.white.withOpacity(0.7),
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 14),
          ] else if (usageText != null && progress != null) ...[
            Text(
              usageText,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.white.withOpacity(0.7),
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 14),
          ] else ...[
            const Text(
              'Your current usage is unavailable right now.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
          ],
          const Text(
            'Discover Plans',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Each screen answers one clear question.',
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
  final bool isCurrentPlan;

  const _PlanCard({
    required this.plan,
    required this.onSelect,
    required this.isHighlighted,
    required this.isCurrentPlan,
  });

  Color _parseHexColor(String value, Color fallback) {
    final hex = value.replaceAll('#', '').trim();
    if (hex.length != 6) return fallback;
    final parsed = int.tryParse(hex, radix: 16);
    if (parsed == null) return fallback;
    return Color(0xFF000000 | parsed);
  }

  List<Color> _resolveGradient() {
    final uiGradient = plan.planFeatures['ui_gradient'];
    if (uiGradient is List && uiGradient.length >= 2) {
      final c1 = uiGradient[0]?.toString() ?? '';
      final c2 = uiGradient[1]?.toString() ?? '';
      return [
        _parseHexColor(c1, const Color(0xFFF7F9FF)),
        _parseHexColor(c2, const Color(0xFFEAF0FF)),
      ];
    }
    if (isHighlighted) {
      return [const Color(0xFFFFF4E6), const Color(0xFFFFE2BD)];
    }
    return [Colors.white, Colors.white];
  }

  String? _badgeText() {
    if (isHighlighted) return 'Most Popular';
    return null;
  }

  List<String> _benefitLines() {
    final raw = plan.benefits.trim();
    if (raw.isEmpty) {
      return const [
        'Featured exposure and core promotion tools.',
        'Higher visibility in recommendations.',
      ];
    }
    final newlineSplit = raw
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (newlineSplit.length >= 2) return newlineSplit;
    final sentenceSplit = raw
        .split('.')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return sentenceSplit.isNotEmpty ? sentenceSplit : [raw];
  }

  @override
  Widget build(BuildContext context) {
    final oldPriceRaw = plan.planFeatures['old_price'];
    final oldPrice = oldPriceRaw is num
        ? oldPriceRaw.toDouble()
        : double.tryParse(oldPriceRaw?.toString() ?? '');
    final hasDiscount =
        oldPrice != null && oldPrice > 0 && oldPrice > plan.price;
    final discountPercent = hasDiscount
      ? (((oldPrice - plan.price) / oldPrice) * 100).round()
        : null;
    final badge = _badgeText();
    final gradient = _resolveGradient();
    final benefits = _benefitLines();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
                      fontWeight: FontWeight.w800, fontSize: 17),
                ),
              ),
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                plan.price.toStringAsFixed(0),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'DZD / month',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(width: 8),
              if (hasDiscount)
                Text(
                  '${oldPrice.toStringAsFixed(0)} DZD',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              if (discountPercent != null)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '-$discountPercent%',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.green,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _specTile(
                  icon: Icons.inventory_2_outlined,
                  label: 'Products',
                  value: 'Up to ${plan.maxProducts}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _specTile(
                  icon: Icons.calendar_month_outlined,
                  label: 'Duration',
                  value: '${plan.durationDays} days',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: benefits
                .take(3)
                .map(
                  (text) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: AppColors.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            text,
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
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
              onPressed: isCurrentPlan ? null : onSelect,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: isCurrentPlan
                  ? const Text('Current Plan')
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Start now',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '7 days free',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
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

  Widget _specTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black87),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
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
  final _picker = ImagePicker();
  final List<XFile> _proofImages = [];

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickProofImages() async {
    try {
      final remaining = 3 - _proofImages.length;
      if (remaining <= 0) return;
      final picked = await _picker.pickMultiImage(imageQuality: 80);
      if (picked.isEmpty) return;
      setState(() {
        final toAdd = picked.take(remaining).toList();
        _proofImages.addAll(toAdd);
      });
    } catch (_) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Could not select images', isError: true);
      }
    }
  }

  void _removeProofAt(int index) {
    setState(() {
      _proofImages.removeAt(index);
    });
  }

  Future<void> _confirm() async {
    if (_proofImages.isEmpty) {
      Helpers.showSnackBar(context, 'Please upload at least one receipt image');
      return;
    }
    setState(() => _submitting = true);
    try {
      final resp = await SubscriptionService.submitPaymentRequest(
        planId: widget.plan.id,
        paymentNote: _noteController.text.trim(),
        images: List<XFile>.from(_proofImages),
      );
      if (!mounted) return;
      await _showSuccessDialog(resp['id']);
      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      if (!mounted) return;
      Helpers.showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _formatRequestId(dynamic raw) {
    if (raw == null) return '—';
    final text = raw.toString().trim();
    final numeric = int.tryParse(text);
    if (numeric == null) return text;
    return 'WN-${text.padLeft(4, '0')}';
  }

  Future<void> _showSuccessDialog(dynamic requestId) async {
    final displayId = _formatRequestId(requestId);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Request received'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Request number',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                displayId,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text('No manual follow-up needed'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Back to home'),
          ),
        ],
      ),
    );
  }

  Future<void> _copyRib() async {
    if (widget.rib.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: widget.rib));
    if (!mounted) return;
    Helpers.showSnackBar(context, 'Number copied');
  }

  Widget _stepCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _numberedInstruction(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: AppColors.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final priceText = '${widget.plan.price.toStringAsFixed(0)} DZD / month';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Plan information'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF4F7FF), Color(0xFFE7EEFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.plan.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(999),
                        border:
                            Border.all(color: Colors.black.withOpacity(0.05)),
                      ),
                      child: Text(
                        priceText,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${widget.plan.durationDays} days',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _infoRow('Products', 'Up to ${widget.plan.maxProducts}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _stepCard(
            title: 'Step 1 — Payment info',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Account number (RIB)',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    widget.rib.isNotEmpty ? widget.rib : '—',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: widget.rib.isNotEmpty ? _copyRib : null,
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy number'),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'No need to type the number or take a screenshot.',
                  style: TextStyle(color: Colors.black54, height: 1.3),
                ),
                const SizedBox(height: 12),
                _numberedInstruction(
                    1, 'Open your banking app and start a transfer.'),
                _numberedInstruction(2, 'Send the amount to this account.'),
                _numberedInstruction(3, 'Upload the receipt in the next step.'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _stepCard(
            title: 'Step 2 — Upload proof',
            child: _proofSection(),
          ),
          const SizedBox(height: 14),
          _stepCard(
            title: 'Step 3 — Confirm',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Send request'),
                  ),
                ),
                const SizedBox(height: 10),
                if (_submitting)
                  Row(
                    children: const [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Expanded(child: Text('We are reviewing your image...')),
                    ],
                  )
                else
                  const Text('No manual follow-up needed'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: Colors.black54,
        letterSpacing: 0.4,
      ),
    );
  }

  Widget _proofSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Upload receipt image',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              '${_proofImages.length}/3',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_proofImages.isEmpty)
          InkWell(
            onTap: _pickProofImages,
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.02),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.upload_file_outlined,
                        size: 28, color: Colors.grey.shade700),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap to choose an image',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    Text(
                      'Camera or gallery',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(_proofImages.length, (index) {
              final image = _proofImages[index];
              return Stack(
                children: [
                  GestureDetector(
                    onTap: () => _openImage(image),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(image.path),
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: InkWell(
                      onTap: () => _removeProofAt(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        if (_proofImages.isNotEmpty && _proofImages.length < 3)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _pickProofImages,
              icon: const Icon(Icons.add),
              label: const Text('Add another image'),
            ),
          ),
        const SizedBox(height: 12),
        TextField(
          controller: _noteController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Note (optional)',
            hintText: 'Example: transfer sent from Ahmed’s account',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryColor),
            ),
          ),
        ),
      ],
    );
  }

  void _openImage(XFile image) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              InteractiveViewer(
                child: Image.file(File(image.path), fit: BoxFit.contain),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
