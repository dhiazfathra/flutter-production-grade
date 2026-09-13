# Flutter production-grade scaffold — design

Date: 2026-09-13
Status: approved, ready for implementation planning

## Purpose

Build a Flutter scaffold that a team can clone and start a real product in. It demonstrates the
full vertical — layered architecture, dependency injection, routing, networking with token
refresh, offline-first caching, theming, localization, error handling, logging, flavors, tests,
and CI — through one authentication flow and one paginated CRUD feature running against a live
public API.

Success criteria:

1. `make gen && make lint && make cov` passes from a clean clone on iOS, Android, and web.
2. Adding a feature means adding one directory and one route; no existing feature is touched.
3. Swapping the backend touches only `data/services` and `data/models`; domain and UI are
   unaffected.
4. Every architectural decision is recorded in `docs/decisions/` with alternatives and
   consequences.

5. The batteries a real product needs on day one — secure credential storage, crash reporting,
   push and deep links, a design system, accessibility, migrations, web delivery — are present in
   the foundation rather than retrofitted onto it.

Out of scope: desktop platforms, store deployment pipelines (Fastlane lanes are deferred, see
ADR-0029), remote feature flags and experiments (ADR-0029), and any backend work — DummyJSON is
taken as given.

## Environment

- Flutter 3.47.4 stable, pinned via fvm (`.fvmrc` committed).
- Platforms: iOS, Android, web.
- Backend: `https://dummyjson.com`.

Dependency versions, verified on pub.dev on 2026-09-13:

| Package | Version | Package | Version |
|---|---|---|---|
| flutter_riverpod | 3.4.3 | drift | 2.35.0 |
| riverpod_annotation | 4.0.7 | drift_flutter | 0.3.1 |
| riverpod_generator | 4.0.9 | drift_dev | 2.35.0 |
| riverpod_lint | 3.1.9 | flutter_secure_storage | 11.1.1 |
| dio | 5.11.1 | go_router | 18.0.1 |
| retrofit | 4.10.0 | connectivity_plus | 7.3.1 |
| retrofit_generator | 10.2.11 | alice | 1.2.0 |
| freezed | 4.0.1 | pretty_dio_logger | 1.4.0 |
| json_serializable | 6.14.1 | mockito | 5.8.1 |
| build_runner | 2.16.1 | very_good_analysis | 11.0.0 |
| custom_lint | 0.8.1 | shared_preferences | 2.5.5 |
| sentry_flutter | 9.30.0 | package_info_plus | 10.2.1 |
| firebase_core | 4.14.0 | firebase_messaging | 16.6.0 |
| flutter_local_notifications | 22.3.1 | app_links | 7.2.1 |
| local_auth | 3.0.2 | skeletonizer | 3.0.0 |
| alchemist | 0.14.0 | patrol | 4.9.0 |
| flutter_launcher_icons | 0.14.4 | flutter_native_splash | 2.4.8 |

## Architecture

Three layers per feature, as in ADR-0001:

- **UI** — views (lean widgets, no business logic) and view models (Riverpod notifiers that own
  screen state and expose commands). Views read immutable snapshots.
- **Domain** — freezed models and, only when justified, use cases. Pure Dart: no Flutter, dio, or
  drift imports.
- **Data** — services (retrofit API clients, drift DAOs, storage wrappers) and repositories.
  Repositories are the single source of truth: they map API models to domain models and own
  caching, revalidation, and retry.

Dependency direction: `ui -> domain <- data`. `core/` is importable by any feature and imports no
feature. Features never import each other.

### Directory layout

