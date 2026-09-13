import 'package:flutter/material.dart';
import 'package:flutter_production_grade/bootstrap.dart';
import 'package:flutter_production_grade/core/data/services/storage/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSettingsService implements SettingsService {
  ThemeMode? theme;
  Locale? locale;

  @override
  Future<Locale?> readLocale() async => locale;

  @override
  Future<ThemeMode?> readThemeMode() async => theme;

  @override
  Future<void> writeLocale(Locale value) async => locale = value;

  @override
  Future<void> writeThemeMode(ThemeMode mode) async => theme = mode;
}

void main() {
  testWidgets('seedThemeMode matches dark OS brightness and persists it', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    final settings = _FakeSettingsService();

    final mode = await seedThemeMode(settings);

    expect(mode, ThemeMode.dark);
    expect(settings.theme, ThemeMode.dark);
  });

  testWidgets('seedLocale picks a supported OS locale', (tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('id');
    final settings = _FakeSettingsService();

    final locale = await seedLocale(settings);

    expect(locale, const Locale('id'));
    expect(settings.locale, const Locale('id'));
  });

  testWidgets('seedLocale falls back to en for an unsupported OS locale', (
    tester,
  ) async {
    tester.platformDispatcher.localeTestValue = const Locale('fr');
    final settings = _FakeSettingsService();

    final locale = await seedLocale(settings);

    expect(locale, const Locale('en'));
    expect(settings.locale, const Locale('en'));
  });
}
