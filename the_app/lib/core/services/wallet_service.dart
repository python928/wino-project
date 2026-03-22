import 'package:image_picker/image_picker.dart';

import '../config/api_config.dart';
import 'api_service.dart';

class WalletService {
  static Future<Map<String, dynamic>> fetchWallet() async {
    final resp = await ApiService.get(ApiConfig.wallet);
    return resp is Map<String, dynamic> ? resp : <String, dynamic>{};
  }

  static Future<Map<String, dynamic>> fetchPacks() async {
    final resp = await ApiService.get(ApiConfig.walletPacks);
    return resp is Map<String, dynamic> ? resp : <String, dynamic>{};
  }

  static Future<Map<String, dynamic>> buyPack({
    required String packId,
    required List<XFile> images,
    String paymentNote = '',
  }) async {
    final resp = await ApiService.postMultipartMany(
      ApiConfig.walletBuy,
      {
        'pack_id': packId,
        if (paymentNote.trim().isNotEmpty) 'payment_note': paymentNote.trim(),
      },
      images,
    );
    return resp is Map<String, dynamic> ? resp : <String, dynamic>{};
  }
}
