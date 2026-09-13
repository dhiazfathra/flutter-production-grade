import 'package:flutter/material.dart';
import 'package:flutter_production_grade/core/data/services/storage/settings_service.dart';
import 'package:flutter_production_grade/features/settings/ui/view_models/locale_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSettings implements SettingsService {
  _FakeSettings({this.storedLocale});

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
  group('LocaleViewModel', () {
    test('uses the initial locale', () {
      final container = ProviderContainer(
        overrides: [
          settingsServiceProvider.overrideWithValue(_FakeSettings()),
          initialLocaleProvider.overrideWithValue(const Locale('en')),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(localeViewModelProvider), const Locale('en'));
    });

    test('select persists and updates the state', () async {
      final settings = _FakeSettings(storedLocale: const Locale('en'));
      final container = ProviderContainer(
        overrides: [
          settingsServiceProvider.overrideWithValue(settings),
          initialLocaleProvider.overrideWithValue(const Locale('en')),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(localeViewModelProvider.notifier)
          .select(const Locale('id'));

      expect(container.read(localeViewModelProvider), const Locale('id'));
      expect(settings.storedLocale, const Locale('id'));
    });
  });
}
