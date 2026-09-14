import 'package:flutter/material.dart';
import 'package:flutter_production_grade/core/data/services/storage/settings_service.dart';
import 'package:flutter_production_grade/routing/router.dart';
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
  test('resolves /settings to the settings route', () {
    final container = ProviderContainer(
      overrides: [
        settingsServiceProvider.overrideWithValue(_FakeSettings()),
        initialThemeModeProvider.overrideWithValue(ThemeMode.light),
        initialLocaleProvider.overrideWithValue(const Locale('en')),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    final match = router.configuration.findMatch(Uri.parse('/settings'));

    expect(match.matches, isNotEmpty);
    expect(match.matches.last.matchedLocation, '/settings');
  });

  test('resolves an unknown path to the error builder', () {
    final container = ProviderContainer(
      overrides: [
        settingsServiceProvider.overrideWithValue(_FakeSettings()),
        initialThemeModeProvider.overrideWithValue(ThemeMode.light),
        initialLocaleProvider.overrideWithValue(const Locale('en')),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    final match = router.configuration.findMatch(Uri.parse('/nope'));

    expect(match.error, isNotNull);
  });
}
