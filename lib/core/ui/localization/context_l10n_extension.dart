import 'package:flutter/widgets.dart';

import 'package:flutter_production_grade/l10n/generated/app_localizations.dart';

extension L10nExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
