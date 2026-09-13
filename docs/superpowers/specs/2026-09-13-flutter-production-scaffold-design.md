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

Out of scope: push notifications, analytics vendors, crash-reporting vendors, deep-link
campaigns, CI/CD deployment to stores, and desktop platforms.

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
| custom_lint | 0.8.1 | | |

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
    ui/themes/            app_theme.dart, colors.dart, typography.dart, dimens.dart
    ui/widgets/           error_view.dart, empty_view.dart, async_value_view.dart
    ui/localization/      context_l10n_extension.dart
    utils/                result.dart, app_error.dart, logger.dart, error_reporter.dart
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
      ui/view_models/     theme_view_model.dart
      ui/views/           settings_screen.dart
l10n/           app_en.arb, app_id.arb
config/         example.json  (dev.json, staging.json, prod.json are git-ignored)
test/           mirrors lib/ file for file
integration_test/ app_test.dart
test_driver/    integration_test.dart
tool/           coverage.sh
.github/workflows/ci.yaml
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
`AppConfig` is a provider reading `--dart-define-from-file` values (ADR-0011).

### Networking

`dio_provider` builds the client from `AppConfig.baseUrl` and attaches, in order:
`AuthInterceptor`, `RefreshInterceptor`, `ErrorInterceptor`, and — only when `kDebugMode` —
`pretty_dio_logger` and alice's interceptor (ADR-0012).

`RefreshInterceptor` on a 401: lock the queue, call `/auth/refresh` once, persist the new pair,
replay every queued request with the new token; on failure clear the session, which the router's
`redirect` observes and navigates to `/login`. Concurrency is the interesting case and is
explicitly tested (ADR-0005).

### Persistence

Tokens go to `flutter_secure_storage`. On web this is backed by WebCrypto over localStorage, which
is weaker than Keychain or Keystore; acceptable for a scaffold, and the README and code comment
both say that a real deployment should prefer httpOnly cookies.

Drift holds cached products with a `fetchedAt` column. `AppDatabase` is opened through a
conditional import so native uses `drift_flutter` and web uses the wasm worker (ADR-0004).
Settings (the resolved theme mode) live in `shared_preferences` via `SettingsService`.

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

## Testing

| Level | Scope | Determinism |
|---|---|---|
| Unit | repositories against generated mock API services and in-memory drift; mappers; interceptors; the router redirect; `Result` and `AppError` | fully stubbed |
| Widget | every screen in loading, data, empty, and error states; the theme switch; the login form | `ProviderScope` overrides |
| Integration | login, list, paginate, open detail, toggle theme, log out | stubbed dio, no live network |

Mocks are generated with `@GenerateMocks`. Interactive widgets carry `ValueKey`s
(`login_email_field`, `login_password_field`, `login_submit`, `products_list`,
`product_tile_$id`, `theme_toggle`, `logout_button`).

Coverage gate: 100% of measured lines. `tool/coverage.sh` excludes, by explicit listing,
`**/*.g.dart`, `**/*.freezed.dart`, generated l10n output, and
`core/data/services/local/connection/web.dart`. The web connection file is exercised only by the
Chrome integration job; if that job is skipped, that file is unverified.

## CI

GitHub Actions on push and pull request, SDK pinned via fvm with the pub cache restored:

1. `dart format --set-exit-if-changed`
2. `flutter analyze --fatal-infos`
3. `dart run custom_lint` (riverpod_lint)
4. codegen freshness — run `build_runner`, fail if the working tree is dirty
5. `flutter test --coverage`, then `tool/coverage.sh` enforces the gate
6. `flutter build web --release` and `flutter build apk --debug`
7. integration tests on Chrome via chromedriver

Dependabot watches pub and GitHub Actions.

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

## Decisions

All thirteen are recorded in `docs/decisions/`: layering (0001), Riverpod with codegen (0002),
feature-first structure (0003), drift (0004), dio and refresh (0005), DummyJSON (0006), model
split (0007), go_router (0008), theme strategy (0009), testing and coverage (0010), flavors
(0011), debug-only inspectors (0012), single package (0013).
