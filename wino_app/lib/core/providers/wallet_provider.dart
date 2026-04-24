import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../services/wallet_service.dart';
import '../utils/app_logger.dart';

class WalletProvider with ChangeNotifier {
  int _coinsBalance = 0;
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _purchases = [];
  List<Map<String, dynamic>> _packs = const [];
  Map<String, dynamic> _costs = const {};
  bool _isLoading = false;
  String? _error;

  int get coinsBalance => _coinsBalance;
  int get postCoins => _coinsBalance;
  int get adViewCoins => _coinsBalance;
  List<Map<String, dynamic>> get transactions => _transactions;
  List<Map<String, dynamic>> get purchases => _purchases;
  List<Map<String, dynamic>> get packs => _packs;
  Map<String, dynamic> get costs => _costs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchWallet({bool notifyStart = true}) async {
    _isLoading = true;
    _error = null;
    if (notifyStart) {
      notifyListeners();
    }
    try {
      final data = await WalletService.fetchWallet();
      _coinsBalance =
          (data['coins_balance'] ?? data['post_coins_balance'] ?? 0) as int;
      final tx = (data['recent_transactions'] as List?) ?? const [];
      _transactions = tx.cast<Map<String, dynamic>>();
      final buys = (data['recent_purchases'] as List?) ?? const [];
      _purchases = buys.cast<Map<String, dynamic>>();
      _costs = (data['costs'] as Map?)?.cast<String, dynamic>() ?? const {};
      AppLogger.info('Wallet fetched successfully: $_coinsBalance coins.');
    } catch (e, stack) {
      _error = e.toString();
      AppLogger.error('Failed to fetch wallet', error: e, stackTrace: stack);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPacks({bool notifyAfter = true}) async {
    try {
      final data = await WalletService.fetchPacks();
      final raw = (data['packs'] as List?) ?? const [];
      _packs = raw.cast<Map<String, dynamic>>();
      AppLogger.info('Wallet packs fetched successfully.');
      if (notifyAfter) {
        notifyListeners();
      }
    } catch (e, stack) {
      _error = e.toString();
      AppLogger.error('Failed to fetch wallet packs',
          error: e, stackTrace: stack);
      if (notifyAfter) {
        notifyListeners();
      }
    }
  }

  Future<Map<String, dynamic>> buyPack({
    required String packId,
    required List<XFile> images,
    String paymentNote = '',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await WalletService.buyPack(
        packId: packId,
        images: images,
        paymentNote: paymentNote,
      );
      AppLogger.success('Successfully submitted wallet pack purchase $packId');
      await fetchWallet();
      return response;
    } catch (e, stack) {
      _error = e.toString();
      AppLogger.error('Failed to buy wallet pack', error: e, stackTrace: stack);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> hydrateForCoinStore() async {
    _isLoading = true;
    _error = null;
    try {
      final walletData = await WalletService.fetchWallet();
      _coinsBalance = (walletData['coins_balance'] ??
          walletData['post_coins_balance'] ??
          0) as int;
      final tx = (walletData['recent_transactions'] as List?) ?? const [];
      _transactions = tx.cast<Map<String, dynamic>>();
      final buys = (walletData['recent_purchases'] as List?) ?? const [];
      _purchases = buys.cast<Map<String, dynamic>>();
      _costs =
          (walletData['costs'] as Map?)?.cast<String, dynamic>() ?? const {};

      final packsData = await WalletService.fetchPacks();
      final rawPacks = (packsData['packs'] as List?) ?? const [];
      _packs = rawPacks.cast<Map<String, dynamic>>();
      AppLogger.info('hydrateForCoinStore completed successfully');
    } catch (e, stack) {
      _error = e.toString();
      AppLogger.error('Failed to hydrate coin store',
          error: e, stackTrace: stack);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
