import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_production_grade/app.dart';
import 'package:flutter_production_grade/config/app_config.dart';
import 'package:flutter_production_grade/config/flavor.dart';
import 'package:flutter_production_grade/core/data/services/storage/settings_service.dart';
import 'package:flutter_production_grade/core/platform/url_strategy.dart';
import 'package:flutter_production_grade/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> bootstrap(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  configureUrlStrategy();

  final config = AppConfig.fromEnvironment(flavor);
  final settings = SharedPreferencesSettingsService(
    await SharedPreferences.getInstance(),
  );

  final themeMode =
      await settings.readThemeMode() ?? await seedThemeMode(settings);
  final locale = await settings.readLocale() ?? await seedLocale(settings);

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        settingsServiceProvider.overrideWithValue(settings),
        initialThemeModeProvider.overrideWithValue(themeMode),
        initialLocaleProvider.overrideWithValue(locale),
      ],
      child: const App(),
    ),
  );
}

/// First launch only: match the OS once, then the stored value wins (ADR-0009).
@visibleForTesting
Future<ThemeMode> seedThemeMode(SettingsService settings) async {
  final mode =
      WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark
      ? ThemeMode.dark
      : ThemeMode.light;
  await settings.writeThemeMode(mode);
  return mode;
}

/// First launch only: match the OS locale against the supported set (ADR-0027).
@visibleForTesting
Future<Locale> seedLocale(SettingsService settings) async {
  final osCode = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  final locale =
      AppLocalizations.supportedLocales
          .where((l) => l.languageCode == osCode)
          .firstOrNull ??
      const Locale('en');
  await settings.writeLocale(locale);
  return locale;
}
