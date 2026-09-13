# Scaffold Plan 1 — Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development
> (recommended) or superpowers:executing-plans to implement this plan task-by-task.
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A Flutter app that builds and runs on iOS, Android, and web in three flavors, with
themes, localization, a design system, typed errors, routing, and a green CI pipeline — and no
feature code yet.

**Architecture:** Feature-first directories under `lib/features/`, shared code under `lib/core/`,
dependency direction `ui -> domain <- data`. Riverpod providers are generated with
`riverpod_generator`; every provider that touches a platform is defined over an interface so tests
substitute a fake through `ProviderScope(overrides:)`.

**Tech Stack:** Flutter 3.47.4 (fvm), flutter_riverpod 3.4.3, riverpod_annotation 4.0.7,
riverpod_generator 4.0.9, freezed 4.0.1, json_serializable 6.14.1, go_router 18.0.1,
shared_preferences 2.5.5, build_runner 2.16.1, very_good_analysis 11.0.0, custom_lint 0.8.1,
riverpod_lint 3.1.9, mockito 5.8.1, alchemist 0.14.0, skeletonizer 3.0.0.

**Spec:** `docs/superpowers/specs/2026-09-13-flutter-production-scaffold-design.md`
(ADRs 0001, 0002, 0003, 0007, 0008, 0009, 0010, 0011, 0019, 0022, 0023, 0025, 0027, 0028)

## Global Constraints

- Flutter 3.47.4 stable, pinned by `.fvmrc`. Every command runs through `fvm flutter` / `fvm dart`.
- Targets: iOS, Android, web. No desktop.
- Package name: `flutter_production_grade`. Bundle id base: `com.dhiazfathra.fpg`.
- `lib/features/<feature>/{data,domain,ui}`; features never import each other; `core/` imports no
  feature.
- Domain files import no Flutter, no dio, no drift. Pure Dart only.
- Every user-visible string comes from generated l10n. No string literals in widgets.
- No literal colours, no literal paddings in feature code — `Theme.of(context)` and `AppSpacing`.
- Every interactive widget carries a `ValueKey` from the list in the spec's testing section.
- Coverage gate: 100% of measured lines. Exclusions are explicit entries in `tool/coverage.sh`.
- Generated files (`*.g.dart`, `*.freezed.dart`) are committed.
- Commits are conventional (`feat`, `fix`, `test`, `chore`, `docs`, `refactor`). Never
  `--no-verify`. Never an AI-attribution trailer.

---

### Task 1: Project creation and SDK pinning

**Files:**

- Create: `.fvmrc`, `pubspec.yaml`, `analysis_options.yaml`, `Makefile`, `.gitignore` (extend)
- Create: `lib/main.dart` (temporary), `test/smoke_test.dart`

**Interfaces:**

- Consumes: nothing.
- Produces: a buildable package named `flutter_production_grade`; `make get`, `make gen`,
  `make lint`, `make test` targets that every later task uses.

- [ ] **Step 1: Create the Flutter project in place**

The repository already exists with `docs/` and `README.md`, so create into a temp dir and move the
generated files in, rather than letting `flutter create` fight the existing tree.

```bash
~/fvm/default/bin/flutter create --org com.dhiazfathra \
  --project-name flutter_production_grade \
  --platforms ios,android,web \
  /tmp/fpg-create
rsync -a --exclude .git /tmp/fpg-create/ .
rm -rf /tmp/fpg-create test/widget_test.dart
```

- [ ] **Step 2: Pin the SDK**

```bash
fvm use 3.47.4 --force
```

Verify `.fvmrc` contains `{"flutter": "3.47.4"}` and commit it. Add `.fvm/` to `.gitignore` except
`.fvmrc`:

```gitignore
.fvm/
!.fvmrc
```

- [ ] **Step 3: Write the dependency block in `pubspec.yaml`**

```yaml
name: flutter_production_grade
description: Production-grade Flutter scaffold.
publish_to: none
version: 0.1.0+1

environment:
  sdk: ^3.10.0

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  flutter_riverpod: ^3.4.3
  riverpod_annotation: ^4.0.7
  go_router: ^18.0.1
  freezed_annotation: ^3.1.0
  json_annotation: ^4.9.0
  shared_preferences: ^2.5.5
  intl: any
  skeletonizer: ^3.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  build_runner: ^2.16.1
  riverpod_generator: ^4.0.9
  riverpod_lint: ^3.1.9
  custom_lint: ^0.8.1
  freezed: ^4.0.1
  json_serializable: ^6.14.1
  go_router_builder: ^4.0.0
  build_verify: ^3.1.0
  mockito: ^5.8.1
  alchemist: ^0.14.0
  very_good_analysis: ^11.0.0

flutter:
  uses-material-design: true
  generate: true
```

