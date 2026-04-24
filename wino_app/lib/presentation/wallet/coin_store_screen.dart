import 'package:wino/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/wallet_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../shared_widgets/wino_coin_badge.dart';
import 'coin_payment_screen.dart';

class CoinStoreScreen extends StatefulWidget {
  final int? requiredCoins;
  final int? currentBalance;

  const CoinStoreScreen({
    super.key,
    this.requiredCoins,
    this.currentBalance,
  });

  @override
  State<CoinStoreScreen> createState() => _CoinStoreScreenState();
}

class _CoinStoreScreenState extends State<CoinStoreScreen> {
  bool _initialLoad = true;
  int _visibleTransactionsCount = 3;
  int _visiblePurchasesCount = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _load();
      }
    });
  }

  Future<void> _load() async {
    final wallet = context.read<WalletProvider>();
    await wallet.hydrateForCoinStore();
    if (mounted) {
      setState(() {
        _initialLoad = false;
        _visibleTransactionsCount = 3;
        _visiblePurchasesCount = 3;
      });
    }
  }

  int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  Widget _buildPackList({
    required String title,
    required List packs,
    required bool isLoading,
  }) {
    if (packs.isEmpty) {
      return _sectionCard(
        title: title,
        child: Text(context.tr('No packs available yet.')),
      );
    }

    return _sectionCard(
      title: title,
      child: Column(
        children: packs.map<Widget>((item) {
          final pack = (item as Map).cast<String, dynamic>();
          final coins = _asInt(pack['coins']);
          final price = pack['price']?.toString() ?? '';
          final originalPrice = pack['original_price']?.toString();
          final percentSaved =
              (pack['percent_saved'] as num?)?.toDouble() ?? 0.0;
          final isPromoted = pack['is_promoted'] == true;
          final promoBadge = (pack['promo_badge'] ?? '').toString();

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isPromoted ? const Color(0xFFEFF5FF) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isPromoted
                    ? const Color(0xFFC7DAFF)
                    : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3EEFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1F6FFF),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'W',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        height: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$coins ${context.tr('coins')}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$price DZD',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      if (originalPrice != null && originalPrice.isNotEmpty)
                        Text(
                          '$originalPrice DZD',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            decoration: TextDecoration.lineThrough,
                            fontSize: 12,
                          ),
                        ),
                      if (percentSaved > 0)
                        Text(
                          'Save ${percentSaved.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Color(0xFF1F6FFF),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      if (promoBadge.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 5),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3EEFF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            promoBadge,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F6FFF),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final submitted = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CoinPaymentScreen(
                                pack: pack,
                              ),
                            ),
                          );
                          if (submitted == true && mounted) {
                            await context.read<WalletProvider>().fetchWallet();
                          }
                          if (mounted) {
                            Helpers.showSnackBar(
                              context,
                              submitted == true
                                  ? 'Payment request sent for approval.'
                                  : 'Purchase was not submitted.',
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(86, 40),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(context.tr('Buy')),
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
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildTransactions(List<Map<String, dynamic>> transactions) {
    if (transactions.isEmpty) {
      return _sectionCard(
        title: context.tr('Recent Transactions'),
        child: Text(context.tr('No transactions yet.')),
      );
    }

    final items = transactions.take(_visibleTransactionsCount).toList();

    return _sectionCard(
      title: context.tr('Recent Transactions'),
      child: Column(
        children: items.map<Widget>((item) {
          final amount = _asInt(item['amount_signed']);
          final isPositive = amount >= 0;
          final reason = item['reason']?.toString() ?? 'update';
          final createdAtRaw = item['created_at']?.toString();
          DateTime? createdAt;
          if (createdAtRaw != null) {
            createdAt = DateTime.tryParse(createdAtRaw);
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isPositive
                        ? AppColors.successGreen.withOpacity(0.12)
                        : AppColors.errorRed.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isPositive ? Icons.add : Icons.remove,
                    color: isPositive
                        ? AppColors.successGreen
                        : AppColors.errorRed,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(reason.replaceAll('_', ' ')),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        createdAt != null
                            ? Helpers.formatDate(createdAt, context: context)
                            : context.tr('Just now'),
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${isPositive ? '+' : ''}$amount',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isPositive
                        ? AppColors.successGreen
                        : AppColors.errorRed,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPurchases(List<Map<String, dynamic>> purchases) {
    if (purchases.isEmpty) {
      return _sectionCard(
        title: context.tr('Purchase Requests'),
        child: Text(context.tr('No purchase requests yet.')),
      );
    }

    final items = purchases.take(_visiblePurchasesCount).toList();
    return _sectionCard(
      title: context.tr('Purchase Requests'),
      child: Column(
        children: items.map<Widget>((item) {
          final packId = (item['pack_id'] ?? '').toString();
          final coins = _asInt(item['coins_amount']);
          final status = (item['status'] ?? 'pending').toString();
          final createdAtRaw = item['created_at']?.toString();
          final createdAt =
              createdAtRaw == null ? null : DateTime.tryParse(createdAtRaw);

          Color statusColor;
          if (status == 'completed') {
            statusColor = AppColors.successGreen;
          } else if (status == 'failed') {
            statusColor = AppColors.errorRed;
          } else {
            statusColor = AppColors.warningAmber;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.receipt_long_outlined, color: statusColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$coins ${context.tr('Coins')} · $packId',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        createdAt != null
                            ? Helpers.formatDate(createdAt, context: context)
                            : context.tr('Just now'),
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildShowMoreButton({
    required bool isVisible,
    required VoidCallback onPressed,
  }) {
    if (!isVisible) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryColor,
        ),
        child: Text(context.tr('Show more')),
      ),
    );
  }

  Widget _buildCostChips(Map<String, dynamic> costs) {
    if (costs.isEmpty) return const SizedBox.shrink();
    final productCost = _asInt(costs['product']);
    final packCost = _asInt(costs['pack']);
    final promotionCost = _asInt(costs['promotion']);
    final adViewCost = _asInt(costs['ad_view']);

    return _sectionCard(
      title: context.tr('Publishing Costs'),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _chip(context.tr('Product Post'), productCost),
          _chip(context.tr('Pack Post'), packCost),
          _chip(context.tr('Promotion Post'), promotionCost),
          _chip(context.tr('Ad View'), adViewCost),
        ],
      ),
    );
  }

  Widget _buildHeroBalance(int coins) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2F80FF), Color(0xFF1F6FFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.32),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text(
              'W',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 20,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('Your Coins'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$coins',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildRequirementBanner({
    required int requiredCoins,
    required int balance,
  }) {
    final shortfall = (requiredCoins - balance).clamp(0, requiredCoins);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF1F6FFF)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${context.tr('You need')} $requiredCoins ${context.tr('coins')}. '
              '${context.tr('Balance')}: $balance. ${context.tr('Missing')}: $shortfall.',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Coin Store')),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          Consumer<WalletProvider>(
            builder: (context, wallet, _) => WinoCoinBadge(
              coins: wallet.coinsBalance,
              margin: const EdgeInsetsDirectional.only(end: 10),
            ),
          ),
        ],
      ),
      body: Consumer<WalletProvider>(
        builder: (context, wallet, _) {
          final packs = wallet.packs;

          final balanceCoins = wallet.coinsBalance;
          final purchases = wallet.purchases;

          final requiredCoins = widget.requiredCoins;
          final requiredBalance = widget.currentBalance ?? balanceCoins;

          if (_initialLoad && wallet.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (requiredCoins != null)
                  _buildRequirementBanner(
                    requiredCoins: requiredCoins,
                    balance: requiredBalance,
                  ),
                if (requiredCoins != null) const SizedBox(height: 12),
                _buildHeroBalance(balanceCoins),
                const SizedBox(height: 16),
                _buildCostChips(wallet.costs),
                if (wallet.costs.isNotEmpty) const SizedBox(height: 16),
                _buildPackList(
                  title: context.tr('Coin Packs'),
                  packs: packs,
                  isLoading: wallet.isLoading,
                ),
                const SizedBox(height: 16),
                Column(
                  children: [
                    _buildPurchases(purchases),
                    _buildShowMoreButton(
                      isVisible: purchases.length > _visiblePurchasesCount,
                      onPressed: () {
                        setState(() {
                          _visiblePurchasesCount += 5;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  children: [
                    _buildTransactions(wallet.transactions),
                    _buildShowMoreButton(
                      isVisible: wallet.transactions.length >
                          _visibleTransactionsCount,
                      onPressed: () {
                        setState(() {
                          _visibleTransactionsCount += 5;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
