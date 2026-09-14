import 'package:flutter/material.dart';

import 'package:flutter_production_grade/core/ui/themes/app_theme.dart';
import 'package:flutter_production_grade/l10n/generated/app_localizations.dart';

/// Wraps a widget under test with the app's theme and localizations, sized
/// to its own content rather than filling the screen — golden scenarios
/// render one widget at a time, not a full app shell.
Widget goldenApp({required Widget child, required ThemeData theme}) {
  return Localizations(
    locale: const Locale('en'),
    delegates: AppLocalizations.localizationsDelegates,
    child: Theme(
      data: theme,
      child: Material(
        color: theme.colorScheme.surface,
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );
}

final ThemeData lightTheme = AppTheme.light();
final ThemeData darkTheme = AppTheme.dark();