- [ ] **Step 4: Write `analysis_options.yaml`**

```yaml
include: package:very_good_analysis/analysis_options.11.0.0.yaml

analyzer:
  plugins:
    - custom_lint
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "lib/l10n/generated/**"
  errors:
    invalid_annotation_target: ignore

linter:
  rules:
    public_member_api_docs: false
```

- [ ] **Step 5: Write the `Makefile`**

```makefile
FLUTTER := fvm flutter
DART := fvm dart

.PHONY: get gen watch l10n run-dev test cov lint goldens integration schema doctor

get:
	$(FLUTTER) pub get

gen:
	$(DART) run build_runner build --delete-conflicting-outputs

watch:
	$(DART) run build_runner watch --delete-conflicting-outputs

l10n:
	$(FLUTTER) gen-l10n

run-dev:
	$(FLUTTER) run --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json

test:
	$(FLUTTER) test

cov:
	$(FLUTTER) test --coverage && ./tool/coverage.sh

goldens:
	$(FLUTTER) test --update-goldens --tags golden

lint:
	$(DART) format --set-exit-if-changed lib test
	$(FLUTTER) analyze --fatal-infos
	$(DART) run custom_lint

integration:
	$(FLUTTER) drive --driver=test_driver/integration_test.dart \
		--target=integration_test/app_test.dart -d chrome

doctor:
	./tool/doctor.sh
```

- [ ] **Step 6: Write a smoke test that proves the toolchain works**

`test/smoke_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toolchain is wired', () {
    expect(1 + 1, 2);
  });
}
```

- [ ] **Step 7: Run it**

Run: `make get && make test`
Expected: PASS, one test.

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "chore: create flutter project, pin sdk, add tooling"
```

---

### Task 2: Result and AppError

**Files:**

- Create: `lib/core/utils/app_error.dart`, `lib/core/utils/result.dart`
- Test: `test/core/utils/result_test.dart`

**Interfaces:**

- Consumes: nothing.
- Produces:
  - `sealed class AppError` with variants `AppError.network()`, `AppError.unauthorized()`,
    `AppError.notFound()`, `AppError.server(int statusCode)`, `AppError.unknown(Object cause)`.
  - `sealed class Result<T>` with `Ok<T>(T value)` and `Err<T>(AppError error)`, plus
    `T? get valueOrNull`, `AppError? get errorOrNull`, and
    `R fold<R>({required R Function(T) ok, required R Function(AppError) err})`.
  - Every repository method in later plans returns `Future<Result<T>>`.

- [ ] **Step 1: Write the failing test**

`test/core/utils/result_test.dart`:

```dart
import 'package:flutter_production_grade/core/utils/app_error.dart';
import 'package:flutter_production_grade/core/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    test('Ok exposes its value and no error', () {
      const result = Result<int>.ok(3);
      expect(result.valueOrNull, 3);
      expect(result.errorOrNull, isNull);
    });

    test('Err exposes its error and no value', () {
      const result = Result<int>.err(AppError.unauthorized());
      expect(result.valueOrNull, isNull);
      expect(result.errorOrNull, const AppError.unauthorized());
    });

    test('fold runs exactly one branch', () {
      const ok = Result<int>.ok(1);
      const err = Result<int>.err(AppError.network());
      expect(ok.fold(ok: (v) => 'v$v', err: (_) => 'e'), 'v1');
      expect(err.fold(ok: (v) => 'v$v', err: (_) => 'e'), 'e');
    });

    test('AppError.server carries its status code', () {
      const error = AppError.server(503);
      expect(error, const AppError.server(503));
      expect(error, isNot(const AppError.server(500)));
    });
  });
}
```

- [ ] **Step 2: Run it and watch it fail**

Run: `fvm flutter test test/core/utils/result_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:.../result.dart'`.

- [ ] **Step 3: Write `app_error.dart`**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_error.freezed.dart';

@freezed
sealed class AppError with _$AppError {
  const factory AppError.network() = NetworkError;
  const factory AppError.unauthorized() = UnauthorizedError;
  const factory AppError.notFound() = NotFoundError;
  const factory AppError.server(int statusCode) = ServerError;
  const factory AppError.unknown(Object cause) = UnknownError;
}
```

- [ ] **Step 4: Write `result.dart`**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import 'app_error.dart';

part 'result.freezed.dart';

@freezed
sealed class Result<T> with _$Result<T> {
  const Result._();

  const factory Result.ok(T value) = Ok<T>;
  const factory Result.err(AppError error) = Err<T>;

  T? get valueOrNull => switch (this) {
        Ok<T>(:final value) => value,
        Err<T>() => null,
      };

  AppError? get errorOrNull => switch (this) {
        Ok<T>() => null,
        Err<T>(:final error) => error,
      };

  R fold<R>({
    required R Function(T value) ok,
    required R Function(AppError error) err,
  }) =>
      switch (this) {
        Ok<T>(value: final v) => ok(v),
        Err<T>(error: final e) => err(e),
      };
}
```

