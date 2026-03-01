import '../config/api_config.dart';
import 'api_service.dart';
import '../../data/models/subscription_plan_model.dart';

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
  }) async {
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
}