```
lib/
  main.dart  main_dev.dart  main_staging.dart
  bootstrap.dart
  app.dart
  config/       flavor.dart, app_config.dart, dependencies.dart
  routing/      router.dart, routes.dart, auth_redirect.dart
  core/
    data/services/api/    dio_provider.dart, interceptors/{auth,refresh,error}_interceptor.dart
    data/services/local/  app_database.dart, connection/{native,web}.dart
    data/services/storage/ secure_token_storage.dart, settings_service.dart
    data/services/remote_config/ version_gate_repository.dart
    ui/themes/            app_theme.dart, colors.dart, typography.dart, dimens.dart
    ui/design_system/     spacing.dart, typography.dart, radius.dart,
                          widgets/{app_button,app_text_field,app_scaffold,
                                   app_empty_state,app_error_view,app_loading}.dart
    ui/widgets/           async_value_view.dart, offline_banner.dart, app_lock_overlay.dart
    ui/localization/      context_l10n_extension.dart
    platform/             connectivity_service.dart, biometric_service.dart,
                          push_service.dart, deep_link_service.dart, url_strategy_{io,web}.dart
    observability/        error_reporter.dart, sentry_error_reporter.dart,
                          analytics_service.dart, analytics_event.dart, analytics_observer.dart
    utils/                result.dart, app_error.dart, logger.dart, validators.dart
  features/
    auth/
      data/models/        login_request_api_model.dart, auth_response_api_model.dart
      data/services/      auth_api_service.dart
      data/repositories/  auth_repository.dart, auth_repository_remote.dart
      domain/models/      user.dart, auth_session.dart
      ui/view_models/     login_view_model.dart, auth_state_notifier.dart
      ui/views/           login_screen.dart
    products/
      data/models/        product_api_model.dart, products_page_api_model.dart
      data/services/      products_api_service.dart, local/products_dao.dart, local/tables.dart
      data/repositories/  products_repository.dart, products_repository_remote.dart
      domain/models/      product.dart, paginated.dart
      ui/view_models/     products_list_view_model.dart, product_detail_view_model.dart
      ui/views/           products_list_screen.dart, product_detail_screen.dart
      ui/widgets/         product_tile.dart
    settings/
      ui/view_models/     theme_view_model.dart, locale_view_model.dart,
                          biometric_settings_view_model.dart
      ui/views/           settings_screen.dart
    update/
      ui/views/           force_update_screen.dart
l10n/           app_en.arb, app_id.arb
config/         example.json  (dev.json, staging.json, prod.json are git-ignored)
web/            index.html (meta, manifest), manifest.json, sqlite3.wasm, drift_worker.js
drift_schemas/  drift_schema_v1.json, ...
test/           mirrors lib/ file for file
test/goldens/   alchemist output, light and dark, plus textScale 2.0
integration_test/ app_test.dart
integration_test/patrol/ permissions_test.dart, biometric_test.dart
test_driver/    integration_test.dart
tool/           coverage.sh, schema.sh
lefthook.yml    renovate.json  release-please-config.json
.github/workflows/ci.yaml, release.yaml
```

### Relationship to the Flutter skills

`flutter-apply-architecture-best-practices` supplies the layer model, the repository pattern, the
conditional use-case rule, and the feature workflow, all of which are followed. Two deliberate
deviations, each with an ADR:

- **Structure is feature-first, not layer-first** (ADR-0003). Layer names, responsibilities, and
  dependency direction are unchanged; only the grouping axis differs.
- **View models are Riverpod notifiers, not `ChangeNotifier`** (ADR-0002). Same role — a
  listenable owning UI state, taking repositories as dependencies, exposing immutable snapshots —
  with `ref.watch` replacing constructor injection.

`dart-add-unit-test`, `flutter-add-widget-test`, and `flutter-add-integration-test` supply the
testing rules in full (mirrored test tree, `group`/`setUp`, mockito, `pumpWidget` inside
`MaterialApp`, `pump` versus `pumpAndSettle`, `scrollUntilVisible`, `ValueKey` targeting,
`IntegrationTestWidgetsFlutterBinding`, and the `test_driver/integration_test.dart` host driver).
Two deviations, both in ADR-0010: `enableFlutterDriverExtension()` is not called (it belongs to
legacy `flutter_driver` and would put test-only code in the production entry point), and the
skill's MCP exploration step is skipped because the Dart MCP server was unavailable.

`flutter-architecting-apps`, `flutter-managing-state`, `flutter-theming-apps`,
`flutter-caching-data`, and `flutter-testing-apps` are not installed in this environment. The
corresponding docs.flutter.dev guidance is applied directly; no skill was run for them.

## Components

### Bootstrap and configuration

`bootstrap(Flavor)` runs inside `runZonedGuarded`, installs `FlutterError.onError` and
`PlatformDispatcher.instance.onError` to route into `ErrorReporter`, awaits the settings read that
resolves the initial theme, and runs the app inside a `ProviderScope` with flavor overrides.
`AppConfig` is a provider reading `--dart-define-from-file` values (ADR-0011), and it asserts at
startup that every required key is present and non-empty — a missing base URL fails immediately
with a named key rather than as a null dereference three screens in.

Startup order is fixed, and each step is skipped only by configuration, never silently:

1. `WidgetsFlutterBinding.ensureInitialized()`, then the web URL strategy (ADR-0022).
2. `AppConfig` validation.
3. `ErrorReporter` selection per flavor, with all three error handlers installed (ADR-0015).
4. Settings read: resolved theme mode and locale (ADR-0009, ADR-0027).
5. Version gate check; a failing gate routes to the update screen before anything else renders
   (ADR-0017).