- [ ] **Step 5: Generate and run**

Run: `make gen && fvm flutter test test/core/utils/result_test.dart`
Expected: PASS, 4 tests.

- [ ] **Step 6: Commit**

```bash
git add lib/core/utils test/core/utils
git commit -m "feat(core): add sealed Result and AppError"
```

---

### Task 3: Flavors and configuration

**Files:**

- Create: `lib/config/flavor.dart`, `lib/config/app_config.dart`
- Create: `config/example.json`, `config/dev.json` (git-ignored)
- Create: `lib/main.dart`, `lib/main_dev.dart`, `lib/main_staging.dart`
- Test: `test/config/app_config_test.dart`

**Interfaces:**

- Consumes: nothing.
- Produces:
  - `enum Flavor { dev, staging, prod }`
  - `class AppConfig` with `final Flavor flavor; final String baseUrl; final String appName;
final String sentryDsn; final String minSupportedVersion;` and a
    `factory AppConfig.fromEnvironment(Flavor flavor)` that throws `MissingConfigException` naming
    the first empty required key.
  - `final appConfigProvider = Provider<AppConfig>((ref) => throw UnimplementedError());` —
    overridden in `bootstrap`, and overridden again in every test.

- [ ] **Step 1: Write the failing test**

`test/config/app_config_test.dart`:

```dart
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
          isA<MissingConfigException>().having((e) => e.key, 'key', 'SENTRY_DSN'),
        ),
      );
    });
  });
}
```

- [ ] **Step 2: Run it and watch it fail**

Run: `fvm flutter test test/config/app_config_test.dart`
Expected: FAIL — missing URI.

- [ ] **Step 3: Write `flavor.dart`**

```dart
enum Flavor {
  dev,
  staging,
  prod;

  bool get isProduction => this == Flavor.prod;
}
```

- [ ] **Step 4: Write `app_config.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'flavor.dart';

class MissingConfigException implements Exception {
  const MissingConfigException(this.key);

  final String key;

  @override
  String toString() => 'Missing required configuration key: $key. '
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
        minSupportedVersion:
            const String.fromEnvironment('MIN_SUPPORTED_VERSION'),
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
```

- [ ] **Step 5: Run the test**

Run: `fvm flutter test test/config/app_config_test.dart`
Expected: PASS, 3 tests.

- [ ] **Step 6: Write the config files**

`config/example.json` (committed):

```json
{
  "BASE_URL": "https://dummyjson.com",
  "APP_NAME": "FPG dev",
  "SENTRY_DSN": "",
  "MIN_SUPPORTED_VERSION": "1.0.0"
}
```

Add to `.gitignore`:

```gitignore
config/*.json
!config/example.json
```

Then `cp config/example.json config/dev.json`.

- [ ] **Step 7: Write the three entry points**

`lib/main_dev.dart`:

```dart
import 'bootstrap.dart';
import 'config/flavor.dart';

void main() => bootstrap(Flavor.dev);
```

`lib/main_staging.dart` and `lib/main.dart` are identical with `Flavor.staging` and `Flavor.prod`.
`bootstrap` arrives in Task 8; until then, stub it as
`Future<void> bootstrap(Flavor flavor) async {}` in `lib/bootstrap.dart` and delete the stub in
Task 8.

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "feat(config): add flavors and validated app configuration"
```

---

### Task 4: Localization

**Files:**

- Create: `l10n.yaml`, `lib/l10n/app_en.arb`, `lib/l10n/app_id.arb`
- Create: `lib/core/ui/localization/context_l10n_extension.dart`
- Test: `test/l10n/arb_parity_test.dart`

**Interfaces:**

- Consumes: nothing.
- Produces: `AppLocalizations` (generated), and `context.l10n` as the only way features read
  strings. Keys used by later plans: `appTitle`, `settings`, `theme`, `language`, `retry`,
  `errorNetwork`, `errorUnauthorized`, `errorNotFound`, `errorServer`, `errorUnknown`,
  `emptyTitle`, `emptyBody`.

- [ ] **Step 1: Write the failing parity test**

`test/l10n/arb_parity_test.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every locale defines exactly the same keys', () {
    Set<String> keysOf(String path) {
      final json = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
      return json.keys.where((k) => !k.startsWith('@')).toSet();
    }

    final en = keysOf('lib/l10n/app_en.arb');
    final id = keysOf('lib/l10n/app_id.arb');

    expect(id.difference(en), isEmpty, reason: 'keys in id missing from en');
    expect(en.difference(id), isEmpty, reason: 'keys in en missing from id');
  });
}
```

- [ ] **Step 2: Run it and watch it fail**

Run: `fvm flutter test test/l10n/arb_parity_test.dart`
Expected: FAIL — `PathNotFoundException`.

- [ ] **Step 3: Write `l10n.yaml`**

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-dir: lib/l10n/generated
output-localization-file: app_localizations.dart
nullable-getter: false
synthetic-package: false
```

