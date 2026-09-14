import 'package:flutter/material.dart';
import 'package:flutter_production_grade/core/data/services/storage/settings_service.dart';
import 'package:flutter_production_grade/features/settings/ui/view_models/locale_view_model.dart';
import 'package:flutter_production_grade/features/settings/ui/view_models/theme_view_model.dart';
import 'package:flutter_production_grade/features/settings/ui/views/settings_screen.dart';
import 'package:flutter_production_grade/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSettings implements SettingsService {
  @override
  Future<ThemeMode?> readThemeMode() async => null;

  @override
  Future<void> writeThemeMode(ThemeMode mode) async {}

  @override
  Future<Locale?> readLocale() async => null;

  @override
  Future<void> writeLocale(Locale locale) async {}
}

void main() {
  testWidgets('tapping the theme toggle flips themeViewModelProvider', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        settingsServiceProvider.overrideWithValue(_FakeSettings()),
        initialThemeModeProvider.overrideWithValue(ThemeMode.light),
        initialLocaleProvider.overrideWithValue(const Locale('en')),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(),
        ),
      ),
    );

    expect(container.read(themeViewModelProvider), ThemeMode.light);

    await tester.tap(find.byKey(const ValueKey('theme_toggle')));
    await tester.pump();

    expect(container.read(themeViewModelProvider), ThemeMode.dark);
  });

  testWidgets('tapping a locale segment flips localeViewModelProvider', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        settingsServiceProvider.overrideWithValue(_FakeSettings()),
        initialThemeModeProvider.overrideWithValue(ThemeMode.light),
        initialLocaleProvider.overrideWithValue(const Locale('en')),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(),
        ),
      ),
    );

    expect(container.read(localeViewModelProvider), const Locale('en'));

    final otherLocale = AppLocalizations.supportedLocales.firstWhere(
      (locale) => locale.languageCode != 'en',
    );
    await tester.tap(find.text(otherLocale.languageCode));
    await tester.pump();

    expect(container.read(localeViewModelProvider), otherLocale);
  });
}
