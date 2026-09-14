import 'package:flutter/material.dart';
import 'package:flutter_production_grade/app.dart';
import 'package:flutter_production_grade/config/app_config.dart';
import 'package:flutter_production_grade/config/flavor.dart';
import 'package:flutter_production_grade/core/data/services/storage/settings_service.dart';
import 'package:flutter_production_grade/features/settings/ui/views/settings_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final config = AppConfig.validate(
    flavor: Flavor.dev,
    baseUrl: 'https://example.com',
    appName: 'Test App',
    sentryDsn: '',
    minSupportedVersion: '1.0.0',
  );

  Widget buildApp({required ThemeMode themeMode, required Locale locale}) {
    return ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        settingsServiceProvider.overrideWithValue(_FakeSettingsService()),
        initialThemeModeProvider.overrideWithValue(themeMode),
        initialLocaleProvider.overrideWithValue(locale),
      ],
      child: const App(),
    );
  }

  testWidgets('renders with initial theme mode and locale from l10n', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(themeMode: ThemeMode.light, locale: const Locale('en')),
    );
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);
    final context = tester.element(find.byType(Scaffold).first);
    expect(app.onGenerateTitle!(context), 'Flutter Production Grade');
  });

  testWidgets('rebuilds with the other theme when the provider changes', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(themeMode: ThemeMode.dark, locale: const Locale('en')),
    );
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });

  testWidgets('navigates from home to settings and back', (tester) async {
    await tester.pumpWidget(
      buildApp(themeMode: ThemeMode.light, locale: const Locale('en')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsNothing);

    await tester.tap(find.widgetWithText(TextButton, 'Settings'));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
  });
}