Add `lib/l10n/generated/` to the analyzer excludes (already done in Task 1) and to
`tool/coverage.sh` exclusions in Task 9.

- [ ] **Step 4: Write the ARB files**

`lib/l10n/app_en.arb`:

```json
{
  "@@locale": "en",
  "appTitle": "Flutter Production Grade",
  "settings": "Settings",
  "theme": "Theme",
  "language": "Language",
  "retry": "Retry",
  "errorNetwork": "No connection. Check your network and try again.",
  "errorUnauthorized": "Your session expired. Sign in again.",
  "errorNotFound": "We couldn't find that.",
  "errorServer": "The server had a problem. Try again shortly.",
  "errorUnknown": "Something went wrong.",
  "emptyTitle": "Nothing here yet",
  "emptyBody": "When there is something to show, it will appear here."
}
```

`lib/l10n/app_id.arb` carries the same keys with Indonesian values (`"settings": "Pengaturan"`,
`"theme": "Tema"`, `"language": "Bahasa"`, `"retry": "Coba lagi"`, and so on).

- [ ] **Step 5: Write the context extension**

`lib/core/ui/localization/context_l10n_extension.dart`:

```dart
import 'package:flutter/widgets.dart';

import '../../../l10n/generated/app_localizations.dart';

extension L10nExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
```

- [ ] **Step 6: Generate and run**

Run: `make l10n && fvm flutter test test/l10n/arb_parity_test.dart`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "feat(l10n): add en and id localizations with a parity test"
```

---

### Task 5: Settings service — theme and locale

**Files:**

- Create: `lib/core/data/services/storage/settings_service.dart`
- Create: `lib/features/settings/ui/view_models/theme_view_model.dart`
- Create: `lib/features/settings/ui/view_models/locale_view_model.dart`
- Test: `test/core/data/services/storage/settings_service_test.dart`
- Test: `test/features/settings/ui/view_models/theme_view_model_test.dart`

**Interfaces:**

- Consumes: nothing.
- Produces:
  - `abstract interface class SettingsService` with
    `Future<ThemeMode?> readThemeMode()`, `Future<void> writeThemeMode(ThemeMode mode)`,
    `Future<Locale?> readLocale()`, `Future<void> writeLocale(Locale locale)`.
  - `SharedPreferencesSettingsService` implementing it.
  - `@riverpod class ThemeViewModel extends _$ThemeViewModel` with `ThemeMode build()` and
    `Future<void> toggle()`.
  - `@riverpod class LocaleViewModel extends _$LocaleViewModel` with `Locale build()` and
    `Future<void> select(Locale locale)`.
  - `settingsServiceProvider`, overridden in `bootstrap` and in every test.

Per ADR-0009 and ADR-0027 the stored value is always a resolved `ThemeMode.light` or
`ThemeMode.dark` — never `ThemeMode.system` — and a supported `Locale`. The OS value is read once,
when storage returns null.

- [ ] **Step 1: Write the failing view-model test**

`test/features/settings/ui/view_models/theme_view_model_test.dart`:

```dart
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
          settingsServiceProvider
              .overrideWithValue(_FakeSettings(storedTheme: ThemeMode.dark)),
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
```

- [ ] **Step 2: Run it and watch it fail**

Run: `fvm flutter test test/features/settings`
Expected: FAIL — missing URIs.

- [ ] **Step 3: Write `settings_service.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class SettingsService {
  Future<ThemeMode?> readThemeMode();
  Future<void> writeThemeMode(ThemeMode mode);
  Future<Locale?> readLocale();
  Future<void> writeLocale(Locale locale);
}

class SharedPreferencesSettingsService implements SettingsService {
  const SharedPreferencesSettingsService(this._prefs);

  static const _themeKey = 'settings.themeMode';
  static const _localeKey = 'settings.locale';

  final SharedPreferences _prefs;

  @override
  Future<ThemeMode?> readThemeMode() async => switch (_prefs.getString(_themeKey)) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => null,
      };

  @override
  Future<void> writeThemeMode(ThemeMode mode) async {
    assert(mode != ThemeMode.system, 'Only a resolved mode may be stored (ADR-0009)');
    await _prefs.setString(_themeKey, mode == ThemeMode.dark ? 'dark' : 'light');
  }

  @override
  Future<Locale?> readLocale() async {
    final code = _prefs.getString(_localeKey);
    return code == null ? null : Locale(code);
  }

  @override
  Future<void> writeLocale(Locale locale) =>
      _prefs.setString(_localeKey, locale.languageCode);
}

