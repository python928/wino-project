import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wino/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wino/core/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();

    // Build our app and trigger a frame.
    await tester.pumpWidget(const WinoApp());

    // Verify that the app loads successfully
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
