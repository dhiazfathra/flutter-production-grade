import 'package:flutter/material.dart';
import 'package:flutter_production_grade/app.dart';
import 'package:flutter_production_grade/config/app_config.dart';
import 'package:flutter_production_grade/config/flavor.dart';
import 'package:flutter_production_grade/core/data/services/storage/settings_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

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
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app boots and renders the home screen', (tester) async {
    final config = AppConfig.validate(
      flavor: Flavor.dev,
      baseUrl: 'https://example.com',
      appName: 'Test App',
      sentryDsn: '',
      minSupportedVersion: '1.0.0',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(config),
          settingsServiceProvider.overrideWithValue(_FakeSettingsService()),
          initialThemeModeProvider.overrideWithValue(ThemeMode.light),
          initialLocaleProvider.overrideWithValue(const Locale('en')),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