final settingsServiceProvider = Provider<SettingsService>(
  (ref) => throw UnimplementedError('settingsServiceProvider must be overridden'),
);

/// Resolved once in `bootstrap` from storage, falling back to OS brightness.
final initialThemeModeProvider = Provider<ThemeMode>(
  (ref) => throw UnimplementedError('initialThemeModeProvider must be overridden'),
);

/// Resolved once in `bootstrap` from storage, falling back to the OS locale.
final initialLocaleProvider = Provider<Locale>(
  (ref) => throw UnimplementedError('initialLocaleProvider must be overridden'),
);
```

- [ ] **Step 4: Write the two view models**

`lib/features/settings/ui/view_models/theme_view_model.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/data/services/storage/settings_service.dart';

part 'theme_view_model.g.dart';

@riverpod
class ThemeViewModel extends _$ThemeViewModel {
  @override
  ThemeMode build() => ref.watch(initialThemeModeProvider);

  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await ref.read(settingsServiceProvider).writeThemeMode(next);
    state = next;
  }
}
```

`locale_view_model.dart` is the same shape with
`Locale build() => ref.watch(initialLocaleProvider);` and
`Future<void> select(Locale locale)` writing then assigning.

- [ ] **Step 5: Write the settings service test**

`test/core/data/services/storage/settings_service_test.dart` uses
`SharedPreferences.setMockInitialValues({})` and asserts: null before a write; `ThemeMode.dark`
after writing dark; that writing `ThemeMode.system` trips the assertion under
`expect(..., throwsAssertionError)`; and round-tripping a `Locale('id')`.

- [ ] **Step 6: Generate and run**

Run: `make gen && fvm flutter test test/core test/features/settings`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "feat(settings): persist resolved theme mode and locale"
```

---

### Task 6: Theme and design system

**Files:**

- Create: `lib/core/ui/themes/app_theme.dart`, `colors.dart`, `typography.dart`
- Create: `lib/core/ui/design_system/spacing.dart`, `radius.dart`
- Create: `lib/core/ui/design_system/widgets/app_button.dart`, `app_text_field.dart`,
  `app_scaffold.dart`, `app_empty_state.dart`, `app_error_view.dart`, `app_loading.dart`
- Test: `test/core/ui/design_system/app_button_test.dart`,
  `test/core/ui/design_system/goldens_test.dart`
- Create: `test/support/golden_helper.dart`, `test/flutter_test_config.dart`

**Interfaces:**

- Consumes: `context.l10n` (Task 4), `AppError` (Task 2).
- Produces:
  - `AppTheme.light(Color seed)` / `AppTheme.dark(Color seed)` returning `ThemeData`.
  - `AppSpacing.xs/sm/md/lg/xl` (4/8/16/24/32), `AppRadius.sm/md/lg`.
  - `AppButton({required String label, required VoidCallback? onPressed, bool isLoading, Key? key})`
  - `AppTextField({required String label, required TextEditingController controller,
String? Function(String?)? validator, bool obscureText, Key? key})`
  - `AppErrorView({required AppError error, required VoidCallback onRetry})` — maps `AppError` to
    an l10n string; this is the only place that mapping exists.
  - `AppEmptyState()`, `AppLoading()`, `AppScaffold({required String title, required Widget body})`

- [ ] **Step 1: Write the failing widget test**

`test/core/ui/design_system/app_button_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_production_grade/core/ui/design_system/widgets/app_button.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppButton', () {
    testWidgets('invokes onPressed when tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              key: const ValueKey('button'),
              label: 'Submit',
              onPressed: () => taps++,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('button')));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('shows a spinner and blocks taps while loading', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              key: const ValueKey('button'),
              label: 'Submit',
              isLoading: true,
              onPressed: () => taps++,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('button')));
      await tester.pump();
      expect(taps, 0);
    });
  });
}
```

- [ ] **Step 2: Run it and watch it fail**

Run: `fvm flutter test test/core/ui`
Expected: FAIL — missing URI.

- [ ] **Step 3: Write the tokens**

`lib/core/ui/design_system/spacing.dart`:

```dart
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}
```

`radius.dart` follows the same shape with `sm = 8`, `md = 12`, `lg = 20`.

- [ ] **Step 4: Write `app_theme.dart`**

```dart
import 'package:flutter/material.dart';

import 'colors.dart';

abstract final class AppTheme {
  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
```

`colors.dart` holds `static const Color seed = Color(0xFF00629E);` and nothing else. No other file
in the project may declare a `Color` literal.

- [ ] **Step 5: Write the six widgets**

`AppButton` renders a `FilledButton` whose `onPressed` is `isLoading ? null : onPressed`, and whose
child is a sized `CircularProgressIndicator(strokeWidth: 2)` when loading. `AppErrorView` maps
`AppError` to a message:

