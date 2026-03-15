import '../config/api_config.dart';
import 'api_service.dart';
import '../../data/models/subscription_plan_model.dart';
import 'package:image_picker/image_picker.dart';

class SubscriptionCatalogData {
  final List<SubscriptionPlanModel> plans;
  final String rib;
  final String instructions;

  const SubscriptionCatalogData({
    required this.plans,
    required this.rib,
    required this.instructions,
  });
}

class SubscriptionService {
  static Future<SubscriptionCatalogData> fetchCatalogData() async {
    final resp = await ApiService.get(ApiConfig.subscriptionPublicData);
    final plansRaw = resp['plans'] ?? [];
    final paymentConfig =
        (resp['payment_config'] ?? {}) as Map<String, dynamic>;
    final plans = (plansRaw as List)
        .map((e) => SubscriptionPlanModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return SubscriptionCatalogData(
      plans: plans,
      rib: (paymentConfig['rib'] ?? '').toString(),
      instructions: (paymentConfig['instructions'] ?? '').toString(),
    );
  }

  static Future<void> submitPaymentRequest({
    required int planId,
    required String paymentNote,
    List<XFile> images = const [],
  }) async {
    if (images.isNotEmpty) {
      await ApiService.postMultipartMany(
        ApiConfig.subscriptionPaymentRequests,
        {
          'plan': planId.toString(),
          'payment_note': paymentNote,
        },
        images,
        fieldName: 'images',
      );
      return;
    }
    await ApiService.post(ApiConfig.subscriptionPaymentRequests, {
      'plan': planId,
      'payment_note': paymentNote,
    });
  }

  static bool isSubscriptionRequiredError(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('subscription_required') ||
        text.contains('free post limit') ||
        text.contains('subscribe to continue');
  }

  static Future<Map<String, dynamic>> fetchMerchantDashboard({
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    var endpoint = ApiConfig.subscriptionMerchantDashboard;
    final query = <String, String>{};
    if (dateFrom != null) {
      query['date_from'] = dateFrom.toIso8601String().split('T').first;
    }
    if (dateTo != null) {
      query['date_to'] = dateTo.toIso8601String().split('T').first;
    }
    if (query.isNotEmpty) {
      endpoint = '$endpoint?${Uri(queryParameters: query).query}';
    }

    final resp = await ApiService.get(endpoint);
    if (resp is Map<String, dynamic>) return resp;
    return <String, dynamic>{};
  }
}
