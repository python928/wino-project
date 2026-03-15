import 'dart:io';
import 'package:flutter/material.dart';
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
    final badge = plan.planFeatures['ui_badge'];
    if (badge is String && badge.trim().isNotEmpty) return badge.trim();
    if (isHighlighted) return 'Top Pick';
    return null;
  }

  List<String> _benefitLines() {
    final raw = plan.benefits.trim();
    if (raw.isEmpty) {
      return const [
        'Priority publishing and better exposure.',
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
                '${plan.price.toStringAsFixed(0)} DZD',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryColor,
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
                  label: 'Posts',
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
        Helpers.showSnackBar(context, 'Error selecting images', isError: true);
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
      Helpers.showSnackBar(context, 'Please add at least 1 payment proof image');
      return;
    }
    setState(() => _submitting = true);
    try {
      await SubscriptionService.submitPaymentRequest(
        planId: widget.plan.id,
        paymentNote: _noteController.text.trim(),
        images: List<XFile>.from(_proofImages),
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
    final priceText = '${widget.plan.price.toStringAsFixed(0)} DZD';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Plan Information'),
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
                _infoRow('Posts', 'Up to ${widget.plan.maxProducts}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle('Payment Information'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How it works',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                _infoRow(
                  'RIB',
                  widget.rib.isNotEmpty ? widget.rib : 'N/A',
                ),
                const SizedBox(height: 6),
                Text(
                  widget.instructions.isNotEmpty
                      ? widget.instructions
                      : 'Send payment to the RIB above, then confirm below. We will review and activate your plan.',
                  style: TextStyle(color: Colors.grey.shade700, height: 1.35),
                ),
                const SizedBox(height: 10),
                Row(
                  children: const [
                    Icon(Icons.verified_outlined, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Activation typically within 24 hours.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _proofSection(),
          const SizedBox(height: 14),
          TextField(
            controller: _noteController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Payment note / transfer reference (optional)',
              filled: true,
              fillColor: Colors.white,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primaryColor),
              ),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
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
                : const Text('Confirm Subscription Request'),
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
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Payment Proofs',
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
          Text(
            'Add 1 to 3 images (receipt, transfer, or bank confirmation).',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 10),
          if (_proofImages.isEmpty)
            OutlinedButton.icon(
              onPressed: _pickProofImages,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Add Images'),
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
        ],
      ),
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