```dart
String _message(BuildContext context, AppError error) => switch (error) {
      NetworkError() => context.l10n.errorNetwork,
      UnauthorizedError() => context.l10n.errorUnauthorized,
      NotFoundError() => context.l10n.errorNotFound,
      ServerError() => context.l10n.errorServer,
      UnknownError() => context.l10n.errorUnknown,
    };
```

The switch is exhaustive over the sealed class, so adding an `AppError` variant later fails
compilation here — which is the intent.

- [ ] **Step 6: Run the widget test**

Run: `fvm flutter test test/core/ui/design_system/app_button_test.dart`
Expected: PASS, 2 tests.

- [ ] **Step 7: Add the golden harness**

`test/flutter_test_config.dart`:

```dart
import 'dart:async';

import 'package:alchemist/alchemist.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  return AlchemistConfig.runWithConfig(
    config: const AlchemistConfig(
      ciGoldensConfig: CiGoldensConfig(enabled: true),
      platformGoldensConfig: PlatformGoldensConfig(enabled: false),
    ),
    run: testMain,
  );
}
```

Platform goldens are disabled deliberately (ADR-0019): they render differently per host and would
fail on any machine but the one that generated them.

- [ ] **Step 8: Write the golden test**

`test/core/ui/design_system/goldens_test.dart` uses `goldenTest` with a `GoldenTestGroup` of each
widget in both themes, tagged `golden`. Run `make goldens` once to generate, then `make test` to
verify they pass unchanged.

- [ ] **Step 9: Commit**

```bash
git add -A
git commit -m "feat(ui): add theme tokens, design system widgets, and goldens"
```

---

### Task 7: Routing shell

**Files:**

- Create: `lib/routing/routes.dart`, `lib/routing/router.dart`
- Create: `lib/features/home/ui/views/home_screen.dart`
- Create: `lib/features/settings/ui/views/settings_screen.dart`
- Create: `lib/core/platform/url_strategy_io.dart`, `url_strategy_web.dart`,
  `url_strategy.dart`
- Test: `test/routing/router_test.dart`, `test/features/settings/ui/views/settings_screen_test.dart`

**Interfaces:**

- Consumes: `themeViewModelProvider`, `localeViewModelProvider` (Task 5), design system (Task 6).
- Produces:
  - Typed routes `HomeRoute`, `SettingsRoute` via `go_router_builder`.
  - `@riverpod GoRouter router(Ref ref)` — a single router provider. Plan 2 adds the auth
    redirect to this provider; nothing else touches routing.
  - `configureUrlStrategy()` — a no-op on native, `usePathUrlStrategy()` on web (ADR-0022).

- [ ] **Step 1: Write the failing router test**

`test/routing/router_test.dart` builds a `ProviderContainer` with the settings overrides, reads
`routerProvider`, and asserts that `router.configuration.findMatch(Uri.parse('/settings'))`
resolves to the settings route and that an unknown path resolves to the error builder.

- [ ] **Step 2: Run it and watch it fail**

Run: `fvm flutter test test/routing`
Expected: FAIL — missing URI.

- [ ] **Step 3: Write `routes.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/home/ui/views/home_screen.dart';
import '../features/settings/ui/views/settings_screen.dart';

part 'routes.g.dart';

@TypedGoRoute<HomeRoute>(
  path: '/',
  routes: [TypedGoRoute<SettingsRoute>(path: 'settings')],
)
class HomeRoute extends GoRouteData with _$HomeRoute {
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const HomeScreen();
}

class SettingsRoute extends GoRouteData with _$SettingsRoute {
  const SettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SettingsScreen();
}
```

- [ ] **Step 4: Write `router.dart`**

```dart
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'routes.dart';

part 'router.g.dart';

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) => GoRouter(
      routes: $appRoutes,
      initialLocation: const HomeRoute().location,
      debugLogDiagnostics: false,
    );
```

- [ ] **Step 5: Write the URL strategy conditional import**

`lib/core/platform/url_strategy.dart`:

```dart
export 'url_strategy_io.dart' if (dart.library.js_interop) 'url_strategy_web.dart';
```

`url_strategy_io.dart` is `void configureUrlStrategy() {}`; the web file calls
`usePathUrlStrategy()` from `package:flutter_web_plugins/url_strategy.dart`.

- [ ] **Step 6: Write the settings screen**

Two controls, both keyed: a `Switch` with `ValueKey('theme_toggle')` calling
`ref.read(themeViewModelProvider.notifier).toggle()`, and a `SegmentedButton<Locale>` with
`ValueKey('locale_selector')` calling `select`.

- [ ] **Step 7: Write the settings widget test**

