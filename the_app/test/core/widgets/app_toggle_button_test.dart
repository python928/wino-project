import 'package:dzlocal_shop/core/widgets/app_toggle_button.dart';
import 'package:dzlocal_shop/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'AppToggleButtonGroup scrollable layout does not throw',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListView(
              children: [
                AppToggleButtonGroup(
                  options: const [
                    ToggleOption(
                      label: 'Very long campaign option label',
                      value: 'campaign',
                    ),
                    ToggleOption(
                      label: 'Another long discount option label',
                      value: 'discount',
                    ),
                    ToggleOption(
                      label: 'Pack promotion option label',
                      value: 'pack',
                    ),
                  ],
                  selectedIndex: 0,
                  onChanged: (_) {},
                  compact: true,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(-120, 0),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(AppToggleButton), findsNWidgets(3));
    },
  );
}