6. Push initialisation, skipped when Firebase configuration is absent (ADR-0020).
7. `runApp` inside `ProviderScope` with flavor overrides.

### Networking

`dio_provider` builds the client from `AppConfig.baseUrl` and attaches, in order:
`AuthInterceptor`, `RefreshInterceptor`, `ErrorInterceptor`, and — only when `kDebugMode` —
`pretty_dio_logger` and alice's interceptor (ADR-0012).

`RefreshInterceptor` on a 401: lock the queue, call `/auth/refresh` once, persist the new pair,
replay every queued request with the new token; on failure clear the session, which the router's
`redirect` observes and navigates to `/login`. Concurrency is the interesting case and is
explicitly tested (ADR-0005).

### Persistence

Tokens go to `flutter_secure_storage` behind a `SecureTokenStorage` interface (ADR-0014): Keychain
on iOS, EncryptedSharedPreferences over the Keystore on Android. On web it is WebCrypto over
`localStorage`, which is weaker than either; acceptable for a scaffold, and the README and the code
comment both say that a real deployment should prefer httpOnly cookies. Logout clears secure
storage and the drift cache together, or the next user of the device sees the previous user's
cached data.

Drift holds cached products with a `fetchedAt` column. `AppDatabase` is opened through a
conditional import so native uses `drift_flutter` and web uses the wasm worker (ADR-0004). The
schema is versioned from v1, with a committed dump per version in `drift_schemas/` and a generated
migration test for every step (ADR-0021); `make schema` produces the dump, and CI fails if
`schemaVersion` moved without one.

Settings — the resolved theme mode, the resolved locale, and the biometric-lock flag — live in
`shared_preferences` via `SettingsService`. Nothing secret goes there.

### Data flow: products list

1. The view model watches `productsRepository.watchPage(page)`, a drift stream — cached rows
   render on the first frame, with no spinner when a cache exists.
2. The repository checks `fetchedAt` against the TTL and, if stale or absent, fetches
   `/products?limit=20&skip=N`.
3. The response is mapped to domain models and upserted into drift; the stream pushes the update
   to the UI automatically.
4. Network failure with a populated cache surfaces a non-blocking banner, not an error screen.
   Network failure with an empty cache shows `ErrorView` with retry.
5. Search calls `/products/search?q=` and bypasses the cache, since results are transient.

### Error handling

Every repository method returns `Result<T>` (a freezed union of `Ok` and `Err`). `ErrorInterceptor`
and a drift error mapper convert exceptions into `AppError`: `network`, `unauthorized`,
`notFound`, `server`, `unknown`. View models pattern-match on `AppError` and produce localized
messages. No code above the data layer catches `DioException` or a drift exception.

### Theming

`ColorScheme.fromSeed` for light and dark; tokens only in `core/ui/themes/`. Widgets use
`Theme.of(context)` and `Dimens` constants — no literal colours or magic padding. `ThemeViewModel`
stores a resolved light or dark mode, seeded once from OS brightness on first launch (ADR-0009).
The settings screen shows a two-state switch.

### Localization

`flutter_localizations` with ARB files for `en` and `id`, generated by `flutter gen-l10n`. Every
user-visible string, including error messages, comes from the generated class. A test asserts the
two ARB files carry identical key sets.

### Observability

`ErrorReporter` is an interface with two implementations: `NoopErrorReporter` (dev, and what every
test gets) and `SentryErrorReporter` (staging and prod), selected by flavor. `beforeSend` scrubs the
`Authorization` header and the body of auth requests — the same leak class ADR-0012 restricts alice
for. The DSN is a `--dart-define` value.

`AnalyticsService` takes a sealed `AnalyticsEvent`, not a string and a map (ADR-0018). A go_router
`NavigatorObserver` emits `ScreenViewed`, so screen tracking is not a per-screen obligation. View
models emit events; widgets never do. Tests assert against a recording fake.

### Connectivity and offline presentation

`ConnectivityService` wraps `connectivity_plus` as a stream provider. It drives an offline banner
and a "cached {relative time}" line from the drift `fetchedAt` column, and nothing else — requests
are never gated on it, because transport presence is not backend reachability (ADR-0016). On
regaining connectivity the list view model triggers exactly one revalidation.

### Version gate