Pump `SettingsScreen` inside `ProviderScope` with overrides, tap the theme toggle, and assert the
container's `themeViewModelProvider` flipped. Use `pump()`, not `pumpAndSettle()` — there is no
animation to settle and `pumpAndSettle` would hide a rebuild bug behind a timeout.

- [ ] **Step 8: Generate and run**

Run: `make gen && fvm flutter test`
Expected: PASS.

- [ ] **Step 9: Commit**

```bash
git add -A
git commit -m "feat(routing): add typed routes, router provider, and settings screen"
```

---

### Task 8: Bootstrap and app widget

**Files:**

- Create: `lib/bootstrap.dart` (replacing the Task 3 stub), `lib/app.dart`
- Test: `test/bootstrap_test.dart`, `test/app_test.dart`

**Interfaces:**

- Consumes: everything above.
- Produces: `Future<void> bootstrap(Flavor flavor)` and `class App extends ConsumerWidget`.
  Plan 4 inserts the error reporter, version gate, and push steps into `bootstrap` at the
  positions marked in the spec's startup order.

- [ ] **Step 1: Write the failing app test**

`test/app_test.dart` pumps `App` inside a `ProviderScope` with all four overrides
(`appConfigProvider`, `settingsServiceProvider`, `initialThemeModeProvider`,
`initialLocaleProvider`) and asserts: `MaterialApp.themeMode` matches the initial mode; the title
comes from l10n; and switching the provider rebuilds with the other theme.

- [ ] **Step 2: Run it and watch it fail**

Run: `fvm flutter test test/app_test.dart`
Expected: FAIL — missing URI.

- [ ] **Step 3: Write `app.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/ui/themes/app_theme.dart';
import 'features/settings/ui/view_models/locale_view_model.dart';
import 'features/settings/ui/view_models/theme_view_model.dart';
import 'l10n/generated/app_localizations.dart';
import 'routing/router.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      routerConfig: ref.watch(routerProvider),
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeViewModelProvider),
      locale: ref.watch(localeViewModelProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        maxScaleFactor: 2,
        child: child!,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
```

The text-scale clamp is the ADR-0025 ceiling, applied once here rather than per screen.

- [ ] **Step 4: Write `bootstrap.dart`**

```dart
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'config/app_config.dart';
import 'config/flavor.dart';
import 'core/data/services/storage/settings_service.dart';
import 'core/platform/url_strategy.dart';
import 'l10n/generated/app_localizations.dart';

Future<void> bootstrap(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  configureUrlStrategy();

  final config = AppConfig.fromEnvironment(flavor);
  final settings =
      SharedPreferencesSettingsService(await SharedPreferences.getInstance());

  final themeMode = await settings.readThemeMode() ??
      await _seedThemeMode(settings);
  final locale = await settings.readLocale() ?? await _seedLocale(settings);

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        settingsServiceProvider.overrideWithValue(settings),
        initialThemeModeProvider.overrideWithValue(themeMode),
        initialLocaleProvider.overrideWithValue(locale),
      ],
      child: const App(),
    ),
  );
}

/// First launch only: match the OS once, then the stored value wins (ADR-0009).
Future<ThemeMode> _seedThemeMode(SettingsService settings) async {
  final mode = PlatformDispatcher.instance.platformBrightness == Brightness.dark
      ? ThemeMode.dark
      : ThemeMode.light;
  await settings.writeThemeMode(mode);
  return mode;
}

/// First launch only: match the OS locale against the supported set (ADR-0027).
Future<Locale> _seedLocale(SettingsService settings) async {
  final osCode = PlatformDispatcher.instance.locale.languageCode;
  final locale = AppLocalizations.supportedLocales
          .where((l) => l.languageCode == osCode)
          .firstOrNull ??
      const Locale('en');
  await settings.writeLocale(locale);
  return locale;
}
```

- [ ] **Step 5: Write the bootstrap seeding test**

`test/bootstrap_test.dart` calls `_seedThemeMode` and `_seedLocale` indirectly by exporting them as
`@visibleForTesting` functions, with
`tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark` and
`localeTestValue = const Locale('id')`. Assert: dark is returned and persisted; `id` is chosen
because it is supported; an unsupported OS locale (`fr`) falls back to `en`.

- [ ] **Step 6: Run everything**

Run: `make gen && make lint && make test`
Expected: PASS, no analyzer output.

- [ ] **Step 7: Verify the app actually runs**

