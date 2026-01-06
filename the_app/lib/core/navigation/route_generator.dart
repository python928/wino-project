import 'package:flutter/material.dart';

import '../routing/route_generator.dart' as legacy;

/// Option A (simplest): Central Router via onGenerateRoute.
///
/// Note: Currently delegates to logic in `core/routing/route_generator.dart`
/// to avoid breaking current routes. All logic can be moved here later if desired.
Route<dynamic> onGenerateRoute(RouteSettings settings) {
  return legacy.RouteGenerator.generateRoute(settings);
}
