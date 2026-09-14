import 'package:flutter_production_grade/config/flavor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MissingConfigException implements Exception {
  const MissingConfigException(this.key);

  final String key;

  @override
  String toString() =>
      'Missing required configuration key: $key. '
      'Pass it with --dart-define-from-file=config/<flavor>.json';
}

class AppConfig {
  const AppConfig._({
    required this.flavor,
    required this.baseUrl,
    required this.appName,
    required this.sentryDsn,
    required this.minSupportedVersion,
  });

  factory AppConfig.fromEnvironment(Flavor flavor) => AppConfig.validate(
    flavor: flavor,
    baseUrl: const String.fromEnvironment('BASE_URL'),
    appName: const String.fromEnvironment('APP_NAME'),
    sentryDsn: const String.fromEnvironment('SENTRY_DSN'),
    minSupportedVersion: const String.fromEnvironment('MIN_SUPPORTED_VERSION'),
  );

  /// Separated from [AppConfig.fromEnvironment] so the validation rules are
  /// testable without a compile-time environment.
  factory AppConfig.validate({
    required Flavor flavor,
    required String baseUrl,
    required String appName,
    required String sentryDsn,
    required String minSupportedVersion,
  }) {
    final required = <String, String>{
      'BASE_URL': baseUrl,
      'APP_NAME': appName,
      'MIN_SUPPORTED_VERSION': minSupportedVersion,
      if (flavor.isProduction) 'SENTRY_DSN': sentryDsn,
    };
    for (final entry in required.entries) {
      if (entry.value.isEmpty) {
        throw MissingConfigException(entry.key);
      }
    }
    return AppConfig._(
      flavor: flavor,
      baseUrl: baseUrl,
      appName: appName,
      sentryDsn: sentryDsn,
      minSupportedVersion: minSupportedVersion,
    );
  }

  final Flavor flavor;
  final String baseUrl;
  final String appName;
  final String sentryDsn;
  final String minSupportedVersion;
}

final appConfigProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError('appConfigProvider must be overridden'),
);