Run: `make run-dev` on a simulator, and
`fvm flutter run -d chrome -t lib/main_dev.dart --dart-define-from-file=config/dev.json`.
Expected: home screen renders; the settings route flips the theme; the web URL is `/settings`
with no `#`.

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "feat(app): add bootstrap, app widget, and first-launch seeding"
```

---

### Task 9: Coverage gate and CI

**Files:**

- Create: `tool/coverage.sh`, `tool/doctor.sh`
- Create: `.github/workflows/ci.yaml`
- Create: `lefthook.yml`, `renovate.json`

**Interfaces:**

- Consumes: the `Makefile` targets from Task 1.
- Produces: the merge gate every later plan must keep green.

- [ ] **Step 1: Write `tool/coverage.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Exclusions are listed explicitly, never globbed away silently (ADR-0010).
EXCLUDE=(
  '**/*.g.dart'
  '**/*.freezed.dart'
  'lib/l10n/generated/**'
  'lib/core/data/services/local/connection/web.dart'
  'lib/core/platform/url_strategy_web.dart'
)

fvm dart run coverage:remove_from_lcov \
  --in coverage/lcov.info --out coverage/lcov.cleaned.info \
  "${EXCLUDE[@]/#/--remove=}"

total=$(fvm dart run coverage:format_coverage --help >/dev/null 2>&1; \
  awk -F: '/^LF:/{f+=$2} /^LH:/{h+=$2} END{printf "%d %d", h, f}' coverage/lcov.cleaned.info)
hit=${total% *}
found=${total#* }

echo "covered ${hit}/${found}"
if [ "$hit" -ne "$found" ]; then
  echo "FAIL: coverage is not 100% of measured lines"
  fvm dart run coverage:format_coverage --lcov --in coverage/lcov.cleaned.info \
    --report-on lib 2>/dev/null || true
  exit 1
fi
```

- [ ] **Step 2: Run it and confirm it fails on purpose**

Temporarily add an uncovered function to `lib/core/utils/result.dart`, run `make cov`, and confirm
it exits non-zero naming the file. Remove the function and confirm it exits 0.
A gate you have never seen fail is not a gate.

- [ ] **Step 3: Write `tool/doctor.sh`**

Checks, each with a named failure message: `.fvmrc` matches `fvm flutter --version`;
`config/dev.json` exists; `dart run build_runner build` leaves the tree clean.

- [ ] **Step 4: Write `.github/workflows/ci.yaml`**

Steps in the spec's order, with `kuhnroyal/flutter-fvm-config-action` to read `.fvmrc`,
`subosito/flutter-action` to install, a `pub-cache` restore, and a `build_runner` cache keyed on
`hashFiles('pubspec.lock', 'lib/**/*.dart')`. Jobs: `analyze`, `test`, `build`, `integration`.

- [ ] **Step 5: Write `lefthook.yml`**

```yaml
pre-commit:
  parallel: true
  commands:
    format:
      glob: "*.dart"
      run: fvm dart format --set-exit-if-changed {staged_files}
    analyze:
      glob: "*.dart"
      run: fvm flutter analyze --fatal-infos
```

Install with `lefthook install`. It must stay fast — bypassing hooks is not permitted in this
repository, so a slow hook is a problem to fix, not to work around.

- [ ] **Step 6: Write `renovate.json`**

Group `build_runner` with every `*_generator` and `*_annotation` package in one pull request; they
must move together or the intermediate state does not compile.

- [ ] **Step 7: Push and watch CI**

```bash
git add -A
git commit -m "ci: add coverage gate, doctor, workflows, hooks, and renovate"
git push
```

Expected: every job green. If `integration` fails for want of an integration test, add the
placeholder from Plan 2 Task 1 rather than disabling the job.

---

## Self-Review

**Spec coverage.** Foundation sections mapped: environment (Task 1), flavors and config (Task 3),
theming (Tasks 5–6), localization (Tasks 4–5), design system (Task 6), routing (Task 7), startup
order steps 1–2 and 4 and 7 (Task 8), coverage gate and CI (Task 9), web URL strategy (Task 7).
Deferred to later plans by design: networking and refresh (Plan 2), drift and products (Plan 3),
observability, version gate, push, biometrics, Patrol, a11y assertions, schema dumps (Plan 4).
Startup steps 3, 5, and 6 are explicitly marked in Task 8 as Plan 4 insertions, so the gap is
named rather than silent.

**Placeholder scan.** No TBDs. Three tasks describe a test's assertions in prose rather than full
code — Task 6 Step 8 (goldens), Task 7 Step 1 (router), Task 9 Step 4 (CI YAML) — because the code
is mechanical given the named API and the assertions are stated exactly. Every other step carries
runnable code.

**Type consistency.** `SettingsService` has the same four methods in Task 5's fake, its
implementation, and Task 8's caller. `initialThemeModeProvider` / `initialLocaleProvider` are
declared in Task 5 and overridden in Task 8. `AppError` variant names (`NetworkError`,
`UnauthorizedError`, `NotFoundError`, `ServerError`, `UnknownError`) are declared in Task 2 and
switched over in Task 6. `AppConfig.validate` is used by both the factory and the tests.
`configureUrlStrategy()` is declared in Task 7 and called in Task 8.
