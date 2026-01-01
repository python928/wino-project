import 'package:flutter/material.dart';

import '../routing/route_generator.dart' as legacy;

/// خيار A (الأبسط): Router مركزي عبر onGenerateRoute.
///
/// ملاحظة: حالياً نفوّض للمنطق الموجود في `core/routing/route_generator.dart`
/// لتجنب كسر المسارات الحالية. لاحقاً يمكن نقل كل المنطق هنا إذا رغبت.
Route<dynamic> onGenerateRoute(RouteSettings settings) {
  return legacy.RouteGenerator.generateRoute(settings);
}
