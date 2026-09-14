import 'package:flutter/material.dart';
import 'package:flutter_production_grade/core/data/services/storage/settings_service.dart';
import 'package:flutter_production_grade/features/settings/ui/view_models/theme_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSettings implements SettingsService {
  _FakeSettings({this.storedTheme});

  ThemeMode? storedTheme;
  Locale? storedLocale;

  @override
  Future<ThemeMode?> readThemeMode() async => storedTheme;

  @override
  Future<void> writeThemeMode(ThemeMode mode) async => storedTheme = mode;

  @override
  Future<Locale?> readLocale() async => storedLocale;

  @override
  Future<void> writeLocale(Locale locale) async => storedLocale = locale;
}

void main() {
  group('ThemeViewModel', () {
    test('uses the stored mode when one exists', () {
      final container = ProviderContainer(
        overrides: [
          settingsServiceProvider.overrideWithValue(
            _FakeSettings(storedTheme: ThemeMode.dark),
          ),
          initialThemeModeProvider.overrideWithValue(ThemeMode.dark),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(themeViewModelProvider), ThemeMode.dark);
    });

    test('toggle flips and persists a resolved mode, never system', () async {
      final settings = _FakeSettings(storedTheme: ThemeMode.light);
      final container = ProviderContainer(
        overrides: [
          settingsServiceProvider.overrideWithValue(settings),
          initialThemeModeProvider.overrideWithValue(ThemeMode.light),
        ],
      );
      addTearDown(container.dispose);

      await container.read(themeViewModelProvider.notifier).toggle();

      expect(container.read(themeViewModelProvider), ThemeMode.dark);
      expect(settings.storedTheme, ThemeMode.dark);
      expect(settings.storedTheme, isNot(ThemeMode.system));
    });
  });
}
