import 'package:flutter/material.dart';
import 'package:flutter_production_grade/core/data/services/storage/settings_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferencesSettingsService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    service = SharedPreferencesSettingsService(
      await SharedPreferences.getInstance(),
    );
  });

  group('SharedPreferencesSettingsService', () {
    test('readThemeMode is null before any write', () async {
      expect(await service.readThemeMode(), isNull);
    });

    test('readThemeMode returns dark after writing dark', () async {
      await service.writeThemeMode(ThemeMode.dark);
      expect(await service.readThemeMode(), ThemeMode.dark);
    });

    test('writeThemeMode rejects ThemeMode.system', () {
      expect(
        () => service.writeThemeMode(ThemeMode.system),
        throwsAssertionError,
      );
    });

    test('readLocale round-trips a written Locale', () async {
      await service.writeLocale(const Locale('id'));
      expect(await service.readLocale(), const Locale('id'));
    });
  });

  group('guard-rail providers', () {
    // Riverpod wraps a provider's synchronous throw in a ProviderException,
    // so assert on the message rather than the (internal) exception type.
    test('settingsServiceProvider throws when not overridden', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        () => container.read(settingsServiceProvider),
        throwsA(predicate((e) => e.toString().contains('must be overridden'))),
      );
    });

    test('initialThemeModeProvider throws when not overridden', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        () => container.read(initialThemeModeProvider),
        throwsA(predicate((e) => e.toString().contains('must be overridden'))),
      );
    });

    test('initialLocaleProvider throws when not overridden', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        () => container.read(initialLocaleProvider),
        throwsA(predicate((e) => e.toString().contains('must be overridden'))),
      );
    });
  });
}
