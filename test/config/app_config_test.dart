import 'package:flutter_production_grade/config/app_config.dart';
import 'package:flutter_production_grade/config/flavor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig', () {
    test('names the missing key rather than failing later', () {
      expect(
        () => AppConfig.validate(
          flavor: Flavor.dev,
          baseUrl: '',
          appName: 'FPG',
          sentryDsn: '',
          minSupportedVersion: '1.0.0',
        ),
        throwsA(
          isA<MissingConfigException>().having((e) => e.key, 'key', 'BASE_URL'),
        ),
      );
    });

    test('dev does not require a sentry dsn', () {
      final config = AppConfig.validate(
        flavor: Flavor.dev,
        baseUrl: 'https://dummyjson.com',
        appName: 'FPG dev',
        sentryDsn: '',
        minSupportedVersion: '1.0.0',
      );
      expect(config.sentryDsn, isEmpty);
    });

    test('prod requires a sentry dsn', () {
      expect(
        () => AppConfig.validate(
          flavor: Flavor.prod,
          baseUrl: 'https://dummyjson.com',
          appName: 'FPG',
          sentryDsn: '',
          minSupportedVersion: '1.0.0',
        ),
        throwsA(
          isA<MissingConfigException>().having(
            (e) => e.key,
            'key',
            'SENTRY_DSN',
          ),
        ),
      );
    });

    test('MissingConfigException.toString names the key', () {
      expect(
        const MissingConfigException('BASE_URL').toString(),
        contains('BASE_URL'),
      );
    });

    test('fromEnvironment reads the compile-time environment', () {
      // `flutter test` runs with `--dart-define-from-file=config/dev.json`
      // (see the Makefile), so this exercises the real dart-define values.
      final config = AppConfig.fromEnvironment(Flavor.dev);
      expect(config.appName, isNotEmpty);
      expect(config.baseUrl, isNotEmpty);
    });
  });

  test('appConfigProvider throws when not overridden', () {
    // Riverpod wraps a provider's synchronous throw in a ProviderException,
    // so assert on the message rather than the (internal) exception type.
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(
      () => container.read(appConfigProvider),
      throwsA(predicate((e) => e.toString().contains('must be overridden'))),
    );
  });
}
