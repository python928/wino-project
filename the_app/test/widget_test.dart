import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dzlocal_shop/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DzLocalApp());

    // Verify that the app loads successfully
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