`package_info_plus` supplies the running version; `VersionGateRepository` supplies the minimum, from
`AppConfig` in the scaffold and from a remote source later without touching callers. Below the
minimum, a go_router guard routes to a blocking update screen that composes with the auth redirect
rather than racing it. Comparison is semantic — `1.10.0 > 1.9.0` is a unit test (ADR-0017).

### Push and deep links

Every external navigation — a notification tap, a universal link, a custom scheme, a web URL — is
converted to a route path and handed to go_router, so the auth redirect applies uniformly
(ADR-0020). `PendingDeepLink` holds the target when it arrives before the router exists or while the
user is signed out; the redirect consumes and clears it after login. Payload `route` values are
untrusted network input: they are matched against known routes, never passed through, and unknown
targets fall back to home and are reported. Firebase configuration files are per-flavor and
git-ignored, with committed examples; when absent, push initialisation is skipped, and that path is
tested.

### Design system and states

`core/ui/design_system/` holds `AppSpacing`, `AppTypography`, `AppRadius`, and the shared widgets
(`AppButton`, `AppTextField`, `AppScaffold`, `AppEmptyState`, `AppErrorView`, `AppLoading`).
Features compose these; literal padding values and bare Material buttons are lint violations.
Loading states use `skeletonizer`, which derives the skeleton from the real widget tree rather than
from a second layout that rots (ADR-0019). Empty, error, and offline are route-level widgets, not
per-screen improvisations.

### Accessibility

Semantics labels come from the ARB files, never hardcoded. A shared test helper asserts the Android
and iOS tap-target guidelines, the labeled-tap-target guideline, and the text-contrast guideline for
every screen in both themes. Text scale is honoured to 2.0 and clamped above it, with a golden at
2.0 per screen that must not overflow (ADR-0025). Contrast guidelines constrain the seed colour, so
a bad seed fails a test rather than a user.

### Biometric lock

Opt-in, off by default (ADR-0024). Returning to the foreground past a timeout shows an overlay above
the router requiring biometric or device-credential authentication. Biometrics gate access to an
existing session; they never replace the password login, and the keystore item is read only after a
successful authentication. Unavailable on web — the setting is hidden there, and both platform
branches are tested.

### Web delivery

Path URL strategy, so routes are shareable URLs; the deployment must rewrite unknown paths to
`index.html`, and a `_redirects` file plus an nginx snippet are committed as examples. `index.html`
carries title, description, Open Graph and Twitter tags, and a theme colour, with a real
`manifest.json` for installability. `sqlite3.wasm` and `drift_worker.js` are committed under `web/`
and their presence is a CI assertion (ADR-0022).

### Forms

Validators are pure `String? Function(String?)` functions in `core/utils/validators.dart`, composed
with a `combine` helper, returning localization keys rather than literal strings. No forms framework
(ADR-0023) — revisit if a form exceeds roughly ten interdependent fields.

## Testing

| Level | Scope | Determinism |
|---|---|---|
| Unit | repositories against generated mock API services and in-memory drift; mappers; interceptors; the router redirect; validators; the version comparator; the deep-link URL-to-route mapper; `Result` and `AppError` | fully stubbed |
| Widget | every screen in loading, data, empty, offline, and error states; the theme and locale switches; the login form; the update gate; the lock overlay | `ProviderScope` overrides |
| Golden | every design-system widget and every screen, light and dark, plus `textScaleFactor: 2.0` | alchemist, bundled font |
| Accessibility | tap targets, labels, and contrast per screen per theme | `meetsGuideline` matchers |
| Migration | every drift schema step against its committed dump | `drift_dev schema generate` |
| Integration | login, list, paginate, open detail, toggle theme, switch locale, deep link into detail, log out | stubbed dio, no live network |
| Patrol (Android only) | notification permission prompt, biometric prompt, permission-denied branches | separate job, native dialogs |

Mocks are generated with `@GenerateMocks`. Platform-backed services — secure storage,
connectivity, biometrics, push, analytics, the error reporter — are substituted through their
interfaces with fakes, never by mocking a plugin channel; that is the reason each one has an
interface. Interactive widgets carry `ValueKey`s (`login_email_field`, `login_password_field`,
`login_submit`, `products_list`, `product_tile_$id`, `theme_toggle`, `locale_selector`,
`biometric_toggle`, `update_now_button`, `logout_button`).

