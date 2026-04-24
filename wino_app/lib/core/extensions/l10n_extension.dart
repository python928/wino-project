import 'package:flutter/widgets.dart';

import '../localization/runtime_translations.dart';
import '../../l10n/app_localizations.dart';

extension L10nBuildContextExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  String tr(String text) => RuntimeTranslations.translate(this, text);
}
