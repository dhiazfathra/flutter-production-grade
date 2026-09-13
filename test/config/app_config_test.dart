import 'package:flutter_production_grade/config/app_config.dart';
import 'package:flutter_production_grade/config/flavor.dart';
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
  });
}