Coverage gate: 100% of measured lines. `tool/coverage.sh` excludes, by explicit listing,
`**/*.g.dart`, `**/*.freezed.dart`, generated l10n output, and
`core/data/services/local/connection/web.dart`. The web connection file is exercised only by the
Chrome integration job; if that job is skipped, that file is unverified. Thin plugin adapters
(`SentryErrorReporter`, the `firebase_messaging` and `local_auth` wrappers) contain no branching
logic and are excluded by the same explicit listing — their callers are fully covered through the
interfaces. Coverage is uploaded to Codecov so the number is visible on the pull request rather
than only as a job exit code (ADR-0028).

Goldens and Patrol tests are part of the merge gate but are not part of the line-coverage measure.

## CI

GitHub Actions on push and pull request, SDK pinned via fvm with the pub cache restored:

1. `dart format --set-exit-if-changed`
2. `flutter analyze --fatal-infos` against `very_good_analysis`
3. `dart run custom_lint` (riverpod_lint)
4. codegen freshness — run `build_runner`, fail if the working tree is dirty; the generated output
   is cached on `pubspec.lock` plus the annotated sources, because codegen otherwise dominates the
   run (ADR-0028)
5. drift schema freshness — fail if `schemaVersion` changed without a dump in `drift_schemas/`
6. web asset check — `sqlite3.wasm` and `drift_worker.js` present under `web/`
7. `flutter test --coverage` (unit, widget, golden, accessibility, migration), then
   `tool/coverage.sh` enforces the gate and uploads to Codecov
8. `flutter build web --release`, `flutter build web --wasm` as a compile check, and
   `flutter build apk --debug`
9. integration tests on Chrome via chromedriver
10. Patrol tests on an Android emulator, in a separate job

`lefthook` runs `dart format` and `flutter analyze` on staged Dart files before each commit; it must
stay fast, because bypassing hooks is not permitted here. Renovate watches pub and GitHub Actions
with grouped pull requests; `release-please` produces the changelog, version bump, and tag from the
conventional commits (ADR-0028).

## Risks

- **DummyJSON availability.** The app depends on a third-party service; every test stubs it, so
  CI is unaffected by an outage. A broken demo is a README problem, not a build failure.
- **Drift on web.** Missing `sqlite3.wasm` or `drift_worker.js` fails only at runtime on web. The
  web build and Chrome integration jobs are what catch it.
- **Codegen drift.** Stale committed generated output produces confusing failures; the freshness
  check in CI is the guard.
- **Coverage gate friction.** A 100% gate will occasionally block a legitimate change. The
  response is to add the test or to add an explicit, reviewed entry to the exclusion list — never
  to lower the threshold silently.
- **Dependency surface.** This scaffold now carries Firebase, Sentry, biometrics, and Patrol.
  Each is a real maintenance cost and a real source of native build breakage. Each is behind an
  interface so it can be removed, and each is listed in the README with what it costs.
- **Firebase configuration.** The scaffold must run with no Firebase files present, or a clone
  cannot be started. Push initialisation is skipped when configuration is absent, and that branch
  is tested — if it regresses, a fresh clone fails at launch with no obvious cause.
- **Golden churn.** Goldens produce review noise on intentional design changes and platform noise
  if generated anywhere but the Flutter-only CI job. A golden update in a pull request that claims
  no visual change is a review signal, not a formality.
- **Web migration coverage.** Drift migration tests run on the native VM; web-specific migration
  behaviour is unverified. Accepted, recorded here rather than discovered later.
- **Untrusted navigation input.** Deep-link and notification payloads come from the network and
  drive navigation. They are matched against known routes rather than passed through; weakening
  that to "just push the path" would be a privilege-escalation bug, not a convenience.
- **Startup chain length.** Seven ordered startup steps means more ways to fail before the first
  frame. Every remote step must have a timeout and fail open, or one outage becomes an app-wide
  outage.

## Decisions

All twenty-nine are recorded in `docs/decisions/`.

Foundation: layering (0001), Riverpod with codegen (0002), feature-first structure (0003), drift
(0004), dio and refresh (0005), DummyJSON (0006), model split (0007), go_router (0008), theme
strategy (0009), testing and coverage (0010), flavors (0011), debug-only inspectors (0012), single
package (0013).

Batteries: secure token storage (0014), crash and error reporting (0015), connectivity and offline
UX (0016), version gate (0017), analytics behind an interface (0018), design system and goldens
(0019), push and deep links (0020), drift migrations (0021), web delivery (0022), forms and
validation (0023), biometric re-authentication (0024), accessibility baseline (0025), Patrol for
native dialogs (0026), in-app locale switcher (0027), repository automation (0028), and the
deferred additions with the seams they depend on (0029, Proposed).
